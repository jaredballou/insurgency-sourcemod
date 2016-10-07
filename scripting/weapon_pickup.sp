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
//Depends: insurgency
#pragma semicolon 1
#pragma unused cvarVersion
#pragma unused cvarMaxExplosive
#pragma unused cvarMaxMagazine

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Weapon Pickup logic for manipulating player inventory"
#define PLUGIN_LOG_PREFIX "WPNPICK"
#define PLUGIN_NAME "[INS] Weapon Pickup"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING "1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks> // http://forums.alliedmods.net/showthread.php?t=106748
#define REQUIRE_EXTENSIONS

#define AUTOLOAD_EXTENSIONS

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarAmmoPickup = INVALID_HANDLE; // allow picking up weapons as ammo?
new Handle:cvarMaxExplosive = INVALID_HANDLE; // Maximum number of explosive ammo
new Handle:cvarMaxMagazine = INVALID_HANDLE; // Maximum number of magazines that can be picked up

new g_WeaponOwner[2048] = 0;
new m_hActiveWeapon;
new m_hMyWeapons;

public OnPluginStart() {
	cvarVersion = CreateConVar("sm_weapon_pickup_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_weapon_pickup_enabled", PLUGIN_WORKING, "sets whether weapon pickup manipulation is enabled", FCVAR_NOTIFY);
	cvarAmmoPickup = CreateConVar("sm_weapon_pickup_ammo", "1", "sets whether picking up a weapon the player already has will add to the player's ammo count", FCVAR_NOTIFY);
	cvarMaxExplosive = CreateConVar("sm_weapon_pickup_max_explosive", "3", "Maximum number of ammo that can be carried for explosives", FCVAR_NOTIFY);
	cvarMaxMagazine = CreateConVar("sm_weapon_pickup_max_magazine", "12", "Maximum number of magazines that can be carried", FCVAR_NOTIFY);

	m_hActiveWeapon = GetSendProp("CINSPlayer", "m_hActiveWeapon");

        HookEvent("player_first_spawn", Event_Player_First_Spawn);
        HookEvent("player_spawn", Event_Player_Spawn);
        HookEvent("weapon_pickup", Event_Weapon_Pickup);

	m_hMyWeapons = GetSendProp("CINSPlayer", "m_hMyWeapons");

	RegConsoleCmd("wp_weaponslots", Command_ListWeaponSlots, "Lists weapon slots. Usage: wp_weaponslots [target]");
	RegConsoleCmd("wp_weaponlist", Command_ListWeapons, "Lists all weapons. Usage: wp_weaponlist [target]");
	RegConsoleCmd("wp_removeweapons", Command_RemoveWeapons, "Removes all weapons. Usage: wp_removeweapons [target]");
	HookEverything();
	HookUpdater();
}

HookEverything() {
	InsLog(DEBUG, "HookEverything");
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if (i > MaxClients) {
			HookEntity(i);
		} else {
			HookClient(i);
		}
	}
}
// Hook entity creation so that all attempts to use it get checked
public OnEntityCreated(entity, const String:classname[]) {
	HookEntity(entity);
}

HookEntity(entity) {
	if(entity > MaxClients && IsValidEntity(entity)) {
		InsLog(DEBUG, "HookEntity %d", entity);
		new String:sNetClass[32];
	        new String:sClassname[64];
		GetEntityNetClass(entity, sNetClass, sizeof(sNetClass));
	        GetEntityClassname(entity, sClassname, sizeof(sClassname));
		//PrintToServer("[WP] sNetClass %s sClassname %s", sNetClass, sClassname);
		// TODO: Only hook weapons/grenades. Need to do some magic here.
		SDKHook(entity, SDKHook_Use, OnEntityUse);
//		new m_iPrimaryAmmoCount = GetSendProp(sNetClass, "m_iPrimaryAmmoCount", 0);
//		if (m_iPrimaryAmmoCount > -1) {
	}
}

// Hook weaponcanuse (called at weapon deployment) and drop
public OnClientPutInServer(client) {
	HookClient(client);
}

HookClient(client) {
	if (!IsValidClient(client))
		return;
	InsLog(DEBUG, "HookClient %N (%d)", client, client);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
}

