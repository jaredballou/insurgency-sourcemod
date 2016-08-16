#include <sourcemod>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "DOI DeathNotices",
	author = "FeuerSturm",
	description = "Show death notices in the chat area",
	version = PLUGIN_VERSION,
	url = "https://feuersturm.info"
}

new Handle:doi_deathnotices_enabled = INVALID_HANDLE

public OnPluginStart()
{
	doi_deathnotices_enabled = CreateConVar("doi_deathnotices_enabled", "1", "<1/0> enable/disable DOI DeathNotices!", _, true, 0.0, true, 1.0)
}

public OnMapStart()
{
	HookEventEx("player_death", OnPlayerDeath, EventHookMode_Post)
}

public OnMapEnd()
{
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Post)
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(doi_deathnotices_enabled) == 1)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"))
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
		decl String:weapon[32]
		GetEventString(event, "weapon", weapon, sizeof(weapon))
		decl String:DeathMsg[256]
		if(victim >= 1 && victim <= MaxClients && IsClientInGame(victim))
		{
			if(attacker == victim)
			{
				Format(DeathMsg, sizeof(DeathMsg), "\x03%N committed suicide with %s", victim, weapon)
			}
			else if(attacker != victim && attacker >= 1 && attacker <= MaxClients && IsClientInGame(attacker))
			{
				Format(DeathMsg, sizeof(DeathMsg), "\x03%N killed %N with %s", attacker, victim, weapon)
			}
			else
			{
				Format(DeathMsg, sizeof(DeathMsg), "\x03%N died under mysterious circumstances", victim)
			}
			new Handle:SayText2 = StartMessageAll("SayText2")
			BfWriteByte(SayText2, attacker)
			BfWriteByte(SayText2, true)
			BfWriteString(SayText2, DeathMsg)
			EndMessage()
		}
	}
	return Plugin_Continue
}