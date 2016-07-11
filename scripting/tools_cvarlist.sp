#pragma semicolon 1

public Plugin:myinfo =
{
	name = "[TOOLS] Cvarlist & Cmdlist",
	author = "MCPAN (mcpan@foxmail.com)",
	description = "List all cvar/cmd value, flags and description.",
	version = "1.1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=201768"
}

new g_SDKVersion;
public OnPluginStart()
{
	g_SDKVersion = GuessSDKVersion();
	RegServerCmd("tools_cvarlist", tools_cvarlist);
}

public Action:tools_cvarlist(argc)
{
	new bool:isCommand, flags;
	new Handle:cvarIter;
	new Handle:cvarTrieDesc = CreateTrie();
	new Handle:cvarTrieFlags = CreateTrie();
	new Handle:cvarArray = CreateArray(ByteCountToCells(256));
	new Handle:cmdTrieDesc = CreateTrie();
	new Handle:cmdTrieFlags = CreateTrie();
	new Handle:cmdArray = CreateArray(ByteCountToCells(256));
	decl String:buffer[256], String:desc[1024];
	
	do
	{
		if (cvarIter == INVALID_HANDLE)
		{
			cvarIter = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc));
		}
		
		if (isCommand)
		{
			PushArrayString(cmdArray, buffer);
			SetTrieString(cmdTrieDesc, buffer, desc);
			SetTrieValue(cmdTrieFlags, buffer, flags);
			continue;
		}
		
		PushArrayString(cvarArray, buffer);
		SetTrieString(cvarTrieDesc, buffer, desc);
		SetTrieValue(cvarTrieFlags, buffer, flags);
	}
	while (FindNextConCommand(cvarIter, buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc)));
	CloseHandle(cvarIter);
	
	new Handle:file, size;
	decl String:game[32], String:version[32], String:appid[16], String:map[64], String:path[256], String:flagsStr[1024], String:value[256], String:defvalue[256];
	GetCurrentMap(map, sizeof(map));
	GetGameInformation(version, game, appid);
	
	FormatTime(path, sizeof(path), "addons/sourcemod/logs/tools_cmdlist_%Y%m%d%H%M%S.cfg");
	file = OpenFile(path, "a+");
	size = GetArraySize(cmdArray);
	SortADTArray(cmdArray, Sort_Ascending, Sort_String);
	WriteFileLine(file, "// game=%s, version=%s, appid=%s, map=%s, totalcmd=%d\n", game, version, appid, map, size);
	
	for (new i; i < size; i++)
	{
		GetArrayString(cmdArray, i, buffer, sizeof(buffer));
		if (GetTrieString(cmdTrieDesc, buffer, desc, sizeof(desc)) && desc[0])
		{
			ReplaceString(desc, sizeof(desc), "\n", "\n// ");
			WriteFileLine(file, "// %s", desc);
		}
		/*
		if (GetTrieValue(cmdTrieFlags, buffer, flags) && flags)
		{
			ConVarFlagsToString(flags, flagsStr, sizeof(flagsStr));
			WriteFileLine(file, "// Flags: %s", flagsStr);
		}
		*/
		WriteFileLine(file, "%s\n", buffer);
	}
	CloseHandle(file);
	CloseHandle(cmdArray);
	CloseHandle(cmdTrieDesc);
	CloseHandle(cmdTrieFlags);
	PrintToServer("Command dump finished. \"%s\"", path);
	
	FormatTime(path, sizeof(path), "addons/sourcemod/logs/tools_cvarlist_%Y%m%d%H%M%S.cfg");
	file = OpenFile(path, "a+");
	size = GetArraySize(cvarArray);
	SortADTArray(cvarArray, Sort_Ascending, Sort_String);
	WriteFileLine(file, "// game=%s, version=%s, appid=%s, map=%s, totalcvar=%d\n", game, version, appid, map, size);
	
	new Handle:hndl, Float:valueMin, Float:valueMax;
	decl String:valueMinStr[32], String:valueMaxStr[32], String:tempStr[96];
	for (new i; i < size; i++)
	{
		GetArrayString(cvarArray, i, buffer, sizeof(buffer));
		if (GetTrieString(cvarTrieDesc, buffer, desc, sizeof(desc)) && desc[0])
		{
			ReplaceString(desc, sizeof(desc), "\n", "\n// ");
			WriteFileLine(file, "// %s", desc);
		}
		
		if (GetTrieValue(cvarTrieFlags, buffer, flags) && flags)
		{
			ConVarFlagsToString(flags, flagsStr, sizeof(flagsStr));
			WriteFileLine(file, "// Flags: %s", flagsStr);
		}
		
		tempStr[0] = 0;
		if (GetConVarBounds((hndl = FindConVar(buffer)), ConVarBound_Lower, valueMin))
		{
			FloatToStringEx(valueMin, valueMinStr, sizeof(valueMinStr));
			Format(tempStr, sizeof(tempStr), "// Min: \"%s\"", valueMinStr);
		}
		
		if (GetConVarBounds(hndl, ConVarBound_Upper, valueMax))
		{
			FloatToStringEx(valueMax, valueMaxStr, sizeof(valueMaxStr));
			Format(tempStr, sizeof(tempStr), "%s%s Max: \"%s\"", tempStr, tempStr[0] ? "" : "//", valueMaxStr);
		}
		
		if (tempStr[0])
		{
			WriteFileLine(file, tempStr);
		}
		
		GetConVarDefault(hndl, defvalue, sizeof(defvalue));
		WriteFileLine(file, "// Default: \"%s\"", defvalue);
		
		GetConVarString(hndl, value, sizeof(value));
		WriteFileLine(file, "%s \"%s\"\n", buffer, value);
	}
	CloseHandle(file);
	CloseHandle(cvarTrieDesc);
	CloseHandle(cvarTrieFlags);
	CloseHandle(cvarArray);
	PrintToServer("ConVar dump finished. \"%s\"", path);
	return Plugin_Handled;
}

