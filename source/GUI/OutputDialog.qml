
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
    minimumWidth: gridLayout.width
    minimumHeight: 800*pix
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height

    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double tabmargin: 0.5*margin
    property double pix: Screen.width/3840

    property bool terminate: false

    onClosing: {
        Julia.save_model("models/" + modelName + ".model")
        analysisfeaturedialogLoader.sourceComponent = null
    }

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            Pane {
                id: menuPane
                spacing: 0
                padding: -1
                width: 1.3*buttonWidth
                height: window.height
                topPadding: tabmargin/2
                bottomPadding: tabmargin/2
                backgroundColor: defaultpalette.window2

                Column {
                    id: menubuttonColumn
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: [{"name": "Mask", "stackview": maskView},
                            {"name": "Area", "stackview": areaView},
                            {"name": "Volume", "stackview": volumeView}]
                        delegate : MenuButton {
                            id: general
                            width: 1.5*buttonWidth
                            height: 1.25*buttonHeight
                            onClicked: {
                                stack.push(modelData.stackview);
                                for (var i=0;i<(menubuttonRepeater.count);i++) {
                                    menubuttonRepeater.itemAt(i).buttonfocus = false
                                }
                                buttonfocus = true
                            }
                            text: modelData.name
                        }
                    }
                }
            }
            ColumnLayout {
                id: columnLayout
                Layout.margins: 0.5*margin
                Layout.row: 2
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 2.125*buttonWidth
                StackView {
                    id: stack
                    initialItem: maskView
                    pushEnter: Transition {
                        PropertyAnimation {
                            from: 0
                            to:1
                            duration: 0
                        }
                    }
                    pushExit: Transition {
                        PropertyAnimation {
                            from: 1
                            to:0
                            duration: 0
                        }
                    }
                    popEnter: Transition {
                        PropertyAnimation {
                            property: "opacity"
                            from: 0
                            to:1
                            duration: 0
                        }
                    }
                    popExit: Transition {
                        PropertyAnimation {
                            from: 1
                            to:0
                            duration: 0
                        }
                    }

                }
                Component {
                    id: maskView
                    Column {
                        spacing: 0.2*margin
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            id: maskCheckBox
                            text: "Mask"
                            Component.onCompleted: {
                                maskCheckBox.checkState =
                                        Julia.get_output(["Mask","mask"],indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Mask","mask"],indTree+1,value)
                            }
                        }
                    }
                }
                Component {
                    id: areaView
                    Column {
                        spacing: 0.2*margin
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            id: areadistributionCheckBox
                            text: "Area distribution"
                            Component.onCompleted: {
                                areadistributionCheckBox.checkState = Julia.get_output(
                                    ["Area","area_distribution"],indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","area_distribution"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: individualobjareaCheckBox
                            text: "Individual object area"
                            Component.onCompleted: {
                                individualobjareaCheckBox.checkState = Julia.get_output(
                                    ["Area","individual_obj_area"],indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","individual_obj_area"],indTree+1,value)
                            }
                        }
                        Rectangle {
                            height: 0.2*margin
                            width: 0.2*margin
                            color: defaultpalette.window
                        }
                        Label {
                            text: "Histogram options:"
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            ColumnLayout {
                                spacing: 0.55*margin
                                Label {
                                    id: label
                                    text: "Number of bins:"
                                }
                                Label {
                                    text: "Maximum Area:"
                                    bottomPadding: 0.05*margin
                                }
                            }
                            ColumnLayout {
                                TextField {
                                    id: areanumbinsTextField
                                    Layout.preferredWidth: 0.25*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999;}
                                    Component.onCompleted: {
                                        areanumbinsTextField.text = Julia.get_output(
                                            ["Area","num_bins"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Area","num_bins"],indTree+1,value)
                                    }
                                }
                                TextField {
                                    id: maxareaTextField
                                    Layout.preferredWidth: 0.25*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999;}
                                    Component.onCompleted: {
                                        maxareaTextField.text =
                                            Julia.get_output(["Area","max_area"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Area","max_area"],indTree+1,value)
                                    }
                                }
                            }
                            ColumnLayout {
                                spacing: 0.6*margin
                                Label {
                                    Layout.alignment : Qt.AlignLeft
                                }
                                Label {
                                    Layout.alignment : Qt.AlignLeft
                                    text: "m\u00B2"
                                }
                            }
                        }
                    }
                }
                Component {
                    id: volumeView
                    Column {
                        spacing: 0.2*margin
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            id: volumedistributionCheckBox
                            text: "Volume distribution"
                            Component.onCompleted: {
                                volumedistributionCheckBox.checkState = Julia.get_output(
                                    ["Volume","volume_distribution"],indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","volume_distribution"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: individualobjvolumeCheckBox
                            text: "Individual object volume"
                            Component.onCompleted: {
                                individualobjvolumeCheckBox.checkState = Julia.get_output(
                                    ["Volume","individual_obj_volume"],indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","individual_obj_volume"],indTree+1,value)
                            }
                        }
                        Rectangle {
                            height: 0.2*margin
                            width: 0.2*margin
                            color: defaultpalette.window
                        }

                        Label {
                            text: "Histogram options:"
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            ColumnLayout {
                                spacing: 0.55*margin
                                Label {
                                    id: label
                                    text: "Number of bins:"
                                }
                                Label {
                                    text: "Maximum volume:"
                                    bottomPadding: 0.05*margin
                                }
                            }
                            ColumnLayout {
                                TextField {
                                    id: volumenumbinsTextField
                                    Layout.preferredWidth: 0.25*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999;}
                                    Component.onCompleted: {
                                        volumenumbinsTextField.text = Julia.get_output(
                                            ["Volume","num_bins"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Volume","num_bins"],indTree+1,value)
                                    }
                                }
                                TextField {
                                    id: maxvolumeTextField
                                    Layout.preferredWidth: 0.25*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999;}
                                    Component.onCompleted: {
                                        maxvolumeTextField.text = Julia.get_output(
                                            ["Volume","max_volume"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Volume","max_volume"],indTree+1,value)
                                    }
                                }
                            }
                            ColumnLayout {
                                spacing: 0.6*margin
                                Label {
                                    Layout.alignment : Qt.AlignLeft
                                }
                                Label {
                                    Layout.alignment : Qt.AlignLeft
                                    text: "µm\u00B3"
                                }
                            }
                        }
                    }
                }
                /*Component {
                    id: motherdaugtherassignmentView
                    Column {
                        spacing: 0.2*margin
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            text: "Mother and daugther assignment"
                        }
                        CheckBox {
                            text: "Mother and daugther volume"
                        }
                        CheckBox {
                            text: "Mother and daugther circularity"
                        }
                        Rectangle {
                            height: 0.2*margin
                            width: 0.2*margin
                            color: defaultpalette.window
                        }

                        Label {
                            text: "Bud definition:"
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            Label {
                                Layout.alignment : Qt.AlignRight
                                Layout.row: 1
                                wrapMode: Label.WordWrap
                                text: "Maximum percentage of mother volume:"
                                bottomPadding: 0.05*margin
                            }
                            TextField {
                                Layout.row: 2
                                Layout.preferredWidth: 0.15*buttonWidth
                                Layout.preferredHeight: buttonHeight
                                maximumLength: 2
                                validator: RegularExpressionValidator { regularExpression: /[0-9]+/ }
                            }
                            Label {
                                Layout.alignment : Qt.AlignLeft
                                Layout.row: 1
                                wrapMode: Label.WordWrap
                                text: "%"
                                bottomPadding: 0.05*margin
                            }

                        }
                    }
               }*/
           }
        }
        MouseArea {
            id: backgroundMouseArea
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

}
