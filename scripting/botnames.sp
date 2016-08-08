#include <sourcemod>
#include <sdktools>
#include <insurgency>

#pragma semicolon 1
#pragma unused cvarVersion

#define PLUGIN_DESCRIPTION "Gives automatic names to bots on creation."
#define PLUGIN_NAME "Bot Names"
#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "BOTNAMES"
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};
#define BOT_NAME_PATH "configs/botnames"

// this array will store the names loaded
new Handle:bot_names;

// this array will have a list of indexes to
// bot_names, use these in order


new Handle:name_redirects;

// this is the next index to use into name_redirects
// update this each time you use a name
new next_index;

// various convars
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarPrefix = INVALID_HANDLE; // bot name prefix
new Handle:cvarRandom = INVALID_HANDLE; // use random-order names?
new Handle:cvarNameList = INVALID_HANDLE; // list to use
new Handle:cvarAnnounce = INVALID_HANDLE; // announce new bots?
new Handle:cvarSuppress = INVALID_HANDLE; // supress join/team/namechange messages?

// called when the plugin loads
public OnPluginStart()
{
	// cvars!
	cvarVersion = CreateConVar("sm_botnames_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_botnames_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY);
	cvarPrefix = CreateConVar("sm_botnames_prefix", "", "sets a prefix for bot names (include a trailing space, if needed!)", FCVAR_NOTIFY);
	cvarRandom = CreateConVar("sm_botnames_random", "1", "sets whether to randomize names used", FCVAR_NOTIFY);
	cvarAnnounce = CreateConVar("sm_botnames_announce", "0", "sets whether to announce bots when added", FCVAR_NOTIFY);
	cvarSuppress = CreateConVar("sm_botnames_suppress", "1", "sets whether to supress join/team change/name change bot messages", FCVAR_NOTIFY);
	cvarNameList = CreateConVar("sm_botnames_list", "default", "Set list to use for bots", FCVAR_NOTIFY);	

	// hook team change, connect to supress messages
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Pre);

	// register our commands
	RegServerCmd("sm_botnames_reload", Command_Reload);
	RegServerCmd("sm_botnames_rename_all", Command_Rename_All);

	AutoExecConfig();
	HookUpdater();
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
}

public OnMapStart()
{
	ReloadNames();
	GenerateRedirects();
}

// a function to generate name_redirects
GenerateRedirects()
{
	new loaded_names = GetArraySize(bot_names);

	if (name_redirects != INVALID_HANDLE)
	{
		ResizeArray(name_redirects, loaded_names);
	} else {
		name_redirects = CreateArray(1, loaded_names);
	}

	for (new i = 0; i < loaded_names; i++)
	{
		SetArrayCell(name_redirects, i, i);
		
		// nothing to do random-wise if i == 0
		if (i == 0)
		{
			continue;
		}

		// now to introduce some chaos
		if (GetConVarBool(cvarRandom))
		{
			SwapArrayItems(name_redirects, GetRandomInt(0, i - 1), i);
		}
	}
}

