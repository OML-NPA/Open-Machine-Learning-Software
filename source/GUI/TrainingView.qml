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
        Loader { id: validationplotLoader}

        function load_model_features() {
            var num_features = Julia.num_features()
            if (num_features!==0 && featureModel.count==0) {
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
                        Julia.set_settings(["Training","images"],dir)
                    }
                    else if (dialogtarget=="Labels") {
                        labelsTextField.text = dir
                        Julia.set_settings(["Training","labels"],dir)
                    }
                    Julia.save_settings()
                }
        }
        FileDialog {
                id: fileDialog
                nameFilters: [ "*.model"]
                onAccepted: {
                    var url = file.toString().replace("file:///","")
                    neuralnetworkTextField.text = url
                    importmodel(model,url)
                    featureModel.clear()
                    load_model_features()
                    nameTextField.text = Julia.get_settings(["Training","name"])
                    Julia.save_settings()
                }
        }
        Column {
            id: mainColumn
            spacing: 0.7*margin
            Column {
                id: dataColumn
                spacing: 0.5*margin
                Row {
                    spacing: margin
                    Row {
                        spacing: 0.3*margin
                        Label {
                            id: problemtypeLabel
                            text: "Problem type:"
                            topPadding: 10*pix
                        }
                        ComboBox {
                            id: problemtypeComboBox
                            function changeLabels() {
                                if (currentIndex===0) {
                                    labelsLabel.text = "Labels:"
                                    inputtypeModel.clear()
                                    inputtypeModel.append({text: "Image"})
                                    inputtypeModel.append({text: "Data series"})
                                    inputtypeComboBox.currentIndex = 0
                                    labelsRow.visible = false

                                }
                                else if (currentIndex===1) {
                                    labelsLabel.text = "Labels:"
                                    inputtypeModel.clear()
                                    inputtypeModel.append({text: "Image"})
                                    inputtypeComboBox.currentIndex = 0
                                    labelsRow.visible = true
                                }
                                else {
                                    labelsLabel.text = "Targets:"
                                    inputtypeModel.clear()
                                    inputtypeModel.append({text: "Image"})
                                    inputtypeModel.append({text: "Data series"})
                                    inputtypeComboBox.currentIndex = 0
                                    labelsRow.visible = true
                                }
                            }
                            editable: false
                            width: 0.69*buttonWidth-1*pix
                            model: ListModel {
                                id: problemtypeModel
                                ListElement {text: "Classification"}
                                ListElement {text: "Segmentation"}
                                ListElement {text: "Regression"}
                            }
                            onActivated: {
                                Julia.set_settings(["Training","problem_type"],
                                    [currentText,currentIndex])
                                changeLabels()
                            }
                            Component.onCompleted: {
                                var val = Julia.get_settings(["Training","problem_type"])
                                currentIndex = val[1]
                                changeLabels()
                            }
                        }
                    }
                    Row {
                        spacing: 0.3*margin
                        Label {
                            text: "Input type:"
                            topPadding: 10*pix
                        }
                        ComboBox {
                            id: inputtypeComboBox
                            function changeLabels() {
                                if (currentIndex===0) {
                                    inputLabel.text = "Images:"
                                    previewdataButton.visible = false
                                }
                                else {
                                    inputLabel.text = "Data:"
                                    previewdataButton.visible = true
                                }
                            }

                            editable: false
                            width: 0.59*buttonWidth-1*pix
                            model: ListModel {
                                id: inputtypeModel
                                ListElement {text: "Image"}
                                ListElement {text: "Data series"}
                            }
                            onActivated: {
                                Julia.set_settings(["Training","input_type"],
                                    [currentText,currentIndex])
                                changeLabels()
                            }
                            Component.onCompleted: {
                                var val = Julia.get_settings(["Training","input_type"])
                                currentIndex = val[1]
                                changeLabels()
                            }
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        id: inputLabel
                        text: "Images:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: imagesTextField
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_settings(["Training","images"])
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
                    id: labelsRow
                    spacing: 0.3*margin
                    Label {
                        id: labelsLabel
                        text: "Labels:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: labelsTextField
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_settings(["Training","labels"])
                            if (Julia.isdir(url)) {
                                text = url
                            }
                        }
                    }
                    Button {
                        id: browselabelsButton
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
                        text: "Network:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: neuralnetworkTextField
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_settings(["Training","template"])
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
                        text: "Name:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: nameTextField
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        onEditingFinished: Julia.set_settings(["Training","name"],text)
                        Component.onCompleted: {
                            text = Julia.get_settings(["Training","name"])
                        }
                    }
                }
            }
            Row {
                Column {
                    id: featuresColumn
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
                                            Julia.save_model("models/" + nameTextField.text + ".model")
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
                Column {
                    id: buttonsColumn
                    spacing: 0.3*margin
                    topPadding: (featuresColumn.height - buttonsColumn.height)/2
                    leftPadding: (dataColumn.width - featuresColumn.width -
                        buttonWidth)/2
                    Button {
                        id: previewdataButton
                        text: "Preview imported data"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                        }
                    }
                    Button {
                        id: optionsButton
                        text: "Options"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (trainingoptionsLoader.sourceComponent === null) {
                                trainingoptionsLoader.source = "TrainingOptions.qml"
                            }
                        }
                    }
                    Button {
                        id: designButton
                        text: "Design"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (customizationLoader.sourceComponent === null) {
                                customizationLoader.source = "Design.qml"
                            }
                        }
                    }
                    Button {
                        id: starttrainingButton
                        text: "Train"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (imagesTextField.length===0 || labelsTextField.length===0) {
                                return
                            }
                            if (starttrainingButton.text==="Train") {
                                starttrainingButton.text = "Stop data preparation"
                                Julia.get_urls_imgs_labels()
                                Julia.empty_progress_channel("Training data preparation")
                                Julia.empty_results_channel("Training data preparation")
                                Julia.empty_progress_channel("Training data preparation modifiers")
                                Julia.empty_progress_channel("Training")
                                Julia.empty_results_channel("Training")
                                Julia.empty_progress_channel("Training modifiers")
                                trainingTimer.max_value = 0
                                trainingTimer.value = 0
                                trainingTimer.done = false
                                trainingTimer.running = true
                                Julia.gc()
                                Julia.prepare_training_data()
                            }
                            else {
                                starttrainingButton.text = "Train"
                                trainingTimer.running = false
                                progressbar.value = 0
                                Julia.put_channel("Training data preparation",["stop"])
                                Julia.put_channel("Training",["stop"])
                            }
                        }
                        Timer {
                            id: trainingTimer
                            interval: 1000; running: false; repeat: true
                            property double step: 0
                            property double value: 0
                            property double max_value: 0
                            property bool done: false
                            onTriggered: {
                                function load_window() {
                                    trainingplotLoader.source = "TrainingPlot.qml"
                                }
                                dataProcessingTimerFunction(starttrainingButton,trainingTimer,
                                    "Train","Stop training","Training data preparation",
                                    "Training",load_window)
                            }
                        }
                    }
                    Button {
                        id: validateButton
                        text: "Validate"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (imagesTextField.length===0 || labelsTextField.length===0) {
                                return
                            }
                            if (validateButton.text==="Validate") {
                                validateButton.text = "Stop data preparation"
                                Julia.get_urls_imgs_labels()
                                Julia.empty_progress_channel("Validation data preparation")
                                Julia.empty_results_channel("Validation data preparation")
                                Julia.empty_progress_channel("Validation data preparation modifiers")
                                Julia.empty_progress_channel("Validation")
                                Julia.empty_results_channel("Validation")
                                Julia.empty_progress_channel("Validation modifiers")
                                validationTimer.max_value = 0
                                validationTimer.value = 0
                                validationTimer.done = false
                                validationTimer.running = true
                                Julia.gc()
                                Julia.prepare_validation_data()
                            }
                            else {
                                validateButton.text = "Validate"
                                validationTimer.running = false
                                progressbar.value = 0
                                Julia.put_channel("Validation data preparation",["stop"])
                                Julia.put_channel("Validation",["stop"])
                            }
                        }
                        Timer {
                            id: validationTimer
                            interval: 1000; running: false; repeat: true
                            property double step: 0
                            property double value: 0
                            property double max_value: 0
                            property bool done: false
                            onTriggered: {
                                function load_window() {
                                    validationplotLoader.source = "ValidationPlot.qml"
                                }
                                dataProcessingTimerFunction(validateButton,validationTimer,
                                    "Validate","Stop validation","Validation data preparation",
                                    "Validation",load_window)
                            }
                        }
                    }
                    ProgressBar {
                        id: progressbar
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        width: buttonWidth
                    }
                }
            }
        }
        function dataProcessingTimerFunction(button,timer,start,stop,
            action,action_done,load_window) {
            var temp = Julia.check_progress(action)
            if (timer.max_value!==0 && !timer.done) {
                var value = Julia.get_progress(action)
                if (timer.value===timer.max_value) {
                    timer.done = true
                    Julia.get_results(action)
                    if (action_done==="Training") {
                        Julia.train()
                    }
                    else if (action_done==="Validation") {
                        Julia.validate()
                    }
                }
                else {
                    if (value!==false) {
                        timer.value += value
                    }
                }
                progressbar.value = timer.value/timer.max_value
            }
            if (timer.done && Julia.check_progress(action_done)!==false) {
                timer.running = false
                button.text = stop
                load_window()
            }
            else {
                value = Julia.get_progress(action)
                if (value===false) { return }
                if (value!==0) {
                    timer.max_value = value
                }
                else {
                    timer.running = false
                    button.text = start
                }
            }
        }
    }
}
