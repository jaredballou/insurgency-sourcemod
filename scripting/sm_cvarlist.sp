#pragma semicolon 1
#include <sourcemod>

#define NAME_SIZE	128
#define VALUE_SIZE	128
#define FLAGS_SIZE	256
#define DESC_SIZE	512
#define LINE_SIZE	NAME_SIZE + VALUE_SIZE + FLAGS_SIZE + DESC_SIZE
#define ARG_SIZE	32

#if !defined FCVAR_DEVELOPMENTONLY
#define FCVAR_DEVELOPMENTONLY (1<<1)
#endif
#define PLUGIN_VERSION	"1.1"
#if !defined FCVAR_SERVER_CAN_EXECUTE
#define FCVAR_SERVER_CAN_EXECUTE	(1<<28)
#endif
#if !defined FCVAR_CLIENTCMD_CAN_EXECUTE
#define FCVAR_CLIENTCMD_CAN_EXECUTE	(1<<30)
#endif

static String:g_name[NAME_SIZE], String:g_value[VALUE_SIZE], String:g_flags[FLAGS_SIZE], String:g_desc[DESC_SIZE], String:g_line[LINE_SIZE];

static String:g_flagnames[] = {
        "a",
        "sp",
        "sv",
        "cheat",
        "user",
        "nf",
        "prot",
        "print",
        "log",
        "numeric",
        "rep",
        "demo",
        "norecord",
        "server_can_execute",
        "clientcmd_can_execute",
        "cl",
        "matsys",
        "studio",
        "devonly",
        "notconnected"
};


static g_flagvalues[] = {FCVAR_ARCHIVE, FCVAR_SPONLY, FCVAR_GAMEDLL, FCVAR_CHEAT, FCVAR_USERINFO, FCVAR_NOTIFY, FCVAR_PROTECTED, FCVAR_PRINTABLEONLY, FCVAR_UNLOGGED, FCVAR_NEVER_AS_STRING, FCVAR_REPLICATED, FCVAR_DEMO, FCVAR_DONTRECORD, FCVAR_SERVER_CAN_EXECUTE, FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_CLIENTDLL, FCVAR_MATERIAL_SYSTEM, FCVAR_DEVELOPMENTONLY, FCVAR_NOT_CONNECTED};
/* min sdk version >= */
/* max sdk version < */
/*
{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Engine_SourceSDK2006, Engine_SourceSDK2006, 0, 0, 0, Engine_Left4Dead, 0, 0},
{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Engine_Left4Dead, 0, 0, 0}
*/
static EngineVersion:g_EngineVersion, Handle:g_arglist, Handle:g_cvarlist, g_cvarcount, bool:g_iscommand, g_flagsbitstr;
public Plugin:myinfo = {
	name = "sm_cvarlist",
	author = "step",
	description = "An alternative to cvarlist command.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=135506"
};
public OnPluginStart() {
	g_EngineVersion = GetEngineVersion();
	//GuessSDKVersion();
	RegAdminCmd("sm_cvarlist", Command_Cvarlist, ADMFLAG_RCON, "sm_cvarlist <search strings> [/listed] or [/unlisted] [/defaults] [/file]", "");
	CreateConVar("sm_cvarlist_version", PLUGIN_VERSION, "sm_cvarlist version", FCVAR_SPONLY|FCVAR_NOTIFY);
}
public Action:Command_Cvarlist(client, args) {
	// cmd arguments
	new numargs = GetCmdArgs(), opt_listmode, bool:opt_defaults, bool:opt_savetofile, bool:opt_search;
	decl String:argstring[128] = "";
	
	if (numargs > 0)
	{
		decl String:arg[ARG_SIZE], String:temparg[ARG_SIZE];
		
		g_arglist = CreateArray(ARG_SIZE, numargs);
		GetCmdArgString(argstring, sizeof(argstring));
		
		for (new i = 0; i < numargs; i++)
		{
			GetCmdArg(i + 1, arg, ARG_SIZE);
			
			// options args
			if (FindCharInString(arg, '/') == 0)
			{
				if (StrEqual(arg[1], "listed"))
				{
					if (!HiddenCvarsSupport(client)) {return;}
					if (opt_listmode == 0) {opt_listmode = 1;}
					continue;
				}
				if (StrEqual(arg[1], "unlisted"))
				{
					if (!HiddenCvarsSupport(client)) {return;}
					if (opt_listmode == 0) {opt_listmode = 2;}
					continue;
				}
				if (StrEqual(arg[1], "defaults"))
				{
					if (!opt_defaults) {opt_defaults = true;}
					continue;
				}
				if (StrEqual(arg[1], "file"))
				{
					if (!opt_savetofile) {opt_savetofile = true;}
					continue;
				}
			}
			
			// search args
			if (!opt_search) {
				opt_search = true;
			}
			SetArrayString(g_arglist, i, arg);
			
			// flag search args
			Format(temparg, ARG_SIZE, "\"%s\"", arg);
			if (StrContains(argstring, temparg) != -1)
			{
				for (new j = 0; j < sizeof(g_flagnames) && !StrEqual(arg, g_flagnames[j]); j++) {
					SetArrayString(g_arglist, i, temparg);
				}
			}
		}
	}
	
	GetCvars(opt_listmode, opt_defaults, opt_search, numargs);
	OutputResults(client, opt_savetofile, argstring);
}

