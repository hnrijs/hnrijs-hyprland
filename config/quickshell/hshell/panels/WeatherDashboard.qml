import QtQuick
import qs
import qs.components

Column {
    spacing: 10
    property int cityIndex: 0
    property bool detailed: false
    Row {
        width: parent.width
        spacing: 8
        ActionIcon {
            width: 44
            height: 44
            text: "‹"
            enabled: Preferences.cities.length > 1
            onClicked: parent.parent.cityIndex = (parent.parent.cityIndex + Preferences.cities.length - 1) % Preferences.cities.length
        }
        BodyText {
            width: parent.width - 104
            height: 44
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: Preferences.cities[parent.parent.cityIndex] || "Weather"
        }
        ActionIcon {
            width: 44
            height: 44
            text: "›"
            enabled: Preferences.cities.length > 1
            onClicked: parent.parent.cityIndex = (parent.parent.cityIndex + 1) % Preferences.cities.length
        }
    }
    WeatherCity {
        width: parent.width
        city: Preferences.cities[parent.cityIndex] || Preferences.city
        detailed: parent.detailed
    }
}
