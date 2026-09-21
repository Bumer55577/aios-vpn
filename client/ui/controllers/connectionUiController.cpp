#include "connectionUiController.h"

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS) || defined(MACOS_NE)
    #include <QGuiApplication>
#else
    #include <QApplication>
#endif

#include "amneziaApplication.h"
#include "core/controllers/serversController.h"
#include "core/models/containerConfig.h"
#include "core/utils/containerEnum.h"

#include <QDateTime>
#include <QDebug>
#include <QTcpSocket>

#ifdef Q_OS_ANDROID
    #include "platforms/android/android_controller.h"
#endif

namespace
{
    // AIOS: display helpers for the home screen stat tiles
    QString formatSpeed(quint64 bytesPerSec)
    {
        const double mbps = bytesPerSec * 8 / 1e6;
        if (mbps >= 10.0) {
            return QObject::tr("%1 Мбит/с").arg(mbps, 0, 'f', 0);
        }
        if (mbps >= 1.0) {
            return QObject::tr("%1 Мбит/с").arg(mbps, 0, 'f', 1);
        }
        return QObject::tr("%1 Кбит/с").arg(bytesPerSec * 8 / 1024.0, 0, 'f', 0);
    }

    QString formatElapsed(qint64 msecs)
    {
        const qint64 total = msecs / 1000;
        const qint64 h = total / 3600;
        const qint64 m = (total % 3600) / 60;
        const qint64 s = total % 60;
        return QString("%1:%2:%3")
            .arg(h, 2, 10, QChar('0'))
            .arg(m, 2, 10, QChar('0'))
            .arg(s, 2, 10, QChar('0'));
    }

#ifdef Q_OS_ANDROID
    // AIOS: авто-повтор старта тумнеля на Android. После force-stop приложения
    // («очистить всё») система может ещё около получминуты держать предыдущую
    // VPN-сессию занятой: establish() возвращает null и подключение падает с
    // транзиентной ошибкой (на UI — «код 1000»). Несколько тихих повторных
    // попыток с нарастающими паузами перекрывают это окно без показа ошибки.
    constexpr int kAndroidConnectRetryAttempts = 3;
    constexpr int kAndroidConnectRetryDelaysMsecs[] = { 5000, 10000, 15000 };
#endif
} // namespace

ConnectionUiController::ConnectionUiController(ConnectionController* connectionController,
                                                ServersController* serversController,
                                                QObject *parent)
    : QObject(parent),
      m_connectionController(connectionController),
      m_serversController(serversController)
{
    connect(m_connectionController, &ConnectionController::connectionStateChanged, this, &ConnectionUiController::onConnectionStateChanged);

    connect(this, &ConnectionUiController::connectButtonClicked, this, &ConnectionUiController::toggleConnection, Qt::QueuedConnection);

    m_state = Vpn::ConnectionState::Disconnected;

    // AIOS: live stats timers (speed tiles on the home screen)
    m_elapsedTimer.setInterval(1000);
    connect(&m_elapsedTimer, &QTimer::timeout, this, [this]() { updateElapsedText(); });

    m_pingTimer.setInterval(5000);
    connect(&m_pingTimer, &QTimer::timeout, this, [this]() { startPingProbe(); });

    m_pingSocket = new QTcpSocket(this);
    connect(m_pingSocket, &QTcpSocket::connected, this, [this]() {
        m_pingInFlight = false;
        m_pingText = tr("%1 мс").arg(QDateTime::currentMSecsSinceEpoch() - m_pingStartedMsecs);
        m_pingSocket->disconnectFromHost();
        emit statisticsChanged();
    });
    connect(m_pingSocket, &QTcpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        if (m_pingInFlight) {
            m_pingInFlight = false;
            m_pingText = tr("—");
            emit statisticsChanged();
        }
        m_pingSocket->abort();
    });
}

void ConnectionUiController::openConnection()
{
    const QString serverId = m_serversController->getDefaultServerId();
    if (serverId.isEmpty()) {
        m_connectionController->setConnectionState(Vpn::ConnectionState::Disconnected);
        return;
    }

    ErrorCode errorCode = m_connectionController->openConnection(serverId);

    if (errorCode != ErrorCode::NoError) {
        notifyConnectionBlocked(errorCode);
        return;
    }
}

