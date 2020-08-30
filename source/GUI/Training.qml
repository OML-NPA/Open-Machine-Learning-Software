
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
    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double pix: Screen.width/3840
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double tabmargin: 0.5*margin
    property color menucolor: "#fafafa"
    property color defaultcolor: systempalette.window

    property bool terminate: false

    property var colors: [[0,255,0],[255,0,0],[0,0,255],[255,255,0],[255,0,255]]
    property string colorR: "0"
    property string colorG: "0"
    property string colorB: "0"
    property int indTree: 0

    onClosing: { trainingLoader.sourceComponent = null }

    FolderDialog {
            id: folderDialog
            currentFolder: currentfolder
            onAccepted: {
                Julia.browsefolder(folderDialog.folder)
                Qt.quit()
            }
    }

    Loader { id: featuredialogLoader}
    Loader { id: trainingoptionsLoader}
    Loader { id: customizationLoader}
    Loader { id: trainingplotLoader}

    GridLayout {
        id: gridLayout
        ColumnLayout {
            Layout.margins: margin
            spacing: 0.7*margin
            ColumnLayout {
                spacing: 0.5*margin
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Neural Network \ntemplate:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1.4*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        text: "Browse"
                    }
                }
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Images:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1.4*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        text: "Browse"
                    }
                }
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Labels:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1.4*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        text: "Browse"
                    }
                }
                RowLayout {
                    spacing: 0.3*margin
                    Label {
                        text: "Name:"
                        bottomPadding: 0.05*margin
                        Layout.preferredWidth: 0.55*buttonWidth
                    }
                    TextField {
                        Layout.preferredWidth: 1.4*buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                }
            }
            RowLayout {
                spacing:1.75*margin
                Column {
                    spacing: -2
                    Label {
                        width: buttonWidth + 0.5*margin
                        text: "Features:"
                        padding: 0.1*margin
                        leftPadding: 0.2*margin
                        background: Rectangle {
                            anchors.fill: parent.fill
                            color: "transparent"
                            border.color: defaultpalette.border
                            border.width: 2
                        }
                    }
                    Frame {
                        height: 0.2*Screen.height
                        width: buttonWidth + 0.5*margin
                        backgroundColor: defaultpalette.listview
                        ScrollView {
                            clip: true
                            anchors.fill: parent
                            padding: 0
                            //topPadding: 0.01*margin
                            spacing: 0
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            Flickable {
                                boundsBehavior: Flickable.StopAtBounds
                                contentHeight: featureView.height+buttonHeight-2
                                Item {
                                    ListView {
                                        id: featureView
                                        height: childrenRect.height
                                        spacing: 0
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: ListModel {id: featureModel}
                                        delegate: TreeButton {
                                            id: control
                                            width: buttonWidth + 0.5*margin-4
                                            height: buttonHeight-2
                                            onClicked: {
                                                if (featuredialogLoader.sourceComponent === null) {
                                                    indTree = index
                                                    featuredialogLoader.source = "FeatureDialog.qml"
                                                }
                                            }
                                            RowLayout {
                                                anchors.fill: parent.fill
                                                Rectangle {
                                                    id: colorRectangle
                                                    Layout.leftMargin: 0.2*margin
                                                    Layout.bottomMargin: 2*pix
                                                    Layout.alignment: Qt.AlignBottom
                                                    height: 30*pix
                                                    width: 30*pix
                                                    border.width: 2*pix
                                                    radius: colorRectangle.width
                                                    color: rgbtohtml([colorR,colorG,colorB])
                                                }
                                                Label {
                                                    topPadding: 0.15*margin
                                                    leftPadding: 0.10*margin
                                                    text: name
                                                    Layout.alignment: Qt.AlignBottom
                                                }
                                            }
                                        }
                                    }
                                    TreeButton {
                                        anchors.top: featureView.bottom
                                        width: buttonWidth + 0.5*margin-4
                                        height: buttonHeight-2
                                        Label {
                                            topPadding: 0.15*margin
                                            leftPadding: 0.2*margin
                                            text: "Add more"
                                        }
                                        onClicked: {featureModel.append({ "name": "feature",
                                                    "colorR": 255, "colorG": 255, "colorB": 255})
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                ColumnLayout {
                    spacing: 0.3*margin
                    Button {
                        id: optionsButton
                        text: "Options"
                        Layout.preferredWidth: buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {
                            if (trainingoptionsLoader.sourceComponent === null) {
                                trainingoptionsLoader.source = "TrainingOptions.qml"
                            }
                        }
                    }
                    Button {
                        id: customizeButton
                        text: "Customize"
                        Layout.preferredWidth: buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {
                            if (customizationLoader.sourceComponent === null) {
                                customizationLoader.source = "Customization.qml"
                            }
                        }
                    }
                    Button {
                        id: validateButton
                        text: "Validate"
                        Layout.preferredWidth: buttonWidth
                        Layout.preferredHeight: buttonHeight
                    }
                    Button {
                        id: starttrainingButton
                        text: "Start training"
                        Layout.preferredWidth: buttonWidth
                        Layout.preferredHeight: buttonHeight
                        onClicked: {
                            if (trainingplotLoader.sourceComponent === null) {
                                trainingplotLoader.source = "TrainingPlot.qml"}
                            }
                    }
                }
            }

        }

    }
//---FUNCTIONS----------------------------------------------------------

    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }

}










