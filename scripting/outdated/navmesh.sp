// Huge huge HUGE props and credits to Anthony Iacono (pimpinjuice) and his Nav-file parser code,
// which can be found here: https://github.com/AnthonyIacono/War3SourceV2/tree/master/Nav

// The rest of the code is based off code in the source-sdk-2013 repository. I only
// attempted to recreate those functions to be used in SourcePawn.

#include <sourcemod>
#include <sdktools>
#include <navmesh>

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Read navigation mesh"
#define PLUGIN_NAME "[INS] Navmesh Parser"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "1.0.4"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-navmesh.txt"

#define UNSIGNED_INT_BYTE_SIZE 4
#define UNSIGNED_CHAR_BYTE_SIZE 1
#define UNSIGNED_SHORT_BYTE_SIZE 2
#define FLOAT_BYTE_SIZE 4

new Handle:g_hNavMeshPlaces;
new Handle:g_hNavMeshAreas;
new Handle:g_hNavMeshAreaConnections;
new Handle:g_hNavMeshAreaHidingSpots;
new Handle:g_hNavMeshAreaEncounterPaths;
new Handle:g_hNavMeshAreaEncounterSpots;
new Handle:g_hNavMeshAreaLadderConnections;
new Handle:g_hNavMeshAreaVisibleAreas;

new Handle:g_hNavMeshLadders;

new g_iNavMeshMagicNumber;
new g_iNavMeshVersion;
new g_iNavMeshSubVersion;
new g_iNavMeshSaveBSPSize;
new bool:g_bNavMeshAnalyzed;

new Handle:g_hNavMeshGrid;
new Handle:g_hNavMeshGridLists;

new Float:g_flNavMeshGridCellSize = 300.0;
new Float:g_flNavMeshMinX;
new Float:g_flNavMeshMinY;
new g_iNavMeshGridSizeX;
new g_iNavMeshGridSizeY;


new bool:g_bNavMeshBuilt = false;

// For A* pathfinding.
new g_iNavMeshAreaOpenListIndex = -1;
new g_iNavMeshAreaOpenListTailIndex = -1;
new g_iNavMeshAreaMasterMarker = 0;


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("navmesh");
	
	CreateNative("NavMesh_Exists", Native_NavMeshExists);
	CreateNative("NavMesh_GetMagicNumber", Native_NavMeshGetMagicNumber);
	CreateNative("NavMesh_GetVersion", Native_NavMeshGetVersion);
	CreateNative("NavMesh_GetSubVersion", Native_NavMeshGetSubVersion);
	CreateNative("NavMesh_GetSaveBSPSize", Native_NavMeshGetSaveBSPSize);
	CreateNative("NavMesh_IsAnalyzed", Native_NavMeshIsAnalyzed);
	CreateNative("NavMesh_GetPlaces", Native_NavMeshGetPlaces);
	CreateNative("NavMesh_GetAreas", Native_NavMeshGetAreas);
	CreateNative("NavMesh_GetLadders", Native_NavMeshGetLadders);

	//Added by Jared Ballou
	CreateNative("NavMesh_GetHidingSpots", Native_NavMeshGetHidingSpots);
	CreateNative("NavMesh_GetConnections", Native_NavMeshGetConnections);
	CreateNative("NavMesh_GetEncounterPaths", Native_NavMeshGetEncounterPaths);
	CreateNative("NavMesh_GetEncounterSpots", Native_NavMeshGetEncounterSpots);
	CreateNative("NavMesh_GetLadderConnections", Native_NavMeshGetLadderConnections);
	CreateNative("NavMesh_GetVisibleAreas", Native_NavMeshGetVisibleAreas);
	//End new additions

	
	CreateNative("NavMesh_CollectSurroundingAreas", Native_NavMeshCollectSurroundingAreas);
	CreateNative("NavMesh_BuildPath", Native_NavMeshBuildPath);
	
	CreateNative("NavMesh_GetArea", Native_NavMeshGetArea);
	CreateNative("NavMesh_GetNearestArea", Native_NavMeshGetNearestArea);
	
	CreateNative("NavMesh_WorldToGridX", Native_NavMeshWorldToGridX);
	CreateNative("NavMesh_WorldToGridY", Native_NavMeshWorldToGridY);
	CreateNative("NavMesh_GetAreasOnGrid", Native_NavMeshGridGetAreas);
	CreateNative("NavMesh_GetGridSizeX", Native_NavMeshGetGridSizeX);
	CreateNative("NavMesh_GetGridSizeY", Native_NavMeshGetGridSizeY);
	
	CreateNative("NavMesh_GetGroundHeight", Native_NavMeshGetGroundHeight);
	
	CreateNative("NavMeshArea_GetMasterMarker", Native_NavMeshAreaGetMasterMarker);
	CreateNative("NavMeshArea_ChangeMasterMarker", Native_NavMeshAreaChangeMasterMarker);
	
	CreateNative("NavMeshArea_GetFlags", Native_NavMeshAreaGetFlags);
	CreateNative("NavMeshArea_GetCenter", Native_NavMeshAreaGetCenter);
	CreateNative("NavMeshArea_GetAdjacentList", Native_NavMeshAreaGetAdjacentList);
	CreateNative("NavMeshArea_GetLadderList", Native_NavMeshAreaGetLadderList);
	CreateNative("NavMeshArea_GetClosestPointOnArea", Native_NavMeshAreaGetClosestPointOnArea);
	CreateNative("NavMeshArea_GetTotalCost", Native_NavMeshAreaGetTotalCost);
	CreateNative("NavMeshArea_GetParent", Native_NavMeshAreaGetParent);
	CreateNative("NavMeshArea_GetParentHow", Native_NavMeshAreaGetParentHow);
	CreateNative("NavMeshArea_SetParent", Native_NavMeshAreaSetParent);
	CreateNative("NavMeshArea_SetParentHow", Native_NavMeshAreaSetParentHow);
	CreateNative("NavMeshArea_GetCostSoFar", Native_NavMeshAreaGetCostSoFar);
	CreateNative("NavMeshArea_GetExtentLow", Native_NavMeshAreaGetExtentLow);
	CreateNative("NavMeshArea_GetExtentHigh", Native_NavMeshAreaGetExtentHigh);
	CreateNative("NavMeshArea_IsOverlappingPoint", Native_NavMeshAreaIsOverlappingPoint);
	CreateNative("NavMeshArea_IsOverlappingArea", Native_NavMeshAreaIsOverlappingArea);
	CreateNative("NavMeshArea_GetNECornerZ", Native_NavMeshAreaGetNECornerZ);
	CreateNative("NavMeshArea_GetSWCornerZ", Native_NavMeshAreaGetSWCornerZ);
	CreateNative("NavMeshArea_GetZ", Native_NavMeshAreaGetZ);
	CreateNative("NavMeshArea_GetZFromXAndY", Native_NavMeshAreaGetZFromXAndY);
	CreateNative("NavMeshArea_Contains", Native_NavMeshAreaContains);
	CreateNative("NavMeshArea_ComputePortal", Native_NavMeshAreaComputePortal);
	CreateNative("NavMeshArea_ComputeClosestPointInPortal", Native_NavMeshAreaComputeClosestPointInPortal);
	CreateNative("NavMeshArea_ComputeDirection", Native_NavMeshAreaComputeDirection);
	CreateNative("NavMeshArea_GetLightIntensity", Native_NavMeshAreaGetLightIntensity);
	
	CreateNative("NavMeshLadder_GetLength", Native_NavMeshLadderGetLength);
}

public OnPluginStart()
{
	g_hNavMeshPlaces = CreateArray(256);
	g_hNavMeshAreas = CreateArray(NavMeshArea_MaxStats);
	g_hNavMeshAreaConnections = CreateArray(NavMeshConnection_MaxStats);
	g_hNavMeshAreaHidingSpots = CreateArray(NavMeshHidingSpot_MaxStats);
	g_hNavMeshAreaEncounterPaths = CreateArray(NavMeshEncounterPath_MaxStats);
	g_hNavMeshAreaEncounterSpots = CreateArray(NavMeshEncounterSpot_MaxStats);
	g_hNavMeshAreaLadderConnections = CreateArray(NavMeshLadderConnection_MaxStats);
	g_hNavMeshAreaVisibleAreas = CreateArray(NavMeshVisibleArea_MaxStats);
	
	g_hNavMeshLadders = CreateArray(NavMeshLadder_MaxStats);
	
	g_hNavMeshGrid = CreateArray(NavMeshGrid_MaxStats);
	g_hNavMeshGridLists = CreateArray(NavMeshGridList_MaxStats);
	
	HookEvent("nav_blocked", Event_NavAreaBlocked);
}

public OnMapStart()
{
	NavMeshDestroy();

	decl String:sMap[256];
	GetCurrentMap(sMap, sizeof(sMap));
	
	g_bNavMeshBuilt = NavMeshLoad(sMap);
}

public Event_NavAreaBlocked(Handle:event, const String:name[], bool:dB)
{
	if (!g_bNavMeshBuilt) return;

	new iAreaID = GetEventInt(event, "area");
	new iAreaIndex = FindValueInArray(g_hNavMeshAreas, iAreaID);
	if (iAreaIndex != -1)
	{
		new bool:bBlocked = bool:GetEventInt(event, "blocked");
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, bBlocked, NavMeshArea_Blocked);
	}
}

stock OppositeDirection(iNavDirection)
{
	switch (iNavDirection)
	{
		case NAV_DIR_NORTH: return NAV_DIR_SOUTH;
		case NAV_DIR_SOUTH: return NAV_DIR_NORTH;
		case NAV_DIR_EAST: return NAV_DIR_WEST;
		case NAV_DIR_WEST: return NAV_DIR_EAST;
	}
	
	return NAV_DIR_NORTH;
}

stock Float:NavMeshAreaComputeAdjacentConnectionHeightChange(iAreaIndex, iTargetAreaIndex)
{
	new bool:bFoundArea = false;
	new iNavDirection;
	
	for (iNavDirection = 0; iNavDirection < NAV_DIR_COUNT; iNavDirection++)
	{
		new Handle:hConnections = NavMeshAreaGetAdjacentList(iAreaIndex, iNavDirection);
		if (hConnections == INVALID_HANDLE) continue;
		
		while (!IsStackEmpty(hConnections))
		{
			new iTempAreaIndex = -1;
			PopStackCell(hConnections, iTempAreaIndex);
			
			if (iTempAreaIndex == iTargetAreaIndex)
			{
				bFoundArea = true;
				break;
			}
		}
		
		CloseHandle(hConnections);
		
		if (bFoundArea) break;
	}
	
	if (!bFoundArea) return 99999999.9;
	
	decl Float:flMyEdge[3];
	new Float:flHalfWidth;
	NavMeshAreaComputePortal(iAreaIndex, iTargetAreaIndex, iNavDirection, flMyEdge, flHalfWidth);
	
	decl Float:flOtherEdge[3];
	NavMeshAreaComputePortal(iAreaIndex, iTargetAreaIndex, OppositeDirection(iNavDirection), flOtherEdge, flHalfWidth);
	
	return flOtherEdge[2] - flMyEdge[2];
}

Handle:NavMeshCollectSurroundingAreas(iStartAreaIndex,
	Float:flTravelDistanceLimit=1500.0,
	Float:flMaxStepUpLimit=StepHeight,
	Float:flMaxDropDownLimit=100.0)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not search surrounding areas because the nav mesh does not exist!");
		return INVALID_HANDLE;
	}
	
	if (iStartAreaIndex == -1)
	{
		LogError("Could not search surrounding areas because the starting area does not exist!");
		return INVALID_HANDLE;
	}
	
	new Handle:hNearAreasList = CreateStack();
	
	NavMeshAreaClearSearchLists();
	
	NavMeshAreaAddToOpenList(iStartAreaIndex);
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, 0, NavMeshArea_TotalCost);
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, 0, NavMeshArea_CostSoFar);
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, -1, NavMeshArea_Parent);
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, NUM_TRAVERSE_TYPES, NavMeshArea_ParentHow);
	NavMeshAreaMark(iStartAreaIndex);
	
	while (!NavMeshAreaIsOpenListEmpty())
	{
		new iAreaIndex = NavMeshAreaPopOpenList();
		if (flTravelDistanceLimit > 0.0 && 
			float(GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CostSoFar)) > flTravelDistanceLimit)
		{
			continue;
		}
		
		new iAreaParent = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Parent);
		if (iAreaParent != -1)
		{
			new Float:flDeltaZ = NavMeshAreaComputeAdjacentConnectionHeightChange(iAreaParent, iAreaIndex);
			if (flDeltaZ > flMaxStepUpLimit) continue;
			if (flDeltaZ < -flMaxDropDownLimit) continue;
		}
		
		PushStackCell(hNearAreasList, iAreaIndex);
		
		NavMeshAreaMark(iAreaIndex);
		
		for (new iNavDir = 0; iNavDir < NAV_DIR_COUNT; iNavDir++)
		{
			new Handle:hConnections = NavMeshAreaGetAdjacentList(iAreaIndex, iNavDir);
			if (hConnections != INVALID_HANDLE)
			{
				while (!IsStackEmpty(hConnections))
				{
					new iAdjacentAreaIndex = -1;
					PopStackCell(hConnections, iAdjacentAreaIndex);
					
					if (bool:GetArrayCell(g_hNavMeshAreas, iAdjacentAreaIndex, NavMeshArea_Blocked)) continue;
					
					if (!NavMeshAreaIsMarked(iAdjacentAreaIndex))
					{
						SetArrayCell(g_hNavMeshAreas, iAdjacentAreaIndex, 0, NavMeshArea_TotalCost);
						SetArrayCell(g_hNavMeshAreas, iAdjacentAreaIndex, iAreaIndex, NavMeshArea_Parent);
						SetArrayCell(g_hNavMeshAreas, iAdjacentAreaIndex, iNavDir, NavMeshArea_ParentHow);
						
						new iDistAlong = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CostSoFar);
						
						decl Float:flAdjacentAreaCenter[3], Float:flAreaCenter[3];
						NavMeshAreaGetCenter(iAreaIndex, flAreaCenter);
						NavMeshAreaGetCenter(iAdjacentAreaIndex, flAdjacentAreaCenter);
						
						iDistAlong += RoundToFloor(GetVectorDistance(flAdjacentAreaCenter, flAreaCenter));
						SetArrayCell(g_hNavMeshAreas, iAdjacentAreaIndex, iDistAlong, NavMeshArea_CostSoFar);
						NavMeshAreaAddToOpenList(iAdjacentAreaIndex);
					}
				}
				
				CloseHandle(hConnections);
			}
		}
	}
	
	return hNearAreasList;
}

