#include "aiosDevicesController.h"

#include "serversUiController.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QUrl>
#include <QBuffer>
#include <QDateTime>
#include <QSysInfo>
#include <QDebug>

namespace {
QString devicesUrlFor(const QString &hostName, const QString &token)
{
    return QStringLiteral("https://%1/api/devices/%2").arg(hostName, token);
}

// Панели могут отдавать добавленное время в разных форматах (unix sec/ms, строка).
QString normalizeAddedAt(const QJsonValue &v)
{
    if (v.isDouble()) {
        const qint64 raw = static_cast<qint64>(v.toDouble());
        const QDateTime dt = raw > 100000000000LL ? QDateTime::fromMSecsSinceEpoch(raw)
                                                  : QDateTime::fromSecsSinceEpoch(raw);
        if (dt.isValid()) {
            return dt.toString("dd.MM.yyyy");
        }
        return QString();
    }
    if (v.isString()) {
        const QString s = v.toString();
        bool ok = false;
        const qint64 raw = s.toLongLong(&ok);
        if (ok && raw > 1000000000LL) {
            const QDateTime dt = raw > 100000000000LL ? QDateTime::fromMSecsSinceEpoch(raw)
                                                      : QDateTime::fromSecsSinceEpoch(raw);
            if (dt.isValid()) {
                return dt.toString("dd.MM.yyyy");
            }
        }
        return s;
    }
    return QString();
}
} // namespace

AiosDevicesController::AiosDevicesController(QObject *parent)
    : QObject(parent)
{
}

QString AiosDevicesController::tokenFor(const QString &serverId) const
{
    return m_servers ? m_servers->aiosTokenForServer(serverId) : QString();
}

QString AiosDevicesController::hostFor(const QString &serverId) const
{
    const QString id = (serverId.isEmpty() && m_servers) ? m_servers->getDefaultServerId() : serverId;
    return m_servers ? m_servers->serverHostName(id) : QString();
}

QString AiosDevicesController::myHwid() const
{
    return QString::fromLatin1(QSysInfo::machineUniqueId());
}

void AiosDevicesController::refresh(const QString &serverId)
{
    const QString token = tokenFor(serverId);
    if (token.isEmpty()) {
        m_supported = false;
        m_hasList = false;
        m_devices.clear();
        m_error = QString();
        m_loading = false;
        emit devicesChanged();
        emit stateChanged();
        return;
    }

    m_loading = true;
    m_error = QString();
    emit stateChanged();

    fetchList(hostFor(serverId), token);
}

void AiosDevicesController::fetchList(const QString &hostName, const QString &token)
{
    if (hostName.isEmpty()) {
        m_loading = false;
        m_supported = false;
        m_hasList = false;
        emit stateChanged();
        return;
    }

    QNetworkRequest request(QUrl(devicesUrlFor(hostName, token)));
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(10000);

    QNetworkReply *reply = m_nam.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, token]() {
        onListReply(reply, token);
    });
}

void AiosDevicesController::onListReply(QNetworkReply *reply, const QString &token)
{
    reply->deleteLater();
    m_loading = false;

    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    if (reply->error() != QNetworkReply::NoError) {
        // 404/405 -> панель не поддерживает список устройств
        m_supported = !(status == 404 || status == 405 || reply->error() == QNetworkReply::ContentNotFoundError
                        || reply->error() == QNetworkReply::OperationCanceledError);
        m_hasList = false;
        m_devices.clear();
        m_error = m_supported ? reply->errorString() : QString();
        emit devicesChanged();
        emit stateChanged();
        return;
    }

    m_supported = true;
    m_error = QString();
    parseDevices(reply->readAll());
    m_hasList = true;
    Q_UNUSED(token)
    emit devicesChanged();
    emit stateChanged();
}

