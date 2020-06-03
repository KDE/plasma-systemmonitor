import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.3

import org.kde.kirigami 2.8 as Kirigami

import org.kde.ksgrd2 0.1 as KSysGuard
import org.kde.quickcharts 1.0 as Charts
import org.kde.ksysguard.process 1.0 as Process
import org.kde.kio 1.0 as KIO

import "qrc:/components"
import "qrc:/components/table"

import org.kde.ksysguardqml 1.0

Kirigami.Page {
    id: page

    title: i18n("Applications")

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    titleDelegate: Kirigami.SearchField {
        id: searchField
        width: Kirigami.Units.gridUnit * 10
        onTextEdited: table.filterString = text
        onAccepted: table.filterString = text
    }

    actions.main: Kirigami.Action {
        icon.name: "application-exit"
        text: i18n("Quit Application")
        onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.TerminateSignal)
        enabled: table.selection.hasSelection
    }

    actions.contextualActions: [
        Kirigami.Action {
            id: showDetailsAction
            icon.name: "documentinfo"
            text: i18n("Show Details Sidebar")
            checkable: true
        },
        Kirigami.Action {
            id: configureColumnsAction
            icon.name: "configure"
            text: i18n("Configure columns...")
            onTriggered: columnDialog.open()
        }
    ]

    Item {
        anchors.fill: parent

        ApplicationsTableView {
            id: table

            anchors {
                left: parent.left
                right: splitter.left
                top: parent.top
                bottom: parent.bottom
            }

            onContextMenuRequested: {
                contextMenu.popup(applicationWindow(), position.x, position.y)
            }

            onHeaderContextMenuRequested: {
                headerContextMenu.popup(applicationWindow(), position)
            }

            enabledColumns: columnDialog.visibleColumns
            columnDisplay: columnDialog.columnDisplay
        }

        Kirigami.Separator {
            id: splitter
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: details.left
            }

            z: 10
            enabled: showDetailsAction.checked
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

        ApplicationDetails {
            id: details

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            x: parent.width - width
            property real minimumWidth: 150
            property real maximumWidth: page.width * 0.75

            headerHeight: table.headerHeight

            onClose: showDetailsAction.checked = false

            applications: table.selectedApplications

            state: showDetailsAction.checked ? "" : "closed"

            states: State {
                name: "closed"
                PropertyChanges { target: details; x: parent.width }
            }
            transitions: Transition {
                NumberAnimation { properties: "x"; duration: Kirigami.Units.shortDuration }
            }
        }
    }

    Menu {
        id: contextMenu

//         MenuItem { text: i18n("Set priority...") }
        Menu {
            title: i18n("Send Signal")

            MenuItem {
                text: i18n("Suspend (STOP)");
                onTriggered: processHelper.sendSignalToSelection(Proces.ProcessHelper.StopSignal)
            }
            MenuItem {
                text: i18n("Continue (CONT)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.ContinueSignal)
            }
            MenuItem {
                text: i18n("Hangup (HUP)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.HangupSignal)
            }
            MenuItem {
                text: i18n("Interrupt (INT)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.InterruptSignal)
            }
            MenuItem {
                text: i18n("Terminate (TERM)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.TerminateSignal)
            }
            MenuItem {
                text: i18n("Kill (KILL)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.KillSignal)
            }
            MenuItem {
                text: i18n("User 1 (USR1)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.User1Signal)
            }
            MenuItem {
                text: i18n("User 2 (USR2)")
                onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.User2Signal)
            }
        }
//         MenuItem { text: i18n("Show Application Window") }
        MenuSeparator { }
        MenuItem {
            icon.name: "application-exit";
            text: i18n("Quit Application");
            onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.TerminateSignal)
        }
    }

    Menu {
        id: headerContextMenu

        MenuItem {
            action: configureColumnsAction
        }
    }

    KillDialog {
        id: killDialog

        property int signalToSend

        x: page.width * 0.5 - width / 2
        y: table.headerHeight - Kirigami.Units.largeSpacing

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
            config.askWhenKillingApplications = !killDialog.doNotAskAgain

            for (var i in table.selectedApplications) {
                for (var j in table.selectedApplications[i].pids) {
                    var pid = table.selectedApplications[i].pids[j]
                    processHelper.sendSignal(pid, killDialog.signalToSend);
                }
            }
        }
    }

    Process.ProcessHelper {
        id: processHelper

        function sendSignalToSelection(sig) {
            if (table.selectedApplications.length == 0) {
                return
            }

            if (config.askWhenKillingApplications) {
                killDialog.signalToSend = sig
                killDialog.open()
                return
            }

            for (var i in table.selectedApplications) {
                for (var j in table.selectedApplications[i].pids) {
                    var pid = table.selectedApplications[i].pids[j]
                    sendSignal(pid, sig);
                }
            }
        }
    }

    ColumnConfigurationDialog {
        id: columnDialog

        width: page.width * 0.75
        height: page.height * 0.75
        x: page.width * 0.125
        y: table.headerHeight - Kirigami.Units.smallSpacing

        sourceModel: table.sourceModel.attributesModel
    }

    Configuration {
        id: config

        property alias showDetails: showDetailsAction.checked
        property alias detailsWidth: details.width
        property alias sortedApplicationColumns: columnDialog.sortedColumns
        property alias applicationColumnWidths: table.columnWidths
        property alias applicationSortColumn: table.sortName
        property alias applicationSortDirection: table.sortOrder

        property string applicationColumnDisplay: JSON.stringify(columnDialog.columnDisplay)

        property bool askWhenKillingApplications

        onConfigurationLoaded: columnDialog.setColumnDisplay(JSON.parse(applicationColumnDisplay))
    }
}
