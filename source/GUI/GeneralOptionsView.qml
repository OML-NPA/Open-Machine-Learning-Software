import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"

Component {
    id: generalOptionsView
    Column {
        padding: 1*margin
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
    }
}

