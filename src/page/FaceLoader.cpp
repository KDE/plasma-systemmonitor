/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "FaceLoader.h"

#include <faces/SensorFaceController.h>

#include "PageDataObject.h"

using namespace KSysGuard;

QHash<QString, KSysGuard::SensorFaceController *> FaceLoader::s_faceCache;

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
        if (faceConfig.isEmpty()) {
            faceConfig = QStringLiteral("Face-%1").arg(reinterpret_cast<quintptr>(this));
            m_dataObject->insert(QStringLiteral("face"), faceConfig);
            Q_EMIT m_dataObject->valueChanged(QStringLiteral("face"), faceConfig);
        }

        if (s_faceCache.contains(faceConfig)) {
            m_faceController = s_faceCache.value(faceConfig);
            return;
        }

        auto configGroup = m_dataObject->config()->group(faceConfig);
        m_faceController = new SensorFaceController(configGroup, qmlEngine(this));
        connect(m_faceController, &SensorFaceController::faceIdChanged, m_dataObject, &PageDataObject::markDirty);
        connect(m_faceController, &SensorFaceController::titleChanged, m_dataObject, &PageDataObject::markDirty);
        connect(m_faceController, &SensorFaceController::totalSensorsChanged, m_dataObject, &PageDataObject::markDirty);
        connect(m_faceController, &SensorFaceController::highPrioritySensorIdsChanged, m_dataObject, &PageDataObject::markDirty);
        connect(m_faceController, &SensorFaceController::lowPrioritySensorIdsChanged, m_dataObject, &PageDataObject::markDirty);
        connect(m_faceController, &SensorFaceController::sensorColorsChanged, m_dataObject, &PageDataObject::markDirty);

        s_faceCache.insert(faceConfig, m_faceController);

        Q_EMIT controllerChanged();
    }

    Q_EMIT dataObjectChanged();
}

SensorFaceController * FaceLoader::controller() const
{
    return m_faceController;
}
