/*
 * Copyright 2012-2015 Canonical Ltd.
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

.pragma library

function areSameDay(date1, date2) {
    if (!date1 || !date2)
        return false

    return date1.getFullYear() == date2.getFullYear()
        && date1.getMonth() == date2.getMonth()
        && date1.getDate() == date2.getDate()
}

function formatLogDate(timestamp) {
    var today = new Date()
    var date = new Date(timestamp)
    if (areSameDay(today, date)) {
        return Qt.formatTime(timestamp, Qt.DefaultLocaleShortDate)
    } else {
        return Qt.formatDateTime(timestamp, Qt.DefaultLocaleShortDate)
    }
}

function friendlyDay(timestamp, i18n) {
    var date = new Date(timestamp);
    var today = new Date();
    if (areSameDay(today, date)) {
        return i18n.tr("Today");
    } else {
        var yesterday = new Date();
        yesterday.setDate(today.getDate()-1);
        if (areSameDay(yesterday, date)) {
            return i18n.tr("Yesterday");
        } else {
            return Qt.formatDate(date, Qt.DefaultLocaleShortDate);
        }
    }
}

function formatFriendlyDate(timestamp) {
    return Qt.formatTime(timestamp, Qt.DefaultLocaleShortDate) + " - " + friendlyDay(timestamp);
}


function formattedTime(time) {
    var d = new Date(0, 0, 0, 0, 0, time)
    return d.getHours() == 0 ? Qt.formatTime(d, "mm:ss") : Qt.formatTime(d, "h:mm:ss")
}
