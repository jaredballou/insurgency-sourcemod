/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basefuncommands Functions
 * Provides Anti-TK punishment functionality
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
 
// Sounds (based off funcommands.sp)
#define SOUND_BLIP		"buttons/blip1.wav"
#define SOUND_BEEP		"buttons/button17.wav"
#define SOUND_FINAL		"weapons/cguard/charging.wav"
#define SOUND_BOOM		"weapons/explode3.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"

// Flags used in various timers
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

// Serial Generator for Timer Safety
new g_Serial_Gen = 0;

// Model indexes for temp entities (based off funcommands.sp)
#if BEACON || TIMEBOMB || ICE || FIRE
new g_BeamSprite;
new g_HaloSprite;
#endif
#if ICE
new g_GlowSprite;
new g_BeamSprite2;
#endif
#if ICE || TIMEBOMB || FIRE
new g_ExplosionSprite;
#endif

// Basic color arrays for temp entities (based off funcommands.sp)
#if BEACON
new redColor[4] = {255, 75, 75, 255};
new greenColor[4] = {75, 255, 75, 255};
#endif
#if FIRE
new orangeColor[4] = {255, 128, 0, 255};
#endif
#if BEACON || ICE
new blueColor[4] = {75, 75, 255, 255};
#endif
#if BEACON || ICE || TIMEBOMB || FIRE
new greyColor[4] = {128, 128, 128, 255};
#endif
#if ICE || TIMEBOMB || FIRE
new whiteColor[4] = {255, 255, 255, 255};
#endif

// UserMessageId for Fade. (based off funcommands.sp)
#if DRUG || BLIND
new UserMsg:g_FadeUserMsgId;
#endif


// Include Punishments (based off funcommands.sp slightly modified)
#if BEACON
new g_BeaconSerial[MAXPLAYERS+1] = { 0, ... };
#endif
#if FIRE
new g_FireBombSerial[MAXPLAYERS+1] = { 0, ... };
new g_FireBombTime[MAXPLAYERS+1] = { 0, ... };
#endif
#if ICE
new g_FreezeSerial[MAXPLAYERS+1] = { 0, ... };
new g_FreezeBombSerial[MAXPLAYERS+1] = { 0, ... };
new g_FreezeTime[MAXPLAYERS+1] = { 0, ... };
new g_FreezeBombTime[MAXPLAYERS+1] = { 0, ... };
#endif
#if DRUG
new Handle:g_DrugTimers[MAXPLAYERS+1];
new Float:g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
#endif
#if TIMEBOMB
new g_TimeBombSerial[MAXPLAYERS+1] = { 0, ... };
new g_TimeBombTime[MAXPLAYERS+1] = { 0, ... };
#endif


// Punishments
// Beacon (based off funcommands.sp slightly modified)
#if BEACON
CreateBeacon(client)
{
	g_BeaconSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_Beacon, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);	
}

KillBeacon(client)
{
	g_BeaconSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllBeacons()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		KillBeacon(i);
	}
}

public Action:Timer_Beacon(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_BeaconSerial[client] != serial)
	{
		KillBeacon(client);
		return Plugin_Stop;
	}

	new team = GetClientTeam(client);

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	new Float:BEACON_RADIUS = GetConVarFloat(g_Cvar_BeaconRadius);

	TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();

	if (team == 2)
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	}
	else if (team == 3)
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
	}
	else
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
	}

	TE_SendToAll();

	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	

	return Plugin_Continue;
}
#endif

// Fire (based off funcommands.sp)
#if FIRE
CreateFireBomb(client)
{
	g_FireBombSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_FireBomb, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
	g_FireBombTime[client] = GetConVarInt(g_Cvar_FireBombTicks);
}

KillFireBomb(client)
{
	g_FireBombSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllFireBombs()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		KillFireBomb(i);
	}
}

