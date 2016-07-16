#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

#define VERSION 		"0.0.2"

new Handle:g_hNetPropKV = INVALID_HANDLE;
new String:g_sNetPropFile[PLATFORM_MAX_PATH];

new Handle:g_hSavedNetProps[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hIgnoreNetProps[MAXPLAYERS+1] = INVALID_HANDLE;

new g_iMarkedEntity[MAXPLAYERS+1];
new bool:g_bStopWatching[MAXPLAYERS+1];


public Plugin:myinfo =
{
	name 		= "tEntDev",
	author 		= "Thrawn",
	description = "Allows to do stuff with the netprops of an entity",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tentdev_version", VERSION, "",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	GetNetpropFilename();

	decl String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "configs/tEntDev/%s", g_sNetPropFile);


	if(FileExists(path)) {
		LogMessage("Loading netprops from file: %s", path);

		g_hNetPropKV = CreateKeyValues("NetProps");
		FileToKeyValues(g_hNetPropKV, path);
	} else {
		SetFailState("Cant find netprops data at %s", path);
	}
}

public OnPlayerDisconnect(client) {
	g_bStopWatching[client] = true;
	if(g_hSavedNetProps[client] != INVALID_HANDLE) {
		CloseHandle(g_hSavedNetProps[client]);
		g_hSavedNetProps[client] = INVALID_HANDLE;
	}

	if(g_hIgnoreNetProps[client] != INVALID_HANDLE) {
		CloseHandle(g_hIgnoreNetProps[client]);
		g_hIgnoreNetProps[client] = INVALID_HANDLE;
	}
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
#else
	public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) {
#endif
	RegPluginLibrary("ted");

	CreateNative("TED_IgnoreNetprop", Native_IgnoreNetprop);
	CreateNative("TED_UnignoreNetprop", Native_UnignoreNetprop);
	CreateNative("TED_SelectEntity", Native_SelectEntity);
	CreateNative("TED_ShowNetprops", Native_ShowNetprops);
	CreateNative("TED_WatchNetprops", Native_WatchNetprops);
	CreateNative("TED_StopWatchNetprops", Native_StopWatchNetprops);
	CreateNative("TED_SaveNetprops", Native_SaveNetprops);
	CreateNative("TED_CompareNetprops", Native_CompareNetprops);
	CreateNative("TED_SetNetprop", Native_SetNetprop);

	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
		return true;
	#endif
}

public Native_SetNetprop(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new String:sNetProp[127];
	GetNativeString(2, sNetProp, sizeof(sNetProp));

	new String:sValue[127];
	GetNativeString(3, sValue, sizeof(sValue));

	new iEnt = g_iMarkedEntity[client];

	if(iEnt == -1) {
		CPrintToChat(client, "{red}No entity marked");
		return;
	}

	if(!IsValidEdict(iEnt)) {
		CPrintToChat(client, "{red}Entity does not exists anymore");
		g_iMarkedEntity[client] = -1;
		if(g_hSavedNetProps[client] != INVALID_HANDLE) {
			CloseHandle(g_hSavedNetProps[client]);
			g_hSavedNetProps[client] = INVALID_HANDLE;
		}
		return;
	}

	decl String:sNetclass[64];
	if(GetEntityNetClass(iEnt, sNetclass, sizeof(sNetclass))) {
		KvRewind(g_hNetPropKV);
		if(!KvJumpToKey(g_hNetPropKV, sNetclass, false)) {
			if(!KvJumpToKey(g_hNetPropKV, sNetProp, false)) {
				new iBits = KvGetNum(g_hNetPropKV, "bits", 0);
				new iOffset = KvGetNum(g_hNetPropKV, "offset", 0);

				if(iOffset == 0)return;

				new iByte = 1;
				if(iBits > 8)iByte = 2;
				if(iBits > 16)iByte = 4;

				new String:sType[16];
				KvGetString(g_hNetPropKV, "type", sType, sizeof(sType), "integer");

				if(StrEqual(sType, "integer")) {
					new iValue = StringToInt(sValue);
					CPrintToChat(client, "Setting %s->%s to %i (%s)", sNetclass, sNetProp, iValue, sType);
					SetEntData(iEnt, iOffset, iValue, iByte, true);
				}

				if(StrEqual(sType, "vector")) {
					CPrintToChat(client, "Setting of type vector is not implemented yet");
				}

				if(StrEqual(sType, "float")) {
					new Float:fValue = StringToFloat(sValue);
					CPrintToChat(client, "Setting %s->%s to %.2f (%s)", sNetclass, sNetProp, fValue, sType);
					SetEntData(iEnt, iOffset, fValue, true);
				}
			} else {
				CPrintToChat(client, "Entity of type {red}%s{default} has no netprop {red}%s{default}", sNetclass, sNetProp);
			}
		}
	}
}

