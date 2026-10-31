#include "appinfo.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QStyleHints>
#include <QUrl>
#include <QWindow>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#endif

AppInfo::AppInfo(const QString &dataDir, bool portable, QObject *parent)
    : QObject(parent)
    , m_dataDir(dataDir)
    , m_portable(portable)
{
#ifdef Q_OS_ANDROID
    m_mobile = true;
#else
    m_mobile = qEnvironmentVariableIntValue("EXAM1_MOBILE") != 0;
#endif
    // EXAM1_SAFE_AREA=top,right,bottom,left: simulates the bars of a phone on a computer.
    const QStringList forced = qEnvironmentVariable("EXAM1_SAFE_AREA").split(QLatin1Char(','));
    if (forced.size() == 4) {
        m_forcedSafe = QMargins(forced.at(3).toInt(), forced.at(0).toInt(), forced.at(1).toInt(), forced.at(2).toInt());
        m_safe = m_forcedSafe;
        m_safeForced = true;
    }
}

QString AppInfo::version() const
{
    return QCoreApplication::applicationVersion();
}

QString AppInfo::qtVersion() const
{
    return QString::fromLatin1(qVersion());
}

QString AppInfo::systemFontFamily() const
{
    return QFontDatabase::systemFont(QFontDatabase::GeneralFont).family();
}

void AppInfo::attachWindow(QWindow *window)
{
    if (!window || m_window == window)
        return;
    m_window = window;
#if QT_VERSION >= QT_VERSION_CHECK(6, 9, 0)
    if (!m_safeForced) {
        setSafeArea(window->safeAreaMargins());
        connect(window, &QWindow::safeAreaMarginsChanged, this, &AppInfo::setSafeArea);
    }
#endif
#ifdef Q_OS_ANDROID
    applyStatusBarStyle();
    // Qt sets the icons back to the system colours when the system switches to dark mode or back.
    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, [this] { applyStatusBarStyle(); });
    connect(qGuiApp, &QGuiApplication::applicationStateChanged, this, [this](Qt::ApplicationState state) {
        if (state == Qt::ApplicationActive)
            applyStatusBarStyle();
    });
#endif
}

void AppInfo::setSafeArea(const QMargins &margins)
{
#ifdef Q_OS_ANDROID
    // Full screen (Main.qml): no room is kept at the top and bottom, where the hidden status and
    // navigation bars only come back over the content for a moment. Only the sides are kept, for
    // the camera cutout of a phone held sideways. Keeping the top and bottom margins gave empty
    // bands, twice the height of the bars when the window was not full screen.
    const QMargins kept(margins.left(), 0, margins.right(), 0);
#else
    const QMargins kept = margins;
#endif
    if (kept == m_safe)
        return;
    m_safe = kept;
    emit safeAreaChanged();
}

void AppInfo::applyStatusBarStyle() const
{
#ifdef Q_OS_ANDROID
    // Android 11 (API 30) and later. Before Android 15 the system draws its own status bar
    // background, and the icons keep the colours chosen by the system.
    if (QNativeInterface::QAndroidApplication::sdkVersion() < 30)
        return;
    (void)QNativeInterface::QAndroidApplication::runOnAndroidMainThread([] {
        const QJniObject activity = QNativeInterface::QAndroidApplication::context();
        if (!activity.isValid())
            return;
        const QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
        if (!window.isValid())
            return;
        const QJniObject controller =
            window.callObjectMethod("getInsetsController", "()Landroid/view/WindowInsetsController;");
        if (!controller.isValid())
            return;
        const jint lightStatusBars = 0x8; // WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
        // Clears the "light status bar" flag: light icons on the dark band.
        controller.callMethod<void>("setSystemBarsAppearance", "(II)V", jint(0), lightStatusBars);
    });
#endif
}

QString AppInfo::formatDuration(int seconds) const
{
    seconds = qMax(0, seconds);
    const int h = seconds / 3600;
    const int m = (seconds % 3600) / 60;
    const int s = seconds % 60;
    if (h > 0)
        return QStringLiteral("%1:%2:%3").arg(h).arg(m, 2, 10, QLatin1Char('0')).arg(s, 2, 10, QLatin1Char('0'));
    return QStringLiteral("%1:%2").arg(m, 2, 10, QLatin1Char('0')).arg(s, 2, 10, QLatin1Char('0'));
}

void AppInfo::openDataFolder() const
{
    if (m_mobile)
        return; // the data of an Android application cannot be shown in a file manager
    QDesktopServices::openUrl(QUrl::fromLocalFile(m_dataDir));
}

bool AppInfo::openUrl(const QString &url) const
{
    const QUrl u = QUrl::fromUserInput(url.trimmed());
    if (!u.isValid() || (u.scheme() != QLatin1String("http") && u.scheme() != QLatin1String("https")))
        return false;
    return QDesktopServices::openUrl(u);
}
