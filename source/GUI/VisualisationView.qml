import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0

Component {
    Column {
        /*Slider {
            from: 10
            to: 640
            value: 200
            width: 500
            onValueChanged: {
                parameters.diameter = value
                circle_canvas.update()
            }
        }*/
        JuliaCanvas {
            id: circle_canvas
            paintFunction: display_image
            width: 500
            height: 500
            Component.onCompleted: circle_canvas.update()
        }
    }
}


