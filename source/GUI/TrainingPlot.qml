
import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import QtCharts 2.15
import "Templates"
//import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  Deep Data Analysis Software v.0.1")
    minimumWidth: gridLayout.width
    minimumHeight: gridLayout.height
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }
    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height

    property double iteration
    property double maxitearions
    property double lossmaxvalue: 5

    onClosing: { trainingplotLoader.sourceComponent = undefined }

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
                            Layout.preferredHeight: 10*margin
                            Layout.preferredWidth: 15*margin
                            Layout.leftMargin: -2.75*margin
                            backgroundColor : defaultpalette.window
                            plotAreaColor : defaultpalette.listview
                            antialiasing: true
                            legend.visible: false
                            margins { right: 0.3*margin; bottom: 0; left: 0; top: 0 }
                            ValueAxis {
                                    id: axisX
                                    min: 0
                                    max: 6
                                    labelsFont.pointSize: 10
                                    tickType: ValueAxis.TicksDynamic
                                    tickInterval: 1
                                    labelFormat: "%i"
                                }
                            ValueAxis {
                                    id: axisY
                                    labelsFont.pointSize: 10
                                    tickType: ValueAxis.TicksDynamic
                                    tickInterval: 10
                                    labelFormat: "%i"
                                    min: 0
                                    max: 100
                                }
                            LineSeries {
                                id: accuracy
                                axisX: axisX
                                axisY: axisY
                                width: 0.04*buttonHeight
                                color: "#3498db"
                                XYPoint { x: 0; y: 5 }
                                XYPoint { x: 1; y: 30 }
                                XYPoint { x: 2; y: 50 }
                                XYPoint { x: 3; y: 70 }
                                XYPoint { x: 4; y: 80 }
                                XYPoint { x: 5; y: 85 }
                                XYPoint { x: 6; y: 86 }
                            }
                        }
                        Label {
                            text: "Epoch"
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
                            Layout.preferredHeight: 6*margin
                            Layout.preferredWidth: 15*margin
                            Layout.leftMargin: -1*margin
                            backgroundColor : defaultpalette.window
                            plotAreaColor : defaultpalette.listview
                            antialiasing: true
                            legend.visible: false
                            margins { right: 0.3*margin; bottom: 0; left: 0; top: 0 }
                            ValueAxis {
                                    id: lossaxisX
                                    min: 0
                                    max: 6
                                    labelsFont.pointSize: 10
                                    tickType: ValueAxis.TicksDynamic
                                    tickInterval: 1
                                    labelFormat: "%i"
                                }
                            ValueAxis {
                                    id: lossaxisY
                                    labelsFont.pointSize: 10
                                    min: 0
                                    max: lossmaxvalue
                                }
                            LineSeries {
                                id: loss
                                axisX: lossaxisX
                                axisY: lossaxisY
                                color: "#e67e22"
                                width: 0.04*buttonHeight
                                XYPoint { x: 0; y: 4.8 }
                                XYPoint { x: 1; y: 3 }
                                XYPoint { x: 2; y: 1.5 }
                                XYPoint { x: 3; y: 0.7 }
                                XYPoint { x: 4; y: 0.5 }
                                XYPoint { x: 5; y: 0.4 }
                                XYPoint { x: 6; y: 0.37 }
                            }
                        }
                        Label {
                            text: "Epoch"
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
                        Label {
                            id: progressbarheader
                            text: "Training iteration  of  "
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
                            }
                        }
                        RowLayout {
                            ColumnLayout {
                                Label {
                                    Layout.topMargin: 0.5*margin
                                    text: "Training time"
                                    font.bold: true
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Start time:"
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Elapsed time:"
                                }
                                Label {
                                    Layout.topMargin: 0.5*margin
                                    text: "Training cycle"
                                    font.bold: true
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Epoch:"
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Iterations per epoch:"
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Iteration:"
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Maximum iterations:"
                                }
                                Label {
                                    Layout.topMargin: 0.5*margin
                                    text: "Other information:"
                                    font.bold: true
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Hardware resource:"
                                }
                                Label {
                                    Layout.topMargin: 0.2*margin
                                    text: "Learning rate:"
                                }
                            }
                            ColumnLayout {
                                Label {
                                    Layout.topMargin: 0.5*margin
                                    text: ""
                                    font.bold: true
                                }
                                Label {
                                    id: starttime
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                                Label {
                                    id: elapsedtime
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                                Label {
                                    Layout.topMargin: 0.5*margin
                                    text: ""
                                    font.bold: true
                                }
                                Label {
                                    id: epoch
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                                Label {
                                    id: iterationsperepoch
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                                Label {
                                    id: iteration
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                                Label {
                                    id: maxiterations
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                                Label {
                                    Layout.topMargin: 0.5*margin
                                    text: ""
                                    font.bold: true
                                }
                                Label {
                                    id:hardwareresource
                                    Layout.topMargin: 0.2*margin
                                    text: ""
                                }
                                Label {
                                    id: learningrate
                                    Layout.topMargin: 0.2*margin
                                    text: ""
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
