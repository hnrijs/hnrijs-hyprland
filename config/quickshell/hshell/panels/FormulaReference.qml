import QtQuick
import qs
import qs.components

Column {
    id: root
    spacing: 8
    signal useFormula(string value)
    property var selectedFormula: []
    property var formulas: [["Percentage", "part ÷ total × 100", "25 / 200 * 100"], ["Percentage Change", "(new − old) ÷ old × 100", "(120 - 100) / 100 * 100"], ["Speed", "distance ÷ time", "100 km / (2 h) to km/h"], ["Circle Area", "π × radius²", "pi * (5 cm)^2 to cm^2"], ["Circle Circumference", "2 × π × radius", "2 * pi * 5 cm"], ["Triangle Area", "base × height ÷ 2", "8 cm * 5 cm / 2"], ["Pythagoras", "√(a² + b²)", "sqrt((3 m)^2 + (4 m)^2)"], ["Sphere Volume", "4 × π × radius³ ÷ 3", "4 / 3 * pi * (5 cm)^3 to cm^3"], ["Electrical Power", "voltage × current", "230 V * 2 A to W"], ["Ohm’s Law", "voltage = current × resistance", "2 A * 10 ohm to V"], ["Energy", "power × time", "2 kW * 3 h to kWh"], ["Energy Cost", "energy × price per kWh", "6 kWh * (0.20 EUR / kWh)"], ["Force", "mass × acceleration", "5 kg * 9.81 m/s^2 to N"], ["Density", "mass ÷ volume", "10 kg / (2 l) to kg/m^3"], ["Kinetic Energy", "mass × speed² ÷ 2", "80 kg * (5 m/s)^2 / 2 to J"], ["Mean", "sum ÷ count", "(4 + 8 + 12) / 3"]]
    Repeater {
        model: root.formulas
        delegate: PillButton {
            required property var modelData
            width: parent.width
            height: 62
            text: modelData[0]
            detail: modelData[1]
            onClicked: root.selectedFormula = modelData
        }
    }
    BodyText {
        width: parent.width
        visible: root.selectedFormula.length > 0
        text: (root.selectedFormula[0] || "") + "\n" + (root.selectedFormula[1] || "") + "\nExample: " + (root.selectedFormula[2] || "")
        textFormat: Text.PlainText
    }
    PillButton {
        width: parent.width
        visible: root.selectedFormula.length > 0
        text: "Use Example"
        onClicked: root.useFormula(root.selectedFormula[2])
    }
}
