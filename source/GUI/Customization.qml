
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
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
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property color defaultcolor: systempalette.window

    property bool optionsOpen: false
    property bool localtrainingOpen: false

    property string currentfolder: Qt.resolvedUrl(".")

    onClosing: { customizationLoader.sourceComponent = undefined }

    GridLayout {
        id: gridLayout
        RowLayout {
            Frame {
                Layout.preferredHeight: 0.2*Screen.height
                Layout.preferredWidth: 2*(buttonWidth + 0.5*margin)
                backgroundColor: systempalette.light
                ScrollView {
                    clip: true
                    anchors.fill: parent
                    padding: 0
                    //topPadding: 0.01*margin
                    spacing: 0
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    Flickable {
                        boundsBehavior: Flickable.StopAtBounds
                        contentHeight: 1.25*(Math.max(build1View.height,build2View.height)+buttonHeight-2)
                        Item {
                            ListView {
                                id: build1View
                                height: childrenRect.height
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {id: build1Model}
                                delegate: TreeButton {
                                    width: buttonWidth + 0.5*margin-4
                                    height: buttonHeight-2
                                    onClicked: {
                                    }
                                    RowLayout {
                                        anchors.fill: parent.fill
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
                                anchors.top: build1View.bottom
                                width: buttonWidth + 0.5*margin-4
                                height: buttonHeight-2
                                Label {
                                    topPadding: 0.15*margin
                                    leftPadding: 0.2*margin
                                    text: "Add more"
                                }
                                onClicked: {build1Model.append({ "name": "feature"})
                                }
                            }
                        }
                        Item {
                            x: buttonWidth
                            ListView {

                                id: build2View
                                height: childrenRect.height
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {id: build2Model}
                                delegate: TreeButton {
                                    width: buttonWidth + 0.5*margin-4
                                    height: buttonHeight-2
                                    onClicked: {
                                    }
                                    RowLayout {
                                        anchors.fill: parent.fill
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
                                anchors.top: build2View.bottom
                                width: buttonWidth + 0.5*margin-4
                                height: buttonHeight-2
                                Label {
                                    topPadding: 0.15*margin
                                    leftPadding: 0.2*margin
                                    text: "Add more"
                                }
                                onClicked: {build2Model.append({ "name": "feature"})
                                }
                            }
                        }

                    }
                }
            }
        }
    }

}
