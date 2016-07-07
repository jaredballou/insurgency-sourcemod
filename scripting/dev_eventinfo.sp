#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION	"1.0.2"
#define TAG				"\x04[EI]\x01"

public Plugin:myinfo = 
{
	name = "[DEV] Event Info",
	author = "McFlurry",
	description = "Allows monitoring of all available events and their information",
	version = PLUGIN_VERSION,
	url = "mcflurrysource.netne.net"
}

static const String:FILE_PATHS[3][] =
{
	"resource/gameevents.res",
	"resource/serverevents.res",
	"resource/modevents.res"
};

static const String:FILE_KEYS[3][] =
{
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
new EventKeyTypes:iEventKeys[MAX_EVENTS][MAX_EVENT_KEYS];
new String:iEventKeyNames[MAX_EVENTS][MAX_EVENT_KEYS][20];
new iIDCounter = -1;

new bool:iListeningFlags[MAXPLAYERS+1][MAX_EVENTS];
new bool:iKeyListening[MAXPLAYERS+1][MAX_EVENTS];
new bool:iListeningToKey[MAXPLAYERS+1][MAX_EVENTS][MAX_EVENT_KEYS];

public OnPluginStart()
{
	CreateConVar("sm_eventinfo_version", PLUGIN_VERSION, "Version of Event Info on this server", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	RegAdminCmd("sm_listen", Command_ListenSwitch, ADMFLAG_GENERIC, "Start or stop listening to an event");
	RegAdminCmd("sm_keylisten", Command_KeyListenSwitch, ADMFLAG_GENERIC, "Start or stop listening to an event's keys");
	RegAdminCmd("sm_listentoall", Command_ListenToAll, ADMFLAG_GENERIC, "Start listening to all events");
	RegAdminCmd("sm_keylistentoall", Command_KeyListenToAll, ADMFLAG_GENERIC, "Start listening to all event keys");
	RegAdminCmd("sm_stoplisten", Command_StopListen, ADMFLAG_GENERIC, "Stop listening to all events and keys");
	RegAdminCmd("sm_listevents", Command_ListEvents, ADMFLAG_GENERIC, "List all hooked events");
	RegAdminCmd("sm_listkeys", Command_ListKeys, ADMFLAG_GENERIC, "List all keys for an event");
	RegAdminCmd("sm_searchevents", Command_SearchEvents, ADMFLAG_GENERIC, "Search for events");
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
				if(iListeningFlags[client][i])
				{
					iListeningFlags[client][i] = false; //stop listening
					iKeyListening[client][i] = false;
					ReplyToCommand(client, "%s Stopped listening to \"%s\"", TAG, sEventName);
					for(new j; j < iEventProperties[i][iNumKeys]; j++)
					{
						iListeningToKey[client][i][j] = false;
					}
					return Plugin_Handled;
				}
				else
				{
					iListeningFlags[client][i] = true; //start listening to the event only
					iKeyListening[client][i] = false;
					ReplyToCommand(client, "%s Started listening to \"%s\"", TAG, sEventName);
					for(new j; j < iEventProperties[i][iNumKeys]; j++)
					{
						iListeningToKey[client][i][j] = false;
					}	
					return Plugin_Handled;
				}	
			}
		}
		ReplyToCommand(client, "%s Failed to find event \"%s\"", TAG, sEventName);
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
						if(StrEqual(iEventKeyNames[i][j], sKeyName, false))
						{
							found = true;
							if(!iListeningToKey[client][i][j])
							{
								iListeningToKey[client][i][j] = true;
								iListeningFlags[client][i] = true;
								iKeyListening[client][i] = true;
								ReplyToCommand(client, "%s Started listening to \"%s\"s \"%s\" key", TAG, sEventName, sKeyName);
								break;
							}
							else
							{
								iListeningToKey[client][i][j] = false;
								iListeningFlags[client][i] = true;
								iKeyListening[client][i] = false;
								ReplyToCommand(client, "%s Stopped listening to \"%s\"s \"%s\" key", TAG, sEventName, sKeyName);
								break;
							}	
						}
					}
					if(!found)
					{
						ReplyToCommand(client, "%s Failed to find key \"%s\" in event \"%s\"", TAG, sKeyName, sEventName);
					}	
					return Plugin_Handled;
				}	
				else if(iKeyListening[client][i])
				{
					iListeningFlags[client][i] = true; //stop listening
					iKeyListening[client][i] = false;
					for(new j; j < iEventProperties[i][iNumKeys]; j++)
					{
						iListeningToKey[client][i][j] = false;
					}	
					ReplyToCommand(client, "%s Stopped listening to \"%s\"s keys", TAG, sEventName);
					return Plugin_Handled;
				}
				else
				{
					iListeningFlags[client][i] = true; //start listening to the event and keys
					iKeyListening[client][i] = true;
					for(new j; j < iEventProperties[i][iNumKeys]; j++)
					{
						iListeningToKey[client][i][j] = true;
					}	
					ReplyToCommand(client, "%s Started listening to \"%s\"s keys", TAG, sEventName);
					return Plugin_Handled;
				}	
			}
		}
		ReplyToCommand(client, "%s Failed to find event \"%s\"", TAG, sEventName);
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_keylisten <event> [keyname]");
	}	
	return Plugin_Handled;
}	

