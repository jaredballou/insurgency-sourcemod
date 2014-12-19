/**
 * wstatshelper.inc - Weapon Stats Helper Include - Modified from SuperLogs's wstatshelper.inc to support Insurgency2
 * Based on SuperLogs by psychonic (https://forums.alliedmods.net/showthread.php?t=99231?t=99231)
 * Author: psychonic, modified by FZFalzar of Brutus.SG Modded Servers (http://brutus.sg)
 * Version: 1.0.7
 */

#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

#define LOG_HIT_OFFSET     7 

#define LOG_HIT_SHOTS      0
#define LOG_HIT_HITS       1
#define LOG_HIT_KILLS      2
#define LOG_HIT_HEADSHOTS  3
#define LOG_HIT_TEAMKILLS  4
#define LOG_HIT_DAMAGE     5
#define LOG_HIT_DEATHS     6
#define LOG_HIT_GENERIC    7
#define LOG_HIT_HEAD       8
#define LOG_HIT_CHEST      9
#define LOG_HIT_STOMACH    10
#define LOG_HIT_LEFTARM    11
#define LOG_HIT_RIGHTARM   12
#define LOG_HIT_LEFTLEG    13
#define LOG_HIT_RIGHTLEG   14

new Handle:g_weapon_trie = INVALID_HANDLE;

CreatePopulateWeaponTrie()
{

	decl String:strBuf[32];
	// Create a Trie
	g_weapon_trie = CreateTrie();
	
	// Initial populate
	// DYNAMIC POPULATE
	//for (new i = 0; i < MAX_LOG_WEAPONS; i++)
	
	//for (new i = 0; i < GetArraySize(g_weap_array); i++)
	for (new i = 0; i < NumWeaponsDefined; i++)
	{
		GetArrayString(g_weap_array, i, strBuf, sizeof(strBuf));
		SetTrieValue(g_weapon_trie, strBuf, i);
	}
}

dump_player_stats(client)
{
	if (IsClientInGame(client) && IsClientConnected(client))
	{
		decl String: player_authid[64];
		if (!GetClientAuthString(client, player_authid, sizeof(player_authid)))
		{
			strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
		}
		new player_team_index = GetClientTeam(client);
		new player_userid = GetClientUserId(client);

		new is_logged;
		//for (new i = 0; (i < MAX_LOG_WEAPONS); i++)
		//DYNAMIC POPULATE
		//for (new i = 0; i < GetArraySize(g_weap_array); i++)
		for (new i = 0; i < NumWeaponsDefined; i++)
		{
			decl String:strBuf[32];
			GetArrayString(g_weap_array, i, strBuf, sizeof(strBuf));
			
			#if defined INS
			if (g_weapon_stats[client][i][LOG_HIT_HITS] > 0)
			{
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf,	//g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_SHOTS], 
				g_weapon_stats[client][i][LOG_HIT_HITS], 
				g_weapon_stats[client][i][LOG_HIT_KILLS], 
				g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], 
				g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], 
				g_weapon_stats[client][i][LOG_HIT_DAMAGE], 
				g_weapon_stats[client][i][LOG_HIT_DEATHS]); 
				
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf,	//g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_HEAD], 
				g_weapon_stats[client][i][LOG_HIT_CHEST], 
				g_weapon_stats[client][i][LOG_HIT_STOMACH], 
				g_weapon_stats[client][i][LOG_HIT_LEFTARM], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTARM], 
				g_weapon_stats[client][i][LOG_HIT_LEFTLEG], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]);
			#else
			if (g_weapon_stats[client][i][LOG_HIT_SHOTS] > 0)
			{
				#if defined GES
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				g_weapon_loglist[i], 
				g_weapon_stats[client][i][LOG_HIT_SHOTS], 
				g_weapon_stats[client][i][LOG_HIT_HITS], 
				g_weapon_stats[client][i][LOG_HIT_KILLS], 
				g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], 
				g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], 
				g_weapon_stats[client][i][LOG_HIT_DAMAGE], 
				g_weapon_stats[client][i][LOG_HIT_DEATHS]); 
				
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				g_weapon_loglist[i], 
				g_weapon_stats[client][i][LOG_HIT_HEAD], 
				g_weapon_stats[client][i][LOG_HIT_CHEST], 
				g_weapon_stats[client][i][LOG_HIT_STOMACH], 
				g_weapon_stats[client][i][LOG_HIT_LEFTARM], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTARM], 
				g_weapon_stats[client][i][LOG_HIT_LEFTLEG], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]); 
				#else
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf, //g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_SHOTS], 
				g_weapon_stats[client][i][LOG_HIT_HITS], 
				g_weapon_stats[client][i][LOG_HIT_KILLS], 
				g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], 
				g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], 
				g_weapon_stats[client][i][LOG_HIT_DAMAGE], 
				g_weapon_stats[client][i][LOG_HIT_DEATHS]);
				
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf, //g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_HEAD],
				g_weapon_stats[client][i][LOG_HIT_CHEST], 
				g_weapon_stats[client][i][LOG_HIT_STOMACH], 
				g_weapon_stats[client][i][LOG_HIT_LEFTARM], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTARM], 
				g_weapon_stats[client][i][LOG_HIT_LEFTLEG], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]);
				#endif
			#endif
				is_logged++;
			}
		}
		if (is_logged > 0)
		{
			reset_player_stats(client);
		}
	}
}