public Action:Timer_FireBomb(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_FireBombSerial[client] != serial)
	{
		KillFireBomb(client);
		return Plugin_Stop;
	}	
	g_FireBombTime[client]--;
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	if (g_FireBombTime[client] > 0)
	{
		new color;
		
		if (g_FireBombTime[client] > 1)
		{
			color = RoundToFloor(g_FireBombTime[client] * (255.0 / GetConVarFloat(g_Cvar_FireBombTicks)));
			EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);	
		}
		else
		{
			color = 0;
			EmitAmbientSound(SOUND_FINAL, vec, client, SNDLEVEL_RAIDSIREN);
		}
		
		SetEntityRenderColor(client, 255, color, color, 255);

		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		PrintCenterTextAll("%t", "Till Explodes", name, g_FireBombTime[client]);		
		
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_FireBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_FireBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	else
	{
		TE_SetupExplosion(vec, g_ExplosionSprite, 0.1, 1, 0, GetConVarInt(g_Cvar_FireBombRadius), 5000);
		TE_SendToAll();
		
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;
		TE_SetupBeamRingPoint(vec, 50.0, GetConVarFloat(g_Cvar_FireBombRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.5, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();
		vec[2] += 15;
		TE_SetupBeamRingPoint(vec, 40.0, GetConVarFloat(g_Cvar_FireBombRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();	
		vec[2] += 15;
		TE_SetupBeamRingPoint(vec, 30.0, GetConVarFloat(g_Cvar_FireBombRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.7, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();
		vec[2] += 15;
		TE_SetupBeamRingPoint(vec, 20.0, GetConVarFloat(g_Cvar_FireBombRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.8, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();		
		
		EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

		IgniteEntity(client, GetConVarFloat(g_Cvar_BurnDuration));
		KillFireBomb(client);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		if (GetConVarInt(g_Cvar_FireBombMode) > 0)
		{
			new teamOnly = ((GetConVarInt(g_Cvar_FireBombMode) == 1) ? true : false);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
				{
					continue;
				}
				
				if (teamOnly && GetClientTeam(i) != GetClientTeam(client))
				{
					continue;
				}
				
				new Float:pos[3];
				GetClientAbsOrigin(i, pos);
				
				new Float:distance = GetVectorDistance(vec, pos);
				
				if (distance > GetConVarFloat(g_Cvar_FireBombRadius))
				{
					continue;
				}
				
				new Float:duration = GetConVarFloat(g_Cvar_BurnDuration);
				duration *= (GetConVarFloat(g_Cvar_FireBombRadius) - distance) / GetConVarFloat(g_Cvar_FireBombRadius);

				IgniteEntity(i, duration);
			}		
		}
		return Plugin_Stop;
	}
}

// Ice (based off funcommands.sp)
#if ICE
FreezeClient(client, time)
{
	if (g_FreezeSerial[client] != 0)
	{
		UnfreezeClient(client);
		return;
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);

	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	g_FreezeTime[client] = time;
	g_FreezeSerial[client] = ++ g_Serial_Gen;
	CreateTimer(1.0, Timer_Freeze, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
}

UnfreezeClient(client)
{
	g_FreezeSerial[client] = 0;
	g_FreezeTime[client] = 0;

	if (IsClientInGame(client))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;	

		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

		SetEntityMoveType(client, MOVETYPE_WALK);

		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

CreateFreezeBomb(client)
{
	if (g_FreezeBombSerial[client] != 0)
	{
		KillFreezeBomb(client);
		return;
	}
	g_FreezeBombTime[client] = GetConVarInt(g_Cvar_FreezeBombTicks);
	g_FreezeBombSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_FreezeBomb, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
}

KillFreezeBomb(client)
{
	g_FreezeBombSerial[client] = 0;
	g_FreezeBombTime[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllFreezes( )
{
	for(new i = 1; i < MaxClients; i++)
	{
		if (g_FreezeSerial[i] != 0)
		{
			UnfreezeClient(i);
		}

		if (g_FreezeBombSerial[i] != 0)
		{
			KillFreezeBomb(i);
		}
	}
}

public Action:Timer_Freeze(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_FreezeSerial[client] != serial)
	{
		UnfreezeClient(client);
		return Plugin_Stop;
	}

	if (g_FreezeTime[client] == 0)
	{
		UnfreezeClient(client);

		/* HintText doesn't work on Dark Messiah */
		if (g_GameEngine != SOURCE_SDK_DARKMESSIAH)
		{
			PrintHintText(client, "You are now unfrozen.");
		}
		else
		{
			PrintCenterText(client, "You are now unfrozen.");
		}

		return Plugin_Stop;
	}

	if (g_GameEngine != SOURCE_SDK_DARKMESSIAH)
	{
		PrintHintText(client, "You will be unfrozen in %d seconds.", g_FreezeTime[client]);
	}
	else
	{
		PrintCenterText(client, "You will be unfrozen in %d seconds.", g_FreezeTime[client]);
	}

	g_FreezeTime[client]--;
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 135);

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupGlowSprite(vec, g_GlowSprite, 0.95, 1.5, 50);
	TE_SendToAll();

	return Plugin_Continue;
}

public Action:Timer_FreezeBomb(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_FreezeBombSerial[client] != serial)
	{
		KillFreezeBomb(client);
		return Plugin_Stop;
	}

	new Float:vec[3];
	GetClientEyePosition(client, vec);
	g_FreezeBombTime[client]--;

	if (g_FreezeBombTime[client] > 0)
	{
		new color;

		if (g_FreezeBombTime[client] > 1)
		{
			color = RoundToFloor(g_FreezeBombTime[client] * (255.0 / GetConVarFloat(g_Cvar_FreezeBombTicks)));
			EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);	
		}
		else
		{
			color = 0;
			EmitAmbientSound(SOUND_FINAL, vec, client, SNDLEVEL_RAIDSIREN);
		}

		SetEntityRenderColor(client, color, color, 255, 255);

		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		PrintCenterTextAll("%t", "Till Explodes", name, g_FreezeBombTime[client]);

		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_FreezeBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_FreezeBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	else
	{
		TE_SetupExplosion(vec, g_ExplosionSprite, 5.0, 1, 0, GetConVarInt(g_Cvar_FreezeBombRadius), 5000);
		TE_SendToAll();

		EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

		KillFreezeBomb(client);
		FreezeClient(client, GetConVarInt(g_Cvar_FreezeDuration));

		if (GetConVarInt(g_Cvar_FreezeBombMode) > 0)
		{
			new bool:teamOnly = ((GetConVarInt(g_Cvar_FreezeBombMode) == 1) ? true : false);

			for (new i = 1; i < MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
				{
					continue;
				}

				if (teamOnly && GetClientTeam(i) != GetClientTeam(client))
				{
					continue;
				}

				new Float:pos[3];
				GetClientEyePosition(i, pos);

				new Float:distance = GetVectorDistance(vec, pos);

				if (distance > GetConVarFloat(g_Cvar_FreezeBombRadius))
				{
					continue;
				}

				TE_SetupBeamPoints(vec, pos, g_BeamSprite2, g_HaloSprite, 0, 1, 0.7, 20.0, 50.0, 1, 1.5, blueColor, 10);
				TE_SendToAll();
				
				FreezeClient(i, GetConVarInt(g_Cvar_FreezeDuration));
			}		
		}
		return Plugin_Stop;
	}
}
#endif

// Blind (based off funcommands.sp slightly modified)
#if BLIND
PerformBlind(target, amount)
{
	new targets[2];
	targets[0] = target;

	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);

	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}

	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);

	EndMessage();
}
#endif

// Drug (based off funcommands.sp)
#if DRUG
CreateDrug(client)
{
	g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);	
}

KillDrug(client)
{
	KillDrugTimer(client);
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);	
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();	
}

KillDrugTimer(client)
{
	KillTimer(g_DrugTimers[client]);
	g_DrugTimers[client] = INVALID_HANDLE;	
}

KillAllDrugs()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_DrugTimers[i] != INVALID_HANDLE)
		{
			if(IsClientInGame(i))
			{
				KillDrug(i);
			}
			else
			{
				KillDrugTimer(i);
			}
		}
	}
}

