#include "aiosProfileController.h"

#include "serversUiController.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
#include <QDebug>

namespace {
// VPNPan endpoint — адрес берётся из hostName сервера (порт VPNPan 8765 за nginx).
// Схема https: на проде VPNPan всегда за TLS.
QString profileUrlFor(const QString &hostName, const QString &token)
{
    return QStringLiteral("https://%1/api/profile/%2").arg(hostName, token);
}
} // namespace

AiosProfileController::AiosProfileController(QObject *parent)
    : QObject(parent)
{
}

QString AiosProfileController::serverToken(const QString &serverId) const
{
    return m_servers ? m_servers->aiosTokenForServer(serverId) : QString();
}

void AiosProfileController::refresh(const QString &serverId)
{
    const QString token = serverToken(serverId);
    if (token.isEmpty()) {
        m_hasProfile = false;
        emit profileChanged();
        return;
    }
    if (token == m_token && m_hasProfile) {
        return; // уже загружен
    }

    const QString id = serverId.isEmpty() && m_servers ? m_servers->getDefaultServerId() : serverId;
    const QString hostName = m_servers ? m_servers->serverHostName(id) : QString();
    QUrl url(profileUrlFor(hostName, token));
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(10000);

    QNetworkReply *reply = m_nam.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, token]() {
        onProfileReply(reply, token);
    });
}

void AiosProfileController::onProfileReply(QNetworkReply *reply, const QString &token)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "AIOS profile request failed:" << reply->errorString();
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    const QJsonObject obj = doc.object();
    if (obj.contains("error")) {
        qWarning() << "AIOS profile error:" << obj.value("error").toString();
        m_hasProfile = false;
        emit profileChanged();
        return;
    }

    m_token = token;
    m_owner = obj.value("owner").toString();
    m_devicesUsed = obj.value("used").toInt(0);
    m_devicesTotal = obj.value("devices").toInt(0);
    m_expires = obj.value("expires").toString();
    m_expired = obj.value("expired").toBool(false);
    m_hasProfile = true;
    emit profileChanged();
}
