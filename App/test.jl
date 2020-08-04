using Test
using QML
using Observables

counter = 0
const oldcounter = Observable(0)

function increment_counter()
  global counter, oldcounter
  oldcounter[] = counter
  counter += 1
  folderdialog()
end

function folderdialog()

  function browsefolder(folder)
    folder = QString(folder)
    folder = folder[8:length(folder)]
    println(folder)
  end

  @qmlfunction browsefolder

  load("folderdialog.qml")
  #exec()
end




@qmlfunction increment_counter

# absolute path in case working dir is overridden
qml_file = "gui.qml"

# Load the QML file
load(qml_file)

# Run the application
exec()
