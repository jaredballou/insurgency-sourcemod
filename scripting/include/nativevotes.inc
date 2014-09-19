/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes
 * Copyright (C) 2011-2013 Ross Bemrose (Powerlord).  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
 
#include <menus>
#include <sourcemod>

// NativeVotes 0.8 series

#if defined _nativevotes_included
 #endinput
#endif
#define _nativevotes_included

#define CLIENT_DISCONNECTED			-1

#define NATIVEVOTES_EXTEND 			"Extend current Map" /** Defined in TF2, but doesn't appear to be localized */

#define NATIVEVOTES_ALL_TEAMS		-1 // Defined by TF2, may be the same in L4D/L4D2
#define NATIVEVOTES_SERVER_INDEX 	99 // Defined by TF2, may be the same in L4D/L4D2

// These may seem backwards, but this is the order that the votes appear in the vote screen
#define NATIVEVOTES_VOTE_INVALID	-1		/**< Vote was invalid, currently only valid internally */
#define NATIVEVOTES_VOTE_YES		0		/**< Vote was yes */
#define NATIVEVOTES_VOTE_NO			1		/**< Vote was no */

/*
The following MenuActions are supported.  Arguments are also listed, as they differ slightly from the default
MenuAction_Start		A menu has been started (nothing passed). Only exists for compat reasons.
MenuAction_Display		A menu is about to be displayed (param1=client). If you choose to change the vote text,
 						To change the text, use RedrawVoteTitle()
						If you do so, return 1 or _:Plugin_Changed  Otherwise, return _:Plugin_Continue or 0.
MenuAction_Select		An item was selected (param1=client, param2=item). For subplugin support.
MenuAction_End			A vote has fully ended and the vote object is ready to be cleaned up
						param1 is MenuEnd reason, either MenuEnd_VotingCancelled or MenuEnd_VotingDone
MenuAction_VoteEnd		A vote sequence has succeeded (param1=chosen item) 
						This is not called if NativeVotes_SetResultCallback has been used on the vote.
						You should call NativeVotes_DisplayPass or NativeVotes_DisplayPassEx after this
MenuAction_VoteStart	A vote sequence has started (nothing passed).  Use this instead of MenuAction_Start
MenuAction_VoteCancel	A vote sequence has been cancelled (param1=reason)
MenuAction_DisplayItem	Item text is being drawn to the display (param1=client, param2=item)
						To change the text, use RedrawVoteItem().
						If you do so, return 1 or _:Plugin_Changed.  Otherwise, return _:Plugin_Continue or 0.
*/

#define NATIVEVOTES_ACTIONS_DEFAULT		MenuAction_VoteStart|MenuAction_VoteCancel|MenuAction_VoteEnd|MenuAction_End

/**
 * Vote types. These are mapped to translation strings and pass strings by VoteStart and VotePass handlers
 */
enum NativeVotesType
{
	NativeVotesType_None = 0,		/** Special placeholder for callvote with no arguments for NativeVotes_OnCallVote */
	NativeVotesType_Custom_YesNo,	/**< Yes/No, details are vote text. */
	NativeVotesType_Custom_Mult,	/**< TF2/CS:GO: Multiple-choice, details are vote text. */
	NativeVotesType_ChgCampaign,	/**< L4D/L4D2: Yes/No, details are campaign name */
	NativeVotesType_ChgDifficulty,	/**< L4D/L4D2: Yes/No, details are difficulty number in L4D/L4D2 */
	NativeVotesType_ReturnToLobby,	/**< L4D/L4D2: Yes/No, details are ignored */
	NativeVotesType_AlltalkOn,		/**< L4D2: Yes/No, details are ignored (handled internally by extension) */
	NativeVotesType_AlltalkOff,		/**< L4D2: Yes/No, details are ignored (handled internally by extension) */
	NativeVotesType_Restart,		/**< Yes/No, details are ignored */
	NativeVotesType_Kick,			/**< Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_KickIdle,		/**< TF2/CS:GO: Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_KickScamming,	/**< TF2/CS:GO: Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_KickCheating,	/**< TF2/CS:GO: Yes/No, target is player userid, details are auto-set by target */
	NativeVotesType_ChgLevel,		/**< Yes/No, details are level number in L4D/L4D2 or map name in TF2 */
	NativeVotesType_NextLevel,		/**< TF2/CS:GO: Yes/No, details are map name */
	NativeVotesType_NextLevelMult,	/**< TF2/CS:GO: Multiple-choice, details are ignored */
	NativeVotesType_ScrambleNow,	/**< TF2/CS:GO: Yes/No, details are ignored */
	NativeVotesType_ScrambleEnd,	/**< TF2: Yes/No, details are ignored */
	NativeVotesType_ChgMission,		/**< TF2: Yes/No, details are popfile */
	NativeVotesType_SwapTeams,		/**< CS:GO: Yes/No, details are ignored */
	NativeVotesType_Surrender,		/**< CS:GO: Yes/No, details are ignored */
	NativeVotesType_Rematch,		/**< CS:GO: Yes/No, details are ignored */
	NativeVotesType_Continue,		/**< CS:GO: Yes/No, details are ignored */
};

