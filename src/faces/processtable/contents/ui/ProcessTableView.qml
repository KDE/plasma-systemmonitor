import QtQuick 2.12
import QtQuick.Controls 2.12

import Qt.labs.qmlmodels 1.0

import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.quickcharts 1.0 as Charts

import org.kde.ksysguard.process 1.0 as Process
import org.kde.ksysguard.table 1.0 as Table

Table.BaseTableView {
    id: view

    enum ViewMode {
        Own,
        User,
        System,
        All
    }

    property string nameFilterString
    onNameFilterStringChanged: rowFilter.invalidate()
    property alias processModel: processModel
    property int viewMode: ProcessTableView.ViewMode.Own
    onViewModeChanged: rowFilter.invalidate()

    property var enabledColumns
    property alias columnDisplay: displayModel.columnDisplay

    readonly property var selectedProcesses: {
        var result = []
        var rows = {}

        for (var i of selection.selectedIndexes) {
            if (rows[i.row] != undefined) {
                continue
            }

            rows[i.row] = true

            var index = rowFilter.mapToSource(i)
            var item = {}

            item.name = processModel.data(processModel.index(index.row, processModel.nameColumn), Process.ProcessDataModel.ValueRole)
            item.pid = processModel.data(processModel.index(index.row, processModel.pidColumn), Process.ProcessDataModel.ValueRole)
            item.username = processModel.data(processModel.index(index.row, processModel.usernameColumn), Process.ProcessDataModel.ValueRole)

            result.push(item)
        }

        return result
    }

    idRole: "Attribute"

    model: KItemModels.KSortFilterProxyModel {
        id: rowFilter

        sourceModel: cacheModel

        filterRowCallback: function(row, role) {
            var result = true
            var uid = processModel.data(processModel.index(row, processModel.uidColumn))

            switch(view.viewMode) {
                case ProcessTableView.ViewMode.Own:
                    result = loggedInUser.loginName == processModel.data(processModel.index(row, processModel.usernameColumn))
                    break
                case ProcessTableView.ViewMode.User:
                    result = uid >= 1000 && uid < 65534
                    break
                case ProcessTableView.ViewMode.System:
                    result = uid < 1000 || uid >= 65534
                    break
                default:
                    break
            }

            if (result && view.nameFilterString != "") {
                result = processModel.data(processModel.index(row, processModel.nameColumn)).includes(view.nameFilterString)
            }

            return result
        }

        filterColumnCallback: function(column, role) {
            var sensorId = processModel.enabledAttributes[column]
            if (processModel.hiddenSensors.indexOf(sensorId) != -1) {
                return false
            }
            return true
        }

        sortRole: "Value"
    }

    Table.ComponentCacheProxyModel {
        id: cacheModel
        sourceModel: displayModel

        component: Charts.ModelHistorySource {
            model: Table.ComponentCacheProxyModel.model
            row: Table.ComponentCacheProxyModel.row
            column: Table.ComponentCacheProxyModel.column
            roleName: "Value"
            maximumHistory: 10
            interval: 2000
        }
    }

    Table.ColumnDisplayModel {
        id: displayModel
        sourceModel: processModel
        idRole: "Attribute"
    }

    Process.ProcessDataModel {
        id: processModel

        property int nameColumn: enabledAttributes.indexOf("name")
        property int pidColumn: enabledAttributes.indexOf("pid")
        property int iconColumn: enabledAttributes.indexOf("iconName")
        property int uidColumn: enabledAttributes.indexOf("uid")
        property int usernameColumn: enabledAttributes.indexOf("username")

        property var requiredSensors: [
            "name",
            "pid",
            "iconName",
            "uid",
            "username"
        ]
        property var hiddenSensors: []

        enabled: view.visible

        enabledAttributes: {
            var result = [].concat(view.enabledColumns)
            var hidden = []

            for (var i of requiredSensors) {
                if (result.indexOf(i) == -1) {
                    result.push(i)
                    hidden.push(i)
                }
            }

            hiddenSensors = hidden
            return result
        }
    }

    delegate: DelegateChooser {
        role: "displayStyle"
        DelegateChoice {
            column: 0;
            Table.FirstCellDelegate {
                iconName: {
                    var index = rowFilter.mapToSource(rowFilter.index(model.row, 0))
                    index = processModel.index(index.row, processModel.nameColumn)
                    return processModel.data(index)
                }
            }
        }
        DelegateChoice {
            roleValue: "line"
            Table.LineChartCellDelegate {
                valueSources: model.cachedComponent != undefined ? model.cachedComponent : []
                maximum: rowFilter.data(rowFilter.index(model.row, model.column), Process.ProcessDataModel.Maximum)
            }
        }
        DelegateChoice { Table.BasicCellDelegate { } }
    }

    KCoreAddons.KUser { id: loggedInUser }
}
