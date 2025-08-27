#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <filewatcher>

ConVar            g_cvarPluginEnabled,
                  g_cvarWatchConfigs,
                  g_cvarWatchPlugins,
                  g_cvarWatchAdmins,
                  g_cvarWatchTranslations,
                  g_cvarWatchDatabases,
                  g_cvarWatchNavMeshes;

FileSystemWatcher g_cfgWatcher,
                  g_pluginsWatcher,
                  g_adminsWatcher,
                  g_databasesWatcher,
                  g_translationsWatcher,
                  g_navWatcher;

char g_mapName[PLATFORM_MAX_PATH],
     g_navFile[PLATFORM_MAX_PATH];

bool isMapReloading;

#define PLUGIN_NAME        "File Reloader"
#define PLUGIN_AUTHOR      "Heapons"
#define PLUGIN_DESC        "Automatically update server files in real-time."
#define PLUGIN_VERSION     "1.0.2"
#define PLUGIN_URL         "https://github.com/Heapons/File-Reloader"
#define PLUGIN_COLOR       "{#FD9E23}"

public Plugin myinfo = 
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public void OnPluginStart()
{
    /* ConVars */
    g_cvarPluginEnabled = CreateConVar("filereload_enabled", "1", "Toggle the plugin.", FCVAR_REPLICATED);
    HookConVarChange(g_cvarPluginEnabled, OnConVarChange);
    g_cvarWatchConfigs = CreateConVar("filereload_configs", "1", "Automatically update cfg files.", FCVAR_REPLICATED);
    HookConVarChange(g_cvarWatchConfigs, OnConVarChange);
    g_cvarWatchPlugins = CreateConVar("filereload_plugins", "1", "Automatically update plugins.", FCVAR_REPLICATED);
    HookConVarChange(g_cvarWatchPlugins, OnConVarChange);
    g_cvarWatchAdmins = CreateConVar("filereload_admins", "1", "Automatically update admin settings.", FCVAR_REPLICATED);
    HookConVarChange(g_cvarWatchAdmins, OnConVarChange);
    g_cvarWatchTranslations = CreateConVar("filereload_translations", "1", "Automatically update translations.", FCVAR_REPLICATED);
    HookConVarChange(g_cvarWatchTranslations, OnConVarChange);
    g_cvarWatchDatabases = CreateConVar("filereload_databases", "1", "Automatically update databases.cfg.", FCVAR_REPLICATED);
    HookConVarChange(g_cvarWatchDatabases, OnConVarChange);
    g_cvarWatchNavMeshes = CreateConVar("filereload_navmeshes", "1", "Automatically update nav meshes.", FCVAR_REPLICATED);
    HookConVarChange(g_cvarWatchNavMeshes, OnConVarChange);

    AutoExecConfig(true, "filereload");

    CreateConVar("filereload_version", PLUGIN_VERSION, "File Reloader version.", FCVAR_NOTIFY);

    /* Directory Watchers */
    // Valve Configs
    g_cfgWatcher = new FileSystemWatcher("cfg");
    g_cfgWatcher.IncludeSubdirectories = true;
    g_cfgWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED | FSW_NOTIFY_RENAMED;
    g_cfgWatcher.OnModified = OnCfgModified;

    // Plugins
    g_pluginsWatcher = new FileSystemWatcher("addons/sourcemod/plugins");
    g_pluginsWatcher.IncludeSubdirectories = true;
    g_pluginsWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED | FSW_NOTIFY_RENAMED | FSW_NOTIFY_DELETED;
    g_pluginsWatcher.OnModified = OnPluginModified;
    g_pluginsWatcher.OnCreated = OnPluginCreated;
    g_pluginsWatcher.OnRenamed = OnPluginRenamed;
    g_pluginsWatcher.OnDeleted = OnPluginDeleted;

    // Admins
    g_adminsWatcher = new FileSystemWatcher("addons/sourcemod/configs");
    g_adminsWatcher.IncludeSubdirectories = false;
    g_adminsWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED;
    g_adminsWatcher.OnModified = OnAdminsUpdated;
    g_adminsWatcher.OnCreated = OnAdminsUpdated;

    // Databases
    g_databasesWatcher = new FileSystemWatcher("addons/sourcemod/configs");
    g_databasesWatcher.IncludeSubdirectories = false;
    g_databasesWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED;
    g_databasesWatcher.OnModified = OnDatabasesUpdated;
    g_databasesWatcher.OnCreated = OnDatabasesUpdated;

    // Translations
    g_translationsWatcher = new FileSystemWatcher("addons/sourcemod/translations");
    g_translationsWatcher.IncludeSubdirectories = true;
    g_translationsWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED | FSW_NOTIFY_RENAMED | FSW_NOTIFY_DELETED;
    g_translationsWatcher.OnModified = OnTranslationsUpdated;
    g_translationsWatcher.OnCreated = OnTranslationsUpdated;
    g_translationsWatcher.OnRenamed = OnTranslationsRenamed;
    g_translationsWatcher.OnDeleted = OnTranslationsUpdated;

    // Navigation Meshes
    g_navWatcher = new FileSystemWatcher("maps");
    g_navWatcher.IncludeSubdirectories = false;
    g_navWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED;
    g_navWatcher.OnModified = OnNavMeshModified;
    g_navWatcher.OnCreated = OnNavMeshCreated;
}

