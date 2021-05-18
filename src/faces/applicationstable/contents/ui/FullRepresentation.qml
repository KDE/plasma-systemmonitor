/*
 * SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
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
            icon.name: "search"
            text: i18nc("@action", "Search")
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
            onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            enabled: table.selection.hasSelection
        }
    ]

    secondaryActions: [
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
            text: i18nc("@action", "Configure columns...")
            onTriggered: columnDialog.open()
        }
    ]

    contentItem: Item {
        Layout.minimumHeight: table.Layout.minimumHeight

        ApplicationsTableView {
            id: table

            anchors {
                left: parent.left
                right: splitter.right
                top: parent.top
                bottom: parent.bottom
            }

            onContextMenuRequested: {
                contextMenu.popup(null, position.x, position.y)
            }

            onHeaderContextMenuRequested: {
                headerContextMenu.popup(null, position)
            }

            enabledColumns: columnDialog.visibleColumns
            columnDisplay: columnDialog.columnDisplay

            columnWidths: root.config.columnWidths
            onColumnWidthsChanged: root.config.columnWidths = columnWidths
            sortName: root.config.sortColumn
            onSortNameChanged: root.config.sortColumn = sortName
            sortOrder: root.config.sortDirection
            onSortOrderChanged: root.config.sortDirection = sortOrder

            Keys.onPressed: {
                if (event.matches(StandardKey.Delete)) {
                    processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal);
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

                onPressed: startX = mouse.x

                onPositionChanged: {
                    var change = LayoutMirroring.enabled ? startX - mouse.x : mouse.x - startX
                    var newWidth = details.width - change
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

            property real minimumWidth: 150
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

        MenuItem { text: i18nc("@action:inmenu", "Set priority..."); enabled: false }

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
                text: i18nc("@action:inmenu Send Signal", "Terminate (TERM)")
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
                text: i18nc("@action:inmenu Send Signal", "User 2 (USR2)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.User2Signal)
            }
        }
        MenuSeparator { }
        MenuItem {
            icon.name: "application-exit";
            text: i18ncp("@action:inmenu", "Quit Application", "Quit %1 Applications", killDialog.items.length);
            onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
        }
    }

    Menu {
        id: headerContextMenu

        MenuItem {
            action: configureColumnsAction
        }
    }

    Table.KillDialog {
        id: killDialog

        property int signalToSend

        title: i18ncp("@title:window", "Quit Application", "Quit %1 Applications", items.length)
        killButtonText: i18nc("@action:button", "Quit")
        killButtonIcon: "application-exit"
        questionText: i18np("Are you sure you want to quit this application?\nAny unsaved work may be lost.",
                            "Are you sure you want to quit these %1 applications?\nAny unsaved work may be lost.", items.length)

        items: table.selectedApplications

        delegate: Kirigami.BasicListItem {
            icon: modelData.iconName
            iconSize:  Kirigami.Units.iconSizes.large
            label: modelData.name
            subtitle: i18ncp("@item:intable", "%1 Process", "%1 Processes", modelData.pids.length)
            highlighted: false
            hoverEnabled: false
        }

        onAccepted: {
            root.config.askWhenKilling = !killDialog.doNotAskAgain

            for (var i in table.selectedApplications) {
                processHelper.sendSignal(table.selectedApplications[i].pids, killDialog.signalToSend);
            }
        }
    }

    Process.ProcessController {
        id: processHelper

        readonly property var killSignals: [
            Process.ProcessController.TerminateSignal,
            Process.ProcessController.KillSignal
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
    }

    Table.ColumnConfigurationDialog {
        id: columnDialog

        sourceModel: table.sourceModel.attributesModel

        sortedColumns: root.config.sortedColumns

        fixedColumns: ["appName"]

        onAccepted: {
            root.config.sortedColumns = sortedColumns
            root.config.columnDisplay = JSON.stringify(columnDisplay)
        }

        Component.onCompleted: {
            setColumnDisplay(JSON.parse(root.config.columnDisplay))
        }
    }
}
