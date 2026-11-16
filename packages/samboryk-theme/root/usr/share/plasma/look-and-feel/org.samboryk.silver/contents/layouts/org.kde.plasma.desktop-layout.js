// Розкладка Samboryk OS: тонка панель меню зверху й плаваючий док знизу.

function trySet(obj, key, value) {
    try { obj[key] = value; } catch (e) { print("samboryk: не вдалося задати " + key + ": " + e); }
}

// Верхня панель
var top = new Panel;
top.location = "top";
top.height = Math.round(gridUnit * 1.6);
trySet(top, "floating", false);

var menu = top.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "samboryk-menu-symbolic");

top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");

// Док
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
trySet(dock, "lengthMode", "fit");
trySet(dock, "alignment", "center");
trySet(dock, "hiding", "dodgewindows");
trySet(dock, "floating", true);

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:firefox_firefox.desktop",
    "applications:org.kde.kmail2.desktop",
    "applications:org.kde.elisa.desktop",
    "applications:org.kde.gwenview.desktop",
    "applications:org.kde.kate.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:steam.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop"
]);
tasks.writeConfig("groupingStrategy", 1);
tasks.writeConfig("showOnlyCurrentDesktop", false);

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");

// Шпалери
var all = desktops();
for (var i = 0; i < all.length; i++) {
    all[i].wallpaperPlugin = "org.kde.image";
    all[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    all[i].writeConfig("Image", "file:///usr/share/wallpapers/SamborykGlass/");
}