enum NativeVotesPassType
{
	NativeVotesPass_None = 0,			/**< Special placeholder for error value */
	NativeVotesPass_Custom,				/**< Details are custom pass message */
	NativeVotesPass_ChgCampaign,		/**< L4D/L4D2: Details are campaign name */
	NativeVotesPass_ChgDifficulty,		/**< L4D/L4D2/TF2: Details are difficulty number in L4D/L4D2 and mission name in TF2 */
	NativeVotesPass_ReturnToLobby,      /**< L4D/L4D2: Details are ignored */
	NativeVotesPass_AlltalkOn,			/**< L4D2: Details are ignored */
	NativeVotesPass_AlltalkOff,			/**< L4D2: Details are ignored */
	NativeVotesPass_Restart,			/**< Details are ignored */
	NativeVotesPass_Kick,				/**< Details are player name */
	NativeVotesPass_ChgLevel,			/**< Details are level number in L4D/L4D2 or map name in TF2/CS:GO */
	NativeVotesPass_NextLevel,			/**< TF2/CS:GO: Details are map name */
	NativeVotesPass_Extend,				/**< TF2/CS:GO: Details are ignored */
	NativeVotesPass_Scramble,			/**< TF2/CS:GO: Details are ignored */
	NativeVotesPass_ChgMission,			/**< TF2: Details are popfile */
	NativeVotesPass_SwapTeams,			/**< CS:GO: Details are ignored */
	NativeVotesPass_Surrender,			/**< CS:GO: Details are ignored */
	NativeVotesPass_Rematch,			/**< CS:GO: Details are ignored */
	NativeVotesPass_Continue,			/**< CS:GO: Details are ignored */
};

/**
 * Reasons a vote was canceled.  Not used for L4D/L4D2, as they don't care
 */
enum NativeVotesFailType
{
	NativeVotesFail_Generic = 0,		/**< Vote was generically cancelled. */
	NativeVotesFail_Loses = 3,			/**< No votes outnumbered Yes votes */
	NativeVotesFail_NotEnoughVotes = 4,	/**< Vote did not receive enough votes. */
};

/**
 * Reasons a callvote command failed.
 * This is provided as a convenience to plugin authors as it's not strictly part of the vote system
 */
