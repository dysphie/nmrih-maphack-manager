#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

#define CVAR_MAXLEN 64
#define PLUGIN_PREFIX "[MaphackManager]"

Handle activeMaphacks;
ConVar pluginDirectory;
ConVar overrideNative;
ConVar svMaphacks;

char maphackLibrary[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name 		= "Advanced Maphack Manager",
	author 		= "Dysphie",
	description = "A maphack management alternative with support for multiple files and folders.",
	version 	= "0.1",
	url 		= ""
};

public void OnPluginStart()
{
	pluginDirectory = CreateConVar("sm_maphack_manager_library", "configs/maphack-manager", "Directory to scan for maphacks");
	pluginDirectory.AddChangeHook(OnPluginDirectoryChange);

	overrideNative 	= CreateConVar("sm_maphack_manager_override", "1", "Disable native maphack system");
	svMaphacks 		= FindConVar("sv_maphack");
	
	if (svMaphacks != null)
		svMaphacks.AddChangeHook(OnSvMaphacksChange);
	else
		SetFailState("%s Unsupported game version. Must be 1.10.0 or higher.", PLUGIN_PREFIX);

	activeMaphacks = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH)); 
	HookEvent("nmrih_reset_map", OnMapReset, EventHookMode_PostNoCopy);

	char directory[PLATFORM_MAX_PATH];
	GetConVarString(pluginDirectory, directory, sizeof(directory));
	BuildPath(Path_SM, maphackLibrary, sizeof(maphackLibrary), "%s", directory);
	
	if(!DirExists(maphackLibrary))
		CreateDirectory(maphackLibrary, 511);  
}
 
public void OnSvMaphacksChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if(overrideNative.BoolValue && StringToInt(newValue) == 0)
	{
		convar.IntValue = 0;
		char convarName[PLATFORM_MAX_PATH];
		GetConVarName(overrideNative, convarName, sizeof(convarName));
		PrintToServer("%s Can't set sv_maphack to 1, unless the server has %s set to 0.", PLUGIN_PREFIX, convarName);
	}
}

public void OnPluginDirectoryChange(ConVar convar, char[] oldValue, char[] newValue)
{
	ClearArray(activeMaphacks);
	PrintToServer("%s Path to maphack library changed, re-scanning...", PLUGIN_PREFIX);
	GetMaphacksForCurrentLevel();
}

public void OnMapStart()
{
	GetMaphacksForCurrentLevel();
}

public void OnMapReset(Event event, const char[] name, bool dontBroadcast)
{
	char buffer[PLATFORM_MAX_PATH];
	for(int i=0; i<GetArraySize(activeMaphacks); i++ )
	{
		GetArrayString(activeMaphacks, i, buffer, sizeof(buffer));
		ServerCommand("maphack_load \"%s/%s\"", maphackLibrary, buffer);
		PrintToServer("%s Loading maphack from file \"%s/%s\"", PLUGIN_PREFIX, maphackLibrary, buffer);
	}
}

int GetMaphacksFromFolder(const char[] directory)
{
	int count;
	char path[PLATFORM_MAX_PATH];
	FormatEx(path, sizeof(path), "%s/%s", maphackLibrary, directory);   //Format absolute path

	if(!DirExists(path))
		return 0;
	
	Handle listing = OpenDirectory(path);
	FileType type; 
	char entryName[PLATFORM_MAX_PATH];
	while(ReadDirEntry(listing, entryName, sizeof(entryName), type))
	{
		if(StrEqual(entryName, "..") || StrEqual(entryName, ".") ||	
			StrEqual(entryName, "/") || StrEqual(entryName, "disabled")) 
		{
			continue;
		}

		FormatEx(path, sizeof(path), "%s/%s", directory, entryName); //Format relative path

		if(type == FileType_Directory)
		{
			count += GetMaphacksFromFolder(path); 
			continue;
		}

		else if(type == FileType_File)
		{
			PushArrayString(activeMaphacks, path);
			count++;

			#if defined DEBUG
			PrintToServer("%s Cached to array: \"%s\"", PLUGIN_PREFIX, path);
			#endif
		}
	}
	return count;
}

int GetMaphacksForCurrentLevel()
{
	ClearArray(activeMaphacks);

	int count;
	if(!DirExists(maphackLibrary))
	{
		char convarName[CVAR_MAXLEN];
		GetConVarName(pluginDirectory, convarName, sizeof(convarName));
		char pluginDirectoryStr[256];
		GetConVarString(pluginDirectory, pluginDirectoryStr, sizeof(pluginDirectoryStr));
		LogError("%s Couldn't find path \"%s\" that %s is specifying.", PLUGIN_PREFIX, maphackLibrary, convarName);
		return 0;
	}

	char map[PLATFORM_MAX_PATH]; 
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, map, sizeof(map));

	Handle ls = OpenDirectory(maphackLibrary);
	FileType type;

	//Get folders that match map name, partially or fully  
	char entry[PLATFORM_MAX_PATH];
	while(ReadDirEntry(ls, entry, sizeof(entry), type))
	{
		if(type == FileType_Directory) 
		{
			if(StrContains(map, entry, false) != -1)
			{
				#if defined DEBUG
				PrintToServer("%s Found qualifying directory: \"%s\"", PLUGIN_PREFIX, path);
				#endif

				//Fetch maphacks from them
				count++;
				GetMaphacksFromFolder(entry);
			}
		}
	}
	return count;
}