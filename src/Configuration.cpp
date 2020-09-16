/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
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
