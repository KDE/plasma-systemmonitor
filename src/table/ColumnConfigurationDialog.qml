/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.5 as Kirigami

import org.kde.ksysguard.formatter 1.0 as Formatter
import org.kde.ksysguard.table 1.0 as Table

Dialog {
    id: columnDialog

    property alias model: columnView.model
    property alias sourceModel: sortModel.sourceModel
    property var visibleColumns: []
    property var sortedColumns: []
    property var fixedColumns: []
    property var columnDisplay: {"name": "text"}

    title: i18ndc("plasma-systemmonitor", "@window:title", "Configure Columns")

    standardButtons: Dialog.Ok | Dialog.Cancel

    modal: true
    parent: Overlay.overlay
    focus: true

    x: parent ? Math.round(parent.width / 2 - width / 2) : 0
    y: ApplicationWindow.window ? ApplicationWindow.window.pageStack.globalToolBar.height - Kirigami.Units.smallSpacing : 0
    width: parent ? parent.width * 0.75 : 0
    height: parent ? parent.height * 0.75 : 0

    leftPadding: 1
    rightPadding: 1
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing

    Kirigami.Theme.colorSet: Kirigami.Theme.View

    function setColumnDisplay(display) {
        columnDisplay = display
        prepare()
        apply()
    }

    onAccepted: {
        apply()
    }

    onAboutToShow: {
        prepare()
    }

    function prepare() {
        sortModel.sortedColumns = sortedColumns.filter(id => fixedColumns.indexOf(id) == -1)
        let tempDisplay = columnDisplay
        fixedColumns.forEach(column => delete tempDisplay[column])
        displayModel.columnDisplay = tempDisplay
    }

    function apply() {
        sortedColumns = fixedColumns.concat(sortModel.sortedColumns)
        visibleColumns = fixedColumns.concat(displayModel.visibleColumnIds)
        columnDisplay = displayModel.columnDisplay
    }

    Rectangle {
        anchors.fill: parent
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.Separator { Layout.fillWidth: true }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: columnView


                model: Table.ColumnDisplayModel {
                    id: displayModel

                    sourceModel: Table.ColumnSortModel {
                        id: sortModel
                    }
                }

                delegate: Loader {
                    width: columnView.width
                    height: Kirigami.Units.gridUnit * 3
                    property var modelData: model
                    sourceComponent: delegateComponent
                }

                Component {
                    id: delegateComponent
                    Kirigami.AbstractListItem {
                        id: listItem
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        rightPadding: Kirigami.Units.smallSpacing
                        property int index: modelData ? modelData.row : -1
                        activeFocusOnTab: false
                        contentItem: GridLayout {
                            rows: 2
                            flow: GridLayout.TopToBottom
                            Kirigami.ListItemDragHandle {
                                id: handle
                                Layout.fillHeight: true
                                Layout.rowSpan: 2
                                listItem: listItem
                                listView: columnView
                                onMoveRequested: sortModel.move(oldIndex, newIndex)
                            }
                            Label {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                Layout.rowSpan: modelData && modelData.description ? 1 : 2
                                text: modelData ? modelData.name : ""
                            }
                            Label {
                                id: descriptionLabel
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                textFormat: Text.PlainText
                                text: modelData ? modelData.description.replace("<br>", " ") : ""
                                color: Kirigami.Theme.disabledTextColor
                            }

                            ComboBox {
                                id: showCombo
                                textRole: "text"
                                Layout.rowSpan: 2
                                model: {
                                    var result = [
                                        {text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Hidden"), value: "hidden"},
                                        {text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Text Only"), value: "text"},
                                    ]

                                    if (modelData && modelData.unit) {
                                        if (modelData.unit != Formatter.Units.UnitInvalid
                                            && modelData.unit != Formatter.Units.UnitNone) {
                                            result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Line Chart"), value: "line"})
                                        }
                                        if (modelData.unit == Formatter.Units.UnitPercent
                                            && modelData.maximum != 100) {
                                            result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Text Only (Scaled to 100%)"), value: "textScaled"})
                                            result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Line Chart (Scaled to 100%)"), value: "lineScaled"})
                                        }
                                    }
                                    return result
                                }

                                currentIndex: {
                                    if (!modelData) {
                                        return -1;
                                    }

                                    for (var i = 0; i < model.length; ++i) {
                                        if (model[i].value == modelData.displayStyle) {
                                            return i;
                                        }
                                    }
                                    return -1;
                                }

                                onActivated: {
                                    displayModel.setDisplay(listItem.index, model[index].value);
                                }
                            }
                        }

                        ToolTip.text: modelData ? modelData.description.replace("<br>", " ") : ""
                        ToolTip.visible: listItem.hovered && descriptionLabel.truncated
                        ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true; }
    }
}
