
import QtQuick 2.12
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

    property bool optionsOpen: false
    property bool localtrainingOpen: false

    property string currentfolder: Qt.resolvedUrl(".")


    onClosing: {
        if (optionsOpen===true) {
            optionsLoader.item.terminate = true
        }
        if (localtrainingOpen===true) {
            localtrainingLoader.item.terminate = true
        }
    }

    FolderListModel {
            id: folderModel
            showFiles: false
            rootFolder: currentfolder
        }
    FolderDialog {
            id: folderDialog
            currentFolder: currentfolder
            onAccepted: {
                currentfolder = folderDialog.folder
                folderModel.folder = currentfolder
                folderView.model = folderModel
                console.log(folderModel.folder)
                //Julia.browsefolder(folderDialog.folder)
                //Qt.quit()
            }
    }

    Loader { id: optionsLoader
    }
    Loader { id: localtrainingLoader
    }

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowLayout
            spacing: margin
            Layout.margins: margin
            Column {
                spacing: 0.3*margin
                RowLayout {
                    spacing: 0.5*margin
                    Button {
                        id: up
                        Layout.row: 1
                        text: "Up"
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        onClicked: {currentfolder = folderModel.parentFolder;
                                    folderModel.folder = currentfolder;
                                    folderView.model = folderModel
                        }
                    }
                    Button {
                        id: browse
                        Layout.row: 2
                        text: "Browse"
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        onClicked: {folderDialog.open()}
                    }
                }
                Column {
                    spacing: -2
                    Label {
                        width: buttonWidth + 0.5*margin
                        text: "Folders:"
                        padding: 0.1*margin
                        leftPadding: 0.2*margin
                        background: Rectangle {
                            anchors.fill: parent.fill
                            color: defaultcolor
                            border.color: systempalette.dark
                            border.width: 2
                        }
                    }
                    Frame {
                        Layout.row: 1
                        Layout.column: 2
                        height: 0.2*Screen.height
                        width: buttonWidth + 0.5*margin
                        backgroundColor: systempalette.light
                        ScrollView {
                            clip: true
                            anchors.fill: parent
                            spacing: 0
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ListView {
                                id: folderView
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: folderModel
                                delegate: TreeButton {
                                    id: control
                                    width: buttonWidth + 0.5*margin-4
                                    height: buttonHeight-2
                                    onDoubleClicked: {
                                    }
                                    RowLayout {
                                        spacing: 0
                                        CheckBox {
                                            padding: 0
                                            Layout.leftMargin: -0.175*margin
                                            Layout.topMargin: 0.125*margin
                                        }
                                        //anchors.fill: parent.fill
                                        Label {
                                            topPadding: 0.10*margin
                                            leftPadding: -0.1*margin
                                            text: fileName
                                            //Layout.alignment: Qt.AlignVCenter
                                        }
                                    }
                                }
                            }

                        }
                    }
                }
            }
            ColumnLayout {
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
                            if (optionsOpen===false)
                               {
                                optionsLoader.source = "Options.qml"
                                optionsOpen = true
                               }
                            else
                               {
                                optionsLoader.item.visible = true
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
                            if (localtrainingOpen===false)
                               {
                                localtrainingLoader.source = "LocalTraining.qml"
                                localtrainingOpen = true
                               }
                            else
                               {
                                localtrainingLoader.item.visible = true
                               }
                    }
                }
                Button {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.row: 2
                    Layout.column: 1
                    text: "Start analysis"
                    Layout.preferredWidth: buttonWidth
                    Layout.preferredHeight: buttonHeight
                }
                ProgressBar {
                    id: progressbar
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.row: 2
                    Layout.column: 2
                    value: 0
                    Layout.preferredWidth: buttonWidth
                    Layout.preferredHeight: buttonHeight/2
                }
            }


        }
    }

}
