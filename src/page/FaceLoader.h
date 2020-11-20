/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#pragma once

#include <QObject>

class PageDataObject;
class QQuickItem;

namespace KSysGuard { class SensorFaceController; }

class FaceLoader : public QObject
{
    Q_OBJECT
    Q_PROPERTY(PageDataObject *dataObject READ dataObject WRITE setDataObject NOTIFY dataObjectChanged)
    Q_PROPERTY(KSysGuard::SensorFaceController *controller READ controller NOTIFY controllerChanged)

public:
    FaceLoader(QObject *parent = nullptr);

    PageDataObject *dataObject() const;
    void setDataObject(PageDataObject *newDataObject);
    Q_SIGNAL void dataObjectChanged();

    KSysGuard::SensorFaceController *controller() const;
    Q_SIGNAL void controllerChanged();

    void reset();
    void save();

private:
    PageDataObject *m_dataObject = nullptr;
    KSysGuard::SensorFaceController *m_faceController = nullptr;
    KSysGuard::SensorFaceController *m_oldController = nullptr;

    static QHash<QString, KSysGuard::SensorFaceController *> s_faceCache;
};
