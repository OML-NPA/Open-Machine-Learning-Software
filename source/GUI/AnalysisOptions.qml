
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
                topPadding: tabmargin/2
                bottomPadding: tabmargin/2
                backgroundColor: defaultpalette.window2

                Column {
                    id: menubuttonColumn
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: [{"name": "General", "stackview": generalView},
                            {"name": "Mask", "stackview": maskView},
                            {"name": "Cell volume", "stackview": cellvolumeView},
                            {"name": "Vacuole volume", "stackview": vacuolevolumeView},
                            {"name": "Mother/daugther assignment", "stackview": motherdaugtherassignmentView}]
                        delegate : MenuButton {
                            id: general
                            width: 1.3*buttonWidth
                            height: buttonHeight
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
                    Rectangle {
                        width: 1.3*buttonWidth
                        height: 6*buttonHeight
                        color: menuPane.backgroundColor
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
                                Label {
                                    text: "pixels per µm"
                                    bottomPadding: 0.05*margin
                                }
                            }
                            RowLayout {
                                spacing: 0.3*margin
                                Label {
                                    text: "Neural Network:"
                                    bottomPadding: 0.05*margin
                                }
                                ComboBox {
                                    editable: false
                                    Layout.preferredWidth: 0.9*buttonWidth
                                    model: ListModel {
                                        id: netModel
                                        ListElement { text: "defaultNetE5D4Yeast" }
                                    }
                                }
                                Button {
                                    Layout.preferredWidth: buttonWidth/2
                                    Layout.preferredHeight: buttonHeight
                                    text: "Browse"
                                }
                            }
                        }
                    }
                Component {
                        id: maskView
                        Column {
                            spacing: 0.2*margin
                            Label {
                                text: "Outputs:"
                            }
                            CheckBox {
                                text: "Mask"

                            }
                        }
                    }
                Component {
                        id: cellvolumeView
                        Column {
                            spacing: 0.2*margin
                            Label {
                                text: "Outputs:"
                            }
                            CheckBox {
                                text: "Cell volume distribution"
                            }
                            CheckBox {
                                text: "Individual cell volume "
                            }
                            Rectangle {
                                height: 0.2*margin
                                width: 0.2*margin
                                color: defaultpalette.window
                            }

                            Label {
                                text: "Histogram options:"
                            }
                            RowLayout {
                                spacing: 0.3*margin
                                ColumnLayout {
                                    spacing: 0.55*margin
                                    Label {
                                        id: label
                                        Layout.alignment : Qt.AlignRight
                                        Layout.row: 1
                                        text: "Number of bins:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignRight
                                        Layout.row: 1
                                        text: "Maximum volume:"
                                        bottomPadding: 0.05*margin
                                    }
                                }
                                ColumnLayout {
                                    TextField {
                                        Layout.row: 2
                                        Layout.preferredWidth: 0.25*buttonWidth
                                        Layout.preferredHeight: buttonHeight
                                        maximumLength: 5
                                        validator: IntValidator { bottom: 1; top: 99999;}
                                    }
                                    TextField {
                                        Layout.row: 2
                                        Layout.preferredWidth: 0.25*buttonWidth
                                        Layout.preferredHeight: buttonHeight
                                        maximumLength: 5
                                        validator: IntValidator { bottom: 1; top: 99999;}
                                    }
                                }
                                ColumnLayout {
                                    spacing: 0.6*margin
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 3
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 3
                                        text: "fL"
                                    }
                                }

                            }


                        }
                    }
                Component {
                        id: vacuolevolumeView
                        Column {
                            spacing: 0.2*margin
                            Label {
                                text: "Outputs:"
                            }
                            CheckBox {
                                text: "Vacuole volume distribution"
                            }
                            CheckBox {
                                text: "Individual vacuole cell volume "
                            }
                            CheckBox {
                                text: "Mean vacuole volume per cell volume"
                            }
                            CheckBox {
                                text: "Vacuole to cell ratio"
                            }
                            Rectangle {
                                height: 0.2*margin
                                width: 0.2*margin
                                color: defaultpalette.window
                            }

                            Label {
                                text: "Histogram options:"
                            }
                            RowLayout {
                                spacing: 0.3*margin
                                ColumnLayout {
                                    spacing: 0.55*margin
                                    Label {
                                        id: label
                                        Layout.alignment : Qt.AlignRight
                                        Layout.row: 1
                                        text: "Number of bins:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignRight
                                        Layout.row: 1
                                        text: "Maximum volume:"
                                        bottomPadding: 0.05*margin
                                    }
                                }
                                ColumnLayout {
                                    TextField {
                                        Layout.row: 2
                                        Layout.preferredWidth: 0.25*buttonWidth
                                        Layout.preferredHeight: buttonHeight
                                        maximumLength: 5
                                        validator: IntValidator { bottom: 1; top: 99999;}
                                    }
                                    TextField {
                                        Layout.row: 2
                                        Layout.preferredWidth: 0.25*buttonWidth
                                        Layout.preferredHeight: buttonHeight
                                        maximumLength: 5
                                        validator: IntValidator { bottom: 1; top: 99999;}
                                    }
                                }
                                ColumnLayout {
                                    spacing: 0.5*margin
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 3
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 3
                                        text: "fL"
                                    }
                                }

                            }


                        }
                    }
                Component {
                        id: motherdaugtherassignmentView
                        Column {
                            spacing: 0.2*margin
                            Label {
                                text: "Outputs:"
                            }
                            CheckBox {
                                text: "Mother and daugther assignment"
                            }
                            CheckBox {
                                text: "Mother and daugther volume"
                            }
                            CheckBox {
                                text: "Mother and daugther circularity"
                            }
                            Rectangle {
                                height: 0.2*margin
                                width: 0.2*margin
                                color: defaultpalette.window
                            }

                            Label {
                                text: "Bud definition:"
                            }
                            RowLayout {
                                spacing: 0.3*margin
                                Label {
                                    Layout.alignment : Qt.AlignRight
                                    Layout.row: 1
                                    wrapMode: Label.WordWrap
                                    text: "Maximum percentage of mother volume:"
                                    bottomPadding: 0.05*margin
                                }
                                TextField {
                                    Layout.row: 2
                                    Layout.preferredWidth: 0.15*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    maximumLength: 2
                                    validator: RegularExpressionValidator { regularExpression: /[0-9]+/ }
                                }
                                Label {
                                    Layout.alignment : Qt.AlignLeft
                                    Layout.row: 1
                                    wrapMode: Label.WordWrap
                                    text: "%"
                                    bottomPadding: 0.05*margin
                                }

                            }


                        }
                    }
           }
        }
    }

}
