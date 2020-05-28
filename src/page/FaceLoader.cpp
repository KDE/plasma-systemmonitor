/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "FaceLoader.h"

#include <faces/SensorFaceController.h>

#include "PageDataObject.h"

FaceLoader::FaceLoader(QObject* parent)
    : QObject(parent)
{
}

PageDataObject * FaceLoader::dataObject() const
{
    return m_dataObject;
}

void FaceLoader::setDataObject(PageDataObject * newDataObject)
{
    if (newDataObject == m_dataObject) {
        return;
    }

    if (m_faceController) {
        m_faceController->deleteLater();
        m_faceController = nullptr;
    }

    m_dataObject = newDataObject;

    if (m_dataObject) {
        auto faceConfig = m_dataObject->value(QStringLiteral("face")).toString();
        qDebug() << faceConfig;
        if (faceConfig.isEmpty()) {
            faceConfig = QStringLiteral("Face-%1").arg(reinterpret_cast<quintptr>(this));
            m_dataObject->insert(QStringLiteral("face"), faceConfig);
            Q_EMIT m_dataObject->valueChanged(QStringLiteral("face"), faceConfig);
        }

        auto configGroup = m_dataObject->config()->group(faceConfig);
        qDebug() << configGroup.group("Sensors").readEntry("sensorIds");
        m_faceController = new KSysGuard::SensorFaceController(configGroup, qmlEngine(this));
        Q_EMIT controllerChanged();
    }

    Q_EMIT dataObjectChanged();
}

KSysGuard::SensorFaceController * FaceLoader::controller() const
{
    return m_faceController;
}
