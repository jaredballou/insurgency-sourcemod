// Keyvalue Storage
//#define ANTITK_KV_FILE "AntiTK.txt"

new String:AntiTK_DataFile[PLATFORM_MAX_PATH];

new Handle:g_kv_AntiTK = INVALID_HANDLE;
new LastTKPurge = 0;

new String:arrayPlayerIDs[MAXPLAYERS + 1][MAX_NETWORKID_LENGTH];

// Create KeyValue Data Path.
BuildKeyValuePath()
{
	// Build Data File Path
	BuildPath(Path_SM, AntiTK_DataFile, sizeof(AntiTK_DataFile), "data/AntiTK.txt");
	LogAction(0, -1, "[Anti-TK Manager] Data File: %s", AntiTK_DataFile);
}

// Read All TKer Information from Keyvalue file.
ReadTKers()
{
	LogDebug(false, "ReadTKers - Reading all TK'ers from Keyvalue file: %s", AntiTK_DataFile);

	if (g_kv_AntiTK == INVALID_HANDLE)
	{
		LogDebug(false, "ReadTKers - Keyvalues Handle is invalid (May not have been read yet)");
		g_kv_AntiTK = CreateKeyValues("Anti-TK");
	}
	else
		LogDebug(false, "ReadTKers - Keyvalues Handle is valid (File has probably already been read?)");

	FileToKeyValues(g_kv_AntiTK, AntiTK_DataFile);
}

SaveTKFile(Handle:file_handle)
{
	// Safety Precation?
	KvRewind(file_handle);
	KeyValuesToFile(file_handle, AntiTK_DataFile);	
}

// Save All TKer data to Keyvalue file.
SaveTKers()
{
	LogDebug(false, "SaveTKers - Saving all TK'ers to Keyvalue file: %s", AntiTK_DataFile);

	if (g_kv_AntiTK == INVALID_HANDLE)
		LogDebug(false, "SaveTKers - Keyvalues Handle is invalid? (This should probably not happen)");
	else
		SaveTKFile(g_kv_AntiTK);

	CloseHandle(g_kv_AntiTK);
	g_kv_AntiTK = INVALID_HANDLE;
}

// Purge Old TK'er data that has expired?
bool:PurgeTKerData(const purgetime, checklast = false)
{
	new time = GetTime();
#if _DEBUG >= 2
	LogDebug(false, "PurgeTKerData - Checking Old TKer data. LastPurge: %d Time: %d", LastTKPurge, time);
#endif

	if (checklast)
		if ((time - LastTKPurge) >= purgetime)
		{
			LogDebug(false, "PurgeTKerData - Old TKer data being purged: LastPurge: %d Time: %d", LastTKPurge, time);
		}
		else
			return false;

	if (g_kv_AntiTK == INVALID_HANDLE)
	{
		LogDebug(false, "PurgeTKerData - Keyvalues Handle is invalid? Attempting to read file?");
		ReadTKers();
	}

	LogDebug(false, "PurgeTKerData - TKer's are being checked.");

	new bool:check_record = true;
	decl savetime;
	decl String:steam_id[MAX_NETWORKID_LENGTH];

	if (KvGotoFirstSubKey(g_kv_AntiTK))
	{
		LogDebug(false, "PurgeTKerData - Starting loop");
		do
		{
			check_record = true;

			do
			{
				savetime = KvGetNum(g_kv_AntiTK, "saved");
				LogDebug(false, "PurgeTKerData - Record Retrieved: Time: %i Saved: %i", time, savetime);

				if (savetime > 0)
				{
					if ((time - savetime) >= purgetime)
					{
						if ( KvGetSectionName(g_kv_AntiTK, steam_id, sizeof(steam_id)) )
							LogDebug(false, "PurgeTKerData - Deleting record %s.", steam_id);
						else
							LogDebug(false, "PurgeTKerData - Deleting record... could not retrieve record name");

						if (KvDeleteThis(g_kv_AntiTK) < 1)
							check_record = false;
					}
					else
						check_record = false;
				}
				else
					check_record = false;
			} while (check_record);
		} while(KvGotoNextKey(g_kv_AntiTK));
	}
	else
		LogDebug(false, "PurgeTKerData - Could not get first Key?");


	LastTKPurge = time;
	SaveTKFile(g_kv_AntiTK);
	return true;
}