public void OnConfigsExecuted()
{
    g_cfgWatcher.IsWatching = g_cvarWatchConfigs.BoolValue && g_cvarPluginEnabled.BoolValue;

    g_pluginsWatcher.IsWatching = g_cvarWatchPlugins.BoolValue && g_cvarPluginEnabled.BoolValue;

    g_adminsWatcher.IsWatching = g_cvarWatchAdmins.BoolValue && g_cvarPluginEnabled.BoolValue;

    g_databasesWatcher.IsWatching = g_cvarWatchDatabases.BoolValue && g_cvarPluginEnabled.BoolValue;

    g_translationsWatcher.IsWatching = g_cvarWatchTranslations.BoolValue && g_cvarPluginEnabled.BoolValue;

    g_navWatcher.IsWatching = g_cvarWatchNavMeshes.BoolValue && g_cvarPluginEnabled.BoolValue;
}

static void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

static void OnCfgModified(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".cfg", false) != -1)
    {
        ServerCommand("exec \"%s\"", path);
        CPrintToAdmins("[%s%s{default}] Executed {green}%s{default}!", PLUGIN_COLOR, PLUGIN_NAME, path);
    }
}

static void OnPluginModified(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1 &&
        StrContains(path, "disabled/", false) == -1)
    {
        ServerCommand("sm plugins reload \"%s\"", path);
        CPrintToAdmins("[%s%s{default}] Reloaded {green}%s{default}!", PLUGIN_COLOR, PLUGIN_NAME, path);
    }
}

static void OnPluginCreated(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1 &&
        StrContains(path, "disabled/", false) == -1)
    {
        ServerCommand("sm plugins load \"%s\"", path);
        CPrintToAdmins("[%s%s{default}] Loaded {green}%s{default}!", PLUGIN_COLOR, PLUGIN_NAME, path);
    }
}

static void OnPluginRenamed(FileSystemWatcher fsw, const char[] oldPath, const char[] newPath)
{
    if (StrContains(newPath, ".smx", false) != -1)
    {
        ServerCommand("sm plugins unload \"%s\"", oldPath);
        CPrintToAdmins("[%s%s{default}] Unloaded {green}%s{default}!", PLUGIN_COLOR, PLUGIN_NAME, oldPath);
    }

    if (StrContains(newPath, "disabled/", false) == -1)
    {
        ServerCommand("sm plugins load \"%s\"", newPath);
        CPrintToAdmins("[%s%s{default}] Loaded {green}%s{default}!", PLUGIN_COLOR, PLUGIN_NAME, newPath);
    }
}