public Action:Command_ListenToAll(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "%s Started listening to all events", TAG);
		for(new i; i < MAX_EVENTS; i++)
		{
			iListeningFlags[client][i] = true;
			iKeyListening[client][i] = false;
			for(new j; j < iEventProperties[i][iNumKeys]; j++)
			{
				iListeningToKey[client][i][j] = false;
			}	
		}
	}
}	

public Action:Command_KeyListenToAll(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "%s Started listening to all events", TAG);
		for(new i; i < MAX_EVENTS; i++)
		{
			iListeningFlags[client][i] = true;
			iKeyListening[client][i] = true;
			for(new j; j < iEventProperties[i][iNumKeys]; j++)
			{
				iListeningToKey[client][i][j] = true;
			}	
		}
	}
}	

public Action:Command_StopListen(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "%s Stopped listening to all events", TAG);
		for(new i; i < MAX_EVENTS; i++)
		{
			iListeningFlags[client][i] = false;	
			iKeyListening[client][i] = false;
			for(new j; j < iEventProperties[i][iNumKeys]; j++)
			{
				iListeningToKey[client][i][j] = false;
			}
		}
	}
}

public Action:Command_ListEvents(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "%s Listing events", TAG);
		for(new i; i < MAX_EVENTS; i++)
		{
			if(strlen(iEventProperties[i][sName]) > 0)
			{
				ReplyToCommand(client, "%s \"%s\"", TAG, iEventProperties[i][sName]);
			}
		}
		ReplyToCommand(client, "%s End of event list", TAG);
	}
}

