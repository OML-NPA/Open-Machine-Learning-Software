
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import QtQuick.Shapes 1.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
//import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("Image Analysis Software")
    minimumWidth: buttonWidth*5
    minimumHeight: buttonHeight*20
    //maximumWidth: gridLayout.width
    //maximumHeight: gridLayout.height

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }
    color: systempalette.window

    property double margin: 0.02*Screen.width
    property double pix: Screen.width/3840
    property double buttonWidth: 380*pix
    property double buttonHeight: 65*pix
    property color defaultcolor: systempalette.window

    property double defaultWidth: buttonWidth*5/2
    property double defaultHeight: buttonHeight*20

    property double paneHeight: window.height - header.height - 4*pix
    property double paneWidth: window.width-leftFrame.width-rightFrame.width-4*pix

    property bool optionsOpen: false
    property bool localtrainingOpen: false

    property string currentfolder: Qt.resolvedUrl(".")

    onWidthChanged: {
        mainPane.height = window.height - header.height - 4*pix
    }
    onHeightChanged: {
        mainPane.width = window.width-leftFrame.width-rightFrame.width-4*pix
    }
    onClosing: { customizationLoader.sourceComponent = undefined }

    header: ToolBar {
        id: header
        height: 200*pix
        Frame {
            height: header.height
            width: header.width
        }
    }
    GridLayout {
        id: gridLayout
        Row {
            spacing: 0
            Frame {
                id: leftFrame
                height: window.height - header.height
                width: 500*pix
                padding:0
                Item {
                    id: layersItem
                    Label {
                        id: layersLabel
                        width: leftFrame.width
                        text: "Layers:"
                        font.pointSize: 10
                        padding: 0.2*margin
                        leftPadding: 0.2*margin
                        background: Rectangle {
                            anchors.fill: parent.fill
                            color: defaultcolor
                            border.color: systempalette.dark
                            border.width: 2
                        }
                    }
                    Frame {
                        id: layersFrame
                        y: layersLabel.height -2*pix
                        height: 0.6*(window.height - header.height - 2*layersLabel.height)
                        width: leftFrame.width
                        padding: 0
                        backgroundColor: "#FDFDFD"
                        ScrollableItem {
                            y: 2*pix
                            id: layersFlickable
                            height: 0.6*(window.height - header.height - 2*layersLabel.height)-4*pix
                            width: leftFrame.width-2*pix
                            contentHeight: 1.25*buttonHeight*(multlayerView.count +
                                normlayerView.count + activationlayerView.count +
                                resizinglayerView.count + otherlayerView.count) + 5*0.75*buttonHeight
                            ScrollBar.horizontal.visible: false
                            Item {
                                id: layersRow
                                Label {
                                    id: multLabel
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*multLabel.height
                                    text: "Multiplication layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: systempalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                        id: multlayerView
                                        height: childrenRect.height
                                        anchors.top: multLabel.bottom
                                        spacing: 0
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: ListModel {id: multlayerModel
                                                          ListElement{
                                                              type: "Convolution" // @disable-check M16
                                                              group: "mult" // @disable-check M16
                                                              name: "conv"// @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0 // @disable-check M16
                                                              input: 1 // @disable-check M16
                                                              output: 1} // @disable-check M16
                                                          ListElement{
                                                              type: "Transposed convolution" // @disable-check M16
                                                              group: "mult" // @disable-check M16
                                                              name: "tconv" // @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0 // @disable-check M16
                                                              input: 1 // @disable-check M16
                                                              output: 1} // @disable-check M16
                                                          ListElement{
                                                              type: "Fully connected" // @disable-check M16
                                                              group: "mult" // @disable-check M16
                                                              name: "fullycon" // @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0 // @disable-check M16
                                                              input: 1 // @disable-check M16
                                                              output: 1} // @disable-check M16
                                                        }
                                        delegate: buttonComponent
                                    }
                                Label {
                                    id: normLabel
                                    anchors.top: multlayerView.bottom
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*activationLabel.height
                                    text: "Normalisation layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: systempalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                    id: normlayerView
                                    anchors.top: normLabel.bottom
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: normlayerModel
                                                      ListElement{
                                                          type: "Drop-out" // @disable-check M16
                                                          group: "norm" // @disable-check M16
                                                          name: "dropout" // @disable-check M16
                                                          colorR: 0 // @disable-check M16
                                                          colorG: 250 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Batch normalisation" // @disable-check M16
                                                          group: "norm" // @disable-check M16
                                                          name: "batchnorm" // @disable-check M16
                                                          colorR: 0 // @disable-check M16
                                                          colorG: 250 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                    }
                                    delegate: buttonComponent
                                }
                                Label {
                                    id: activationLabel
                                    anchors.top: normlayerView.bottom
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*activationLabel.height
                                    text: "Activation layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: systempalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                    id: activationlayerView
                                    anchors.top: activationLabel.bottom
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: activationlayerModel
                                                      ListElement{
                                                          type: "RelU" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "relu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Laeky RelU" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "leakyrelu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "ElU" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "elu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Tanh" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "tanh" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Sigmoid" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "sigmoid" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                    }
                                    delegate: buttonComponent
                                }
                                Label {
                                    id: resizingLabel
                                    anchors.top: activationlayerView.bottom
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*activationLabel.height
                                    text: "Resizing layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: systempalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                    id: resizinglayerView
                                    anchors.top: resizingLabel.bottom
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: resizinglayerModel
                                                      ListElement{
                                                          type: "Catenation" // @disable-check M16
                                                          group: "resizing" // @disable-check M16
                                                          name: "cat" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180// @disable-check M16
                                                          input: 2 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Decatenation" // @disable-check M16
                                                          group: "resizing" // @disable-check M16
                                                          name: "decat" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 2} // @disable-check M16
                                                      ListElement{
                                                          type: "Scaling" // @disable-check M16
                                                          group: "resizing" // @disable-check M16
                                                          name: "scaling" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Resizing" // @disable-check M16
                                                          group: "resizing" // @disable-check M16
                                                          name: "resizing" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                    }
                                    delegate: buttonComponent
                                }
                                Label {
                                    id: otherLabel
                                    anchors.top: resizinglayerView.bottom
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*activationLabel.height
                                    text: "Other layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: systempalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                    id: otherlayerView
                                    anchors.top: otherLabel.bottom
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: otherlayerModel
                                                      ListElement{
                                                          type: "Other" // @disable-check M16
                                                          group: "other" // @disable-check M16
                                                          name: "other" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 250 // @disable-check M16
                                                          colorB: 250 // @disable-check M16
                                                          input: 1 // @disable-check M16
                                                          output: 1} // @disable-check M16
                                                    }
                                    delegate: buttonComponent
                                }
                            }
                        }
                    }
                }
                Item {
                    id: layergroupsItem
                    y: layersLabel.height + layersFrame.height - 2*pix
                    Label {
                        id: layergroupsLabel
                        width: leftFrame.width
                        text: "Layer groups:"
                        font.pointSize: 10
                        padding: 0.2*margin
                        leftPadding: 0.2*margin
                        background: Rectangle {
                            anchors.fill: parent.fill
                            color: defaultcolor
                            border.color: systempalette.dark
                            border.width: 2
                        }
                    }
                    Frame {
                        y: layergroupsLabel.height - 2*pix
                        height: 0.4*(window.height - header.height - 2*layergroupsLabel.height)+4*pix
                        width: leftFrame.width
                        padding: 0
                        backgroundColor: "#FDFDFD"

                        ScrollableItem {
                            clip: true
                            y: 2*pix
                            height: 0.4*(window.height - header.height - 2*layergroupsLabel.height)
                            width: leftFrame.width-2*pix
                            contentHeight: 1.25*buttonHeight*(defaultgroupsView.count)
                                           +0.75*buttonHeight
                            ScrollBar.horizontal.visible: false
                            Item {
                                id: groupsRow
                                Label {
                                    id: defaultLabel
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*defaultLabel.height
                                    text: "Default layer groups"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: systempalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                        id: defaultgroupsView
                                        height: childrenRect.height
                                        anchors.top: defaultLabel.bottom
                                        spacing: 0
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: ListModel {id: deafultmodulesModel
                                                        }
                                        delegate: ButtonNN {
                                            x: +2
                                            width: leftFrame.width-23*pix
                                            height: 1.25*buttonHeight
                                            RowLayout {
                                                anchors.fill: parent.fill
                                                ColorBox {
                                                    Layout.leftMargin: 0.2*margin
                                                    Layout.bottomMargin: 0.03*margin
                                                    Layout.preferredWidth: 0.4*margin
                                                    Layout.preferredHeight: 0.4*margin
                                                    height: 20*margin
                                                    Layout.alignment: Qt.AlignBottom
                                                    colorRGB: [colorR,colorG,colorB]
                                                }
                                                Label {
                                                    topPadding: 0.28*margin
                                                    leftPadding: 0.10*margin
                                                    text: name
                                                    Layout.alignment: Qt.AlignBottom
                                                }
                                            }
                                        }
                                    }
                              }
                        }
                    }
                }

            }
            Frame {
                id: mainFrame
                width : window.width-leftFrame.width-rightFrame.width
                height : window.height - header.height
                padding: 2*pix
                antialiasing: true
                layer.enabled: true
                layer.samples: 8
                ScrollableItem{
                   id: flickableMainPane
                   width : mainFrame.width - 4*pix
                   height : mainFrame.height - 4*pix
                   showBackground: false
                   clip: true
                   Pane {
                        id: mainPane
                        padding: 0
                        backgroundColor: "#FDFDFD"
                        Component.onCompleted: {
                            flickableMainPane.contentWidth = flickableMainPane.width
                            flickableMainPane.contentHeight = flickableMainPane.height
                            mainPane.width = flickableMainPane.width
                            mainPane.height = flickableMainPane.height
                            flickableMainPane.ScrollBar.vertical.visible = false
                            flickableMainPane.ScrollBar.horizontal.visible = false
                        }
                        Item {
                            id: layers
                        }
                        Item {
                            id: connections
                        }
                    }
                }
            }
            Frame {
                id: rightFrame
                height: window.height
                width: 500*pix
                padding:0
                Item {
                    id: propertiesColumn
                    Label {
                        id: propertiesLabel
                        width: rightFrame.width
                        text: "Properties:"
                        font.pointSize: 10
                        padding: 0.2*margin
                        leftPadding: 0.2*margin
                        background: Rectangle {
                            anchors.fill: parent.fill
                            color: defaultcolor
                            border.color: systempalette.dark
                            border.width: 2
                        }
                    }
                    Frame {
                        id: propertiesFrame
                        y: propertiesLabel.height -2*pix
                        height: 0.6*(window.height - header.height - 2*layersLabel.height)
                        width: rightFrame.width
                        padding: 0
                        backgroundColor: systempalette.window
                        ScrollableItem {
                            id: propertiesFlickable
                            y: 2*pix
                            height: 0.6*(window.height - header.height - 2*layersLabel.height) - 4*pix
                            width: rightFrame.width-2*pix
                            contentHeight: 0.6*(window.height - header.height - 2*layersLabel.height) - 4*pix
                            ScrollBar.horizontal.visible: false
                            Item {
                                StackView {
                                    id: propertiesStackView
                                    initialItem: generalpropertiesComponent
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
                            }
                        }
                    }
                }
                Item {
                    id: overviewItem
                    y: propertiesLabel.height + propertiesFrame.height - 2*pix
                    Label {
                        id: overviewLabel
                        width: rightFrame.width
                        text: "Overview:"
                        font.pointSize: 10
                        padding: 0.2*margin
                        leftPadding: 0.2*margin
                        background: Rectangle {
                            anchors.fill: parent.fill
                            color: defaultcolor
                            border.color: systempalette.dark
                            border.width: 2
                        }
                    }
                    Frame {
                        id: overviewFrame
                        y: overviewLabel.height - 2*pix
                        height: 0.4*(window.height - header.height - 2*layersLabel.height) + 4*pix
                        width: rightFrame.width
                        padding: 0
                        backgroundColor: "#FDFDFD"
                        ScrollableItem {
                            id: overviewFlickable
                            y: 2*pix
                            height: 0.4*(window.height - header.height - 2*layersLabel.height)-2*pix
                            width: rightFrame.width-2*pix
                            showBackground: false
                            contentHeight: 0.4*(window.height - header.height - 2*layersLabel.height)-2*pix
                            Item {

                            }
                        }
                    }
                }
            }
        }
    }


