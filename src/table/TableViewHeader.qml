/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls
import QtQml.Models

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.formatter as Formatter

import org.kde.kitemmodels as KItemModels
import org.kde.qqc2desktopstyle.private as StylePrivate

FocusScope {
    id: heading

    x: LayoutMirroring.enabled ? view.contentWidth - view.width - view.contentX : -view.contentX
    width: view.contentWidth
    height: heightHelper.height

    property TableView view
    property int sortColumn: -1
    property int sortOrder: Qt.AscendingOrder

    property string idRole: "Attribute"
    property string sortName

    property alias sourceModel: headerModel.sourceModel

    signal sort(int column, int order)
    signal resize(int column, real width)
    signal contextMenuRequested(int column, point position)

    function columnWidth(index) {
        return repeater.itemAt(index).width
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button

    StylePrivate.StyleItem {
        anchors.fill: parent
        elementType: "header"
        raised: false
        sunken: false
        properties: {
            "headerpos": LayoutMirroring.enabled ? "beginning" : "end"
        }
    }

    ItemDelegate {
        id: heightHelper
        icon.name: "document-new"
        text: "Placeholder"
        visible: false
    }

    activeFocusOnTab: true

    function focusNext(delta) {
        var newIndex = headerRow.currentIndex
        var item = undefined
        while (item === undefined || item instanceof Repeater) {
            newIndex = newIndex + delta

            if (newIndex < 0) {
                newIndex = headerRow.children.length - 1
            }
            if (newIndex >= headerRow.children.length) {
                newIndex = 0
            }

            item = headerRow.children[newIndex]
        }

        item.focus = true
        headerRow.currentIndex = newIndex
    }

    Row {
        id: headerRow
        anchors.left: parent.left
        anchors.leftMargin: LayoutMirroring.enabled ? view.contentWidth - width : 0
        property int currentIndex: 0

        Repeater {
            id: repeater

            model: KItemModels.KColumnHeadersModel {
                id: headerModel
                sourceModel: heading.view.model
            }

            delegate: StylePrivate.StyleItem {
                id: headerItem
                // FIXME Need to reverse the index order until TableView correctly supports it itself, see QTBUG-90547
                width: heading.view.columnWidthProvider(LayoutMirroring.enabled ? repeater.count - model.row - 1 : model.row)
                height: heightHelper.height
                enabled: width > 0

                property string headerPosition: {
                    if (repeater.count === 1) {
                        return "only";
                    }
                    if (index == 0) {
                        return LayoutMirroring.enabled ? "end" : "beginning"
                    }
                    return "middle"
                }

                property string columnId: model[heading.idRole] !== undefined ? model[heading.idRole] : ""

                elementType: "header"
                activeControl: heading.sortName == columnId ? (heading.sortOrder == Qt.AscendingOrder ? "down" : "up") : ""
                raised: false
                sunken: mouse.pressed || activeFocus
                text: model.display != undefined ? model.display : ""
                hover: mouse.containsMouse

                focus: true

                properties: {
                    "headerpos": headerPosition,
                    "textalignment": Text.AlignHCenter
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                        case Qt.Key_Space:
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                            toggleSort()
                            break;
                        case Qt.Key_Menu:
                            heading.contextMenuRequested(model.row, mapToGlobal(headerItem.x, headerItem.y + headerItem.height))
                            break
                        case Qt.Key_Left:
                            heading.focusNext(-1)
                            break
                        case Qt.Key_Right:
                            heading.focusNext(1)
                            break
                        default:
                            break;
                    }
                }

                function toggleSort() {
                    if (heading.sortName == headerItem.columnId) {
                        sort(heading.sortOrder == Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder);
                    } else {
                        sort(model.Unit == Formatter.Units.UnitNone || model.Unit == Formatter.Units.UnitInvalid ? Qt.AscendingOrder : Qt.DescendingOrder);
                    }
                }

                function sort(sortOrder) {
                    heading.sortColumn = model.row;
                    heading.sortName = headerItem.columnId
                    heading.sortOrder = sortOrder
                    heading.sort(heading.sortColumn, heading.sortOrder)
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: {
                        if (mouse.button == Qt.RightButton) {
                            heading.contextMenuRequested(model.row, mapToGlobal(mouse.x, mouse.y))
                            return
                        }

                        headerItem.toggleSort()
                    }
                }
                MouseArea {
                    id: dragHandle
                    property real mouseDownX
                    property bool dragging: false
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: LayoutMirroring.enabled && !dragging ? parent.left : undefined
                        right: !LayoutMirroring.enabled && !dragging ? parent.right : undefined
                    }
                    drag.target: dragHandle
                    drag.axis: Drag.XAxis
                    cursorShape: enabled ? Qt.SplitHCursor : undefined
                    width: Kirigami.Units.smallSpacing * 2
                    onPressed: {
                        dragging = true
                        mouseDownX = x
                    }
                    onXChanged: {
                        if (!dragging) {
                            return
                        }
                        heading.resize(model.row, headerItem.width + (x - mouseDownX))
                        mouseDownX = x

                    }
                    onReleased: {
                        dragging = false
                    }
                }
                Component.onCompleted: {
                    if (heading.sortColumn == -1 && headerItem.columnId == heading.sortName) {
                        Qt.callLater(() => headerItem.sort(heading.sortOrder));
                    }
                }
            }
        }
    }
}
