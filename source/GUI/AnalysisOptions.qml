
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
    title: qsTr("  Deep Data Analysis Software")
    minimumWidth: gridLayout.width
    minimumHeight: 800*pix
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height

    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double tabmargin: 0.5*margin
    property double pix: Screen.width/3840

    property bool terminate: false

    FolderDialog {
            id: folderDialog
            onAccepted: {
                Julia.browsefolder(folderDialog.folder)
                Qt.quit()
            }
    }

    onClosing: { analysisoptionsLoader.sourceComponent = null }

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            //spacing: margin
            Pane {
                id: menuPane
                spacing: 0
                padding: -1
                width: 1.3*buttonWidth
                height: window.height
                topPadding: tabmargin/2
                bottomPadding: tabmargin/2
                backgroundColor: defaultpalette.window2

                Column {
                    id: menubuttonColumn
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: [{"name": "General", "stackview": generalView}]
                        delegate : MenuButton {
                            id: general
                            width: 1.5*buttonWidth
                            height: 1.25*buttonHeight
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
                        spacing: 0.5*margin
                        ColumnLayout {
                            spacing: 0.4*margin
                            RowLayout {
                                spacing: 0.3*margin
                                ColumnLayout {
                                    Layout.alignment : Qt.AlignHCenter
                                    spacing: 0.6*margin
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 1
                                        text: "Output data type:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 1
                                        text: "Output image type:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 1
                                        text: "Downsize images:"
                                        bottomPadding: 0.05*margin
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 1
                                        text: "Reduce framerate (video):"
                                        bottomPadding: 0.05*margin
                                    }
                                }
                                ColumnLayout {
                                    ComboBox {
                                        editable: false
                                        model: ListModel {
                                            id: modelData
                                            ListElement { text: "XLSX" }
                                            ListElement { text: "XLS" }
                                            ListElement { text: "CSV" }
                                            ListElement { text: "TXT" }
                                        }
                                        onAccepted: {
                                            if (find(editText) === -1)
                                                model.append({text: editText})
                                        }
                                    }
                                    ComboBox {
                                        editable: false
                                        model: ListModel {
                                            id: modelImages
                                            ListElement { text: "PNG" }
                                            ListElement { text: "TIFF" }
                                        }
                                        onAccepted: {
                                            if (find(editText) === -1)
                                                model.append({text: editText})
                                        }
                                    }
                                    ComboBox {
                                    editable: false
                                    model: ListModel {
                                        id: resizeModel
                                        ListElement { text: "Disable" }
                                        ListElement { text: "1.5x" }
                                        ListElement { text: "2x" }
                                        ListElement { text: "3x" }
                                        ListElement { text: "4x" }
                                    }
                                    onAccepted: {
                                        if (find(editText) === -1)
                                            model.append({text: editText})
                                    }
                                    }
                                    ComboBox {
                                    editable: false
                                    model: ListModel {
                                        id: skipframesModel
                                        ListElement { text: "Disable" }
                                        ListElement { text: "2x" }
                                        ListElement { text: "3x" }
                                        ListElement { text: "4x" }
                                    }
                                    onAccepted: {
                                        if (find(editText) === -1)
                                            model.append({text: editText})
                                    }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            Label {
                                text: "Scaling:"
                                bottomPadding: 0.05*margin
                            }
                            TextField {
                                Layout.preferredWidth: 0.3*buttonWidth
                                Layout.preferredHeight: buttonHeight
                                maximumLength: 6
                                validator: DoubleValidator { bottom: 0.0001; top: 999999;
                                    decimals: 4; notation: DoubleValidator.StandardNotation}
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
