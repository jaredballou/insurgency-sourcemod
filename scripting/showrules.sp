#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#define VERSION "1.5.1" 

new String:clientname[MAX_NAME_LENGTH];
new String:language[4];
new String:languagecode[4];
new String:playerid[MAXPLAYERS + 1][64];
new String:steamid[64];
new String:g_joinsound[PLATFORM_MAX_PATH];
new playeridcount = 0;
new NumTries = 1;
new g_expiration;
new UserMsg:g_VGUIMenu;
new bool:prevclient;
new bool:g_AdminChecked[MAXPLAYERS + 1];
new bool:g_CookiesCached[MAXPLAYERS + 1];
new bool:g_IntermissionCalled;
new bool:g_enabled;
new bool:g_showonjoin;
new bool:g_showtoadmins;
new bool:g_displayfailurekick;
new bool:g_showmenuoptions;
new g_menutime, g_displayattempts;
new Handle:g_Cvarenabled = INVALID_HANDLE;
new Handle:g_Cvarmenutime = INVALID_HANDLE;
new Handle:g_Cvarshowonjoin = INVALID_HANDLE;
new Handle:g_Cvarshowtoadmins = INVALID_HANDLE;
new Handle:g_Cvardisplayattempts = INVALID_HANDLE;
new Handle:g_Cvardisplayfailurekick = INVALID_HANDLE;
new Handle:g_Cvarshowmenuoptions = INVALID_HANDLE;
new Handle:g_Cvarjoinsound = INVALID_HANDLE;
new Handle:g_Cvarexpiration = INVALID_HANDLE;
new Handle:g_cookie = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Menu Based Rules",
	author = "XARiUS",
	description = "Display menu of rules to clients when they join a server, or by console command.",
	version = "1.5.1",
	url = "http://www.the-otc.com/"
};

public OnPluginStart()
{
  LoadTranslations("common.phrases");
  LoadTranslations("showrules.phrases");
  LoadTranslations("showrulesdata.phrases");
  g_cookie = RegClientCookie("showrules", "Rules Agreement Timestamp", CookieAccess_Protected);
  GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));
  CreateConVar("sm_showrules_version", VERSION, "Menu Rules Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_showrules_enabled", "1", "Enable this plugin.  0 = Disabled.");
  g_Cvarjoinsound = CreateConVar("sm_showrules_joinsound", "", "Sound file to play to connecting clients.  Relative to the sound/ folder.  Example: 'welcome.mp3' or 'mysounds/welcome.mp3'");
  g_Cvarmenutime = CreateConVar("sm_showrules_menutime", "120", "Time to display rules menu to client before dissolving (and kicking them).");
  g_Cvarshowonjoin = CreateConVar("sm_showrules_showonjoin", "1", "Display Rules menu to clients automatically upon joining the server.");
  g_Cvarshowtoadmins = CreateConVar("sm_showrules_showtoadmins", "0", "On join, display menu to admins.");
  g_Cvardisplayattempts = CreateConVar("sm_showrules_displayattempts", "20", "Number of times to attempt to display the rules menu. (3 second intervals)");
  g_Cvardisplayfailurekick = CreateConVar("sm_showrules_displayfailurekick", "1", "Kick the client if the rules cannot be displayed after defined display attempts.");
  g_Cvarshowmenuoptions = CreateConVar("sm_showrules_showmenuoptions", "1", "Shows agree/disagree options instead of a single option to close the rules menu.");
  g_Cvarexpiration = CreateConVar("sm_showrules_expiration", "24", "Number of hours before the previous terms agreement expires.");
  RegAdminCmd("sm_showrules", Command_rules, ADMFLAG_KICK, "sm_showrules <#userid|name>");

  HookConVarChange(g_Cvarenabled, OnSettingChanged);
  HookConVarChange(g_Cvarmenutime, OnSettingChanged);
  HookConVarChange(g_Cvarshowonjoin, OnSettingChanged);
  HookConVarChange(g_Cvarshowtoadmins, OnSettingChanged);
  HookConVarChange(g_Cvardisplayattempts, OnSettingChanged);
  HookConVarChange(g_Cvardisplayfailurekick, OnSettingChanged);
  HookConVarChange(g_Cvarshowmenuoptions, OnSettingChanged);
  HookConVarChange(g_Cvarexpiration, OnSettingChanged);
	
  g_VGUIMenu = GetUserMessageId("VGUIMenu");
  if (g_VGUIMenu == INVALID_MESSAGE_ID)
  {
    LogError("FATAL: Cannot find VGUIMenu user message id.");
    SetFailState("VGUIMenu Not Found");
  }
  HookUserMessage(g_VGUIMenu, UserMsg_VGUIMenu);

  AutoExecConfig(true, "showrules");
}

