/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "PagePlugin.h"

#include "FaceLoader.h"
#include "FacesModel.h"
#include "PageDataModel.h"
#include "PageDataObject.h"
#include "PageSortModel.h"
#include "PagesModel.h"
#include "WidgetExporter.h"

#include <QQmlEngine>

void PagePlugin::registerTypes(const char *uri)
{
    Q_ASSERT(QLatin1String(uri) == QLatin1String("org.kde.ksysguard.page"));

    qmlRegisterType<PageDataModel>(uri, 1, 0, "PageDataModel");
    qmlRegisterType<PagesModel>(uri, 1, 0, "PagesModel");
    qmlRegisterType<FaceLoader>(uri, 1, 0, "FaceLoader");
    qmlRegisterType<PageSortModel>(uri, 1, 0, "PageSortModel");
    qmlRegisterType<FacesModel>(uri, 1, 0, "FacesModel");
    qmlRegisterSingletonType<WidgetExporter>(uri, 1, 0, "WidgetExporter", [](QQmlEngine *, QJSEngine *) {
        return new WidgetExporter();
    });

    qmlRegisterUncreatableType<PageDataObject>(uri, 1, 0, "PageDataObject", QStringLiteral("Used for data storage"));
}

#include "moc_PagePlugin.cpp"
