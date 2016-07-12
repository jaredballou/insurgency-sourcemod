//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#pragma unused cvarVersion

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Adds suicide bomb for bots"
#define PLUGIN_NAME "[INS] Suicide Bombers"
#define PLUGIN_URL "http://jballou.com/"
#define PLUGIN_VERSION "0.0.4"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define UPDATE_URL    ""

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarDeathChance = INVALID_HANDLE; //global death chance
new Handle:cvarIncenDeathChance = INVALID_HANDLE; //death chance if explosion
new Handle:cvarExplosiveDeathChance = INVALID_HANDLE; //death chance if explosion
new Handle:cvarChestStomachDeathChance = INVALID_HANDLE; //death chance if chest/stomach
new g_ClientBombs[MAXPLAYERS+1];
new String:g_client_last_classstring[MAXPLAYERS+1][64];
new bool:bEnabled = false;
new g_isDetonating[MAXPLAYERS+1];
/*hitgroups
generic = 0?
head = 1
chest = 2
stomach = 3
leftArm = 4
rightArm = 5
leftLeg = 6
rightLeg = 7
Gear = 8 ?
*/

public OnPluginStart()
{
	//PrintToServer("[SUICIDE] Starting");
	cvarVersion = CreateConVar("sm_suicidebomb_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_suicidebomb_enabled", "1", "sets whether suicide bombs are enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarDeathChance = CreateConVar("sm_suicidebomb_death_chance", "0.0", "Chance as a fraction of 1 that a bomber will explode when killed", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarIncenDeathChance = CreateConVar("sm_suicidebomb_incen_death_chance", "0.15", "Chance as a fraction of 1 that a bomber will explode when hurt by incen/molotov", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarExplosiveDeathChance = CreateConVar("sm_suicidebomb_explosive_death_chance", "0.75", "Chance as a fraction of 1 that a bomber will explode when hurt by explosive", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarChestStomachDeathChance = CreateConVar("sm_suicidebomb_chest_stomach_death_chance", "0.50", "Chance as a fraction of 1 that a bomber will explode if shot in stomach/chest", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(cvarEnabled,ConVarChanged);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
}
public OnMapStart()
{	
	CreateTimer(2.0, Timer_BomberLoop, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == cvarEnabled)
		bEnabled = bool:StringToInt(newVal);
}
public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToServer("[SUICIDE] Running Event_PlayerPickSquad");
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	decl String:class_template[64];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	if( client) {
		g_client_last_classstring[client] = class_template;
	}
	return;
}
public Action:Timer_BomberLoop(Handle:timer) //this controls bomber loop to check if distance from player
{
	new Float:fBomberDistance = GetRandomFloat(100.0, 300.0);
	//PrintToServer("[SUICIDE] TIMER: g_isDetonating: %i", g_isDetonating);
	
	////PrintToServer("[SUICIDE] TIMER STARTED");
	for (new bomber = 1; bomber <= MaxClients; bomber++)
	{
		if (bomber < 1 || !IsClientInGame(bomber) || !IsFakeClient(bomber) && g_isDetonating[bomber] != 1)
			continue;
			
		if ((StrContains(g_client_last_classstring[bomber], "bomber") > -1) && 
			IsPlayerAlive(bomber))
		{
			////PrintToServer("[SUICIDE] TIMER BOMBER DETECTED");
			
			for (new victim = 1; victim <= MaxClients; victim++) // lets get our victim to compare distance
			{
				if (victim < 1 || !IsClientInGame(victim) || IsFakeClient(victim))
					continue;
					
				if (IsPlayerAlive(victim))
				{
					new Float:tDistance = (GetEntitiesDistance(bomber, victim)); // get current distance
					//tDistance = Math_UnitsToMeters(tDistance);
					//PrintToServer("[SUICIDE] Bomber Distance: %f ", tDistance);
					
					////PrintToServer("[SUICIDE] TIMER VICTIM DETECTED");
					if (tDistance < fBomberDistance)
					{
						new Float:fBomberViewThreshold = 0.75; // if negative, bombers back is turned
						new Bool:tCanBomberSeeTarget = (ClientViews(bomber, victim, fBomberDistance, fBomberViewThreshold));
						if (tCanBomberSeeTarget)
						{
							//new victimId = GetClientUserId(bomber);
							//PrintToServer("[SUICIDE] IN BOMBER DISTANCE AND LOS");
							g_isDetonating[bomber] = 1;
							//PrintToServer("[SUICIDE] EventDeath: Victim ID is %d, g_isDetonating: %i",victimId, g_isDetonating);
							
							CheckExplodeHurt(bomber);
						}
						else
						{
							//PrintToServer("[SUICIDE] BOMBER HAS NO LOS!");
						}
					}
				}
			}
		}
	}
}
// ----------------------------------------------------------------------------
// ClientViews()
// ----------------------------------------------------------------------------
stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.73)
{
    // Retrieve view and target eyes position
    decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    decl Float:fViewDir[3];
    decl Float:fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    decl Float:fTargetDir[3];
    decl Float:fDistance[3];
    
    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }
    
    // Check dot product. If it's negative, that means the viewer is facing
    // backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    // Now check if there are no obstacles in between through raycasting
    new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