public Native_UnignoreNetprop(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new String:sNetProp[127];
	GetNativeString(2, sNetProp, sizeof(sNetProp));

	if(g_hIgnoreNetProps[client] == INVALID_HANDLE) {
		g_hIgnoreNetProps[client] = CreateTrie();
	}

	SetTrieValue(g_hIgnoreNetProps[client], sNetProp, 0, true);
	CPrintToChat(client, "Un-Ignoring netprop: {olive}%s", sNetProp);
}

public Native_IgnoreNetprop(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new String:sNetProp[127];
	GetNativeString(2, sNetProp, sizeof(sNetProp));

	if(g_hIgnoreNetProps[client] == INVALID_HANDLE) {
		g_hIgnoreNetProps[client] = CreateTrie();
	}

	SetTrieValue(g_hIgnoreNetProps[client], sNetProp, 1, true);
	CPrintToChat(client, "Ignoring netprop: {olive}%s", sNetProp);
}

public Native_SelectEntity(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new iEnt = GetNativeCell(2);

	g_bStopWatching[client] = true;

	if(iEnt > 0) {
		decl String:sNetclass[64];
		if(GetEntityNetClass(iEnt, sNetclass, sizeof(sNetclass))) {
			CPrintToChat(client, "You've marked: {olive}%s{default}(%i)", sNetclass, iEnt);
			g_iMarkedEntity[client] = iEnt;

			if(g_hSavedNetProps[client] != INVALID_HANDLE) {
				CloseHandle(g_hSavedNetProps[client]);
				g_hSavedNetProps[client] = INVALID_HANDLE;
			}

			return true;
		}
	}

	return false;
}

public Native_ShowNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new iEnt = g_iMarkedEntity[client];

	if(iEnt == -1) {
		CPrintToChat(client, "{red}No entity marked");
		return;
	}

	if(!IsValidEdict(iEnt)) {
		CPrintToChat(client, "{red}Entity does not exists anymore");
		g_iMarkedEntity[client] = -1;
		if(g_hSavedNetProps[client] != INVALID_HANDLE) {
			CloseHandle(g_hSavedNetProps[client]);
			g_hSavedNetProps[client] = INVALID_HANDLE;
		}
		return;
	}

	decl String:sNetclass[64];
	if(GetEntityNetClass(iEnt, sNetclass, sizeof(sNetclass))) {
		KvRewind(g_hNetPropKV);
		if(!KvJumpToKey(g_hNetPropKV, sNetclass, false)) {
			if(!KvGotoFirstSubKey(g_hNetPropKV, true)) {
				do {
					new String:sSection[64];
					KvGetSectionName(g_hNetPropKV, sSection, sizeof(sSection));
					new iBits = KvGetNum(g_hNetPropKV, "bits", 0);
					new iOffset = KvGetNum(g_hNetPropKV, "offset", 0);

					if(iOffset == 0)continue;

					new iByte = 1;
					if(iBits > 8)iByte = 2;
					if(iBits > 16)iByte = 4;

					new String:sType[16];
					KvGetString(g_hNetPropKV, "type", sType, sizeof(sType), "integer");

					if(iBits == 0 && StrEqual(sType, "integer"))continue;

					new String:sResult[64];
					if(StrEqual(sType, "integer")) {
						Format(sResult, sizeof(sResult), "%i", GetEntData(iEnt, iOffset, iByte));
					}

					if(StrEqual(sType, "vector")) {
						new Float:vData[3];
						GetEntDataVector(iEnt, iOffset, vData);
						Format(sResult, sizeof(sResult), "%.4f %.4f %.4f", vData[0], vData[1], vData[2]);
					}

					if(StrEqual(sType, "float")) {
						Format(sResult, sizeof(sResult), "%.4f", GetEntDataFloat(iEnt, iOffset));
					}

					CPrintToChat(client, "{olive}%s{default}: %s", sSection, sResult);
				} while (KvGotoNextKey(g_hNetPropKV, true));
			} else {
				CPrintToChat(client, "Netclass %s has no netprops", sNetclass);
			}
		} else {
			CPrintToChat(client, "Could not find netprops definitions for {olive}%s", sNetclass);
		}
	}

	return;
}

