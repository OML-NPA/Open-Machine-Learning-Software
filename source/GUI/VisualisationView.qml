import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0

Component {
    GridLayout {
        id: gridLayout
        JuliaDisplay {
            id: jdisp
            width: 512*pix
            height: 512*pix
        }
        Component.onCompleted: {
            function listProperty(item)
            {
                for (var p in item)
                console.log(p + ": " + item[p]);
            }
            console.log( listProperty(jdisp))

        }

    }
}


