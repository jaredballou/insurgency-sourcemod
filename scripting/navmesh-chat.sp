#include <sourcemod>
#include <sdktools>
#include <scp>
#include <navmesh>
#include <smlib>
#include <loghelper>
#pragma unused cvarVersion
#define PLUGIN_VERSION				"0.0.1"
#define PLUGIN_DESCRIPTION "Puts navmesh area into chat"

new Handle:g_hNavMeshPlaces;
new bool:g_bOverviewLoaded = false;
new g_iOverviewPosX = 0;
new g_iOverviewPosY = 0;
new g_iOverviewRotate = 0;
new Float:g_fOverviewScale = 1.0;
new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?

public Plugin:myinfo =
{
	name = "[INS] Navmesh Chat",
	author = "Jared Ballou",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_navmesh_chat_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_navmesh_chat_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	//RegConsoleCmd("say_team", Command_SendToTeam);
	if (!g_bOverviewLoaded) {
		OnMapStart();
	}
	RegConsoleCmd("get_grid", Get_Grid);
//	RegAdminCmd("sm_get_cplist", Command_CPList, ADMFLAG_GENERIC, "sm_CPList");
}

public Action:Get_Grid(client, args)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Handled;
	}
	decl Float:flEyePos[3],String:sGridPos[2];
	GetClientEyePosition(client, flEyePos);
	GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));
	PrintHintText(client, "You are in grid %s",sGridPos);
	return Plugin_Handled;
}
public Get_ControlPoints()
{
	PrintToServer("[NMchat] Running Get_ControlPoints");
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if((StrEqual("point_controlpoint", name,false)) || (StrEqual("obj_weapon_cache", name,false))){
				decl String:entity_name[128];
				GetEntPropString(i, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
				PrintToServer("[NMchat] Found point named %s",entity_name);
				new Float:position[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
			}
		}
	}

}
public OnMapStart()
{
	g_hNavMeshPlaces = NavMesh_GetPlaces();
	OverviewDestroy();
	decl String:sMap[256];
	GetCurrentMap(sMap, sizeof(sMap));
	g_bOverviewLoaded = OverviewLoad(sMap);
}

OverviewDestroy()
{
	return;
}

bool:OverviewLoad(const String:sMapName[])
{
	PrintToServer("[NMchat]: start OverviewLoad");
	decl String:sOverviewFilePath[PLATFORM_MAX_PATH];
	Format(sOverviewFilePath, sizeof(sOverviewFilePath), "maps\\overviews\\%s.txt", sMapName);
	if (!FileExists(sOverviewFilePath)) {
		Format(sOverviewFilePath, sizeof(sOverviewFilePath), "resource\\overviews\\%s.txt", sMapName);
	}
	if (!FileExists(sOverviewFilePath)) {
		PrintToServer("[NMchat]: OverviewLoad cannot find suitable overview file!");
		return false;
	}
	PrintToServer("[NMchat]: OverviewLoad sOverviewFilePath is %s",sOverviewFilePath);
	new Handle:g_hNavMeshKeyValues = CreateKeyValues(sMapName);
	FileToKeyValues(g_hNavMeshKeyValues,sOverviewFilePath);
	g_iOverviewPosX = KvGetNum(g_hNavMeshKeyValues, "pos_x", 0);
	g_iOverviewPosY = KvGetNum(g_hNavMeshKeyValues, "pos_y", 0);
	g_iOverviewRotate = KvGetNum(g_hNavMeshKeyValues, "rotate", 0);
	g_fOverviewScale = KvGetFloat(g_hNavMeshKeyValues, "scale", 1.0);
	PrintToServer("[NMchat]: OverviewLoad KeyValues parsed: pos_x %d pos_y %d rotate %d scale %f", g_iOverviewPosX, g_iOverviewPosY, g_iOverviewRotate, g_fOverviewScale);
 
	CloseHandle(g_hNavMeshKeyValues);
	return true;
/*
		KvJumpToKey(g_hNavMeshKeyValues, "places", true);
			KvSetString(g_hNavMeshKeyValues, sBuffer, sPlaceName);
		KvGoBack(g_hNavMeshKeyValues);

						KvSetNum(g_hNavMeshKeyValues,sBuffer,iDirection);
*/
}
public Action:Command_SendToTeam(client, args)
{
	PrintMessageTeam(client);

	return Plugin_Handled;
}

