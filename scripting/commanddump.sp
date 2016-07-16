#include <sourcemod>
#include <admin>
#define PLUGIN_VERSION "1.1.0"

new Handle:v_Output = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[Any] Command Dumper",
	author = "DarthNinja",
	description = "Dumps information for *ALL* SM commands to a file",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	RegAdminCmd("sm_dumpcommands", DumpCommandList, ADMFLAG_ROOT, "Dumps all SM commands and their info to a file.");
	v_Output = CreateConVar("sm_commanddump_use_csv", "0", "Output to a CSV file instead of a .txt 1/0", 0, true, 0.0, true, 1.0);
	CreateConVar("sm_commanddump_version", PLUGIN_VERSION, "Plugin Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:DumpCommandList(client, args)
{
	new bool:DoCSV = GetConVarBool(v_Output);

	decl String:TakeADump[PLATFORM_MAX_PATH];
	if (DoCSV)
		BuildPath(Path_SM, TakeADump, sizeof(TakeADump), "logs/CommandDump.csv");
	else
		BuildPath(Path_SM, TakeADump, sizeof(TakeADump), "logs/CommandDump.txt");

	//Cleanup:
	if (FileExists(TakeADump))
	{
		//ReplyToCommand(client, "%s already exists, deleting file!", TakeADump);
		DeleteFile(TakeADump);
	}

	new Handle:CommandListFile = OpenFile(TakeADump, "w");

	decl String:Command[64];
	decl String:Description[255];
	new Handle:hIterator = GetCommandIterator();

	new iFlags;
	decl String:strFlags[64];

	if (DoCSV)
		WriteFileLine(CommandListFile, "#,Command,Description,Admin Flag");
	else
		WriteFileLine(CommandListFile, "#	Command		Description		Admin Flag\n");

	/* Start printing the commands to the client */
	new i = 1;
	while (ReadCommandIterator(hIterator, Command, sizeof(Command), iFlags, Description, sizeof(Description)))
	{
		Format(strFlags, sizeof(strFlags), "");
		
		//This still may not be the best way to do this
		if (iFlags & ADMFLAG_RESERVATION)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_RESERVATION ");
		if (iFlags & ADMFLAG_GENERIC)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_GENERIC ");
		if (iFlags & ADMFLAG_KICK)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_KICK ");
		if (iFlags & ADMFLAG_BAN)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_BAN ");
		if (iFlags & ADMFLAG_UNBAN)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_UNBAN ");
		if (iFlags & ADMFLAG_SLAY)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_SLAY ");
		if (iFlags & ADMFLAG_CHANGEMAP)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CHANGEMAP ");
		if (iFlags & ADMFLAG_CONVARS)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CONVARS ");
		if (iFlags & ADMFLAG_CONFIG)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CONFIG ");
		if (iFlags & ADMFLAG_CHAT)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CHAT ");
		if (iFlags & ADMFLAG_VOTE)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_VOTE ");
		if (iFlags & ADMFLAG_PASSWORD)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_PASSWORD ");
		if (iFlags & ADMFLAG_RCON)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_RCON ");
		if (iFlags & ADMFLAG_CHEATS)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CHEATS ");
		if (iFlags & ADMFLAG_ROOT)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_ROOT ");
		if (iFlags & ADMFLAG_CUSTOM1)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CUSTOM1 ");
		if (iFlags & ADMFLAG_CUSTOM2)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CUSTOM2 ");
		if (iFlags & ADMFLAG_CUSTOM3)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CUSTOM3 ");
		if (iFlags & ADMFLAG_CUSTOM4)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CUSTOM4 ");
		if (iFlags & ADMFLAG_CUSTOM5)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CUSTOM5 ");
		if (iFlags & ADMFLAG_CUSTOM6)
			StrCat(strFlags, sizeof(strFlags), "ADMFLAG_CUSTOM6 ");
		if (iFlags == 0)
			Format(strFlags, sizeof(strFlags), "No flag registered");

		if (StrEqual(Description, "", false))
			Format(Description, sizeof(Description), "No description found");

		if (DoCSV)
			WriteFileLine(CommandListFile, "%i,%s,\"%s\",%s", i, Command, Description, strFlags);
		else
			WriteFileLine(CommandListFile, "%i	%s		%s		%s", i, Command, Description, strFlags);
		i++;
	}

	if (!DoCSV)
		WriteFileLine(CommandListFile, "--- No more commands found ---");
	CloseHandle(hIterator);
	CloseHandle(CommandListFile);
	ReplyToCommand(client, "Command dump complete, see %s for output", TakeADump);

	return Plugin_Handled;
}
