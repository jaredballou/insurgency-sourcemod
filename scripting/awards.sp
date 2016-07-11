//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Round awards"
#define PLUGIN_NAME "[INS] Round Awards"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING "0"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-awards.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_awards_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_awards_enabled", PLUGIN_WORKING, "Enable end-round awards", FCVAR_NOTIFY);

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
/*
DoRoundAwards
At the end of each round, give awards for "best" of each stat
TODO:
 * Avoid giving least deaths and best accuracy to those who just joined or didn't take part.
 * Add K/D counter to help with this or add points?
 * Find a way to give points to actual in-game score before final tally is generated.
*/

DoRoundAwards()
{
	InsLog(DEBUG,"Running DoRoundAwards");
	new iHighStat[RoundStatFields],iLowStat[RoundStatFields], val;
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			new m_iPlayerScore = Ins_GetPlayerScore(i);
			g_round_stats[i][STAT_SCORE] = (m_iPlayerScore - g_round_stats[i][STAT_SCORE]);
			g_round_stats[i][STAT_ACCURACY] = RoundToFloor((Float:g_round_stats[i][STAT_HITS] / Float:g_round_stats[i][STAT_SHOTS]) * 100.0);
			for (new s;s<sizeof(iHighStat);s++)
			{
				val = g_round_stats[i][s];
				if (val > iHighStat[s])
				{
					iHighStat[s] = val;
				}
				if ((val < iLowStat[s]) || (i == 1))
				{
					iLowStat[s] = val;
				}
			}
			InsLog(DEBUG,"Client %N KILLS %d, DEATHS %d, SHOTS %d, HITS %d, GRENADES %d, CAPTURES %d, CACHES %d, DMG_GIVEN %d, DMG_TAKEN %d, TEAMKILLS %d SCORE %d (total %d) SUPPRESSIONS %d",i,g_round_stats[i][STAT_KILLS],g_round_stats[i][STAT_DEATHS],g_round_stats[i][STAT_SHOTS],g_round_stats[i][STAT_HITS],g_round_stats[i][STAT_GRENADES],g_round_stats[i][STAT_CAPTURES],g_round_stats[i][STAT_CACHES],g_round_stats[i][STAT_DMG_GIVEN],g_round_stats[i][STAT_DMG_TAKEN],g_round_stats[i][STAT_TEAMKILLS],g_round_stats[i][STAT_SCORE],m_iPlayerScore,g_round_stats[i][STAT_SUPPRESSIONS]);
		}
//		reset_round_stats(i);
	}
/*
	GiveRoundAward(STAT_SCORE,1,iHighStat[STAT_SCORE],"round_mvp","score");
	GiveRoundAward(STAT_KILLS,1,iHighStat[STAT_KILLS],"round_kills","kills");
	GiveRoundAward(STAT_DEATHS,-1,iLowStat[STAT_DEATHS],"round_deaths","deaths");
	GiveRoundAward(STAT_SHOTS,1,iHighStat[STAT_SHOTS],"round_shots","shots");
	GiveRoundAward(STAT_HITS,1,iHighStat[STAT_HITS],"round_hits","hits");
	GiveRoundAward(STAT_ACCURACY,1,iHighStat[STAT_ACCURACY],"round_accuracy","accuracy");
	GiveRoundAward(STAT_GRENADES,1,iHighStat[STAT_GRENADES],"round_grenades","grenades");
	GiveRoundAward(STAT_CAPTURES,1,iHighStat[STAT_CAPTURES],"round_captures","captures");
	GiveRoundAward(STAT_CACHES,1,iHighStat[STAT_CACHES],"round_caches","caches");
	GiveRoundAward(STAT_DMG_GIVEN,1,iHighStat[STAT_DMG_GIVEN],"round_dmg_given","dmg_given");
	GiveRoundAward(STAT_DMG_TAKEN,-1,iLowStat[STAT_DMG_TAKEN],"round_dmg_taken","dmg_taken");
	GiveRoundAward(STAT_SUPPRESSIONS,1,iHighStat[STAT_SUPPRESSIONS],"round_suppressions","suppressions");
*/
}
GiveRoundAward(RoundStatFields:stat,high,value,String:award[32],String:valname[32])
{
	new String:buffer[256];
	if (high)
	{
		if (value <= 0)
		{
			return;
		}
	}
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			Format(buffer, sizeof(buffer), " (%s \"%d\")",valname,value);
			if (((high) && (g_round_stats[i][stat] >= value)) || (g_round_stats[i][stat] <= value))
			{
				LogPlayerEvent(i, "triggered", award, false, buffer);
			}
		}
	}	
}
