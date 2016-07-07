#include <sourcemod>
#include <loghelper>
#undef REQUIRE_PLUGIN
#include <updater>
#pragma unused cvarVersion

#define PLUGIN_DESCRIPTION "Prints all game events to console"
#define PLUGIN_NAME "Event Logger"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING "1"
#define PLUGIN_FILE "eventlog"
#define PLUGIN_LOG_PREFIX "EVENTLOG"
#include <myinfo>

#define INS

new Handle:cvarVersion = INVALID_HANDLE; // version cvar
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public OnPluginStart() {
	cvarVersion = CreateConVar("sm_eventlog_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_eventlog_enabled", PLUGIN_WORKING, "Enable logging of game events", FCVAR_NOTIFY | FCVAR_PLUGIN);
}
public EventHandler(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(cvarEnabled)) {
		return;
	}
	LogToGame("Event fired: \"%s\"", name);
}
