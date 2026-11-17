import QtQuick 2.0;
import calamares.slideshow 1.0;
Presentation {
    id: presentation
    function onActivate() { }
    function onLeave() { }
    Slide {
        Image { anchors.fill: parent; source: "welcome.png"; fillMode: Image.PreserveAspectCrop }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 30
               color: "white"; font.family: "JetBrains Mono"; font.pixelSize: 20
               text: "Installing LinuxSpherso - Wine, Proton, WinBoat and 3 app stores included" }
    }
}
