import QtQuick
import QtQuick.Controls
import qs
import qs.components

Column {
    id: root
    required property string city
    property bool detailed: false
    property int forecastIndex: 0
    readonly property var chosen: (weather.result.forecast || [])[forecastIndex] || {}
    property string requestedCity: ""
    function refresh() {
        if (!weather.running) {
            requestedCity = city;
            weather.start(["weather", city]);
        }
    }
    onCityChanged: refresh()
    function symbol(description) {
        const value = description.toLowerCase();
        return value.includes("thunder") ? "󰙾" : value.includes("snow") ? "󰖘" : value.includes("rain") || value.includes("drizzle") ? "󰖗" : value.includes("cloud") || value.includes("overcast") ? "󰖐" : value.includes("fog") || value.includes("mist") ? "󰖑" : "󰖙";
    }
    spacing: 10
    Task {
        id: weather
        onFinished: success => {
            if (root.requestedCity !== root.city)
                Qt.callLater(root.refresh);
        }
    }
    Component.onCompleted: refresh()
    Row {
        width: parent.width
        spacing: 12
        BodyText {
            width: parent.width - 72
            text: weather.result.temperature !== undefined ? weather.result.temperature + "°" : "—"
            font.pixelSize: root.detailed ? 52 : 28
        }
        BodyText {
            width: 60
            height: root.detailed ? 64 : 40
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.iconFontFamily
            font.pixelSize: root.detailed ? 36 : 24
            text: root.symbol(weather.result.description || "")
        }
    }
    BodyText {
        width: parent.width
        text: weather.running && !weather.result.description ? "Loading weather…" : weather.result.description || ""
        font.pixelSize: 16
    }
    BodyText {
        width: parent.width
        text: weather.result.feels !== undefined ? "Feels " + weather.result.feels + " °C  ·  Wind " + weather.result.wind + " km/h" : ""
        color: Style.muted
        font.pixelSize: 12
    }
    Repeater {
        model: root.detailed || !Preferences.option("detailedWeather", true) ? [] : weather.result.forecast || []
        Column {
            required property var modelData
            width: parent.width
            spacing: 8
            Row {
                width: parent.width
                BodyText {
                    width: parent.width * 0.45
                    height: 30
                    verticalAlignment: Text.AlignVCenter
                    text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd, d")
                    font.pixelSize: 14
                }
                BodyText {
                    width: parent.width * 0.55
                    height: 30
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: modelData.min + "°  /  " + modelData.max + "°"
                    font.pixelSize: 14
                }
            }
        }
    }
    Row {
        width: parent.width
        spacing: 10
        visible: root.detailed
        Repeater {
            model: root.detailed ? weather.result.forecast || [] : []
            Rectangle {
                required property var modelData
                required property int index
                width: (root.width - 20) / 3
                height: 76
                radius: 16
                color: "transparent"
                border.width: root.forecastIndex === index ? 1 : 0
                border.color: Style.muted
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    BodyText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd, d MMM")
                        font.pixelSize: 14
                    }
                    BodyText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.min + "°  /  " + modelData.max + "°"
                        font.pixelSize: 18
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.forecastIndex = index
                }
            }
        }
    }
    Flickable {
        width: parent.width
        height: root.detailed ? 120 : 0
        visible: root.detailed
        contentWidth: hours.width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Row {
            id: hours
            spacing: 8
            Repeater {
                model: root.detailed ? root.chosen.hours || [] : []
                Column {
                    required property var modelData
                    width: 100
                    spacing: 8
                    BodyText {
                        width: parent.width
                        text: modelData.time
                        horizontalAlignment: Text.AlignHCenter
                        color: Style.muted
                        font.pixelSize: 12
                    }
                    BodyText {
                        width: parent.width
                        text: root.symbol(modelData.description || "")
                        font.family: Style.iconFontFamily
                        font.pixelSize: 22
                        horizontalAlignment: Text.AlignHCenter
                    }
                    BodyText {
                        width: parent.width
                        text: modelData.temperature + "°"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                    }
                    BodyText {
                        width: parent.width
                        text: modelData.rain + "% rain"
                        color: Style.muted
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
    BodyText {
        visible: root.detailed
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "Sunrise " + (root.chosen.sunrise || "—") + "   ·   Sunset " + (root.chosen.sunset || "—") + "   ·   Humidity " + (weather.result.humidity || "—") + "%"
        color: Style.muted
        font.pixelSize: 13
    }
    BodyText {
        width: parent.width
        visible: Preferences.option("detailedWeather", true) && !!weather.result.fetched
        text: "Updated " + Qt.formatDateTime(new Date((weather.result.fetched || 0) * 1000), "HH:mm") + " · wttr.in"
        color: Style.muted
        font.pixelSize: 11
    }
    TaskStatus {
        width: parent.width
        task: weather
    }
}
