
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Window 2.2

T.Button {
    id: control

    property real size: 20

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }

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
        text: control.text
        font.family: "Proxima Nova"//control.font.family
        font.pointSize: 9
        color: control.checked || control.highlighted ? control.palette.brightText :
               control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText
    }

    background: Rectangle {
        implicitWidth: size
        implicitHeight: size
        radius: 2*size
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: Color.blend(control.checked || control.highlighted ? control.palette.dark : "#fafafa",
                                                                    control.palette.mid, control.down ? 0.5 : 0.0)
        border.color: control.palette.dark
        border.width: (Screen.width/3840)*(control.visualFocus ? 4 : 2)
        Rectangle {
            x: 1.08*size
            y: 1.08*size
            width: 1.15*size
            height: 1.15*size
            radius: 0.1*size
            color: Color.blend(control.checked || control.highlighted ? "#333333" : systempalette.shadow,
                               "#333333", control.down ? 0.5 : 0.0)
        }
    }
}
