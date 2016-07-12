/**
 * Raw Entity Dump by sarysa
 *
 * After seeing the awesome work FlaminSarge did with TF2 Sentries, I knew I needed a way to find the many, many
 * hidden props that exist with TF2 entities.
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_gamerules>
#include <sdkhooks>

#define DUMP_CMD_STRING "red_dump"
#define DUMP_KEY_CMD_STRING "red_dump_key"
#define DUMP_FLOATS_CMD_STRING "red_dump_floats"
#define DIFF_CMD_STRING "red_diff"
#define EXCLUDE_DIFF_CMD_STRING "red_exclude_diff"
#define FIND_SIMILAR_CMD_STRING "red_find_similar"
#define FIND_VALUE_CMD_STRING "red_find_value"

#define ARG_LENGTH 256
#define BUFFER_SIZE 256

public Plugin:myinfo=
{
	name = "Raw Entity Dump",
	author = "sarysa",
	description = "Dump raw bytes of an entity.",
	version = "0.4",
};

public OnPluginStart()
{
	RegAdminCmd(DUMP_CMD_STRING, RawEntityDump, ADMFLAG_GENERIC);
	RegAdminCmd(DUMP_KEY_CMD_STRING, RawEntityDumpKey, ADMFLAG_GENERIC);
	RegAdminCmd(DUMP_FLOATS_CMD_STRING, RawEntityDumpFloats, ADMFLAG_GENERIC);
	RegAdminCmd(DIFF_CMD_STRING, RawEntityDiff, ADMFLAG_GENERIC);
	RegAdminCmd(EXCLUDE_DIFF_CMD_STRING, RawEntityExcludeDiff, ADMFLAG_GENERIC);
	RegAdminCmd(FIND_SIMILAR_CMD_STRING, RawEntityFindSimilar, ADMFLAG_GENERIC);
	RegAdminCmd(FIND_VALUE_CMD_STRING, RawEntityFindValue, ADMFLAG_GENERIC);
	PrintToServer("************************************************************************");
	PrintToServer("* Loaded raw entity dump.                                              *");
	PrintToServer("* DO NOT USE THIS ON YOUR LIVE SERVER!                                 *");
	PrintToServer("* It is strictly for debug purposes and it does no safe file checking! *");
	PrintToServer("* (but furthermore, using a dev tool on a live server is just foolish) *");
	PrintToServer("************************************************************************");
}

/**
 * Various usage printouts
 */
