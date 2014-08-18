#define CHEATS_VERSION_CVAR_NAME "ftz_cheats_version"
#define CHEATS_VERSION_CVAR_DESCRIPTION "The version of cheats plugin."
#define CHEATS_CFG_FILE "ftz_cheats"
#define CHEATS_TRANSLATION_FILE "ftz_cheats.phrases"

Config_PreInit()
{
	CreateConVar(CHEATS_VERSION_CVAR_NAME, PLUGIN_VERSION, CHEATS_VERSION_CVAR_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	LoadTranslations(CHEATS_TRANSLATION_FILE);
}

Config_PostInit()
{
	AutoExecConfig(true, CHEATS_CFG_FILE);
}