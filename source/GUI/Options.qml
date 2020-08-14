
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
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
    property double tabmargin: 0.5*margin
    property color menucolor: "#fafafa"
    property color defaultcolor: systempalette.window
    property double pix: Screen.width/3840

    property bool terminate: false

    FolderDialog {
            id: folderDialog
            onAccepted: {
                Julia.browsefolder(folderDialog.folder)
                Qt.quit()
            }
    }

    onClosing: { optionsLoader.sourceComponent = null }

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            //spacing: margin
            Frame {
                Layout.row: 1
                spacing: 0
                padding: 1
                topPadding: tabmargin/2
                leftPadding: 2
                bottomPadding: tabmargin/2
                background: Rectangle {
                    anchors.fill: parent.fill
                    border.color: systempalette.dark
                    border.width: 2
                    color: menucolor
                }

                ColumnLayout {
                    spacing: 0
                    MenuButton {
                        id: generalMenuButton
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(generalView)}
                        text: "General"
                    }
                    MenuButton {
                        id: hardwareMenuButton
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(hardwareView)}
                        text: "Hardware resources"
                    }
                    MenuButton {
                        id: aboutMenuButton
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(aboutView)}
                        text: "About"
                    }
                    Rectangle {
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: 8*buttonHeight
                        color: menucolor
                    }

                }
            }
            ColumnLayout {
                id: columnLayout
                Layout.margins: 0.5*margin
                Layout.row: 2
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 2.125*buttonWidth
                StackView {
                    id: stack
                    initialItem: generalView
                    pushEnter: Transition {
                        PropertyAnimation {
                            from: 0
                            to:1
                            duration: 0
                        }
                    }
                    pushExit: Transition {
                        PropertyAnimation {
                            from: 1
                            to:0
                            duration: 0
                        }
                    }
                    popEnter: Transition {
                        PropertyAnimation {
                            property: "opacity"
                            from: 0
                            to:1
                            duration: 0
                        }
                    }
                    popExit: Transition {
                        PropertyAnimation {
                            from: 1
                            to:0
                            duration: 0
                        }
                    }

                }
                Component {
                        id: generalView
                        Column {

                        }
                    }
                Component {
                        id: hardwareView
                        Column {
                            spacing: 0.2*margin
                            RowLayout {
                                spacing: 0.3*margin
                                ColumnLayout {
                                    Layout.alignment : Qt.AlignHCenter
                                    spacing: 0.55*margin
                                    Label {
                                        Layout.alignment : Qt.AlignRight
                                        Layout.row: 1
                                        text: "Execution environment:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignRight
                                        Layout.row: 1
                                        text: "Parallel processing:"
                                        bottomPadding: 0.05*margin
                                    }
                                }
                                ColumnLayout {
                                    ComboBox {
                                        editable: false
                                        model: ListModel {
                                            id: modelEnv
                                            ListElement { text: "GPU, if available" }
                                            ListElement { text: "CPU" }
                                        }
                                        onAccepted: {
                                            if (find(editText) === -1)
                                                model.append({text: editText})
                                        }
                                    }
                                    ComboBox {
                                        editable: false
                                        model: ListModel {
                                            id: modelPar
                                            ListElement { text: "1" }
                                            ListElement { text: "2" }
                                            ListElement { text: "3" }
                                            ListElement { text: "4" }
                                            ListElement { text: "5" }
                                            ListElement { text: "6" }
                                        }
                                        onAccepted: {
                                            if (find(editText) === -1)
                                                model.append({text: editText})
                                        }
                                    }
                                }

                            }


                        }
                    }
                Component {
                        id: aboutView
                        Column {
                            spacing: 0.2*margin
                            TextArea {
                                id: descriptionTextArea
                                width: 2*buttonWidth
                                readOnly: true
                                padding: 0
                                anchors.left: parent.left
                                wrapMode: TextEdit.WordWrap
                                horizontalAlignment: TextEdit.AlignJustify
                                text: "This software allows to design and apply neural networks and data "+
                                       "processing functions to images, videos or "+
                                        "data in any other format.\n\n"+
                                        "Copyright (C) 2020 Aleksandr Illarionov\n"
                            }
                            Label {
                                id: licenseLabel
                                text: "License:"
                                bottomPadding: 0.1*margin
                            }
                            Flickable {
                                clip: true
                                //anchors.top: licenseLabel.bottom
                                leftMargin: 0
                                height: 4*buttonHeight
                                width: contentWidth
                                contentWidth: licenseTextArea.width;
                                contentHeight: licenseTextArea.height
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.vertical: ScrollBar{
                                    id: vertical
                                    policy: ScrollBar.AsNeeded
                                    contentItem:
                                        Rectangle {
                                            implicitWidth: 25*pix
                                            implicitHeight: 100
                                            color: "transparent"
                                            Rectangle {
                                                anchors.right: parent.right
                                                implicitWidth: 10*pix
                                                implicitHeight: parent.height
                                                radius: width / 2
                                                color: vertical.pressed ? systempalette.dark : systempalette.mid
                                            }
                                    }
                                }
                                TextArea {
                                    id: licenseTextArea
                                    width: 2*buttonWidth+20*pix
                                    readOnly: true
                                    leftPadding: 0
                                    rightPadding: 20*pix
                                    anchors.left: parent.left
                                    wrapMode: TextEdit.WordWrap
                                    horizontalAlignment: TextEdit.AlignJustify
                                    text: "This program is free software: you can redistribute it and/or modify "+
                                           "it under the terms of the GNU General Public License as published "+
                                           "by the Free Software Foundation; either version 3 of the License, "+
                                           "or (at your option) any later version.\n\n"+
                                           "This program is distributed in the hope that it will be useful, "+
                                           "but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY "+
                                           "or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public "+
                                           "License for more details.\n\n"+
                                           "You should have received a copy of the GNU General Public License "+
                                           "along with Deep Data Analysis. If not, see: https://www.gnu.org/licenses/"
                                }
                            }
                        }
                    }

            }
        }
    }

}
