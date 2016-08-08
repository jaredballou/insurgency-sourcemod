#define PLUGIN_AUTHOR "Jared Ballou, based on plugin by McFlurry"
#define PLUGIN_DESCRIPTION "Log events to client or server"
#define PLUGIN_NAME "Event Logger"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "EVENTS"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};
#include <sourcemod>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>


#pragma semicolon 1

static const String:FILE_PATHS[3][] =
{
	"resource/gameevents.res",
	"resource/serverevents.res",
	"resource/modevents.res"
};

static const String:FILE_KEYS[4][] =
{
	"ModEvents",
	"cstrikeevents",
	"engineevents",
	"gameevents"
};	

#define MAX_EVENTS		386
#define MAX_EVENT_KEYS	40 //tf2 -_-
#define NAME_SIZE		37 //l4d2 has a 35 character event name, while valves modevents.res states an event name has a max of 32 characters -_-

#define LISTEN_TO_KEYS	(1 << 0)
#define LISTEN_TO_EVENT	(1 << 1)

enum EventProperties
{
	String:sName[NAME_SIZE],
	bool:IsHooked,
	iNumKeys
};

enum EventKeyTypes
{
	KeyType_Null,
	KeyType_String,
	KeyType_Bool,
	KeyType_Byte,
	KeyType_Short,
	KeyType_Long,
	KeyType_Float
};

static const String:KeyTypeString[EventKeyTypes][] =
{
	"blarg", //0 is our placeholder for "no key in here yet"
	"string",
	"bool",
	"byte",
	"short",
	"long",
	"float"
};	

new iEventProperties[MAX_EVENTS][EventProperties];
new EventKeyTypes:ektEventKeys[MAX_EVENTS][MAX_EVENT_KEYS];
new String:sEventKeyNames[MAX_EVENTS][MAX_EVENT_KEYS][20];
new String:sPrefix[64];
new iIDCounter = -1;
new Handle:cvarPrefix = INVALID_HANDLE;

new bool:bEventListening[MAXPLAYERS+1][MAX_EVENTS];
new bool:bKeyListening[MAXPLAYERS+1][MAX_EVENTS];
new bool:bListeningToKey[MAXPLAYERS+1][MAX_EVENTS][MAX_EVENT_KEYS];

public OnPluginStart()
{
	Format(sPrefix, sizeof(sPrefix), "\x04[%s]\x01", PLUGIN_LOG_PREFIX);
	CreateConVar("sm_events_version", PLUGIN_VERSION, "Version of Event Info on this server", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_REPLICATED);

	cvarPrefix = CreateConVar("sm_events_prefix", sPrefix, "What to prefix on event messages", FCVAR_NOTIFY);
	HookConVarChange(cvarPrefix, OnCvarPrefixChange);
	
	RegAdminCmd("sm_events_listen", Command_ListenSwitch, ADMFLAG_GENERIC, "Start or stop listening to an event");
	RegAdminCmd("sm_events_keylisten", Command_KeyListenSwitch, ADMFLAG_GENERIC, "Start or stop listening to an event's keys");
	RegAdminCmd("sm_events_listentoall", Command_ListenToAll, ADMFLAG_GENERIC, "Start listening to all events");
	RegAdminCmd("sm_events_keylistentoall", Command_KeyListenToAll, ADMFLAG_GENERIC, "Start listening to all event keys");
	RegAdminCmd("sm_events_stoplisten", Command_StopListen, ADMFLAG_GENERIC, "Stop listening to all events and keys");
	RegAdminCmd("sm_events_listevents", Command_ListEvents, ADMFLAG_GENERIC, "List all hooked events");
	RegAdminCmd("sm_events_listkeys", Command_ListKeys, ADMFLAG_GENERIC, "List all keys for an event");
	RegAdminCmd("sm_events_searchevents", Command_SearchEvents, ADMFLAG_GENERIC, "Search for events");
	HookUpdater();
}

//GetConVarString(cvarPrefix, sPrefix, sizeof(sPrefix));
public OnCvarPrefixChange(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	// If nothing has changed, exit
	if (strcmp(sPrefix,newVal,false) == 0)
		return;
	if (StrEqual(newVal,"")) {
		Format(sPrefix, sizeof(sPrefix), "");
	} else {
		Format(sPrefix, sizeof(sPrefix), "%s ", newVal);
	}
}

public Action:Command_ListenSwitch(client, args)
{
	if(args == 1 && client != 0)
	{
		decl String:sEventName[NAME_SIZE];
		GetCmdArg(1, sEventName, sizeof(sEventName));
		for(new i; i < MAX_EVENTS; i++)
		{
			if(StrEqual(sEventName, iEventProperties[i][sName], false))
			{
				if(bEventListening[client][i])
				{
					SetEventListen(client,i,false,false);
					ReplyToCommand(client, "%s Stopped listening to \"%s\"", sPrefix, sEventName);
					return Plugin_Handled;
				}
				else
				{
					SetEventListen(client,i,true,false);
					ReplyToCommand(client, "%s Started listening to \"%s\"", sPrefix, sEventName);
					return Plugin_Handled;
				}	
			}
		}
		ReplyToCommand(client, "%s Failed to find event \"%s\"", sPrefix, sEventName);
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_listen <event>");
	}	
	return Plugin_Handled;
}