enum NativeVotesCallFailType
{
	NativeVotesCallFail_Generic = 0,			/**< Generic fail. */
	NativeVotesCallFail_Loading = 1,			/**< L4D/L4D2: Players are still loading. */
	NativeVotesCallFail_Recent = 2,				/**< TF2/CS:GO: You can't call another vote yet: Argument is seconds until you can call another vote. */
	NativeVotesCallFail_Disabled = 5,			/**< TF2/CS:GO: Server has disabled that issue. */
	NativeVotesCallFail_MapNotFound = 6,		/**< TF2/CS:GO: Server does not have that map. */
	NativeVotesCallFail_SpecifyMap = 7,			/**< TF2/CS:GO: You must specify a map. */
	NativeVotesCallFail_Failed = 8,				/**< TF2/CS:GO: This vote failed recently. */
	NativeVotesCallFail_WrongTeam = 9,			/**< TF2/CS:GO: Team can't call this vote. */
	NativeVotesCallFail_Waiting = 10,			/**< TF2/CS:GO: Vote can't be called during Waiting For Players. */
	NativeVotesCallFail_PlayerNotFound = 11,	/**< TF2/CS:GO: Player to kick can't be found. Buggy in TF2. */
	NativeVotesCallFail_Unknown = 11,
	NativeVotesCallFail_CantKickAdmin = 12,		/**< TF2/CS:GO: Can't kick server admin. */
	NativeVotesCallFail_ScramblePending = 13,	/**< TF2/CS:GO: Team Scramble is pending.. */
	NativeVotesCallFail_Spectators = 14,		/**< TF2/CS:GO: Spectators aren't allowed to call votes. */
	NativeVotesCallFail_LevelSet = 15,			/**< TF2/CS:GO: Next level already set. */
	NativeVotesCallFail_MapNotValid = 16,		/**< ???: Map is invalid. */
	NativeVotesCallFail_KickTime = 17,			/**< ???: Cannot kick for time. */
	NativeVotesCallFail_KickDuringRound = 18,	/**< ???: Cannot kick during a round. */
};

/*
 * Is a specific vote type supported by this game?
 * 
 * @param voteType			Vote type
 */
native bool:NativeVotes_IsVoteTypeSupported(NativeVotesType:voteType);

/**
 * Creates a new, empty vote.
 * 
 * @param handler			Function which will receive vote actions.
 * @param voteType			Vote type, cannot be changed after set
 * @param actions			Optionally set which actions to receive.  Start, 
 *							Cancel, and End will always be received regardless
 *							of whether they are set or not.  They are also
 *							the only default actions.
 * @return					A new vote Handle on INVALID_HANDLE if a vote type is unsupported by this game.
 */
native Handle:NativeVotes_Create(MenuHandler:handler, NativeVotesType:voteType,
							MenuAction:actions=NATIVEVOTES_ACTIONS_DEFAULT);

/**
 * Frees all handles related to a vote.
 * 
 * THIS MUST BE CALLED TO AVOID HANDLE LEAKS
 * 
 * @param vote				Vote handle
 * @noreturn
 */
native Handle:NativeVotes_Close(Handle:vote);

/**
 * Appends a new item to the end of a vote.  Only valid for Multiple Choice votes
 *
 * @param vote				NativeVotes Handle.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Handle, item limit reached, or if the vote is not multiple choice.
 */
native bool:NativeVotes_AddItem(Handle:vote, const String:info[], const String:display[]);

/**
 * Inserts an item into the menu before a certain position; the new item will
 * be at the given position and all next items pushed forward.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Handle or vote position, or if the vote is not multiple choice.
 */
native bool:NativeVotes_InsertItem(Handle:vote, position, const String:info[], const String:display[]);

/**
 * Removes an item from the menu.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @return					True on success, false on failure.
 * @error					Invalid Handle or vote position,  or if the vote is not multiple choice.
 */
native bool:NativeVotes_RemoveItem(Handle:vote, position);

/**
 * Removes all items from a vote.
 *
 * @param vote				Vote Handle.
 * @noreturn
 * @error					Invalid Handle or vote position, or if the vote is not multiple choice.
 */
native NativeVotes_RemoveAllItems(Handle:vote);

/**
 * Retrieves information about a vote item.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param infoBuf			Info buffer.
 * @param infoBufLen		Maximum length of the info buffer.
 * @return					True on success, false if position is invalid.
 * @error					Invalid Handlem
 */
native bool:NativeVotes_GetItem(Handle:vote, 
						position, 
						String:infoBuf[], 
						infoBufLen,
						String:dispBuf[]="",
						dispBufLen=0);
						
/**
 * Returns the number of items in a vote.
 *
 * @param vote				Vote Handle.
 * @return					Number of items in the vote.
 * @error					Invalid Handle.
 */
native NativeVotes_GetItemCount(Handle:vote);

