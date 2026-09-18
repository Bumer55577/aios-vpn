#ifndef AIOSPROFILECONTROLLER_H
#define AIOSPROFILECONTROLLER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class ServersUiController;

// AIOS: профиль пользователя из VPNPan API (/api/profile/<token>).
// Токен берётся из конфига сервера (aios_token). Без ключей — только публичные данные.
class AiosProfileController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString owner READ owner NOTIFY profileChanged)
    Q_PROPERTY(int devicesUsed READ devicesUsed NOTIFY profileChanged)
    Q_PROPERTY(int devicesTotal READ devicesTotal NOTIFY profileChanged)
    Q_PROPERTY(QString expires READ expires NOTIFY profileChanged)
    Q_PROPERTY(bool expired READ expired NOTIFY profileChanged)
    Q_PROPERTY(bool hasProfile READ hasProfile NOTIFY profileChanged)

public:
    explicit AiosProfileController(QObject *parent = nullptr);

    void setServersController(ServersUiController *servers) { m_servers = servers; }

    QString owner() const { return m_owner; }
    int devicesUsed() const { return m_devicesUsed; }
    int devicesTotal() const { return m_devicesTotal; }
    QString expires() const { return m_expires; }
    bool expired() const { return m_expired; }
    bool hasProfile() const { return m_hasProfile; }

    // Профиль для конкретного сервера: token из его конфига; пусто — дефолтный сервер
    Q_INVOKABLE void refresh(const QString &serverId = QString());
    Q_INVOKABLE QString serverToken(const QString &serverId) const;

signals:
    void profileChanged();

private slots:
    void onProfileReply(QNetworkReply *reply, const QString &token);

private:
    QNetworkAccessManager m_nam;
    QString m_token;
    QString m_owner;
    int m_devicesUsed = 0;
    int m_devicesTotal = 0;
    QString m_expires;
    bool m_expired = false;
    bool m_hasProfile = false;
    ServersUiController *m_servers = nullptr;
};

#endif // AIOSPROFILECONTROLLER_H