bool:NavMeshBuildPath(iStartAreaIndex,
	iGoalAreaIndex,
	const Float:flGoalPos[3],
	Handle:hCostFunctionPlugin,
	Function:iCostFunction,
	any:iCostData=INVALID_HANDLE,
	&iClosestAreaIndex=-1,
	Float:flMaxPathLength=0.0)
{
	if (!g_bNavMeshBuilt) 
	{
		LogError("Could not build path because the nav mesh does not exist!");
		return false;
	}
	
	if (iClosestAreaIndex != -1) 
	{
		iClosestAreaIndex = iStartAreaIndex;
	}
	
	if (iStartAreaIndex == -1)
	{
		LogError("Could not build path because the starting area does not exist!");
		return false;
	}
	
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, -1, NavMeshArea_Parent);
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, NUM_TRAVERSE_TYPES, NavMeshArea_ParentHow);
	
	if (iGoalAreaIndex == -1)
	{
		LogError("Could not build path from area %d to area %d because the goal area does not exist!");
		return false;
	}
	
	if (iStartAreaIndex == iGoalAreaIndex) return true;
	
	// Start the search.
	NavMeshAreaClearSearchLists();
	
	// Compute estimate of path length.
	decl Float:flStartAreaCenter[3];
	NavMeshAreaGetCenter(iStartAreaIndex, flStartAreaCenter);
	
	new iStartTotalCost = RoundFloat(GetVectorDistance(flStartAreaCenter, flGoalPos));
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, iStartTotalCost, NavMeshArea_TotalCost);
	
	new iInitCost;
	
	Call_StartFunction(hCostFunctionPlugin, iCostFunction);
	Call_PushCell(iStartAreaIndex);
	Call_PushCell(-1);
	Call_PushCell(-1);
	Call_PushCell(iCostData);
	Call_Finish(iInitCost);
	
	if (iInitCost < 0) return false;
	
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, 0, NavMeshArea_CostSoFar);
	SetArrayCell(g_hNavMeshAreas, iStartAreaIndex, 0.0, NavMeshArea_PathLengthSoFar);
	NavMeshAreaAddToOpenList(iStartAreaIndex);
	
	new iClosestAreaDist = iStartTotalCost;
	
	new bool:bHaveMaxPathLength = bool:(flMaxPathLength != 0.0);
	
	// Perform A* search.
	while (!NavMeshAreaIsOpenListEmpty())
	{
		new iAreaIndex = NavMeshAreaPopOpenList();
		
		if (bool:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Blocked)) 
		{
			// Don't consider blocked areas.
			continue;
		}
		
		if (iAreaIndex == iGoalAreaIndex ||
			(iGoalAreaIndex == -1 && NavMeshAreaContains(iAreaIndex, flGoalPos)))
		{
			if (iClosestAreaIndex != -1)
			{
				iClosestAreaIndex = iGoalAreaIndex;
			}
			
			return true;
		}
		
		// No support for elevator areas yet.
		static SEARCH_FLOOR = 0, SEARCH_LADDERS = 1;
		
		new iSearchWhere = SEARCH_FLOOR;
		new iSearchDir = NAV_DIR_NORTH;
		
		new Handle:hFloorList = NavMeshAreaGetAdjacentList(iAreaIndex, iSearchDir);
		
		new bool:bLadderUp = true;
		new Handle:hLadderList = INVALID_HANDLE;
		new iLadderTopDir = 0;
		
		for (;;)
		{
			new iNewAreaIndex = -1;
			new iNavTraverseHow = 0;
			new iLadderIndex = -1;
			
			if (iSearchWhere == SEARCH_FLOOR)
			{
				if (hFloorList == INVALID_HANDLE || IsStackEmpty(hFloorList))
				{
					iSearchDir++;
					if (hFloorList != INVALID_HANDLE) CloseHandle(hFloorList);
					
					if (iSearchDir == NAV_DIR_COUNT)
					{
						iSearchWhere = SEARCH_LADDERS;
						
						hLadderList = NavMeshAreaGetLadderList(iAreaIndex, NAV_LADDER_DIR_UP);
						iLadderTopDir = 0;
					}
					else
					{
						hFloorList = NavMeshAreaGetAdjacentList(iAreaIndex, iSearchDir);
					}
					
					continue;
				}
				
				PopStackCell(hFloorList, iNewAreaIndex);
				iNavTraverseHow = iSearchDir;
			}
			else if (iSearchWhere == SEARCH_LADDERS)
			{
				if (hLadderList == INVALID_HANDLE || IsStackEmpty(hLadderList))
				{
					if (hLadderList != INVALID_HANDLE) CloseHandle(hLadderList);
					
					if (!bLadderUp)
					{
						iLadderIndex = -1;
						break;
					}
					else
					{
						bLadderUp = false;
						hLadderList = NavMeshAreaGetLadderList(iAreaIndex, NAV_LADDER_DIR_DOWN);
					}
					
					continue;
				}
				
				PopStackCell(hLadderList, iLadderIndex);
				
				if (bLadderUp)
				{
					switch (iLadderTopDir)
					{
						case 0:
						{
							iNewAreaIndex = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_TopForwardAreaIndex);
						}
						case 1:
						{
							iNewAreaIndex = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_TopLeftAreaIndex);
						}
						case 2:
						{
							iNewAreaIndex = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_TopRightAreaIndex);
						}
						default:
						{
							iLadderTopDir = 0;
							continue;
						}
					}
					
					iNavTraverseHow = GO_LADDER_UP;
					iLadderTopDir++;
				}
				else
				{
					iNewAreaIndex = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_BottomAreaIndex);
					iNavTraverseHow = GO_LADDER_DOWN;
				}
				
				if (iNewAreaIndex == -1) continue;
			}
			
			if (GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Parent) == iNewAreaIndex) 
			{
				// Don't backtrack.
				continue;
			}
			
			if (iNewAreaIndex == iAreaIndex)
			{
				continue;
			}
			
			if (bool:GetArrayCell(g_hNavMeshAreas, iNewAreaIndex, NavMeshArea_Blocked)) 
			{
				// Don't consider blocked areas.
				continue;
			}
			
			new iNewCostSoFar;
			
			Call_StartFunction(hCostFunctionPlugin, iCostFunction);
			Call_PushCell(iNewAreaIndex);
			Call_PushCell(iAreaIndex);
			Call_PushCell(iLadderIndex);
			Call_Finish(iNewCostSoFar);
			
			if (iNewCostSoFar < 0) continue;
			
			decl Float:flNewAreaCenter[3];
			NavMeshAreaGetCenter(iNewAreaIndex, flNewAreaCenter);
			
			if (bHaveMaxPathLength)
			{
				decl Float:flAreaCenter[3];
				NavMeshAreaGetCenter(iAreaIndex, flAreaCenter);
				
				new Float:flDeltaLength = GetVectorDistance(flNewAreaCenter, flAreaCenter);
				new Float:flNewLengthSoFar = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_PathLengthSoFar) + flDeltaLength;
				if (flNewLengthSoFar > flMaxPathLength)
				{
					continue;
				}
				
				SetArrayCell(g_hNavMeshAreas, iNewAreaIndex, flNewLengthSoFar, NavMeshArea_PathLengthSoFar);
			}
			
			if ((NavMeshAreaIsOpen(iNewAreaIndex) || NavMeshAreaIsClosed(iNewAreaIndex)) &&
				GetArrayCell(g_hNavMeshAreas, iNewAreaIndex, NavMeshArea_CostSoFar) <= iNewCostSoFar)
			{
				continue;
			}
			else
			{
				new iNewCostRemaining = RoundFloat(GetVectorDistance(flNewAreaCenter, flGoalPos));
				
				if (iClosestAreaIndex != -1 && iNewCostRemaining < iClosestAreaDist)
				{
					iClosestAreaIndex = iNewAreaIndex;
					iClosestAreaDist = iNewCostRemaining;
				}
				
				SetArrayCell(g_hNavMeshAreas, iNewAreaIndex, iNewCostSoFar, NavMeshArea_CostSoFar);
				SetArrayCell(g_hNavMeshAreas, iNewAreaIndex, iNewCostSoFar + iNewCostRemaining, NavMeshArea_TotalCost);
				
				/*
				if (NavMeshAreaIsClosed(iNewAreaIndex)) 
				{
					NavMeshAreaRemoveFromClosedList(iNewAreaIndex);
				}
				*/
				
				if (NavMeshAreaIsOpen(iNewAreaIndex))
				{
					NavMeshAreaUpdateOnOpenList(iNewAreaIndex);
				}
				else
				{
					NavMeshAreaAddToOpenList(iNewAreaIndex);
				}
				
				SetArrayCell(g_hNavMeshAreas, iNewAreaIndex, iAreaIndex, NavMeshArea_Parent);
				SetArrayCell(g_hNavMeshAreas, iNewAreaIndex, iNavTraverseHow, NavMeshArea_ParentHow);
			}
		}
		
		NavMeshAreaAddToClosedList(iAreaIndex);
	}
	
	return false;
}

NavMeshAreaClearSearchLists()
{
	g_iNavMeshAreaMasterMarker++;
	g_iNavMeshAreaOpenListIndex = -1;
	g_iNavMeshAreaOpenListTailIndex = -1;
}

bool:NavMeshAreaIsMarked(iAreaIndex)
{
	return bool:(GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Marker) == g_iNavMeshAreaMasterMarker);
}

NavMeshAreaMark(iAreaIndex)
{
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, g_iNavMeshAreaMasterMarker, NavMeshArea_Marker);
}

bool:NavMeshAreaIsOpen(iAreaIndex)
{
	return bool:(GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_OpenMarker) == g_iNavMeshAreaMasterMarker);
}

bool:NavMeshAreaIsOpenListEmpty()
{
	return bool:(g_iNavMeshAreaOpenListIndex == -1);
}

NavMeshAreaAddToOpenList(iAreaIndex)
{
	if (NavMeshAreaIsOpen(iAreaIndex)) return;
	
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, g_iNavMeshAreaMasterMarker, NavMeshArea_OpenMarker);
	
	if (g_iNavMeshAreaOpenListIndex == -1)
	{
		g_iNavMeshAreaOpenListIndex = iAreaIndex;
		g_iNavMeshAreaOpenListTailIndex = iAreaIndex;
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, -1, NavMeshArea_PrevOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, -1, NavMeshArea_NextOpenIndex);
		return;
	}
	
	new iTotalCost = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_TotalCost);
	
	new iTempAreaIndex = -1, iLastAreaIndex = -1;
	for (iTempAreaIndex = g_iNavMeshAreaOpenListIndex; iTempAreaIndex != -1; iTempAreaIndex = GetArrayCell(g_hNavMeshAreas, iTempAreaIndex, NavMeshArea_NextOpenIndex))
	{
		if (iTotalCost < GetArrayCell(g_hNavMeshAreas, iTempAreaIndex, NavMeshArea_TotalCost)) break;
		iLastAreaIndex = iTempAreaIndex;
	}
	
	if (iTempAreaIndex != -1)
	{
		new iPrevOpenIndex = GetArrayCell(g_hNavMeshAreas, iTempAreaIndex, NavMeshArea_PrevOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, iPrevOpenIndex, NavMeshArea_PrevOpenIndex);
		
		if (iPrevOpenIndex != -1)
		{
			SetArrayCell(g_hNavMeshAreas, iPrevOpenIndex, iAreaIndex, NavMeshArea_NextOpenIndex);
		}
		else
		{
			g_iNavMeshAreaOpenListIndex = iAreaIndex;
		}
		
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, iTempAreaIndex, NavMeshArea_NextOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iTempAreaIndex, iAreaIndex, NavMeshArea_PrevOpenIndex);
	}
	else
	{
		SetArrayCell(g_hNavMeshAreas, iLastAreaIndex, iAreaIndex, NavMeshArea_NextOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, iLastAreaIndex, NavMeshArea_PrevOpenIndex);
		
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, -1, NavMeshArea_NextOpenIndex);
		
		g_iNavMeshAreaOpenListTailIndex = iAreaIndex;
	}
}

stock NavMeshAreaAddToOpenListTail(iAreaIndex)
{
	if (NavMeshAreaIsOpen(iAreaIndex)) return;
	
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, g_iNavMeshAreaMasterMarker, NavMeshArea_OpenMarker);
	
	if (g_iNavMeshAreaOpenListIndex == -1)
	{
		g_iNavMeshAreaOpenListIndex = iAreaIndex;
		g_iNavMeshAreaOpenListTailIndex = iAreaIndex;
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, -1, NavMeshArea_PrevOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, -1, NavMeshArea_NextOpenIndex);
		return;
	}
	
	SetArrayCell(g_hNavMeshAreas, g_iNavMeshAreaOpenListTailIndex, iAreaIndex, NavMeshArea_NextOpenIndex);
	
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, g_iNavMeshAreaOpenListTailIndex, NavMeshArea_PrevOpenIndex);
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, -1, NavMeshArea_NextOpenIndex);
	
	g_iNavMeshAreaOpenListTailIndex = iAreaIndex;
}

NavMeshAreaUpdateOnOpenList(iAreaIndex)
{
	new iTotalCost = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_TotalCost);
	
	new iPrevIndex = -1;
	
	while ((iPrevIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_PrevOpenIndex)) != -1 &&
		iTotalCost < (GetArrayCell(g_hNavMeshAreas, iPrevIndex, NavMeshArea_TotalCost)))
	{
		new iOtherIndex = iPrevIndex;
		new iBeforeIndex = GetArrayCell(g_hNavMeshAreas, iPrevIndex, NavMeshArea_PrevOpenIndex);
		new iAfterIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_NextOpenIndex);
	
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, iPrevIndex, NavMeshArea_NextOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iAreaIndex, iBeforeIndex, NavMeshArea_PrevOpenIndex);
		
		SetArrayCell(g_hNavMeshAreas, iOtherIndex, iAreaIndex, NavMeshArea_PrevOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iOtherIndex, iAfterIndex, NavMeshArea_NextOpenIndex);
		
		if (iBeforeIndex != -1)
		{
			SetArrayCell(g_hNavMeshAreas, iBeforeIndex, iAreaIndex, NavMeshArea_NextOpenIndex);
		}
		else
		{
			g_iNavMeshAreaOpenListIndex = iAreaIndex;
		}
		
		if (iAfterIndex != -1)
		{
			SetArrayCell(g_hNavMeshAreas, iAfterIndex, iOtherIndex, NavMeshArea_PrevOpenIndex);
		}
		else
		{
			g_iNavMeshAreaOpenListTailIndex = iAreaIndex;
		}
	}
}

