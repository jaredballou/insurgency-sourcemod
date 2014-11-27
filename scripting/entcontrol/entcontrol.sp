/*
	------------------------------------------------------------------------------------------
	Entcontrol-System
	By Raffael 'LeGone' Holz
	http://www.exp-clan.com

	Grabbing-Code based on L. Duke´s Grabber(mod):SM
	
	NOTE: If you see YOUR code in my code ... let me know !!!
	I´m going to give you credits for sure !
	------------------------------------------------------------------------------------------
*/

// -- Includes
#include <sourcemod>
#include <sdktools>
#include <morecolors>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#include <entcontrol>

// -- Definitions
#define PLUGIN_VERSION "0.0.1.81"

#define INVISIBLE 	{255, 255, 255,   0}
#define VISIBLE   	{255, 255, 255, 255}

// -- Globals
// - Some variables
new gObj[MAXPLAYERS+1];
new gSelectedEntity[MAXPLAYERS+1]; // This is not the grabbed-entity!
new Float:gSavedPos[MAXPLAYERS+1][3];
new Float:gDistance[MAXPLAYERS+1];
new Float:gNextPickup[MAXPLAYERS+1];
new Handle:gTimer;
new Handle:gTimerVehicles;
new Handle:gTimerHudInfo;
new gCollisionOffset;
//new gSelectedEntitySprite;
new gLeaderOffset;
new fakeClient;
new gLaser1;
new gHalo1;
new gSmoke1;
new gGlow1;
new bool:notBetweenRounds;

// Admin Flags
//new Handle:gUpdateURL = INVALID_HANDLE;
new Handle:gAdvert = INVALID_HANDLE;
new Handle:gAdminFlagGrab = INVALID_HANDLE;
new Handle:gAdminFlagGrabPlayer = INVALID_HANDLE;
new Handle:gAdminFlagHUD = INVALID_HANDLE;
new Handle:gAdminCanGrabSelf = INVALID_HANDLE;
new Handle:gAdminCanModSelf = INVALID_HANDLE;
new Handle:gNoneAdminsUseGrab = INVALID_HANDLE;
new Handle:gAdminShowHud = INVALID_HANDLE;
new Handle:gSpawnRandomNPCs = INVALID_HANDLE;
new Handle:gDrawBoundingBox = INVALID_HANDLE;

// Spraytrace
new Float:SprayPos[MAXPLAYERS + 1][3];
new String:SprayName[MAXPLAYERS + 1][64];

// gameMod
new GameType:gameMod;

// Extensions
new bool:SDKHooksLoaded;
new bool:EntControlExtLoaded;

new Handle:kv = INVALID_HANDLE;
new Handle:kvEnts = INVALID_HANDLE;

// -- Entcontrol-Includes
#include "stocks.sp"

#include "menu.sp"
#include "spawn.sp"
#include "helper.sp"
#include "move.sp"
#include "edit.sp"
#include "portal.sp"
#include "rotate.sp"
#include "weapons.sp"
#include "NPCs.sp"
#include "world.sp"
#include "natives.sp"
#include "Vehicles/BaseVehicle.sp"
#include "webinterface.sp"

// -- Plugin Info
// Please do not just remove my name or rename this plugin :(
// I spend much time to write this plugin -.-
public Plugin:myinfo = 
{
	name = "Ent-Control",
	author = "LeGone",
	description = "Entity-Control-System",
	version = PLUGIN_VERSION,
	url = "http://www.legone.name"
};

