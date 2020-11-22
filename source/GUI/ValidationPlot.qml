

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
    //maximumHeight: Math.max(1024*pix,informationPane.height)
    minimumWidth: informationPane.width + 1024*pix + margin
    title: qsTr("  Deep Data Analysis Software")
    color: defaultpalette.window
    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height

    onClosing: {
        trainingplotLoader.sourceComponent = undefined
        validateButton.text = "Validate"
        progressbar.value = 0
    }

    Timer {
        id: validationTimer
        interval: 200
        running: true
        repeat: true
        property int iteration: 0
        property int max_iterations: 0
        property var accuracy: []
        property var loss: []
        property double mean_accuracy
        property double mean_loss
        property double accuracy_std
        property double loss_std
        onTriggered: {
            var data = Julia.get_progress("Validation")
            if (max_iterations===0) {
                if (data===false) {return}
                max_iterations = data[0]
            }
            else if (iteration<max_iterations) {
                if (data===false) {return}
                var accuracy_temp = data[0]
                var loss_temp = data[1]
                var accuracy_std_temp = data[2]
                var loss_std_temp = data[3]
                iteration += 1
                accuracyLabel.text = accuracy_temp.toFixed(2) + " ± " + accuracy_std_temp.toFixed(2)
                lossLabel.text = loss_temp.toFixed(2) + " ± " + loss_std_temp.toFixed(2)
                validationProgressBar.value = iteration/max_iterations
            }
            else if (iteration===max_iterations) {
                data = Julia.get_results("Validation")
                if (data===false) {return}
                running = false
                accuracy = data[0]
                loss = data[1]
                mean_accuracy = data[2]
                mean_loss = data[3]
                accuracy_std = data[4]
                loss_std = data[5]
                sampleSpinBox.value = 1
                featureComboBox.currentIndex = 0
                var ind1 = 1
                var ind2 = 1
                accuracyLabel.text = mean_accuracy.toFixed(2) + " ± " + accuracy_std.toFixed(2) +
                    " (" + accuracy[0].toFixed(2) + ")"
                lossLabel.text = mean_loss.toFixed(2) + " ± " + loss_std.toFixed(2) +
                        " (" + loss[0].toFixed(2)+")"
                get_image(originalDisplay,"data_input_orig",[ind1])
                get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
            }

        }
    }
    Timer {
        id: sizechangeTimer
        interval: 300
        running: true
        repeat: true
        property double prevWidth: 0
        property bool prevWidthChanged: false
        property double check: 0
        onTriggered: {
            if (prevWidth!==validationWindow.width) {
                prevWidth = validationWindow.width
                check = 0
                prevWidthChanged = true
            }
            else if (prevWidthChanged) {
                check = check + 1
                prevWidthChanged = false
            }
            else {
                return
            }
            if (check<3) {
                if (validationTimer.running) {return}
                var ind1 = sampleSpinBox.value
                var ind2 = featureComboBox.currentIndex+1
                var modif = (validationWindow.width-580*pix)/originalDisplay.width
                var new_width = validationWindow.width-580*pix-margin
                var new_heigth = Math.min(0.95*Screen.height,originalDisplay.height*modif)
                var modif2 = Math.min(new_width/originalDisplay.width,
                    new_heigth/originalDisplay.height)
                displayItem.width = displayItem.width*modif2
                originalDisplay.width = originalDisplay.width*modif2
                resultDisplay.width = originalDisplay.width
                originalDisplay.height = originalDisplay.height*modif2
                resultDisplay.height = originalDisplay.height
                originalDisplay.contentsScale = originalDisplay.contentsScale*modif2
                resultDisplay.contentsScale = resultDisplay.contentsScale*modif2
                informationPane.height = Math.max(1024*pix,originalDisplay.height+margin)
                displayItem.y = Math.max(0.5*margin,
                    (informationPane.height-originalDisplay.height)/2-0.25*margin)
                validationWindow.maximumHeight = Math.max(1024*pix,informationPane.height)
                validationWindow.height = Math.max(1024*pix,informationPane.height)
                //validationWindow.maximumHeight = Screen.height
                check = check + 1
            }
            else {
                check = 0
            }
        }
    }
    Item {
        Pane {
            id: displayItem
            x: 0.5*margin
            y: (validationWindow.height-originalDisplay.height)/2-0.25*margin
            height: Math.max(1024*pix,originalDisplay.height + 0.5*margin)
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
            x: validationWindow.width - 580*pix
            height: Math.max(validationWindow.height,1024*pix)
            width: 580*pix
            padding: 0.75*margin
            backgroundColor: defaultpalette.window2
            Column {
                id: informationColumn
                spacing: 0.4*margin
                Row {
                    spacing: 0.3*margin
                    ProgressBar {
                        id: validationProgressBar
                        width: buttonWidth-50*pix
                        height: buttonHeight
                    }
                    StopButton {
                        id: stoptraining
                        width: buttonHeight
                        height: buttonHeight
                        onClicked: Julia.put_channel("Validation",["stop"])
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
                        id: accuracytextLabel
                        text: "Accuracy:"
                    }
                    Label {
                        id: accuracyLabel
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Loss:"
                        width: accuracytextLabel.width
                    }
                    Label {
                        id: lossLabel
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
                        width: accuracytextLabel.width
                    }
                    SpinBox {
                        id: sampleSpinBox
                        from: 1
                        value: 1
                        to: validationTimer.accuracy.length
                        stepSize: 1
                        editable: false
                        onValueModified: {
                            var ind1 = sampleSpinBox.value
                            var ind2 = featureComboBox.currentIndex+1
                            accuracyLabel.text = validationTimer.mean_accuracy.toFixed(2) + " ± " +
                                validationTimer.accuracy_std.toFixed(2) +
                                " (" + validationTimer.accuracy[ind1-1].toFixed(2) + ")"
                            lossLabel.text = validationTimer.mean_loss.toFixed(2) + " ± " +
                                 validationTimer.loss_std.toFixed(2) +
                                 " (" + validationTimer.loss[ind1-1].toFixed(2)+")"
                            get_image(originalDisplay,"data_input_orig",[ind1])
                            get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Feature:"
                        width: accuracytextLabel.width
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
                            var num = featureselectModel.count
                            for (i=0;i<num;i++) {
                                if (featureModel.get(i).border) {
                                    featureselectModel.append(
                                        {"name": featureModel.get(i).name+" (border)"})
                                }
                            }
                            for (i=0;i<num;i++) {
                                if (featureModel.get(i).border) {
                                    featureselectModel.append(
                                        {"name": featureModel.get(i).name+" (applied border)"})
                                }
                            }
                            currentIndex = 0
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Show:"
                        width: accuracytextLabel.width
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
                            ListElement {name: "Target"}
                        }
                        onActivated: {
                            if (typeComboBox.currentIndex==0) {
                                type = "data_predicted"
                            }
                            else if  (typeComboBox.currentIndex==1) {
                                type = "data_error"
                            }
                            else {
                                type = "data_target"
                            }

                            get_image(resultDisplay,type,
                                [sampleSpinBox.value,featureComboBox.currentIndex+1])
                        }
                    }
                }
                Row {
                    topPadding: 34*pix
                    spacing: 0.3*margin
                    Label {
                        text: "Opacity:"
                        width: accuracytextLabel.width
                        topPadding: -24*pix
                    }
                    Slider {
                        width: 0.64*buttonWidth-1*pix
                        height: 12*pix
                        leftPadding: 0
                        from: 0
                        value: 0.5
                        to: 1
                        onMoved: {
                            resultDisplay.opacity = value
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
        var size = Julia.get_image(["Training_data","Validation_plot_data",type],
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
