/* 
	------------------------------------------------------------------------------------------
	EntControl::NativeSamples::SpawnNPC
	by Raffael 'LeGone' Holz
	Idea by Franc1sco
	
	Spawn zombie-NPC on the position the caller is looking at.
	------------------------------------------------------------------------------------------
*/

#include <sourcemod>
#include <sdktools>
#include <entcontrol>

public OnPluginStart()
{
	RegAdminCmd("sm_spawn_zombie", Command_Spawn_Zombie, ADMFLAG_GENERIC);
}

/* 
	------------------------------------------------------------------------------------------
	COMMAND_SPAWN_ZOMBIE
	THis function will spawn a zombie on the players-aim-position
	------------------------------------------------------------------------------------------
*/
public Action:Command_Spawn_Zombie(client, args)
{
	new Float:position[3];

	if (GetPlayerEye(client, position))
		EC_NPC_Spawn("npc_zombie", position[0], position[1], position[2]);
	else
		PrintHintText(client, "Wrong Position!"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	GETPLAYEREYE
	Will return the aim-position
	This code was borrowed from Nican's spraytracer
	------------------------------------------------------------------------------------------
*/
stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return (true);
	}

	CloseHandle(trace);
	return (false);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}