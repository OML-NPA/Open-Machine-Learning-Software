
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
    property double pix: Screen.width/3840
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double tabmargin: 0.5*margin
    property color menucolor: "#fafafa"
    property color defaultcolor: systempalette.window

    onClosing: { selectneuralnetworkLoader.sourceComponent = null }

    ListModel {
        id: emptyModel
        ListElement { text: "" }
    }


    GridLayout {
        id: gridLayout
        ColumnLayout {
            Layout.margins: margin
            spacing: 0.2*margin
            RowLayout {
                spacing: 0.2*margin
                ColumnLayout {
                    Layout.alignment : Qt.AlignHCenter | Qt.AlignTop
                    spacing: 0.55*margin
                    Layout.topMargin: 0.2*margin
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Data type:"
                    }
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Data subtype:"
                        //bottomPadding: 0.05*margin
                    }
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Cell subtype:"
                        //bottomPadding: 0.05*margin
                    }
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Neural network:"
                    }
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Encoder length:"
                    }
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Decoder length:"
                    }
                }
                ColumnLayout {
                ComboBox {
                    editable: false
                    Layout.preferredWidth: buttonWidth + 0.5*margin
                    Layout.leftMargin: 0.5*margin
                    onActivated: {}
                    model: ListModel {
                        id: datatypeModel
                        ListElement { text: "Image" }
                        ListElement { text: "Other" }
                    }
                }
                ComboBox {
                    editable: false
                    Layout.preferredWidth: buttonWidth + 0.5*margin
                    Layout.leftMargin: 0.5*margin
                    model: ListModel {
                        id: datasubtypeModel
                        ListElement { text: "Biological image" }
                        ListElement { text: "Other" }
                    }
                }
                ComboBox {
                    editable: false
                    Layout.preferredWidth: buttonWidth + 0.5*margin
                    Layout.leftMargin: 0.5*margin
                    model: ListModel {
                        id: datasubsubtypeModel
                        ListElement { text: "Bacteria" }
                        ListElement { text: "Yeast" }
                        ListElement { text: "Mammalian" }
                    }
                }
                ComboBox {
                    editable: false
                    Layout.preferredWidth: buttonWidth + 0.5*margin
                    Layout.leftMargin: 0.5*margin
                    model: ListModel {
                        id: neuralnetworkModel
                        ListElement { text: "defaultnet" }
                        ListElement { text: "net1" }
                        ListElement { text: "net2" }
                    }
                }
                ComboBox {
                    editable: false
                    Layout.preferredWidth: buttonWidth + 0.5*margin
                    Layout.leftMargin: 0.5*margin
                    currentIndex: 5
                    model: ListModel {
                        id: encoderModel
                        ListElement { text: "1" }
                        ListElement { text: "2" }
                        ListElement { text: "3" }
                        ListElement { text: "4" }
                        ListElement { text: "5" }
                        ListElement { text: "6" }
                    }
                }
                ComboBox {
                    editable: false
                    Layout.preferredWidth: buttonWidth + 0.5*margin
                    Layout.leftMargin: 0.5*margin
                    currentIndex: 4
                    model: ListModel {
                        id: decoderModel
                        ListElement { text: "1" }
                        ListElement { text: "2" }
                        ListElement { text: "3" }
                        ListElement { text: "4" }
                        ListElement { text: "5" }
                        ListElement { text: "6" }
                    }
                }
            }
        }
       }
    }
}










