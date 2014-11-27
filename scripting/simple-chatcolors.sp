/************************************************************************
*************************************************************************
Simple Chat Colors
Description:
		Changes the colors of players chat based on config file
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id$
$Author$
$Revision$
$Date$
$LastChangedBy$
$LastChangedDate$
$URL$
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#include <sourcemod>
#include <sdktools>
#include <scp>
#include <smlib>

#define PLUGIN_VERSION				"2.0.0.$Rev$"

new Handle:g_aPlayers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public Plugin:myinfo =
{
	name = "Simple Chat Colors",
	author = "Simple Plugins",
	description = "Changes the colors of players chat based on config file.",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
};

public OnPluginStart()
{
	CreateConVar("scc_version", PLUGIN_VERSION, "Simple Chat Colors", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_reloadscc", Command_Reload, ADMFLAG_CONFIG,  "Reloads settings from the config file");
	RegAdminCmd("sm_printcolors", Command_PrintColors, ADMFLAG_GENERIC,  "Prints out the color names in their color");
}

public OnClientPostAdminCheck(client)
{
	CheckPlayer(client);
}

public OnClientDisconnect(client)
{
	if (g_aPlayers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_aPlayers[client]);
	}
	g_aPlayers[client] = INVALID_HANDLE;
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
	if (g_aPlayers[author] != INVALID_HANDLE)
	{
		new index = CHATCOLOR_NOSUBJECT;
		decl String:sNameBuffer[MAXLENGTH_NAME], String:sTagBuffer[32];
		Color_StripFromChatText(name, sNameBuffer, MAXLENGTH_NAME);
	
		decl String:ColorCodes[3][12];
		if (GetTrieString(g_aPlayers[author], "namecolor", ColorCodes[0], sizeof(ColorCodes[])))
		{
			Format(sNameBuffer, sizeof(sNameBuffer), "%s%s", ColorCodes[0], sNameBuffer);
		}
		else
		{
			Format(sNameBuffer, sizeof(sNameBuffer), "\x03%s", sNameBuffer);
		}
		
		if (GetTrieString(g_aPlayers[author], "tag", sTagBuffer, sizeof(sTagBuffer)))
		{
			Format(sNameBuffer, sizeof(sNameBuffer), "%s%s", sTagBuffer, sNameBuffer);
			
			if (GetTrieString(g_aPlayers[author], "tagcolor", ColorCodes[1], sizeof(ColorCodes[])))
			{
				Format(sNameBuffer, sizeof(sNameBuffer), "%s%s", ColorCodes[1], sNameBuffer);
			}
		}
		
		if (StrContains(sNameBuffer, "{T}") != -1)
		{
			Color_ChatSetSubject(author);
		}
		index = Color_ParseChatText(sNameBuffer, name, MAXLENGTH_NAME);
		Color_ChatClearSubject();
		
		if (GetTrieString(g_aPlayers[author], "textcolor", ColorCodes[2], sizeof(ColorCodes[])))
		{
				decl String:sMessageBuffer[MAXLENGTH_INPUT];
				Format(sMessageBuffer, sizeof(sMessageBuffer), "%s%s", ColorCodes[2], message);	
				if (index == CHATCOLOR_NOSUBJECT)
				{
					index = Color_ParseChatText(sMessageBuffer, message, MAXLENGTH_INPUT);
				}
				else
				{
					Color_ChatSetSubject(index)
					Color_ParseChatText(sMessageBuffer, message, MAXLENGTH_INPUT);
					Color_ChatClearSubject();
				}
		}
		
		if (index != CHATCOLOR_NOSUBJECT)
		{
			author = index;
		}
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:Command_Reload(client, args)
{
	LOOP_CLIENTS(buffer, CLIENTFILTER_NOBOTS | CLIENTFILTER_INGAMEAUTH)
	{
		CheckPlayer(buffer);
	}
	LogAction(client, 0, "[SCC] Config file has been reloaded");
	ReplyToCommand(client, "[SCC] Config file has been reloaded");
	return Plugin_Handled;
}

public Action:Command_PrintColors(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "Command can only be ran while in game");
		return Plugin_Handled;
	}
	Client_PrintToChat(client, true, "{N}default/normal");
	Client_PrintToChat(client, true, "{O}orange");
	Client_PrintToChat(client, true, "{R}red (green if no player on red team)");
	Client_PrintToChat(client, true, "{RB}red/blue");
	Client_PrintToChat(client, true, "{B}blue (green if no player on blue team)");
	Client_PrintToChat(client, true, "{BR}blue/red");
	Color_ChatSetSubject(client);
	Client_PrintToChat(client, true, "{T}teamcolor");
	Color_ChatClearSubject();
	Client_PrintToChat(client, true, "{L}lightgreen");
	Client_PrintToChat(client, true, "{GRA}grey (green if no spectator)");
	Client_PrintToChat(client, true, "{G}green");
	Client_PrintToChat(client, true, "{OG}olive");
	Client_PrintToChat(client, true, "{BLA}black");
	return Plugin_Handled;
}

stock CheckPlayer(client)
{
	new String:sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/simple-chatcolors.cfg");
	
	if (g_aPlayers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_aPlayers[client]);
	}
	
	if (FileExists(sFile)) 
	{
		new Handle:hSettings = CreateKeyValues("Settings");
		FileToKeyValues(hSettings, sFile);
		KvGotoFirstSubKey(hSettings);

		decl String:sClientSteamID[64];
		GetClientAuthString(client, sClientSteamID, sizeof(sClientSteamID));
		
		do 
		{
			decl String:sSectionName[64];
			KvGetSectionName(hSettings, sSectionName, sizeof(sSectionName));
			if (StrContains(sSectionName, "STEAM_0:") != -1)
			{
				if (StrEqual(sSectionName, sClientSteamID))
				{
					g_aPlayers[client] = LoadPlayerTrie(client, hSettings);
					break;
				}
			}
			else
			{
				decl String:sFlags[15];
				KvGetString(hSettings, "flag", sFlags, sizeof(sFlags));
				new iGroupFlags = ReadFlagString(sFlags);
				if (iGroupFlags != 0 && CheckCommandAccess(client, "scc_colors", iGroupFlags, true))
				{
					g_aPlayers[client] = LoadPlayerTrie(client, hSettings);
					break;
				}
			}
		} while (KvGotoNextKey(hSettings));
		CloseHandle(hSettings);
	}
	else
	{
		LogError("[SCC] Simple Chat Colors is not running! Could not find file %s", sFile);
		SetFailState("Could not find file %s", sFile);
	}
}

stock Handle:LoadPlayerTrie(const client, const Handle:kv)
{
	new Handle:trie = CreateTrie();
	decl String:sSettings[4][32];
	KvGetString(kv, "tag", sSettings[0], sizeof(sSettings[]));
	KvGetString(kv, "tagcolor", sSettings[1], sizeof(sSettings[]));
	KvGetString(kv, "namecolor", sSettings[2], sizeof(sSettings[]));
	KvGetString(kv, "textcolor", sSettings[3], sizeof(sSettings[]));
	
	if (!IsStringBlank(sSettings[0]))
	{
		SetTrieString(trie, "tag", sSettings[0]);
	}
	
	if (!IsStringBlank(sSettings[1]))
	{
		SetTrieString(trie, "tagcolor", sSettings[1]);
	}
	
	if (!IsStringBlank(sSettings[2]))
	{
		SetTrieString(trie, "namecolor", sSettings[2]);
	}
	
	if (!IsStringBlank(sSettings[3]))
	{
		SetTrieString(trie, "textcolor", sSettings[3]);
	}
	return trie;
}

stock bool:IsStringBlank(const String:input[])
{
	new len = strlen(input);
	for (new i=0; i<len; i++)
	{
		if (!IsCharSpace(input[i]))
		{
			return false;
		}
	}
	return true;
}