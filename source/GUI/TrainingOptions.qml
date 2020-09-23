
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
    property var analysisOptions: {parent_imgs: ""; parent_label: "";
        labels_color: []; labels_incl: []; border: []; mirror: true;
        num_angles: 6; pix_fr_lim: 0.1}

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
            Pane {
                spacing: 0
                width: 1.3*buttonWidth
                padding: -1
                topPadding: tabmargin/2
                bottomPadding: tabmargin/2
                backgroundColor: defaultpalette.window2
                Column {
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: [{"name": "Processing", "stackview": processingView},
                            {"name": "Hyperparameters", "stackview": hyperparametersView}]
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
                        height: 8*buttonHeight
                        color: defaultpalette.window2
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
                    initialItem: processingView
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
                        id: processingView
                        Column {
                            spacing: 0.2*margin
                            Label {
                                text: "Augmentation"
                                font.bold: true
                            }
                            CheckBox {
                                text: "Mirroring"
                                onClicked: {
                                    if (checkState==Qt.Checked) {
                                        analysisOptions.mirroring = true
                                    }
                                    else  {
                                        analysisOptions.mirroring = false
                                    }
                                }
                            }
                            Row {
                                spacing: 0.55*margin
                                Label {
                                    text: "Rotation (number of angles):"
                                }
                                SpinBox {
                                    from: 1
                                    value: 6
                                    to: 10
                                    onValueModified: {
                                        analysisOptions.num_angles = value
                                    }
                                }
                            }
                            Row {
                                spacing: 0.55*margin
                                Label {
                                    text: "Minimum fraction of labeled pixels:"
                                }
                                SpinBox {
                                    from: 0
                                    value: 10
                                    to: 100
                                    stepSize: 10
                                    property real realValue: value/100
                                    textFromValue: function(value, locale) {
                                        return Number(value/100).toLocaleString(locale,'f',1)
                                    }
                                    onValueModified: {
                                        analysisOptions.pix_fr_lim = value/100
                                    }
                                }
                            }
                        }

                }
                Component {
                        id: hyperparametersView
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
