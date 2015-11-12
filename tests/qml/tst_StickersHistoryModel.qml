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
import QtTest 1.0
import Ubuntu.Components 1.3
import Ubuntu.Test 0.1
import messagingapp.private 0.1
import messagingapptest.private 0.1

Item {
    id: root
    width: 1
    height: 1

    property var model: StickersHistoryModel

    SignalSpy {
       id: countSpy
       target: model
       signalName: "rowCountChanged"
    }

    SignalSpy {
       id: rowsInsertedSpy
       target: model
       signalName: "rowsInserted"
    }

    SignalSpy {
       id: dataChangedSpy
       target: model
       signalName: "dataChanged"
    }

    UbuntuTestCase {
        id: test
        name: 'stickersHistoryModelTestCase'
        when: windowShown

        function init() {
            model.databasePath = ":memory:"
        }

        function cleanup() {
            model.databasePath = ""
            countSpy.clear()
            rowsInsertedSpy.clear()
            dataChangedSpy.clear()
        }

        function test_initiallyEmpty() {
            compare(model.count, 0)
        }

        function test_addingEmptyOrInvalidDoesNothing() {
            model.add("")
            compare(model.count, 0)
            model.add(null)
            compare(model.count, 0)
            model.add(undefined)
            compare(model.count, 0)
        }

        function test_add_new() {
            compare(model.add("foo"), 1)
            compare(model.count, 1)
            compare(countSpy.count, 1)
            compare(rowsInsertedSpy.count, 1)
            compare(rowsInsertedSpy.signalArguments[0][1], 0) // first
            compare(rowsInsertedSpy.signalArguments[0][2], 0) // last

            compare(model.add("bar"), 1)
            compare(model.count, 2)
            compare(countSpy.count, 2)
            compare(rowsInsertedSpy.count, 2)
            compare(rowsInsertedSpy.signalArguments[0][1], 0) // first
            compare(rowsInsertedSpy.signalArguments[0][2], 0) // last
        }

        function test_add_existing() {
            compare(model.add("foo"), 1)
            compare(model.add("foo"), 2)
        }

        function test_get() {
            model.add("foo")
            model.add("foo")
            model.add("bar")

            var item = model.get(0)
            verify(item !== null)
            compare(item.sticker, "bar")
            compare(item.uses, 1)

            item = model.get(1)
            verify(item !== null)
            compare(item.sticker, "foo")
            compare(item.uses, 2)
        }
    }
}
