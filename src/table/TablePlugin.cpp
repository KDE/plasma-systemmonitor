/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "TablePlugin.h"

#include <QQmlEngine>

#include "ColumnDisplayModel.h"
#include "ColumnSortModel.h"
#include "ComponentCacheProxyModel.h"
#include "ProcessSortFilterModel.h"

void TablePlugin::registerTypes(const char *uri)
{
    Q_ASSERT(QLatin1String(uri) == QLatin1String("org.kde.ksysguard.table"));

    qmlRegisterType<ColumnSortModel>(uri, 1, 0, "ColumnSortModel");
    qmlRegisterType<ColumnDisplayModel>(uri, 1, 0, "ColumnDisplayModel");
    qmlRegisterType<ComponentCacheProxyModel>(uri, 1, 0, "ComponentCacheProxyModel");
    qmlRegisterType<ProcessSortFilterModel>(uri, 1, 0, "ProcessSortFilterModel");
}
