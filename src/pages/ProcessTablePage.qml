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

    title: i18n("Processes")

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    titleDelegate: Kirigami.SearchField {
        width: Kirigami.Units.gridUnit * 10
        onTextEdited: table.nameFilterString = text
        onAccepted: table.nameFilterString = text
    }

    ActionGroup { id: showGroup }
    ActionGroup { id: viewGroup }

    actions.main: Kirigami.Action {
        icon.name: "process-stop"
        text: i18n("End Process")
        onTriggered: processHelper.sendSignalToSelection(Process.ProcessHelper.TerminateSignal)
        enabled: table.selection.hasSelection
    }

    actions.contextualActions: [
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
                property int mode: ProcessesTableView.ViewMode.Own
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18n("User Processes")
                checkable: true
                checked: config.userFilterMode == mode
                icon.name: "view-process-users"
                property int mode: ProcessesTableView.ViewMode.User
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18n("System Processes")
                checkable: true
                checked: config.userFilterMode == mode
                icon.name: "view-process-system"
                property int mode: ProcessesTableView.ViewMode.System
                ActionGroup.group: showGroup
            }

            Kirigami.Action {
                text: i18n("All Processes")
                checkable: true
                checked: config.userFilterMode == mode
                icon.name: "view-process-all"
                property int mode: ProcessesTableView.ViewMode.All
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

    ProcessesTableView {
        id: table

        anchors.fill: parent

        viewMode: showGroup.checkedAction.mode

        onContextMenuRequested: {
            contextMenu.popup(applicationWindow(), position.x, position.y)
        }

        onHeaderContextMenuRequested: {
            headerContextMenu.popup(applicationWindow(), position)
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
            icon.name: "process-stop";
            text: i18np("End Process", "End %1 Processes", killDialog.items.length);
            onTriggered: {
                processHelper.sendSignalToSelection(Process.ProcessHelper.TerminateSignal)
            }

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

    Process.ProcessHelper {
        id: processHelper

        property var killSignals: [
            Process.ProcessHelper.TerminateSignal,
            Process.ProcessHelper.KillSignal
        ]

        function sendSignalToSelection(sig) {
            if (config.askWhenKillingProcesses && killSignals.includes(sig)) {
                killDialog.signalToSend = sig
                killDialog.open()
            } else {
                for (var i of table.selectedProcesses) {
                    sendSignal(i.pid, sig)
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

        sourceModel: table.processModel.attributesModel
    }

    Configuration {
        id: config

        property int userFilterMode: showGroup.checkedAction.mode
        property int viewMode: viewGroup.checkedAction.mode
        property alias sortedProcessColumns: columnDialog.sortedColumns
        property alias processColumnWidths: table.columnWidths
        property alias processSortColumn: table.sortName
        property alias processSortDirection: table.sortOrder

        property string processColumnDisplay: JSON.stringify(columnDialog.columnDisplay)

        property bool askWhenKillingProcesses

        onConfigurationLoaded: columnDialog.setColumnDisplay(JSON.parse(config.processColumnDisplay))
    }
}
