
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

    property bool optionsOpen: false
    property bool localtrainingOpen: false

    property string currentfolder: Qt.resolvedUrl(".")


    function updatefolder(path) {
        console.log(currentfolder)
        currentfolder = path
        folderModel.folder = currentfolder
        folderView.model = folderModel
        //Julia.browsefolder(folderDialog.folder)
        console.log(folderModel.folder)
    }

    onClosing: { analysisLoader.sourceComponent = undefined }

    FolderListModel {
            id: folderModel
            showFiles: false
            folder: currentfolder
        }
    FolderDialog {
            id: folderDialog
            currentFolder: currentfolder
            onAccepted: { updatefolder(folderDialog.folder) }
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
                    ComboBox {
                        editable: false
                        Layout.preferredWidth: buttonWidth + 0.5*margin
                        Layout.leftMargin: 0.5*margin
                        model: ListModel {
                            id: netModel
                            // @disable-check M16
                            ListElement { text: "defaultNetE5D4Yeast" }
                        }
                    }
                }
                RowLayout {
                    spacing: margin
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
                                        onDoubleClicked: { updatefolder(currentfolder+"/"+name.text) }
                                        RowLayout {
                                            spacing: 0
                                            CheckBox {
                                                padding: 0
                                                Layout.leftMargin: -0.175*margin
                                                Layout.topMargin: 0.125*margin
                                            }
                                            Label {
                                                id: name
                                                topPadding: 0.10*margin
                                                leftPadding: -0.1*margin
                                                text: fileName
                                            }
                                        }
                                    }
                                }

                            }
                        }
                    }
                    Column {
                        spacing: -2
                        Label {
                            width: buttonWidth + 0.5*margin
                            text: "Features:"
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
                            height: 0.2*Screen.height
                            width: buttonWidth + 0.5*margin
                            backgroundColor: systempalette.light
                            ScrollView {
                                clip: true
                                anchors.fill: parent
                                padding: 0
                                //topPadding: 0.01*margin
                                spacing: 0
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ListView {
                                    id: featureView
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: featureModel
                                                      ListElement{
                                                          name: "Yeast cell" // @disable-check M16
                                                          colorR: 0 // @disable-check M16
                                                          colorG: 255 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
                                                      ListElement{
                                                          name: "Vacuole" // @disable-check M16
                                                          colorR: 255 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
                                                    }
                                    delegate: Rectangle {
                                        width: buttonWidth + 0.5*margin-4
                                        height: buttonHeight-2
                                        RowLayout {
                                            anchors.fill: parent.fill
                                            ColorBox {
                                                Layout.leftMargin: 0.2*margin
                                                Layout.bottomMargin: 0.03*margin
                                                Layout.preferredWidth: 0.4*margin
                                                Layout.preferredHeight: 0.4*margin
                                                height: 10*margin
                                                Layout.alignment: Qt.AlignBottom
                                                colorRGB: [colorR,colorG,colorB]
                                            }
                                            Label {
                                                topPadding: 0.15*margin
                                                leftPadding: 0.10*margin
                                                text: name
                                                Layout.alignment: Qt.AlignBottom
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
