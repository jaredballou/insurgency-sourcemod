#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <botmimic>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVShowDamage;
new Handle:g_hCVPlayHitSound;

public Plugin:myinfo = 
{
	name = "Bot Mimic Training",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Plays sounds if you hit a mimicing bot",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	g_hCVShowDamage = CreateConVar("sm_botmimic_showdamage", "1", "Show damage when hitting a mimicing bot?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVPlayHitSound = CreateConVar("sm_botmimic_playhitsound", "1", "Play a sound when hitting a mimicing bot?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_hurt", Event_OnPlayerHurt);
}

public OnMapStart()
{
	PrecacheSound("ui/achievement_earned.wav", true);
}

public Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!attacker)
		return;
	
	if(BotMimic_IsPlayerMimicing(client))
	{
		// Show the hitgroup he's been hit and the damage done.
		if(GetConVarBool(g_hCVShowDamage))
		{
			new iHitGroup = GetEventInt(event, "hitgroup");
			decl String:sHitGroup[64];
			switch(iHitGroup)
			{
				case 0:
					Format(sHitGroup, sizeof(sHitGroup), "Body");
				case 1:
					Format(sHitGroup, sizeof(sHitGroup), "Head");
				case 2:
					Format(sHitGroup, sizeof(sHitGroup), "Bosom");
				case 3:
					Format(sHitGroup, sizeof(sHitGroup), "Belly");
				case 4:
					Format(sHitGroup, sizeof(sHitGroup), "L Hand");
				case 5:
					Format(sHitGroup, sizeof(sHitGroup), "R Hand");
				case 6:
					Format(sHitGroup, sizeof(sHitGroup), "L Foot");
				case 7:
					Format(sHitGroup, sizeof(sHitGroup), "R Foot");
			}
			
			PrintCenterText(attacker, "%s : %d", sHitGroup, GetEventInt(event, "dmg_health") + GetEventInt(event, "dmg_armor"));
		}
		
		if(GetConVarBool(g_hCVPlayHitSound))
			EmitSoundToClient(attacker, "ui/achievement_earned.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_ROCKET);
	}
}