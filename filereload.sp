#include <sourcemod>
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

char g_mapName[PLATFORM_MAX_PATH];

#define PLUGIN_NAME        "File Reloader"
#define PLUGIN_AUTHOR      "Heapons"
#define PLUGIN_DESC        "Automatically update server files in real-time."
#define PLUGIN_VERSION     "1.0.1"
#define PLUGIN_URL         "https://github.com/Heapons/File-Reloader"

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
    g_cvarPluginEnabled = CreateConVar("filereload_enabled", "1", "Toggle the plugin.", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    HookConVarChange(g_cvarPluginEnabled, OnConVarChange);
    g_cvarWatchConfigs = CreateConVar("filereload_configs", "1", "Should cfg files be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    HookConVarChange(g_cvarWatchConfigs, OnConVarChange);
    g_cvarWatchPlugins = CreateConVar("filereload_plugins", "1", "Should plugins be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    HookConVarChange(g_cvarWatchPlugins, OnConVarChange);
    g_cvarWatchAdmins = CreateConVar("filereload_admins", "1", "Should admin settings be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    HookConVarChange(g_cvarWatchAdmins, OnConVarChange);
    g_cvarWatchTranslations = CreateConVar("filereload_translations", "1", "Should translations be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    HookConVarChange(g_cvarWatchTranslations, OnConVarChange);
    g_cvarWatchDatabases = CreateConVar("filereload_databases", "1", "Should databases.cfg be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    HookConVarChange(g_cvarWatchDatabases, OnConVarChange);
    g_cvarWatchNavMeshes = CreateConVar("filereload_navmeshes", "1", "Should nav meshes be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);
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
    g_navWatcher.OnModified = OnNavMeshUpdated;
    g_navWatcher.OnCreated = OnNavMeshUpdated;
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
        PrintToServer("[%s] exec %s", PLUGIN_NAME, path);
    }
}

static void OnPluginModified(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1 &&
        StrContains(path, "disabled/", false) == -1)
    {
        ServerCommand("sm plugins reload \"%s\"", path);
        PrintToServer("[%s] sm plugins reload %s", PLUGIN_NAME, path);
    }
}

static void OnPluginCreated(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1 &&
        StrContains(path, "disabled/", false) == -1)
    {
        ServerCommand("sm plugins load \"%s\"", path);
        PrintToServer("[%s] sm plugins load %s", PLUGIN_NAME, path);
    }
}

static void OnPluginRenamed(FileSystemWatcher fsw, const char[] oldPath, const char[] newPath)
{
    if (StrContains(newPath, ".smx", false) != -1)
    {
        ServerCommand("sm plugins unload \"%s\"", oldPath);
        PrintToServer("[%s] sm plugins unload %s", PLUGIN_NAME, oldPath);
    }

    if (StrContains(newPath, "disabled/", false) == -1)
    {
        ServerCommand("sm plugins load \"%s\"", newPath);
        PrintToServer("[%s] sm plugins load %s", PLUGIN_NAME, newPath);
    }
}

static void OnPluginDeleted(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1)
    {
        ServerCommand("sm plugins unload \"%s\"", path);
        PrintToServer("[%s] sm plugins unload %s", PLUGIN_NAME, path);
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
        PrintToServer("[%s] sm_reloadadmins", PLUGIN_NAME);
    }

    // Admin Menus
    if (strcmp(path, "adminmenu_") == 0)
    {
        ServerCommand("sm plugins reload adminmenu.smx");
        PrintToServer("[%s] sm plugins reload adminmenu.smx", PLUGIN_NAME);
    }
}

static void OnDatabasesUpdated(FileSystemWatcher fsw, const char[] path)
{
    if (strcmp(path, "databases.cfg", false) == 0)
    {
        ServerCommand("sm_reload_databases");
        PrintToServer("[%s] sm_reload_databases", PLUGIN_NAME);
    }
}

static void OnTranslationsUpdated(FileSystemWatcher fsw, const char[] path)
{
    ServerCommand("sm_reload_translations");
    PrintToServer("[%s] sm_reload_translations", PLUGIN_NAME);
}

static void OnTranslationsRenamed(FileSystemWatcher fsw, const char[] oldPath, const char[] newPath)
{
    OnTranslationsUpdated(fsw, newPath);
}

static void OnNavMeshUpdated(FileSystemWatcher fsw, const char[] path)
{
    GetCurrentMap(g_mapName, sizeof(g_mapName));
    char navFile[PLATFORM_MAX_PATH];
    Format(navFile, sizeof(navFile), "%s.nav", g_mapName);
    if (StrContains(path, navFile, false) != -1)
    {
        ServerCommand("sm_map %s", g_mapName);
        PrintToServer("[%s] sm_map %s", PLUGIN_NAME, g_mapName);
    }
}