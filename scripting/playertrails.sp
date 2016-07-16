/* Player Trails
   author: databomb
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#tryinclude <ToggleEffects>
#tryinclude <hub>
#tryinclude <SpecialDays>
#define REQUIRE_PLUGIN

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.7"

#define MAX_DISPLAYNAME_SIZE 30
#define MAX_COLORDATA_SIZE 18

/*********************************************************************************************/
// Efficient Cvar Handling from Zephyrus

#define CVAR_LENGTH 128
#define MAX_CVARS 32

enum CVAR_TYPE
{
		TYPE_INT = 0,
		TYPE_FLOAT,
		TYPE_STRING,
		TYPE_FLAG
}
 
enum CVAR_CACHE
{
		Handle:hCvar,
		CVAR_TYPE:eType,
		any:aCache,
		String:sCache[CVAR_LENGTH]
}new g_eCvars[MAX_CVARS][CVAR_CACHE];
 
new g_iCvars = 0;
 
public RegisterConVar(String:name[], String:value[], String:description[], CVAR_TYPE:type)
{
		new Handle:cvar = CreateConVar(name, value, description);
		HookConVarChange(cvar, GlobalConVarChanged);
		g_eCvars[g_iCvars][hCvar] = cvar;
		g_eCvars[g_iCvars][eType] = type;
		if(g_eCvars[g_iCvars][eType]==TYPE_INT)
				g_eCvars[g_iCvars][aCache] = GetConVarInt(cvar);
		else if(g_eCvars[g_iCvars][eType]==TYPE_FLOAT)
				g_eCvars[g_iCvars][aCache] = GetConVarFloat(cvar);
		else if(g_eCvars[g_iCvars][eType]==TYPE_STRING)
				GetConVarString(cvar, g_eCvars[g_iCvars][sCache], CVAR_LENGTH);
		else if(g_eCvars[g_iCvars][eType]==TYPE_FLAG)
		{
				GetConVarString(cvar, g_eCvars[g_iCvars][sCache], CVAR_LENGTH);
				g_eCvars[g_iCvars][aCache] = ReadFlagString(g_eCvars[g_iCvars][sCache]);
		}
		g_iCvars++;
		return g_iCvars-1;
}
 
public GlobalConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
		new i;
		for(i=0;i<g_iCvars;++i)
				if(g_eCvars[i][hCvar]==convar)
						break;
		if(g_eCvars[i][eType]==TYPE_INT)
		{
				g_eCvars[i][aCache] = StringToInt(newValue);
		} else if(g_eCvars[i][eType]==TYPE_FLOAT)
		{
				g_eCvars[i][aCache] = StringToFloat(newValue);
		} else if(g_eCvars[i][eType]==TYPE_STRING)
		{
				strcopy(g_eCvars[i][sCache], CVAR_LENGTH, newValue);
		} else if(g_eCvars[i][eType]==TYPE_FLAG)
		{
				strcopy(g_eCvars[i][sCache], CVAR_LENGTH, newValue);
				g_eCvars[i][aCache] = ReadFlagString(newValue);
		}
}

/*********************************************************************************************/

enum MenuTrailChoice
{
	MTC_None = 0,
	MTC_Type,
	MTC_Color,
	MTC_Visibility
};

new bool:g_bToggleEffectsLibAvail = false;
new bool:g_bSpecDaysLibAvail = false;
new bool:g_bIsDonator[MAXPLAYERS+1];
new Handle:gH_DArray_CustomTypeNames = INVALID_HANDLE;
new Handle:gH_DArray_CustomPathNames = INVALID_HANDLE;
new g_CurrentTrail[MAXPLAYERS+1];
new g_iTrailNone;
new String:g_sCurrentColor[MAXPLAYERS+1][MAX_COLORDATA_SIZE];
new bool:g_bTeamOnlyTrails[MAXPLAYERS+1];
new String:g_CookieCache[MAXPLAYERS+1][7][5];
new g_iClientSpriteEntIndex[MAXPLAYERS+1];
new Handle:gH_Trie_Paths = INVALID_HANDLE;