public Native_WatchNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);

	new iEnt = g_iMarkedEntity[client];
	if(iEnt == -1) {
		CPrintToChat(client, "{red}No entity marked");
		return false;
	}

	EmptySavedNetprops(client);
	SaveNetprops(client, g_iMarkedEntity[client]);

	g_bStopWatching[client] = false;
	CreateTimer(1.0, Timer_WatchEntity, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return true;
}

public Native_StopWatchNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	g_bStopWatching[client] = true;
}

public Native_SaveNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new iEnt = g_iMarkedEntity[client];

	if(iEnt == -1) {
		CPrintToChat(client, "{red}No entity marked");
		return false;
	}

	EmptySavedNetprops(client);

	new iCount = SaveNetprops(client, iEnt);
	if(iCount == -1)return false;

	CPrintToChat(client, "Saved {olive}%i{default} netprops", iCount);
	return true;
}

public Native_CompareNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);

	g_bStopWatching[client] = true;
	if(g_hSavedNetProps[client] == INVALID_HANDLE) {
		CPrintToChat(client, "{red}No netprops saved");
		return false;
	}

	new iEnt = g_iMarkedEntity[client];
	if(iEnt == -1) {
		CPrintToChat(client, "{red}No entity marked");
		return false;
	}

	new iCount = CompareNetprops(client, iEnt);
	if(iCount == -1)return false;

	CPrintToChat(client, "Netprops changed: {olive}%i", iCount);
	return true;
}

EmptySavedNetprops(client) {
	if(g_hSavedNetProps[client] == INVALID_HANDLE) {
		g_hSavedNetProps[client] = CreateTrie();
	} else {
		ClearTrie(g_hSavedNetProps[client]);
	}
}


public Action:Timer_WatchEntity(Handle:timer, any:client) {
	if(g_bStopWatching[client])return Plugin_Stop;
	if(!IsClientInGame(client) || !IsClientConnected(client))return Plugin_Stop;

	new iCount = CompareNetprops(client, g_iMarkedEntity[client]);
	if(iCount == -1)return Plugin_Stop;

	SaveNetprops(client, g_iMarkedEntity[client]);
	return Plugin_Continue;
}


