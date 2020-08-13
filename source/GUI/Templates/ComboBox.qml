
import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.impl 2.14
import QtQuick.Templates 2.14 as T

T.ComboBox {
    id: control
    implicitWidth: 0.7*defaultWidth
    implicitHeight: defaultHeight

    property double defaultWidth: 0.1*Screen.width
    property double defaultHeight: 0.03*Screen.height
    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }

    //implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
    //                        implicitContentWidth + leftPadding + rightPadding)
    //implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
    //                         implicitContentHeight + topPadding + bottomPadding,
    //                         implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)

    delegate: ItemDelegate {
        width: parent.width
        text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        palette.text: control.palette.text
        palette.highlightedText: control.palette.text//control.palette.highlightedText
        font.weight: control.currentIndex === index ? Font.DemiBold : Font.Normal
        highlighted: control.highlightedIndex === index
        hoverEnabled: control.hoverEnabled
    }
    contentItem: T.TextField {
        leftPadding: !control.mirrored ? 12 : control.editable && activeFocus ? 3 : 1
        rightPadding: control.mirrored ? 12 : control.editable && activeFocus ? 3 : 1
        topPadding: 6 - control.padding
        bottomPadding: 6 - control.padding

        text: control.editable ? control.editText : control.displayText

        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator

        font.family: control.font.family
        font.pointSize: 9
        color: control.editable ? control.palette.text : control.palette.buttonText
        selectionColor: control.palette.highlight
        selectedTextColor: control.palette.highlightedText
        verticalAlignment: Text.AlignVCenter

        background: Rectangle {
            visible: control.enabled && control.editable && !control.flat
            border.width: parent && parent.activeFocus ? 2 : 1
            border.color: parent && parent.activeFocus ? control.palette.highlight : control.palette.dark//control.palette.button
            color: control.palette.base
        }
    }

    indicator: ColorImage {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.palette.dark
        defaultColor: "#353637"
        source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/double-arrow.png"
        opacity: enabled ? 1 : 0.3
    }

    background: Rectangle {
        implicitWidth: 140
        implicitHeight: 40

        color: control.down ? control.palette.mid : "#fafafa"//control.palette.button
        border.color: control.palette.dark
        border.width: !control.editable && control.visualFocus ? 2 : 2
        visible: !control.flat || control.down
    }

    popup: T.Popup {
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight, control.Window.height - topMargin - bottomMargin)
        topMargin: 6
        bottomMargin: 6

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0

            Rectangle {
                z: 10
                width: parent.width
                height: parent.height
                color: "transparent"
                border.color: control.palette.mid
            }

            T.ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: "#fafafa"//control.palette.window
        }
    }
}
