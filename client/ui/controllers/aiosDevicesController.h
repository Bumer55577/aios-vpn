#ifndef AIOSDEVICESCONTROLLER_H
#define AIOSDEVICESCONTROLLER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantList>
#include <QStringList>

class ServersUiController;

// AIOS: управление устройствами подписки через VPNPan API.
//   GET    https://<host>/api/devices/<token>          -> список устройств
//   DELETE https://<host>/api/devices/<token> {"hwid"} -> отвязка устройства
// Панель без этих эндпоинтов -> supported=false, UI показывает фолбэк
// (счётчики из профиля, управление в панели VPNPan).
class AiosDevicesController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool loading READ loading NOTIFY stateChanged)
    Q_PROPERTY(bool supported READ supported NOTIFY stateChanged)
    Q_PROPERTY(bool hasList READ hasList NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)

public:
    explicit AiosDevicesController(QObject *parent = nullptr);

    void setServersController(ServersUiController *servers) { m_servers = servers; }

    bool loading() const { return m_loading; }
    bool supported() const { return m_supported; }
    bool hasList() const { return m_hasList; }
    QString error() const { return m_error; }
    QVariantList devices() const { return m_devices; }

    // Обновить список устройств (serverId пуст -> сервер по умолчанию)
    Q_INVOKABLE void refresh(const QString &serverId = QString());
    // Отвязать одно устройство
    Q_INVOKABLE void revoke(const QString &hwid);
    // Отвязать несколько (последовательно); ok/fail counts в revokeFinished
    Q_INVOKABLE void revokeMany(const QVariantList &hwids);
    // Сбросить локальное выделение после операции
    Q_INVOKABLE QString myHwid() const;

signals:
    void stateChanged();
    void devicesChanged();
    // includesThisDevice=true среди отвязанных был HWID этого устройства
    void revokeFinished(int okCount, int failCount, bool includesThisDevice, const QString &lastError);

private slots:
    void onListReply(QNetworkReply *reply, const QString &token);
    void onRevokeReply(QNetworkReply *reply, const QString &hwid);

private:
    QString tokenFor(const QString &serverId) const;
    QString hostFor(const QString &serverId) const;
    void fetchList(const QString &hostName, const QString &token);
    void revokeNext();
    void parseDevices(const QByteArray &body);

    QNetworkAccessManager m_nam;
    ServersUiController *m_servers = nullptr;

    QVariantList m_devices;
    QStringList m_pendingRevokes;
    int m_okCount = 0;
    int m_failCount = 0;
    bool m_includeThisDevice = false;
    QString m_lastError;

    bool m_loading = false;
    bool m_supported = true;
    bool m_hasList = false;
    QString m_error;
};

#endif // AIOSDEVICESCONTROLLER_H