SaveNetprops(client, iEnt) {
	if(!IsValidEdict(iEnt)) {
		CPrintToChat(client, "{red}Entity does not exists anymore");
		g_iMarkedEntity[client] = -1;
		CloseHandle(g_hSavedNetProps[client]);
		g_hSavedNetProps[client] = INVALID_HANDLE;
		return -1;
	}

	decl String:sNetclass[64];
	new iCount = 0;
	if(GetEntityNetClass(iEnt, sNetclass, sizeof(sNetclass))) {
		KvRewind(g_hNetPropKV);
		if(!KvJumpToKey(g_hNetPropKV, sNetclass, false)) {
			if(KvGotoFirstSubKey(g_hNetPropKV, true)) {
				do {
					new String:sSection[64];
					KvGetSectionName(g_hNetPropKV, sSection, sizeof(sSection));
					new iBits = KvGetNum(g_hNetPropKV, "bits", 0);
					new iOffset = KvGetNum(g_hNetPropKV, "offset", 0);

					if(iOffset == 0)continue;

					new iByte = 1;
					if(iBits > 8)iByte = 2;
					if(iBits > 16)iByte = 4;

					new String:sType[16];
					KvGetString(g_hNetPropKV, "type", sType, sizeof(sType), "integer");

					if(iBits == 0 && StrEqual(sType, "integer"))continue;

					new String:sResult[64];
					if(StrEqual(sType, "integer")) {
						Format(sResult, sizeof(sResult), "%i", GetEntData(iEnt, iOffset, iByte));
					}

					if(StrEqual(sType, "vector")) {
						new Float:vData[3];
						GetEntDataVector(iEnt, iOffset, vData);
						Format(sResult, sizeof(sResult), "%.4f %.4f %.4f", vData[0], vData[1], vData[2]);
					}

					if(StrEqual(sType, "float")) {
						Format(sResult, sizeof(sResult), "%.4f", GetEntDataFloat(iEnt, iOffset));
					}

					SetTrieString(g_hSavedNetProps[client], sSection, sResult, true);
					iCount++;
				} while (KvGotoNextKey(g_hNetPropKV, true));
			} else {
				CPrintToChat(client, "Netclass %s has no netprops", sNetclass);
				return -1;
			}
		} else {
			CPrintToChat(client, "Could not find netprops definitions for {olive}%s", sNetclass);
			return -1;

		}
	}

	return iCount;
}

CompareNetprops(client, iEnt) {
	if(!IsValidEdict(iEnt)) {
		CPrintToChat(client, "{red}Entity does not exists anymore");
		g_iMarkedEntity[client] = -1;
		if(g_hSavedNetProps[client] != INVALID_HANDLE) {
			CloseHandle(g_hSavedNetProps[client]);
			g_hSavedNetProps[client] = INVALID_HANDLE;
		}
		return -1;
	}

	decl String:sNetclass[64];
	new iCount = 0;
	if(GetEntityNetClass(iEnt, sNetclass, sizeof(sNetclass))) {
		KvRewind(g_hNetPropKV);
		if(!KvJumpToKey(g_hNetPropKV, sNetclass, false)) {
			if(KvGotoFirstSubKey(g_hNetPropKV, true)) {
				do {
					new String:sSection[64];
					KvGetSectionName(g_hNetPropKV, sSection, sizeof(sSection));
					new iBits = KvGetNum(g_hNetPropKV, "bits", 0);
					new iOffset = KvGetNum(g_hNetPropKV, "offset", 0);
					if(iOffset == 0)continue;

					new bool:bIgnore = false;
					if(g_hIgnoreNetProps[client] != INVALID_HANDLE) {
						GetTrieValue(g_hIgnoreNetProps[client], sSection, bIgnore);
					}
					if(bIgnore)continue;
					new iByte = 1;
					if(iBits > 8)iByte = 2;
					if(iBits > 16)iByte = 4;

					new String:sType[16];
					KvGetString(g_hNetPropKV, "type", sType, sizeof(sType), "integer");

					if(iBits == 0 && StrEqual(sType, "integer"))continue;

					new String:sResult[64];
					if(StrEqual(sType, "integer")) {
						Format(sResult, sizeof(sResult), "%i", GetEntData(iEnt, iOffset, iByte));
					}

					if(StrEqual(sType, "vector")) {
						new Float:vData[3];
						GetEntDataVector(iEnt, iOffset, vData);
						Format(sResult, sizeof(sResult), "%.4f %.4f %.4f", vData[0], vData[1], vData[2]);
					}

					if(StrEqual(sType, "float")) {
						Format(sResult, sizeof(sResult), "%.4f", GetEntDataFloat(iEnt, iOffset));
					}

					new String:sPrevious[64];
					GetTrieString(g_hSavedNetProps[client], sSection, sPrevious, sizeof(sPrevious));

					if(!StrEqual(sResult, sPrevious)) {
						iCount++;
						CPrintToChat(client, "{olive}%s{default} changed from {red}%s{default} to {red}%s", sSection, sPrevious, sResult);
					}
				} while (KvGotoNextKey(g_hNetPropKV, true));
			} else {
				CPrintToChat(client, "Netclass %s has no netprops", sNetclass);
				return -1;
			}
		} else {
			CPrintToChat(client, "Could not find netprops definitions for {olive}%s", sNetclass);
			return -1;

		}
	}

	return iCount;
}

