
using QML
using Observables

cd("C:\\Users\\a_ill\\Documents\\GitHub\\Deep-Image-Analysis\\source")

function returnfolder(folder)
  folder = QString(folder)
  folder = folder[8:length(folder)]
  return (folder)
end

@qmlfunction returnfolder
load("GUI//Main.qml")
exec()