//--FUNCTIONS--------------------------------------------------------------------

    function getleft(item) {
        return(item.x)
    }

    function getright(item) {
        return(item.x+item.width)
    }

    function gettop(item) {
        return(item.y)
    }

    function getbottom(item) {
        return(item.y+item.height)
    }

    function getrightchild(item) {
        var max = -10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = getright(item.children[i])
            temp = item.mapToItem(mainPane,temp,0).x
            if (temp>max) {
                max = temp;
            }
        }
        return(max)
    }

    function getleftchild(item) {
        var min = 10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = getleft(item.children[i])
            temp = item.mapToItem(mainPane,temp,0).x
            if (temp<min) {
                min = temp;
            }
        }
        return(min)
    }

    function getbottomchild(item) {
        var max = -10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = getbottom(item.children[i])
            temp = item.mapToItem(mainPane,0,temp).y
            if (temp>max) {
                max = temp;
            }
        }
        return(max)
    }

    function gettopchild(item) {
        var min = 10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = gettop(item.children[i])
            temp = item.mapToItem(mainPane,0,temp).y
            if (temp<min) {
                min = temp;
            }
        }
        return(min)
    }

    function adjustcolor(colorRGB) {

        if (colorRGB[0]===colorRGB[1] && colorRGB[0]===colorRGB[2]) {
            colorRGB[0] = 200 + colorRGB[0]/255*55
            colorRGB[1] = 200 + colorRGB[1]/255*55
            colorRGB[2] = 200 + colorRGB[2]/255*55
        }
        else {
            var max = 255/Math.max(colorRGB[0],colorRGB[1],colorRGB[2])

            for (var i=0;i<=2;i++) {
                if (colorRGB[i]===0) {
                    colorRGB[i] = 245
                }
                else {
                    colorRGB[i] = colorRGB[i] * max
                }
            }
        }
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }

    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }


    function debug(x) {
        console.log(x)
        return(x)
    }

    function comparelocations(item1,mouseX,mouseY,item2,item) {
        var coor1 = item1.mapToItem(item, mouseX, mouseY)
        var coor2 = item2.mapToItem(item, 10*pix, 10*pix)
        if (Math.abs(coor2.x-coor1.x)<30*pix && Math.abs(coor2.y-coor1.y)<30*pix) {
            return(true)
        }
        else {
            return(false)
        }

    }

    function getconnectionsnum() {
        return(connections.children.length)
    }

    function getirregularitiesnum() {
        var out = 0;
        if (layers.children.length>1) {
            for (var i=1;i<layers.children.length;i++) {
                if (layers.children[i].group==="activation") {
                    out = out + 1
                }
            }
        }
        return(out)
    }


