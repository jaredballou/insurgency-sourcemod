#if defined _ted_included_
	#endinput
#endif
#define _ted_included_

native TED_SetNetprop(client, const String:sNetprop[], const String:sValue[]);
native TED_SelectEntity(client, entity);
native TED_IgnoreNetprop(client, const String:sNetprop[]);
native TED_UnignoreNetprop(client, const String:sNetprop[]);
native TED_ShowNetprops(client);
native TED_WatchNetprops(client);
native TED_StopWatchNetprops(client);
native TED_SaveNetprops(client);
native TED_CompareNetprops(client);