stock GetGridPos(Float:position[3],String:buffer[], size)
{
	Format(buffer,size, "XX");
	if (!NavMesh_Exists()) return -2;
	decl Float:flMapPos[3],iGridPos[3];
	new String:sLetters[27]=".ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	flMapPos[0] = FloatAbs(FloatDiv((position[0] - float(g_iOverviewPosX)), g_fOverviewScale));
	flMapPos[1] = FloatAbs(FloatDiv((position[1] - float(g_iOverviewPosY)), g_fOverviewScale));
	iGridPos[0] = RoundToFloor(FloatDiv(flMapPos[0], 128.0))+1;
	iGridPos[1] = RoundToFloor(FloatDiv(flMapPos[1], 128.0))+1;
	Format(buffer,size, "%c%d",sLetters[iGridPos[0]],iGridPos[1]);
//	PrintHintText(client, "Raw position is %f,%f calculated to %f,%f grid %c%d",position[0],position[1],flMapPos[0],flMapPos[1],sLetters[iGridPos[0]],iGridPos[1]);
//	ShowSyncHudText(client, hHudText, "%s",sDisplay);
//	CloseHandle(hHudText);
	return true;
}

stock GetPlaceName(Float:position[3], String:buffer[], size, bool:bReturnRaw=false)
{
	Format(buffer,size, "");
	if (!NavMesh_Exists()) return -2;
	new iAreaIndex = NavMesh_GetNearestArea(position);
	if (iAreaIndex != -1)
	{
		new Handle:hAreas = NavMesh_GetAreas();
		new iPlaceID = GetArrayCell(hAreas, iAreaIndex, NavMeshArea_PlaceID);
		if (iPlaceID) {
			GetArrayString(g_hNavMeshPlaces, (iPlaceID-1), buffer, size);
		} else {
			if (bReturnRaw) {
				Format(buffer,size, "A[%d]",iAreaIndex);
			}
		}
	}
	return iAreaIndex;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "scp"))
	{
		SetFailState("Simple Chat Processor Unloaded.  Plugin Disabled.");
	}
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	new index = CHATCOLOR_NOSUBJECT;
	decl String:sNameBuffer[MAXLENGTH_NAME],Float:flEyePos[3],String:sGridPos[16],String:sPlace[64];
        GetClientEyePosition(author, flEyePos);
	GetPlaceName(flEyePos,sPlace,sizeof(sPlace));
        GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));
	Format(sNameBuffer, sizeof(sNameBuffer), "{G}(%s) %s {T}%s", sGridPos, sPlace, name);
	Color_ChatSetSubject(author);
	index = Color_ParseChatText(sNameBuffer, name, MAXLENGTH_NAME);
	Color_ChatClearSubject();
	author = index;
	return Plugin_Changed;
}




stock Action:PrintMessageTeam(client)
{
	/* Get the name */
	decl String:sName[MAXLENGTH_NAME];
//	decl String:sNameBuffer[MAXLENGTH_NAME];
	GetClientName(client, sName, sizeof(sName));
	//Color_StripFromChatText(sNameBuffer, sName, MAXLENGTH_NAME);

	decl Float:flEyePos[3],String:sGridPos[2],String:sPlace[64];
        GetClientEyePosition(client, flEyePos);
	GetPlaceName(flEyePos,sPlace,sizeof(sPlace));
        GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));

	/* Get the team */
	new team = GetClientTeam(client);

	/* Get the message */
	decl String:sTextToTeam[1024],String:sMessageBuffer[MAXLENGTH_INPUT],String:sMessage[MAXLENGTH_INPUT];
//	decl String:sTextBuffer[MAXLENGTH_INPUT];
	GetCmdArgString(sTextToTeam, sizeof(sTextToTeam));
	StripQuotes(sTextToTeam);

	LogPlayerEvent(client, "say_team", sTextToTeam);

//	Color_ChatSetSubject(client);
	Format(sMessageBuffer,sizeof(sMessageBuffer),"{G}(%s)", sPlace);
	Color_ParseChatText(sMessageBuffer, sMessage, MAXLENGTH_INPUT);

	/* Put parts in one piece */
	/* Chat trigger */
	if(IsChatTrigger())
	{
		return Plugin_Continue;
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new PlayersTeam = GetClientTeam(i);
				if(PlayersTeam & team)
				{
					PrintToServer("[Chat] Sending");
					new clientid[1];
					clientid[0] = i;
					Client_PrintToChatEx(clientid,1,true,"(%s) %s %s: %s",sGridPos,sMessage,sName,sTextToTeam);
				}
			}
		}
	}
	return Plugin_Stop;
}
