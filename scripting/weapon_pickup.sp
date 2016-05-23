/*
================================================================================
weapon_pickup

Allow manipulation of weapons and items in the game world.
* Allow taking explosives and adding them to ammo for items we already have
* Allow modifying loadout and ammo counts on weapons that get selected
* Drop weapons that aren't part of the player's loadout when resupplying
* Drop one entity per ammo for grenades (i.e. drop 3 M67s)
* Perhaps add "Ammo drop" as part of dropping a weapon that allows getting the
  ammo
================================================================================
*/
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
#define PLUGIN_LOG_PREFIX "WPNPICK"
#define PLUGIN_NAME "[INS] Weapon Pickup"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.3"
#define PLUGIN_WORKING "1"

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
new Handle:cvarAmmoPickup = INVALID_HANDLE; // allow picking up weapons as ammo?
new OwnerOfWeapon[2048] = 0;
new m_hActiveWeapon;
new m_hMyWeapons;

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_weapon_pickup_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_weapon_pickup_enabled", PLUGIN_WORKING, "sets whether weapon pickup manipulation is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarAmmoPickup = CreateConVar("sm_weapon_pickup_ammo", "1", "sets whether picking up a weapon the player already has will add to the player's ammo count", FCVAR_NOTIFY | FCVAR_PLUGIN);
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	m_hActiveWeapon = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	if (m_hActiveWeapon == -1) {
		LogError("Can't find CBasePlayer::m_hActiveWeapon");
	}

	m_hMyWeapons = FindSendPropOffs("CINSPlayer", "m_hMyWeapons");
	if (m_hMyWeapons == -1) {
		LogError("Can't find CINSPlayer::m_hMyWeapons");
	}

	RegConsoleCmd("wp_weaponslots", Command_ListWeaponSlots, "Lists weapon slots. Usage: wp_weaponslots [target]");
	RegConsoleCmd("wp_weaponlist", Command_ListWeapons, "Lists all weapons. Usage: wp_weaponlist [target]");
	RegConsoleCmd("wp_removeweapons", Command_RemoveWeapons, "Removes all weapons. Usage: wp_removeweapons [target]");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}


// Hook weaponcanuse (called at weapon deployment) and drop
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
}

public OnWeaponDropPost(client, weapon)
{
	OwnerOfWeapon[weapon] = client; 
}
// Dump data about weapon entity
public Action:OnWeaponCanUse(client, weapon)
{
	new String:weaponClass[64];
	GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
	//PrintToServer("[WPNPICK] weaponClass %s",weaponClass);
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	return Plugin_Continue;
}  
//SDKHooks_DropWeapon(client, weapon, const Float:vecTarget[3]=NULL_VECTOR, const Float:vecVelocity[3]=NULL_VECTOR);


// List weapons in each slot
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
        ReplyToCommand(client, "Lists weapon slots. Usage: wp_weaponlist [target]");
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

// List all weapons
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
        ReplyToCommand(client, "Lists all weapon. Usage: wp_weaponlist [target]");
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

// Remove all weapons from a player
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
        ReplyToCommand(client, "Removes all weapons. Usage: wp_removeweapons [target]");
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
//aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
        new String:classname[64];
        GetEntityClassname(weapon, classname, sizeof(classname));
	new m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
	new m_bChamberedRound = GetEntData(weapon, FindSendPropInfo("CINSWeaponBallistic", "m_bChamberedRound"),1);
	new m_iClip1 = GetEntProp(weapon, Prop_Data, "m_iClip1"); // weapon clip amount bullets
	new m_hWeaponDefinitionHandle = GetEntProp(weapon, Prop_Send, "m_hWeaponDefinitionHandle");
	new m_iAmmo = -1;
	new m_iPrimaryAmmoCount = -1;
	if (m_iPrimaryAmmoType != -1) {
		m_iAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
		m_iPrimaryAmmoCount = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount");
	}
	new maxammo = Ins_GetWeaponGetMaxClip1(weapon);
        ReplyToCommand(observer, "%d\t%d\t%s m_hWeaponDefinitionHandle %d m_bChamberedRound %d m_iPrimaryAmmoType %d m_iClip1 %d m_iAmmo %d m_iPrimaryAmmoCount %d maxammo %d",offset, weapon, classname, m_hWeaponDefinitionHandle, m_bChamberedRound, m_iPrimaryAmmoType, m_iClip1, m_iAmmo, m_iPrimaryAmmoCount, maxammo);
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

// Hook entity creation so that all attempts to use it get checked
public OnEntityCreated(entity, const String:classname[])
{
    if(entity > MaxClients && IsValidEntity(entity))
    {
        SDKHook(entity, SDKHook_Use, OnEntityUse);
    }
}

// Called every time a player uses anything, need to add logic to only work on weapons
public Action:OnEntityUse(entity, activator, caller, UseType:type, Float:value)
{
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	PrintToServer("[WPNPICK] OnEntityUse called");
	if( activator > 0 && activator < MaxClients + 1 ) {
		if (!GetConVarBool(cvarAmmoPickup)) {
			return Plugin_Continue;
		}
	        new String:classname[64];
        	GetEntityClassname(entity, classname, sizeof(classname));
		new m_iPrimaryAmmoType = GetEntProp(entity, Prop_Data, "m_iPrimaryAmmoType");
		new m_bChamberedRound = GetEntData(entity, FindSendPropInfo("CINSWeaponBallistic", "m_bChamberedRound"),1);
		new m_iClip1 = GetEntProp(entity, Prop_Data, "m_iClip1"); // weapon clip amount bullets
		new m_iAmmo = -1;
		new m_iPrimaryAmmoCount = -1;
		if (m_iPrimaryAmmoType != -1) {
			m_iAmmo = GetEntProp(activator, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
			m_iPrimaryAmmoCount = GetEntProp(entity, Prop_Data, "m_iPrimaryAmmoCount");
		}
		PrintToServer("callback OnEntityUse, entity %i activator %i entity %d classname %s m_bChamberedRound %d m_iPrimaryAmmoType %d m_iClip1 %d m_iAmmo %d m_iPrimaryAmmoCount %d", entity, activator, entity, classname, m_bChamberedRound,m_iPrimaryAmmoType,m_iClip1,m_iAmmo,m_iPrimaryAmmoCount);
		int iOffset = FindInventoryItem(activator,classname);
		if (iOffset > -1) {
			//m_iAmmo = GetEntProp(activator, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
			new inc = 1; // TODO: Handle magazines and ammo type mismatches
			SetEntProp(activator, Prop_Send, "m_iAmmo", m_iAmmo+inc, _, m_iPrimaryAmmoType);
			PrintToServer("[WPNPICK] Added %d ammo for %s to %N (%d)",inc,classname,activator,activator);
			PrintHintText(activator,"Added %d ammo for %s",inc,classname);
			RemoveEdict(entity);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

FindInventoryItem(client,const String:sClassname[]) {
	if (!IsValidClient(client)) {
		return -1;
	}
	new String:classname[64];
	for(new offset = 0; offset < 128; offset += 4) {
		new weapon = GetEntDataEnt2(client, m_hMyWeapons + offset);
		if (weapon < 0) {
			continue;
		}
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (StrEqual(sClassname,classname)) {
			PrintToServer("[WPNPICK] Found %s in inventory for %N (%d) at offset %d",classname,client,client,offset);
			return offset;
		}
	}
	return -1;
}
