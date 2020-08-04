
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

    Loader { id: optionsLoader
    }

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
                        id: general
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(generalView)}
                        text: "General"

                    }
                    MenuButton {
                        id: mask
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(maskView)}
                        text: "Mask"
                    }
                    MenuButton {
                        id: cellvolume
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(cellvolumeView)}
                        text: "Cell volume"
                    }
                    MenuButton {
                        id: vacuolarvolume
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(vacuolarvolumeView)}
                        text: "Vacuolar volume"
                    }
                    MenuButton {
                        id: motherdaugtherassignment
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(motherdaugtherassignmentView)}
                        text: "Mother/daugther assignment"
                    }
                    MenuButton {
                        id: advanced
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {stack.push(advancedView)}
                        text: "Advanced"
                    }
                    Rectangle {
                        Layout.row: 1
                        Layout.preferredWidth: 1.3*buttonWidth
                        Layout.preferredHeight: 5*buttonHeight
                        color: menucolor
                    }

                }
            }
            ColumnLayout {
                Layout.margins: 0.5*margin
                Layout.row: 2
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 2*buttonWidth
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
                                Label {
                                    Layout.alignment : Qt.AlignLeft
                                    Layout.row: 1
                                    text: "Output:"
                                }
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
                                            id: modelResize
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
                                TextField {
                                    Layout.preferredWidth: 0.7*buttonWidth
                                    Layout.preferredHeight: buttonHeight
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
                                color: defaultcolor
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
                                        Text {
                                            text: "."
                                            color: menucolor
                                        }
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
                        id: vacuolarvolumeView
                        Column {
                            spacing: 0.2*margin
                            Label {
                                text: "Outputs:"
                            }
                            CheckBox {
                                text: "Vacuolar volume distribution"
                            }
                            CheckBox {
                                text: "Individual vacuolar cell volume "
                            }
                            CheckBox {
                                text: "Mean vacuolar volume per cell volume"
                            }
                            CheckBox {
                                text: "Vacuole to cell ratio"
                            }
                            Rectangle {
                                height: 0.2*margin
                                width: 0.2*margin
                                color: defaultcolor
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
                                        Text {
                                            text: "."
                                            color: menucolor
                                        }
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
                                color: defaultcolor
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
                Component {
                        id: advancedView
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

            }
        }
    }

}
