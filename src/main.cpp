/*
 * This file is part of KSysGuard.
 * Copyright 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QCommandLineParser>
#include <QQmlContext>

#include <KDeclarative/KDeclarative>

#include "ToolsModel.h"
#include "Configuration.h"

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("ksysguardqml"));
    app.setDesktopFileName(QStringLiteral("org.kde.ksysguardqml"));

    QCommandLineParser parser;
    parser.addOption({QStringLiteral("page"), QStringLiteral("The page to show."), QStringLiteral("page")});
    parser.addHelpOption();
    parser.process(app);

    qmlRegisterAnonymousType<QAbstractItemModel>("org.kde.ksysguardqml", 1);
    qmlRegisterType<ToolsModel>("org.kde.ksysguardqml", 1, 0, "ToolsModel");
    qmlRegisterType<Configuration>("org.kde.ksysguardqml", 1, 0, "Configuration");

    QQmlApplicationEngine engine;

    KDeclarative::KDeclarative kdeclarative;
    kdeclarative.setDeclarativeEngine(&engine);
    kdeclarative.setupContext();

    engine.rootContext()->setContextProperty("__context__initialPage", parser.value(QStringLiteral("page")));
    engine.load(QStringLiteral(":/main.qml"));

    return app.exec();
}