/**
 * Sets the vote's details for votes that support details
 * If this is a custom vote, use NativeVotes_SetTitle to set the vote's title.
 *
 * @param vote				Vote Handle.
 * @param argument			Details string. See vote types for what details stands for.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_SetDetails(Handle:vote, const String:argument[]);

/**
 * Returns the text of a vote's details if set.
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store details.
 * @param maxlength			Maximum length of the buffer.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_GetDetails(Handle:vote, String:buffer[], maxlength);

/**
 * Sets a custom vote's title
 *
 * @param vote				Vote Handle.
 * @param title			 	Vote title string.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_SetTitle(Handle:vote, const String:argument[]);

/**
 * Return the vote's Title.
 * If not set, returns Details instead.
 *     This behavior is for compatibility with NativeVotes 0.8.0 and below.
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store title.
 * @param maxlength			Maximum length of the buffer.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_GetTitle(Handle:vote, String:buffer[], maxlength);

/**
 * Sets the target userid for vote
 * This should be used instead of SetArgument for votes that target players
 * 
 * Also sets target SteamID
 * 
 * @param vote				Vote Handle.
 * @param userid			Client index of target player
 * @param setDetails		If true, also sets vote details to client's name
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_SetTarget(Handle:vote, client, bool:setDetails=true);

/**
 * Returns the userid of a vote's target
 *
 * @param vote				Vote Handle.
 * @return					Client index of target player or 0 for no target or target disconnected since vote started
 * @error					Invalid Handle.
 */
native NativeVotes_GetTarget(Handle:vote);

/**
 * Get the Steam ID of a vote's target
 * Useful if the target has disconnect from the server during a vote.
 * This was added in specifically for Kick/Ban votes
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store steamId.  Should be 19 characters or more..
 * @param maxlength			Maximum length of the buffer.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_GetTargetSteam(Handle:vote, String:buffer[], maxlength);

/**
 * Returns whether a vote is in progress.
 *
 * @return					True if a NativeVotes vote is in progress, false otherwise.
 */
native bool:NativeVotes_IsVoteInProgress();

/**
 * Returns a style's maximum items
 * 
 * @return Maximum items
 */
native NativeVotes_GetMaxItems();

/**
 * Sets a vote's option flags.
 *
 * If a certain bit is not supported, it will be stripped before being set.
 * 
 * NOTE: This is currently unused, but reserved for future use.
 *
 * @param menu				Builtin Vote Handle.
 * @param flags				A new bitstring of VOTEFLAG bits.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_SetOptionFlags(Handle:vote, flags);

/**
 * Retrieves a menu's option flags.
 *
 * NOTE: This is currently unused, but reserved for future use.
 *
 * @param vote				Builtin Vote Handle.
 * @return					A bitstring of VOTEFLAG bits.
 * @error					Invalid Handle.
 */
native NativeVotes_GetOptionFlags(Handle:vote);

/**
 * Cancels the vote in progress.
 *
 * @noreturn
 * @error					If no vote is in progress.
 */
native NativeVotes_Cancel();

/**
 * Callback for when a vote has ended and results are available.
 * 
 * Due to SourceMod Forward limitations in plugins, multi-dimension arrays can't be passed
 * to forwards.  This means we have to split the client_info and item_info arrays into
 * their components.
 * 
 * @param vote				The vote being voted on.
 * @param num_votes			Number of votes tallied in total.
 * @param num_clients		Number of clients who could vote.
 * @param client_indexes	Array of client indexes. Parallel with client_votes.
 * @param client_votes		Array of client votes. Parallel with client_indexes.
 * @param num_items			Number of unique items that were selected.
 * @param item_indexes		Array of vote item indexes. Parallel with item_votes..
 * @param item_votes		Array of vote vote counts. Parallel with item_indexes.
 * @noreturn
 */
functag public NativeVotes_VoteHandler(Handle:vote,
							num_votes, 
							num_clients,
							const client_indexes[],
							const client_votes[],
							num_items,
							const item_indexes[],
							const item_votes[]);
