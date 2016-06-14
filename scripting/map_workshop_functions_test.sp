/**
 * vim: set ts=4 :
 * =============================================================================
 * Map Workshop Functions Test
 * Test the various Map Workshop Functions
 *
 * Map Workshop Functions Test
 * (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
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
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#include <sourcemod>
#include "include/map_workshop_functions.inc"
#pragma semicolon 1

#define VERSION "1.0.0"

public Plugin:myinfo = {
	name			= "Map Workshop Functions Test",
	author			= "Powerlord",
	description		= "Test the various Map Workshop Functions",
	version			= VERSION,
	url				= ""
};
 
public OnPluginStart()
{
	CreateConVar("map_workshop_functions_test_version", VERSION, "Map Workshop Functions Test version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	RegConsoleCmd("substring", Cmd_Substring, "Test SubString command");
	RegConsoleCmd("removemappath", Cmd_RemoveMapPath, "Test RemoveMapPath command");
	RegConsoleCmd("mapequal", Cmd_MapEqual, "Test MapEqual command");
}

public Action:Cmd_Substring(client, args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage: substring start length");
		return Plugin_Handled;
	}
	
	new String:source[64];
	new String:strStart[5];
	new String:strLen[5];

	GetCmdArg(1, source, sizeof(source));
	GetCmdArg(2, strStart, sizeof(strStart));
	GetCmdArg(3, strLen, sizeof(strLen));
	
	new start = StringToInt(strStart);
	new len = StringToInt(strLen);
	
	new String:destination[64];
	SubString(source, start, len, destination, sizeof(destination));
	
	ReplyToCommand(client, "%s", destination);
	
	return Plugin_Handled;
}

public Action:Cmd_MapEqual(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: mapequal \"map\" \"map2\"");
		return Plugin_Handled;
	}
	
	new String:map1[PLATFORM_MAX_PATH];
	new String:map2[PLATFORM_MAX_PATH];
	
	GetCmdArg(1, map1, sizeof(map1));
	GetCmdArg(2, map2, sizeof(map2));
	
	ReplyToCommand(client, "Maps equal: %d", MapEqual(map1, map2));
	
	return Plugin_Handled;
}

public Action:Cmd_RemoveMapPath(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: removemappath \"map\"");
		return Plugin_Handled;
	}
	
	new String:map[PLATFORM_MAX_PATH];
	
	GetCmdArg(1, map, sizeof(map));
	
	new String:outputmap[PLATFORM_MAX_PATH];
	new bool:success = RemoveMapPath(map, outputmap, sizeof(outputmap));
	
	if (success)
	{
		ReplyToCommand(client, "RemoveMapPath succeeded: %s", outputmap);
	}
	else
	{
		ReplyToCommand(client, "RemoveMapPath failed");
	}
	
	return Plugin_Handled;
}
