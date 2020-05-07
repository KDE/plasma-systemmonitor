import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami
import org.kde.ksysguard.page 1.0

Kirigami.Action {
    id: action

    property int axis: Qt.YAxis
    property Container target

    signal move(int from, int to)

    text: i18n("Move")
    icon.name: "transform-move"
    enabled: !action.target.single

    displayComponent: Button {
        action: kirigamiAction
        DragHandler {
            id: drag

            target: action.target

            xAxis.enabled: action.axis == Qt.XAxis
            xAxis.minimum: 0
            xAxis.maximum: action.target.parent.width - action.target.width

            yAxis.enabled: action.axis == Qt.YAxis
            yAxis.minimum: 0
            yAxis.maximum: action.target.parent.height - action.target.height

            property Item justMoved

            onTranslationChanged: {
                var pressPositionInTarget = parent.mapToItem(action.target, centroid.pressPosition.x, centroid.pressPosition.y)

                var left = centroid.scenePosition.x - pressPositionInTarget.x
                var top = centroid.scenePosition.y - pressPositionInTarget.y

                var rectInParent = action.target.parent.mapFromItem(null, left, top, action.target.width, action.target.height)

                var x = 0
                var y = 0
                if (action.axis == Qt.XAxis) {
                    x = translation.x < 0 ? rectInParent.left - 2 : rectInParent.right + 2
                    y = action.target.y + action.target.height / 2
                } else {
                    x = action.target.x + action.target.width / 2
                    y = translation.y < 0 ? rectInParent.top - 2 : rectInParent.bottom + 2
                }

                var child = action.target.parent.childAt(x, y)

                if (child && child != action.target && child != justMoved) {
                    var index = child.index
                    justMoved = child
                    action.move(action.target.index, index)
                }
            }
        }
        PointHandler {
            id: point

            onActiveChanged: {
                if (active) {
                    action.target.raised = true
                } else {
                    dropNumberAnimation.to = action.target.parent.positionFor(action.target.index)
                    dropAnimation.start()
                    action.target.parent.forceLayout()
                    drag.justMoved = null
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: action.target.raised ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }

        SequentialAnimation {
            id: dropAnimation
            NumberAnimation {
                id: dropNumberAnimation
                target: action.target
                property: action.axis == Qt.YAxis ? "y" : "x"
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
            PropertyAction {
                target: action.target
                property: "raised"
                value: false
            }
        }
    }
}
