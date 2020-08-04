import QtQuick 2.11
import QtQuick.Window 2.11


ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("Start Window")
    onC: {
        var component = Qt.createComponent("qrc:/Editor.qml");
        component.createObject();
    }
}
