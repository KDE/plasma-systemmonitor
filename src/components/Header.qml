import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.4 as Kirigami
import org.kde.quickcharts 1.0 as Charts
import org.kde.ksgrd2 0.1 as KSGRD

Item {
    height: details.height + Kirigami.Units.smallSpacing

    property alias currentIndex: tabBar.currentIndex
    property alias systemIcon: computerIcon.source

    Kirigami.Icon {
        id: computerIcon
        width: Kirigami.Units.iconSizes.large
        height: Kirigami.Units.iconSizes.large
        source: iconNameSensor.value

        KSGRD.Sensor { id: iconNameSensor; sensorId: "os/system/iconName" }
    }

    Column {
        id: details
        anchors.left: computerIcon.right

        Label {
            text: hostnameSensor.value;
            font.bold: true;
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2

            KSGRD.Sensor { id: hostnameSensor; sensorId: "os/system/hostname" }
        }
        Label {
            text: "Uptime %1".arg(Qt.formatTime(new Date(uptimeSensor.data * 1000)));
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8

            KSGRD.Sensor { id: uptimeSensor; sensorId: "uptime/system/uptime" }
        }
        Label { text: "AMD Ryzen 5 2500, AMD RX560, 16 GiB Memory";  font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8 }
    }

    TabBar {
        id: tabBar

        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.bottom: parent.bottom

        TabButton {
            text: "Overview"
        }
        TabButton {
            text: "Applications"
        }
    }
}
