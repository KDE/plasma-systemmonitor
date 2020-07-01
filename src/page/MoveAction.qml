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

            target: action.target.mainControl

            xAxis.enabled: action.axis == Qt.XAxis
            xAxis.minimum: action.target.parent.Kirigami.ScenePosition.x
            xAxis.maximum: action.target.parent.Kirigami.ScenePosition.x + action.target.parent.width - action.target.width

            yAxis.enabled: action.axis == Qt.YAxis
            yAxis.minimum: action.target.parent.Kirigami.ScenePosition.y
            yAxis.maximum: action.target.parent.Kirigami.ScenePosition.y + action.target.parent.height - action.target.height

            property Item justMovedLeft
            property Item justMovedRight
            property real lastX: -1
            property real lastY: -1


            onTranslationChanged: {
                var pressPositionInTarget = parent.mapToItem(action.target.mainControl, centroid.pressPosition.x, centroid.pressPosition.y)

                var left = centroid.scenePosition.x - pressPositionInTarget.x
                var top = centroid.scenePosition.y - pressPositionInTarget.y

                var rectInParent = action.target.parent.mapFromItem(null, left, top, action.target.width, action.target.height)

                var x = 0
                var y = 0
                var child = null
                var beforeChild = null
                var afterChild = null

                if (action.axis == Qt.XAxis) {
                    x = rectInParent.left
                    y = action.target.y + action.target.height / 2
                    
                    beforeChild = action.target.parent.childAt(rectInParent.left - 2, y);
                    afterChild = action.target.parent.childAt(rectInParent.right + 2, y);
                    
                    var mappedLeft = beforeChild ? beforeChild.mapFromItem(action.target.parent, rectInParent.left - 2, y).x : -1;
                    var mappedRight = afterChild ? afterChild.mapFromItem(action.target.parent, rectInParent.right + 2, y).x : -1;
                    
                    if (beforeChild && mappedLeft < beforeChild.width / 2 && mappedLeft > 0) {
                        child = beforeChild;

                    } else if (afterChild && mappedRight > afterChild.width / 2 && mappedRight < afterChild.width) {
                        child = afterChild;
                    }

                } else {
                    x = action.target.x + action.target.width / 2
                    y = rectInParent.top

                    beforeChild = action.target.parent.childAt(x, rectInParent.top - 2);
                    afterChild = action.target.parent.childAt(x, rectInParent.bottom + 2);
                    
                    var mappedLeft = beforeChild ? beforeChild.mapFromItem(action.target.parent, x, rectInParent.top - 2).y : -1;
                    var mappedRight = afterChild ? afterChild.mapFromItem(action.target.parent, x, rectInParent.bottom + 2).y : -1;
                    
                    if (beforeChild && mappedLeft < beforeChild.height / 2 && mappedLeft > 0) {
                        child = beforeChild;

                    } else if (afterChild && mappedRight > afterChild.height / 2 && mappedRight < afterChild.width) {
                        child = afterChild;
                    }
                }

                if (child && child != action.target &&
                    ((action.axis == Qt.XAxis &&
                     (lastX < x || child != justMovedLeft) &&
                     (lastX > x || child != justMovedRight))
                     || (action.axis == Qt.YAxis && (lastY < y || child != justMovedLeft) &&
                     (lastY > y || child != justMovedRight)))) {

                    if (child == beforeChild) {
                        justMovedLeft = child;
                        justMovedRight = null;
                    } else {
                        justMovedLeft = null;
                        justMovedRight = child;
                    }

                    action.move(action.target.index, child.index);
                }
                lastX = x
                lastY = y
            }
        }
        PointHandler {
            id: point

            onActiveChanged: {
                if (active) {
                    let pos = action.target.Overlay.overlay.mapFromItem(action.target.mainControl, 0, 0);
                    action.target.mainControl.parent = action.target.Overlay.overlay;
                    action.target.mainControl.x = pos.x;
                    action.target.mainControl.y = pos.y;
                    action.target.raised = true;

                } else {
                    let pos = action.target.mapFromItem(action.target.mainControl, 0, 0);
                    action.target.mainControl.x = pos.x
                    action.target.mainControl.y = pos.y
                    action.target.mainControl.parent = action.target

                    dropAnimation.start()
                    action.target.parent.forceLayout()
                    drag.justMovedLeft = null
                    drag.justMovedRight = null
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
                target: action.target.mainControl
                to: 0
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
