import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami
import org.kde.ksysguard.page 1.0

Item  {
    id: root

    property int axis: Qt.YAxis
    property Item target

    signal moved(int from, int to)

    parent: target
    anchors.fill: target
    DragHandler {
        id: drag
        enabled: !root.target.single
        target: root.target.mainControl
        grabPermissions: PointerHandler.TakeOverForbidden	
        xAxis.enabled: root.axis == Qt.XAxis
        xAxis.minimum: root.target.parent.Kirigami.ScenePosition.x
        xAxis.maximum: root.target.parent.Kirigami.ScenePosition.x + root.target.parent.width - root.target.width

        yAxis.enabled: root.axis == Qt.YAxis
        yAxis.minimum: root.target.parent.Kirigami.ScenePosition.y
        yAxis.maximum: root.target.parent.Kirigami.ScenePosition.y + root.target.parent.height - root.target.height

        property Item justMovedLeft
        property Item justMovedRight
        property real lastX: -1
        property real lastY: -1

        onTranslationChanged: {
            if (root.target.single) {
                console.log("is signle" + root.target + " " + target)
                return
            }
            console.log("got grab" + root.target + " " + target)
            var pressPositionInTarget = parent.mapToItem(root.target.mainControl, centroid.pressPosition.x, centroid.pressPosition.y)

            var left = centroid.scenePosition.x - pressPositionInTarget.x
            var top = centroid.scenePosition.y - pressPositionInTarget.y

            var rectInParent = root.target.parent.mapFromItem(null, left, top, root.target.width, root.target.height)

            var x = 0
            var y = 0
            var child = null
            var beforeChild = null
            var afterChild = null

            if (root.axis == Qt.XAxis) {
                x = rectInParent.left
                y = root.target.y + root.target.height / 2

                beforeChild = root.target.parent.childAt(rectInParent.left - 2, y);
                afterChild = root.target.parent.childAt(rectInParent.right + 2, y);

                if (beforeChild === afterChild) {
                    if (lastX > x) {
                        afterChild = null;
                    } else {
                        beforeChild = null;
                    }
                }

                var mappedLeft = beforeChild ? beforeChild.mapFromItem(root.target.parent, rectInParent.left - 2, y).x : -1;
                var mappedRight = afterChild ? afterChild.mapFromItem(root.target.parent, rectInParent.right + 2, y).x : -1;

                if (beforeChild && mappedLeft < beforeChild.width / 2 && mappedLeft > 0) {
                    child = beforeChild;
                } else if (afterChild && mappedRight > afterChild.width / 2 && mappedRight < afterChild.width) {
                    child = afterChild;
                }

            } else {
                x = root.target.x + root.target.width / 2
                y = rectInParent.top

                beforeChild = root.target.parent.childAt(x, rectInParent.top - 2);
                afterChild = root.target.parent.childAt(x, rectInParent.bottom + 2);

                if (beforeChild === afterChild) {
                    if (lastY > y) {
                        afterChild = null;
                    } else {
                        beforeChild = null;
                    }
                }

                var mappedLeft = beforeChild ? beforeChild.mapFromItem(root.target.parent, x, rectInParent.top - 2).y : -1;
                var mappedRight = afterChild ? afterChild.mapFromItem(root.target.parent, x, rectInParent.bottom + 2).y : -1;

                if (beforeChild && mappedLeft < beforeChild.height / 2 && mappedLeft > 0) {
                    child = beforeChild;
                } else if (afterChild && mappedRight > afterChild.height / 2 && mappedRight < afterChild.width) {
                    child = afterChild;
                }
            }

            if (child && child != root.target &&
                ((root.axis == Qt.XAxis &&
                    (lastX < x || child != justMovedLeft) &&
                    (lastX > x || child != justMovedRight))
                 || (root.axis == Qt.YAxis &&
                    (lastY < y || child != justMovedLeft) &&
                    (lastY > y || child != justMovedRight)))) {

                if (child == beforeChild) {
                    justMovedLeft = child;
                    justMovedRight = null;
                } else {
                    justMovedLeft = null;
                    justMovedRight = child;
                }

                root.moved(root.target.index, child.index);
            }

            lastX = x
            lastY = y
        }
    }
    PointHandler {
        id: point
        enabled: !root.target.single
        onActiveChanged: {
            if (root.target.single) {
                return
            }
            if (active) {
                let pos = root.target.Overlay.overlay.mapFromItem(root.target.mainControl, 0, 0);
                root.target.mainControl.parent = root.target.Overlay.overlay;
                root.target.mainControl.x = pos.x;
                root.target.mainControl.y = pos.y;
                root.target.raised = true;

            } else {
                let pos = root.target.mapFromItem(root.target.mainControl, 0, 0);
                root.target.mainControl.x = pos.x
                root.target.mainControl.y = pos.y
                root.target.mainControl.parent = root.target

                dropAnimation.start()

                drag.justMovedLeft = null
                drag.justMovedRight = null
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: root.target.raised ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    }

    SequentialAnimation {
        id: dropAnimation
        NumberAnimation {
            id: dropNumberAnimation
            target: root.target.mainControl
            property: root.axis == Qt.YAxis ? "y" : "x"
            to: 0
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
        PropertyAction {
            target: root.target
            property: "raised"
            value: false
        }
    }
}
