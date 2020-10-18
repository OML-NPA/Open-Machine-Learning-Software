import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  Deep Data Analysis Software")
    minimumWidth: 1670*pix
    minimumHeight: 1200*pix

    color: defaultpalette.window
    property double pix: Screen.width/3840
    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property color defaultcolor: palette.window

    property var defaultcolors: {"light": rgbtohtml([254,254,254]),"light2": rgbtohtml([253,253,253]),
        "midlight": rgbtohtml([245,245,245]),"midlight2": rgbtohtml([240,240,240]),
        "midlight3": rgbtohtml([235,235,235]),
        "mid": rgbtohtml([220,220,220]),"middark": rgbtohtml([210,210,210]),
        "middark2": rgbtohtml([180,180,180]),"dark2": rgbtohtml([160,160,160]),
        "dark": rgbtohtml([130,130,130])}

    property var defaultpalette: {"window": defaultcolors.midlight,
                                  "window2": defaultcolors.midlight3,
                                  "button": defaultcolors.light2,
                                  "buttonhovered": defaultcolors.mid,
                                  "buttonpressed": defaultcolors.middark,
                                  "buttonborder": defaultcolors.dark2,
                                  "controlbase": defaultcolors.light,
                                  "controlborder": defaultcolors.middark2,
                                  "border": defaultcolors.dark2,
                                  "listview": defaultcolors.light
                                  }

    property string currentfolder: Qt.resolvedUrl(".")

    onClosing: Julia.save_data()

    header: Rectangle {
        width: window.width
        height: buttonHeight
        color: menuPane.backgroundColor

    }

    MouseArea {
        id: mainMouseArea
        width: window.width
        height: window.height
        onClicked: mainMouseArea.focus = true
    }

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            Pane {
                id: menuPane
                spacing: 0
                padding: -1
                topPadding: 1
                width: 1.3*buttonWidth
                height: window.height
                backgroundColor: defaultpalette.window2
                Column {
                    id: menubuttonColumn
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: [{"name": "Main", "stackview": mainView},
                            {"name": "Options", "stackview": generalOptionsView},
                            {"name": "Training", "stackview": trainingView},
                            {"name": "Analysis", "stackview": analysisView},
                            {"name": "Visualisation", "stackview": visualisationView}]
                        delegate : MenuButton {
                            id: general
                            width: 1.3*buttonWidth
                            height: 1.5*buttonHeight
                            font_size: 13
                            onClicked: {
                                if (window.header.children[0]!==undefined) {
                                    window.header.children[0].destroy()
                                }
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
                Layout.margins: margin
                StackView {
                    id: stack
                    initialItem: mainView
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
                    MainView { id: mainView}
                    GeneralOptionsView { id: generalOptionsView}
                    TrainingView { id: trainingView}
                    AnalysisView { id: analysisView}
                    VisualisationView { id: visualisationView}

                }
           }
        }
    }
//--Functions---------------------------------------------------------

    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }

    function updatefolder(path) {
            currentfolder = path
            folderModel.folder = currentfolder
            folderView.model = folderModel
            Julia.browsefolder(folderDialog.folder)
        }
}
