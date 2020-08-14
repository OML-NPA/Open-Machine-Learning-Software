
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
    property double fontsize: Math.round(11*Screen.height/2160)
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double tabmargin: 0.5*margin
    property color menucolor: "#fafafa"
    property color defaultcolor: systempalette.window

    onClosing: { selectneuralnetworkLoader.sourceComponent = null }


    GridLayout {
        id: gridLayout
        RowLayout {
            Layout.margins: margin
            spacing: 0.2*margin
            ColumnLayout {
                Layout.alignment : Qt.AlignHCenter
                spacing: 0.55*margin
                Label {
                    Layout.alignment : Qt.AlignLeft
                    Layout.row: 1
                    text: "Data type:"
                }
                Label {
                    Layout.alignment : Qt.AlignLeft
                    Layout.row: 1
                    text: "Data subtype:"
                    bottomPadding: 0.05*margin
                }
            }
            ColumnLayout {
                ComboBox {
                    editable: false
                    Layout.preferredWidth: buttonWidth + 0.5*margin
                    Layout.leftMargin: 0.5*margin
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
            }
        }
    }
}