#define FCVAR_DEVELOPMENTONLY			FCVAR_LAUNCHER
#define FCVAR_SS						FCVAR_STUDIORENDER
#define FCVAR_SS_ADDED
#define FCVAR_RELEASE					FCVAR_DATACACHE
#define FCVAR_RELOAD_MATERIALS			FCVAR_TOOLSYSTEM
#define FCVAR_RELOAD_TEXTURES			FCVAR_FILESYSTEM
#define FCVAR_MATERIAL_SYSTEM_THREAD	FCVAR_SOUNDSYSTEM
#define FCVAR_ACCESSIBLE_FROM_THREADS	FCVAR_INPUTSYSTEM
#define FCVAR_SERVER_CAN_EXECUTE		(1<<28)
#define FCVAR_SERVER_CANNOT_QUERY		(1<<29)
#define FCVAR_CLIENTCMD_CAN_EXECUTE		(1<<30)

new g_FlagsList[]=
{
	FCVAR_NONE,//					0		/**< The default, no flags at all */
	FCVAR_UNREGISTERED,//			(1<<0)	/**< If this is set, don't add to linked list, etc. */
	//FCVAR_LAUNCHER,//				(1<<1)	/**< Defined by launcher. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_DEVELOPMENTONLY */
	FCVAR_DEVELOPMENTONLY,//		(1<<1)	// Hidden in released products.
	FCVAR_GAMEDLL,//				(1<<2)	/**< Defined by the game DLL. */
	FCVAR_CLIENTDLL,//				(1<<3)	/**< Defined by the client DLL. */
	FCVAR_MATERIAL_SYSTEM,//		(1<<4)	/**< Defined by the material system. */
	FCVAR_PROTECTED,//				(1<<5)	/**< It's a server cvar, but we don't send the data since it's a password, etc. Sends 1 if it's not bland/zero, 0 otherwise as value. */
	FCVAR_SPONLY,//					(1<<6)	/**< This cvar cannot be changed by clients connected to a multiplayer server. */
	FCVAR_ARCHIVE,//				(1<<7)	/**< Set to cause it to be saved to vars.rc */
	FCVAR_NOTIFY,//					(1<<8)	/**< Notifies players when changed. */
	FCVAR_USERINFO,//				(1<<9)	/**< Changes the client's info string. */
	FCVAR_PRINTABLEONLY,//			(1<<10)	/**< This cvar's string cannot contain unprintable characters (e.g., used for player name, etc.) */
	FCVAR_UNLOGGED,//				(1<<11)	/**< If this is a FCVAR_SERVER, don't log changes to the log file / console if we are creating a log */
	FCVAR_NEVER_AS_STRING,//		(1<<12)	/**< Never try to print that cvar. */
	FCVAR_REPLICATED,//				(1<<13)	/**< Server setting enforced on clients. */
	FCVAR_CHEAT,//					(1<<14)	/**< Only useable in singleplayer / debug / multiplayer & sv_cheats */
	//FCVAR_STUDIORENDER,//			(1<<15)	/**< Defined by the studiorender system. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_SS */
	FCVAR_SS,//						(1<<15) // causes varnameN where N == 2 through max splitscreen slots for mod to be autogenerated
	FCVAR_DEMO,//					(1<<16)	/**< Record this cvar when starting a demo file. */
	FCVAR_DONTRECORD,//				(1<<17)	/**< Don't record these command in demo files. */
	//,//				(1<<18)	/**< Defined by a 3rd party plugin. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_SS_ADDED */
	FCVAR_SS_ADDED,//				(1<<18) // This is one of the "added" FCVAR_SS variables for the splitscreen players
	//FCVAR_DATACACHE,//			(1<<19)	/**< Defined by the datacache system. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_RELEASE */
	FCVAR_RELEASE,//				(1<<19) // Cvars tagged with this are the only cvars avaliable to customers
	//FCVAR_TOOLSYSTEM,//			(1<<20)	/**< Defined by an IToolSystem library. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_RELOAD_MATERIALS */
	FCVAR_RELOAD_MATERIALS,//		(1<<20)	// If this cvar changes, it forces a material reload
	//FCVAR_FILESYSTEM,//			(1<<21)	/**< Defined by the file system. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_RELOAD_TEXTURES */
	FCVAR_RELOAD_TEXTURES,//		(1<<21)	// If this cvar changes, if forces a texture reload
	FCVAR_NOT_CONNECTED,//			(1<<22)	/**< Cvar cannot be changed by a client that is connected to a server. */
	//FCVAR_SOUNDSYSTEM,//			(1<<23)	/**< Defined by the soundsystem library. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_MATERIAL_SYSTEM_THREAD */
	FCVAR_MATERIAL_SYSTEM_THREAD,// 	(1<<23)	// Indicates this cvar is read from the material system thread
	FCVAR_ARCHIVE_XBOX,//			(1<<24)	/**< Cvar written to config.cfg on the Xbox. */
	//FCVAR_INPUTSYSTEM,//			(1<<25)	/**< Defined by the inputsystem DLL. SDKVersion > SOURCE_SDK_EPISODE1 use FCVAR_ACCESSIBLE_FROM_THREADS */
	FCVAR_ACCESSIBLE_FROM_THREADS,//	(1<<25)	// used as a debugging tool necessary to check material system thread convars
	FCVAR_NETWORKSYSTEM,//			(1<<26)	/**< Defined by the network system. */
	FCVAR_VPHYSICS,//				(1<<27)	/**< Defined by vphysics. */
	FCVAR_SERVER_CAN_EXECUTE,//		(1<<28)// the server is allowed to execute this command on clients via ClientCommand/NET_StringCmd/CBaseClientState::ProcessStringCmd.
	FCVAR_SERVER_CANNOT_QUERY,//	(1<<29)// If this is set, then the server is not allowed to query this cvar's value (via IServerPluginHelpers::StartQueryCvarValue).
	FCVAR_CLIENTCMD_CAN_EXECUTE //	(1<<30)	// IVEngineClient::ClientCmd is allowed to execute this command. 
											// Note: IVEngineClient::ClientCmd_Unrestricted can run any client command.
};

