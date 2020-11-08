

import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import QtCharts 2.15
import "Templates"
import org.julialang 1.0

ApplicationWindow {
    id: validationWindow
    visible: true
    minimumHeight: Math.max(1024*pix,informationPane.height)
    maximumHeight: Math.max(1024*pix,informationPane.height)
    minimumWidth: informationPane.width + 1024*pix
    title: qsTr("  Deep Data Analysis Software")
    color: defaultpalette.window
    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height

    onWidthChanged: {
        if (validationTimer.running) {return}
        var ind1 = sampleSpinBox.value
        var ind2 = featureComboBox.currentIndex+1
        var modif = (validationWindow.width-700*pix)/originalDisplay.width
        originalDisplay.width = validationWindow.width-700*pix
        resultDisplay.width = validationWindow.width-700*pix
        originalDisplay.height = originalDisplay.height*modif
        resultDisplay.height = originalDisplay.height*modif
        originalDisplay.contentsScale = originalDisplay.contentsScale*modif
        resultDisplay.contentsScale = resultDisplay.contentsScale*modif
        informationPane.height = informationPane.height*modif
    }

    onClosing: {
        trainingplotLoader.sourceComponent = undefined
        validateButton.text = "Validate"
        progressbar.value = 0
    }

    Timer {
        id: validationTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            validationProgressBar.value = Julia.get_data(["Training","Validation_plot","progress"])
            if (Julia.get_data(["Training","Validation_plot","validation_done"])) {
                progressbar.value = 1
                repeat = false
                running = false
                var ind1 = sampleSpinBox.value
                var ind2 = featureComboBox.currentIndex+1
                get_image(originalDisplay,"data_input_orig",[ind1])
                get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
            }
            loss.text = mean(Julia.get_data(["Training","Validation_plot","loss"])).toFixed(2)
            accuracy.text = mean(Julia.get_data(["Training","Validation_plot","accuracy"])).toFixed(2)
            loss.text = loss.text + " ± " +
                Julia.get_data(["Training","Validation_plot","loss_std"]).toFixed(2)
            accuracy.text = accuracy.text + " ± " +
                Julia.get_data(["Training","Validation_plot","accuracy_std"]).toFixed(2)
            var accuracy_std_in = Julia.get_data(["Training","Validation_plot","accuracy_std_in"])
        }
    }
    Item {
        Item {
            id: displayItem
            x: 0.5*margin
            y: (validationWindow.height-originalDisplay.height)/2
            height: Math.max(1024*pix,originalDisplay.height)
            width: Math.max(1024*pix,originalDisplay.width + 0.8*margin)
            JuliaDisplay {
                id: originalDisplay
                width: 1024*pix
                height: 1024*pix
            }
            JuliaDisplay {
                id: resultDisplay
                opacity: 0.5
                width: 1024*pix
                height: 1024*pix
            }
        }
        Pane {
            id: informationPane
            x: displayItem.width
            height: Math.max(validationWindow.height,1024*pix)
            width: 700*pix
            padding: 0.5*margin
            backgroundColor: defaultpalette.window2
            Column {
                id: informationColumn
                spacing: 0.4*margin
                Row {
                    spacing: 0.3*margin
                    ProgressBar {
                        id: validationProgressBar
                        width: 1.2*buttonWidth
                        height: buttonHeight
                    }
                    StopButton {
                        id: stoptraining
                        width: buttonHeight
                        height: buttonHeight
                        onClicked: Julia.set_data(["Training","stop_training"],true)
                    }
                }
                Label {
                    topPadding: 0.2*margin
                    text: "Validation information"
                    font.bold: true
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        id: accuracyLabel
                        text: "Accuracy:"
                    }
                    Label {
                        id: accuracy
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Loss:"
                        width: accuracyLabel.width
                    }
                    Label {
                        id: loss
                    }
                }
                Label {
                    topPadding: 0.2*margin
                    text: "Visualization controls"
                    font.bold: true
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Sample:"
                        width: accuracyLabel.width
                    }
                    SpinBox {
                        id: sampleSpinBox
                        from: 1
                        value: 1
                        to: Julia.get_data(["Training","Validation_plot","data_input_orig"]).length
                        stepSize: 1
                        editable: false
                        onValueModified: {
                            var ind1 = sampleSpinBox.value
                            var ind2 = featureComboBox.currentIndex+1
                            get_image(originalDisplay,"data_input_orig",[ind1])
                            get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Feature:"
                        width: accuracyLabel.width
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: featureComboBox
                        editable: false
                        width: 0.64*buttonWidth-1*pix
                        model: ListModel {
                            id: featureselectModel
                        }
                        onActivated: {
                            var ind1 = sampleSpinBox.value
                            var ind2 = featureComboBox.currentIndex+1
                            get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                        }
                        Component.onCompleted: {
                            for (var i=0;i<featureModel.count;i++) {
                                featureselectModel.append(
                                    {"name": featureModel.get(i).name})
                            }
                            currentIndex = 0
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Show:"
                        width: accuracyLabel.width
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: typeComboBox
                        property string type: "data_predicted"
                        editable: false
                        currentIndex: 0
                        width: 0.64*buttonWidth-1*pix
                        model: ListModel {
                            id: typeModel
                            ListElement {name: "Result"}
                            ListElement {name: "Error"}
                        }
                        onActivated: {
                            if (typeComboBox.currentIndex==0) {
                                type = "data_predicted"
                            }
                            else {
                                type = "data_error"
                            }
                            get_image(resultDisplay,type,
                                [sampleSpinBox.value,featureComboBox.currentIndex+1])
                        }
                    }
                }
            }
        }
    }
    MouseArea {
        width: validationWindow.width
        height: validationWindow.height
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
    function get_image(display,type,inds) {
        var size = Julia.get_image(["Training","Validation_plot",type],
            [0,0],inds)
        var ratio = size[0]/size[1]
        if (ratio<1) {
            display.height = display.width*ratio
        }
        else {
            display.width = display.height/ratio
        }
        Julia.display_image(display)
    }
}
