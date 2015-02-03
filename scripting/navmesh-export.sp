#include <sourcemod>
#include <sdktools>
#include <navmesh>
#include <smlib>
#include <loghelper>
#undef REQUIRE_PLUGIN
#include <updater>
#include <smjansson>

#pragma unused cvarVersion
#define PLUGIN_VERSION				"0.0.1"
#define PLUGIN_DESCRIPTION "Puts navmesh area into export"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-navmesh-export.txt"

new Handle:g_hNavMeshPlaces;
new Handle:g_hNavMeshAreas;
new Handle:g_hNavMeshLadders;
new Handle:g_hNavMeshHidingSpots;

new Handle:cvarVersion = INVALID_HANDLE;
new Handle:cvarEnabled = INVALID_HANDLE;
new bool:g_bOverviewLoaded = false;
new g_iOverviewPosX = 0;
new g_iOverviewPosY = 0;
new g_iOverviewRotate = 0;
new Float:g_fOverviewScale = 1.0;

public Plugin:myinfo =
{
	name = "[INS] Navmesh Export",
	author = "Jared Ballou",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com"
};

public OnPluginStart()
{
	PrintToServer("[NMExport] Starting");
	cvarVersion = CreateConVar("sm_navmesh_export_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_navmesh_export_enabled", "1", "sets whether this plugin is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	if (!g_bOverviewLoaded) {
		OnMapStart();
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public OnMapStart()
{
	g_hNavMeshPlaces = NavMesh_GetPlaces();
	g_hNavMeshAreas = NavMesh_GetAreas();
	g_hNavMeshLadders = NavMesh_GetLadders();
	g_hNavMeshHidingSpots = NavMesh_GetHidingSpots();

	OverviewDestroy();
	decl String:sMap[256];
	GetCurrentMap(sMap, sizeof(sMap));
	g_bOverviewLoaded = OverviewLoad(sMap);
	DoExport();
}

OverviewDestroy()
{
	return;
}

bool:OverviewLoad(const String:sMapName[])
{
	PrintToServer("[NMchat]: start OverviewLoad");
	decl String:sOverviewFilePath[PLATFORM_MAX_PATH];
	Format(sOverviewFilePath, sizeof(sOverviewFilePath), "insurgency-data\\resource\\overviews\\%s.txt", sMapName);
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

public DoExport()
{
	PrintToServer("[NMExport] DoExport Starting");
	if (!GetConVarBool(cvarEnabled))
	{
		return -1;
	}
	decl String:sOutput[PLATFORM_MAX_PATH];
	decl String:sMap[256];
	decl String:buffer[256];
	new posx[2], posy[2], pos_x, pos_y, pos_width, pos_height;

	if (!NavMesh_Exists()) return -2;

	GetCurrentMap(sMap, sizeof(sMap));
	Format(sOutput, sizeof(sOutput), "insurgency-data\\maps\\navmesh\\%s.txt", sMap);
	
	new Handle:kv = CreateKeyValues(sMap);

	KvJumpToKey(kv, "Areas", true);
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshAreas); iIndex < iSize; iIndex++)
	{
		new ID = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ID);
		Format(buffer, sizeof(buffer), "%d", ID);
		KvJumpToKey(kv, buffer, true);
		new PlaceID = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_PlaceID);
		if (PlaceID) {
			GetArrayString(g_hNavMeshPlaces, (PlaceID-1), buffer, sizeof(buffer));
			KvSetString(kv, "pos_name", buffer);
		}
		posx[0] = RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_X1) - float(g_iOverviewPosX)), g_fOverviewScale)));
		posy[0] = RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Y1) - float(g_iOverviewPosY)), g_fOverviewScale)));
		posx[1] = RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_X2) - float(g_iOverviewPosX)), g_fOverviewScale)));
		posy[1] = RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Y2) - float(g_iOverviewPosY)), g_fOverviewScale)));
		if (posx[0] < posx[1])
		{
			pos_x = posx[0];
			pos_width = (posx[1] - posx[0]);
		}
		else
		{
			pos_x = posx[1];
			pos_width = (posx[0] - posx[1]);
		}

		if (posy[0] < posy[1])
		{
			pos_y = posy[0];
			pos_height = (posy[1] - posy[0]);
		}
		else
		{
			pos_y = posy[1];
			pos_height = (posy[0] - posy[1]);
		}
		if (pos_width < 0)
		{
			pos_width = (0 - pos_width);
		}
		if (pos_height < 0)
		{
			pos_height = (0 - pos_height);
		}
		KvSetNum(kv, "pos_x", pos_x);
		KvSetNum(kv, "pos_width", pos_width+1);
		KvSetNum(kv, "pos_y", pos_y);
		KvSetNum(kv, "pos_height", pos_height+1);
