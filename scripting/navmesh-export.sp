#include <sourcemod>
#include <sdktools>
#include <navmesh>
#include <smlib>
#include <loghelper>
#undef REQUIRE_PLUGIN
#include <updater>
#include <smjansson>

#pragma unused cvarVersion
#pragma unused g_hNavMeshVisibleAreas
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Exports navmesh data in JSON format"
#define PLUGIN_NAME "[INS] Navmesh JSON Export"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.4"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-navmesh-export.txt"

new Handle:g_hNavMeshPlaces;
new Handle:g_hNavMeshAreas;
new Handle:g_hNavMeshConnections;
new Handle:g_hNavMeshHidingSpots;
new Handle:g_hNavMeshEncounterPaths;
new Handle:g_hNavMeshEncounterSpots;
new Handle:g_hNavMeshLadderConnections;
new Handle:g_hNavMeshVisibleAreas;
new Handle:g_hNavMeshLadders;

new Handle:cvarVersion = INVALID_HANDLE;
new Handle:cvarEnabled = INVALID_HANDLE;
new bool:g_bOverviewLoaded = false;
new g_iOverviewPosX = 0;
new g_iOverviewPosY = 0;
new g_iOverviewRotate = 0;
new Float:g_fOverviewScale = 1.0;

public OnPluginStart()
{
	PrintToServer("[NMExport] Starting");
	cvarVersion = CreateConVar("sm_navmesh_export_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_navmesh_export_enabled", "0", "sets whether this plugin is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
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
	g_hNavMeshConnections = NavMesh_GetConnections();
	g_hNavMeshHidingSpots = NavMesh_GetHidingSpots();
	g_hNavMeshEncounterPaths = NavMesh_GetEncounterPaths();
	g_hNavMeshEncounterSpots = NavMesh_GetEncounterSpots();
	g_hNavMeshLadderConnections = NavMesh_GetLadderConnections();
	g_hNavMeshVisibleAreas = NavMesh_GetVisibleAreas();
	g_hNavMeshLadders = NavMesh_GetLadders();

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
	PrintToServer("[NMExport]: start OverviewLoad");
	decl String:sOverviewFilePath[PLATFORM_MAX_PATH];
	Format(sOverviewFilePath, sizeof(sOverviewFilePath), "insurgency-data\\resource\\overviews\\%s.txt", sMapName);
	if (!FileExists(sOverviewFilePath)) {
		PrintToServer("[NMExport]: OverviewLoad cannot find suitable overview file!");
		return false;
	}
	PrintToServer("[NMExport]: OverviewLoad sOverviewFilePath is %s",sOverviewFilePath);
	new Handle:g_hNavMeshKeyValues = CreateKeyValues(sMapName);
	FileToKeyValues(g_hNavMeshKeyValues,sOverviewFilePath);
	g_iOverviewPosX = KvGetNum(g_hNavMeshKeyValues, "pos_x", 0);
	g_iOverviewPosY = KvGetNum(g_hNavMeshKeyValues, "pos_y", 0);
	g_iOverviewRotate = KvGetNum(g_hNavMeshKeyValues, "rotate", 0);
	g_fOverviewScale = KvGetFloat(g_hNavMeshKeyValues, "scale", 1.0);
	PrintToServer("[NMExport]: OverviewLoad KeyValues parsed: pos_x %d pos_y %d rotate %d scale %f", g_iOverviewPosX, g_iOverviewPosY, g_iOverviewRotate, g_fOverviewScale);
 
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
	decl String:buffer[256],String:name[32];
	new posx[2], posy[2], pos_x, pos_y, pos_width, pos_height;
	new Handle:hJSON = json_object();
	new Handle:hSection = INVALID_HANDLE;
	new Handle:hSubSection = INVALID_HANDLE;

	if (!NavMesh_Exists()) return -2;

	GetCurrentMap(sMap, sizeof(sMap));
	Format(sOutput, sizeof(sOutput), "insurgency-data\\maps\\navmesh\\%s.txt", sMap);
	
	hSection = json_object();
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshAreas); iIndex < iSize; iIndex++)
	{
		new Handle:hChild = json_object();
		new PlaceID = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_PlaceID);
		if (PlaceID) {
			GetArrayString(g_hNavMeshPlaces, (PlaceID-1), buffer, sizeof(buffer));
			json_object_set_new(hChild, "pos_name", json_string(buffer));
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
		json_object_set_new(hChild, "pos_x", json_integer(pos_x));
		json_object_set_new(hChild, "pos_y", json_integer(pos_y));
		json_object_set_new(hChild, "pos_width", json_integer(pos_width+1));
		json_object_set_new(hChild, "pos_height", json_integer(pos_height+1));
		json_object_set_new(hChild, "pos_center_x", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CenterX) - float(g_iOverviewPosX)), g_fOverviewScale)))));
		json_object_set_new(hChild, "pos_center_y", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CenterY) - float(g_iOverviewPosY)), g_fOverviewScale)))));
		new ConnectionsStartIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ConnectionsStartIndex);
		new ConnectionsEndIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ConnectionsEndIndex);
		if (ConnectionsStartIndex > -1)
		{
			hSubSection = json_object();
			for (new iSubIndex = ConnectionsStartIndex; iSubIndex <= ConnectionsEndIndex; iSubIndex++)
			{
				Format(name,sizeof(name),"%d",GetArrayCell(g_hNavMeshConnections, iSubIndex, NavMeshConnection_AreaIndex));
				json_object_set_new(hSubSection,name, json_integer(GetArrayCell(g_hNavMeshConnections, iSubIndex, NavMeshConnection_Direction)));
			}
			json_object_set_new(hChild, "Connections", hSubSection);
		}
		new HidingSpotsStartIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_HidingSpotsStartIndex);
		new HidingSpotsEndIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_HidingSpotsEndIndex);
		if (HidingSpotsStartIndex > -1)
		{
			hSubSection = json_object();
			for (new iSubIndex = HidingSpotsStartIndex; iSubIndex <= HidingSpotsEndIndex; iSubIndex++)
			{
				new Handle:hSubChild = json_object();
				json_object_set_new(hSubChild, "pos_x", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshHidingSpots, iSubIndex, NavMeshHidingSpot_X) - float(g_iOverviewPosX)), g_fOverviewScale)))));
				json_object_set_new(hSubChild, "pos_y", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshHidingSpots, iSubIndex, NavMeshHidingSpot_Y) - float(g_iOverviewPosY)), g_fOverviewScale)))));
				json_object_set_new(hSubChild, "pos_z", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshHidingSpots, iSubIndex, NavMeshHidingSpot_Z)), g_fOverviewScale)))));
				Format(name,sizeof(name),"%d",GetArrayCell(g_hNavMeshHidingSpots, iSubIndex, NavMeshHidingSpot_ID));
				json_object_set_new(hSubSection,name,hSubChild);
			}
			json_object_set_new(hChild, "HidingSpots", hSubSection);
		}
		new LadderConnectionsStartIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_LadderConnectionsStartIndex);
		new LadderConnectionsEndIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_LadderConnectionsEndIndex);
		if (LadderConnectionsStartIndex > -1)
		{
			hSubSection = json_object();
			for (new iSubIndex = LadderConnectionsStartIndex; iSubIndex <= LadderConnectionsEndIndex; iSubIndex++)
			{
				Format(name,sizeof(name),"%d",GetArrayCell(g_hNavMeshLadderConnections, iSubIndex, NavMeshLadderConnection_LadderIndex));
				json_object_set_new(hSubSection,name, json_integer(GetArrayCell(g_hNavMeshLadderConnections, iSubIndex, NavMeshLadderConnection_Direction)));
			}
			json_object_set_new(hChild, "LadderConnections", hSubSection);
		}

		new EncounterPathsStartIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EncounterPathsStartIndex);
		new EncounterPathsEndIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EncounterPathsEndIndex);
		if (EncounterPathsStartIndex > -1)
		{
			hSubSection = json_object();
			for (new iSubIndex = EncounterPathsStartIndex; iSubIndex <= EncounterPathsEndIndex; iSubIndex++)
			{
				new Handle:hSubChild = json_object();
				json_object_set_new(hSubChild, "pos_from_area", json_integer(GetArrayCell(g_hNavMeshEncounterPaths, iSubIndex, NavMeshEncounterPath_FromID)));
				json_object_set_new(hSubChild, "pos_from_direction", json_integer(GetArrayCell(g_hNavMeshEncounterPaths, iSubIndex, NavMeshEncounterPath_FromDirection)));
				json_object_set_new(hSubChild, "pos_to_area", json_integer(GetArrayCell(g_hNavMeshEncounterPaths, iSubIndex, NavMeshEncounterPath_ToID)));
				json_object_set_new(hSubChild, "pos_to_direction", json_integer(GetArrayCell(g_hNavMeshEncounterPaths, iSubIndex, NavMeshEncounterPath_ToDirection)));
				new start = GetArrayCell(g_hNavMeshEncounterPaths, iSubIndex, NavMeshEncounterPath_SpotsStartIndex);
				new end = GetArrayCell(g_hNavMeshEncounterPaths, iSubIndex, NavMeshEncounterPath_SpotsEndIndex);
				if (start > -1)
				{
					new Handle:hSubSubSection = json_object();
					for (new iSubSubIndex = start; iSubSubIndex <= end; iSubSubIndex++)
					{
						Format(name,sizeof(name),"%d",GetArrayCell(g_hNavMeshEncounterSpots, iSubSubIndex, NavMeshEncounterSpot_OrderID));
						json_object_set_new(hSubSubSection,name,json_integer(GetArrayCell(g_hNavMeshEncounterSpots, iSubSubIndex, NavMeshEncounterSpot_ParametricDistance)));
					}
					json_object_set_new(hSubChild,"EncounterSpots",hSubSubSection);
				}
				Format(name,sizeof(name),"%d",iSubIndex);
				json_object_set_new(hSubSection,name,hSubChild);
			}
			json_object_set_new(hChild, "EncounterPaths", hSubSection);
		}
