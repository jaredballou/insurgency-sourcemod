//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.2"
#define PLUGIN_DESCRIPTION "Adds backblast to rocket based weapons"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-backblast.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

new Handle:cvarDamageRange = INVALID_HANDLE;
new Handle:cvarMaxRange = INVALID_HANDLE;
new Handle:cvarConeAngle = INVALID_HANDLE;
new Handle:cvarDamage = INVALID_HANDLE;
new Handle:cvarWallDistance = INVALID_HANDLE;

new Float:g_fDamageRange = 15.0;
new Float:g_fMaxRange = 25.0;
new Float:g_fConeAngle = 90.0;
new Float:g_fDamage = 80.0;
new Float:g_fWallDistance = 5.0;

new g_iFlashDuration = -1;
new g_iFlashAlpha = -1;

//new Handle: = INVALID_HANDLE;

public Plugin:myinfo = {
	name= "[INS] Backblast",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	if ((g_iFlashDuration = FindSendPropOffs("CINSPlayer", "m_flFlashDuration")) == -1)
		SetFailState("[BACKBLAST] Failed to find \"m_flFlashDuration\".");
	if ((g_iFlashAlpha = FindSendPropOffs("CINSPlayer", "m_flFlashMaxAlpha")) == -1)
		SetFailState("[BACKBLAST] Failed to find \"m_flFlashMaxAlpha\".");

	cvarVersion = CreateConVar("sm_backblast_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_backblast_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarDamage = CreateConVar("sm_backblast_damage", "80", "Max damage from backblast", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarDamageRange = CreateConVar("sm_backblast_damage_range", "15", "Distance in meters from firing to hurt players in backblast", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxRange = CreateConVar("sm_backblast_max_range", "25", "Max range for backblast to affect players visually", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarConeAngle = CreateConVar("sm_backblast_cone_angle", "90", "Angle behind firing to include in backblast effect", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarWallDistance = CreateConVar("sm_backblast_wall_distance", "5", "Distance in meters to wall where player firing will hurt himself", FCVAR_NOTIFY | FCVAR_PLUGIN);

	HookConVarChange(cvarDamageRange, OnSettingsChange);
	HookConVarChange(cvarMaxRange, OnSettingsChange);
	HookConVarChange(cvarConeAngle, OnSettingsChange);
	HookConVarChange(cvarDamage, OnSettingsChange);
	HookConVarChange(cvarWallDistance, OnSettingsChange);

	HookEvent("weapon_fire", Event_WeaponFired);

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == cvarDamageRange)
		g_fDamageRange = StringToFloat(newvalue);
	else if(cvar == cvarMaxRange)
		g_fMaxRange = StringToFloat(newvalue);
	else if(cvar == cvarConeAngle)
		g_fConeAngle = StringToFloat(newvalue);
	else if(cvar == cvarDamage)
		g_fDamage = StringToFloat(newvalue);
	else if(cvar == cvarWallDistance)
		g_fWallDistance = StringToFloat(newvalue);
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public Action:Event_WeaponFired(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:shotWeapName[32];
	GetClientWeapon(client, shotWeapName, sizeof(shotWeapName));
	if (
		(StrContains(shotWeapName,"weapon_at4") > -1)
		|| (StrContains(shotWeapName,"weapon_rpg") > -1)
	) {
		DoBackblast(client);
	}
	return Plugin_Continue;
}

public DoBackblast(client)
{
	new Float:distance;
	new String:name[32];
	new Float:fTargetPosition[3];
	new Float:fClientPosition[3];
	GetClientEyePosition(client, fClientPosition);
	new Float:fHalfCone = (g_fConeAngle * 0.5);
	new Handle:hTrace = INVALID_HANDLE;

	//new Float:fGameTime = GetGameTime();
	PrintToServer("[BACKBLAST] Called DoBackblast");
	for(new target=1; target<= MaxClients; target++)
	{
		if(!IsValidEntity(target))
		{
			continue;
		}
		if(!(IsClientInGame(target)) || (target == client) || (IsFakeClient(target)))
		{
			continue;
		}
		if(GetEdictClassname(target, name, sizeof(name)))
		{
			if (StrContains(name,"player") > -1)
			{
				GetClientEyePosition(target, fTargetPosition);
				new Float:fAngle = GetViewAngleToTarget(client, target);//,35.0,true,true);
				distance = (GetVectorDistance(fClientPosition, fTargetPosition) * 0.01905);
				PrintToServer("[BACKBLAST] Player %N backblast found %N distance %f fAngle %f g_fConeAngle %f fHalfCone %f",client,target,distance,fAngle,g_fConeAngle,fHalfCone);
				if ((fAngle > (180.0 - fHalfCone)) && (fAngle < (180.0 + fHalfCone)))
				{
					if (distance < g_fMaxRange)
					{
						PrintToServer("[BACKBLAST] Player %N backblast within cone and range for %N",client,target);
						hTrace = TR_TraceRayFilterEx(fClientPosition, fTargetPosition, MASK_SOLID, RayType_EndPoint, Filter_ClientSelf, client);
						if (!TR_DidHit(hTrace)) {
							PrintToServer("[BACKBLAST] Player %N backblast would BLIND %N",client,target);
							SetEntDataFloat(target, g_iFlashAlpha, 0.75);
							SetEntDataFloat(target, g_iFlashDuration, GetRandomFloat(3.0, 6.0));
							if (distance < g_fDamageRange)
							{
								PrintToServer("[BACKBLAST] Player %N backblast would HURT %N",client,target);
							}
						}
					}
				}
			}
		}
	}
	new Float:anglevector[3], Float:endpos[3];
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);

	PrintToServer("[BACKBLAST] Player %N anglevector %f",client,anglevector[1]);
	hTrace = TR_TraceRayFilterEx(fClientPosition, anglevector, MASK_SOLID, RayType_Infinite, Filter_ClientSelf, client);
	if (TR_DidHit(hTrace)) {
		TR_GetEndPosition(endpos);
		distance = (GetVectorDistance(fClientPosition, endpos) * 0.01905);
		PrintToServer("[BACKBLAST] Player %N hit wall behind at %0.2f meters g_fDamage %f g_fWallDistance %f",client,distance,g_fDamage,g_fWallDistance);
	}
	CloseHandle(hTrace);
}
public bool:Filter_ClientSelf(entity, contentsMask, any:client)
{
	if (entity != client)
	{
		return true;
	}
	return false;
}
stock Float:GetViewAngleToTarget(client, target)
{
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle;
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	return resultangle;
}
