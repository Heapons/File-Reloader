# [ANY] File Reloader
This plugin automatically executes the right commands on your behalf whenever you update your server files.
> [!WARNING]
> Requires [FileWatcher](https://github.com/KitRifty/SM-FileWatcher/releases) extension!

# How to install?
- Go to [GitHub Actions](https://github.com/Heapons/File-Reloader/actions/workflows/compile.yml).
- Click on the latest workflow (with a ✅ next to its name).
- Scroll down to the `Artifacts` section, and download the plugin from there.
> [!NOTE]
> If the latest workflow has expired, click on `Run workflow`.

# Features
## ConVars
|Name|Description|
|-|-|
|`filereload_enabled`|Toggle the plugin.|
|`filereload_configs`|Automatically update cfg files.|
|`filereload_plugins`|Automatically update plugins.|
|`filereload_admins`|Automatically update admin settings.|
|`filereload_translations`|Automatically update translations.|
|`filereload_databases`|Automatically update databases.cfg.|
|`filereload_navmeshes`|Automatically update nav meshes.|
|`filereload_waypoints`|Automatically update waypoints.<br>**⚠** Requires [RCBot2](https://github.com/APGRoboCop/rcbot2)‼</br>|
|`filereload_version`|File Reloader version.|

## Valve Configs
|Action|Executed Command|
|-|-|
|Edit `<filename>.cfg`|`exec <filename>`|

## Plugins
> [!NOTE]
> This also accounts for `addons/sourcemod/plugins/disabled/`.

|Action|Executed Command|
|-|-|
|Overwrite `<filename>.smx`|`sm plugins reload <filename>`|
|Add `<filename>.smx`|`sm plugins load <filename>`|
|Delete `<filename>.smx`<br>Move `<filename>.smx` in `disabled` folder</br>|`sm plugins unload <filename>`|
|Rename/Move `<filename>.smx` |`sm plugins unload <oldpath>`<br>`sm plugins load <newpath>`</br>|

## Admins
|Action|Executed Command|
|-|-|
|Edit `admins.cfg`, `admins_simple.ini`, or `admin_groups.cfg`|`sm_reloadadmins`|
|Edit `adminmenu_*.txt`|`sm plugins reload adminmenu.smx`|

## Translations
|Action|Executed Command|
|-|-|
|Any|`sm_reload_translations`|

## Databases
|Action|Executed Command|
|-|-|
|Edit `databases.cfg`|`sm_reload_databases`|

<<<<<<< HEAD
## Bot Navigations
=======
## Navigation Meshes
>>>>>>> 25627d1a251bba6c3c3dbf86d0198e92d3372a2f
> [!NOTE]
> This will only attempt to reload the current map. Changes to unrelated maps will be ignored.
### Navigation Meshes
|Action|Executed Command|
|-|-|
<<<<<<< HEAD
|Update `<mapname>.nav`|`sm_votemap <mapname>`|
### [RCBot2](https://github.com/APGRoboCop/rcbot2)
|Action|Executed Command|
|-|-|
|Update `<mapname>.rcw`|`sm_votemap <mapname>`|
=======
|Add/Overwrite `<mapname>.nav`|`sm_map <mapname>`|
>>>>>>> 25627d1a251bba6c3c3dbf86d0198e92d3372a2f
