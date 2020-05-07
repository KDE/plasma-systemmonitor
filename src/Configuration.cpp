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

#include "Configuration.h"

#include <QDebug>
#include <QMetaProperty>

#include "Config.h"

Config *Configuration::m_config = nullptr;

Configuration::Configuration(QObject* parent)
    : QObject(parent)
{
    if (!m_config) {
        m_config = new Config();
    }

    m_saveTimer = std::make_unique<QTimer>();
    m_saveTimer->setInterval(500);
    m_saveTimer->setSingleShot(true);
    connect(m_saveTimer.get(), &QTimer::timeout, m_config, &Config::save);
}

void Configuration::propertyChanged()
{
    auto signal = metaObject()->method(senderSignalIndex());
    // Strip "Changed" from the signal name to get property name
    auto propertyName = signal.name().chopped(7);
    auto property = metaObject()->property(metaObject()->indexOfProperty(propertyName));

    if (property.isValid()) {
        m_config->setProperty(property.name(), property.read(this));
        m_saveTimer->start();
    } else {
        qWarning() << "Property" << propertyName << "was not found!";
    }
}

void Configuration::classBegin()
{
}

void Configuration::componentComplete()
{
    if (!m_config) {
        return;
    }

    auto propertyChangedMethod = metaObject()->method(metaObject()->indexOfMethod("propertyChanged()"));

    for (auto i = 0; i < metaObject()->propertyCount(); ++i) {
        auto property = metaObject()->property(i);

        if (property.name() == QStringLiteral("config")) {
            continue;
        }

        if (m_config->metaObject()->indexOfProperty(property.name()) == -1) {
            qWarning() << "Property" << property.name() << "not found in configuration, ignoring";
            continue;
        }

        property.write(this, m_config->property(property.name()));

        if (property.hasNotifySignal()) {
            connect(this, property.notifySignal(), this, propertyChangedMethod);
        } else {
            qWarning() << "Property" << property.name() << "is not notifiable!";
        }
    }

    Q_EMIT configurationLoaded();
}
