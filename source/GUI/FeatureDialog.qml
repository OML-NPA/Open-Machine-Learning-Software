
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

    onClosing: { featuredialogLoader.sourceComponent = null }


    GridLayout {
        id: gridLayout
        ColumnLayout {
            Layout.margins: margin
            spacing: 0.7*margin
            ColumnLayout {
                //spacing: 0.25*margin
                RowLayout {
                    spacing: 0.3*margin
                    ColumnLayout {
                        Layout.alignment : Qt.AlignHCenter
                        spacing: 0.55*margin
                        Label {
                            Layout.alignment : Qt.AlignLeft
                            text: "Name:"
                            bottomPadding: 0.05*margin
                        }
                        Label {
                            Layout.alignment : Qt.AlignLeft
                            Layout.row: 1
                            text: "Type:"
                        }
                        Label {
                            Layout.alignment : Qt.AlignLeft
                            Layout.row: 1
                            text: "Parent:"
                            bottomPadding: 0.05*margin
                        }
                    }
                    ColumnLayout {
                        TextField {
                            id: name
                            text: featureModel.get(indTree).name
                            Layout.alignment : Qt.AlignLeft
                            Layout.preferredWidth: 0.7*buttonWidth
                            Layout.preferredHeight: buttonHeight
                        }
                        ComboBox {
                            id: typeComboBox
                            editable: false
                            model: ListModel {
                            id: modelEnv
                                ListElement { text: "Cell" }
                                ListElement { text: "Organelle" }
                                ListElement { text: "Other" }
                            }
                            onAccepted: {
                                if (find(editText) === -1)
                                    model.append({text: editText})
                            }
                        }
                        ComboBox {

                            ListModel {
                                id: emptyListModel
                                ListElement {
                                    text: ""
                                }
                            }
                            ListModel {
                                id: filledListModel
                                ListElement {
                                    text: "Cell1"
                                }
                                ListElement {
                                    text: "Cell2"
                                }
                            }

                            id: parentComboBox
                            editable: false
                            model: typeComboBox.currentText !== "Cell" ? filledListModel :
                                   emptyListModel
                            onAccepted: {
                                if (find(editText) === -1)
                                    model.append({text: editText})
                            }
                        }
                    }

                }
            Label {
                Layout.topMargin: 0.5*margin
                text: "Color (RGB):"
            }
            RowLayout {
                Layout.topMargin: 0.2*margin
                Layout.bottomMargin: 0.5*margin
                spacing: 0.3*margin
                Label {
                    Layout.row: 1
                    text: "Red:"
                }
                TextField {
                    id: red
                    text: featureModel.get(indTree).colorR
                    Layout.preferredWidth: 0.25*buttonWidth
                    Layout.preferredHeight: buttonHeight
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                    if (parseFloat(red.text)>255) {
                            red.text = "255"
                        }
                    }
                }
                Label {
                    Layout.row: 1
                    text: "Green:"
                }
                TextField {
                    id: green
                    text: featureModel.get(indTree).colorG
                    Layout.preferredWidth: 0.25*buttonWidth
                    Layout.preferredHeight: buttonHeight
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                        if (parseFloat(green.text)>255) {
                            green.text = "255"
                        }
                    }
                }
                Label {
                    Layout.row: 1
                    text: "Blue:"
                }
                TextField {
                    id: blue
                    text: featureModel.get(indTree).colorB
                    Layout.preferredWidth: 0.25*buttonWidth
                    Layout.preferredHeight: buttonHeight
                    maximumLength: 3
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                        console.log(parseFloat(blue.text))
                        if (parseFloat(blue.text)>255) {
                            blue.text = "255"
                        }
                    }
                }
            }
            RowLayout {
                Layout.alignment : Qt.AlignHCenter
                spacing: 1.5*margin
                Button {
                    text: "Apply"
                    Layout.preferredWidth: buttonWidth/2
                    Layout.preferredHeight: buttonHeight
                    onClicked: {
                        featureModel.get(indTree).colorR = parseFloat(red.text)
                        featureModel.get(indTree).colorG = parseFloat(green.text)
                        featureModel.get(indTree).colorB = parseFloat(blue.text)
                        featureModel.get(indTree).name = name.text
                        featureView.itemAtIndex(indTree).children[0].children[0].colorRGB =
                                [featureModel.get(indTree).colorR,
                                 featureModel.get(indTree).colorG,
                                 featureModel.get(indTree).colorB]
                    }
                }
                Button {
                    text: "Delete"
                    Layout.preferredWidth: buttonWidth/2
                    Layout.preferredHeight: buttonHeight
                    onClicked: {
                        featureModel.remove(indTree)
                        window.visible = false
                    }
                }
            }
            }
        }
    }
}










