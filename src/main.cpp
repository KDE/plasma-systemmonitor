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

#include "ToolsModel.h"
#include "Configuration.h"

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("plasma-systemmonitor"));
    app.setDesktopFileName(QStringLiteral("org.kde.systemmonitor"));

    KDBusService service(KDBusService::Unique);

    QCommandLineParser parser;
    parser.addOption({QStringLiteral("page"), QStringLiteral("The page to show."), QStringLiteral("page")});
    parser.addHelpOption();
    parser.process(app);

    qmlRegisterAnonymousType<QAbstractItemModel>("org.kde.systemmonitor", 1);
    qmlRegisterType<ToolsModel>("org.kde.systemmonitor", 1, 0, "ToolsModel");
    qmlRegisterType<Configuration>("org.kde.systemmonitor", 1, 0, "Configuration");

    QQmlApplicationEngine engine;

    KDeclarative::KDeclarative kdeclarative;
    kdeclarative.setDeclarativeEngine(&engine);
    kdeclarative.setupContext();

    engine.rootContext()->setContextProperty("__context__initialPage", parser.value(QStringLiteral("page")));
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
