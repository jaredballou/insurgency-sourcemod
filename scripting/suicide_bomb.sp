//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#pragma unused cvarVersion

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Adds suicide bomb for bots"
new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?

new String:g_client_last_classstring[MAXPLAYERS+1][64];


public Plugin:myinfo = {
	name= "[INS] Suicide Bombers",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_suicidebomb_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_suicidebomb_enabled", "1", "sets whether suicide bombs are enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	HookEvent("player_hurt", Event_player_hurt, EventHookMode_Pre);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
	PrecacheSound( "weapons/ied/ied_detonate_01.wav", true);
	PrecacheSound( "weapons/ied/ied_detonate_02.wav", true);
	PrecacheSound( "weapons/ied/ied_detonate_03.wav", true);
}
public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	decl String:class_template[64];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	if( client == 0)
		return;
	g_client_last_classstring[client] = class_template;
}
public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	if ((victimId != 0) && (attackerId != 0))
	{
		new victim = GetClientOfUserId(victimId);
		//new attacker = GetClientOfUserId(attackerId);
		if (IsClientInGame(victim))
		{
			if (StrContains(g_client_last_classstring[victim], "suicide") > -1)
			{
				PrintToServer("[SUICIDE] Blowing Up %N with class %s!",victim,g_client_last_classstring[victim]);
				explode(victim);
			}
		}
	}
	return Plugin_Continue;
}
stock explode(client)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new explosion = CreateEntityByName("env_explosion");
	if (explosion != -1)
	{
		decl Float:vector[3];
		new damage = 500;
		new radius = 128;
		new team = GetEntProp(client, Prop_Send, "m_iTeamNum");
		GetClientEyePosition(client, vector);
		SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
		SetEntProp(explosion, Prop_Data, "m_spawnflags", 264);
		SetEntProp(explosion, Prop_Data, "m_iMagnitude", damage);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", radius);
		DispatchKeyValue(explosion, "rendermode", "5");
		DispatchSpawn(explosion);
		ActivateEntity(explosion);
		TeleportEntity(explosion, vector, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll("weapons/ied/ied_detonate_01.wav", explosion, 1, 90);
		AcceptEntityInput(explosion, "Explode");
	}
}
