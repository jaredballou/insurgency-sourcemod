#define CON_COMMAND_NAME_SIZE 256
#define CHEATS_ACCESS_OVERRIDE "ftz_cheats"
#define CHEATS_DEFAULT_ACCESS_FLAGS ADMFLAG_CHEATS

static Handle:CommandBuffer = INVALID_HANDLE;

ConCmds_Init()
{
	CommandBuffer = CreateArray(CON_COMMAND_NAME_SIZE);
	decl String:name[CON_COMMAND_NAME_SIZE];
	new bool:iscmd;
	new flags;
	new Handle:it = FindFirstConCommand(name, CON_COMMAND_NAME_SIZE, iscmd, flags);
	if (it == INVALID_HANDLE)
	{
		return;
	}
	do
	{
		if ((!iscmd) || !(flags & FCVAR_CHEAT))
		{
			continue;
		}
		if (!AddCommandListener(ConCmds_OnCheatCommand, name))
		{
			continue;
		}
		flags &= ~FCVAR_CHEAT;
		if (!SetCommandFlags(name, flags))
		{
			continue;
		}
		PushArrayString(CommandBuffer, name);
	}
	while (FindNextConCommand(it, name, CON_COMMAND_NAME_SIZE, iscmd, flags));
}

ConCmds_Uninit()
{
	new size = GetArraySize(CommandBuffer);
	decl String:name[CON_COMMAND_NAME_SIZE];
	for (new i = 0; i < size; i++)
	{
		GetArrayString(CommandBuffer, i, name, CON_COMMAND_NAME_SIZE);
		ConCommand_AddFlags(name, FCVAR_CHEAT);
	}
	CloseHandle(CommandBuffer);
}

public Action:ConCmds_OnCheatCommand(client, const String:command[], argc)
{
	new bool:hasaccess = CheckCommandAccess(client, CHEATS_ACCESS_OVERRIDE, CHEATS_DEFAULT_ACCESS_FLAGS) || CheckCommandAccess(client, command, CHEATS_DEFAULT_ACCESS_FLAGS);
	Logging_NotifyCheatCommand(client, command, hasaccess);
	if (hasaccess)
	{
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Handled;
	}
}