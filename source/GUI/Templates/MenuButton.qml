
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Window 2.2

T.Button {
    id: control

    property double margin: 0.02*Screen.width
    property double pix: Screen.width/3840
    property double tabmargin: 0.5*margin
    property double font_size: 9
    property bool buttonfocus: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    horizontalPadding: padding + 2
    spacing: 6

    icon.width: 24
    icon.height: 24
    icon.color: control.checked || control.highlighted ? control.palette.brightText :
                control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        Text {
            text: control.text
            anchors.fill: parent
            font.family: "Proxima Nova"//control.font.family
            font.pointSize: font_size
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            leftPadding: tabmargin
        }


        color: control.checked || control.highlighted ? control.palette.brightText :
               control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText
    }

    background: Rectangle {
        anchors.fill: parent.fill
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.pressed ? defaultpalette.buttonpressed :
               control.hovered && !control.buttonfocus ? defaultcolors.midlight3:
               control.buttonfocus ? defaultpalette.window: defaultpalette.window2
        border.color: control.palette.dark
        border.width: 0
        Rectangle {
                y: -1*pix
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: control.width
                height: 2*pix
        }
        Rectangle {
                y: control.height
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: control.width
                height: 2*pix
        }
    }
}
