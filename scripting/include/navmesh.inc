#if defined _navmesh_included
 #endinput
#endif
#define _navmesh_included

#define HalfHumanHeight 35.5

#define StepHeight 18.0

#define NAV_MAGIC_NUMBER 0xFEEDFACE

enum
{
	NAV_DIR_NORTH = 0,
	NAV_DIR_EAST,
	NAV_DIR_SOUTH,
	NAV_DIR_WEST,
	NAV_DIR_COUNT
};

enum
{
	NAV_CORNER_NORTH_WEST = 0,
	NAV_CORNER_NORTH_EAST,
	NAV_CORNER_SOUTH_EAST,
	NAV_CORNER_SOUTH_WEST,
	NAV_CORNER_COUNT
};

enum
{
	NAV_LADDER_DIR_UP = 0,
	NAV_LADDER_DIR_DOWN,
	NAV_LADDER_DIR_COUNT
};

enum
{
	NAV_MESH_CROUCH = 0x0001, 
	NAV_MESH_JUMP = 0x0002, 
	NAV_MESH_PRECISE = 0x0004, 
	NAV_MESH_NO_JUMP = 0x0008, 
	NAV_MESH_STOP = 0x0010, 
	NAV_MESH_RUN = 0x0020, 
	NAV_MESH_WALK = 0x0040, 
	NAV_MESH_AVOID = 0x0080, 
	NAV_MESH_TRANSIENT = 0x0100, 
	NAV_MESH_DONT_HIDE = 0x0200, 
	NAV_MESH_STAND = 0x0400, 
	NAV_MESH_NO_HOSTAGES = 0x0800
};

enum
{
	GO_NORTH = 0,
	GO_EAST,
	GO_SOUTH,
	GO_WEST,
	GO_LADDER_UP,
	GO_LADDER_DOWN,
	GO_JUMP,
	NUM_TRAVERSE_TYPES
};

enum
{
	NavMeshArea_ID = 0,
	NavMeshArea_Flags,
	NavMeshArea_PlaceID,
	NavMeshArea_X1,
	NavMeshArea_Y1,
	NavMeshArea_Z1,
	NavMeshArea_X2,
	NavMeshArea_Y2,
	NavMeshArea_Z2,
	NavMeshArea_CenterX,
	NavMeshArea_CenterY,
	NavMeshArea_CenterZ,
	NavMeshArea_InvDxCorners,
	NavMeshArea_InvDyCorners,
	NavMeshArea_NECornerZ,
	NavMeshArea_SWCornerZ,
	
//	NavMeshArea_Connections,
	NavMeshArea_ConnectionsStartIndex,
	NavMeshArea_ConnectionsEndIndex,
	
//	NavMeshArea_HidingSpots,
	NavMeshArea_HidingSpotsStartIndex,
	NavMeshArea_HidingSpotsEndIndex,
	
//	NavMeshArea_EncounterPaths,
	NavMeshArea_EncounterPathsStartIndex,
	NavMeshArea_EncounterPathsEndIndex,
	
//	NavMeshArea_LadderConnections,
	NavMeshArea_LadderConnectionsStartIndex,
	NavMeshArea_LadderConnectionsEndIndex,
	
	NavMeshArea_CornerLightIntensityNW,
	NavMeshArea_CornerLightIntensityNE,
	NavMeshArea_CornerLightIntensitySE,
	NavMeshArea_CornerLightIntensitySW,
	
//	NavMeshArea_VisibleAreas,
	NavMeshArea_VisibleAreasStartIndex,
	NavMeshArea_VisibleAreasEndIndex,
	
	NavMeshArea_InheritVisibilityFrom,
	NavMeshArea_EarliestOccupyTimeFirstTeam,
	NavMeshArea_EarliestOccupyTimeSecondTeam,
	NavMeshArea_unk01,
	NavMeshArea_Blocked,
	
// 	A* pathfinding
	NavMeshArea_Parent,
	NavMeshArea_ParentHow,
	NavMeshArea_CostSoFar,
	NavMeshArea_TotalCost,
	NavMeshArea_Marker,
	NavMeshArea_OpenMarker,
	NavMeshArea_PrevOpenIndex,
	NavMeshArea_NextOpenIndex,
	NavMeshArea_PathLengthSoFar,
	
