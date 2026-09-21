#ifndef CONNECTIONUICONTROLLER_H
#define CONNECTIONUICONTROLLER_H

#include <QObject>
#include <QTimer>

#include "core/controllers/connectionController.h"
#include "core/utils/errorCodes.h"
#include "core/utils/routeModes.h"
#include "core/utils/commonStructs.h"
#include "core/protocols/vpnProtocol.h"
#include "core/controllers/serversController.h"

class QTcpSocket;

class ConnectionUiController : public QObject
{
    Q_OBJECT

public:
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)
    Q_PROPERTY(bool isConnectionInProgress READ isConnectionInProgress NOTIFY connectionStateChanged)
    Q_PROPERTY(QString connectionStateText READ connectionStateText NOTIFY connectionStateChanged)

    // AIOS: live connection stats for the home screen tiles
    Q_PROPERTY(QString receivedSpeedText READ receivedSpeedText NOTIFY statisticsChanged)
    Q_PROPERTY(QString sentSpeedText READ sentSpeedText NOTIFY statisticsChanged)
    Q_PROPERTY(QString pingText READ pingText NOTIFY statisticsChanged)
    Q_PROPERTY(QString connectionElapsedText READ connectionElapsedText NOTIFY statisticsChanged)

    explicit ConnectionUiController(ConnectionController* connectionController,
                                    ServersController* serversController,
                                    QObject *parent = nullptr);

    ~ConnectionUiController() = default;

    bool isConnected() const;
    bool isConnectionInProgress() const;
    QString connectionStateText() const;

    QString receivedSpeedText() const { return m_receivedSpeedText; }
    QString sentSpeedText() const { return m_sentSpeedText; }
    QString pingText() const { return m_pingText; }
    QString connectionElapsedText() const { return m_connectionElapsedText; }

public slots:
    void toggleConnection();

    void openConnection();
    void closeConnection();

    bool isRevokeBlockedDuringActiveConnection(const QString &serverId, int containerIndex, const QString &clientId) const;

    ErrorCode getLastConnectionError();
    void onConnectionStateChanged(Vpn::ConnectionState state);

    void onTranslationsUpdated();

    // AIOS: per-second traffic counters from the VPN service (cumulative rx/tx bytes)
    void onBytesChanged(quint64 receivedBytes, quint64 sentBytes);

    // AIOS: re-sync the UI connection state with the real state of the VPN service
    // (called on app resume; fixes "not connected" shown while the tunnel is up)
    Q_INVOKABLE void refreshConnectionState();

signals:
    void connectionStateChanged();

    void statisticsChanged();

    void connectionErrorOccurred(ErrorCode errorCode);

    void connectButtonClicked();
    void preparingConfig();
    void prepareConfig();
    void unsupportedConnectDrawerRequested();
    void noInstalledContainers();

private:
    Vpn::ConnectionState getCurrentConnectionState();
    void notifyConnectionBlocked(ErrorCode errorCode);

    // AIOS: live stats helpers
    void resetStats();
    void startStatsTimers();
    void stopStatsTimers();
    void updateElapsedText();
    void startPingProbe();

    ConnectionController* m_connectionController;
    ServersController* m_serversController;

    bool m_isConnected = false;
    bool m_isConnectionInProgress = false;
    QString m_connectionStateText = tr("Connect");

    Vpn::ConnectionState m_state;

    // AIOS: live stats state
    QString m_receivedSpeedText;
    QString m_sentSpeedText;
    QString m_pingText;
    QString m_connectionElapsedText;

    quint64 m_lastReceivedBytes = 0;
    quint64 m_lastSentBytes = 0;
    qint64 m_lastStatsMsecs = 0;
    qint64 m_connectedAtMsecs = 0;
    QTimer m_elapsedTimer;
    QTimer m_pingTimer;
    QTcpSocket* m_pingSocket = nullptr;
    qint64 m_pingStartedMsecs = 0;
    bool m_pingInFlight = false;
};

#endif
