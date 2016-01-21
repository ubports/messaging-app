import QtQuick 2.0
//import Unity.InputInfo 0.1

Item {
    // FIXME: implement correctly without relying on unity private stuff
    property bool hasMouse: mainView.dualPanel //miceModel.count > 0 || touchPadModel.count > 0
    property bool hasKeyboard: false //keyboardsModel.count > 0

    /*InputDeviceModel {
        id: miceModel
        deviceFilter: InputInfo.Mouse
    }

    InputDeviceModel {
        id: touchPadModel
        deviceFilter: InputInfo.TouchPad
    }

    InputDeviceModel {
        id: keyboardsModel
        deviceFilter: InputInfo.Keyboard
    }*/
}

