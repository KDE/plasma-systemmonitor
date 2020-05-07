import QtQuick 2.9
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.2

import org.kde.kirigami 2.4 as Kirigami
import org.kde.quickcharts 1.0 as Charts

Control {
    id: control

    property alias chart: legendModel.chart
    property alias model: legendRepeater.model
    property alias delegate: legendRepeater.delegate
    property alias flow: legend.flow

    property real valueWidth: 100
    property var formatValue: function(input) { return input }

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: GridLayout {
        id: legend

        columns: flow == GridLayout.TopToBottom ? 1 : -1
        rows: flow == GridLayout.TopToBottom ? -1 : 1

        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            id: legendRepeater
            model: Charts.LegendModel { id: legendModel; chart: chart }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 0

                implicitHeight: Kirigami.Units.gridUnit

                Rectangle {
                    id: color
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }
                    width: Kirigami.Units.smallSpacing;
                    color: model.color;
                    visible: (parent.width - control.valueWidth - Kirigami.Units.smallSpacing * 2 > 0) || parent.width < control.valueWidth
                }

                Label {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: color.right
                        right: value.left
                        leftMargin: Kirigami.Units.smallSpacing
                        rightMargin: Kirigami.Units.smallSpacing
                    }

                    text: model.name;
                    font: control.font
                    visible: contentWidth < width
                    verticalAlignment: Qt.AlignVCenter
                }

                Label {
                    id: value
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                        rightMargin: Kirigami.Units.smallSpacing
                    }
                    width: control.valueWidth

                    text: control.formatValue(model.value);
                    font: control.font
                    color: model.color
                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignRight

                    visible: parent.width >= control.valueWidth
                }
            }
        }
    }


}