NavMeshAreaRemoveFromOpenList(iAreaIndex)
{
	if (GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_OpenMarker) == 0) return;
	
	new iPrevOpenIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_PrevOpenIndex);
	new iNextOpenIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_NextOpenIndex);
	
	if (iPrevOpenIndex != -1)
	{
		SetArrayCell(g_hNavMeshAreas, iPrevOpenIndex, iNextOpenIndex, NavMeshArea_NextOpenIndex);
	}
	else
	{
		g_iNavMeshAreaOpenListIndex = iNextOpenIndex;
	}
	
	if (iNextOpenIndex != -1)
	{
		SetArrayCell(g_hNavMeshAreas, iNextOpenIndex, iPrevOpenIndex, NavMeshArea_PrevOpenIndex);
	}
	else
	{
		g_iNavMeshAreaOpenListTailIndex = iPrevOpenIndex;
	}
	
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, 0, NavMeshArea_OpenMarker);
}

NavMeshAreaPopOpenList()
{
	if (g_iNavMeshAreaOpenListIndex != -1)
	{
		new iOpenListIndex = g_iNavMeshAreaOpenListIndex;
	
		NavMeshAreaRemoveFromOpenList(iOpenListIndex);
		SetArrayCell(g_hNavMeshAreas, iOpenListIndex, -1, NavMeshArea_PrevOpenIndex);
		SetArrayCell(g_hNavMeshAreas, iOpenListIndex, -1, NavMeshArea_NextOpenIndex);
		
		return iOpenListIndex;
	}
	
	return -1;
}

bool:NavMeshAreaIsClosed(iAreaIndex)
{
	if (NavMeshAreaIsMarked(iAreaIndex) && !NavMeshAreaIsOpen(iAreaIndex)) return true;
	return false;
}

NavMeshAreaAddToClosedList(iAreaIndex)
{
	NavMeshAreaMark(iAreaIndex);
}

/*
static NavMeshAreaRemoveFromClosedList(iAreaIndex)
{
}
*/