//--COMPONENTS--------------------------------------------------------------------

    Component {
        id: layerComponent
        Rectangle {
            id: unit
            height: 1.5*buttonHeight
            width: 0.9*buttonWidth
            radius: 8*pix
            border.color: systempalette.mid
            border.width: 3*pix
            property string name
            property string type
            property string group
            property var labelColor
            property double input
            property double output
            Column {
                anchors.fill: parent.fill
                topPadding: 8*pix
                leftPadding: 14*pix
                spacing: 5*pix
                Label {
                    id: nameLabel
                    text: name
                    font.pointSize: 10
                }
                Label {
                    id: typeLabel
                    text: type
                    color: "#777777"
                }
            }

            MouseArea {
                anchors.fill: parent
                drag.target: parent
                hoverEnabled: true
                onEntered: {
                    unit.border.color = "#666666"
                    for (var i=0;i<upNodes.children.length;i++) {
                        upNodes.children[i].children[0].visible = true
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        downNodes.children[i].children[0].visible = true
                    }
                }
                onExited: {
                    unit.border.color = systempalette.mid
                    for (var i=0;i<upNodes.children.length;i++) {
                        if (upNodes.children[i].children[0].connectedNode===null) {
                            upNodes.children[i].children[0].visible = false
                        }
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        if (downNodes.children[i].children[1].connectedNode===null) {
                            downNodes.children[i].children[0].visible = false
                        }
                    }
                }
                onClicked: {
                    if (type=="Convolution") {
                        propertiesStackView.push(convpropertiesComponent)
                        propertiesStackView.currentItem.labelColor = labelColor
                        propertiesStackView.currentItem.type = type
                    }
                    else if (type=="Transposed convolution") {
                        propertiesStackView.push(tconvpropertiesComponent)
                        propertiesStackView.currentItem.labelColor = labelColor
                        propertiesStackView.currentItem.type = type
                    }
                    else if (type=="Fully connected") {
                        propertiesStackView.push(fconnpropertiesComponent)
                        propertiesStackView.currentItem.labelColor = labelColor
                        propertiesStackView.currentItem.type = type
                    }
                    else {
                        propertiesStackView.push(emptypropertiesComponent)
                        propertiesStackView.currentItem.labelColor = labelColor
                        propertiesStackView.currentItem.type = type
                    }
                }

                onPositionChanged: {
                    if (pressed) {
                        for (var i=0;i<upNodes.children.length;i++) {
                            if (upNodes.children[i].children[0].connectedNode!==null) {
                                var startX = upNodes.children[i].children[0].connectedItem.connection.data[0].startX;
                                var startY = upNodes.children[i].children[0].connectedItem.connection.data[0].startY;
                                upNodes.children[i].children[0].connectedItem.connection.destroy()
                                upNodes.children[i].children[0].connectedItem.connection = shapeComponent.createObject(connections, {
                                      "beginX": startX,
                                      "beginY": startY,
                                      "finishX": unit.x + unit.width*upNodes.children[i].index/(input+1),
                                      "finishY": unit.y + 2*pix,
                                      "origin": upNodes.children[i].children[0].connectedItem});
                                var nodePoint = upNodes.children[i].children[0].
                                mapToItem(upNodes.children[i].children[0].connectedItem.parent,0,0)
                                upNodes.children[i].children[0].connectedItem.x = nodePoint.x - upNodes.children[i].children[0].radius/2
                                upNodes.children[i].children[0].connectedItem.y = nodePoint.y - upNodes.children[i].children[0].radius/2
                            }
                        }
                        for (i=0;i<downNodes.children.length;i++) {
                            for (var j=1;j<downNodes.children[i].children.length;j++) {
                                if (pressed && downNodes.children[i].children[j].connectedNode!==null) {
                                    var finishX = downNodes.children[i].children[j].connection.data[0].pathElements[0].x
                                    var finishY = downNodes.children[i].children[j].connection.data[0].pathElements[0].y
                                    downNodes.children[i].children[j].connection.destroy()
                                    downNodes.children[i].children[j].connection = shapeComponent.createObject(connections, {
                                          "beginX": unit.x + unit.width*downNodes.children[i].index/(output+1),
                                          "beginY": unit.y + unit.height - 2*pix,
                                          "finishX": finishX,
                                          "finishY": finishY,
                                          "origin": downNodes.children[i].children[j]});
                                    nodePoint = downNodes.children[i].children[j].connectedNode.
                                        mapToItem(downNodes.children[i],0,0)
                                    downNodes.children[i].children[j].x = nodePoint.x - downNodes.children[i].children[0].radius/2
                                    downNodes.children[i].children[j].y = nodePoint.y - downNodes.children[i].children[0].radius/2 + 2*pix
                                }
                            }
                        }
                    }
                }
                onReleased: {
                    var paneHeight = mainPane.height
                    var paneWidth = mainPane.width
                    var minheight = -Math.min(0,gettop(unit))
                    var minwidth = -Math.min(0,getleft(unit))
                    var maxheight = Math.max(paneHeight,getbottom(unit))
                    var maxwidth = Math.max(paneWidth,getright(unit))
                    var minheightchildren = -Math.min(gettopchild(layers))
                    var minwidthchildren = -Math.min(getleftchild(layers))
                    var maxheightchildren = Math.max(getbottomchild(layers))
                    var maxwidthchildren = Math.max(getrightchild(layers))

                    if (layers.children.length===1) {
                        if (layers.children[0].x + layers.children[0].width>paneWidth) {
                            layers.children[0].x = paneWidth - layers.children[0].width - 20*pix
                        }
                        if (layers.children[0].y + layers.children[0].height>paneHeight) {
                            layers.children[0].y = paneHeight - layers.children[0].height - 20*pix
                        }
                        return
                    }

                    var adjX = 0
                    var adjY = 0
                    if (minwidth!==0) {
                        adjX = minwidth + 20*pix
                    }
                    else {
                        adjX = minwidthchildren + 20*pix
                    }
                    if (minheight!==0) {
                        adjY = minheight + 20*pix
                    }
                    else {
                        adjY = minheightchildren + 20*pix
                    }
                    if ((adjX===20 && minwidthchildren===0*pix) || (-minwidthchildren+maxwidthchildren)/2<=paneWidth/2) {
                        adjX = 0
                    }
                    if ((adjY===20 && minheightchildren===0*pix) || (-minheightchildren+maxheightchildren)/2<=paneHeight/2) {
                        adjY = 0
                    }

                    if (adjX<0 && (-minwidthchildren+maxwidthchildren)/2>paneWidth/2) {
                        adjX = -((-minwidthchildren+maxwidthchildren)/2-paneWidth/2)
                    }
                    if (adjY<0 && (-minheightchildren+maxheightchildren)/2>paneHeight/2) {
                        adjY = -((-minheightchildren+maxheightchildren)/2-paneHeight/2)
                    }
                    if (adjX!==0 || adjY!==0) {
                        for (var i = 0; i < layers.children.length; i++) {
                            layers.children[i].x = layers.children[i].x + adjX
                            layers.children[i].y = layers.children[i].y + adjY

                        }
                        var num = connections.children.length
                        for (i = 0; i < num; i++) {
                            var object = shapeComponent.createObject(connections, {
                                  "beginX": connections.children[i].beginX + adjX,
                                  "beginY": connections.children[i].beginY + adjY,
                                  "finishX": connections.children[i].finishX + adjX,
                                  "finishY": connections.children[i].finishY + adjY,
                                  "origin": connections.children[i].origin});
                            connections.children[i].origin.connection.destroy()
                            connections.children[i].origin.connection = object
                        }
                    }

                    paneHeight = mainPane.height
                    paneWidth = mainPane.width
                    minheight = -Math.min(0,gettop(unit))
                    minwidth = -Math.min(0,getleft(unit))
                    maxheight = Math.max(paneHeight,getbottom(unit))
                    maxwidth = Math.max(paneWidth,getright(unit))
                    minheightchildren = -Math.min(gettopchild(layers))
                    minwidthchildren = -Math.min(getleftchild(layers))
                    maxheightchildren = Math.max(getbottomchild(layers))
                    maxwidthchildren = Math.max(getrightchild(layers))

                    flickableMainPane.contentHeight = paneHeight
                    flickableMainPane.contentWidth = paneWidth

                    if (maxheight>paneHeight) {
                        mainPane.height = maxheight + 20*pix
                        flickableMainPane.contentHeight = mainPane.height
                        flickableMainPane.contentY = maxheight - flickableMainPane.height + 20*pix
                    }
                    if (maxwidth>paneWidth) {
                        mainPane.width = maxwidth + 20*pix
                        flickableMainPane.contentWidth = mainPane.width
                        flickableMainPane.contentX = maxwidth - flickableMainPane.width + 20*pix
                    }

                    if (flickableMainPane.contentHeight>flickableMainPane.height) {
                        flickableMainPane.ScrollBar.vertical.visible = true
                    }
                    else {
                        flickableMainPane.ScrollBar.vertical.visible = false
                    }
                    if (flickableMainPane.contentWidth>flickableMainPane.width) {
                        flickableMainPane.ScrollBar.horizontal.visible = true
                    }
                    else {
                        flickableMainPane.ScrollBar.horizontal.visible = false
                    }
                }
            }

            Item {
            id: nodes
                Item {
                    id: upNodes
                    Component.onCompleted: {
                        for (var i=0;i<input;i++) {
                            upNodeComponent.createObject(upNodes, {
                                "unit": unit,
                                "upNodes": upNodes,
                                "downNodes": downNodes,
                                "input": input,
                                "index": i+1});
                        }
                    }
                }
                Item {
                    id: downNodes
                    Component.onCompleted: {
                        for (var i=0;i<output;i++) {
                            downNodeComponent.createObject(downNodes, {
                                "unit": unit,
                                "upNodes": upNodes,
                                "downNodes": downNodes,
                                "output": output,
                                "index": i+1});
                        }
                    }
                }
            }
        }
    }

    Component {
        id: downNodeComponent
        Item {
            id: downNodeItem
            property var unit
            property var upNodes
            property var downNodes
            property double output
            property double index
            Rectangle {
                id: downNode
                width: 20*pix
                height: 20*pix
                radius: 20*pix
                border.color: systempalette.mid
                border.width: 3*pix
                visible: false
                x: unit.width*index/(output+1) - downNode.radius/2
                y: unit.height - downNode.radius/2 - 2*pix
            }
            Component.onCompleted: downNodeRectangleComponent.createObject(downNodeItem, {
                "unit": unit,
                "upNodes": upNodes,
                "downNodes": downNodes,
                "downNodeItem": downNodeItem,
                "downNode": downNode,
                "output": output,
                "index": index});
        }
    }

    Component {
        id: downNodeRectangleComponent
        Rectangle {
            id: downNodeRectangle
            property var unit
            property var upNodes
            property var downNodes
            property var downNode
            property var downNodeItem
            property var connectedNode: null
            property var connectedItem: null
            property var connection: null
            property double output
            property double index
            width: 2*downNode.radius
            height: 2*downNode.radius
            //opacity: 0.2
            color: "transparent"
            x: unit.width*index/(output+1) - downNode.radius
            y: unit.height - downNode.radius - 2*pix
            MouseArea {
                id: downnodeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                drag.target: downNodeRectangle
                drag.smoothed: false
                property var mouseAdjust: [0,0]
                onEntered: {
                    for (var i=0;i<upNodes.children.length;i++) {
                        upNodes.children[i].children[0].visible = true
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        downNodes.children[i].children[0].visible = true
                    }
                    downNode.border.color = "#666666"
                }
                onExited: {
                    for (var i=0;i<upNodes.children.length;i++) {
                        if (upNodes.children[i].children[0].connectedNode===null) {
                            upNodes.children[i].children[0].visible = false
                        }
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        if (downNodes.children[i].children[1].connectedNode===null) {
                            downNodes.children[i].children[0].visible = false
                        }
                    }
                    downNode.border.color = systempalette.mid
                }
                onPressed: {
                    mouseAdjust[0] = 0//mouse.x - downNodeRectangle.width/2;
                    mouseAdjust[1] = 0//mouse.y - downNodeRectangle.height/2;
                    for (var i=0;i<layers.children.length;i++) {
                        for (var j=0;j<layers.children[i].children[2].children[0].children.length;j++) {
                            layers.children[i].children[2].children[0].children[j].children[0].visible = true
                        }
                    }
                }
                onPositionChanged: {
                    if (pressed) {
                        if (downNodeRectangle.connection !== null) {
                            downNodeRectangle.connection.destroy()
                        }
                        downNodeRectangle.connection = shapeComponent.createObject(connections, {
                             "beginX": unit.x + unit.width*index/(output+1),
                             "beginY": unit.y + unit.height - 2*pix,
                             "finishX": unit.x + downNodeRectangle.x + downNode.radius +
                                            mouseAdjust[0],
                             "finishY": unit.y + downNodeRectangle.y + downNode.radius +
                                            mouseAdjust[1] + 2*pix,
                             "origin": downNodeRectangle});
                    }
                }
                onReleased: {
                    for (var i=0;i<layers.children.length;i++) {
                        for (var j=0;j<layers.children[i].children[2].children[0].children.length;j++) {
                            if (layers.children[i].children[2].children[0].children[j].children[0].connectedNode===null) {
                                layers.children[i].children[2].children[0].children[j].children[0].visible = false
                            }
                        }
                    }
                    for (i=0;i<layers.children.length;i++) {
                        for (j=0;j<layers.children[i].children[2].children[0].children.length;j++) {
                            if (comparelocations(downNodeRectangle,mouse.x,mouse.y,
                                    layers.children[i].children[2].children[0].children[j].children[0],layers) &&
                                    (layers.children[i].children[2].children[0].children[j].children[0].connectedNode===null ||
                                    (layers.children[i].children[2].children[0].children[j].children[0].connectedNode===downNode &&
                                    layers.children[i].children[2].children[0].children[j].children[0].connectedItem===downNodeRectangle)) &&
                                    layers.children[i].children[2].children[0].children[0]!==
                                    upNodes.children[0]) {
                                debug(layers.children[i].children[2].children[0].children[j].children[0].parent.input)
                                downNodeRectangle.connectedNode = layers.children[i].children[2].children[0].children[j].children[0]
                                layers.children[i].children[2].children[0].children[j].children[0].connectedNode = downNode
                                layers.children[i].children[2].children[0].children[j].children[0].connectedItem = downNodeRectangle
                                layers.children[i].children[2].children[0].children[j].children[0].visible = true
                                var upNodePoint = layers.children[i].children[2].children[0].children[j].children[1].mapToItem(layers,0,0)
                                var downNodePoint = downNodeRectangle.mapToItem(layers,0,0)
                                var adjX = downNodePoint.x - upNodePoint.x
                                var adjY = downNodePoint.y - upNodePoint.y
                                downNodeRectangle.x = downNodeRectangle.x - adjX
                                downNodeRectangle.y = downNodeRectangle.y - adjY
                                downNodeRectangle.connection.destroy()
                                downNodeRectangle.connection = shapeComponent.createObject(connections, {
                                     "beginX": unit.x + unit.width*index/(output+1),
                                     "beginY": unit.y + unit.height - 2*pix,
                                     "finishX": unit.x + downNodeRectangle.x + downNode.radius,
                                     "finishY": unit.y + downNodeRectangle.y + downNode.radius,
                                     "origin": downNodeRectangle});
                                downNodeRectangleComponent.createObject(downNodeItem, {
                                                "unit": unit,
                                                "upNodes": upNodes,
                                                "downNodes": downNodes,
                                                "downNodeItem": downNodeItem,
                                                "downNode": downNode,
                                                "output": output,
                                                "index": index});
                                return
                            }
                        }
                    }
                    downNodeRectangle.connection.destroy()
                    downNode.visible = false
                    if (downNodeItem.children.length>2) {
                        for (i=downNodeItem.children.length-1;i>=2;i--) {
                            if (downNodeItem.children[i-1].connectedNode===null) {
                                downNodeItem.children[i].destroy()
                            }
                        }
                    }
                    if (downNodeItem.children[1].connectedNode!==null) {
                        downNode.visible = true
                    }
                    if (downNodeRectangle.connectedNode===null) {
                        downNodeRectangle.x = unit.width*index/(output+1) - downNode.radius
                        downNodeRectangle.y = unit.height - downNode.radius - 2*pix
                    }
                }
            }
        }
    }

    Component {
        id: upNodeComponent
        Item {
            id: upNodeItem
            property var unit
            property var upNodes
            property var downNodes
            property double input
            property double index
            Rectangle {
                id: upNode
                width: 20*pix
                height: 20*pix
                radius: 20*pix
                border.color: systempalette.mid
                border.width: 3*pix
                visible: false
                property var connectedNode: null
                property var connectedItem: null
                x: unit.width*index/(input+1)-upNode.radius/2
                y: -upNode.radius/2 + 2*pix
            }
            Rectangle {
                id: upNodeRectangle
                width: 2*upNode.radius
                height: 2*upNode.radius
                //opacity: 0.2
                color: "transparent"
                border.width: 0
                x: unit.width*index/(input+1)-upNode.radius
                y: -upNode.radius + 2*pix
                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    hoverEnabled: true
                    property var mouseAdjust: [0,0]
                    onEntered: {
                        for (var i=0;i<upNodes.children.length;i++) {
                            upNodes.children[i].children[0].visible = true
                        }
                        for (i=0;i<downNodes.children.length;i++) {
                            downNodes.children[i].children[0].visible = true
                        }
                        upNode.border.color = "#666666"
                    }
                    onExited: {
                        for (var i=0;i<upNodes.children.length;i++) {
                            if (upNodes.children[i].children[0].connectedNode===null) {
                                upNodes.children[i].children[0].visible = false
                            }
                        }
                        for (i=0;i<downNodes.children.length;i++) {
                            if (downNodes.children[i].children[1].connectedNode===null) {
                                downNodes.children[i].children[0].visible = false
                            }
                        }
                        upNode.border.color = systempalette.mid
                    }
                    onPressed: {
                        if (upNode.connectedNode==null) {
                            return
                        }
                        mouseAdjust[0] = 0//mouse.x - upNode.connectedItem.width/2;
                        mouseAdjust[1] = 0//mouse.y - upNode.connectedItem.height/2;
                        for (var i=0;i<layers.children.length;i++) {
                            for (var j=0;j<layers.children[i].children[2].children[0].children.length;j++) {
                                layers.children[i].children[2].children[0].children[j].children[0].visible = true
                            }
                        }
                    }
                    onPositionChanged: {
                        if (upNode.connectedNode==null) {
                            return
                        }
                        if (pressed) {
                            if (upNode.connectedItem.connection !== null) {
                                upNode.connectedItem.connection.destroy()
                            }
                            var point = upNodeRectangle.mapToItem(layers,0,0)
                            upNode.connectedItem.connection = shapeComponent.createObject(connections, {
                                 "beginX": upNode.connectedItem.unit.x + upNode.connectedItem.unit.width*
                                                upNode.connectedItem.index/(upNode.connectedItem.output+1),
                                 "beginY": upNode.connectedItem.unit.y + upNode.connectedItem.unit.height - 2*pix,
                                 "finishX": point.x +
                                            upNode.connectedNode.radius + mouseAdjust[0],
                                 "finishY": point.y +
                                            upNode.connectedNode.radius + mouseAdjust[1] + 2*pix,
                                 "origin": upNode.connectedItem})
                        }
                    }
                    onReleased: {
                        if (upNode.connectedNode==null) {
                            upNodeRectangle.x = unit.width*index/(input+1)-upNode.radius
                            upNodeRectangle.y = -upNode.radius + 2*pix
                            return
                        }
                        for (var i=0;i<layers.children.length;i++) {
                            for (var j=0;j<layers.children[i].children[2].children[0].children.length;j++) {
                                if (layers.children[i].children[2].children[0].children[j].children[0].connectedNode===null) {
                                    layers.children[i].children[2].children[0].children[j].children[0].visible = false
                                }
                            }
                        }
                        for (i=0;i<layers.children.length;i++) {
                            for (j=0;j<layers.children[i].children[2].children[0].children.length;j++) {
                                if (comparelocations(upNodeRectangle,mouse.x,mouse.y,
                                        layers.children[i].children[2].children[0].children[j].children[0],layers) &&
                                        (layers.children[i].children[2].children[0].children[j].children[0].connectedNode===null ||
                                        layers.children[i].children[2].children[0].children[j].children[0].connectedNode===upNode.connectedNode) &&
                                        layers.children[i].children[2].children[0].children[j].children[1]!==
                                        upNode.connectedNode.parent.parent.parent.children[j].children[1]) {
                                    upNode.connectedItem.connectedNode = layers.children[i].children[2].children[0].children[j].children[0]
                                    layers.children[i].children[2].children[0].children[j].children[0].connectedNode = upNode.connectedNode
                                    layers.children[i].children[2].children[0].children[j].children[0].connectedItem = upNode.connectedItem
                                    layers.children[i].children[2].children[0].children[j].children[0].visible = true
                                    var upNodePoint = layers.children[i].children[2].children[0].children[j].children[1].mapToItem(layers,0,0)
                                    var downNodePoint = upNode.connectedItem.mapToItem(layers,0,0)
                                    var adjX = downNodePoint.x - upNodePoint.x
                                    var adjY = downNodePoint.y - upNodePoint.y
                                    upNodeRectangle.x = unit.width*index/(output+1)-upNode.radius
                                    upNodeRectangle.y = -upNode.radius + 2*pix
                                    upNode.connectedItem.x = upNode.connectedItem.x - adjX
                                    upNode.connectedItem.y = upNode.connectedItem.y - adjY
                                    upNode.connectedItem.connection.destroy()
                                    var point = layers.children[i].children[2].children[0].children[j].children[1].mapToItem(layers,0,0)
                                    upNode.connectedItem.connection = shapeComponent.createObject(connections, {
                                          "beginX": upNode.connectedItem.unit.x + upNode.connectedItem.unit.width*
                                                        upNode.connectedItem.index/(upNode.connectedItem.output+1),
                                          "beginY": upNode.connectedItem.unit.y + upNode.connectedItem.unit.height - 2*pix,
                                          "finishX": point.x +
                                                     upNode.connectedNode.radius + mouseAdjust[0],
                                          "finishY": point.y +
                                                     upNode.connectedNode.radius + mouseAdjust[1] + 2*pix,
                                          "origin": upNode.connectedItem})
                                    if (upNode!==layers.children[i].children[2].children[0].children[j].children[0]) {
                                        upNode.connectedNode = null
                                        upNode.connectedItem = null
                                    }
                                    return
                                }
                            }
                        }
                        upNode.connectedItem.connection.destroy()
                        upNode.connectedItem.connectedNode = null
                        upNode.connectedItem.destroy()

                        upNode.connectedNode.visible = false
                        upNode.connectedNode = null
                        upNodeRectangle.x = unit.width*index/(input+1)-upNode.radius
                        upNodeRectangle.y = -upNode.radius + 2*pix
                        for (i=0;i<layers.children.length;i++) {
                            for (j=0;j<layers.children[i].children[2].children[0].children.length;j++) {
                                if (layers.children[i].children[2].children[0].children[j].children[0].connectedNode===null) {
                                    layers.children[i].children[2].children[0].children[j].children[0].visible = false
                                }
                            }
                        }
                        for (i=0;i<downNodes.children.length;i++) {
                            downNodes.children[i].children[0].visible = false
                        }
                    }
                }
            }

        }
    }

    Component {
        id: shapeComponent

        Shape {
            id: pathShape
            property double beginX: 0
            property double beginY: 0
            property double finishX: 0
            property double finishY: 0
            property var origin: null
            antialiasing: true
            vendorExtensionsEnabled: false
            ShapePath {
                id: pathShapePath
                strokeColor: "#666666"
                strokeWidth: 4*pix
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                property int joinStyleIndex: 0

                property variant styles: [
                    ShapePath.BevelJoin,
                    ShapePath.MiterJoin,
                    ShapePath.RoundJoin
                ]

                joinStyle: styles[joinStyleIndex]

                startX: beginX
                startY: beginY
                PathLine {
                    x: finishX
                    y: finishY
                }
            }
        }
    }

    Component {
        id: buttonComponent
        ButtonNN {
            x: +2
            width: leftFrame.width-23*pix
            height: 1.25*buttonHeight
            onPressed: {
                var object = layerComponent.createObject(layers,{"color" : adjustcolor([colorR,colorG,colorB]),
                                           "name": name,
                                           "group": group,
                                           "type": type,
                                           "labelColor": [colorR,colorG,colorB],
                                           "input": input,
                                           "output": output,
                                           "x": 20*pix,
                                           "y": 20*pix});
            }
            RowLayout {
                anchors.fill: parent.fill
                ColorBox {
                    Layout.leftMargin: 0.2*margin
                    Layout.bottomMargin: 0.03*margin
                    Layout.preferredWidth: 0.4*margin
                    Layout.preferredHeight: 0.4*margin
                    height: 20*margin
                    Layout.alignment: Qt.AlignBottom
                    colorRGB: [colorR,colorG,colorB]
                }
                Label {
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    Layout.alignment: Qt.AlignBottom
                }
            }
        }
    }