static void OnPluginDeleted(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1)
    {
        ServerCommand("sm plugins unload \"%s\"", path);
        CPrintToAdmins("[%s%s{default}] Unloaded {green}%s{default}!", PLUGIN_COLOR, PLUGIN_NAME, path);
    }
}

static void OnAdminsUpdated(FileSystemWatcher fsw, const char[] path)
{
    // Admin Roles
    if (strcmp(path, "admin_groups.cfg") == 0 ||
        strcmp(path, "admins.cfg") == 0 ||
        strcmp(path, "admins_simple.ini") == 0)
    {
        ServerCommand("sm_reloadadmins");
        CPrintToAdmins("[%s%s{default}] Reloaded admins!", PLUGIN_COLOR, PLUGIN_NAME);
    }

    // Admin Menus
    if (strcmp(path, "adminmenu_") == 0)
    {
        ServerCommand("sm plugins reload adminmenu.smx");
        CPrintToAdmins("[%s%s{default}] Reloaded admin menus!", PLUGIN_COLOR, PLUGIN_NAME);
    }
}

static void OnDatabasesUpdated(FileSystemWatcher fsw, const char[] path)
{
    if (strcmp(path, "databases.cfg", false) == 0)
    {
        ServerCommand("sm_reload_databases");
        CPrintToAdmins("[%s%s{default}] Reloaded {green}databases.cfg{default}!", PLUGIN_COLOR, PLUGIN_NAME);
    }
}

static void OnTranslationsUpdated(FileSystemWatcher fsw, const char[] path)
{
    ServerCommand("sm_reload_translations");
    CPrintToAdmins("[%s%s{default}] Reloaded phrases!", PLUGIN_COLOR, PLUGIN_NAME);
}

static void OnTranslationsRenamed(FileSystemWatcher fsw, const char[] oldPath, const char[] newPath)
{
    OnTranslationsUpdated(fsw, newPath);
}

static void OnNavMeshModified(FileSystemWatcher fsw, const char[] path)
{
    GetCurrentMap(g_mapName, sizeof(g_mapName));
    Format(g_navFile, sizeof(g_navFile), "%s.nav", g_mapName);

    if (StrContains(path, g_navFile, false) != -1)
    {
        ReloadMap(g_mapName, true);
        isMapReloading = true;
    }
}

static void OnNavMeshCreated(FileSystemWatcher fsw, const char[] path)
{
    GetCurrentMap(g_mapName, sizeof(g_mapName));
    Format(g_navFile, sizeof(g_navFile), "%s.nav", g_mapName);

    if (StrContains(path, g_navFile, false) != -1)
    {
        ReloadMap(g_mapName);
        isMapReloading = true;
    }
}

/**
 * Reload the map forcefully or via a vote.
 * 
 * @param mapName  Name of the map
 * @param callvote Whether to call a vote or not (i.e. forcefully)
 */
stock void ReloadMap(const char[] mapName, bool callvote=false)
{
    if (isMapReloading) return;
    ServerCommand("sm_%s %s", callvote ? "votemap" : "map", mapName);
    CPrintToAdmins("[%s%s{default}] The nav meshes have been updated. Reload map%s", PLUGIN_COLOR, PLUGIN_NAME, callvote ? "?" : "...");
}

/**
 * Prints a colored message to all admins in the chat area.
 *
 * @param format        Formatting rules.
 * @param ...           Variable number of format parameters.
 */
stock void CPrintToAdmins(const char[] format, any ...)
{
    PrecacheSound("ui/cyoa_map_open.wav");

	char buffer[254];

	for (int i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && GetUserFlagBits(i) != 0)
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			CPrintToChat(i, "%s", buffer);
            EmitSoundToClient(i, "ui/cyoa_map_open.wav");
		}
	}
}