/*
		new VisibleAreasStartIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_VisibleAreasStartIndex);
		new VisibleAreasEndIndex = GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_VisibleAreasEndIndex);
		if (VisibleAreasStartIndex > -1)
		{
			hSubSection = json_object();
			for (new iSubIndex = VisibleAreasStartIndex; iSubIndex <= VisibleAreasEndIndex; iSubIndex++)
			{
				Format(name,sizeof(name),"%d",GetArrayCell(g_hNavMeshVisibleAreas, iSubIndex, NavMeshVisibleArea_Index));
				json_object_set_new(hSubSection,name, json_integer(GetArrayCell(g_hNavMeshVisibleAreas, iSubIndex, NavMeshVisibleArea_Attributes)));
			}
			//json_object_set_new(hChild, "VisibleAreas", hSubSection);
		}
*/

/*
		json_object_set_new(hChild, "pos_center_z", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CenterZ), g_fOverviewScale)))));
		json_object_set_new(hChild, "InvDxCorners", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_InvDxCorners));
		json_object_set_new(hChild, "InvDyCorners", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_InvDyCorners));
		json_object_set_new(hChild, "NECornerZ", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_NECornerZ));
		json_object_set_new(hChild, "SWCornerZ", Float:GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_SWCornerZ));
		json_object_set_new(hChild, "CornerLightIntensityNW", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensityNW)));
		json_object_set_new(hChild, "CornerLightIntensityNE", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensityNE)));
		json_object_set_new(hChild, "CornerLightIntensitySE", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensitySE)));
		json_object_set_new(hChild, "CornerLightIntensitySW", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CornerLightIntensitySW)));
		json_object_set_new(hChild, "InheritVisibilityFrom", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_InheritVisibilityFrom)));
		json_object_set_new(hChild, "EarliestOccupyTimeFirstTeam", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EarliestOccupyTimeFirstTeam)));
		json_object_set_new(hChild, "EarliestOccupyTimeSecondTeam", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_EarliestOccupyTimeSecondTeam)));
		json_object_set_new(hChild, "unk01", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_unk01)));
		json_object_set_new(hChild, "Blocked", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Blocked)));
*/
		json_object_set_new(hChild, "Parent", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Parent)));
		json_object_set_new(hChild, "ParentHow", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ParentHow)));
		json_object_set_new(hChild, "CostSoFar", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_CostSoFar)));
		json_object_set_new(hChild, "TotalCost", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_TotalCost)));
		json_object_set_new(hChild, "Marker", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_Marker)));
		json_object_set_new(hChild, "OpenMarker", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_OpenMarker)));
		json_object_set_new(hChild, "PrevOpenIndex", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_PrevOpenIndex)));
		json_object_set_new(hChild, "NextOpenIndex", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_NextOpenIndex)));
		json_object_set_new(hChild, "PathLengthSoFar", json_integer(GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_PathLengthSoFar)));
		Format(name,sizeof(name),"%d",GetArrayCell(g_hNavMeshAreas, iIndex, NavMeshArea_ID));
		json_object_set_new(hSection,name,hChild);
	}
	json_object_set_new(hJSON, "Areas", hSection);

	hSection = json_object();
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshPlaces); iIndex < iSize; iIndex++)
	{
		GetArrayString(g_hNavMeshPlaces, iIndex,buffer,sizeof(buffer));
		Format(name,sizeof(name),"%d",iIndex);
		json_object_set_new(hSection,name,json_string(buffer));
	}
	json_object_set_new(hJSON, "Places", hSection);

	hSection = json_object();
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshLadders); iIndex < iSize; iIndex++)
	{
		Format(name,sizeof(name),"%d",GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_ID));
		new Handle:hChild = json_object();
		json_object_set_new(hChild, "pos_x", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopX) - float(g_iOverviewPosX)), g_fOverviewScale)))));
		json_object_set_new(hChild, "pos_y", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopY) - float(g_iOverviewPosY)), g_fOverviewScale)))));
		json_object_set_new(hChild, "pos_z", json_integer(RoundToFloor(FloatAbs(FloatDiv((Float:GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopZ)), g_fOverviewScale)))));
		json_object_set_new(hChild, "pos_direction", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_Direction)));
		json_object_set_new(hChild, "pos_width", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_Width)));
		json_object_set_new(hChild, "pos_height", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_Length)));
		json_object_set_new(hChild, "pos_area_top_forward", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopForwardAreaIndex)));
		json_object_set_new(hChild, "pos_area_top_left", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopLeftAreaIndex)));
		json_object_set_new(hChild, "pos_area_top_right", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopRightAreaIndex)));
		json_object_set_new(hChild, "pos_area_top_behind", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_TopBehindAreaIndex)));
		json_object_set_new(hChild, "pos_area_bottom", json_integer(GetArrayCell(g_hNavMeshLadders, iIndex, NavMeshLadder_BottomAreaIndex)));
		json_object_set_new(hSection,name,hChild);
	}
	json_object_set_new(hJSON, "Ladders", hSection);

/*
	KvJumpToKey(kv, "Places", true);
	KvJumpToKey(kv, "HidingSpots", true);
	KvJumpToKey(kv, "Paths", true);
	KvJumpToKey(kv, "Connections", true);
	KvJumpToKey(kv, "Ladders", true);
	for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshAreas); iIndex < iSize; iIndex++)
*/
	Format(sOutput, sizeof(sOutput), "insurgency-data\\maps\\navmesh\\%s.json", sMap);
	json_dump_file(hJSON, sOutput, 4, _, _, true);



	// Close the Handle to the JSON object, i.e. free it's memory
	// and free the Handle.
/*
	CloseHandle(hSection);
	CloseHandle(hChild);
	CloseHandle(hJSON);
*/
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