public Action:Command_KeyListenSwitch(client, args)
{
	if(1 <= args <= 2)
	{
		decl String:sEventName[NAME_SIZE];
		GetCmdArg(1, sEventName, sizeof(sEventName));
		for(new i; i < MAX_EVENTS; i++)
		{
			if(StrEqual(sEventName, iEventProperties[i][sName], false))
			{
				if(args == 2)
				{
					decl String:sKeyName[20];
					GetCmdArg(2, sKeyName, sizeof(sKeyName));
					new bool:found;
					for(new j; j < iEventProperties[i][iNumKeys]; j++)
					{
						if(StrEqual(sEventKeyNames[i][j], sKeyName, false))
						{
							found = true;
							if(!bListeningToKey[client][i][j])
							{
								SetEventListen(client,i,true,true);
								ReplyToCommand(client, "%s Started listening to \"%s\"s \"%s\" key", sPrefix, sEventName, sKeyName);
								break;
							}
							else
							{
								SetEventListen(client,i,false,false);
								ReplyToCommand(client, "%s Stopped listening to \"%s\"s \"%s\" key", sPrefix, sEventName, sKeyName);
								break;
							}
						}
					}
					if(!found)
					{
						ReplyToCommand(client, "%s Failed to find key \"%s\" in event \"%s\"", sPrefix, sKeyName, sEventName);
					}
					return Plugin_Handled;
				}	
				else if(bKeyListening[client][i])
				{
					SetEventListen(client,i,false,false);
					ReplyToCommand(client, "%s Stopped listening to \"%s\"s keys", sPrefix, sEventName);
					return Plugin_Handled;
				}
				else
				{
					SetEventListen(client,i,true,true);
					ReplyToCommand(client, "%s Started listening to \"%s\"s keys", sPrefix, sEventName);
					return Plugin_Handled;
				}	
			}
		}
		ReplyToCommand(client, "%s Failed to find event \"%s\"", sPrefix, sEventName);
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_keylisten <event> [keyname]");
	}	
	return Plugin_Handled;
}	

public Action:Command_ListenToAll(client, args) {
	if(args == 0) {
		for(new i; i < MAX_EVENTS; i++) {
			SetEventListen(client,i,true,false);
		}
		ReplyToCommand(client, "%s Started listening to all events", sPrefix);
	}
}	

SetEventListen(int client, int event, bool listen, bool keys) {
	bEventListening[client][event] = listen;
	bKeyListening[client][event] = keys;
	for(new j; j < iEventProperties[event][iNumKeys]; j++) {
		bListeningToKey[client][event][j] = keys;
	}
}

public Action:Command_KeyListenToAll(client, args) {
	if(args == 0) {
		ReplyToCommand(client, "%s Started listening to all events", sPrefix);
		for(new i; i < MAX_EVENTS; i++) {
			SetEventListen(client,i,true,true);
		}
	}
}	

public Action:Command_StopListen(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "%s Stopped listening to all events", sPrefix);
		for(new i; i < MAX_EVENTS; i++) {
			SetEventListen(client,i,false,false);
		}
	}
}

public Action:Command_ListEvents(client, args)
{
	if(args == 0) {
		ReplyToCommand(client, "%s Listing events", sPrefix);
		for(new i; i < MAX_EVENTS; i++) {
			if(strlen(iEventProperties[i][sName]) > 0) {
				ReplyToCommand(client, "%s \"%s\"", sPrefix, iEventProperties[i][sName]);
			}
		}
		ReplyToCommand(client, "%s End of event list", sPrefix);
	}
}

public Action:Command_ListKeys(client, args) {
	if(args == 1) {
		decl String:sEventName[NAME_SIZE];
		GetCmdArg(1, sEventName, sizeof(sEventName));
		ReplyToCommand(client, "%s Listing events", sPrefix);
		for(new i; i < MAX_EVENTS; i++) {
			if(StrEqual(sEventName, iEventProperties[i][sName], false)) {
				for(new j; j < MAX_EVENT_KEYS; j++) {
					ReplyToCommand(client, "%s %s: \"%s\" type %s", sPrefix, sEventName, sEventKeyNames[i][j], KeyTypeString[ektEventKeys[i][j]]);
				}
				ReplyToCommand(client, "%s Finished listing events", sPrefix);
				return Plugin_Handled;
			}
		}
		ReplyToCommand(client, "%s Failed to find event \"%s\"", sPrefix, sEventName);
	} else {
		ReplyToCommand(client, "[SM] Usage: sm_listkeys <event>");
	}
	return Plugin_Handled;
}

