/*
 * SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.faces as Faces
import org.kde.ksysguard.process as Process

import org.kde.ksysguard.table as Table

Faces.SensorFace {
    id: root
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Layout.minimumWidth: Kirigami.Units.gridUnit * 5

    readonly property var config: controller.faceConfiguration

    readonly property bool quitEnabled: {
        for (let info of table.selectedApplications) {
            if (info.menuId == "session.slice" || info.menuId == "background.slice" || info.menuId == "services") {
                return false
            }
        }
        return true
    }

    actions: [
        Kirigami.Action {
            icon.name: "search"
            text: i18nc("@action", "Search")
            displayHint: Kirigami.DisplayHint.KeepVisible
            displayComponent: Kirigami.SearchField {
                text: table.filterString
                onTextEdited: table.filterString = text;
                onAccepted: table.filterString = text;
                Component.onCompleted: forceActiveFocus()
            }
        },
        Kirigami.Action {
            icon.name: "application-exit"
            text: i18nc("@action", "Quit Application")
            displayHint: Kirigami.DisplayHint.KeepVisible
            onTriggered: processHelper.sendSignalToSelection(Process.Signal.TerminateSignal)
            enabled: table.selection.hasSelection && root.quitEnabled
        },
        Kirigami.Action {
            id: showDetailsAction
            icon.name: "documentinfo"
            text: i18nc("@action", "Show Details Sidebar")
            checkable: true
            checked: root.config.showDetails
            onToggled: root.config.showDetails = checked
        },
        Kirigami.Action {
            id: configureColumnsAction
            icon.name: "configure"
            text: i18nc("@action", "Configure Columns…")
            displayHint: Kirigami.DisplayHint.AlwaysHide
            onTriggered: columnDialog.open()
        }
    ]

    contentItem: Item {
        Layout.minimumHeight: table.Layout.minimumHeight

        ToolBar {
            id: toolbar

            anchors {
                left: parent.left
                right: splitter.right
                top: parent.top
            }
            height: visible ? undefined : 0
            visible: root.controller.showTitle || root.config.showToolBar

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Button

            RowLayout {
                anchors.fill: parent

                Kirigami.Heading {
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    level: 2
                    text: root.controller.title
                    visible: root.controller.showTitle
                }

                Kirigami.ActionToolBar {
                    Layout.fillWidth: true
                    actions: root.actions
                    alignment: Qt.AlignRight
                    visible: root.config.showToolBar
                }
            }

            background: Rectangle {
                color: Kirigami.Theme.backgroundColor

                Kirigami.Separator {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                }
            }
        }

        ApplicationsTableView {
            id: table

            anchors {
                left: parent.left
                right: splitter.right
                top: toolbar.bottom
                bottom: parent.bottom
            }

            onContextMenuRequested: (index, position) => {
                const pos = mapFromItem(null, position)
                contextMenu.popup(table, Math.round(pos.x), Math.round(pos.y))
            }

            onHeaderContextMenuRequested: (column, columnId, position) => {
                headerContextMenu.columnId = columnId;
                const pos = mapFromItem(null, position)
                headerContextMenu.popup(table, Math.round(pos.x), Math.round(pos.y))
            }

            enabledColumns: columnDialog.sortedColumns
            columnDisplay: columnDialog.columnDisplay

            columnWidths: root.config.columnWidths
            onColumnWidthsChanged: root.config.columnWidths = columnWidths
            sortName: root.config.sortColumn
            onSortNameChanged: root.config.sortColumn = sortName
            sortOrder: root.config.sortDirection
            onSortOrderChanged: root.config.sortDirection = sortOrder

            Keys.onPressed: event => {
                if (!root.quitEnabled) {
                    return
                }

                if (event.matches(StandardKey.Delete)) {
                    processHelper.sendSignalToSelection(Process.Signal.TerminateSignal);
                    event.accepted = true;
                } else if ((event.modifiers & Qt.ShiftModifier) && (event.key == Qt.Key_Delete)) {
                    processHelper.sendSignalToSelection(Process.Signal.KillSignal);
                    event.accepted = true;
                } else if (event.key == Qt.Key_F8) {
                    processHelper.reniceSelection();
                    event.accepted = true;
                }
            }
        }

        Kirigami.Separator {
            id: splitter
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: details.left
            }

            z: 10
            enabled: root.config.showDetails
            visible: enabled

            Kirigami.Separator {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.smallSpacing
                height: Kirigami.Units.gridUnit
                width: 1
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Kirigami.Units.largeSpacing
                cursorShape: enabled ? Qt.SplitHCursor : undefined
                drag.target: this

                property real startX

                onPressed: mouse => {
                    startX = mouse.x
                }

                onPositionChanged: mouse => {
                    const change = LayoutMirroring.enabled ? startX - mouse.x : mouse.x - startX
                    const newWidth = details.width - change
                    if (newWidth > details.minimumWidth && newWidth < details.maximumWidth) {
                        details.width += -change
                    }
                }
            }
        }

        Loader {
            id: details

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right

            property real minimumWidth: Kirigami.Units.gridUnit * 8
            property real maximumWidth: root.width * 0.75

            width: root.config.detailsWidth
            onWidthChanged: root.config.detailsWidth = width

            active: root.config.showDetails

            state: root.config.showDetails ? "" : "closed"

            states: State {
                name: "closed"
                PropertyChanges { target: details; anchors.rightMargin: -width ; visible: false; enabled: false }
            }
            transitions: Transition {
                SequentialAnimation {
                    NumberAnimation { properties: "x"; duration: Kirigami.Units.shortDuration }
                    PropertyAction { property: "visible" }
                }
            }

            sourceComponent: Component {
                ApplicationDetails {
                    headerHeight: table.headerHeight
                    onClose: root.config.showDetails = false
                    applications: table.selectedApplications
                }
            }
        }
    }

    Menu {
        id: contextMenu

        modal: true

        MenuItem {
            text: i18nc("@action:inmenu", "Set priority…")
            icon.name: "process-working-symbolic"
            onTriggered: processHelper.reniceSelection()
            enabled: root.quitEnabled
        }

        Menu {
            title: i18nc("@action:inmenu", "Send Signal")
            icon.name: "send_signal-symbolic"
            enabled: root.quitEnabled

            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Suspend (STOP)");
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.StopSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Continue (CONT)")
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.ContinueSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Hangup (HUP)")
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.HangupSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Interrupt (INT)")
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.InterruptSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Terminate (TERM)")
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.TerminateSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "Kill (KILL)")
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.KillSignal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "User 1 (USR1)")
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.User1Signal)
            }
            MenuItem {
                text: i18nc("@action:inmenu Send Signal", "User 2 (USR2)")
                onTriggered: processHelper.sendSignalToSelection(Process.Signal.User2Signal)
            }
        }
        MenuSeparator { }
        MenuItem {
            icon.name: "application-exit";
            enabled: root.quitEnabled
            text: i18ncp("@action:inmenu", "Quit Application", "Quit %1 Applications", killDialog.items.length);
            onTriggered: processHelper.sendSignalToSelection(Process.Signal.TerminateSignal)
        }
    }

    Menu {
        id: headerContextMenu
        property string columnId

        MenuItem {
            text: i18nc("@action:inmenu hide column", "Hide")
            icon.name: "hide_table_column"
            onClicked: columnDialog.hideColumn(headerContextMenu.columnId)
        }
        MenuItem {
            action: configureColumnsAction
        }
    }

    Table.KillDialog {
        id: killDialog

        property int signalToSend

        title: signalToSend === Process.Signal.KillSignal
               ? i18ncp("@title:window", "Force Quit Application", "Force Quit %1 Applications", items.length)
               : i18ncp("@title:window", "Quit Application", "Quit %1 Applications", items.length)
        killButtonText: signalToSend === Process.Signal.KillSignal
               ? i18ncp("@action:button", "Force Quit Application", "Force Quit Applications", items.length)
               : i18ncp("@action:button", "Quit Application", "Quit Applications", items.length)
        killButtonIcon: "application-exit"
        questionText: signalToSend === Process.Signal.KillSignal
                      ? i18np("Force quit (SIGKILL) the application? Unsaved work may be lost.",
                              "Force quit (SIGKILL) these %1 applications Unsaved work may be lost.",
                              items.length)
                      : i18np("Quit this application? Unsaved work may be lost.",
                              "Quit these %1 applications? Unsaved work may be lost.",
                              items.length)

        items: table.selectedApplications

        delegate: Kirigami.Padding {
            horizontalPadding: Kirigami.Units.largeSpacing
            verticalPadding: Kirigami.Units.smallSpacing

            contentItem: Kirigami.IconTitleSubtitle {
                icon.name: modelData.iconName
                icon.width: Kirigami.Units.iconSizes.large
                icon.height: Kirigami.Units.iconSizes.large
                title: modelData.name
                subtitle: i18ncp("@item:intable", "%1 Process", "%1 Processes", modelData.pids.length)
            }
        }

        onAccepted: {
            root.config.askWhenKilling = !killDialog.doNotAskAgain

            for (var i in table.selectedApplications) {
                processHelper.sendSignal(table.selectedApplications[i].pids, killDialog.signalToSend);
            }
        }
    }

    Table.ReniceDialog {
        id: reniceDialog

        onAccepted: {
            const niceValue = 20 - cpuPriority
            for (var i in table.selectedApplications) {
                processHelper.setPriority(table.selectedApplications[i].pids, niceValue)
                processHelper.setCpuScheduler(table.selectedApplications[i].pids, cpuMode, niceValue)
                processHelper.setIoScheduler(table.selectedApplications[i].pids, ioMode, ioPriority)
            }
        }
    }

    Process.ProcessController {
        id: processHelper

        window: root.Window.window

        readonly property var killSignals: [
            Process.Signal.TerminateSignal,
            Process.Signal.KillSignal
        ]

        function sendSignalToSelection(sig) {
            if (table.selectedApplications.length == 0) {
                return
            }

            if (root.config.askWhenKilling && killSignals.includes(sig)) {
                killDialog.signalToSend = sig
                killDialog.open()
                return
            }

            for (var i in table.selectedApplications) {
                sendSignal(table.selectedApplications[i].pids, sig);
            }
        }

        function reniceSelection() {
            if (table.selectedApplications.length == 0) {
                return
            }

            let pids = table.selectedApplications.reduce((acc, val) => acc.concat(val.pids), [])

            reniceDialog.cpuPriority = 20 - (processHelper.priority(pids) ?? 20)
            reniceDialog.cpuMode = processHelper.cpuScheduler(pids) ?? 0
            reniceDialog.ioPriority = processHelper.ioPriority(pids) ?? 0
            reniceDialog.ioMode = processHelper.ioScheduler(pids) ?? 0

            reniceDialog.open()
        }
    }

    Table.ColumnConfigurationDialog {
        id: columnDialog

        parent: root.Window.window?.overlay

        sourceModel: table.sourceModel.attributesModel

        sortedColumns: root.config.sortedColumns

        nameAttribute: "appName"

        onAccepted: {
            root.config.sortedColumns = sortedColumns
            root.config.columnDisplay = JSON.stringify(columnDisplay)
        }

        Component.onCompleted: {
            setColumnDisplay(JSON.parse(root.config.columnDisplay))
        }
    }
}
