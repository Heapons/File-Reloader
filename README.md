# [ANY] File Reloader
This plugin automatically executes the right commands on your behalf whenever you update your server files.
> [!WARNING]
> Requires [FileWatcher](https://github.com/KitRifty/SM-FileWatcher/releases) extension!

## How to install?
- Go to [GitHub Actions](https://github.com/Heapons/File-Reloader/actions/workflows/compile.yml).
- Click on the latest workflow (with a ✅ next to its name).
- Scroll down to the `Artifacts` section, and download the plugin from there.
> [!NOTE]
> If the latest workflow has expired, click on `Run workflow`.

## Features
### ConVars
|Name|Description|
|-|-|
|`filereload_enabled`|Toggle the plugin.|
|`filereload_configs`|Should cfg files be automatically updated?|
|`filereload_plugins`|Should plugins be automatically updated?|
|`filereload_admins`|Should admin settings be automatically updated?|
|`filereload_translations`|Should translations be automatically updated?|
|`filereload_databases`|Should databases.cfg be automatically updated?|
|`filereload_navmeshes`|Should nav meshes be automatically updated?|
|`filereload_version`|File Reloader version.|

### Valve Configs
|Action|Executed Command|
|-|-|
|Update `<filename>.cfg`|`exec <filename>`|

### Plugins
> [!NOTE]
> This also accounts for `addons/sourcemod/plugins/disabled/`.

|Action|Executed Command|
|-|-|
|Overwrite `<filename>.smx`|`sm plugins reload <filename>`|
|Add `<filename>.smx`|`sm plugins load <filename>`|
|Delete `<filename>.smx`<br>Move `<filename>.smx` in `disabled` folder</br>|`sm plugins unload <filename>`|
|Rename/Move `<filename>.smx` |`sm plugins unload <oldpath>`<br>`sm plugins load <newpath>`</br>|

### Admins
|Action|Executed Command|
|-|-|
|Update `admins.cfg`, `admins_simple.ini`, or `admin_groups.cfg`|`sm_reloadadmins`|
|Update `adminmenu_*.txt`|`sm plugins reload adminmenu.smx`|

### Translations
|Action|Executed Command|
|-|-|
|Any|`sm_reload_translations`|

### Databases
|Action|Executed Command|
|-|-|
|Update `databases.cfg`|`sm_reload_databases`|

### Navigation Meshes
> [!NOTE]
> This will only attempt to reload the current map. Changes to unrelated maps will be ignored.

|Action|Executed Command|
|-|-|
|Add/Overwrite `<mapname>.nav`|`sm_map <mapname>`|