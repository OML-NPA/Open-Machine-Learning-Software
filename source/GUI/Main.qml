
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
//import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("Image Analysis Software")
    minimumWidth: gridLayout.width
    minimumHeight: gridLayout.height
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }
    color: systempalette.window

    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property color defaultcolor: systempalette.window

    property string currentfolder: Qt.resolvedUrl(".")


    onClosing: {
        if (optionsLoader.sourceComponent !== null) {
            console.log()
            optionsLoader.item.terminate = true
        }
        if (trainingLoader.sourceComponent !== null) {
            trainingLoader.item.terminate = true
        }
        if (analysisLoader.sourceComponent !== null) {
            analysisLoader.item.terminate = true
        }
    }


    Loader { id: optionsLoader }
    Loader { id: trainingLoader }
    Loader { id: analysisLoader }

    GridLayout {
        id: gridLayout
        ColumnLayout {
            Layout.margins: margin
            spacing: 0.4*margin
            id: columnLayout
            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.row: 2
                Layout.column: 1
                text: "Options"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                    if (optionsLoader.sourceComponent == null) {
                        optionsLoader.source = "Options.qml"

                    }
                }
            }
            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.row: 2
                Layout.column: 1
                text: "Training"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                    if (trainingLoader.sourceComponent == null) {
                        trainingLoader.source = "Training.qml"
                    }
                }
            }
            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.row: 2
                Layout.column: 1
                text: "Visualisation"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                }
            }
            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.row: 2
                Layout.column: 1
                text: "Analysis"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                    if (analysisLoader.sourceComponent == null) {
                        analysisLoader.source = "Analysis.qml"
                    }
                }
            }
        }
    }

}
