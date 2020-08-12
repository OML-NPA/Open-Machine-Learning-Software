
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Controls"
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
        if (optionsLoader.source.length !== undefined) {
            optionsLoader.item.terminate = true
        }
        if (localtrainingLoader.source.length !== undefined) {
            localtrainingLoader.item.terminate = true
        }
        if (analysisLoader.source.length !== undefined) {
            analysisLoader.item.terminate = true
        }
    }


    Loader { id: optionsLoader }
    Loader { id: localtrainingLoader }
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
                    if (optionsLoader.sourceComponent == undefined) {
                        optionsLoader.source = "Options.qml"

                    }
                }
            }
            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.row: 2
                Layout.column: 1
                text: "Local training"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                    if (localtrainingLoader.sourceComponent == undefined) {
                        localtrainingLoader.source = "LocalTraining.qml"
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
                    if (analysisLoader.sourceComponent == undefined) {
                        analysisLoader.source = "Analysis.qml"
                    }
                }
            }
        }
    }

}