public OnConfigsExecuted()
{
  g_enabled = GetConVarBool(g_Cvarenabled);
  g_menutime = GetConVarInt(g_Cvarmenutime);
  g_showonjoin = GetConVarBool(g_Cvarshowonjoin);
  g_showtoadmins = GetConVarBool(g_Cvarshowtoadmins);
  g_displayattempts = GetConVarInt(g_Cvardisplayattempts);
  g_displayfailurekick = GetConVarBool(g_Cvardisplayfailurekick);
  g_showmenuoptions = GetConVarBool(g_Cvarshowmenuoptions);
  g_expiration = GetConVarInt(g_Cvarexpiration) * 3600;
  GetConVarString(g_Cvarjoinsound, g_joinsound, sizeof(g_joinsound));

  decl String:buffer[PLATFORM_MAX_PATH];
  if (!StrEqual(g_joinsound, "", false))
  {
    Format(buffer, PLATFORM_MAX_PATH, "sound/%s", g_joinsound);
    if (FileExists(buffer, false))
    {
      Format(buffer, PLATFORM_MAX_PATH, "%s", g_joinsound);
      if (!PrecacheSound(buffer, true))
      {
        LogError("Menu Based Rules: Could not pre-cache defined sound: %s", buffer);
        SetFailState("Menu Based Rules: Could not pre-cache sound: %s", buffer);
      }
      else
      {
        Format(buffer, PLATFORM_MAX_PATH, "sound/%s", g_joinsound);
        AddFileToDownloadsTable(buffer);
      }
    }
  }
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
  if (convar == g_Cvarmenutime)
  {
    g_menutime = StringToInt(newValue);
  }
  if (convar == g_Cvardisplayattempts)
  {
    g_displayattempts = StringToInt(newValue);
  }
  if (convar == g_Cvarexpiration)
  {
  g_expiration = StringToInt(newValue) * 3600;
  }
  if (convar == g_Cvarenabled)
  {
    if (newValue[0] == '1')
    {
			g_enabled = true;
    }
    else
    {
      g_enabled = false;
    }
  }
  if (convar == g_Cvardisplayfailurekick)
  {
    if (newValue[0] == '1')
    {
			g_displayfailurekick = true;
    }
    else
    {
      g_displayfailurekick = false;
    }
  }
  if (convar == g_Cvarshowmenuoptions)
  {
    if (newValue[0] == '1')
    {
			g_showmenuoptions = true;
    }
    else
    {
      g_showmenuoptions = false;
    }
  }
  if (convar == g_Cvarshowonjoin)
  {
    if (newValue[0] == '1')
    {
			g_showonjoin = true;
    }
    else
    {
      g_showonjoin = false;
    }
  }
  if (convar == g_Cvarshowtoadmins)
  {
    if (newValue[0] == '1')
    {
			g_showtoadmins = true;
    }
    else
    {
      g_showtoadmins = false;
    }
  }
}

public Action:PlayJoinSound(Handle:timer, any:client)
{
  if (!StrEqual(g_joinsound, ""))
  {
    EmitSoundToClient(client, g_joinsound);
  }
}

