
using QML
using Observables

cd("C:\\Users\\a_ill\\Documents\\App")

function browsefolder(folder)
  folder = QString(folder)
  folder = folder[8:length(folder)]
  println(folder)
end

@qmlfunction browsefolder
load("GUI//Main.qml")
exec()
