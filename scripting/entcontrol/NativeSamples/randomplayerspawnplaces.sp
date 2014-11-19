/* 
	------------------------------------------------------------------------------------------
	EntControl::NativeSamples::RandomPlayerSpawnPlaces
	by Raffael 'LeGone' Holz
	
	This sample demonstrates the ability, to spawn players on random spawnplaces
	using the nav-mesh. There is no need to create extra-playerstarts this way.
	------------------------------------------------------------------------------------------
*/

#include <sourcemod>
#include <sdktools>
#include <entcontrol>

new bool:navMeshLoaded = false;

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	RegAdminCmd("sm_teletoranpos", Command_TeleportToRandomPos, ADMFLAG_GENERIC);
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", OnPlayerSpawn);
}

/* 
	------------------------------------------------------------------------------------------
	OnMapStart
	Store all the positions once. Only if there is a valid navmesh.
	------------------------------------------------------------------------------------------
*/
public OnMapStart()
{
	// Load the nav-mesh of the current map
	if (EC_Nav_Load())
	{
		// Cache positions
		if (EC_Nav_CachePositions())
		{
			// Positions stored
			navMeshLoaded = true;
		}
		else
		{
			PrintToServer("Unable to cache positions!");
		}
	}
	else
	{
		PrintToServer("No Navigation loaded! Make sure the .nav is not packed in one of the .vpk-files.");
	}
}

public OnMapEnd()
{
	navMeshLoaded = false;
}

/* 
	------------------------------------------------------------------------------------------
	OnPlayerSpawn
	Teleport player to a "random" spawn position after has been spawned
	------------------------------------------------------------------------------------------
*/
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	TeleToRandomPosition(client);
	
	return (Plugin_Continue);
}

public TeleToRandomPosition(client)
{
	new Float:position[3];
	if (navMeshLoaded && EC_Nav_GetNextHidingSpot(position))
	{
		position[2] += 10.0;
		
		TeleportEntity(client, position, NULL_VECTOR, Float:{10.0, 10.0, 10.0});
		
		new checksum = RoundToFloor(position[0] + position[1] + position[2]);
		
		new Handle:data;
		CreateDataTimer(0.1, CheckStuckTimer, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, client);
		WritePackCell(data, checksum);
	}
}

public Action:CheckStuckTimer(Handle:Timer, Handle:data)
{
	new Float:position[3];
	
	ResetPack(data);
	new client = ReadPackCell(data);
	new checksum = ReadPackCell(data);

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	new checksumNow = RoundToFloor(position[0] + position[1] + position[2]);
	
	checksumNow = checksum-checksumNow;
	
	if (checksumNow > -1 && checksumNow < 1)
		TeleToRandomPosition(client);
	
	return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	COMMAND_TELEPORTTORANDOMPOS
	THis function will spawn a zombie on the players-aim-position
	------------------------------------------------------------------------------------------
*/
public Action:Command_TeleportToRandomPos(client, args)
{
	TeleToRandomPosition(client);

	return (Plugin_Handled);
}
