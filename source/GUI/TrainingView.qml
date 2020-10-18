import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0

Component {
    Item {
        id: mainItem
        property string colorR: "0"
        property string colorG: "0"
        property string colorB: "0"
        property int indTree: 0
        property var model: []
        property var model_name: "model"

        property string dialogtarget

        Loader { id: featuredialogLoader}
        Loader { id: trainingoptionsLoader}
        Loader { id: customizationLoader}
        Loader { id: trainingplotLoader}

        FolderDialog {
                id: folderDialog
                currentFolder: currentfolder
                options: FolderDialog.ShowDirsOnly
                onAccepted: {
                    var dir = folder.toString().replace("file:///","")
                    updateButton.visible = true
                    var count = featureModel.count
                    for (var i=0;i<count;i++) {
                        featureModel.remove(0)
                    }
                    if (dialogtarget=="Images") {
                        imagesTextField.text = dir
                        Julia.set_data(["Training","images"],dir)
                    }
                    else if (dialogtarget=="Labels") {
                        labelsTextField.text = dir
                        Julia.set_data(["Training","labels"],dir)
                    }
                }
        }
        FileDialog {
                id: fileDialog
                nameFilters: [ "*.json"]
                onAccepted: {
                    var url = file.toString().replace("file:///","")
                    model.length = 0
                    state = Julia.load_model(url)
                    var skipStringing = ["x","y"]
                    if (state!==null) {
                        neuralnetworkTextField.text = url
                        var count = Julia.model_count()
                        for (var i=0;i<count;i++) {
                            var indJ = i+1
                            var unit = {}
                            var properties = Julia.model_properties(indJ)
                            for (var j=0;j<properties.length;j++) {
                                var prop_name = properties[j]
                                var prop = Julia.model_get_property(indJ,prop_name)
                                if (typeof(prop)==='object' && prop.length===2) {
                                    if (typeof(prop[0])==='string' && typeof(prop[1])==='number') {
                                       unit[prop_name] = {"text": prop[0],"ind": prop[1]}
                                    }
                                    else {
                                        unit[prop_name] = prop
                                    }
                                }
                                else {
                                    if (skipStringing.includes(prop_name) || typeof(prop)==='object') {
                                        unit[prop_name] = prop
                                    }
                                    else {
                                        unit[prop_name] = prop.toString()
                                    }
                                }
                            }
                            model.push(unit)
                        }
                    }
                    Julia.set_data(["Training","template"],url)
                }
        }

        MouseArea {
            width: 500
            height:500
            onClicked: console.log("clicked")
        }

        Column {
            x: 0
            y: 0
            spacing: 0.7*margin
            ColumnLayout {
                spacing: 0.5*margin
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Network:"
                        bottomPadding: 0.05*margin
                        width: 0.38*buttonWidth
                    }
                    TextField {
                        id: neuralnetworkTextField
                        text: Julia.get_data(["Training","template"])
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                    }
                    Button {
                        width: buttonWidth/2
                        height: buttonHeight
                        text: "Browse"
                        onClicked: {
                            dialogtarget = "Network"
                            fileDialog.open()
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Images:"
                        bottomPadding: 0.05*margin
                        width: 0.38*buttonWidth
                    }
                    TextField {
                        id: imagesTextField
                        text: Julia.get_data(["Training","images"])
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                    }
                    Button {
                        width: buttonWidth/2
                        height: buttonHeight
                        text: "Browse"
                        onClicked: {
                            dialogtarget = "Images"
                            folderDialog.open()
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Labels:"
                        bottomPadding: 0.05*margin
                        width: 0.38*buttonWidth
                    }
                    TextField {
                        id: labelsTextField
                        text: Julia.get_data(["Training","labels"])
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                    }
                    Button {
                        width: buttonWidth/2
                        height: buttonHeight
                        text: "Browse"
                        onClicked: {
                            dialogtarget = "Labels"
                            folderDialog.open()
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Name:"
                        bottomPadding: 0.05*margin
                        width: 0.38*buttonWidth
                    }
                    TextField {
                        id: nameTextField
                        text: Julia.get_data(["Training","name"])
                        width: 1.55*buttonWidth
                        height: buttonHeight
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
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
                            border.width: 2*pix
                        }
                    }
                    Frame {
                        height: 0.2*Screen.height
                        width: buttonWidth + 0.5*margin
                        backgroundColor: "white"
                        ScrollView {
                            clip: true
                            anchors.fill: parent
                            padding: 0
                            spacing: 0
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            Flickable {
                                boundsBehavior: Flickable.StopAtBounds
                                contentHeight: featureView.height+buttonHeight-2*pix
                                Item {
                                    TreeButton {
                                        id: updateButton
                                        anchors.top: featureView.bottom
                                        width: buttonWidth + 0.5*margin-24*pix
                                        height: buttonHeight-2*pix
                                        hoverEnabled: true
                                        Label {
                                            topPadding: 0.15*margin
                                            leftPadding: 1.95*margin
                                            text: "Update"
                                        }
                                        onClicked: {
                                            if (imagesTextField.text!=="" && labelsTextField.text!=="") {
                                                Julia.get_urls_imgs_labels(imagesTextField.text,
                                                    labelsTextField.text,"segmentation")
                                                var colors = Julia.get_labels_colors()
                                                for (var i=0;i<colors.length;i++) {
                                                    featureModel.append({
                                                            "name": "feature "+i,
                                                            "colorR": colors[i][0],
                                                            "colorG": colors[i][1],
                                                            "colorB": colors[i][2],
                                                            "border": false,
                                                            "parent": ""})
                                                }
                                                updateButton.visible = false
                                            }
                                        }
                                    }
                                    ListView {
                                        id: featureView
                                        height: childrenRect.height
                                        spacing: 0
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: ListModel {id: featureModel}
                                        delegate: TreeButton {
                                            id: control
                                            hoverEnabled: true
                                            width: buttonWidth + 0.5*margin-24*pix
                                            height: buttonHeight-2*pix
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
}