public Action:CheckForMenu(Handle:timer, any:client)
{
  if (GetClientMenu(client) == MenuSource_None && IsClientConnected(client) && IsClientInGame(client))
  {
    Show_Rules(client);
    NumTries = 1;
    return Plugin_Stop;
  } 
  else
  {
    if (NumTries++ >= g_displayattempts)
    {
      NumTries = 1;
      if (g_displayfailurekick)
      {
        CreateTimer(0.5, KickPlayer, client);
      }
      return Plugin_Stop;
    }
  }
  return Plugin_Continue;
}

public OnMapEnd()
{
	g_IntermissionCalled = false;
}

public Action:UserMsg_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
  if (g_IntermissionCalled)
  {
    return Plugin_Handled;
  }
  
  decl String:type[15];

  /* If we don't get a valid string, bail out. */
  if (BfReadString(bf, type, sizeof(type)) < 0)
  {
    return Plugin_Handled;
  }
 
  if (BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && (strcmp(type, "scores", false) == 0))
  {
    g_IntermissionCalled = true;

    new maxplayers = GetMaxClients();
    playeridcount = 0;

    for (new i = 1; i <= maxplayers; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthString(i, playerid[playeridcount], sizeof(playerid[]))) {
            playeridcount++;
        }
      }
  }
  return Plugin_Handled;
}

public CheckCookies(client)
{
  g_AdminChecked[client] = false;
  g_CookiesCached[client] = false;
  new String:cookie[64];
  GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
  if (StrEqual(cookie, ""))
  {
    CreateTimer(3.0, CheckForMenu, client, TIMER_REPEAT);
  }
  else
  {
    new timestamp;
    timestamp = StringToInt(cookie);
    if ((GetTime() - timestamp) > g_expiration)
    {
      CreateTimer(3.0, CheckForMenu, client, TIMER_REPEAT);
    }
  }
}

public OnClientCookiesCached(client)
{
  g_CookiesCached[client] = true;
  if (g_AdminChecked[client])
  {
    CheckCookies(client);
  }
}
public OnClientPostAdminCheck(client)
{
  if (g_enabled)
  {
    if (g_showonjoin && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client))
    {
      GetClientName(client, clientname, sizeof(clientname));
      if (!g_showtoadmins)
      {
        new AdminId:isadmin = GetUserAdmin(client);
        if (isadmin != INVALID_ADMIN_ID)
        {
          return;
        }
      }
      g_AdminChecked[client] = true;
      // Search through playerid array to see if user was here for map change.
      prevclient = false;
      GetClientAuthString(client, steamid, 64);
      playeridcount = 0;
      new maxplayers = GetMaxClients();
      for (new i = 1; i <= maxplayers; i++) 
      {
        if (StrEqual(steamid,playerid[playeridcount]))
        {
          prevclient = true;
          return;
        } else {
          playeridcount++;
        }
      }
      if (!prevclient)
      {
        CreateTimer(1.0, PlayJoinSound, client);
      }
      if (g_CookiesCached[client])
      {
        CheckCookies(client);
      }
    }
    return;
  }
}