	NavMeshArea_NearSearchMarker,
	
	NavMeshArea_MaxStats
};

enum
{
	NavMeshConnection_AreaIndex = 0,
	NavMeshConnection_Direction,
	NavMeshConnection_MaxStats
};

enum
{
	NavMeshHidingSpot_ID = 0,
	NavMeshHidingSpot_X,
	NavMeshHidingSpot_Y,
	NavMeshHidingSpot_Z,
	NavMeshHidingSpot_Flags,
	NavMeshHidingSpot_MaxStats
};

enum
{
	NavMeshEncounterPath_FromID = 0,
	NavMeshEncounterPath_FromDirection,
	NavMeshEncounterPath_ToID,
	NavMeshEncounterPath_ToDirection,
	NavMeshEncounterPath_SpotsStartIndex,
	NavMeshEncounterPath_SpotsEndIndex,
	NavMeshEncounterPath_MaxStats
};

enum
{
	NavMeshEncounterSpot_OrderID = 0,
	NavMeshEncounterSpot_ParametricDistance,
	NavMeshEncounterSpot_MaxStats
};

enum
{
	NavMeshLadderConnection_LadderIndex = 0,
	NavMeshLadderConnection_Direction,
	NavMeshLadderConnection_MaxStats
};

enum
{
	NavMeshVisibleArea_Index = 0,
	NavMeshVisibleArea_Attributes,
	NavMeshVisibleArea_MaxStats
};

enum
{
	NavMeshLadder_ID = 0,
	NavMeshLadder_Width,
	NavMeshLadder_Length,
	NavMeshLadder_TopX,
	NavMeshLadder_TopY,
	NavMeshLadder_TopZ,
	NavMeshLadder_BottomX,
	NavMeshLadder_BottomY,
	NavMeshLadder_BottomZ,
	NavMeshLadder_Direction,
	NavMeshLadder_TopForwardAreaIndex,
	NavMeshLadder_TopLeftAreaIndex,
	NavMeshLadder_TopRightAreaIndex,
	NavMeshLadder_TopBehindAreaIndex,
	NavMeshLadder_BottomAreaIndex,
	NavMeshLadder_MaxStats
};

enum
{
	NavMeshGrid_ListStartIndex = 0,
	NavMeshGrid_ListEndIndex,
	NavMeshGrid_MaxStats
};

enum
{
	NavMeshGridList_AreaIndex = 0,
	NavMeshGridList_Owner,
	NavMeshGridList_MaxStats
};


native NavMesh_Exists();

native NavMesh_GetMagicNumber();

native NavMesh_GetVersion();

native NavMesh_GetSubVersion();

native NavMesh_GetSaveBSPSize();

native bool:NavMesh_IsAnalyzed();

native Handle:NavMesh_GetPlaces();

native Handle:NavMesh_GetAreas();

native Handle:NavMesh_GetLadders();

//Added by Jared Ballou
native Handle:NavMesh_GetHidingSpots();
native Handle:NavMesh_GetConnections();
native Handle:NavMesh_GetEncounterPaths();
native Handle:NavMesh_GetEncounterSpots();
native Handle:NavMesh_GetLadderConnections();
native Handle:NavMesh_GetVisibleAreas();
//End additions

native NavMesh_CollectSurroundingAreas(Handle:hStack, iStartAreaIndex, Float:flTravelDistanceLimit=1500.0, Float:flMaxStepUpLimit=StepHeight, Float:flMaxDropDownLimit=100.0);

native bool:NavMesh_BuildPath(iStartAreaIndex, iGoalAreaIndex, const Float:flGoalPos[3], Function:iCostFunctor, any:iCostData=INVALID_HANDLE, &iClosestAreaIndex=-1, Float:flMaxPathLength=0.0);


native NavMesh_GetArea(const Float:flPos[3], Float:flBeneathLimit=120.0);