public Action:Command_ListKeys(client, args)
{
	if(args == 1)
	{
		decl String:sEventName[NAME_SIZE];
		GetCmdArg(1, sEventName, sizeof(sEventName));
		ReplyToCommand(client, "%s Listing events", TAG);
		for(new i; i < MAX_EVENTS; i++)
		{
			if(StrEqual(sEventName, iEventProperties[i][sName], false))
			{
				for(new j; j < MAX_EVENT_KEYS; j++)
				{
					ReplyToCommand(client, "%s %s: \"%s\" type %s", TAG, sEventName, iEventKeyNames[i][j], KeyTypeString[iEventKeys[i][j]]);
				}
				ReplyToCommand(client, "%s Finished listing events", TAG);
				return Plugin_Handled;
			}
		}
		ReplyToCommand(client, "%s Failed to find event \"%s\"", TAG, sEventName);
	}
	else
	{
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
		ReplyToCommand(client, "%s Searching for events", TAG);
		for(new i; i < MAX_EVENTS; i++)
		{
			if(StrContains(iEventProperties[i][sName], sEventName, false) != -1)
			{
				ReplyToCommand(client, "%s \"%s\"", TAG, iEventProperties[i][sName]);
			}
		}
		ReplyToCommand(client, "%s Finished searching events", TAG);
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
			PrintEventNameToListeners(i);
			for(new j; j < iEventProperties[i][iNumKeys]; j++)
			{
				decl String:sKeyName[20];
				Format(sKeyName, sizeof(sKeyName), iEventKeyNames[i][j]);
				new EventKeyTypes:type = iEventKeys[i][j];
				if(type == KeyType_String)
				{
					decl String:sKey[256];
					GetEventString(event, sKeyName, sKey, sizeof(sKey));
					PrintKeyInfoStringToListeners(i, j, sKeyName, sKey);
				}
				else if(type == KeyType_Byte || type == KeyType_Short || type == KeyType_Long || type == KeyType_Bool)
				{
					new iKey = GetEventInt(event, sKeyName);
					PrintKeyInfoToListeners(i, j, sKeyName, iKey, 1);
				}
				else if(type == KeyType_Float)
				{
					new Float:flKey = GetEventFloat(event, sKeyName);
					PrintKeyInfoToListeners(i, j, sKeyName, flKey, 2);
				}
			}
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
						if(iEventKeys[id][j] != KeyType_Null)
						{
							iEventKeys[id][j] = KeyType_Null;
							Format(iEventKeyNames[id][j], sizeof(iEventKeyNames[][]), "");
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
						iEventKeys[iIDCounter][++iMaxKeys] = EventKeyTypes:iKeyType;
						Format(iEventKeyNames[iIDCounter][iMaxKeys], sizeof(iEventKeyNames[][]), sSection);
						
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
				if(iEventKeys[i][j] != KeyType_Null)
				{
					iEventKeys[i][j] = KeyType_Null;
					Format(iEventKeyNames[i][j], sizeof(iEventKeyNames[][]), "");
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
		iListeningFlags[client][j] = false;
		iKeyListening[client][j] = false;
		for(new i; i < MAX_EVENT_KEYS; i++)
		{
			iListeningToKey[client][j][i] = false;
		}	
	}
}

static PrintEventNameToListeners(id)
{
	for(new c; c <= MaxClients; c++)
	{
		if(iListeningFlags[c][id])
		{
			if(c == 0)
			{
				PrintToServer("%s %s", TAG, iEventProperties[id][sName]);
			}
			else
			{
				PrintToChat(c, "%s %s", TAG, iEventProperties[id][sName]);
			}
		}
	}
}

static PrintKeyInfoToListeners(id, keyid, const String:key[], any:data, type)
{
	for(new c = 1; c <= MaxClients; c++)
	{
		if(iListeningToKey[c][id][keyid])
		{
			switch(type)
			{
				case 1:
				{
					if(c == 0)
					{
						PrintToServer("%s %s: \"%i\"", TAG, key, data);
					}
					else
					{
						PrintToChat(c, "%s %s: \"%i\"", TAG, key, data);
					}
				}	
				case 2:
				{
					if(c == 0)
					{
						PrintToServer("%s %s: \"%f\"", TAG, key, data);
					}
					else
					{
						PrintToChat(c, "%s %s: \"%f\"", TAG, key, data);
					}
				}	
			}	
		}
	}
}

static PrintKeyInfoStringToListeners(id, keyid, const String:key[], const String:data[])
{
	for(new c = 1; c <= MaxClients; c++)
	{
		if(iListeningToKey[c][id][keyid])
		{
			if(c == 0)
			{
				PrintToServer("%s %s: \"%s\"", TAG, key, data);
			}
			else
			{
				PrintToChat(c, "%s %s: \"%s\"", TAG, key, data);
			}
		}
	}
}
