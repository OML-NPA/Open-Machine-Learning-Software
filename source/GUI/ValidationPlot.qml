

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
    minimumHeight: 1024*pix + margin
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
            /*var data = Julia.get_progress("Validation")
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
                displayPane.height = validationWindow.height - originalDisplay.height
                displayPane.width = validationWindow.width - originalDisplay.width
                controlsLabel.visible = true
                sampleRow.visible = true
                featureRow.visible = true
                typeRow.visible = true
                opacityRow.visible = true
                zoomRow.visible = true
            }*/
            running = false
            sampleSpinBox.value = 1
            featureComboBox.currentIndex = 0
            var ind1 = 1
            var ind2 = 1
            get_image(originalDisplay,"data_input_orig",[ind1])
            var size = get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
            var ratio = size[0]/size[1]
            if (ratio<1) {
                displayItem.height = displayItem.width*ratio
            }
            else {
                displayItem.width = displayItem.height/ratio
            }
            var cond = 1024*pix-margin
            if (displayItem.width>=cond) {
                displayPane.horizontalPadding = 0.5*margin
            }
            else {
                displayPane.horizontalPadding = (1024*pix+margin -
                                   displayItem.width - informationPane.width)/2
            }
            if (displayItem.height>=cond) {
                displayPane.verticalPadding = 0.5*margin
            }
            else {
                displayPane.verticalPadding = (1024*pix+margin - displayItem.height)/2
            }
            displayPane.height = displayItem.height + 2*displayPane.verticalPadding
            displayPane.width = displayItem.width + 2*displayPane.horizontalPadding
            displayScrollableItem.width = displayPane.width - 2*displayPane.horizontalPadding
            displayScrollableItem.height = displayPane.height - 2*displayPane.verticalPadding
            sizechangeTimer.prevWidth = displayPane.height
            sizechangeTimer.running = true
            controlsLabel.visible = true
            sampleRow.visible = true
            featureRow.visible = true
            typeRow.visible = true
            opacityRow.visible = true
            zoomRow.visible = true

        }
    }
    Timer {
        id: sizechangeTimer
        interval: 300
        running: false
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
            if (check>0 || displayPane.width!==(validationWindow.width - 580*pix) ||
                    displayPane.height!==(validationWindow.height)) {
                var ind1 = sampleSpinBox.value
                var ind2 = featureComboBox.currentIndex+1
                var modif = (validationWindow.width-580*pix)/
                        (displayPane.width)
                var new_width = validationWindow.width - 580*pix
                var new_heigth = Math.min(Screen.height-0.75*margin,displayPane.height*modif)
                var modif2 = Math.min(new_width/displayPane.width,
                    new_heigth/displayPane.height)
                displayItem.width = displayItem.width*modif2
                displayItem.height = displayItem.height*modif2
                displayItem.contentsScale = displayItem.contentsScale*modif2
                var cond = 1024*pix-margin
                if (displayItem.width>=cond) {
                    displayPane.horizontalPadding = 0.5*margin
                }
                else {
                    displayPane.horizontalPadding = (1024*pix+margin -
                                       displayItem.width - informationPane.width)/2
                }
                if (displayItem.height>=cond) {
                    displayPane.verticalPadding = 0.5*margin
                }
                else {
                    displayPane.verticalPadding = (1024*pix+margin - displayItem.height)/2
                }
                displayPane.height = displayItem.height + 2*displayPane.verticalPadding
                displayPane.width = displayItem.width + 2*displayPane.horizontalPadding
                displayScrollableItem.width = displayPane.width - 2*displayPane.horizontalPadding
                displayScrollableItem.height = displayPane.height - 2*displayPane.verticalPadding
                validationWindow.height = informationPane.height
                displayPane.x = (validationWindow.width - displayPane.width - informationPane.width)/2
                check = 0
            }
        }
    }
    Item {
        Pane {
            id: displayPane
            horizontalPadding: 0.5*margin
            verticalPadding: 0.5*margin
            height: 1024*pix + margin
            width: 1024*pix + margin
            ScrollableItem {
                id: displayScrollableItem
                width : 1024*pix
                height : 1024*pix
                contentWidth: displayItem.width
                contentHeight: displayItem.height
                showBackground: false
                backgroundColor: defaultpalette.window
                //scrollbar: false
                clip: true
                Item {
                    id: displayItem
                    width: 1024*pix
                    height: 1024*pix
                    property double contentsScale: 1.014
                    JuliaDisplay {
                        id: originalDisplay
                        width: displayItem.width
                        height: displayItem.height
                        contentsScale: displayItem.contentsScale
                        x: 1
                    }
                    JuliaDisplay {
                        id: resultDisplay
                        opacity: 0.5
                        width: displayItem.width
                        height: displayItem.height
                        contentsScale: displayItem.contentsScale
                    }
                }
            }
        }
        Pane {
            id: informationPane
            x: validationWindow.width - 580*pix
            height: Math.max(1024*pix+margin,validationWindow.height)
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
                        width: buttonWidth
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
                    id: controlsLabel
                    visible: false
                    topPadding: 0.2*margin
                    text: "Visualization controls"
                    font.bold: true
                }
                Row {
                    id: sampleRow
                    visible: false
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
                    id: featureRow
                    visible: false
                    spacing: 0.3*margin
                    Label {
                        text: "Feature:"
                        width: accuracytextLabel.width
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: featureComboBox
                        editable: false
                        width: 0.76*buttonWidth
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
                    id: typeRow
                    visible: false
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
                        width: 0.76*buttonWidth
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
                    id: opacityRow
                    visible: false
                    topPadding: 34*pix
                    spacing: 0.3*margin
                    Label {
                        text: "Opacity:"
                        width: accuracytextLabel.width
                        topPadding: -24*pix
                    }
                    Slider {
                        width: 0.76*buttonWidth
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
                Row {
                    id: zoomRow
                    visible: false
                    topPadding: 34*pix
                    spacing: 0.3*margin
                    Label {
                        text: "Zoom:"
                        width: accuracytextLabel.width
                        topPadding: -24*pix
                    }
                    Slider {
                        width: 0.76*buttonWidth
                        height: 12*pix
                        leftPadding: 0
                        from: 1
                        value: 1
                        to: 10
                        property double last_value: 1
                        property double initial_width: 0
                        property double initial_height:0
                        onMoved: {
                            if(initial_width==0) {
                                initial_width = originalDisplay.width
                                initial_height = originalDisplay.height
                            }

                            if (value!==last_value) {
                                var ratio = value/last_value
                            }
                            else {
                                return
                            }
                            originalDisplay.contentsScale = originalDisplay.contentsScale*ratio
                            resultDisplay.contentsScale = originalDisplay.contentsScale
                            originalDisplay.x = -(originalDisplay.contentsScale*
                                    initial_width-initial_width)/2
                            originalDisplay.y = -(originalDisplay.contentsScale*
                                    initial_height-initial_height)/2
                            resultDisplay.x = originalDisplay.x
                            resultDisplay.y = originalDisplay.y
                            originalDisplay.width = originalDisplay.width*ratio
                            resultDisplay.width = originalDisplay.width
                            originalDisplay.height = originalDisplay.height*ratio
                            resultDisplay.height = originalDisplay.height
                            last_value = value
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
        Julia.display_image(display)
        return size
    }
}