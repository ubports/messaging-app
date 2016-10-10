/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.2
import Ubuntu.History 0.1

Image {
    property int messageStatus: -1
    enabled: true
    height: enabled ? units.gu(1) : 0
    width: enabled ? undefined : 0
    fillMode: Image.PreserveAspectFit
    source: {
        if (!enabled) {
            return ""
        }
        if (messageStatus == HistoryThreadModel.MessageStatusDelivered) {
            return Qt.resolvedUrl("./assets/single_tick.svg")
        } else if (messageStatus == HistoryThreadModel.MessageStatusRead) {
            return Qt.resolvedUrl("./assets/double_tick.svg")
        }
        return ""
    }
    asynchronous: true
}