bool:NavMeshLoad(const String:sMapName[])
{
	decl String:sNavFilePath[PLATFORM_MAX_PATH];
	Format(sNavFilePath, sizeof(sNavFilePath), "maps\\%s.nav", sMapName);
	
	new Handle:hFile = OpenFile(sNavFilePath, "rb");
	if (hFile == INVALID_HANDLE)
	{
		new EngineVersion:iEngineVersion;
		new bool:bFound = false;
		
		if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available)
		{
			iEngineVersion = GetEngineVersion();
			
			switch (iEngineVersion)
			{
				case Engine_CSGO:
				{
					// Search addon directories.
					new Handle:hDir = OpenDirectory("addons");
					if (hDir != INVALID_HANDLE)
					{
						LogMessage("Couldn't find .nav file in maps folder, checking addon folders...");
						
						decl String:sFolderName[PLATFORM_MAX_PATH];
						decl FileType:iFileType;
						while (ReadDirEntry(hDir, sFolderName, sizeof(sFolderName), iFileType))
						{
							if (iFileType == FileType_Directory)
							{
								Format(sNavFilePath, sizeof(sNavFilePath), "addons\\%s\\maps\\%s.nav", sFolderName, sMapName);
								hFile = OpenFile(sNavFilePath, "rb");
								if (hFile != INVALID_HANDLE)
								{
									bFound = true;
									break;
								}
							}
						}
						
						CloseHandle(hDir);
					}
				}
				case Engine_TF2:
				{
					// Search custom directories.
					new Handle:hDir = OpenDirectory("custom");
					if (hDir != INVALID_HANDLE)
					{
						LogMessage("Couldn't find .nav file in maps folder, checking custom folders...");
					
						decl String:sFolderName[PLATFORM_MAX_PATH];
						decl FileType:iFileType;
						while (ReadDirEntry(hDir, sFolderName, sizeof(sFolderName), iFileType))
						{
							if (iFileType == FileType_Directory)
							{
								Format(sNavFilePath, sizeof(sNavFilePath), "custom\\%s\\maps\\%s.nav", sFolderName, sMapName);
								hFile = OpenFile(sNavFilePath, "rb");
								if (hFile != INVALID_HANDLE)
								{
									bFound = true;
									break;
								}
							}
						}
						
						CloseHandle(hDir);
					}
				}
			}
		}
		
		if (!bFound)
		{
			LogMessage(".NAV file for %s could not be found", sMapName);
			return false;
		}
	}
	
	LogMessage("Found .NAV file in %s", sNavFilePath);
	
	// Get magic number.
	new iNavMagicNumber;
	new iElementsRead = ReadFileCell(hFile, iNavMagicNumber, UNSIGNED_INT_BYTE_SIZE);
	
	if (iElementsRead != 1)
	{
		CloseHandle(hFile);
		LogError("Error reading magic number value from navigation mesh: %s", sNavFilePath);
		return false;
	}
	
	if (iNavMagicNumber != NAV_MAGIC_NUMBER)
	{
		CloseHandle(hFile);
		LogError("Invalid magic number value from navigation mesh: %s [%p]", sNavFilePath, iNavMagicNumber);
		return false;
	}
	
	// Get the version.
	new iNavVersion;
	iElementsRead = ReadFileCell(hFile, iNavVersion, UNSIGNED_INT_BYTE_SIZE);
	
	if (iElementsRead != 1)
	{
		CloseHandle(hFile);
		LogError("Error reading version number from navigation mesh: %s", sNavFilePath);
		return false;
	}
	
	if (iNavVersion < 6 || iNavVersion > 16)
	{
		CloseHandle(hFile);
		LogError("Invalid version number value from navigation mesh: %s [%d]", sNavFilePath, iNavVersion);
		return false;
	}
	
	// Get the sub version, if supported.
	new iNavSubVersion;
	if (iNavVersion >= 10)
	{
		ReadFileCell(hFile, iNavSubVersion, UNSIGNED_INT_BYTE_SIZE);
	}
	
	// Get the save bsp size.
	new iNavSaveBspSize;
	if (iNavVersion >= 4)
	{
		ReadFileCell(hFile, iNavSaveBspSize, UNSIGNED_INT_BYTE_SIZE);
	}
	
	// Check if the nav mesh was analyzed.
	new iNavMeshAnalyzed;
	if (iNavVersion >= 14)
	{
		ReadFileCell(hFile, iNavMeshAnalyzed, UNSIGNED_CHAR_BYTE_SIZE);
		LogMessage("Is mesh analyzed: %d", iNavMeshAnalyzed);
	}
	
	LogMessage("Nav version: %d; SubVersion: %d (v10+); BSPSize: %d; MagicNumber: %d", iNavVersion, iNavSubVersion, iNavSaveBspSize, iNavMagicNumber);
	
	new iPlaceCount;
	ReadFileCell(hFile, iPlaceCount, UNSIGNED_SHORT_BYTE_SIZE);
	LogMessage("Place count: %d", iPlaceCount);
	
	// Parse through places.
	// TF2 doesn't use places, but CS:S does.
	for (new iPlaceIndex = 0; iPlaceIndex < iPlaceCount; iPlaceIndex++) 
	{
		new iPlaceStringSize;
		ReadFileCell(hFile, iPlaceStringSize, UNSIGNED_SHORT_BYTE_SIZE);
		
		new String:sPlaceName[256];
		ReadFileString(hFile, sPlaceName, sizeof(sPlaceName), iPlaceStringSize);
		
		PushArrayString(g_hNavMeshPlaces, sPlaceName);
		
		//LogMessage("Parsed place \"%s\" [index: %d]", sPlaceName, iPlaceIndex);
	}
	
	// Get any unnamed areas.
	new iNavUnnamedAreas;
	if (iNavVersion > 11)
	{
		ReadFileCell(hFile, iNavUnnamedAreas, UNSIGNED_CHAR_BYTE_SIZE);
		LogMessage("Has unnamed areas: %s", iNavUnnamedAreas ? "true" : "false");
	}
	
	// Get area count.
	new iAreaCount;
	ReadFileCell(hFile, iAreaCount, UNSIGNED_INT_BYTE_SIZE);
	
	LogMessage("Area count: %d", iAreaCount);
	
	new Float:flExtentLow[2] = { 99999999.9, 99999999.9 };
	new bool:bExtentLowX = false;
	new bool:bExtentLowY = false;
	new Float:flExtentHigh[2] = { -99999999.9, -99999999.9 };
	new bool:bExtentHighX = false;
	new bool:bExtentHighY = false;
	
	if (iAreaCount > 0)
	{
		// The following are index values that will serve as starting and ending markers for areas
		// to determine what is theirs.
		
		// This is to avoid iteration of the whole area set to reduce lookup time.
		
		new iGlobalConnectionsStartIndex = 0;
		new iGlobalHidingSpotsStartIndex = 0;
		new iGlobalEncounterPathsStartIndex = 0;
		new iGlobalEncounterSpotsStartIndex = 0;
		new iGlobalLadderConnectionsStartIndex = 0;
		new iGlobalVisibleAreasStartIndex = 0;
		
		for (new iAreaIndex = 0; iAreaIndex < iAreaCount; iAreaIndex++)
		{
			new iAreaID;
			new Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2;
			new iAreaFlags;
			new iInheritVisibilityFrom;
			new iHidingSpotCount;
			new iVisibleAreaCount;
			new Float:flEarliestOccupyTimeFirstTeam;
			new Float:flEarliestOccupyTimeSecondTeam;
			new Float:flNECornerZ;
			new Float:flSWCornerZ;
			new iPlaceID;
			new unk01;
			
			ReadFileCell(hFile, iAreaID, UNSIGNED_INT_BYTE_SIZE);
			
			//LogMessage("Area ID: %d", iAreaID);
			
			if (iNavVersion <= 8) 
			{
				ReadFileCell(hFile, iAreaFlags, UNSIGNED_CHAR_BYTE_SIZE);
			}
			else if (iNavVersion < 13) 
			{
				ReadFileCell(hFile, iAreaFlags, UNSIGNED_SHORT_BYTE_SIZE);
			}
			else 
			{
				ReadFileCell(hFile, iAreaFlags, UNSIGNED_INT_BYTE_SIZE);
			}
			
			//LogMessage("Area Flags: %d", iAreaFlags);
			
			ReadFileCell(hFile, _:x1, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:y1, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:z1, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:x2, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:y2, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:z2, FLOAT_BYTE_SIZE);
			
			//LogMessage("Area extent: (%f, %f, %f), (%f, %f, %f)", x1, y1, z1, x2, y2, z2);
			
			if (!bExtentLowX || x1 < flExtentLow[0]) 
			{
				bExtentLowX = true;
				flExtentLow[0] = x1;
			}
			
			if (!bExtentLowY || y1 < flExtentLow[1]) 
			{
				bExtentLowY = true;
				flExtentLow[1] = y1;
			}
			
			if (!bExtentHighX || x2 > flExtentHigh[0]) 
			{
				bExtentHighX = true;
				flExtentHigh[0] = x2;
			}
			
			if (!bExtentHighY || y2 > flExtentHigh[1]) 
			{
				bExtentHighY = true;
				flExtentHigh[1] = y2;
			}
			
			// Cache the center position.
			decl Float:flAreaCenter[3];
			flAreaCenter[0] = (x1 + x2) / 2.0;
			flAreaCenter[1] = (y1 + y2) / 2.0;
			flAreaCenter[2] = (z1 + z2) / 2.0;
			
			new Float:flInvDxCorners = 0.0; 
			new Float:flInvDyCorners = 0.0;
			
			if ((x2 - x1) > 0.0 && (y2 - y1) > 0.0)
			{
				flInvDxCorners = 1.0 / (x2 - x1);
				flInvDyCorners = 1.0 / (y2 - y1);
			}
			
			ReadFileCell(hFile, _:flNECornerZ, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:flSWCornerZ, FLOAT_BYTE_SIZE);
			
			//LogMessage("Corners: NW(%f), SW(%f)", flNECornerZ, flSWCornerZ);
			
			new iConnectionsStartIndex = -1;
			new iConnectionsEndIndex = -1;
			
			// Find connections.
			for (new iDirection = 0; iDirection < NAV_DIR_COUNT; iDirection++)
			{
				new iConnectionCount;
				ReadFileCell(hFile, iConnectionCount, UNSIGNED_INT_BYTE_SIZE);
				
				//LogMessage("Connection count: %d", iConnectionCount);
				
				if (iConnectionCount > 0)
				{
					if (iConnectionsStartIndex == -1) iConnectionsStartIndex = iGlobalConnectionsStartIndex;
				
					for (new iConnectionIndex = 0; iConnectionIndex < iConnectionCount; iConnectionIndex++) 
					{
						iConnectionsEndIndex = iGlobalConnectionsStartIndex;
					
						new iConnectingAreaID;
						ReadFileCell(hFile, iConnectingAreaID, UNSIGNED_INT_BYTE_SIZE);
						
						new iIndex = PushArrayCell(g_hNavMeshAreaConnections, iConnectingAreaID);
						SetArrayCell(g_hNavMeshAreaConnections, iIndex, iDirection, NavMeshConnection_Direction);
						
						iGlobalConnectionsStartIndex++;
					}
				}
			}
			
			// Get hiding spots.
			ReadFileCell(hFile, iHidingSpotCount, UNSIGNED_CHAR_BYTE_SIZE);
			
			//LogMessage("Hiding spot count: %d", iHidingSpotCount);
			
			new iHidingSpotsStartIndex = -1;
			new iHidingSpotsEndIndex = -1;
			
			if (iHidingSpotCount > 0)
			{
				iHidingSpotsStartIndex = iGlobalHidingSpotsStartIndex;
				
				for (new iHidingSpotIndex = 0; iHidingSpotIndex < iHidingSpotCount; iHidingSpotIndex++)
				{
					iHidingSpotsEndIndex = iGlobalHidingSpotsStartIndex;
				
					new iHidingSpotID;
					ReadFileCell(hFile, iHidingSpotID, UNSIGNED_INT_BYTE_SIZE);
					
					new Float:flHidingSpotX, Float:flHidingSpotY, Float:flHidingSpotZ;
					ReadFileCell(hFile, _:flHidingSpotX, FLOAT_BYTE_SIZE);
					ReadFileCell(hFile, _:flHidingSpotY, FLOAT_BYTE_SIZE);
					ReadFileCell(hFile, _:flHidingSpotZ, FLOAT_BYTE_SIZE);
					
					new iHidingSpotFlags;
					ReadFileCell(hFile, iHidingSpotFlags, UNSIGNED_CHAR_BYTE_SIZE);
					
					new iIndex = PushArrayCell(g_hNavMeshAreaHidingSpots, iHidingSpotID);
					SetArrayCell(g_hNavMeshAreaHidingSpots, iIndex, flHidingSpotX, NavMeshHidingSpot_X);
					SetArrayCell(g_hNavMeshAreaHidingSpots, iIndex, flHidingSpotY, NavMeshHidingSpot_Y);
					SetArrayCell(g_hNavMeshAreaHidingSpots, iIndex, flHidingSpotZ, NavMeshHidingSpot_Z);
					SetArrayCell(g_hNavMeshAreaHidingSpots, iIndex, iHidingSpotFlags, NavMeshHidingSpot_Flags);
					
					iGlobalHidingSpotsStartIndex++;
					
					//LogMessage("Parsed hiding spot (%f, %f, %f) with ID [%d] and flags [%d]", flHidingSpotX, flHidingSpotY, flHidingSpotZ, iHidingSpotID, iHidingSpotFlags);
				}
			}
			
			// Get approach areas (old version, only used to read data)
			if (iNavVersion < 15)
			{
				new iApproachAreaCount;
				ReadFileCell(hFile, iApproachAreaCount, UNSIGNED_CHAR_BYTE_SIZE);
				
				for (new iApproachAreaIndex = 0; iApproachAreaIndex < iApproachAreaCount; iApproachAreaIndex++)
				{
					new iApproachHereID;
					ReadFileCell(hFile, iApproachHereID, UNSIGNED_INT_BYTE_SIZE);
					
					new iApproachPrevID;
					ReadFileCell(hFile, iApproachPrevID, UNSIGNED_INT_BYTE_SIZE);
					
					new iApproachType;
					ReadFileCell(hFile, iApproachType, UNSIGNED_CHAR_BYTE_SIZE);
					
					new iApproachNextID;
					ReadFileCell(hFile, iApproachNextID, UNSIGNED_INT_BYTE_SIZE);
					
					new iApproachHow;
					ReadFileCell(hFile, iApproachHow, UNSIGNED_CHAR_BYTE_SIZE);
				}
			}
			
			// Get encounter paths.
			new iEncounterPathCount;
			ReadFileCell(hFile, iEncounterPathCount, UNSIGNED_INT_BYTE_SIZE);
			
			//LogMessage("Encounter Path Count: %d", iEncounterPathCount);
			
			new iEncounterPathsStartIndex = -1;
			new iEncounterPathsEndIndex = -1;
			
			if (iEncounterPathCount > 0)
			{
				iEncounterPathsStartIndex = iGlobalEncounterPathsStartIndex;
			
				for (new iEncounterPathIndex = 0; iEncounterPathIndex < iEncounterPathCount; iEncounterPathIndex++)
				{
					iEncounterPathsEndIndex = iGlobalEncounterPathsStartIndex;
				
					new iEncounterFromID;
					ReadFileCell(hFile, iEncounterFromID, UNSIGNED_INT_BYTE_SIZE);
					
					new iEncounterFromDirection;
					ReadFileCell(hFile, iEncounterFromDirection, UNSIGNED_CHAR_BYTE_SIZE);
					
					new iEncounterToID;
					ReadFileCell(hFile, iEncounterToID, UNSIGNED_INT_BYTE_SIZE);
					
					new iEncounterToDirection;
					ReadFileCell(hFile, iEncounterToDirection, UNSIGNED_CHAR_BYTE_SIZE);
					
					new iEncounterSpotCount;
					ReadFileCell(hFile, iEncounterSpotCount, UNSIGNED_CHAR_BYTE_SIZE);
					
					//LogMessage("Encounter [from ID %d] [from dir %d] [to ID %d] [to dir %d] [spot count %d]", iEncounterFromID, iEncounterFromDirection, iEncounterToID, iEncounterToDirection, iEncounterSpotCount);
					
					new iEncounterSpotsStartIndex = -1;
					new iEncounterSpotsEndIndex = -1;
					
					if (iEncounterSpotCount > 0)
					{
						iEncounterSpotsStartIndex = iGlobalEncounterSpotsStartIndex;
					
						for (new iEncounterSpotIndex = 0; iEncounterSpotIndex < iEncounterSpotCount; iEncounterSpotIndex++)
						{
							iEncounterSpotsEndIndex = iGlobalEncounterSpotsStartIndex;
						
							new iEncounterSpotOrderID;
							ReadFileCell(hFile, iEncounterSpotOrderID, UNSIGNED_INT_BYTE_SIZE);
							
							new iEncounterSpotT;
							ReadFileCell(hFile, iEncounterSpotT, UNSIGNED_CHAR_BYTE_SIZE);
							
							new Float:flEncounterSpotParametricDistance = float(iEncounterSpotT) / 255.0;
							
							new iIndex = PushArrayCell(g_hNavMeshAreaEncounterSpots, iEncounterSpotOrderID);
							SetArrayCell(g_hNavMeshAreaEncounterSpots, iIndex, flEncounterSpotParametricDistance, NavMeshEncounterSpot_ParametricDistance);
							
							iGlobalEncounterSpotsStartIndex++;
							
							//LogMessage("Encounter spot [order id %d] and [T %d]", iEncounterSpotOrderID, iEncounterSpotT);
						}
					}
					
					new iIndex = PushArrayCell(g_hNavMeshAreaEncounterPaths, iEncounterFromID);
					SetArrayCell(g_hNavMeshAreaEncounterPaths, iIndex, iEncounterFromDirection, NavMeshEncounterPath_FromDirection);
					SetArrayCell(g_hNavMeshAreaEncounterPaths, iIndex, iEncounterToID, NavMeshEncounterPath_ToID);
					SetArrayCell(g_hNavMeshAreaEncounterPaths, iIndex, iEncounterToDirection, NavMeshEncounterPath_ToDirection);
					SetArrayCell(g_hNavMeshAreaEncounterPaths, iIndex, iEncounterSpotsStartIndex, NavMeshEncounterPath_SpotsStartIndex);
					SetArrayCell(g_hNavMeshAreaEncounterPaths, iIndex, iEncounterSpotsEndIndex, NavMeshEncounterPath_SpotsEndIndex);
					
					iGlobalEncounterPathsStartIndex++;
				}
			}
			
			ReadFileCell(hFile, iPlaceID, UNSIGNED_SHORT_BYTE_SIZE);
			
			//LogMessage("Place ID: %d", iPlaceID);
			
			// Get ladder connections.
			
			new iLadderConnectionsStartIndex = -1;
			new iLadderConnectionsEndIndex = -1;
			
			for (new iLadderDirection = 0; iLadderDirection < NAV_LADDER_DIR_COUNT; iLadderDirection++)
			{
				new iLadderConnectionCount;
				ReadFileCell(hFile, iLadderConnectionCount, UNSIGNED_INT_BYTE_SIZE);
				
				//LogMessage("Ladder Connection Count: %d", iLadderConnectionCount);
				
				if (iLadderConnectionCount > 0)
				{
					iLadderConnectionsStartIndex = iGlobalLadderConnectionsStartIndex;
				
					for (new iLadderConnectionIndex = 0; iLadderConnectionIndex < iLadderConnectionCount; iLadderConnectionIndex++)
					{
						iLadderConnectionsEndIndex = iGlobalLadderConnectionsStartIndex;
					
						new iLadderConnectionID;
						ReadFileCell(hFile, iLadderConnectionID, UNSIGNED_INT_BYTE_SIZE);
						
						new iIndex = PushArrayCell(g_hNavMeshAreaLadderConnections, iLadderConnectionID);
						SetArrayCell(g_hNavMeshAreaLadderConnections, iIndex, iLadderDirection, NavMeshLadderConnection_Direction);
						
						iGlobalLadderConnectionsStartIndex++;
						
						//LogMessage("Parsed ladder connect [ID %d]\n", iLadderConnectionID);
					}
				}
			}
			
			ReadFileCell(hFile, _:flEarliestOccupyTimeFirstTeam, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:flEarliestOccupyTimeSecondTeam, FLOAT_BYTE_SIZE);
			
			new Float:flNavCornerLightIntensityNW;
			new Float:flNavCornerLightIntensityNE;
			new Float:flNavCornerLightIntensitySE;
			new Float:flNavCornerLightIntensitySW;
			
			new iVisibleAreasStartIndex = -1;
			new iVisibleAreasEndIndex = -1;
			
			if (iNavVersion >= 11)
			{
				ReadFileCell(hFile, _:flNavCornerLightIntensityNW, FLOAT_BYTE_SIZE);
				ReadFileCell(hFile, _:flNavCornerLightIntensityNE, FLOAT_BYTE_SIZE);
				ReadFileCell(hFile, _:flNavCornerLightIntensitySE, FLOAT_BYTE_SIZE);
				ReadFileCell(hFile, _:flNavCornerLightIntensitySW, FLOAT_BYTE_SIZE);
				
				if (iNavVersion >= 16)
				{
					ReadFileCell(hFile, iVisibleAreaCount, UNSIGNED_INT_BYTE_SIZE);
					
					//LogMessage("Visible area count: %d", iVisibleAreaCount);
					
					if (iVisibleAreaCount > 0)
					{
						iVisibleAreasStartIndex = iGlobalVisibleAreasStartIndex;
					
						for (new iVisibleAreaIndex = 0; iVisibleAreaIndex < iVisibleAreaCount; iVisibleAreaIndex++)
						{
							iVisibleAreasEndIndex = iGlobalVisibleAreasStartIndex;
						
							new iVisibleAreaID;
							ReadFileCell(hFile, iVisibleAreaID, UNSIGNED_INT_BYTE_SIZE);
							
							new iVisibleAreaAttributes;
							ReadFileCell(hFile, iVisibleAreaAttributes, UNSIGNED_CHAR_BYTE_SIZE);
							
							new iIndex = PushArrayCell(g_hNavMeshAreaVisibleAreas, iVisibleAreaID);
							SetArrayCell(g_hNavMeshAreaVisibleAreas, iIndex, iVisibleAreaAttributes, NavMeshVisibleArea_Attributes);
							
							iGlobalVisibleAreasStartIndex++;
							
							//LogMessage("Parsed visible area [%d] with attr [%d]", iVisibleAreaID, iVisibleAreaAttributes);
						}
					}
					
					ReadFileCell(hFile, iInheritVisibilityFrom, UNSIGNED_INT_BYTE_SIZE);
					
					//LogMessage("Inherit visibilty from: %d", iInheritVisibilityFrom);
					
					ReadFileCell(hFile, unk01, UNSIGNED_INT_BYTE_SIZE);
				}
			}
			
			new iIndex = PushArrayCell(g_hNavMeshAreas, iAreaID);
			SetArrayCell(g_hNavMeshAreas, iIndex, iAreaFlags, NavMeshArea_Flags);
			SetArrayCell(g_hNavMeshAreas, iIndex, iPlaceID, NavMeshArea_PlaceID);
			SetArrayCell(g_hNavMeshAreas, iIndex, x1, NavMeshArea_X1);
			SetArrayCell(g_hNavMeshAreas, iIndex, y1, NavMeshArea_Y1);
			SetArrayCell(g_hNavMeshAreas, iIndex, z1, NavMeshArea_Z1);
			SetArrayCell(g_hNavMeshAreas, iIndex, x2, NavMeshArea_X2);
			SetArrayCell(g_hNavMeshAreas, iIndex, y2, NavMeshArea_Y2);
			SetArrayCell(g_hNavMeshAreas, iIndex, z2, NavMeshArea_Z2);
			SetArrayCell(g_hNavMeshAreas, iIndex, flAreaCenter[0], NavMeshArea_CenterX);
			SetArrayCell(g_hNavMeshAreas, iIndex, flAreaCenter[1], NavMeshArea_CenterY);
			SetArrayCell(g_hNavMeshAreas, iIndex, flAreaCenter[2], NavMeshArea_CenterZ);
			SetArrayCell(g_hNavMeshAreas, iIndex, flInvDxCorners, NavMeshArea_InvDxCorners);
			SetArrayCell(g_hNavMeshAreas, iIndex, flInvDyCorners, NavMeshArea_InvDyCorners);
			SetArrayCell(g_hNavMeshAreas, iIndex, flNECornerZ, NavMeshArea_NECornerZ);
			SetArrayCell(g_hNavMeshAreas, iIndex, flSWCornerZ, NavMeshArea_SWCornerZ);
			SetArrayCell(g_hNavMeshAreas, iIndex, iConnectionsStartIndex, NavMeshArea_ConnectionsStartIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iConnectionsEndIndex, NavMeshArea_ConnectionsEndIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iHidingSpotsStartIndex, NavMeshArea_HidingSpotsStartIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iHidingSpotsEndIndex, NavMeshArea_HidingSpotsEndIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iEncounterPathsStartIndex, NavMeshArea_EncounterPathsStartIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iEncounterPathsEndIndex, NavMeshArea_EncounterPathsEndIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iLadderConnectionsStartIndex, NavMeshArea_LadderConnectionsStartIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iLadderConnectionsEndIndex, NavMeshArea_LadderConnectionsEndIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, flNavCornerLightIntensityNW, NavMeshArea_CornerLightIntensityNW);
			SetArrayCell(g_hNavMeshAreas, iIndex, flNavCornerLightIntensityNE, NavMeshArea_CornerLightIntensityNE);
			SetArrayCell(g_hNavMeshAreas, iIndex, flNavCornerLightIntensitySE, NavMeshArea_CornerLightIntensitySE);
			SetArrayCell(g_hNavMeshAreas, iIndex, flNavCornerLightIntensitySW, NavMeshArea_CornerLightIntensitySW);
			SetArrayCell(g_hNavMeshAreas, iIndex, iVisibleAreasStartIndex, NavMeshArea_VisibleAreasStartIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iVisibleAreasEndIndex, NavMeshArea_VisibleAreasEndIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, iInheritVisibilityFrom, NavMeshArea_InheritVisibilityFrom);
			SetArrayCell(g_hNavMeshAreas, iIndex, flEarliestOccupyTimeFirstTeam, NavMeshArea_EarliestOccupyTimeFirstTeam);
			SetArrayCell(g_hNavMeshAreas, iIndex, flEarliestOccupyTimeSecondTeam, NavMeshArea_EarliestOccupyTimeSecondTeam);
			SetArrayCell(g_hNavMeshAreas, iIndex, unk01, NavMeshArea_unk01);
			SetArrayCell(g_hNavMeshAreas, iIndex, -1, NavMeshArea_Parent);
			SetArrayCell(g_hNavMeshAreas, iIndex, NUM_TRAVERSE_TYPES, NavMeshArea_ParentHow);
			SetArrayCell(g_hNavMeshAreas, iIndex, 0, NavMeshArea_TotalCost);
			SetArrayCell(g_hNavMeshAreas, iIndex, 0, NavMeshArea_CostSoFar);
			SetArrayCell(g_hNavMeshAreas, iIndex, -1, NavMeshArea_Marker);
			SetArrayCell(g_hNavMeshAreas, iIndex, -1, NavMeshArea_OpenMarker);
			SetArrayCell(g_hNavMeshAreas, iIndex, -1, NavMeshArea_PrevOpenIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, -1, NavMeshArea_NextOpenIndex);
			SetArrayCell(g_hNavMeshAreas, iIndex, 0.0, NavMeshArea_PathLengthSoFar);
			SetArrayCell(g_hNavMeshAreas, iIndex, false, NavMeshArea_Blocked);
			SetArrayCell(g_hNavMeshAreas, iIndex, -1, NavMeshArea_NearSearchMarker);
		}
	}
	
	// Set up the grid.
	NavMeshGridAllocate(flExtentLow[0], flExtentHigh[0], flExtentLow[1], flExtentHigh[1]);
	
	for (new i = 0; i < iAreaCount; i++)
	{
		NavMeshAddAreaToGrid(i);
	}
	
	NavMeshGridFinalize();
	LogMessage("Loading ladders....");
	
	new iLadderCount;
	ReadFileCell(hFile, iLadderCount, UNSIGNED_INT_BYTE_SIZE);
	
	if (iLadderCount > 0)
	{
		for (new iLadderIndex; iLadderIndex < iLadderCount; iLadderIndex++)
		{
			new iLadderID;
			ReadFileCell(hFile, iLadderID, UNSIGNED_INT_BYTE_SIZE);
			
			new Float:flLadderWidth;
			ReadFileCell(hFile, _:flLadderWidth, FLOAT_BYTE_SIZE);
			
			new Float:flLadderTopX, Float:flLadderTopY, Float:flLadderTopZ, Float:flLadderBottomX, Float:flLadderBottomY, Float:flLadderBottomZ;
			ReadFileCell(hFile, _:flLadderTopX, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:flLadderTopY, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:flLadderTopZ, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:flLadderBottomX, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:flLadderBottomY, FLOAT_BYTE_SIZE);
			ReadFileCell(hFile, _:flLadderBottomZ, FLOAT_BYTE_SIZE);
			
			new Float:flLadderLength;
			ReadFileCell(hFile, _:flLadderLength, FLOAT_BYTE_SIZE);
			
			new iLadderDirection;
			ReadFileCell(hFile, iLadderDirection, UNSIGNED_INT_BYTE_SIZE);
			
			new iLadderTopForwardAreaID;
			ReadFileCell(hFile, iLadderTopForwardAreaID, UNSIGNED_INT_BYTE_SIZE);
			
			new iLadderTopLeftAreaID;
			ReadFileCell(hFile, iLadderTopLeftAreaID, UNSIGNED_INT_BYTE_SIZE);
			
			new iLadderTopRightAreaID;
			ReadFileCell(hFile, iLadderTopRightAreaID, UNSIGNED_INT_BYTE_SIZE);
			
			new iLadderTopBehindAreaID;
			ReadFileCell(hFile, iLadderTopBehindAreaID, UNSIGNED_INT_BYTE_SIZE);
			
			new iLadderBottomAreaID;
			ReadFileCell(hFile, iLadderBottomAreaID, UNSIGNED_INT_BYTE_SIZE);
			
			new iIndex = PushArrayCell(g_hNavMeshLadders, iLadderID);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderWidth, NavMeshLadder_Width);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderLength, NavMeshLadder_Length);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderTopX, NavMeshLadder_TopX);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderTopY, NavMeshLadder_TopY);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderTopZ, NavMeshLadder_TopZ);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderBottomX, NavMeshLadder_BottomX);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderBottomY, NavMeshLadder_BottomY);
			SetArrayCell(g_hNavMeshLadders, iIndex, flLadderBottomZ, NavMeshLadder_BottomZ);
			SetArrayCell(g_hNavMeshLadders, iIndex, iLadderDirection, NavMeshLadder_Direction);
			SetArrayCell(g_hNavMeshLadders, iIndex, iLadderTopForwardAreaID, NavMeshLadder_TopForwardAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iIndex, iLadderTopLeftAreaID, NavMeshLadder_TopLeftAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iIndex, iLadderTopRightAreaID, NavMeshLadder_TopRightAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iIndex, iLadderTopBehindAreaID, NavMeshLadder_TopBehindAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iIndex, iLadderBottomAreaID, NavMeshLadder_BottomAreaIndex);
		}
	}
	
	g_iNavMeshMagicNumber = iNavMagicNumber;
	g_iNavMeshVersion = iNavVersion;
	g_iNavMeshSubVersion = iNavSubVersion;
	g_iNavMeshSaveBSPSize = iNavSaveBspSize;
	g_bNavMeshAnalyzed = bool:iNavMeshAnalyzed;
	
	LogMessage("Done loading ladders.");
	CloseHandle(hFile);
	LogMessage("Navmesh file closed");
	
	// File parsing is all done. Convert IDs to array indexes for faster performance and 
	// lesser lookup time.
	LogMessage("Index cleanup starting...");
	if (GetArraySize(g_hNavMeshAreaConnections) > 0)
	{
		for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshAreaConnections); iIndex < iSize; iIndex++)
		{
			new iConnectedAreaID = GetArrayCell(g_hNavMeshAreaConnections, iIndex, NavMeshConnection_AreaIndex);
			SetArrayCell(g_hNavMeshAreaConnections, iIndex, FindValueInArray(g_hNavMeshAreas, iConnectedAreaID), NavMeshConnection_AreaIndex);
		}
	}
	LogMessage("g_hNavMeshAreaConnections Done!");
	/*
	if (GetArraySize(g_hNavMeshAreaVisibleAreas) > 0)
	{
		for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshAreaVisibleAreas); iIndex < iSize; iIndex++)
		{
			new iVisibleAreaID = GetArrayCell(g_hNavMeshAreaVisibleAreas, iIndex, NavMeshVisibleArea_Index);
			SetArrayCell(g_hNavMeshAreaVisibleAreas, iIndex, FindValueInArray(g_hNavMeshAreas, iVisibleAreaID), NavMeshVisibleArea_Index);
		}
	}
	LogMessage("g_hNavMeshAreaVisibleAreas Done!");
	*/
	if (GetArraySize(g_hNavMeshAreaLadderConnections) > 0)
	{
		for (new iIndex = 0, iSize = GetArraySize(g_hNavMeshAreaLadderConnections); iIndex < iSize; iIndex++)
		{
			new iLadderID = GetArrayCell(g_hNavMeshAreaLadderConnections, iIndex, NavMeshLadderConnection_LadderIndex);
			SetArrayCell(g_hNavMeshAreaLadderConnections, iIndex, FindValueInArray(g_hNavMeshLadders, iLadderID), NavMeshLadderConnection_LadderIndex);
		}
	}
	LogMessage("g_hNavMeshAreaLadderConnections Done!");
	
	if (GetArraySize(g_hNavMeshLadders) > 0)
	{
		for (new iLadderIndex = 0; iLadderIndex < iLadderCount; iLadderIndex++)
		{
			new iTopForwardAreaID = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_TopForwardAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iLadderIndex, FindValueInArray(g_hNavMeshAreas, iTopForwardAreaID), NavMeshLadder_TopForwardAreaIndex);
			
			new iTopLeftAreaID = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_TopLeftAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iLadderIndex, FindValueInArray(g_hNavMeshAreas, iTopLeftAreaID), NavMeshLadder_TopLeftAreaIndex);
			
			new iTopRightAreaID = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_TopRightAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iLadderIndex, FindValueInArray(g_hNavMeshAreas, iTopRightAreaID), NavMeshLadder_TopRightAreaIndex);
			
			new iTopBehindAreaID = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_TopBehindAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iLadderIndex, FindValueInArray(g_hNavMeshAreas, iTopBehindAreaID), NavMeshLadder_TopBehindAreaIndex);
			
			new iBottomAreaID = GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_BottomAreaIndex);
			SetArrayCell(g_hNavMeshLadders, iLadderIndex, FindValueInArray(g_hNavMeshAreas, iBottomAreaID), NavMeshLadder_BottomAreaIndex);
		}
	}
	LogMessage("g_hNavMeshLadders Done!");
	LogMessage("Index cleanup complete.");
	return true;
}

