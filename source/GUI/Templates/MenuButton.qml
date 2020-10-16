
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
    property bool horizontal: false

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

    FontMetrics {
        id: fontMetrics
        font.family: "Proxima Nova"
    }

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        Label {
            id: textText
            text: control.text
            font.family: "Proxima Nova"//control.font.family
            font.pointSize: font_size
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            leftPadding: horizontal ? 0 : tabmargin
            Component.onCompleted: {
                if (horizontal) {
                    var text_width = fontMetrics.advanceWidth(text)
                    x = (control.width - text_width)/2 - 0.22*text_width
                }
                else {
                    anchors.fill = parent
                }
            }
        }


        color: control.checked || control.highlighted ? control.palette.brightText :
               control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText
    }

    background: Rectangle {
        anchors.fill: parent.fill
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.pressed ? defaultpalette.buttonpressed :
               control.hovered && !control.buttonfocus ? defaultcolors.midlight2:
               control.buttonfocus ? defaultpalette.window: defaultpalette.window2
        border.color: control.palette.dark
        border.width: 0
        Rectangle {
                y: horizontal ? 0 : -1*pix
                x: horizontal ? -1*pix : 0
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: horizontal ? 2*pix : control.width
                height: horizontal ? control.height : 2*pix
        }
        Rectangle {
                y: horizontal ? 0 : control.height
                x: horizontal ? control.width : 0
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: horizontal ? 2*pix : control.width
                height: horizontal ? control.height : 2*pix
        }
    }
}