/* 
	------------------------------------------------------------------------------------------
	EVENTS CODE
	------------------------------------------------------------------------------------------
*/
public OnPluginStart()
{
	CreateConVar("sm_entcontrol_version", PLUGIN_VERSION, "EntControl-Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	PrintToServer("==== Entcontrol ====");
	PrintToServer("Version %s", PLUGIN_VERSION);
	
	// Check Gametype
	gameMod = GetGameType();
	if (gameMod != OTHER)
		PrintToServer("Running on gameMod/mod: %s", GameTypeToString());
	else
		PrintToServer("This mod \"%s\" is official not supported!", GameTypeToString());
		
	PrintToServer("Duo to the huge amount of features, not all features are at a stable state at the moment.");
	PrintToServer("If you use one of these experimental features, please let me know about the bugs.");
	PrintToServer("Thank you :)");
	
	AddServerTag("entcontrol"); // Buggy -.-
	//SetConVarString(FindConVar("sv_tags"), "entcontrol");
	
	LoadTranslations("entcontrol.phrases");
	
	// -- Events
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	
	// Cstrike only 
	if (gameMod == CSS || gameMod == CSGO) 
	{
		HookEvent("round_start", OnRoundStart);
		HookEvent("round_end", OnRoundEnd);
	}
	else if (gameMod == TF) // TF only
	{
		HookEvent("teamplay_round_win", OnRoundEnd);
		HookEvent("teamplay_round_start", OnRoundStart);
	}
	else if (gameMod == DOD)
	{
		HookEvent("dod_round_win", OnRoundEnd);
	}

	gCollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup"); 
	
	// -- Commands
	// - Menu
	RegMenuCommands();

	// - Spawn
	RegSpawnCommands();

	// - Move
	RegMoveCommands();
	
	// - Edit
	RegEditCommands();

	// - Rotate
	RegRotateCommands();

	// - Helper
	RegHelperCommands();
	
	// - Webinterface
	RegWebinterfaceCommands();
	
	if (gameMod == CSS || gameMod == CSGO)
	{
		// - NPCs
		gLeaderOffset = FindSendPropOffs("CHostage", "m_leader");
	}
	
	// - NPCs
	RegNPCsCommands();

	// - Weapons
	RegWeaponsCommands();
	
	// - Vehicles
	BaseVehicle_Commands();

	// -- Convars
	// Advert - Disabled by default
	gAdvert = CreateConVar("sm_entcontrol_advert", "0", "Help us sharing this plugin.");
	
	gNoneAdminsUseGrab = CreateConVar("sm_entcontrol_noneadminsusegrab", "0", "Will none-admins be able to grab things?");
	gAdminFlagGrab = CreateConVar("sm_entcontrol_grab_fl", "z", "The needed Flag to grab things");
	gAdminFlagGrabPlayer = CreateConVar("sm_entcontrol_grab_pl_fl", "z", "The needed Flag to grab player");
	gAdminCanGrabSelf = CreateConVar("sm_entcontrol_grab_self", "0", "Self-Grabbing?");
	RegConsoleCmd("+sm_entcontrol_grab", Command_Grab, "Grab Object");
	RegConsoleCmd("-sm_entcontrol_grab", Command_UnGrab, "Ungrab Object");
	RegConsoleCmd("sm_entcontrol_grab_toggle", Command_GrabToggle, "Grab Object(Toggle)");
	
	gAdminFlagHUD = CreateConVar("sm_entcontrol_hud_fl", "z", "The needed Flag to get the hud info");
	gAdminShowHud = CreateConVar("sm_entcontrol_show_hud", "1", "Show Hud");

	RegConsoleCmd("sm_entcontrol", Command_Show_Info, "Shows the Plugin-info"); // !entcontrol in chat
	//RegConsoleCmd("sm_entcontrol_bug", Command_Report_Bugs, "Report a entcontrol-bug"); // !entcontrol_bug in chat

	gAdminCanModSelf = CreateConVar("sm_entcontrol_mod_self", "0", "Self-Modding?");
	
	// Draw bounding box?
	gDrawBoundingBox = CreateConVar("sm_entcontrol_boundingbox", "1", "Draw bounding box when selecting object?");
	
	// Random NPCs on random places
	gSpawnRandomNPCs = CreateConVar("sm_entcontrol_randomnpcs", "0", "Spawn random NPCs in random places");
	
	AutoExecConfig();
	
	PrintToServer("==== !Entcontrol ====");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegisterNatives();
	return (APLRes_Success);
}

public OnEventShutdown()
{
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookEvent("player_spawn", OnPlayerSpawn);
	
	// Cstrike only
	if (gameMod == CSS || gameMod == CSGO)
	{
		UnhookEvent("round_start", OnRoundStart);
		UnhookEvent("round_end", OnRoundEnd);
	}
	else if (gameMod == TF)
	{
		UnhookEvent("teamplay_round_win", OnRoundEnd);
		UnhookEvent("teamplay_round_start", OnRoundStart);
	}
	else if (gameMod == DOD)
		UnhookEvent("dod_round_win", OnRoundEnd);
}

public OnMapStart()
{
	// Check for SDKHOOKS
	if (GetExtensionFileStatus("sdkhooks.ext") != 1)
		LogError("SDKHooks NOT LOADED! Entcontrol is not fully working! Status: %i", GetExtensionFileStatus("sdkhooks.ext"));
	else
		SDKHooksLoaded = true;

	// Check for the EntControl-Ext
	if (GetExtensionFileStatus("entcontrol.ext") != 1)
		LogError("The EntControl Extension IS NOT LOADED! Entcontrol is not fully working! Status: %i", GetExtensionFileStatus("entcontrol.ext"));
	else
		EntControlExtLoaded = true;

	SetConVarString(FindConVar("sm_entcontrol_version"), PLUGIN_VERSION);

	// LaserBeam
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	PrecacheModel("models/items/battery.mdl", false);
	PrecacheModel("models/weapons/w_missile_launch.mdl", false);
	PrecacheSound("weapons/Irifle/irifle_fire2.wav", false);

	// Grabbing Sound
	// weapons/physcannon/physcannon_charge.wav
	PrecacheSound("buttons/combine_button5.wav");
	
	//gSelectedEntitySprite = PrecacheModel("models/extras/info_speech.mdl");
	
	// start timer
	gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	gTimerVehicles = CreateTimer(0.1, BaseVehicle_Update, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	if (GetConVarBool(gAdminShowHud))
	{
		if (gameMod == CSS || gameMod == TF || gameMod == NMRIH)
			gTimerHudInfo = CreateTimer(1.0, UpdateHudInfoExtended, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		else
			gTimerHudInfo = CreateTimer(1.0, UpdateHudInfoSimple, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Hostage
	PrecacheSound("physics/glass/glass_sheet_break3.wav");
	
	kv = CreateKeyValues("EntControl");
	decl String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/entcontrol.cfg");
	if (!FileToKeyValues(kv, file))
	{
		CloseHandle(kv);
		kv = INVALID_HANDLE;
		
		LogError("%s NOT loaded! You NEED that file!", file);
	}
	
	kvEnts = CreateKeyValues("EntControl_Entities");
	BuildPath(Path_SM, file, sizeof(file), "configs/entcontrol_entities.cfg");
	if (!FileToKeyValues(kvEnts, file))
	{
		CloseHandle(kvEnts);
		kv = INVALID_HANDLE;
		
		LogError("%s NOT loaded! You NEED that file!", file);
	}
	
	if (gameMod != CSGO)
		InitWeapons();
	
	InitNPCs();
	
	Portal_Init();
	
	BaseVehicle_Init();
	
	BuildMenu();

	notBetweenRounds = true;
}

public OnMapEnd()
{
	if (gTimer != INVALID_HANDLE)
		CloseHandle(gTimer);
	if (gTimerHudInfo != INVALID_HANDLE)
		CloseHandle(gTimerHudInfo);
	if (gTimerVehicles != INVALID_HANDLE)
		CloseHandle(gTimerVehicles);

	gLastKilledNPC = 0;
	gNPCCount = 0;
	
	FreeMenu();
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	notBetweenRounds = true;
	gRedPortal = 0;
	
	CreateTimer(0.5, SpawnEntities, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	notBetweenRounds = false;
	gLastKilledNPC = 0;
	gNPCCount = 0;
	
	if (fakeClient)
		KickClient(fakeClient);

	/*
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientConnectedIngame(i) && !IsFakeClient(i))
		{
			if (IsValidEdict(gTVMissile[i]) && IsValidEntity(gTVMissile[i]))
				AcceptEntityInput(gTVMissile[i], "Kill");
				
			if (IsValidEdict(gTV[i]) && IsValidEntity(gTV[i]))
				AcceptEntityInput(gTV[i], "Kill");
		}
	}
	*/
}

public OnClientPutInServer(client)
{
	if (client)
	{
		gObj[client] = -1;
		gSelectedEntity[client] = -1;
		gDistance[client] = 0.0;
		gSavedPos[client][0] = 0.0;
		gSavedPos[client][1] = 0.0;
		gSavedPos[client][2] = 0.0;
		gNextPickup[client] = 0.0;
	}
}

public OnClientDisconnect(client) 
{
	// Was driving?
	if (gClientVehicle[client] != 0)
		BaseVehicle_Leave(gClientVehicle[client], client); // Force "him" to leave the vehicle
}

// Hostage improvements
public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "hostage_entity"))
		SDKHook(entity, SDKHook_Touch, OnHostageTouch);
}

// Improve the hostage AI !!! xD
public Action:OnHostageTouch(hostage, other)
{
	if (other)
	{
		new String:edictname[32];
		GetEdictClassname(other, edictname, 32);

		if (StrEqual("func_breakable", edictname) || StrEqual("func_breakable_surf", edictname))
		{
			BaseNPC_PlaySound(hostage, "physics/glass/glass_sheet_break3.wav");
			
			new health = Entity_GetHealth(other);
			if (health - 5 < 1)
				AcceptEntityInput(other, "Break");
			else
				SetEntProp(other, Prop_Data, "m_iHealth", health - 5);
		}
		else if ((StrEqual(edictname, "prop_physics")
				|| StrEqual(edictname, "prop_physics_multiplayer")
				|| StrEqual(edictname, "func_physbox"))
				&& Entity_GetHealth(other))
		{
			AcceptEntityInput(other, "Break");
		}
	}

	return (Plugin_Continue);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// reset object held
	gObj[client] = -1;
	gClientVehicle[client] = 0;

	return (Plugin_Continue);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// reset object held
	gObj[client] = -1;
	
	// Died driving vehicle?
	if (gClientVehicle[client] != 0)
		BaseVehicle_Leave(gClientVehicle[client], client); // Force "him" to leave it
	
	if (GetConVarBool(gAdvert))
		CPrintToChat(client, "{black}Entcontrol %s", PLUGIN_VERSION);

	return (Plugin_Continue);
}

/*
	------------------------------------------------------------------------------------------
	COMMANDS
	------------------------------------------------------------------------------------------
*/
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (gClientVehicle[client] != 0)
	{
		if (buttons & IN_MOVELEFT)
		{
			BaseVehicle_Turn(gClientVehicle[client], false);
		}
		else if (buttons & IN_MOVERIGHT)
		{
			BaseVehicle_Turn(gClientVehicle[client], true);
		}

		if (buttons & IN_FORWARD)
		{
			BaseVehicle_Move(gClientVehicle[client], false);
		}
		else if (buttons & IN_BACK)
		{
			BaseVehicle_Move(gClientVehicle[client], true);
		}
	}
	
	if (GetConVarBool(gNoneAdminsUseGrab))
	{
		if ((buttons & IN_ATTACK || buttons & IN_ATTACK2) && gObj[client] >= 1)
		{
			gObj[client] = -1;
		}
		else if (buttons & IN_USE && (gNextPickup[client] < GetGameTime()) && IsPlayerAlive(client))
		{
			gNextPickup[client] = GetGameTime() + 1.0;
			
			if (gObj[client] >= 1)
			{
				new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
				new Float:viewang[3];

				// get client info
				GetClientEyeAngles(client, viewang);
				GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
				GetClientEyePosition(client, vecPos);
				
				// update object 
				vecPos[0]+=vecDir[0]*100.0;
				vecPos[1]+=vecDir[1]*100.0;
				vecPos[2]+=vecDir[2]*100.0;

				GetEntPropVector(gObj[client], Prop_Send, "m_vecOrigin", vecDir);

				SubtractVectors(vecPos, vecDir, vecVel);
				ScaleVector(vecVel, 10.0);
				TeleportEntity(gObj[client], NULL_VECTOR, NULL_VECTOR, vecVel);

				gObj[client] = -1;
			}
			else
			{
				new ent;
				new Float:VecPos_Ent[3], Float:VecPos_Client[3];
				
				ent = TraceToEntity(client); // GetClientAimTarget(client);

				if (IsValidEntity(ent) && IsValidEdict(ent))
				{
					GetClientEyePosition(client, VecPos_Client);
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", VecPos_Ent);
					if(GetVectorDistance(VecPos_Client, VecPos_Ent) <= 128.0)
					{
						new String:edictname[64];
						GetEdictClassname(ent, edictname, 64);
						if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_physics_multiplayer") || StrEqual(edictname, "func_physbox"))
						{
							gObj[client] = EntIndexToEntRef(ent);
							gDistance[client] = 40.0;
						}
					}
				}
			}
		}
	}
	
	return (Plugin_Continue);
}

stock GrabSomething(client)
{
	if (CanUseCMD(client, gAdminFlagGrab))
	{
		new ent;
		new Float:VecPos_Ent[3], Float:VecPos_Client[3];
		
		if (GetConVarBool(gAdminCanGrabSelf)) // I know this might be slow ... but we need the ability to change the cvar every time
			ent = GetObject(client);
		else
			ent = GetObject(client, false);
		
		if (ent == -1)
			return;
		
		ent = EntRefToEntIndex(ent);
		
		if (ent == INVALID_ENT_REFERENCE)
			return;

		// only grab physics entities
		new String:edictname[128];
		GetEdictClassname(ent, edictname, 128);

		if (StrEqual(edictname, "player"))
		{
			if (!CanUseCMD(client, gAdminFlagGrabPlayer))
				return;
			
			PrintHintText(ent, "Admin %N is grabbing you", client);

			LogAction(client, ent, "%L grabbed %L", client, ent);
		}
		else
		{
			LogAction(client, 0, "%L grabbed %s", client, edictname);

			if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_physics_multiplayer"))
			{
				// Convert to prop_physics_override
				if (IsValidEdict(ent) && IsValidEntity(ent)) 
				{
					ent = ReplacePhysicsEntity(ent);
					
					SetEntPropEnt(ent, Prop_Data, "m_hPhysicsAttacker", client);
					SetEntPropFloat(ent, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
				}
			}
		}

		if (GetEntityMoveType(ent) == MOVETYPE_NONE)
		{
			if (strncmp("player", edictname, 5, false)!=0)
			{
				SetEntityMoveType(ent, MOVETYPE_VPHYSICS);

				PrintHintText(client, "Object ist now Unfreezed");
			}
			else
			{
				SetEntityMoveType(ent, MOVETYPE_WALK);
				return;
			}
		}

		gObj[client] = EntIndexToEntRef(ent);

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", VecPos_Ent);
		GetClientEyePosition(client, VecPos_Client);
		gDistance[client] = GetVectorDistance(VecPos_Ent, VecPos_Client, false);

		new Float:position[3];
		TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, position);
		
		EmitSoundToClient(client, "buttons/combine_button5.wav");
	}
}

public Action:Command_Grab(client, args)
{
	GrabSomething(client);

	return (Plugin_Handled);
}

public Action:Command_UnGrab(client, args)
{
	if (ValidGrab(client))
	{
		new String:edictname[128];
		GetEdictClassname(gObj[client], edictname, 128);
		
		if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_physics_multiplayer"))
			SetEntPropEnt(gObj[client], Prop_Data, "m_hPhysicsAttacker", 0);
	}
	
	gObj[client] = -1;
	
	return (Plugin_Handled);
}

public Action:Command_GrabToggle(client, args)
{
	if (gObj[client] != -1)
	{
		if (ValidGrab(client))
		{
			new String:edictname[128];
			GetEdictClassname(gObj[client], edictname, 128);
			
			if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_physics_multiplayer"))
				SetEntPropEnt(gObj[client], Prop_Data, "m_hPhysicsAttacker", 0);
		}
		
		gObj[client] = -1;
	}
	else
	{
		GrabSomething(client);
	}
	
	return (Plugin_Handled);
}

public Action:Command_Show_Info(client, args)
{
	if (client)
		ShowMOTDPanel(client, "EntControl-Information", "http://www.legone.name/entcontrol.html", 2);

	return (Plugin_Handled);
}

/* // Not supported right now
public Action:Command_Report_Bugs(client, args)
{
 	decl String:steamID[32];
 	decl String:url[120];
 
 	steamID[0] = '\0'; // Ripped from somewhere ... SourceIRC ? Oo

 	GetClientAuthString(client, steamID, sizeof(steamID));

	Format(url, sizeof(url), "http://www.legone.name/mantisbt/bug_report_page.php?Server=19&SteamID=%s", steamID);

	ShowMOTDPanel(client, "Bug-Report", url, 2);
	ShowMOTDPanel(client, "Bug-Report", url, 2);

	return (Plugin_Handled);
}
*/

/* 
	------------------------------------------------------------------------------------------
	MAIN TIMER/LOOP CODE
	------------------------------------------------------------------------------------------
*/
public Action:UpdateObjects(Handle:timer)
{
	new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
	new Float:viewang[3];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (ValidGrab(i))
		{
			// get client info
			GetClientEyeAngles(i, viewang);
			GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(i, vecPos);

			// update object
			vecPos[0]+=vecDir[0]*gDistance[i];
			vecPos[1]+=vecDir[1]*gDistance[i];
			vecPos[2]+=vecDir[2]*gDistance[i];
			
			GetEntPropVector(gObj[i], Prop_Send, "m_vecOrigin", vecDir);
			
			SubtractVectors(vecPos, vecDir, vecVel);
			ScaleVector(vecVel, 10.0);
			
			TeleportEntity(gObj[i], NULL_VECTOR, NULL_VECTOR, vecVel);
		}
	}
	
	return (Plugin_Continue);
}

public Action:UpdateHudInfoExtended(Handle:timer)
{
	new Float:vecPos[3];
	
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientConnectedIngame(i) && !IsFakeClient(i))
		{
			if (CanUseCMD(i, gAdminFlagHUD, false)) // This might be a little slow
			{
				GetPlayerEye(i, vecPos);

				for (new i2 = 1; i2 <= MaxClients; i2++) 
				{
					if (GetVectorDistance(vecPos, SprayPos[i2]) <= 40.0)
					{
						decl String:szText[250];
						Format(szText, sizeof(szText), "Sprayer: %s", SprayName[i2]);
						
						new Handle:hBuffer = StartMessageOne("KeyHintText", i);
						BfWriteByte(hBuffer, 1);
						BfWriteString(hBuffer, szText);
						EndMessage();

						break;
					}
				}
				
				// find entity
				new ent = GetObject(i, false);
				if (ent != -1)
				{
					new String:edictname[128];
					GetEdictClassname(ent, edictname, 128);

					if (StrEqual(edictname, "player") && IsPlayerAlive(ent))
						GetClientName(ent, edictname, sizeof(edictname));

					decl String:szText[64];
					Format(szText, sizeof(szText), "%s(%i)\nHP: %i", edictname, ent, GetEntProp(ent, Prop_Data, "m_iHealth"));
    
					new Handle:hBuffer = StartMessageOne("KeyHintText", i);
					BfWriteByte(hBuffer, 1);
					BfWriteString(hBuffer, szText);
					EndMessage();
					
					/*
					if (gSelectedEntity[i] != -1)
					{
						new Float:vEntPosition[3];
						GetEntPropVector(gSelectedEntity[i], Prop_Send, "m_vecOrigin", vEntPosition);
						vEntPosition[2] += 20.0;
						TE_SetupGlowSprite(vEntPosition, gSelectedEntitySprite, 1.0, 1.0, 255);
						TE_SendToClient(i);
					}
					*/
				}
			}
		}
	}
	
	return (Plugin_Continue);
}

public Action:UpdateHudInfoSimple(Handle:timer)
{
	new Float:vecPos[3];
	
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			if (CanUseCMD(i, gAdminFlagHUD, false)) // This might be a little slow
			{
				GetPlayerEye(i, vecPos);

				for (new i2 = 1; i2 <= MaxClients; i2++) 
				{
					if (GetVectorDistance(vecPos, SprayPos[i2]) <= 40.0)
					{
						decl String:szText[250];
						Format(szText, sizeof(szText), "Sprayer: %s", SprayName[i2]);
    
						PrintCenterText(i, szText);

						break;
					}
				}

				// find entity
				new ent = GetObject(i, false);
				if (ent != -1)
				{
					new String:edictname[128];
					GetEdictClassname(ent, edictname, 128);

					if (StrEqual(edictname, "player") && IsPlayerAlive(ent))
						GetClientName(ent, edictname, sizeof(edictname));
    
					PrintCenterText(i, edictname);
				}
			}
		}
	}
	
	return (Plugin_Continue);
}