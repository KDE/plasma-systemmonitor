import QtQuick 2.12
import QtQuick.Controls 2.12

import org.kde.ksgrd2 0.1 as KSysGuard
import org.kde.ksysguard.process 1.0 as Process
import org.kde.quickcharts 1.0 as Charts
import org.kde.kitemmodels 1.0 as KItemModels

import org.kde.ksysguardqml 1.0 as KSysGuardQML

import Qt.labs.qmlmodels 1.0

import "qrc:/components"

BaseTableView {
    id: view

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
            item.update()
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

    property var enabledColumns: []
    property alias columnDisplay: displayModel.columnDisplay

    property alias sourceModel: appModel

    idRole: "Attribute"

    columnWidths: [200, 100, 100, 100, 100]

    model: KItemModels.KSortFilterProxyModel {
        id: sortFilter

        sourceModel: cacheModel

        filterColumnCallback: function(column, parent) {
            // Note: This assumes cacheModel column == appModel column
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

    KSysGuardQML.ComponentCacheProxyModel {
        id: cacheModel
        sourceModel: displayModel

        component: Charts.ModelHistorySource {
            model: KSysGuardQML.ComponentCacheProxyModel.model
            row: KSysGuardQML.ComponentCacheProxyModel.row
            column: KSysGuardQML.ComponentCacheProxyModel.column
            roleName: "Value"
            maximumHistory: 10
            interval: 2000
        }
    }

    KSysGuardQML.ColumnDisplayModel {
        id: displayModel
        sourceModel: appModel
        idRole: "Attribute"
    }

    Process.ApplicationsDataModel {
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

        enabledAttributes: {
            var result = [].concat(view.enabledColumns)
            var hidden = []

            for (var i of requiredAttributes) {
                if (result.indexOf(i) == -1) {
                    result.push(i)
                    hidden.push(i)
                }
            }

            hiddenAttributes = hidden
            return result;
        }
    }

    delegate: DelegateChooser {
        DelegateChoice {
            column: 0;
            FirstCellDelegate {
                iconName: {
                    var index = sortFilter.mapToSource(sortFilter.index(model.row, 0))
                    index = appModel.index(index.row, appModel.iconColumn)
                    return appModel.data(index)
                }
            }
        }
        DelegateChoice {
            roleValue: "line"
            LineChartCellDelegate {
                valueSources: model.cachedComponent != undefined ? model.cachedComponent : []
                maximum: sortFilter.data(sortFilter.index(model.row, model.column), KSysGuard.ProcessDataModel.Maximum)
            }
        }
        DelegateChoice { BasicCellDelegate { } }
    }
}
