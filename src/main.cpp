/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QCommandLineParser>
#include <QQmlContext>
#include <QWindow>

#include <KDeclarative/KDeclarative>
#include <KDBusService>
#include <KLocalizedString>
#include <KAboutData>

#include "ToolsModel.h"
#include "Configuration.h"

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

    KLocalizedString::setApplicationDomain("plasma-systemmonitor");

    KAboutData aboutData{
        /* componentName */ "plasma-systemmonitor",
        /* displayName */ i18n("System Monitor"),
        /* version */ "1.0",
        /* shortDescription */ i18n("An application for monitoring system resources"),
        /* licenseType */ KAboutLicense::GPL,
        /* copyrightStatement */ i18n("© 2020 Plasma Development Team"),
        /* otherText */ QString{},
        /* homePageAddress */ QString{}
    };
    aboutData.setDesktopFileName(QStringLiteral("org.kde.plasma-systemmonitor"));
    aboutData.setProgramLogo(app.windowIcon());

    aboutData.addAuthor(i18n("Arjen Hiemstra"), i18n("Development"), QStringLiteral("ahiemstra@heimr.nl"));
    aboutData.addAuthor(i18n("Uri Herrera"), i18n("Design"), QString{});
    aboutData.addAuthor(i18n("Nate Graham"), i18n("Design and Quality Assurance"), QString{});
    aboutData.addAuthor(i18n("David Redondo"), i18n("Development"), QString{});
    aboutData.addAuthor(i18n("Noah Davis"), i18n("Design and Quality Assurance"), QString{});
    aboutData.addAuthor(i18n("Marco Martin"), i18n("Development"), QString{});
    aboutData.addAuthor(i18n("David Edmundson"), i18n("Development"), QString{});

    aboutData.setTranslator(
        i18ndc(nullptr, "NAME OF TRANSLATORS", "Your names"),
        i18ndc(nullptr, "EMAIL OF TRANSLATORS", "Your emails")
    );

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
    qmlRegisterSingletonType<CommandLineArguments>("org.kde.systemmonitor", 1, 0, "CommandLineArguments", [&parser](QQmlEngine*, QJSEngine*) {
        return new CommandLineArguments{parser};
    });

    QQmlApplicationEngine engine;

    KDeclarative::KDeclarative kdeclarative;
    kdeclarative.setDeclarativeEngine(&engine);
    kdeclarative.setupContext();

    engine.load(QStringLiteral(":/main.qml"));

    QObject::connect(&service, &KDBusService::activateRequested, &engine, []() {
        if (!qApp->topLevelWindows().isEmpty()) {
            QWindow *win = qApp->topLevelWindows().first();
            win->raise();
            win->requestActivate();
        }
    });

    return app.exec();
}

#include "main.moc"
