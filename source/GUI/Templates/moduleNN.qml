import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2

Rectangle {
    width: 100
    height: 100
}


/*
Rectangle {
    id: unit
    height: buttonWidth/2
    width: buttonWidth/2
    radius: 8*pix
    color: "#fafafa"
    border.color: systempalette.mid
    border.width: 3*pix
    MouseArea {
        anchors.fill: parent
        drag.target: parent
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.maximumX: mainPane.width - unit.width
        drag.minimumY: 0
        hoverEnabled: true
        onEntered: {
            unit.border.color = "#666666"
            upNode.visible = true
            downNode.visible = true
        }
        onExited: {
            unit.border.color = systempalette.mid
            upNode.visible = false
            downNode.visible = false
        }
    }
    Rectangle {
        id: upNode
        width: buttonHeight/3
        height: buttonHeight/3
        radius: buttonHeight/3
        border.color: systempalette.mid
        border.width: 3*pix
        visible: false
        x: unit.width/2-upNode.radius/2
        y: -upNode.radius/2 + 1.5*pix
    }
    Rectangle {
        width: 2*buttonHeight/3
        height: 2*buttonHeight/3
        color: "transparent"
        border.color: "transparent"
        border.width: 0
        x: unit.width/2-upNode.radius
        y: -upNode.radius + 1.5*pix
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                upNode.visible = true
                downNode.visible = true
                upNode.border.color = "#666666"
            }
            onExited: {
                upNode.visible = false
                downNode.visible = false
                upNode.border.color = systempalette.mid
            }
        }
    }

    Rectangle {
        id: downNode
        width: buttonHeight/3
        height: buttonHeight/3
        radius: buttonHeight/3
        border.color: systempalette.mid
        border.width: 3*pix
        visible: false
        x: unit.width/2-downNode.radius/2
        y: 0.88*unit.height+downNode.radius/2
    }
    Rectangle {
        width: 2*buttonHeight/3
        height: 2*buttonHeight/3
        color: "transparent"
        border.color: "transparent"
        border.width: 0
        x: unit.width/2-downNode.radius/2
        y: 0.88*unit.height+downNode.radius/2
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                upNode.visible = true
                downNode.visible = true
                downNode.border.color = "#666666"
            }
            onExited: {
                upNode.visible = false
                downNode.visible = false
                downNode.border.color = systempalette.mid
            }
        }
    }

}



*/
