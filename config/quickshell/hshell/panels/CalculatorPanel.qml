import QtQuick
import Quickshell
import qs
import qs.components

Column {
    id: root
    spacing: 12
    property string submitted: ""
    property bool showFormulas: false
    property var groups: [
        {
            name: "Length",
            units: ["mm", "cm", "dm", "m", "km", "nm", "um", "in", "ft", "yd", "mi", "ly", "au", "pc"]
        },
        {
            name: "Speed",
            units: ["m/s", "km/h", "mph", "knots"]
        },
        {
            name: "Pressure",
            units: ["psi", "bar", "Pa", "kPa", "MPa", "atm"]
        },
        {
            name: "Power",
            units: ["W", "kW", "MW", "hp"]
        },
        {
            name: "Energy",
            units: ["J", "kJ", "Wh", "kWh", "cal", "kcal"]
        },
        {
            name: "Mass",
            units: ["mg", "g", "kg", "lb", "oz"]
        },
        {
            name: "Temperature",
            units: ["°C", "°F", "K"]
        },
        {
            name: "Volume",
            units: ["ml", "l", "m^3", "gal"]
        },
        {
            name: "Area",
            units: ["mm^2", "cm^2", "m^2", "ha", "km^2", "ft^2"]
        },
        {
            name: "Time",
            units: ["ns", "us", "ms", "s", "min", "h", "day", "week", "month", "year", "decade", "century", "millennium"]
        },
        {
            name: "Data",
            units: ["bit", "byte", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"]
        },
        {
            name: "Currency",
            units: ["USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "PLN", "AED", "ALL", "AMD", "ARS", "AZN", "BAM", "BDT", "BHD", "BOB", "BRL", "BWP", "CLP", "CNY", "COP", "CRC", "CZK", "DKK", "DOP", "DZD", "EGP", "GEL", "GHS", "GTQ", "HKD", "HNL", "HUF", "IDR", "ILS", "INR", "ISK", "JMD", "JOD", "KES", "KRW", "KWD", "KZT", "LKR", "MAD", "MDL", "MKD", "MUR", "MXN", "MYR", "NAD", "NGN", "NOK", "NPR", "NZD", "OMR", "PEN", "PHP", "PKR", "QAR", "RON", "RSD", "SAR", "SEK", "SGD", "THB", "TND", "TRY", "TWD", "TZS", "UAH", "UGX", "UYU", "UZS", "VND", "XAF", "XCD", "XOF", "XPF", "ZAR", "ZMW"]
        }
    ]
    function evaluate(value, refresh) {
        if (calc.running)
            return;
        submitted = value;
        calc.start(["calculate", value, refresh ? "refresh" : "cached"]);
    }
    Task {
        id: calc
    }
    Row {
        width: parent.width
        spacing: 8
        Field {
            id: expression
            width: parent.width - 104
            placeholderText: "Expression or Conversion"
            onAccepted: root.evaluate(text, false)
        }
        PillButton {
            width: 44
            text: "ƒ"
            selected: root.showFormulas
            Accessible.name: "Formulas"
            onClicked: root.showFormulas = !root.showFormulas
        }
        PillButton {
            width: 44
            text: "="
            enabled: !calc.running
            onClicked: root.evaluate(expression.text, false)
        }
    }
    FormulaReference {
        visible: root.showFormulas
        width: parent.width
        onUseFormula: value => expression.text = value
    }
    Rectangle {
        width: parent.width
        height: Math.max(64, answer.implicitHeight + 24)
        radius: 18
        color: Style.bg1
        BodyText {
            id: answer
            x: 12
            y: 12
            width: parent.width - 24
            font.pixelSize: 22
            text: calc.result.text || "0"
        }
        TapHandler {
            onTapped: Quickshell.execDetached(["wl-copy", "--", calc.result.text || "0"])
        }
    }
    BodyText {
        text: "Unit Converter"
    }
    Choice {
        id: category
        width: parent.width
        model: root.groups.map(g => g.name)
        onCurrentIndexChanged: {
            fromUnit.currentIndex = 0;
            toUnit.currentIndex = 1;
        }
    }
    Field {
        id: amount
        width: parent.width
        text: "1"
        placeholderText: "Amount or Expression"
    }
    Row {
        width: parent.width
        spacing: 8
        Choice {
            id: fromUnit
            searchable: category.currentText === "Currency"
            width: (parent.width - 60) / 2
            model: root.groups[category.currentIndex].units
        }
        PillButton {
            width: 44
            text: "⇄"
            onClicked: {
                const old = fromUnit.currentIndex;
                fromUnit.currentIndex = toUnit.currentIndex;
                toUnit.currentIndex = old;
            }
        }
        Choice {
            id: toUnit
            searchable: category.currentText === "Currency"
            width: (parent.width - 60) / 2
            model: root.groups[category.currentIndex].units
            currentIndex: 1
        }
    }
    PillButton {
        width: parent.width
        text: "Convert"
        enabled: !calc.running
        onClicked: root.evaluate("(" + amount.text + ") " + fromUnit.currentText + " to " + toUnit.currentText, false)
    }
    Row {
        width: parent.width
        spacing: 8
        visible: category.currentText === "Currency"
        PillButton {
            width: 180
            text: "Refresh Rates"
            enabled: !calc.running
            onClicked: root.evaluate("1 USD to EUR", true)
        }
        BodyText {
            width: parent.width - 188
            text: calc.result.ratesDate || "Cached Rates — Refresh for Recent Rates"
            font.pixelSize: 12
        }
    }
    TaskStatus {
        width: parent.width
        task: calc
    }
    BodyText {
        width: parent.width
        visible: !!calc.result.warning
        text: calc.result.warning || ""
        color: Style.muted
    }
    Row {
        width: parent.width
        PillButton {
            width: 44
            text: "󰆏"
            onClicked: Quickshell.execDetached(["wl-copy", "--", calc.result.text || "0"])
        }
        Item {
            width: parent.width - 88
            height: 44
        }
        PillButton {
            width: 44
            text: "󰃢"
            enabled: !calc.running
            onClicked: {
                calc.result = ({});
                expression.clear();
            }
        }
    }
}
