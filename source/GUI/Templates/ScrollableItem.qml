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
    property color backgroundColor: "white"
    property color scrollbarColor: defaultpalette.window
    default property alias content : pane.contentItem

    Pane {

        id:pane
        anchors.fill: parent
        padding: 0
        background: Rectangle {anchors.fill: parent; color: backgroundColor}
    }
    ScrollBar.vertical: ScrollBar{
        id: vertical
        x: 2*pix
        background: Rectangle {
            width: 20*pix
            anchors.right: parent.right
            color: showBackground ? scrollbarColor : "transparent"
        }

        contentItem:
            Rectangle {
                implicitWidth: 25*pix
                implicitHeight: 100
                color: "transparent"
                Rectangle {
                    //anchors.right: parent.right
                    x: 13*pix
                    y: 2*pix
                    implicitWidth: 10*pix
                    implicitHeight: parent.height - 4*pix
                    radius: width / 2
                    visible: contentHeight > flickable.height
                    color: defaultpalette.border
                }
        }
    }
    ScrollBar.horizontal: ScrollBar{
        id: horizontal
        background: Rectangle {
            height: 20*pix
            anchors.bottom: parent.bottom
            color: showBackground ? scrollbarColor : "transparent"
        }

        contentItem:
            Rectangle {
                implicitWidth: 100
                implicitHeight: 25*pix
                color: "transparent"
                Rectangle {
                    x: 2*pix
                    y: 13*pix
                    implicitWidth: parent.width - 4*pix
                    implicitHeight: 10*pix
                    radius: height / 2
                    visible: contentWidth > flickable.width
                    color: defaultpalette.border
                }
        }
    }

}
