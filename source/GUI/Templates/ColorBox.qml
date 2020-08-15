
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T

T.Frame {
    id: control
    property var colorRGB: [1,1,1]
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    padding: 12

    background: Rectangle {
        anchors.fill: parent.fill

        color: typeof(colorRGB)=="undefined" ? "white" :
              Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255,1.0)
        border.width: 1
    }
}