public Action:Event_Weapon_Pickup(Handle:event, const String:name[], bool:dontBroadcast) {
        new userid = GetEventInt(event, "userid");
        new weaponid = GetEventInt(event, "weaponid");
        if (userid > 0 && weaponid > 0) {
                new client = GetClientOfUserId(userid);
                if (client) {
			InsLog(DEBUG, "Event_Weapon_Pickup userid %d client %N (%d) weaponid %d",userid,client,client,weaponid);
                }
        }
}
public Action:Event_Player_Spawn( Handle:event, const String:name[], bool:dontBroadcast ) {
        new userid = GetEventInt(event, "userid");
        new client = GetClientOfUserId(userid);
        if( client == 0 || !IsClientInGame(client) )
                return Plugin_Continue;
	InsLog(DEBUG, "Event_Player_Spawn userid %d client %N (%d)",userid,client,client);
        return Plugin_Continue;
}
public Action:Event_Player_First_Spawn( Handle:event, const String:name[], bool:dontBroadcast ) {
        new userid = GetEventInt(event, "userid");
        new client = GetClientOfUserId(userid);
        if( client == 0 || !IsClientInGame(client) )
                return Plugin_Continue;
	InsLog(DEBUG, "Event_Player_First_Spawn userid %d client %N (%d)",userid,client,client);
        return Plugin_Continue;
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
}


