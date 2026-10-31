// Application-level information and small helpers for QML.
#pragma once

#include <QMargins>
#include <QObject>
#include <QPointer>
#include <QString>
#include <QUrl>

class QWindow;

class AppInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)
    Q_PROPERTY(QString dataDir READ dataDir CONSTANT)
    Q_PROPERTY(bool portable READ portable CONSTANT)
    Q_PROPERTY(QString systemFontFamily READ systemFontFamily CONSTANT)
    // Phone or tablet (Android): touch screen, no data folder to open, no folder import.
    // EXAM1_MOBILE=1 gives the same interface on a computer (layout checks).
    Q_PROPERTY(bool mobile READ mobile CONSTANT)
    // Parts of the window the content must stay clear of, in device-independent pixels: on Android
    // (full screen) the camera cutout of a phone held sideways, at the left or right.
    Q_PROPERTY(int safeTop READ safeTop NOTIFY safeAreaChanged)
    Q_PROPERTY(int safeBottom READ safeBottom NOTIFY safeAreaChanged)
    Q_PROPERTY(int safeLeft READ safeLeft NOTIFY safeAreaChanged)
    Q_PROPERTY(int safeRight READ safeRight NOTIFY safeAreaChanged)

public:
    AppInfo(const QString &dataDir, bool portable, QObject *parent = nullptr);

    QString version() const;
    QString qtVersion() const;
    QString dataDir() const { return m_dataDir; }
    bool portable() const { return m_portable; }
    // Platform UI font (Segoe UI on Windows), as used by the Evalbox web page in a browser.
    QString systemFontFamily() const;
    bool mobile() const { return m_mobile; }
    int safeTop() const { return m_safe.top(); }
    int safeBottom() const { return m_safe.bottom(); }
    int safeLeft() const { return m_safe.left(); }
    int safeRight() const { return m_safe.right(); }

    // Follows the safe area of the main window and, on Android, keeps the status bar icons
    // light on the slate band drawn behind them.
    void attachWindow(QWindow *window);

    Q_INVOKABLE QString formatDuration(int seconds) const;  // "14:05" or "1:02:03"
    Q_INVOKABLE void openDataFolder() const;
    Q_INVOKABLE bool openUrl(const QString &url) const;

signals:
    void safeAreaChanged();

private:
    void setSafeArea(const QMargins &margins);
    void applyStatusBarStyle() const;

    QString m_dataDir;
    bool m_portable;
    bool m_mobile;
    QMargins m_safe;
    QMargins m_forcedSafe;   // EXAM1_SAFE_AREA (layout checks on a computer)
    bool m_safeForced = false;
    QPointer<QWindow> m_window;
};
