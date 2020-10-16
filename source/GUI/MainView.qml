
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
//import org.julialang 1.0

Component {
    ColumnLayout {
        id: gridLayout
        property double margin: 0.02*Screen.width
        property double pix: Screen.width/3840
        property double buttonWidth: 0.1*Screen.width
        property double buttonHeight: 0.03*Screen.height

    }
}