public Action:Command_SearchEvents(client, args)
{
	if(args == 1)
	{
		decl String:sEventName[NAME_SIZE];
		GetCmdArg(1, sEventName, sizeof(sEventName));
		if(strlen(sEventName) == 0)
		{
			return Plugin_Handled;
		}	
		ReplyToCommand(client, "%s Searching for events", sPrefix);
		for(new i; i < MAX_EVENTS; i++)
		{
			if(StrContains(iEventProperties[i][sName], sEventName, false) != -1)
			{
				ReplyToCommand(client, "%s \"%s\"", sPrefix, iEventProperties[i][sName]);
			}
		}
		ReplyToCommand(client, "%s Finished searching events", sPrefix);
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_searchevents <searchstring>");
	}	
	return Plugin_Handled;
}	

public OnMapEnd()
{
	ResetEvents();
	for(new i; i <= MaxClients; i++)
	{
		ResetListener(i);
	}
}

public OnMapStart()
{
	iIDCounter = -1;
	HookEvents();
}

public OnClientDisconnect(client)
{
	ResetListener(client);
}	

public OnClientConnected(client)
{
	ResetListener(client);
}

stock IsEventHooked(const String:event[])
{
	for(new i=0,s=sizeof(iEventProperties); i<s; i++)
	{
		if(iEventProperties[i][IsHooked] && StrEqual(iEventProperties[i][sName], event, false))
		{
			return i;
		}
	}
	return -1;
}

public Action:Event_Callback(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i; i < MAX_EVENTS; i++)
	{
		if(StrEqual(iEventProperties[i][sName], name))
		{
			PrintEventToListeners(event,i);
		}
	}
}	

static HookEvents()
{
	for(new i; i < sizeof(FILE_PATHS); i++)
	{
		new Handle:kvFile = CreateKeyValues(FILE_KEYS[i]);
		if(FileToKeyValues(kvFile, FILE_PATHS[i]))
		{
			if(!KvGotoFirstSubKey(kvFile, false))
			{
				return;
			}
			for(;;)
			{
				iIDCounter++;
				decl String:sSection[NAME_SIZE], String:sValue[20];
				KvGetSectionName(kvFile, sSection, sizeof(sSection));
				
				new id = IsEventHooked(sSection), oid = iIDCounter;
				if(id > -1)
				{
					UnhookEvent(sSection, Event_Callback);
					Format(iEventProperties[id][sName], NAME_SIZE, "");
					for(new j; j < MAX_EVENT_KEYS; j++)
					{
						if(ektEventKeys[id][j] != KeyType_Null)
						{
							ektEventKeys[id][j] = KeyType_Null;
							Format(sEventKeyNames[id][j], sizeof(sEventKeyNames[][]), "");
						}
					}
					iEventProperties[id][IsHooked] = false;
					iEventProperties[id][iNumKeys] = 0;
					iIDCounter = id;
				}
				iEventProperties[iIDCounter][IsHooked] = HookEventEx(sSection, Event_Callback);
				if(!iEventProperties[iIDCounter][IsHooked])
				{
					LogMessage("Failed to hook event: %s", sSection);
					continue;
				}
				Format(iEventProperties[iIDCounter][sName], NAME_SIZE, sSection);
				
				if(KvGotoFirstSubKey(kvFile, false)) //add to the stack and access the sub keys
				{
					new iMaxKeys = -1;
					for(;;)
					{
						KvGetSectionName(kvFile, sSection, sizeof(sSection));
						KvGetString(kvFile, NULL_STRING, sValue, sizeof(sValue));
						
						new iKeyType = StringTypeToIndex(sValue);
						ektEventKeys[iIDCounter][++iMaxKeys] = EventKeyTypes:iKeyType;
						Format(sEventKeyNames[iIDCounter][iMaxKeys], sizeof(sEventKeyNames[][]), sSection);
						
						if(!KvGotoNextKey(kvFile, false)) //this doesn't add to the traversal stack
						{
							break;
						}
					}
					iEventProperties[iIDCounter][iNumKeys] = iMaxKeys+1;
					KvGoBack(kvFile); //escape this sub key block and continue with loop
				}
				if(!KvGotoNextKey(kvFile)) //break if end of file.
				{
					break;
				}
				iIDCounter = oid;
			}	
		}	
		CloseHandle(kvFile);
	}	
}

