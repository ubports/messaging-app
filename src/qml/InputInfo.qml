import QtQuick 2.0
import Unity.InputInfo 0.1

Item {
    property bool hasMouse: miceModel.count > 0 || touchPadModel.count > 0
    property bool hasKeyboard: keyboardsModel.count > 0

    InputDeviceModel {
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
    }

}