public RawEntityDump_Usage(clientIdx)
{
	PrintToConsole(clientIdx, "Usage: %s [entityIdx OR entityClassname] [endPosition] [filepathRelativeToServerGameDir] (startAt)", DUMP_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s 23 9814 tfplayer.dmp", DUMP_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s obj_sentrygun 2832 tfsentry.dmp", DUMP_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s obj_sentrygun 2832 tfsentry2.dmp 1000", DUMP_CMD_STRING);
	PrintToConsole(clientIdx, "Resulting file will be a binary, so get out your hex editor. (I personally like HxD)");
}

public RawEntityDumpKey_Usage(clientIdx)
{
	PrintToConsole(clientIdx, "Usage: %s [entityIdx OR entityClassname] [endPosition] [keyId] [filepathRelativeToServerGameDir] (startAt)", DUMP_KEY_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s 23 9814 IN_RELOAD tfplayer.dmp", DUMP_KEY_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s 23 9814 +taunt tfplayer.dmp", DUMP_KEY_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s obj_sentrygun 2832 IN_ATTACK2 tfsentry.dmp", DUMP_KEY_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s obj_sentrygun 2832 IN_ATTACK tfsentry2.dmp 1000", DUMP_KEY_CMD_STRING);
	PrintToConsole(clientIdx, "Resulting file will be a binary, so get out your hex editor. (I personally like HxD)");
}

public RawEntityDumpFloats_Usage(clientIdx)
{
	PrintToConsole(clientIdx, "Usage: %s [entityIdx OR entityClassname] [endPosition] [filepathRelativeToServerGameDir] (startAt)", DUMP_FLOATS_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s 23 9814 tfplayer.txt", DUMP_FLOATS_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s obj_sentrygun 2832 tfsentry.txt", DUMP_FLOATS_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s obj_sentrygun 2832 tfsentry2.txt 1000", DUMP_FLOATS_CMD_STRING);
	PrintToConsole(clientIdx, "Resulting file will be human readable, every possible float from the start position to end position - 3.");
}

public RawEntityDiff_Usage(clientIdx)
{
	PrintToConsole(clientIdx, "Usage: %s [file1] [file2]", DIFF_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s tfsentry1.dmp tfsentry2.dmp", DIFF_CMD_STRING);
	PrintToConsole(clientIdx, "Resulting compare data will be in [file1].cmp, i.e. for above example tfsentry1.dmp.cmp");
}

public RawEntityExcludeDiff_Usage(clientIdx)
{
	PrintToConsole(clientIdx, "Usage: %s [file1] [file2] [file3] [excludeIdx (1-3)]", EXCLUDE_DIFF_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s tfplayer1.dmp tfplayer2.dmp tfplayer3.dmp 3", EXCLUDE_DIFF_CMD_STRING);
	PrintToConsole(clientIdx, "Resulting compare data will be in [file1].cmp, i.e. for above example tfplayer1.dmp.cmp.");
	PrintToConsole(clientIdx, "In above example, diffs between files 1 and 2 will only print out if file 3 shares the same value as either 1 or 2.");
	PrintToConsole(clientIdx, "This tool allows you to exclude unwanted values that change often, like animation values and entity position.");
}

public RawEntityFindSimilar_Usage(clientIdx)
{
	PrintToConsole(clientIdx, "Usage: %s [entity] [endPosition] [knownNetProp] [type] [netClassname]", FIND_SIMILAR_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s 23 9814 m_flTauntYaw float CTFPlayer", FIND_SIMILAR_CMD_STRING);
	PrintToConsole(clientIdx, "Will find all offsets with the same value as the one specified. It will also print out the offset for said prop.");
	PrintToConsole(clientIdx, "Output goes to both player console and server console.");
}

public RawEntityFindValue_Usage(clientIdx)
{
	PrintToConsole(clientIdx, "Usage: %s [entity] [endPosition] [value] [type]", FIND_VALUE_CMD_STRING);
	PrintToConsole(clientIdx, "Example: %s 23 9814 180.0 float", FIND_VALUE_CMD_STRING);
	PrintToConsole(clientIdx, "Will find all offsets with the specified value.");
	PrintToConsole(clientIdx, "Output goes to both player console and server console.");
}

/**
 * Dump
 */
bool:DoRawEntityDump(clientIdx, entity, bytesToRead, String:filePath[], startPos, bool:isDumpKey)
{
	if (!IsValidEntity(entity))
	{
		PrintToConsole(clientIdx, "Entity %d is invalid!", entity);
		return false;
	}
	
	// validity of length
	if (bytesToRead == 0) // probably means not enough args
	{
		if (isDumpKey)
			RawEntityDumpKey_Usage(clientIdx);
		else
			RawEntityDump_Usage(clientIdx);
		return false;
	}
	else if (bytesToRead < 0)
	{
		if (startPos == 0)
			PrintToConsole(clientIdx, "Length must be a positive number.");
		else
			PrintToConsole(clientIdx, "Start position is greater than length.");
		return false;
	}
	
	// validity of file path
	if (strlen(filePath) == 0)
	{
		if (isDumpKey)
			RawEntityDumpKey_Usage(clientIdx);
		else
			RawEntityDump_Usage(clientIdx);
		return false;
	}
	
	// dump entity raw data to file
	new Handle:file = OpenFile(filePath, "wb");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s. There may be more output in the server console.", filePath);
		return false;
	}
	new buffer[BUFFER_SIZE];
	buffer[0] = '.';
	WriteFile(file, buffer, 1, 1);

	new offset = 1;
	new btrStored = bytesToRead; // for console output later, bytesToRead gets corrupted
	bytesToRead--;
	while (bytesToRead > 0)
	{
		for (new i = 0; i < min(BUFFER_SIZE, bytesToRead); i++)
		{
			if (offset < startPos)
				buffer[i] = '.';
			else
				buffer[i] = GetEntData(entity, offset, 1);
			offset++;
		}
		
		WriteFile(file, buffer, min(BUFFER_SIZE, bytesToRead), 1);
		
		bytesToRead -= BUFFER_SIZE;
	}
	FlushFile(file);
	CloseHandle(file);
	
	// let user know
	PrintToConsole(clientIdx, "Dumped %d bytes to file %s successfully.", btrStored, filePath);
	
	return true;
}

new StoredEntRef = -1;
new StoredClientIdx = -1;
new StoredBytesToRead = 0;
new StoredKey = 0;
new StoredStartPos = 0;
new String:StoredFilePath[ARG_LENGTH];
new String:StoredListenedCommand[ARG_LENGTH];
new bool:DumpNextTick = false;
public Action:OnPlayerRunCmd(clientIdx, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (clientIdx == StoredClientIdx)
	{
		if (DumpNextTick)
		{
			new entity = EntRefToEntIndex(StoredEntRef);
			if (!IsValidEntity(entity))
				PrintToConsole(clientIdx, "Entity no longer valid. Done tracking.");
			else
			{
				new String:filePath[ARG_LENGTH + 2];
				Format(filePath, ARG_LENGTH + 2, "%s.2", StoredFilePath);
				DoRawEntityDump(clientIdx, entity, StoredBytesToRead, filePath, StoredStartPos, true);
			}
			
			StoredClientIdx = -1;
			StoredEntRef = -1;
			DumpNextTick = false;
		}
		else if (buttons & StoredKey)
		{
			new entity = EntRefToEntIndex(StoredEntRef);
			if (!IsValidEntity(entity))
			{
				PrintToConsole(clientIdx, "Entity no longer valid. Done tracking.");
				StoredClientIdx = -1;
				StoredEntRef = -1;
			}
			else
			{
				new String:filePath[ARG_LENGTH + 2];
				Format(filePath, ARG_LENGTH + 2, "%s.1", StoredFilePath);
				DoRawEntityDump(clientIdx, entity, StoredBytesToRead, filePath, StoredStartPos, true);
				DumpNextTick = true;
			}
		}
	}
}

public Action:CommandTrigger(clientIdx, const String:command[], argc)
{
	if (clientIdx == StoredClientIdx)
	{
		// do a dump and trigger one for the next OnPlayerRunCmd
		new entity = EntRefToEntIndex(StoredEntRef);
		if (!IsValidEntity(entity))
		{
			PrintToConsole(clientIdx, "Entity no longer valid. Done tracking.");
			StoredClientIdx = -1;
			StoredEntRef = -1;
		}
		else
		{
			new String:filePath[ARG_LENGTH + 2];
			Format(filePath, ARG_LENGTH + 2, "%s.1", StoredFilePath);
			DoRawEntityDump(clientIdx, entity, StoredBytesToRead, filePath, StoredStartPos, true);
			DumpNextTick = true;
		}

		RemoveCommandListener(CommandTrigger, StoredListenedCommand);
		StoredListenedCommand[0] = 0;
	}
	return Plugin_Continue;
}

public Action:RawEntityDump(clientIdx, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	if (GetCmdArgString(unparsedArgs, ARG_LENGTH) < 1)
	{
		RawEntityDump_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// split the args
	new String:args[4][ARG_LENGTH];
	ExplodeString(unparsedArgs, " ", args, 4, ARG_LENGTH);
	new entity = StringToInt(args[0]);
	new bytesToRead = StringToInt(args[1]);
	new String:filePath[ARG_LENGTH];
	strcopy(filePath, ARG_LENGTH, args[2]);
	new startPos = strlen(args[3]) == 0 ? 0 : StringToInt(args[3]);
	
	// validity of entity, or ability 
	if (entity == 0)
	{
		if (strlen(args[0]) == 0)
		{
			RawEntityDump_Usage(clientIdx);
			return Plugin_Handled;
		}

		// maybe it's a classname instead?
		entity = -1; //MaxClients + 1;
		entity = FindEntityByClassname(entity, args[0]);
		if (!IsValidEntity(entity))
		{
			PrintToConsole(clientIdx, "Could not find any entities with classname %s", args[0]);
			return Plugin_Handled;
		}
	}

	DoRawEntityDump(clientIdx, entity, bytesToRead, filePath, startPos, false);
	
	return Plugin_Handled;
}

public Action:RawEntityDumpKey(clientIdx, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	if (GetCmdArgString(unparsedArgs, ARG_LENGTH) < 1)
	{
		RawEntityDumpKey_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// split the args
	new String:args[5][ARG_LENGTH];
	ExplodeString(unparsedArgs, " ", args, 5, ARG_LENGTH);
	new entity = StringToInt(args[0]);
	new bytesToRead = StringToInt(args[1]);
	new String:keyStr[ARG_LENGTH];
	strcopy(keyStr, ARG_LENGTH, args[2]);
	new key = GetInputKey(keyStr);
	new String:filePath[ARG_LENGTH];
	strcopy(filePath, ARG_LENGTH, args[3]);
	new startPos = strlen(args[4]) == 0 ? 0 : StringToInt(args[4]);	
	
	// validity of entity, or ability 
	if (entity == 0)
	{
		if (strlen(args[0]) == 0)
		{
			RawEntityDumpKey_Usage(clientIdx);
			return Plugin_Handled;
		}
	
		// maybe it's a classname instead?
		entity = -1; //MaxClients + 1;
		entity = FindEntityByClassname(entity, args[0]);
		if (!IsValidEntity(entity))
		{
			PrintToConsole(clientIdx, "Could not find any entities with classname %s", args[0]);
			return Plugin_Handled;
		}
	}
	
	if (DoRawEntityDump(clientIdx, entity, bytesToRead, filePath, startPos, true))
	{
		if (key == 0)
			PrintToConsole(clientIdx, "Invalid key (%s) provided. Will monitor it as a command instead.", keyStr);
		
		// remove old command
		if (strlen(StoredListenedCommand) > 0)
		{
			RemoveCommandListener(CommandTrigger, StoredListenedCommand);
			StoredListenedCommand[0] = 0;
		}
		
		StoredEntRef = EntIndexToEntRef(entity);
		StoredClientIdx = clientIdx;
		StoredBytesToRead = bytesToRead;
		StoredKey = key;
		StoredStartPos = startPos;
		strcopy(StoredFilePath, ARG_LENGTH, filePath);
		if (key == 0)
		{
			strcopy(StoredListenedCommand, ARG_LENGTH, keyStr);
			AddCommandListener(CommandTrigger, StoredListenedCommand);
		}
	}
	
	return Plugin_Handled;
}

public Action:RawEntityDumpFloats(clientIdx, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	if (GetCmdArgString(unparsedArgs, ARG_LENGTH) < 1)
	{
		RawEntityDumpFloats_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// split the args
	new String:args[4][ARG_LENGTH];
	ExplodeString(unparsedArgs, " ", args, 4, ARG_LENGTH);
	new entity = StringToInt(args[0]);
	new bytesToRead = StringToInt(args[1]);
	new String:filePath[ARG_LENGTH];
	strcopy(filePath, ARG_LENGTH, args[2]);
	new startPos = strlen(args[3]) == 0 ? 0 : StringToInt(args[3]);
	
	// validity of entity, or ability 
	if (entity == 0)
	{
		if (strlen(args[0]) == 0)
		{
			RawEntityDumpFloats_Usage(clientIdx);
			return Plugin_Handled;
		}

		// maybe it's a classname instead?
		entity = -1; //MaxClients + 1;
		entity = FindEntityByClassname(entity, args[0]);
		if (!IsValidEntity(entity))
		{
			PrintToConsole(clientIdx, "Could not find any entities with classname %s", args[0]);
			return Plugin_Handled;
		}
	}

	if (!IsValidEntity(entity))
	{
		PrintToConsole(clientIdx, "Entity %d is invalid!", entity);
		return Plugin_Handled;
	}
	
	// dump the floats
	if (startPos < 1)
		startPos = 1;
	bytesToRead -= 3; // since last reliable float starts 3 bytes before the end
	new data;
	new Handle:file = OpenFile(filePath, "w");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s for writing. There may be more output in the server console.", filePath);
		return Plugin_Handled;
	}
	for (new i = startPos; i < bytesToRead; i++)
	{
		data = GetEntData(entity, i, 4);
		WriteFileLine(file, "At offset %d (0x%x) is float: %f [hex: 0x%x]", i, i, data, data);
		FlushFile(file);
	}
	CloseHandle(file);
	
	PrintToConsole(clientIdx, "Wrote to file: %s", filePath);
	
	return Plugin_Handled;
}

/**
 * Diff
 */
#define GIANT_BUFFER_SIZE 32768 // * 4 * 3, heh. this is just horrible. :P
// big inefficient buffers mean less code. besides, you don't want this plugin on your live server so who cares. :P
new fileData[3][GIANT_BUFFER_SIZE];
AnalyzeShort(Handle:file, i, String:prefix[], compIdx1, compIdx2)
{
	new shortOne = fileData[compIdx1][i] + (fileData[compIdx1][i + 1]<<8);
	new shortTwo = fileData[compIdx2][i] + (fileData[compIdx2][i + 1]<<8);
	WriteFileLine(file, "  %s file one short is %d (0x%x), file two short is %d (0x%x)", prefix, shortOne, shortOne, shortTwo, shortTwo);
}

AnalyzeIntFloat(Handle:file, i, String:prefix[], compIdx1, compIdx2)
{
	new intOne = fileData[compIdx1][i] + (fileData[compIdx1][i + 1]<<8) + (fileData[compIdx1][i + 2]<<16) + (fileData[compIdx1][i + 3]<<24);
	new intTwo = fileData[compIdx2][i] + (fileData[compIdx2][i + 1]<<8) + (fileData[compIdx2][i + 2]<<16) + (fileData[compIdx2][i + 3]<<24);
	WriteFileLine(file, "  %s file one int %d (0x%x) -or- float %f, file two int %d (0x%x) -or- float %f", prefix, intOne, intOne, intOne, intTwo, intTwo, intTwo);
}

PerformDiff(clientIdx, String:filename[], fileSize, compIdx1, compIdx2, excludeIdx)
{
	// fix rare case of huge file
	fileSize = min(fileSize, GIANT_BUFFER_SIZE);

	// open the result file
	new String:outFilename[ARG_LENGTH + 4];
	Format(outFilename, ARG_LENGTH + 4, "%s.cmp", filename);
	new Handle:file = OpenFile(outFilename, "w");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s for writing. There may be more output in the server console.", outFilename);
		return;
	}
	
	// time to do our compare
	new excludeCount = 0;
	new diffCount = 0;
	new testI;
	for (new i = 0; i < fileSize; i++)
	{
		if (fileData[compIdx1][i] != fileData[compIdx2][i])
		{
			if (excludeIdx != -1)
			{
				if (fileData[compIdx1][i] != fileData[excludeIdx][i] && fileData[compIdx2][i] != fileData[excludeIdx][i])
				{
					excludeCount++;
					continue;
				}
			}
			
			diffCount++;
		
			WriteFileLine(file, "Offset %d (0x%x) is different. Analysis below:", i, i);
			WriteFileLine(file, "  File one byte is %d (0x%x), file two byte is %d (0x%x)", fileData[compIdx1][i], fileData[compIdx1][i], fileData[compIdx2][i], fileData[compIdx2][i]);
			
			// short analysis current byte
			if (i + 1 < fileSize)
				AnalyzeShort(file, i, "OFFSET-0", compIdx1, compIdx2);
			else
				WriteFileLine(file, "  Not enough bytes remaining for a short.");
			
			// short analysis starting from previous byte
			testI = i - 1;
			if (testI + 1 < fileSize && testI >= 0)
				AnalyzeShort(file, testI, "  OFFSET-1", compIdx1, compIdx2);
				
			// int and float analysis current byte
			if (i + 3 < fileSize)
				AnalyzeIntFloat(file, i, "OFFSET-0", compIdx1, compIdx2);
			else
				WriteFileLine(file, "  Not enough bytes remaining for a short.");
				
			// int and float analysis starting from previous bytes
			testI = i - 1;
			if (testI + 3 < fileSize && testI >= 0)
				AnalyzeIntFloat(file, testI, "  OFFSET-1", compIdx1, compIdx2);
			testI = i - 2;
			if (testI + 3 < fileSize && testI >= 0)
				AnalyzeIntFloat(file, testI, "  OFFSET-2", compIdx1, compIdx2);
			testI = i - 3;
			if (testI + 3 < fileSize && testI >= 0)
				AnalyzeIntFloat(file, testI, "  OFFSET-3", compIdx1, compIdx2);
				
			FlushFile(file);
		}
	}
	if (excludeIdx != -1)
	{
		WriteFileLine(file, "%d bytes of differences were excluded due to all three files being different.", excludeCount);
		FlushFile(file);
	}
	CloseHandle(file);
	
	PrintToConsole(clientIdx, "Wrote to %s successfully. %d diffs found.", outFilename, diffCount);
	if (excludeIdx != -1)
		PrintToConsole(clientIdx, "%d byte differences excluded.", excludeCount);
}

public Action:RawEntityDiff(clientIdx, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	if (GetCmdArgString(unparsedArgs, ARG_LENGTH) < 1)
	{
		RawEntityDiff_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// split the args
	new String:args[2][ARG_LENGTH];
	ExplodeString(unparsedArgs, " ", args, 2, ARG_LENGTH);
	new String:filename1[ARG_LENGTH];
	strcopy(filename1, ARG_LENGTH, args[0]);
	new String:filename2[ARG_LENGTH];
	strcopy(filename2, ARG_LENGTH, args[1]);
	
	// validity
	if (strlen(filename1) == 0 || strlen(filename2) == 0)
	{
		RawEntityDiff_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	new fileOneSize = FileSize(filename1);
	new fileTwoSize = FileSize(filename2);
	if (fileOneSize <= 0)
	{
		PrintToConsole(clientIdx, "Error reading file (does it exist?): %s", filename1);
		return Plugin_Handled;
	}
	else if (fileTwoSize <= 0)
	{
		PrintToConsole(clientIdx, "Error reading file (does it exist?): %s", filename2);
		return Plugin_Handled;
	}
	else if (fileOneSize != fileTwoSize)
	{
		PrintToConsole(clientIdx, "Files are different sizes. %s is %d bytes, %s is %d bytes.", filename1, fileOneSize, filename2, fileTwoSize);
		return Plugin_Handled;
	}
	
	new Handle:file = OpenFile(filename1, "rb");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s. There may be more output in the server console.", filename1);
		return Plugin_Handled;
	}
	FileSeek(file, 0, SEEK_SET);
	ReadFile(file, fileData[0], GIANT_BUFFER_SIZE, 1);
	CloseHandle(file);
	file = OpenFile(filename2, "rb");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s. There may be more output in the server console.", filename2);
		return Plugin_Handled;
	}
	FileSeek(file, 0, SEEK_SET);
	ReadFile(file, fileData[1], GIANT_BUFFER_SIZE, 1);
	CloseHandle(file);
	
	PrintToConsole(clientIdx, "File size is %d", fileOneSize);
	
	PerformDiff(clientIdx, filename1, fileOneSize, 0, 1, -1);
	
	return Plugin_Handled;
}

public Action:RawEntityExcludeDiff(clientIdx, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	if (GetCmdArgString(unparsedArgs, ARG_LENGTH) < 1)
	{
		RawEntityExcludeDiff_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// split the args
	new String:args[4][ARG_LENGTH];
	ExplodeString(unparsedArgs, " ", args, 4, ARG_LENGTH);
	new String:filename1[ARG_LENGTH];
	strcopy(filename1, ARG_LENGTH, args[0]);
	new String:filename2[ARG_LENGTH];
	strcopy(filename2, ARG_LENGTH, args[1]);
	new String:filename3[ARG_LENGTH];
	strcopy(filename3, ARG_LENGTH, args[2]);
	new excludeIdx = StringToInt(args[3]);
	
	// validity
	if (strlen(filename1) == 0 || strlen(filename2) == 0 || strlen(filename3) == 0 || strlen(args[3]) == 0)
	{
		RawEntityExcludeDiff_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// validity of exclude idx
	excludeIdx--;
	if (excludeIdx < 0 || excludeIdx > 2)
	{
		PrintToConsole(clientIdx, "Invalid exclude index. Must be between 1-3. Yours is %d", excludeIdx);
		return Plugin_Handled;
	}
	
	new fileOneSize = FileSize(filename1);
	new fileTwoSize = FileSize(filename2);
	new fileThreeSize = FileSize(filename3);
	if (fileOneSize <= 0)
	{
		PrintToConsole(clientIdx, "Error reading file (does it exist?): %s", filename1);
		return Plugin_Handled;
	}
	else if (fileTwoSize <= 0)
	{
		PrintToConsole(clientIdx, "Error reading file (does it exist?): %s", filename2);
		return Plugin_Handled;
	}
	else if (fileThreeSize <= 0)
	{
		PrintToConsole(clientIdx, "Error reading file (does it exist?): %s", filename3);
		return Plugin_Handled;
	}
	else if (fileOneSize != fileTwoSize || fileTwoSize != fileThreeSize)
	{
		PrintToConsole(clientIdx, "Files are different sizes. %s is %d bytes, %s is %d bytes, %s is %d bytes.", filename1, fileOneSize, filename2, fileTwoSize, filename3, fileThreeSize);
		return Plugin_Handled;
	}
	
	new Handle:file = OpenFile(filename1, "rb");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s. There may be more output in the server console.", filename1);
		return Plugin_Handled;
	}
	FileSeek(file, 0, SEEK_SET);
	ReadFile(file, fileData[0], GIANT_BUFFER_SIZE, 1);
	CloseHandle(file);
	file = OpenFile(filename2, "rb");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s. There may be more output in the server console.", filename2);
		return Plugin_Handled;
	}
	FileSeek(file, 0, SEEK_SET);
	ReadFile(file, fileData[1], GIANT_BUFFER_SIZE, 1);
	CloseHandle(file);
	file = OpenFile(filename3, "rb");
	if (file == INVALID_HANDLE)
	{
		PrintToConsole(clientIdx, "Failed to open file %s. There may be more output in the server console.", filename3);
		return Plugin_Handled;
	}
	FileSeek(file, 0, SEEK_SET);
	ReadFile(file, fileData[2], GIANT_BUFFER_SIZE, 1);
	CloseHandle(file);
	
	PrintToConsole(clientIdx, "File size is %d", fileOneSize);
	
	if (excludeIdx == 0)
		PerformDiff(clientIdx, filename1, fileOneSize, 1, 2, excludeIdx);
	else if (excludeIdx == 1)
		PerformDiff(clientIdx, filename1, fileOneSize, 0, 2, excludeIdx);
	else if (excludeIdx == 2)
		PerformDiff(clientIdx, filename1, fileOneSize, 0, 1, excludeIdx);
	
	return Plugin_Handled;
}

/**
 * Find
 */
public DoFindValue(clientIdx, entity, value, byteLength, maxOffset)
{
	new findCount = 0;

	maxOffset -= byteLength - 1;
	for (new i = 1; i < maxOffset; i++)
	{
		new foundValue = GetEntData(entity, i, byteLength);
		if (value == foundValue)
		{
			PrintToConsole(clientIdx, "Found at offset %d (0x%x)", i, i);
			PrintToServer("Found at offset %d (0x%x)", i, i);
			findCount++;
		}
	}
	
	return findCount;
}
 
public Action:RawEntityFindSimilar(clientIdx, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	if (GetCmdArgString(unparsedArgs, ARG_LENGTH) < 1)
	{
		RawEntityFindSimilar_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// split the args
	new String:args[5][ARG_LENGTH];
	ExplodeString(unparsedArgs, " ", args, 5, ARG_LENGTH);
	new entity = StringToInt(args[0]);
	new bytesToRead = StringToInt(args[1]);
	new String:findSimilarOf[ARG_LENGTH];
	strcopy(findSimilarOf, ARG_LENGTH, args[2]);
	new byteLength = GetByteLength(args[3]);
	new bool:isFloat = !strcmp(args[3], "float");
	new String:netClassname[ARG_LENGTH];
	strcopy(netClassname, ARG_LENGTH, args[4]);
	
	// validity of entity, or ability 
	if (entity == 0)
	{
		if (strlen(args[0]) == 0)
		{
			RawEntityFindSimilar_Usage(clientIdx);
			return Plugin_Handled;
		}
	
		// maybe it's a classname instead?
		entity = -1; //MaxClients + 1;
		entity = FindEntityByClassname(entity, args[0]);
		if (!IsValidEntity(entity))
		{
			PrintToConsole(clientIdx, "Could not find any entities with classname %s", args[0]);
			return Plugin_Handled;
		}
	}
	
	if (!IsValidEntity(entity))
	{
		PrintToConsole(clientIdx, "Entity %d is invalid!", entity);
		return Plugin_Handled;
	}
	
	// ensure net classname and value to find are valid
	if (strlen(netClassname) == 0 || strlen(findSimilarOf) == 0)
	{
		RawEntityFindSimilar_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// ensure byte length is valid
	if (byteLength == -1)
	{
		PrintToConsole(clientIdx, "Bad type specified: %s", args[3]);
		return Plugin_Handled;
	}
	
	// find the offset for the value we want
	new offset = FindSendPropInfo(netClassname, findSimilarOf);
	if (offset <= 0)
	{
		PrintToConsole(clientIdx, "Failed to find offset for %s / %s . Are you sure it's valid?", netClassname, findSimilarOf);
		return Plugin_Handled;
	}
	
	// get the value and use the finder method
	new value = GetEntData(entity, offset, byteLength);
	if (isFloat)
	{
		PrintToConsole(clientIdx, "Searching for values similar to %s / %s, which is a float (%f) at offset %d (0x%x)", netClassname, findSimilarOf, value, offset, offset);
		PrintToServer("Searching for values similar to %s / %s, which is a float (%f) at offset %d (0x%x)", netClassname, findSimilarOf, value, offset, offset);
	}
	else
	{
		PrintToConsole(clientIdx, "Searching for values similar to %s / %s, which is (%d) at offset %d (0x%x)", netClassname, findSimilarOf, value, offset, offset);
		PrintToServer("Searching for values similar to %s / %s, which is (%d) at offset %d (0x%x)", netClassname, findSimilarOf, value, offset, offset);
	}
	DoFindValue(clientIdx, entity, value, byteLength, bytesToRead);
	
	return Plugin_Handled;
}

public Action:RawEntityFindValue(clientIdx, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	if (GetCmdArgString(unparsedArgs, ARG_LENGTH) < 1)
	{
		RawEntityFindValue_Usage(clientIdx);
		return Plugin_Handled;
	}
	
	// split the args
	new String:args[4][ARG_LENGTH];
	ExplodeString(unparsedArgs, " ", args, 4, ARG_LENGTH);
	new entity = StringToInt(args[0]);
	new bytesToRead = StringToInt(args[1]);
	new byteLength = GetByteLength(args[3]);
	new bool:isFloat = !strcmp(args[3], "float");
	new any:value;
	if (isFloat)
		value = StringToFloat(args[2]);
	else
		value = StringToInt(args[2]);
	
	// validity of entity, or ability 
	if (entity == 0)
	{
		if (strlen(args[0]) == 0)
		{
			RawEntityFindValue_Usage(clientIdx);
			return Plugin_Handled;
		}
	
		// maybe it's a classname instead?
		entity = -1; //MaxClients + 1;
		entity = FindEntityByClassname(entity, args[0]);
		if (!IsValidEntity(entity))
		{
			PrintToConsole(clientIdx, "Could not find any entities with classname %s", args[0]);
			return Plugin_Handled;
		}
	}
	
	if (!IsValidEntity(entity))
	{
		PrintToConsole(clientIdx, "Entity %d is invalid!", entity);
		return Plugin_Handled;
	}
	
	// ensure byte length is valid
	if (byteLength == -1)
	{
		PrintToConsole(clientIdx, "Bad type specified: %s", args[3]);
		return Plugin_Handled;
	}

	if (isFloat)
	{
		PrintToConsole(clientIdx, "Searching for float (%f) in entity %d", value, entity);
		PrintToServer("Searching for float (%f) in entity %d", value, entity);
	}
	else
	{
		PrintToConsole(clientIdx, "Searching for value (%d) in entity %d", value, entity);
		PrintToServer("Searching for value (%d) in entity %d", value, entity);
	}
	
	// find this value!
	new findCount = DoFindValue(clientIdx, entity, value, byteLength, bytesToRead);
	PrintToConsole(clientIdx, "Found %d instances.", findCount);
	PrintToServer("Found %d instances.", findCount);
	
	return Plugin_Handled;
}

/**
 * Helper stocks
 */
stock min(i1, i2) { return i1 > i2 ? i2 : i1; }

stock GetInputKey(const String:keyStr[ARG_LENGTH])
{
	if (!strcmp(keyStr, "IN_ATTACK"))
		return IN_ATTACK;
	else if (!strcmp(keyStr, "IN_JUMP"))
		return IN_JUMP;
	else if (!strcmp(keyStr, "IN_DUCK"))
		return IN_DUCK;
	else if (!strcmp(keyStr, "IN_FORWARD"))
		return IN_FORWARD;
	else if (!strcmp(keyStr, "IN_BACK"))
		return IN_BACK;
	else if (!strcmp(keyStr, "IN_USE"))
		return IN_USE;
	else if (!strcmp(keyStr, "IN_CANCEL"))
		return IN_CANCEL;
	else if (!strcmp(keyStr, "IN_LEFT"))
		return IN_LEFT;
	else if (!strcmp(keyStr, "IN_RIGHT"))
		return IN_RIGHT;
	else if (!strcmp(keyStr, "IN_MOVELEFT"))
		return IN_MOVELEFT;
	else if (!strcmp(keyStr, "IN_MOVERIGHT"))
		return IN_MOVERIGHT;
	else if (!strcmp(keyStr, "IN_ATTACK2"))
		return IN_ATTACK2;
	else if (!strcmp(keyStr, "IN_RUN"))
		return IN_RUN;
	else if (!strcmp(keyStr, "IN_RELOAD"))
		return IN_RELOAD;
	else if (!strcmp(keyStr, "IN_ALT1"))
		return IN_ALT1;
	else if (!strcmp(keyStr, "IN_ALT2"))
		return IN_ALT2;
	else if (!strcmp(keyStr, "IN_SCORE"))
		return IN_SCORE;
	else if (!strcmp(keyStr, "IN_SPEED"))
		return IN_SPEED;
	else if (!strcmp(keyStr, "IN_WALK"))
		return IN_WALK;
	else if (!strcmp(keyStr, "IN_ZOOM"))
		return IN_ZOOM;
	else if (!strcmp(keyStr, "IN_WEAPON1"))
		return IN_WEAPON1;
	else if (!strcmp(keyStr, "IN_WEAPON2"))
		return IN_WEAPON2;
	else if (!strcmp(keyStr, "IN_BULLRUSH"))
		return IN_BULLRUSH;
	else if (!strcmp(keyStr, "IN_GRENADE1"))
		return IN_GRENADE1;
	else if (!strcmp(keyStr, "IN_GRENADE2"))
		return IN_GRENADE2;
	else if (!strcmp(keyStr, "IN_ATTACK3"))
		return IN_ATTACK3;
		
	return 0;
}

stock GetByteLength(String:type[])
{
	if (!strcmp(type, "int"))
		return 4;
	else if (!strcmp(type, "integer"))
		return 4;
	else if (!strcmp(type, "short"))
		return 2;
	else if (!strcmp(type, "byte"))
		return 1;
	else if (!strcmp(type, "bool"))
		return 1;
	else if (!strcmp(type, "boolean"))
		return 1;
	else if (!strcmp(type, "float"))
		return 4;
		
	return -1;
}
