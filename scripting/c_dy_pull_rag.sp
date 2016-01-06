//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <updater>
#include <sdktools> 
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#define IN_SPEED        (1 << 17)
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Plugin for Pulling prop_ragdoll bodies"

#define MAX_BUTTONS 25
new g_LastButtons[MAXPLAYERS+1];

public Plugin:myinfo = {
        name        = "[INS] Pull Rag",
        author      = "Daimyo",
        description = PLUGIN_DESCRIPTION,
        version     = PLUGIN_VERSION,
        url         = ""
};

public OnPluginStart()
{

    HookEvent("player_disconnect", Event_PlayerDisconnect_Post, EventHookMode_Post);
}


public Action:Event_PlayerDisconnect_Post(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_LastButtons[client] = 0;
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
  for (new i = 0; i < MAX_BUTTONS; i++)
  {
      new button = (1 << i);
      
      if ((buttons & button)) { 
          if (!(g_LastButtons[client] & button)) { 
              OnButtonPress(client, button); 
          } 
      } else if ((g_LastButtons[client] & button)) { 
          OnButtonRelease(client, button); 
      }  
  }
    
    g_LastButtons[client] = buttons;
    
    return Plugin_Continue;
}


OnButtonPress(client, button)
{
   if(button == (1 << 17))
    // do stuff
}

OnButtonRelease(client, button)
{
    // do stuff
}