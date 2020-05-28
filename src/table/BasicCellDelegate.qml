import QtQuick 2.12
import QtQuick.Controls 2.2

import org.kde.kirigami 2.2 as Kirigami

Label {
    id: delegate

    leftPadding: Kirigami.Units.smallSpacing
    rightPadding: leftPadding

    text: model.display != undefined ? model.display : ""

    Kirigami.Theme.colorSet: background.selected ? Kirigami.Theme.Selection : Kirigami.Theme.View

    maximumLineCount: 1
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter

    background: CellBackground { view: delegate.TableView.view; row: model.row; column: model.column }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        ToolTip.text: delegate.text
        ToolTip.delay: Kirigami.Units.toolTipDelay
        ToolTip.visible: mouse.containsMouse && delegate.truncated
    }
}