// ----------------------------------------------------------------------------
// ClientViewsFilter()
// ----------------------------------------------------------------------------
public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}  
stock Float:GetEntitiesDistance(ent1, ent2)
{
	new Float:orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	new Float:orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

	return GetVectorDistance(orig1, orig2);
} 

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	
	////PrintToServer("[SUICIDE] Victim ID is %d, g_isDetonating: %i",victimId, g_isDetonating);
	
	new victim = GetClientOfUserId(victimId);
	if (!(StrContains(g_client_last_classstring[victim], "bomber") > -1)) //make sure its a bot bomber
	{
		return;
	}
	if (IsClientInGame(victim) && IsFakeClient(victim) && g_isDetonating[victim] != 1)
	{
		
		new Float:fChestStomachDeathChance = GetConVarFloat(cvarChestStomachDeathChance);
		new Float:fExplosiveDeathChance = GetConVarFloat(cvarExplosiveDeathChance);
		new Float:fIncenDeathChance = GetConVarFloat(cvarIncenDeathChance);
		
		new hitgroup = GetEventInt(event, "hitgroup");
		decl String:weapon[32];
		new Int:dmg_taken = GetEventInt(event, "dmg_health");
		new Int:victimHealth = GetEventInt(event, "health");
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		//PrintToServer("[SUICIDE] victimHealth is: %i, Damage Taken: %i | RETURNING",victimHealth, dmg_taken);
		
		new Float:fRandom = GetRandomFloat(0.0, 1.0);
		//PrintToServer("[SUICIDE] Weapon used: %s, Damage done: %i",weapon, dmg_taken);

		if (hitgroup == 0)
		{
			//explosive list
			//incens
			//grenade_molotov, grenade_anm14
			//grenade_m67, grenade_f1, grenade_ied, grenade_c4, rocket_rpg7, rocket_at4, grenade_gp25_he, grenade_m203_he
			if (StrEqual(weapon, "grenade_anm14", false) || StrEqual(weapon, "grenade_molotov", false))
			{
				//PrintToServer("[SUICIDE] incen/molotov DETECTED!");
				if (fRandom < fIncenDeathChance)
				{
					
					CheckExplodeHurt(victim);
				}
			}
			else if (StrEqual(weapon, "grenade_m67", false) || 
				StrEqual(weapon, "grenade_f1", false) || 
				StrEqual(weapon, "grenade_ied", false) || 
				StrEqual(weapon, "grenade_c4", false) || 
				StrEqual(weapon, "rocket_rpg7", false) || 
				StrEqual(weapon, "rocket_at4", false) || 
				StrEqual(weapon, "grenade_gp25_he", false) || 
				StrEqual(weapon, "grenade_m203_he", false))
			{
				//PrintToServer("[SUICIDE] Explosive DETECTED!");
				if (dmg_taken >= 50.0)
				{
					if (fRandom < fExplosiveDeathChance)
					{
						
						CheckExplodeHurt(victim);
					}
				}
				else if (dmg_taken < 50.0) 
				{
					if (fRandom < 0.10) //10% chance
					{
						
						CheckExplodeHurt(victim);
					}
				}
			}
			//PrintToServer("[SUICIDE] HITRGOUP 0 [GENERIC]");
		}
		else if (hitgroup == 1)
		{
			//PrintToServer("[SUICIDE] BOOM HEADSHOT");
		}
		else if (hitgroup == 2 || hitgroup == 3)
		{
			if (dmg_taken >= 50.0)
				{
					if (fRandom < 0.75) // To compensate for higher caliber rifles that may kill target in 1-2 shots we raise chance o 75%
					{
						
						CheckExplodeHurt(victim);
					}
				}
				else if (dmg_taken < 50.0) 
				{
					//PrintToServer("[SUICIDE] Chest/Stomach shot");
					if (fRandom < fChestStomachDeathChance)
					{
						
						CheckExplodeHurt(victim);
					}
				}
		}
		else if (hitgroup == 4 || hitgroup == 5  || hitgroup == 6 || hitgroup == 7)
		{
			if (fRandom < 0.25) //25% chance if shot in legs/arms to panic detonate
			{
				
				CheckExplodeHurt(victim);
			}
		}
	}
	//PrintToServer("[SUICIDE] EventDeath: Victim ID is %d, g_isDetonating: %i",victimId, g_isDetonating);
	
}
public Action:Timer_DetonatePeriod(Handle:timer, any:client)
{
	//new client;
	new bomb;
	new Float:clientPos[3];
	//PrintToServer("[DEBUG]-------BOMB ACTIVE");
	//ResetPack(bomberPack);
	//client = ReadPackCell(bomberPack);
	//bomb = ReadPackCell(bomberPack);
	bomb = EntRefToEntIndex(g_ClientBombs[client]);
	GetClientAbsOrigin(client, Float:clientPos);
	clientPos[2] = clientPos[2] + 54;
    //client is our victim and we are running through all medics to see whos nearby
	if(IsFakeClient(client) && IsPlayerAlive(client) && bomb > 0 && bomb != INVALID_ENT_REFERENCE && IsValidEdict(bomb) && IsValidEntity(bomb))
	{
		TeleportEntity(bomb, clientPos, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		return Plugin_Stop;
	}
}
public CheckExplodeHurt(client) {
	g_isDetonating[client] = 1;
	//new m_iSquad = GetEntProp(client, Prop_Send, "m_iSquad");
	//new m_iSquadSlot = GetEntProp(client, Prop_Send, "m_iSquadSlot");
	
	//PrintToServer("[SUICIDE] Running CheckExplodeHURT for client %d name %N squad %d squadslot %d",client,client,m_iSquad,m_iSquadSlot);
	//PrintToServer("[SUICIDE] Blowing Up %N with class %s!",client,g_client_last_classstring[client]);

	new Float:vecOrigin[3],Float:vecAngles[3];
	GetClientEyePosition(client, vecOrigin);

	new ent = CreateEntityByName("grenade_ied");
	if(IsValidEntity(ent))
	{
		vecAngles[0] = vecAngles[1] = vecAngles[2] = 0.0;
		TeleportEntity(ent, vecOrigin, vecAngles, vecAngles);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", 1); //for smoke
		SetEntProp(ent, Prop_Data, "m_takedamage", 2);
		SetEntProp(ent, Prop_Data, "m_iHealth", 1);
		SetEntProp(ent, Prop_Data, "m_usSolidFlags", 0);
		SetEntProp(ent, Prop_Data, "m_nSolidType", 0);
		g_ClientBombs[client] = EntIndexToEntRef(ent);
		//new Handle:bomberPack;
		//CreateDataTimer(0.0 , Timer_DetonatePeriod, bomberPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);	
		CreateTimer(0.0, Timer_DetonatePeriod, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
        // WritePackCell(bomberPack, client);
        // WritePackCell(bomberPack, ent);

		if (DispatchSpawn(ent)) {
			DealDamage(ent,304,client,DMG_BLAST,"weapon_c4_ied");
			
		}
	}
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new Float:fExplosiveDeathChance = GetConVarFloat(cvarExplosiveDeathChance);
	new Float:fDeathChance = GetConVarFloat(cvarDeathChance);
	
	new Float:fRandom = GetRandomFloat(0.0, 1.0);
	new victimId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimId);
	if (!(StrContains(g_client_last_classstring[victim], "bomber") > -1)) //make sure its a bot bomber
	{
		return;
	}
	//PrintToServer("[SUICIDE] EventDeath: Victim ID is %d, g_isDetonating: %i",victimId, g_isDetonating);
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (victimId > 0)
	{
		
		if (IsClientInGame(victim) && IsFakeClient(victim) && g_isDetonating[victim] != 1)
		{
			if (fRandom < fDeathChance)
			{	
				CheckExplodeDeath(victim);
			}
			else if (StrEqual(weapon, "grenade_m67", false) || 
				StrEqual(weapon, "grenade_f1", false) || 
				StrEqual(weapon, "grenade_ied", false) || 
				StrEqual(weapon, "grenade_c4", false) || 
				StrEqual(weapon, "rocket_rpg7", false) || 
				StrEqual(weapon, "rocket_at4", false) || 
				StrEqual(weapon, "grenade_gp25_he", false) || 
				StrEqual(weapon, "grenade_m203_he", false) ||
				StrEqual(weapon, "grenade_anm14", false) || 
				StrEqual(weapon, "grenade_molotov", false))
			{
				if (fRandom < fExplosiveDeathChance)
				{
					CheckExplodeDeath(victim);
				}
			}
		}
	}
	g_isDetonating[victim] = 0;
}
public CheckExplodeDeath(client) {
	//new m_iSquad = GetEntProp(client, Prop_Send, "m_iSquad");
	//new m_iSquadSlot = GetEntProp(client, Prop_Send, "m_iSquadSlot");
	//new Float:fDeathChance = GetConVarFloat(cvarDeathChance);
	new Float:fExplosiveDeathChance = GetConVarFloat(cvarExplosiveDeathChance);
	
	//PrintToServer("[SUICIDE] Running CheckExplodeDEATH for client %d name %N squad %d squadslot %d",client,client,m_iSquad,m_iSquadSlot);

	//PrintToServer("[SUICIDE] Blowing Up %N with class %s!",client,g_client_last_classstring[client]);
	
	//Assign random variable first
	//new String:shotWeapName[32];

	new Float:vecOrigin[3],Float:vecAngles[3];
	GetClientEyePosition(client, vecOrigin);

	new ent = CreateEntityByName("grenade_ied");
	if(IsValidEntity(ent))
	{
		//PrintToServer("[SUICIDE] Created IED entity");
		vecAngles[0] = vecAngles[1] = vecAngles[2] = 0.0;
		TeleportEntity(ent, vecOrigin, vecAngles, vecAngles);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", 1); //for smoke
		SetEntProp(ent, Prop_Data, "m_takedamage", 2);
		SetEntProp(ent, Prop_Data, "m_iHealth", 1);
		SetEntProp(ent, Prop_Data, "m_usSolidFlags", 0);
		SetEntProp(ent, Prop_Data, "m_nSolidType", 0);
		g_ClientBombs[client] = EntIndexToEntRef(ent);
		//new Handle:bomberPack;
		//CreateDataTimer(0.0 , Timer_DetonatePeriod, bomberPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);	
		CreateTimer(0.0, Timer_DetonatePeriod, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        //WritePackCell(bomberPack, client);
        //WritePackCell(bomberPack, ent);
		
		if (DispatchSpawn(ent)) {
			//PrintToServer("[SUICIDE] Detonating IED entity");
			DealDamage(ent,304,client,DMG_BLAST,"weapon_c4_ied");
		}
	}
}

DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && damage>0)
	{
		decl String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		decl String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","donthurtme");
			RemoveEdict(pointHurt);
		}
	}

}