NavMeshDestroy()
{
	ClearArray(g_hNavMeshPlaces);
	ClearArray(g_hNavMeshAreas);
	ClearArray(g_hNavMeshAreaConnections);
	ClearArray(g_hNavMeshAreaHidingSpots);
	ClearArray(g_hNavMeshAreaEncounterPaths);
	ClearArray(g_hNavMeshAreaEncounterSpots);
	ClearArray(g_hNavMeshAreaLadderConnections);
	ClearArray(g_hNavMeshAreaVisibleAreas);
	ClearArray(g_hNavMeshLadders);
	
	ClearArray(g_hNavMeshGrid);
	ClearArray(g_hNavMeshGridLists);
	
	g_iNavMeshMagicNumber = 0;
	g_iNavMeshVersion = 0;
	g_iNavMeshSubVersion = 0;
	g_iNavMeshSaveBSPSize = 0;
	g_bNavMeshAnalyzed = false;
	
	g_bNavMeshBuilt = false;
	
	g_iNavMeshAreaOpenListIndex = -1;
	g_iNavMeshAreaOpenListTailIndex = -1;
	g_iNavMeshAreaMasterMarker = 0;
}

NavMeshGridAllocate(Float:flMinX, Float:flMaxX, Float:flMinY, Float:flMaxY)
{
	ClearArray(g_hNavMeshGrid);
	ClearArray(g_hNavMeshGridLists);
	
	g_flNavMeshMinX = flMinX;
	g_flNavMeshMinY = flMinY;
	
	g_iNavMeshGridSizeX = IntCast((flMaxX - flMinX) / g_flNavMeshGridCellSize) + 1;
	g_iNavMeshGridSizeY = IntCast((flMaxY - flMinY) / g_flNavMeshGridCellSize) + 1;
	
	new iArraySize = g_iNavMeshGridSizeX * g_iNavMeshGridSizeY;
	ResizeArray(g_hNavMeshGrid, iArraySize);
	
	for (new iGridIndex = 0; iGridIndex < iArraySize; iGridIndex++)
	{
		SetArrayCell(g_hNavMeshGrid, iGridIndex, -1, NavMeshGrid_ListStartIndex);
		SetArrayCell(g_hNavMeshGrid, iGridIndex, -1, NavMeshGrid_ListEndIndex);
	}
}

NavMeshGridFinalize()
{
	new iAreaCount = GetArraySize(g_hNavMeshAreas);
	new bool:bAreaInGrid[iAreaCount];
	
	SortADTArrayCustom(g_hNavMeshGridLists, SortNavMeshGridLists);
	
	for (new iGridIndex = 0, iSize = GetArraySize(g_hNavMeshGrid); iGridIndex < iSize; iGridIndex++)
	{
		new iStartIndex = -1;
		new iEndIndex = -1;
		NavMeshGridGetListBounds(iGridIndex, iStartIndex, iEndIndex);
		SetArrayCell(g_hNavMeshGrid, iGridIndex, iStartIndex, NavMeshGrid_ListStartIndex);
		SetArrayCell(g_hNavMeshGrid, iGridIndex, iEndIndex, NavMeshGrid_ListEndIndex);
		
		if (iStartIndex != -1)
		{
			for (new iListIndex = iStartIndex; iListIndex <= iEndIndex; iListIndex++)
			{
				new iAreaIndex = GetArrayCell(g_hNavMeshGridLists, iListIndex);
				if (iAreaIndex != -1)
				{
					bAreaInGrid[iAreaIndex] = true;
				}
				else
				{
					LogError("Warning! Invalid nav area found in list of grid index %d!", iGridIndex);
				}
			}
		}
	}
	
	new bool:bAllIn = true;
	new iErrorAreaIndex = -1;
	
	for (new iAreaIndex = 0; iAreaIndex < iAreaCount; iAreaIndex++)
	{
		if (!bAreaInGrid[iAreaIndex])
		{
			iErrorAreaIndex = iAreaIndex;
			bAllIn = false;
			break;
		}
	}
	
	if (bAllIn)
	{
		LogMessage("All nav areas parsed into the grid!");
	}
	else
	{
		LogError("Warning! Not all nav areas were parsed into the grid! Please check your nav mesh!");
		LogError("First encountered nav area ID %d not in the grid!", GetArrayCell(g_hNavMeshAreas, iErrorAreaIndex));
	}
}

// The following functions should ONLY be called during NavMeshLoad(), due to displacement of
// array indexes!

// Some things to take into account: because we're adding things into the
// array, it's inevitable that the indexes will change over time. Therefore,
// we can't assign array indexes while this function is running, since it
// will shift preceding array indexes.

// The array indexes should be assigned afterwards using NavMeshGridFinalize().

public SortNavMeshGridLists(index1, index2, Handle:array, Handle:hndl)
{
	new iGridIndex1 = GetArrayCell(array, index1, NavMeshGridList_Owner);
	new iGridIndex2 = GetArrayCell(array, index2, NavMeshGridList_Owner);
	
	if (iGridIndex1 < iGridIndex2) return -1;
	else if (iGridIndex1 > iGridIndex2) return 1;
	return 0;
}

NavMeshGridAddAreaToList(iGridIndex, iAreaIndex)
{
	new iIndex = PushArrayCell(g_hNavMeshGridLists, iAreaIndex);
	
	if (iIndex != -1)
	{
		SetArrayCell(g_hNavMeshGridLists, iIndex, iGridIndex, NavMeshGridList_Owner);
	}
}

NavMeshGridGetListBounds(iGridIndex, &iStartIndex, &iEndIndex)
{
	iStartIndex = -1;
	iEndIndex = -1;
	
	for (new i = 0, iSize = GetArraySize(g_hNavMeshGridLists); i < iSize; i++)
	{
		if (GetArrayCell(g_hNavMeshGridLists, i, NavMeshGridList_Owner) == iGridIndex)
		{
			if (iStartIndex == -1) iStartIndex = i;
			iEndIndex = i;
		}
	}
}

NavMeshAddAreaToGrid(iAreaIndex)
{
	new Float:flExtentLow[2], Float:flExtentHigh[2];
//	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
//	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);
	
	flExtentLow[0] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_X1);
	flExtentLow[1] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Y1);
	flExtentHigh[0] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_X2);
	flExtentHigh[1] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Y2);
	
	new loX = NavMeshWorldToGridX(flExtentLow[0]);
	new loY = NavMeshWorldToGridY(flExtentLow[1]);
	new hiX = NavMeshWorldToGridX(flExtentHigh[0]);
	new hiY = NavMeshWorldToGridY(flExtentHigh[1]);
	
	/*
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH, "navtest.txt");
	new Handle:hFile = OpenFile(path, "a");
	
	WriteFileLine(hFile, "[%d]", GetArrayCell(g_hNavMeshAreas, iAreaIndex));
	WriteFileLine(hFile, "{");
	WriteFileLine(hFile, "\t---Extent: (%f, %f) - (%f, %f)", flExtentLow[0], flExtentLow[1], flExtentHigh[0], flExtentHigh[1]);
	*/
	
	for (new y = loY; y <= hiY; ++y)
	{
		//WriteFileLine(hFile, "\t--- y = %d", y);
	
		for (new x = loX; x <= hiX; ++x)
		{
			//WriteFileLine(hFile, "\t\t--- x = %d", x);
		
			new iGridIndex = x + y * g_iNavMeshGridSizeX;
			NavMeshGridAddAreaToList(iGridIndex, iAreaIndex);
			
			//WriteFileLine(hFile, "\t\t\t--- %d", iGridIndex);
		}
	}
	
	/*
	WriteFileLine(hFile, "}");
	CloseHandle(hFile);
	*/
}

