//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks> // http://forums.alliedmods.net/showthread.php?t=106748
#define REQUIRE_EXTENSIONS

#define AUTOLOAD_EXTENSIONS
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Weapon Pickup logic for manipulating player inventory"
#define PLUGIN_NAME "[INS] Weapon Pickup"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING 0

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-weapon_pickup.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new OwnerOfWeapon[2048] = 0;
new m_hActiveWeapon;
new m_hMyWeapons;

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
}

public OnWeaponDropPost(client, weapon)
{
	OwnerOfWeapon[weapon] = client; 
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new String:weaponClass[64];
	GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
	Ins_Log(LOG_LEVEL:DEBUG,"weaponClass %s",weaponClass);
/*
		new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		new m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		new m_iClip1 = GetEntProp(weapon, Prop_Send, "m_iClip1"); // weapon clip amount bullets
		new m_iAmmo_prim = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
		new m_iPrimaryAmmoCount = -1;//GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoCount");
		InsLog(DEBUG,"weapon %d m_iPrimaryAmmoType %d m_iClip1 %d m_iAmmo_prim %d m_iPrimaryAmmoCount %d",weapon,m_iPrimaryAmmoType,m_iClip1,m_iAmmo_prim,m_iPrimaryAmmoCount);
		SetEntProp(client, Prop_Send, "m_iAmmo", 99, _, m_iPrimaryAmmoType); // Set player ammunition of this weapon primary ammo type

if (OwnerOfWeapon[weapon] == client)
	if(GetClientTeam(client) == 3)
	{
		return Plugin_Continue;
	}
*/
	return Plugin_Handled;
}  
//SDKHooks_DropWeapon(client, weapon, const Float:vecTarget[3]=NULL_VECTOR, const Float:vecVelocity[3]=NULL_VECTOR);



public Action:Command_ListWeaponSlots(client, argc)
{
    new target = -1;
    new String:valueString[64];
    
    if (argc >= 1)
    {
        GetCmdArg(1, valueString, sizeof(valueString));
        target = FindTarget(client, valueString);
    }
    
    if (target <= 0)
    {
        ReplyToCommand(client, "Lists weapon slots. Usage: zrtest_weaponlist [target]");
        return Plugin_Handled;
    }
    
    if (argc >= 1)
    {
        ListWeaponSlots(target, client);
    }
    else
    {
        ListWeaponSlots(client, client);
    }
    
    return Plugin_Handled;
}

public Action:Command_ListWeapons(client, argc)
{
    new target = -1;
    new String:valueString[64];
    
    if (argc >= 1)
    {
        GetCmdArg(1, valueString, sizeof(valueString));
        target = FindTarget(client, valueString);
    }
    
    if (target <= 0)
    {
        ReplyToCommand(client, "Lists all weapon. Usage: zrtest_weaponlist [target]");
        return Plugin_Handled;
    }
    
    if (argc >= 1)
    {
        ListWeapons(target, client);
    }
    else
    {
        ListWeapons(client, client);
    }
    
    return Plugin_Handled;
}

public Action:Command_Knife(client, argc)
{
    new target = -1;
    new String:valueString[64];
    
    if (argc >= 1)
    {
        GetCmdArg(1, valueString, sizeof(valueString));
        target = FindTarget(client, valueString);
    }
    
    if (target <= 0)
    {
        ReplyToCommand(client, "Gives a knife. Usage: zrtest_knife [target]");
        return Plugin_Handled;
    }
    
    if (argc >= 1)
    {
        GiveKnife(target);
    }
    else
    {
        GiveKnife(client);
    }
    
    return Plugin_Handled;
}

public Action:Command_RemoveWeapons(client, argc)
{
    new target = -1;
    new String:valueString[64];
    
    if (argc >= 1)
    {
        GetCmdArg(1, valueString, sizeof(valueString));
        target = FindTarget(client, valueString);
    }
    
    if (target <= 0)
    {
        ReplyToCommand(client, "Removes all weapons. Usage: zrtest_removeweapons [target]");
        return Plugin_Handled;
    }
    
    if (argc >= 1)
    {
        RemoveAllClientWeapons(target, client);
    }
    else
    {
        RemoveAllClientWeapons(client, client);
    }
    
    return Plugin_Handled;
}

