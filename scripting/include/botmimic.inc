#if defined _botmimic_included
  #endinput
#endif
#define _botmimic_included

#define MAX_RECORD_NAME_LENGTH 64
#define MAX_BOOKMARK_NAME_LENGTH 64
#define DEFAULT_CATEGORY "default"

enum BMError {
	BM_NoError = 0,
	BM_BadClient, // Provided client index is invalid
	BM_FileNotFound, // The file does not exists or can't be opened
	BM_BadFile, // Not a Bot Mimic record.
	BM_NewerBinaryVersion // The record was recorded with a newer version of Bot Mimic and can't be played.
}

enum BMFileHeader {
	BMFH_binaryFormatVersion = 0,
	BMFH_recordEndTime,
	String:BMFH_recordName[MAX_RECORD_NAME_LENGTH],
	BMFH_tickCount,
	Float:BMFH_initialPosition[3],
	Float:BMFH_initialAngles[3],
	BMFH_bookmarkCount
}

/**
 * Start to record the movements of a player.
 * It's stored in memory until told to write to disk.
 * 
 * Make sure the player isn't recording already.
 * 
 * @param client	The client to record
 * @param name		The name of the record (anything, not the filename)
 * @param category	The category to put this record in. This is used as a directory filename inside /data/botmimic/%CATEGORY%/%MAP_NAME%/stuff.rec
 * @param subdir	The subdirectory to organize records physically. This isn't used or retrieved back anywhere, just to better manage files by hand. /data/botmimic/%CATEGORY%/%MAP_NAME%/%SUBDIR%/stuff.rec
 * @noreturn
 */
native BotMimic_StartRecording(client, const String:name[], const String:category[]="", const String:subdir[]="");

/**
 * Pause recording the current record.
 * 
 * @param client	The recording client, which should pause recording.
 * @noreturn
 * @error			Invalid client index, client not recording or recording already paused.
 */
native BotMimic_PauseRecording(client);

/**
 * Resume recording the current record.
 * 
 * @param client		The recording client, which should resume recording.
 * @noreturn
 * @error				Invalid client index, client not recording or record not paused.
 */
native BotMimic_ResumeRecording(client);

/**
 * Check whether a client is currently paused recording a record.
 *
 * @param client	The client index of the player you want to know if he's paused.
 * @return			True if recording is paused, false otherwise.
 * @error			Invalid client index or client not recording.
 */
native bool:BotMimic_IsRecordingPaused(client);

/**
 * Stop recording and save or discard the record
 * 
 * @param client	The client which was recording
 * @param save		Save the record (true) or discard (false)
 * @noreturn
 */
native BotMimic_StopRecording(client, bool:save=true);

/**
 * Save the current frame with the given name as bookmark.
 * You can skip to this point when playing back the record using BotMimic_GoToBookmark.
 *
 * @param client	The client which is recording
 * @param name		The name of this bookmark
 * @noreturn
 * @error	Client not recording
 */
native BotMimic_SaveBookmark(client, const String:name[]);

/**
 * Deletes a record and does some checks, that the file is really a record.
 * 
 * @param path		The Path to the .rec recording file to delete.
 * @return			Number of bots, which were mimicing this record or -1 on error (file not found/invalid)
 */
native BotMimic_DeleteRecord(const String:path[]);

/**
 * Is the player currently recording something?
 * 
 * @param client	The client to check
 * @return			true, if player is recording, false otherwise
 */
native bool:BotMimic_IsPlayerRecording(client);

/**
 * Is the player currently mimicing something?
 * 
 * @param client	The client to check
 * @return			true, if the player is mimicing, false otherwise
 */
native bool:BotMimic_IsPlayerMimicing(client);

/**
 * Get the path to the record file this player is currently mimicing.
 *
 * @param client	The mimicing client
 * @param path		A String where to store the path
 * @param maxlen	The maximal length of the path
 * @noreturn
 */
native BotMimic_GetRecordPlayerMimics(client, String:path[], maxlen);

/**
 * Let a client start to mimic a record from a file.
 *
 * @param client	The client, which should start mimicing
 * @param path		The path to a .rec recording file
 * @return			BM_NoError if all went smooth, see BMError definition.
 */
native BMError:BotMimic_PlayRecordFromFile(client, const String:path[]);

/**
 * Let a client start to mimic a record by providing the record name.
 * Since record names don't have to be unique, this native picks the most recent one.
 *
 * @param client	The client, which should start mimicing.
 * @param name		The name of the record to play.
 * @return			BM_NoError if all went smooth, see BMError definition.
 */
native BMError:BotMimic_PlayRecordByName(client, const String:name[]);

