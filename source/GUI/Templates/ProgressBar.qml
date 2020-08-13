
import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Window 2.2

T.ProgressBar {
    id: control
    property real backgroundHeight: 6*Screen.width/3840
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    contentItem: ProgressBarImpl {
        implicitHeight: backgroundHeight
        implicitWidth: 116
        scale: control.mirrored ? -1 : 1
        progress: control.position
        indeterminate: control.visible && control.indeterminate
        color: "#3498db"
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 6
        radius: 8*Screen.width/3840
        y: (control.height - height) / 2
        height: backgroundHeight

        color: control.palette.midlight
    }
}
