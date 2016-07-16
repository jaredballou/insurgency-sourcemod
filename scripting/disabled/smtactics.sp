/**
 * =============================================================================
 * WCFAN Tactics
 * Possiblity to place routes and positions around the map to visualize war tactics.
 *
 * WCFAN Tactics (C)2011 Jannik Hartung  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Changelog:
 * 1.0: Initial version
 * 1.1: Added temporary position glows per map in different colors
 * 1.1.1: Added option to teleport to point with rightclick + e
 * 1.2: Added multilingual support
 * 1.2.1: Removed bullet_impact event dependency and used tracerays instead to support more mods.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.2.1"

#define PREFIX "{olive}Tactics {default}>{green} "

#define TACTIC_NAME 0
#define TACTIC_COLORS 1

#define COLOR_COLOR 0
#define COLOR_WAYPARTS 1
#define COLOR_SHOW 2
#define COLOR_WIDTH 3

#define DEFAULT_BEAM_WIDTH 10.0

// Glow colors
#define GLOW_BLUE 0
#define GLOW_RED 1
#define GLOW_GREEN 2
#define GLOW_YELLOW 3
#define GLOW_PURPLE 4
#define GLOW_ORANGE 5
#define GLOW_WHITE 6

#define GLOW_COUNT 7

// Config parser stuff
enum ConfigSection
{
	State_None = 0,
	State_Root,
	State_Tactic,
	State_Color,
	State_Waypoints
}

new Handle:g_hTactics = INVALID_HANDLE;
new Handle:g_hGlows = INVALID_HANDLE;
new ConfigSection:g_ConfigSection = State_None;
new g_iCurrentConfigIndex = -1;
new g_iCurrentColorIndex = -1;
new g_iCurrentPartIndex = -1;

new g_iPlayerEditsTactic[MAXPLAYERS+1] = {-1,...};
new g_iPlayerEditsColor[MAXPLAYERS+1] = {-1,...};
new g_iPlayerEditsPart[MAXPLAYERS+1] = {-1,...};
new g_iPlayerEditsGlow[MAXPLAYERS+1] = {-1,...};

new bool:g_bPlayerAddsNewTactic[MAXPLAYERS+1] = {false,...};
new bool:g_bPlayerRenamesTactic[MAXPLAYERS+1] = {false,...};
new bool:g_bPlayerPressesUse[MAXPLAYERS+1] = {false,...};
new bool:g_bPlayerPressesAttack1[MAXPLAYERS+1] = {false,...};
new bool:g_bPlayerPressesAttack2[MAXPLAYERS+1] = {false,...};

new g_iBeamSprite = -1;
new g_iHaloSprite = -1;
new g_iBlueGlowSprite = -1;
new g_iRedGlowSprite = -1;
new g_iGreenGlowSprite = -1;
new g_iYellowGlowSprite = -1;
new g_iPurpleGlowSprite = -1;
new g_iOrangeGlowSprite = -1;
new g_iWhiteGlowSprite = -1;

public Plugin:myinfo = 
{
	name = "Tatics",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Visualize different tactics on maps",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_tactics_version", PLUGIN_VERSION, "Tactics version",FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	LoadTranslations("common.phrases");
	LoadTranslations("tactics.phrases");
	
	g_hTactics = CreateArray();
	g_hGlows = CreateArray(3);
	RegAdminCmd("sm_tactic", Cmd_Tactic, ADMFLAG_CONFIG, "Opens the tactic menu");
	RegAdminCmd("sm_tactics", Cmd_Tactic, ADMFLAG_CONFIG, "Opens the tactic menu"); // Just an alias - i mistyped it too many times >.<
	
	AddCommandListener(CmdLstnr_Say, "say");
	AddCommandListener(CmdLstnr_Say, "say_team");
}

public OnMapStart()
{
	LoadTacticsFromFile();
	
	CreateTimer(1.0, Timer_ShowBeams, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt", true);
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_iBlueGlowSprite = PrecacheModel("materials/sprites/blueglow1.vmt",true);
	g_iRedGlowSprite = PrecacheModel("materials/sprites/redglow1.vmt",true);
	g_iGreenGlowSprite = PrecacheModel("materials/sprites/greenglow1.vmt",true);
	g_iYellowGlowSprite = PrecacheModel("materials/sprites/yellowglow1.vmt",true);
	g_iPurpleGlowSprite = PrecacheModel("materials/sprites/purpleglow1.vmt",true);
	g_iOrangeGlowSprite = PrecacheModel("materials/sprites/orangeglow1.vmt",true);
	g_iWhiteGlowSprite = PrecacheModel("materials/sprites/glow1.vmt",true);
	
	// Set the default size of the array and set all vectors to ->0.0
	ResizeArray(g_hGlows, GLOW_COUNT);
	new Float:fNullVec[3] = {0.0, 0.0, 0.0};
	for(new i=0; i<GLOW_COUNT; i++)
	{
		SetArrayArray(g_hGlows, i, fNullVec, 3);
	}
}

public OnMapEnd()
{
	ClearTacticArrays();
	ClearArray(g_hGlows);
}

public OnClientDisconnect(client)
{
	g_iPlayerEditsGlow[client] = -1;
	g_iPlayerEditsTactic[client] = -1;
	g_iPlayerEditsColor[client] = -1;
	g_iPlayerEditsPart[client] = -1;
	g_bPlayerAddsNewTactic[client] = false;
	g_bPlayerRenamesTactic[client] = false;
	g_bPlayerPressesUse[client] = false;
	g_bPlayerPressesAttack2[client] = false;
	g_bPlayerPressesAttack1[client] = false;
}

// Remove glow position on +use
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_ATTACK2)
		g_bPlayerPressesAttack2[client] = true;
	else
		g_bPlayerPressesAttack2[client] = false;
	
	// Player is shooting
	if(buttons & IN_ATTACK)
	{
		if(!g_bPlayerPressesAttack1[client])
		{
			g_bPlayerPressesAttack1[client] = true;
			
			// Only mess with the weapon, if we need to
			if((g_iPlayerEditsColor[client] != -1 && g_iPlayerEditsPart[client] != -1)
			|| g_iPlayerEditsGlow[client] != -1)
			{
				new iWeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				new Float:fGameTime = GetGameTime();
				
				// Check if the weapon is able to fire. The player is holding +attack, so we assume his weapon fires.
				if (iWeaponIndex != -1
				&& fGameTime >= GetEntPropFloat(iWeaponIndex, Prop_Send, "m_flNextPrimaryAttack")
				&& fGameTime >= GetEntPropFloat(client, Prop_Send, "m_flNextAttack")
				&& GetEntProp(iWeaponIndex, Prop_Send, "m_iClip1") > 0)
				{
					if(g_iPlayerEditsColor[client] != -1 && g_iPlayerEditsPart[client] != -1)
					{
						new Float:fOrigin[3], Float:fAngle[3];
						GetClientEyePosition(client, fOrigin);
						GetClientEyeAngles(client, fAngle);
						TR_TraceRayFilter(fOrigin, fAngle, MASK_SHOT, RayType_Infinite, TR_FilterDontHitSelf, client);
						if(TR_DidHit())
						{
							TR_GetEndPosition(fOrigin);
							
							new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[client]);
							
							new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
							
							new Handle:hColor = GetArrayCell(hColors, g_iPlayerEditsColor[client]);
							
							new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
							
							new Handle:hCoordinates = GetArrayCell(hParts, g_iPlayerEditsPart[client]);
							
							// Higher!
							fOrigin[2] += 10.0;
							
							// Add the position of the bullet to the end of the way
							PushArrayArray(hCoordinates, fOrigin, 3);
							
							SaveTacticsToFile();
							
							CPrintToChat(client, "%s%t", PREFIX, "Added new waypoint");
							
							// The menu clears those vars on cancel -.-
							new iBufTactic = g_iPlayerEditsTactic[client];
							new iBufColor = g_iPlayerEditsColor[client];
							new iBufPart = g_iPlayerEditsPart[client];
							
							// Update the menu
							ShowTacticColorMenu(client);
							
							g_iPlayerEditsTactic[client] = iBufTactic;
							g_iPlayerEditsColor[client] = iBufColor;
							g_iPlayerEditsPart[client] = iBufPart;
						}
					}
					// He's adding colored glow positions
					else if(g_iPlayerEditsGlow[client] != -1)
					{
						PrintToChat(client, "You shot.");
						new Float:fOrigin[3], Float:fAngle[3];
						GetClientEyePosition(client, fOrigin);
						GetClientEyeAngles(client, fAngle);
						TR_TraceRayFilter(fOrigin, fAngle, MASK_SHOT, RayType_Infinite, TR_FilterDontHitSelf, client);
						if(TR_DidHit())
						{
							TR_GetEndPosition(fOrigin);
							
							// Higher!
							fOrigin[2] += 10.0;
							
							// Replace the position of the bullet into the position of the color
							SetArrayArray(g_hGlows, g_iPlayerEditsGlow[client], fOrigin, 3);
							
							new iBuf = g_iPlayerEditsGlow[client];
							
							// Redraw the menu to show the *
							ShowGlowMenu(client);
							
							g_iPlayerEditsGlow[client] = iBuf;
						}
					}
				}
			}
		}
	}
	else
		g_bPlayerPressesAttack1[client] = false;
	
	if(buttons & IN_USE)
	{
		// Only check for removal when he just started to press +use
		if(!g_bPlayerPressesUse[client] && g_iPlayerEditsGlow[client] != -1)
		{
			// Teleport to the current position
			if(g_bPlayerPressesAttack2[client] && IsPlayerAlive(client))
			{
				new Float:fOrigin[3];
				GetArrayArray(g_hGlows, g_iPlayerEditsGlow[client], fOrigin, 3);
				if(!IsEmptyVector(fOrigin))
				{
					TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR);
				}
			}
			// Delete the current position
			else
			{
				new Float:fOrigin[3];
				GetArrayArray(g_hGlows, g_iPlayerEditsGlow[client], fOrigin, 3);
				if(!IsEmptyVector(fOrigin))
				{
					SetArrayArray(g_hGlows, g_iPlayerEditsGlow[client], Float:{0.0, 0.0, 0.0}, 3);
					
					// Need to save the index temporary, since we reset it to -1 when this menu closes..
					new iBuf = g_iPlayerEditsGlow[client];
					
					// Redraw the menu
					ShowGlowMenu(client);
					
					g_iPlayerEditsGlow[client] = iBuf;
				}
			}
		}
		
		g_bPlayerPressesUse[client] = true;
	}
	else
		g_bPlayerPressesUse[client] = false;
	
	return Plugin_Continue;
}

public bool:TR_FilterDontHitSelf(entity, contentsMask, any:data)
{
	if(entity == data)
		return false;
	return true;
}

public Action:Cmd_Tactic(client, args)
{
	if(!client)
		return Plugin_Handled;
	
	g_bPlayerAddsNewTactic[client] = false;
	g_bPlayerRenamesTactic[client] = false;
	
	ShowTacticOverviewMenu(client);
	
	return Plugin_Handled;
}

ShowTacticOverviewMenu(client)
{
	new Handle:hMenu = CreateMenu(Menu_HandleTacticSelection);
	SetMenuTitle(hMenu, "%T: %T", "Tactics", client, "Overview", client);
	SetMenuExitButton(hMenu, true);
	
	decl String:sMenu[64];
	
	Format(sMenu, sizeof(sMenu), "%T", "Add new tactic", client);
	AddMenuItem(hMenu, "add", sMenu);
	
	Format(sMenu, sizeof(sMenu), "%T", "Manage positions", client);
	AddMenuItem(hMenu, "points", sMenu);
	
	// Load current tactics into menu
	new iSize = GetArraySize(g_hTactics);
	
	if(iSize > 0)
	{
		AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
		Format(sMenu, sizeof(sMenu), "%T", "Present tactics", client);
		AddMenuItem(hMenu, "", sMenu, ITEMDRAW_DISABLED);
		
		new Handle:hConfig;
		decl String:sBuffer[10], String:sTactic[64];
		for(new i=0;i<iSize;i++)
		{
			hConfig = GetArrayCell(g_hTactics, i);
			
			IntToString(i, sBuffer, sizeof(sBuffer));
			
			GetArrayString(hConfig, TACTIC_NAME, sTactic, sizeof(sTactic));
			AddMenuItem(hMenu, sBuffer, sTactic);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

ShowTacticDetailsMenu(client, bool:bShow2ndSite = false)
{
	if(GetArraySize(g_hTactics) <= g_iPlayerEditsTactic[client])
	{
		g_iPlayerEditsTactic[client] = -1;
		ShowTacticOverviewMenu(client);
		return;
	}
	
	new Handle:hMenu = CreateMenu(Menu_HandleTacticDetails);
	
	new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[client]);
	decl String:sBuffer[64];
	GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
	
	SetMenuTitle(hMenu, "%T: %s", "Tactics", client, sBuffer);
	SetMenuExitBackButton(hMenu, true);
	
	decl String:sMenu[64];
	
	Format(sMenu, sizeof(sMenu), "%T", "Show all ways", client);
	AddMenuItem(hMenu, "showall", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Hide all ways", client);
	AddMenuItem(hMenu, "hideall", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Rename tactic", client);
	AddMenuItem(hMenu, "rename", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Delete tactic", client);
	AddMenuItem(hMenu, "delete", sMenu);
	
	AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
	
	Format(sMenu, sizeof(sMenu), "%T", "Platin", client);
	AddMenuItem(hMenu, "platin", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Red", client);
	AddMenuItem(hMenu, "red", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Blue", client);
	AddMenuItem(hMenu, "blue", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Yellow", client);
	AddMenuItem(hMenu, "yellow", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Green", client);
	AddMenuItem(hMenu, "green", sMenu);
	Format(sMenu, sizeof(sMenu), "%T", "Purple", client);
	AddMenuItem(hMenu, "purple", sMenu);
	
	// Show the 2nd site
	if(bShow2ndSite)
		DisplayMenuAtItem(hMenu, client, 7, MENU_TIME_FOREVER);
	else
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

ShowTacticColorMenu(client, const String:sColorTag[] = "", bool:bShow2ndSite = false)
{
	if(GetArraySize(g_hTactics) <= g_iPlayerEditsTactic[client])
	{
		g_iPlayerEditsTactic[client] = -1;
		g_iPlayerEditsColor[client] = -1;
		ShowTacticOverviewMenu(client);
		return;
	}
	
	// That should never happen >.<
	if(strlen(sColorTag) == 0 && g_iPlayerEditsColor[client] == -1)
	{
		ShowTacticDetailsMenu(client);
		return;
	}
	
	new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[client]);
	
	decl String:sBuffer[64], String:sBuffer2[64];
	
	new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
	decl String:sColor[32];
	new Handle:hColor;
	
	// Get color index, if it's already a config for that color
	if(strlen(sColorTag) > 0)
	{
		g_iPlayerEditsColor[client] = -1;
		new iSize = GetArraySize(hColors);
		for(new x=0;x<iSize;x++)
		{
			hColor = GetArrayCell(hColors, x);
			GetArrayString(hColor, COLOR_COLOR, sBuffer, sizeof(sBuffer));
			if(StrEqual(sBuffer, sColorTag))
			{
				g_iPlayerEditsColor[client] = x;
				break;
			}
		}
		
		// Not Found? Add it.
		if(g_iPlayerEditsColor[client] == -1)
		{
			hColor = CreateArray(ByteCountToCells(64));
			
			PushArrayString(hColor, sColorTag); // Color read
			PushArrayCell(hColor, CreateArray()); // way parts
			PushArrayCell(hColor, true); // show this tactic color
			PushArrayCell(hColor, DEFAULT_BEAM_WIDTH); // beam width
			
			g_iPlayerEditsColor[client] = PushArrayCell(hColors, hColor);
		}
		
		Format(sColor, sizeof(sColor), "%s", sColorTag);
	}
	// This color already exists, since we got the index
	else
	{
		hColor = GetArrayCell(hColors, g_iPlayerEditsColor[client]);
		GetArrayString(hColor, COLOR_COLOR, sColor, sizeof(sColor));
	}
	
	// No part yet? Create one!
	new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
	new Handle:hCoordinates;
	new iPartCount = GetArraySize(hParts);
	if(iPartCount == 0)
	{
		hCoordinates = CreateArray(3); // coordinates
		g_iPlayerEditsPart[client] = PushArrayCell(hParts, hCoordinates);
		iPartCount++;
	}
	// He's chosen a part before
	else
	{
		// Chose the first part by default
		if(g_iPlayerEditsPart[client] == -1 || iPartCount <= g_iPlayerEditsPart[client])
			g_iPlayerEditsPart[client] = 0;
		
		hCoordinates = GetArrayCell(hParts, g_iPlayerEditsPart[client]);
	}
	
	// Get tactic name and color for the menu title
	GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
	GetColorReadable(sColor, sBuffer2, sizeof(sBuffer2), client);
	
	new Handle:hMenu = CreateMenu(Menu_HandleTacticWaypointSet);
	SetMenuTitle(hMenu, "%T: %s > %s %d", "Tactics", client, sBuffer, sBuffer2, g_iPlayerEditsPart[client]);
	SetMenuExitBackButton(hMenu, true);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Add point at position", client);
	AddMenuItem(hMenu, "mypos", sBuffer);
	// Are there any coordinates already?
	Format(sBuffer, sizeof(sBuffer), "%T", "Teleport to last point", client);
	AddMenuItem(hMenu, "teleport", sBuffer, (GetArraySize(hCoordinates)>0?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	Format(sBuffer, sizeof(sBuffer), "%T", "Delete last waypoint", client);
	AddMenuItem(hMenu, "dellast", sBuffer, (GetArraySize(hCoordinates)>0?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	Format(sBuffer, sizeof(sBuffer), "%T", "Add new part", client);
	AddMenuItem(hMenu, "newpart", sBuffer);
	// This isn't the first part?
	Format(sBuffer, sizeof(sBuffer), "%T", "Previous part", client);
	AddMenuItem(hMenu, "prevpart", sBuffer, (g_iPlayerEditsPart[client]!=0?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	// This isn't the last part?
	Format(sBuffer, sizeof(sBuffer), "%T", "Next part", client);
	AddMenuItem(hMenu, "nextpart", sBuffer, (g_iPlayerEditsPart[client]!=(iPartCount-1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Show waypoints", client);
	if(GetArrayCell(hColor, COLOR_SHOW))
		Format(sBuffer, sizeof(sBuffer), "%s: %T", sBuffer, "Yes", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%s: %T", sBuffer, "No", client);
	
	AddMenuItem(hMenu, "showhide", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Enlarge laserwidth", client);
	AddMenuItem(hMenu, "widthadd", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Smaller laserwidth", client);
	AddMenuItem(hMenu, "widthrem", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Delete this part", client);
	AddMenuItem(hMenu, "delete", sBuffer);
	
	
	//AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
	//AddMenuItem(hMenu, "", "Shoot at a position to set the next point there.", ITEMDRAW_DISABLED);
	
	if(bShow2ndSite)
		DisplayMenuAtItem(hMenu, client, 7, MENU_TIME_FOREVER);
	else
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

ShowGlowMenu(client)
{
	new Handle:hMenu = CreateMenu(Menu_HandleGlowColor);
	
	decl String:sBuffer[64];
	new Float:fOrigin[3];
	
	SetMenuTitle(hMenu, "%T: %T", "Tactics", client, "Manage positions", client);
	SetMenuExitBackButton(hMenu, true);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Blue", client);
	// Is this client currently editing this color?
	if(g_iPlayerEditsGlow[client] == GLOW_BLUE)
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	GetArrayArray(g_hGlows, GLOW_BLUE, fOrigin);
	// Is there a position with this color already somewhere?
	if(!IsEmptyVector(fOrigin))
		Format(sBuffer, sizeof(sBuffer), "%s *", sBuffer);
	AddMenuItem(hMenu, "blue", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Red", client);
	if(g_iPlayerEditsGlow[client] == GLOW_RED)
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	GetArrayArray(g_hGlows, GLOW_RED, fOrigin);
	if(!IsEmptyVector(fOrigin))
		Format(sBuffer, sizeof(sBuffer), "%s *", sBuffer);
	AddMenuItem(hMenu, "red", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Green", client);
	if(g_iPlayerEditsGlow[client] == GLOW_GREEN)
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	GetArrayArray(g_hGlows, GLOW_GREEN, fOrigin);
	if(!IsEmptyVector(fOrigin))
		Format(sBuffer, sizeof(sBuffer), "%s *", sBuffer);
	AddMenuItem(hMenu, "green", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Yellow", client);
	if(g_iPlayerEditsGlow[client] == GLOW_YELLOW)
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	GetArrayArray(g_hGlows, GLOW_YELLOW, fOrigin);
	if(!IsEmptyVector(fOrigin))
		Format(sBuffer, sizeof(sBuffer), "%s *", sBuffer);
	AddMenuItem(hMenu, "yellow", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Purple", client);
	if(g_iPlayerEditsGlow[client] == GLOW_PURPLE)
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	GetArrayArray(g_hGlows, GLOW_PURPLE, fOrigin);
	if(!IsEmptyVector(fOrigin))
		Format(sBuffer, sizeof(sBuffer), "%s *", sBuffer);
	AddMenuItem(hMenu, "purple", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Orange", client);
	if(g_iPlayerEditsGlow[client] == GLOW_ORANGE)
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	GetArrayArray(g_hGlows, GLOW_ORANGE, fOrigin);
	if(!IsEmptyVector(fOrigin))
		Format(sBuffer, sizeof(sBuffer), "%s *", sBuffer);
	AddMenuItem(hMenu, "orange", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "White", client);
	if(g_iPlayerEditsGlow[client] == GLOW_WHITE)
		Format(sBuffer, sizeof(sBuffer), "-> %s", sBuffer);
	GetArrayArray(g_hGlows, GLOW_WHITE, fOrigin);
	if(!IsEmptyVector(fOrigin))
		Format(sBuffer, sizeof(sBuffer), "%s *", sBuffer);
	AddMenuItem(hMenu, "white", sBuffer);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Menu_HandleTacticSelection(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		decl String:info[35];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		// Admin wants to add a new tactic!
		if(StrEqual(info, "add"))
		{
			g_bPlayerAddsNewTactic[param1] = true;
			CPrintToChat(param1, "%s%t", PREFIX, "Type name of new tactic");
		}
		else if(StrEqual(info, "points"))
		{
			ShowGlowMenu(param1);
		}
		// Admin wants to manage a given tactic
		else
		{
			g_iPlayerEditsTactic[param1] = StringToInt(info);
			ShowTacticDetailsMenu(param1);
		}
	}
}

public Menu_HandleTacticDetails(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		g_iPlayerEditsTactic[param1] = -1;
		if(param2 == MenuCancel_ExitBack)
			ShowTacticOverviewMenu(param1);
	}
	else if(action == MenuAction_Select)
	{
		decl String:info[35];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(GetArraySize(g_hTactics) <= g_iPlayerEditsTactic[param1])
		{
			g_iPlayerEditsTactic[param1] = -1;
			ShowTacticOverviewMenu(param1);
			return;
		}
		
		// Show all connected ways
		if(StrEqual(info, "showall"))
		{
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[param1]);
			
			decl String:sBuffer[64];
			GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
			
			new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
			
			new Handle:hColor;
			new iSize = GetArraySize(hColors);
			for(new x=0;x<iSize;x++)
			{
				hColor = GetArrayCell(hColors, x);
				SetArrayCell(hColor, COLOR_SHOW, true);
			}
			
			CPrintToChat(param1, "%s%t", PREFIX, "Showed all ways", sBuffer);
			ShowTacticDetailsMenu(param1);
		}
		else if(StrEqual(info, "hideall"))
		{
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[param1]);
			
			decl String:sBuffer[64];
			GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
			
			new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
			
			new Handle:hColor;
			new iSize = GetArraySize(hColors);
			for(new x=0;x<iSize;x++)
			{
				hColor = GetArrayCell(hColors, x);
				SetArrayCell(hColor, COLOR_SHOW, false);
			}
			
			CPrintToChat(param1, "%s%t", PREFIX, "Hidden all ways", sBuffer);
			ShowTacticDetailsMenu(param1);
		}
		// Admin wants to rename this tactic
		else if(StrEqual(info, "rename"))
		{
			g_bPlayerRenamesTactic[param1] = true;
			
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[param1]);
			
			decl String:sBuffer[128];
			GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
			
			CPrintToChat(param1, "%s%t", PREFIX, "Rename tactic instruction", sBuffer);
		}
		// Admin wants to delete this tactic
		else if(StrEqual(info, "delete"))
		{
			new Handle:hPanel = CreatePanel();
			
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[param1]);
			
			decl String:sBuffer[128];
			GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
			Format(sBuffer, sizeof(sBuffer), "%T", "Confirm tactic delete", param1, sBuffer);
			
			SetPanelTitle(hPanel, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%T", "Yes", param1);
			DrawPanelItem(hPanel, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%T", "No", param1);
			DrawPanelItem(hPanel, sBuffer);
			
			SendPanelToClient(hPanel, param1, Panel_ConfirmDeleteTacticHandle, MENU_TIME_FOREVER);
			CloseHandle(hPanel);
		}
		// Admin wants to manage a colored waypoint
		else
		{
			ShowTacticColorMenu(param1, info);
		}
	}
}

public Panel_ConfirmDeleteTacticHandle(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(GetArraySize(g_hTactics) <= g_iPlayerEditsTactic[param1])
		{
			g_iPlayerEditsTactic[param1] = -1;
			ShowTacticOverviewMenu(param1);
			return;
		}
		
		// Yes!
		if(param2 == 1)
		{
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[param1]);
			new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
		
			new iSize = GetArraySize(hColors), iSize2;
			new Handle:hColor, Handle:hParts, Handle:hCoordinates;
			for(new x=0;x<iSize;x++)
			{
				hColor = GetArrayCell(hColors, x);
				hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
				
				iSize2 = GetArraySize(hParts);
				for(new y=0;y<iSize2;y++)
				{
					hCoordinates = GetArrayCell(hParts, y);
					CloseHandle(hCoordinates);
				}
				
				CloseHandle(hParts);
				CloseHandle(hColor);
			}
			
			CloseHandle(hColors);
			CloseHandle(hConfig);
			RemoveFromArray(g_hTactics, g_iPlayerEditsTactic[param1]);
			
			SaveTacticsToFile();
			
			ShowTacticOverviewMenu(param1);
		}
		// No..
		else
			ShowTacticDetailsMenu(param1);
	}
}

public Menu_HandleTacticWaypointSet(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		g_iPlayerEditsPart[param1] = -1;
		g_iPlayerEditsColor[param1] = -1;
		if(param2 == MenuCancel_ExitBack)
			ShowTacticDetailsMenu(param1, true);
		else
			g_iPlayerEditsTactic[param1] = -1;
	}
	else if(action == MenuAction_Select)
	{
		if(GetArraySize(g_hTactics) <= g_iPlayerEditsTactic[param1])
		{
			g_iPlayerEditsTactic[param1] = -1;
			g_iPlayerEditsColor[param1] = -1;
			g_iPlayerEditsPart[param1] = -1;
			ShowTacticOverviewMenu(param1);
			return;
		}
		
		new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[param1]);
		
		new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
		
		// That color isn't there anymore? Don't error, just go back to previous menu
		if(GetArraySize(hColors) <= g_iPlayerEditsColor[param1])
		{
			g_iPlayerEditsColor[param1] = -1;
			g_iPlayerEditsPart[param1] = -1;
			ShowTacticDetailsMenu(param1);
			return;
		}
		
		new Handle:hColor = GetArrayCell(hColors, g_iPlayerEditsColor[param1]);
		
		decl String:info[35];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		// Toggle way
		if(StrEqual(info, "showhide"))
		{
			// Set to the opposite
			SetArrayCell(hColor, COLOR_SHOW, !GetArrayCell(hColor, COLOR_SHOW));
			
			ShowTacticColorMenu(param1);
		}
		// Remove the latest waypoint
		else if(StrEqual(info, "dellast"))
		{
			new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			new Handle:hCoordinates = GetArrayCell(hParts, g_iPlayerEditsPart[param1]);
			
			// Remove the latest element
			new iSize = GetArraySize(hCoordinates);
			if(iSize > 0)
				ResizeArray(hCoordinates, iSize-1);
			
			SaveTacticsToFile();
			
			ShowTacticColorMenu(param1);
		}
		// Add a new waypoint at the position of admin's feet
		else if(StrEqual(info, "mypos"))
		{
			new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			new Handle:hCoordinates = GetArrayCell(hParts, g_iPlayerEditsPart[param1]);
			
			new Float:fOrigin[3];
			GetClientAbsOrigin(param1, fOrigin);
			
			// Add the current position to the end of the way
			PushArrayArray(hCoordinates, fOrigin, 3);
			
			SaveTacticsToFile();
			
			ShowTacticColorMenu(param1);
			
			CPrintToChat(param1, "%s%t", PREFIX, "Added new waypoint");
		}
		// Add a new waypoint at the position of admin's feet
		else if(StrEqual(info, "teleport"))
		{
			new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			new Handle:hCoordinates = GetArrayCell(hParts, g_iPlayerEditsPart[param1]);
			
			new Float:fOrigin[3];
			// Teleport admin to the latest point
			new iSize = GetArraySize(hCoordinates);
			if(iSize > 0)
			{
				GetArrayArray(hCoordinates, iSize-1, fOrigin, 3);
				TeleportEntity(param1, fOrigin, NULL_VECTOR, NULL_VECTOR);
			}
			
			ShowTacticColorMenu(param1);
		}
		// Add a new part
		else if(StrEqual(info, "newpart"))
		{
			new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			// Add a new part and set the admin to edit it
			g_iPlayerEditsPart[param1] = PushArrayCell(hParts, CreateArray(3));
			
			ShowTacticColorMenu(param1);
		}
		// Edit the previous way part
		else if(StrEqual(info, "prevpart"))
		{
			new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			new iSize = GetArraySize(hParts);
			
			if(g_iPlayerEditsPart[param1] >= iSize)
				g_iPlayerEditsPart[param1] = iSize - 1;
			else if(g_iPlayerEditsPart[param1]-1 >= 0)
				g_iPlayerEditsPart[param1]--;
			
			ShowTacticColorMenu(param1);
		}
		// Edit the next way part
		else if(StrEqual(info, "nextpart"))
		{
			new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			new iSize = GetArraySize(hParts);
			
			if(g_iPlayerEditsPart[param1] >= iSize)
				g_iPlayerEditsPart[param1] = iSize - 1;
			else if(g_iPlayerEditsPart[param1]+1 < iSize)
				g_iPlayerEditsPart[param1]++;
			
			ShowTacticColorMenu(param1);
		}
		// Delete this part
		else if(StrEqual(info, "delete"))
		{
			//new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			new Handle:hPanel = CreatePanel();
			
			decl String:sBuffer[128], String:sColor[20], String:sBuffer2[64];
			GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
			GetArrayString(hColor, COLOR_COLOR, sColor, sizeof(sColor));
			GetColorReadable(sColor, sBuffer2, sizeof(sBuffer2), param1);
			Format(sBuffer, sizeof(sBuffer), "%s > %s > %T", sBuffer, sColor, "Confirm part delete", param1, g_iPlayerEditsPart[param1]);
			
			SetPanelTitle(hPanel, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%T", "Yes", param1);
			DrawPanelItem(hPanel, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%T", "No", param1);
			DrawPanelItem(hPanel, sBuffer);
			
			SendPanelToClient(hPanel, param1, Panel_ConfirmDeletePartHandler, MENU_TIME_FOREVER);
			CloseHandle(hPanel);
		}
		else if(StrEqual(info, "widthadd"))
		{
			new Float:fWidth = GetArrayCell(hColor, COLOR_WIDTH);
			fWidth += 1.0;
			
			SetArrayCell(hColor, COLOR_WIDTH, fWidth);
			
			CPrintToChat(param1, "%s%T", PREFIX, "Enlarged laser", param1, RoundToNearest(fWidth));
			
			ShowTacticColorMenu(param1, "", true);
		}
		else if(StrEqual(info, "widthrem"))
		{
			new Float:fWidth = GetArrayCell(hColor, COLOR_WIDTH);
			fWidth -= 1.0;
			if(fWidth < 1.0)
				fWidth = 1.0;
			
			SetArrayCell(hColor, COLOR_WIDTH, fWidth);
			
			CPrintToChat(param1, "%s%T", PREFIX, "Smallered laser", param1, RoundToNearest(fWidth));
			
			ShowTacticColorMenu(param1, "", true);
		}
	}
}

public Panel_ConfirmDeletePartHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(GetArraySize(g_hTactics) <= g_iPlayerEditsTactic[param1])
		{
			g_iPlayerEditsTactic[param1] = -1;
			ShowTacticOverviewMenu(param1);
			return;
		}
		
		new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[param1]);
		
		new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
		
		// Make sure there isn't someone deleting the whole color first..
		new iSize = GetArraySize(hColors);
		if(iSize <= g_iPlayerEditsColor[param1])
		{
			g_iPlayerEditsColor[param1] = -1;
			ShowTacticDetailsMenu(param1);
			return;
		}
		
		// Make sure there are enough parts for the one to delete
		new Handle:hColor = GetArrayCell(hColors, g_iPlayerEditsColor[param1]);
		new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
		if(GetArraySize(hParts) <= g_iPlayerEditsPart[param1])
		{
			g_iPlayerEditsPart[param1] = -1;
			ShowTacticColorMenu(param1);
			return;
		}
		
		// Yes!
		if(param2 == 1)
		{
			new Handle:hCoordinates = GetArrayCell(hParts, g_iPlayerEditsPart[param1]);
			CloseHandle(hCoordinates);

			RemoveFromArray(hParts, g_iPlayerEditsPart[param1]);
			
			// Chose the previous one.
			g_iPlayerEditsPart[param1]--;
			
			SaveTacticsToFile();
			
			ShowTacticColorMenu(param1);
		}
		// No..
		else
			ShowTacticColorMenu(param1);
	}
}

public Menu_HandleGlowColor(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		g_iPlayerEditsGlow[param1] = -1;
		if(param2 == MenuCancel_ExitBack)
			ShowTacticOverviewMenu(param1);
	}
	else if(action == MenuAction_Select)
	{
		decl String:info[35];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(StrEqual(info, "blue"))
			g_iPlayerEditsGlow[param1] = GLOW_BLUE;
		else if(StrEqual(info, "red"))
			g_iPlayerEditsGlow[param1] = GLOW_RED;
		else if(StrEqual(info, "green"))
			g_iPlayerEditsGlow[param1] = GLOW_GREEN;
		else if(StrEqual(info, "yellow"))
			g_iPlayerEditsGlow[param1] = GLOW_YELLOW;
		else if(StrEqual(info, "purple"))
			g_iPlayerEditsGlow[param1] = GLOW_PURPLE;
		else if(StrEqual(info, "orange"))
			g_iPlayerEditsGlow[param1] = GLOW_ORANGE;
		else if(StrEqual(info, "white"))
			g_iPlayerEditsGlow[param1] = GLOW_WHITE;
		
		// Need to save the index temporary, since we reset it to -1 when this menu closes..
		new iBuf = g_iPlayerEditsGlow[param1];
		
		// Redraw the menu
		ShowGlowMenu(param1);
		
		g_iPlayerEditsGlow[param1] = iBuf;
	}
}

public Action:CmdLstnr_Say(client, const String:command[], argc)
{
	if(!client)
		return Plugin_Continue;
	
	if(g_bPlayerAddsNewTactic[client])
	{
		g_bPlayerAddsNewTactic[client] = false;
		decl String:sBuffer[64];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		StripQuotes(sBuffer);
		
		if(StrEqual(sBuffer, "!stop"))
		{
			CPrintToChat(client, "%s%t", PREFIX, "Adding stopped");
			ShowTacticOverviewMenu(client);
			return Plugin_Handled;
		}
		
		new Handle:hConfig = CreateArray(ByteCountToCells(64));
		
		PushArrayString(hConfig, sBuffer); // Tactic name
		PushArrayCell(hConfig, CreateArray()); // colors
		
		g_iPlayerEditsTactic[client] = PushArrayCell(g_hTactics, hConfig);
		
		SaveTacticsToFile();
		
		ShowTacticDetailsMenu(client);
		CPrintToChat(client, "%sTaktik angelegt.", PREFIX);
		
		return Plugin_Handled;
	}
	else if(g_bPlayerRenamesTactic[client])
	{
		g_bPlayerRenamesTactic[client] = false;
		decl String:sBuffer[64];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		StripQuotes(sBuffer);
		
		if(StrEqual(sBuffer, "!stop"))
		{
			CPrintToChat(client, "%s%t", PREFIX, "Renaming stopped");
			ShowTacticDetailsMenu(client);
			return Plugin_Handled;
		}
		
		new Handle:hConfig = GetArrayCell(g_hTactics, g_iPlayerEditsTactic[client]);
		
		SetArrayString(hConfig, TACTIC_NAME, sBuffer);
		
		SaveTacticsToFile();
		
		ShowTacticDetailsMenu(client);
		CPrintToChat(client, "%s%t", PREFIX, "Renamed tactic");
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Timer_ShowBeams(Handle:timer, any:data)
{
	// Handle position glows
	new Float:fGlowOrigin[3];
	for(new i=0;i<GLOW_COUNT;i++)
	{
		GetArrayArray(g_hGlows, i, fGlowOrigin, 3);
		// There is a position for this
		if(!IsEmptyVector(fGlowOrigin))
		{
			switch(i)
			{
				case GLOW_BLUE:
				{
					TE_SetupGlowSprite(fGlowOrigin, g_iBlueGlowSprite, 2.0, 1.0, 255);
				}
				case GLOW_RED:
				{
					TE_SetupGlowSprite(fGlowOrigin, g_iRedGlowSprite, 2.0, 1.0, 255);
				}
				case GLOW_GREEN:
				{
					TE_SetupGlowSprite(fGlowOrigin, g_iGreenGlowSprite, 2.0, 1.0, 255);
				}
				case GLOW_YELLOW:
				{
					TE_SetupGlowSprite(fGlowOrigin, g_iYellowGlowSprite, 2.0, 1.0, 255);
				}
				case GLOW_PURPLE:
				{
					TE_SetupGlowSprite(fGlowOrigin, g_iPurpleGlowSprite, 2.0, 1.0, 255);
				}
				case GLOW_ORANGE:
				{
					TE_SetupGlowSprite(fGlowOrigin, g_iOrangeGlowSprite, 2.0, 1.0, 255);
				}
				case GLOW_WHITE:
				{
					TE_SetupGlowSprite(fGlowOrigin, g_iWhiteGlowSprite, 2.0, 1.0, 255);
				}
			}
			TE_SendToAll();
		}
	}
	
	// Handle tactics
	new iSize = GetArraySize(g_hTactics), iSize2, iSize3, iSize4;
	
	// Nothing to do here.
	if(iSize == 0)
		return Plugin_Continue;
	
	new Handle:hConfig, Handle:hColors, Handle:hColor, Handle:hParts, Handle:hCoordinates;
	new Float:fCoord[3], Float:fPreviousCoord[3], iColor[4], Float:fWidth;
	decl String:sColor[32];
	// Loop through all tactics
	for(new i=0;i<iSize;i++)
	{
		hConfig = GetArrayCell(g_hTactics, i);
		
		hColors = GetArrayCell(hConfig, TACTIC_COLORS);
		iSize2 = GetArraySize(hColors);
		// Loop through all different colors of ways
		for(new x=0;x<iSize2;x++)
		{
			hColor = GetArrayCell(hColors, x);
			
			// Show this way?
			if(!GetArrayCell(hColor, COLOR_SHOW))
				continue;
			
			GetArrayString(hColor, COLOR_COLOR, sColor, sizeof(sColor));
			GetRGBColor(sColor, iColor);
			
			fWidth = GetArrayCell(hColor, COLOR_WIDTH);
			
			hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			iSize3 = GetArraySize(hParts);
			for(new y=0;y<iSize3;y++)
			{
				// Reset data
				fPreviousCoord[0] = 0.0;
				fPreviousCoord[1] = 0.0;
				fPreviousCoord[2] = 0.0;
				
				hCoordinates = GetArrayCell(hParts, y);
				iSize4 = GetArraySize(hCoordinates);
				for(new z=0;z<iSize4;z++)
				{
					// Get new coord.
					GetArrayArray(hCoordinates, z, fCoord, 3);
					
					// Is there a previous one already?
					// Connect them!
					if(fPreviousCoord[0] > 0 || fPreviousCoord[1] > 0 || fPreviousCoord[1] > 0)
					{
						TE_SetupBeamPoints(fPreviousCoord, fCoord, g_iBeamSprite, g_iHaloSprite, 0, 1, 2.0, fWidth, fWidth, 1, 0.0, iColor, 4);
						TE_SendToAll();
					}
					fPreviousCoord = fCoord;
				}
			}
		}
	}
	return Plugin_Continue;
}

GetColorReadable(const String:sColorCode[], String:sColor[], maxlength, client)
{
	if(StrEqual(sColorCode, "platin"))
		Format(sColor, maxlength, "%T", "Platin way", client);
	else if(StrEqual(sColorCode, "red"))
		Format(sColor, maxlength, "%T", "Red way", client);
	else if(StrEqual(sColorCode, "blue"))
		Format(sColor, maxlength, "%T", "Blue way", client);
	else if(StrEqual(sColorCode, "yellow"))
		Format(sColor, maxlength, "%T", "Yellow way", client);
	else if(StrEqual(sColorCode, "green"))
		Format(sColor, maxlength, "%T", "Green way", client);
	else if(StrEqual(sColorCode, "purple"))
		Format(sColor, maxlength, "%T", "Purple way", client);
}

GetRGBColor(const String:sColorCode[], iColor[4])
{
	if(StrEqual(sColorCode, "platin"))
		iColor = {85,88,90,255};
	else if(StrEqual(sColorCode, "red"))
		iColor = {199,21,133,255};
	else if(StrEqual(sColorCode, "blue"))
		iColor = {39,64,139,255};
	else if(StrEqual(sColorCode, "yellow"))
		iColor = {255,215,0,255};
	else if(StrEqual(sColorCode, "green"))
		iColor = {0,100,0,255};
	else if(StrEqual(sColorCode, "purple"))
		iColor = {125,38,205,255};
}

stock bool:IsEmptyVector(const Float:fVec[3])
{
	if(fVec[0] == 0.0 && fVec[1] == 0.0 && fVec[2] == 0.0)
		return true;
	return false;
}

ClearTacticArrays()
{
	new iSize = GetArraySize(g_hTactics), iSize2, iSize3;
	new Handle:hConfig, Handle:hColors, Handle:hColor, Handle:hParts, Handle:hCoordinates;
	for(new i=0;i<iSize;i++)
	{
		hConfig = GetArrayCell(g_hTactics, i);
		
		hColors = GetArrayCell(hConfig, TACTIC_COLORS);
		
		iSize2 = GetArraySize(hColors);
		for(new x=0;x<iSize2;x++)
		{
			hColor = GetArrayCell(hColors, x);
			hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			iSize3 = GetArraySize(hParts);
			for(new y=0;y<iSize3;y++)
			{
				hCoordinates = GetArrayCell(hParts, y);
				CloseHandle(hCoordinates);
			}
			
			CloseHandle(hParts);
			CloseHandle(hColor);
		}
		
		CloseHandle(hColors);
		CloseHandle(hConfig);
	}
	ClearArray(g_hTactics);
}

SaveTacticsToFile()
{
	// Since there's no SMC writer, we have to do it on our own :S
	decl String:sConfigFile[PLATFORM_MAX_PATH], String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/tactics");
	
	// Create that directory
	if(!DirExists(sConfigFile))
		CreateDirectory(sConfigFile, 511);
	
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/tactics/%s.cfg", sMap);
	
	// Open the file for writing
	new Handle:hFile = OpenFile(sConfigFile, "w");
	
	WriteFileLine(hFile, "\"SMTactics\"");
	WriteFileLine(hFile, "{");
	
	new iSize = GetArraySize(g_hTactics), iSize2, iSize3, iSize4;
	new Handle:hConfig, Handle:hColors, Handle:hColor, Handle:hParts, Handle:hCoordinates;
	decl String:sBuffer[64];
	new Float:fCoord[3], Float:fWidth;
	for(new i=0;i<iSize;i++)
	{
		hConfig = GetArrayCell(g_hTactics, i);
		
		GetArrayString(hConfig, TACTIC_NAME, sBuffer, sizeof(sBuffer));
		WriteFileLine(hFile, "\t\"%s\"", sBuffer);
		WriteFileLine(hFile, "\t{");
		
		hColors = GetArrayCell(hConfig, TACTIC_COLORS);
		iSize2 = GetArraySize(hColors);
		for(new x=0;x<iSize2;x++)
		{
			hColor = GetArrayCell(hColors, x);
			hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			iSize3 = GetArraySize(hParts);
			
			if(iSize3 == 0)
				continue;
			
			GetArrayString(hColor, COLOR_COLOR, sBuffer, sizeof(sBuffer));
			
			WriteFileLine(hFile, "\t\t\"%s\"", sBuffer);
			WriteFileLine(hFile, "\t\t{");
			
			fWidth = GetArrayCell(hColor, COLOR_WIDTH);
			WriteFileLine(hFile, "\t\t\t\"beamwidth\"\t\"%f\"", fWidth);
			
			for(new y=0;y<iSize3;y++)
			{
				hCoordinates = GetArrayCell(hParts, y);
				iSize4 = GetArraySize(hCoordinates);
				
				if(iSize4 == 0)
					continue;
				
				WriteFileLine(hFile, "\t\t\t\"part\"");
				WriteFileLine(hFile, "\t\t\t{");
				
				for(new z=0;z<iSize4;z++)
				{
					GetArrayArray(hCoordinates, z, fCoord, 3);
					WriteFileLine(hFile, "\t\t\t\t\"coord\"\t\"%f %f %f\"", fCoord[0], fCoord[1], fCoord[2]);
				}
				WriteFileLine(hFile, "\t\t\t}");
			}
			
			WriteFileLine(hFile, "\t\t}");
		}
		WriteFileLine(hFile, "\t}");
	}
	WriteFileLine(hFile, "}");
	
	FlushFile(hFile);
	CloseHandle(hFile);
}

LoadTacticsFromFile()
{
	decl String:sConfigFile[PLATFORM_MAX_PATH], String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/tactics/%s.cfg", sMap);
	
	if(!FileExists(sConfigFile))
		return;
	
	// Close old arrays
	ClearTacticArrays();
	
	g_ConfigSection = State_None;
	g_iCurrentConfigIndex = -1;
	
	new Handle:hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, Config_OnNewSection, Config_OnKeyValue, Config_OnEndSection);
	SMC_SetParseEnd(hSMC, Config_OnParseEnd);
	
	new iLine, iColumn;
	new SMCError:smcResult = SMC_ParseFile(hSMC, sConfigFile, iLine, iColumn);
	CloseHandle(hSMC);
	
	if(smcResult != SMCError_Okay)
	{
		decl String:sError[128];
		SMC_GetErrorString(smcResult, sError, sizeof(sError));
		LogError("Error parsing config: %s on line %d, col %d of %s", sError, iLine, iColumn, sConfigFile);
		
		// Clear the halfway parsed config
		ClearTacticArrays();
	}
}

public SMCResult:Config_OnNewSection(Handle:parser, const String:section[], bool:quotes)
{
	switch(g_ConfigSection)
	{
		// new colored part
		case State_Color:
		{
			new Handle:hCoordinates = CreateArray(3); // coordinates
			
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iCurrentConfigIndex);
			new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
			new Handle:hColor = GetArrayCell(hColors, g_iCurrentColorIndex);
			new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
			
			g_iCurrentPartIndex = PushArrayCell(hParts, hCoordinates);
			
			g_ConfigSection = State_Waypoints;
		}
		// new waypoint color setting
		case State_Tactic:
		{
			new Handle:hColor = CreateArray(ByteCountToCells(64));
			
			PushArrayString(hColor, section); // Color read
			PushArrayCell(hColor, CreateArray()); // way parts
			PushArrayCell(hColor, false); // show this tactic color
			PushArrayCell(hColor, DEFAULT_BEAM_WIDTH); // beam width
			
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iCurrentConfigIndex);
			new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
			
			g_iCurrentColorIndex = PushArrayCell(hColors, hColor);
			
			g_ConfigSection = State_Color;
		}
		// New tactic "category"
		case State_Root:
		{
			new Handle:hConfig = CreateArray(ByteCountToCells(64));
			
			PushArrayString(hConfig, section); // Tactic name
			PushArrayCell(hConfig, CreateArray()); // colors
			
			g_iCurrentConfigIndex = PushArrayCell(g_hTactics, hConfig);
			g_ConfigSection = State_Tactic;
		}
		case State_None:
		{
			g_ConfigSection = State_Root;
		}
	}
	return SMCParse_Continue;
}

public SMCResult:Config_OnKeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(!key[0])
		return SMCParse_Continue;
	
	// Store the beam width
	if(g_ConfigSection == State_Color)
	{
		if(StrEqual(key, "beamwidth"))
		{
			new Handle:hConfig = GetArrayCell(g_hTactics, g_iCurrentConfigIndex);
			new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
			new Handle:hColor = GetArrayCell(hColors, g_iCurrentColorIndex);
			SetArrayCell(hColor, COLOR_WIDTH, StringToFloat(value));
		}
	}
	// Store the coordinates
	else if(g_ConfigSection == State_Waypoints)
	{
		new Handle:hConfig = GetArrayCell(g_hTactics, g_iCurrentConfigIndex);
		new Handle:hColors = GetArrayCell(hConfig, TACTIC_COLORS);
		new Handle:hColor = GetArrayCell(hColors, g_iCurrentColorIndex);
		new Handle:hParts = GetArrayCell(hColor, COLOR_WAYPARTS);
		new Handle:hCoordinates = GetArrayCell(hParts, g_iCurrentPartIndex);
		// Save the coordinate into the array
		if(StrEqual(key, "coord", false))
		{
			decl String:sCoords[3][32];
			new iCount = ExplodeString(value, " ", sCoords, 3, 32);
			if(iCount == 3)
			{
				new Float:fCoords[3];
				fCoords[0] = StringToFloat(sCoords[0]);
				fCoords[1] = StringToFloat(sCoords[1]);
				fCoords[2] = StringToFloat(sCoords[2]);
				
				PushArrayArray(hCoordinates, fCoords, 3);
			}
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult:Config_OnEndSection(Handle:parser)
{
	// Finished parsing that config part
	switch(g_ConfigSection)
	{
		case State_Waypoints:
		{
			g_iCurrentPartIndex = -1;
			g_ConfigSection = State_Color;
		}
		case State_Color:
		{
			g_iCurrentColorIndex = -1;
			g_ConfigSection = State_Tactic;
		}
		case State_Tactic:
		{
			g_iCurrentConfigIndex = -1;
			g_ConfigSection = State_Root;
		}
	}
	
	return SMCParse_Continue;
}

public Config_OnParseEnd(Handle:parser, bool:halted, bool:failed) {
	// We error later already
	//if (failed)
	//	SetFailState("Error during parse of the config.");
}
