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

    property var model: StickersPackModel {}

    SignalSpy {
       id: countSpy
       target: model
       signalName: "rowCountChanged"
    }

    SignalSpy {
       id: stickerPackChangedSpy
       target: model
       signalName: "dataChanged"
    }

    SignalSpy {
       id: stickerPathChangedSpy
       target: model
       signalName: "stickerPathChanged"
    }

    SignalSpy {
        id: stickerPackCreatedSpy
        target: model
        signalName: "packCreated"
    }

    SignalSpy {
        id: stickerPackRemovedSpy
        target: model
        signalName: "packRemoved"
    }



    UbuntuTestCase {
        id: test
        name: 'stickersPackModelTestCase'
        when: windowShown


        function init() {
            model.stickerPath = TestContext.testDir + "/stickers"
        }

        function cleanup() {
            TestContext.clear()
            model.stickerPath = ""
            stickerPathChangedSpy.wait()
            countSpy.clear()
            stickerPackChangedSpy.clear()
            stickerPathChangedSpy.clear()
            stickerPackCreatedSpy.clear()
            stickerPackRemovedSpy.clear()
        }

        function test_modelIsEmpty() {
            model.stickerPath = ""
            stickerPathChangedSpy.wait()
            compare(model.count, 0)
        }


        function test_createPack() {
            stickerPackCreatedSpy.clear()
            model.createPack();
            countSpy.wait()
            compare(model.count, 2)
            compare(stickerPackCreatedSpy.count, 1)
        }

        function test_removePack() {
            var stickerPack = model.get(0)
            model.removePack(stickerPack.packName)
            countSpy.wait()
            compare(model.count, 0)
            compare(stickerPackRemovedSpy.count, 1)
        }


        function test_addSticker() {
            var stickerPack = model.get(0)
            compare(stickerPack.stickersCount, 0)
            model.addSticker(stickerPack.packName, Qt.resolvedUrl("../data/sample.png"))

            stickerPack = model.get(0)
            compare(stickerPack.stickersCount, 1)
        }

        function test_removeSticker() {
            var stickerPack = model.get(0)
            compare(stickerPack.stickersCount, 0)
            model.addSticker(stickerPack.packName, Qt.resolvedUrl("../data/sample.png"))
            stickerPack = model.get(0)
            compare(stickerPack.stickersCount, 1)

            model.removeSticker(stickerPack.packName, stickerPack.thumbnail)
            countSpy.wait()
            //pack is removed
            compare(model.count, 0)
        }


    }

}