public OnWeaponDropPost(client, weapon) {
	g_WeaponOwner[weapon] = client; 
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
	new String:sNetClass[32];
	new iOffset;
	GetEntityNetClass(weapon, sNetClass, sizeof(sNetClass));
        GetEntityClassname(weapon, classname, sizeof(classname));
	new m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
	new m_bChamberedRound = 0;
	iOffset = FindSendPropInfo(sNetClass, "m_bChamberedRound");
	if (iOffset > -1) {
		m_bChamberedRound = GetEntData(weapon, iOffset, 1);
	}
	new m_iClip1 = GetEntProp(weapon, Prop_Data, "m_iClip1"); // weapon clip amount bullets
	new m_hWeaponDefinitionHandle = GetEntProp(weapon, Prop_Send, "m_hWeaponDefinitionHandle");
	new m_iAmmo = -1;
	new m_iPrimaryAmmoCount = -1;
	new m_bHammerDown = 0;
	new m_eBoltState = 0;
	iOffset = FindSendPropInfo(sNetClass, "m_bHammerDown");
	if (iOffset > -1) {
		m_bHammerDown = GetEntData(weapon, iOffset, 1);
	}
	iOffset = FindSendPropInfo(sNetClass, "m_eBoltState");
	if (iOffset > -1) {
		m_eBoltState = GetEntData(weapon, iOffset, 1);
	}
	if (m_iPrimaryAmmoType != -1) {
		m_iAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
		m_iPrimaryAmmoCount = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount");
	}
	new maxammo = Ins_GetMaxClip1(weapon);
        ReplyToCommand(observer, "%d\t%d\t%s m_hWeaponDefinitionHandle %d m_bChamberedRound %d m_iPrimaryAmmoType %d m_iClip1 %d m_iAmmo %d m_iPrimaryAmmoCount %d maxammo %d m_bHammerDown %d m_eBoltState %d",offset, weapon, classname, m_hWeaponDefinitionHandle, m_bChamberedRound, m_iPrimaryAmmoType, m_iClip1, m_iAmmo, m_iPrimaryAmmoCount, maxammo,m_bHammerDown,m_eBoltState);
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


// Called every time a player uses anything, need to add logic to only work on weapons
public Action:OnEntityUse(entity, activator, caller, UseType:type, Float:value)
{
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	InsLog(DEBUG, "OnEntityUse called");
	if( activator > 0 && activator < MaxClients + 1 ) {
		if (!GetConVarBool(cvarAmmoPickup)) {
			return Plugin_Continue;
		}
	        new String:classname[64];
               	new String:sNetClass[32];
		new iOffset;
		GetEntityNetClass(entity, sNetClass, sizeof(sNetClass));
	        GetEntityClassname(entity, classname, sizeof(classname));
		InsLog(DEBUG, "OnEntityUse, entity %i activator %i classname %s netclass %s", entity, activator, classname, sNetClass);
		new m_iPrimaryAmmoType = GetEntProp(entity, Prop_Data, "m_iPrimaryAmmoType");
		new m_bChamberedRound = 0;
		iOffset = FindSendPropInfo(sNetClass, "m_bChamberedRound");
		if (iOffset > -1) {
			m_bChamberedRound = GetEntData(entity, iOffset, 1);
		}
		new m_iClip1 = GetEntProp(entity, Prop_Data, "m_iClip1"); // weapon clip amount bullets
		new m_hWeaponDefinitionHandle = GetEntProp(entity, Prop_Send, "m_hWeaponDefinitionHandle");
		new m_iAmmo = -1;
		new m_iPrimaryAmmoCount = -1;
		new m_bHammerDown = 0;
		new m_eBoltState = 0;
		iOffset = FindSendPropInfo(sNetClass, "m_bHammerDown");
		if (iOffset > -1) {
			m_bHammerDown = GetEntData(entity, iOffset, 1);
		}
		iOffset = FindSendPropInfo(sNetClass, "m_eBoltState");
		if (iOffset > -1) {
			m_eBoltState = GetEntData(entity, iOffset, 1);
		}
		if (m_iPrimaryAmmoType != -1) {
			m_iAmmo = GetEntProp(activator, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
			m_iPrimaryAmmoCount = GetEntProp(entity, Prop_Data, "m_iPrimaryAmmoCount");
		}
		InsLog(DEBUG, "OnEntityUse m_bChamberedRound %d m_iPrimaryAmmoType %d m_iClip1 %d m_iAmmo %d m_iPrimaryAmmoCount %d m_bHammerDown %d m_eBoltState %d m_hWeaponDefinitionHandle %d", m_bChamberedRound,m_iPrimaryAmmoType,m_iClip1,m_iAmmo,m_iPrimaryAmmoCount, m_bHammerDown, m_eBoltState, m_hWeaponDefinitionHandle);
		iOffset = FindInventoryItem(activator,classname);
		if (iOffset > -1) {
	                InsLog(DEBUG,"sNetClass %s",sNetClass);

//cvarMaxExplosive
//cvarMaxMagazine
			//m_iAmmo = GetEntProp(activator, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
			new inc = 1; // TODO: Handle magazines and ammo type mismatches
			SetEntProp(activator, Prop_Send, "m_iAmmo", m_iAmmo+inc, _, m_iPrimaryAmmoType);
/*
//int CBaseCombatCharacter::GiveAmmo(int, int, bool)
new Handle:hGiveAmmo;
        offset = GameConfGetOffset(temp, "GiveAmmo");
        hGiveAmmo = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, GiveAmmo);
        DHookAddParam(hGiveAmmo, HookParamType_Int);
        DHookAddParam(hGiveAmmo, HookParamType_Int);
        DHookAddParam(hGiveAmmo, HookParamType_Bool);
        DHookEntity(hGiveAmmo, false, client);
// int CBaseCombatCharacter::GiveAmmo(int, int, bool)
// int CBaseCombatCharacter::GiveAmmo(int, int, bool)
public MRESReturn:GiveAmmo(pThis, Handle:hReturn, Handle:hParams)
{
	PrintToChat(pThis, "Giving %i of %i supress %i", DHookGetParam(hParams, 1), DHookGetParam(hParams, 2), DHookGetParam(hParams, 3));
        return MRES_Ignored;
}
*/
			InsLog(DEBUG, "Added %d ammo for %s to %N (%d)",inc,classname,activator,activator);
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
	        	InsLog(DEBUG, "Found %s in inventory for %N (%d) at offset %d",classname,client,client,offset);
			return offset;
		}
	}
	return -1;
}



/*
	new Handle:hGameConfIns = INVALID_HANDLE;
	new Handle:hGameConfSDK = INVALID_HANDLE;
	hGameConfIns = LoadGameConfigFile("insurgency.games");
	hGameConfSDK = LoadGameConfigFile("sdkhooks.games/engine.insurgency");

Weapon_Drop(weapon)
{
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGameConfSDK, SDKConf_Virtual, "Weapon_Drop")) {
		SetFailState("PrepSDKCall_SetFromConf false, nothing found"); 
	}
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	new Handle:hCall = EndPrepSDKCall();
	new value = SDKCall(hCall, weapon);
	CloseHandle(hCall);
	return value;
}

new Handle:hCanHaveAmmo;
	offset = GameConfGetOffset(hGameConf, "CanHaveAmmo");
	hCanHaveAmmo = DHookCreate(offset, HookType_GameRules, ReturnType_Bool, ThisPointer_Ignore, CanHaveAmmoPost);
	DHookAddParam(hCanHaveAmmo, HookParamType_CBaseEntity);
	DHookAddParam(hCanHaveAmmo, HookParamType_Int);
	offset = GameConfGetOffset(hGameConf, "GiveAmmo");
	hGiveAmmo = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, GiveAmmo);
	DHookAddParam(hGiveAmmo, HookParamType_Int);
	DHookAddParam(hGiveAmmo, HookParamType_Int);
	DHookAddParam(hGiveAmmo, HookParamType_Bool);
*/