new String:g_FlagsListStrOld[][]=
{
	"FCVAR_NONE",
	"FCVAR_UNREGISTERED",
	"FCVAR_LAUNCHER",
	"FCVAR_GAMEDLL",
	"FCVAR_CLIENTDLL",
	"FCVAR_MATERIAL_SYSTEM",
	"FCVAR_PROTECTED",
	"FCVAR_SPONLY",
	"FCVAR_ARCHIVE",
	"FCVAR_NOTIFY",
	"FCVAR_USERINFO",
	"FCVAR_PRINTABLEONLY",
	"FCVAR_UNLOGGED",
	"FCVAR_NEVER_AS_STRING",
	"FCVAR_REPLICATED",
	"FCVAR_CHEAT",
	"FCVAR_STUDIORENDER",
	"FCVAR_DEMO",
	"FCVAR_DONTRECORD",
	"",
	"FCVAR_DATACACHE",
	"FCVAR_TOOLSYSTEM",
	"FCVAR_FILESYSTEM",
	"FCVAR_NOT_CONNECTED",
	"FCVAR_SOUNDSYSTEM",
	"FCVAR_ARCHIVE_XBOX",
	"FCVAR_INPUTSYSTEM",
	"FCVAR_NETWORKSYSTEM",
	"FCVAR_VPHYSICS"
};

