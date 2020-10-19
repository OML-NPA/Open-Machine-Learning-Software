import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"

Component {
    id: generalOptionsView
    StackView {
        id: stack
        initialItem: hardwareView
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
        Component {
            id: repeaterComponent
            Row {
                x: 1.3*buttonWidth-2*pix
                Repeater {
                    id: menubuttonRepeater
                    Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                    model: [{"name": "Hardware resources", "stackview": hardwareView},
                        {"name": "About", "stackview": aboutView}]
                    delegate : MenuButton {
                        id: general
                        //width: 0.8*buttonWidth
                        height: 1*buttonHeight
                        font_size: 11
                        horizontal: true
                        onClicked: {
                            stack.push(modelData.stackview);
                            for (var i=0;i<(menubuttonRepeater.count);i++) {
                                menubuttonRepeater.itemAt(i).buttonfocus = false
                            }
                            buttonfocus = true
                        }
                        text: modelData.name
                    }
                }
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
                                Layout.alignment : Qt.AlignLeft
                                Layout.row: 1
                                text: "Execution environment:"
                            }
                            Label {
                                Layout.alignment : Qt.AlignLeft
                                Layout.row: 1
                                text: "Allowed CPU cores:"
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
                        width: panel_width
                        font.pointSize: 10
                        font.family: "Proxima Nova"
                        readOnly: true
                        padding: 0
                        anchors.left: parent.left
                        wrapMode: TextEdit.WordWrap
                        horizontalAlignment: TextEdit.AlignJustify
                        text: "This software allows to design and apply neural networks and data "+
                               "processing functions to images, videos or "+
                                "data in any other format.\n\n"+
                                "Copyright (C) 2020 Aleksandr Illarionov and Daria Aborneva\n"
                    }
                    Label {
                        id: licenseLabel
                        text: "License:"
                        font.pointSize: 10
                        bottomPadding: 0.1*margin
                    }
                    Flickable {
                        clip: true
                        //anchors.top: licenseLabel.bottom
                        leftMargin: 0
                        height: 600*pix
                        width: contentWidth
                        contentWidth: licenseTextArea.width;
                        contentHeight: licenseTextArea.height
                        boundsBehavior: Flickable.StopAtBounds
                        /*ScrollBar.vertical: ScrollBar{
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
                                        color: defaultpalette.border
                                    }
                            }
                        }*/
                        TextArea {
                            id: licenseTextArea
                            width: panel_width
                            font.pointSize: 10
                            font.family: "Proxima Nova"
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
                                   "along with this program. If not, see: https://www.gnu.org/licenses/"
                        }
                    }
                }
        }
        Component.onCompleted: {
            repeaterComponent.createObject(window.header);
        }
    }
}

