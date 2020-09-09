
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import QtQuick.Shapes 1.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
import org.julialang 1.0

ApplicationWindow {
    id: window
    visible: true
    title: qsTr("Image Analysis Software")
    minimumWidth: 2200*pix
    minimumHeight: 1500*pix

    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double pix: Screen.width/3840
    property double buttonWidth: 380*pix
    property double buttonHeight: 65*pix

    property double defaultWidth: buttonWidth*5/2
    property double defaultHeight: buttonHeight*20

    property double paneHeight: window.height - header.height - 4*pix
    property double paneWidth: window.width-leftFrame.width-rightFrame.width-4*pix

    property bool optionsOpen: false
    property bool localtrainingOpen: false

    property var currentFocus: null

    property var architecture


    onClosing: { customizationLoader.sourceComponent = undefined }

    header: Pane {
        id: header
        height: 50*pix
        padding: 0
        Row {
            Button {
                text: "Save"
                padding: 0
                backgroundRadius: 0
                width: (header.width)/15
                height: header.height + 1
                onClicked: {
                   getarchitecture()
                   gridLayout.forceActiveFocus()
                }
            }
            Button {
                text: "Arrange"
                padding: 0
                backgroundRadius: 0
                width: (header.width)/15
                height: header.height + 1
                onClicked: {
                    if (layers.children.length===0) {
                        return
                    }
                    function getpositions() {
                        var x = []
                        var y = []
                        for (var i=0;i<layers.children.length;i++) {
                            x[i] = layers.children[i].x - width/2
                            y[i] = layers.children[i].y - height/2
                        }
                        return({"x": x,"y": y})
                    }
                    var height = layers.children[0].height
                    var width = layers.children[0].width
                    var marginy = 40*pix + height
                    var marginx = 40*pix + 1.5*width
                    // Arrange into y groups
                    var skipinds = []
                    var positions_orig = getpositions()
                    for(var k=0;k<layers.children.length-1;k++) {
                        var positions = getpositions()
                        for (var i=0;i<skipinds.length;i++) {
                            positions.y[skipinds[i]] = Infinity
                        }
                        var minind = indexofmin(positions.y)
                        var minval = Math.min(...positions.y)
                        var dist = dif(positions.y,minval)
                        for (i=0;i<dist.length;i++) {
                            if ( i===minind || skipinds.includes(i)) {
                                continue
                            }
                            if (dist[i]>0) {
                                if (dist[i]<marginy) {
                                    if (Math.abs(positions_orig.y[minind]-positions_orig.y[i])>height) {
                                        layers.children[i].y = layers.children[i].y + (marginy - dist[i])
                                    }
                                    else {
                                        layers.children[i].y = layers.children[minind].y
                                    }
                                }
                            }
                        }
                        skipinds.push(minind)
                    }
                    // Arrange x margins for y groups
                    skipinds = []
                    positions_orig = getpositions()
                    for(k=0;k<layers.children.length-1;k++) {
                        positions = getpositions()
                        for (i=0;i<skipinds.length;i++) {
                            positions.x[skipinds[i]] = Infinity
                        }
                        minind = indexofmin(positions.x)
                        minval = Math.min(...positions.x)
                        dist = dif(positions.x,minval)

                        for (i=0;i<dist.length;i++) {
                            if ( i===minind || skipinds.includes(i)) {
                                continue
                            }
                            if (dist[i]>=0 && positions.y[minind]===positions.y[i]) {
                                layers.children[i].x = minval + marginx
                            }
                        }
                        skipinds.push(minind)
                    }
                    var unique_y = getpositions().y.filter((x,i,a)=>a.indexOf(x)===i)
                    positions = getpositions()
                    var ind = indexOfMin(positions.y)
                    var min_x = positions.x[ind]
                    var buffer = 0
                    unique_y = unique_y.sort((a,b)=>a-b)
                    for (i=0;i<(unique_y.length-1);i++) {
                        var value = unique_y[i+1]-unique_y[i]
                        positions = getpositions()
                        var inds = findindex(positions.y,unique_y[i+1])
                        var array = []
                        for (var j=0;j<inds.length;j++) {
                            array.push(layers.children[inds[j]].x)
                        }
                        var dev = mean(array) - min_x
                        for (j=0;j<inds.length;j++) {
                            layers.children[inds[j]].x = layers.children[inds[j]].x - dev + width/2
                        }
                        if (value!==marginy){
                            buffer = buffer + (marginy - value)
                            for (j=0;j<inds.length;j++) {
                                layers.children[inds[j]].y = layers.children[inds[j]].y + buffer
                            }
                        }
                    }
                    updateMainPane(layers.children[0])
                    updateConnections()
                    gridLayout.forceActiveFocus()
                }
            }
        }
        Rectangle {
            width: header.width
            height: 2*pix
            border.width: 0
            y: header.height - 1
            color: defaultpalette.border
        }
    }
    GridLayout {
        id: gridLayout
        focus: true
        Keys.onPressed: {
            if (event.key===Qt.Key_Backspace || event.key===Qt.Key_Delete) {

                var upNodes = currentFocus.children[2].children[0]
                var downNodes = currentFocus.children[2].children[1]
                for (var i=0;i<upNodes.children.length;i++) {
                    if (upNodes.children[i].children[0].connectedNode!==null) {
                        upNodes.children[i].children[0].connectedItem.connectedNode = null
                        upNodes.children[i].children[0].connectedItem.connection.destroy()
                        connections.num = connections.num - 1
                    }
                }
                for (i=0;i<downNodes.children.length;i++) {
                    for (var j=1;j<downNodes.children[i].children.length;j++) {
                        if (downNodes.children[i].children[j].connectedNode!==null) {
                            downNodes.children[i].children[j].connectedNode.connectedNode = null
                            downNodes.children[i].children[j].connectedNode.connectedItem = null
                            downNodes.children[i].children[j].connection.destroy()
                            connections.num = connections.num - 1
                        }
                    }
                }
                currentFocus.destroy()
                currentFocus = null
                updateOverview()
                propertiesStackView.push(generalpropertiesComponent)
            }
        }
        Row {
            spacing: 0
            Frame {
                id: leftFrame
                height: window.height - header.height + 1
                width: 500*pix + 1
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
                            color: "transparent"
                            border.color: defaultpalette.border
                            border.width: 2*pix
                        }
                    }
                    Frame {
                        id: layersFrame
                        y: layersLabel.height -2*pix
                        height: 0.6*(window.height - header.height - 2*layersLabel.height)
                        width: leftFrame.width
                        padding: 0
                        backgroundColor: defaultpalette.listview
                        ScrollableItem {
                            y: 2*pix
                            id: layersFlickable
                            height: 0.6*(window.height - header.height - 2*layersLabel.height)-4*pix
                            width: leftFrame.width-2*pix
                            contentHeight: 1.25*buttonHeight*(inoutlayerView.count + linearlayerView.count +
                                normlayerView.count + activationlayerView.count + poolinglayerView.count +
                                resizinglayerView.count + otherlayerView.count) + 7*0.75*buttonHeight
                            ScrollBar.horizontal.visible: false
                            Item {
                                id: layersRow
                                Label {
                                    id: inoutLabel
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*linearLabel.height
                                    text: "Input and output layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: defaultpalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                        id: inoutlayerView
                                        height: childrenRect.height
                                        anchors.top: inoutLabel.bottom
                                        spacing: 0
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: ListModel {id: inoutlayerModel
                                                          ListElement{
                                                              type: "Input" // @disable-check M16
                                                              group: "inout" // @disable-check M16
                                                              name: "input"// @disable-check M16
                                                              colorR: 0 // @disable-check M16
                                                              colorG: 0 // @disable-check M16
                                                              colorB: 250 // @disable-check M16
                                                              inputnum: 0 // @disable-check M16
                                                              outputnum: 1} // @disable-check M16
                                                          ListElement{
                                                              type: "Output" // @disable-check M16
                                                              group: "inout" // @disable-check M16
                                                              name: "outputnum" // @disable-check M16
                                                              colorR: 0 // @disable-check M16
                                                              colorG: 0 // @disable-check M16
                                                              colorB: 250 // @disable-check M16
                                                              inputnum: 1 // @disable-check M16
                                                              outputnum: 0} // @disable-check M16
                                                        }
                                        delegate: buttonComponent
                                    }
                                Label {
                                    id: linearLabel
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    anchors.top: inoutlayerView.bottom
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*linearLabel.height
                                    text: "Linear layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: defaultpalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                        id: linearlayerView
                                        height: childrenRect.height
                                        anchors.top: linearLabel.bottom
                                        spacing: 0
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: ListModel {id: linearlayerModel
                                                          ListElement{
                                                              type: "Convolution" // @disable-check M16
                                                              group: "linear" // @disable-check M16
                                                              name: "conv"// @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0 // @disable-check M16
                                                              inputnum: 1 // @disable-check M16
                                                              outputnum: 1} // @disable-check M16
                                                          ListElement{
                                                              type: "Transposed convolution" // @disable-check M16
                                                              group: "linear" // @disable-check M16
                                                              name: "tconv" // @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0 // @disable-check M16
                                                              inputnum: 1 // @disable-check M16
                                                              outputnum: 1} // @disable-check M16
                                                          ListElement{
                                                              type: "Dense" // @disable-check M16
                                                              group: "linear" // @disable-check M16
                                                              name: "dense" // @disable-check M16
                                                              colorR: 250 // @disable-check M16
                                                              colorG: 250 // @disable-check M16
                                                              colorB: 0 // @disable-check M16
                                                              inputnum: 1 // @disable-check M16
                                                              outputnum: 1} // @disable-check M16
                                                        }
                                        delegate: buttonComponent
                                    }
                                Label {
                                    id: normLabel
                                    anchors.top: linearlayerView.bottom
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
                                        color: defaultpalette.window
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
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Batch normalisation" // @disable-check M16
                                                          group: "norm" // @disable-check M16
                                                          name: "batchnorm" // @disable-check M16
                                                          colorR: 0 // @disable-check M16
                                                          colorG: 250 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
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
                                        color: defaultpalette.window
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
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Laeky RelU" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "leakyrelu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "ElU" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "elu" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Tanh" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "tanh" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Sigmoid" // @disable-check M16
                                                          group: "activation" // @disable-check M16
                                                          name: "sigmoid" // @disable-check M16
                                                          colorR: 250 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 0 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                    }
                                    delegate: buttonComponent
                                }
                                Label {
                                    id: poolingLabel
                                    anchors.top: activationlayerView.bottom
                                    width: leftFrame.width-4*pix
                                    height: 0.75*buttonHeight
                                    font.pointSize: 10
                                    color: "#777777"
                                    topPadding: 0.10*poolingLabel.height
                                    text: "Pooling layers"
                                    leftPadding: 0.25*margin
                                    background: Rectangle {
                                        anchors.fill: parent.fill
                                        x: 2*pix
                                        color: defaultpalette.window
                                        width: leftFrame.width-4*pix
                                        height: 0.75*buttonHeight
                                    }
                                }
                                ListView {
                                    id: poolinglayerView
                                    anchors.top: poolingLabel.bottom
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: poolinglayerModel
                                                      ListElement{
                                                          type: "Max pooling" // @disable-check M16
                                                          group: "pooling" // @disable-check M16
                                                          name: "maxpool" // @disable-check M16
                                                          colorR: 150 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 255 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Average pooling" // @disable-check M16
                                                          group: "pooling" // @disable-check M16
                                                          name: "avgpool" // @disable-check M16
                                                          colorR: 150 // @disable-check M16
                                                          colorG: 0 // @disable-check M16
                                                          colorB: 255 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                    }
                                    delegate: buttonComponent
                                }

                                Label {
                                    id: resizingLabel
                                    anchors.top: poolinglayerView.bottom
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
                                        color: defaultpalette.window
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
                                                          inputnum: 2 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Decatenation" // @disable-check M16
                                                          group: "resizing" // @disable-check M16
                                                          name: "decat" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 2} // @disable-check M16
                                                      ListElement{
                                                          type: "Scaling" // @disable-check M16
                                                          group: "resizing" // @disable-check M16
                                                          name: "scaling" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
                                                      ListElement{
                                                          type: "Resizing" // @disable-check M16
                                                          group: "resizing" // @disable-check M16
                                                          name: "resizing" // @disable-check M16
                                                          colorR: 180 // @disable-check M16
                                                          colorG: 180 // @disable-check M16
                                                          colorB: 180 // @disable-check M16
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
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
                                        color: defaultpalette.window
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
                                                          inputnum: 1 // @disable-check M16
                                                          outputnum: 1} // @disable-check M16
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
                            color: defaultpalette.window
                            border.color: defaultpalette.border
                            border.width: 2
                        }
                    }
                    Frame {
                        y: layergroupsLabel.height - 2*pix
                        height: 0.4*(window.height - header.height - 2*layergroupsLabel.height)+4*pix
                        width: leftFrame.width
                        padding: 0
                        backgroundColor: defaultpalette.listview

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
                                        color: defaultpalette.window
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
                onWidthChanged: {
                    flickableMainPane.width = mainFrame.width - 4*pix
                    mainPane.width = flickableMainPane.width
                }
                onHeightChanged: {
                    flickableMainPane.height = mainFrame.height - 4*pix
                    mainPane.height = flickableMainPane.height
                }
                ScrollableItem {
                   id: flickableMainPane
                   width : mainFrame.width - 4*pix
                   height : mainFrame.height - 4*pix
                   contentWidth: flickableMainPane.width
                   contentHeight: flickableMainPane.height
                   showBackground: false
                   backgroundColor: defaultpalette.listview
                   clip: false
                   Pane {
                        id: mainPane
                        width: flickableMainPane.width
                        height: flickableMainPane.height
                        padding: 0
                        backgroundColor: defaultpalette.listview
                        Component.onCompleted: {
                            flickableMainPane.ScrollBar.vertical.visible = false
                            flickableMainPane.ScrollBar.horizontal.visible = false
                        }
                        property var selectioninds: []
                        MouseArea {
                            id: mainMouseArea
                            anchors.fill: parent
                            property int initialXPos
                            property int initialYPos
                            onClicked: {
                                propertiesStackView.push(generalpropertiesComponent)
                                currentFocus = null
                            }
                            onPressed: {
                                deselectunits()
                                if (mouse.button == Qt.LeftButton) {
                                    // initialize local variables to determine the selection orientation
                                    initialXPos = mouse.x
                                    initialYPos = mouse.y

                                    flickableMainPane.interactive = false // in case the event started over a Flickable element
                                    selectionRect.x = mouse.x
                                    selectionRect.y = mouse.y
                                    selectionRect.width = 0
                                    selectionRect.height = 0
                                    selectionRect.visible = true
                                }
                            }

                            onPositionChanged: {
                                if (selectionRect.visible == true) {
                                    if ((mouse.x != initialXPos || mouse.y != initialYPos)) {
                                        if (mouse.x >= initialXPos) {
                                            if (mouse.y >= initialYPos)
                                               selectionRect.rotation = 0
                                            else
                                               selectionRect.rotation = -90

                                        }
                                        else {
                                            if (mouse.y >= initialYPos)
                                                selectionRect.rotation = 90
                                            else
                                                selectionRect.rotation = -180
                                        }
                                    }

                                    if (selectionRect.rotation == 0 || selectionRect.rotation == -180) {
                                        selectionRect.width = Math.abs(mouse.x - selectionRect.x)
                                        selectionRect.height = Math.abs(mouse.y - selectionRect.y)
                                    }
                                    else {
                                        selectionRect.width = Math.abs(mouse.y - selectionRect.y)
                                        selectionRect.height = Math.abs(mouse.x - selectionRect.x)
                                    }
                                }
                            }

                            onReleased: {
                                selectionRect.visible = false
                                // restore the Flickable duties
                                flickableMainPane.interactive = true
                                var finishX = mouse.x
                                var finishY = mouse.y
                                var maxX = Math.max(initialXPos,finishX)
                                var minX = Math.min(initialXPos,finishX)
                                var maxY = Math.max(initialYPos,finishY)
                                var minY = Math.min(initialYPos,finishY)
                                for (var i=0;i<layers.children.length;i++) {
                                    if (layers.children[i].x >minX && layers.children[i].x <maxX &&
                                        layers.children[i].y >minY && layers.children[i].y <maxY &&
                                        (layers.children[i].x + layers.children[i].width)>minX &&
                                        (layers.children[i].x + layers.children[i].width)<maxX &&
                                        (layers.children[i].y + layers.children[i].height) >minY &&
                                        (layers.children[i].y + layers.children[i].height) <maxY)                                                          {
                                        mainPane.selectioninds.push(i)
                                        layers.children[i].border.color = defaultcolors.dark
                                        layers.children[i].border.width = 4*pix
                                    }
                                }
                            }
                        }

                        Item {
                            property int cnt: 0
                            id: layers
                        }
                        Item {
                            id: connections
                            property int num: 0
                        }
                        Rectangle {
                            id: selectionRect
                            visible: false
                            x: 0
                            y: 0
                            z: 99
                            width: 0
                            height: 0
                            rotation: 0
                            transformOrigin: Item.TopLeft
                            border.width: 2*pix
                            border.color: Qt.rgba(0.2,0.5,0.8,0.8)
                            color: Qt.rgba(0.2,0.5,0.8,0.05)
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
                            color: defaultpalette.window
                            border.color: defaultpalette.border
                            border.width: 2
                        }
                    }
                    Frame {
                        id: propertiesFrame
                        y: propertiesLabel.height -2*pix
                        height: 0.6*(window.height - header.height - 2*layersLabel.height)
                        width: rightFrame.width
                        padding: 0
                        backgroundColor: defaultpalette.window
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
                            color: defaultpalette.window
                            border.color: defaultpalette.border
                            border.width: 2
                        }
                    }
                    Frame {
                        id: overviewFrame
                        y: overviewLabel.height - 2*pix
                        height: 0.4*(window.height - header.height - 2*layersLabel.height) + 4*pix
                        width: rightFrame.width
                        padding: 0
                        backgroundColor: defaultpalette.listview
                        Image {
                            id: overviewImage
                            x: 2*pix
                            y: 2*pix
                            height: overviewFrame.height - 4*pix
                            width: overviewFrame.width - 4*pix
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }
            }
        }
    }


//--FUNCTIONS--------------------------------------------------------------------

    function dif(ar,x) {
        function dif_subfunc(value,x) {
            return value - x;
        }
        return ar.map(value => dif_subfunc(value,x));
    }

    function abs(ar) {
        return array.map(Math.abs);
    }

    function mean(array) {
        var total = 0
        for(var i = 0;i<array.length;i++) {
            total += array[i]
        }
        return(total/array.length)
    }

    function findindex(array,value) {
        var array2 = []
        for (var i=0;i<array.length;i++){
            if (array[i]===value){
                array2.push(i)
            }
        }
        return(array2)
    }

    function indexOfMax(array) {
        if (array.length === 0) {
            return -1;
        }
        var max = array[0];
        var maxIndex = 0;
        for (var i=1;i<array.length;i++) {
            if (array[i] > max) {
                maxIndex = i;
                max = array[i];
            }
        }
        return maxIndex;
    }

    function indexOfMin(array) {
        if (array.length === 0) {
            return -1;
        }
        var min = array[0];
        var minIndex = 0;
        for (var i=1;i<array.length;i++) {
            if (array[i] < min) {
                minIndex = i;
                min = array[i];
            }
        }
        return minIndex;
    }

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
        colorRGB[0] = 240 + colorRGB[0]/255*15
        colorRGB[1] = 240 + colorRGB[1]/255*15
        colorRGB[2] = 240 + colorRGB[2]/255*15
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
        return(connections.num)
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

    function datacmp(data,type) {
        if (data===undefined) {
            if (type==="str") {
                return("")
            }
            else if (type==="num") {
                return(-1)
            }
            else {
                return("")
            }
        }
        else {
            return(data)
        }
    }


    function updateOverview() {
        function Timer() {
            return Qt.createQmlObject("import QtQuick 2.0; Timer {}", window);
        }
        function delay(delayTime, cb) {
            var timer = new Timer();
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.start();
        }
        function upd() {
            mainPane.grabToImage(function(result) {
                overviewImage.source = result.url;
            })
        }
        delay(10, upd)
    }

    function deselectunits() {
        for (var i=0;i<layers.children.length;i++) {
            mainPane.selectioninds = []
            layers.children[i].border.color = defaultpalette.controlborder
            layers.children[i].border.width = 3*pix
        }
    }

    function deselectunit(unit) {
        unit.border.color = defaultpalette.controlborder
        unit.border.width = 3*pix
    }

    function selectunit(unit) {
        unit.border.color = defaultcolors.dark
        unit.border.width = 4*pix
    }

    function getarchitecture() {
        Julia.resetlayers()
        for (var i=0;i<layers.children.length;i++) {
            var datastore = layers.children[i].datastore
            var keys = Object.keys(datastore)
            var values = Object.values(datastore)
            for (var j=0;j<keys.length;j++) {
                if (typeof values[j] === typeof {}) {
                    values[j] = values[j]["text"]
                }
            }

            var upNodes = layers.children[i].children[2].children[0]
            var connections_up = Array(upNodes.children.length).fill(0)
            for (j=0;j<upNodes.children.length;j++) {
                var node = upNodes.children[j].children[0].connectedNode
                if (node!==null) {
                    connections_up[j] = getlayerindex(nodetolayer(node))+1
                }
            }
            var downNodes = layers.children[i].children[2].children[1]
            var connections_down = Array(downNodes.children.length).fill(0)
            for (j=0;j<downNodes.children.length;j++) {
                node = downNodes.children[j].children[1].connectedNode
                if (node!==null) {
                    connections_down[j] = getlayerindex(nodetolayer(node))+1
                }
            }
            var x = layers.children[i].x
            var y = layers.children[i].y
            Julia.returnmap(keys,values,"connections_up",connections_up,
                            "connections_down",connections_down,
                            "x",x,"y",y);
            Julia.updatelayers()
        }

    }

    function getlayerindex(layer) {
        for (var i=0;i<layers.children.length;i++) {
            if (layer===layers.children[i]) {
                return(i)
            }
        }
    }

    function nodetolayer(node) {
        return(node.parent.parent.parent.parent)
    }

    function indexofmin(a) {
        var lowest = 0;
        for (var i = 1; i < a.length; i++) {
            if (a[i] < a[lowest]) lowest = i;
        }
        return lowest;
    }

    function indexofmax(a) {
        var highest = 0;
        for (var i = 1; i < a.length; i++) {
            if (a[i] > a[highest]) highest = i;
        }
        return highest;
    }

    function pushstack(comp,labelColor,group,type,name,unit,datastore) {
        propertiesStackView.push(comp, {"labelColor": labelColor,
            "group": group,"type": type, "name": name,"unit": unit})
        if (datastore!==undefined) {
            propertiesStackView.currentItem.datastore = datastore
        }
    }

    function getstack(labelColor,group,type,name,unit,datastore) {
        switch(type) {
        case "Input":
            return pushstack(inputpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Output":
            return pushstack(outputpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Convolution":
            return pushstack(convpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Transposed convolution":
            return pushstack(tconvpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Dense":
            return pushstack(densepropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Drop-out":
            return pushstack(dropoutpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Batch normalisation":
            return pushstack(batchnormpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Leaky RelU":
            return pushstack(leakyrelupropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "ElU":
            return pushstack(elupropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Max pooling":
            return pushstack(poolpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Average pooling":
            return pushstack(poolpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Catenation":
            return pushstack(catpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Decatenation":
            return pushstack(decatpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Scaling":
            return pushstack(scalingpropertiesComponent,labelColor,group,type,name,unit,datastore)
        case "Resizing":
            return pushstack(resizingpropertiesComponent,labelColor,group,type,name,unit,datastore)
        default:
            pushstack(emptypropertiesComponent,labelColor,group,type,name,unit,datastore)
        }
    }

    function updateConnections() {
        for (var k=0;k<layers.children.length;k++) {
            var unit = layers.children[k]
            var upNodes = unit.children[2].children[0]
            var downNodes = unit.children[2].children[1]
            for (var i=0;i<upNodes.children.length;i++) {
                var upNodeRectangle = upNodes.children[i].children[0]
                if (upNodeRectangle.connectedNode!==null) {
                    var startX = upNodeRectangle.connectedItem.connection.data[0].startX;
                    var startY = upNodeRectangle.connectedItem.connection.data[0].startY;
                    upNodeRectangle.connectedItem.connection.destroy()
                    upNodeRectangle.connectedItem.connection = shapeComponent.createObject(connections, {
                          "beginX": startX ,
                          "beginY": startY,
                          "finishX": unit.x + unit.width*upNodes.children[i].index/(unit.inputnum+1),
                          "finishY": unit.y + 2*pix,
                          "origin": upNodeRectangle.connectedItem});
                    var nodePoint = upNodeRectangle.mapToItem(upNodeRectangle.connectedItem.parent,0,0)
                    upNodeRectangle.connectedItem.x = nodePoint.x - upNodeRectangle.radius/2
                    upNodeRectangle.connectedItem.y = nodePoint.y - upNodeRectangle.radius/2
                }
            }
            for (i=0;i<downNodes.children.length;i++) {
                for (var j=1;j<downNodes.children[i].children.length;j++) {
                    var downNodeRectangle = downNodes.children[i].children[j]
                    if (downNodeRectangle.connectedNode!==null) {
                        var finishX = downNodeRectangle.connection.data[0].pathElements[0].x
                        var finishY = downNodeRectangle.connection.data[0].pathElements[0].y
                        downNodeRectangle.connection.destroy()
                        downNodeRectangle.connection = shapeComponent.createObject(connections, {
                              "beginX": unit.x + unit.width*downNodes.children[i].index/(unit.outputnum+1),
                              "beginY": unit.y + unit.height - 2*pix,
                              "finishX": finishX,
                              "finishY": finishY,
                              "origin": downNodeRectangle});
                        nodePoint = downNodeRectangle.connectedNode.
                            mapToItem(downNodes.children[i],0,0)
                        downNodeRectangle.x = nodePoint.x - downNodeRectangle.radius/2
                        downNodeRectangle.y = nodePoint.y - downNodeRectangle.radius/2 + 2*pix
                    }
                }
            }
        }
    }

    function updateMainPane(unit) {
        var paneHeight = mainPane.height
        var paneWidth = mainPane.width
        var minheight = Math.min(0,gettop(unit))
        var minwidth = Math.min(0,getleft(unit))
        var maxheight = Math.max(paneHeight,getbottom(unit))
        var maxwidth = Math.max(paneWidth,getright(unit))
        var minheightchildren = gettopchild(layers)
        var minwidthchildren = getleftchild(layers)
        var maxheightchildren = getbottomchild(layers)
        var maxwidthchildren = getrightchild(layers)
        var padding = 20*pix
        var limit = [mainFrame.width/4,mainFrame.height]

        var adjX = 0
        var adjY = 0
        if (minwidth<0) {
            adjX = -minwidth + padding
        }
        else {
            adjX = -minwidthchildren + padding
        }
        if (minheight<0) {
            adjY = -minheight + padding
        }
        else {
            adjY = -minheightchildren + padding
        }
        if (adjX===padding && minwidthchildren===0*pix) {
            adjX = 0
        }
        if (adjY===padding && minheightchildren===0*pix) {
            adjY = 0
        }

        var devX = (minwidthchildren+maxwidthchildren)/2-paneWidth/2
        if (adjX<0) {
            if (Math.abs(devX)>limit[0] && minwidthchildren>devX && layers.children.length!==1) {
                adjX = -devX
            }
            else {
                adjX = 0
            }
        }
        var devY = (minheightchildren+maxheightchildren)/2-paneHeight/2

        if (adjY<0) {
            if (Math.abs(devY)>limit[1] && minheightchildren>devY && layers.children.length!==1) {
                adjY = -devY
            }
            else {
                adjY = 0
            }
        }
        if (layers.children.length===1) {
            if (adjX<0 ) { adjX = 0}
            if (adjY<0 ) { adjY = 0}
        }

        if (adjX!==0 || adjY!==0) {
            for (var i = 0; i < layers.children.length; i++) {
                layers.children[i].x = layers.children[i].x + adjX
                layers.children[i].y = layers.children[i].y + adjY
                mainPane.width = mainPane.width
                mainPane.height = mainPane.height
            }
            if (adjX!==0) {
                flickableMainPane.contentX = 0
            }
            if (adjY!==0) {
                flickableMainPane.contentY = 0
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
        maxheight = Math.max(paneHeight,getbottom(unit))
        maxwidth = Math.max(paneWidth,getright(unit))
        maxheightchildren = Math.max(getbottomchild(layers))
        maxwidthchildren = Math.max(getrightchild(layers))

        if (maxheight>paneHeight) {
            mainPane.height = maxheight + padding
            flickableMainPane.contentHeight = mainPane.height
            flickableMainPane.contentY = maxheight - flickableMainPane.height + padding
        }
        if (maxwidth>paneWidth) {
            mainPane.width = maxwidth + padding
            flickableMainPane.contentWidth = mainPane.width
            flickableMainPane.contentX = maxwidth - flickableMainPane.width + padding
        }
        if (maxheightchildren>paneHeight) {
            mainPane.height = maxheightchildren + padding
            flickableMainPane.contentHeight = mainPane.height
        }
        else if (maxheightchildren>(mainFrame.height - 4*pix)) {
            mainPane.height = maxheightchildren + padding
            flickableMainPane.contentHeight = mainPane.height
        }
        else {
            mainPane.height = mainFrame.height - 4*pix
            flickableMainPane.contentHeight = mainPane.height
        }

        if (maxwidthchildren>paneWidth) {
            mainPane.width = maxwidthchildren + padding
            flickableMainPane.contentWidth = mainPane.width
        }
        else if (maxwidthchildren>(mainFrame.width - 4*pix)) {
            mainPane.width = maxwidthchildren + padding
            flickableMainPane.contentWidth = mainPane.width
        }
        else {
            mainPane.width = mainFrame.width - 4*pix
            flickableMainPane.contentWidth = mainPane.width
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
        updateOverview()
    }

//--COMPONENTS--------------------------------------------------------------------

    Component {
        id: layerComponent
        Rectangle {
            id: unit
            height: 1.5*buttonHeight
            width: 0.9*buttonWidth
            radius: 8*pix
            border.color: defaultpalette.controlborder
            border.width: 3*pix
            property string name
            property string type
            property string group
            property var labelColor
            property double inputnum
            property double outputnum
            property var datastore
            property var oldpos: [x,y]

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
                id: unitMouseArea
                anchors.fill: parent
                drag.target: parent
                hoverEnabled: true
                Component.onCompleted: {
                    deselectunits()
                    currentFocus = unit
                    selectunit(unit)
                    getstack(labelColor,group,type,name,unit,datastore)
                }
                onEntered: {
                    selectunit(unit)
                    for (var i=0;i<upNodes.children.length;i++) {
                        upNodes.children[i].children[0].visible = true
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        downNodes.children[i].children[0].visible = true
                    }
                }
                onExited: {
                    if (unit!==currentFocus) {
                        if (mainPane.selectioninds.length<2){
                            deselectunit(unit)
                        }
                    }
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
                onPressed: {
                    unit.oldpos = [unit.x,unit.y]
                    currentFocus = unit
                    if (mainPane.selectioninds<2) {
                        deselectunits()
                        selectunit(unit)
                    }
                }
                onClicked: {
                    currentFocus = unit
                    deselectunits()
                    selectunit(unit)
                    getstack(labelColor,group,type,name,unit,datastore)
                }
                onPositionChanged: {
                    if (pressed) {
                        var inds = -1
                        var currentind = -1
                        for (var i=0;i<layers.children.length;i++) {
                            if (layers.children[i]===unit) {
                                currentind = i
                                break
                            }
                        }
                        if (mainPane.selectioninds.length===0) {
                            inds = [currentind]
                        }
                        else {
                            inds = mainPane.selectioninds
                        }
                        for (var k=0;k<inds.length;k++) {
                            if (inds[k]!==currentind) {
                                layers.children[inds[k]].x = layers.children[inds[k]].x + unit.x - unit.oldpos[0]
                                layers.children[inds[k]].y = layers.children[inds[k]].y + unit.y - unit.oldpos[1]
                            }

                            var upNodes = layers.children[inds[k]].children[2].children[0]
                            var downNodes = layers.children[inds[k]].children[2].children[1]
                            for (i=0;i<upNodes.children.length;i++) {
                                var upNodeRectangle = upNodes.children[i].children[0]
                                if (upNodeRectangle.connectedNode!==null) {
                                    var devX = 0
                                    var devY = 0

                                    if (inds[k]!==currentind) {
                                        devX = layers.children[inds[k]].x - unit.x
                                        devY = layers.children[inds[k]].y - unit.y

                                    }
                                    var startX = upNodeRectangle.connectedItem.connection.data[0].startX;
                                    var startY = upNodeRectangle.connectedItem.connection.data[0].startY;
                                    upNodeRectangle.connectedItem.connection.destroy()
                                    upNodeRectangle.connectedItem.connection = shapeComponent.createObject(connections, {
                                          "beginX": startX ,
                                          "beginY": startY,
                                          "finishX": unit.x + unit.width*upNodes.children[i].index/(layers.children[inds[k]].inputnum+1) + devX,
                                          "finishY": unit.y + 2*pix + devY,
                                          "origin": upNodeRectangle.connectedItem});
                                    var nodePoint = upNodeRectangle.mapToItem(upNodeRectangle.connectedItem.parent,0,0)
                                    upNodeRectangle.connectedItem.x = nodePoint.x - upNodeRectangle.radius/2
                                    upNodeRectangle.connectedItem.y = nodePoint.y - upNodeRectangle.radius/2
                                }
                            }
                            for (i=0;i<downNodes.children.length;i++) {
                                for (var j=1;j<downNodes.children[i].children.length;j++) {
                                    var downNodeRectangle = downNodes.children[i].children[j]
                                    if (pressed && downNodeRectangle.connectedNode!==null) {
                                        devX = 0
                                        devY = 0
                                        if (inds[k]!==currentind) {
                                            devX = layers.children[inds[k]].x - unit.x
                                            devY = layers.children[inds[k]].y - unit.y
                                        }
                                        var finishX = downNodeRectangle.connection.data[0].pathElements[0].x
                                        var finishY = downNodeRectangle.connection.data[0].pathElements[0].y
                                        downNodeRectangle.connection.destroy()
                                        downNodeRectangle.connection = shapeComponent.createObject(connections, {
                                              "beginX": unit.x + unit.width*downNodes.children[i].index/(layers.children[inds[k]].outputnum+1) + devX,
                                              "beginY": unit.y + unit.height - 2*pix + devY,
                                              "finishX": finishX,
                                              "finishY": finishY,
                                              "origin": downNodeRectangle});
                                        nodePoint = downNodeRectangle.connectedNode.
                                            mapToItem(downNodes.children[i],0,0)
                                        downNodeRectangle.x = nodePoint.x - downNodeRectangle.radius/2
                                        downNodeRectangle.y = nodePoint.y - downNodeRectangle.radius/2 + 2*pix
                                    }
                                }
                            }
                        }
                        unit.oldpos = [unit.x,unit.y]
                    }
                }
                onReleased: {
                    updateMainPane(unit)
                }
            }

            Item {
            id: nodes
                Item {
                    id: upNodes
                    Component.onCompleted: {
                        for (var i=0;i<inputnum;i++) {
                            upNodeComponent.createObject(upNodes, {
                                "unit": unit,
                                "upNodes": upNodes,
                                "downNodes": downNodes,
                                "inputnum": inputnum,
                                "index": i+1});
                        }
                    }
                }
                Item {
                    id: downNodes
                    Component.onCompleted: {
                        for (var i=0;i<outputnum;i++) {
                            downNodeComponent.createObject(downNodes, {
                                "unit": unit,
                                "upNodes": upNodes,
                                "downNodes": downNodes,
                                "outputnum": outputnum,
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
            property double outputnum
            property double index
            Rectangle {
                id: downNode
                width: 20*pix
                height: 20*pix
                radius: 20*pix
                border.color: defaultpalette.controlborder
                border.width: 3*pix
                visible: false
                x: unit.width*index/(outputnum+1) - downNode.radius/2
                y: unit.height - downNode.radius/2 - 2*pix
            }
            Component.onCompleted: downNodeRectangleComponent.createObject(downNodeItem, {
                "unit": unit,
                "upNodes": upNodes,
                "downNodes": downNodes,
                "downNodeItem": downNodeItem,
                "downNode": downNode,
                "outputnum": outputnum,
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
            property double outputnum
            property double index
            width: 2*downNode.radius
            height: 2*downNode.radius
            //opacity: 0.2
            color: "transparent"
            x: unit.width*index/(outputnum+1) - downNode.radius
            y: unit.height - downNode.radius - 2*pix
            MouseArea {
                id: downnodeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                drag.target: downNodeRectangle
                drag.smoothed: false
                property var mouseAdjust: [0,0]
                onEntered: {
                    downNode.border.color = defaultcolors.dark
                    downNode.border.width = 4*pix
                    for (var i=0;i<upNodes.children.length;i++) {
                        upNodes.children[i].children[0].visible = true
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        downNodes.children[i].children[0].visible = true
                    }
                }
                onExited: {
                    downNode.border.color = defaultpalette.controlborder
                    downNode.border.width = 3*pix
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
                onPressed: {
                    deselectunits()
                    mainPane.selectioninds = []
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
                             "beginX": unit.x + unit.width*index/(outputnum+1),
                             "beginY": unit.y + unit.height - 2*pix,
                             "finishX": unit.x + downNodeRectangle.x + downNode.radius +
                                            mouseAdjust[0],
                             "finishY": unit.y + downNodeRectangle.y + downNode.radius +
                                            mouseAdjust[1] + 2*pix,
                             "origin": downNodeRectangle});
                    }
                }
                onReleased: {
                    updateOverview()
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
                                     "beginX": unit.x + unit.width*index/(outputnum+1),
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
                                                "outputnum": outputnum,
                                                "index": index});
                                connections.num = connections.num + 1
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
                                connections.num = connections.num - 1
                            }
                        }
                    }
                    if (downNodeItem.children[1].connectedNode!==null) {
                        downNode.visible = true
                    }
                    if (downNodeRectangle.connectedNode===null) {
                        downNodeRectangle.x = unit.width*index/(outputnum+1) - downNode.radius
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
            property double inputnum
            property double index
            Rectangle {
                id: upNode
                width: 20*pix
                height: 20*pix
                radius: 20*pix
                border.color: defaultpalette.controlborder
                border.width: 3*pix
                visible: false
                property var connectedNode: null
                property var connectedItem: null
                x: unit.width*index/(inputnum+1)-upNode.radius/2
                y: -upNode.radius/2 + 2*pix
            }
            Rectangle {
                id: upNodeRectangle
                width: 2*upNode.radius
                height: 2*upNode.radius
                //opacity: 0.2
                color: "transparent"
                border.width: 0
                x: unit.width*index/(inputnum+1)-upNode.radius
                y: -upNode.radius + 2*pix
                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    hoverEnabled: true
                    property var mouseAdjust: [0,0]
                    onEntered: {
                        upNode.border.color = defaultcolors.dark
                        upNode.border.width = 4*pix
                        for (var i=0;i<upNodes.children.length;i++) {
                            upNodes.children[i].children[0].visible = true
                        }
                        for (i=0;i<downNodes.children.length;i++) {
                            downNodes.children[i].children[0].visible = true
                        }

                    }
                    onExited: {
                        upNode.border.color = defaultpalette.controlborder
                        upNode.border.width = 3*pix
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
                    onPressed: {
                        deselectunits()
                        mainPane.selectioninds = []
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
                                                upNode.connectedItem.index/(upNode.connectedItem.outputnum+1),
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
                            upNodeRectangle.x = unit.width*index/(inputnum+1)-upNode.radius
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
                                    upNodeRectangle.x = unit.width*index/(inputnum+1)-upNode.radius
                                    upNodeRectangle.y = -upNode.radius + 2*pix
                                    upNode.connectedItem.x = upNode.connectedItem.x - adjX
                                    upNode.connectedItem.y = upNode.connectedItem.y - adjY
                                    upNode.connectedItem.connection.destroy()
                                    var point = layers.children[i].children[2].children[0].children[j].children[1].mapToItem(layers,0,0)
                                    upNode.connectedItem.connection = shapeComponent.createObject(connections, {
                                          "beginX": upNode.connectedItem.unit.x + upNode.connectedItem.unit.width*
                                                        upNode.connectedItem.index/(upNode.connectedItem.outputnum+1),
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
                        upNodeRectangle.x = unit.width*index/(inputnum+1)-upNode.radius
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
                strokeColor: defaultcolors.dark
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
                                           "inputnum": inputnum,
                                           "outputnum": outputnum,
                                           "x": flickableMainPane.contentX + 20*pix,
                                           "y": flickableMainPane.contentY + 20*pix});
            }
            RowLayout {
                anchors.fill: parent.fill
                Rectangle {
                    id: colorRectangle
                    Layout.leftMargin: 0.2*margin
                    Layout.bottomMargin: 0.03*margin
                    Layout.preferredWidth: 0.4*margin
                    Layout.preferredHeight: 0.4*margin
                    height: 20*pix
                    width: 20*pix
                    radius: colorRectangle.height
                    Layout.alignment: Qt.AlignBottom
                    color: rgbtohtml([colorR,colorG,colorB])
                    border.width: 2*pix
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

//----Properties components
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
                    text: "Number of nonlinearities: "
                }
            }
            ColumnLayout {
                Layout.leftMargin: 0.2*margin
                Layout.topMargin: 0.2*margin
                spacing: 0.2*margin
                Label {
                    text: layers.children.length
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
        id: inputpropertiesComponent

        Column {
            id: column
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"size": "160,160",
                "normalisation": {"text": "[0,1]", "ind": 0}}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }

            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Size","Normalisation"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.size
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,3})|([1-9]\d{0,3},[1-9]\d{0,3})|([1-9]\d{0,3},[1-9]\d{0,3},[1-9]\d{0,3}))/ }
                        onEditingFinished: {
                            unit.datastore.size = displayText
                        }
                    }
                    ComboBox {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        currentIndex: datastore.normalisation.ind
                        model: ListModel {
                           id: optionsModel
                           ListElement { text: "[0,1]" } //@disable-check M16
                           ListElement { text: "[-1,1]" } //@disable-check M16
                           ListElement { text: "zero center" } //@disable-check M16
                        }
                        onActivated: {
                            unit.datastore.normalisation.text = currentText
                            unit.datastore.normalisation.ind = currentIndex
                        }
                    }
                }
            }
        }
    }

    Component {
        id: outputpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"loss": {"text": "Dice coefficient", "ind": 12}}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Loss"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    ComboBox {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        currentIndex: datastore.loss.ind
                        model: ListModel {
                           id: optionsModel
                           ListElement { text: "MAE" } //@disable-check M16
                           ListElement { text: "MSE" } //@disable-check M16
                           ListElement { text: "MSLE" } //@disable-check M16
                           ListElement { text: "Huber" } //@disable-check M16
                           ListElement { text: "Crossentropy" } //@disable-check M16
                           ListElement { text: "Logit crossentropy" } //@disable-check M16
                           ListElement { text: "Binary crossentropy" } //@disable-check M16
                           ListElement { text: "Logit binary crossentropy" } //@disable-check M16
                           ListElement { text: "Kullback-Leibler divergence" } //@disable-check M16
                           ListElement { text: "Poisson" } //@disable-check M16
                           ListElement { text: "Hinge" } //@disable-check M16
                           ListElement { text: "Squared hinge" } //@disable-check M16
                           ListElement { text: "Dice coefficient" } //@disable-check M16
                           ListElement { text: "Tversky" } //@disable-check M16
                        }
                        onActivated: {
                            unit.datastore.loss.text = currentText
                            unit.datastore.loss.ind = currentIndex
                        }
                    }
                }
            }
        }
    }

    Component {
        id: convpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"filters": "32", "filtersize": "3",
                "stride": "1", "dilationfactor": "1"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.filters
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{1,5}/ }
                        onEditingFinished: {
                            unit.datastore.filters = displayText
                        }
                    }
                    TextField {
                        text: datastore.filtersize
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.filtersize = displayText
                        }
                    }
                    TextField {
                        text: datastore.stride
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.stride = displayText
                        }
                    }
                    TextField {
                        text: datastore.dilationfactor
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.dilationfactor = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: tconvpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"filters": "32", "filtersize": "3",
                "stride": "1"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.filters
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{1,5}/ }
                        onEditingFinished: {
                            unit.datastore.filters = displayText
                        }
                    }
                    TextField {
                        text: datastore.filtersize
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.filtersize = displayText
                        }
                    }
                    TextField {
                        text: datastore.stride
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.stride = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: densepropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"neurons": "32"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.neurons
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{1,5}/ }
                        onEditingFinished: {
                            unit.datastore.neurons = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: batchnormpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"epsilon": "0.00001"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Epsilon"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.epsilon
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,10}/ }
                        onEditingFinished: {
                            unit.datastore.epsilon = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dropoutpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"probability": "0.5"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Probability"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.probability
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,2}/ }
                        onEditingFinished: {
                            unit.datastore.probability = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: leakyrelupropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"scale": "0.01"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Scale"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.scale
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,2}/ }
                        onEditingFinished: {
                            unit.datastore.scale = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: elupropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"alpha": "1"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Alpha"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.alpha
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,4}|[1-9]d{1,2}/ }
                        onEditingFinished: {
                            unit.datastore.alpha = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: poolpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"poolsize": "2", "stride": "2"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Pool size","Stride"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.poolsize
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.poolsize = displayText
                        }
                    }
                    TextField {
                        text: datastore.stride
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.stride = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: catpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"inputs": "2", "dimension": "1"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","Inputs","Dimension"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.inputs
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1}/ }
                        onEditingFinished: {
                            var inputnum = parseFloat(unit.datastore.inputs)
                            var newinputnum = parseFloat(displayText)
                            if (inputnum===newinputnum) {return}
                            if (inputnum<newinputnum) {
                                for (var i=0;i<inputnum;i++) {
                                    unit.children[2].children[0].children[i].inputnum = newinputnum
                                    unit.children[2].children[0].children[i].children[0].x = unit.width*
                                            unit.children[2].children[0].children[i].index/(newinputnum+1)-10*pix
                                    unit.children[2].children[0].children[i].children[1].x = unit.width*
                                            unit.children[2].children[0].children[i].index/(newinputnum+1)-20*pix
                                }
                                for (i=0;i<(newinputnum-inputnum);i++) {
                                    upNodeComponent.createObject(unit.children[2].children[0], {
                                        "unit": unit,
                                        "upNodes": unit.children[2].children[0],
                                        "downNodes": unit.children[2].children[1],
                                        "inputnum": newinputnum,
                                        "index": inputnum+i+1})
                                }
                            }
                            else {
                                for (i=inputnum-1;i>=0;i--) {
                                    if (i<newinputnum) {
                                        unit.children[2].children[0].children[i].inputnum = newinputnum
                                        unit.children[2].children[0].children[i].children[0].x = unit.width*
                                                unit.children[2].children[0].children[i].index/(newinputnum+1)-10*pix
                                        unit.children[2].children[0].children[i].children[1].x = unit.width*
                                                unit.children[2].children[0].children[i].index/(newinputnum+1)-20*pix
                                    }
                                    else {
                                        if (unit.children[2].children[0].children[i].children[0].connectedItem!==null) {
                                            unit.children[2].children[0].children[i].children[0].connection.destroy()
                                            unit.children[2].children[0].children[i].children[0].connectedItem = null
                                            unit.children[2].children[0].children[i].children[0].connectedNode = null
                                        }
                                        unit.children[2].children[0].children[i].destroy()
                                    }
                                }
                            }
                            unit.inputnum = newinputnum
                            unit.datastore.inputs = displayText
                        }
                    }
                    TextField {
                        text: datastore.dimension
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-3]/ }
                        onEditingFinished: {
                            unit.datastore.dimension = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: decatpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"outputs": "2"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.outputs
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,1}/ }
                        onEditingFinished: {
                            var outputnum = parseFloat(unit.datastore.outputs)
                            var newoutputnum = parseFloat(displayText)
                            if (outputnum===newoutputnum) {return}
                            if (outputnum<newoutputnum) {
                                for (var i=0;i<outputnum;i++) {
                                    unit.children[2].children[1].children[i].outputnum = newoutputnum
                                    unit.children[2].children[1].children[i].children[1].outputnum = newoutputnum
                                    unit.children[2].children[1].children[i].children[0].x = unit.width*
                                            unit.children[2].children[1].children[i].index/(newoutputnum+1)-10*pix
                                    unit.children[2].children[1].children[i].children[1].x = unit.width*
                                            unit.children[2].children[1].children[i].index/(newoutputnum+1)-20*pix
                                }
                                for (i=0;i<(newoutputnum-outputnum);i++) {
                                    downNodeComponent.createObject(unit.children[2].children[1], {
                                        "unit": unit,
                                        "upNodes": unit.children[2].children[0],
                                        "downNodes": unit.children[2].children[1],
                                        "outputnum": newoutputnum,
                                        "index": outputnum+i+1})
                                }
                            }
                            else {
                                for (i=outputnum-1;i>=0;i--) {
                                    if (i<newoutputnum) {
                                        unit.children[2].children[1].children[i].outputnum = newoutputnum
                                        unit.children[2].children[1].children[i].children[1].outputnum = newoutputnum
                                        unit.children[2].children[1].children[i].children[0].x = unit.width*
                                                unit.children[2].children[1].children[i].index/(newoutputnum+1)-10*pix
                                        unit.children[2].children[1].children[i].children[1].x = unit.width*
                                                unit.children[2].children[1].children[i].index/(newoutputnum+1)-20*pix
                                    }
                                    else {
                                        if (unit.children[2].children[1].children[i].children[1].connectedItem!==null) {
                                            unit.children[2].children[1].children[i].children[1].connection.destroy()
                                            unit.children[2].children[1].children[i].children[1].connectedItem = null
                                            unit.children[2].children[1].children[i].children[1].connectedNode = null
                                        }
                                        unit.children[2].children[1].children[i].destroy()
                                    }
                                }

                            }
                            unit.outputnum = newoutputnum
                            unit.datastore.outputs = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: scalingpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"multiplier": "2"}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.multiplier
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /([1-9]\d{0,1})|(0,\d{1-2})/ }
                        onEditingFinished: {
                            unit.datastore.multiplier = displayText
                        }
                    }
                }
            }
        }
    }

    Component {
        id: resizingpropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property var group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group,"newsize": "100,100", "mode": {"text": "Column major", "ind": 1}}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 0.4*margin
                    Layout.topMargin: 0.22*margin
                    spacing: 0.24*margin
                    Repeater {
                        model: ["Name","New size","Mode"]
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.newsize
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,3})|([1-9]\d{0,3},[1-9]\d{0,3})|([1-9]\d{0,3},[1-9]\d{0,3},[1-9]\d{0,3}))/ }
                        onEditingFinished: {
                            unit.datastore.newsize = displayText
                        }
                    }
                    ComboBox {
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        currentIndex: datastore.mode.ind
                        model: ListModel {
                           id: netModel
                           ListElement { text: "Column major" } //@disable-check M16
                           ListElement { text: "Row major" } //@disable-check M16
                        }
                        onActivated: {
                            unit.datastore.mode.text = currentText
                            unit.datastore.mode.ind = currentIndex
                        }
                    }
                }
            }
        }
    }

    Component {
        id: emptypropertiesComponent
        Column {
            property var unit
            property var name
            property string type
            property string group
            property var labelColor
            property var datastore: { "name": name, "type": type, "group": group}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
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
                    id: labelColumnLayout
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
                        text: datastore.name
                        defaultHeight: 0.75*buttonHeight
                        defaultWidth: rightFrame.width - labelColumnLayout.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                }
            }
        }
    }
}
