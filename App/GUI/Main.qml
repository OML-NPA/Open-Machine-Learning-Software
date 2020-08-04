
import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
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
    property double fontsize: Math.round(11*Screen.height/2160)
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property color defaultcolor: systempalette.window

    property bool optionsOpen: false
    property bool localtrainingOpen: false

    onClosing: {
        if (optionsOpen===true) {
            optionsLoader.item.terminate = true
        }
        if (localtrainingOpen===true) {
            localtrainingLoader.item.terminate = true
        }
    }

    FolderDialog {
            id: folderDialog
            onAccepted: {
                Julia.browsefolder(folderDialog.folder)
                Qt.quit()
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
                        //onClicked: updatelocation
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
                        background: Rectangle {
                                       anchors.fill: parent.fill
                                       border.color: systempalette.dark
                                       border.width: 2
                                   }
                        ScrollView {
                            clip: true
                            anchors.fill: parent
                            spacing: 0
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ColumnLayout {
                                spacing: 0
                                Repeater {
                                    model: 4
                                    TreeButton {
                                        id: control
                                        Layout.preferredWidth: buttonWidth + 0.5*margin-4
                                        Layout.preferredHeight: buttonHeight-2
                                        onClicked: {
                                        }
                                        RowLayout {
                                            spacing: 0
                                            CheckBox {
                                                padding: 0
                                                Layout.leftMargin: -0.175*margin
                                                Layout.topMargin: 0.125*margin
                                            }
                                            anchors.fill: parent.fill
                                            Label {
                                                topPadding: 0.10*margin
                                                leftPadding: -0.1*margin
                                                text: "folder"+index
                                                //Layout.alignment: Qt.AlignVCenter
                                            }
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
