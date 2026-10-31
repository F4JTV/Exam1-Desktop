// Exam'1 — French amateur radio licence exam trainer (Qt 6 / QML edition).

#include "appinfo.h"
#include "appsettings.h"
#include "appupdate.h"
#include "bankstore.h"
#include "browsermodel.h"
#include "examsession.h"
#include "iconprovider.h"
#include "updater.h"
#include "userstore.h"

#include <QDir>
#include <QFileInfo>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickItem>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTimer>
#include <functional>

#ifndef EXAM1_VERSION
#define EXAM1_VERSION "dev" // normally set by CMake from project(VERSION)
#endif

namespace {

// Development aid (capture tour): lists the visible items that go beyond the right edge of the
// window, i.e. content cut or pushed out of the screen on a narrow window.
void reportOverflow(QQuickItem *item, qreal limit, const QString &step, bool parentOver = false)
{
    if (!item || !item->isVisible() || item->opacity() <= 0.0)
        return;
    const QRectF r = item->mapRectToScene(QRectF(0, 0, item->width(), item->height()));
    const bool over = item->width() > 0 && r.right() > limit + 1 && r.left() < limit - 1;
    const bool isText = item->inherits("QQuickText") || item->inherits("QQuickTextInput");
    // The outermost item that overflows, and the texts inside it (usually the cause).
    if (over && (!parentOver || isText))
        qWarning().noquote() << "OVERFLOW" << step << item->metaObject()->className() << "x" << int(r.left())
                             << "right" << int(r.right()) << "w" << int(item->width())
                             << item->property("text").toString().left(60);
    const auto children = item->childItems();
    for (QQuickItem *child : children)
        reportOverflow(child, limit, step, over || parentOver);
}

// Development aid: when EXAM1_CAPTURE_DIR is set, walks through the screens defined by
// Main.qml's tourStep() and saves a screenshot of each one.
void runCaptureTour(QQmlApplicationEngine &engine, const QString &dir)
{
    QDir().mkpath(dir);
    auto step = std::make_shared<int>(0);
    auto next = std::make_shared<std::function<void()>>();
    *next = [&engine, dir, step, next]() {
        QObject *root = engine.rootObjects().value(0);
        auto *window = qobject_cast<QQuickWindow *>(root);
        if (!window) {
            QCoreApplication::exit(1);
            return;
        }
        QVariant name;
        QMetaObject::invokeMethod(root, "tourStep", Q_RETURN_ARG(QVariant, name), Q_ARG(QVariant, *step));
        if (name.toString().isEmpty()) {
            QCoreApplication::quit();
            return;
        }
        if (name.toString() == QLatin1String("wait")) { // bank still being installed
            QTimer::singleShot(500, window, [next]() { (*next)(); });
            return;
        }
        QTimer::singleShot(900, window, [window, dir, step, name, next]() {
            reportOverflow(window->contentItem(), window->width(), name.toString());
            const QImage img = window->grabWindow();
            img.save(QDir(dir).filePath(QStringLiteral("%1-%2.png").arg(*step, 2, 10, QLatin1Char('0')).arg(name.toString())));
            ++*step;
            (*next)();
        });
    };
    QTimer::singleShot(2500, *next);
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setOrganizationName(QStringLiteral("Exam1"));
    QGuiApplication::setApplicationName(QStringLiteral("Exam1"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("Exam'1"));
    QGuiApplication::setApplicationVersion(QStringLiteral(EXAM1_VERSION));
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Exam1App/resources/icons/exam1.png")));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    for (const char *face : {"Regular", "Bold", "Italic", "BoldItalic"})
        QFontDatabase::addApplicationFont(QStringLiteral(":/qt/qml/Exam1App/resources/fonts/AtkinsonHyperlegible-%1.ttf").arg(QLatin1String(face)));
    QFont font(QStringLiteral("Atkinson Hyperlegible"));
    font.setPointSizeF(10.5);
    QGuiApplication::setFont(font);

    // Portable mode (USB key): a "portable.txt" file next to the executable keeps all data beside it.
    const QString appDir = QCoreApplication::applicationDirPath();
    const bool portable = QFileInfo::exists(QDir(appDir).filePath(QStringLiteral("portable.txt")));
    QString dataDir = portable ? QDir(appDir).filePath(QStringLiteral("userdata"))
                               : QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString overrideDir = qEnvironmentVariable("EXAM1_USER_DIR");
    if (!overrideDir.isEmpty())
        dataDir = overrideDir;
    QDir().mkpath(dataDir);

    // The question bank (about 40 MB with its pictures) is re-installed from the package when
    // needed. On Android it goes to "no_backup", next to "files": Android's automatic backup of
    // "files" is limited to 25 MB, and keeps only the candidates, results and settings.
    QString banksDir = QDir(dataDir).filePath(QStringLiteral("banks"));
#ifdef Q_OS_ANDROID
    if (overrideDir.isEmpty() && QFileInfo(dataDir).fileName() == QLatin1String("files"))
        banksDir = QDir::cleanPath(QDir(dataDir).filePath(QStringLiteral("../no_backup/banks")));
#endif

    AppSettings settings;
    AppInfo info(dataDir, portable);
    BankStore bank(banksDir);
    UserStore user(QDir(dataDir).filePath(QStringLiteral("user.sqlite")));
    Updater updater(&bank, &settings);
    AppUpdate appUpdate(&settings, portable);
    ExamSession exam(&bank, &user, &settings);
    exam.setSavePath(QDir(dataDir).filePath(QStringLiteral("session.json")));
    BrowserModel browser(&bank, &user);
    bank.openCurrent();

    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "App", &info);
    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "Prefs", &settings);
    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "Bank", &bank);
    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "User", &user);
    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "Updates", &updater);
    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "AppUpdate", &appUpdate);
    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "Exam", &exam);
    qmlRegisterSingletonInstance("Exam1.Core", 1, 0, "Browser", &browser);
    qmlRegisterUncreatableType<Updater>("Exam1.Core", 1, 0, "UpdaterState", QStringLiteral("enum holder"));

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    engine.addImageProvider(QStringLiteral("icon"), new IconProvider);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Exam1App/qml/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst()))
        info.attachWindow(window);

    // Phones close applications in the background without notice: the exam in progress is
    // saved as soon as the application leaves the screen.
    QObject::connect(&app, &QGuiApplication::applicationStateChanged, &exam, [&exam](Qt::ApplicationState state) {
        if (state != Qt::ApplicationActive)
            exam.saveProgress();
    });

    updater.autoStart();
    if (qEnvironmentVariable("EXAM1_CAPTURE_DIR").isEmpty() || !qEnvironmentVariable("EXAM1_RELEASES_URL").isEmpty())
        appUpdate.autoStart();

    const QString captureDir = qEnvironmentVariable("EXAM1_CAPTURE_DIR");
    if (!captureDir.isEmpty()) {
        // EXAM1_WINDOW_SIZE=1000x660: capture at another window size (layout checks).
        const QStringList size = qEnvironmentVariable("EXAM1_WINDOW_SIZE").split(QLatin1Char('x'));
        if (size.size() == 2) {
            if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst()))
                window->resize(size.at(0).toInt(), size.at(1).toInt());
        }
        engine.rootObjects().constFirst()->setProperty("tourName", qEnvironmentVariable("EXAM1_TOUR", QStringLiteral("main")));
        runCaptureTour(engine, captureDir);
    }

    return app.exec();
}
