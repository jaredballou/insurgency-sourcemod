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
	if (!g_bOverviewLoaded) {
		OnMapStart();
	}
	RegConsoleCmd("get_grid", Get_Grid);
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
	new chatflags = GetMessageFlags();
	if (chatflags & CHATFLAGS_TEAM) {
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
	return Plugin_Continue;
}