void ConnectionUiController::closeConnection()
{
    m_connectionController->closeConnection();
}

ErrorCode ConnectionUiController::getLastConnectionError()
{
    return m_connectionController->lastConnectionError();
}

void ConnectionUiController::onConnectionStateChanged(Vpn::ConnectionState state)
{
    const Vpn::ConnectionState previousState = m_state;
    m_state = state;

    m_isConnected = false;
    m_connectionStateText = tr("Connecting...");
    switch (state) {
    case Vpn::ConnectionState::Connected: {
        amnApp->networkManager()->clearConnectionCache();

        m_isConnectionInProgress = false;
        m_isConnected = true;
        m_connectionStateText = tr("Connected");

        // AIOS: тумнель поднялся — сбрасываем состояние повторов и считаем,
        // что текущее подключение соответствует желанию пользователя
        m_wasConnectingBeforeError = false;
        m_androidRetryAttemptsLeft = 0;
        m_userDisconnectedManually = false;

        // AIOS: (re)start live stats when the tunnel is up. This also covers the
        // resume path, where the UI learns about an already-active connection.
        if (previousState != Vpn::ConnectionState::Connected) {
            resetStats();
            startStatsTimers();
        }
        break;
    }
    case Vpn::ConnectionState::Connecting: {
        m_isConnectionInProgress = true;
        m_wasConnectingBeforeError = true;
        break;
    }
    case Vpn::ConnectionState::Reconnecting: {
        m_isConnectionInProgress = true;
        m_connectionStateText = tr("Reconnecting...");
        break;
    }
    case Vpn::ConnectionState::Disconnected: {
        m_isConnectionInProgress = false;
        m_connectionStateText = tr("Connect");

        // AIOS: чистое отключение — отложенные повторы старта больше не нужны
        m_wasConnectingBeforeError = false;
        m_androidRetryAttemptsLeft = 0;

        stopStatsTimers();
        break;
    }
    case Vpn::ConnectionState::Disconnecting: {
        m_isConnectionInProgress = true;
        m_connectionStateText = tr("Disconnecting...");
        break;
    }
    case Vpn::ConnectionState::Preparing: {
        m_isConnectionInProgress = true;
        m_connectionStateText = tr("Preparing...");
        break;
    }
    case Vpn::ConnectionState::Error: {
        m_isConnectionInProgress = false;
        m_connectionStateText = tr("Connect");

        stopStatsTimers();
#ifdef Q_OS_ANDROID
        // AIOS: транзиентный сбой старта тумнеля (код 1000 — Android ещё не
        // освободил VPN-сессию после force-stop). Повторяем молча несколько
        // раз, прежде чем показать ошибку пользователю.
        if (m_wasConnectingBeforeError && m_androidRetryAttemptsLeft > 0) {
            --m_androidRetryAttemptsLeft;
            m_wasConnectingBeforeError = false;
            m_connectionStateText = tr("Connecting...");
            emit connectionStateChanged();
            scheduleAndroidConnectRetry();
            break;
        }
        m_wasConnectingBeforeError = false;
#endif
        emit connectionErrorOccurred(getLastConnectionError());
        break;
    }
    case Vpn::ConnectionState::Unknown: {
        m_isConnectionInProgress = false;
        m_connectionStateText = tr("Connect");

        stopStatsTimers();
        emit connectionErrorOccurred(getLastConnectionError());
        break;
    }
    }
    emit connectionStateChanged();
}

void ConnectionUiController::onTranslationsUpdated()
{
    onConnectionStateChanged(getCurrentConnectionState());
}

Vpn::ConnectionState ConnectionUiController::getCurrentConnectionState()
{
    return m_state;
}

// --- AIOS: live connection stats -------------------------------------------