new String:g_FlagsListStrNew[][]=
{
	"FCVAR_NONE",
	"FCVAR_UNREGISTERED",
	"FCVAR_DEVELOPMENTONLY",//new
	"FCVAR_GAMEDLL",
	"FCVAR_CLIENTDLL",
	"FCVAR_MATERIAL_SYSTEM",
	"FCVAR_PROTECTED",
	"FCVAR_SPONLY",
	"FCVAR_ARCHIVE",
	"FCVAR_NOTIFY",
	"FCVAR_USERINFO",
	"FCVAR_PRINTABLEONLY",
	"FCVAR_UNLOGGED",
	"FCVAR_NEVER_AS_STRING",
	"FCVAR_REPLICATED",
	"FCVAR_CHEAT",
	"FCVAR_SS",//new
	"FCVAR_DEMO",
	"FCVAR_DONTRECORD",
	"FCVAR_SS_ADDED",//new
	"FCVAR_RELEASE",//new
	"FCVAR_RELOAD_MATERIALS",//new
	"FCVAR_FILESYSTEM",
	"FCVAR_NOT_CONNECTED",
	"FCVAR_MATERIAL_SYSTEM_THREAD",//new
	"FCVAR_ARCHIVE_XBOX",
	"FCVAR_ACCESSIBLE_FROM_THREADS",//new
	"FCVAR_NETWORKSYSTEM",
	"FCVAR_VPHYSICS",
	"FCVAR_SERVER_CAN_EXECUTE",//new
	"FCVAR_SERVER_CANNOT_QUERY",//new
	"FCVAR_CLIENTCMD_CAN_EXECUTE" //new
};

ConVarFlagsToString(flags, String:flagsStr[], length)
{
	flagsStr[0] = 0;
	for (new i; i < sizeof(g_FlagsList); i++)
	{
		if (flags & g_FlagsList[i])
		{
			Format(flagsStr, length, "%s%s%s", flagsStr, flagsStr[0] ? "|" : "", g_SDKVersion > SOURCE_SDK_EPISODE1 ? g_FlagsListStrNew[i] : g_FlagsListStrOld[i]);
		}
	}
}

GetGameInformation(String:PatchVersion[], String:ProductName[], String:appID[])
{
	new Handle:file;
	if ((file = OpenFile("steam.inf", "r")) == INVALID_HANDLE)
	{
		return;
	}
	
	decl String:buffer[64];
	while (ReadFileLine(file, buffer, sizeof(buffer)))
	{
		if (StrContains(buffer, "PatchVersion=") == 0)
		{
			strcopy(PatchVersion, strlen(buffer) - 13, buffer[13]);
		}
		if (StrContains(buffer, "ProductName=") == 0)
		{
			strcopy(ProductName, strlen(buffer) - 12, buffer[12]);
		}
		if (StrContains(buffer, "appID=") == 0)
		{
			strcopy(appID, strlen(buffer) - 6, buffer[6]);
		}
	}
	CloseHandle(file);
}

FloatToStringEx(Float:num, String:str[], maxlength)
{
	new len = FloatToString(num, str, maxlength);
	for (new i = len - 1; i >= 0; i--)
	{
		if (str[i] != '0')
		{
			new idx;
			if (str[i] == '.')
			{
				idx = 1;
			}
			
			len = i - idx + 1;
			str[len] = 0;
			break;
		}
	}
	return len;
}