/**
 * Function to convert client/vote arrays into their two-dimensional versions,
 * which can then be passed to a standard vote handler.
 * 
 * client_info and item_info are the resulting arrays.
 * 
 * Note: When declaring client_info and item_info, you'll probably want to declare them like this:
 * new client_info[num_clients][2];
 * new item_info[num_items][2];
 * 
 * @param num_clients		Number of clients who could vote.
 * @param client_indexes	Array of client indexes. Parallel with client_votes.
 * @param client_votes		Array of client votes. Parallel with client_indexes.
 * @param num_items			Number of unique items that were selected.
 * @param item_indexes		Array of vote item indexes. Parallel with item_votes..
 * @param item_votes		Array of vote vote counts. Parallel with item_indexes.
 * @param client_info		Array of clients.  Use VOTEINFO_CLIENT_ defines.
 * @param item_info			Array of items, sorted by count.  Use VOTEINFO_ITEM
 *							defines.
 * @noreturn
 */
stock NativeVotes_FixResults(num_clients,
							const client_indexes[],
							const client_votes[],
							num_items,
							const item_indexes[],
							const item_votes[],
							client_info[][2], 
							item_info[][2])
{
	for (new i = 0; i < num_clients; ++i)
	{
		client_info[i][VOTEINFO_CLIENT_INDEX] = client_indexes[i];
		client_info[i][VOTEINFO_CLIENT_ITEM] = client_votes[i];
	}
	
	for (new i = 0; i < num_items; ++i)
	{
		item_info[i][VOTEINFO_ITEM_INDEX] = item_indexes[i];
		item_info[i][VOTEINFO_ITEM_VOTES] = item_votes[i];
	}
}

/**
 * Sets an advanced vote handling callback.  If this callback is set,
 * MenuAction_VoteEnd will not be called.
 *
 * @param vote				NativeVotes Handle.
 * @param callback			Callback function.
 * @noreturn
 * @error					Invalid Handle or callback.
 */
native NativeVotes_SetResultCallback(Handle:vote, NativeVotes_VoteHandler:callback);

/**
 * Returns the number of seconds you should "wait" before displaying
 * a public vote.  This number is the time remaining until
 * (last_vote + sm_vote_delay).
 *
 * @return					Number of seconds to wait, or 0 for none.
 */
native NativeVotes_CheckVoteDelay();

/**
 * Returns whether a client is in the pool of clients allowed 
 * to participate in the current vote.  This is determined by 
 * the client list passed to NativeVotes_Display().
 *
 * @param client			Client index.
 * @return					True if client is allowed to vote, false otherwise.
 * @error					If no vote is in progress or client index is invalid.
 */
native bool:NativeVotes_IsClientInVotePool(client);

/**
 * Redraws the current vote to a client in the voting pool.
 *
 * @param client			Client index.
 * @param revotes			True to allow revotes, false otherwise.
 * @return					True on success, false if the client is in the vote pool 
 *							but cannot vote again.
 * @error					No vote in progress, client is not in the voting pool, 
 *							or client index is invalid.
 */
native bool:NativeVotes_RedrawClientVote(client, bool:revotes=true);

/**
 * Retrieve the vote type
 * 
 * @param vote				NativeVotes Handle.
 * @return					The built in vote type
 * @error					Invalid Handle
 */
native NativeVotesType:NativeVotes_GetType(Handle:vote);

/**
 * Set the team this vote is for, or NATIVEVOTES_ALL_TEAMS for all teams.
 * 
 * Defaults to NATIVEVOTES_ALL_TEAMS if not explicitly set.
 * 
 * @param vote				NativeVotes Handle.
 * @param team				Team number this vote is for
 * @noreturn
 * @error					Invalid Handle
 */
native NativeVotes_SetTeam(Handle:vote, team);

/**
 * Retrieve the team this vote is for
 * 
 * @param vote				NativeVotes Handle.
 * @return					Team index or NATIVEVOTES_ALL_TEAMS for all teams.
 * @error					Invalid Handle
 */
native NativeVotes_GetTeam(Handle:vote);

