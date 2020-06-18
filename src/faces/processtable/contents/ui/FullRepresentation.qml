/*
 *   Copyright 2019 Marco Martin <mart@kde.org>
 *   Copyright 2019 David Edmundson <davidedmundson@kde.org>
 *   Copyright 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.8 as Kirigami

import org.kde.ksysguard.sensors 1.0 as Sensors
import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.ksysguard.process 1.0 as Process

import org.kde.ksysguard.table 1.0 as Table

Faces.SensorFace {
    id: root

    readonly property var config: controller.faceConfiguration

    primaryActions: [
        Kirigami.Action {
            text: i18n("Search")
            displayComponent: Kirigami.SearchField {
                onTextEdited: table.nameFilterString = text;
                onAccepted: table.nameFilterString = text;
            }
        },

        Kirigami.Action {
            icon.name: "process-stop"
            text: i18n("End Process")
            onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            enabled: table.selection.hasSelection
        }
    ]

    secondaryActions: [
         Kirigami.Action {
            icon.name: "view-list-details"
            checkable: true
            checked: config.viewMode == mode
            text: i18n("Display as List")
            displayHint: Kirigami.Action.IconOnly
            property int mode: 0
            ActionGroup.group: viewGroup
        },

        Kirigami.Action {
            icon.name: "view-list-tree"
            checkable: true
            checked: config.viewMode == mode
            text: i18n("Display as Tree")
            displayHint: Kirigami.Action.IconOnly
            property int mode: 1
            enabled: false
            ActionGroup.group: viewGroup
        },

        Kirigami.Action {
            icon.name: showGroup.checkedAction.icon.name
            text: i18n("Show: %1", showGroup.checkedAction.text)

            Kirigami.Action {
                text: i18n("Own Processes")
                checkable: true
                checked: config.userFilterMode == mode
                icon.name: "view-process-own"
                property int mode: Table.UserMode.Own
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18n("User Processes")
                checkable: true
                checked: config.userFilterMode == mode
                icon.name: "view-process-users"
                property int mode: Table.UserMode.User
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18n("System Processes")
                checkable: true
                checked: config.userFilterMode == mode
                icon.name: "view-process-system"
                property int mode: Table.UserMode.System
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18n("All Processes")
                checkable: true
                checked: config.userFilterMode == mode
                icon.name: "view-process-all"
                property int mode: Table.UserMode.All
                ActionGroup.group: showGroup
            }
        },

        Kirigami.Action {
            id: configureColumnsAction
            icon.name: "configure"
            text: i18n("Configure columns...")
            onTriggered: columnDialog.open()
        }
    ]

    ActionGroup { id: showGroup }
    ActionGroup { id: viewGroup }

    contentItem: ProcessTableView {
        id: table

        viewMode: root.config.userFilterMode

        columnWidths: root.config.columnWidths
        sortName: root.config.sortColumn
        sortOrder: root.config.sortDirection

        onContextMenuRequested: {
            contextMenu.popup(null, position.x, position.y)
        }

        onHeaderContextMenuRequested: {
            headerContextMenu.popup(null, position)
        }

        enabledColumns: columnDialog.visibleColumns
        columnDisplay: columnDialog.columnDisplay
    }

    Menu {
        id: contextMenu

//         MenuItem { text: i18n("Set priority...") }
        Menu {
            title: i18n("Send Signal")

            MenuItem {
                text: i18n("Suspend (STOP)");
                onTriggered: processHelper.sendSignalToSelection(Proces.ProcessController.StopSignal)
            }
            MenuItem {
                text: i18n("Continue (CONT)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.ContinueSignal)
            }
            MenuItem {
                text: i18n("Hangup (HUP)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.HangupSignal)
            }
            MenuItem {
                text: i18n("Interrupt (INT)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.InterruptSignal)
            }
            MenuItem {
                text: i18n("Terminate (TERM)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            }
            MenuItem {
                text: i18n("Kill (KILL)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.KillSignal)
            }
            MenuItem {
                text: i18n("User 1 (USR1)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.User1Signal)
            }
            MenuItem {
                text: i18n("User 2 (USR2)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.User2Signal)
            }
        }
//         MenuItem { text: i18n("Show Application Window") }
        MenuSeparator { }
        MenuItem {
            icon.name: "process-stop";
            text: i18np("End Process", "End %1 Processes", killDialog.items.length);
            onTriggered: {
                processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            }

        }
    }

    Menu {
        id: headerContextMenu

        MenuItem {
            text: i18n("Configure Columns...")
            onClicked: columnDialog.open()
        }
    }

    Table.KillDialog {
        id: killDialog

        property int signalToSend

        x: root.width * 0.5 - width / 2
        y: table.headerHeight - Kirigami.Units.largeSpacing

        title: i18np("End Process", "End %1 Processes", items.length)
        killButtonText: i18n("End")
        killButtonIcon: "process-stop"
        questionText: i18np("Are you sure you want to end this process?\nAny unsaved work may be lost.",
                            "Are you sure you want to end these %1 processes?\nAny unsaved work may be lost.", items.length)

        items: table.selectedProcesses

        delegate: Kirigami.AbstractListItem {
            leftPadding: Kirigami.Units.gridUnit
            contentItem: Column {
                Label { text: modelData.name; width: parent.width; elide: Text.ElideRight }
                Label {
                    width: parent.width
                    text: i18n("Process ID %1, owned by %2", modelData.pid, modelData.username)
                    color: Kirigami.Theme.disabledTextColor
                    elide: Text.ElideRight
                }
            }
            highlighted: false
            hoverEnabled: false
        }

        onAccepted: {
            config.askWhenKillingProcesses = !killDialog.doNotAskAgain
            for (var i of items) {
                processHelper.sendSignal(i.pid, signalToSend)
            }
        }
    }

    Process.ProcessController {
        id: processHelper

        property var killSignals: [
            Process.ProcessController.TerminateSignal,
            Process.ProcessController.KillSignal
        ]

        function sendSignalToSelection(sig) {
            if (root.config.askWhenKillingProcesses && killSignals.includes(sig)) {
                killDialog.signalToSend = sig
                killDialog.open()
            } else {
                for (var i of table.selectedProcesses) {
                    sendSignal(i.pid, sig)
                }
            }
        }
    }

    Table.ColumnConfigurationDialog {
        id: columnDialog

        width: root.width * 0.75
        height: root.height * 0.75
        x: root.width * 0.125
        y: table.headerHeight - Kirigami.Units.smallSpacing

        sourceModel: table.processModel.attributesModel

        sortedColumns: root.config.sortedColumns

        onAccepted: {
            root.config.sortedColumns = sortedColumns
            root.config.columnDisplay = JSON.stringify(columnDisplay)
        }

        Component.onCompleted: {
            setColumnDisplay(JSON.parse(root.config.columnDisplay))
        }
    }

//     Configuration {
//         id: config
//
//         property int userFilterMode: showGroup.checkedAction.mode
//         property int viewMode: viewGroup.checkedAction.mode
//         property alias sortedProcessColumns: columnDialog.sortedColumns
//         property alias processColumnWidths: table.columnWidths
//         property alias processSortColumn: table.sortName
//         property alias processSortDirection: table.sortOrder
//
//         property string processColumnDisplay: JSON.stringify(columnDialog.columnDisplay)
//
//         property bool askWhenKillingProcesses
//
//         onConfigurationLoaded: columnDialog.setColumnDisplay(JSON.parse(config.processColumnDisplay))
//     }
}