void ConnectionUiController::onBytesChanged(quint64 receivedBytes, quint64 sentBytes)
{
    if (!isConnected()) {
        return;
    }

    const qint64 now = QDateTime::currentMSecsSinceEpoch();

    if (m_lastStatsMsecs == 0) {
        // First sample: VpnProtocol diffs against a zero baseline, so the first
        // value is the total transfer count — skip it to avoid a bogus spike.
        m_lastStatsMsecs = now;
        return;
    }

    const qint64 dt = now - m_lastStatsMsecs;
    m_lastStatsMsecs = now;
    if (dt <= 0) {
        return;
    }

    // VpnProtocol::bytesChanged reports bytes since the previous sample; normalise
    // to bytes-per-second using the real time between samples.
    m_receivedSpeedText = formatSpeed(static_cast<quint64>(receivedBytes * 1000 / dt));
    m_sentSpeedText = formatSpeed(static_cast<quint64>(sentBytes * 1000 / dt));

    emit statisticsChanged();
}

void ConnectionUiController::refreshConnectionState()
{
#ifdef Q_OS_ANDROID
    AndroidController::instance()->requestConnectionStatus();
#endif
}

void ConnectionUiController::resetStats()
{
    m_receivedSpeedText = tr("0 Кбит/с");
    m_sentSpeedText = tr("0 Кбит/с");
    m_pingText = tr("...");
    m_lastReceivedBytes = 0;
    m_lastSentBytes = 0;
    m_lastStatsMsecs = 0;
    m_connectedAtMsecs = QDateTime::currentMSecsSinceEpoch();
    updateElapsedText();
}

void ConnectionUiController::startStatsTimers()
{
    m_elapsedTimer.start();
    m_pingTimer.start();
    startPingProbe();
}

void ConnectionUiController::stopStatsTimers()
{
    m_elapsedTimer.stop();
    m_pingTimer.stop();

    if (m_pingSocket && m_pingSocket->state() != QAbstractSocket::UnconnectedState) {
        m_pingSocket->abort();
    }

    m_receivedSpeedText.clear();
    m_sentSpeedText.clear();
    m_pingText.clear();
    m_connectionElapsedText.clear();

    emit statisticsChanged();
}

void ConnectionUiController::updateElapsedText()
{
    if (m_connectedAtMsecs == 0) {
        return;
    }
    m_connectionElapsedText = formatElapsed(QDateTime::currentMSecsSinceEpoch() - m_connectedAtMsecs);
    emit statisticsChanged();
}

void ConnectionUiController::startPingProbe()
{
    if (!isConnected()) {
        return;
    }

    const QString serverId = m_serversController->getDefaultServerId();
    if (serverId.isEmpty()) {
        return;
    }

    const ServerCredentials credentials = m_serversController->getServerCredentials(serverId);
    if (credentials.hostName.isEmpty()) {
        return;
    }

    if (m_pingSocket->state() != QAbstractSocket::UnconnectedState) {
        m_pingSocket->abort();
    }

    m_pingStartedMsecs = QDateTime::currentMSecsSinceEpoch();
    m_pingInFlight = true;
    // While the tunnel is up this TCP handshake goes through it, so the measured
    // round-trip reflects the real link latency to the server.
    m_pingSocket->connectToHost(credentials.hostName, credentials.port > 0 ? credentials.port : 443);
}
// ---------------------------------------------------------------------------

QString ConnectionUiController::connectionStateText() const
{
    return m_connectionStateText;
}

void ConnectionUiController::toggleConnection()
{
    // AIOS: любое ручное действие отменяет отложенный тихий повтор подключения
    ++m_retryGeneration;

    if (m_state == Vpn::ConnectionState::Preparing) {
        emit preparingConfig();
        return;
    }

    if (isConnectionInProgress()) {
        m_userDisconnectedManually = true; // AIOS: пользователь сам останавливает подключение
        closeConnection();
    } else if (isConnected()) {
        m_userDisconnectedManually = true; // AIOS: пользователь сам нажал «выключить»
        closeConnection();
    } else {
        m_userDisconnectedManually = false; // AIOS: ручное подключение сбрасывает запрет
#ifdef Q_OS_ANDROID
        m_androidRetryAttemptsLeft = kAndroidConnectRetryAttempts; // новая попытка — новые повторы
#endif
        const QString serverId = m_serversController->getDefaultServerId();
        if (serverId.isEmpty()) {
            return;
        }

        const ErrorCode errorCode = m_connectionController->isConnectionSupported(serverId);
        if (errorCode != ErrorCode::NoError) {
            notifyConnectionBlocked(errorCode);
            return;
        }

        emit prepareConfig();
    }
}

