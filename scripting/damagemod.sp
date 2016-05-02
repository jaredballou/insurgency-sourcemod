#include <sourcemod>
#include <regex>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>
#pragma unused cvarVersion
#define INS
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarFFMinDistance = INVALID_HANDLE; // Minimum Friendly Fire distance

//============================================================================================================

#define PLUGIN_VERSION "0.0.2"
#define PLUGIN_DESCRIPTION "Modifies damage before applying to players"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-damagemod.txt"

public Plugin:myinfo =
{
	name = "[INS] Damage Modifier",
	author = "Jared Ballou",
	version = PLUGIN_VERSION,
	description = PLUGIN_DESCRIPTION,
	url = "http://jballou.com"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_damagemod_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_damagemod_enabled", "1", "Enable Damage Mod plugin", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarFFMinDistance = CreateConVar("sm_damagemod_ff_min_distance", "120", "Minimum distance between players for Friendly Fire to register", FCVAR_NOTIFY | FCVAR_PLUGIN);
	PrintToServer("[DAMAGEMOD] Starting");
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("weapon_fire", Event_WeaponFired);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_suppressed", Event_PlayerSuppressed);
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
public Action:Event_WeaponFired(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"weaponid" "short"
	//"userid" "short"
	//"shots" "byte"
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new String:shotWeapName[32];
	//GetClientWeapon(client, shotWeapName, sizeof(shotWeapName));
	return Plugin_Continue;
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public Action:Event_PlayerSuppressed( Handle:event, const String:name[], bool:dontBroadcast )
{
/*
	new victim   = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker == 0 || victim == 0 || attacker == victim)
	{
		return;
	}
*/
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//"deathflags" "short"
	//"attacker" "short"
	//"customkill" "short"
	//"lives" "short"
	//"attackerteam" "short"
	//"damagebits" "short"
	//"weapon" "string"
	//"weaponid" "short"
	//"userid" "short"
	//"priority" "short"
	//"team" "short"
	//"y" "float"
	//"x" "float"
	//"z" "float"
	//"assister" "short"
/*
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//new weaponid = GetEventInt(event, "weaponid");

	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	if (assister) {
		LogPlayerEvent(assister, "triggered", "kill assist");
	}

	new weapon_index = g_client_last_weapon[attacker];
	if (weapon_index < 0)
	{
		return;
	}
	decl String:strLastWeapon[32];
	GetArrayString(g_weap_array, weapon_index, strLastWeapon, sizeof(strLastWeapon));
	//PrintToServer("[DAMAGEMOD] from event (weaponid: %d weapon: %s) from last (g_client_hurt_weaponstring: %s weapon_index: %d strLastWeapon: %s)", weaponid, weapon, g_client_hurt_weaponstring[victim], weapon_index, strLastWeapon);
	
	if (attacker == 0 || victim == 0 || attacker == victim)
	{
		return;
	}

	//PrintToChat(attacker, "Kills: %d", g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]);
	dump_player_stats(victim);
*/
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToServer("[DMG] PlayerHurt");
	if (!GetConVarBool(cvarEnabled))
	{
		//PrintToServer("[DMG] Not enabled");
		return Plugin_Continue;
	}
	//"userid" "short"
	//"weapon" "string"
	//"hitgroup" "short"
	//"priority" "short"
	//"attacker" "short"
	//"dmg_health" "short"
	//"health" "byte"
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	//PrintToServer("[DMG] attacker %d %N victim %d %N",attacker,attacker,victim,victim);
	if (attacker > 0 && attacker != victim) {
		//PrintToServer("[DMG] Attacker valid");
		if (GetClientTeam(attacker) == GetClientTeam(victim)) {
			//PrintToServer("[DMG] Team Damage");
			decl Float:attackerPos[3], Float:victimPos[3],Float:flDistance;
			GetClientAbsOrigin(attacker, attackerPos);
			GetClientAbsOrigin(victim, victimPos);
			flDistance = GetVectorDistance(attackerPos, victimPos);
			//PrintToServer("[DMG] Distance is %f",flDistance);
			if (flDistance <= GetConVarFloat(cvarFFMinDistance)) {
				//PrintToServer("[DMG] Distance triggered");
				//PrintToChat(attacker, "Close range FF against %N", victim);
				//PrintToChat(victim, "Close range FF from %N",attacker);
				return Plugin_Handled;
			}
		}
	}
/*
	decl String:weapon[MAX_WEAPON_LEN];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (StrEqual(weapon,"player")) {
		g_client_hurt_weaponstring[victim] = weapon;
	} else {
		if(StrContains(weapon, "grenade_") > -1 || StrContains(weapon, "rocket_") > -1) {
			ReplaceString(weapon, sizeof(weapon), "grenade_c4", "weapon_c4_clicker", false);
			ReplaceString(weapon, sizeof(weapon), "grenade_", "weapon_", false);
			ReplaceString(weapon, sizeof(weapon), "rocket_", "weapon_", false);
		}
		g_client_hurt_weaponstring[victim] = weapon;
	}
	//PrintToServer("[DAMAGEMOD] PlayerHurt attacher %d victim %d weapon %s ghws: %s", attacker, victim, weapon,g_client_hurt_weaponstring[victim]);
	if (attacker > 0 && attacker != victim)
	{
		new hitgroup  = GetEventInt(event, "hitgroup");
		if (hitgroup < 8)
		{
			hitgroup += LOG_HIT_OFFSET;
		}
		
		
		decl String:clientname[64];
		GetClientName(attacker, clientname, sizeof(clientname));
		

		//new weapon_index = GetWeaponIndex(weapon, -1 ,false);
		//PrintToChatAll("idx: %d - weapon: %s", weapon_index, weapon);
		new weapon_index = GetWeaponIndex(weapon);

		if (weapon_index > -1)  {
			g_weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
			g_weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE]  += GetEventInt(event, "dmg_health");
			g_weapon_stats[attacker][weapon_index][hitgroup]++;
			
			if (hitgroup == (HITGROUP_HEAD+LOG_HIT_OFFSET))
			{
				g_weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
			}
			g_client_last_weapon[attacker] = weapon_index;
			g_client_last_weaponstring[attacker] = weapon;
		}
		
		if (hitgroup == (HITGROUP_HEAD+LOG_HIT_OFFSET))
		{
			LogPlayerEvent(attacker, "triggered", "headshot");
		}
	}
*/
	return Plugin_Continue;
}
