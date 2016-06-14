#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION				"2.3"

public Plugin:myinfo = 
{
	name = "Web Shortcuts CS:GO version",
	author = "Franc1sco franug and James \"sslice\" Gray",
	description = "Provides chat-triggered web shortcuts",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug/"
};

new Handle:g_Shortcuts;
new Handle:g_Titles;
new Handle:g_Links;

new String:g_ServerIp [32];
new String:g_ServerPort [16];

public OnPluginStart()
{
	CreateConVar( "sm_webshortcutscsgo_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED );
	
	RegConsoleCmd( "say", OnSay );
	RegConsoleCmd( "say_team", OnSay );
	
	RegAdminCmd("sm_web", Command_Web, ADMFLAG_GENERIC,"Open URL for target");
	
	g_Shortcuts = CreateArray( 32 );
	g_Titles = CreateArray( 64 );
	g_Links = CreateArray( 512 );
	
	new Handle:cvar = FindConVar( "hostip" );
	new hostip = GetConVarInt( cvar );
	FormatEx( g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
		(hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF );
	
	cvar = FindConVar( "hostport" );
	GetConVarString( cvar, g_ServerPort, sizeof(g_ServerPort) );
	
	LoadWebshortcuts();
}
 
public OnMapEnd()
{
	LoadWebshortcuts();
}
 
public Action:OnSay( client, args )
{
	if(!client) return Plugin_Continue;	
	
	
	decl String:text [512];
	GetCmdArgString( text, sizeof(text) );
	
	new start;
	new len = strlen(text);
	if ( text[len-1] == '"' )
	{
		text[len-1] = '\0';
		start = 1;
	}
	
	decl String:shortcut [32];
	BreakString( text[start], shortcut, sizeof(shortcut) );
	
	new size = GetArraySize( g_Shortcuts );
	for (new i; i != size; ++i)
	{
		GetArrayString( g_Shortcuts, i, text, sizeof(text) );
		
		if ( strcmp( shortcut, text, false ) == 0 )
		{
			QueryClientConVar(client, "cl_disablehtmlmotd", ConVarQueryFinished:ClientConVar, client);
			
			decl String:title [256];
			decl String:steamId [64];
			decl String:userId [16];
			decl String:name [64];
			decl String:clientIp [32];
			
			GetArrayString( g_Titles, i, title, sizeof(title) );
			GetArrayString( g_Links, i, text, sizeof(text) );
			
			//GetClientAuthString( client, steamId, sizeof(steamId) );
			GetClientAuthId(client, AuthId_Steam2,  steamId, sizeof(steamId) );
			FormatEx( userId, sizeof(userId), "%u", GetClientUserId( client ) );
			GetClientName( client, name, sizeof(name) );
			GetClientIP( client, clientIp, sizeof(clientIp) );
			
/* 			ReplaceString( title, sizeof(title), "{SERVER_IP}", g_ServerIp);
			ReplaceString( title, sizeof(title), "{SERVER_PORT}", g_ServerPort);
			ReplaceString( title, sizeof(title), "{STEAM_ID}", steamId);
			ReplaceString( title, sizeof(title), "{USER_ID}", userId);
			ReplaceString( title, sizeof(title), "{NAME}", name);
			ReplaceString( title, sizeof(title), "{IP}", clientIp); */
			
			ReplaceString( text, sizeof(text), "{SERVER_IP}", g_ServerIp);
			ReplaceString( text, sizeof(text), "{SERVER_PORT}", g_ServerPort);
			ReplaceString( text, sizeof(text), "{STEAM_ID}", steamId);
			ReplaceString( text, sizeof(text), "{USER_ID}", userId);
			ReplaceString( text, sizeof(text), "{NAME}", name);
			ReplaceString( text, sizeof(text), "{IP}", clientIp);
			
			if(StrEqual(title, "none", false))
			{
				StreamPanel("Webshortcuts", text, client);
			}
			else if(StrEqual(title, "full", false))
			{
				FixMotdCSGO_fullsize(text);
				ShowMOTDPanel( client, "Script by Franc1sco franug", text, MOTDPANEL_TYPE_URL );
			}
			else
			{
				FixMotdCSGO(text, title);
				ShowMOTDPanel( client, "Script by Franc1sco franug", text, MOTDPANEL_TYPE_URL );
			}
		}
	}
	
	return Plugin_Continue;	
}
 
LoadWebshortcuts()
{
	decl String:buffer [1024];
	BuildPath( Path_SM, buffer, sizeof(buffer), "configs/webshortcuts.txt" );
	
	if ( !FileExists( buffer ) )
	{
		return;
	}
 
	new Handle:f = OpenFile( buffer, "r" );
	if ( f == INVALID_HANDLE )
	{
		LogError( "[SM] Could not open file: %s", buffer );
		return;
	}
	
	ClearArray( g_Shortcuts );
	ClearArray( g_Titles );
	ClearArray( g_Links );
	
	decl String:shortcut [32];
	decl String:title [256];
	decl String:link [512];
	while ( !IsEndOfFile( f ) && ReadFileLine( f, buffer, sizeof(buffer) ) )
	{
		TrimString( buffer );
		if ( buffer[0] == '\0' || buffer[0] == ';' || ( buffer[0] == '/' && buffer[1] == '/' ) )
		{
			continue;
		}
		
		new pos = BreakString( buffer, shortcut, sizeof(shortcut) );
		if ( pos == -1 )
		{
			continue;
		}
		
		new linkPos = BreakString( buffer[pos], title, sizeof(title) );
		if ( linkPos == -1 )
		{
			continue;
		}
		
		strcopy( link, sizeof(link), buffer[linkPos+pos] );
		TrimString( link );
		
		PushArrayString( g_Shortcuts, shortcut );
		PushArrayString( g_Titles, title );
		PushArrayString( g_Links, link );
	}
	
	CloseHandle( f );
}

public Action:Command_Web(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_web <target> <url>");
		return Plugin_Handled;
	}
	decl String:pattern[96], String:buffer[64], String:url[512];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, url, sizeof(url));
	new targets[129], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), 0, buffer, sizeof(buffer), ml);

	if(StrContains(url, "http://", false) != 0) Format(url, sizeof(url), "http://%s", url);
	FixMotdCSGO(url,"height=720,width=1280");
	
	if (count <= 0) ReplyToCommand(client, "Bad target");
	else for (new i = 0; i < count; i++)
	{
		ShowMOTDPanel(targets[i], "Web Shortcuts", url, MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}

public StreamPanel(String:title[], String:url[], client) {
	new Handle:Radio = CreateKeyValues("data");
	KvSetString(Radio, "title", title);
	KvSetString(Radio, "type", "2");
	KvSetString(Radio, "msg", url);
	ShowVGUIPanel(client, "info", Radio, false);
	CloseHandle(Radio);
}

stock FixMotdCSGO(String:web[512], String:title[256])
{
	Format(web, sizeof(web), "http://claninspired.com/franug/webshortcuts2.php?web=%s;franug_is_pro;%s", title,web);
}

stock FixMotdCSGO_fullsize(String:web[512])
{
	Format(web, sizeof(web), "http://claninspired.com/franug/webshortcuts_f.html?web=%s", web);
}

public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (StringToInt(cvarValue) > 0)
	{
		PrintToChat(client, "---------------------------------------------------------------");
		PrintToChat(client, "You have cl_disablehtmlmotd to 1 and for that reason webshortcuts plugin dont work for you");
		PrintToChat(client, "Please, put this in your console: cl_disablehtmlmotd 0");
		PrintToChat(client, "---------------------------------------------------------------");
	}
}
