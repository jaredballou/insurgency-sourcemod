/**
 * gameME Plugin - Raw Messages Interface
 * http://www.gameme.com
 * Copyright (C) 2007-2014 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 *
 * This file demonstrates the access to the raw message
 * interface of gameME Stats. Documentation is available
 * at http://www.gameme.com/docs/api/rawmessages
 *  
 */

#pragma semicolon 1
#include <sourcemod>
#include <gameme>


// plugin information
#define GAMEME_MESSAGES_PLUGIN_VERSION "1.3"
public Plugin:myinfo = {
	name = "gameME Raw Message Plugin",
	author = "TTS Oetzel & Goerz GmbH",
	description = "gameME Plugin",
	version = GAMEME_MESSAGES_PLUGIN_VERSION,
	url = "http://www.gameme.com"
};


/* Example to define query contants to be able to distinct gameME Stats queries. The
 * payload is given as cell on query function call
 */
 
#define QUERY_TYPE_OTHER				0
#define QUERY_TYPE_ONCLIENTPUTINSERVER	1


public OnPluginStart() 
{
	LogToGame("gameME Raw Messages Example Plugin %s (http://www.gameme.com), copyright (c) 2007-2014 by TTS Oetzel & Goerz GmbH", GAMEME_MESSAGES_PLUGIN_VERSION);

	QueryGameMEStatsTop10("top10", -1, QuerygameMEStatsTop10Callback);
}


public OnClientPutInServer(client)
{
	// example on how to retrieve data from gameME Stats if player put in server
	if (client > 0) {
		if (!IsFakeClient(client)) {
			QueryGameMEStats("playerinfo", client, QuerygameMEStatsCallback, QUERY_TYPE_ONCLIENTPUTINSERVER);
			QueryGameMEStatsNext("next", client, QuerygameMEStatsNextCallback);
		}
	}
}


public QuerygameMEStatsCallback(command, payload, client, &Handle: datapack)
{
	if ((client > 0) && (command == RAW_MESSAGE_CALLBACK_PLAYER)) {

		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		
		// total values
		new rank            = ReadPackCell(data);
		new players         = ReadPackCell(data);	
		new skill           = ReadPackCell(data);	
		new kills           = ReadPackCell(data);	
		new deaths          = ReadPackCell(data);	
		new Float: kpd      = ReadPackFloat(data);
		new suicides        = ReadPackCell(data);
		new headshots       = ReadPackCell(data);
		new Float: hpk      = ReadPackFloat(data);
		new Float: accuracy = ReadPackFloat(data);
		new connection_time = ReadPackCell(data);
		new kill_assists    = ReadPackCell(data);
		new kills_assisted  = ReadPackCell(data);
		new points_healed   = ReadPackCell(data);
		new flags_captured  = ReadPackCell(data);
		new custom_wins     = ReadPackCell(data);
		new kill_streak     = ReadPackCell(data);
		new death_streak    = ReadPackCell(data);

		// session values
		new session_pos_change      = ReadPackCell(data);
		new session_skill_change    = ReadPackCell(data);
		new session_kills           = ReadPackCell(data);
		new session_deaths          = ReadPackCell(data);
		new Float: session_kpd      = ReadPackFloat(data);
		new session_suicides        = ReadPackCell(data);
		new session_headshots       = ReadPackCell(data);
		new Float: session_hpk 		= ReadPackFloat(data);
		new Float: session_accuracy = ReadPackFloat(data);
		new session_time            = ReadPackCell(data);
		new session_kill_assists    = ReadPackCell(data);
		new session_kills_assisted  = ReadPackCell(data);
		new session_points_healed   = ReadPackCell(data);
		new session_flags_captured  = ReadPackCell(data);
		new session_custom_wins     = ReadPackCell(data);
		new session_kill_streak     = ReadPackCell(data);
		new session_death_streak    = ReadPackCell(data);
		
		decl String: session_fav_weapon[32];
		ReadPackString(data, session_fav_weapon, 32);
		
		// global values
		new global_rank       = ReadPackCell(data);
		new global_players    = ReadPackCell(data);
		new global_kills      = ReadPackCell(data);
		new global_deaths     = ReadPackCell(data);
		new Float: global_kpd = ReadPackFloat(data);
		new global_headshots  = ReadPackCell(data);
		new Float: global_hpk = ReadPackFloat(data);

		CloseHandle(data);

		// only write this message to gameserver log if client has connected
		if (payload == QUERY_TYPE_ONCLIENTPUTINSERVER) {
			LogToGame("Player %L is on rank %d with %d points", client, rank, skill);
		}
		
	}
}


