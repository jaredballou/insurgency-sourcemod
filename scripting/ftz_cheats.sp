#include <sourcemod>

#include <smlib/concommands>

#define PLUGIN_VERSION "1.1"

#include "ftz_cheats/config"
#include "ftz_cheats/concmds"
#include "ftz_cheats/logging"

public Plugin:myinfo =
{
	name = "Cheats",
	author = "FaTony",
	description = "Allows clients to use cheat commands without sv_cheats 1",
	version = PLUGIN_VERSION,
	url = "http://fatony.com/"
};

public OnPluginStart()
{
	Config_PreInit();
	ConCmds_Init();
	Logging_Init();
	Config_PostInit();
}

public OnPluginEnd()
{
	ConCmds_Uninit();
}