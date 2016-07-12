#include <sourcemod>
#include <sdktools>
#include <insurgency>

#define VERSION "1.3"

new Handle:g_CvarEnable = INVALID_HANDLE;

new g_sprite;
//new g_lasers[MAXPLAYERS+1];
public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Plugin:myinfo =
{
	name = "Laser Aim",
	author = "Leonardo",
	description = "Creates A Beam For every times when player holds in arms a Snipers Rifle",
	version = VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_laser_aim", VERSION, "1 turns the plugin on 0 is off", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarEnable = CreateConVar("sm_laser_aim_on", "0", "1 turns the plugin on 0 is off", FCVAR_NOTIFY);
}

public OnGameFrame()
{
	for (new i=1; i<=MaxClients; i++)
	{
		//new client = GetClientOfUserId(i);
		if(IsClientInGame(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			if(GetConVarBool(g_CvarEnable))
				CreateBeam(i);
		}
	}
}

public Action:CreateBeam(any:client)
{
	new Float:f_playerViewOrigin[3];
	GetClientAbsOrigin(client, f_playerViewOrigin);
	if(GetClientButtons(client) & IN_DUCK)
		f_playerViewOrigin[2] += 40;
	else
		f_playerViewOrigin[2] += 60;

	new Float:f_playerViewDestination[3];
	GetPlayerEye(client, f_playerViewDestination);

	new Float:distance = GetVectorDistance( f_playerViewOrigin, f_playerViewDestination );
	new Float:percentage = 0.4 / ( distance / 100 );
	new Float:life = 0.1;
	new Float:width = 0.4;

	new Float:f_newPlayerViewOrigin[3];
	f_newPlayerViewOrigin[0] = f_playerViewOrigin[0] + ( ( f_playerViewDestination[0] - f_playerViewOrigin[0] ) * percentage );
	f_newPlayerViewOrigin[1] = f_playerViewOrigin[1] + ( ( f_playerViewDestination[1] - f_playerViewOrigin[1] ) * percentage ) - 0.08;
	f_newPlayerViewOrigin[2] = f_playerViewOrigin[2] + ( ( f_playerViewDestination[2] - f_playerViewOrigin[2] ) * percentage );

	new color[4];
	new team = GetClientTeam(client);
	color[0] = 255;
	color[1] = 255;
	color[2] = 255;
	color[3] = 255;
	if (team == _:TEAM_SECURITY)
	{
		color[0] = 0;
		color[1] = 0;
	}
	else if (team == _:TEAM_INSURGENTS)
	{
		color[1] = 0;
		color[2] = 0;
	}
	TE_SetupBeamPoints( f_newPlayerViewOrigin, f_playerViewDestination, g_sprite, 0, 0, 0, life, width, width, 0, 0, color, 0 );
	TE_SendToAll();
	
/*
	if (g_lasers[client])
	{
		new String:name[64];
		GetEdictClassname(g_lasers[client], name, sizeof(name));
		if(!StrEqual(name, "env_beam"))
			g_lasers[client] = -1;
	}
	if (!g_lasers[client])
	{
		g_lasers[client] = CreateEntityByName("env_beam");
		TeleportEntity(g_lasers[client], f_playerViewOrigin, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(g_lasers[client], "materials/sprites/laserbeam.vmt");
		SetEntPropVector(g_lasers[client], Prop_Data, "m_vecEndPos", f_playerViewDestination);
		DispatchKeyValue(g_lasers[client], "rendercolor", "255 255 255");
		DispatchKeyValue(g_lasers[client], "renderamt", "100");
		DispatchSpawn(g_lasers[client]);
		DispatchKeyValue(g_lasers[client], "targetname", "beam");
		SetEntPropFloat(g_lasers[client], Prop_Data, "m_fWidth", 4.0); // how big the beam will be, i.e "4.0"
		SetEntPropFloat(g_lasers[client], Prop_Data, "m_fEndWidth", 4.0); // same as above
		ActivateEntity(g_lasers[client]);
		AcceptEntityInput(g_lasers[client], "TurnOn");
	}
	SetEntPropVector(g_lasers[client], Prop_Data, "m_vecEndPos", f_playerViewDestination);
	if (team == _:TEAM_SECURITY)
	{
		DispatchKeyValue(g_lasers[client], "rendercolor", "0 0 255");
	}
	else if (team == _:TEAM_INSURGENTS)
	{
		DispatchKeyValue(g_lasers[client], "rendercolor", "255 0 0");
	}
	else
	{
		DispatchKeyValue(g_lasers[client], "rendercolor", "255 255 255");
	}
*/
	return Plugin_Continue;
}

bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
return entity > GetMaxClients();
}