reset_player_stats(client)
{
	//for (new i = 0; (i < MAX_LOG_WEAPONS); i++)
	//DYNAMIC POPULATE
	//for( new i = 0; i < GetArraySize(g_weap_array); i++)
	for( new i = 0; i < NumWeaponsDefined; i++)
	{
		g_weapon_stats[client][i][LOG_HIT_SHOTS]     = 0;
		g_weapon_stats[client][i][LOG_HIT_HITS]      = 0;
		g_weapon_stats[client][i][LOG_HIT_KILLS]     = 0;
		g_weapon_stats[client][i][LOG_HIT_HEADSHOTS] = 0;
		g_weapon_stats[client][i][LOG_HIT_TEAMKILLS] = 0;
		g_weapon_stats[client][i][LOG_HIT_DAMAGE]    = 0;
		g_weapon_stats[client][i][LOG_HIT_DEATHS]    = 0;
		g_weapon_stats[client][i][LOG_HIT_GENERIC]   = 0;
		g_weapon_stats[client][i][LOG_HIT_HEAD]      = 0;
		g_weapon_stats[client][i][LOG_HIT_CHEST]     = 0;
		g_weapon_stats[client][i][LOG_HIT_STOMACH]   = 0;
		g_weapon_stats[client][i][LOG_HIT_LEFTARM]   = 0;
		g_weapon_stats[client][i][LOG_HIT_RIGHTARM]  = 0;
		g_weapon_stats[client][i][LOG_HIT_LEFTLEG]   = 0;
		g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]  = 0;
	}
}

//stock get_weapon_index(const String:weapon_name[], id=-1, bool:bReplace=true)
stock get_weapon_index(const String:weapon_name[])
{
	new index = -1;
	GetTrieValue(g_weapon_trie, weapon_name, index);
	/*
	if(id != index && index != -1 && id != -1 && bReplace)
	{
		//fix our trie value to reflect the actual id. it *should* fix once per fire of every weapon
		SetTrieValue(g_weapon_trie, weapon_name, id);
		return id;
	}
	//GetTrieValue(g_weapon_trie, weapon_name, index);*/
	return index;
}


WstatsDumpAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		dump_player_stats(i);
	}
}

OnPlayerDisconnect(client)
{
	if(client > 0 && IsClientInGame(client))
	{
		dump_player_stats(client);
		reset_player_stats(client);
	}
}