bool:HiddenCvarsSupport(client)
{
	if (g_EngineVersion <= Engine_SourceSDK2006)
	{
		PrintToConsole(client, "This Source Engine doesn't support hidden cvars.\nDon't use the \"/listed\" or \"/unlisted\" options.");
		return false;
	}
	return true;
}

GetCvars(opt_listmode, bool:opt_defaults, bool:opt_search, numargs) {
	// get cvars and fill array
	decl String:temp[ARG_SIZE];
	
	g_cvarlist = CreateArray(LINE_SIZE, 1);
	g_cvarcount = 0;
	
	new Handle:cvar = FindFirstConCommand(g_name, sizeof(g_name), g_iscommand, g_flagsbitstr, g_desc, sizeof(g_desc));
	do {
		if ((opt_listmode == 0) ||
			(opt_listmode == 1 && !(g_flagsbitstr & FCVAR_MATERIAL_SYSTEM)) ||
			(opt_listmode == 2 && (g_flagsbitstr & FCVAR_MATERIAL_SYSTEM))
		) {
			PrepareLine(opt_defaults);
			if (opt_search) {
				for (new i = 0; i < numargs; i++) {
					GetArrayString(g_arglist, i, temp, sizeof(temp));
					if (!StrEqual(temp, "") && StrContains(g_line, temp, false) != -1) {
						InsertLine();
						break;
					}
				}
			} else {
				InsertLine();
			}
		}
	} while (FindNextConCommand(cvar, g_name, sizeof(g_name), g_iscommand, g_flagsbitstr, g_desc, sizeof(g_desc)));
	CloseHandle(cvar);
	if (numargs > 0) {CloseHandle(g_arglist);}
	
	// remove excess lines and sort array
	if (g_cvarcount % 100 != 1) {ResizeArray(g_cvarlist, g_cvarcount);}
	SortADTArrayCustom(g_cvarlist, SortResults);
}

PrepareLine(bool:opt_defaults) {
	// value
	if (g_iscommand) {
		g_value = "cmd";
	} else {
		if (opt_defaults) {
			GetConVarDefault(FindConVar(g_name), g_value, sizeof(g_value));
		} else {
			GetConVarString(FindConVar(g_name), g_value, sizeof(g_value));
			if (StrEqual(g_value, "FCVAR_NEVER_AS_STRING")) {IntToString(GetConVarInt(FindConVar(g_name)), g_value, sizeof(g_value));}
		}
	}
	
	// flags
	g_flags = "";
	if (g_flagsbitstr != FCVAR_NONE) {
		// -1 = has all flags
		if (g_flagsbitstr == INVALID_FCVAR_FLAGS) {
			g_flagsbitstr = 0;
			for (new i = 0; i < sizeof(g_flagnames); i++) {
				// there's a next flagvalue and it's the same as the current one (it's a repeated value)
				if (i + 1 < sizeof(g_flagnames) && g_flagvalues[i] == g_flagvalues[i + 1]) {
					continue;
				}
				// add the flagvalue
				g_flagsbitstr += g_flagvalues[i];
			}
		}
		
		// flag names
		new hasFlags;
		for (new i = 0; i < sizeof(g_flagvalues) && hasFlags < g_flagsbitstr; i++) {
			if (g_flagvalues[i] > g_flagsbitstr) {
				continue;
			}
			if (g_flagsbitstr & g_flagvalues[i]) {
				if (i + 1 < sizeof(g_flagnames) && g_flagvalues[i] != g_flagvalues[i + 1]) {
					hasFlags += g_flagvalues[i];
				}
				//if (g_flagvalues[1][i] != 0 && g_EngineVersion < g_flagvalues[1][i]) {continue;}
				//if (g_flagvalues[2][i] != 0 && g_EngineVersion >= g_flagvalues[2][i]) {continue;}
				Format(g_flags, sizeof(g_flags), "%s \"%s\"", g_flags, g_flagnames[i]);
			}
		}
	}
	
	// prepare strings
	StrCat(g_name, 41, "                                                  ");
	StrCat(g_name, sizeof(g_name), " : ");
	StrCat(g_value, 9, "                                                  ");
	StrCat(g_value, sizeof(g_value), " : ");
	StrCat(g_flags, 17, "                                                  ");
	StrCat(g_flags, sizeof(g_flags), " : ");
	ReplaceString(g_desc, sizeof(g_desc), "	", " ");
	ReplaceString(g_desc, sizeof(g_desc), "\n", " ");
	
	// join strings into one line
	g_line = "";
	StrCat(g_line, sizeof(g_line), g_name);
	StrCat(g_line, sizeof(g_line), g_value);
	StrCat(g_line, sizeof(g_line), g_flags);
	StrCat(g_line, sizeof(g_line), g_desc);
}