public QuerygameMEStatsTop10Callback(command, payload, &Handle: datapack)
{
	if ((command == RAW_MESSAGE_CALLBACK_TOP10)) {

		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		new total_count = ReadPackCell(data); // total_players

		if (total_count == -1) {

			LogToGame("-----------------------------------------------------------");
			LogToGame("No Players ranked");
			LogToGame("-----------------------------------------------------------");

		} else {

			LogToGame("-----------------------------------------------------------");
			LogToGame("Current Top10-Players");
			for (new i = 0; (i < total_count); i++) {

				new rank       = ReadPackCell(data); // rank
				new skill      = ReadPackCell(data); // skill

				decl String: name[64]; // name
				ReadPackString(data, name, 64);

				new Float: kpd = ReadPackFloat(data); // kpd
				new Float: hpk = ReadPackFloat(data); // hpk

				LogToGame("%02d  %d  %s", rank, skill, name);
			}
			LogToGame("-----------------------------------------------------------");

		}

		CloseHandle(data);
	}
}


public QuerygameMEStatsNextCallback(command, payload, client, &Handle: datapack)
{
	if ((client > 0) && (command == RAW_MESSAGE_CALLBACK_NEXT)) {

		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		new total_count = ReadPackCell(data); // total_players

		if (total_count == -1) {

			LogToGame("-----------------------------------------------------------");
			LogToGame("No next players available");
			LogToGame("-----------------------------------------------------------");

		} else {

			LogToGame("-----------------------------------------------------------");
			LogToGame("Next players for %L", client);

			new prev_skill = -1;
			for (new i = 0; (i < total_count); i++) {

				new rank       = ReadPackCell(data); // rank
				new skill      = ReadPackCell(data); // skill

				decl String: name[64]; // name
				ReadPackString(data, name, 64);

				new Float: kpd = ReadPackFloat(data); // kpd
				new Float: hpk = ReadPackFloat(data); // hpk

				new diff  = -1;
				if (prev_skill > -1) {
					diff  = skill - prev_skill;
				}

				if (i == 0) {
					LogToGame("%02d  %d  -  %s", rank, skill, name);
				} else {
					LogToGame("%02d  %d  +%04d  %s", rank, skill, diff, name);
				}
				
				if (prev_skill == -1) {
					prev_skill = skill;
				}
			}
			LogToGame("-----------------------------------------------------------");

		}

		CloseHandle(data);
	}
}


// helper function to format timestamps
format_time(timestamp, String: formatted_time[192]) {
	Format(formatted_time, 192, "%dd %02d:%02d:%02dh", timestamp / 86400, timestamp / 3600 % 24, timestamp / 60 % 60, timestamp % 60);
}


