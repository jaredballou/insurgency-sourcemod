#include <sourcemod>
#include <regex>
#include <insurgency>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>
#pragma unused cvarVersion
#define INS
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarFFMinDistance = INVALID_HANDLE; // Minimum Friendly Fire distance

//============================================================================================================

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Modifies damage before applying to players"
#define PLUGIN_NAME "[INS] Damage Modifier"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING "1"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

public OnPluginStart()
{
	PrintToServer("[DAMAGEMOD] Starting");

	cvarVersion = CreateConVar("sm_damagemod_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_damagemod_enabled", PLUGIN_WORKING, "Enable Damage Mod plugin", FCVAR_NOTIFY);
	cvarFFMinDistance = CreateConVar("sm_damagemod_ff_min_distance", "120", "Minimum distance between players for Friendly Fire to register", FCVAR_NOTIFY);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_hurt", Event_PlayerHurtPre, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFired);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_suppressed", Event_PlayerSuppressed);
	HookUpdater();
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
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

public Action Event_PlayerHurtPre(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToServer("[DMG] PlayerHurtPre");
	if (!GetConVarBool(cvarEnabled))
	{
		//PrintToServer("[DMG] Not enabled");
		return Plugin_Continue;
	}
/*
	int priority = event.GetInt("priority");
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int dmg_health = event.GetInt("dmg_health");
	int health = event.GetInt("health");
	int damagebits = event.GetInt("damagebits");
	int hitgroup = event.GetInt("hitgroup");
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	int userid = GetClientOfUserId(event.GetInt("userid"));

	PrintToServer("[DMG] priority %d attacker %d %N dmg_health %d health %d damagebits %d hitgroup %d weapon %s userid %d %N",priority,attacker,attacker,dmg_health,health,damagebits,hitgroup,weapon,userid,userid);
*/
	return Plugin_Continue;
}
public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	//PrintToServer("[DMG] PlayerHurt");
	if (!GetConVarBool(cvarEnabled)) {
		//PrintToServer("[DMG] Not enabled");
		return Plugin_Continue;
	}
	int priority = event.GetInt("priority");
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int dmg_health = event.GetInt("dmg_health");
	int health = event.GetInt("health");
	int damagebits = event.GetInt("damagebits");
	int hitgroup = event.GetInt("hitgroup");
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	int userid = GetClientOfUserId(event.GetInt("userid"));

	if (hitgroup <= LOG_HIT_OFFSET) {
		hitgroup += LOG_HIT_OFFSET;
	}

	char sValDump[2048];
	Format(sValDump, sizeof(sValDump), "priority %d attacker %d %N dmg_health %d health %d damagebits %d hitgroup %d weapon %s userid %d %N",priority,attacker,attacker,dmg_health,health,damagebits,hitgroup,weapon,userid,userid);

	if (attacker > 0 && attacker != userid) {
		//PrintToServer("[DMG] Attacker valid");
		if (GetClientTeam(attacker) == GetClientTeam(userid)) {
			//PrintToServer("[DMG] Team Damage");
			decl Float:vecAttacker[3], Float:vecUserid[3],Float:flDistance;
			GetClientAbsOrigin(attacker, vecAttacker);
			GetClientAbsOrigin(userid, vecUserid);
			flDistance = GetVectorDistance(vecAttacker, vecUserid);
			if ((damagebits & DMG_BULLET) && (flDistance <= GetConVarFloat(cvarFFMinDistance))) {
				PrintToServer("[DMG] Friendly Fire Blocked for Distance %f",flDistance);
				PrintToChat(attacker, "Close range FF against %N blocked due to proximity", userid);
				PrintToChat(userid, "Close range FF from %N blocked due to proximity",attacker);
				return Plugin_Handled;
			}
		}
	}
/*
	decl String:weapon[MAX_WEAPON_LEN];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (StrEqual(weapon,"player")) {
		g_client_hurt_weaponstring[userid] = weapon;
	} else {
		if(StrContains(weapon, "grenade_") > -1 || StrContains(weapon, "rocket_") > -1) {
			ReplaceString(weapon, sizeof(weapon), "grenade_c4", "weapon_c4_clicker", false);
			ReplaceString(weapon, sizeof(weapon), "grenade_", "weapon_", false);
			ReplaceString(weapon, sizeof(weapon), "rocket_", "weapon_", false);
		}
		g_client_hurt_weaponstring[userid] = weapon;
	}
	//PrintToServer("[DAMAGEMOD] PlayerHurt attacher %d userid %d weapon %s ghws: %s", attacker, userid, weapon,g_client_hurt_weaponstring[userid]);
	if (attacker > 0 && attacker != userid)
	{
		new hitgroup  = GetEventInt(event, "hitgroup");
		
		
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
