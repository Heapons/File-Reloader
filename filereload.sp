#include <sourcemod>
#include <filewatcher>

ConVar g_cvarPluginEnabled;
ConVar g_cvarWatchConfigs;
ConVar g_cvarWatchPlugins;

FileSystemWatcher g_cfgWatcher;
FileSystemWatcher g_pluginsWatcher;

#define PLUGIN_NAME        "File Reloader"
#define PLUGIN_AUTHOR      "Heapons"
#define PLUGIN_DESC        "Automatically update added/removed/modified cfg and plugin files."
#define PLUGIN_VERSION     "1.0.0"
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
    g_cvarWatchConfigs = CreateConVar("filereload_configs", "1", "Should cfg files be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    g_cvarWatchPlugins = CreateConVar("filereload_plugins", "1", "Should plugins be automatically updated?", FCVAR_REPLICATED, true, 0.0, true, 1.0);

    AutoExecConfig(true, "filereload");

    /* Directory Watchers */
    // Configs
    if (g_cvarWatchConfigs.BoolValue)
    {
        g_cfgWatcher = new FileSystemWatcher("cfg");
        g_cfgWatcher.IncludeSubdirectories = true;
        g_cfgWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED | FSW_NOTIFY_RENAMED;
        g_cfgWatcher.OnModified = OnCfgChanged;
        g_cfgWatcher.OnCreated = OnCfgChanged;
        g_cfgWatcher.OnRenamed = OnCfgRenamed;
    }
    
    // Plugins
    if (g_cvarWatchPlugins.BoolValue)
    {
        g_pluginsWatcher = new FileSystemWatcher("addons/sourcemod/plugins");
        g_pluginsWatcher.IncludeSubdirectories = true;
        g_pluginsWatcher.NotifyFilter = FSW_NOTIFY_MODIFIED | FSW_NOTIFY_CREATED | FSW_NOTIFY_RENAMED | FSW_NOTIFY_DELETED;
        g_pluginsWatcher.OnModified = OnPluginChanged;
        g_pluginsWatcher.OnCreated = OnPluginCreated;
        g_pluginsWatcher.OnRenamed = OnPluginRenamed;
        g_pluginsWatcher.OnDeleted = OnPluginDeleted;
    }
}

public void OnMapStart()
{
    g_cfgWatcher.IsWatching = true;
    g_pluginsWatcher.IsWatching = true;
}

static void OnCfgChanged(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".cfg", false) != -1)
    {
        ServerCommand("exec \"%s\"", path);
        PrintToServer("[%s] exec %s", PLUGIN_NAME, path);
    }
}

static void OnCfgRenamed(FileSystemWatcher fsw, const char[] oldPath, const char[] newPath)
{
    if (StrContains(newPath, ".cfg", false) != -1)
    {
        ServerCommand("exec \"%s\"", newPath);
        PrintToServer("[%s] exec %s", PLUGIN_NAME, newPath);
    }
}

static void OnPluginChanged(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1)
    {
        int idx = StrContains(path, "plugins/") && !StrContains(path, "disabled/");
        char relPath[PLATFORM_MAX_PATH];
        if (idx != -1)
        {
            strcopy(relPath, sizeof(relPath), path[idx]);
        }
        else
        {
            strcopy(relPath, sizeof(relPath), path);
        }
        ServerCommand("sm plugins reload \"%s\"", relPath);
        PrintToServer("[%s] sm plugins reload %s", PLUGIN_NAME, relPath);
    }
}

static void OnPluginCreated(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1)
    {
        int idx = StrContains(path, "plugins/") && !StrContains(path, "disabled/");
        char relPath[PLATFORM_MAX_PATH];
        if (idx != -1)
        {
            strcopy(relPath, sizeof(relPath), path[idx]);
        }
        else
        {
            strcopy(relPath, sizeof(relPath), path);
        }
        ServerCommand("sm plugins load \"%s\"", relPath);
        PrintToServer("[%s] sm plugins load %s", PLUGIN_NAME, relPath);
    }
}

static void OnPluginRenamed(FileSystemWatcher fsw, const char[] oldPath, const char[] newPath)
{
    if (StrContains(newPath, ".smx", false) != -1)
    {
        if (StrContains(newPath, "plugins/disabled/", false) != -1)
        {
            int oldIdx = StrContains(oldPath, "plugins/");
            char oldRelPath[PLATFORM_MAX_PATH];
            if (oldIdx != -1)
            {
                strcopy(oldRelPath, sizeof(oldRelPath), oldPath[oldIdx]);
            }
            else
            {
                strcopy(oldRelPath, sizeof(oldRelPath), oldPath);
            }
            ServerCommand("sm plugins unload \"%s\"", oldRelPath);
            PrintToServer("[%s] sm plugins unload %s", PLUGIN_NAME, oldRelPath);
            return;
        }

        if (StrContains(oldPath, ".smx", false) != -1)
        {
            int oldIdx = StrContains(oldPath, "plugins/");
            char oldRelPath[PLATFORM_MAX_PATH];
            if (oldIdx != -1)
            {
                strcopy(oldRelPath, sizeof(oldRelPath), oldPath[oldIdx]);
            }
            else
            {
                strcopy(oldRelPath, sizeof(oldRelPath), oldPath);
            }
            ServerCommand("sm plugins unload \"%s\"", oldRelPath);
            PrintToServer("[File Reloader] sm plugins unload %s", oldRelPath);
        }

        int newIdx = StrContains(newPath, "plugins/");
        char newRelPath[PLATFORM_MAX_PATH];
        if (newIdx != -1)
        {
            strcopy(newRelPath, sizeof(newRelPath), newPath[newIdx]);
        }
        else
        {
            strcopy(newRelPath, sizeof(newRelPath), newPath);
        }
        ServerCommand("sm plugins load \"%s\"", newRelPath);
        PrintToServer("[%s] sm plugins load %s", PLUGIN_NAME, newRelPath);
    }
}

static void OnPluginDeleted(FileSystemWatcher fsw, const char[] path)
{
    if (StrContains(path, ".smx", false) != -1)
    {
        int idx = StrContains(path, "plugins/");
        char relPath[PLATFORM_MAX_PATH];
        if (idx != -1)
        {
            strcopy(relPath, sizeof(relPath), path[idx]);
        }
        else
        {
            strcopy(relPath, sizeof(relPath), path);
        }
        ServerCommand("sm plugins unload \"%s\"", relPath);
        PrintToServer("[%s] sm plugins unload %s", PLUGIN_NAME, relPath);
    }
}
