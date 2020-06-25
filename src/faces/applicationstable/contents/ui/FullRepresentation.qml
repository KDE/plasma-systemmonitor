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
                onTextEdited: table.filterString = text;
                onAccepted: table.filterString = text;
            }
        },
        Kirigami.Action {
            icon.name: "application-exit"
            text: i18n("Quit Application")
            onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.TerminateSignal)
            enabled: table.selection.hasSelection
        }
    ]

    secondaryActions: [
        Kirigami.Action {
            id: showDetailsAction
            icon.name: "documentinfo"
            text: i18n("Show Details Sidebar")
            checkable: true
            checked: root.config.showDetails
            onToggled: root.config.showDetails = checked
        },
        Kirigami.Action {
            id: configureColumnsAction
            icon.name: "configure"
            text: i18n("Configure columns...")
            onTriggered: columnDialog.open()
        }
    ]

    contentItem: Item {
        ApplicationsTableView {
            id: table

            anchors {
                left: parent.left
                right: splitter.left
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
                    var change = mouse.x - startX
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

            x: parent.width - width
            property real minimumWidth: 150
            property real maximumWidth: root.width * 0.75

            width: root.config.detailsWidth
            onWidthChanged: root.config.detailsWidth = width

            active: root.config.showDetails

            state: root.config.showDetails ? "" : "closed"

            states: State {
                name: "closed"
                PropertyChanges { target: details; x: parent.width; visible: false; enabled: false }
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

        MenuItem { text: i18n("Set priority..."); enabled: false }

        Menu {
            title: i18n("Send Signal")

            MenuItem {
                text: i18n("Suspend (STOP)");
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessController.StopSignal)
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
        MenuSeparator { }
        MenuItem {
            icon.name: "application-exit";
            text: i18n("Quit Application");
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

        title: i18np("Quit Application", "Quit %1 Applications", items.length)
        killButtonText: i18n("Quit")
        killButtonIcon: "application-exit"
        questionText: i18np("Are you sure you want to quit this application?\nAny unsaved work may be lost.",
                            "Are you sure you want to quit these %1 applications?\nAny unsaved work may be lost.", items.length)

        items: table.selectedApplications

        delegate: Kirigami.AbstractListItem {
            leftPadding: Kirigami.Units.gridUnit
            contentItem: RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large;
                    Layout.preferredHeight: width;
                    source: modelData.iconName
                }
                ColumnLayout {
                    id: detailsColumn
                    Label { Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight }
                    Label {
                        Layout.fillWidth: true
                        text: i18np("1 Process", "%1 Processes", modelData.pids.length)
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                    }
                }
            }
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

        function sendSignalToSelection(sig) {
            if (table.selectedApplications.length == 0) {
                return
            }

            if (root.config.askWhenKilling) {
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

        onAccepted: {
            root.config.sortedColumns = sortedColumns
            root.config.columnDisplay = JSON.stringify(columnDisplay)
        }

        Component.onCompleted: {
            setColumnDisplay(JSON.parse(root.config.columnDisplay))
        }
    }
}