public onGameMEStatsRank(command, client, String: message_prefix[], &Handle: datapack)
{
	if ((client > 0) && (command == RAW_MESSAGE_RANK)) {
		new time = 15;
		new need_handler = 0;
		
		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		
		// total values
		new rank            = ReadPackCell(data);
		new players         = ReadPackCell(data);	
		new skill           = ReadPackCell(data);	
		new kills           = ReadPackCell(data);	
		new deaths          = ReadPackCell(data);	
		new Float: kpd      = ReadPackFloat(data);
		new suicides        = ReadPackCell(data);
		new headshots       = ReadPackCell(data);
		new Float: hpk      = ReadPackFloat(data);
		new Float: accuracy = ReadPackFloat(data);
		new connection_time = ReadPackCell(data);
		new kill_assists    = ReadPackCell(data);
		new kills_assisted  = ReadPackCell(data);
		new points_healed   = ReadPackCell(data);
		new flags_captured  = ReadPackCell(data);
		new custom_wins     = ReadPackCell(data);
		new kill_streak     = ReadPackCell(data);
		new death_streak    = ReadPackCell(data);

		// session values
		new session_pos_change      = ReadPackCell(data);
		new session_skill_change    = ReadPackCell(data);
		new session_kills           = ReadPackCell(data);
		new session_deaths          = ReadPackCell(data);
		new Float: session_kpd      = ReadPackFloat(data);
		new session_suicides        = ReadPackCell(data);
		new session_headshots       = ReadPackCell(data);
		new Float: session_hpk 		= ReadPackFloat(data);
		new Float: session_accuracy = ReadPackFloat(data);
		new session_time            = ReadPackCell(data);
		new session_kill_assists    = ReadPackCell(data);
		new session_kills_assisted  = ReadPackCell(data);
		new session_points_healed   = ReadPackCell(data);
		new session_flags_captured  = ReadPackCell(data);
		new session_custom_wins     = ReadPackCell(data);
		new session_kill_streak     = ReadPackCell(data);
		new session_death_streak    = ReadPackCell(data);
		
		decl String: session_fav_weapon[32];
		ReadPackString(data, session_fav_weapon, 32);
		
		// global values
		new global_rank       = ReadPackCell(data);
		new global_players    = ReadPackCell(data);
		new global_kills      = ReadPackCell(data);
		new global_deaths     = ReadPackCell(data);
		new Float: global_kpd = ReadPackFloat(data);
		new global_headshots  = ReadPackCell(data);
		new Float: global_hpk = ReadPackFloat(data);

		CloseHandle(data);


		decl String: formatted_time[192];
		format_time(connection_time, formatted_time);
		decl String: formatted_session_time[192];
		format_time(session_time, formatted_session_time);
		
		new String: message[1024];
		if (rank < 1) {
			Format(message, 1024, "Not yet available");
		} else {
			// total
			decl String: total_message[512];
			Format(total_message, 512, "->1 - Total\\n   Position %d of %d\\n   %d Points\\n   %d:%d Frags (%.2f)\\n   %d (%.0f%%) Headshots\\n   %.0f%% Accuracy\\n   Time %s\\n\\n",
				rank, players, skill, kills, deaths, kpd, headshots, hpk * 100, accuracy * 100, formatted_time);
			strcopy(message[strlen(message)], 512, total_message);

			// session
			decl String: session_message[512];
			Format(session_message, 512, "->2 - Session\\n   %d Positions\\n   %d Points\\n   %d:%d Frags (%.2f)\\n   %d (%.0f%%) Headshots\\n   %.0f%% Accuracy\\n   %s\\n   Time %s\\n",
				session_pos_change, session_skill_change, session_kills, session_deaths, session_kpd, session_headshots, session_hpk * 100, session_accuracy * 100, session_fav_weapon, formatted_session_time);
			strcopy(message[strlen(message)], 512, session_message);

			// global
			if (global_rank < 1) {
				decl String: global_message[512];
				Format(global_message, 512, "%s", "->3 - Global\\n   Not yet available");
				strcopy(message[strlen(message)], 512, global_message);
			} else {
				decl String: global_message[512];
				Format(global_message, 512, "->3 - Global\\n   Position %d of %d\\n   %d Points\\n   %d:%d Frags (%.2f)\\n%   %d (%.0f%%) Headshots",
					global_rank, global_players, global_kills, global_deaths, global_kpd, global_headshots, global_hpk * 100);
				strcopy(message[strlen(message)], 512, global_message);
			}
		}

		if ((!IsFakeClient(client)) && (IsClientInGame(client))) {
			DisplayGameMEStatsMenu(client, time, message, need_handler);			
		}
	}
}


public onGameMEStatsPublicCommand(command, client, String: message_prefix[], &Handle: datapack)
{
	new color_index = -1;

	if ((client > 0) && ((command == RAW_MESSAGE_PLACE) || (command == RAW_MESSAGE_KDEATH) || (command == RAW_MESSAGE_SESSION_DATA))) {

		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		
		// total values
		new rank            = ReadPackCell(data);
		new players         = ReadPackCell(data);	
		new skill           = ReadPackCell(data);	
		new kills           = ReadPackCell(data);	
		new deaths          = ReadPackCell(data);	
		new Float: kpd      = ReadPackFloat(data);
		new suicides        = ReadPackCell(data);
		new headshots       = ReadPackCell(data);
		new Float: hpk      = ReadPackFloat(data);
		new Float: accuracy = ReadPackFloat(data);
		new connection_time = ReadPackCell(data);
		new kill_assists    = ReadPackCell(data);
		new kills_assisted  = ReadPackCell(data);
		new points_healed   = ReadPackCell(data);
		new flags_captured  = ReadPackCell(data);
		new custom_wins     = ReadPackCell(data);
		new kill_streak     = ReadPackCell(data);
		new death_streak    = ReadPackCell(data);

		// session values
		new session_pos_change      = ReadPackCell(data);
		new session_skill_change    = ReadPackCell(data);
		new session_kills           = ReadPackCell(data);
		new session_deaths          = ReadPackCell(data);
		new Float: session_kpd      = ReadPackFloat(data);
		new session_suicides        = ReadPackCell(data);
		new session_headshots       = ReadPackCell(data);
		new Float: session_hpk 		= ReadPackFloat(data);
		new Float: session_accuracy = ReadPackFloat(data);
		new session_time            = ReadPackCell(data);
		new session_kill_assists    = ReadPackCell(data);
		new session_kills_assisted  = ReadPackCell(data);
		new session_points_healed   = ReadPackCell(data);
		new session_flags_captured  = ReadPackCell(data);
		new session_custom_wins     = ReadPackCell(data);
		new session_kill_streak     = ReadPackCell(data);
		new session_death_streak    = ReadPackCell(data);
		
		decl String: session_fav_weapon[32];
		ReadPackString(data, session_fav_weapon, 32);
		
		// global values
		new global_rank       = ReadPackCell(data);
		new global_players    = ReadPackCell(data);
		new global_kills      = ReadPackCell(data);
		new global_deaths     = ReadPackCell(data);
		new Float: global_kpd = ReadPackFloat(data);
		new global_headshots  = ReadPackCell(data);
		new Float: global_hpk = ReadPackFloat(data);

		CloseHandle(data);

		decl String: client_message[192];
		switch (command) {
			case RAW_MESSAGE_PLACE: 
				Format(client_message, 192, "%N is on rank %d of %d with %d points", client, rank, players, skill);
			case RAW_MESSAGE_KDEATH: 
				Format(client_message, 192, "%N has %d:%d (%.2f) kills with %d (%.2f) headshots", client, kills, deaths, kpd, headshots, hpk);
			case RAW_MESSAGE_SESSION_DATA:
				Format(client_message, 192, "%N has %d:%d (%.2f) kills, %d (%.2f) headshots, %d skill change", client, session_kills, session_deaths, session_kpd, session_headshots, session_hpk, session_skill_change);
		}
			

		decl String: message[192];
		if (strcmp(message_prefix, "") == 0) {
			Format(message, 192, "\x01%s", client_message);
		} else {
			gameMEStatsColorEntities(message_prefix);
			Format(message, 192, "\x04%s\x01 %s", message_prefix, client_message);
		}

		// display message
		if ((!IsFakeClient(client)) && (IsClientInGame(client))) {
			PrintToChatAll(message);
		}
	}
}


