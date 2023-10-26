/*
 *   SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
 *   SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.faces as Faces
import org.kde.ksysguard.process as Process

import org.kde.ksysguard.table as Table

Faces.SensorFace {
    id: root

    readonly property var config: controller.faceConfiguration

    actions: [
        Kirigami.Action {
            icon.name: "search"
            text: i18nc("@action", "Search")
            displayHint: Kirigami.DisplayHint.KeepVisible
            displayComponent: Kirigami.SearchField {
                text: table.nameFilterString
                onTextEdited: table.nameFilterString = text;
                onAccepted: table.nameFilterString = text;
                Component.onCompleted: forceActiveFocus()
            }
        },

        Kirigami.Action {
            icon.name: "process-stop"
            text: i18nc("@action", "End Process")
            onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            enabled: table.selection.hasSelection
        },

        // Note: can't use ActionGroup there because of https://bugreports.qt.io/browse/QTBUG-86860
        Kirigami.Action {
            id: listAction
            icon.name: "view-list-details"
            checkable: true
            checked: root.config.viewMode === mode
            visible: table.treeModeSupported
            text: i18nc("@action", "Display as List")

            displayHint: Kirigami.DisplayHint.IconOnly
            property int mode: 0
            onTriggered: {
                root.config.viewMode = mode
                checked = true;
                treeAction.checked = false;
            }
        },

        Kirigami.Action {
            id: treeAction
            icon.name: "view-list-tree"
            checkable: true
            checked: root.config.viewMode === mode
            visible: table.treeModeSupported
            text: i18nc("@action", "Display as Tree")
            displayHint: Kirigami.DisplayHint.IconOnly
            property int mode: 1
            onTriggered: {
                root.config.viewMode = mode;
                checked = true;
                listAction.checked = false;
            }
        },

        Kirigami.Action {
            icon.name: showGroup.checkedAction.icon.name
            text: i18nc("@action %1 is view type", "Show: %1", showGroup.checkedAction.text)

            Kirigami.Action {
                text: i18nc("@item:inmenu", "Own Processes")
                checkable: true
                checked: root.config.userFilterMode == mode
                icon.name: "view-process-own"
                property int mode: Table.ProcessSortFilterModel.ViewOwn
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18nc("@item:inmenu", "User Processes")
                checkable: true
                checked: root.config.userFilterMode == mode
                icon.name: "view-process-users"
                property int mode: Table.ProcessSortFilterModel.ViewUser
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18nc("@item:inmenu", "System Processes")
                checkable: true
                checked: root.config.userFilterMode == mode
                icon.name: "view-process-system"
                property int mode: Table.ProcessSortFilterModel.ViewSystem
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18nc("@item:inmenu", "All Processes")
                checkable: true
                checked: root.config.userFilterMode == mode
                icon.name: "view-process-all"
                property int mode: Table.ProcessSortFilterModel.ViewAll
                ActionGroup.group: showGroup
            }
        },

        Kirigami.Action {
            id: configureColumnsAction
            icon.name: "configure"
            text: i18nc("@action", "Configure columns…")
            onTriggered: columnDialog.open()
        }
    ]

    ActionGroup { id: showGroup; onTriggered: root.config.userFilterMode = action.mode }

    contentItem: ProcessTableView {
        id: table

        flatList: root.config.viewMode === 0
        viewMode: root.config.userFilterMode
        onViewModeChanged: root.config.userFilterMode = viewMode

        columnWidths: root.config.columnWidths
        onColumnWidthsChanged: root.config.columnWidths = columnWidths
        sortName: root.config.sortColumn
        onSortNameChanged: root.config.sortColumn = sortName
        sortOrder: root.config.sortDirection
        onSortOrderChanged: root.config.sortDirection = sortOrder

        onContextMenuRequested: {
            contextMenu.popup(null, position.x, position.y)
        }

        onHeaderContextMenuRequested: {
            headerContextMenu.popup(null, position)
        }

        enabledColumns: columnDialog.visibleColumns
        columnDisplay: columnDialog.columnDisplay

        Keys.onPressed: event => {
            if (event.matches(StandardKey.Delete)) {
                processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal);
                event.accepted = true;
            } else if ((event.modifiers & Qt.ShiftModifier) && (event.key == Qt.Key_Delete)) {
                processHelper.sendSignalToSelection(Process.ProcessController.KillSignal);
                event.accepted = true;
            }
        }
    }

    Menu {
        id: contextMenu

//         MenuItem { text: i18n("Set priority...") }
        Menu {
            title: i18nc("@action:inmenu", "Send Signal")

            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Suspend (STOP)");
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.StopSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Continue (CONT)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.ContinueSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Hangup (HUP)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.HangupSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Interrupt (INT)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.InterruptSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu  Send Signal", "Terminate (TERM)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Kill (KILL)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.KillSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "User 1 (USR1)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.User1Signal)
            }
            MenuItem {
                text: i18nc("@action:inmenu  Send Signal", "User 2 (USR2)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.User2Signal)
            }
        }
//         MenuItem { text: i18nc("@action:inmenu", "Show Application Window") }
        MenuSeparator { }
        MenuItem {
            icon.name: "process-stop";
            text: i18ncp("@action:inmenu", "End Process", "End %1 Processes", killDialog.items.length);
            onTriggered: {
                processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            }

        }
    }

    Menu {
        id: headerContextMenu

        MenuItem {
            text: i18nc("@action:inmenu", "Configure Columns…")
            onClicked: columnDialog.open()
        }
    }

    Table.KillDialog {
        id: killDialog

        property int signalToSend

        title: i18ncp("@title:window", "End Process", "End %1 Processes", items.length)
        killButtonText: i18ncp("@action:button", "End Process", "End Processes", items.length)
        killButtonIcon: "process-stop"
        questionText: i18np("Are you sure you want to end this process?\nAny unsaved work may be lost.",
                            "Are you sure you want to end these %1 processes?\nAny unsaved work may be lost.", items.length)

        items: table.selectedProcesses

        delegate: Kirigami.Padding {
            horizontalPadding: Kirigami.Units.largeSpacing
            verticalPadding: Kirigami.Units.smallSpacing

            contentItem: Kirigami.TitleSubtitle {
                title: modelData.name
                subtitle: i18nc("@item:intable %1 is process id, %2 is user name", "Process ID %1, owned by %2", modelData.pid, modelData.username)
            }
        }

        onAccepted: {
            root.config.askWhenKilling = !killDialog.doNotAskAgain
            var pids = items.map(i => i.pid)
            processHelper.sendSignal(pids, signalToSend)
        }
    }

    Process.ProcessController {
        id: processHelper

        property var killSignals: [
            Process.ProcessController.TerminateSignal,
            Process.ProcessController.KillSignal
        ]

        function sendSignalToSelection(sig) {
            if (root.config.askWhenKilling && killSignals.includes(sig)) {
                killDialog.signalToSend = sig
                killDialog.open()
            } else {
                var pids = table.selectedProcesses.map(i => i.pid)
                sendSignal(pids, sig);
            }
        }
    }

    Table.ColumnConfigurationDialog {
        id: columnDialog

        sourceModel: table.processModel.attributesModel

        sortedColumns: root.config.sortedColumns

        fixedColumns: ["name"]

        onAccepted: {
            root.config.sortedColumns = sortedColumns
            root.config.columnDisplay = JSON.stringify(columnDisplay)
        }

        Component.onCompleted: {
            setColumnDisplay(JSON.parse(root.config.columnDisplay))
        }
    }
}