/**
 * Have a bot restart the record he's currently playing from the beginning.
 *
 * @param client   The client, who should start over with the record he's currently mimicing.
 * @noreturn
 */
native BotMimic_ResetPlayback(client);

/**
 * Jump the the frame where this bookmark was set in the record.
 * @see BotMimic_SaveBookmark
 *
 * @param client	The client, which is mimicing some record
 * @param name		The name of the bookmark saved during recording using BotMimic_SaveBookmark
 * @noreturn
 */
native BotMimic_GoToBookmark(client, const String:name[]);

/**
 * Stops a player from mimicing a record.
 *
 * @param client	The client who should stop mimicing
 * @noreturn
 */
native BotMimic_StopPlayerMimic(client);

/**
 * Get the Handle to a sorted adt_array, containing a list of paths to all loaded record files.
 * DON'T CLOSE THIS HANDLE!
 * Just use GetArrayString to read the path.
 *
 * @return Handle to sorted adt_array containing all paths to records
 */
native Handle:BotMimic_GetLoadedRecordList();

/**
 * Get the Handle to a sorted adt_array, containing a list of categorys.
 * DON'T CLOSE THIS HANDLE!
 * Just use GetArrayString to read the category.
 *
 * @return Handle to sorted adt_array containing all categories.
 */
native Handle:BotMimic_GetLoadedRecordCategoryList();

/**
 * Get the header information of a record. This includes the record name.
 *
 * @param path	The path to the .rec record file
 * @param iFileHeader	An array to store the file header in.
 * @return			BM_NoError if all went smooth, see BMError definition.
 */
native BMError:BotMimic_GetFileHeaders(const String:path[], iFileHeader[BMFileHeader], size=_:BMFileHeader);

/**
 * Get the category of a record.
 *
 * @param path			The path to the .rec record file.
 * @param category	The String where to store the category in.
 * @param maxlen		The maximal length of the category buffer.
 * @return				true if category of file found, false otherwise
 */
native bool:BotMimic_GetFileCategory(const String:path[], String:category[], maxlen);

/**
 * Change the name of a record. This doesn't change the filename, but the stored record name inside the file. (BMTP_recordName)
 *
 * @param path	The path to the .rec record file which name to change.
 * @param name	The new name of the record
 * @return			BM_NoError if all went smooth, see BMError definition.
 */
native BMError:BotMimic_ChangeRecordName(const String:path[], String:name[]);

/**
 * Get a list of all bookmarks stored in this record as an adt_array.
 * You have to close the returned Handle using CloseHandle.
 *
 * @param path		The path to the .rec record file.
 * @param bookmarks	The handle where the bookmark array will be stored in.
 * @return			BM_NoError if all went smooth, see BMError definition.
 */
native BMError:BotMimic_GetRecordBookmarks(const String:path[], &Handle:bookmarks);

/**
 * Called when a player starts recording.
 * path is NOT the path to the .rec file, but just the path to the category folder (by default: Path_SM/data/botmimic/%CATEGORY%)
 *
 * @param client	The client index, who's being recorded
 * @param name		The name of the recording (stored in file header)
 * @param category	The category name
 * @param subdir	The subdir used to organize the record files (no further sense..)
 * @param path		The path to the category folder
 * @return			>= Plugin_Handled to abort recording or Plugin_Continue to let it pass and start recording.
 */
forward Action:BotMimic_OnStartRecording(client, String:name[], String:category[], String:subdir[], String:path[]);

/**
 * Called when recording a record is paused or resumed.
 *
 * @param client	The client which recording pause state changed
 * @param paused	True when the recording was paused, false when it was unpaused
 * @noreturn
 */
forward BotMimic_OnRecordingPauseStateChanged(client, bool:paused);

/**
 * Called when a bookmark is saved while the client is recording.
 *
 * @param client	The client which is recording.
 * @param bookmark	The name of the saved bookmark.
 * @noreturn
 */
forward BotMimic_OnRecordingBookmarkSaved(client, const String:bookmark[]);

/**
 * Called when a player stops recording.
 * Change the save param if you want to prevent it from being discarded/written.
 *
 * @param client		The client who was recording.
 * @param name			The name of the record (stored in file header)
 * @param category	The category name.
 * @param subdir		The subdir used to organize the record files (no further sense..)
 * @param path			The path to the category folder
 * @param save			Set to true, if the record should be stored to disk, or false to discard.
 * @return				>= Plugin_Handled to continue recording, Plugin_Continue to let it stop.
 */
forward Action:BotMimic_OnStopRecording(client, String:name[], String:category[], String:subdir[], String:path[], &bool:save);

