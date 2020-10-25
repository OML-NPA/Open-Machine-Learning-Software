
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  Deep Data Analysis Software")
    minimumWidth: columnLayout.width
    minimumHeight: columnLayout.height
    maximumWidth: columnLayout.width
    maximumHeight: columnLayout.height

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }
    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double fontsize: Math.round(11*Screen.height/2160)
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double tabmargin: 0.5*margin
    property color menucolor: "#fafafa"
    property color defaultcolor: systempalette.window

    onClosing: {featuredialogLoader.sourceComponent = null}

    ColumnLayout {
        id: columnLayout
        ColumnLayout {
            Layout.margins: margin
            spacing: 0.4*margin
            RowLayout {
                spacing: 0.3*margin
                ColumnLayout {
                    Layout.alignment : Qt.AlignHCenter
                    spacing: 0.55*margin
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        text: "Name:"
                        bottomPadding: 0.05*margin
                    }
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Parent:"
                        bottomPadding: 0.05*margin
                    }
                }
                ColumnLayout {
                    TextField {
                        id: nameTextField
                        text: featureModel.get(indTree).name
                        Layout.alignment : Qt.AlignLeft
                        Layout.preferredWidth: 300*pix
                        Layout.preferredHeight: buttonHeight
                    }
                    ComboBox {
                        id: parentComboBox
                        Layout.preferredWidth: 300*pix
                        editable: false
                        model: nameModel
                        ListModel {
                            id: nameModel
                        }
                        Component.onCompleted: {
                            nameModel.append({"name": ""})
                            for (var i=0;i<featureModel.count;i++) {
                              if (i===indTree) continue
                              nameModel.append({"name": featureModel.get(i).name})
                            }
                            var name = featureModel.get(indTree).parent
                            if (name!=="") {
                                for (i=0;i<nameModel.count;i++) {
                                    if (nameModel.get(i).name===name) {
                                        currentIndex = i
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Row {
                Label {
                    topPadding: 7*pix
                    text: "Border is important:"
                }
                CheckBox {
                    onClicked: {
                        if (checkState==Qt.Checked) {
                            featureModel.get(indTree).border = true
                        }
                        if (checkState==Qt.Unchecked) {
                            featureModel.get(indTree).border = false
                        }
                    }
                    Component.onCompleted: {
                        checkState = featureModel.get(indTree).border ?
                            Qt.Checked : Qt.Unchecked
                    }
                }
            }
            /*Label {
                text: "Color (RGB):"
            }
            Row {
                topPadding: 0.1*margin
                bottomPadding: 0.4*margin
                spacing: 0.3*margin
                Label {
                    topPadding: 12*pix
                    text: "Red:"
                }
                TextField {
                    id: red
                    text: featureModel.get(indTree).colorR
                    width: 0.25*buttonWidth
                    height: buttonHeight
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                    if (parseFloat(red.text)>255) {
                            red.text = "255"
                        }
                    }
                }
                Label {
                    topPadding: 12*pix
                    text: "Green:"
                }
                TextField {
                    id: green
                    text: featureModel.get(indTree).colorG
                    width: 0.25*buttonWidth
                    height: buttonHeight
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                        if (parseFloat(green.text)>255) {
                            green.text = "255"
                        }
                    }
                }
                Label {
                    topPadding: 12*pix
                    text: "Blue:"
                }
                TextField {
                    id: blue
                    text: featureModel.get(indTree).colorB
                    width: 0.25*buttonWidth
                    height: buttonHeight
                    maximumLength: 3
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                        if (parseFloat(blue.text)>255) {
                            blue.text = "255"
                        }
                    }
                }
            }*/
            RowLayout {
                Layout.alignment : Qt.AlignHCenter
                spacing: 1.5*margin
                Button {
                    text: "Apply"
                    Layout.preferredWidth: buttonWidth/2
                    Layout.preferredHeight: buttonHeight
                    onClicked: {
                        var prev_name = featureModel.get(indTree).name
                        var new_name = nameTextField.text
                        if (prev_name!==new_name) {
                            for (var i=0;i<featureModel.count;i++) {
                                var element = featureModel.get(i)
                                if (element.parent===prev_name) {
                                    element.parent = new_name
                                }
                            }
                        }
                        var feature = featureModel.get(indTree)
                        feature.name = new_name
                        feature.parent = parentComboBox.currentText
                        /*feature.colorR = parseFloat(red.text)
                        feature.colorG = parseFloat(green.text)
                        feature.colorB = parseFloat(blue.text)
                        featureView.itemAtIndex(indTree).children[0].children[0].color =
                                rgbtohtml([featureModel.get(indTree).colorR,
                                           featureModel.get(indTree).colorG,
                                           featureModel.get(indTree).colorB])*/
                        Julia.update_features(indTree+1,
                                              feature.name,
                                              feature.colorR,
                                              feature.colorG,
                                              feature.colorB,
                                              feature.border,
                                              feature.parent)
                        featuredialogLoader.sourceComponent = null
                    }
                }
            }
        }
        MouseArea {
            width: window.width
            height: window.height
            onPressed: {
                focus = true
                mouse.accepted = false
            }
            onReleased: mouse.accepted = false;
            onDoubleClicked: mouse.accepted = false;
            onPositionChanged: mouse.accepted = false;
            onPressAndHold: mouse.accepted = false;
            onClicked: mouse.accepted = false;
        }
    }
//---FUNCTIONS----------------------------------------------------------

    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }
}










