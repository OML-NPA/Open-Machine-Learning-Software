
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  Deep Data Analysis Software v.0.1")
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

    FolderDialog {
            id: folderDialog
            onAccepted: {
                Julia.browsefolder(folderDialog.folder)
                Qt.quit()
            }
    }

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            Pane {
                spacing: 0
                width: 1.3*buttonWidth
                height: window.height
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
                                checkState : Julia.get_data(
                                           ["Training","Options","Processing","mirroring"]) ?
                                           Qt.Checked : Qt.Unchecked
                                onClicked: {
                                    var value = checkState==Qt.Checked ? true : false
                                    Julia.set_data(
                                        ["Training","Options","Processing","mirroring"],
                                        value)
                                }
                            }
                            Row {
                                spacing: 0.55*margin
                                Label {
                                    text: "Rotation (number of angles):"
                                }
                                SpinBox {
                                    from: 1
                                    value: Julia.get_data(
                                               ["Training","Options","Processing","num_angles"])
                                    to: 10
                                    onValueModified: {
                                        Julia.set_data(
                                            ["Training","Options","Processing","num_angles"],
                                            value)
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
                                    value: 100*Julia.get_data(
                                               ["Training","Options","Processing","min_fr_pix"])
                                    to: 100
                                    stepSize: 10
                                    property real realValue: value/100
                                    textFromValue: function(value, locale) {
                                        return Number(value/100).toLocaleString(locale,'f',1)
                                    }
                                    onValueModified: {
                                        Julia.set_data(
                                            ["Training","Options","Processing","min_fr_pix"],
                                            value/100)
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
                                        text: "Batch size:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 1
                                        text: "Number of epochs:"
                                        bottomPadding: 0.05*margin
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        Layout.row: 1
                                        text: "Learning rate:"
                                        bottomPadding: 0.05*margin
                                    }

                                }
                                Column {
                                    topPadding: 0*pix
                                    spacing: 0.50*margin
                                    SpinBox {
                                        from: 1
                                        value: Julia.get_data(
                                                   ["Training","Options","Hyperparameters","batch_size"])
                                        to: 10000
                                        stepSize: 1
                                        editable: true
                                        onValueModified: {
                                            Julia.set_data(
                                                ["Training","Options","Hyperparameters","batch_size"],
                                                value)
                                        }
                                    }
                                    SpinBox {
                                        from: 1
                                        value: Julia.get_data(
                                                   ["Training","Options","Hyperparameters","epochs"])
                                        to: 100000
                                        stepSize: 1
                                        editable: true
                                        onValueModified: {
                                            Julia.set_data(
                                                ["Training","Options","Hyperparameters","epochs"],
                                                value)
                                        }
                                    }
                                    SpinBox {
                                        from: 1
                                        value: 100000*Julia.get_data(
                                                   ["Training","Options","Hyperparameters","learning_rate"])
                                        to: 1000
                                        stepSize: 100
                                        editable: true
                                        property real realValue: value/100000
                                        textFromValue: function(value, locale) {
                                            return Number(value/100000).toLocaleString(locale,'e',0)
                                        }
                                        onValueModified: {
                                            if (value>1000) {
                                                stepSize = 1000
                                            }
                                            else if (value>100) {
                                                stepSize = 100
                                            }
                                            else if (value>10) {
                                                stepSize = 10
                                            }
                                            else {
                                                stepSize = 1
                                            }
                                            Julia.set_data(
                                                ["Training","Options","Hyperparameters","learning_rate"],
                                                value/100000)
                                        }
                                    }
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
