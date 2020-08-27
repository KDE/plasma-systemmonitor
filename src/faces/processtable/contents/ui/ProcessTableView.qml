import QtQuick 2.12
import QtQuick.Controls 2.12

import Qt.labs.qmlmodels 1.0

import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.quickcharts 1.0 as Charts

import org.kde.ksysguard.formatter 1.0 as Formatter
import org.kde.ksysguard.process 1.0 as Process
import org.kde.ksysguard.table 1.0 as Table

Table.BaseTableView {
    id: view

    property alias nameFilterString: rowFilter.filterString
    property alias processModel: processModel
    property int viewMode: ProcessTableView.ViewMode.Own
    onViewModeChanged: rowFilter.invalidate()

    property alias columnDisplay: displayModel.columnDisplay
    property var enabledColumns
    onEnabledColumnsChanged: processModel.updateEnabledAttributes()

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

    model: Table.ComponentCacheProxyModel {
        id: cacheModel
        sourceModel: rowFilter

        component: Charts.ModelHistorySource {
            model: Table.ComponentCacheProxyModel.model
            row: Table.ComponentCacheProxyModel.row
            column: Table.ComponentCacheProxyModel.column
            roleName: "Value"
            maximumHistory: 10
            interval: 2000
        }

        function sort(column, order) {
            rowFilter.sort(column, order)
        }
    }

    Table.ProcessSortFilterModel {
        id: rowFilter
        sourceModel: displayModel
        uidColumn: processModel.uidColumn
        nameColumn: processModel.nameColumn
        hiddenAttributes: processModel.hiddenSensors
    }

    Table.ColumnDisplayModel {
        id: displayModel
        sourceModel: processModel
        idRole: "Attribute"
    }

    Process.ProcessDataModel {
        id: processModel

        property int nameColumn
        property int pidColumn
        property int uidColumn
        property int usernameColumn

        property var requiredSensors: [
            "name",
            "pid",
            "uid",
            "username"
        ]
        property var hiddenSensors: []

        enabled: view.visible

        function updateEnabledAttributes() {
            var result = []
            for (let i of view.enabledColumns) {
                if (processModel.availableAttributes.includes(i)) {
                    result.push(i)
                }
            }

            var hidden = []
            for (let i of requiredSensors) {
                if (result.indexOf(i) == -1 && processModel.availableAttributes.includes(i)) {
                    result.push(i)
                    hidden.push(i)
                }
            }

            processModel.nameColumn = result.indexOf("name")
            processModel.pidColumn = result.indexOf("pid")
            processModel.uidColumn = result.indexOf("uid")
            processModel.usernameColumn = result.indexOf("username")
            processModel.hiddenSensors = hidden
            processModel.enabledAttributes = result
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
        DelegateChoice {
            roleValue: "lineScaled"
            Table.LineChartCellDelegate {
                valueSources: model.cachedComponent != undefined ? model.cachedComponent : []
                maximum: rowFilter.data(rowFilter.index(model.row, model.column), Process.ProcessDataModel.Maximum)
                text: Formatter.Formatter.formatValue(parseInt(model.Value) / model.Maximum * 100, model.Unit)
            }

        }
        DelegateChoice {
            roleValue: "textScaled"
            Table.BasicCellDelegate {
                text: Formatter.Formatter.formatValue(parseInt(model.Value) / model.Maximum * 100, model.Unit)
            }
        }
        DelegateChoice { Table.BasicCellDelegate{} }
    }
}
