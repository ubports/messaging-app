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
       id: rowsMovedSpy
       target: model
       signalName: "rowsMoved"
    }

    SignalSpy {
       id: dataChangedSpy
       target: model
       signalName: "dataChanged"
    }

    SignalSpy {
       id: rowsRemovedSpy
       target: model
       signalName: "rowsRemoved"
    }

    UbuntuTestCase {
        id: test
        name: 'stickersHistoryModelTestCase'
        when: windowShown

        function init() {
            model.databasePath = ":memory:"
            model.limit = 10
        }

        function cleanup() {
            model.databasePath = ""
            countSpy.clear()
            rowsInsertedSpy.clear()
            dataChangedSpy.clear()
            rowsMovedSpy.clear()
            rowsRemovedSpy.clear()
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
            model.add("foo")
            compare(model.count, 1)
            compare(countSpy.count, 1)
            compare(rowsInsertedSpy.count, 1)
            compare(rowsInsertedSpy.signalArguments[0][1], 0) // first
            compare(rowsInsertedSpy.signalArguments[0][2], 0) // last

            model.add("bar")
            compare(model.count, 2)
            compare(countSpy.count, 2)
            compare(rowsInsertedSpy.count, 2)
            compare(rowsInsertedSpy.signalArguments[0][1], 0) // first
            compare(rowsInsertedSpy.signalArguments[0][2], 0) // last
        }

        function test_signals() {
            model.limit = 2

            model.add("a")
            compare(model.count, 1)
            compare(countSpy.count, 1)
            compare(rowsInsertedSpy.count, 1)
            compare(rowsInsertedSpy.signalArguments[0][1], 0) // first
            compare(rowsInsertedSpy.signalArguments[0][2], 0) // last

            model.add("a")
            compare(dataChangedSpy.count, 1)

            model.add("b")
            compare(model.count, 2)
            compare(countSpy.count, 2)
            compare(rowsInsertedSpy.count, 2)
            compare(rowsInsertedSpy.signalArguments[0][1], 0) // first
            compare(rowsInsertedSpy.signalArguments[0][2], 0) // last

            model.add("a")
            compare(rowsMovedSpy.count, 1)
            compare(rowsMovedSpy.signalArguments[0][1], 1) // from first
            compare(rowsMovedSpy.signalArguments[0][2], 1) // from last
            compare(rowsMovedSpy.signalArguments[0][4], 0) // to
            compare(dataChangedSpy.count, 2)

            model.add("c")
            compare(model.count, 2)
            compare(rowsRemovedSpy.count, 1)
            compare(rowsRemovedSpy.signalArguments[0][1], 2) // from
            compare(rowsRemovedSpy.signalArguments[0][2], 2) // to
        }

        function test_get_and_order() {
            model.add("a")
            // datetimes have only millisecond precision, and we want to prevent
            // the two entries to have the same timestamp
            wait(100)
            model.add("b")

            var a = model.get(1)
            verify(a !== null)
            compare(a.sticker, "a")

            var b = model.get(0)
            verify(b !== null)
            compare(b.sticker, "b")

            verify(b.mostRecentUse.toISOString() > a.mostRecentUse.toISOString())

            wait(100)
            model.add("a")

            a = model.get(0)
            verify(a !== null)
            compare(a.sticker, "a")

            b = model.get(1)
            verify(b !== null)
            compare(b.sticker, "b")

            verify(a.mostRecentUse.toISOString() > b.mostRecentUse.toISOString())
        }

        function test_limit_change() {
            model.add("d")
            model.add("c")
            model.add("b")
            model.add("a")
            model.limit = 2

            compare(model.count, 2)
            compare(model.get(0).sticker, "a")
            compare(model.get(1).sticker, "b")
        }
    }
}