native NavMesh_GetNearestArea(const Float:flPos[3], bool:bAnyZ=false, Float:flMaxDist=10000.0, bool:bCheckLOS=false, bool:bCheckGround=true, iTeam=-2);


native NavMesh_WorldToGridX(Float:flWX);

native NavMesh_WorldToGridY(Float:flWY);

native NavMesh_GetAreasOnGrid(Handle:hStack, x, y);

native NavMesh_GetGridSizeX();

native NavMesh_GetGridSizeY();


native bool:NavMesh_GetGroundHeight(const Float:flPos[3], &Float:flHeight=-1.0, Float:flNormal[3]=NULL_VECTOR);


native NavMeshArea_GetFlags(iAreaIndex);

native bool:NavMeshArea_GetCenter(iAreaIndex, Float:flBuffer[3]);

native NavMeshArea_GetAdjacentList(Handle:hStack, iAreaIndex, iDirection);

native NavMeshArea_GetLadderList(Handle:hStack, iAreaIndex, iLadderDirection);

native NavMeshArea_GetClosestPointOnArea(iAreaIndex, const Float:flPos[3], Float:flClose[3]);

native NavMeshArea_GetTotalCost(iAreaIndex);

native NavMeshArea_GetCostSoFar(iAreaIndex);

native NavMeshArea_GetParent(iAreaIndex);

native NavMeshArea_GetParentHow(iAreaIndex);

native NavMeshArea_SetParent(iAreaIndex, iParentAreaID);

native NavMeshArea_SetParentHow(iAreaIndex, iParentHow);

native bool:NavMeshArea_GetExtentLow(iAreaIndex, Float:flBuffer[3]);

native bool:NavMeshArea_GetExtentHigh(iAreaIndex, Float:flBuffer[3]);

native bool:NavMeshArea_IsOverlappingPoint(iAreaIndex, const Float:flPos[3], Float:flTolerance);

native bool:NavMeshArea_IsOverlappingArea(iAreaIndex, iTargetAreaID);

native Float:NavMeshArea_GetNECornerZ(iAreaIndex);

native Float:NavMeshArea_GetSWCornerZ(iAreaIndex);

native Float:NavMeshArea_GetZ(iAreaIndex, const Float:flPos[3]);

native Float:NavMeshArea_GetZFromXAndY(iAreaIndex, Float:flX, Float:flY);

native bool:NavMeshArea_Contains(iAreaIndex, const Float:flPos[3]);

native bool:NavMeshArea_ComputePortal(iAreaIndex, iAreaToIndex, iNavDirection, Float:flCenter[3], &Float:flHalfWidth);

native bool:NavMeshArea_ComputeClosestPointInPortal(iAreaIndex, iAreaToIndex, iNavDirection, const Float:flFromPos[3], Float:flClosestPos[3]);

native NavMeshArea_ComputeDirection(iAreaIndex, const Float:flPos[3]);

native Float:NavMeshArea_GetLightIntensity(iAreaIndex, const Float:flPos[3]);

native Float:NavMeshLadder_GetLength(iLadderID);


// Shortest-path cost function for NavMesh_BuildPath.
stock NavMeshShortestPathCost(iAreaIndex, iFromAreaIndex, iLadderIndex, any:data)
{
	if (iFromAreaIndex == -1)
	{
		return 0;
	}
	else
	{
		new iDist;
		
		if (iLadderIndex != -1)
		{
			iDist = RoundFloat(NavMeshLadder_GetLength(iLadderIndex));
		}
		else
		{
			decl Float:flAreaCenter[3], Float:flFromAreaCenter[3];
			NavMeshArea_GetCenter(iAreaIndex, flAreaCenter);
			NavMeshArea_GetCenter(iFromAreaIndex, flFromAreaCenter);
			
			iDist = RoundFloat(GetVectorDistance(flAreaCenter, flFromAreaCenter));
		}
		
		new iCost = iDist + NavMeshArea_GetCostSoFar(iFromAreaIndex);
		
		new iAreaFlags = NavMeshArea_GetFlags(iAreaIndex);
		if (iAreaFlags & NAV_MESH_CROUCH) iCost += 20;
		if (iAreaFlags & NAV_MESH_JUMP) iCost += (5 * iDist);
		
		return iCost;
	}
}