/**
 * Called when a record was saved to file.
 *
 * @param client		The client who was recording.
 * @param name			The name of the record (stored in file header)
 * @param category	The category name.
 * @param subdir		The subdir used to organize the record files (no further sense..)
 * @param file			The actual path to the saved .rec file.
 * @noreturn
 */
forward BotMimic_OnRecordSaved(client, String:name[], String:category[], String:subdir[], String:file[]);

/**
 * Called when a record was deleted.
 * 
 * @param name		The name of the record (stored in file header)
 * @param category	The category of the file. (If it wasn't loaded before it defaults to "default".)
 * @param path		The path to the deleted file.
 * @noreturn;
 */
forward BotMimic_OnRecordDeleted(String:name[], String:category[], String:path[]);

/**
 * Called when a player starts to mimic a record
 *
 * @param client		The client which starts mimicing.
 * @param name			The name of the record (stored in file header)
 * @param category	The category of the file.
 * @param path			The path to the record file.
 * @return 					>= Plugin_Handled to stop the player from mimicing, Plugin_Continue to allow
 */
forward Action:BotMimic_OnPlayerStartsMimicing(client, String:name[], String:category[], String:path[]);

/**
 * Called when a player stops mimicing a record.
 *
 * @param client		The client who was mimicing
 * @param name			The name of the record (stored in file header)
 * @param category	The category of the file.
 * @param path			The path to the record file.
 * @noreturn
 */
forward BotMimic_OnPlayerStopsMimicing(client, String:name[], String:category[], String:path[]);

/**
 * Called everytime a mimicing player starts to mimic the record again from the beginning,
 * when he was teleported back to the start.
 *
 * @param client		The mimicing client
 * @noreturn
 */
forward BotMimic_OnPlayerMimicLoops(client);

/**
 * Called when a bookmark is reached during playback of a record.
 *
 * @param client	The client which is mimicing.
 * @param bookmark	The name of the bookmark.
 * @noreturn
 */
forward BotMimic_OnPlayerMimicBookmark(client, const String:bookmark[]);

/**
 * Translate an error id to a human readable string
 * 
 * @param error		The error id
 * @param str		The string to store the error message in
 * @param maxlen	The maximal length of the error message string
 * @noreturn
 */
stock BotMimic_GetErrorString(BMError:error, String:str[], maxlen)
{
	switch(error)
	{
		case BM_BadClient:
		{
			strcopy(str, maxlen, "Invalid client index.");
		}
		case BM_FileNotFound:
		{
			strcopy(str, maxlen, "File not found.");
		}
		case BM_NewerBinaryVersion:
		{
			strcopy(str, maxlen, "The file was recorded with a newer version of Bot Mimic and can't be played.");
		}
		case BM_BadFile:
		{
			strcopy(str, maxlen, "The file is not a record. Bad format.");
		}
		case BM_NoError:
		{
			strcopy(str, maxlen, "");
		}
	}
}

public SharedPlugin:__pl_botmimic = 
{
	name = "botmimic",
	file = "botmimic.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_botmimic_SetNTVOptional()
{
	MarkNativeAsOptional("BotMimic_StartRecording");
	MarkNativeAsOptional("BotMimic_PauseRecording");
	MarkNativeAsOptional("BotMimic_ResumeRecording");
	MarkNativeAsOptional("BotMimic_IsRecordingPaused");
	MarkNativeAsOptional("BotMimic_StopRecording");
	MarkNativeAsOptional("BotMimic_SaveBookmark");
	MarkNativeAsOptional("BotMimic_GoToBookmark");
	MarkNativeAsOptional("BotMimic_DeleteRecord");
	MarkNativeAsOptional("BotMimic_IsPlayerRecording");
	MarkNativeAsOptional("BotMimic_IsPlayerMimicing");
	MarkNativeAsOptional("BotMimic_GetRecordPlayerMimics");
	MarkNativeAsOptional("BotMimic_PlayRecordFromFile");
	MarkNativeAsOptional("BotMimic_PlayRecordByName");
	MarkNativeAsOptional("BotMimic_StopPlayerMimic");
	MarkNativeAsOptional("BotMimic_GetLoadedRecordCategoryList");
	MarkNativeAsOptional("BotMimic_GetLoadedRecordList");
	MarkNativeAsOptional("BotMimic_GetFileHeaders");
	MarkNativeAsOptional("BotMimic_GetFileCategory");
	MarkNativeAsOptional("BotMimic_ChangeRecordName");
	MarkNativeAsOptional("BotMimic_GetRecordBookmarks");
}
#endif