/**
 * Set the client index of the player who initiated the vote.
 * Use NATIVEVOTES_SERVER_INDEX if initiated by the server itself.
 * 
 * Defaults to NATIVEVOTES_SERVER_INDEX if not explicitly set.
 * 
 * @param vote				NativeVotes Handle.
 * @param client			Client who initiated the vote or NATIVEVOTES_SERVER_INDEX
 * @noreturn
 * @error					Invalid Handle
 */
native NativeVotes_SetInitiator(Handle:vote, client);

/**
 * Retrieve the client index of the player who initiated the vote or NATIVEVOTES_SERVER_INDEX if 
 * initiated by the server itself.
 * 
 * @param					Vote handle
 * @return					Client index or NATIVEVOTES_SERVER_INDEX
 * @error					Invalid Handle
 */
native NativeVotes_GetInitiator(Handle:vote);

/**
 * Broadcasts a vote to a list of clients.  The most selected item will be 
 * returned through MenuAction_VoteEnd.  On a tie, a random item will be returned 
 * from a list of the tied items.
 *
 * Note that MenuAction_VoteStart, MenuAction_VoteCancel, MenuAction_VoteEnd, and MenuAction_End are all
 * default callbacks and do not need to be enabled.
 *
 * @param vote				Vote Handle.
 * @param clients			Array of clients to broadcast to.
 * @param numClients		Number of clients in the array.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if a vote is already in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
native bool:NativeVotes_Display(Handle:vote, clients[], numClients, time);

/**
 * Sends a vote menu to all clients.  See NativeVotes_Display() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
stock bool:NativeVotes_DisplayToAll(Handle:vote, time)
{
	new total = 0;
	decl players[MaxClients];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Sends a vote menu to a single team.  See NativeVotes_Display() for more information.
 *
 * @param vote				Vote Handle.
 * @param team				Team to send vote to. 1 = spectators, 2 = RED/Survivors/Terrorists, 3 = BLU/Infected/Counter-Terrorists
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
stock bool:NativeVotes_DisplayToTeam(Handle:vote, team, time)
{
	NativeVotes_SetTeam(vote, team);

	new total;
	decl players[MaxClients];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) != team))
		{
			continue;
		}
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Sends a vote menu to all clients who are not spectators or waiting to choose a team.  See NativeVotes_Display() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
stock bool:NativeVotes_DisplayToAllNonSpectators(Handle:vote, time)
{
	new total;
	decl players[MaxClients];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) < 2))
		{
			continue;
		}
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Display vote passed screen
 *
 * You MUST call one of the NativeVotesDisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * @param vote				Vote handle
 * @param details			Normally the item that won the vote or format string. Also used for custom vote winners
 * @param ...				Variable number of format parameters.
 * @noreturn
 */
native NativeVotes_DisplayPass(Handle:vote, const String:details[]="");

/**
 * Display vote passed screen with custom text to a single user
 *
 * You MUST call one of the NativeVotesDisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * @param vote				Vote handle
 * @param client			client to display to
 * @param format			A format string.
 * @param any				Variable number of format parameters
 * @noreturn
 */
native NativeVotes_DisplayPassCustomToOne(Handle:vote, client, const String:format[], any:...);

/**
 * Display vote passed screen with custom text
 *
 * You MUST call one of the NativeVotesDisplayPass* or NativeVotes_DisplayFail functions
 * to hide the vote screen for users who didn't vote, and to clear out their selection
 * for the next vote.
 * 
 * @param vote				Vote handle
 * @param format			A format string.
 * @param any				Variable number of format parameters
 * @noreturn
 */
stock NativeVotes_DisplayPassCustom(Handle:vote, const String:format[], any:...)
{
	decl String:buffer[192];
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			NativeVotes_DisplayPassCustomToOne(vote, i, "%s", buffer);
		}
	}
}

/**
 * Display vote passed screen with a custom type.
 *
 * A sample usage of this would be if Extend won an RTV vote: NativeVotes_DisplayPassEx(vote, NativeVotesPass_Extend, map);
 *
 * You MUST call one of NativeVotes_DisplayPass, NativeVotes_DisplayPassEx,
 * or NativeVotes_DisplayFail to hide the vote screen for users who didn't vote
 * and to clear out their selection for the next vote.
 * 
 * #param vote				Vote handle
 * @param passType			The pass screen to display
 * @param details			Normally the item that won the vote. Also used for custom vote winners
 * @noreturn
 */
