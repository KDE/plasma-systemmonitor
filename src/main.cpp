/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QApplication>
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QWindow>

#include <KAboutData>
#include <KDBusService>
#include <KDeclarative/KDeclarative>
#include <KLocalizedString>

#include "Configuration.h"
#include "ToolsModel.h"

static QLoggingCategory::CategoryFilter oldCategoryFilter;

// Qt 5.14 introduces a new syntax for connections
// framework code can't port away due to needing Qt5.12
// this filters out the warnings
// Remove this once we depend on Qt5.15 in frameworks
void filterConnectionSyntaxWarning(QLoggingCategory *category)
{
    if (qstrcmp(category->categoryName(), "qt.qml.connections") == 0) {
        category->setEnabled(QtWarningMsg, false);
    } else if (oldCategoryFilter) {
        oldCategoryFilter(category);
    }
}

class CommandLineArguments : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString pageId MEMBER m_pageId CONSTANT)
    Q_PROPERTY(QString pageName MEMBER m_pageName CONSTANT)
    Q_PROPERTY(QVariant aboutData READ aboutData CONSTANT)

public:
    CommandLineArguments(QCommandLineParser &parser)
        : QObject()
    {
        m_pageId = parser.value("page-id");
        m_pageName = parser.value("page-name");

        if (m_pageId.isEmpty() && m_pageName.isEmpty()) {
            m_pageId = QStringLiteral("overview.page");
        }
    }

    QVariant aboutData() const
    {
        return QVariant::fromValue(KAboutData::applicationData());
    }

private:
    QString m_pageId;
    QString m_pageName;
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_UseHighDpiPixmaps, true);
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("utilities-system-monitor")));

    oldCategoryFilter = QLoggingCategory::installFilter(filterConnectionSyntaxWarning);

    KLocalizedString::setApplicationDomain("plasma-systemmonitor");

    KAboutData aboutData{/* componentName */ "plasma-systemmonitor",
                         /* displayName */ i18n("System Monitor"),
                         /* version */ PROJECT_VERSION,
                         /* shortDescription */ i18n("An application for monitoring system resources"),
                         /* licenseType */ KAboutLicense::GPL,
                         /* copyrightStatement */ i18n("© 2020 Plasma Development Team"),
                         /* otherText */ QString{},
                         /* homePageAddress */ QString{}};
    aboutData.setDesktopFileName(QStringLiteral("org.kde.plasma-systemmonitor"));
    aboutData.setProgramLogo(app.windowIcon());

    aboutData.addAuthor(i18n("Arjen Hiemstra"), i18n("Development"), QStringLiteral("ahiemstra@heimr.nl"));
    aboutData.addAuthor(i18n("Uri Herrera"), i18n("Design"), QString{});
    aboutData.addAuthor(i18n("Nate Graham"), i18n("Design and Quality Assurance"), QString{});
    aboutData.addAuthor(i18n("David Redondo"), i18n("Development"), QString{});
    aboutData.addAuthor(i18n("Noah Davis"), i18n("Design and Quality Assurance"), QString{});
    aboutData.addAuthor(i18n("Marco Martin"), i18n("Development"), QString{});
    aboutData.addAuthor(i18n("David Edmundson"), i18n("Development"), QString{});

    aboutData.setTranslator(i18ndc(nullptr, "NAME OF TRANSLATORS", "Your names"), i18ndc(nullptr, "EMAIL OF TRANSLATORS", "Your emails"));

    KAboutData::setApplicationData(aboutData);

    KDBusService service(KDBusService::Unique);

    QCommandLineParser parser;
    aboutData.setupCommandLine(&parser);
    parser.addOption({QStringLiteral("page-id"), QStringLiteral("Start with the specified page ID shown"), QStringLiteral("page-id")});
    parser.addOption({QStringLiteral("page-name"), QStringLiteral("Start with the specified page name shown"), QStringLiteral("page-name")});
    parser.process(app);
    aboutData.processCommandLine(&parser);

    qmlRegisterAnonymousType<QAbstractItemModel>("org.kde.systemmonitor", 1);
    qmlRegisterType<ToolsModel>("org.kde.systemmonitor", 1, 0, "ToolsModel");
    qmlRegisterType<Configuration>("org.kde.systemmonitor", 1, 0, "Configuration");
    qmlRegisterSingletonType<CommandLineArguments>("org.kde.systemmonitor", 1, 0, "CommandLineArguments", [&parser](QQmlEngine *, QJSEngine *) {
        return new CommandLineArguments{parser};
    });

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.load(QStringLiteral(":/main.qml"));

    QObject::connect(&service, &KDBusService::activateRequested, &engine, []() {
        if (!qApp->topLevelWindows().isEmpty()) {
            QWindow *win = qApp->topLevelWindows().first();
            win->raise();
            win->requestActivate();
        }
    });
    // QDBusConnectionInterface::StartService is blocking so we do it manually
    const auto busInterface = QDBusConnection::sessionBus().interface();
    busInterface->asyncCall(QStringLiteral("StartServiceByName"), QStringLiteral("org.kde.ksystemstats"), 0u);
    return app.exec();
}

#include "main.moc"