#define WALK_THRU_PROP_DOORS		0x01
#define WALK_THRU_FUNC_DOORS		0x02
#define WALK_THRU_DOORS				(WALK_THRU_PROP_DOORS | WALK_THRU_FUNC_DOORS)
#define WALK_THRU_BREAKABLES		0x04
#define WALK_THRU_TOGGLE_BRUSHES	0x08
#define WALK_THRU_EVERYTHING		(WALK_THRU_DOORS | WALK_THRU_BREAKABLES | WALK_THRU_TOGGLE_BRUSHES)


stock bool:IsEntityWalkable(iEnt, iFlags)
{
	decl String:sClass[64];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if (!strcmp(sClass, "worldspawn")) return false;
	
	if (!strcmp(sClass, "player")) return false;
	
	if (!strcmp(sClass, "func_door*"))
	{
		return (iFlags & WALK_THRU_PROP_DOORS) ? true : false;
	}
	
	if (!strcmp(sClass, "prop_door*"))
	{
		return (iFlags & WALK_THRU_PROP_DOORS) ? true : false;
	}
	
	if (!strcmp(sClass, "func_brush"))
	{
		new iSolidity = GetEntProp(iEnt, Prop_Data, "m_iSolidity");
		
		switch (iSolidity)
		{
			case 2: // BRUSHSOLID_ALWAYS
			{
				return false;
			}
			case 1: // BRUSHSOLID_NEVER
			{
				return true;
			}
			case 0: // BRUSHSOLID_TOGGLE
			{
				return (iFlags & WALK_THRU_TOGGLE_BRUSHES) ? true : false;
			}
		}
		
		return (iFlags & WALK_THRU_PROP_DOORS) ? true : false;
	}
	
	if (!strcmp(sClass, "func_breakable") && GetEntProp(iEnt, Prop_Data, "m_iHealth") && GetEntProp(iEnt, Prop_Data, "m_takedamage") == 2) // DAMAGE_YES
	{
		return (iFlags & WALK_THRU_BREAKABLES) ? true : false;
	}
	
	if (!strcmp(sClass, "func_playerinfected_clip"))
	{
		return true;
	}
	
	return false;
}

stock bool:IsWalkableTraceLineClear(const Float:flFrom[3], const Float:flTo[3], iFlags)
{
	decl Float:flUseFrom[3];
	flUseFrom[0] = flFrom[0];
	flUseFrom[1] = flFrom[1];
	flUseFrom[2] = flFrom[2];
	
	decl Handle:hTrace;
	
	new Float:flFraction = 0.0;
	
	for (new t = 0; t < 50; t++)
	{
		hTrace = TR_TraceRayFilterEx(flUseFrom, flTo, MASK_NPCSOLID, RayType_EndPoint, TraceFilterWalkableEntities, iFlags);
		flFraction = TR_GetFraction(hTrace);
		new iResEnt = TR_GetEntityIndex(hTrace);
		decl Float:flResPos[3];
		TR_GetEndPosition(flResPos, hTrace);
		CloseHandle(hTrace);
		
		if (flFraction != 1.0 && IsEntityWalkable(iResEnt, iFlags))
		{
			decl Float:flDir[3];
			SubtractVectors(flTo, flFrom, flDir);
			NormalizeVector(flDir, flDir);
			ScaleVector(flDir, 5.0);
			AddVectors(flResPos, flDir, flUseFrom);
		}
		else
		{
			break;
		}
	}
	
	if (flFraction == 1.0) return true;
	
	return false;
}

public bool:TraceFilterWalkableEntities(entity, mask, any:iFlags)
{
	return !IsEntityWalkable(entity, iFlags);
}


public SharedPlugin:__pl_navmesh = 
{
	name = "navmesh",
	file = "navmesh.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
