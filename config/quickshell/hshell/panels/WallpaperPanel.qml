import QtQuick
import qs
import qs.components

Item {
    id: root
    implicitHeight: Math.max(130, (width - 20) / 3 * 0.5625 + 16)
    focus: true
    function takeInitialFocus() {
        forceActiveFocus();
    }
    function syncSelection() {
        const selected = WallpaperState.wallpapers.findIndex(w => w.path === WallpaperState.currentPath);
        if (selected >= 0) {
            gallery.currentIndex = selected;
            gallery.positionViewAtIndex(selected, ListView.Contain);
        }
    }
    Component.onCompleted: {
        WallpaperState.refreshWallpapers();
        Qt.callLater(takeInitialFocus);
        syncSelection();
    }
    Connections {
        target: WallpaperState
        function onWallpapersChanged() {
            root.syncSelection();
        }
        function onCurrentPathChanged() {
            root.syncSelection();
        }
    }
    function step(offset) {
        if (!gallery.count)
            return;
        gallery.currentIndex = (gallery.currentIndex + offset + gallery.count) % gallery.count;
        gallery.positionViewAtIndex(gallery.currentIndex, ListView.Contain);
    }
    function applySelection() {
        if (gallery.count)
            WallpaperState.setWallpaper(WallpaperState.wallpapers[gallery.currentIndex].path);
    }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    Keys.onTabPressed: step(1)
    Keys.onBacktabPressed: step(-1)
    Keys.onReturnPressed: applySelection()
    Keys.onEnterPressed: applySelection()
    ListView {
        id: gallery
        objectName: "wallpaperGallery"
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        model: WallpaperState.wallpapers
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: (gallery.width - 20) / 3
            height: gallery.height - 16
            y: gallery.currentIndex === index ? 0 : 10
            Behavior on y {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            radius: 0
            color: "transparent"
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: 0
                source: modelData.url
                sourceSize.width: 420
                sourceSize.height: 260
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: 0
                border.width: gallery.currentIndex === index ? 2 : 0
                border.color: Style.primary
            }
            HoverHandler {
                onHoveredChanged: if (hovered)
                    gallery.currentIndex = index
            }
            TapHandler {
                onTapped: {
                    gallery.currentIndex = index;
                    WallpaperState.setWallpaper(modelData.path);
                    root.takeInitialFocus();
                }
            }
        }
    }
    BodyText {
        anchors.centerIn: parent
        visible: WallpaperState.error !== "" || gallery.count === 0
        text: WallpaperState.error || "No Wallpapers"
    }
}
