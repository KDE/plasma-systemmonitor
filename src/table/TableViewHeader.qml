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

HorizontalHeaderView {
    id: header

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }

    property alias view: header.syncView

    property alias sortColumn: header.currentColumn
    property int sortOrder: Qt.AscendingOrder
    property string sortName
    onSortNameChanged: updateSelectedColumn()

    property string idRole: "Attribute"

    signal sort(int column, int order)
    signal resize(int column, real width)
    signal contextMenuRequested(int column, point position)

    resizableColumns: true
    clip: true

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    onCurrentColumnChanged: sort(sortColumn, sortOrder)

    Component.onCompleted: Qt.callLater(updateSelectedColumn)

    function updateSelectedColumn() {
        let roleIndex = headerModel.KItemModels.KRoleNames.role(idRole)
        for (let i = 0; i < headerModel.rowCount(); ++i) {
            let index = headerModel.index(i, 0)
            if (headerModel.data(index, roleIndex) == sortName) {
                selectionModel.setCurrentIndex(headerModel.sourceModel.index(0, i), ItemSelectionModel.Current)
                break
            }
        }
    }

    selectionModel: ItemSelectionModel { model: headerModel }
    model: KItemModels.KColumnHeadersModel {
        id: headerModel
        sourceModel: header.view.model
        sortColumn: header.currentColumn
        sortOrder: header.sortOrder
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton

        onTapped: (eventPoint, button) => {
            let cell = header.cellAtPosition(eventPoint.position)
            if (cell.x == header.currentColumn) {
                header.sortOrder = header.sortOrder == Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder
                header.sort(header.sortColumn, header.sortOrder)
            } else {
                header.sortOrder = model.Unit == Formatter.Units.UnitNone || model.Unit == Formatter.Units.UnitInvalid ? Qt.AscendingOrder : Qt.DescendingOrder
                eventPoint.accepted = false
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton

        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: (eventPoint, button) => {
            let cell = header.cellAtPosition(eventPoint.position)
            header.contextMenuRequested(cell.x, eventPoint.scenePosition)
        }
    }
}