new Handle:gH_Cookie_PlayerSettings = INVALID_HANDLE;
new Handle:gH_Cookie_PlayerTrail = INVALID_HANDLE;

new Handle:gH_Cvar_TrailsEnabled = INVALID_HANDLE;
new Handle:gH_Cvar_DonatorsOnly = INVALID_HANDLE;
new Handle:gH_Cvar_DonatorFlags = INVALID_HANDLE;

new Handle:gH_Cvar_Lifetime = INVALID_HANDLE;
new Handle:gH_Cvar_StartWidth = INVALID_HANDLE;
new Handle:gH_Cvar_EndWidth = INVALID_HANDLE;
new Handle:gH_Cvar_RenderMode = INVALID_HANDLE;
new g_Cvar_ChatPrefix;

public Plugin:myinfo = 
{
	name = "Player Trails",
	author = "databomb",
	description = "Adds a trail to players.",
	version = PLUGIN_VERSION,
	url = "vintagejailbreak.org"
};

public OnMapStart()
{
	ClearArray(gH_DArray_CustomTypeNames);
	ClearArray(gH_DArray_CustomPathNames);
	ClearTrie(gH_Trie_Paths);
	
	PushArrayString(gH_DArray_CustomTypeNames, "None");
	g_iTrailNone = PushArrayString(gH_DArray_CustomPathNames, "n/a");
		
	// read through materials/sprites/trails/ directory and add custom models
	
	if (DirExists("materials/sprites/trails"))
	{
		new Handle:dir = INVALID_HANDLE;
		dir = OpenDirectory("materials/sprites/trails");
		new String:buffer[PLATFORM_MAX_PATH];
		new String:pathName[PLATFORM_MAX_PATH];
		new FileType:type;
		
		while (ReadDirEntry(dir, buffer, PLATFORM_MAX_PATH, type))
		{
			new length = strlen(buffer);
			if (buffer[length-1] == '\n')
			{
				buffer[--length] = '\0';
			}
			TrimString(buffer);
			
			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
			{
				if (type == FileType_File)
				{
					// check Extension to make sure it's a material
					if (StrContains(buffer, ".vmt", false) != -1)
					{
						Format(pathName, PLATFORM_MAX_PATH, "materials/sprites/trails/%s", buffer);
						PrecacheModel(pathName);
						SetTrieValue(gH_Trie_Paths, pathName, PushArrayString(gH_DArray_CustomPathNames, pathName));
						
						// cut off the VMT
						decl String:trailName[100];
						SplitString(buffer, ".vmt", trailName, sizeof(trailName)); 
						PushArrayString(gH_DArray_CustomTypeNames, trailName);
						
						Format(buffer, sizeof(buffer), "materials/sprites/trails/%s.vmt", trailName);
						AddFileToDownloadsTable(buffer);
						Format(buffer, sizeof(buffer), "materials/sprites/trails/%s.vtf", trailName);
						AddFileToDownloadsTable(buffer);
					}
				}
			}
		}
	}
}

