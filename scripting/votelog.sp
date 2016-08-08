#define PLUGIN_DESCRIPTION "Logs voting events"
#define PLUGIN_NAME "Vote Logging"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "VOTE"
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
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
#include <loghelper>
#undef REQUIRE_PLUGIN
#include <updater>

//Add ammo to 99 code in weapon_deploy
#pragma unused cvarVersion


#define INS

new Handle:cvarVersion = INVALID_HANDLE; // version cvar
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
public OnPluginStart() {
	cvarVersion = CreateConVar("sm_votelog_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_votelog_enabled", PLUGIN_WORKING, "Enable vote logging", FCVAR_NOTIFY);
	InsLog(DEBUG,"Starting");
	HookEvent("vote_started", Event_vote_started);
	HookEvent("vote_changed", Event_vote_changed);
	HookEvent("vote_passed", Event_vote_passed);
	HookEvent("vote_failed", Event_vote_failed);
	HookEvent("vote_cast", Event_vote_cast);
	HookEvent("vote_options", Event_vote_options);
	HookUpdater();
}

public OnPluginEnd() {
}

public OnMapStart() {
}

public Action:Event_vote_started(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	new i_initiator = GetEventInt(event, "initiator");
	decl String:i_issue[256];
	GetEventString(event, "issue", i_issue, sizeof(i_issue));
	decl String:i_param1[256];
	GetEventString(event, "param1", i_param1, sizeof(i_param1));
	new i_team = GetEventInt(event, "team");
	LogToGame("[VOTELOG] triggered \"vote_started\" initiator \"%d\" issue \"%s\" param1 \"%s\" team \"%d\"", i_initiator, i_issue, i_param1, i_team);
	return Plugin_Continue;
}

public Action:Event_vote_changed(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	new i_potentialVotes = GetEventInt(event, "potentialVotes");
	new i_vote_option4 = GetEventInt(event, "vote_option4");
	new i_vote_option5 = GetEventInt(event, "vote_option5");
	new i_vote_option1 = GetEventInt(event, "vote_option1");
	new i_vote_option2 = GetEventInt(event, "vote_option2");
	new i_vote_option3 = GetEventInt(event, "vote_option3");
	LogToGame("[VOTELOG] triggered \"vote_changed\" potentialVotes \"%d\" vote_option4 \"%d\" vote_option5 \"%d\" vote_option1 \"%d\" vote_option2 \"%d\" vote_option3 \"%d\"", i_potentialVotes, i_vote_option4, i_vote_option5, i_vote_option1, i_vote_option2, i_vote_option3);
	return Plugin_Continue;
}

public Action:Event_vote_passed(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	decl String:i_details[256];
	GetEventString(event, "details", i_details, sizeof(i_details));
	decl String:i_param1[256];
	GetEventString(event, "param1", i_param1, sizeof(i_param1));
	new i_team = GetEventInt(event, "team");
	LogToGame("[VOTELOG] triggered \"vote_passed\" details \"%s\" param1 \"%s\" team \"%d\"", i_details, i_param1, i_team);
	return Plugin_Continue;
}

public Action:Event_vote_failed(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	new i_team = GetEventInt(event, "team");
	LogToGame("[VOTELOG] triggered \"vote_failed\" team \"%d\"", i_team);
	return Plugin_Continue;
}

public Action:Event_vote_cast(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	new i_entityid = GetEventInt(event, "entityid");
	new i_vote_option = GetEventInt(event, "vote_option");
	new i_team = GetEventInt(event, "team");
	LogToGame("[VOTELOG] triggered \"vote_cast\" entityid \"%d\" vote_option \"%d\" team \"%d\"", i_entityid, i_vote_option, i_team);
	return Plugin_Continue;
}

public Action:Event_vote_options(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Continue;
	}
	new i_count = GetEventInt(event, "count");
	decl String:i_option4[256];
	GetEventString(event, "option4", i_option4, sizeof(i_option4));
	decl String:i_option5[256];
	GetEventString(event, "option5", i_option5, sizeof(i_option5));
	decl String:i_option2[256];
	GetEventString(event, "option2", i_option2, sizeof(i_option2));
	decl String:i_option3[256];
	GetEventString(event, "option3", i_option3, sizeof(i_option3));
	decl String:i_option1[256];
	GetEventString(event, "option1", i_option1, sizeof(i_option1));
	LogToGame("[VOTELOG] triggered \"vote_options\" count \"%d\" option4 \"%s\" option5 \"%s\" option2 \"%s\" option3 \"%s\" option1 \"%s\"", i_count, i_option4, i_option5, i_option2, i_option3, i_option1);
	return Plugin_Continue;
}

