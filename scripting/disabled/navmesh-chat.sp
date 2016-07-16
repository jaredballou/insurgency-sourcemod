#include <sourcemod>
#include <sdktools>
#include <scp>
#include <navmesh>
#include <smlib>
#include <loghelper>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma unused cvarVersion
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Puts navmesh area into chat"
#define PLUGIN_NAME "[INS] Navmesh Chat"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-navmesh-chat.txt"

new Handle:g_hNavMeshPlaces;
new bool:g_bOverviewLoaded = false;
new g_iOverviewPosX = 0;
new g_iOverviewPosY = 0;
new g_iOverviewRotate = 0;
new Float:g_flOverviewGridDivisions = 8.0;
new Float:g_fOverviewScale = 1.0;

new Handle:h_DisplayPrint;

new Handle:cvarVersion = INVALID_HANDLE;
new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarTeamOnly = INVALID_HANDLE;
new Handle:cvarGrid = INVALID_HANDLE;
new Handle:cvarPlace = INVALID_HANDLE;
new Handle:cvarDistance = INVALID_HANDLE;
new Handle:cvarDirection = INVALID_HANDLE;

public OnPluginStart()
{
//	LoadTranslations("insurgency.phrases");
	cvarVersion = CreateConVar("sm_navmesh_chat_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_navmesh_chat_enabled", "1", "sets whether this plugin is enabled", FCVAR_NOTIFY);
	cvarTeamOnly = CreateConVar("sm_navmesh_chat_teamonly", "1", "sets whether to prepend to all messages or just team messages", FCVAR_NOTIFY);
	cvarGrid = CreateConVar("sm_navmesh_chat_grid", "1", "Include grid coordinates", FCVAR_NOTIFY);
	cvarPlace = CreateConVar("sm_navmesh_chat_place", "1", "Include place name from navmesh", FCVAR_NOTIFY);
	cvarDistance = CreateConVar("sm_navmesh_chat_distance", "1", "Include distance to speaker", FCVAR_NOTIFY);
	cvarDirection = CreateConVar("sm_navmesh_chat_direction", "1", "Include direction to speaker", FCVAR_NOTIFY);
	HookUserMessage(GetUserMessageId("VoiceSubtitle"), VoiceHook, true);
	if (!g_bOverviewLoaded) {
		OnMapStart();
	}
	RegConsoleCmd("get_grid", Get_Grid);
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public Action:VoiceHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new clientid = BfReadByte(bf);
	decl String:message[256];
	BfReadString(bf, message, sizeof(message));
	//PrintToServer("[NMchat]: VoiceHook called for %N clientid: %d, message: %s",clientid,clientid,message);
	if(IsPlayerAlive(clientid) && IsClientInGame(clientid) && GetConVarBool(cvarEnabled))
	{
		new String:clientname[64];
		GetClientName(clientid, clientname, sizeof(clientname));

		decl String:sNameBuffer[MAXLENGTH_NAME],String:sTranslated[64],Float:flEyePos[3],String:sGridPos[16],String:sPlace[64];
	        GetClientEyePosition(clientid, flEyePos);
		GetPlaceName(flEyePos,sPlace,sizeof(sPlace));
	        GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));
		//Color_ChatSetSubject(clientid);
		Format(sNameBuffer,sizeof(sNameBuffer), "%s%s%s{T}%s", sGridPos, sPlace, sNameBuffer, clientname);
		//Color_ParseChatText(sNameBuffer, clientname, MAXLENGTH_NAME);
		Format(sTranslated, sizeof(sTranslated), "radial_%s_subtitle", message);
		StartDataTimer(clientid, String:sNameBuffer, String:sTranslated);
