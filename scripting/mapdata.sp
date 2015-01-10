//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Creates files with map overlay data for parsing by the Web interface"
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public Plugin:myinfo = {
	name= "[INS] Map Data Exporter",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_mapdata_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_mapdata_enabled", "1", "sets whether data export is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	dump_map_data();
	PrintToChatAll ("\x01 1 .. \x02 2 .. \x03 3 .. \x04 4 .. \x05 5 .. \x06 6 .. \x07 7 .. \x08 8 .. \x09 9 ..");  
}
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	dump_map_data();
}
public dump_map_data()
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	return true;
	new String:classname[32],String:targetname[32],String:controlpoint[32],teamnum,Float:origin[3];
decl String:sMap[256];
GetCurrentMap(sMap, sizeof(sMap));
decl String:sOutput[PLATFORM_MAX_PATH], String:sSeparator[1], String:sContent[1024],String:sBuffer[1024];
new Handle:g_hNavMeshKeyValues = CreateKeyValues(sMap);
Format(sOutput, sizeof(sOutput), "maps\\navmesh\\%s.txt", sMap);
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, classname, sizeof(classname))){
			if (
				(StrEqual("point_controlpoint", classname,false)) ||
				(StrEqual("obj_weapon_cache", classname,false)) ||
				(StrEqual("ins_spawnpoint", classname,false)) ||
				(StrEqual("ins_spawnzone", classname,false)) ||
				(StrEqual("ins_blockzone", classname,false)) ||
				(StrEqual("trigger_capture_zone", classname,false))
			)
			{
				teamnum = GetEntProp(i, Prop_Send, "teamnum");
				GetEntPropString(i, Prop_Data, "controlpoint", controlpoint, sizeof(controlpoint));
				GetEntPropString(i, Prop_Data, "targetname", targetname, sizeof(targetname));
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);
	       	PrintToServer("[TestProp] Entity %d classname %s",i,classname);
			}
		}
	}
	return true;
}
