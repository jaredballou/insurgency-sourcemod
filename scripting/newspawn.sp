//(C) 2016 Jared Ballou <sourcemod@jballou.com>
// This is a testing plugin that I am using to work out how to fix botspawns and other issues
// It is not for production use, and will likely break stuff.
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "New spawning plugin"
#define PLUGIN_NAME "[INS] New Spawn"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-newspawn.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_sprinklers_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_sprinklers_enabled", "0", "Set to 1 to remove sprinklers. 0 leaves them alone.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	RegAdminCmd("sm_list_spawns", Command_List, ADMFLAG_SLAY, "sm_list_spawns");
	list_spawns();
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	list_spawns();
}
public Action:Command_List(client, args)
{
	list_spawns();
	return Plugin_Handled;
}
public list_spawns()
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	PrintToServer("Running list_spawns");
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if(StrEqual("ins_spawnpoint", name,false) || StrEqual("ins_spawnzone", name,false)){
				decl String:entity_name[128],m_iDisabled;
				GetEntPropString(i, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
				m_iDisabled = GetEntProp(i, Prop_Data, "m_iDisabled");
				PrintToServer("Found %s named %s m_iDisabled %d",name,entity_name,m_iDisabled);
			}
		}
	}
	return true;
}
