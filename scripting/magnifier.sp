#pragma semicolon 1
#include <sourcemod>

new Handle:zoomlevel = INVALID_HANDLE;

#define VERSION "3.0"

new bool:bInMagnifier[MAXPLAYERS+1] = {false, ...};

new Handle:g_CVarAdmFlag;
new g_AdmFlag;

new Handle:nobloqueardisparos;

new zoomlevel_int;
new bool:noshotsblocked;

new fov_client[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[INS] Magnifier",
	author = "Jared Ballou",
	description = "Allow toggle for magnifier in zoom",
	version = VERSION,
	url = "www.jballou.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_magnifier", ToggleMagnifier);

	HookEventEx("weapon_zoom", EventWeaponZoom);
	HookEvent("player_spawn", Event_Player_Spawn);


        zoomlevel = CreateConVar("sm_magnifier_zoom", "60", "zoom level for magnifier", 0, true, 1.0);
        CreateConVar("sm_magnifier_version", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

        nobloqueardisparos = CreateConVar("sm_magnifier_shots", "0", "Allow or disallow shots while using magnifier. 1 = allow. 0 = disallow.");
	g_CVarAdmFlag = CreateConVar("sm_magnifier_adminflag", "0", "Admin flag required to use magnifier. 0 = No flag needed. Can use a b c ....");

	HookConVarChange(g_CVarAdmFlag, CVarChange);
	HookConVarChange(zoomlevel, CVarChange2);
	HookConVarChange(nobloqueardisparos, CVarChange2);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_AdmFlag = ReadFlagString(newValue);
}

public CVarChange2(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}


public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	fov_client[client] = GetEntProp(client, Prop_Send, "m_iFOV"); // get default fov
	bInMagnifier[client] = false;
}

public Action:ToggleMagnifier(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
	}


	if ((g_AdmFlag > 0) && !CheckCommandAccess(client, "sm_magnifier", g_AdmFlag, true)) 
        {
		PrintToChat(client, "\x03[SM_magnifier] \x04You do not have access");
		return Plugin_Handled;
	}

        if(!IsPlayerAlive(client))
        {
		PrintToChat(client, "\x03[SM_magnifier] \x04you must be alive");
		return Plugin_Handled;
	}

        if(!bInMagnifier[client])
        {
		SetEntProp(client, Prop_Send, "m_iFOV", zoomlevel_int);
		PrintToChat(client, "\x03[SM_magnifier] \x04Now you use magnifier");
		bInMagnifier[client] = true;
        }
        else
        { 
		SetEntProp(client, Prop_Send, "m_iFOV", fov_client[client]);
		PrintToChat(client, "\x03[SM_magnifier] \x04magnifier removed");
		bInMagnifier[client] = false;
        }
	new zoomactual = GetEntProp(client, Prop_Send, "m_iFOV");
	PrintToChat(client, "\x03[SM_magnifier] \x04 fov %d inmag %b fov_c %d",zoomactual,bInMagnifier[client],fov_client[client]);
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{   
  	return Plugin_Continue; 
  	if(!noshotsblocked)
  	{
		if(buttons & IN_ATTACK) 
		{ 

			if(!bInMagnifier[client]) return Plugin_Continue; 

			new zoomactual = GetEntProp(client, Prop_Send, "m_iFOV");
			if(zoomactual != 90 && zoomactual != 0)
			{
				PrintToChat(client, "\x03[SM_magnifier] \x04you cant attack while using magnifier");
				buttons &= ~IN_ATTACK;
			}
		}
  	}
  	return Plugin_Continue; 
} 


public Action:EventWeaponZoom(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new zoomactual = GetEntProp(client, Prop_Send, "m_iFOV");
	PrintToChat(client, "\x03[SM_magnifier] \x04 zoomactual %s inmag %b",zoomactual,bInMagnifier[client]);
	bInMagnifier[client] = false;
}


// Get new values of cvars if they has being changed
public GetCVars()
{
	noshotsblocked = GetConVarBool(nobloqueardisparos);
	zoomlevel_int = GetConVarInt(zoomlevel);
}


// Easy ;D



// si quieres aprender a hacer plugins visita www.servers-cfg.foroactivo.com y registrate
// tenemos un apartado para ello
