// ===== LinuxSpherso layout: advanced glass top bar + floating dock =====
var wall = "file:///usr/share/wallpapers/LinuxSphere/contents/images/3840x2160.png";
desktopsArray = desktops();
for (var i = 0; i < desktopsArray.length; i++) {
    var d = desktopsArray[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", wall);
    d.writeConfig("FillMode", "2");
}

// ---------- TOP BAR ----------
var top = new Panel;
top.location = "top";
top.height = 32;
top.floating = true;
top.opacity = "translucent";   // glass/blur
top.lengthMode = "fill";

var dash = top.addWidget("org.kde.plasma.kickerdash");   // full-screen "Sphere Launchpad"
dash.currentConfigGroup = ["General"];
dash.writeConfig("icon", "linuxsphere-start");
top.addWidget("org.kde.plasma.appmenu");                  // global menu of focused app
top.addWidget("org.kde.plasma.panelspacer");
var clock = top.addWidget("org.kde.plasma.digitalclock"); // centered clock + calendar
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("dateDisplayFormat", "BesideTime");
top.addWidget("org.kde.plasma.panelspacer");
// live system monitors
var cpu = top.addWidget("org.kde.plasma.systemmonitor.cpucore");
var mem = top.addWidget("org.kde.plasma.systemmonitor.memory");
var net = top.addWidget("org.kde.plasma.systemmonitor.net");
top.addWidget("org.kde.plasma.pager");                    // virtual desktops
top.addWidget("org.kde.plasma.systemtray");               // wifi, sound, bluetooth, battery...
top.addWidget("org.kde.plasma.notifications");
top.addWidget("org.kde.plasma.userswitcher");
var lo = top.addWidget("org.kde.plasma.lock_logout");

// ---------- FLOATING DOCK TASKBAR ----------
var dock = new Panel;
dock.location = "bottom";
dock.height = 56;
dock.floating = true;
dock.lengthMode = "fit";       // shrinks to fit icons, centered like a dock
dock.alignment = "center";
dock.hiding = "dodgewindows";  // slides away when a window touches it
dock.opacity = "translucent";

// Favourites come from /usr/local/bin/linuxsphere-kickoff-defaults (Kickoff reads them
// as soon as it is created, before this script can set them).
var menu = dock.addWidget("org.kde.plasma.kickoff");      // the Sphere start menu
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "linuxsphere-start");
menu.writeConfig("favoritesDisplay", "0");   // grid
menu.writeConfig("applicationsDisplay", "0");
menu.writeConfig("switchCategoryOnHover", "true");
dock.addWidget("org.kde.plasma.marginsseparator");

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", ["preferred://browser", "applications:org.kde.dolphin.desktop", "applications:org.kde.konsole.desktop", "applications:winboat.desktop", "applications:steam.desktop", "applications:mintinstall.desktop", "applications:org.kde.discover.desktop", "applications:systemsettings.desktop"]);
tasks.writeConfig("iconSpacing", "2");
tasks.writeConfig("indicateAudioStreams", "true");
tasks.writeConfig("maxStripes", "1");
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