// The following functions are stock functions associated with the navmesh grid. These
// are safe to use after the grid has been finalized using NavMeshGridFinalize(), and
// can be included in other stock functions as well.

stock IntCast(Float:val)
{
	if (val < 0.0) return RoundToFloor(val);
	return RoundToCeil(val);
}

stock NavMeshWorldToGridX(Float:flWX)
{
	new x = IntCast((flWX - g_flNavMeshMinX) / g_flNavMeshGridCellSize);
	
	if (x < 0) x = 0;
	else if (x >= g_iNavMeshGridSizeX) 
	{
	//	PrintToServer("NavMeshWorldToGridX: clamping x (%d) down to %d", x, g_iNavMeshGridSizeX - 1);
		x = g_iNavMeshGridSizeX - 1;
	}
	
	return x;
}

stock NavMeshWorldToGridY(Float:flWY)
{
	new y = IntCast((flWY - g_flNavMeshMinY) / g_flNavMeshGridCellSize);
	
	if (y < 0) y = 0;
	else if (y >= g_iNavMeshGridSizeY) 
	{
	//	PrintToServer("NavMeshWorldToGridY: clamping y (%d) down to %d", y, g_iNavMeshGridSizeY - 1);
		y = g_iNavMeshGridSizeY - 1;
	}
	
	return y;
}

stock Handle:NavMeshGridGetAreas(x, y)
{
	new iGridIndex = x + y * g_iNavMeshGridSizeX;
	new iListStartIndex = GetArrayCell(g_hNavMeshGrid, iGridIndex, NavMeshGrid_ListStartIndex);
	new iListEndIndex = GetArrayCell(g_hNavMeshGrid, iGridIndex, NavMeshGrid_ListEndIndex);
	
	if (iListStartIndex == -1) return INVALID_HANDLE;
	
	new Handle:hStack = CreateStack();
	
	for (new i = iListStartIndex; i <= iListEndIndex; i++)
	{
		PushStackCell(hStack, GetArrayCell(g_hNavMeshGridLists, i, NavMeshGridList_AreaIndex));
	}
	
	return hStack;
}

stock NavMeshGetNearestArea(const Float:flPos[3], bool:bAnyZ=false, Float:flMaxDist=10000.0, bool:bCheckLOS=false, bool:bCheckGround=true, iTeam=-2)
{
	if (GetArraySize(g_hNavMeshGridLists) == 0) return -1;
	
	new iClosestAreaIndex = -1;
	new Float:flClosestDistSq = flMaxDist * flMaxDist;
	
	if (!bCheckLOS && !bCheckGround)
	{
		iClosestAreaIndex = NavMeshGetArea(flPos);
		if (iClosestAreaIndex != -1) return iClosestAreaIndex;
	}
	
	decl Float:flSource[3];
	flSource[0] = flPos[0];
	flSource[1] = flPos[1];
	
	decl Float:flNormal[3];
	
	if (!NavMeshGetGroundHeight(flPos, flSource[2], flNormal))
	{
		if (!bCheckGround)
		{
			flSource[2] = flPos[2];
		}
		else
		{
			return -1;
		}
	}
	
	flSource[2] += HalfHumanHeight;
	
	static iSearchMarker = -1;
	if (iSearchMarker == -1) iSearchMarker = GetRandomInt(0, 1024 * 1024);
	
	iSearchMarker++;
	if (iSearchMarker == 0) iSearchMarker++;
	
	new iOriginX = NavMeshWorldToGridX(flPos[0]);
	new iOriginY = NavMeshWorldToGridY(flPos[1]);
	
	new iShiftLimit = RoundToCeil(flMaxDist / g_flNavMeshGridCellSize);
	
	for (new iShift = 0; iShift <= iShiftLimit; ++iShift)
	{
		for (new x = (iOriginX - iShift); x <= (iOriginX + iShift); ++x)
		{
			if (x < 0 || x >= g_iNavMeshGridSizeX) continue;
			
			for (new y = (iOriginY - iShift); y <= (iOriginY + iShift); ++y)
			{
				if (y < 0 || y >= g_iNavMeshGridSizeY) continue;
				
				if (x > (iOriginX - iShift) &&
					x < (iOriginX + iShift) &&
					y > (iOriginY - iShift) &&
					y < (iOriginY + iShift))
				{
					continue;
				}
				
				new Handle:hAreas = NavMeshGridGetAreas(x, y);
				if (hAreas != INVALID_HANDLE)
				{
					while (!IsStackEmpty(hAreas))
					{
						new iAreaIndex = -1;
						PopStackCell(hAreas, iAreaIndex);
						
						new iAreaNearSearchMarker = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_NearSearchMarker);
						if (iAreaNearSearchMarker == iSearchMarker) continue;
						
						if (GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Blocked)) 
						{
							continue;
						}
						
						SetArrayCell(g_hNavMeshAreas, iAreaIndex, iSearchMarker, NavMeshArea_NearSearchMarker);
						
						new Float:flAreaPos[3];
						NavMeshAreaGetClosestPointOnArea(iAreaIndex, flSource, flAreaPos);
						
						new Float:flDistSq = Pow(GetVectorDistance(flPos, flAreaPos), 2.0);
						
						if (flDistSq >= flClosestDistSq) continue;
						
						if (bCheckLOS)
						{
							decl Float:flSafePos[3];
							decl Float:flStartPos[3];
							decl Float:flEndPos[3];
							flEndPos[0] = flPos[0];
							flEndPos[1] = flPos[1];
							flEndPos[2] = flPos[2] + StepHeight;
							
							new Handle:hTrace = TR_TraceRayEx(flPos, flEndPos, MASK_NPCSOLID_BRUSHONLY, RayType_EndPoint);
							new Float:flFraction = TR_GetFraction(hTrace);
							TR_GetEndPosition(flEndPos, hTrace);
							CloseHandle(hTrace);
							
							if (flFraction == 0.0)
							{
								flSafePos[0] = flEndPos[0];
								flSafePos[1] = flEndPos[1];
								flSafePos[2] = flEndPos[2] + 1.0;
							}
							else
							{
								flSafePos[0] = flPos[0];
								flSafePos[1] = flPos[1];
								flSafePos[2] = flPos[2];
							}
							
							new Float:flHeightDelta = FloatAbs(flAreaPos[2] - flSafePos[2]);
							if (flHeightDelta > StepHeight)
							{
								flStartPos[0] = flAreaPos[0];
								flStartPos[1] = flAreaPos[1];
								flStartPos[2] = flAreaPos[2] + StepHeight;
								
								flEndPos[0] = flAreaPos[0];
								flEndPos[1] = flAreaPos[1];
								flEndPos[2] = flSafePos[2];
								
								hTrace = TR_TraceRayEx(flStartPos, flEndPos, MASK_NPCSOLID_BRUSHONLY, RayType_EndPoint);
								flFraction = TR_GetFraction(hTrace);
								CloseHandle(hTrace);
								
								if (flFraction != 1.0)
								{
									continue;
								}
							}
							
							flEndPos[0] = flAreaPos[0];
							flEndPos[1] = flAreaPos[1];
							flEndPos[2] = flSafePos[2] + StepHeight;
							
							hTrace = TR_TraceRayEx(flSafePos, flEndPos, MASK_NPCSOLID_BRUSHONLY, RayType_EndPoint);
							flFraction = TR_GetFraction(hTrace);
							CloseHandle(hTrace);
							
							if (flFraction != 1.0)
							{
								continue;
							}
						}
						
						flClosestDistSq = flDistSq;
						iClosestAreaIndex = iAreaIndex;
						
						iShiftLimit = iShift + 1;
					}
					
					CloseHandle(hAreas);
				}
			}
		}
	}
	
	return iClosestAreaIndex;
}

stock NavMeshAreaGetClosestPointOnArea(iAreaIndex, const Float:flPos[3], Float:flClose[3])
{
	new Float:x, Float:y, Float:z;
	
	new Float:flExtentLow[3], Float:flExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);
	
	x = fsel(flPos[0] - flExtentLow[0], flPos[0], flExtentLow[0]);
	x = fsel(x - flExtentHigh[0], flExtentHigh[0], x);
	
	y = fsel(flPos[1] - flExtentLow[1], flPos[1], flExtentLow[1]);
	y = fsel(y - flExtentHigh[1], flExtentHigh[1], y);
	
	z = NavMeshAreaGetZFromXAndY(iAreaIndex, x, y);
	
	flClose[0] = x;
	flClose[1] = y;
	flClose[2] = z;
}

stock Float:fsel(Float:a, Float:b, Float:c)
{
	return a >= 0.0 ? b : c;
}

stock NavMeshAreaGetFlags(iAreaIndex)
{
	if (!g_bNavMeshBuilt) return 0;
	
	return GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Flags);
}

stock bool:NavMeshAreaGetCenter(iAreaIndex, Float:flBuffer[3])
{
	if (!g_bNavMeshBuilt) return false;
	
	flBuffer[0] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CenterX);
	flBuffer[1] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CenterY);
	flBuffer[2] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CenterZ);
	return true;
}

stock Handle:NavMeshAreaGetAdjacentList(iAreaIndex, iNavDirection)
{
	if (!g_bNavMeshBuilt) return INVALID_HANDLE;
	
	new iConnectionsStartIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_ConnectionsStartIndex);
	if (iConnectionsStartIndex == -1) return INVALID_HANDLE;
	
	new iConnectionsEndIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_ConnectionsEndIndex);
	
	new Handle:hStack = CreateStack();
	
	for (new i = iConnectionsStartIndex; i <= iConnectionsEndIndex; i++)
	{
		if (GetArrayCell(g_hNavMeshAreaConnections, i, NavMeshConnection_Direction) == iNavDirection)
		{
			PushStackCell(hStack, GetArrayCell(g_hNavMeshAreaConnections, i, NavMeshConnection_AreaIndex));
		}
	}
	
	return hStack;
}

stock Handle:NavMeshAreaGetLadderList(iAreaIndex, iLadderDir)
{
	if (!g_bNavMeshBuilt) return INVALID_HANDLE;
	
	new iLadderConnectionsStartIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_LadderConnectionsStartIndex);
	if (iLadderConnectionsStartIndex == -1) return INVALID_HANDLE;
	
	new iLadderConnectionsEndIndex = GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_LadderConnectionsEndIndex);
	
	new Handle:hStack = CreateStack();
	
	for (new i = iLadderConnectionsStartIndex; i <= iLadderConnectionsEndIndex; i++)
	{
		if (GetArrayCell(g_hNavMeshAreaLadderConnections, i, NavMeshLadderConnection_Direction) == iLadderDir)
		{
			PushStackCell(hStack, GetArrayCell(g_hNavMeshAreaLadderConnections, i, NavMeshLadderConnection_LadderIndex));
		}
	}
	
	return hStack;
}

stock NavMeshAreaGetTotalCost(iAreaIndex)
{
	if (!g_bNavMeshBuilt) return 0;
	
	return GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_TotalCost);
}

stock NavMeshAreaGetCostSoFar(iAreaIndex)
{
	if (!g_bNavMeshBuilt) return 0;
	
	return GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CostSoFar);
}

stock NavMeshAreaGetParent(iAreaIndex)
{
	if (!g_bNavMeshBuilt) return -1;
	
	return GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Parent);
}

stock NavMeshAreaGetParentHow(iAreaIndex)
{
	if (!g_bNavMeshBuilt) return NUM_TRAVERSE_TYPES;
	
	return GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_ParentHow);
}

stock NavMeshAreaSetParent(iAreaIndex, iParentAreaIndex)
{
	if (!g_bNavMeshBuilt) return;
	
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, iParentAreaIndex, NavMeshArea_Parent);
}

stock NavMeshAreaSetParentHow(iAreaIndex, iParentHow)
{
	if (!g_bNavMeshBuilt) return;
	
	SetArrayCell(g_hNavMeshAreas, iAreaIndex, iParentHow, NavMeshArea_ParentHow);
}

stock bool:NavMeshAreaGetExtentLow(iAreaIndex, Float:flBuffer[3])
{
	if (!g_bNavMeshBuilt) return false;
	
	flBuffer[0] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_X1);
	flBuffer[1] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Y1);
	flBuffer[2] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Z1);
	return true;
}

stock bool:NavMeshAreaGetExtentHigh(iAreaIndex, Float:flBuffer[3])
{
	if (!g_bNavMeshBuilt) return false;
	
	flBuffer[0] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_X2);
	flBuffer[1] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Y2);
	flBuffer[2] = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_Z2);
	return true;
}

stock bool:NavMeshAreaIsOverlappingPoint(iAreaIndex, const Float:flPos[3], Float:flTolerance)
{
	if (!g_bNavMeshBuilt) return false;
	
	decl Float:flExtentLow[3], Float:flExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);
	
	if (flPos[0] + flTolerance >= flExtentLow[0] &&
		flPos[0] - flTolerance <= flExtentHigh[0] &&
		flPos[1] + flTolerance >= flExtentLow[1] &&
		flPos[1] - flTolerance <= flExtentHigh[1])
	{
		return true;
	}
	
	return false;
}

stock bool:NavMeshAreaIsOverlappingArea(iAreaIndex, iTargetAreaIndex)
{
	if (!g_bNavMeshBuilt) return false;
	
	decl Float:flExtentLow[3], Float:flExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);
	
	decl Float:flTargetExtentLow[3], Float:flTargetExtentHigh[3];
	NavMeshAreaGetExtentLow(iTargetAreaIndex, flTargetExtentLow);
	NavMeshAreaGetExtentHigh(iTargetAreaIndex, flTargetExtentHigh);
	
	if (flTargetExtentLow[0] < flExtentHigh[0] &&
		flTargetExtentHigh[0] > flExtentLow[0] &&
		flTargetExtentLow[1] < flExtentHigh[1] &&
		flTargetExtentHigh[1] > flExtentLow[1])
	{
		return true;
	}
	
	return false;
}

stock Float:NavMeshAreaGetNECornerZ(iAreaIndex)
{
	if (!g_bNavMeshBuilt) return 0.0;
	
	return Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_NECornerZ);
}

stock Float:NavMeshAreaGetSWCornerZ(iAreaIndex)
{
	if (!g_bNavMeshBuilt) return 0.0;
	
	return Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_SWCornerZ);
}