InsertLine()
{
	// if last two digits are 01, then it needs more cells
	if (g_cvarcount % 100 == 1) {ResizeArray(g_cvarlist, g_cvarcount + 100);}
	
	// insert line in array
	SetArrayString(g_cvarlist, g_cvarcount, g_line);
	g_cvarcount += 1;
}

public SortResults(index1, index2, Handle:array, Handle:hndl)
{
	decl String:str1[LINE_SIZE], String:str2[LINE_SIZE];
	new bool:str1pm, bool:str2pm;
	
	GetArrayString(array, index1, str1, sizeof(str1));
	GetArrayString(array, index2, str2, sizeof(str2));
	SplitString(str1, " ", str1, sizeof(str1));
	SplitString(str2, " ", str2, sizeof(str2));
	
	if (FindCharInString(str1, '+') == 0 || FindCharInString(str1, '-') == 0) {str1pm = true;}
	if (FindCharInString(str2, '+') == 0 || FindCharInString(str2, '-') == 0) {str2pm = true;}
	
	if (str1pm)
	{
		if (str2pm && StrEqual(str1[1], str2[1], false)) {return strcmp(str1, str2, false);}
		if (StrEqual(str1[1], str2, false)) {return 1;}
		strcopy(str1, sizeof(str1), str1[1]);
	}
	if (str2pm)
	{
		if (str1pm && StrEqual(str1[1], str2[1], false)) {return strcmp(str1, str2, false);}
		if (StrEqual(str1, str2[1], false))	{return -1;}
		strcopy(str2, sizeof(str2), str2[1]);
	}
	
	return strcmp(str1, str2, false);
}

OutputResults(client, bool:opt_savetofile, String:argstring[])
{
	if (g_cvarcount == 0)
	{
		PrintToConsole(client, "No results found for: %s", argstring);
	}
	else
	{
		if (opt_savetofile == false)
		{
			// print results
			PrintToConsole(client, "sm_cvarlist %s", argstring);
			PrintToConsole(client, "--------------");
			for (new i = 0; i < g_cvarcount; i++)
			{
				GetArrayString(g_cvarlist, i, g_line, sizeof(g_line));
				PrintToConsole(client, "%s", g_line);
			}
			PrintToConsole(client, "--------------");
			PrintToConsole(client, "%i total convars/concommands", g_cvarcount);
		}
		else
		{
			// save results to file
			decl String:path[128];
			GenerateFilePath(path, sizeof(path));
			new Handle:file = OpenFile(path, "w");
			WriteFileLine(file, "sm_cvarlist %s", argstring);
			WriteFileLine(file, "--------------");
			for (new i = 0; i < g_cvarcount; i++)
			{
				GetArrayString(g_cvarlist, i, g_line, sizeof(g_line));
				WriteFileLine(file, "%s", g_line);
			}
			WriteFileLine(file, "--------------");
			WriteFileLine(file, "%i total convars/concommands", g_cvarcount);
			CloseHandle(file);
			PrintToConsole(client, "Results saved to \"%s\".", path);
		}
	}
	CloseHandle(g_cvarlist);
}

GenerateFilePath(String:buffer[], maxlength)
{
	static String:game[32], String:version[32];
	decl String:date[32], String:temp[128];
	
	// game name
	if (strlen(game) == 0) {GetGameFolderName(game, sizeof(game));}
	
	// game version
	if (strlen(version) == 0)
	{
		new Handle:file = OpenFile("steam.inf", "r");
		do {ReadFileLine(file, temp, sizeof(temp));}
		while (StrContains(temp, "PatchVersion=") != 0);
		CloseHandle(file);
		TrimString(temp);
		StrCat(version, sizeof(version), temp[FindCharInString(temp, '=')]);
		ReplaceString(version, sizeof(version), "=", "v");
		ReplaceString(version, sizeof(version), ".", "");
	}
	
	// date & time
	FormatTime(date, sizeof(date), "%Y%m%d_%H%M%S");
	
	// path
	BuildPath(Path_SM, temp, sizeof(temp), "logs");
	if (!DirExists(temp)) {CreateDirectory(temp, 777);}
	Format(temp, sizeof(temp), "%s\\sm_cvarlist_%s_%s_%s.txt", temp, game, version, date);
	
	// return
	strcopy(buffer, maxlength, temp);
}