public Action:Timer_Drug(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimer(client);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		KillDrug(client);
		
		return Plugin_Handled;
	}
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0002));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, 128);
	
	EndMessage();	
		
	return Plugin_Handled;
}
#endif

// TimeBomb (based off funcommands.sp slightly modified)
#if TIMEBOMB
CreateTimeBomb(client)
{
	g_TimeBombSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_TimeBomb, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
	g_TimeBombTime[client] = GetConVarInt(g_Cvar_TimeBombTicks);
}

public Action:Timer_TimeBomb(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| serial != g_TimeBombSerial[client])
	{
		KillTimeBomb(client);
		return Plugin_Stop;
	}	
	g_TimeBombTime[client]--;

	new Float:vec[3];
	GetClientEyePosition(client, vec);

	if (g_TimeBombTime[client] > 0)
	{
		new color;

		if (g_TimeBombTime[client] > 1)
		{
			color = RoundToFloor(g_TimeBombTime[client] * (128.0 / GetConVarFloat(g_Cvar_TimeBombTicks)));
			EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);	
		}
		else
		{
			color = 0;
			EmitAmbientSound(SOUND_FINAL, vec, client, SNDLEVEL_RAIDSIREN);
		}

		SetEntityRenderColor(client, 255, 128, color, 255);

		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		PrintCenterTextAll("%t", "Till Explodes", name, g_TimeBombTime[client]);
		
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_TimeBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_TimeBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	else
	{
		TE_SetupExplosion(vec, g_ExplosionSprite, 5.0, 1, 0, GetConVarInt(g_Cvar_TimeBombRadius), 5000);
		TE_SendToAll();

		EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

		ForcePlayerSuicide(client);
		KillTimeBomb(client);
		SetEntityRenderColor(client, 255, 255, 255, 255);

		if (GetConVarInt(g_Cvar_TimeBombMode) > 0)
		{
			new teamOnly = ((GetConVarInt(g_Cvar_TimeBombMode) == 1) ? true : false);

			new maxclients = GetMaxClients();

			for (new i = 1; i <= maxclients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
				{
					continue;
				}

				if (teamOnly && GetClientTeam(i) != GetClientTeam(client))
				{
					continue;
				}

				new Float:pos[3];
				GetClientEyePosition(i, pos);

				new Float:distance = GetVectorDistance(vec, pos);

				if (distance > GetConVarFloat(g_Cvar_TimeBombRadius))
				{
					continue;
				}

				new damage = 220;
				damage = RoundToFloor(damage * ((GetConVarFloat(g_Cvar_TimeBombRadius) - distance) / GetConVarFloat(g_Cvar_TimeBombRadius)));

				SlapPlayer(i, damage, false);
				TE_SetupExplosion(pos, g_ExplosionSprite, 0.05, 1, 0, 1, 1);
				TE_SendToAll();				

				/* ToDo
				new Float:dir[3];
				SubtractVectors(vec, pos, dir);
				TR_TraceRayFilter(vec, dir, MASK_SOLID, RayType_Infinite, TR_Filter_Client);

				if (i == TR_GetEntityIndex())
				{
					new damage = 100;
					new radius = GetConVarInt(g_Cvar_TimeBombRadius) / 2;
					
					if (distance > radius)
					{
						distance -= radius;
						damage = RoundToFloor(damage * ((radius - distance) / radius));
					}

					SlapPlayer(i, damage, false);
				}
				*/
			}		
		}
		return Plugin_Stop;
	}
}

KillTimeBomb(client)
{
	g_TimeBombSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllTimeBombs()
{
	new maxclients = GetMaxClients();

	for (new i = 1; i <= maxclients; i++)
	{
		KillTimeBomb(i);
	}
}
#endif