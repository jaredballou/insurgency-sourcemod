#define CHEATS_NOTIFY_MODE_CVAR_NAME "ftz_cheats_notify_mode"
#define CHEATS_NOTIFY_MODE_CVAR_DEFAULT "6"
#define CHEATS_NOTIFY_MODE_CVAR_DESCRIPTION "Notification mode of usage of cheat commands."
#define CHEATS_NOTIFY_MODE_CVAR_MAX 63.0
#define CHEATS_NOTIFY_OVERRIDE "ftz_cheats_notify"
#define CHEATS_NOTIFY_DEFAULT_FLAGS ADMFLAG_ROOT

#define NOTIFY_FAILURE_CLIENT (1 << 0)
#define NOTIFY_FAILURE_LOG (1 << 1)
#define NOTIFY_FAILURE_OVERRIDE (1 << 2)
#define NOTIFY_SUCCESS_CLIENT (1 << 3)
#define NOTIFY_SUCCESS_LOG (1 << 4)
#define NOTIFY_SUCCESS_OVERRIDE (1 << 5)

static Handle:NotifyMode = INVALID_HANDLE;

Logging_Init()
{
	NotifyMode = CreateConVar(CHEATS_NOTIFY_MODE_CVAR_NAME, CHEATS_NOTIFY_MODE_CVAR_DEFAULT, CHEATS_NOTIFY_MODE_CVAR_DESCRIPTION, _, true, 0.0, true, CHEATS_NOTIFY_MODE_CVAR_MAX);
}

Logging_NotifyCheatCommand(const client, const String:command[], const bool:success)
{
	new mode = GetConVarInt(NotifyMode);
	if (!success)
	{
		if (mode & NOTIFY_FAILURE_CLIENT)
		{
			PrintToChat(client, "%t", "CHEATS_NOTIFY_FAILURE_CLIENT");
		}
		if (mode & NOTIFY_FAILURE_LOG)
		{
			LogMessage("%T", "CHEATS_NOTIFY_FAILURE_LOG", LANG_SERVER, client, command);
		}
		if (mode & NOTIFY_FAILURE_OVERRIDE)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if ((i != client) && IsClientInGame(i) && CheckCommandAccess(client, CHEATS_NOTIFY_OVERRIDE, CHEATS_NOTIFY_DEFAULT_FLAGS))
				{
					
					PrintToChat(i, "%t", "CHEATS_NOTIFY_FAILURE_CHAT", client, command);
				}
			}
		}
	}
	else
	{
		if (mode & NOTIFY_SUCCESS_CLIENT)
		{
			PrintToChat(client, "%t", "CHEATS_NOTIFY_SUCCESS_CLIENT", command);
		}
		if (mode & NOTIFY_SUCCESS_LOG)
		{
			LogMessage("%T", "CHEATS_NOTIFY_SUCCESS_LOG", LANG_SERVER, client, command);
		}
		if (mode & NOTIFY_SUCCESS_OVERRIDE)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				
				if ((i != client) && IsClientInGame(i) && CheckCommandAccess(client, CHEATS_NOTIFY_OVERRIDE, CHEATS_NOTIFY_DEFAULT_FLAGS))
				{
					PrintToChat(i, "%t", "CHEATS_NOTIFY_SUCCESS_CHAT", client, command);
				}
			}
		}
	}
}