
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
    id: window
    visible: true
    title: qsTr("  Deep Data Analysis Software")
    minimumWidth: gridLayout.width
    minimumHeight: gridLayout.height
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }
    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height

    onClosing: { trainingplotLoader.sourceComponent = undefined }

    Item {
        Timer {
            property int last_iter: 0
            property int last_test_iter: 0
            property int last_epoch: 0
            interval: 100
            running: true
            repeat: true
            onTriggered: {
                Julia.yield()
                var loss = Julia.get_data(["Training","loss"])
                var accuracy = Julia.get_data(["Training","accuracy"])
                var test_loss = Julia.get_data(["Training","test_loss"])
                var test_accuracy = Julia.get_data(["Training","test_accuracy"])
                var iter = loss.length
                var test_iter = test_loss.length
                if (iter>last_iter) {
                    for (var i=last_iter;i<iter;i++) {
                        accuracyLine.append(i+1,100*accuracy[i])
                        lossLine.append(i+1,loss[i])
                        if (test_iter>last_test_iter) {
                            accuracytestLine.append(i+1,100*test_accuracy[test_iter-1])
                            losstestLine.append(i+1,test_loss[test_iter-1])
                            last_test_iter = test_iter
                        }
                        if (loss[i]>lossAxisY.max) {
                            lossLine.lossAxisY.max = loss[i]
                        }
                        accuracyAxisX.max = iter + 1
                        accuracyAxisX.tickInterval = Math.round(iter/10)+1
                        lossAxisX.max = iter + 1
                        lossAxisX.tickInterval = Math.round(iter/10)+1
                        last_iter = iter
                    }
                    currentiterationLabel.text = Julia.get_data(["Training","iteration"])
                }
                if (iter===Julia.get_data(["Training","max_iterations"]))
                    running = false
                end
                elapsedtime.text = Julia.training_elapsed_time()
                alliterationsLabel.text = Julia.get_data(["Training","max_iterations"])
                epoch.text = Julia.get_data(["Training","epoch"])
                iterationsperepoch.text = Julia.get_data(["Training","iterations_per_epoch"])
            }
        }
    }
    GridLayout {
        id: gridLayout
        Row {
            Layout.alignment : Qt.AlignTop
            ColumnLayout {
                id: plots
                Label {
                    Layout.topMargin: 0.5*margin
                    text: "Training progress"
                    Layout.alignment : Qt.AlignHCenter | Qt.AligTop
                    font.pointSize: 12
                    font.bold: true
                }
                RowLayout {
                    spacing: 0
                    Label {
                        text: "Accuracy (%)"
                        font.pointSize: 10
                        rotation : 270
                        Layout.alignment : Qt.AlignHCenter
                        topPadding: -1.25*margin
                        leftPadding: margin
                    }
                    ColumnLayout {
                        ChartView {
                            id: accuracyChartView
                            Layout.preferredHeight: 10*margin
                            Layout.preferredWidth: 15*margin
                            Layout.leftMargin: -2.75*margin
                            backgroundColor : defaultpalette.window
                            plotAreaColor : defaultpalette.listview
                            antialiasing: true
                            legend.visible: false
                            margins { right: 0.3*margin; bottom: 0; left: 0; top: 0 }
                            ValueAxis {
                                    id: accuracyAxisX
                                    min: 1
                                    max: 2
                                    labelsFont.pointSize: 10
                                    tickType: ValueAxis.TicksDynamic
                                    tickInterval: 1
                                    labelFormat: "%i"
                                }
                            ValueAxis {
                                    id: accuracyAxisY
                                    labelsFont.pointSize: 10
                                    tickInterval: 0.1
                                    min: 0
                                    max: 100
                                }
                            LineSeries {
                                id: accuracyLine
                                axisX: accuracyAxisX
                                axisY: accuracyAxisY
                                width: 4*pix
                                color: "#3498db"
                            }
                            LineSeries {
                                id: accuracytestLine
                                axisX: accuracyAxisX
                                axisY: accuracyAxisY
                                width: 4*pix
                                color: "#163E5A"
                                style: Qt.DashLine
                            }
                        }
                        Label {
                            text: "Iteration"
                            font.pointSize: 10
                            Layout.topMargin: -0.3*margin
                            Layout.leftMargin: -2.75*margin
                            Layout.alignment : Qt.AlignHCenter
                        }
                    }
                }
                RowLayout {
                    spacing: 0
                    Label {
                        text: "Loss"
                        font.pointSize: 10
                        rotation : 270
                        Layout.alignment : Qt.AlignHCenter
                        topPadding: -0.25*margin
                        leftPadding: margin
                    }
                    ColumnLayout {
                        ChartView {
                            id: lossChartView
                            Layout.preferredHeight: 6*margin
                            Layout.preferredWidth: 15*margin
                            Layout.leftMargin: -1*margin
                            backgroundColor : defaultpalette.window
                            plotAreaColor : defaultpalette.listview
                            antialiasing: true
                            legend.visible: false
                            margins { right: 0.3*margin; bottom: 0; left: 0; top: 0 }
                            ValueAxis {
                                    id: lossAxisX
                                    min: 1
                                    max: 2
                                    labelsFont.pointSize: 10
                                    tickType: ValueAxis.TicksDynamic
                                    tickInterval: 1
                                    labelFormat: "%i"
                                }
                            ValueAxis {
                                    id: lossAxisY
                                    labelsFont.pointSize: 10
                                    tickInterval: 0.1
                                    min: 0
                                    max: 1
                                }
                            LineSeries {
                                id: lossLine
                                axisX: lossAxisX
                                axisY: lossAxisY
                                width: 4*pix
                                color: "#e67e22"
                            }
                            LineSeries {
                                id: losstestLine
                                axisX: lossAxisX
                                axisY: lossAxisY
                                width: 4*pix
                                color: "#5E340E"
                                style: Qt.DashLine
                            }
                        }
                        Label {
                            text: "Iteration"
                            font.pointSize: 10
                            Layout.topMargin: -0.3*margin
                            Layout.leftMargin: -1*margin
                            Layout.bottomMargin: 0.5*margin
                            Layout.alignment : Qt.AlignHCenter
                        }
                    }
                }
            }
            Pane {
                height: plots.height
                backgroundColor: defaultpalette.window2
                ColumnLayout {
                    ColumnLayout {
                        Layout.margins: 0.5*margin
                        Row {
                            id: progressbarheader
                            Label {
                                text: "Training iteration  "
                            }
                            Label {
                                id: currentiterationLabel
                                text: ""
                            }
                            Label {
                                text: "  of  "
                            }
                            Label {
                                id: alliterationsLabel
                                text: ""
                            }
                        }
                        RowLayout {
                            ProgressBar {
                                id: progressbar
                                Layout.preferredWidth: 1.2*buttonWidth
                                Layout.preferredHeight: buttonHeight
                                Layout.alignment: Qt.AlignVCenter
                                backgroundHeight: 0.8*buttonHeight
                            }
                            StopButton {
                                id: stoptraining
                                Layout.preferredWidth: buttonHeight
                                Layout.preferredHeight: buttonHeight
                                Layout.leftMargin: 0.3*margin
                                onClicked: Julia.set_data(["Training","stop_training"],true)
                            }
                        }
                        Column {
                            spacing: 0.4*margin
                            Label {
                                topPadding: 0.5*margin
                                text: "Training time"
                                font.bold: true
                            }
                            Row {
                                spacing: 0.3*margin
                                Label {
                                    text: "Start time:"
                                    width: iterationsperepochLabel.width
                                }
                                Label {
                                    id: starttime
                                    text: Julia.time()
                                }
                            }
                            Row {
                                spacing: 0.3*margin
                                Label {
                                    text: "Elapsed time:"
                                    width: iterationsperepochLabel.width
                                }
                                Label {
                                    id: elapsedtime
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                            }
                            Label {
                                topPadding: 0.5*margin
                                text: "Training cycle"
                                font.bold: true
                            }
                            Row {
                                spacing: 0.3*margin
                                Label {
                                    text: "Epoch:"
                                    width: iterationsperepochLabel.width
                                }
                                Label {
                                    id: epoch
                                    text: ""
                                }
                            }
                            Row {
                                spacing: 0.3*margin
                                Label {
                                    id: iterationsperepochLabel
                                    text: "Iterations per epoch:"
                                }
                                Label {
                                    id: iterationsperepoch
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                            }
                            Label {
                                topPadding: 0.5*margin
                                text: "Other information:"
                                font.bold: true
                            }
                            Row {
                                spacing: 0.3*margin
                                Label {
                                    text: "Hardware resource:"
                                    width: iterationsperepochLabel.width
                                }
                                Label {
                                    id:hardwareresource
                                    Layout.topMargin: 0.2*margin
                                    text: Julia.get_data(["Options",
                                        "Hardware_resources","allow_GPU"]) ? "GPU" : "CPU"
                                }
                            }
                            Row {
                                spacing: 0.3*margin
                                Label {
                                    text: "Learning rate:"
                                    width: iterationsperepochLabel.width
                                }
                                SpinBox {
                                    from: 1
                                    value: 100000*Julia.get_data(
                                               ["Training","Options","Hyperparameters","learning_rate"])
                                    to: 1000
                                    stepSize: 100
                                    editable: true
                                    property real realValue: value/100000
                                    textFromValue: function(value, locale) {
                                        return Number(value/100000).toLocaleString(locale,'e',0)
                                    }
                                    onValueModified: {
                                        if (value>1000) {
                                            stepSize = 1000
                                        }
                                        else if (value>100) {
                                            stepSize = 100
                                        }
                                        else if (value>10) {
                                            stepSize = 10
                                        }
                                        else {
                                            stepSize = 1
                                        }
                                        Julia.set_data(
                                            ["Training","Options","Hyperparameters","learning_rate"],
                                            value/100000)
                                        Julia.set_data(
                                            ["Training","learning_rate_changed"],true)
                                    }
                                }
                            }
                        }
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
}