// a function to load data into bot_names
ReloadNames()
{
	next_index = 0;
	decl String:path[PLATFORM_MAX_PATH],String:basepath[PLATFORM_MAX_PATH],String:filename[32];
	GetConVarString(cvarNameList,filename,sizeof(filename));
	BuildPath(Path_SM, basepath, sizeof(basepath), BOT_NAME_PATH);
	Format(path, sizeof(path), "%s/%s.txt", basepath, filename);
	if (!FileExists(path)) {
		PrintToServer("[BOTNAMES]: Cannot find %s, using default!",path);
		Format(path, sizeof(path), "%s/%s.txt", basepath, "default");
	}
	
	if (bot_names != INVALID_HANDLE)
	{
		ClearArray(bot_names);
	} else {
		bot_names = CreateArray(MAX_NAME_LENGTH);
	}
	
	new Handle:file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
	{
		PrintToServer("[BOTNAMES] Cannot open %s",path);
		return;
	}
	
	// this LENGTH*3 is sort of a hack
	// don't make long lines, people!
	decl String:newname[MAX_NAME_LENGTH*3];
	decl String:formedname[MAX_NAME_LENGTH];
	decl String:prefix[MAX_NAME_LENGTH];

	GetConVarString(cvarPrefix, prefix, MAX_NAME_LENGTH);

	while (IsEndOfFile(file) == false)
	{
		if (ReadFileLine(file, newname, sizeof(newname)) == false)
		{
			break;
		}
		
		// trim off comments starting with // or #
		new commentstart;
		commentstart = StrContains(newname, "//");
		if (commentstart != -1)
		{
			newname[commentstart] = 0;
		}
		commentstart = StrContains(newname, "#");
		if (commentstart != -1)
		{
			newname[commentstart] = 0;
		}
		
		new length = strlen(newname);
		if (length < 2)
		{
			// we loaded a bum name
			// (that is, blank line or 1 char == bad)
			//PrintToServer("bum name");
			continue;
		}

		// get rid of pesky whitespace
		TrimString(newname);
		
		Format(formedname, MAX_NAME_LENGTH, "%s%s", prefix, newname);
		PushArrayString(bot_names, formedname);
	}
	
	CloseHandle(file);
}


// reload bot name, via console
public Action:Command_Reload(args)
{
	ReloadNames();
	GenerateRedirects();
	PrintToServer("[botnames] Loaded %i names.", GetArraySize(bot_names));
}
public Action:Command_Rename_All(args)
{
//	Command_Reload(args);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
		{
			RenameBot(i);
		}
	}
}

// handle client connection, to change the names...
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	return RenameBot(client);
}
public bool:RenameBot(client)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new loaded_names = GetArraySize(bot_names);
	if (IsFakeClient(client) && loaded_names != 0)
	{
		// we got a bot, here, boss
		
		decl String:newname[MAX_NAME_LENGTH];
		GetArrayString(bot_names, GetArrayCell(name_redirects, next_index), newname, MAX_NAME_LENGTH);

		next_index++;
		if (next_index > loaded_names - 1)
		{
			next_index = 0;
		}
		
		SetClientInfo(client, "name", newname);
		if (GetConVarBool(cvarAnnounce))
		{
			PrintToChatAll("[botnames] Bot %s created.", newname);
			PrintToServer("[botnames] Bot %s created.", newname);
		}
	}
	return true;
}

// handle player team change, to supress bot messages
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(GetConVarBool(cvarEnabled) && GetConVarBool(cvarSuppress)))
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0)
	{
		// weird error, ignore
		return Plugin_Continue;
	}
	if (IsFakeClient(client))
	{
		// fake client == bot
		SetEventBool(event, "silent", true);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
// handle player team change, to supress bot messages
public Action:Event_PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!(GetConVarBool(cvarEnabled) && GetConVarBool(cvarSuppress))) {
		return Plugin_Continue;
	}
	//PrintToServer("[BOTNAMES]: Triggered Event_PlayerChangeName");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0) {
		return Plugin_Continue;
	}
	if (IsFakeClient(client)) {
		//PrintToServer("[BOTNAMES]: Bot, suppressing name change event");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// handle player connect, to supress bot messages
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(GetConVarBool(cvarEnabled) && GetConVarBool(cvarSuppress)))
	{
		return Plugin_Continue;
	}

	decl String:networkID[32];
	GetEventString(event, "networkid", networkID, sizeof(networkID));

	if(!dontBroadcast && StrEqual(networkID, "BOT"))
	{
		// we got a bot connectin', resend event as no-broadcast
		decl String:clientName[MAX_NAME_LENGTH], String:address[32];
		GetEventString(event, "name", clientName, sizeof(clientName));
		GetEventString(event, "address", address, sizeof(address));

		new Handle:newEvent = CreateEvent("player_connect", true);
		SetEventString(newEvent, "name", clientName);
		SetEventInt(newEvent, "index", GetEventInt(event, "index"));
		SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
		SetEventString(newEvent, "networkid", networkID);
		SetEventString(newEvent, "address", address);

		FireEvent(newEvent, true);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}