public onGameMEStatsTop10(command, client, String: message_prefix[], &Handle: datapack)
{
	if ((client > 0) && (command == RAW_MESSAGE_TOP10)) {
		new time = 15;
		new need_handler = 0;
		new String: message[1024];

		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		new total_count = ReadPackCell(data); // total_players

		if (total_count == -1) {

			Format(message, 1024, "->1 - Top Players\\n   Not yet available");

		} else {

			decl String: start_message[192];
			Format(start_message, 192, "->1 - Top Players\\n");
			strcopy(message[strlen(message)], 192, start_message);
	
			for (new i = 0; (i < total_count); i++) {

				new rank       = ReadPackCell(data); // rank
				new skill      = ReadPackCell(data); // skill

				decl String: name[64]; // name
				ReadPackString(data, name, 64);

				new Float: kpd = ReadPackFloat(data); // kpd
				new Float: hpk = ReadPackFloat(data); // hpk

				decl String: entry_message[192];
				Format(entry_message, 192, "   %02d  %d  %s\\n", rank, skill, name);
				strcopy(message[strlen(message)], 192, entry_message);
			}
		}
		CloseHandle(data);
		
		if ((!IsFakeClient(client)) && (IsClientInGame(client))) {
			DisplayGameMEStatsMenu(client, time, message, need_handler);			
		}
	}
}


public onGameMEStatsNext(command, client, String: message_prefix[], &Handle: datapack)
{
	if ((client > 0) && (command == RAW_MESSAGE_NEXT)) {
		new time = 15;
		new need_handler = 0;
		new String: message[1024];

		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		new total_count = ReadPackCell(data); // total_players

		if (total_count == -1) {

			Format(message, 1024, "->1 - Next Players\\n   Not yet available");

		} else {

			decl String: start_message[192];
			Format(start_message, 192, "->1 - Next Players\\n");
			strcopy(message[strlen(message)], 192, start_message);
	
			new prev_skill = -1;
			for (new i = 0; (i < total_count); i++) {

				new rank       = ReadPackCell(data); // rank
				new skill      = ReadPackCell(data); // skill

				decl String: name[64]; // name
				ReadPackString(data, name, 64);

				new Float: kpd = ReadPackFloat(data); // kpd
				new Float: hpk = ReadPackFloat(data); // hpk

				new diff  = -1;
				if (prev_skill > -1) {
					diff  = skill - prev_skill;
				}

				decl String: entry_message[192];
				if (i == 0) {
					Format(entry_message, 192, "   %02d  %d       -      %s\\n", rank, skill, name);
					strcopy(message[strlen(message)], 192, entry_message);
				} else {
					Format(entry_message, 192, "   %02d  %d  +%04d  %s\\n", rank, skill, diff, name);
					strcopy(message[strlen(message)], 192, entry_message);
				}

				if (prev_skill == -1) {
					prev_skill = skill;
				}
			}
		}
		CloseHandle(data);
		
		if ((!IsFakeClient(client)) && (IsClientInGame(client))) {
			DisplayGameMEStatsMenu(client, time, message, need_handler);			
		}
	}
}
