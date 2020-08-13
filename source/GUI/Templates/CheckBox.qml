
import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Window 2.15

T.CheckBox {
    id: control

    property double modif: 1.5*Math.min(Screen.height,Screen.width)/2160

    implicitWidth: 1.5*Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6

    // keep in sync with CheckDelegate.qml (shared CheckIndicator.qml was removed for performance reasons)
    indicator: Rectangle {
        implicitWidth: modif*28
        implicitHeight: modif*28

        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding) : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2

        color: control.down ? control.palette.light : control.palette.base
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? control.palette.highlight : control.palette.mid

        ColorImage {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: 1*modif*28
            height: 1*modif*28
            defaultColor: "#353637"
            color: control.palette.text
            source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/check.png"
            visible: control.checkState === Qt.Checked
        }

        Rectangle {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: modif*16
            height: modif*3
            color: control.palette.text
            visible: control.checkState === Qt.PartiallyChecked
        }
    }

    contentItem: CheckLabel {
        leftPadding: 0.9*modif*(control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0)
        rightPadding: 0.9*modif*(control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0)

        text: control.text
        font.family: control.font.family
        font.pointSize: 9
        color: control.palette.windowText
    }
}