stock Float:NavMeshAreaGetZ(iAreaIndex, const Float:flPos[3])
{
	if (!g_bNavMeshBuilt) return 0.0;
	
	decl Float:flExtentLow[3], Float:flExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);
	
	new Float:dx = flExtentHigh[0] - flExtentLow[0];
	new Float:dy = flExtentHigh[1] - flExtentLow[1];
	
	new Float:flNEZ = NavMeshAreaGetNECornerZ(iAreaIndex);
	
	if (dx == 0.0 || dy == 0.0)
	{
		return flNEZ;
	}
	
	new Float:u = (flPos[0] - flExtentLow[0]) / dx;
	new Float:v = (flPos[1] - flExtentLow[1]) / dy;
	
	u = fsel(u, u, 0.0);
	u = fsel(u - 1.0, 1.0, u);
	
	v = fsel(v, v, 0.0);
	v = fsel(v - 1.0, 1.0, v);
	
	new Float:flSWZ = NavMeshAreaGetSWCornerZ(iAreaIndex);
	
	new Float:flNorthZ = flExtentLow[2] + u * (flNEZ - flExtentLow[2]);
	new Float:flSouthZ = flSWZ + u * (flExtentHigh[2] - flSWZ);
	
	return flNorthZ + v * (flSouthZ - flNorthZ);
}

stock Float:NavMeshAreaGetZFromXAndY(iAreaIndex, Float:x, Float:y)
{
	if (!g_bNavMeshBuilt) return 0.0;
	
	new Float:flInvDxCorners = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_InvDxCorners);
	new Float:flInvDyCorners = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_InvDyCorners);
	
	new Float:flNECornerZ = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_NECornerZ);
	
	if (flInvDxCorners == 0.0 || flInvDyCorners == 0.0)
	{
		return flNECornerZ;
	}
	
	decl Float:flExtentLow[3], Float:flExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);

	new Float:u = (x - flExtentLow[0]) * flInvDxCorners;
	new Float:v = (y - flExtentLow[1]) * flInvDyCorners;
	
	u = FloatClamp(u, 0.0, 1.0);
	v = FloatClamp(v, 0.0, 1.0);
	
	new Float:flSWCornerZ = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_SWCornerZ);
	
	new Float:flNorthZ = flExtentLow[2] + u * (flNECornerZ - flExtentLow[2]);
	new Float:flSouthZ = flSWCornerZ + u * (flExtentHigh[2] - flSWCornerZ);
	
	return flNorthZ + v * (flSouthZ - flNorthZ);
}

stock bool:NavMeshAreaContains(iAreaIndex, const Float:flPos[3])
{
	if (!g_bNavMeshBuilt) return false;
	
	if (!NavMeshAreaIsOverlappingPoint(iAreaIndex, flPos, 0.0)) return false;
	
	new Float:flMyZ = NavMeshAreaGetZ(iAreaIndex, flPos);
	
	if ((flMyZ - StepHeight) > flPos[2]) return false;
	
	for (new i = 0, iSize = GetArraySize(g_hNavMeshAreas); i < iSize; i++)
	{
		if (i == iAreaIndex) continue;
		
		if (!NavMeshAreaIsOverlappingArea(iAreaIndex, i)) continue;
		
		new Float:flTheirZ = NavMeshAreaGetZ(i, flPos);
		if ((flTheirZ - StepHeight) > flPos[2]) continue;
		
		if (flTheirZ > flMyZ)
		{
			return false;
		}
	}
	
	return true;
}

stock bool:NavMeshAreaComputePortal(iAreaIndex, iAreaToIndex, iNavDirection, Float:flCenter[3], &Float:flHalfWidth)
{
	if (!g_bNavMeshBuilt) return false;
	
	decl Float:flAreaExtentLow[3], Float:flAreaExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flAreaExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flAreaExtentHigh);
	
	decl Float:flAreaToExtentLow[3], Float:flAreaToExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaToIndex, flAreaToExtentLow);
	NavMeshAreaGetExtentHigh(iAreaToIndex, flAreaToExtentHigh);
	
	if (iNavDirection == NAV_DIR_NORTH || iNavDirection == NAV_DIR_SOUTH)
	{
		if (iNavDirection == NAV_DIR_NORTH)
		{
			flCenter[1] = flAreaExtentLow[1];
		}
		else
		{
			flCenter[1] = flAreaExtentHigh[1];
		}
		
		new Float:flLeft = flAreaExtentLow[0] > flAreaToExtentLow[0] ? flAreaExtentLow[0] : flAreaToExtentLow[0];
		new Float:flRight = flAreaExtentHigh[0] < flAreaToExtentHigh[0] ? flAreaExtentHigh[0] : flAreaToExtentHigh[0];
		
		if (flLeft < flAreaExtentLow[0]) flLeft = flAreaExtentLow[0];
		else if (flLeft > flAreaExtentHigh[0]) flLeft = flAreaExtentHigh[0];
		
		if (flRight < flAreaExtentLow[0]) flRight = flAreaExtentLow[0];
		else if (flRight > flAreaExtentHigh[0]) flRight = flAreaExtentHigh[0];
		
		flCenter[0] = (flLeft + flRight) / 2.0;
		flHalfWidth = (flRight - flLeft) / 2.0;
	}
	else
	{
		if (iNavDirection == NAV_DIR_WEST)
		{
			flCenter[0] = flAreaExtentLow[0];
		}
		else
		{
			flCenter[0] = flAreaExtentHigh[0];
		}
		
		new Float:flTop = flAreaExtentLow[1] > flAreaToExtentLow[1] ? flAreaExtentLow[1] : flAreaToExtentLow[1];
		new Float:flBottom = flAreaExtentHigh[1] < flAreaToExtentHigh[1] ? flAreaExtentHigh[1] : flAreaToExtentHigh[1];
		
		if (flTop < flAreaExtentLow[1]) flTop = flAreaExtentLow[1];
		else if (flTop > flAreaExtentHigh[1]) flTop = flAreaExtentHigh[1];
		
		if (flBottom < flAreaExtentLow[1]) flBottom = flAreaExtentLow[1];
		else if (flBottom > flAreaExtentHigh[1]) flBottom = flAreaExtentHigh[1];
		
		flCenter[1] = (flTop + flBottom) / 2.0;
		flHalfWidth = (flBottom - flTop) / 2.0;
	}
	
	flCenter[2] = NavMeshAreaGetZFromXAndY(iAreaIndex, flCenter[0], flCenter[1]);
	
	return true;
}

stock Float:FloatMin(Float:a, Float:b)
{
	if (a < b) return a;
	return b;
}

stock Float:FloatMax(Float:a, Float:b)
{
	if (a > b) return a;
	return b;
}

stock bool:NavMeshAreaComputeClosestPointInPortal(iAreaIndex, iAreaToIndex, iNavDirection, const Float:flFromPos[3], Float:flClosestPos[3])
{
	if (!g_bNavMeshBuilt) return false;
	
	static Float:flMargin = 25.0; // GenerationStepSize = 25.0;
	
	decl Float:flAreaExtentLow[3], Float:flAreaExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flAreaExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flAreaExtentHigh);
	
	decl Float:flAreaToExtentLow[3], Float:flAreaToExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaToIndex, flAreaToExtentLow);
	NavMeshAreaGetExtentHigh(iAreaToIndex, flAreaToExtentHigh);
	
	if (iNavDirection == NAV_DIR_NORTH || iNavDirection == NAV_DIR_SOUTH)
	{
		if (iNavDirection == NAV_DIR_NORTH)
		{
			flClosestPos[1] = flAreaExtentLow[1];
		}
		else
		{
			flClosestPos[1] = flAreaExtentHigh[1];
		}
		
		new Float:flLeft = FloatMax(flAreaExtentLow[0], flAreaToExtentLow[0]);
		new Float:flRight = FloatMin(flAreaExtentHigh[0], flAreaToExtentHigh[0]);
		
		new Float:flLeftMargin = NavMeshAreaIsEdge(iAreaToIndex, NAV_DIR_WEST) ? (flLeft + flMargin) : flLeft;
		new Float:flRightMargin = NavMeshAreaIsEdge(iAreaToIndex, NAV_DIR_EAST) ? (flRight - flMargin) : flRight;
		
		if (flLeftMargin > flRightMargin)
		{
			new Float:flMid = (flLeft + flRight) / 2.0;
			flLeftMargin = flMid;
			flRightMargin = flMid;
		}
		
		if (flFromPos[0] < flLeftMargin)
		{
			flClosestPos[0] = flLeftMargin;
		}
		else if (flFromPos[0] > flRightMargin)
		{
			flClosestPos[0] = flRightMargin;
		}
		else
		{
			flClosestPos[0] = flFromPos[0];
		}
	}
	else
	{
		if (iNavDirection == NAV_DIR_WEST)
		{
			flClosestPos[0] = flAreaExtentLow[0];
		}
		else
		{
			flClosestPos[0] = flAreaExtentHigh[0];
		}
		
		new Float:flTop = FloatMax(flAreaExtentLow[1], flAreaToExtentLow[1]);
		new Float:flBottom = FloatMin(flAreaExtentHigh[1], flAreaToExtentHigh[1]);
		
		new Float:flTopMargin = NavMeshAreaIsEdge(iAreaToIndex, NAV_DIR_NORTH) ? (flTop + flMargin) : flTop;
		new Float:flBottomMargin = NavMeshAreaIsEdge(iAreaToIndex, NAV_DIR_SOUTH) ? (flBottom - flMargin) : flBottom;
		
		if (flTopMargin > flBottomMargin)
		{
			new Float:flMid = (flTop + flBottom) / 2.0;
			flTopMargin = flMid;
			flBottomMargin = flMid;
		}
		
		if (flFromPos[1] < flTopMargin)
		{
			flClosestPos[1] = flTopMargin;
		}
		else if (flFromPos[1] > flBottomMargin)
		{
			flClosestPos[1] = flBottomMargin;
		}
		else
		{
			flClosestPos[1] = flFromPos[1];
		}
	}
	
	flClosestPos[2] = NavMeshAreaGetZFromXAndY(iAreaIndex, flClosestPos[0], flClosestPos[1]);
	
	return true;
}

stock NavMeshAreaComputeDirection(iAreaIndex, const Float:flPos[3])
{
	if (!g_bNavMeshBuilt) return NAV_DIR_COUNT;
	
	decl Float:flExtentLow[3], Float:flExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);
	
	if (flPos[0] >= flExtentLow[0] && flPos[0] <= flExtentHigh[0])
	{
		if (flPos[1] < flExtentLow[1])
		{
			return NAV_DIR_NORTH;
		}
		else if (flPos[1] > flExtentHigh[1])
		{
			return NAV_DIR_SOUTH;
		}
	}
	else if (flPos[1] >= flExtentLow[1] && flPos[1] <= flExtentHigh[1])
	{
		if (flPos[0] < flExtentLow[0])
		{
			return NAV_DIR_WEST;
		}
		else if (flPos[0] > flExtentHigh[0])
		{
			return NAV_DIR_EAST;
		}
	}
	
	decl Float:flCenter[3];
	NavMeshAreaGetCenter(iAreaIndex, flCenter);
	
	decl Float:flTo[3];
	SubtractVectors(flPos, flCenter, flTo);
	
	if (FloatAbs(flTo[0]) > FloatAbs(flTo[1]))
	{
		if (flTo[0] > 0.0) return NAV_DIR_EAST;
		
		return NAV_DIR_WEST;
	}
	else
	{
		if (flTo[1] > 0.0) return NAV_DIR_SOUTH;
		
		return NAV_DIR_NORTH;
	}
}

stock Float:NavMeshAreaGetLightIntensity(iAreaIndex, const Float:flPos[3])
{
	if (!g_bNavMeshBuilt) return 0.0;
	
	decl Float:flExtentLow[3], Float:flExtentHigh[3];
	NavMeshAreaGetExtentLow(iAreaIndex, flExtentLow);
	NavMeshAreaGetExtentHigh(iAreaIndex, flExtentHigh);

	decl Float:flTestPos[3];
	flTestPos[0] = FloatClamp(flPos[0], flExtentLow[0], flExtentHigh[0]);
	flTestPos[1] = FloatClamp(flPos[1], flExtentLow[1], flExtentHigh[1]);
	flTestPos[2] = flPos[2];
	
	new Float:dX = (flTestPos[0] - flExtentLow[0]) / (flExtentHigh[0] - flExtentLow[0]);
	new Float:dY = (flTestPos[1] - flExtentLow[1]) / (flExtentHigh[1] - flExtentLow[1]);
	
	new Float:flCornerLightIntensityNW = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CornerLightIntensityNW);
	new Float:flCornerLightIntensityNE = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CornerLightIntensityNE);
	new Float:flCornerLightIntensitySW = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CornerLightIntensitySW);
	new Float:flCornerLightIntensitySE = Float:GetArrayCell(g_hNavMeshAreas, iAreaIndex, NavMeshArea_CornerLightIntensitySE);
	
	new Float:flNorthLight = flCornerLightIntensityNW * (1.0 - dX) + flCornerLightIntensityNE * dX;
	new Float:flSouthLight = flCornerLightIntensitySW * (1.0 - dX) + flCornerLightIntensitySE * dX;
	
	return (flNorthLight * (1.0 - dY) + flSouthLight * dY);
}


stock Float:FloatClamp(Float:a, Float:min, Float:max)
{
	if (a < min) a = min;
	if (a > max) a = max;
	return a;
}

stock bool:NavMeshAreaIsEdge(iAreaIndex, iNavDirection)
{
	new Handle:hConnections = NavMeshAreaGetAdjacentList(iAreaIndex, iNavDirection);
	if (hConnections == INVALID_HANDLE || IsStackEmpty(hConnections))
	{
		if (hConnections != INVALID_HANDLE) CloseHandle(hConnections);
		return true;
	}
	
	CloseHandle(hConnections);
	return false;
}

stock Float:NavMeshLadderGetLength(iLadderIndex)
{
	if (!g_bNavMeshBuilt) return 0.0;
	
	return Float:GetArrayCell(g_hNavMeshLadders, iLadderIndex, NavMeshLadder_Length);
}

stock NavMeshGetArea(const Float:flPos[3], Float:flBeneathLimit=120.0)
{
	if (!g_bNavMeshBuilt) return -1;
	
	new x = NavMeshWorldToGridX(flPos[0]);
	new y = NavMeshWorldToGridY(flPos[1]);
	
	new Handle:hAreas = NavMeshGridGetAreas(x, y);
	
	new iUseAreaIndex = -1;
	new Float:flUseZ = -99999999.9;
	new Float:flTestPos[3];
	flTestPos[0] = flPos[0];
	flTestPos[1] = flPos[1];
	flTestPos[2] = flPos[2] + 5.0;
	
	if (hAreas != INVALID_HANDLE)
	{
		while (IsStackEmpty(hAreas))
		{
			new iAreaIndex = -1;
			PopStackCell(hAreas, iAreaIndex);
			
			if (NavMeshAreaIsOverlappingPoint(iAreaIndex, flTestPos, 0.0))
			{
				new Float:z = NavMeshAreaGetZ(iAreaIndex, flTestPos);
				
				if (z > flTestPos[2]) continue;
				
				if (z < flPos[2] - flBeneathLimit) continue;
				
				if (z > flUseZ)
				{
					iUseAreaIndex = iAreaIndex;
					flUseZ = z;
				}
			}
		}
		
		CloseHandle(hAreas);
	}
	
	return iUseAreaIndex;
}

