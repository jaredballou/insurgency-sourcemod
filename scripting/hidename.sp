/*
	Revision 1.1.7
	----------------
	Hook for "player_changename" event now returns Plugin_Handled if sm_hidename_hide_gagged is enabled.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <scp>

#define PLUGIN_VERSION "1.1.7"

#define MODE_COMMAND 0
#define MODE_WITH 1
#define MODE_WITHOUT 2
#define MODE_ALL 3

new bool:g_bIgnoreChange[MAXPLAYERS + 1];
new bool:g_bHideChange[MAXPLAYERS + 1];
new String:g_sName[MAXPLAYERS + 1][32];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hHideAll = INVALID_HANDLE;
new Handle:g_hRevertAll = INVALID_HANDLE;
new Handle:g_hHideGagged = INVALID_HANDLE;
new Handle:g_hRevertGagged = INVALID_HANDLE;
new Handle:g_hHideFlag = INVALID_HANDLE;

new bool:g_bLateLoad, bool:g_bEnabled, bool:g_bHideAll, bool:g_bRevertAll, bool:g_bHideGagged, bool:g_bRevertGagged;
new g_iFlag;
new String:g_sPrefixChat[32];

public Plugin:myinfo = 
{
	name = "[INS] Hide Name Changes",
	author = "Twisted|Panda",
	description = "Provides support for hiding name changes from chat for all players/specific players/gagged players, as well as reverting name changes for all players or only gagged players.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{	
	PrintToServer("[HIDENAME] starting");
	LoadTranslations("common.phrases");
	LoadTranslations("sm_hidename.phrases");

	CreateConVar("sm_hidename_version", PLUGIN_VERSION, "Hide Name Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_hidename_enabled", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hHideAll = CreateConVar("sm_hidename_hide_all", "1", "If enabled, players will have their name changes hidden from chat, regardless of other settings provided by this plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hHideAll, OnSettingsChange);
	g_hRevertAll = CreateConVar("sm_hidename_revert_all", "0", "If enabled, players will be unable to change their name while in the server, regardless of other settings provided by this plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hHideAll, OnSettingsChange);
	
	g_hHideGagged = CreateConVar("sm_hidename_hide_gagged", "1", "If enabled, players that are currently gagged will have their name changes hidden from chat. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hHideGagged, OnSettingsChange);
	g_hRevertGagged = CreateConVar("sm_hidename_revert_gagged", "1", "If enabled, players that are currently gagged will be unable to change their name while in the server. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hRevertGagged, OnSettingsChange);
	g_hHideFlag = CreateConVar("sm_hidename_hide_flag", "b", "Players that possess this flag, or the \"hide_name_changes\" override, will have their name changes hidden from chat. (\"\" = Disabled)", FCVAR_NONE);
	HookConVarChange(g_hHideFlag, OnSettingsChange);
	AutoExecConfig(true, "sm_hidename");

	HookEvent("player_changename", Event_OnNameChange);
	RegAdminCmd("sm_hidename", Command_Hide, ADMFLAG_KICK);

	HookUserMessage(GetUserMessageId("SayText"), UserMessageHook, true);
	HookUserMessage(GetUserMessageId("SayText2"), UserMessageHook, true);
	HookUserMessage(GetUserMessageId("HintText"), UserMessageHook, true);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook, true);
	HookUserMessage(GetUserMessageId("GameMessage"), UserMessageHook, true);

	Void_SetDefaults();
	PrintToServer("[HIDENAME] Initialized");
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, sizeof(g_sPrefixChat), "%T", "Prefix_Chat", LANG_SERVER);

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(CheckCommandAccess(i, "hide_name_changes", ADMFLAG_ROOT))
						g_bHideChange[i] = true;
					else
					{
						new _iBits = GetUserFlagBits(i);
						if(_iBits && _iBits & g_iFlag)
							g_bHideChange[i] = true;
					}

					GetClientName(i, g_sName[i], sizeof(g_sName[]));
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(client && g_bEnabled)
	{
		if(CheckCommandAccess(client, "hide_name_changes", ADMFLAG_ROOT))
			g_bHideChange[client] = true;
		else
		{
			new _iBits = GetUserFlagBits(client);
			if(_iBits && _iBits & g_iFlag)
				g_bHideChange[client] = true;
		}
	}
}

public OnClientConnected(client)
{
	if(client && g_bEnabled)
	{
		GetClientName(client, g_sName[client], sizeof(g_sName[]));
	}
}

public OnClientDisconnect(client)
{
	if(client && g_bEnabled)
	{
		g_bHideChange[client] = false;
		g_bIgnoreChange[client] = false;
	}
}

public Action:Event_OnNameChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("[HIDENAME] Called Event_OnNameChange");
	if(g_bEnabled)
	{
		PrintToServer("[HIDENAME] Enabled");
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		PrintToServer("[HIDENAME] Testing user %d",client);

		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;
		if (IsFakeClient(client)) {
			PrintToServer("[HIDENAME] Bot, stop");
			return Plugin_Handled;
		}
		if(g_bRevertAll)
			return Plugin_Continue;
		else if(g_bRevertGagged && BaseComm_IsClientGagged(client))
		{
			if(g_bHideGagged)
				return Plugin_Handled;
			else
				return Plugin_Continue;
		}

		GetEventString(event, "newname", g_sName[client], 32);
	}
	PrintToServer("[HIDENAME] Continue");

	return Plugin_Continue;
}

public Action:Command_Hide(client, args)
{
	if(g_bEnabled)
	{
		if(args < 2)
		{
			ReplyToCommand(client, "%s%t", g_sPrefixChat, "Phrase_Missing_Parameters");
			return Plugin_Handled;
		}

		new _iTargets[64], bool:_bTemp;
		decl String:_sTargets[64], String:_sBuffer[64], String:_sState[4];
		GetCmdArg(1, _sTargets, sizeof(_sTargets));
		GetCmdArg(2, _sState, sizeof(_sState));
		new bool:_bStatus = StringToInt(_sState) ? true : false;

		new _iTemp = ProcessTargetString(_sTargets, client, _iTargets, sizeof(_iTargets), 0, _sBuffer, sizeof(_sBuffer), _bTemp);
		for (new i = 0; i < _iTemp; i++)
		{
			if(IsClientInGame(_iTargets[i]))
			{
				if(!CanUserTarget(client, _iTargets[i]))
					ReplyToCommand(client, "%s%t", g_sPrefixChat, "Phrase_Target_Immunity");
				else
				{
					if(_bStatus)
					{
						if(g_bHideChange[_iTargets[i]])
							ReplyToCommand(client, "%s%t", g_sPrefixChat, "Phrase_Changes_Already_Hidden", _iTargets[i]);
						else
						{
							g_bHideChange[_iTargets[i]] = _bStatus;
							ShowActivity2(client, g_sPrefixChat, "%t", "Phrase_Changes_Now_Hidden", _iTargets[i]);
						}
					}
					else
					{
						if(!g_bHideChange[_iTargets[i]])
							ReplyToCommand(client, "%s%t", g_sPrefixChat, "Phrase_Changes_Already_Visible", _iTargets[i]);
						else
						{
							g_bHideChange[_iTargets[i]] = _bStatus;
							ShowActivity2(client, g_sPrefixChat, "%t", "Phrase_Changes_Now_Visible", _iTargets[i]);
						}
					}
				}
			}
		}
	}

	return Plugin_Handled;
}

public Action:UserMessageHook(UserMsg:msg_hd, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
//	PrintToServer("[HIDENAME] Called UserMessageHook");

	if(g_bEnabled)
	{
		new bool:_bHideRevert = false;
		decl String:_sMessage[96];
		BfReadString(bf, _sMessage, sizeof(_sMessage));
		PrintToServer("[HIDENAME] 1 sMessage is %s",_sMessage);
		BfReadString(bf, _sMessage, sizeof(_sMessage));
		PrintToServer("[HIDENAME] 2 sMessage is %s",_sMessage);
		
		if(StrContains(_sMessage, "Name_Change") != -1)
		{
			BfReadString(bf, _sMessage, sizeof(_sMessage));
			PrintToServer("[HIDENAME] 3 sMessage is %s",_sMessage);
	
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && StrEqual(_sMessage, g_sName[i]))
				{
					new bool:_bActiveGag = BaseComm_IsClientGagged(i);
					if(g_bIgnoreChange[i])
					{
						_bHideRevert = true;
						g_bIgnoreChange[i] = false;
					}
					else if((g_bRevertAll || g_bRevertGagged && _bActiveGag))
					{
						_bHideRevert = true;
						CreateTimer(0.1, Timer_Revert, i, TIMER_FLAG_NO_MAPCHANGE);
					}

					if(g_bHideAll || g_bHideGagged && _bActiveGag || g_bHideChange[i] || _bHideRevert)
						return Plugin_Handled;

					return Plugin_Continue;
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_Revert(Handle:timer, any:client)
{
	g_bIgnoreChange[client] = true;

	SetClientInfo(client, "name", g_sName[client]);
	SetEntPropString(client, Prop_Data, "m_szNetname", g_sName[client]);
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bHideAll = GetConVarInt(g_hHideAll) ? true : false;
	g_bRevertAll = GetConVarInt(g_hRevertAll) ? true : false;
	g_bHideGagged = GetConVarInt(g_hHideGagged) ? true : false;
	g_bRevertGagged = GetConVarInt(g_hRevertGagged) ? true : false;
	
	decl String:_sBuffer[32];
	GetConVarString(g_hHideFlag, _sBuffer, sizeof(_sBuffer));
	g_iFlag = ReadFlagString(_sBuffer);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hHideAll)
		g_bHideAll = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hRevertAll)
		g_bRevertAll = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hHideFlag)
		g_iFlag = ReadFlagString(newvalue);
	else if(cvar == g_hHideGagged)
		g_bHideGagged = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hRevertGagged)
		g_bRevertGagged = StringToInt(newvalue) ? true : false;
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
	if (!g_hEnabled)
	{
		return Plugin_Continue;
	}
	new chatflags = GetMessageFlags();
	PrintToServer("[NMChat] author %d name %s message %s flags %d",author,name,message,chatflags);
/*	
	if ((chatflags & CHATFLAGS_TEAM) || (!GetConVarBool(cvarTeamOnly))) {
		new index = CHATCOLOR_NOSUBJECT;
		decl String:sNameBuffer[MAXLENGTH_NAME],Float:flEyePos[3],String:sGridPos[16],String:sPlace[64],sDistance[64];
	        GetClientEyePosition(author, flEyePos);
		GetPlaceName(flEyePos,sPlace,sizeof(sPlace));
	        GetGridPos(flEyePos,sGridPos,sizeof(sGridPos));
		Format(sNameBuffer, sizeof(sNameBuffer), "%s%s{T}%s", sGridPos, sPlace, name);
		Color_ChatSetSubject(author);
		index = Color_ParseChatText(sNameBuffer, name, MAXLENGTH_NAME);
		Color_ChatClearSubject();
		author = index;
		return Plugin_Changed;
	}
*/
	return Plugin_Continue;
}