native NativeVotes_DisplayPassEx(Handle:vote, NativeVotesPassType:passType, const String:details[]="");

/**
 * Display failure screen.
 *
 * You MUST call one of NativeVotes_DisplayPass, NativeVotes_DisplayPassEx,
 * or NativeVotes_DisplayFail to hide the vote screen for users who didn't vote,
 * and to clear out their selection for the next vote.
 * 
 * @param reason			Vote failure reason from NativeVotesFailType enum
 * @noreturn
 */
native NativeVotes_DisplayFail(Handle:vote, NativeVotesFailType:reason=NativeVotesFail_Generic);

/**
 * Quick stock to determine whether voting is allowed.  This doesn't let you 
 * fine-tune a reason for not voting, so it's not recommended for lazily 
 * telling clients that voting isn't allowed.
 * 
 * @return				True if voting is allowed, false if voting is in progress
 *						or the cooldown is active.
 */
stock bool:NativeVotes_IsNewVoteAllowed()
{
	if (NativeVotes_IsVoteInProgress() || NativeVotes_CheckVoteDelay() != 0)
	{
		return false;
	}
	
	return true;
}

/**
 * Used when callvote is called with no arguments.
 * 
 * This is used to configure the VoteSetup usermessage on TF2 and CS:GO
 * 
 * @param client		Client, in case the votes are restricted by client
 * @param voteTypes		Populate this array with the vote types this server supports
 * 						Custom and multiple choice votes are not supported from
 * 						the GUI and are thus ignored.
 * @return				Plugin_Continue to allow the server itself (or another plugin) to process the callvote
 * 						Plugin_Changed if you're changing the voteTypes,
 * 						Plugin_Handled to return a blank VoteSetup usermessage
 * 						Plugin_Stop to prevent VoteSetup usermessage (not recommended)
 */
functag public Action:NativeVotes_CallVoteSetupHandler(client, NativeVotesType:voteTypes[]);

/**
 * Forward for "callvote" handling
 * 
 * You should respond to this by starting a vote or by calling NativeVotes_DisplayCallVoteFail
 * 
 * @param client		Client
 * @param voteType		Type of vote being called.  This will NEVER be a multiple-choice or custom vote.
 * @param voteArgument	Vote argument or blank if the vote type has no argument.
 * @param target		target userid for kick votes or 0 for all other votes
 * @return				Plugin_Continue to allow the server itself (or another plugin) to process the callvote
 * 						Plugin_Handled if you processed this vote type
 * 						Plugin_Stop to block the vote type (not recommended)
 */
functag public Action:NativeVotes_CallVoteHandler(client, NativeVotesType:voteType, const String:voteArgument[], target);

/**
 * Register a plugin as a vote manager.
 * This is used to abstract away the details of the callvote command.
 * 
 * @param callHandler	Handler for callvote commands.
 * @param setupHandler	Handler to override the which vote types your server supports.  Only useful on TF2 and CS:GO.
 * @noreturn
 */
native NativeVotes_RegisterVoteManager(NativeVotes_CallVoteHandler:callHandler, NativeVotes_CallVoteSetupHandler:setupHandler=INVALID_FUNCTION);

/**
 *  Send a call vote fail screen to a user
 * Used to respond to a callvote with invalid arguments or for other reasons
 * (such as trying to target an admin for a kick/ban vote)
 * 
 * @param client		The client to display the fail screen to
 * @param reason		A vote call fail reason
 * @param time			For NativeVotesCallFail_Recent, the number of seconds until the vote
 * 						can be called again
 */
native NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFailType:reason, time);

/**
 * Redraws the vote title from inside a MenuAction_Display callback
 * Not supported on L4D
 * 
 * @param text			Vote title to draw
 * @error 				If called from outside MenuAction_Display
 * @return				Plugin_Changed if the change is allowed, Plugin_Continue if it isn't.
 */
native Action:NativeVotes_RedrawVoteTitle(const String:text[]);