//RoundToFloor(FloatAbs(posx[0] - posx[1]))+1);

/*
		KvSetFloat(kv, "X1", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_X1));
		KvSetFloat(kv, "Y1", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Y1));
		KvSetFloat(kv, "Z1", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Z1));
		KvSetFloat(kv, "X2", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_X2));
		KvSetFloat(kv, "Y2", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Y2));
		KvSetFloat(kv, "Z2", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Z2));
		KvSetFloat(kv, "CenterX", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CenterX));
		KvSetFloat(kv, "CenterY", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CenterY));
		KvSetFloat(kv, "CenterZ", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CenterZ));
		KvSetFloat(kv, "InvDxCorners", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_InvDxCorners));
		KvSetFloat(kv, "InvDyCorners", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_InvDyCorners));
		KvSetFloat(kv, "NECornerZ", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_NECornerZ));
		KvSetFloat(kv, "SWCornerZ", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_SWCornerZ));
		KvSetNum(kv, "ConnectionsStartIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ConnectionsStartIndex));
		KvSetNum(kv, "ConnectionsEndIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ConnectionsEndIndex));
		KvSetNum(kv, "HidingSpotsStartIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_HidingSpotsStartIndex));
		KvSetNum(kv, "HidingSpotsEndIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_HidingSpotsEndIndex));
		KvSetNum(kv, "EncounterPathsStartIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EncounterPathsStartIndex));
		KvSetNum(kv, "EncounterPathsEndIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EncounterPathsEndIndex));
		KvSetNum(kv, "LadderConnectionsStartIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_LadderConnectionsStartIndex));
		KvSetNum(kv, "LadderConnectionsEndIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_LadderConnectionsEndIndex));
		KvSetNum(kv, "CornerLightIntensityNW", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensityNW));
		KvSetNum(kv, "CornerLightIntensityNE", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensityNE));
		KvSetNum(kv, "CornerLightIntensitySE", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensitySE));
		KvSetNum(kv, "CornerLightIntensitySW", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensitySW));
		KvSetNum(kv, "VisibleAreasStartIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_VisibleAreasStartIndex));
		KvSetNum(kv, "VisibleAreasEndIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_VisibleAreasEndIndex));
		KvSetNum(kv, "InheritVisibilityFrom", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_InheritVisibilityFrom));
		KvSetNum(kv, "EarliestOccupyTimeFirstTeam", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EarliestOccupyTimeFirstTeam));
		KvSetNum(kv, "EarliestOccupyTimeSecondTeam", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EarliestOccupyTimeSecondTeam));
		KvSetNum(kv, "unk01", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_unk01));
		KvSetNum(kv, "Blocked", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Blocked));
		KvSetNum(kv, "Parent", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Parent));
		KvSetNum(kv, "ParentHow", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ParentHow));
		KvSetNum(kv, "CostSoFar", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CostSoFar));
		KvSetNum(kv, "TotalCost", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_TotalCost));
		KvSetNum(kv, "Marker", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Marker));
		KvSetNum(kv, "OpenMarker", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_OpenMarker));
		KvSetNum(kv, "PrevOpenIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_PrevOpenIndex));
		KvSetNum(kv, "NextOpenIndex", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_NextOpenIndex));
		KvSetNum(kv, "PathLengthSoFar", GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_PathLengthSoFar));
*/
		KvGoBack(kv);
	}
	KvGoBack(kv);

	KvJumpToKey(kv, "HidingSpots", true);
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshHidingSpots); iIndex < iSize; iIndex++)
	{
		new ID = GetArrayCell(g_hNavMeshHidingSpots, iIndex, NavMeshHidingSpot_ID);
		Format(buffer, sizeof(buffer), "%d", ID);
		KvJumpToKey(kv, buffer, true);
		KvSetNum(kv, "pos_x", RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshHidingSpots, iIndex, NavMeshHidingSpot_X) - float(g_iOverviewPosX)), g_fOverviewScale))));
		KvSetNum(kv, "pos_y", RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshHidingSpots, iIndex, NavMeshHidingSpot_Y) - float(g_iOverviewPosY)), g_fOverviewScale))));
		KvSetNum(kv, "pos_z", RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshHidingSpots, iIndex, NavMeshHidingSpot_Z)), g_fOverviewScale))));
		KvGoBack(kv);
	}
	KvGoBack(kv);

	KvJumpToKey(kv, "Ladders", true);
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshLadders); iIndex < iSize; iIndex++)
	{
		new ID = GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_ID);
		Format(buffer, sizeof(buffer), "%d", ID);
		KvJumpToKey(kv, buffer, true);
		KvSetNum(kv, "pos_x", RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopX) - float(g_iOverviewPosX)), g_fOverviewScale))));
		KvSetNum(kv, "pos_y", RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopY) - float(g_iOverviewPosY)), g_fOverviewScale))));
		KvSetNum(kv, "pos_z", RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopZ)), g_fOverviewScale))));
		KvSetNum(kv, "pos_direction", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_Direction));
		KvSetNum(kv, "pos_width", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_Width));
		KvSetNum(kv, "pos_height", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_Length));
		KvSetNum(kv, "pos_area_top_forward", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopForwardAreaIndex));
		KvSetNum(kv, "pos_area_top_left", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopLeftAreaIndex));
		KvSetNum(kv, "pos_area_top_right", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopRightAreaIndex));
		KvSetNum(kv, "pos_area_top_behind", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopBehindAreaIndex));
		KvSetNum(kv, "pos_area_bottom", GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_BottomAreaIndex));
		KvGoBack(kv);
	}
	KvGoBack(kv);

	KvJumpToKey(kv, "Places", true);
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshPlaces); iIndex < iSize; iIndex++)
	{
		GetArrayString(g_hNavMeshPlaces, iIndex,buffer,sizeof(buffer));
		new String:ID[8];
		Format(ID,sizeof(ID),"%d",iIndex);
		KvSetString(kv, ID, buffer);
	}
	KvGoBack(kv);

