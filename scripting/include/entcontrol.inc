/**
 * Extension-Natives
 */

// + Entities
native EC_Entity_GetOutputCount(entity, String:sOutputName[]);
native bool:EC_Entity_GetOutputFirst(entity, String:sOutputName[]);
native bool:EC_Entity_GetOutputAt(entity, String:sOutputName[], i);
// - Entities

// + Navigation(.nav needed) - Used to spawn players/npcs/...
// Thanks to AnthonyIacono - https://github.com/AnthonyIacono for his navigation-parsing-code
native bool:EC_Nav_Load(); // .nav-files will automatically extracted from .vpk file
native bool:EC_Nav_CachePositions();
native bool:EC_Nav_GetNextHidingSpot(Float:randomPosition[3]);
// - Navigation

// + Webserver
// Not working? Look into your logfile: "Not enough space on the stack"? Type the following to increase the stackspace to 131072 bytes (131072/4=32768 cells)
// #pragma dynamic 32768
#define EC_MAXHTTPRESULT 131072
forward Action:EC_OnWebserverCallFunction(const userID, const String:function[], const String:arg[], String:result[]); // resultsize is max 131072 bytes
native EC_Web_GetPort();
native EC_Web_GetIP(String:address[]); // text is in/out
// - Webserver

// + HLLib - http://nemesis.thewavelength.net/index.php?p=35
native bool:EC_HLLib_OpenFile(const String:function[]); // BSP, GCF, NCF, PAK, VPK, WAD, XZP and uncompressed ZIP package formats are supported.
native bool:EC_HLLib_ItemExist(const String:item[]);
native bool:EC_HLLib_Extract(const String:source[], const String:destination[]);
native EC_HLLib_Close();
// - HLLib

// + Dlib - http://dlib.net/
native EC_Dlib_CRC32(const String:text[]);
native EC_Dlib_MD5(const String:text[]); // text is in/out
native EC_Dlib_HammingDistance(num1, num2);
native EC_Dlib_Hash(const String:text[]);
native Float:EC_Dlib_GaussianRandomHash(num1, num2, num3);
// - Dlib

// + Bugs
// Please do not abuse this feature. It´s for reporting bugs related to entcontrol.
native EC_ReportBug(const String:summary[], const String:format[], any:...);
// - Bugs

// + NPCs
// Possible NPC-Names:
// npc_antlion,npc_antlionguard,npc_barney,npc_dog,npc_gman,npc_headcrab,npc_police,npc_soldier,npc_sentrygun,npc_vortigaunt,npc_synth,npc_zombie,...
native EC_NPC_Spawn(String:sNPCName[], Float:x, Float:y, Float:z);
// - NPCs

/**
 * _________________Do not edit below this line!_______________________
 */
public Extension:__ext_smec = 
{
	name = "Entcontrol",
	file = "entcontrol.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public __ext_smec_SetNTVOptional()
{
	MarkNativeAsOptional("EC_Entity_GetOutputCount");
	MarkNativeAsOptional("EC_Entity_GetOutputFirst");
	MarkNativeAsOptional("EC_Entity_GetOutputAt");
	MarkNativeAsOptional("EC_Nav_Load");
	MarkNativeAsOptional("EC_Nav_CachePositions");
	MarkNativeAsOptional("EC_Nav_GetNextHidingSpot");
	MarkNativeAsOptional("EC_Web_GetPort");
	MarkNativeAsOptional("EC_Web_GetIP");
	MarkNativeAsOptional("EC_HLLib_OpenFile");
	MarkNativeAsOptional("EC_HLLib_ItemExist");
	MarkNativeAsOptional("EC_HLLib_Extract");
	MarkNativeAsOptional("EC_HLLib_Close");
	MarkNativeAsOptional("EC_Dlib_CRC32");
	MarkNativeAsOptional("EC_Dlib_MD5");
	MarkNativeAsOptional("EC_Dlib_HammingDistance");
	MarkNativeAsOptional("EC_Dlib_Hash");
	MarkNativeAsOptional("EC_Dlib_GaussianRandomHash");
}
#endif