public OnPluginStart()
{
	CreateConVar("playertrails_version", PLUGIN_VERSION, "Player Trails Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gH_Cvar_TrailsEnabled = CreateConVar("sm_playertrails_enable", "0", "Enables/Disables Player Trails",, true, 0.0, true, 1.0);
	gH_Cvar_DonatorsOnly = CreateConVar("sm_playertrails_donatoronly", "0", "Specifies whether everyone or only donators will receive trails",, true, 0.0, true, 1.0);
	gH_Cvar_DonatorFlags = CreateConVar("sm_playertrails_adminflags", "sz", "Admin flags which will have access to grenade trails. empty=all admins",);
	
	gH_Cvar_Lifetime = CreateConVar("sm_playertrails_lifetime", "1.0", "Seconds a trail will continue before disappearing.",);
	gH_Cvar_StartWidth = CreateConVar("sm_playertrails_startwidth", "22.0", "Meters the trail is wide at the beginning of life.",);
	gH_Cvar_EndWidth = CreateConVar("sm_playertrails_endwidth", "0.0", "Meters the trail is wide at the end of life.",);
	gH_Cvar_RenderMode = CreateConVar("sm_playertrails_rendermode", "5", "The render mode of trails.",);
	g_Cvar_ChatPrefix = RegisterConVar("sm_playertrails_chatprefix", "\x03[xG] \x01", "The prefix before each chat message.", TYPE_STRING);
	
	RegConsoleCmd("sm_trails", Command_Trails);

	if (LibraryExists("clientprefs"))
	{
		gH_Cookie_PlayerSettings = RegClientCookie("PlayerTrails_Settings", "Stores all player trail options.", CookieAccess_Protected);
		gH_Cookie_PlayerTrail = RegClientCookie("PlayerTrails_TrailName", "The name of the trail file used.", CookieAccess_Protected);
		
		SetCookieMenuItem(CookieMenu_PlayerTrails, 0, "Player Trails");
	}
	else
	{
		SetFailState("Unable to load clientprefs library!");
	}
	
	if (LibraryExists("specialfx"))
	{
		g_bToggleEffectsLibAvail = true;
	}
	
	g_bSpecDaysLibAvail = LibraryExists("SpecialDays");

	HookEvent("player_spawn", Hook_PlayerSpawn);
	HookEvent("player_death", Hook_PlayerDeath);
	HookEvent("round_end", Hook_RoundEnd);
	
	gH_DArray_CustomTypeNames = CreateArray(MAX_DISPLAYNAME_SIZE);
	gH_DArray_CustomPathNames = CreateArray(PLATFORM_MAX_PATH);
	gH_Trie_Paths = CreateTrie();
	
	AutoExecConfig(true, "player-trails");
}

public OnLibraryAdded(const String:name[])
{
	if (!strcmp(name, "specialfx"))
	{
		g_bToggleEffectsLibAvail = true;
	}
	else if (!strcmp(name, "SpecialDays"))
	{
		g_bSpecDaysLibAvail = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (!strcmp(name, "specialfx"))
	{
		g_bToggleEffectsLibAvail = false;
	}
	else if (!strcmp(name, "SpecialDays"))
	{
		g_bSpecDaysLibAvail = false;
	}
}

public OnClientPostAdminCheck(client)
{
	if (!GetConVarBool(gH_Cvar_TrailsEnabled))
	{
		g_bIsDonator[client] = false;
	}
	else if (GetConVarBool(gH_Cvar_DonatorsOnly))
	{
		decl String:sAdminFlags[20];
		GetConVarString(gH_Cvar_DonatorFlags, sAdminFlags, sizeof(sAdminFlags));
		
		if (strlen(sAdminFlags) == 0)
		{
			Format(sAdminFlags, sizeof(sAdminFlags), "bz");
		}

		if (GetUserFlagBits(client) & ReadFlagString(sAdminFlags))
		{
			g_bIsDonator[client] = bool:true;
		}
		else
		{
			g_bIsDonator[client] = bool:false;
		}
	}
	else
	{
		g_bIsDonator[client] = bool:true;
	}
}

public Action:Command_Trails(client, args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	Menu_PlayerTrails(client);
	return Plugin_Handled;
}

public CookieMenu_PlayerTrails(client, CookieMenuAction:selection, any:info, String:buffer[], maxlen)
{
	if (selection != CookieMenuAction_DisplayOption)
	{
		// check user
		if (!g_bIsDonator[client])
		{
			PrintToChat(client, "\x04This menu is reserved for donators only!");
		}
		else if (!GetConVarBool(gH_Cvar_TrailsEnabled))
		{
			PrintToChat(client, "\x04Player Trails Disabled.");
		}
		else
		{
			Menu_PlayerTrails(client);

		}
	}
}

void:Menu_PlayerTrails(client)
{
	new Handle:GTMenu = CreateMenu(PlayerTrailsMenu_Main);
	SetMenuTitle(GTMenu, "Player Trails Settings");
	
	#if defined _Hub_Included_
	
	AddMenuItem(GTMenu, "1", "Trail Type");
	
	if (ClientHasFeature(client, "Trail Color"))
	{
		AddMenuItem(GTMenu, "2", "Trail Color");
	}
	else
	{
		AddMenuItem(GTMenu, "2", "Trail Color", ITEMDRAW_DISABLED);
	}
	
	if (ClientHasFeature(client, "Trail Visibility"))
	{
		AddMenuItem(GTMenu, "3", "Trail Visibility");
	}
	else
	{
		AddMenuItem(GTMenu, "3", "Trail Visibility", ITEMDRAW_DISABLED);
	}
	
	#else
	
	AddMenuItem(GTMenu, "1", "Trail Type");
	AddMenuItem(GTMenu, "2", "Trail Color");
	AddMenuItem(GTMenu, "3", "Trail Visibility");
	
	#endif
	
	SetMenuExitBackButton(GTMenu, true);
	DisplayMenu(GTMenu, client, MENU_TIME_FOREVER);
}

public PlayerTrailsMenu_Main(Handle:GTMenu, MenuAction:selection, client, param2)
{
	if (selection == MenuAction_Select)
	{
		new String:sInfo[4];
		GetMenuItem(GTMenu, param2, sInfo, sizeof(sInfo));
		new MenuTrailChoice:choice = MenuTrailChoice:StringToInt(sInfo);
		
		switch (choice)
		{
			case MTC_Type:
			{
				new Handle:MTC_TypeMenu = CreateMenu(PlayerTrailsMenu_Type);
				SetMenuTitle(MTC_TypeMenu, "Choose Trail Type:");
				decl String:sBuffer[64];
				decl String:trailName[100];
				// add all types
				new numTrails = GetArraySize(gH_DArray_CustomTypeNames);
				
				// add none (guaranteed to be there)
				AddMenuItem(MTC_TypeMenu, "n/a", "None");
				
				for (new idx = 1; idx < numTrails; idx++)
				{
					GetArrayString(gH_DArray_CustomPathNames, idx, sBuffer, sizeof(sBuffer));
					GetArrayString(gH_DArray_CustomTypeNames, idx, trailName, sizeof(trailName));
					
					#if defined _Hub_Included_
	
					if (ClientHasFeature(client, trailName))
					{
						AddMenuItem(MTC_TypeMenu, sBuffer, trailName);
					}
					else
					{
						AddMenuItem(MTC_TypeMenu, sBuffer, trailName, ITEMDRAW_DISABLED);
					}
					
					#else
					
					AddMenuItem(MTC_TypeMenu, sBuffer, trailName);
					
					#endif
					
				}
				SetMenuExitBackButton(MTC_TypeMenu, true);
				DisplayMenu(MTC_TypeMenu, client, MENU_TIME_FOREVER);
			}
			case MTC_Color:
			{
				new Handle:MTC_ColorMenu = CreateMenu(PlayerTrailsMenu_Color);
				SetMenuTitle(MTC_ColorMenu, "Choose Trail Color:");
				// add pre-defined types
				AddMenuItem(MTC_ColorMenu, "255 255 255 255", "None");
				AddMenuItem(MTC_ColorMenu, "255 0 0 255", "Red");
				AddMenuItem(MTC_ColorMenu, "255 128 0 255", "Orange");
				AddMenuItem(MTC_ColorMenu, "255 255 0 255", "Yellow");
				AddMenuItem(MTC_ColorMenu, "0 255 0 255", "Green");
				AddMenuItem(MTC_ColorMenu, "0 80 255 255", "Blue");
				AddMenuItem(MTC_ColorMenu, "75 0 130 255", "Indigo");
				AddMenuItem(MTC_ColorMenu, "127 0 255 255", "Violet");
				AddMenuItem(MTC_ColorMenu, "0 255 255 255", "Cyan");		
				SetMenuExitBackButton(MTC_ColorMenu, true);
				DisplayMenu(MTC_ColorMenu, client, MENU_TIME_FOREVER);
			}
			case MTC_Visibility:
			{
				new Handle:MTC_VisibilityMenu = CreateMenu(PlayerTrailsMenu_Visibility);
				SetMenuTitle(MTC_VisibilityMenu, "Set Who Will See the Trails:");
				AddMenuItem(MTC_VisibilityMenu, "0", "All Players");
				AddMenuItem(MTC_VisibilityMenu, "1", "Teammates Only");
				SetMenuExitBackButton(MTC_VisibilityMenu, true);
				DisplayMenu(MTC_VisibilityMenu, client, MENU_TIME_FOREVER);
			}
		}	
	}
	else if (selection == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			#if defined _Hub_Included_
			FakeClientCommand(client, "sm_hub");
			#else
			ShowCookieMenu(client);
			#endif
		}
	}
	else if (selection == MenuAction_End)
	{
		CloseHandle(GTMenu);
	}
}

public PlayerTrailsMenu_Visibility(Handle:MTC_VisibilityMenu, MenuAction:selection, param1, param2)
{
	new client = param1;
	
	if (selection == MenuAction_Select) 
	{
		Trail_Remove(client);
		
		decl String:sInfo[5];
		decl String:sDisplay[20];
		GetMenuItem(MTC_VisibilityMenu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
		
		g_bTeamOnlyTrails[client] = bool:StringToInt(sInfo);
		
		IntToString(g_bTeamOnlyTrails[client], g_CookieCache[client][4], 5);
		decl String:sCookie[99];
		ImplodeStrings(g_CookieCache[client], 7, " ", sCookie, sizeof(sCookie));
		SetClientCookie(client, gH_Cookie_PlayerSettings, sCookie);
		
		PrintToChat(client, "%sChanged Trail Visibility To: %s", g_eCvars[g_Cvar_ChatPrefix][sCache], sDisplay);
		
		Menu_PlayerTrails(param1);
		
		CreateTimer(0.2, Timer_AttachTrail, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (selection == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			Menu_PlayerTrails(client);
		}
	}
	else if (selection == MenuAction_End)
	{
		CloseHandle(MTC_VisibilityMenu);
	} 
}

public PlayerTrailsMenu_Type(Handle:MTC_ColorMenu, MenuAction:selection, param1, param2)
{
	new client = param1;
	
	if (selection == MenuAction_Select) 
	{
		Trail_Remove(client);
		
		decl String:sBuffer[64];
		GetMenuItem(MTC_ColorMenu, param2, sBuffer, sizeof(sBuffer));
		
		new index = g_iTrailNone;
		GetTrieValue(gH_Trie_Paths, sBuffer, index);
		g_CurrentTrail[client] = index;
		
		SetClientCookie(client, gH_Cookie_PlayerTrail, sBuffer);
		
		decl String:trailName[100];
		GetArrayString(gH_DArray_CustomTypeNames, index, trailName, sizeof(trailName));
		PrintToChat(client, "%sTrail Type Changed: %s", g_eCvars[g_Cvar_ChatPrefix][sCache], trailName);
		
		Menu_PlayerTrails(param1);
		
		CreateTimer(0.2, Timer_AttachTrail, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (selection == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			Menu_PlayerTrails(client);
		}
	}
	else if (selection == MenuAction_End)
	{
		CloseHandle(MTC_ColorMenu);
	} 
}

public PlayerTrailsMenu_Color(Handle:MTC_TypeMenu, MenuAction:selection, param1, param2)
{
	new client = param1;
	
	if (selection == MenuAction_Select) 
	{
		Trail_Remove(client);
		
		decl String:sInfo[MAX_COLORDATA_SIZE];
		decl String:sDisplay[20];
		GetMenuItem(MTC_TypeMenu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
		Format(g_sCurrentColor[client], MAX_COLORDATA_SIZE, "%s", sInfo);

		decl String:colors[4][4];
		ExplodeString(g_sCurrentColor[client], " ", colors, sizeof(colors), sizeof(colors[]));
		Format(g_CookieCache[client][0], 5, "%s", colors[0]);
		Format(g_CookieCache[client][1], 5, "%s", colors[1]);
		Format(g_CookieCache[client][2], 5, "%s", colors[2]);
		Format(g_CookieCache[client][3], 5, "%s", colors[3]);
		
		decl String:sCookie[99];
		ImplodeStrings(g_CookieCache[client], 7, " ", sCookie, sizeof(sCookie));
		SetClientCookie(client, gH_Cookie_PlayerSettings, sCookie);
		
		PrintToChat(client, "%sTrail Color Changed: %s", g_eCvars[g_Cvar_ChatPrefix][sCache], sDisplay);
		
		Menu_PlayerTrails(param1);
		
		CreateTimer(0.2, Timer_AttachTrail, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (selection == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			Menu_PlayerTrails(client);
		}
	}
	else if (selection == MenuAction_End)
	{
		CloseHandle(MTC_TypeMenu);
	} 
}

public OnClientCookiesCached(client)
{
	// grab all the settings
	decl String:sTrailSettings[99];
	
	GetClientCookie(client, gH_Cookie_PlayerSettings, sTrailSettings, sizeof(sTrailSettings));
	if (StrEqual(sTrailSettings, ""))
	{
		// set defaults
		Format(g_sCurrentColor[client], MAX_COLORDATA_SIZE, "255 255 255 255");
		g_bTeamOnlyTrails[client] = true;
	}
	else
	{
		// get settings	
		decl String:settings[7][5];
		ExplodeString(sTrailSettings, " ", settings, sizeof(settings), sizeof(settings[]));
		Format(g_sCurrentColor[client], MAX_COLORDATA_SIZE, "%s %s %s %s", settings[0], settings[1], settings[2], settings[3]);
		g_bTeamOnlyTrails[client] = bool:StringToInt(settings[4]);
	}
	
	GetClientCookie(client, gH_Cookie_PlayerTrail, sTrailSettings, sizeof(sTrailSettings));
	if (StrEqual(sTrailSettings, ""))
	{
		// set defaults
		g_CurrentTrail[client] = g_iTrailNone;
	}
	else
	{
		new key = g_iTrailNone;
		GetTrieValue(gH_Trie_Paths, sTrailSettings, key);
		g_CurrentTrail[client] = key;
	}

	UpdateLocalCookieCache(client);
}

void:UpdateLocalCookieCache(client)
{
	decl String:colors[4][4];
	ExplodeString(g_sCurrentColor[client], " ", colors, sizeof(colors), sizeof(colors[]));
	Format(g_CookieCache[client][0], 5, "%s", colors[0]);
	Format(g_CookieCache[client][1], 5, "%s", colors[1]);
	Format(g_CookieCache[client][2], 5, "%s", colors[2]);
	Format(g_CookieCache[client][3], 5, "%s", colors[3]);
	IntToString(g_bTeamOnlyTrails[client], g_CookieCache[client][4], 5);
}

public Hook_RoundEnd(Handle:event, const String:name[], bool:DontBroadcast)
{
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		Trail_Remove(idx);
	}
}

public Hook_PlayerDeath(Handle:event, const String:name[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bIsDonator[client])
	{
		Trail_Remove(client);
	}
}

public Hook_PlayerSpawn(Handle:event, const String:name[], bool:DontBroadcast)
{
	if (!GetConVarInt(gH_Cvar_TrailsEnabled))
	{
		return;	
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsFakeClient(client) && g_bIsDonator[client])
	{
		CreateTimer(0.2, Timer_AttachTrail, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_AttachTrail(Handle:timer, any:client)
{
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) > 1))
	{
		// attach trail to client
		Trail_Attach(client);
	}
	
	return Plugin_Handled;
}

public OnMapEnd()
{
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		new ent = g_iClientSpriteEntIndex[idx];
		if (ent != 0)
		{
			if (IsValidEntity(ent))
			{
				SDKUnhook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
				AcceptEntityInput(ent, "Kill");
			}
		}
	}
}

void:Trail_Remove(client)
{
	new ent = g_iClientSpriteEntIndex[client];
	if (ent != 0)
	{
		if (IsValidEntity(ent))
		{
			SDKUnhook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
			AcceptEntityInput(ent, "Kill");
		}
		g_iClientSpriteEntIndex[client] = 0;
	}
}

public HubFeatureRemoved(client, const String:szFeatureName[])
{
	if (g_CurrentTrail[client] != g_iTrailNone)
	{
		new index = FindStringInArray(gH_DArray_CustomTypeNames, szFeatureName);
		if (index == -1)
		{
			index = g_iTrailNone;
		}
		
		if (index == g_CurrentTrail[client])
		{
			SetClientCookie(client, gH_Cookie_PlayerTrail, "n/a");
			
			decl String:trailName[100];
			GetArrayString(gH_DArray_CustomTypeNames, index, trailName, sizeof(trailName));
			PrintToChat(client, "%sTrail Removed: %s", g_eCvars[g_Cvar_ChatPrefix][sCache], trailName);
			
			Trail_Remove(client);
		}
	}
}

void:Trail_Attach(client)
{
	// check if they're a donator and they have a trail configured
	if (g_bIsDonator[client] && g_CurrentTrail[client] != g_iTrailNone)
	{
		// take string and make array
		decl String:colors[4][4];
		ExplodeString(g_sCurrentColor[client], " ", colors, sizeof(colors), sizeof(colors[]));
		
		decl String:sTempName[64];
		Format(sTempName, sizeof(sTempName), "PlayerTrail_%d", GetClientUserId(client));
		DispatchKeyValue(client, "targetname", sTempName);
		
		new entIndex = CreateEntityByName("env_spritetrail");
		if (entIndex > 0 && IsValidEntity(entIndex))
		{
			// mark that we made a sprite trail for this client
			g_iClientSpriteEntIndex[client] = entIndex;
			
			DispatchKeyValue(entIndex, "parentname", sTempName);
			decl String:thePath[PLATFORM_MAX_PATH];
			GetArrayString(gH_DArray_CustomPathNames, g_CurrentTrail[client], thePath, PLATFORM_MAX_PATH);
			DispatchKeyValue(entIndex, "spritename", thePath);
			SetEntPropFloat(entIndex, Prop_Send, "m_flTextureRes", 0.05);
			
			DispatchKeyValue(entIndex, "renderamt", colors[3]);
			decl String:theColor[16];
			Format(theColor, sizeof(theColor), "%s %s %s", colors[0], colors[1], colors[2]);
			DispatchKeyValue(entIndex, "rendercolor", theColor);
			
			DispatchKeyValueFloat(entIndex, "lifetime", GetConVarFloat(gH_Cvar_Lifetime));
			DispatchKeyValueFloat(entIndex, "startwidth", GetConVarFloat(gH_Cvar_StartWidth));
			DispatchKeyValueFloat(entIndex, "endwidth", GetConVarFloat(gH_Cvar_EndWidth));
			decl String:sTemp[5];
			GetConVarString(gH_Cvar_RenderMode, sTemp, sizeof(sTemp));
			DispatchKeyValue(entIndex, "rendermode", sTemp);
			
			DispatchSpawn(entIndex);
			new Float:f_origin[3];
			GetClientAbsOrigin(client, f_origin);
			f_origin[2] += 14.0; // 34
			TeleportEntity(entIndex, f_origin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(sTempName);
			AcceptEntityInput(entIndex, "SetParent", entIndex, entIndex);
			
			SDKHook(entIndex, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}	
}

public Action:Hook_SetTransmit(entity, client)
{
	#if defined _GlobalEffects_Included_
	// check if we're loaded and ready to go
	if (g_bToggleEffectsLibAvail && !ShowClientEffects(client))
	{
		return Plugin_Handled;
	}
	#endif
	
	#if defined _SpecialDays_Included_
	if (g_bSpecDaysLibAvail && IsSpecialDay())
	{
		return Plugin_Handled;
	}
	#endif
	
	// find entity's owner
	new parent = -1;
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (g_iClientSpriteEntIndex[idx] == entity)
		{
			if (IsClientInGame(idx))
			{
				parent = idx;
			}
		}
	}
	// find if the entity's team matches the client teams and they want team only
	if ((parent != -1) && (GetClientTeam(parent) != GetClientTeam(client)) && g_bTeamOnlyTrails[parent])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