//		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public StartDataTimer(clientid, String:clientname[], String:message[])
{
	//PrintToServer("[NMchat]: StartDataTimer(clientid=%d, String:clientname[]=%s, String:message[]=%s)",clientid,clientname,message);
	CreateDataTimer(0.1, SubTitle_Print, h_DisplayPrint);
	WritePackCell(h_DisplayPrint, clientid);
	WritePackString(h_DisplayPrint, clientname);
	WritePackString(h_DisplayPrint, message);
}
public Action:SubTitle_Print(Handle:timer, Handle:h_DisplayPrint)
{
	//PrintToServer("[NMchat]: Called SubTitle_Print");
	new String:clientname[64];
	new String:message[256];
	new Float:senderOrigin[3];
	new Float:receiverOrigin[3];
	new Float:distance;
	new Float:dist;
	new Float:vecPoints[3];
	new Float:vecAngles[3];
	new Float:receiverAngles[3];
	decl String:sDistance[64];
	new String:textToPrint[256];
	decl String:sGridPos[16],String:sPlace[64];

	ResetPack(h_DisplayPrint);
	new clientid = ReadPackCell(h_DisplayPrint);
	ReadPackString(h_DisplayPrint, clientname, sizeof(clientname));
	ReadPackString(h_DisplayPrint, message, sizeof(message));
	GetClientEyePosition(clientid, senderOrigin);
	GetPlaceName(senderOrigin,sPlace,sizeof(sPlace));
        GetGridPos(senderOrigin,sGridPos,sizeof(sGridPos));

	//Color_ChatSetSubject(clientid);

	for(new receiver = 1; receiver <= MaxClients; receiver++)
	{
		if ((IsClientInGame(receiver) && GetClientTeam(clientid) == GetClientTeam(receiver)) && (clientid != receiver))
		{
			GetDistanceDirection(receiver,senderOrigin,sDistance,sizeof(sDistance));
			Format(textToPrint,sizeof(textToPrint),"%s%s%s",sGridPos,sPlace,sDistance);
			//PrintToServer("[NMchat]: Sending message to client %d",receiver);
			Client_PrintToChat(receiver,true,textToPrint);
//			PrintToChat(receiver,textToPrint);
		}
	}
	//Color_ChatClearSubject();
//	return Plugin_Handled;
	return Plugin_Continue;
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
	//PrintToServer("[NMchat]: start OverviewLoad");
	decl String:sOverviewFilePath[PLATFORM_MAX_PATH];
	Format(sOverviewFilePath, sizeof(sOverviewFilePath), "insurgency-data\\resource\\overviews\\%s.txt", sMapName);
	if (!FileExists(sOverviewFilePath)) {
		//PrintToServer("[NMchat]: OverviewLoad cannot find suitable overview file!");
		return false;
	}
	//PrintToServer("[NMchat]: OverviewLoad sOverviewFilePath is %s",sOverviewFilePath);
	new Handle:g_hNavMeshKeyValues = CreateKeyValues(sMapName);
	FileToKeyValues(g_hNavMeshKeyValues,sOverviewFilePath);
	g_iOverviewPosX = KvGetNum(g_hNavMeshKeyValues, "pos_x", 0);
	g_iOverviewPosY = KvGetNum(g_hNavMeshKeyValues, "pos_y", 0);
	g_iOverviewRotate = KvGetNum(g_hNavMeshKeyValues, "rotate", 0);
	g_fOverviewScale = KvGetFloat(g_hNavMeshKeyValues, "scale", 1.0);
	g_flOverviewGridDivisions = KvGetFloat(g_hNavMeshKeyValues, "grid_divisions", 8.0);
	PrintToServer("[NMchat]: OverviewLoad KeyValues parsed: pos_x %d pos_y %d rotate %d scale %f grid_divisions %f", g_iOverviewPosX, g_iOverviewPosY, g_iOverviewRotate, g_fOverviewScale,g_flOverviewGridDivisions);
 
	CloseHandle(g_hNavMeshKeyValues);
	return true;
}
stock GetDistanceDirection(client,Float:endpos[3],String:buffer[], size)
{
	Format(buffer,size,"");
	if (!GetConVarBool(cvarDistance)) {
		return -1;
	}
	new String:clientname2[64];
	new String:message2[256];
	new Float:origin[3];
	new Float:distance;
	new Float:dist;
	new Float:vecPoints[3];
	new Float:vecAngles[3];
	new Float:receiverAngles[3];
	decl String:directionString[64];
	new String:textToPrint[256];

	GetClientAbsOrigin(client, origin);
	distance = GetVectorDistance(origin, endpos);
	dist = distance * 0.01905;
	GetClientAbsAngles(client, receiverAngles);
	MakeVectorFromPoints(origin, endpos, vecPoints);
	GetVectorAngles(vecPoints, vecAngles);
	new Float:diff = receiverAngles[1] - vecAngles[1];

	if (diff < -180)
	{
		diff = 360 + diff;
	}
	if (diff > 180)
	{
		diff = 360 - diff;
	}


	// Now geht the direction
	// Up
	if (diff >= -22.5 && diff < 22.5)
	{
		Format(directionString, sizeof(directionString), "FWD");//"\xe2\x86\x91");
	}
	// right up
	else if (diff >= 22.5 && diff < 67.5)
	{
		Format(directionString, sizeof(directionString), "FWD-RIGHT");//"\xe2\x86\x97");
	}
	// right
	else if (diff >= 67.5 && diff < 112.5)
	{
		Format(directionString, sizeof(directionString), "RIGHT");//"\xe2\x86\x92");
	}

	// right down
	else if (diff >= 112.5 && diff < 157.5)
	{
		Format(directionString, sizeof(directionString), "BACK-RIGHT");//"\xe2\x86\x98");
	}
	// down
	else if (diff >= 157.5 || diff < -157.5)
	{
		Format(directionString, sizeof(directionString), "BACK");//"\xe2\x86\x93");
	}

					// down left
	else if (diff >= -157.5 && diff < -112.5)
	{
		Format(directionString, sizeof(directionString), "BACK-LEFT");//"\xe2\x86\x99");
	}

	// left
	else if (diff >= -112.5 && diff < -67.5)
	{
		Format(directionString, sizeof(directionString), "LEFT");//"\xe2\x86\x90");
	}
	// left up
	else if (diff >= -67.5 && diff < -22.5)
	{
		Format(directionString, sizeof(directionString), "FWD-LEFT");//"\xe2\x86\x96");
	}
	Format(buffer, size, "(%.0fm %s) ",dist,directionString);
	return dist;
}

