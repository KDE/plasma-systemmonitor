import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12

import org.kde.kirigami 2.2 as Kirigami

Rectangle {
    id: root

    property var view
    property int row
    property int column
    property bool selected: false

    property var __selection: view.selectionModel
    property var __modelIndex: view.model.index(row, column)

    color: (row % 2 == 0) ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

    // We need to update:
    // if the selected indexes changes
    // if our delegate moves
    // if the model moves and the delegate stays in the same place
    function updateIsSelected() {
        selected = __selection.isRowSelected(row)
    }

    Connections {
        target: __selection
        function onSelectionChanged() {
            updateIsSelected();
        }
    }

    onRowChanged: updateIsSelected();

    Connections {
        target: view.model
        function onLayoutChanged() {
            updateIsSelected();
        }
    }

    Component.onCompleted: {
        updateIsSelected();
    }


    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Selection
        opacity: selected ? 1 : (root.__selection.currentIndex.row == root.__modelIndex.row ? 0.3 : 0)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: root.__selection.setCurrentIndex(root.__modelIndex, ItemSelectionModel.NoUpdate)
        onExited: Qt.callLater(maybeClearCurrent)

        onClicked: {
            if (root.__selection.isSelected(root.__modelIndex) && mouse.button == Qt.RightButton) {
                view.contextMenuRequested(root.__modelIndex, mapToGlobal(mouse.x, mouse.y))
                return
            }

            if (mouse.modifiers & Qt.ShiftModifier) {
                //TODO: Implement range selection
                root.__selection.select(root.__modelIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else if (mouse.modifiers & Qt.ControlModifier) {
                root.__selection.select(root.__modelIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else {
                root.__selection.select(root.__modelIndex, ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Rows)
            }

            if (mouse.button == Qt.RightButton) {
                view.contextMenuRequested(root.__modelIndex, mapToGlobal(mouse.x, mouse.y))
            }
        }

        function maybeClearCurrent() {
            // We (ab)use currentIndex to indicate the currently hovered row. This means
            // we shouldn't just clear the current index when the mouse leaves this item
            // since it may just be hovering a different table cell. However, if the mouse
            // exited but the currentIndex is still the current cell, then we can be fairly
            // sure the mouse is no longer over a table cell and we can safely clear the
            // current index.
            if (__selection.currentIndex == __modelIndex) {
                __selection.clearCurrentIndex()
            }
        }
    }
}
