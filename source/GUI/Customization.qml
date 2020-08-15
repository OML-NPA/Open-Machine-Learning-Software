
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
    minimumWidth: buttonWidth*5
    minimumHeight: buttonHeight*20
    //maximumWidth: gridLayout.width
    //maximumHeight: gridLayout.height

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }
    color: systempalette.window

    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double pix: Screen.width/3840
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
                Column {
                    id: layersColumn
                    Label {
                        id: layersLabel
                        width: leftFrame.width
                        text: "Layers:"
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
                        height: 0.6*(window.height - header.height - 2*layersLabel.height)
                        width: leftFrame.width
                        padding: 0
                        backgroundColor: "#FDFDFD"
                        ScrollableItem {
                            id: layersFlickable
                            height: 0.6*(window.height - header.height - 2*layersLabel.height)-2*pix
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
                                                              name: "conv"// @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0} // @disable-check M16
                                                          ListElement{
                                                              type: "Transposed convolution" // @disable-check M16
                                                              name: "tconv" // @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0} // @disable-check M16
                                                          ListElement{
                                                              type: "Fully connected" // @disable-check M16
                                                              name: "fullycon" // @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0} // @disable-check M16
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
                                                          name: "fullycon" // @disable-check M16
                                                          colorR: 0 // @disable-check M16
                                                          colorG: 250 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
                                                      ListElement{
                                                          type: "Batch normalisation" // @disable-check M16
                                                          colorR: 0 // @disable-check M16
                                                          colorG: 250 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
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
                                                          name: "relu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
                                                      ListElement{
                                                          type: "Laeky RelU" // @disable-check M16
                                                          name: "relu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
                                                      ListElement{
                                                          type: "ElU" // @disable-check M16
                                                          name: "elu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
                                                      ListElement{
                                                          type: "Tanh" // @disable-check M16
                                                          name: "tanh" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
                                                      ListElement{
                                                          type: "Sigmoid" // @disable-check M16
                                                          name: "sigmoid" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0} // @disable-check M16
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
                                                          name: "cat" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180} // @disable-check M16
                                                      ListElement{
                                                          type: "Decatenation" // @disable-check M16
                                                          name: "decat" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180} // @disable-check M16
                                                      ListElement{
                                                          type: "Scaling" // @disable-check M16
                                                          name: "scaling" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180} // @disable-check M16
                                                      ListElement{
                                                          type: "Resizing" // @disable-check M16
                                                          name: "resizing" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180} // @disable-check M16
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
                                                          type: "Something" // @disable-check M16
                                                          name: "something" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 250 // @disable-check M16
                                                          colorB: 250} // @disable-check M16
                                                    }
                                    delegate: buttonComponent
                                }
                            }
                        }
                    }
                }
                Column {
                    anchors.top: layersColumn.bottom
                    Label {
                        id: layergroupsLabel
                        width: leftFrame.width
                        text: "Layer groups:"
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
                        height: 0.4*(window.height - header.height - 2*layergroupsLabel.height)-0*pix
                        width: leftFrame.width
                        padding: 0
                        backgroundColor: "#FDFDFD"

                        ScrollableItem {
                            clip: true
                            height: 0.4*(window.height - header.height - 2*layergroupsLabel.height)-2*pix
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
                                                          ListElement{
                                                              name: "Group 1" // @disable-check M16
                                                              colorR: 0 // @disable-check M16
                                                              colorG: 0 // @disable-check M16
                                                              colorB: 0} // @disable-check M16
                                                          ListElement{
                                                              name: "Group 2" // @disable-check M16
                                                              colorR: 0 // @disable-check M16
                                                              colorG: 0 // @disable-check M16
                                                              colorB: 0} // @disable-check M16
                                                          ListElement{
                                                              name: "Group 3" // @disable-check M16
                                                              colorR: 0 // @disable-check M16
                                                              colorG: 0 // @disable-check M16
                                                              colorB: 0} // @disable-check M16
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
                width : window.width-leftFrame.width-rightFrame.width
                height : paneHeight+4*pix
                padding: 2*pix
                ScrollableItem{
                   id: flickableMainPane
                   width : paneWidth
                   height : paneHeight
                   showBackground: false
                   clip: true
                   Pane {
                        id: mainPane
                        padding: 0
                        backgroundColor: "#FDFDFD"
                        Component.onCompleted: {
                            flickableMainPane.contentWidth = Math.max(paneWidth)
                            flickableMainPane.contentHeight = Math.max(paneHeight)
                            mainPane.width = window.width/2
                            mainPane.height = paneHeight
                            flickableMainPane.ScrollBar.vertical.visible = false
                            flickableMainPane.ScrollBar.horizontal.visible = false
                        }
                    }
                }
            }
            Frame {
                id: rightFrame
                height: window.height
                width: 500*pix
                padding:0
                Column {
                    id: propertiesColumn
                    Label {
                        id: propertiesLabel
                        width: rightFrame.width
                        text: "Properties:"
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
                        height: 0.6*(window.height - header.height - 2*layersLabel.height)
                        width: rightFrame.width
                        padding: 0
                        backgroundColor: "#FDFDFD"
                        ScrollableItem {
                            id: propertiesFlickable
                            height: 0.6*(window.height - header.height - 2*layersLabel.height)-2*pix
                            width: rightFrame.width-2*pix
                            contentHeight: 0.6*(window.height - header.height - 2*layersLabel.height)-2*pix
                            ScrollBar.horizontal.visible: false
                            Item {

                            }
                        }
                    }
                }
                Column {
                    anchors.top: propertiesColumn.bottom
                    Label {
                        id: overviewLabel
                        width: rightFrame.width
                        text: "Overview:"
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
                        height: 0.4*(window.height - header.height - 2*layersLabel.height)
                        width: rightFrame.width
                        padding: 0
                        backgroundColor: "#FDFDFD"
                        ScrollableItem {
                            id: overviewFlickable
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
        var max = 0;
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 1; i < item.children.length; i++) {
            var temp = getright(item.children[i])
            if (temp>max) {
                max = temp;
            }
        }
        return(max)
    }

    function getleftchild(item) {
        var min = 0;
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 1; i < item.children.length; i++) {
            var temp = getleft(item.children[i])
            if (temp<min) {
                min = temp;
            }
        }
        return(min)
    }

    function getbottomchild(item) {
        var max = 0;
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 1; i < item.children.length; i++) {
            var temp = getbottom(item.children[i])
            if (temp>max) {
                max = temp;
            }
        }
        return(max)
    }

    function gettopchild(item) {
        var min = 0;
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 1; i < item.children.length; i++) {
            var temp = gettop(item.children[i])
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

//--COMPONENTS--------------------------------------------------------------------

    Component {
        id: moduleNN


        Rectangle {
            id: unit
            height: 1.5*buttonHeight
            width: 0.9*buttonWidth
            radius: 8*pix
            border.color: systempalette.mid
            border.width: 3*pix
            property string name: "test"
            property string type: "test"
            color: "#000000"
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
                    upNode.visible = true
                    downNode.visible = true
                }
                onExited: {
                    unit.border.color = systempalette.mid
                    upNode.visible = false
                    downNode.visible = false
                }
                onReleased: {

                    var windowHeight = window.height-buttonHeight

                    var minheight = -Math.min(0,gettop(unit))
                    var minwidth = -Math.min(0,getleft(unit))
                    var maxheight = Math.max(windowHeight,getbottom(unit))
                    var maxwidth = Math.max(window.width/2,getright(unit))
                    var minheightchildren = -Math.min(0,gettopchild(mainPane))
                    var minwidthchildren = -Math.min(0,getleftchild(mainPane))
                    var maxheightchildren = Math.max(0,getbottomchild(mainPane))
                    var maxwidthchildren = Math.max(0,getrightchild(mainPane))
                    var paneHeight = mainPane.height
                    var paneWidth = mainPane.width
                    var changeHeight = (maxheight-mainPane.height)
                    var changeWidth = (maxwidth-mainPane.width)

                    mainPane.height = Math.max(flickableMainPane.height,maxheightchildren + minheightchildren)
                    mainPane.width = Math.max(flickableMainPane.width,maxwidthchildren + minwidthchildren)

                    var i
                    if (minheight!==0) {
                        for (i = 1; i < mainPane.children.length; i++) {
                            mainPane.children[i].y = mainPane.children[i].y+minheight
                        }
                    }
                    if (maxheight>paneHeight || maxheight!==(windowHeight+flickableMainPane.contentY)) {
                        flickableMainPane.contentY = (maxheight-(windowHeight))
                    }
                    if (minwidth!==0) {
                        for (i = 1; i < mainPane.children.length; i++) {
                            mainPane.children[i].x = mainPane.children[i].x+minwidth
                        }
                    }
                    if (maxwidth>paneWidth || maxwidth!==(window.width/2+flickableMainPane.contentX)) {
                        flickableMainPane.contentX = (maxwidth-(window.width/2))
                    }

                    flickableMainPane.contentHeight = maxheightchildren + minheightchildren
                    flickableMainPane.contentWidth = maxwidthchildren + minwidthchildren

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
                    /*console.log(["maxwidth: "+maxwidth,"minwidth: "+minwidth,
                                 "panewidth: "+mainPane.width,"X:",flickableMainPane.contentX,
                                 "minwidthchildren:", minwidthchildren,
                                 "maxwidthchildren:", maxwidthchildren,
                                 "changeHeight: ",changeHeight,
                                 "contentWidth:",flickableMainPane.contentWidth,
                                 "mainpaneWidth: ",flickableMainPane.width])*/
                }
            }

            Rectangle {
                id: upNode
                width: buttonHeight/3
                height: buttonHeight/3
                radius: buttonHeight/3
                border.color: systempalette.mid
                border.width: 3*pix
                visible: false
                x: unit.width/2-upNode.radius/2
                y: -upNode.radius/2 + 2*pix
            }
            Rectangle {
                width: 2*buttonHeight/3
                height: 2*buttonHeight/3
                color: "transparent"
                border.color: "transparent"
                border.width: 0
                x: unit.width/2-upNode.radius
                y: -upNode.radius + 1.5*pix
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        upNode.visible = true
                        downNode.visible = true
                        upNode.border.color = "#666666"
                    }
                    onExited: {
                        upNode.visible = false
                        downNode.visible = false
                        upNode.border.color = systempalette.mid
                    }
                }
            }

            Rectangle {
                id: downNode
                width: buttonHeight/3
                height: buttonHeight/3
                radius: buttonHeight/3
                border.color: systempalette.mid
                border.width: 3*pix
                visible: false
                x: unit.width/2 - downNode.radius/2
                y: unit.height - downNode.radius/2 - 2*pix
            }
            Rectangle {
                width: 2*buttonHeight/3
                height: 2*buttonHeight/3
                color: "transparent"
                border.color: "transparent"
                border.width: 0
                x: unit.width/2-downNode.radius/2
                y: 0.88*unit.height+downNode.radius/2
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        upNode.visible = true
                        downNode.visible = true
                        downNode.border.color = "#666666"
                    }
                    onExited: {
                        upNode.visible = false
                        downNode.visible = false
                        downNode.border.color = systempalette.mid
                    }
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
            onClicked: {
                moduleNN.createObject(mainPane,{"color" : adjustcolor([colorR,colorG,colorB]),
                                               "name" : name,
                                               "type" : type});
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

//--Layers






}