// Разбор одного элемента списка устройств; поля называются по-разному в разных панелях.
static QVariantMap parseDeviceEntry(const QJsonObject &obj)
{
    QVariantMap entry;
    const QString hwid = obj.value("hwid").toString(obj.value("id").toString());
    if (hwid.isEmpty()) {
        return {};
    }
    entry.insert("hwid", hwid);
    entry.insert("name", obj.value("name").toString(obj.value("deviceName").toString(QStringLiteral("Устройство"))));
    entry.insert("platform", obj.value("platform").toString(obj.value("os").toString(obj.value("device").toString())));
    const QJsonValue added = obj.contains("addedAt") ? obj.value("addedAt") : obj.value("added_at");
    entry.insert("addedAt", normalizeAddedAt(added));
    return entry;
}

void AiosDevicesController::parseDevices(const QByteArray &body)
{
    QVariantList result;
    const QJsonDocument doc = QJsonDocument::fromJson(body);
    QJsonArray arr;
    if (doc.isObject()) {
        const QJsonObject obj = doc.object();
        if (obj.contains("error")) {
            m_error = obj.value("error").toString();
            m_hasList = false;
            m_devices.clear();
            return;
        }
        arr = obj.value("devices").toArray();
    } else if (doc.isArray()) {
        arr = doc.array();
    }

    for (const QJsonValue &v : arr) {
        const QVariantMap entry = parseDeviceEntry(v.toObject());
        if (!entry.isEmpty()) {
            result.append(entry);
        }
    }

    m_devices = result;
}

void AiosDevicesController::revoke(const QString &hwid)
{
    m_pendingRevokes.clear();
    m_pendingRevokes.append(hwid);
    m_okCount = 0;
    m_failCount = 0;
    m_includeThisDevice = false;
    m_lastError = QString();
    revokeNext();
}

void AiosDevicesController::revokeMany(const QVariantList &hwids)
{
    m_pendingRevokes.clear();
    for (const QVariant &v : hwids) {
        const QString hwid = v.toString();
        if (!hwid.isEmpty()) {
            m_pendingRevokes.append(hwid);
        }
    }
    m_okCount = 0;
    m_failCount = 0;
    m_includeThisDevice = false;
    m_lastError = QString();
    revokeNext();
}

void AiosDevicesController::revokeNext()
{
    if (m_pendingRevokes.isEmpty()) {
        emit revokeFinished(m_okCount, m_failCount, m_includeThisDevice, m_lastError);
        if (m_okCount > 0) {
            refresh(); // обновить список и счётчики
        }
        return;
    }

    const QString hwid = m_pendingRevokes.first();
    const QString token = tokenFor(QString());
    const QString host = hostFor(QString());
    if (token.isEmpty() || host.isEmpty()) {
        m_failCount += m_pendingRevokes.size();
        m_lastError = QStringLiteral("no access token");
        m_pendingRevokes.clear();
        emit revokeFinished(m_okCount, m_failCount, m_includeThisDevice, m_lastError);
        return;
    }

    QNetworkRequest request(QUrl(devicesUrlFor(host, token)));
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(10000);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QBuffer *buffer = new QBuffer();
    buffer->setData(QJsonDocument(QJsonObject { { "hwid", hwid } }).toJson(QJsonDocument::Compact));
    buffer->open(QIODevice::ReadOnly);

    QNetworkReply *reply = m_nam.sendCustomRequest(request, "DELETE", buffer);
    buffer->setParent(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, hwid]() {
        onRevokeReply(reply, hwid);
    });
}

void AiosDevicesController::onRevokeReply(QNetworkReply *reply, const QString &hwid)
{
    reply->deleteLater();
    if (!m_pendingRevokes.isEmpty() && m_pendingRevokes.first() == hwid) {
        m_pendingRevokes.removeFirst();
    }

    if (reply->error() == QNetworkReply::NoError) {
        m_okCount++;
        if (hwid == myHwid()) {
            m_includeThisDevice = true;
        }
    } else {
        m_failCount++;
        m_lastError = reply->errorString();
    }

    revokeNext();
}