public Action:Command_rules(client, args)
{
  new String:arg1[32];
  GetCmdArg(1,arg1, sizeof(arg1));
  
  if (args < 1)
  {
    ReplyToCommand(client, "[SM] Usage: sm_showrules <#userid|name>");
    return Plugin_Handled;
  }

  decl String:Arguments[256];
  GetCmdArgString(Arguments, sizeof(Arguments));
  decl String:arg[65];
  new len = BreakString(Arguments, arg, sizeof(arg));

  if (len == -1)
  {
    len = 0;
    Arguments[0] = '\0';
  }

  decl String:target_name[MAX_TARGET_LENGTH];
  decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

  if ((target_count = ProcessTargetString(arg,client,target_list,MAXPLAYERS,COMMAND_FILTER_CONNECTED,target_name,sizeof(target_name),tn_is_ml)) <= 0)
  {
    ReplyToTargetError(client, target_count);
    return Plugin_Handled;
  }
  
  for (new i = 0; i < target_count; i++)
  {
    if (!IsClientConnected(target_list[i]) || IsFakeClient(target_list[i]) || !IsClientInGame(target_list[i]))
    {
      ReplyToCommand(client,"[SM] Client %s has not finished connecting or is timing out.  Please try again.", target_name);
      return Plugin_Handled;
    }
    else
    {
      if (GetClientMenu(target_list[i]) == MenuSource_None)
      {
        Show_Rules(target_list[i]);
      } else
      {
        CreateTimer(3.0, CheckForMenu, target_list[i], TIMER_REPEAT);
      }
      ReplyToCommand(client,"[SM] %t %s", "Client Command Success", target_name);
    }
  }
  return Plugin_Handled;
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
    if (param2 == 1)
    {
      if (g_showmenuoptions)
      {
        new String:timestamp[64];
        IntToString(GetTime(), timestamp, sizeof(timestamp));
        SetClientCookie(param1, g_cookie, timestamp);
        PrintToChat(param1,"[SM] %t", "Player agrees to rules");
      }
    }
    else
    {
      PrintToChatAll("[SM] %s %t", clientname, "Player disagreed public");
      CreateTimer(0.5, KickPlayer, param1);
    }
  }
	else if (action == MenuAction_Cancel)
  {
    if (param2 == -1) // -1 = Client disconnected
    {
      return;
    } 
    else if (param2 == -5) // -5 = Menu Timeout
    {
      CreateTimer(0.5, KickPlayer, param1); 
    }
    else if ((param2 == -4 || param2 == -2)) // -4 = Unable to display panel | -2 = Interrupted by another menu
    {
      CreateTimer(3.0, CheckForMenu, param1, TIMER_REPEAT);
    } 
  }
}

public Action:KickPlayer(Handle:timer, any:param1)
{
  if (IsClientInGame(param1))
  {
    GetClientName(param1, clientname, sizeof(clientname));
    KickClient(param1, "%t", "Player disagrees to rules");
    LogMessage("%t %s", "Log kick message", clientname);
  }
  return Plugin_Handled;
}
 
public Action:Show_Rules(client)
{
  new String:title[128];
  new String:question[128];
  new String:yes[128];
  new String:no[128];
  new String:close[128];
  new String:ruleData[10][512];
  new Handle:panel = CreatePanel();
  Format(title,127, "%T", "Rules menu title", client);
  Format(question,127, "%T", "Agree Question", client);
  Format(yes,127, "%T", "Yes Option", client);
  Format(no,127, "%T", "No Option", client);
  Format(close,127, "%T", "Close Option", client);
  Format(ruleData[0], 512, "%T", "Rule Line 1", client);
  Format(ruleData[1], 512, "%T", "Rule Line 2", client);
  Format(ruleData[2], 512, "%T", "Rule Line 3", client);
  Format(ruleData[3], 512, "%T", "Rule Line 4", client);
  Format(ruleData[4], 512, "%T", "Rule Line 5", client);
  Format(ruleData[5], 512, "%T", "Rule Line 6", client);
  Format(ruleData[6], 512, "%T", "Rule Line 7", client);
  Format(ruleData[7], 512, "%T", "Rule Line 8", client);
  Format(ruleData[8], 512, "%T", "Rule Line 9", client);
  Format(ruleData[9], 512, "%T", "Rule Line 10", client);
  
  SetPanelTitle(panel,title);
  DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
  for (new i = 0; i <= 9; i++)
  {
    if (strlen(ruleData[i]) > 1)
    {
      DrawPanelText(panel, ruleData[i]);
    }
  }
  DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
  if (g_showmenuoptions)
  {
    DrawPanelText(panel,question);
    DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    DrawPanelItem(panel,yes);
    DrawPanelItem(panel,no);
  }
  else
  {
    DrawPanelItem(panel,close);
  }
  SendPanelToClient(panel, client, PanelHandler, g_menutime);
  CloseHandle(panel);
  return Plugin_Handled;
}
