
import QtQuick 2.15
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
    property double tabmargin: 0.5*margin
    property color menucolor: "#fafafa"
    property color defaultcolor: systempalette.window

    property bool terminate: false

    property var colors: ["green","red","blue","orange"]

    onClosing: {
        window.visible = false
        close.accepted = terminate

    }

    FolderDialog {
            id: folderDialog
            onAccepted: {
                Julia.browsefolder(folderDialog.folder)
                Qt.quit()
            }
    }

    Loader { id: featuredialogLoader}

    GridLayout {
        id: gridLayout
        ColumnLayout {
            Layout.margins: margin
            spacing: 0.7*margin
            ColumnLayout {
                spacing: 0.5*margin
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Neural Network \ntemplate:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1.4*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        text: "Browse"
                    }
                }
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Images:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1.4*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        text: "Browse"
                    }
                }
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Labels:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1.4*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        text: "Browse"
                    }
                }
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Name:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                }
            }
            RowLayout {
                spacing:1.75*margin
                Column {
                    spacing: -2
                    Label {
                        width: buttonWidth + 0.5*margin
                        text: "Features:"
                        padding: 0.1*margin
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
                        background: Rectangle {
                                       anchors.fill: parent.fill
                                       border.color: systempalette.dark
                                       border.width: 2
                                   }
                        ScrollView {
                            clip: false
                            anchors.fill: parent
                            padding: -10
                            spacing: 0
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ColumnLayout {
                                spacing: -2
                                Repeater {
                                    model: 4
                                    TreeButton {
                                        id: control
                                        Layout.preferredWidth: buttonWidth + 0.5*margin-4
                                        Layout.preferredHeight: buttonHeight-2
                                        //onClicked:
                                        RowLayout {
                                            anchors.fill: parent.fill
                                            Frame {
                                                Layout.leftMargin: 0.3*margin
                                                Layout.bottomMargin: 0.025*margin
                                                Layout.preferredWidth: 0.4*margin
                                                Layout.preferredHeight: 0.4*margin
                                                height: 10*margin
                                                Layout.alignment: Qt.AlignBottom

                                                background: Rectangle {
                                                    anchors.fill: parent.fill
                                                    color: colors[index]
                                                    border.width: 1
                                                }
                                            }
                                            Label {
                                                text: "feature"+index
                                                topPadding: 10
                                                Layout.alignment: Qt.AlignBottom
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                ColumnLayout {
                    spacing: 0.3*margin
                    Button {
                        id: customize
                        text: "Customize"
                        Layout.preferredWidth: buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        id: starttraining
                        text: "Start training"
                        Layout.preferredWidth: buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                }
            }

        }

    }
}










