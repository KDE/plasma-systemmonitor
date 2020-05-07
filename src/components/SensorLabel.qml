import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.4 as Kirigami

import org.kde.ksgrd2 0.1 as KSGRD

TextField {
    property alias sensorId: sensor.sensorId;
    property alias sensor: sensor;

    property string prefix;

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.fillWidth: true

    text: prefix + " " + sensor.value;

    horizontalAlignment: Qt.AlignHCenter
    verticalAlignment: Qt.AlignVCenter


    readOnly: true
    background: Item { }
    padding: 0

    KSGRD.Sensor { id: sensor; }
}