static ResetEvents()
{
	for(new i; i < MAX_EVENTS; i++)
	{
		if(iEventProperties[i][IsHooked])
		{
			UnhookEvent(iEventProperties[i][sName], Event_Callback);
			Format(iEventProperties[i][sName], NAME_SIZE, "");
			for(new j; j < MAX_EVENT_KEYS; j++)
			{
				if(ektEventKeys[i][j] != KeyType_Null)
				{
					ektEventKeys[i][j] = KeyType_Null;
					Format(sEventKeyNames[i][j], sizeof(sEventKeyNames[][]), "");
				}
			}
			iEventProperties[i][IsHooked] = false;
			iEventProperties[i][iNumKeys] = 0;
		}
	}
}	

static StringTypeToIndex(const String:type[])
{
	for(new i = 1; i < sizeof(KeyTypeString); i++)
	{
		if(StrEqual(KeyTypeString[i], type, false))
		{
			return i;
		}
	}
	return 0;
}

static ResetListener(client)
{
	for(new j; j < MAX_EVENTS; j++)
	{
		SetEventListen(client,j,false,false);
	}
}

static PrintEventToListener(Handle:event,id,client) {
	decl String:sMessage[4096];
	decl String:sKeyName[20];
	decl String:sKeyValue[256];
	decl String:sKeyPrefix[32];
	int iKey;
	int iClient;
	float flKey;
	Format(sMessage, sizeof(sMessage), "%s %s", sPrefix, iEventProperties[id][sName]);
	for(new j; j < iEventProperties[id][iNumKeys]; j++) {
		Format(sKeyName, sizeof(sKeyName), sEventKeyNames[id][j]);
		new EventKeyTypes:type = ektEventKeys[id][j];
		if(type == KeyType_String) {
			GetEventString(event, sKeyName, sKeyValue, sizeof(sKeyValue));
		} else if(type == KeyType_Byte || type == KeyType_Short || type == KeyType_Long || type == KeyType_Bool) {
			iKey = GetEventInt(event, sKeyName);
			Format(sKeyValue, sizeof(sKeyValue), "%d", iKey);
		} else if(type == KeyType_Float) {
			flKey = GetEventFloat(event, sKeyName);
			Format(sKeyValue, sizeof(sKeyValue), "%f", flKey);
		}
		Format(sMessage, sizeof(sMessage), "%s (%s \"%s\")", sMessage, sKeyName, sKeyValue);
		if (StrEqual(sKeyName,"player") || StrEqual(sKeyName,"userid") || StrEqual(sKeyName,"attacker") || StrEqual(sKeyName,"victim") || StrEqual(sKeyName,"avenger_id") || StrEqual(sKeyName,"assister")) {
			if (StrEqual(sKeyName,"player")) {
				iClient = iKey;
			} else {
				iClient = GetClientOfUserId(iKey);
			}
			if (StrEqual(sKeyName,"userid")) {
				Format(sKeyPrefix, sizeof(sKeyPrefix), "");
			} else if (StrEqual(sKeyName,"attacker") || StrEqual(sKeyName,"victim") || StrEqual(sKeyName,"assister")) {
				Format(sKeyPrefix, sizeof(sKeyPrefix), "%s_", sKeyName);
			} else if (StrEqual(sKeyName,"avenger_id")) {
				Format(sKeyPrefix, sizeof(sKeyPrefix), "avenger_");
			}
			Format(sMessage, sizeof(sMessage), "%s (%sclient \"%d\") (%sname \"%N\")", sMessage, sKeyPrefix, iClient, sKeyPrefix, iClient);
		}
	}
	if(client == 0) {
		PrintToServer(sMessage);
	} else {
		PrintToChat(client, sMessage);
	}
}
static PrintEventToListeners(Handle:event,id) {
	for(new c; c <= MaxClients; c++) {
		if(bEventListening[c][id]) {
			PrintEventToListener(event,id,c);
		}
	}
}
/*
static PrintKeyInfoToListeners(id, keyid, const String:key[], any:data, type)
{
	for(new c = 1; c <= MaxClients; c++) {
		if(bListeningToKey[c][id][keyid]) {
			switch(type) {
				case 1: {
					if(c == 0) {
						PrintToServer("%s %s: \"%i\"", sPrefix, key, data);
					} else {
						PrintToChat(c, "%s %s: \"%i\"", sPrefix, key, data);
					}
				}	
				case 2: {
					if(c == 0) {
						PrintToServer("%s %s: \"%f\"", sPrefix, key, data);
					} else {
						PrintToChat(c, "%s %s: \"%f\"", sPrefix, key, data);
					}
				}	
			}	
		}
	}
}

static PrintKeyInfoStringToListeners(id, keyid, const String:key[], const String:data[]) {
	for(new c = 1; c <= MaxClients; c++) {
		if(bListeningToKey[c][id][keyid]) {
			if(c == 0) {
				PrintToServer("%s %s: \"%s\"", sPrefix, key, data);
			} else {
				PrintToChat(c, "%s %s: \"%s\"", sPrefix, key, data);
			}
		}
	}
}
*/