/**
 * Lists weapon entity indexes in each weapon slot.
 *
 * @param client        Source client.
 * @param observer      Client that will receive output.
 * @param count         Optional. Number of slots to check.
 **/
ListWeaponSlots(client, observer, count = 10)
{
    ReplyToCommand(observer, "Slot:\tEntity:\tClassname:");
    
    // Loop through slots.
    for (new slot = 0; slot < count; slot++)
    {
        new weapon = GetPlayerWeaponSlot(client, slot);
            
        if (weapon < 0)
        {
            ReplyToCommand(observer, "%d\t(empty/invalid)", slot);
            continue;
        }
        
        new String:classname[64];
        GetEntityClassname(weapon, classname, sizeof(classname));
        
        ReplyToCommand(observer, "%d\t%d\t%s", slot, weapon, classname);
    }
}
/**
 * Lists all weapons.
 *
 * @param client        Source client.
 * @param observer      Client that will receive output.
 */
ListWeapons(client, observer)
{
    ReplyToCommand(observer, "Offset:\tEntity:\tClassname:");
    
    // Loop through entries in m_hMyWeapons.
    for(new offset = 0; offset < 128; offset += 4)     // +4 to skip to next entry in array.
    {
        new weapon = GetEntDataEnt2(client, m_hMyWeapons + offset);
        
        if (weapon < 0)
        {
            ReplyToCommand(observer, "%d\t(empty/invalid)", offset);
            continue;
        }
        
        new String:classname[64];
        GetEntityClassname(weapon, classname, sizeof(classname));
        
        ReplyToCommand(observer, "%d\t%d\t%s", offset, weapon, classname);
    }
}

/**
 * Remove all weapons.
 * 
 * @param client        Source client.
 * @param observer      Client that will receive output.
 * @param count         Optional. Number of slots to list.
 */
RemoveAllClientWeapons(client, observer, count = 5)
{
    // Loop through weapon slots.
    for (new slot = 0; slot < count; slot++)
    {
        new weapon = GetPlayerWeaponSlot(client, slot);
        
        // Remove all weapons in this slot.
        while (weapon > 0)
        {
            // Remove weapon entity.
            RemovePlayerItem(client, weapon);
            AcceptEntityInput(weapon, "Kill");
            
            ReplyToCommand(observer, "Removed weapon in slot %d.", slot);
            
            // Get next weapon in this slot, if any.
            weapon = GetPlayerWeaponSlot(client, slot);
        }
    }
}

GiveKnife(client)
{
    GivePlayerItem(client, "weapon_knife");
}





































public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_weapon_pickup_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_weapon_pickup_enabled", "1", "sets whether weapon pickup manipulation is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

/*
	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	remove_fog();
*/
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	m_hActiveWeapon = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
    if (m_hActiveWeapon == -1)
    {
        LogError("Can't find CBasePlayer::m_hActiveWeapon");
    }
    
    m_hMyWeapons = FindSendPropOffs("CInsPlayer", "m_hMyWeapons");
    if (m_hMyWeapons == -1)
    {
        LogError("Can't find CInsPlayer::m_hMyWeapons");
    }
    
    RegConsoleCmd("zrtest_weaponslots", Command_ListWeaponSlots, "Lists weapon slots. Usage: zrtest_weaponslots [target]");
    RegConsoleCmd("zrtest_weaponlist", Command_ListWeapons, "Lists all weapons. Usage: zrtest_weaponlist [target]");
    RegConsoleCmd("zrtest_knife", Command_Knife, "Gives a knife. Usage: zrtest_knife [target]");
    RegConsoleCmd("zrtest_removeweapons", Command_RemoveWeapons, "Removes all weapons. Usage: zrtest_removeweapons [target]");
}


public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
/*
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	remove_fog();
}
public remove_fog()
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if (StrEqual("env_fog_controller", name,false)) {
				RemoveEdict(i);
			}
		}
	}
	return true;
}
*/
