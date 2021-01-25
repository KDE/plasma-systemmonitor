/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQml.Models 2.12

import org.kde.kirigami 2.2 as Kirigami
import org.kde.ksysguard.formatter 1.0 as Formatter

import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.qqc2desktopstyle.private 1.0 as StylePrivate

FocusScope {
    id: heading

    x: -view.contentX
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
            "headerpos": "end"
        }
    }

    Kirigami.BasicListItem {
        id: heightHelper
        text: "Placeholder"
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

        property int currentIndex: 0

        Repeater {
            id: repeater

            model: KItemModels.KColumnHeadersModel {
                id: headerModel
                sourceModel: heading.view.model
            }

            delegate: StylePrivate.StyleItem {
                id: headerItem

                width: heading.view.columnWidthProvider(model.row)
                height: heightHelper.height
                enabled: width > 0

                property string headerPosition: {
                    if (repeater.count === 1) {
                        return "only";
                    }

                    return "beginning";
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

                Keys.onPressed: {
                    switch (event.key) {
                        case Qt.Key_Space:
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                            sort()
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

                function sort() {
                    if (heading.sortName == headerItem.columnId) {
                        heading.sortOrder = heading.sortOrder == Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder;
                    } else {
                        heading.sortColumn = model.row;
                        heading.sortName = headerItem.columnId
                        heading.sortOrder = model.Unit == Formatter.Units.UnitNone || model.Unit == Formatter.Units.UnitInvalid ? Qt.AscendingOrder : Qt.DescendingOrder;
                    }
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

                        headerItem.sort()
                    }
                }
                MouseArea {
                    id: dragHandle
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    drag.target: dragHandle
                    drag.axis: Drag.XAxis
                    cursorShape: enabled ? Qt.SplitHCursor : undefined
                    width: Kirigami.Units.smallSpacing * 2
                    property real mouseDownX
                    property bool dragging: false
                    onPressed: {
                        dragging = true
                        mouseDownX = x
                        anchors.right = undefined
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
                        anchors.right = parent.right
                    }
                }
                Component.onCompleted: {
                    if (heading.sortColumn == -1 && headerItem.columnId == heading.sortName) {
                        heading.sortColumn = model.row
                        Qt.callLater(() => heading.sort(model.row, heading.sortOrder))
                    }
                }
            }
        }
    }
}
