/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * SPDX-FileCopyrightText: 2023 Nate Graham <nate@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.formatter as Formatter
import org.kde.ksysguard.table as Table

Dialog {
    id: columnDialog

    property string nameAttribute: "name"

    property alias model: columnView.model
    property alias sourceModel: sortModel.sourceModel
    property var sortedColumns: []
    property var columnDisplay: {}

    title: i18ndc("plasma-systemmonitor", "@window:title", "Configure Columns")

    focus: true

    standardButtons: Dialog.Ok | Dialog.Cancel

    popupType: Popup.Window
    modal: false
    padding: 0

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
        sortModel.sortedColumns = sortedColumns
        sortModel.columnDisplay = columnDisplay
    }

    function apply() {
        sortedColumns = sortModel.sortedColumns
        columnDisplay = sortModel.columnDisplay
    }

    function hideColumn(columnId) {
        sortModel.setDisplayById(columnId, "hidden");
        accept()
    }

    header: ToolBar {
        Kirigami.SearchField {
            id: searchField
            width: parent.width
            onAccepted: sortModel.filterString = text
        }
    }

    footer: ToolBar {
        DialogButtonBox {
            width: parent.width
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel

            onAccepted: columnDialog.accept()
            onRejected: columnDialog.reject()
        }
    }

    contentItem: ScrollView {
        id: scrollView

        implicitWidth: Kirigami.Units.gridUnit * 40
        implicitHeight: Kirigami.Units.gridUnit * 40

        ListView {
            id: columnView

            model: visible ? sortModel : null

            Table.ColumnSortFilterDisplayModel {
                id: sortModel
                nameAttribute: columnDialog.nameAttribute
            }

            section.property: "enabled"
            section.delegate: Kirigami.ListSectionHeader {
                required property string section
                width: ListView.view.width
                text: section === "enabled" ? i18ndc("plasma-systemmonitor", "@item:inlistbox", "Enabled Columns") : i18ndc("plasma-systemmonitor", "@item:inlistbox", "Disabled Columns")
            }

            move: Transition {
                NumberAnimation { duration: Kirigami.Units.shortDuration; properties: "y" }
            }

            moveDisplaced: Transition {
                NumberAnimation { duration: Kirigami.Units.shortDuration; properties: "y" }
            }

            delegate: Loader {
                required property var model

                width: columnView.width
                height: Kirigami.Units.gridUnit * 3

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.mediumSpacing
                    color: Qt.alpha(Kirigami.Theme.highlightColor, 0.1)
                    border.color: Kirigami.Theme.highlightColor
                    border.width: 1
                    radius: Kirigami.Units.cornerRadius
                    visible: parent.item?.highlighted ?? false
                }

                sourceComponent: Kirigami.SubtitleDelegate {
                    id: delegate

                    property int index: model.row
                    property string attributeId: model.id
                    property int unit: model.unit
                    property int maximum: model.maximum
                    property string displayStyle: model.displayStyle

                    rightPadding: Kirigami.Units.smallSpacing
                    activeFocusOnTab: false

                    property Item _originalParent

                    SequentialAnimation {
                        id: dropAnimation

                        property real to

                        NumberAnimation {
                            target: delegate
                            property: "y"
                            duration: Kirigami.Units.shortDuration
                            to: dropAnimation.to
                        }

                        ScriptAction {
                            script: {
                                delegate.highlighted = false
                                delegate.parent = delegate._originalParent
                                delegate.y = 0
                            }
                        }
                    }

                    // We don't want visual interactivity for the background except on drag.
                    hoverEnabled: false
                    down: false

                    text: model.name
                    subtitle: model.description

                    Kirigami.Theme.useAlternateBackgroundColor: true

                    ToolTip.visible: hoverHandler.hovered && contentItem.truncated && !highlighted

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        property bool truncated: titleSubtitle.truncated

                        // This reimplements ListItemDragHandle in a slightly different way,
                        // as ListItemDragHandle itself breaks when Dialog uses popupType Window.
                        Kirigami.Icon {
                            source: "handle-sort"
                            visible: model.enabled === "enabled" ?? false
                            enabled: model.id !== columnDialog.nameAttribute && !sortModel.filterString

                            MouseArea {
                                anchors.fill: parent

                                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                drag.target: delegate
                                drag.axis: Drag.YAxis

                                drag.onActiveChanged: {
                                    if (drag.active) {
                                        // delegate._originalZ = delegate.parent.z
                                        // delegate.parent.z = 9999
                                        delegate._originalParent = delegate.parent
                                        delegate.parent = Overlay.overlay
                                        delegate.highlighted = true
                                    } else {
                                        dropAnimation.to = delegate._originalParent.mapToItem(Overlay.overlay, 0, 0).y
                                        dropAnimation.start()
                                    }
                                }

                                onPositionChanged: mouse => {
                                    let listViewPosition = mapToItem(columnView, mouse.x, mouse.y)
                                    let index = columnView.indexAt(listViewPosition.x, listViewPosition.y)
                                    if (index >= 1 && index != delegate.index) {
                                        let delegateViewPosition = delegate.mapToItem(columnView, delegate.x, delegate.y)
                                        sortModel.move(delegate.index, index)
                                        delegate.y = columnView.mapToItem(delegate, delegateViewPosition.x, delegateViewPosition.y).y
                                    }
                                }
                            }
                        }

                        Kirigami.TitleSubtitle {
                            id: titleSubtitle
                            Layout.fillWidth: true
                            title: delegate.text
                            subtitle: delegate.subtitle
                        }

                        ComboBox {
                            id: showCombo
                            textRole: "text"
                            Layout.rowSpan: 2
                            Layout.rightMargin: Kirigami.Units.smallSpacing
                            enabled: delegate.attributeId !== columnDialog.nameAttribute

                            model: {
                                var result = [
                                    {text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Hidden"), value: "hidden"},
                                    {text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Text Only"), value: "text"},
                                ]

                                if (delegate.unit != Formatter.Units.UnitInvalid && delegate.unit != Formatter.Units.UnitNone) {
                                    result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Line Chart"), value: "line"})
                                }

                                if (delegate.unit == Formatter.Units.UnitPercent && delegate.maximum != 100) {
                                    result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Text Only (Scaled to 100%)"), value: "textScaled"})
                                    result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Line Chart (Scaled to 100%)"), value: "lineScaled"})
                                }

                                return result
                            }

                            currentIndex: {
                                if (delegate.attributeId === columnDialog.nameAttribute) {
                                    return 1;
                                }

                                for (var i = 0; i < model.length; ++i) {
                                    if (model[i].value == delegate.displayStyle) {
                                        return i;
                                    }
                                }
                                return -1;
                            }

                            onActivated: index => {
                                sortModel.setDisplay(delegate.index, model[index].value);
                            }
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                    }
                }
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width * 0.75

                visible: !columnView.count

                text: i18ndc("plasma-systemmonitor", "@info", "No columns matched the search")
            }
        }
    }
}