//--Properties components
    Component {
        id: generalpropertiesComponent
        RowLayout {
            ColumnLayout {
                Layout.leftMargin: 0.2*margin
                Layout.topMargin: 0.2*margin
                spacing: 0.2*margin
                Label {
                    text: "Number of layers: "
                }
                Label {
                    text: "Number of connections: "
                }
                Label {
                    text: "Number of irregularities: "
                }
            }
            ColumnLayout {
                Layout.leftMargin: 0.2*margin
                Layout.topMargin: 0.2*margin
                spacing: 0.2*margin
                Label {
                    text: mainPane.children.length - 1
                }
                Label {
                    text: getconnectionsnum()
                }
                Label {
                    text: getirregularitiesnum()
                }
            }
        }
    }

    Component {
        id: convpropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Filters","Filter size",
                            "Stride","Dilation factor"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{1,5}/ }
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}/ }
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}/ }
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}/ }
                    }
                }
        }

        }
    }

    Component {
        id: tconvpropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                    //Layout.alignment: Qt.AlignBottom
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Filters","Filter size",
                            "Stride"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{1,5}/ }
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}/ }
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}/ }
                    }
                }
        }

        }
    }

    Component {
        id: fconnpropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                    //Layout.alignment: Qt.AlignBottom
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Neurons"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{1,5}/ }
                    }
                }
        }

        }
    }

    Component {
        id: catpropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Inputs"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1}/ }
                    }
                }
        }

        }
    }

    Component {
        id: decatpropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Outputs"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1}/ }
                    }
                }
        }

        }
    }

    Component {
        id: scalingpropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Multiplier"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /([1-9]\d{0,1}) | (0,\d{1-2})/ }
                    }
                }
        }

        }
    }

    Component {
        id: resizingpropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","New size"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{1,3},[1-9]\d{1,3},[1-9]\d{1,3}/ }
                    }
                }
            }

        }
    }


    Component {
        id: emptypropertiesComponent
        Column {
            property string type
            property var labelColor
            Row {
                leftPadding: 20*pix
                ColorBox {
                    topPadding: 0.37*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: labelColor
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pointSize: 10
                    color: "#777777"
                    wrapMode: Text.NoWrap
                    //Layout.alignment: Qt.AlignBottom
                }
            }
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name"]
                        Label {
                            text: modelData+": "
                            topPadding: 4*pix
                            bottomPadding: topPadding
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 0.2*margin
                    TextField {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: 600*pix
                    }
                }
            }
        }
    }
}
