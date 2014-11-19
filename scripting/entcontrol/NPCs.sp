/* 
	------------------------------------------------------------------------------------------
	EntControl::NPCs
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

// Admin Flags
new Handle:gAdminFlagNPC;
new gMuzzle1;

// Include our NPCs
#include "NPCs/BaseNPC.sp"
#include "NPCs/sentrygun.sp"
#include "NPCs/vortigaunt.sp"
#include "NPCs/antlion.sp"
#include "NPCs/antlionguard.sp"
#include "NPCs/headcrab.sp"
#include "NPCs/gman.sp"
#include "NPCs/zombie.sp"
#include "NPCs/soldier.sp"
#include "NPCs/police.sp"
#include "NPCs/barney.sp"
#include "NPCs/strider.sp"
#include "NPCs/stalker.sp"
#include "NPCs/synth.sp"
#include "NPCs/dog.sp"

public InitNPCs()
{
	if (gameMod == CSS || gameMod ==TF)
	{
		gMuzzle1 = PrecacheModel("materials/sprites/muzzleflash4.vmt");
		
		InitSentryGun();
		
		if (gameMod == CSS)
		{
			InitBaseNPC();
			
			InitAntlion();
			
			InitVortigaunt();
			
			InitAntlionGuard();
			
			InitHeadCrab();
			
			InitGMan();
			
			InitZombie();
			
			InitSoldier();
			
			InitPolice();
			
			InitBarney();
			
			InitStalker();
			
			InitStrider();
			
			InitSynth();
			
			InitDog();
		}
	}
}

public RegNPCsCommands()
{
	RegConsoleCmd("sm_entcontrol_npc_fake", Command_Fake, "Fake-Client");
	
	if (gameMod == CSS || gameMod == TF)
	{
		gAdminFlagNPC = CreateConVar("sm_entcontrol_npc_fl", "z", "The needed Flag to spawn NPCs");
		RegConsoleCmd("sm_shownpcs", Command_ShowNPCs, "Show connections to NPCs"); // Without sm_entcontrol_... | !shownpcs
		
		RegConsoleCmd("sm_entcontrol_npc_sentry", Command_Sentry, "Sentry-Gun");
		
		if (gameMod == CSS)
		{
			RegConsoleCmd("sm_entcontrol_npc_antlion", Command_AntLion, "AntLion");
			RegConsoleCmd("sm_entcontrol_npc_vortigaunt", Command_Vortigaunt, "Vortigaunt");
			RegConsoleCmd("sm_entcontrol_npc_antlionguard", Command_AntlionGuard, "AntlionGuard");
			RegConsoleCmd("sm_entcontrol_npc_headcrab", Command_HeadCrab, "AntlionGuard");
			RegConsoleCmd("sm_entcontrol_npc_gman", Command_GMan, "Spawn GMan");
			RegConsoleCmd("sm_entcontrol_npc_zombie", Command_Zombie, "Spawn Zombie");
			RegConsoleCmd("sm_entcontrol_npc_soldier", Command_Soldier, "Spawn Soldier");
			RegConsoleCmd("sm_entcontrol_npc_police", Command_Police, "Spawn Police");
			RegConsoleCmd("sm_entcontrol_npc_barney", Command_Barney, "Spawn Barney");
			RegConsoleCmd("sm_entcontrol_npc_strider", Command_Strider, "Spawn Strider");
			RegConsoleCmd("sm_entcontrol_npc_stalker", Command_Stalker, "Spawn Stalker");
			RegConsoleCmd("sm_entcontrol_npc_synth", Command_Synth, "Spawn Synth");
			RegConsoleCmd("sm_entcontrol_npc_dog", Command_Dog, "Spawn Dog");
		}
	}
}

/* 
	------------------------------------------------------------------------------------------
	Show NPCs
	------------------------------------------------------------------------------------------
*/
public Action:Command_ShowNPCs(client, args)
{
	new String:sClassName[64];
	new Float:vClientPosition[3], Float:vEntityPosition[3];
	
	GetClientEyePosition(client, vClientPosition);
	new count = GetMaxEntities()-100;

	for (new i = 2; i < count; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i)) 
		{
			GetEdictClassname(i, sClassName, 64);
			if (StrContains(sClassName, "npc_") == 0)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vEntityPosition);
				
				TE_SetupBeamPoints(vClientPosition, vEntityPosition, gLaser1, 0, 0, 0, 5.0, 1.0, 1.0, 0, 0.0, {0, 255, 0, 255}, 0);
				TE_SendToClient(client);
			}
		}
	}
}

public Action:OnStartTouch(entity, other)
{
	if (IsValidEntity(other) && IsValidEdict(other))
	{
		decl String:classname[32];
		GetEntPropString(other, Prop_Data, "m_iClassname", classname, sizeof(classname));
		if (StrContains(classname, "npc_") != -1)
			BaseNPC_Death(other);
	}

	return (Plugin_Continue);
}

/*
public Action:OnStartTouch(entity, other)
{
	if (IsValidEntity(other) && IsValidEdict(other))
	{
		decl String:classname[32];
		GetEntPropString(other, Prop_Data, "m_iClassname", classname, sizeof(classname));
		if (StrEqual(classname, "hostage_entity"))
		{
			new target = GetEntDataEnt2(other, gLeaderOffset);
			AcceptEntityInput(other, "OnRescueZoneTouch", target, target);
		}
		else if (StrEqual(classname, "player") && !IsFakeClient(other))
			SetEntProp(other, Prop_Send, "m_bInHostageRescueZone", 1, 1);
	}

	return (Plugin_Continue);
}

public Action:OnEndTouch(entity, other)
{
	if (IsValidEntity(other) && IsValidEdict(other))  
	{
		decl String:classname[32];
		GetEntPropString(other, Prop_Data, "m_iClassname", classname, sizeof(classname)); 
		
		if (StrEqual(classname, "player") && !IsFakeClient(other))
			SetEntProp(other, Prop_Send, "m_bInHostageRescueZone", 0, 1);    
	} 

	return (Plugin_Continue);
}
*/
/* 
	------------------------------------------------------------------------------------------
	Command_Fake
	Just for testing ...
	------------------------------------------------------------------------------------------
*/
public Action:Command_Fake(client, args)
{
	if (CanUseCMD(client, gAdminFlagNPC) && !fakeClient)
	{
		fakeClient = CreateFakeClient("Monster");
		ChangeClientTeam(fakeClient, 2);
		DispatchKeyValue(fakeClient, "classname", "TheDeath");
		DispatchSpawn(fakeClient);
	}
}