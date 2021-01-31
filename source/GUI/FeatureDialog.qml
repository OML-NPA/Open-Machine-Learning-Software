
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
    width: columnLayout.width
    height: columnLayout.height
    color: defaultpalette.window

    onClosing: {featuredialogLoader.sourceComponent = null}

    ColumnLayout {
        id: columnLayout
        Column {
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
                        Layout.preferredWidth: 400*pix
                        Layout.preferredHeight: buttonHeight
                    }
                    ComboBox {
                        id: parentComboBox
                        Layout.preferredWidth: 400*pix
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
                    id: borderLabel
                    width: 400*pix
                    text: "Border is important:"
                }
                CheckBox {
                    id: borderCheckBox
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
            Row {
                spacing: 0.3*margin
                Label {
                    visible: borderCheckBox.checkState==Qt.Checked
                    text: "Border thickness (pix):"
                    width: 400*pix
                }
                SpinBox {
                    id: bordernumpixelsSpinBox
                    visible: borderCheckBox.checkState==Qt.Checked
                    from: 0
                    to: 9
                    stepSize: 1
                    property double realValue
                    textFromValue: function(value, locale) {
                        realValue = (value)*2+1
                        return realValue.toLocaleString(locale,'f',0)
                    }
                    onValueModified: {
                        featureModel.get(indTree).border_thickness = value
                    }
                    Component.onCompleted: {
                        value = featureModel.get(indTree).border_thickness
                    }
                }
            }
            Row {
                Label {
                    id: borderremoveobjsLabel
                    visible: borderCheckBox.checkState==Qt.Checked
                    width: 400*pix
                    wrapMode: Label.WordWrap
                    text: "Ignore objects with broken border:"
                }
                CheckBox {
                    visible: borderCheckBox.checkState==Qt.Checked
                    onClicked: {
                        if (checkState==Qt.Checked) {
                            featureModel.get(indTree).borderRemoveObjs = true
                        }
                        if (checkState==Qt.Unchecked) {
                            featureModel.get(indTree).borderRemoveObjs = false
                        }
                    }
                    Component.onCompleted: {
                        checkState = featureModel.get(indTree).borderRemoveObjs ?
                            Qt.Checked : Qt.Unchecked
                    }
                }
            }
            Row {
                spacing: 0.3*margin
                Label {
                    id: minareaLabel
                    text: "Minimum object area:"
                    width: 400*pix
                    topPadding: 10*pix
                }
                TextField {
                    id: minareaTextField
                    width: 140*pix
                    text: featureModel.get(indTree).min_area
                    validator: RegExpValidator { regExp: /([1-9]\d{0,5})/ }
                    onEditingFinished: {
                        featureModel.get(indTree).min_area = parseInt(text)
                    }
                }
            }
            Button {
                id: applyButton
                text: "Apply"
                x: columnLayout.width/2 -applyButton.width/1.20
                width: buttonWidth/2
                height: buttonHeight
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
                                          feature.border_thickness,
                                          feature.borderRemoveObjs,
                                          feature.min_area,
                                          feature.parent)
                    featuredialogLoader.sourceComponent = null
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










