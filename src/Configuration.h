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

#ifndef CONFIGWRITER_H
#define CONFIGWRITER_H

#include <memory>

#include <QObject>
#include <QQmlParserStatus>
#include <QTimer>

#include "Config.h"

/**
 * Wraps Config in an API similar to Qt.labs.settings
 *
 * This object should be used from QML. Any custom properties declared on the
 * QML instance will be forwarded from and to the KConfig based configuration
 * class.
 */
class Configuration : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

public:
    explicit Configuration(QObject *parent = nullptr);

    Q_SLOT void propertyChanged();

    Q_SIGNAL void configurationLoaded();

    void classBegin() override;
    void componentComplete() override;

private:
    std::unique_ptr<QTimer> m_saveTimer;
    static Config *m_config;
};

#endif // CONFIGWRITER_H
