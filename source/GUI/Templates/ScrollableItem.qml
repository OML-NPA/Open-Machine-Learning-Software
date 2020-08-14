import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2

Flickable{
    contentWidth: pane.implicitWidth
    contentHeight: pane.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.AutoFlickIfNeeded
    clip: true
    property double pix: Screen.width/3840
    default property alias content : pane.contentItem
    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }
    Pane {
        id:pane
        padding: 0
    }
    ScrollBar.vertical: ScrollBar{
        id: vertical
        policy: ScrollBar.AsNeeded
        contentItem:
            Rectangle {
                implicitWidth: 25*pix
                implicitHeight: 100
                color: "transparent"
                Rectangle {
                    anchors.right: parent.right
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
        contentItem:
            Rectangle {
                implicitWidth: 100
                implicitHeight: 25*pix
                color: "transparent"
                Rectangle {
                    anchors.bottom: parent.bottom
                    implicitWidth: parent.width
                    implicitHeight: 10*pix
                    radius: height / 2
                    color: horizontal.pressed ? systempalette.dark : systempalette.mid
                }
        }
    }

}
