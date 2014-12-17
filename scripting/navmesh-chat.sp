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
new Handle:h_DisplayPrint;
new Float:g_fOverviewScale = 1.0;
new Handle:cvarVersion;
new Handle:cvarEnabled;
new Handle:cvarTeamOnly;
new Handle:cvarGrid;
new Handle:cvarPlace;
new Handle:cvarDistance;
new Handle:cvarDirection;

public Plugin:myinfo =
{
	name = "[INS] Navmesh Chat",
	author = "Jared Ballou",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com"
};
new Handle:kv = INVALID_HANDLE;

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_navmesh_chat_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_navmesh_chat_enabled", "1", "sets whether this plugin is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarTeamOnly = CreateConVar("sm_navmesh_chat_teamonly", "1", "sets whether to prepend to all messages or just team messages", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarGrid = CreateConVar("sm_navmesh_chat_grid", "1", "Include grid coordinates", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarPlace = CreateConVar("sm_navmesh_chat_place", "1", "Include place name from navmesh", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarDistance = CreateConVar("sm_navmesh_chat_distance", "1", "Include distance to speaker", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarDirection = CreateConVar("sm_navmesh_chat_direction", "1", "Include direction to speaker", FCVAR_NOTIFY | FCVAR_PLUGIN);
	HookUserMessage(GetUserMessageId("VoiceSubtitle"), VoiceHook, true);
	if (!g_bOverviewLoaded) {
		OnMapStart();
	}
	RegConsoleCmd("get_grid", Get_Grid);

//jballou - trying to get a way to read the translation file which has a lot of control characters in it
/*

        decl String:path[256],String:line[256];
        BuildPath(Path_SM, path, sizeof(path), "../../resource/insurgency_english.txt");
        if(FileExists(path)) {
#define GIANT_BUFFER_SIZE 4096 // * 4 * 3, heh. this is just horrible. :P
new fileData[GIANT_BUFFER_SIZE];

//        ReadFile(file, fileData[0], GIANT_BUFFER_SIZE, 1);
		new Handle:fileHandle=OpenFile(path,"r");
		FileSeek(fileHandle, 0, SEEK_SET);
//		ReadFile(file, fileData[0], GIANT_BUFFER_SIZE, 1);

		while(!IsEndOfFile(fileHandle)&&ReadFile(fileHandle,fileData,32768,4))
		{
			PrintToServer("line %s",line);
		}
		CloseHandle(fileHandle);
                LogMessage("[NMChat] Loading translations from file: %s", path);
                kv = CreateKeyValues("Lang");
		KvSetEscapeSequences(kv, true);
                FileToKeyValues(kv, path);
                decl String:section[128], String:value[256];
                if(!KvJumpToKey(kv, "Tokens", false)) {
			do
			{
	                        KvGetSectionName(kv, section, sizeof(section));
        	                KvGetString(kv, NULL_STRING, value, sizeof(value));
                	        PrintToServer("--> Key: %s | Value: %s", section, value);
	                } while (KvGotoNextKey(kv, false));
		}
        } else {
                SetFailState("Cant find netprops data at %s", path);
        }
*/	
}
public Action:VoiceHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new clientid = BfReadByte(bf);
	decl String:message1[256],String:message[256];
	BfReadString(bf, message1, sizeof(message1));
//	BfReadString(bf, message2, sizeof(message2));

	new voicemenu1 = BfReadByte(bf);
	new voicemenu2 = BfReadByte(bf);
//	new voicemenu3 = BfReadByte(bf);
//	new voicemenu4 = BfReadByte(bf);
	PrintToServer("[NMchat]: VoiceHook called for %N clientid: %d, message1: %s, 1 %d 2 %d",clientid,clientid,message1,voicemenu1,voicemenu2);
//voicemenu1: %d, voicemenu2: %d voicemenu3: %d voicemenu4: %d",clientid,clientid,voicemenu1,voicemenu2,voicemenu3,voicemenu4);
	if(IsPlayerAlive(clientid) && IsClientInGame(clientid) && GetConVarBool(cvarEnabled))
	{
		new String:clientname[64];
		GetClientName(clientid, clientname, sizeof(clientname));
		decl String:sNameBuffer[MAXLENGTH_NAME],Float:flEyePos[3],String:sGridPos[16],String:sPlace[64];
	        GetClientEyePosition(clientid, flEyePos);
		GetPlaceName(flEyePos,sPlace,sizeof(sPlace));
	        GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));
		Format(sNameBuffer, sizeof(sNameBuffer), "");
		if ((GetConVarBool(cvarGrid)) && (!StrEqual(sGridPos,"XX"))){
			Format(sNameBuffer, sizeof(sNameBuffer), "%s{G}(%s) ", sNameBuffer, sGridPos);
		}
		if ((GetConVarBool(cvarPlace)) && (!StrEqual(sPlace,""))) {
			Format(sNameBuffer, sizeof(sNameBuffer), "%s{G}[%s] ", sNameBuffer, sPlace);
		}
		//Not yet implemented
		if (GetConVarBool(cvarDistance)) {
		}
		if (GetConVarBool(cvarDirection)) {
		}
		Color_ChatSetSubject(clientid);

		Format(sNameBuffer, sizeof(sNameBuffer), "%s{T}%s", sNameBuffer, clientname);
		Color_ParseChatText(sNameBuffer, clientname, MAXLENGTH_NAME);



//		Format(message, sizeof(message), "%s: ", sNameBuffer);
		StartDataTimer(clientid, String:clientname, String:sNameBuffer);
//		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public StartDataTimer(clientid, String:clientname[], String:message[])
{
	CreateDataTimer(0.1, SubTitle_Print, h_DisplayPrint);
	WritePackCell(h_DisplayPrint, clientid);
	WritePackString(h_DisplayPrint, clientname);
	WritePackString(h_DisplayPrint, message);
}
new i;
public Action:SubTitle_Print(Handle:timer, Handle:h_DisplayPrint)
{
	new String:clientname2[64];
	new String:message2[256];
	new Float:senderOrigin[3];
	new Float:receiverOrigin[3];
	new Float:distance;
	new Float:dist;
	new Float:vecPoints[3];
	new Float:vecAngles[3];
	new Float:receiverAngles[3];
	decl String:directionString[64];
	new String:textToPrint[256];

	ResetPack(h_DisplayPrint);
	new clientid2 = ReadPackCell(h_DisplayPrint);
	ReadPackString(h_DisplayPrint, clientname2, sizeof(clientname2));
	ReadPackString(h_DisplayPrint, message2, sizeof(message2));
	GetClientAbsOrigin(clientid2, senderOrigin);
	for(i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(clientid2) == GetClientTeam(i))
		{
			GetClientAbsOrigin(i, receiverOrigin);
			distance = GetVectorDistance(receiverOrigin,senderOrigin);
			dist = distance * 0.01905;
			GetClientAbsAngles(i, receiverAngles);
			MakeVectorFromPoints(receiverOrigin,senderOrigin, vecPoints);
			GetVectorAngles(vecPoints, vecAngles);
			new Float:diff = receiverAngles[1] - vecAngles[1];

// Correct it
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
						Format(directionString, sizeof(directionString), "\xe2\x86\x91");
					}

					// right up
					else if (diff >= 22.5 && diff < 67.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x97");
					}

					// right
					else if (diff >= 67.5 && diff < 112.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x92");
					}

					// right down
					else if (diff >= 112.5 && diff < 157.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x98");
					}

					// down
					else if (diff >= 157.5 || diff < -157.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x93");
					}

					// down left
					else if (diff >= -157.5 && diff < -112.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x99");
					}

					// left
					else if (diff >= -112.5 && diff < -67.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x90");
					}

					// left up
					else if (diff >= -67.5 && diff < -22.5)
					{
						Format(directionString, sizeof(directionString), "\xe2\x86\x96");
					}

			Format(textToPrint,sizeof(textToPrint),"%s (%.0fm %s)",message2,dist,directionString);
			Client_PrintToChat(i, true, textToPrint);
//			SayText2(clientid2, message2);
		}
	}
	return Plugin_Continue;
}
/*
stock SayText2(author_index , const String:message[])
{
	new Handle:buffer = StartMessageOne("SayText2", i);
	if (buffer != INVALID_HANDLE)
	{
		BfWriteByte(buffer, author_index);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}
*/
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
	if (!g_bOverviewLoaded) return -2;
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
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new chatflags = GetMessageFlags();
	if ((chatflags & CHATFLAGS_TEAM) || (!GetConVarBool(cvarTeamOnly))) {
		new index = CHATCOLOR_NOSUBJECT;
		decl String:sNameBuffer[MAXLENGTH_NAME],Float:flEyePos[3],String:sGridPos[16],String:sPlace[64];
	        GetClientEyePosition(author, flEyePos);
		GetPlaceName(flEyePos,sPlace,sizeof(sPlace));
	        GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));
		Format(sNameBuffer, sizeof(sNameBuffer), "");
		if ((GetConVarBool(cvarGrid)) && (!StrEqual(sGridPos,"XX"))){
			Format(sNameBuffer, sizeof(sNameBuffer), "%s{G}(%s) ", sNameBuffer, sGridPos);
		}
		if ((GetConVarBool(cvarPlace)) && (!StrEqual(sPlace,""))) {
			Format(sNameBuffer, sizeof(sNameBuffer), "%s{G}[%s] ", sNameBuffer, sPlace);
		}
		//Not yet implemented
		if (GetConVarBool(cvarDistance)) {
		}
		if (GetConVarBool(cvarDirection)) {
		}
		Format(sNameBuffer, sizeof(sNameBuffer), "%s{T}%s", sNameBuffer, name);
		Color_ChatSetSubject(author);
		index = Color_ParseChatText(sNameBuffer, name, MAXLENGTH_NAME);
		Color_ChatClearSubject();
		author = index;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