stock bool:NavMeshGetGroundHeight(const Float:flPos[3], &Float:flHeight, Float:flNormal[3])
{
	static Float:flMaxOffset = 100.0;
	
	decl Float:flTo[3], Float:flFrom[3];
	flTo[0] = flPos[0];
	flTo[1] = flPos[1];
	flTo[2] = flPos[2] - 10000.0;
	
	flFrom[0] = flPos[0];
	flFrom[1] = flPos[1];
	flFrom[2] = flPos[2] + HalfHumanHeight + 0.001;
	
	while (flTo[2] - flPos[2] < flMaxOffset)
	{
		new Handle:hTrace = TR_TraceRayEx(flFrom, flTo, MASK_NPCSOLID_BRUSHONLY, RayType_EndPoint);
		new Float:flFraction = TR_GetFraction(hTrace);
		decl Float:flPlaneNormal[3];
		decl Float:flEndPos[3];
		TR_GetEndPosition(flEndPos, hTrace);
		TR_GetPlaneNormal(hTrace, flPlaneNormal);
		CloseHandle(hTrace);
		
		if (flFraction == 1.0 || ((flFrom[2] - flEndPos[2]) >= HalfHumanHeight))
		{
			flHeight = flEndPos[2];
			flNormal[0] = flPlaneNormal[0];
			flNormal[1] = flPlaneNormal[1];
			flNormal[2] = flPlaneNormal[2];
			return true;
		}
		
		flTo[2] = (flFraction == 0.0) ? flFrom[2] : flEndPos[2];
		flFrom[2] = flTo[2] + HalfHumanHeight + 0.001;
	}
	
	flHeight = 0.0;
	flNormal[0] = 0.0;
	flNormal[1] = 0.0;
	flNormal[2] = 1.0;
	
	return false;
}

//	==================================
//	API
//	==================================

public Native_NavMeshExists(Handle:plugin, numParams)
{
	return g_bNavMeshBuilt;
}

public Native_NavMeshGetMagicNumber(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve magic number because the nav mesh doesn't exist!");
		return -1;
	}
	
	return g_iNavMeshMagicNumber;
}

public Native_NavMeshGetVersion(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve version because the nav mesh doesn't exist!");
		return -1;
	}
	
	return g_iNavMeshVersion;
}

public Native_NavMeshGetSubVersion(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve subversion because the nav mesh doesn't exist!");
		return -1;
	}
	
	return g_iNavMeshSubVersion;
}

public Native_NavMeshGetSaveBSPSize(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve save BSP size because the nav mesh doesn't exist!");
		return -1;
	}
	
	return g_iNavMeshSaveBSPSize;
}

public Native_NavMeshIsAnalyzed(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve analysis state because the nav mesh doesn't exist!");
		return 0;
	}
	
	return g_bNavMeshAnalyzed;
}

public Native_NavMeshGetPlaces(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve place list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshPlaces;
}

public Native_NavMeshGetAreas(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve area list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshAreas;
}

public Native_NavMeshGetLadders(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve ladder list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshLadders;
}

//Added by Jared Ballou
public Native_NavMeshGetHidingSpots(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve hiding spot list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshAreaHidingSpots;
}

public Native_NavMeshGetConnections(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve hiding spot list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshAreaConnections;
}
public Native_NavMeshGetEncounterPaths(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve hiding spot list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshAreaEncounterPaths;
}
public Native_NavMeshGetEncounterSpots(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve hiding spot list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshAreaEncounterSpots;
}
public Native_NavMeshGetLadderConnections(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve hiding spot list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshAreaLadderConnections;
}
public Native_NavMeshGetVisibleAreas(Handle:plugin, numParams)
{
	if (!g_bNavMeshBuilt)
	{
		LogError("Could not retrieve hiding spot list because the nav mesh doesn't exist!");
		return _:INVALID_HANDLE;
	}
	
	return _:g_hNavMeshAreaVisibleAreas;
}

//End new additions

public Native_NavMeshCollectSurroundingAreas(Handle:plugin, numParams)
{
	new Handle:hTarget = Handle:GetNativeCell(1);
	new Handle:hDummy = NavMeshCollectSurroundingAreas(GetNativeCell(2), Float:GetNativeCell(3), Float:GetNativeCell(4), Float:GetNativeCell(5));
	
	if (hDummy != INVALID_HANDLE)
	{
		while (!IsStackEmpty(hDummy))
		{
			new iAreaIndex = -1;
			PopStackCell(hDummy, iAreaIndex);
			PushStackCell(hTarget, iAreaIndex);
		}
		
		CloseHandle(hDummy);
	}
}

public Native_NavMeshBuildPath(Handle:plugin, numParams)
{
	decl Float:flGoalPos[3];
	GetNativeArray(3, flGoalPos, 3);
	
	new iClosestIndex = GetNativeCellRef(6);
	
	new bool:bResult = NavMeshBuildPath(GetNativeCell(1), 
		GetNativeCell(2), 
		flGoalPos,
		plugin,
		Function:GetNativeCell(4),
		GetNativeCell(5),
		iClosestIndex,
		Float:GetNativeCell(7));
		
	SetNativeCellRef(6, iClosestIndex);
	return bResult;
}

public Native_NavMeshGetArea(Handle:plugin, numParams)
{
	decl Float:flPos[3];
	GetNativeArray(1, flPos, 3);

	return NavMeshGetArea(flPos, Float:GetNativeCell(2));
}

public Native_NavMeshGetNearestArea(Handle:plugin, numParams)
{
	decl Float:flPos[3];
	GetNativeArray(1, flPos, 3);
	
	return NavMeshGetNearestArea(flPos, bool:GetNativeCell(2), Float:GetNativeCell(3), bool:GetNativeCell(4), bool:GetNativeCell(5), GetNativeCell(6));
}

public Native_NavMeshWorldToGridX(Handle:plugin, numParams)
{
	return NavMeshWorldToGridX(Float:GetNativeCell(1));
}

public Native_NavMeshWorldToGridY(Handle:plugin, numParams)
{
	return NavMeshWorldToGridY(Float:GetNativeCell(1));
}

public Native_NavMeshGridGetAreas(Handle:plugin, numParams)
{
	new Handle:hTarget = Handle:GetNativeCell(1);
	new Handle:hDummy = NavMeshGridGetAreas(GetNativeCell(2), GetNativeCell(3));
	
	if (hDummy != INVALID_HANDLE)
	{
		while (!IsStackEmpty(hDummy))
		{
			new iAreaIndex = -1;
			PopStackCell(hDummy, iAreaIndex);
			PushStackCell(hTarget, iAreaIndex);
		}
		
		CloseHandle(hDummy);
	}
}

public Native_NavMeshGetGridSizeX(Handle:plugin, numParams)
{
	return g_iNavMeshGridSizeX;
}

public Native_NavMeshGetGridSizeY(Handle:plugin, numParams)
{
	return g_iNavMeshGridSizeY;
}

public Native_NavMeshAreaGetClosestPointOnArea(Handle:plugin, numParams)
{
	decl Float:flPos[3], Float:flClose[3];
	GetNativeArray(2, flPos, 3);
	NavMeshAreaGetClosestPointOnArea(GetNativeCell(1), flPos, flClose);
	SetNativeArray(3, flClose, 3);
}

//stock bool:NavMeshGetGroundHeight(const Float:flPos[3], &Float:flHeight, Float:flNormal[3])
public Native_NavMeshGetGroundHeight(Handle:plugin, numParams)
{
	decl Float:flPos[3], Float:flNormal[3];
	GetNativeArray(1, flPos, 3);
	new Float:flHeight = Float:GetNativeCellRef(2);
	new bool:bResult = NavMeshGetGroundHeight(flPos, flHeight, flNormal);
	SetNativeCellRef(2, flHeight);
	SetNativeArray(3, flNormal, 3);
	return bResult;
}

public Native_NavMeshAreaGetMasterMarker(Handle:plugin, numParams)
{
	return g_iNavMeshAreaMasterMarker;
}

public Native_NavMeshAreaChangeMasterMarker(Handle:plugin, numParams)
{
	g_iNavMeshAreaMasterMarker++;
}

public Native_NavMeshAreaGetFlags(Handle:plugin, numParams)
{
	return NavMeshAreaGetFlags(GetNativeCell(1));
}

public Native_NavMeshAreaGetCenter(Handle:plugin, numParams)
{
	decl Float:flResult[3];
	if (NavMeshAreaGetCenter(GetNativeCell(1), flResult))
	{
		SetNativeArray(2, flResult, 3);
		return true;
	}
	
	return false;
}

public Native_NavMeshAreaGetAdjacentList(Handle:plugin, numParams)
{
	new Handle:hTarget = Handle:GetNativeCell(1);
	new Handle:hDummy = NavMeshAreaGetAdjacentList(GetNativeCell(2), GetNativeCell(3));
	
	if (hDummy != INVALID_HANDLE)
	{
		while (!IsStackEmpty(hDummy))
		{
			new iAreaIndex = -1;
			PopStackCell(hDummy, iAreaIndex);
			PushStackCell(hTarget, iAreaIndex);
		}
		
		CloseHandle(hDummy);
	}
}

public Native_NavMeshAreaGetLadderList(Handle:plugin, numParams)
{
	new Handle:hTarget = Handle:GetNativeCell(1);

	new Handle:hDummy = NavMeshAreaGetLadderList(GetNativeCell(2), GetNativeCell(3));
	if (hDummy != INVALID_HANDLE)
	{
		while (!IsStackEmpty(hDummy))
		{
			new iAreaIndex = -1;
			PopStackCell(hDummy, iAreaIndex);
			PushStackCell(hTarget, iAreaIndex);
		}
		
		CloseHandle(hDummy);
	}
}

public Native_NavMeshAreaGetTotalCost(Handle:plugin, numParams)
{
	return NavMeshAreaGetTotalCost(GetNativeCell(1));
}

public Native_NavMeshAreaGetCostSoFar(Handle:plugin, numParams)
{
	return NavMeshAreaGetCostSoFar(GetNativeCell(1));
}

public Native_NavMeshAreaGetParent(Handle:plugin, numParams)
{
	return NavMeshAreaGetParent(GetNativeCell(1));
}

public Native_NavMeshAreaGetParentHow(Handle:plugin, numParams)
{
	return NavMeshAreaGetParentHow(GetNativeCell(1));
}

public Native_NavMeshAreaSetParent(Handle:plugin, numParams)
{
	NavMeshAreaSetParent(GetNativeCell(1), GetNativeCell(2));
}

public Native_NavMeshAreaSetParentHow(Handle:plugin, numParams)
{
	NavMeshAreaSetParentHow(GetNativeCell(1), GetNativeCell(2));
}

public Native_NavMeshAreaGetExtentLow(Handle:plugin, numParams)
{
	decl Float:flExtent[3];
	if (NavMeshAreaGetExtentLow(GetNativeCell(1), flExtent))
	{
		SetNativeArray(2, flExtent, 3);
		return true;
	}
	
	return false;
}

public Native_NavMeshAreaGetExtentHigh(Handle:plugin, numParams)
{
	decl Float:flExtent[3];
	if (NavMeshAreaGetExtentHigh(GetNativeCell(1), flExtent))
	{
		SetNativeArray(2, flExtent, 3);
		return true;
	}
	
	return false;
}

public Native_NavMeshAreaIsOverlappingPoint(Handle:plugin, numParams)
{
	decl Float:flPos[3];
	GetNativeArray(2, flPos, 3);
	
	return NavMeshAreaIsOverlappingPoint(GetNativeCell(1), flPos, Float:GetNativeCell(3));
}

public Native_NavMeshAreaIsOverlappingArea(Handle:plugin, numParams)
{
	return NavMeshAreaIsOverlappingArea(GetNativeCell(1), GetNativeCell(2));
}

public Native_NavMeshAreaGetNECornerZ(Handle:plugin, numParams)
{
	return _:NavMeshAreaGetNECornerZ(GetNativeCell(1));
}

public Native_NavMeshAreaGetSWCornerZ(Handle:plugin, numParams)
{
	return _:NavMeshAreaGetSWCornerZ(GetNativeCell(1));
}

public Native_NavMeshAreaGetZ(Handle:plugin, numParams)
{
	decl Float:flPos[3];
	GetNativeArray(2, flPos, 3);

	return _:NavMeshAreaGetZ(GetNativeCell(1), flPos);
}

public Native_NavMeshAreaGetZFromXAndY(Handle:plugin, numParams)
{
	return _:NavMeshAreaGetZFromXAndY(GetNativeCell(1), Float:GetNativeCell(2), Float:GetNativeCell(3));
}

public Native_NavMeshAreaContains(Handle:plugin, numParams)
{
	decl Float:flPos[3];
	GetNativeArray(2, flPos, 3);

	return NavMeshAreaContains(GetNativeCell(1), flPos);
}

public Native_NavMeshAreaComputePortal(Handle:plugin, numParams)
{
	new Float:flCenter[3];
	new Float:flHalfWidth = GetNativeCellRef(5);
	
	new bool:bResult = NavMeshAreaComputePortal(GetNativeCell(1),
		GetNativeCell(2),
		GetNativeCell(3),
		flCenter,
		flHalfWidth);
		
	SetNativeArray(4, flCenter, 3);
	SetNativeCellRef(5, flHalfWidth);
	return bResult;
}

public Native_NavMeshAreaComputeClosestPointInPortal(Handle:plugin, numParams)
{
	decl Float:flFromPos[3];
	GetNativeArray(4, flFromPos, 3);
	
	new Float:flClosestPos[3];

	new bool:bResult = NavMeshAreaComputeClosestPointInPortal(GetNativeCell(1),
		GetNativeCell(2),
		GetNativeCell(3),
		flFromPos,
		flClosestPos);
		
	SetNativeArray(5, flClosestPos, 3);
	return bResult;
}

public Native_NavMeshAreaComputeDirection(Handle:plugin, numParams)
{
	decl Float:flPos[3];
	GetNativeArray(2, flPos, 3);
	
	return NavMeshAreaComputeDirection(GetNativeCell(1), flPos);
}

public Native_NavMeshAreaGetLightIntensity(Handle:plugin, numParams)
{
	decl Float:flPos[3];
	GetNativeArray(2, flPos, 3);
	
	return _:NavMeshAreaGetLightIntensity(GetNativeCell(1), flPos);
}

public Native_NavMeshLadderGetLength(Handle:plugin, numParams)
{
	return _:NavMeshLadderGetLength(GetNativeCell(1));
}
