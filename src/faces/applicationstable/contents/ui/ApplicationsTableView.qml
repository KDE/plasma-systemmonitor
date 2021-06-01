/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.12
import QtQuick.Controls 2.12

import Qt.labs.qmlmodels 1.0

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.quickcharts 1.0 as Charts

import org.kde.ksysguard.formatter 1.0 as Formatter
import org.kde.ksysguard.process 1.0 as Process
import org.kde.ksysguard.table 1.0 as Table

Table.BaseTableView {
    id: view

    Kirigami.PlaceholderMessage {
        visible: !appModel.available
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        icon.name: "action-unavailable-symbolic"
        text: i18nc("Warning message shown on runtime error", "Applications view is unsupported on your system");
    }

    property var enabledColumns: []
    property alias columnDisplay: displayModel.columnDisplay
    property alias sourceModel: appModel

    property alias filterString: sortFilter.filterString

    property var selectedApplications: {
        var result = []
        var rows = {}

        for (var i of selection.selectedIndexes) {
            if (rows[i.row] != undefined) {
                continue
            }
            rows[i.row] = true

            var index = sortFilter.mapToSource(i)
            var item = applicationInformation.createObject()
            item.index = index
            result.push(item)
        }

        return result
    }

    property Component applicationInformation: ApplicationInformation {
        model: appModel
        sensorColumns: {
            "name": appModel.enabledAttributes.indexOf("appName"),
            "cpu": appModel.enabledAttributes.indexOf("usage"),
            "memory": appModel.enabledAttributes.indexOf("vmPSS"),
            "netInbound": appModel.enabledAttributes.indexOf("netInbound"),
            "netOutbound": appModel.enabledAttributes.indexOf("netOutbound"),
            "diskRead": appModel.enabledAttributes.indexOf("ioCharactersActuallyReadRate"),
            "diskWrite": appModel.enabledAttributes.indexOf("ioCharactersActuallyWrittenRate"),
            "iconName": appModel.enabledAttributes.indexOf("iconName")
        }
        role: Process.ProcessDataModel.Value
        pidsRole: Process.ProcessDataModel.PIDs
    }

    idRole: "Attribute"

    columnWidths: [200, 100, 100, 100, 100]

    onSort: {
        sortFilter.sortColumn = column
        sortFilter.sortOrder = order
    }

    headerModel: sortFilter

    model: KItemModels.KSortFilterProxyModel {
        id: sortFilter

        sourceModel: cacheModel

        filterColumnCallback: function(column, parent) {
            // Note: This assumes displayModel column == appModel column
            // This may not always hold, but we get incorrect results if we try to
            // map to source indices when the model is empty.
            var sensorId = appModel.enabledAttributes[column]
            if (appModel.hiddenAttributes.indexOf(sensorId) != -1) {
                return false
            }
            return true
        }

        filterKeyColumn: appModel.nameColumn
        filterCaseSensitivity: Qt.CaseInsensitive
        sortRole: "Value"
    }

    Table.ComponentCacheProxyModel {
        id: cacheModel
        sourceModel: displayModel

        component: Charts.HistoryProxySource {
            id: history
            source: Charts.ModelSource {
                model: history.Table.ComponentCacheProxyModel.model
                column: history.Table.ComponentCacheProxyModel.column
                roleName: "Value"
            }
            item: Table.ComponentCacheProxyModel.row
            maximumHistory: 10
            interval: 2000
            fillMode: Charts.HistoryProxySource.FillFromEnd
        }
    }

    Table.ColumnDisplayModel {
        id: displayModel
        sourceModel: appModel
        idRole: "Attribute"
    }

    Process.ApplicationDataModel {
        id: appModel

        property int nameColumn: enabledAttributes.indexOf("appName")
        property int iconColumn: enabledAttributes.indexOf("iconName")

        property var requiredAttributes: [
            "iconName",
            "appName",
            "usage",
            "vmPSS",
            "netInbound",
            "netOutbound",
            "ioCharactersActuallyReadRate",
            "ioCharactersActuallyWrittenRate",
        ]
        property var hiddenAttributes: []

        enabled: view.visible

        enabledAttributes: {
            var result = []
            for (let i of view.enabledColumns) {
                if (appModel.availableAttributes.includes(i)) {
                    result.push(i)
                }
            }

            var hidden = []
            for (let i of requiredAttributes) {
                if (result.indexOf(i) == -1) {
                    result.push(i)
                    hidden.push(i)
                }
            }

            hiddenAttributes = hidden
            return result;
        }

        Component.onCompleted: {
            if (!available) {
                console.error("Implementation matching https://systemd.io/DESKTOP_ENVIRONMENTS/ was not found. ApplicationsView will not be available")
            }
        }
    }

    delegate: DelegateChooser {
        role: "displayStyle"
        DelegateChoice {
            column: view.LayoutMirroring.enabled ? view.model.columnCount() - 1 : 0
            Table.FirstCellDelegate {
                iconName: {
                    var index = sortFilter.mapToSource(sortFilter.index(model.row, 0))
                    index = appModel.index(index.row, appModel.iconColumn)
                    return appModel.data(index)
                    return ""
                }
            }
        }
        DelegateChoice {
            roleValue: "line"
            Table.LineChartCellDelegate {
                valueSources: model.cachedComponent != undefined ? model.cachedComponent : []
                maximum: sortFilter.data(sortFilter.index(model.row, model.column), Process.ProcessDataModel.Maximum)
            }
        }
        DelegateChoice {
            roleValue: "lineScaled"
            Table.LineChartCellDelegate {
                valueSources: model.cachedComponent != undefined ? model.cachedComponent : []
                maximum: sortFilter.data(sortFilter.index(model.row, model.column), Process.ProcessDataModel.Maximum)
                text: Formatter.Formatter.formatValue(parseInt(model.Value) / model.Maximum * 100, model.Unit)
            }

        }
        DelegateChoice {
            roleValue: "textScaled"
            Table.TextCellDelegate {
                text: Formatter.Formatter.formatValue(parseInt(model.Value) / model.Maximum * 100, model.Unit)
            }
        }
        DelegateChoice { Table.TextCellDelegate { } }
    }
}
