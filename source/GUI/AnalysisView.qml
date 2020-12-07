
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
import org.julialang 1.0

Component {
    ColumnLayout {
        id: mainLayout
        property bool optionsOpen: false
        property bool localtrainingOpen: false

        property string currentfolder: Qt.resolvedUrl(".")

        Component.onCompleted: {
            var url = "file:///"+Julia.get_settings(["Analysis","folder_url"])
            if (url!=="") {
                currentfolder = url
                folderModel.folder = currentfolder
                folderView.model = folderModel
            }
        }

        FolderListModel {
            id: folderModel
            showFiles: false
            folder: currentfolder
        }
        FolderDialog {
            id: folderDialog
            currentFolder: currentfolder
            onAccepted: {
                updateFolder(folderDialog.folder)
            }
        }

        Loader { id: analysisoptionsLoader }
        Loader { id: selectneuralnetworkLoader }
        RowLayout {
            id: rowLayout
            Layout.alignment: Qt.AlignHCenter
            spacing: margin
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
                        onClicked: {updateFolder(folderModel.parentFolder)}
                    }
                    Button {
                        id: browse
                        Layout.row: 2
                        text: "Browse"
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        onClicked: {folderDialog.open()}
                    }
                   Button {
                        Layout.preferredWidth: buttonWidth + 0.5*margin
                        Layout.preferredHeight: buttonHeight
                        Layout.leftMargin: 0.5*margin
                        backgroundRadius: 0
                        onClicked: {
                            if (selectneuralnetworkLoader.sourceComponent === null) {
                                selectneuralnetworkLoader.source = "SelectNeuralNetwork.qml"
                            }
                        }

                        Label {
                            id: nnselectLabel
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 15*pix

                            text: "Select neural network"
                        }
                        Image {
                                anchors.right: parent.right
                                height: parent.height
                                opacity: 0.3
                                source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/double-arrow.png"
                                fillMode: Image.PreserveAspectFit
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
                                color: defaultpalette.window
                                border.color: defaultcolors.dark
                                border.width: 2
                            }
                        }
                        Frame {
                            Layout.row: 1
                            Layout.column: 2
                            height: 0.2*Screen.height
                            width: buttonWidth + 0.5*margin
                            backgroundColor: "white"
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
                                        width: buttonWidth + 0.5*margin - 24*pix
                                        height: buttonHeight-2*pix
                                        onDoubleClicked: { updateFolder(currentfolder+"/"+name.text) }
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
                                color: defaultpalette.window
                                border.color: defaultcolors.dark
                                border.width: 2
                            }
                        }
                        Frame {
                            height: 0.2*Screen.height
                            width: buttonWidth + 0.5*margin
                            backgroundColor: defaultcolors.light
                            ScrollView {
                                clip: true
                                anchors.fill: parent
                                padding: 0
                                spacing: 0
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ListView {
                                    id: featureView
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: featureModel}
                                    delegate: Rectangle {
                                        width: buttonWidth + 0.5*margin-24*pix
                                        height: buttonHeight-2*pix
                                        RowLayout {
                                            anchors.fill: parent.fill
                                            Rectangle {
                                                id: colorRectangle
                                                Layout.leftMargin: 0.2*margin
                                                Layout.bottomMargin: 2*pix
                                                Layout.alignment: Qt.AlignBottom
                                                height: 30*pix
                                                width: 30*pix
                                                border.width: 2*pix
                                                radius: colorRectangle.width
                                                color: rgbtohtml([colorR,colorG,colorB])
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
        }
        ColumnLayout {
            id: columnLayout
            spacing: 0.4*margin
            Layout.topMargin: margin
            Layout.alignment: Qt.AlignHCenter
            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.row: 2
                Layout.column: 1
                text: "Options"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                    if (analysisoptionsLoader.sourceComponent === null) {
                       analysisoptionsLoader.source = "AnalysisOptions.qml"

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
        }

        function updateFolder(path) {
            currentfolder = path
            folderModel.folder = currentfolder
            folderView.model = folderModel
            path = String(path).substring(8)
            Julia.set_settings(["Analysis","folder_url"],path)
        }
    }
}
