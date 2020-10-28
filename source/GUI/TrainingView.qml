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
        property string dialogtarget

        Loader { id: featuredialogLoader}
        Loader { id: trainingoptionsLoader}
        Loader { id: customizationLoader}
        Loader { id: trainingplotLoader}

        function load_model_features() {
            var num_features = Julia.num_features()
            if (num_features!==0) {
                updateButton.visible = false
                updatemodelButton.visible = true
                for (var i=0;i<num_features;i++) {
                    var color = Julia.get_feature_field(i+1,"color")
                    var feature = {
                        "name": Julia.get_feature_field(i+1,"name"),
                        "colorR": color[0],
                        "colorG": color[1],
                        "colorB": color[2],
                        "border": Julia.get_feature_field(i+1,"border"),
                        "parent": Julia.get_feature_field(i+1,"parent")}
                    featureModel.append(feature)
                }
            }
        }

        FolderDialog {
                id: folderDialog
                currentFolder: currentfolder
                options: FolderDialog.ShowDirsOnly
                onAccepted: {
                    var dir = folder.toString().replace("file:///","")
                    updateButton.visible = true
                    updatemodelButton.visible = false
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
                    Julia.save_data()
                }
        }
        FileDialog {
                id: fileDialog
                nameFilters: [ "*.model"]
                onAccepted: {
                    var url = file.toString().replace("file:///","")
                    neuralnetworkTextField.text = url
                    importmodel(model,url)
                    load_model_features()
                    nameTextField.text = Julia.get_data(["Training","name"])
                    Julia.save_data()
                }
        }
        Column {
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
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_data(["Training","template"])
                            if (Julia.isfile(url)) {
                                text = url
                                importmodel(model,url)
                                load_model_features()
                            }
                        }
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
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_data(["Training","images"])
                            if (Julia.isdir(url)) {
                                text = url
                            }
                        }
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
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_data(["Training","labels"])
                            if (Julia.isdir(url)) {
                                text = url
                            }
                        }
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
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        onEditingFinished: Julia.set_data(["Training","name"],text)
                        Component.onCompleted: {
                            text = Julia.get_data(["Training","name"])
                        }
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
                                                var count = featureModel.count
                                                for (var i=0;i<count;i++) {
                                                    featureModel.remove(0)
                                                }
                                                Julia.get_urls_imgs_labels()
                                                var colors = Julia.get_labels_colors()
                                                Julia.reset_features()
                                                for (i=0;i<colors.length;i++) {
                                                    var feature = {
                                                        "name": "feature "+(i+1),
                                                        "colorR": colors[i][0],
                                                        "colorG": colors[i][1],
                                                        "colorB": colors[i][2],
                                                        "border": false,
                                                        "parent": ""}
                                                    featureModel.append(feature)
                                                    Julia.append_features(feature.name,
                                                                          feature.colorR,
                                                                          feature.colorG,
                                                                          feature.colorB,
                                                                          feature.border,
                                                                          feature.parent)
                                                }
                                                updateButton.visible = false
                                                updatemodelButton.visible = true
                                            }
                                        }
                                        Component.onCompleted: {
                                            load_model_features()
                                        }
                                    }
                                    TreeButton {
                                        id: updatemodelButton
                                        anchors.top: featureView.bottom
                                        width: buttonWidth + 0.5*margin-24*pix
                                        height: buttonHeight-2*pix
                                        hoverEnabled: true
                                        visible: false
                                        Label {
                                            topPadding: 0.15*margin
                                            leftPadding: 105*pix
                                            text: "Update model"
                                        }
                                        onClicked: {

                                            Julia.save_model(nameTextField.text)
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
                            if (imagesTextField.length===0 || labelsTextField.length===0) {
                                return
                            }
                            if (text==="Start training") {
                                text = "Stop data preparation"
                                Julia.set_data(["Training","stop_training"],false)
                                Julia.get_urls_imgs_labels()
                                dataprocessingTimer.running = true
                                Julia.prepare_training_data()
                            }
                            else {
                                if (dataprocessingTimer.running) {
                                    text = "Wait"
                                }
                                else {
                                    text = "Start training"
                                    progressbar.value = 0
                                }
                                Julia.set_data(["Training","stop_training"],true)
                                Julia.reset(Julia.get_data(["Training","data_ready"]))
                            }
                        }
                        Timer {
                            id: dataprocessingTimer
                            interval: 1000; running: false; repeat: true
                            property double step: 0
                            onTriggered: {
                                if (starttrainingButton.text==="Wait") {
                                    if (Julia.get_data(["Training","task_done"])) {
                                        starttrainingButton.text = "Start training"
                                        running = false
                                        step = 0
                                        progressbar.value = 0
                                        return
                                    }
                                    return
                                }
                                if (step!==0) {
                                    Julia.yield()
                                    var state = Julia.get_data(["Training","data_ready"])
                                    var mean_val = mean(state)
                                    var sum_val = sum(state)
                                    if (mean_val===1) {
                                        running = false
                                        starttrainingButton.text = "Stop training"
                                    }
                                    progressbar.value = mean_val
                                }
                                else {
                                    state = Julia.get_data(["Training","data_ready"])
                                    if (state.length!==0) {
                                        state = Julia.get_data(["Training","data_ready"])
                                        step = 1/state.length
                                    }
                                    else {
                                        running = false
                                        starttrainingButton.text = "Start training"
                                        //trainingplotLoader.source = "TrainingPlot.qml"}
                                    }
                                }
                            }
                        }
                    }
                    ProgressBar {
                        id: progressbar
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        value: 0
                        Layout.preferredWidth: buttonWidth
                    }
                }
            }
        }
    }
}
