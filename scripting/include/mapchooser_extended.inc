/**
 * vim: set ts=4 :
 * =============================================================================
 * MapChooser Extended
 * Creates a map vote at appropriate times, setting sm_nextmap to the winning
 * vote
 *
 * MapChooser Extended (C)2011-2013 Powerlord (Ross Bemrose)
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
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

#if defined _mapchooser_extended_included_
  #endinput
#endif
#define _mapchooser_extended_included_
#include <mapchooser>

// MCE 1.9 series

enum CanNominateResult
{
	CanNominate_No_VoteFull,		/** No, nominations list is full */
	CanNominate_No_VoteInProgress,	/** No, map vote is in progress */
	CanNominate_No_VoteComplete,	/** No, map vote is completed */
	CanNominate_Yes,				/** Yes, you can nominate */
};


/**
 * Called whenever warning timer starts
 * 
 */
forward OnMapVoteWarningStart();

/**
 * Called whenever runoff warning timer starts
 */
forward OnMapVoteRunnoffWarningStart();

/**
 * Called whenever the timer ticks
 */
forward OnMapVoteWarningTick(time);

/**
 * Called whenever vote starts
 * 
 * @deprecated Will be removed in MapChooser 1.8.  Use OnMapVoteStarted instead.
 */
forward OnMapVoteStart();

/**
 * Called whenever vote ends
 */
forward OnMapVoteEnd(const String:map[]);

/**
 * Is a map on the current game's official list?
 * This should be treated as informative only.
 * 
 * @param map 	Name of map to check
 * @return 		true if it's on the list of official maps for this game
 */
native bool:IsMapOfficial(const String:map[]);

/**
 * Is nominate allowed?
 * 
 * @return		A CanNominateResult corresponding to whether a vote is allowed or not
 */
native CanNominateResult:CanNominate();

public SharedPlugin:__pl_mapchooser_extended = 
{
	name = "mapchooser",
	file = "mapchooser_extended.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