void ConnectionUiController::tryAutoConnect()
{
#ifdef Q_OS_ANDROID
    // AIOS: перед решением уточняем реальное состояние VPN-сервиса — на resume
    // статус тумнеля может прийти с задержкой, и без этого запроса можно
    // случайно начать «подключаться» к уже работающему тумнелю (сервис такое
    // игнорирует, но UI мигнёт «Подключение…» без причины).
    AndroidController::instance()->requestConnectionStatus();
    QTimer::singleShot(800, this, [this]() { tryAutoConnectNow(); });
#else
    tryAutoConnectNow();
#endif
}

void ConnectionUiController::tryAutoConnectNow()
{
    // AIOS: автоподключение при запуске/открытии приложения. Раньше срабатывало
    // только на холодный старт процесса (CoreSignalHandlers::initAutoConnectHandler),
    // а свайп приложения и повторное открытие процесс не перезапускает —
    // пользователь видел отключённое состояние, хотя автоподключение включено.
    if (m_userDisconnectedManually) {
        qDebug() << "AIOS: auto-connect skipped: user disconnected manually in this session";
        return;
    }

    switch (m_state) {
    case Vpn::ConnectionState::Disconnected:
    case Vpn::ConnectionState::Error:
    case Vpn::ConnectionState::Unknown:
        break;
    default:
        return; // уже подключено или подключение идёт
    }

    const QString serverId = m_serversController->getDefaultServerId();
    if (serverId.isEmpty()) {
        return;
    }

    qDebug() << "AIOS: auto-connect on app start/open";
    toggleConnection();
}

void ConnectionUiController::scheduleAndroidConnectRetry()
{
#ifdef Q_OS_ANDROID
    const int delayIndex = qBound(0, kAndroidConnectRetryAttempts - m_androidRetryAttemptsLeft - 1,
                                  kAndroidConnectRetryAttempts - 1);
    const int delayMsecs = kAndroidConnectRetryDelaysMsecs[delayIndex];
    const int generation = m_retryGeneration;
    qInfo() << "AIOS: tunnel start failed transiently (code 1000), retry in" << delayMsecs << "ms";

    QTimer::singleShot(delayMsecs, this, [this, generation]() {
        if (generation != m_retryGeneration) {
            return; // пользователь начал новое действие — повтор отменён
        }
        if (m_state != Vpn::ConnectionState::Error) {
            return; // состояние уже изменилось (подключено/отключено/подключается)
        }
        qInfo() << "AIOS: retrying tunnel start after transient failure";
        openConnection();
    });
#endif
}

void ConnectionUiController::notifyConnectionBlocked(ErrorCode errorCode)
{
    if (errorCode == ErrorCode::LegacyApiV1NotSupportedError) {
        emit unsupportedConnectDrawerRequested();
        return;
    }

    if (errorCode == ErrorCode::NoInstalledContainersError) {
        emit noInstalledContainers();
        return;
    }

    emit connectionErrorOccurred(errorCode);
}

bool ConnectionUiController::isConnectionInProgress() const
{
    return m_isConnectionInProgress;
}

bool ConnectionUiController::isConnected() const
{
    return m_isConnected;
}

bool ConnectionUiController::isRevokeBlockedDuringActiveConnection(const QString &serverId, int containerIndex,
                                                                   const QString &clientId) const
{
    if (clientId.isEmpty() || (!isConnected() && !isConnectionInProgress())) {
        return false;
    }

    if (m_serversController->getDefaultServerId() != serverId) {
        return false;
    }

    if (static_cast<int>(m_serversController->getDefaultContainer(serverId)) != containerIndex) {
        return false;
    }

    const auto adminConfig = m_serversController->selfHostedAdminConfig(serverId);
    if (!adminConfig.has_value()) {
        return false;
    }

    const QString connectionClientId =
            adminConfig->containerConfig(static_cast<DockerContainer>(containerIndex)).protocolConfig.clientId();
    if (connectionClientId.isEmpty()) {
        return false;
    }

    return connectionClientId == clientId || connectionClientId.contains(clientId);
}