/**
 * Redraws the vote text from inside a MenuAction_DisplayItem callback.
 * Only supported on multiple-choice votes
 * 
 * @param text			Vote text to draw.
 * @error 				If called from outside MenuAction_DisplayItem
 * @return				Plugin_Changed if the change is allowed, Plugin_Continue if it isn't.
 */
native Action:NativeVotes_RedrawVoteItem(const String:text[]);

/**
 * Retrieves voting information from MenuAction_VoteEnd.
 *
 * @param param2		Second parameter of MenuAction_VoteEnd.
 * @param winningVotes	Number of votes received by the winning option.
 * @param totalVotes	Number of total votes received.
 * @noreturn
 */
stock NativeVotes_GetInfo(param2, &winningVotes, &totalVotes)
{
	winningVotes = param2 & 0xFFFF;
	totalVotes = param2 >> 16;
}

/**
 * Do not edit below this line!
 */
public SharedPlugin:__pl_nativevotes = 
{
	name = "nativevotes",
	file = "nativevotes.smx",
#if defined REQUIRE_PLUGINS
	required = 1,
#else
	required = 0,
#endif
};

public __pl_nativevotes_SetNTVOptional()
{
	MarkNativeAsOptional("NativeVotes_IsVoteTypeSupported");
	MarkNativeAsOptional("NativeVotes_Create");
	MarkNativeAsOptional("NativeVotes_Close");
	MarkNativeAsOptional("NativeVotes_AddItem");
	MarkNativeAsOptional("NativeVotes_InsertItem");
	MarkNativeAsOptional("NativeVotes_RemoveItem");
	MarkNativeAsOptional("NativeVotes_RemoveAllItems");
	MarkNativeAsOptional("NativeVotes_GetItem");
	MarkNativeAsOptional("NativeVotes_GetItemCount");
	MarkNativeAsOptional("NativeVotes_SetDetails");
	MarkNativeAsOptional("NativeVotes_GetDetails");
	MarkNativeAsOptional("NativeVotes_SetTitle");
	MarkNativeAsOptional("NativeVotes_GetTitle");
	MarkNativeAsOptional("NativeVotes_SetTarget");
	MarkNativeAsOptional("NativeVotes_GetTarget");
	MarkNativeAsOptional("NativeVotes_GetTargetSteam");
	MarkNativeAsOptional("NativeVotes_IsVoteInProgress");
	MarkNativeAsOptional("NativeVotes_GetMaxItems");
	MarkNativeAsOptional("NativeVotes_SetOptionFlags");
	MarkNativeAsOptional("NativeVotes_GetOptionFlags");
	MarkNativeAsOptional("NativeVotes_Cancel");
	MarkNativeAsOptional("NativeVotes_SetResultCallback");
	MarkNativeAsOptional("NativeVotes_CheckVoteDelay");
	MarkNativeAsOptional("NativeVotes_IsClientInVotePool");
	MarkNativeAsOptional("NativeVotes_RedrawClientVote");
	MarkNativeAsOptional("NativeVotes_RedrawClientVote");
	MarkNativeAsOptional("NativeVotes_GetType");
	MarkNativeAsOptional("NativeVotes_SetTeam");
	MarkNativeAsOptional("NativeVotes_GetTeam");
	MarkNativeAsOptional("NativeVotes_SetInitiator");
	MarkNativeAsOptional("NativeVotes_GetInitiator");
	MarkNativeAsOptional("NativeVotes_Display");
	MarkNativeAsOptional("NativeVotes_DisplayPass");
	MarkNativeAsOptional("NativeVotes_DisplayPassCustomToOne");
	MarkNativeAsOptional("NativeVotes_DisplayPassEx");
	MarkNativeAsOptional("NativeVotes_DisplayFail");
	MarkNativeAsOptional("NativeVotes_RegisterVoteManager");
	MarkNativeAsOptional("NativeVotes_DisplayCallVoteFail");
	MarkNativeAsOptional("NativeVotes_RedrawVoteTitle");
	MarkNativeAsOptional("NativeVotes_RedrawVoteItem");
}