/*
	KvJumpToKey(kv, "Places", true);
	KvJumpToKey(kv, "HidingSpots", true);
	KvJumpToKey(kv, "Paths", true);
	KvJumpToKey(kv, "Connections", true);
	KvJumpToKey(kv, "Ladders", true);
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshAreas); iIndex < iSize; iIndex++)
*/
//	KeyValuesToFile(kv, sOutput);
	new Handle:hObj = KeyValuesToJSON(kv);

	// And finally save the JSON object to a file
	// with indenting set to 2.
	Format(sOutput, sizeof(sOutput), "insurgency-data\\maps\\navmesh\\%s.json", sMap);
	json_dump_file(hObj, sOutput, 2);

	// Close the Handle to the JSON object, i.e. free it's memory
	// and free the Handle.
	CloseHandle(kv);
	CloseHandle(hObj);
	PrintToServer("[NMExport] DoExport Finished");
	return 1;
}


stock Handle:KeyValuesToJSON(Handle:kv) {
	new Handle:hObj = json_object();

	//Traverse the keyvalues structure
	IterateKeyValues(kv, hObj);

	//return output
	return hObj;
}

IterateKeyValues(&Handle:kv, &Handle:hObj) {
	do {
		new String:sSection[255];
		KvGetSectionName(kv, sSection, sizeof(sSection));

		new String:sValue[255];
		KvGetString(kv, "", sValue, sizeof(sValue));

		new bool:bIsSubSection = ((KvNodesInStack(kv) == 0) || (KvGetDataType(kv, "") == KvData_None && KvNodesInStack(kv) > 0));

		//new KvDataTypes:type = KvGetDataType(kv, "");
		//LogMessage("Section: %s, Value: %s, Type: %d", sSection, sValue, type);

		if(!bIsSubSection) {
		//if(type != KvData_None) {
			json_object_set_new(hObj, sSection, json_string(sValue));
		} else {
			//We have no value, this must be another section
			new Handle:hChild = json_object();

			if (KvGotoFirstSubKey(kv, false)) {
				IterateKeyValues(kv, hChild);
				KvGoBack(kv);
			}

			json_object_set_new(hObj, sSection, hChild);
		}

	} while (KvGotoNextKey(kv, false));
}
