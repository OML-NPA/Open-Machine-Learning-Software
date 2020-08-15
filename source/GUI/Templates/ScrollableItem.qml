import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2

Flickable{
    id: flickable
    contentWidth: pane.implicitWidth
    contentHeight: pane.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.AutoFlickIfNeeded
    clip: true
    property double pix: Screen.width/3840
    property bool showBackground: true
    default property alias content : pane.contentItem
    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }

    Frame {
        id:pane
        padding: 0
    }
    ScrollBar.vertical: ScrollBar{
        id: vertical
        policy: ScrollBar.AsNeeded
        background: Rectangle {
            width: 20*pix
            anchors.right: parent.right
            color: showBackground ? systempalette.window : "transparent"
        }

        contentItem:
            Rectangle {
                implicitWidth: 25*pix
                implicitHeight: 100
                color: "transparent"
                Rectangle {
                    //anchors.right: parent.right
                    x: 13*pix
                    implicitWidth: 10*pix
                    implicitHeight: parent.height
                    radius: width / 2
                    color: vertical.pressed ? systempalette.dark : systempalette.mid
                }
        }
    }
    ScrollBar.horizontal: ScrollBar{
        id: horizontal
        policy: ScrollBar.AsNeeded

        background: Rectangle {
            height: 20*pix
            anchors.bottom: parent.bottom
            color: showBackground ? systempalette.window : "transparent"
        }

        contentItem:
            Rectangle {
                implicitHeight: 25*pix
                implicitWidth: 100
                color: "transparent"
                Rectangle {
                    //anchors.right: parent.right
                    y: 13*pix
                    implicitHeight: 10*pix
                    implicitWidth: parent.height
                    radius: width / 2
                    color: vertical.pressed ? systempalette.dark : systempalette.mid
                }
        }
    }

}
