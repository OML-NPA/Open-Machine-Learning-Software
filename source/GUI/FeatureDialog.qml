
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
    title: qsTr("  Open Machine Learning Software")
    minimumWidth: columnLayout.width
    minimumHeight: columnLayout.height
    maximumWidth: columnLayout.width
    maximumHeight: columnLayout.height
    color: defaultpalette.window

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