stock GetGridPos(Float:position[3],String:buffer[], size)
{
	Format(buffer,size, "");
	if (!GetConVarBool(cvarGrid)) {
		return -1;
	}
	if (!g_bOverviewLoaded) return -2;
	decl Float:flMapPos[3],iGridPos[3];
	new String:sLetters[27]=".ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	flMapPos[0] = FloatAbs(FloatDiv((position[0] - float(g_iOverviewPosX)), g_fOverviewScale));
	flMapPos[1] = FloatAbs(FloatDiv((position[1] - float(g_iOverviewPosY)), g_fOverviewScale));
	new Float:flGridSize = FloatDiv(1024.0,g_flOverviewGridDivisions);
	iGridPos[0] = RoundToFloor(FloatDiv(flMapPos[0], flGridSize))+1;
	iGridPos[1] = RoundToFloor(FloatDiv(flMapPos[1], flGridSize))+1;
	//PrintToServer("[NMCHAT] Raw position is %f,%f calculated to %f,%f flGridSize %f grid %c, %d",position[0],position[1],flMapPos[0],flMapPos[1],flGridSize,sLetters[iGridPos[0]],iGridPos[1]);
	Format(buffer,size, "{G}[%c%d] ",sLetters[iGridPos[0]],iGridPos[1]);
	return true;
}

stock GetPlaceName(Float:position[3], String:buffer[], size, bool:bReturnRaw=false)
{
	Format(buffer,size, "");
	if (!GetConVarBool(cvarPlace)) {
		return -1;
	}
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
				Format(buffer,size, "Area %d",iAreaIndex);
			} else {
				return -1;
			}
		}
		Format(buffer,size, "\x03[%s] ",buffer);
		return iAreaIndex;
	}
	return -1;
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
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new chatflags = GetMessageFlags();
	if ((chatflags & CHATFLAGS_TEAM) || (!GetConVarBool(cvarTeamOnly))) {
		new index = CHATCOLOR_NOSUBJECT;
		decl String:sNameBuffer[MAXLENGTH_NAME],Float:flEyePos[3],String:sGridPos[16],String:sPlace[64],sDistance[64];
	        GetClientEyePosition(author, flEyePos);
		GetPlaceName(flEyePos,sPlace,sizeof(sPlace));
	        GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));
		Format(sNameBuffer, sizeof(sNameBuffer), "%s%s{T}%s", sGridPos, sPlace, name);
		//PrintToServer("[NMChat] NameBuffer changed from '%s' to '%s'",name,sNameBuffer);
		Color_ChatSetSubject(author);
		index = Color_ParseChatText(sNameBuffer, name, MAXLENGTH_NAME);
		Color_ChatClearSubject();
		author = index;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
