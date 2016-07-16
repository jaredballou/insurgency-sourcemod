#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo = 
{
	name = "Show Health",
	author = "exvel",
	description = "Shows your health on the screen",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new Handle:cvar_show_health = INVALID_HANDLE;
new Handle:cvar_show_health_on_hit_only = INVALID_HANDLE;
new Handle:cvar_show_health_text_area = INVALID_HANDLE;

new bool:show_health = true;
new bool:show_health_on_hit_only = true;
new show_health_text_area = 1;

new bool:option_show_health[MAXPLAYERS + 1] = {true,...};
new Handle:cookie_show_health = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_show_health_version", PLUGIN_VERSION, "Show Health Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_show_health = CreateConVar("sm_show_health", "1", "Enabled/Disabled show health functionality, 0 = off/1 = on",, true, 0.0, true, 1.0);
	cvar_show_health_on_hit_only = CreateConVar("sm_show_health_on_hit_only", "1", "Defines the weather when to show a health text:\n0 = always show your health on a screen\n1 = show your health only when somebody hit you",, true, 0.0, true, 1.0);
	cvar_show_health_text_area = CreateConVar("sm_show_health_text_area", "1", "Defines the area for health text:\n 1 = in the hint text area\n 2 = in the center of the screen",, true, 1.0, true, 2.0);
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	HookConVarChange(cvar_show_health, OnCVarChange);
	HookConVarChange(cvar_show_health_on_hit_only, OnCVarChange);
	HookConVarChange(cvar_show_health_text_area, OnCVarChange);
	
	AutoExecConfig(true, "plugin.showhealth");
	LoadTranslations("common.phrases");
	LoadTranslations("showhealth.phrases");
	
	cookie_show_health = RegClientCookie("Show Health On/Off", "", CookieAccess_Private);
	SetCookieMenuItem(CookieMenuHandler_ShowHealth, 0, "Show Health");
	
	CreateTimer(1.5, RefreshHealthText, _, TIMER_REPEAT);
}

public CookieMenuHandler_ShowHealth(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		decl String:status[10];
		if (option_show_health[client])
		{
			Format(status, sizeof(status), "%T", "On", client);
		}
		else
		{
			Format(status, sizeof(status), "%T", "Off", client);
		}
		
		Format(buffer, maxlen, "%T: %s", "Cookie Show Health", client, status);
	}
	// CookieMenuAction_SelectOption
	else
	{
		option_show_health[client] = !option_show_health[client];
		
		if (option_show_health[client])
		{
			SetClientCookie(client, cookie_show_health, "On");
		}
		else
		{
			SetClientCookie(client, cookie_show_health, "Off");
		}
		
		ShowCookieMenu(client);
	}
}

public OnClientCookiesCached(client)
{
	option_show_health[client] = GetCookieShowHealth(client);
}

bool:GetCookieShowHealth(client)
{
	decl String:buffer[10];
	GetClientCookie(client, cookie_show_health, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

public OnConfigsExecuted()
{
	GetCVars();
}

public Action:RefreshHealthText(Handle:timer)
{
	if (!show_health || show_health_on_hit_only)
	{
		return;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client))
		{
			ShowHealth(client, GetClientHealth(client));
		}
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!show_health)
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new health = GetEventInt(event, "health");
	
	if (health > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		ShowHealth(client, health);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!show_health)
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0)
		return Plugin_Continue;
	
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		ShowHealth(client, 0);
	}
	
	return Plugin_Continue;
}

public ShowHealth(client, health)
{
	if (!option_show_health[client])
		return;
	
	switch (show_health_text_area)
	{
		case 1:
		{
			PrintHintText(client, "%t", "HintText Health Text", health);
		}
		
		case 2:
		{
			PrintCenterText(client, "%t", "CenterText Health Text", health);
		}
	}
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public GetCVars()
{
	show_health = GetConVarBool(cvar_show_health);
	show_health_on_hit_only = GetConVarBool(cvar_show_health_on_hit_only);
	show_health_text_area = GetConVarInt(cvar_show_health_text_area);
}
