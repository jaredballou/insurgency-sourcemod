#include <sourcemod>
#include <extended_logging>

public Plugin:myinfo =
{
	name = "Example plugin for extended logging",
	author = "Bara",
	description = "Example plugin for extended logging",
	version = "1.0",
	url = "www.bara.in"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_logfile", Command_LogFile);
}

public Action:Command_LogFile(client, args)
{
	decl String:sPath[PLATFORM_MAX_PATH + 1];
	Format(sPath, sizeof(sPath), "example");

	decl String:sFile[PLATFORM_MAX_PATH + 1];
	Format(sFile, sizeof(sFile), "name_example");

	decl String:sDate[64];
	FormatTime(sDate, sizeof(sDate), "%d-%m-%y");

	// with sDate
	Log_File(	sPath, sFile, sDate, DEFAULT, 	"Test Log_File - DEFAULT - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, sDate, TRACE, 	"Test Log_File - TRACE - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, sDate, DEBUG, 	"Test Log_File - DEBUG - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, sDate, INFO, 		"Test Log_File - INFO - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, sDate, WARN, 		"Test Log_File - WARN - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, sDate, ERROR, 	"Test Log_File - ERROR - %s", "Works fine! ;)");
	Log_Default(sPath, sFile, sDate, 			"Test Log_Default - %s", "Works fine! ;)");
	Log_Trace(	sPath, sFile, sDate, 			"Test Log_Trace - %s", "Works fine! ;)");
	Log_Debug(	sPath, sFile, sDate, 			"Test Log_Debug - %s", "Works fine! ;)");
	Log_Info(	sPath, sFile, sDate, 			"Test Log_Info - %s", "Works fine! ;)");
	Log_Warn(	sPath, sFile, sDate, 			"Test Log_Warn- %s", "Works fine! ;)");
	Log_Error(	sPath, sFile, sDate, 			"Test Log_Error - %s", "Works fine! ;)");

	// without sDate
	Log_File(	sPath, sFile, _, DEFAULT, 		"Test Log_File - DEFAULT - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, _, TRACE, 		"Test Log_File - TRACE - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, _, DEBUG, 		"Test Log_File - DEBUG - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, _, INFO, 			"Test Log_File - INFO - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, _, WARN, 			"Test Log_File - WARN - %s", "Works fine! ;)");
	Log_File(	sPath, sFile, _, ERROR, 		"Test Log_File - ERROR - %s", "Works fine! ;)");
	Log_Default(sPath, sFile, _, 				"Test Log_Default - %s", "Works fine! ;)");
	Log_Trace(	sPath, sFile, _, 				"Test Log_Trace - %s", "Works fine! ;)");
	Log_Debug(	sPath, sFile, _, 				"Test Log_Debug - %s", "Works fine! ;)");
	Log_Info(	sPath, sFile, _, 				"Test Log_Info - %s", "Works fine! ;)");
	Log_Warn(	sPath, sFile, _, 				"Test Log_Warn- %s", "Works fine! ;)");
	Log_Error(	sPath, sFile, _, 				"Test Log_Error - %s", "Works fine! ;)");
}