GetNetpropFilename() {
	// Adapted from HLX:CE ingame plugin :3
	if (StrEqual(g_sNetPropFile, "")) {
		new String: szGameDesc[64];
		GetGameDescription(szGameDesc, 64, true);

		if (GuessSDKVersion() == SOURCE_SDK_DARKMESSIAH)							g_sNetPropFile = "netprops.dm.cfg";
		else if (StrContains(szGameDesc, "Counter-Strike", false) != -1)			g_sNetPropFile = "netprops.css.cfg";
		else if (StrContains(szGameDesc, "Day of Defeat", false) != -1)				g_sNetPropFile = "netprops.dods.cfg";
		else if (StrContains(szGameDesc, "Half-Life 2 Deathmatch", false) != -1)	g_sNetPropFile = "netprops.hl2mp.cfg";
		else if (StrContains(szGameDesc, "Team Fortress", false) != -1)				g_sNetPropFile = "netprops.tf2.cfg";
		else if (StrContains(szGameDesc, "L4D", false) != -1 ||
				 StrContains(szGameDesc, "Left 4 D", false) != -1)					g_sNetPropFile = (GuessSDKVersion() >= SOURCE_SDK_LEFT4DEAD) ? "netprops.l4d.cfg" : "netprops.l4d2.cfg";
		else if (StrContains(szGameDesc, "Insurgency", false) != -1)				g_sNetPropFile = "netprops.insurgency.cfg";
		else if (StrContains(szGameDesc, "Fortress Forever", false) != -1)			g_sNetPropFile = "netprops.ff.cfg";
		else if (StrContains(szGameDesc, "ZPS", false) != -1)						g_sNetPropFile = "netprops.zps.cfg";
		else if (StrContains(szGameDesc, "Age of Chivalry", false) != -1)			g_sNetPropFile = "netprops.aoc.cfg";

		// game could not detected, try further
		if (StrEqual(g_sNetPropFile, "")) {
			new String: szGameDir[64];
			GetGameFolderName(szGameDir, 64);

			if (StrContains(szGameDir, "cstrike", false) != -1)						g_sNetPropFile = "netprops.css.cfg";
			else if (StrContains(szGameDir, "dod", false) != -1)					g_sNetPropFile = "netprops.dods.cfg";
			else if (StrContains(szGameDir, "hl2mp", false) != -1 ||
					 StrContains(szGameDir, "hl2ctf", false) != -1)					g_sNetPropFile = "netprops.hl2mp.cfg";
			else if (StrContains(szGameDir, "fistful_of_frags", false) != -1)		g_sNetPropFile = "netprops.fof.cfg";
			else if (StrContains(szGameDir, "tf", false) != -1)						g_sNetPropFile = "netprops.tf2.cfg";
			else if (StrContains(szGameDir, "left4dead", false) != -1)				g_sNetPropFile = (GuessSDKVersion() == SOURCE_SDK_LEFT4DEAD) ? "netprops.l4d.cfg" : "netprops.l4d2.cfg";
			else if (StrContains(szGameDir, "insurgency", false) != -1)				g_sNetPropFile = "netprops.insmod.cfg";
			else if (StrContains(szGameDir, "FortressForever", false) != -1)		g_sNetPropFile = "netprops.ff.cfg";
			else if (StrContains(szGameDir, "zps", false) != -1)					g_sNetPropFile = "netprops.zps.cfg";
			else if (StrContains(szGameDir, "ageofchivalry", false) != -1)			g_sNetPropFile = "netprops.aoc.cfg";
			else if (StrContains(szGameDir, "gesource", false) != -1)				g_sNetPropFile = "netprops.ges.cfg";
		}
	}
}