// Retrieve stored TKer data for players steamid.
bool:RetrieveTKer(client)
{
	// Retrieve Steam ID
	GetClientAuthString(client, arrayPlayerIDs[client], MAX_NETWORKID_LENGTH);

#if _DEBUG >= 2
	LogDebug(false, "RetrieveTKer - Reading TK'er data for: %s", arrayPlayerIDs[client]);
#endif

	if (g_kv_AntiTK == INVALID_HANDLE)
	{
		LogDebug(false, "RetrieveTKer - Keyvalues Handle is invalid? (This should not happen)");
		ReadTKers();
	}

	// Rewind File
	KvRewind(g_kv_AntiTK);

	if (KvJumpToKey(g_kv_AntiTK, arrayPlayerIDs[client]))
	{
#if _DEBUG >= 2
		LogDebug(false, "RetrieveTKer - Found Key: %s", arrayPlayerIDs[client]);
#endif
		arrayPlayerStats[client][STAT_KARMA] = KvGetNum(g_kv_AntiTK, "karma");
		arrayPlayerStats[client][STAT_KILLS] = KvGetNum(g_kv_AntiTK, "kills");
		arrayPlayerStats[client][STAT_TEAM_KILLS] = KvGetNum(g_kv_AntiTK, "tks");
		KvRewind(g_kv_AntiTK);
		return true;
	}
	else
	{
#if _DEBUG >= 2
		LogDebug(false, "RetrieveTKer - Failed? Key Not Found.");
#endif
		return false;
	}
}

bool:SaveTKer(client)
{
#if _DEBUG >= 2
	LogDebug(false, "SaveTKer - Saving TK'er data for: %s", arrayPlayerIDs[client]);
#endif

	if (g_kv_AntiTK == INVALID_HANDLE)
	{
		LogDebug(false, "SaveTKer - Keyvalues Handle is invalid? (This should not happen)");
		ReadTKers();
	}

	// Safety Precaution
	KvRewind(g_kv_AntiTK);
	if (!StrEqual(arrayPlayerIDs[client], ""))
	{
		KvJumpToKey(g_kv_AntiTK,arrayPlayerIDs[client],true);
	
		// Store Values
		KvSetNum(g_kv_AntiTK, "karma", arrayPlayerStats[client][STAT_KARMA]);
		KvSetNum(g_kv_AntiTK, "kills", arrayPlayerStats[client][STAT_KILLS]);
		KvSetNum(g_kv_AntiTK, "tks", arrayPlayerStats[client][STAT_TEAM_KILLS]);
		KvSetNum(g_kv_AntiTK, "saved", GetTime());
	
		SaveTKFile(g_kv_AntiTK);
	
		arrayPlayerIDs[client] = "";

		return true;
	}
	return false;
}

bool:RemoveTKer(const String:steamid[])
{
	LogDebug(false, "RemoveTKer - Removing TK'er data for: %s", steamid);

	if (g_kv_AntiTK == INVALID_HANDLE)
	{
		LogDebug(false, "RemoveTKer - Keyvalues Handle is invalid? (This should not happen)");
		ReadTKers();
	}

	if (KvGotoFirstSubKey(g_kv_AntiTK))
	{
		if (KvJumpToKey(g_kv_AntiTK, steamid))
		{
			KvDeleteThis(g_kv_AntiTK);
			KvRewind(g_kv_AntiTK);
			return true;
		}
		else
			return false;
	}
	else
		return false;
}

/*
DeleteAllTKers()
{
#if _DEBUG
	LogAction(0, -1, "DeleteAllTKers - Removing all TKer data.");
#endif
	if (g_kv_AntiTK == INVALID_HANDLE)
	{
#if _DEBUG
	LogAction(0, -1, "DeleteAllTKers - Keyvalues Handle is invalid? (This should not happen)");
#endif
	}
	if (!KvGotoFirstSubKey(g_kv_AntiTK))
	{
		return;
	}

	for (;;)
	{
		decl String:name[4];
		KvGetString(g_kv_AntiTK, name, sizeof(name))
		if (name[0] == '\0')
		{
			if (KvDeleteThis(g_kv_AntiTK) < 1)
			{
				break;
			}
		} else if (!KvGotoNextKey(g_kv_AntiTK)) {
			break;
		}
	}
}
*/