/**
 * gameME Plugin
 * http://www.gameme.com
 * Copyright (C) 2007-2014 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

 
#pragma semicolon 1

#define REQUIRE_EXTENSIONS 
#include <lang>
#include <sourcemod>
#include <keyvalues>
#include <menus>
#include <sdktools>
#include <gameme>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <clientprefs>
#include <sdkhooks>
#include <tf2_stocks>
#include <socket>


// plugin information
#define GAMEME_PLUGIN_VERSION "4.4.2"
public Plugin:myinfo = {
	name = "gameME Plugin",
	author = "TTS Oetzel & Goerz GmbH",
	description = "gameME Plugin",
	version = GAMEME_PLUGIN_VERSION,
	url = "http://www.gameme.com"
};

// mod information
#define MOD_CSS 1
#define MOD_DODS 2
#define MOD_HL2MP 3
#define MOD_TF2 4
#define MOD_L4D 5
#define MOD_L4DII 6
#define MOD_INSMOD 7
#define MOD_FF 8
#define MOD_CSP 9
#define MOD_ZPS 10
#define MOD_CSGO 11

new String: team_list[16][32];

// gameME Stats
#define GAMEME_TAG "gameME"
enum gameme_plugin_data {
  mod_id,
  String: game_mod[32],
  Handle: block_chat_commands,
  Handle: blocked_commands,
  Handle: block_chat_commands_values,
  Handle: message_prefix,
  String: message_prefix_value[32],
  Handle: protect_address,
  String: protect_address_value[32],
  String: protect_address_port,
  Handle: display_spectatorinfo,
  Handle: menu_main,
  Handle: menu_auto,
  Handle: menu_events,
  Handle: player_color_array,
  Handle: message_recipients,
  Handle: enable_log_locations,
  Handle: enable_damage_display,
  Handle: enable_gameme_live,
  Handle: gameme_live_address,
  String: gameme_live_address_value[32],
  String: gameme_live_address_port,
  log_locations,
  damage_display,
  damage_display_type,
  live_active, 
  Float: live_interval,
  display_spectator,
  bool: sdkhook_available,
  EngineVersion: engine_version,
  bool: ignore_next_tag_change,
  Handle: custom_tags,
  Handle: sv_tags,
  Handle: live_socket,
  server_port,
  protobuf
}
new gameme_plugin[gameme_plugin_data];


/**
 *  Spectator Info Display
 */

#define SPECTATOR_TIMER_INTERVAL 	0.5
#define SPECTATOR_NONE 				0
#define SPECTATOR_FIRSTPERSON 		4
#define SPECTATOR_3RDPERSON 		5
#define SPECTATOR_FREELOOK	 		6
#define QUERY_TYPE_UNKNOWN			0
#define QUERY_TYPE_SPECTATOR		1001

enum player_display_messages {
	String: smessage[255],
	supdated
}

new player_messages[MAXPLAYERS + 1][MAXPLAYERS + 1][player_display_messages];

enum spectator_data {
	Handle: stimer,
	Float: srequested,
	starget
}


/**
 *  gameME Stats Players
 */

enum gameme_data {
	prole, parmor, phealth, ploc1, ploc2, ploc3, pangle, pmoney, palive, pweapon, pgglevel,
	pspectator[spectator_data]
}

new gameme_players[MAXPLAYERS + 1][gameme_data];


/**
 *  Hit location tracking
 */

#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

#define MAX_LOG_WEAPONS    38
#define LOG_HIT_OFFSET     8
enum weapon_data {wshots, whits, wkills, wheadshots, wteamkills, wdamage, wdeaths, whealth, wgeneric, whead, wchest, wstomach, wleftarm, wrightarm, wleftleg, wrightleg}
	
new player_weapons[MAXPLAYERS + 1][MAX_LOG_WEAPONS][weapon_data];


/**
 *  Damage tracking
 */

#define	DAMAGE_HITS    	     0
#define	DAMAGE_KILLED	     1
#define	DAMAGE_HEADSHOT		 2
#define	DAMAGE_DAMAGE   	 3
#define	DAMAGE_KILLER	     4
#define	DAMAGE_HPLEFT    	 5
#define	DAMAGE_TEAMKILL 	 6
#define	DAMAGE_WEAPON    	 7
#define	DAMAGE_WEAPONKILLER  8

enum damage_data {dhits, dkills, dheadshots, ddamage, dkiller, dhpleft, dteamkill, dweapon}
	
new player_damage[MAXPLAYERS + 1][MAXPLAYERS + 1][damage_data];


/**
 *  Misc Handling
 */
 
new ColorSlotArray[] = { -1, -1, -1, -1, -1, -1 };


/**
 *  Counter-Strike: Global Offensive
 */


#define MAX_CSGO_CODE_MODELS 6
new const String: csgo_code_models[6][] = {"leet", 
	          	            	           "phoenix",
	          	            	           "balkan",
	          	            	           "st6",
	          	            	           "gign",
	          	            	           "gsg9"};
                                
#define MAX_CSGO_WEAPON_COUNT 38
new const String: csgo_weapon_list[][] = { "ak47", "m4a1", "deagle", "awp", "p90", "bizon", "hkp2000",
										   "glock", "nova", "galilar", "ump45", "famas", "aug", "ssg08",
										   "p250", "mp7", "elite", "sg556", "knife", "fiveseven", "sawedoff",
										   "mag7", "hegrenade", "tec9", "scar20", "mp9", "xm1014", "negev",
										   "g3sg1", "mac10", "m249", "taser", "inferno", "decoy", "flashbang",
										   "smokegrenade", "molotov", "incgrenade", "knifegg" };


/**
 *  Counter-Strike: Source
 */

new const String: css_code_models[8][] = {"phoenix", 
                           		   		  "leet", 
                              			  "arctic", 
                              			  "guerilla",
                              			  "urban", 
          	            	        	  "gsg9", 
            	            	    	  "sas", 
                		            	  "gign"};

#define MAX_CSS_CT_MODELS 4
new const String: css_ct_models[4][] = {"models/player/ct_urban.mdl", 
          	            	        	"models/player/ct_gsg9.mdl", 
            	            	    	"models/player/ct_sas.mdl", 
                		            	"models/player/ct_gign.mdl"};

#define MAX_CSS_TS_MODELS 4
new const String: css_ts_models[4][] = {"models/player/t_phoenix.mdl", 
                              			"models/player/t_leet.mdl", 
                              			"models/player/t_arctic.mdl", 
                              			"models/player/t_guerilla.mdl"};



#define MAX_CSS_WEAPON_COUNT 28
new const String: css_weapon_list[][] = { "ak47", "m4a1", "awp", "deagle", "mp5navy", "aug", "p90",
										  "famas", "galil", "scout", "g3sg1", "hegrenade", "usp",
										  "glock", "m249", "m3", "elite", "fiveseven", "mac10",
										  "p228", "sg550", "sg552", "tmp", "ump45", "xm1014", "knife",
										  "smokegrenade", "flashbang" };

enum css_plugin_data {
	money_offset
}

new css_data[css_plugin_data];


/**
 *  Day of Defeat: Source
 */

#define MAX_DODS_WEAPON_COUNT 26
new const String: dods_weapon_list[][] = {
									 "thompson",		// 11
									 "m1carbine",		// 7
									 "k98",				// 8
									 "k98_scoped",		// 10	// 34
									 "mp40",			// 12
									 "mg42",			// 16	// 36
									 "mp44",			// 13	// 38
									 "colt",			// 3
									 "garand",			// 31	// 6
									 "spring",			// 9	// 33
									 "c96",				// 5
									 "bar",				// 14
									 "30cal",			// 15	// 35
									 "bazooka",			// 17
									 "pschreck",		// 18
									 "p38",				// 4
									 "spade",			// 2
									 "frag_ger",		// 20
									 "punch",			// 30	// 29
									 "frag_us",			// 19
									 "amerknife",		// 1
									 "riflegren_ger",	// 26
									 "riflegren_us",	// 25
									 "smoke_ger",		// 24
									 "smoke_us",		// 23
									 "dod_bomb_target"
								};


/**
 *  Left4Dead 
 */
 
 #define MAX_L4D_WEAPON_COUNT 23
new const String: l4d_weapon_list[][] = { "rifle", "autoshotgun", "pumpshotgun", "smg", "dual_pistols",
										  "pipe_bomb", "hunting_rifle", "pistol", "prop_minigun",
										  "tank_claw", "hunter_claw", "smoker_claw", "boomer_claw",
										  "smg_silenced", "pistol_magnum", "rifle_ak47", "rifle_desert",
										  "shotgun_chrome", "shotgun_spas", "sniper_military", "jockey_claw",
										  "splitter_claw", "charger_claw"										  
										  };
 
enum l4dii_plugin_data {
	active_weapon_offset
}

new l4dii_data[l4dii_plugin_data];


/**
 *  Half-Life 2: Deathmatch
 */

#define MAX_HL2MP_WEAPON_COUNT 6
new const String: hl2mp_weapon_list[][] = { "crossbow_bolt", "smg1", "357", "shotgun", "ar2", "pistol" }; 

#define HL2MP_CROSSBOW 0

enum hl2mp_plugin_data {
	Handle: teamplay,
	bool: teamplay_enabled,
	Handle: boltchecks,
	crossbow_owner_offset
}

new hl2mp_data[hl2mp_plugin_data];

enum hl2mp_player {
	next_hitgroup,
	nextbow_hitgroup
}

new hl2mp_players[MAXPLAYERS + 1][hl2mp_player];


/**
 *  Zombie Panic! Source
 */

#define MAX_ZPS_WEAPON_COUNT 11
new const String: zps_weapon_list[][] = { "870", "revolver", "ak47", "usp", "glock18c", "glock", "mp5", "m4", "supershorty", "winchester", "ppk"};

enum zps_player {
	next_hitgroup
}

new zps_players[MAXPLAYERS + 1][zps_player];


/**
 *  Insurgency: Modern Infantry Combat
 */

#define MAX_INSMOD_WEAPON_COUNT 19
new const String: insmod_weapon_list[][] = { "makarov", "m9", "sks", "m1014", "toz", "svd", "rpk", "m249", "m16m203", "l42a1", "m4med", "m4", "m16a4", "m14", "fnfal", "aks74u", "ak47", "kabar", "bayonet"}; 

enum insmod_player {
	last_weapon
}

new insmod_players[MAXPLAYERS + 1][insmod_player];


/**
 *  Team Fortress 2
 */

#define TF2_UNLOCKABLE_BIT (1<<30)
#define TF2_WEAPON_PREFIX_LENGTH 10
#define TF2_MAX_LOADOUT_SLOTS 8
#define TF2_OBJ_DISPENSER 0
#define TF2_OBJ_TELEPORTER 1
#define TF2_OBJ_SENTRYGUN 2
#define TF2_OBJ_SENTRYGUN_MINI 20
#define TF2_ITEMINDEX_DEMOSHIELD 131
#define TF2_ITEMINDEX_GUNBOATS 133
#define TF2_JUMP_NONE 0
#define TF2_JUMP_ROCKET_START 1
#define TF2_JUMP_ROCKET 2
#define TF2_JUMP_STICKY 3
#define TF2_LUNCHBOX_CHOCOLATE 159
#define TF2_LUNCHBOX_STEAK 311

#define MAX_TF2_WEAPON_COUNT 28
new const String: tf2_weapon_list[MAX_TF2_WEAPON_COUNT][] = {
	"ball",
	"flaregun",
	"minigun",
	"natascha",
	"pistol",
	"pistol_scout",
	"revolver",
	"ambassador",
	"scattergun",
	"force_a_nature",
	"shotgun_hwg",
	"shotgun_primary",
	"shotgun_pyro",
	"shotgun_soldier",
	"smg",
	"sniperrifle",
	"syringegun_medic",
	"blutsauger",
	"tf_projectile_arrow",
	"tf_projectile_pipe",
	"tf_projectile_pipe_remote",
	"sticky_resistance",
	"tf_projectile_rocket",
	"rocketlauncher_directhit",
	"deflect_rocket",
	"deflect_promode",
	"deflect_flare",
	"deflect_arrow"
};


enum tf2_plugin_data {
	Handle: weapons_trie, 
	Handle: items_kv,
	Handle: slots_trie,
	stun_ball_id,
	Handle: stun_balls,
	Handle: wearables,
	carry_offset,
	Handle: critical_hits,
	critical_hits_enabled,
	bool: block_next_logging
}

new tf2_data[tf2_plugin_data];


enum tf2_player {
	player_loadout0[TF2_MAX_LOADOUT_SLOTS],
	player_loadout1[TF2_MAX_LOADOUT_SLOTS],
	bool: player_loadout_updated,
	Handle: object_list,
	Float: object_removed,
	jump_status,
	Float: dalokohs,
	TFClassType: player_class,
	bool: carry_object
}

new tf2_players[MAXPLAYERS + 1][tf2_player];


/**
 *  Raw Messages Interface
 */

#define RAW_MESSAGE_RANK				1
#define RAW_MESSAGE_PLACE				2
#define RAW_MESSAGE_KDEATH				3
#define RAW_MESSAGE_SESSION_DATA		4
#define RAW_MESSAGE_TOP10				5
#define RAW_MESSAGE_NEXT				6

// callbacks
#define RAW_MESSAGE_CALLBACK_PLAYER		101
#define RAW_MESSAGE_CALLBACK_TOP10		102
#define RAW_MESSAGE_CALLBACK_NEXT		103

// internal usage
#define RAW_MESSAGE_CALLBACK_INT_CLOSE		1000
#define RAW_MESSAGE_CALLBACK_INT_SPECTATOR	1001


new Handle: gameMEStatsRankForward;
new Handle: gameMEStatsPublicCommandForward;
new Handle: gameMEStatsTop10Forward;
new Handle: gameMEStatsNextForward;

new global_query_id = 0;
new Handle: QueryCallbackArray;

#define CALLBACK_DATA_SIZE 7
enum callback_data {callback_data_id, Float: callback_data_time, callback_data_client, Handle: callback_data_plugin, Function: callback_data_function, callback_data_payload, callback_data_limit};


public OnPluginStart() 
{
	LogToGame("gameME Plugin %s (http://www.gameme.com), copyright (c) 2007-2014 TTS Oetzel & Goerz GmbH", GAMEME_PLUGIN_VERSION);

	// setup default values
	gameme_plugin[log_locations]       = 1;
	gameme_plugin[damage_display]      = 0;
	gameme_plugin[damage_display_type] = 1;
	gameme_plugin[live_active]         = 0;
	gameme_plugin[live_interval]       = 0.2;
	gameme_plugin[protobuf]            = 0;

	LoadTranslations("gameme.phrases");
	
	// block origin gameME Stats command setup by default
	gameme_plugin[blocked_commands] = CreateTrie();
	SetTrieValue(gameme_plugin[blocked_commands], "rank", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/rank", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!rank", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "skill", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/skill", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!skill", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "points", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/points", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!points", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "place", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/place", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!place", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "session", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/session", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!session", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "sdata", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/sdata", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!sdata", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "kpd", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/kpd", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!kpd", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "kdratio", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/kdratio", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!kdratio", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "kdeath", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/kdeath", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!kdeath", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "next", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/next", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!next", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "load", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/load", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!load", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "status", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/status", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!status", 1); 
	SetTrieValue(gameme_plugin[blocked_commands], "top20", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/top20", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!top20", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "top10", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/top10", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!top10", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "top5", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/top5", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!top5", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "maps", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/maps", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!maps", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "map_stats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/map_stats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!map_stats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "clans", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/clans", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!clans", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "cheaters", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/cheaters", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!cheaters", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "statsme", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/statsme", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!statsme", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "weapons", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/weapons", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!weapons", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "weapon", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/weapon", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!weapon", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "action", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/action", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!action", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "actions", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/actions", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!actions", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "accuracy", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/accuracy", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!accuracy", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "targets", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/targets", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!targets", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "target", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/target", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!target", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "kills", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/kills", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!kills", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "kill", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/kill", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!kill", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "player_kills", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/player_kills", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!player_kills", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "cmds", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/cmds", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!cmds", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "commands", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/commands", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!commands", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_display 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_display 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_display 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_display 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_display 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_display 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_atb 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_atb 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_atb 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_atb 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_atb 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_atb 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_hideranking", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_hideranking", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_hideranking", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_reset", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_reset", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_reset", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_chat 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_chat 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_chat 0", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_chat 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_chat 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_chat 1", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gstats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gstats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gstats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "global_stats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/global_stats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!global_stats", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "gameme_menu", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "/gameme_menu", 1);
	SetTrieValue(gameme_plugin[blocked_commands], "!gameme_menu", 1);

	CreateConVar("gameme_plugin_version", GAMEME_PLUGIN_VERSION, "gameME Plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	CreateConVar("gameme_webpage", "http://www.gameme.com", "http://www.gameme.com", FCVAR_PLUGIN|FCVAR_NOTIFY);
	gameme_plugin[block_chat_commands] = CreateConVar("gameme_block_commands", "1", "If activated gameME commands are blocked from the chat area", FCVAR_PLUGIN);
	gameme_plugin[block_chat_commands_values] = CreateConVar("gameme_block_commands_values", "", "Define which commands should be blocked from the chat area", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[block_chat_commands_values], OnBlockChatCommandsValuesChange);
	gameme_plugin[message_prefix] = CreateConVar("gameme_message_prefix", "", "Define the prefix displayed on every gameME ingame message", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[message_prefix], OnMessagePrefixChange);
	gameme_plugin[protect_address] = CreateConVar("gameme_protect_address", "", "Address to be protected for logging/forwarding", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[protect_address], OnProtectAddressChange);
	gameme_plugin[enable_log_locations] = CreateConVar("gameme_log_locations", "1", "If activated the gameserver logs players locations", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[enable_log_locations], OnLogLocationsChange);
	gameme_plugin[display_spectatorinfo] = CreateConVar("gameme_display_spectatorinfo", "0", "If activated gameME Stats data are displayed while spectating a player", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[display_spectatorinfo], OnDisplaySpectatorinfoChange);
	gameme_plugin[enable_damage_display] = CreateConVar("gameme_damage_display", "0", "If activated the damage summary is display on player_death (1 = menu, 2 = chat)", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[enable_damage_display], OnDamageDisplayChange);
	gameme_plugin[enable_gameme_live] = CreateConVar("gameme_live", "0", "If activated gameME Live! is enabled", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[enable_gameme_live], OngameMELiveChange);
	gameme_plugin[gameme_live_address] = CreateConVar("gameme_live_address", "", "Network address of gameME Live!", FCVAR_PLUGIN);
	HookConVarChange(gameme_plugin[gameme_live_address], OnLiveAddressChange);

	get_server_mod();
	if (gameme_plugin[mod_id] == MOD_CSGO) {
		if (GetUserMessageType() == UM_Protobuf) {
			gameme_plugin[protobuf] = 1;
			LogToGame("Protobuf user messages detected");
		}
	}

	CreateGameMEMenuMain(gameme_plugin[menu_main]);
	CreateGameMEMenuAuto(gameme_plugin[menu_auto]);
	CreateGameMEMenuEvents(gameme_plugin[menu_events]);

	RegServerCmd("gameme_raw_message",   gameme_raw_message);
	RegServerCmd("gameme_psay",          gameme_psay);
	RegServerCmd("gameme_csay",          gameme_csay);
	RegServerCmd("gameme_msay",          gameme_msay);
	RegServerCmd("gameme_tsay",          gameme_tsay);
	RegServerCmd("gameme_hint",          gameme_hint);
	RegServerCmd("gameme_khint",         gameme_khint);
	RegServerCmd("gameme_browse",        gameme_browse);
	RegServerCmd("gameme_swap",          gameme_swap);
	RegServerCmd("gameme_redirect",      gameme_redirect);
	RegServerCmd("gameme_player_action", gameme_player_action);
	RegServerCmd("gameme_team_action",   gameme_team_action);
	RegServerCmd("gameme_world_action",  gameme_world_action);

	RegConsoleCmd("say",                 gameme_block_commands);
	RegConsoleCmd("say_team",            gameme_block_commands);

	if (gameme_plugin[mod_id] == MOD_INSMOD) {
		RegConsoleCmd("say2",            gameme_block_commands);
	}

	RegServerCmd("log", ProtectLoggingChange);
	RegServerCmd("logaddress_del", ProtectForwardingChange);
	RegServerCmd("logaddress_delall", ProtectForwardingDelallChange);
	RegServerCmd("gameme_message_prefix_clear", MessagePrefixClear);

	gameme_plugin[custom_tags] = CreateArray(128);
	gameme_plugin[sv_tags] = FindConVar("sv_tags");
	gameme_plugin[engine_version] = GetEngineVersion();
	if (gameme_plugin[sv_tags] != INVALID_HANDLE) {
		AddPluginServerTag(GAMEME_TAG);
		HookConVarChange(gameme_plugin[sv_tags], OnTagsChange);
	}

	
	if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
		HookEvent("player_team", gameME_Event_PlyTeamChange, EventHookMode_Pre);
	}
	
	switch (gameme_plugin[mod_id]) {
		case MOD_L4DII: {
			l4dii_data[active_weapon_offset] = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		}
		case MOD_HL2MP: {
			hl2mp_data[crossbow_owner_offset] = FindSendPropInfo("CCrossbowBolt", "m_hOwnerEntity");
			hl2mp_data[teamplay] = FindConVar("mp_teamplay");
			if (hl2mp_data[teamplay] != INVALID_HANDLE) {
				hl2mp_data[teamplay_enabled] = GetConVarBool(hl2mp_data[teamplay]);
				HookConVarChange(hl2mp_data[teamplay], OnTeamPlayChange);
			}
			hl2mp_data[boltchecks] = CreateStack();
		}
		case MOD_TF2: {
			tf2_data[critical_hits] = FindConVar("tf_weapon_criticals");
			HookConVarChange(tf2_data[critical_hits], OnTF2CriticalHitsChange);
		
			tf2_data[stun_balls] = CreateStack();
			tf2_data[wearables] = CreateStack();
			tf2_data[items_kv] = CreateKeyValues("items_game");
			if (FileToKeyValues(tf2_data[items_kv], "scripts/items/items_game.txt")) {
				KvJumpToKey(tf2_data[items_kv], "items");
			}
			tf2_data[slots_trie] = CreateTrie();
			SetTrieValue(tf2_data[slots_trie], "primary", 0);
			SetTrieValue(tf2_data[slots_trie], "secondary", 1);
			SetTrieValue(tf2_data[slots_trie], "melee", 2);
			SetTrieValue(tf2_data[slots_trie], "pda", 3);
			SetTrieValue(tf2_data[slots_trie], "pda2", 4);
			SetTrieValue(tf2_data[slots_trie], "building", 5);
			SetTrieValue(tf2_data[slots_trie], "head", 6);
			SetTrieValue(tf2_data[slots_trie], "misc", 7);

			for (new i = 0; (i <= MAXPLAYERS); i++) {
				tf2_players[i][object_list]  = CreateStack(); 
				tf2_players[i][carry_object] = false; 
				tf2_players[i][jump_status]  = 0;
			}
			
			init_tf2_weapon_trie();
			AddGameLogHook(OnTF2GameLog);
		}
	}


	GetConVarString(gameme_plugin[message_prefix], gameme_plugin[message_prefix_value], 32);
	color_gameme_entities(gameme_plugin[message_prefix_value]);

	if (gameme_plugin[protect_address] != INVALID_HANDLE) {
		decl String: protect_address_cvar_value[32];
		GetConVarString(gameme_plugin[protect_address], protect_address_cvar_value, 32);
		if (strcmp(protect_address_cvar_value, "") != 0) {
			decl String: ProtectSplitArray[2][16];
			new protect_split_count = ExplodeString(protect_address_cvar_value, ":", ProtectSplitArray, 2, 16);
			if (protect_split_count == 2) {
				strcopy(gameme_plugin[protect_address_value], 32, ProtectSplitArray[0]);
				gameme_plugin[protect_address_port] = StringToInt(ProtectSplitArray[1]);
			}
		}
	}


	if (gameme_plugin[gameme_live_address] != INVALID_HANDLE) {
		decl String: gameme_live_address_cvar_value[32];
		GetConVarString(gameme_plugin[gameme_live_address], gameme_live_address_cvar_value, 32);
		if (strcmp(gameme_live_address_cvar_value, "") != 0) {
			decl String: LiveSplitArray[2][16];
			new live_split_count = ExplodeString(gameme_live_address_cvar_value, ":", LiveSplitArray, 2, 16);
			if (live_split_count == 2) {
				strcopy(gameme_plugin[gameme_live_address_value], 32, LiveSplitArray[0]);
				gameme_plugin[gameme_live_address_port] = StringToInt(LiveSplitArray[1]);
			}
		}
	}

	new Handle: server_hostport = FindConVar("hostport");          
	if (server_hostport != INVALID_HANDLE) {
		decl String: temp_port[16];       
		GetConVarString(server_hostport, temp_port, 16);      
		gameme_plugin[server_port] = StringToInt(temp_port);
	}

	gameme_plugin[player_color_array] = CreateArray();
	gameme_plugin[message_recipients] = CreateStack();
	QueryCallbackArray = CreateArray(CALLBACK_DATA_SIZE);

	gameMEStatsRankForward = CreateGlobalForward("onGameMEStatsRank", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_Array, Param_Array, Param_String, Param_Array, Param_Array, Param_String);
	gameMEStatsPublicCommandForward = CreateGlobalForward("onGameMEStatsPublicCommand", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_Array, Param_Array, Param_String, Param_Array, Param_Array, Param_String);
	gameMEStatsTop10Forward = CreateGlobalForward("onGameMEStatsTop10", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String);
	gameMEStatsNextForward = CreateGlobalForward("onGameMEStatsNext", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String);

}


public OnPluginEnd() 
{
	if (gameme_plugin[player_color_array] != INVALID_HANDLE) {
		CloseHandle(gameme_plugin[player_color_array]);
	}
	if (gameme_plugin[message_recipients] != INVALID_HANDLE) {
		CloseHandle(gameme_plugin[message_recipients]);
	}
	if (QueryCallbackArray != INVALID_HANDLE) {
		CloseHandle(QueryCallbackArray);
	}
	if (gameme_plugin[blocked_commands] != INVALID_HANDLE) {
		CloseHandle(gameme_plugin[blocked_commands]);
	}
	
	if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS)) {
		for (new i = 1; (i <= MaxClients); i++) {
			if (gameme_players[i][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[i][pspectator][stimer]);
				gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
			}
		}
	}
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("gameme");

	CreateNative("DisplayGameMEStatsMenu", native_display_menu);
	CreateNative("QueryGameMEStats", native_query_gameme_stats);
	CreateNative("QueryGameMEStatsTop10", native_query_gameme_stats);
	CreateNative("QueryGameMEStatsNext", native_query_gameme_stats);
	CreateNative("QueryIntGameMEStats", native_query_gameme_stats);
	CreateNative("gameMEStatsColorEntities", native_color_gameme_entities);

	MarkNativeAsOptional("CS_SwitchTeam");
	MarkNativeAsOptional("CS_RespawnPlayer");
	MarkNativeAsOptional("SetCookieMenuItem");
	MarkNativeAsOptional("SDKHook");
	MarkNativeAsOptional("SocketCreate");
	MarkNativeAsOptional("SocketSendTo");

	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbAddString");

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	return APLRes_Success;
#else 	
	return true;
#endif
}


public OnAllPluginsLoaded()
{
	if (LibraryExists("clientprefs")) {
		SetCookieMenuItem(gameMESettingsMenu, 0, "gameME Settings");
	}

	if (LibraryExists("sdkhooks")) {
		LogToGame("Extension SDK Hooks is available");
		gameme_plugin[sdkhook_available] = true;
	}


	if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_CSGO)) {
		if ((strcmp(gameme_plugin[gameme_live_address_value], "") != 0) &&
		    (strcmp(gameme_plugin[gameme_live_address_port], "") != 0)) {
			new enable_gameme_live_cvar = GetConVarInt(gameme_plugin[enable_gameme_live]);
			if (enable_gameme_live_cvar == 1) {
				gameme_plugin[live_active] = 1;
				start_gameme_live();
				LogToGame("gameME Live! activated");
			} else if (enable_gameme_live_cvar == 0) {
				gameme_plugin[live_active] = 0;
				LogToGame("gameME Live! not active");
			}
		} else {
			gameme_plugin[live_active] = 0;
			LogToGame("gameME Live! cannot be activated, no gameME Live! address assigned");
		}
	}
	
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (gameme_plugin[sdkhook_available]) {
				switch (gameme_plugin[mod_id]) {
					case MOD_HL2MP: {
						SDKHook(i, SDKHook_FireBulletsPost,  OnHL2MPFireBullets);
						SDKHook(i, SDKHook_TraceAttackPost,  OnHL2MPTraceAttack);
						SDKHook(i, SDKHook_OnTakeDamagePost, OnHL2MPTakeDamage);
					}
					case MOD_ZPS: {
						SDKHook(i, SDKHook_FireBulletsPost,  OnZPSFireBullets);
						SDKHook(i, SDKHook_TraceAttackPost,  OnZPSTraceAttack);
						SDKHook(i, SDKHook_OnTakeDamagePost, OnZPSTakeDamage);
					}
					case MOD_TF2: {
						SDKHook(i, SDKHook_OnTakeDamagePost, OnTF2TakeDamage_Post);
						SDKHook(i, SDKHook_OnTakeDamage, 	 OnTF2TakeDamage);

						tf2_players[i][player_loadout_updated] = true;
						tf2_players[i][carry_object] = false;
						tf2_players[i][object_removed] = 0.0;
						tf2_players[i][player_class] = TFClass_Unknown;

						for (new j = 0; j < TF2_MAX_LOADOUT_SLOTS; j++) {
							tf2_players[i][player_loadout0][j] = -1;
							tf2_players[i][player_loadout1][j] = -1;
						}

					}
				}
			}

			if (!IsFakeClient(i)) {
				QueryClientConVar(i, "cl_language", ConVarQueryFinished: ClientConVar, i);
				if ((gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_DODS) || (gameme_plugin[mod_id] == MOD_HL2MP)) {
					QueryClientConVar(i, "cl_connectmethod", ConVarQueryFinished: ClientConVar, i);
				}
			}
			
			if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS)) {
				gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
				for (new j = 0; (j <= MAXPLAYERS); j++) {
					player_messages[j][i][supdated] = 1;
					strcopy(player_messages[j][i][smessage], 255, "");
				}
			}
		}
	}
}


public gameMESettingsMenu(client, CookieMenuAction: action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption) {
		DisplayMenu(gameme_plugin[menu_main], client, MENU_TIME_FOREVER);
	}
}


public OnMapStart()
{

	get_server_mod();

	for (new i = 0; (i <= MAXPLAYERS); i++) {
		reset_player_data(i);
		gameme_players[i][prole] = -1;
		gameme_players[i][pgglevel] = 0;
	}
	
	if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_DODS) || (gameme_plugin[mod_id] == MOD_HL2MP) ||
	    (gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_FF) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII) ||
	    (gameme_plugin[mod_id] == MOD_CSP)) {		

		decl String: map_name[64];
		GetCurrentMap(map_name, 64);

		new max_teams_count = GetTeamCount();
		for (new team_index = 0; (team_index < max_teams_count); team_index++) {
			decl String: team_name[32];
			if (gameme_plugin[mod_id] == MOD_INSMOD) {
				if ((strcmp(map_name, "ins_baghdad") == 0) || (strcmp(map_name, "ins_karam") == 0)) {
					switch (team_index) {
						case 1:
							strcopy(team_name, 32, "Iraqi Insurgents");
						case 2:
							strcopy(team_name, 32, "U.S. Marines");
						case 3:
							strcopy(team_name, 32, "SPECTATOR");
						default:
							strcopy(team_name, 32, "Unassigned");
					}
				} else {
					switch (team_index) {
						case 1:
							strcopy(team_name, 32, "U.S. Marines");
						case 2:
							strcopy(team_name, 32, "Iraqi Insurgents");
						case 3:
							strcopy(team_name, 32, "SPECTATOR");
						default:
							strcopy(team_name, 32, "Unassigned");
					}
				}
			} else {
				GetTeamName(team_index, team_name, 32);
			}

			if (strcmp(team_name, "") != 0) {
				team_list[team_index] = team_name;
			}
		}
	}
	
	if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
		find_player_team_slot(2);
		find_player_team_slot(3);
	}
	
	ClearArray(QueryCallbackArray);
}


get_server_mod()
{
	if (strcmp(gameme_plugin[game_mod], "") == 0) {
		new String: game_description[64];
		GetGameDescription(game_description, 64, true);

		if (StrContains(game_description, "Counter-Strike", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "CSS");
			gameme_plugin[mod_id] = MOD_CSS;
		}
		if (StrContains(game_description, "Counter-Strike: Global Offensive", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "CSGO");
			gameme_plugin[mod_id] = MOD_CSGO;
		}
		if (StrContains(game_description, "Day of Defeat", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "DODS");
			gameme_plugin[mod_id] = MOD_DODS;
		}
		if (StrContains(game_description, "Half-Life 2 Deathmatch", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "HL2MP");
			gameme_plugin[mod_id] = MOD_HL2MP;
		}
		if (StrContains(game_description, "Team Fortress", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "TF2");
			gameme_plugin[mod_id] = MOD_TF2;
		}
		if (StrContains(game_description, "Insurgency", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "INSMOD");
			gameme_plugin[mod_id] = MOD_INSMOD;
		}
		if (StrContains(game_description, "L4D", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "L4D");
			gameme_plugin[mod_id] = MOD_L4D;
		}
		if (StrContains(game_description, "Left 4 Dead 2", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "L4DII");
			gameme_plugin[mod_id] = MOD_L4DII;
		}
		if (StrContains(game_description, "Fortress Forever", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "FF");
			gameme_plugin[mod_id] = MOD_FF;
		}
		if (StrContains(game_description, "CSPromod", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "CSP");
			gameme_plugin[mod_id] = MOD_CSP;
		}
		if (StrContains(game_description, "ZPS", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "ZPS");
			gameme_plugin[mod_id] = MOD_ZPS;
		}
		
		// game mod could not detected, try further
		if (strcmp(gameme_plugin[game_mod], "") == 0) {
			new String: game_folder[64];
			GetGameFolderName(game_folder, 64);

			if (StrContains(game_folder, "cstrike", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "CSS");
				gameme_plugin[mod_id] = MOD_CSS;
			}
			if (StrContains(game_folder, "csgo", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "CSGO");
				gameme_plugin[mod_id] = MOD_CSGO;
			}
			if (StrContains(game_folder, "dod", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "DODS");
				gameme_plugin[mod_id] = MOD_DODS;
			}
			if (StrContains(game_folder, "hl2mp", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "HL2MP");
				gameme_plugin[mod_id] = MOD_HL2MP;
			}
			if (StrContains(game_folder, "tf", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "TF2");
				gameme_plugin[mod_id] = MOD_TF2;
			}
			if (StrContains(game_folder, "insurgency", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "INSMOD");
				gameme_plugin[mod_id] = MOD_INSMOD;
			}
			if (StrContains(game_folder, "left4dead", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "L4D");
				gameme_plugin[mod_id] = MOD_L4D;
			}
			if (StrContains(game_folder, "left4dead2", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "L4DII");
				gameme_plugin[mod_id] = MOD_L4DII;
			}
			if (StrContains(game_folder, "FortressForever", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "FF");
				gameme_plugin[mod_id] = MOD_FF;
			}
			if (StrContains(game_folder, "cspromod", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "CSP");
				gameme_plugin[mod_id] = MOD_CSP;
			}
			if (StrContains(game_folder, "zps", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "ZPS");
				gameme_plugin[mod_id] = MOD_ZPS;
			}
			if (strcmp(gameme_plugin[game_mod], "") == 0) {
				LogToGame("gameME - Game Detection: Failed (%s, %s)", game_description, game_folder);
			}
		}

		// setup hooks
		switch (gameme_plugin[mod_id]) {
			case MOD_CSGO: {
				HookEvent("weapon_fire",  		   	      Event_CSGOPlayerFire);
				HookEvent("weapon_fire_on_empty",  	      Event_CSGOPlayerFire);
				HookEvent("player_hurt",     	  		  Event_CSGOPlayerHurt);
				HookEvent("player_death", 			      Event_CSGOPlayerDeath);
				HookEvent("player_spawn",		     	  Event_CSGOPlayerSpawn);
				HookEvent("round_start",   	   	   	      Event_CSGORoundStart);
				HookEvent("round_end",       		  	  Event_CSGORoundEnd);
				HookEvent("round_announce_warmup",        Event_CSGOAnnounceWarmup);
				HookEvent("round_announce_match_start",   Event_CSGOAnnounceMatchStart);
				HookEvent("gg_player_levelup",            Event_CSGOGGLevelUp);
				HookEvent("ggtr_player_levelup",          Event_CSGOGGLevelUp);
				HookEvent("ggprogressive_player_levelup", Event_CSGOGGLevelUp);
				HookEvent("gg_final_weapon_achieved",     Event_CSGOGGWin);
				HookEvent("gg_leader",                    Event_CSGOGGLeader);
				HookEvent("round_mvp",                    Event_RoundMVP);

				HookEvent("bomb_dropped",		 	 gameME_Event_PlyBombDropped, EventHookMode_Pre);
				HookEvent("player_given_c4",     	 gameME_Event_PlyBombPickup,  EventHookMode_Pre);
				HookEvent("bomb_planted",    		 gameME_Event_PlyBombPlanted, EventHookMode_Pre);
				HookEvent("bomb_defused",    		 gameME_Event_PlyBombDefused, EventHookMode_Pre);
				HookEvent("hostage_killed",  		 gameME_Event_PlyHostageKill, EventHookMode_Pre);
				HookEvent("hostage_rescued", 		 gameME_Event_PlyHostageResc, EventHookMode_Pre);
				
			}
			case MOD_CSS: {
				HookEvent("weapon_fire",  			 Event_CSSPlayerFire);
				HookEvent("player_hurt",  			 Event_CSSPlayerHurt);
				HookEvent("player_death", 			 Event_CSSPlayerDeath);
				HookEvent("player_spawn",			 Event_CSSPlayerSpawn);
				HookEvent("round_start",   			 Event_CSSRoundStart);
				HookEvent("round_end",    			 Event_CSSRoundEnd);
				HookEvent("round_mvp",               Event_RoundMVP);

				HookEvent("bomb_dropped",			 gameME_Event_PlyBombDropped, EventHookMode_Pre);
				HookEvent("bomb_pickup",     		 gameME_Event_PlyBombPickup,  EventHookMode_Pre);
				HookEvent("bomb_planted",    		 gameME_Event_PlyBombPlanted, EventHookMode_Pre);
				HookEvent("bomb_defused",    		 gameME_Event_PlyBombDefused, EventHookMode_Pre);
				HookEvent("hostage_killed",  		 gameME_Event_PlyHostageKill, EventHookMode_Pre);
				HookEvent("hostage_rescued", 		 gameME_Event_PlyHostageResc, EventHookMode_Pre);
			}
			case MOD_DODS: {
				HookEvent("dod_stats_weapon_attack", Event_DODSWeaponAttack);
				HookEvent("player_hurt",  			 Event_DODSPlayerHurt);
				HookEvent("player_death", 			 Event_DODSPlayerDeath);
				HookEvent("round_end", 			     Event_DODSRoundEnd);
			}
			case MOD_TF2: {
				HookEvent("player_death", 			 	Event_TF2PlayerDeath);

				HookEvent("object_destroyed", 			Event_TF2ObjectDestroyedPre, EventHookMode_Pre);
				HookEvent("player_builtobject", 	 	Event_TF2PlayerBuiltObjectPre, EventHookMode_Pre);
				HookEvent("player_spawn", 			 	Event_TF2PlayerSpawn);
				HookEvent("round_start",   			 	Event_TF2RoundStart);
				HookEvent("round_end",    			 	Event_TF2RoundEnd);
				HookEvent("object_removed", 			Event_TF2ObjectRemoved);
				HookEvent("post_inventory_application", Event_TF2PostInvApp);
				HookEvent("teamplay_win_panel",     	Event_TF2WinPanel);
				HookEvent("arena_win_panel",         	Event_TF2WinPanel);
				HookEvent("player_teleported",       	Event_TF2PlayerTeleported);

				HookEvent("rocket_jump", 				Event_TF2RocketJump);
				HookEvent("rocket_jump_landed", 	 	Event_TF2JumpLanded);
				HookEvent("sticky_jump", 				Event_TF2StickyJump);
				HookEvent("sticky_jump_landed", 	 	Event_TF2JumpLanded);
				HookEvent("object_deflected", 			Event_TF2ObjectDeflected);

				HookEvent("player_stealsandvich",    	Event_TF2StealSandvich);
				HookEvent("player_stunned",          	Event_TF2Stunned);
				HookEvent("player_escort_score",     	Event_TF2EscortScore);
				HookEvent("deploy_buff_banner",      	Event_TF2DeployBuffBanner);
				HookEvent("medic_defended",          	Event_TF2MedicDefended);
				
				HookUserMessage(GetUserMessageId("PlayerJarated"),       Event_TF2Jarated);
				HookUserMessage(GetUserMessageId("PlayerShieldBlocked"), Event_TF2ShieldBlocked);
				
				AddNormalSoundHook(NormalSHook: Event_TF2SoundHook);
				
				tf2_data[carry_offset] = FindSendPropInfo("CTFPlayer", "m_bCarryingObject");
			}
			case MOD_L4D, MOD_L4DII: {
				HookEvent("weapon_fire",  			 Event_L4DPlayerFire);
				HookEvent("weapon_fire_on_empty",  	 Event_L4DPlayerFire);
				HookEvent("player_hurt",  			 Event_L4DPlayerHurt);
				HookEvent("infected_hurt",  		 Event_L4DInfectedHurt);
				HookEvent("player_death", 			 Event_L4DPlayerDeath);
				HookEvent("player_spawn", 			 Event_L4DPlayerSpawn);
				HookEvent("round_end_message",		 Event_L4DRoundEnd, EventHookMode_PostNoCopy);
		
				HookEvent("survivor_rescued",		 Event_L4DRescueSurvivor);
				HookEvent("heal_success", 			 Event_L4DHeal);
				HookEvent("revive_success", 		 Event_L4DRevive);
				HookEvent("witch_harasser_set", 	 Event_L4DStartleWitch);
				HookEvent("lunge_pounce", 			 Event_L4DPounce);
				HookEvent("player_now_it", 			 Event_L4DBoomered);
				HookEvent("friendly_fire", 			 Event_L4DFF);
				HookEvent("witch_killed", 			 Event_L4DWitchKilled);
				HookEvent("award_earned", 			 Event_L4DAward);

				if (gameme_plugin[mod_id] == MOD_L4DII) {
					HookEvent("defibrillator_used", 	 Event_L4DDefib);
					HookEvent("adrenaline_used", 	     Event_L4DAdrenaline);
					HookEvent("jockey_ride", 		     Event_L4DJockeyRide);
					HookEvent("charger_pummel_start",    Event_L4DChargerPummelStart);
					HookEvent("vomit_bomb_tank",         Event_L4DVomitBombTank);
					HookEvent("scavenge_match_finished", Event_L4DScavengeEnd);
					HookEvent("versus_match_finished",   Event_L4DVersusEnd);
					HookEvent("charger_killed",          Event_L4dChargerKilled);
				}
			
			}
			case MOD_INSMOD: {
				HookEvent("player_hurt",  			 Event_INSMODPlayerHurt); 
				HookEvent("player_death", 			 Event_INSMODPlayerDeath);
				HookEvent("player_spawn", 			 Event_INSMODPlayerSpawn);
				HookEvent("round_end",    			 Event_INSMODRoundEnd);
				
				HookUserMessage(GetUserMessageId("ObjMsg"), Event_INSMODObjMsg);
			}	
			case MOD_HL2MP: {
				HookEvent("player_death",            Event_HL2MPPlayerDeath);
				HookEvent("player_spawn",            Event_HL2MPPlayerSpawn);
				HookEvent("round_end",               Event_HL2MPRoundEnd, EventHookMode_PostNoCopy);
			}
			case MOD_ZPS: {
				HookEvent("player_death",            Event_ZPSPlayerDeath);
				HookEvent("player_spawn",            Event_ZPSPlayerSpawn);
				HookEvent("round_end",               Event_ZPSRoundEnd, EventHookMode_PostNoCopy);
			}
			case MOD_CSP: {
				HookEvent("round_start",   			 Event_CSPRoundStart);
				HookEvent("round_end",    			 Event_CSPRoundEnd);
			}
		} // end switch 

		// generic death event hook		
		HookEvent("player_death", gameME_Event_PlyDeath, EventHookMode_Pre);

		if ((gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII) || (gameme_plugin[mod_id] == MOD_INSMOD)) {
			// since almost no deaths occurs force the data to be logged at least every 180 seconds
			CreateTimer(180.0, flush_weapon_logs, 0, TIMER_REPEAT);
		}

		// player location logging
		if (gameme_plugin[enable_log_locations] != INVALID_HANDLE) {
			new enable_log_locations_cvar = GetConVarInt(gameme_plugin[enable_log_locations]);
			if (enable_log_locations_cvar == 1) {
				gameme_plugin[log_locations] = 1;
				LogToGame("gameME location logging activated");
			} else if (enable_log_locations_cvar == 0) {
				gameme_plugin[log_locations] = 0;
				LogToGame("gameME location logging deactivated");
			}
		} else {
			gameme_plugin[log_locations] = 0;
		}

		LogToGame("gameME - Game Detection: %s [%s]", game_description, gameme_plugin[game_mod]);

	}
}


public OnClientPutInServer(client)
{
	if (client > 0) {
		if (gameme_plugin[sdkhook_available]) {
			switch (gameme_plugin[mod_id]) {
				case MOD_HL2MP: {
					SDKHook(client, SDKHook_FireBulletsPost,  OnHL2MPFireBullets);
					SDKHook(client, SDKHook_TraceAttackPost,  OnHL2MPTraceAttack);
					SDKHook(client, SDKHook_OnTakeDamagePost, OnHL2MPTakeDamage);
				}
				case MOD_ZPS: {
					SDKHook(client, SDKHook_FireBulletsPost,  OnZPSFireBullets);
					SDKHook(client, SDKHook_TraceAttackPost,  OnZPSTraceAttack);
					SDKHook(client, SDKHook_OnTakeDamagePost, OnZPSTakeDamage);
				}
				case MOD_TF2: {
					SDKHook(client, SDKHook_OnTakeDamagePost, OnTF2TakeDamage_Post);
					SDKHook(client, SDKHook_OnTakeDamage, 	  OnTF2TakeDamage);
			
					tf2_players[client][player_loadout_updated] = true;
					tf2_players[client][carry_object] = false;
					tf2_players[client][object_removed] = 0.0;
					tf2_players[client][player_class] = TFClass_Unknown;

					for (new i = 0; (i < TF2_MAX_LOADOUT_SLOTS); i++) {
						tf2_players[client][player_loadout0][i] = -1;
						tf2_players[client][player_loadout1][i] = -1;
					}
				}
			}
		}

		reset_player_data(client);
		gameme_players[client][prole] = -1;
		gameme_players[client][pgglevel] = 0;
		
		if (!IsFakeClient(client)) {
			QueryClientConVar(client, "cl_language", ConVarQueryFinished:ClientConVar, client);
			if ((gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_DODS) || (gameme_plugin[mod_id] == MOD_HL2MP)) {
				QueryClientConVar(client, "cl_connectmethod", ConVarQueryFinished: ClientConVar, client);
			}
		}

		if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS)) {
			if (gameme_plugin[display_spectator] == 1) {
				gameme_players[client][pspectator][stimer] = INVALID_HANDLE;
				for (new j = 0; (j <= MAXPLAYERS); j++) {
					player_messages[j][client][supdated] = 1;
					strcopy(player_messages[j][client][smessage], 255, "");
				}
			}
		}

	}
}


public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {
	if (IsClientConnected(client)) {
		log_player_settings(client, "setup", cvarName, cvarValue);
	}
}


start_gameme_live()
{
	if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_CSGO)) {
		if (gameme_plugin[live_active] == 1) {
			if (GetExtensionFileStatus("socket.ext") == 1) {
				LogToGame("Extension Socket is available");
				if (gameme_plugin[mod_id] == MOD_CSS) {
					css_data[money_offset] = FindSendPropOffs("CCSPlayer", "m_iAccount");
				}
				gameme_plugin[live_socket] = SocketCreate(SOCKET_UDP, OnSocketError);
		
				CreateTimer(gameme_plugin[live_interval], CollectData, 0, TIMER_REPEAT);
			} else {
				LogToGame("gameME Live! not activated, Socket extension not available");
			}
		}
	} else {
		LogToGame("gameME Live! not enabled, not supported yet");
		gameme_plugin[live_active] = 0;
	}

}


get_weapon_index(const String: weapon_list[][], weapon_list_count, const String: weapon_name[])
{
	new loop_break = 0;
	new index = 0;
	
	while ((loop_break == 0) && (index < weapon_list_count)) {
   	    if (strcmp(weapon_name, weapon_list[index], true) == 0) {
       		loop_break++;
		} else {
			index++;
		}
	}

	if (loop_break == 0) {
		return -1;
	}
	return index;
}


init_tf2_weapon_trie()
{

	tf2_data[weapons_trie] = CreateTrie();
	for (new i = 0; i < MAX_TF2_WEAPON_COUNT; i++) {
		SetTrieValue(tf2_data[weapons_trie], tf2_weapon_list[i], i);
	}
	
	new index;
	if(GetTrieValue(tf2_data[weapons_trie], "ball", index)) {
		SetTrieValue(tf2_data[weapons_trie], "tf_projectile_stun_ball", index);
		tf2_data[stun_ball_id] = index;
	}
}


get_tf2_weapon_index(const String: weapon_name[], client = 0, weapon = -1)
{
	new weapon_index = -1;
	new bool: unlockable_weapon;
	new reflect_index = -1;

	if (strlen(weapon_name) < 15) {
		return -1;
	}
	
	if(GetTrieValue(tf2_data[weapons_trie], weapon_name, weapon_index)) {
		if (weapon_index & TF2_UNLOCKABLE_BIT) {
			weapon_index &= ~TF2_UNLOCKABLE_BIT;
			unlockable_weapon = true;
		}
		
		if ((weapon_name[3] == 'p') && (weapon > -1)) {
			if (client == GetEntProp(weapon, Prop_Send, "m_iDeflected")) {
				switch(weapon_name[14]) {
					case 'a':
						reflect_index = get_tf2_weapon_index("deflect_arrow");
					case 'f':
						reflect_index = get_tf2_weapon_index("deflect_flare");
					case 'p': {
						if (weapon_name[19] == 0) {
							reflect_index = get_tf2_weapon_index("deflect_promode");
						}
					}
					case 'r':
						reflect_index = get_tf2_weapon_index("deflect_rocket");
				}
			}
		}

		if (reflect_index > -1) {
			return reflect_index;
		}

		if ((unlockable_weapon) && (client > 0)) {
			new slot = 0;
			if (tf2_players[client][player_class] == TFClass_DemoMan) {
				slot = 1;
			}
			new item_index = tf2_players[client][player_loadout0][slot];
			switch (item_index) {
				case 36, 41, 45, 61, 127, 130:
					weapon_index++;
			}
		}
	}
	return weapon_index;
}



reset_player_data(player_index) 
{
	for (new i = 0; (i < MAX_LOG_WEAPONS); i++) {
		player_weapons[player_index][i][wshots]     = 0;
		player_weapons[player_index][i][whits]      = 0;
		player_weapons[player_index][i][wkills]     = 0;
		player_weapons[player_index][i][wheadshots] = 0;
		player_weapons[player_index][i][wteamkills] = 0;
		player_weapons[player_index][i][wdamage]    = 0;
		player_weapons[player_index][i][wdeaths]    = 0;
		player_weapons[player_index][i][wgeneric]   = 0;
		player_weapons[player_index][i][whead]      = 0;
		player_weapons[player_index][i][wchest]     = 0;
		player_weapons[player_index][i][wstomach]   = 0;
		player_weapons[player_index][i][wleftarm]   = 0;
		player_weapons[player_index][i][wrightarm]  = 0;
		player_weapons[player_index][i][wleftleg]   = 0;
		player_weapons[player_index][i][wrightleg]  = 0;

	}


	if (gameme_plugin[damage_display] == 1) {
		for (new i = 1; (i <= MaxClients); i++) {
			player_damage[player_index][i][dhits]         = 0;
			player_damage[player_index][i][dkills]        = 0;
			player_damage[player_index][i][dheadshots]    = 0;
			player_damage[player_index][i][ddamage]       = 0;
			player_damage[player_index][i][dkiller]       = 0;
			player_damage[player_index][i][dhpleft]       = 0;
			player_damage[player_index][i][dteamkill]     = 0;
			player_damage[player_index][i][dweapon]       = 0;
		}
	}

	if (gameme_plugin[live_active] == 1) {
		gameme_players[player_index][parmor]  = 0;
		gameme_players[player_index][phealth] = 0;
		gameme_players[player_index][ploc1]   = 0;
		gameme_players[player_index][ploc2]   = 0;
		gameme_players[player_index][ploc3]   = 0;
		gameme_players[player_index][pangle]  = 0;
		gameme_players[player_index][pmoney]  = 0;
		gameme_players[player_index][palive]  = 0;
	}

}


dump_player_data(player_index)
{
	if (IsClientInGame(player_index))  {
		new is_logged = 0;
		for (new i = 0; (i < MAX_LOG_WEAPONS); i++) {
			if (player_weapons[player_index][i][wshots] > 0) {
				switch (gameme_plugin[mod_id]) {
					case MOD_CSGO: {
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, csgo_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, csgo_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_CSS: {
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, css_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, css_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_DODS: {
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, dods_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, dods_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_L4D, MOD_L4DII: {
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, l4d_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, l4d_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_INSMOD: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, insmod_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, insmod_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_HL2MP: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, hl2mp_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, hl2mp_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_ZPS: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, zps_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, zps_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_TF2: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, tf2_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
					}
				} // switch
				is_logged++;
			}
		}
		if (is_logged > 0) {
			reset_player_data(player_index);
		}
	}
	
}


public Action: flush_weapon_logs(Handle:timer, any:index) 
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
}


public Action: spectator_player_timer(Handle:timer, any: caller) 
{
	if (((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS)) && (IsValidEntity(caller))) {
		new observer_mode = GetEntProp(caller, Prop_Send, "m_iObserverMode");
		if ((!IsFakeClient(caller)) && ((observer_mode == SPECTATOR_FIRSTPERSON) || (observer_mode == SPECTATOR_3RDPERSON))) {
			new target = GetEntPropEnt(caller, Prop_Send, "m_hObserverTarget");
			if ((target > 0) && (target <= MaxClients) && (IsClientInGame(target))) {

				if ((player_messages[caller][target][supdated] == 1) || (gameme_players[caller][pspectator][starget] == 0)) {
					for (new i = 0; (i <= MAXPLAYERS); i++) {
						player_messages[i][target][supdated] = 0;
					}
					QueryIntGameMEStats("spectatorinfo", target, QuerygameMEStatsIntCallback, QUERY_TYPE_SPECTATOR);
				}
			
				if (target != gameme_players[caller][pspectator][starget]) {
					gameme_players[caller][pspectator][srequested] = 0.0;
				}

				if (strcmp(player_messages[caller][target][smessage], "") != 0) {
					if ((caller > 0) && (caller <= MaxClients) && (!IsFakeClient(caller)) && (IsClientInGame(caller))) {
						if ((GetGameTime() - gameme_players[caller][pspectator][srequested]) > 5) {
							new Handle: message_handle = StartMessageOne("KeyHintText", caller);
							if (message_handle != INVALID_HANDLE) {
								if (gameme_plugin[protobuf] == 1) {
									PbAddString(message_handle, "hints", player_messages[caller][target][smessage]);
								} else {
									BfWriteByte(message_handle, 1);
									BfWriteString(message_handle, player_messages[caller][target][smessage]);
								}
								EndMessage();
							}
							gameme_players[caller][pspectator][srequested] = GetGameTime();
						}
					}
				} else {
					if (target != gameme_players[caller][pspectator][starget]) {
						if (gameme_plugin[mod_id] != MOD_CSGO) {
							new Handle: message_handle = StartMessageOne("KeyHintText", caller);
							if (message_handle != INVALID_HANDLE) {
								if (gameme_plugin[protobuf] == 1) {
									PbAddString(message_handle, "hints", "");
								} else {
									BfWriteByte(message_handle, 1);
									BfWriteString(message_handle, "");
								}
								EndMessage();
							}
						}
						gameme_players[caller][pspectator][srequested] = GetGameTime();
					}
				}
				gameme_players[caller][pspectator][starget] = target;
			}
		}
	}
}


public QuerygameMEStatsIntCallback(query_command, query_payload, query_caller[MAXPLAYERS + 1], query_target[MAXPLAYERS + 1], const String: query_message_prefix[], const String: query_message[])
{
	if ((query_caller[0] > 0) && (query_command == RAW_MESSAGE_CALLBACK_INT_SPECTATOR)) {
		if ((query_payload == QUERY_TYPE_SPECTATOR) && (query_target[0] > 0)) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				if (query_caller[i] > -1) {
					strcopy(player_messages[query_caller[i]][query_target[0]][smessage], 255, query_message);
					ReplaceString(player_messages[query_caller[i]][query_target[0]][smessage], 255, "\\n", "\10");
					gameme_players[query_caller[i]][pspectator][srequested] = 0.0;
				}
			}
		}
	}
}


public OnSocketError(Handle:socket, const errorType, const errorNum, any: arg) {
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
	gameme_plugin[live_socket] = SocketCreate(SOCKET_UDP, OnSocketError);
}


public Action:CollectData(Handle:timer, any:index) 
{

	if ((gameme_plugin[live_active] == 1) && (gameme_plugin[live_socket] != INVALID_HANDLE)) {
		new String: network_packet[1500];

		for(new i = 1; i <= MaxClients; i++) {
			new player_index = i;
			if (IsClientInGame(player_index)) {

				if (gameme_players[player_index][palive] == 1) {

					new Float: player_origin_float[3];
					GetClientAbsOrigin(player_index, player_origin_float);

					new player_origin[3];
					player_origin[0] = RoundFloat(player_origin_float[0]);
					player_origin[1] = RoundFloat(player_origin_float[1]);
					player_origin[2] = RoundFloat(player_origin_float[2]);

					new Float: player_angles_float[3];
					GetClientAbsAngles(player_index, player_angles_float);
					new player_angle;
					player_angle = RoundFloat(player_angles_float[1]);

					// player movement				
					if ((player_origin[0] != gameme_players[player_index][ploc1]) ||
						(player_origin[1] != gameme_players[player_index][ploc2]) ||
						(player_origin[2] != gameme_players[player_index][ploc3]) ||
						(player_angle     != gameme_players[player_index][pangle])) {

						gameme_players[player_index][ploc1]  = player_origin[0];
						gameme_players[player_index][ploc2]  = player_origin[1];
						gameme_players[player_index][ploc3]  = player_origin[2];
						gameme_players[player_index][pangle] = player_angle;
						
						decl String: send_message[128];
						Format(send_message, 128, "\255\255R\254%d\254%d\254%d\254%d\254\%d\254%d\254", gameme_plugin[server_port], GetClientUserId(player_index), gameme_players[player_index][ploc1], gameme_players[player_index][ploc2], gameme_players[player_index][ploc3], gameme_players[player_index][pangle]); 
						// LogToGame("|%s|", send_message);
						
						new send_message_len = strlen(send_message);
						new network_packet_len = strlen(network_packet);
						if ((network_packet_len + send_message_len) <= 1500) {
							strcopy(network_packet[network_packet_len], 1500, send_message);
						} else {
							if (strcmp(network_packet, "") != 0) {
								SocketSendTo(gameme_plugin[live_socket], network_packet, strlen(network_packet), gameme_plugin[gameme_live_address_value], gameme_plugin[gameme_live_address_port]);
								// LogToGame("Send [%s:%d]: |%s|", gameme_plugin[gameme_live_address_value], gameme_plugin[gameme_live_address_port], network_packet);
								network_packet[0] = '\0';
								if (strcmp(send_message, "") != 0) {
									strcopy(network_packet[1], 1500, send_message);
								}
							}
						}
						
					}
					

					new health = GetClientHealth(player_index);
					new armor  = GetClientArmor(player_index);
					decl String: player_weapon[32];
					GetClientWeapon(player_index, player_weapon, 32);
					new weapon_index;
					if (gameme_plugin[mod_id] == MOD_CSS) {
						weapon_index = get_weapon_index(css_weapon_list, MAX_CSS_WEAPON_COUNT, player_weapon[7]);
					} else if (gameme_plugin[mod_id] == MOD_CSGO) {
						weapon_index = get_weapon_index(csgo_weapon_list, MAX_CSGO_WEAPON_COUNT, player_weapon[7]);
					} else {
						weapon_index = -1;
					}
				
					new money;
					if (gameme_plugin[mod_id] == MOD_CSS) {
						if (css_data[money_offset] != -1) {
							money = GetEntData(player_index, css_data[money_offset]);
						}
					} else if (gameme_plugin[mod_id] == MOD_CSGO) {
						money = 0;
					} else {
						money = 0;
					}
					
					
					
					// player equipment
					if ((health != gameme_players[player_index][phealth]) ||
					 	(armor  != gameme_players[player_index][parmor]) ||
					 	(money  != gameme_players[player_index][pmoney]) ||
					 	((weapon_index > -1) && (weapon_index != gameme_players[player_index][pweapon]))) {

						// LogToGame("Health (%d): %d, %d", player_index, health, gameme_players[player_index][phealth]); 
						// LogToGame("Armor  (%d): %d, %d", player_index, armor,  gameme_players[player_index][parmor]); 
						// LogToGame("Money  (%d): %d, %d", player_index, money, gameme_players[player_index][pmoney]); 
						// LogToGame("Weapon (%d): %d, %d", player_index, weapon_index, gameme_players[player_index][pweapon]); 

						gameme_players[player_index][phealth] = health;
						gameme_players[player_index][parmor]  = armor;
						gameme_players[player_index][pmoney]  = money;
						gameme_players[player_index][pweapon] = weapon_index;
						
						new String: weapon_name[32];
						if (gameme_players[player_index][pweapon] > -1) {
							if (gameme_plugin[mod_id] == MOD_CSS) {
								Format(weapon_name, 32, css_weapon_list[gameme_players[player_index][pweapon]]);
							} else if (gameme_plugin[mod_id] == MOD_CSGO) {
								Format(weapon_name, 32, csgo_weapon_list[gameme_players[player_index][pweapon]]);
							} 
						}
						
						decl String: send_message[128];
						Format(send_message, 128, "\255\255S\254%d\254%d\254%d\254%d\254%s\254%d\254", gameme_plugin[server_port], GetClientUserId(player_index), gameme_players[player_index][phealth], gameme_players[player_index][parmor], weapon_name, gameme_players[player_index][pmoney]);
						// LogToGame("|%s|", send_message);
						
						new send_message_len = strlen(send_message);
						new network_packet_len = strlen(network_packet);
						if ((network_packet_len + send_message_len) <= 1500) {
							strcopy(network_packet[network_packet_len], 1500, send_message);
						} else {
							if (strcmp(network_packet, "") != 0) {
								SocketSendTo(gameme_plugin[live_socket], network_packet, strlen(network_packet), gameme_plugin[gameme_live_address_value], gameme_plugin[gameme_live_address_port]);
								// LogToGame("Send [%s:%d]: |%s|", gameme_plugin[gameme_live_address_value], gameme_plugin[gameme_live_address_port], network_packet);
								network_packet[0] = '\0';
								if (strcmp(send_message, "") != 0) {
									strcopy(network_packet[1], 1500, send_message);
								}
							}
						}

					}
				}
			}
		}
		
		if (strcmp(network_packet, "") != 0) {
			SocketSendTo(gameme_plugin[live_socket], network_packet, strlen(network_packet), gameme_plugin[gameme_live_address_value], gameme_plugin[gameme_live_address_port]);
			// LogToGame("Send [%s:%d]: |%s|", gameme_plugin[gameme_live_address_value], gameme_plugin[gameme_live_address_port], network_packet);
		}
		
	}

}


public PanelDamageHandler(Handle:menu, MenuAction:action, param1, param2)
{
}


public build_damage_panel(player_index) 
{

	if ((gameme_plugin[damage_display] == 0) || ((!IsClientInGame(player_index)) || (IsFakeClient(player_index)))) {
		return ;
	}

	new max_clients = GetMaxClients();

	new String: attacked[8][128];
	new attacked_index = 0;
	new String: wounded[8][128];
	new wounded_index = 0;
	new String: killed[8][128];
	new killed_index = 0;
	new String: killer[8][128];
	new killer_index = 0;

	for (new i = 1; (i <= max_clients); i++) {
		if (player_index == i) {
			for (new j = 1; (j <= max_clients); j++) {
				new wounded_damage = 0;
				new wounded_hits   = 0;
				new is_kill        = 0;
				if (player_damage[i][j][DAMAGE_HITS] > 0) {
					wounded_hits = player_damage[i][j][DAMAGE_HITS];
					wounded_damage = player_damage[i][j][DAMAGE_DAMAGE];
					if (player_damage[i][j][DAMAGE_KILLED] > 0) {
						is_kill++;
					}
				}
				if (wounded_hits > 0) {
					if (IsClientConnected(j)) {
						if (is_kill == 0) {
							decl String: victim_name[64];
							GetClientName(j, victim_name, 64);
							if (wounded_index < sizeof(wounded)) {
								if (wounded_hits == 1) {
									Format(wounded[wounded_index], 128, "  %s - %d %T, %d Hit", victim_name, wounded_damage, "DamagePanel_Dmg", player_index, wounded_hits, "DamagePanel_Hit", player_index);
								} else {
									Format(wounded[wounded_index], 128, "  %s - %d %T, %d Hits", victim_name, wounded_damage, "DamagePanel_Dmg", player_index, wounded_hits, "DamagePanel_Hits", player_index);
								}
								wounded_index++;
							}
						} else {
							decl String: victim_name[32];
							GetClientName(j, victim_name, 32);
							if (killed_index < sizeof(killed)) {
								if (wounded_hits == 1) {
									Format(killed[killed_index], 128, "  %s - %d %T, %d %T", victim_name, wounded_damage, "DamagePanel_Dmg", player_index, wounded_hits, "DamagePanel_Hit", player_index);
								} else {
									Format(killed[killed_index], 128, "  %s - %d %T, %d %T", victim_name, wounded_damage, "DamagePanel_Dmg", player_index, wounded_hits, "DamagePanel_Hits", player_index);
								}
								killed_index++;
							}
						}
					}
				}
			}
		} else {
			for (new j = 1; (j <= max_clients); j++) {
				if (j == player_index) {
					new attacked_damage   = 0;
					new attacked_hits     = 0;
					new is_killer         = 0;
					new killer_hpleft     = 0;
					new killer_weapon     = 0;
					if (player_damage[i][j][DAMAGE_HITS] > 0) {
						attacked_hits = player_damage[i][j][DAMAGE_HITS];
						attacked_damage = player_damage[i][j][DAMAGE_DAMAGE];
						if (player_damage[i][j][DAMAGE_KILLER] > 0) {
							is_killer++;
							killer_hpleft = player_damage[i][j][DAMAGE_HPLEFT];
							killer_weapon = player_damage[i][j][DAMAGE_WEAPON];
							
							player_damage[i][j][DAMAGE_KILLER] = 0;
							player_damage[i][j][DAMAGE_HPLEFT] = 0;
							player_damage[i][j][DAMAGE_WEAPON] = -1;
						}
					}
					if (attacked_hits > 0) {
						if (IsClientConnected(i)) {
							if (is_killer == 0) {
								decl String: attacker_name[64];
								GetClientName(i, attacker_name, 64);
								if (attacked_index < sizeof(attacked)) {
									if (attacked_hits == 1) {
										Format(attacked[attacked_index], 128, "  %s - %d %T, %d %T", attacker_name, attacked_damage, "DamagePanel_Dmg", player_index, attacked_hits, "DamagePanel_Hit", player_index);
									} else {
										Format(attacked[attacked_index], 128, "  %s - %d %T, %d %T", attacker_name, attacked_damage, "DamagePanel_Dmg", player_index, attacked_hits, "DamagePanel_Hits", player_index);
									}
									attacked_index++;
								}
							} else {
								decl String: killer_name[64];
								GetClientName(i, killer_name, 64);
								if (killer_index < sizeof(killer)) {
									if (gameme_plugin[mod_id] == MOD_CSGO) {								
										if (attacked_hits == 1) {
											Format(killer[killer_index], 128, "  %s - %d %T, %d %T, %s", killer_name, killer_hpleft,  "DamagePanel_Hp", player_index, attacked_damage, "DamagePanel_Dmg", player_index, csgo_weapon_list[killer_weapon]);
										} else {
											Format(killer[killer_index], 128, "  %s - %d %T, %d %T, %s", killer_name, killer_hpleft,  "DamagePanel_Hp", player_index, attacked_damage, "DamagePanel_Dmg", player_index, csgo_weapon_list[killer_weapon]);
										}
									} else if (gameme_plugin[mod_id] == MOD_CSS) {
										if (attacked_hits == 1) {
											Format(killer[killer_index], 128, "  %s - %d %T, %d %T, %s", killer_name, killer_hpleft,  "DamagePanel_Hp", player_index, attacked_damage, "DamagePanel_Dmg", player_index, css_weapon_list[killer_weapon]);
										} else {
											Format(killer[killer_index], 128, "  %s - %d %T, %d %T, %s", killer_name, killer_hpleft,  "DamagePanel_Hp", player_index, attacked_damage, "DamagePanel_Dmg", player_index, css_weapon_list[killer_weapon]);
										}
									} else if (gameme_plugin[mod_id] == MOD_DODS) {
										if (attacked_hits == 1) {
											Format(killer[killer_index], 128, "  %s - %d %T, %d %T, %s", killer_name, killer_hpleft,  "DamagePanel_Hp", player_index, attacked_damage, "DamagePanel_Dmg", player_index, dods_weapon_list[killer_weapon]);
										} else {
											Format(killer[killer_index], 128, "  %s - %d %T, %d %T, %s", killer_name, killer_hpleft,  "DamagePanel_Hp", player_index, attacked_damage, "DamagePanel_Dmg", player_index, dods_weapon_list[killer_weapon]);
										}
									}
									killer_index++;
								}
							}
						}
					}
				}
			}
		
		
		}
	}

	if ((attacked_index > 0) || (wounded_index > 0) || (killed_index > 0) || (killer_index > 0)) {
		new Handle:panel = CreatePanel();
		SetPanelKeys(panel, 1023);
	
		new is_attacked = 0;
		for (new i = 0; (i < sizeof(attacked)); i++) {
			if (strcmp(attacked[i], "") != 0) {
				is_attacked++;
				if (is_attacked == 1) {
					decl String: attackers_caption[32];
					Format(attackers_caption, 32, "%T", "DamagePanel_Attackers", player_index);
					DrawPanelItem(panel, attackers_caption);
				}
				DrawPanelText(panel, attacked[i]);
			} else {
				break;
			}
		}

		new is_killed = 0;
		for (new i = 0; (i < sizeof(killed)); i++) {
			if (strcmp(killed[i], "") != 0) {
				is_killed++;
				if (is_killed == 1) {
					decl String: killed_caption[32];
					Format(killed_caption, 32, "%T", "DamagePanel_Killed", player_index);
					DrawPanelItem(panel, killed_caption);
				}
				DrawPanelText(panel, killed[i]);
			} else {
				break;
			}
		}

		new is_wounded = 0;
		for (new i = 0; (i < sizeof(wounded)); i++) {
			if (strcmp(wounded[i], "") != 0) {
				is_wounded++;
				if (is_wounded == 1) {
					decl String: wounded_caption[32];
					Format(wounded_caption, 32, "%T", "DamagePanel_Wounded", player_index);
					DrawPanelItem(panel, wounded_caption);
				}
				DrawPanelText(panel, wounded[i]);
			} else {
				break;
			}
		}

		new is_killer = 0;
		for (new i = 0; (i < sizeof(killer)); i++) {
			if (strcmp(killer[i], "") != 0) {
				is_killer++;
				if (is_killer == 1) {
					decl String: killer_caption[32];
					Format(killer_caption, 32, "%T", "DamagePanel_Killer", player_index);
					DrawPanelItem(panel, killer_caption);
				}
				DrawPanelText(panel, killer[i]);
			} else {
				break;
			}
		}

		SendPanelToClient(panel, player_index, PanelDamageHandler, 15);
		CloseHandle(panel);
	}
}


public build_damage_chat(player_index) 
{

	if ((gameme_plugin[damage_display] == 0) || ((!IsClientInGame(player_index)) || (IsFakeClient(player_index)))) {
		return ;
	}

	new max_clients = GetMaxClients();
	decl String: killed_message[192];
	new killer_index = 0;

	for (new i = 1; (i <= max_clients); i++) {
		if (i != player_index) {
			for (new j = 1; (j <= max_clients); j++) {
				if (j == player_index) {
					new attacked_damage = 0;
					new killer_hpleft   = 0;
					new is_killer       = 0;
					if (player_damage[i][j][DAMAGE_HITS] > 0) {
						attacked_damage = player_damage[i][j][DAMAGE_DAMAGE];
						if (player_damage[i][j][DAMAGE_KILLER] > 0) {
							killer_hpleft = player_damage[i][j][DAMAGE_HPLEFT];
							is_killer++;

							player_damage[i][j][DAMAGE_KILLER] = 0;
							player_damage[i][j][DAMAGE_HPLEFT] = 0;
							player_damage[i][j][DAMAGE_WEAPON] = -1;
						}
					}

					if (is_killer > 0) {
						if (IsClientConnected(i)) {					
							decl String: killer_name[64];
							GetClientName(i, killer_name, 64);
							if (strcmp(gameme_plugin[message_prefix_value], "") == 0) {								
								Format(killed_message, 192, "%T", "DamageChat_Killedyou", player_index, killer_name, attacked_damage, killer_hpleft);
							} else {
								Format(killed_message, 192, "%s %T", gameme_plugin[message_prefix_value], "DamageChat_Killedyou", player_index, killer_name, attacked_damage, killer_hpleft);
							}
							killer_index++;
						}
					}
				}
			}
		}
	}

	if (killer_index > 0) {
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {

			if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_DODS)) {
				color_gameme_entities(killed_message);
					
				if (gameme_plugin[mod_id] == MOD_DODS) {
					PrintToChat(player_index, killed_message);
				} else { 
					new Handle: message_handle = StartMessageOne("SayText2", player_index);
					if (message_handle != INVALID_HANDLE) {
						if (gameme_plugin[protobuf] == 1) {
							PbSetInt(message_handle, "ent_idx", player_index);
							PbSetBool(message_handle, "chat", false);
							PbSetString(message_handle, "msg_name", killed_message);
							PbAddString(message_handle, "params", "");
							PbAddString(message_handle, "params", "");
							PbAddString(message_handle, "params", "");
							PbAddString(message_handle, "params", "");							
						} else {					
							BfWriteByte(message_handle, player_index); 
							BfWriteByte(message_handle, 0); 
							BfWriteString(message_handle, killed_message);
						}
						EndMessage();
					}
				}
			}
		}

	}
}


public Event_CSGOPlayerFire(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"        "short"
	// "weapon"        "string"        // weapon name used

	new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(csgo_weapon_list, MAX_CSGO_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if ((weapon_index != 22) && // hegrenade
			    (weapon_index != 32) && // inferno
			    (weapon_index != 33) && // decoy
			    (weapon_index != 34) && // flashbang
			    (weapon_index != 35) && // smokegrenade
			    (weapon_index != 36) && // molotov
			    (weapon_index != 37)) { // incgrenade
				player_weapons[userid][weapon_index][wshots]++;
			}
		}
	}
}


public Event_CSSPlayerFire(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"        "short"
	// "weapon"        "string"        // weapon name used

	new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(css_weapon_list, MAX_CSS_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if ((weapon_index != 27) && // flashbang
			    (weapon_index != 11) && // hegrenade
			    (weapon_index != 26)) { // smokegrenade
				player_weapons[userid][weapon_index][wshots]++;
			}
		}
	}
}


public Event_DODSWeaponAttack(Handle: event, const String: name[], bool:dontBroadcast)
{
    // "attacker"      "short"
    // "weapon"        "byte"

	new userid   = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (userid > 0) {
		new log_weapon_index  = GetEventInt(event, "weapon");

		new weapon_index = -1;
		switch (log_weapon_index) {
			case 1 :
				weapon_index = 20;
			case 2 :
				weapon_index = 16;
			case 3 :
				weapon_index = 7;
			case 4 :
				weapon_index = 15;
			case 5 :
				weapon_index = 10;
			case 6 :
				weapon_index = 8;
			case 7 :
				weapon_index = 1;
			case 8 :
				weapon_index = 2;
			case 9 :
				weapon_index = 9;
			case 10 :
				weapon_index = 3;
			case 11 :
				weapon_index = 0;
			case 12 :
				weapon_index = 4;
			case 13 :
				weapon_index = 6;
			case 14 :
				weapon_index = 11;
			case 15 :
				weapon_index = 12;
			case 16 :
				weapon_index = 5;
			case 17 :
				weapon_index = 13;
			case 18 :
				weapon_index = 14;
			case 19 :
				weapon_index = 19;
			case 20 :
				weapon_index = 17;
			case 23 :
				weapon_index = 24;
			case 24 :
				weapon_index = 23;
			case 25 :
				weapon_index = 22;
			case 26 :
				weapon_index = 21;
			case 31 :
				weapon_index = 8;
			case 33 :
				weapon_index = 9;
			case 34 :
				weapon_index = 3;
			case 35 :
				weapon_index = 12;
			case 36 :
				weapon_index = 5;
			case 38 :
				weapon_index = 6;
		}
		
		if (weapon_index > -1) {
			if ((weapon_index != 25) && // dod_bomb_target
			    (weapon_index != 21) && // riflegren_ger
			    (weapon_index != 22) && // riflegren_us
			    (weapon_index != 23) && // smoke_ger
			    (weapon_index != 24)) { // smoke_us
				player_weapons[userid][weapon_index][wshots]++;
			}
		}
	}

}


public Event_L4DPlayerFire(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "local"         "1"             // don't network this, its way too spammy
	// "userid"        "short"
	// "weapon"        "string"        // used weapon name  
	// "weaponid"      "short"         // used weapon ID
	// "count"         "short"         // number of bullets

	new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if ((weapon_index != 12) && // entityflame
			    (weapon_index != 6)) { // inferno
				player_weapons[userid][weapon_index][wshots]++;
			}
		}
	}
}


public Event_CSGOPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	//	"userid"        "short"         // player index who was hurt
	//	"attacker"      "short"         // player index who attacked
	//	"health"        "byte"          // remaining health points
	//	"armor"         "byte"          // remaining armor points
	//	"weapon"        "string"        // weapon name attacker used, if not the world
	//	"dmg_health"    "byte"  		// damage done to health
	//	"dmg_armor"     "byte"          // damage done to armor
	//	"hitgroup"      "byte"          // hitgroup that was damaged

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(csgo_weapon_list, MAX_CSGO_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "dmg_health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}


			if (gameme_plugin[damage_display] == 1) {
				player_damage[attacker][victim][dhits]++;
				player_damage[attacker][victim][ddamage] += GetEventInt(event, "dmg_health");
			}
		}
	}
}


public Event_CSSPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	//	"userid"        "short"         // player index who was hurt
	//	"attacker"      "short"         // player index who attacked
	//	"health"        "byte"          // remaining health points
	//	"armor"         "byte"          // remaining armor points
	//	"weapon"        "string"        // weapon name attacker used, if not the world
	//	"dmg_health"    "byte"  		// damage done to health
	//	"dmg_armor"     "byte"          // damage done to armor
	//	"hitgroup"      "byte"          // hitgroup that was damaged

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(css_weapon_list, MAX_CSS_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "dmg_health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}

			if (gameme_plugin[damage_display] == 1) {
				player_damage[attacker][victim][dhits]++;
				player_damage[attacker][victim][ddamage] += GetEventInt(event, "dmg_health");
			}
		}
	}
}


public Event_DODSPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user ID who attacked
	// "weapon"        "string"        // weapon name attacker used
	// "health"        "byte"          // health remaining
	// "damage"        "byte"          // how much damage in this attack
	// "hitgroup"      "byte"          // what hitgroup was hit

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(dods_weapon_list, MAX_DODS_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}

			if (gameme_plugin[damage_display] == 1) {
				player_damage[attacker][victim][dhits]++;
				player_damage[attacker][victim][ddamage] += GetEventInt(event, "damage");
			}
		}
	}
}


public Event_L4DPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "local"         "1"             // Not networked
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user id who attacked
	// "attackerentid" "long"          // entity id who attacked, if attacker not a player, and userid therefore invalid
	// "health"        "short"         // remaining health points
	// "armor"         "byte"          // remaining armor points
	// "weapon"        "string"        // weapon name attacker used, if not the world
	// "dmg_health"    "short"         // damage done to health
	// "dmg_armor"     "byte"          // damage done to armor
	// "hitgroup"      "byte"          // hitgroup that was damaged
	// "type"          "long"          // damage type

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "dmg_health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}

		} else if (!strcmp(weapon_str, "insect_swarm")) {
			if ((victim > 0) && (IsClientInGame(victim)) && (GetClientTeam(victim) == 2) &&  (!GetEntProp(victim, Prop_Send, "m_isIncapacitated"))) {
				log_player_player_event(attacker, victim, "triggered", "spit_hurt");
			}
		} 

	}
}


public Event_L4DInfectedHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "local"         "1"             // don't network this, its way too spammy
	// "attacker"      "short"         // player userid who attacked
	// "entityid"      "long"          // entity id of infected
	// "hitgroup"      "byte"          // hitgroup that was damaged
	// "amount"        "short"         // how much damage was done                  
	// "type"          "long"          // damage type     

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0) {
		decl String: weapon_str[32];
		GetClientWeapon(attacker, weapon_str, 32);
		new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str[7]);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "amount");

			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}

		}
	}
}


public Event_INSMODPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{ 	
	//  "userid"		"short"			// user ID on server 	
	//  "attacker"		"short"			// user ID on server of the attacker 	
	//  "dmg_health"	"short"			// lost health points 	
	//  "hitgroup"		"short"			// Hit groups 
	//  "weapon"		"string"		// Weapon name, like WEAPON_AK47
	
	new attacker  = GetEventInt(event, "attacker");
	new victim = GetEventInt(event, "userid");

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(insmod_weapon_list, MAX_INSMOD_WEAPON_COUNT, weapon_str[7]);
		if (weapon_index > -1) {
			
			// we cannot track the shots
			//if (player_weapons[attacker][weapon_index][wshots] == 0) {
			//	player_weapons[attacker][weapon_index][wshots]++;
			//}
			
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage]  += GetEventInt(event, "dmg_health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			} else {
				player_weapons[attacker][weapon_index][hitgroup]++;
			} 

			if (hitgroup == HITGROUP_HEAD) {
				player_weapons[attacker][weapon_index][wheadshots]++;
				log_player_event(attacker, "triggered", "headshot");
			}
			insmod_players[attacker][last_weapon] = weapon_index;
		}
	}
} 


public Event_CSGOPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	//	"userid"	"short"   	// user ID who died				
	//	"attacker"	"short"	 	// user ID who killed
	//	"assister"	"short"	 	// user ID who assisted in the kill
	//	"weapon"	"string" 	// weapon name killer used 
	//	"headshot"	"bool"		// singals a headshot
	//	"dominated"	"short"		// did killer dominate victim with this kill
	//	"revenge"	"short"		// did killer get revenge on victim with this kill
	//	"penetrated" "short"	// number of objects shot penetrated before killing target

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(csgo_weapon_list, MAX_CSGO_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				new headshot = GetEventBool(event, "headshot");
				if (headshot == 1) {
					player_weapons[attacker][weapon_index][wheadshots]++;
				}
				player_weapons[victim][weapon_index][wdeaths]++;

				if (GetEventInt(event, "dominated")) {
					log_player_player_event(attacker, victim, "triggered", "domination");
				} else if (GetEventInt(event, "revenge")) {
					log_player_player_event(attacker, victim, "triggered", "revenge");
				}

				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
					if (gameme_plugin[damage_display] == 1) {
						player_damage[attacker][victim][dteamkill] += 1;
					}		
				} else {
					new assister = GetClientOfUserId(GetEventInt(event, "assister"));
					if ((assister > 0) && (assister != victim)) {
						log_player_player_event(assister, victim, "triggered", "kill_assist");
					}
				}

				if (gameme_plugin[damage_display] == 1) {
					player_damage[attacker][victim][dhpleft]    = GetClientHealth(attacker);
					player_damage[attacker][victim][dkills]     += 1;
					player_damage[attacker][victim][dkiller]    = attacker;
					player_damage[attacker][victim][dweapon]    = weapon_index;
					if (headshot == 1) {
						player_damage[attacker][victim][dheadshots] += 1;
					}

					if (gameme_plugin[damage_display_type] == 2) {
						build_damage_chat(victim);
					} else {
						build_damage_panel(victim);
					}
					
				}
			}
		}
		dump_player_data(victim);
		
		gameme_players[victim][palive] = 0;
		if (gameme_plugin[display_spectator] == 1) {
			if ((IsClientInGame(victim)) && (!IsFakeClient(victim))) {
				gameme_players[victim][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}

			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[j][attacker][supdated] = 1;
				player_messages[j][victim][supdated] = 1;
			}
		}
	}
}

 
public Event_CSSPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	// "userid"        "short"         // user ID who died                             
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killer used 
	// "headshot"      "bool"          // signals a headshot
	// "dominated" 	   "short"		   // did killer dominate victim with this kill
	// "revenge" 	   "short" 		   // did killer get revenge on victim with this kill 
	
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(css_weapon_list, MAX_CSS_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				new headshot = GetEventBool(event, "headshot");
				if (headshot == 1) {
					player_weapons[attacker][weapon_index][wheadshots]++;
				}
				player_weapons[victim][weapon_index][wdeaths]++;

				if (GetEventInt(event, "dominated")) {
					log_player_player_event(attacker, victim, "triggered", "domination");
				} else if (GetEventInt(event, "revenge")) {
					log_player_player_event(attacker, victim, "triggered", "revenge");
				}


				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
					if (gameme_plugin[damage_display] == 1) {
						player_damage[attacker][victim][dteamkill] += 1;
					}		
				}

				if (gameme_plugin[damage_display] == 1) {
					player_damage[attacker][victim][dhpleft]    = GetClientHealth(attacker);
					player_damage[attacker][victim][dkills]     += 1;
					player_damage[attacker][victim][dkiller]    = attacker;
					player_damage[attacker][victim][dweapon]    = weapon_index;
					if (headshot == 1) {
						player_damage[attacker][victim][dheadshots] += 1;
					}

					if (gameme_plugin[damage_display_type] == 2) {
						build_damage_chat(victim);
					} else {
						build_damage_panel(victim);
					}

				}
			}
		}
		dump_player_data(victim);
		
		gameme_players[victim][palive] = 0;
		if (gameme_plugin[display_spectator] == 1) {
			if ((IsClientInGame(victim)) && (!IsFakeClient(victim))) {
				gameme_players[victim][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}

			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[j][attacker][supdated] = 1;
				player_messages[j][victim][supdated] = 1;
			}
		}
	}
}


public Event_DODSPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death
	// "userid"        "short"         // user ID who died
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killed used

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(dods_weapon_list, MAX_DODS_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				player_weapons[victim][weapon_index][wdeaths]++;

				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
					if (gameme_plugin[damage_display] == 1) {
						player_damage[attacker][victim][dteamkill] += 1;
					}		
				}

				if (gameme_plugin[damage_display] == 1) {
					player_damage[attacker][victim][dhpleft]    = GetClientHealth(attacker);
					player_damage[attacker][victim][dkills]     += 1;
					player_damage[attacker][victim][dkiller]    = attacker;
					player_damage[attacker][victim][dweapon]    = weapon_index;

					if (gameme_plugin[damage_display_type] == 2) {
						build_damage_chat(victim);
					} else {
						build_damage_panel(victim);
					}
				}
			}
		}
		dump_player_data(victim);
	}
}


public Event_L4DPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID who died
	// "entityid"      "long"          // entity ID who died, userid should be used first, to get the dead Player.  Otherwise, it is not a player, so use this.         $
	// "attacker"      "short"         // user ID who killed   
	// "attackername"  "string"        // What type of zombie, so we don't have zombie names
	// "attackerentid" "long"          // if killer not a player, the entindex of who killed.  Again, use attacker first
	// "weapon"        "string"        // weapon name killer used
	// "headshot"      "bool"          // signals a headshot
	// "attackerisbot" "bool"          // is the attacker a bot
	// "victimname"    "string"        // What type of zombie, so we don't have zombie names
	// "victimisbot"   "bool"          // is the victim a bot     
	// "abort"         "bool"          // did the victim abort        
	// "type"          "long"          // damage type      
	// "victim_x"      "float"
	// "victim_y"      "float"
	// "victim_z"      "float"

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				new headshot = GetEventBool(event, "headshot");
				if (headshot == 1) {
					player_weapons[attacker][weapon_index][wheadshots]++;
				}
				player_weapons[victim][weapon_index][wdeaths]++;

				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
			}
		}
		dump_player_data(victim);
	}
}


public Event_INSMODPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	//  "userid"	"short"   	// user ID who died				
	//  "attacker"	"short"	 	// user ID who killed
	//  "type"		"byte"		// type of death
	//  "nodeath"	"bool"		// true if death messages were off when player died

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			new weapon_index = insmod_players[attacker][last_weapon];
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				player_weapons[victim][weapon_index][wdeaths]++;
				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
			}
		}
		dump_player_data(victim);
	}
}


public Event_HL2MPPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	// "userid"        "short"         // user ID who died                             
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killer used 
	
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(hl2mp_weapon_list, MAX_HL2MP_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;		
				player_weapons[victim][weapon_index][wdeaths]++;
				if ((hl2mp_data[teamplay_enabled]) && (GetClientTeam(attacker) == GetClientTeam(victim))) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}	
			}
		}
		dump_player_data(victim);
	}
}


public Event_ZPSPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	// "userid"        "short"         // user ID who died                             
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killer used 
	
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(zps_weapon_list, MAX_ZPS_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;		
				player_weapons[victim][weapon_index][wdeaths]++;
				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
			}
		}
		dump_player_data(victim);
	}
}


public Event_CSGOPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
		if (gameme_plugin[display_spectator] == 1) {
			if (gameme_players[userid][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[userid][pspectator][stimer]);
				gameme_players[userid][pspectator][stimer] = INVALID_HANDLE;
			}
		}
		

		if (IsClientInGame(userid)) {
			new client_team = GetClientTeam(userid);
			if ((client_team == 2) || (client_team == 3)) {

				decl String: client_model[128];
				GetClientModel(userid, client_model, 128);
			
				new role_index = -1;
				for (new i = 0; (i < MAX_CSGO_CODE_MODELS); i++) {
					if (StrContains(client_model, csgo_code_models[i]) != -1) {
						role_index = i;
					}
				}
		
				if (role_index > -1) {
					if (gameme_players[userid][prole] != role_index) {
						gameme_players[userid][prole] = role_index;
						LogToGame("\"%L\" changed role to \"%s\"", userid, csgo_code_models[role_index]);
					}
				}

			} else if (client_team == 0) {

				if (gameme_plugin[display_spectator] == 1) {
					gameme_players[userid][pspectator][starget] = 0;
					if (!IsFakeClient(userid)) {
						gameme_players[userid][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					}
				}

			}
		}
		
	}
}


public Event_CSSPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
		if (gameme_plugin[display_spectator] == 1) {
			if (gameme_players[userid][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[userid][pspectator][stimer]);
				gameme_players[userid][pspectator][stimer] = INVALID_HANDLE;
			}
		}


		if (IsClientInGame(userid)) {
			new client_team = GetClientTeam(userid);
			if ((client_team == 2) || (client_team == 3)) {

				decl String: client_model[128];
				GetClientModel(userid, client_model, 128);
			
				new role_index = -1;
				if (client_team == 2) {
					for (new i = 0; (i < MAX_CSS_TS_MODELS); i++) {
						if (strcmp(css_ts_models[i], client_model) == 0) {
							role_index = i;
						}
					}
				} else if (client_team == 3) {
					for (new i = 0; (i < MAX_CSS_CT_MODELS); i++) {
						if (strcmp(css_ct_models[i], client_model) == 0) {
							role_index = i + MAX_CSS_TS_MODELS;
						}
					}
				}
			
				if (role_index > -1) {
					if (gameme_players[userid][prole] != role_index) {
						gameme_players[userid][prole] = role_index;
						LogToGame("\"%L\" changed role to \"%s\"", userid, css_code_models[role_index]);
					}
				}

			} else if (client_team == 0) {

				if (gameme_plugin[display_spectator] == 1) {
					gameme_players[userid][pspectator][starget] = 0;

					if (!IsFakeClient(userid)) {
						gameme_players[userid][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					}
				}

			}
		}

	}
}


public Event_L4DPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
}


public Event_INSMODPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
}


public Event_HL2MPPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
}


public Event_ZPSPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
}


public Action: Event_CSPRoundStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	LogToGame("World triggered \"Round_Start\"");
}


public Event_CSGORoundStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	if (gameme_plugin[display_spectator] == 1) {
		for (new i = 1; (i <= MaxClients); i++) {
			if (gameme_players[i][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[i][pspectator][stimer]);
				gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
			}

			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[i][j][supdated] = 1;
			}

			if ((i > 0) && (IsClientInGame(i)) && (!IsFakeClient(i)) && (IsClientObserver(i))) {
				gameme_players[i][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, i, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	if (gameme_plugin[live_active] == 1) {
		for (new i = 1; (i <= MaxClients); i++) {
			gameme_players[i][palive] = 1;
		}
	}
}


public Event_CSSRoundStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	if (gameme_plugin[display_spectator] == 1) {
		for (new i = 1; (i <= MaxClients); i++) {

			if (gameme_players[i][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[i][pspectator][stimer]);
				gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
			}

			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[i][j][supdated] = 1;
			}

			if ((i > 0) && (IsClientInGame(i)) && (!IsFakeClient(i)) && (IsClientObserver(i))) {
				gameme_players[i][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, i, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	if (gameme_plugin[live_active] == 1) {
		for (new i = 1; (i <= MaxClients); i++) {
			gameme_players[i][palive] = 1;
		}
	}
}


public Event_CSGORoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		if ((IsClientConnected(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i))) {
			if (gameme_plugin[damage_display_type] == 1) {
				build_damage_panel(i);
			}
		}
		dump_player_data(i);
	}
}


public Event_CSSRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		if ((IsClientConnected(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i))) {
			if (gameme_plugin[damage_display_type] == 1) {
				build_damage_panel(i);
			}
		}
		dump_player_data(i);
	}
}


public Event_DODSRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		if ((IsClientConnected(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i))) {
			if (gameme_plugin[damage_display_type] == 1) {
				build_damage_panel(i);
			}
		}
		dump_player_data(i);
	}
}


public Event_L4DRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
}


public Event_INSMODRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}

	new team_index = GetEventInt(event, "winner");
	if (team_index > 0) {
		log_team_event(team_list[team_index], "Round_Win");
	}
}


public Event_HL2MPRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
}


public Event_ZPSRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
}


public Event_CSPRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	new team_index = GetEventInt(event, "winners");
	if (strcmp(team_list[team_index], "") != 0) {
		log_team_event(team_list[team_index], "Round_Win");
	}
	LogToGame("World triggered \"Round_End\"");
}


public Event_CSGOAnnounceWarmup(Handle: event, const String: name[], bool:dontBroadcast)
{
	LogToGame("World triggered \"Round_Warmup_Start\"");
}


public Event_CSGOAnnounceMatchStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 0; (i <= MAXPLAYERS); i++) {
		reset_player_data(i);
		gameme_players[i][pgglevel] = 0;
	}
	LogToGame("World triggered \"Round_Match_Start\"");
}


public Event_CSGOGGLevelUp(Handle: event, const String: name[], bool:dontBroadcast)
{
	//	"userid"	"short"		// player who leveled up
	//	"weaponrank"	"short"
	//	"weaponname"	"string"	// name of weapon being awarded

	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {

		new level = GetEventInt(event,"weaponrank");
		if (level >= 0) {
			if (level > gameme_players[player][pgglevel]) {
				log_player_event(player, "triggered", "gg_levelup");
			} else if (level < gameme_players[player][pgglevel]) {
				log_player_event(player, "triggered", "gg_leveldown");
			}
			gameme_players[player][pgglevel] = level;
		}
	}
}


public Event_CSGOGGWin(Handle: event, const String: name[], bool:dontBroadcast)
{
	// 	"playerid"	"short"	 	// user ID who achieved the final gun game weapon

	new player = GetClientOfUserId(GetEventInt(event, "playerid"));
	if (player > 0) {
		log_player_event(player, "triggered", "gg_win");
	}
}


public Event_CSGOGGLeader(Handle: event, const String: name[], bool:dontBroadcast)
{
	//	"playerid"      "short"         // user ID that is currently in the lead

	new player = GetClientOfUserId(GetEventInt(event, "playerid"));
	if (player > 0) {
		log_player_event(player, "triggered", "gg_leader");
	}
}


public Event_RoundMVP(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		log_player_event(player, "triggered", "mvp");
	}
}


public Event_TF2PlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"		"short"   	// user ID who died				
	// "attacker"	"short"	 	// user ID who killed
	// "weapon"	"string" 		// weapon name killer used 
	// "weaponid"	"short"		// ID of weapon killed used
	// "damagebits"	"long"		// bits of type of damage
	// "customkill"	"short"		// type of custom kill
	// "assister"	"short"		// user ID of assister
	// "weapon_logclassname"	"string" 	// weapon name that should be printed on the log
	// "stun_flags"	"short"		// victim's stun flags at the moment of death
	// "death_flags"	"short" //death flags.

	new death_flags = GetEventInt(event, "death_flags");
	if ((death_flags & TF_DEATHFLAG_DEADRINGER) == TF_DEATHFLAG_DEADRINGER) {
		return;
	}

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (victim > 0) && (attacker <= MaxClients)) {

		tf2_players[victim][jump_status] = TF2_JUMP_NONE;
		tf2_players[victim][carry_object] = false;

		new custom_kill = GetEventInt(event, "customkill");
		if (custom_kill > 0) {
			new victim_team_index = GetClientTeam(victim);
			new player_team_index = GetClientTeam(attacker);
				
			if (victim_team_index == player_team_index) {
				if (custom_kill == TF_CUSTOM_SUICIDE) {
					log_player_event(attacker, "triggered", "force_suicide");
				}
			} else {
				if (custom_kill == TF_CUSTOM_HEADSHOT) {
					log_player_event(attacker, "triggered", "headshot");
				} else if (custom_kill == TF_CUSTOM_BACKSTAB) {
					log_player_player_event(attacker, victim, "triggered", "backstab");
				}
			}
		}

		if (attacker != victim) {
			switch(tf2_players[attacker][jump_status]) {
				case 2:
					log_player_event(attacker, "triggered", "rocket_jump_kill");
				case 3:
					log_player_event(attacker, "triggered", "sticky_jump_kill");
			}

			new bits = GetEventInt(event, "damagebits");
			if ((bits & DMG_ACID) && (attacker > 0) && (custom_kill != TF_CUSTOM_HEADSHOT)) {
				log_player_event(attacker, "triggered", "crit_kill");
			} else if (bits & DMG_DROWN) {
				log_player_event(attacker, "triggered", "drowned");
			}
			if ((death_flags & TF_DEATHFLAG_FIRSTBLOOD) == TF_DEATHFLAG_FIRSTBLOOD) {
				log_player_event(attacker, "triggered", "first_blood");
			}
			if ((custom_kill == TF_CUSTOM_HEADSHOT) && (victim <= MaxClients) && (IsClientInGame(victim)) && ((GetEntityFlags(victim) & (FL_ONGROUND | FL_INWATER)) == 0)) {
				log_player_event(attacker, "triggered", "airshot_headshot");
			}
		}

		decl String: weapon_log_name[64];
		GetEventString(event, "weapon_logclassname", weapon_log_name, 64);
		new weapon_index = get_tf2_weapon_index(weapon_log_name, attacker);
		if (weapon_index != -1) {
			player_weapons[attacker][weapon_index][wkills]++;
			if (custom_kill == TF_CUSTOM_HEADSHOT) {
				player_weapons[attacker][weapon_index][wheadshots]++;
			}
			player_weapons[victim][weapon_index][wdeaths]++;
			if (GetClientTeam(victim) == GetClientTeam(attacker)) {
				player_weapons[attacker][weapon_index][wteamkills]++;
			}
		}
		dump_player_data(victim);
		gameme_players[victim][palive] = 0;
	}
}


public Event_TF2PlayerTeleported(Handle: event, const String: name[], bool:dontBroadcast)
{
	//	"userid"        "short"         // userid of the player
	//	"builderid"     "short"         // userid of the player who built the teleporter

	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new builder = GetClientOfUserId(GetEventInt(event, "builderid"));
	if (((player > 0) && (builder > 0)) && (player != builder)) {
		log_player_player_event(builder, player, "triggered", "player_teleported", 1);
	}
}


public OnGameFrame()
{
	switch (gameme_plugin[mod_id]) {
		case MOD_HL2MP: {
			new bow_entity;
			while (PopStackCell(hl2mp_data[boltchecks], bow_entity))	{
				if (!IsValidEntity(bow_entity)) {
					continue;
				}
				new owner = GetEntDataEnt2(bow_entity, hl2mp_data[crossbow_owner_offset]);
				if ((owner < 0) || (owner > MaxClients)) {
					continue;
				}
				player_weapons[owner][HL2MP_CROSSBOW][wshots]++;
			}
		}
		case MOD_TF2: {
			new entity;
			if ((gameme_plugin[sdkhook_available]) && (tf2_data[stun_ball_id] > -1)) {
				while (PopStackCell(tf2_data[stun_balls], entity)) {
					if (IsValidEntity(entity)) {
						new owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
						if ((owner > 0) && (owner <= MaxClients)) {
							player_weapons[owner][tf2_data[stun_ball_id]][wshots]++;
						}
					}
				}
			}

			while (PopStackCell(tf2_data[wearables], entity)) {
				if (IsValidEntity(entity)) {
					new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if ((owner > 0) && (owner <= MaxClients)) {

						new item_index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
						decl String: tmp_str[16];
						Format(tmp_str, 16, "%d", item_index);

						if (KvJumpToKey(tf2_data[items_kv], tmp_str)) {
							KvGetString(tf2_data[items_kv], "item_slot", tmp_str, 16);
							new slot;
							if (GetTrieValue(tf2_data[slots_trie], tmp_str, slot)) {
								if ((slot == 0) && (tf2_players[owner][player_class] == TFClass_DemoMan)) {
									slot++;
								}
								if (tf2_players[owner][player_loadout0][slot] != item_index) {
									tf2_players[owner][player_loadout0][slot] = item_index;
									tf2_players[owner][player_loadout_updated] = true;
								}
								tf2_players[owner][player_loadout1][slot] = entity;
							}
							KvGoBack(tf2_data[items_kv]);
						}
					}
				}
			}
	
			new client_count = GetClientCount();
			for (new i = 1; i <= client_count; i++) {
				if ((IsClientInGame(i)) && (GetEntData(i, tf2_data[carry_offset], 1))) {
					tf2_players[i][carry_object] = true;
				}
			}

		}
	
	}
}


public OnEntityCreated(entity, const String: classname[]) {
	switch (gameme_plugin[mod_id]) {
		case MOD_HL2MP: {
			if (strcmp(classname, "crossbow_bolt") == 0) {
				PushStackCell(hl2mp_data[boltchecks], entity);
			}
		}
		case MOD_TF2: {
			if(StrEqual(classname, "tf_projectile_stun_ball")) {
				PushStackCell(tf2_data[stun_balls], EntIndexToEntRef(entity));
			} else if(StrEqual(classname, "tf_wearable_item_demoshield") || StrEqual(classname, "tf_wearable_item")) {
				PushStackCell(tf2_data[wearables], EntIndexToEntRef(entity));
			}
		}
	}
}


public Action:OnTF2GameLog(const String: message[])
{
	if (tf2_data[block_next_logging]) {
		tf2_data[block_next_logging] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public OnLogLocationsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0) {
		if ((strcmp(newVal, "0") == 0) || (strcmp(newVal, "1") == 0)) {
			if (((strcmp(newVal, "1") == 0) && (strcmp(oldVal, "1") != 0)) ||
			   ((strcmp(newVal, "0") == 0) && (strcmp(oldVal, "0") != 0))) {

				if (gameme_plugin[enable_log_locations] != INVALID_HANDLE) {
					new enable_log_locations_cvar = GetConVarInt(gameme_plugin[enable_log_locations]);
					if (enable_log_locations_cvar == 1) {
						gameme_plugin[log_locations] = 1;
						LogToGame("gameME location logging activated");
					} else if (enable_log_locations_cvar == 0) {
						gameme_plugin[log_locations] = 0;
						LogToGame("gameME location logging deactivated");
					}
				} else {
					gameme_plugin[log_locations] = 0;
				}

			}
		}
	}
}


public OnDisplaySpectatorinfoChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0) {
		if ((strcmp(newVal, "0") == 0) || (strcmp(newVal, "1") == 0)) {
			if (((strcmp(newVal, "1") == 0) && (strcmp(oldVal, "1") != 0)) ||
			   ((strcmp(newVal, "0") == 0) && (strcmp(oldVal, "0") != 0))) {

				if (gameme_plugin[display_spectatorinfo] != INVALID_HANDLE) {
					new display_info = GetConVarInt(gameme_plugin[display_spectatorinfo]);
					if (display_info == 1) {
						gameme_plugin[display_spectator] = 1;
						LogToGame("gameME spectator displaying activated");
					} else if (display_info == 0) {
						gameme_plugin[display_spectator] = 0;
						for (new i = 0; (i <= MAXPLAYERS); i++) {
							if (gameme_players[i][pspectator][stimer] != INVALID_HANDLE) {
								KillTimer(gameme_players[i][pspectator][stimer]);
								gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
							}
						}
						LogToGame("gameME spectator displaying deactivated");
					}
				} else {
					gameme_plugin[display_spectator] = 0;
				}
			}
		}
	}
}


public OnDamageDisplayChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0) {
		if ((strcmp(newVal, "0") == 0) || (strcmp(newVal, "1") == 0) || (strcmp(newVal, "2") == 0)) {

			if (((strcmp(newVal, "2") == 0) && (strcmp(oldVal, "2") != 0)) ||
			    ((strcmp(newVal, "1") == 0) && (strcmp(oldVal, "1") != 0)) ||
			    ((strcmp(newVal, "0") == 0) && (strcmp(oldVal, "0") != 0))) {

				if (gameme_plugin[enable_damage_display] != INVALID_HANDLE) {
					new enable_damage_display_cvar = GetConVarInt(gameme_plugin[enable_damage_display]);
					if (enable_damage_display_cvar == 1) {
						gameme_plugin[damage_display] = 1;
						gameme_plugin[damage_display_type] = 1;
						LogToGame("gameME damage display activated [Mode: Menu]");
					} else if (enable_damage_display_cvar == 2) {
						gameme_plugin[damage_display] = 1;
						gameme_plugin[damage_display_type] = 2;
						LogToGame("gameME damage display activated [Mode: Chat]");
					} else if (enable_damage_display_cvar == 0) {
						gameme_plugin[damage_display] = 0;
						LogToGame("gameME damage display deactivated");
					}
				} else {
					gameme_plugin[damage_display] = 0;
				}

			}
		}
	}
}


public OngameMELiveChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0) {
		if ((strcmp(newVal, "0") == 0) || (strcmp(newVal, "1") == 0)) {

			if (((strcmp(newVal, "1") == 0) && (strcmp(oldVal, "1") != 0)) ||
			   ((strcmp(newVal, "0") == 0) && (strcmp(oldVal, "0") != 0))) {

				if (gameme_plugin[enable_gameme_live] != INVALID_HANDLE) {
					if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_CSGO)) {
						if ((strcmp(gameme_plugin[gameme_live_address_value], "") != 0) &&
		    				(strcmp(gameme_plugin[gameme_live_address_port], "") != 0)) {
							new enable_gameme_live_cvar = GetConVarInt(gameme_plugin[enable_gameme_live]);
							if (enable_gameme_live_cvar == 1) {
								gameme_plugin[live_active] = 1;
								start_gameme_live();
								LogToGame("gameME Live! activated");
							} else if (enable_gameme_live_cvar == 0) {
								gameme_plugin[live_active] = 0;
								if (gameme_plugin[live_socket] != INVALID_HANDLE) {
									CloseHandle(gameme_plugin[live_socket]);
								}
								LogToGame("gameME Live! disabled");
							}
						} else {
							if (strcmp(newVal, "1") == 0) {
								SetConVarInt(gameme_plugin[enable_gameme_live], 0);
							} else {
								LogToGame("gameME Live! cannot be activated, no gameME Live! address assigned");
							}
							gameme_plugin[live_active] = 0;
						}
					}
				}
			}
		}
	}
}


public OnLiveAddressChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{

	if (strcmp(newVal, "") != 0) {
		if (gameme_plugin[gameme_live_address] != INVALID_HANDLE) {
			decl String: gameme_live_cvar_value[32];
			GetConVarString(gameme_plugin[gameme_live_address], gameme_live_cvar_value, 32);
			if (strcmp(gameme_live_cvar_value, "") != 0) {
				decl String: SplitArray[2][16];
				new split_count = ExplodeString(gameme_live_cvar_value, ":", SplitArray, 2, 16);
				if (split_count == 2) {
					strcopy(gameme_plugin[gameme_live_address_value], 32, SplitArray[0]);
					gameme_plugin[gameme_live_address_port] = StringToInt(SplitArray[1]);
				}
			}
		}
	}
}


public OnTagsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (gameme_plugin[ignore_next_tag_change]){
		return;
	}
	
	new count = GetArraySize(gameme_plugin[custom_tags]);
	for (new i = 0; (i < count); i++) {
		decl String: tag[128];
		GetArrayString(gameme_plugin[custom_tags], i, tag, 128);
		AddPluginServerTag(tag);
	}
}


public OnProtectAddressChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{

	if (strcmp(newVal, "") != 0) {
		if (gameme_plugin[protect_address] != INVALID_HANDLE) {
			decl String: protect_address_cvar_value[32];
			GetConVarString(gameme_plugin[protect_address], protect_address_cvar_value, 32);
			if (strcmp(protect_address_cvar_value, "") != 0) {
				decl String: SplitArray[2][16];
				new split_count = ExplodeString(protect_address_cvar_value, ":", SplitArray, 2, 16);
				if (split_count == 2) {
					strcopy(gameme_plugin[protect_address_value], 32, SplitArray[0]);
					gameme_plugin[protect_address_port] = StringToInt(SplitArray[1]);
				}
			}

			decl String: log_command[192];
			Format(log_command, 192, "logaddress_add %s", newVal);
			ServerCommand(log_command);

			for (new i = 0; (i <= MAXPLAYERS); i++) {
				gameme_players[i][prole] = -1;
			}
		}
	}
}


public Action: ProtectLoggingChange(args)
{
	if (gameme_plugin[protect_address] != INVALID_HANDLE) {
		decl String: protect_address_cvar_value[192];
		GetConVarString(gameme_plugin[protect_address], protect_address_cvar_value, 192);
		if (args >= 1) {
			decl String: log_action[192];
			GetCmdArg(1, log_action, 192);
			if ((strcmp(log_action, "off") == 0) || (strcmp(log_action, "0") == 0)) {
				if (strcmp(protect_address_cvar_value, "") != 0) {
					LogToGame("gameME address protection active, logging reenabled!");
					ServerCommand("log 1");
				}
			} else if ((strcmp(log_action, "on") == 0) || (strcmp(log_action, "1") == 0)) {
				for (new i = 0; (i <= MAXPLAYERS); i++) {
					gameme_players[i][prole] = -1;
				}
			}
			
		}
	}
	return Plugin_Continue;
}


public Action: ProtectForwardingChange(args)
{
	if (gameme_plugin[protect_address] != INVALID_HANDLE) {
		decl String: protect_address_cvar_value[32];
		GetConVarString(gameme_plugin[protect_address], protect_address_cvar_value, 32);
		if (strcmp(protect_address_cvar_value, "") != 0) {
			if (args == 1) {
				decl String: log_action[192];
				GetCmdArg(1, log_action, 192);
				if (strcmp(log_action, protect_address_cvar_value) == 0) {
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address_cvar_value);
					LogToGame("gameME address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			} else if (args > 1) {
				new String: log_action[192];
				for (new i = 1; i <= args; i++) {
					decl String: temp_argument[192];
					GetCmdArg(i, temp_argument, 192);
					strcopy(log_action[strlen(log_action)], 192, temp_argument);
				}
				if (strcmp(log_action, protect_address_cvar_value) == 0) {
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address_cvar_value);
					LogToGame("gameME address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action: ProtectForwardingDelallChange(args)
{
	if (gameme_plugin[protect_address] != INVALID_HANDLE) {
		decl String: protect_address_cvar_value[32];
		GetConVarString(gameme_plugin[protect_address], protect_address_cvar_value, 32);
		if (strcmp(protect_address_cvar_value, "") != 0) {
			decl String: log_command[192];
			Format(log_command, 192, "logaddress_add %s", protect_address_cvar_value);
			LogToGame("gameME address protection active, logaddress readded!");
			ServerCommand(log_command);
		}
	}
	return Plugin_Continue;
}


public OnBlockChatCommandsValuesChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "clear") == 0) {
		ClearTrie(gameme_plugin[blocked_commands]);
		LogToGame("Server triggered \"%s\"", "blocked_commands_cleared");
	} else {
		if (strcmp(newVal, "") != 0) {
			decl String: BlockedCommands[32][64];
			new block_commands_count = ExplodeString(String:newVal, " ", BlockedCommands, 32, 64);
			for (new i = 0; (i < block_commands_count); i++) {
				SetTrieValue(gameme_plugin[blocked_commands], BlockedCommands[i], 1);
			}
		}
	}
}


public OnMessagePrefixChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(gameme_plugin[message_prefix_value], 32, newVal);
	color_gameme_entities(gameme_plugin[message_prefix_value]);
}


public Action: MessagePrefixClear(args)
{
	strcopy(gameme_plugin[message_prefix_value], 32, "");
}


public OnTeamPlayChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (gameme_plugin[mod_id] == MOD_HL2MP) {
		hl2mp_data[teamplay_enabled] = GetConVarBool(hl2mp_data[teamplay]);
	}
}


public OnTF2CriticalHitsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	tf2_data[critical_hits_enabled] = GetConVarBool(tf2_data[critical_hits]);
	if(!tf2_data[critical_hits_enabled]) {
		for(new i = 1; i <= MaxClients; i++) {
			dump_player_data(i);
		}
	}
}


public Action: TF2_CalcIsAttackCritical(attacker, weapon, String: weaponname[], &bool: result)
{
	if ((gameme_plugin[sdkhook_available]) && (attacker > 0) && (attacker <= MaxClients)) {
		new weapon_index = get_tf2_weapon_index(weaponname[TF2_WEAPON_PREFIX_LENGTH], attacker);
		if (weapon_index != -1) {
			player_weapons[attacker][weapon_index][wshots]++;
		}
	}
	return Plugin_Continue;
}


log_player_settings(client, String: verb[32], const String: settings_name[], const String: settings_value[])
{
	if (client > 0) {
		LogToGame("\"%L\" %s \"%s\" (value \"%s\")", client, verb, settings_name, settings_value); 
	} else {
		LogToGame("\"%s\" %s \"%s\" (value \"%s\")", "Server", verb, settings_name, settings_value); 
	}
}


log_player_event(client, String: verb[32], String: player_event[192], additional_player = 0, display_location = 0)
{
	if (client > 0) {
		if (display_location > 0) {
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);
			if ((additional_player > 0) && (client != additional_player)) {
				LogToGame("\"%L\" %s \"%s\" (position \"%d %d %d\") (player \"%L\")", client, verb, player_event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), additional_player); 
			} else {
				LogToGame("\"%L\" %s \"%s\" (position \"%d %d %d\")", client, verb, player_event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
			}
		} else {
			if ((additional_player > 0) && (client != additional_player)) {
				LogToGame("\"%L\" %s \"%s\" (player \"%L\")", client, verb, player_event, additional_player); 
			} else {
				LogToGame("\"%L\" %s \"%s\"", client, verb, player_event); 
			}
		}
	}
}


log_player_player_event(client, victim, String: verb[32], String: player_event[192],  display_location = 0)
{
	if ((client > 0) && (victim > 0)) {
		if (display_location > 0) {
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);

			new Float: victim_origin[3];
			GetClientAbsOrigin(victim, victim_origin);
			
			LogToGame("\"%L\" %s \"%s\" against \"%L\" (position \"%d %d %d\") (victim_position \"%d %d %d\")", client, verb, player_event, victim, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), RoundFloat(victim_origin[0]), RoundFloat(victim_origin[1]), RoundFloat(victim_origin[2])); 
		} else {
			LogToGame("\"%L\" %s \"%s\" against \"%L\"", client, verb, player_event, victim); 
		}
	}
}


log_team_event(String: team_name[32], String: team_action[192],  String: team_objective[192] = "")
{
	if (strcmp(team_name, "") != 0) {
		if (strcmp(team_objective, "") != 0) {
			LogToGame("Team \"%s\" triggered \"%s\" (object \"%s\")", team_name, team_action, team_objective);
		} else {
			LogToGame("Team \"%s\" triggered \"%s\"", team_name, team_action);
		}
	}
}


log_player_location(String: event[32], client, additional_player = 0)
{
	if (client > 0) {
		new Float: player_origin[3];
		GetClientAbsOrigin(client, player_origin);
		if ((additional_player > 0) && (client != additional_player)) {
			new Float: additional_player_origin[3];
			GetClientAbsOrigin(additional_player, additional_player_origin);
			LogToGame("\"%L\" located on \"%s\" (position \"%d %d %d\") against \"%L\" (victim_position \"%d %d %d\")", client, event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), additional_player, RoundFloat(additional_player_origin[0]), RoundFloat(additional_player_origin[1]), RoundFloat(additional_player_origin[2])); 
		} else {
			LogToGame("\"%L\" located on \"%s\" (position \"%d %d %d\")", client, event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
	}
}


find_player_team_slot(team_index) 
{
	if (team_index > -1) {
		ColorSlotArray[team_index] = -1;
		for (new i = 1; i <= MaxClients; i++) {
			if ((IsClientInGame(i)) && (GetClientTeam(i) == team_index)) {
				ColorSlotArray[team_index] = i;
				break;
			}
		}
	}
}


stock validate_team_colors() 
{
	for (new i = 0; (i < sizeof(ColorSlotArray)); i++) {
		new color_client = ColorSlotArray[i];
		if (color_client > 0) {
			if ((IsClientInGame(color_client)) && (GetClientTeam(color_client) != color_client)) {
				find_player_team_slot(i);
			}
		} else {
			if ((i == 2) || (i == 3)) {
				find_player_team_slot(i);
			}
		}
	}
}


public native_color_gameme_entities(Handle: plugin, numParams)
{
	if (numParams < 1) {
		return 0;
	}

	new message_length;
	GetNativeStringLength(1, message_length);
	if (message_length <= 0) {
		return 0;
	}
 
	new String: message[message_length + 1];
	GetNativeString(1, message, message_length + 1);
   
	color_gameme_entities(message);
	SetNativeString(1, message, strlen(message) + 1);

	return 1;
}


color_gameme_entities(String: message[])
{
	ReplaceString(message, 192, "x08", "\x08");
	ReplaceString(message, 192, "x07", "\x07");
	ReplaceString(message, 192, "x05", "\x05");
	ReplaceString(message, 192, "x04", "\x04");
	ReplaceString(message, 192, "x03", "\x03");
	ReplaceString(message, 192, "x01", "\x01");
	ReplaceString(message, 192, "x||0", "x0");
}


public OnClientDisconnect(client)
{
	if (client > 0) {
		if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_DODS) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII) || (gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_ZPS)) {
			dump_player_data(client);
			reset_player_data(client);
		}
		if (IsClientInGame(client)) {
			if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
				new team_index = GetClientTeam(client);
				if (client == ColorSlotArray[team_index]) {
					ColorSlotArray[team_index] = -1;
				}
			}
		}
		
		if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS)) {
			if (gameme_players[client][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[client][pspectator][stimer]);
				gameme_players[client][pspectator][stimer] = INVALID_HANDLE;
			}
			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[j][client][supdated] = 1;
				strcopy(player_messages[j][client][smessage], 255, "");
			}
		}

	}
}


stock get_team_index(String: team_name[])
{
	new loop_break = 0;
	new index = 0;
	while ((loop_break == 0) && (index < sizeof(team_list))) {
   	    if (strcmp(team_name, team_list[index], true) == 0) {
       		loop_break++;
        }
   	    index++;
	}
	if (loop_break == 0) {
		return -1;
	} else {
		return index - 1;
	}
}


public native_display_menu(Handle: plugin, numParams)
{
	if (numParams < 4) {
		return;
	}

	new client = GetNativeCell(1);
	new time = GetNativeCell(2);

	new message_length;
	GetNativeStringLength(3, message_length);
	if (message_length <= 0) {
		return;
	}
	new String: message[message_length + 1];
	GetNativeString(3, message, message_length + 1);

	new handler = GetNativeCell(4);
	display_menu(client, time, message, handler);

	return;
}


display_menu(player_index, time, String: full_message[], need_handler = 0)
{
	ReplaceString(full_message, 1024, "\\n", "\10");
	if (need_handler == 0) {
		InternalShowMenu(player_index, full_message, time);
	} else {
		InternalShowMenu(player_index, full_message, time, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), InternalMenuHandler);
	}
}


public InternalMenuHandler(Handle:menu, MenuAction: action, param1, param2)
{
	new client = param1;
	if (IsClientInGame(client)) {
		if (action == MenuAction_Select) {
			decl String: player_event[192];
			IntToString(param2, player_event, 192);
			log_player_event(client, "selected", player_event);
		} else if (action == MenuAction_Cancel) {
			new String: player_event[192] = "cancel";
			log_player_event(client, "selected", player_event);
		}
	}
}


get_param(index, argument_count) 
{
	decl String: param[128];
	if (index <= argument_count) {
		GetCmdArg(index, param, 128);
		return StringToInt(param);
	}
	return -1;
}


get_query_id()
{
	global_query_id++;
	if (global_query_id > 65535) {
		global_query_id = 1;
	}
	return global_query_id;
}


find_callback(query_id)
{
	new index = -1;
	new size = GetArraySize(QueryCallbackArray);
	
	for (new i = 0; i < size; i++) {
		decl data[callback_data];
		GetArrayArray(QueryCallbackArray, i, data, sizeof(data));
		if ((data[callback_data_id] == query_id) && (data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
			index = i;
			break;
		}
	}
	return index;
}


public native_query_gameme_stats(Handle: plugin, numParams)
{
	if (numParams < 4) {
		return;
	}
	decl String: cb_type[255];
	GetNativeString(1, cb_type, 255);
	new cb_client = GetNativeCell(2);
	new Function: cb_function = GetNativeCell(3);
	new cb_payload = GetNativeCell(4);
	
	new cb_limit = 1;
	if (numParams >= 5) {
		cb_limit = GetNativeCell(5);
	}
	
	if (cb_client < 1) {
		new queryid = get_query_id();

		decl data[callback_data];
		data[callback_data_id] = queryid;
		data[callback_data_time] = GetGameTime();
		data[callback_data_client] = cb_client;
		data[callback_data_plugin] = plugin;
		data[callback_data_function] = cb_function;
		data[callback_data_payload] = cb_payload;
		data[callback_data_limit] = cb_limit;
		if (QueryCallbackArray != INVALID_HANDLE) {
			PushArrayArray(QueryCallbackArray, data);
		}
			
		new String: query_payload[32];
		IntToString(queryid, query_payload, 32);
		log_player_settings(cb_client, "requested", cb_type, query_payload);
	} else {
		if (IsClientInGame(cb_client)) {
			new userid = GetClientUserId(cb_client);
			if (userid > 0) {
				new queryid = get_query_id();

				decl data[callback_data];
				data[callback_data_id] = queryid;
				data[callback_data_time] = GetGameTime();
				data[callback_data_client] = cb_client;
				data[callback_data_plugin] = plugin;
				data[callback_data_function] = cb_function;
				data[callback_data_payload] = cb_payload;
				data[callback_data_limit] = cb_limit;

				if (QueryCallbackArray != INVALID_HANDLE) {
					PushArrayArray(QueryCallbackArray, data);
			
					new String: query_payload[32];
					IntToString(queryid, query_payload, 32);
					log_player_settings(cb_client, "requested", cb_type, query_payload);
				}
			}
		}
	}
}


public Action: gameme_raw_message(args)
{

	if (args < 1) {
		PrintToServer("Usage: gameme_raw_message <type><array> - retrieve internal gameME Stats data");
		return Plugin_Handled;
	}
	
	new argument_count = GetCmdArgs();
	new type = get_param(1, argument_count);
	switch (type) {

		case RAW_MESSAGE_CALLBACK_PLAYER, RAW_MESSAGE_RANK, RAW_MESSAGE_PLACE, RAW_MESSAGE_KDEATH, RAW_MESSAGE_SESSION_DATA: {
			if (argument_count >= 48) {
				new query_id = get_param(2, argument_count);		
				new userid = get_param(3, argument_count);		
				new client = GetClientOfUserId(userid);		
				if (client > 0) {

					new Handle: pack = CreateDataPack();

					// total values
					WritePackCell(pack, get_param(4, argument_count)); // rank
					WritePackCell(pack, get_param(5, argument_count)); // players
					WritePackCell(pack, get_param(6, argument_count)); // skill
					WritePackCell(pack, get_param(7, argument_count)); // kills
					WritePackCell(pack, get_param(8, argument_count)); // deaths

					decl String: kpd_param[16];
					GetCmdArg(9, kpd_param, 16);					
					WritePackFloat(pack, StringToFloat(kpd_param)); // kpd

					WritePackCell(pack, get_param(10, argument_count)); // suicides
					WritePackCell(pack, get_param(11, argument_count)); // headshots

					decl String: hpk_param[16];
					GetCmdArg(12, hpk_param, 16);					
					WritePackFloat(pack, StringToFloat(hpk_param)); // hpk

					decl String: acc_param[16];
					GetCmdArg(13, acc_param, 16);					
					WritePackFloat(pack, StringToFloat(acc_param)); // accuracy

					WritePackCell(pack, get_param(14, argument_count)); // connection_time
					WritePackCell(pack, get_param(15, argument_count)); // kill_assists
					WritePackCell(pack, get_param(16, argument_count)); // kills_assisted
					WritePackCell(pack, get_param(17, argument_count)); // points_healed
					WritePackCell(pack, get_param(18, argument_count)); // flags_captured
					WritePackCell(pack, get_param(19, argument_count)); // custom_wins
					WritePackCell(pack, get_param(20, argument_count)); // kill_streak
					WritePackCell(pack, get_param(21, argument_count)); // death_streak

					// session values
					WritePackCell(pack, get_param(22, argument_count)); // session_pos_change
					WritePackCell(pack, get_param(23, argument_count)); // session_skill_change
					WritePackCell(pack, get_param(24, argument_count)); // session_kills
					WritePackCell(pack, get_param(25, argument_count)); // session_deaths

					decl String: session_kpd_param[16];
					GetCmdArg(26, session_kpd_param, 16);					
					WritePackFloat(pack, StringToFloat(session_kpd_param)); // session_kpd

					WritePackCell(pack, get_param(27, argument_count)); // session_suicides
					WritePackCell(pack, get_param(28, argument_count)); // session_headshots

					decl String: session_hpk_param[16];
					GetCmdArg(29, session_hpk_param, 16);					
					WritePackFloat(pack, StringToFloat(hpk_param)); // session_hpk

					decl String: session_acc_param[16];
					GetCmdArg(30, session_acc_param, 16);					
					WritePackFloat(pack, StringToFloat(session_acc_param)); // session_accuracy

					WritePackCell(pack, get_param(31, argument_count)); // session_time
					WritePackCell(pack, get_param(32, argument_count)); // session_kill_assists
					WritePackCell(pack, get_param(33, argument_count)); // session_kills_assisted
					WritePackCell(pack, get_param(34, argument_count)); // session_points_healed
					WritePackCell(pack, get_param(35, argument_count)); // session_flags_captured
					WritePackCell(pack, get_param(36, argument_count)); // session_custom_wins
					WritePackCell(pack, get_param(37, argument_count)); // session_kill_streak
					WritePackCell(pack, get_param(38, argument_count)); // session_death_streak

					decl String: session_fav_weapon[32];
					GetCmdArg(39, session_fav_weapon, 32);					
					if (StrEqual(session_fav_weapon, "-")) {
						session_fav_weapon = "No Fav Weapon";
					}
					WritePackString(pack, session_fav_weapon); // fav weapons

					// global values
					WritePackCell(pack, get_param(40, argument_count)); // global_rank
					WritePackCell(pack, get_param(41, argument_count)); // global_players
					WritePackCell(pack, get_param(42, argument_count)); // global_kills
					WritePackCell(pack, get_param(43, argument_count)); // global_deaths

					decl String: global_kpd_param[16];
					GetCmdArg(44, global_kpd_param, 16);					
					WritePackFloat(pack, StringToFloat(global_kpd_param)); // global_kpd

					WritePackCell(pack, get_param(45, argument_count)); // global_headshots

					decl String: global_hpk_param[16];
					GetCmdArg(46, global_hpk_param, 16);					
					WritePackFloat(pack, StringToFloat(global_hpk_param)); // global_hpk

					// country
					decl String: country_code[16];
					GetCmdArg(47, country_code, 16);					
					WritePackString(pack, country_code); // player country
					
					
					decl Action: result;
					if (type == RAW_MESSAGE_CALLBACK_PLAYER) {
						if (query_id > 0) {
							new cb_array_index = find_callback(query_id);
							if (cb_array_index >= 0) {
								decl data[callback_data];
								GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
								if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
									Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
									Call_PushCell(RAW_MESSAGE_CALLBACK_PLAYER);
									
									Call_PushCell(data[callback_data_payload]);
									Call_PushCell(client);

									Call_PushCellRef(pack);
									Call_Finish(_:result);
									
									if (data[callback_data_limit] == 1) {
										RemoveFromArray(QueryCallbackArray, cb_array_index); 
									}
								}
							}
						}
					} else {
						switch (type) {
							case RAW_MESSAGE_RANK: {
								Call_StartForward(gameMEStatsRankForward);
								Call_PushCell(RAW_MESSAGE_RANK);
							}
							case RAW_MESSAGE_PLACE: {
								Call_StartForward(gameMEStatsPublicCommandForward);
								Call_PushCell(RAW_MESSAGE_PLACE);
							}
							case RAW_MESSAGE_KDEATH: {
								Call_StartForward(gameMEStatsPublicCommandForward);
								Call_PushCell(RAW_MESSAGE_KDEATH);
							}
							case RAW_MESSAGE_SESSION_DATA: {
								Call_StartForward(gameMEStatsPublicCommandForward);
								Call_PushCell(RAW_MESSAGE_SESSION_DATA);
							}
						}
						Call_PushCell(client);
						Call_PushString(gameme_plugin[message_prefix_value]);

						Call_PushCellRef(pack);
						Call_Finish(_: result);
					}

					CloseHandle(pack);
				}
				
			}
		}
		case RAW_MESSAGE_CALLBACK_TOP10, RAW_MESSAGE_TOP10: {
			if (argument_count >= 4) {
				new query_id = get_param(2, argument_count);		
				new userid = get_param(3, argument_count);	
				if (((userid > 0) && (type == RAW_MESSAGE_TOP10)) ||
   					((userid == -1) && (type == RAW_MESSAGE_CALLBACK_TOP10))) {

   					new client = GetClientOfUserId(userid);		
   					if ((client < 1) && (type == RAW_MESSAGE_TOP10)) {
						return Plugin_Handled;
   					}

					new Handle: pack = CreateDataPack();
					if (argument_count == 4) {
						WritePackCell(pack, -1); // total_players
					} else {
						new count = 0;
						for (new i = 4; (i <= argument_count); i++) {
							if (((i + 3) <= argument_count)) {
								count++;
								i = i + 3;
							}
						}
						WritePackCell(pack, count); // total_players

						new rank = 0;
						for (new i = 4; (i <= argument_count); i++) {
							if (((i + 3) <= argument_count)) {
								rank++;

								WritePackCell(pack, rank); // rank
								WritePackCell(pack, get_param(i, argument_count)); // skill

								decl String: name[64];
								GetCmdArg((i + 1), name, 64);
								WritePackString(pack, name); // name

								decl String: kpd_param[16];
								GetCmdArg((i + 2), kpd_param, 16);					
								WritePackFloat(pack, StringToFloat(kpd_param)); // kpd

								decl String: hpk_param[16];
								GetCmdArg((i + 3), hpk_param, 16);					
								WritePackFloat(pack, StringToFloat(hpk_param)); // hpk
								
								i = i + 3;
							}
						}
					}

					decl Action: result;
					if (type == RAW_MESSAGE_CALLBACK_TOP10) {
						if (query_id > 0) {
							new cb_array_index = find_callback(query_id);
							if (cb_array_index >= 0) {
								decl data[callback_data];
								GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
								if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
									Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
									Call_PushCell(RAW_MESSAGE_CALLBACK_TOP10);
									Call_PushCell(data[callback_data_payload]);
									Call_PushCellRef(pack);
									Call_Finish(_:result);
									
									if (data[callback_data_limit] == 1) {
										RemoveFromArray(QueryCallbackArray, cb_array_index); 
									}
								}
							}
						}
					} else {

						Call_StartForward(gameMEStatsTop10Forward);
						Call_PushCell(RAW_MESSAGE_TOP10);
						Call_PushCell(client);
						Call_PushString(gameme_plugin[message_prefix_value]);
						Call_PushCellRef(pack);
						Call_Finish(_:result);

					}

					CloseHandle(pack);
				}
			}
		}
		case RAW_MESSAGE_CALLBACK_NEXT, RAW_MESSAGE_NEXT: {
			if (argument_count >= 4) {
				new query_id = get_param(2, argument_count);		
				new userid = get_param(3, argument_count);	
				new client = GetClientOfUserId(userid);		
				if (client > 0) {

					new Handle: pack = CreateDataPack();
					
					if (argument_count == 4) {
						WritePackCell(pack, -1); // total_players
					} else {
						new count = 0;
						for (new i = 4; (i <= argument_count); i++) {
							if (((i + 4) <= argument_count)) {
								count++;
								i = i + 4;
							}
						}
						WritePackCell(pack, count); // total_players

						for (new i = 4; (i <= argument_count); i++) {
							if (((i + 4) <= argument_count)) {
								
								WritePackCell(pack, get_param(i, argument_count)); // rank
								WritePackCell(pack, get_param((i + 1), argument_count)); // skill

								decl String: name[64];
								GetCmdArg((i + 2), name, 64);
								WritePackString(pack, name); // name

								decl String: kpd_param[16];
								GetCmdArg((i + 3), kpd_param, 16);					
								WritePackFloat(pack, StringToFloat(kpd_param)); // kpd

								decl String: hpk_param[16];
								GetCmdArg((i + 4), hpk_param, 16);					
								WritePackFloat(pack, StringToFloat(hpk_param)); // hpk

								i = i + 4;
							}
						}
					}

					decl Action: result;
					if (type == RAW_MESSAGE_CALLBACK_NEXT) {
						if (query_id > 0) {
							new cb_array_index = find_callback(query_id);
							if (cb_array_index >= 0) {
								decl data[callback_data];
								GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
								if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
									Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
									Call_PushCell(RAW_MESSAGE_CALLBACK_NEXT);
									Call_PushCell(data[callback_data_payload]);
									Call_PushCell(client);
									Call_PushCellRef(pack);
									Call_Finish(_:result);
									
									if (data[callback_data_limit] == 1) {
										RemoveFromArray(QueryCallbackArray, cb_array_index); 
									}
								}
							}
						}
					} else {

						Call_StartForward(gameMEStatsNextForward);
						Call_PushCell(RAW_MESSAGE_NEXT);
						Call_PushCell(client);
						Call_PushString(gameme_plugin[message_prefix_value]);
						Call_PushCellRef(pack);
						Call_Finish(_:result);

					}
					CloseHandle(pack);
				}
			}
		}
		case RAW_MESSAGE_CALLBACK_INT_CLOSE: {
			if (argument_count >= 2) {
				new query_id = get_param(2, argument_count);
				new cb_array_index = find_callback(query_id);
				if (cb_array_index >= 0) {
					RemoveFromArray(QueryCallbackArray, cb_array_index); 
				}
			}
		}
		case RAW_MESSAGE_CALLBACK_INT_SPECTATOR: {
			if (argument_count >= 5) {
				new query_id = get_param(2, argument_count);		

				new caller[MAXPLAYERS + 1] = {-1, ...};
				decl String: caller_id[512];
				GetCmdArg(3, caller_id, 512);
				if (StrContains(caller_id, ",") > -1) {
					decl String: CallerRecipients[MaxClients][16];
					new recipient_count = ExplodeString(caller_id, ",", CallerRecipients, MaxClients, 16);
					for (new i = 0; (i < recipient_count); i++) {
						caller[i] = GetClientOfUserId(StringToInt(CallerRecipients[i]));
					}
				} else {
					caller[0] = GetClientOfUserId(StringToInt(caller_id));
				}

				new target[MAXPLAYERS + 1] = {-1, ...};
				decl String: target_id[512];
				GetCmdArg(4, target_id, 512);
				if (StrContains(target_id, ",") > -1) {
					decl String: TargetRecipients[MaxClients][16];
					new recipient_count = ExplodeString(target_id, ",", TargetRecipients, MaxClients, 16);
					for (new i = 0; (i < recipient_count); i++) {
						target[i] = GetClientOfUserId(StringToInt(TargetRecipients[i]));
					}
				} else {
					target[0] = GetClientOfUserId(StringToInt(target_id));
				}


				if ((caller[0] > -1) && (target[0] > -1) && (query_id > 0)) {
					decl String: message[1024];
					GetCmdArg(5, message, 1024);	
					
					new cb_array_index = find_callback(query_id);
					if (cb_array_index >= 0) {
						decl data[callback_data];
						GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
						if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
							decl Action: result;
							Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
							Call_PushCell(RAW_MESSAGE_CALLBACK_INT_SPECTATOR);
							Call_PushCell(data[callback_data_payload]);
							Call_PushArray(caller, MAXPLAYERS + 1);
							Call_PushArray(target, MAXPLAYERS + 1);
							Call_PushString(gameme_plugin[message_prefix_value]);
							Call_PushString(message);
							Call_Finish(_:result);

							if (data[callback_data_limit] == 1) {
								RemoveFromArray(QueryCallbackArray, cb_array_index); 
							}
						}
					}

				}
			}
		}

	}

	return Plugin_Handled;
}


public Action: gameme_psay(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_psay <userid><colored><message> - sends private message");
		return Plugin_Handled;
	}

	decl String: client_id[192];
	GetCmdArg(1, client_id, 192);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(gameme_plugin[message_recipients], StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(gameme_plugin[message_recipients], StringToInt(client_id));
	}

	decl String: colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new is_colored = 0;
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0) {
		is_colored = 1;
		ignore_param = 1;
	} else if (strcmp(colored_param, "2") == 0) {
		is_colored = 2;
		ignore_param = 1;
	} else if (strcmp(colored_param, "3") == 0) {
		is_colored = 3;
		ignore_param = 1;
	} else if (strcmp(colored_param, "0") == 0) {
		ignore_param = 1;
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(client_id) + 3;
	if (ignore_param == 1) {
 		copy_start_length += strlen(colored_param) + 1;
 	}
	copy_start_length += 1;

	new String: client_message[192];
	strcopy(client_message, 192, argument_string[copy_start_length]);
	while ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] == 34)) {
		client_message[strlen(client_message)-1] = 0;
	}
	
	if (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
		new color_index = -1;
		if ((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_DODS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {

			if (is_colored > 1) {
				validate_team_colors();
				if (is_colored == 2) {
					if (ColorSlotArray[2] > -1) {
						color_index = ColorSlotArray[2];
					}
				} else if (is_colored == 3) {
					if (ColorSlotArray[3] > -1) {
						color_index = ColorSlotArray[3];
					}
				}
				color_gameme_entities(client_message);
			} else if (is_colored == 1) {
				color_gameme_entities(client_message);
			}
				
			new bool: setupColorForRecipients = false;
			if (color_index == -1) {
				setupColorForRecipients = true;
			}

			while (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
				new recipient_client = -1;
				PopStackCell(gameme_plugin[message_recipients], recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {
					if (setupColorForRecipients == true) {
						color_index = player_index;
					}
					
					if (gameme_plugin[mod_id] == MOD_DODS) {
						PrintToChat(player_index, client_message);
					} else { 
						new Handle: message_handle = StartMessageOne("SayText2", player_index);
						if (message_handle != INVALID_HANDLE) {
							if (gameme_plugin[protobuf] == 1) {
								PbSetInt(message_handle, "ent_idx", color_index);
								PbSetBool(message_handle, "chat", false);
								PbSetString(message_handle, "msg_name", client_message);
								PbAddString(message_handle, "params", "");
								PbAddString(message_handle, "params", "");
								PbAddString(message_handle, "params", "");
								PbAddString(message_handle, "params", "");							
							} else {					
								BfWriteByte(message_handle, color_index); 
								BfWriteByte(message_handle, 0); 
								BfWriteString(message_handle, client_message);
							}
							EndMessage();
						}
					}
				}
			}
		} else {
			while (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
				new recipient_client = -1;
				PopStackCell(gameme_plugin[message_recipients], recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {
					PrintToChat(player_index, client_message);
				}
			}
		}
	}

	return Plugin_Handled;
}


public Action: gameme_csay(args)
{
	if (args < 1) {
		PrintToServer("Usage: gameme_csay <message> - display center message");
		return Plugin_Handled;
	}

	new String: display_message[192];
	GetCmdArg(1, display_message, 192);

	if (strcmp(display_message, "") != 0) {
		PrintCenterTextAll(display_message);
	}
		
	return Plugin_Handled;
}


public Action: gameme_msay(args)
{
	if (args < 3) {
		PrintToServer("Usage: gameme_msay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	if (gameme_plugin[mod_id] == MOD_HL2MP) {
		return Plugin_Handled;
	}
	
	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	decl String: handler_param[32];
	GetCmdArg(3, handler_param, 32);

	new need_handler = 0;
	if ((strcmp(handler_param, "1") == 0) || (strcmp(handler_param, "0") == 0)) {
		need_handler = 1;
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(display_time) + 3 + strlen(client_id) + 3;
	if (need_handler == 1) {
		copy_start_length += 2;
	}
	copy_start_length += 1;

	new String: client_message[1024];
	strcopy(client_message, 1024, argument_string[copy_start_length]);
	while ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] == 34)) {
		client_message[strlen(client_message)-1] = 0;
	}

	new time = StringToInt(display_time);
	if (time <= 0) {
		time = 10;
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {
			if (strcmp(client_message, "") != 0) {
				display_menu(player_index, time, client_message, need_handler);			
			}
		}	
	}		
		
	return Plugin_Handled;
}


public Action: gameme_tsay(args)
{
	if (args < 3) {
		PrintToServer("Usage: gameme_tsay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(display_time) + 3 + strlen(client_id) + 3;
	copy_start_length += 1;

	new String: client_message[192];
	strcopy(client_message, 192, argument_string[copy_start_length]);
	while ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] == 34)) {
		client_message[strlen(client_message)-1] = 0;
	}

	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_message, "") != 0)) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {
			new Handle:values = CreateKeyValues("msg");
			KvSetString(values, "title", client_message);
			KvSetNum(values, "level", 1); 
			KvSetString(values, "time", display_time); 
			CreateDialog(player_index, values, DialogType_Msg);
			CloseHandle(values);
		}	
	}		
		
	return Plugin_Handled;
}


public Action: gameme_hint(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_hint <userid><message> - send hint message");
		return Plugin_Handled;
	}

	if (gameme_plugin[mod_id] == MOD_HL2MP) {
		return Plugin_Handled;
	}

	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(gameme_plugin[message_recipients], StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(gameme_plugin[message_recipients], StringToInt(client_id));
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(client_id) + 3;
	copy_start_length++;
	
	new String: client_message[192];
	strcopy(client_message, 192, argument_string[copy_start_length]);
	while ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] == 34)) {
		client_message[strlen(client_message)-1] = 0;
	}

	if (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
		if (strcmp(client_message, "") != 0) {
			while (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
				new recipient_client = -1;
				PopStackCell(gameme_plugin[message_recipients], recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {
					PrintHintText(player_index, client_message);
				}
			}
		}
	}		
			
	return Plugin_Handled;
}


public Action: gameme_khint(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_khint <userid><message> - send khint message");
		return Plugin_Handled;
	}

	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(gameme_plugin[message_recipients], StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(gameme_plugin[message_recipients], StringToInt(client_id));
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(client_id) + 3;
	copy_start_length++;
	
	new String: client_message[255];
	strcopy(client_message, 255, argument_string[copy_start_length]);
	while ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] == 34)) {
		client_message[strlen(client_message)-1] = 0;
	}
	ReplaceString(client_message, 255, "\\n", "\10");

	if (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
		if (strcmp(client_message, "") != 0) {
			while (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
				new recipient_client = -1;
				PopStackCell(gameme_plugin[message_recipients], recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {
					new Handle: message_handle = StartMessageOne("KeyHintText", player_index);
					if (message_handle != INVALID_HANDLE) {
						if (gameme_plugin[protobuf] == 1) {
							PbAddString(message_handle, "hints", client_message);
						} else {
							BfWriteByte(message_handle, 1);
							BfWriteString(message_handle, client_message);
						}
						EndMessage();
					}
				}
			}
		}
	}		
			
	return Plugin_Handled;
}


public Action: gameme_browse(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_browse <userid><url> - open client ingame browser");
		return Plugin_Handled;
	}

	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(gameme_plugin[message_recipients], StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(gameme_plugin[message_recipients], StringToInt(client_id));
	}

	new String: client_url[192];
	GetCmdArg(2, client_url, 192);

	if (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
		if (strcmp(client_url, "") != 0) {
			while (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
				new recipient_client = -1;
				PopStackCell(gameme_plugin[message_recipients], recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {

					if (gameme_plugin[protobuf] == 1) {
						new Handle: message_handle = StartMessageOne("VGUIMenu", player_index);
						if (message_handle != INVALID_HANDLE) {
							PbSetString(message_handle, "name", "info");
							PbSetBool(message_handle, "show", true);

							new Handle: subkey;
							
							subkey = PbAddMessage(message_handle, "subkeys");
							PbSetString(subkey, "name", "type");
							PbSetString(subkey, "str", "2"); // MOTDPANEL_TYPE_URL

							subkey = PbAddMessage(message_handle, "subkeys");
							PbSetString(subkey, "name", "title");
							PbSetString(subkey, "str", "gameME");

							subkey = PbAddMessage(message_handle, "subkeys");
							PbSetString(subkey, "name", "msg");
							PbSetString(subkey, "str", client_url);

							EndMessage();
						}
					} else {
						ShowMOTDPanel(player_index, "gameME", client_url, MOTDPANEL_TYPE_URL);
					}
				}
			}
		}
	}		
			
	return Plugin_Handled;
}


public Action: gameme_swap(args)
{
	if (args < 1) {
		PrintToServer("Usage: gameme_swap <userid> - swaps players to the opposite team (css only)");
		return Plugin_Handled;
	}

	if (gameme_plugin[mod_id] != MOD_CSS) {
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (IsClientInGame(player_index))) {
			swap_player(player_index);
		}
	}
	return Plugin_Handled;
}


public Action: gameme_redirect(args)
{
	if (args < 3) {
		PrintToServer("Usage: gameme_redirect <time><userid><address><reason> - asks player to be redirected to specified gameserver");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[512];
	GetCmdArg(2, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(gameme_plugin[message_recipients], StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(gameme_plugin[message_recipients], StringToInt(client_id));
	}

	new String: server_address[192];
	GetCmdArg(3, server_address, 192);

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(display_time) + 3 + strlen(client_id) + 3 + strlen(server_address) + 3;
	copy_start_length++;

	new String: redirect_reason[192];
	strcopy(redirect_reason, 192, argument_string[copy_start_length]);
	while ((strlen(redirect_reason) > 0) && (redirect_reason[strlen(redirect_reason)-1] == 34)) {
		redirect_reason[strlen(redirect_reason)-1] = 0;
	}

	if (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
		if (strcmp(server_address, "") != 0) {

			while (IsStackEmpty(gameme_plugin[message_recipients]) == false) {
				new recipient_client = -1;
				PopStackCell(gameme_plugin[message_recipients], recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientInGame(player_index))) {
					new Handle:top_values = CreateKeyValues("msg");
					KvSetString(top_values, "title", redirect_reason);
					KvSetNum(top_values, "level", 1); 
					KvSetString(top_values, "time", display_time); 
					CreateDialog(player_index, top_values, DialogType_Msg);
					CloseHandle(top_values);
			
					new Float: display_time_float;
					display_time_float = StringToFloat(display_time);
					DisplayAskConnectBox(player_index, display_time_float, server_address);
				}
			}
		}	
	}		
		
	return Plugin_Handled;
}


public Action: gameme_player_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_player_action <client><action> - trigger player action to be handled from gameME");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	decl String: player_action[192];
	GetCmdArg(2, player_action, 192);

	new client = StringToInt(client_id);
	if (client > 0) {
		log_player_event(client, "triggered", player_action);
	}

	return Plugin_Handled;
}


public Action: gameme_team_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_team_action <team_name><action>(objective) - trigger team action to be handled from gameME");
		return Plugin_Handled;
	}

	decl String: team_name[32];
	GetCmdArg(1, team_name, 32);

	decl String: team_action[192];
	GetCmdArg(2, team_action, 192);
	
	if (args > 2) {
		decl String: team_objective[192];
		GetCmdArg(3, team_objective, 192);
		log_team_event(team_name, team_action, team_objective);
	} else {
		log_team_event(team_name, team_action);
	}

	return Plugin_Handled;
}


public Action: gameme_world_action(args)
{
	if (args < 1) {
		PrintToServer("Usage: gameme_world_action <action> - trigger world action to be handled from gameME");
		return Plugin_Handled;
	}

	decl String: world_action[192];
	GetCmdArg(1, world_action, 192);

	LogToGame("World triggered \"%s\"", world_action); 

	return Plugin_Handled;
}


is_command_blocked(String: command[])
{
	new index;
	if(GetTrieValue(gameme_plugin[blocked_commands], command, index)) {
		return 1;
	}
	return 0;
}


public Action: gameme_block_commands(client, args)
{
	if (client) {
		if (client == 0) {
			return Plugin_Continue;
		}
		new block_chat_commands_enabled = GetConVarInt(gameme_plugin[block_chat_commands]);
		
		decl String: user_command[192];
		GetCmdArgString(user_command, 192);

		decl String: origin_command[192];
		new start_index = 0;
		new command_length = strlen(user_command);
		if (command_length > 0) {
			if (user_command[0] == 34)	{
				start_index = 1;
				if (user_command[command_length - 1] == 34)	{
					user_command[command_length - 1] = 0;
				}
			}
			strcopy(origin_command, 192, user_command[start_index]);
		}
		
		new String: command_type[32] = "say";
		if (gameme_plugin[mod_id] == MOD_INSMOD) {
			decl String: say_type[1];
			strcopy(say_type, 2, user_command[start_index]);
			if (strcmp(say_type, "1") == 0) {
				command_type = "say";
			} else if (strcmp(say_type, "2") == 0) {
				command_type = "say_team";
			}
			start_index += 4;
		}

		if (command_length > 0) {
			if (block_chat_commands_enabled > 0) {
				if (IsClientInGame(client)) {
					if (gameme_plugin[mod_id] == MOD_INSMOD) {
						log_player_event(client, command_type, user_command[start_index]);
					}

					if (is_command_blocked(user_command[start_index]) > 0) {
						if ((strcmp("gameme", user_command[start_index]) == 0) ||
							(strcmp("/gameme", user_command[start_index]) == 0) ||
							(strcmp("!gameme", user_command[start_index]) == 0) ||
							(strcmp("gameme_menu", user_command[start_index]) == 0) ||
							(strcmp("/gameme_menu", user_command[start_index]) == 0) ||
							(strcmp("!gameme_menu", user_command[start_index]) == 0)) {
							DisplayMenu(gameme_plugin[menu_main], client, MENU_TIME_FOREVER);
						}
						if (gameme_plugin[mod_id] != MOD_INSMOD) {
							log_player_event(client, command_type, origin_command);
						}
						return Plugin_Stop;
					} else {
						if ((strcmp("gameme", user_command[start_index]) == 0) ||
							(strcmp("/gameme", user_command[start_index]) == 0) ||
							(strcmp("!gameme", user_command[start_index]) == 0) ||
							(strcmp("gameme_menu", user_command[start_index]) == 0) ||
							(strcmp("/gameme_menu", user_command[start_index]) == 0) ||
							(strcmp("!gameme_menu", user_command[start_index]) == 0)) {
							DisplayMenu(gameme_plugin[menu_main], client, MENU_TIME_FOREVER);
						}
					}
				}
			} else {
				if (IsClientInGame(client)) {
					if ((strcmp("gameme", user_command[start_index]) == 0) ||
						(strcmp("/gameme", user_command[start_index]) == 0) ||
						(strcmp("!gameme", user_command[start_index]) == 0) ||
						(strcmp("gameme_menu", user_command[start_index]) == 0) ||
						(strcmp("/gameme_menu", user_command[start_index]) == 0) ||
						(strcmp("!gameme_menu", user_command[start_index]) == 0)) {
						DisplayMenu(gameme_plugin[menu_main], client, MENU_TIME_FOREVER);
					}
					
					if (gameme_plugin[mod_id] == MOD_INSMOD) {
						log_player_event(client, command_type, user_command[start_index]);
					}
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}


public Action: gameME_Event_PlyDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));

	if (attacker > 0) {
		new headshot = 0;
		headshot = GetEventBool(event, "headshot");

		if (((gameme_plugin[mod_id] == MOD_CSGO) || (gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_CSP)) && (victim > 0)) {
			if (headshot == 1) {
				new player_team_index = GetClientTeam(attacker);
				new victim_team_index = GetClientTeam(victim);
				if (victim_team_index != player_team_index) {
					log_player_event(attacker, "triggered", "headshot");
				}
			}
			if ((gameme_plugin[log_locations] == 1) && ((gameme_plugin[mod_id] != MOD_CSP))) {
				if (attacker != victim) {
					log_player_location("kill", attacker, victim);
				} else {
					log_player_location("suicide", attacker);
				}
			}
		}

		if ((gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
			if (headshot == 1) {
				log_player_event(attacker, "triggered", "headshot");
			}
			if (gameme_plugin[mod_id] == MOD_L4DII) {
				decl String: weapon[32];
				GetEventString(event, "weapon", weapon, 32);
				if (strncmp(weapon, "melee", 5) == 0) {
					new new_weapon_index = GetEntDataEnt2(attacker, l4dii_data[active_weapon_offset]);
					if (IsValidEdict(new_weapon_index)) {
						GetEdictClassname(new_weapon_index, weapon, 32);
						if (strncmp(weapon[7], "melee", 5) == 0) { 
							GetEntPropString(new_weapon_index, Prop_Data, "m_strMapSetScriptName", weapon, 32);
							SetEventString(event, "weapon", weapon);
						}
					}
				}
			}
		}
		
		if (gameme_plugin[mod_id] == MOD_HL2MP) {
			decl String: weapon[32];
			GetEventString(event, "weapon", weapon, 32);
			if (strcmp(weapon, "crossbow_bolt") == 0) {
				if (hl2mp_players[victim][nextbow_hitgroup] == HITGROUP_HEAD) {
					log_player_event(attacker, "triggered", "headshot");
				}
			} else {
				if (hl2mp_players[victim][next_hitgroup] == HITGROUP_HEAD) {
					log_player_event(attacker, "triggered", "headshot");
				}		
			}
		}

		if (gameme_plugin[mod_id] == MOD_ZPS) {
			if (zps_players[victim][next_hitgroup] == HITGROUP_HEAD) {
				log_player_event(attacker, "triggered", "headshot");
			}		
		}

		if (gameme_plugin[mod_id] == MOD_TF2) {
			new customkill = GetEventInt(event, "customkill");
			new weapon = GetEventInt(event, "weaponid");
			switch (customkill) {
				case TF_CUSTOM_BURNING_ARROW, TF_CUSTOM_FLYINGBURN: {
					decl String: log_weapon[64];
					GetEventString(event, "weapon_logclassname", log_weapon, 64);
					if (log_weapon[0] != 'd') {
						SetEventString(event, "weapon_logclassname", "tf_projectile_arrow_fire");
					}
				}
				case TF_CUSTOM_TAUNT_UBERSLICE: {
					if (weapon == TF_WEAPON_BONESAW) {
						SetEventString(event, "weapon_logclassname", "taunt_medic");
						SetEventString(event, "weapon", "taunt_medic");
					}
				}
				case TF_CUSTOM_DECAPITATION_BOSS: {
					log_player_event(attacker, "triggered", "killed_by_horseman");
				}
			}
		}

		if (gameme_plugin[log_locations] == 1) {
			if (((gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_DODS)) && (victim > 0)) {
				if (attacker != victim) {
					log_player_location("kill", attacker, victim);
				}
			}
		}

	}

	return Plugin_Continue;
}


public Action: gameME_Event_PlyTeamChange(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	if (userid > 0) {
		new player_index = GetClientOfUserId(userid);
		if (player_index > 0) {
			for (new i = 0; (i < sizeof(ColorSlotArray)); i++) {
				new color_client = ColorSlotArray[i];
				if (color_client > -1) {
					if (color_client == player_index) {
						ColorSlotArray[i] = -1;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action: gameME_Event_PlyBombDropped(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_plugin[log_locations] == 1) {
			log_player_location("Dropped_The_Bomb", player);
		}

		if (gameme_plugin[display_spectator] == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}

	return Plugin_Continue;
}


public Action: gameME_Event_PlyBombPickup(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_plugin[log_locations] == 1) {
			log_player_location("Got_The_Bomb", player);
		}
		if (gameme_plugin[display_spectator] == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}

	return Plugin_Continue;
}


public Action: gameME_Event_PlyBombPlanted(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_plugin[log_locations] == 1) {
			log_player_location("Planted_The_Bomb", player);
		}
		if (gameme_plugin[display_spectator] == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}

	return Plugin_Continue;
}


public Action: gameME_Event_PlyBombDefused(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_plugin[log_locations] == 1) {
			log_player_location("Defused_The_Bomb", player);
		}

		if (gameme_plugin[display_spectator] == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}
	return Plugin_Continue;
}


public Action: gameME_Event_PlyHostageKill(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_plugin[log_locations] == 1) {
			log_player_location("Killed_A_Hostage", player);
		}

		if (gameme_plugin[display_spectator] == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}
	return Plugin_Continue;
}


public Action: gameME_Event_PlyHostageResc(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_plugin[log_locations] == 1) {
			log_player_location("Rescued_A_Hostage", player);
		}

		if (gameme_plugin[display_spectator] == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}
	return Plugin_Continue;
}


swap_player(player_index)
{
	if (IsClientInGame(player_index)) {
		new player_team_index = GetClientTeam(player_index);
		decl String: player_team[32];
		player_team = team_list[player_team_index];			

		if (strcmp(player_team, "CT") == 0) {
			if (IsPlayerAlive(player_index)) {
				CS_SwitchTeam(player_index, CS_TEAM_T);
				CS_RespawnPlayer(player_index);
				new new_model = GetRandomInt(0, 3);
				SetEntityModel(player_index, css_ts_models[new_model]);
			} else {
				CS_SwitchTeam(player_index, CS_TEAM_T);
			}
		} else if (strcmp(player_team, "TERRORIST") == 0) {
			if (IsPlayerAlive(player_index)) {
				CS_SwitchTeam(player_index, CS_TEAM_CT);
				CS_RespawnPlayer(player_index);
				new new_model = GetRandomInt(0, 3);
				SetEntityModel(player_index, css_ct_models[new_model]);
				new weapon_entity = GetPlayerWeaponSlot(player_index, 4);
				if (weapon_entity > 0) {
					decl String: class_name[32];
					GetEdictClassname(weapon_entity, class_name, 32);
					if (strcmp(class_name, "weapon_c4") == 0) {
						RemovePlayerItem(player_index, weapon_entity);
					}
				}
			} else {
				CS_SwitchTeam(player_index, CS_TEAM_CT);
			}
		}
	}
}


public CreateGameMEMenuMain(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(gameMEMainCommandHandler, MenuAction_Display | MenuAction_DisplayItem  | MenuAction_Select | MenuAction_Cancel);

	if ((gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP)) {

		SetMenuTitle(MenuHandle, "gameME - Main Menu");

		AddMenuItem(MenuHandle, "IngameMenu_Menu1",  "Display Rank");
		AddMenuItem(MenuHandle, "IngameMenu_Menu2",  "Next Players");
		AddMenuItem(MenuHandle, "IngameMenu_Menu3",  "Top10 Players");
		AddMenuItem(MenuHandle, "IngameMenu_Menu4",  "Auto Ranking");
		AddMenuItem(MenuHandle, "IngameMenu_Menu5",  "Console Events");
		AddMenuItem(MenuHandle, "IngameMenu_Menu6",  "Toggle Ranking Display");
		AddMenuItem(MenuHandle, "IngameMenu_Menu16" ,"Reset Statistics");

	} else {

		SetMenuTitle(MenuHandle, "gameME - Main Menu");

		AddMenuItem(MenuHandle, "IngameMenu_Menu1",  "Display Rank");
		AddMenuItem(MenuHandle, "IngameMenu_Menu2",  "Next Players");
		AddMenuItem(MenuHandle, "IngameMenu_Menu3",  "Top10 Players");
		AddMenuItem(MenuHandle, "IngameMenu_Menu7",  "Clans Ranking");
		AddMenuItem(MenuHandle, "IngameMenu_Menu8",  "Server Status");
		AddMenuItem(MenuHandle, "IngameMenu_Menu9",  "Statsme");

		AddMenuItem(MenuHandle, "IngameMenu_Menu4",  "Auto Ranking");
		AddMenuItem(MenuHandle, "IngameMenu_Menu5",  "Console Events");
		AddMenuItem(MenuHandle, "IngameMenu_Menu10", "Weapon Usage");
		AddMenuItem(MenuHandle, "IngameMenu_Menu11", "Weapons Accuracy");
		AddMenuItem(MenuHandle, "IngameMenu_Menu12", "Weapons Targets");
		AddMenuItem(MenuHandle, "IngameMenu_Menu13", "Player Kills");

		AddMenuItem(MenuHandle, "IngameMenu_Menu6" , "Toggle Ranking Display");
		AddMenuItem(MenuHandle, "IngameMenu_Menu16" ,"Reset Statistics");
		AddMenuItem(MenuHandle, "IngameMenu_Menu14", "VAC Cheaterlist");
		AddMenuItem(MenuHandle, "IngameMenu_Menu15", "Display Help");
	}

	SetMenuPagination(MenuHandle, 8);
}


public CreateGameMEMenuAuto(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(gameMEAutoCommandHandler, MenuAction_Display | MenuAction_DisplayItem  | MenuAction_Select | MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "gameME - Auto-Ranking");

	AddMenuItem(MenuHandle, "AutoMenu_Menu1", "Enable on round-start");
	AddMenuItem(MenuHandle, "AutoMenu_Menu2", "Enable on round-end");
	AddMenuItem(MenuHandle, "AutoMenu_Menu3", "Enable on player death");
	AddMenuItem(MenuHandle, "AutoMenu_Menu4", "Disable");

	SetMenuPagination(MenuHandle, 8);
}


public CreateGameMEMenuEvents(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(gameMEEventsCommandHandler, MenuAction_Display | MenuAction_DisplayItem  | MenuAction_Select | MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "gameME - Console Events");

	AddMenuItem(MenuHandle, "ConsoleMenu_Menu1", "Enable Events");
	AddMenuItem(MenuHandle, "ConsoleMenu_Menu2", "Disable Events");
	AddMenuItem(MenuHandle, "ConsoleMenu_Menu3", "Enable Global Chat");
	AddMenuItem(MenuHandle, "ConsoleMenu_Menu4", "Disable Global Chat");

	SetMenuPagination(MenuHandle, 8);
}


make_player_command(client, String: player_command[192]) 
{
	if (client > 0) {
		log_player_event(client, "say", player_command);
	}
}


public gameMEMainCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_DisplayItem) {

		decl String: info[64];
		GetMenuItem(menu, param2, info, sizeof(info), _, "", 0);
		
		decl String: buffer[255];
		Format(buffer, sizeof(buffer), "%T", info, param1);

		return RedrawMenuItem(buffer);

	} else if (action == MenuAction_Display) {

		decl String: buffer[255];
		Format(buffer, sizeof(buffer), "%T", "IngameMenu_Caption", param1);
 
		new Handle: panel = Handle: param2;
		SetPanelTitle(panel, buffer);
		
	} else if (action == MenuAction_Select) {

		if (IsClientInGame(param1)) {
			if ((gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP)) {
				switch (param2) {
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						DisplayMenu(gameme_plugin[menu_auto], param1, MENU_TIME_FOREVER);
					case 4 : 
						DisplayMenu(gameme_plugin[menu_events], param1, MENU_TIME_FOREVER);
					case 5 : 
						make_player_command(param1, "/gameme_hideranking");
					case 6 : 
						make_player_command(param1, "/gameme_reset");
				}
			} else {
				switch (param2) {
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						make_player_command(param1, "/clans");
					case 4 : 
						make_player_command(param1, "/status");
					case 5 : 
						make_player_command(param1, "/statsme");
					case 6 : 
						DisplayMenu(gameme_plugin[menu_auto], param1, MENU_TIME_FOREVER);
					case 7 : 
						DisplayMenu(gameme_plugin[menu_events], param1, MENU_TIME_FOREVER);
					case 8 : 
						make_player_command(param1, "/weapons");
					case 9 : 
						make_player_command(param1, "/accuracy");
					case 10 : 
						make_player_command(param1, "/targets");
					case 11 : 
						make_player_command(param1, "/kills");
					case 12 : 
						make_player_command(param1, "/gameme_hideranking");
					case 13 : 
						make_player_command(param1, "/gameme_reset");
					case 14 : 
						make_player_command(param1, "/cheaters");
					case 15 : 
						make_player_command(param1, "/help");


				}
			}
		}
	}
	
	return 0;
}


public gameMEAutoCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_DisplayItem) {

		decl String: info[64];
		GetMenuItem(menu, param2, info, sizeof(info), _, "", 0);
		
		decl String: buffer[255];
		Format(buffer, sizeof(buffer), "%T", info, param1);

		return RedrawMenuItem(buffer);

	} else if (action == MenuAction_Display) {

		decl String: buffer[255];
		Format(buffer, sizeof(buffer), "%T", "IngameMenu_Caption", param1);
		
		new Handle: panel = Handle: param2;
		SetPanelTitle(panel, buffer);

	} else if (action == MenuAction_Select) {

		if (IsClientInGame(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/gameme_auto start rank");
				case 1 : 
					make_player_command(param1, "/gameme_auto end rank");
				case 2 : 
					make_player_command(param1, "/gameme_auto kill rank");
				case 3 : 
					make_player_command(param1, "/gameme_auto clear");
			}
		}
	}

	return 0;
}


public gameMEEventsCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_DisplayItem) {

		decl String: info[64];
		GetMenuItem(menu, param2, info, sizeof(info), _, "", 0);
		
		decl String: buffer[255];
		Format(buffer, sizeof(buffer), "%T", info, param1);
 
		return RedrawMenuItem(buffer);

	} else if (action == MenuAction_Display) {

		decl String: buffer[255];
		Format(buffer, sizeof(buffer), "%T", "IngameMenu_Caption", param1);
 
		new Handle: panel = Handle: param2;
		SetPanelTitle(panel, buffer);

	} else if (action == MenuAction_Select) {

		if (IsClientInGame(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/gameme_display 1");
				case 1 : 
					make_player_command(param1, "/gameme_display 0");
				case 2 : 
					make_player_command(param1, "/gameme_chat 1");
				case 3 : 
					make_player_command(param1, "/gameme_chat 0");
			}
		}
	}

	return 0;
}


//
//
// Third Party Addons
//
//


/*
 *
 * Advanced Logging for
 *   Left 4 Dead,
 *   Left 4 Dead 2,
 *   Team Fortress 2,
 *   Insurgency,
 *   Half-Life 2: Deathmatch
 * Copyright (C) 2011 Nicholas Hastings (psychonic)
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
*/


public Event_L4DRescueSurvivor(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "rescuer"));
	if (player > 0) {
		log_player_event(player, "triggered", "rescued_survivor");
	}
}


public Event_L4DHeal(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((player > 0) && (player != GetClientOfUserId(GetEventInt(event, "subject")))) {
		log_player_event(player, "triggered", "healed_teammate");
	}
}


public Event_L4DRevive(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		log_player_event(player, "triggered", "revived_teammate");
	}
}


public Event_L4DStartleWitch(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((player > 0) && ((gameme_plugin[mod_id] != MOD_L4DII) || (GetEventBool(event, "first")))) {
		log_player_event(player, "triggered", "startled_witch");
	}
}


public Event_L4DPounce(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (victim > 0) {
		log_player_player_event(player, victim, "triggered", "pounce");
	} else {
		log_player_event(player, "triggered", "pounce");
	}
}


public Event_L4DBoomered(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((player > 0) && ((gameme_plugin[mod_id] != MOD_L4DII) || (GetEventBool(event, "by_boomer")))) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "vomit");
		} else {
			log_player_event(player, "triggered", "vomit");
		}
	}
}


public Event_L4DFF(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if ((player > 0) && (player == GetClientOfUserId(GetEventInt(event, "guilty")))) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "friendly_fire");
		} else {
			log_player_event(player, "triggered", "friendly_fire");
		}
	}
}


public Event_L4DWitchKilled(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((player > 0) && (GetEventBool(event, "oneshot"))) {
		log_player_event(player, "triggered", "cr0wned");
	}
}


public Event_L4DDefib(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		log_player_event(player, "triggered", "defibrillated_teammate");
	}
}


public Event_L4DAdrenaline(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		log_player_event(player, "triggered", "used_adrenaline");
	}
}


public Event_L4DJockeyRide(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (player > 0) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "jockey_ride");
		} else {
			log_player_event(player, "triggered", "jockey_ride");
		}
	}
}


public Event_L4DChargerPummelStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (player > 0) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "charger_pummel");
		} else {
			log_player_event(player, "triggered", "charger_pummel");
		}
	}
}


public Event_L4DVomitBombTank(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		log_player_event(player, "triggered", "bilebomb_tank");
	}
}


public Event_L4DScavengeEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	new team_index = GetEventInt(event, "winners");
	if (strcmp(team_list[team_index], "") != 0) {
		log_team_event(team_list[team_index], "scavenge_win");
	}
}


public Event_L4DVersusEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	new team_index = GetEventInt(event, "winners");
	if (strcmp(team_list[team_index], "") != 0) {
		log_team_event(team_list[team_index], "versus_win");
	}
}


public Event_L4dChargerKilled(Handle: event, const String: name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "charger"));
	if ((attacker > 0) && (IsClientInGame(attacker))) {
		if (GetEventBool(event, "melee") && GetEventBool(event, "charging")) {
			if ((victim > 0) && (IsClientInGame(victim))) {
				log_player_player_event(attacker, victim, "triggered", "level_a_charge");
			} else {
				log_player_event(attacker, "triggered", "level_a_charge");
			}
		}
	}
}


public Event_L4DAward(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"	"short"				// player who earned the award
	// "entityid"	"long"			// client likes ent id
	// "subjectentid"	"long"		// entity id of other party in the award, if any
	// "award"		"short"			// id of award earned

	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		switch (GetEventInt(event, "award")) {
			case 21: 
				log_player_event(player, "triggered", "hunter_punter");
			case 27:
				log_player_event(player, "triggered", "tounge_twister");
			case 67:
				log_player_event(player, "triggered", "protect_teammate");
			case 80:
				log_player_event(player, "triggered", "no_death_on_tank");
			case 136:
				log_player_event(player, "triggered", "killed_all_survivors");
		}
	}
}


public Action: Event_INSMODObjMsg(UserMsg: msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{ 
	new objective_point = BfReadByte(bf); // Objective Point: 1 = point A, 2 = point B, 3 = point C, etc.
	new cap_status = BfReadByte(bf); // Capture Status: 1 on starting capture, 2 on finished capture
	new team_index = BfReadByte(bf); // Team Index: 1 = Marines, 2 = Insurgents
	
	if ((cap_status == 2) && (strcmp(team_list[team_index], "") != 0)) {
		switch (objective_point) {
			case 1:
				log_team_event(team_list[team_index], "point_captured", "point_a");
			case 2:
				log_team_event(team_list[team_index], "point_captured", "point_b");
			case 3:
				log_team_event(team_list[team_index], "point_captured", "point_c");
			case 4:
				log_team_event(team_list[team_index], "point_captured", "point_d");
			case 5:
				log_team_event(team_list[team_index], "point_captured", "point_e");
		}
	}

	return Plugin_Continue;
} 


public Event_TF2StealSandvich(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "owner"		"short"
	// "target"		"short"
		
	new owner = GetClientOfUserId(GetEventInt(event, "owner"));
	new target = GetClientOfUserId(GetEventInt(event, "target"));

	if ((owner > 0) && (target > 0)) {
		log_player_player_event(target, owner, "triggered", "steal_sandvich");
	}
}


public Event_TF2Stunned(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "stunner"	"short"
	// "victim"	"short"
	// "victim_capping"	"bool"
	// "big_stun"	"bool"

	new stunner = GetClientOfUserId(GetEventInt(event, "stunner"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if ((stunner > 0) && (victim > 0)) {

		log_player_player_event(stunner, victim, "triggered", "stun");
		if ((GetEntityFlags(victim) & (FL_ONGROUND | FL_INWATER)) == 0) {
			log_player_event(stunner, "triggered", "airshot_stun");
		}
	}
}


public Action: Event_TF2Jarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);

	if ((client > 0) && (victim > 0) && (IsClientInGame(client)) && (IsClientInGame(victim))) {
		if (TF2_IsPlayerInCondition(victim, TFCond_Jarated)) {
			log_player_player_event(client, victim, "triggered", "jarate");
		} else if (TF2_IsPlayerInCondition(victim, TFCond_Milked)) {
			log_player_player_event(client, victim, "triggered", "madmilk");
		}
	}
	return Plugin_Continue;
}


public Action: Event_TF2ShieldBlocked(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new victim = BfReadByte(bf);
	new client = BfReadByte(bf);
		
	if ((client > 0) && (victim > 0)) {
		log_player_player_event(client, victim, "triggered", "shield_blocked");
	}
	return Plugin_Continue;
}


public Action: Event_TF2SoundHook(clients[64], &numClients, String: sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if ((entity <= MaxClients) &&(clients[0] == entity) && (tf2_players[entity][player_class] == TFClass_Heavy) && (StrEqual(sample, "vo/SandwichEat09.wav"))) {
		
		switch (tf2_players[entity][player_loadout0][1]) {
			case TF2_LUNCHBOX_CHOCOLATE: {
				log_player_event(entity, "triggered", "dalokohs");
				new Float: time = GetGameTime();
				if ((time - tf2_players[entity][dalokohs]) > 30) {
					log_player_event(entity, "triggered", "dalokohs_healthboost");
				}
				tf2_players[entity][dalokohs] = time;
				if (GetClientHealth(entity) < 350) {
					log_player_event(entity, "triggered", "dalokohs_healself");
				}
			}
			case TF2_LUNCHBOX_STEAK: {
				log_player_event(entity, "triggered", "steak");
			}
			default: {
				log_player_event(entity, "triggered", "sandvich");
				if (GetClientHealth(entity) < 300) {
					log_player_event(entity, "triggered", "sandvich_healself");
				}
			}
		}

		
	} 
	return Plugin_Continue;
} 


public Event_TF2WinPanel(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player1 = GetEventInt(event, "player_1");
	new player2 = GetEventInt(event, "player_2");
	new player3 = GetEventInt(event, "player_3");
	
	if ((player1 > 0) && (IsClientInGame(player1))) {
		log_player_event(player1, "triggered", "mvp1");
	}
	if ((player2 > 0) && (IsClientInGame(player2))) {
		log_player_event(player2, "triggered", "mvp2");
	}
	if ((player3 > 0) && (IsClientInGame(player3))) {
		log_player_event(player3, "triggered", "mvp3");
	}
} 


public Event_TF2EscortScore(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetEventInt(event, "player");
	if (player > 0) {
		log_player_event(player, "triggered", "escort_score");
	}
}


public Event_TF2DeployBuffBanner(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "buff_owner"));
	if (player > 0) {
		log_player_event(player, "triggered", "buff_deployed");
	}

}


public Event_TF2MedicDefended(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		log_player_event(player, "triggered", "defended_medic");
	}
}


public Action: Event_TF2ObjectDestroyedPre(Handle: event, const String: name[], bool:dontBroadcast)
{
	if (GetEntProp(GetEventInt(event, "index"), Prop_Send, "m_bMiniBuilding", 1)) {
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new userid = GetEventInt(event, "userid");
		new victim = GetClientOfUserId(userid);
		
		if ((attacker > 0) && (victim > 0) && (attacker <= MAXPLAYERS) && (victim <= MAXPLAYERS) && (IsClientInGame(victim)) && (IsClientInGame(attacker))) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new Float: player_origin[3];
			GetClientAbsOrigin(attacker, player_origin);
			LogToGame("\"%L\" %s \"%s\" (object \"%s\") (weapon \"%s\") (objectowner \"%L\") (attacker_position \"%d %d %d\")", attacker, "triggered", "killedobject", "OBJ_SENTRYGUN_MINI", weapon_str, victim, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
		tf2_data[block_next_logging] = true;
	}
	return Plugin_Continue;
}


public Action: Event_TF2PlayerBuiltObjectPre(Handle: event, const String: name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		if (tf2_players[client][carry_object]) {
			tf2_players[client][carry_object] = false;
			tf2_data[block_next_logging] = true;
		} else {
			if (GetEntProp(GetEventInt(event, "index"), Prop_Send, "m_bMiniBuilding", 1)) {
				if ((client > 0) && (client <= MAXPLAYERS) && (IsClientInGame(client))) {
					new Float: player_origin[3];
					GetClientAbsOrigin(client, player_origin);
					LogToGame("\"%L\" %s \"%s\" (object \"%s\") (position \"%d %d %d\")", client, "triggered", "builtobject", "OBJ_SENTRYGUN_MINI", RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
				}
				tf2_data[block_next_logging] = true;
			}
		}
	}
	return Plugin_Continue;
}


public Event_TF2PlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new Float: time = GetGameTime();
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new TFClassType: spawn_class = TFClassType: GetEventInt(event, "class");

	tf2_players[client][jump_status] = TF2_JUMP_NONE;
	dump_player_data(client);

	if (time == tf2_players[client][object_removed]) {
		new obj_type;
		decl String: obj_name[24];
		while (PopStackCell(tf2_players[client][object_list], obj_type)) {
			switch (obj_type) {
				case TF2_OBJ_DISPENSER:
					obj_name = "OBJ_DISPENSER";
				case TF2_OBJ_TELEPORTER:
					obj_name = "OBJ_TELEPORTER";
				case TF2_OBJ_SENTRYGUN:
					obj_name = "OBJ_SENTRYGUN";
				case TF2_OBJ_SENTRYGUN_MINI:
					obj_name = "OBJ_SENTRYGUN_MINI";
				default:
					continue;
			}
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);
			LogToGame("\"%L\" %s \"%s\" (object \"%s\") (weapon \"%s\") (objectowner \"%L\") (attacker_position \"%d %d %d\")", client, "triggered", "killedobject", obj_name, "pda_engineer", client, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
	}
	
	tf2_players[client][player_class] = spawn_class;
	tf2_players[client][dalokohs] = -30.0;
}


public Event_TF2RoundStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	if (gameme_plugin[live_active] == 1) {
		for (new i = 0; (i <= MAXPLAYERS); i++) {
			gameme_players[i][palive] = 1;
		}
	}
}


public Event_TF2RoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
}


public Event_TF2ObjectRemoved(Handle: event, const String: name[], bool:dontBroadcast)
{
	new Float: time = GetGameTime();
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if (time != tf2_players[client][object_removed]) {
		tf2_players[client][object_removed] = time;
		while (PopStack(tf2_players[client][object_list])) {
			continue;
		}
	}
	new obj_type = GetEventInt(event, "objecttype");
	new obj_index = GetEventInt(event, "index");
	if ((IsValidEdict(obj_index)) && (GetEntProp(GetEventInt(event, "index"), Prop_Send, "m_bMiniBuilding", 1))) {
		obj_type = TF2_OBJ_SENTRYGUN_MINI;
	}
	PushStackCell(tf2_players[client][object_list], obj_type);
}


public Event_TF2PostInvApp(Handle: event, const String: name[], bool:dontBroadcast)
{
	CreateTimer(0.2, check_player_loadout, GetEventInt(event, "userid"));
}


public Action: check_player_loadout(Handle: timer, any: userid)
{
	new client = GetClientOfUserId(userid);
	if ((client == 0) || (!IsClientInGame(client))) {
		return Plugin_Stop;
	}
	
	new bool: is_new_loadout = false;
	for (new check_slot = 0; check_slot <= 5; check_slot++) {
		if ((tf2_players[client][player_loadout1][check_slot] != 0) && (IsValidEntity(tf2_players[client][player_loadout1][check_slot]))) {
			continue;
		}
		new entity = GetPlayerWeaponSlot(client, check_slot);
		if (entity == -1) {
			if ((gameme_plugin[sdkhook_available]) && (check_slot < 3) && ((tf2_players[client][player_class] == TFClass_Soldier) || (tf2_players[client][player_class] == TFClass_DemoMan))) {
				tf2_players[client][player_loadout1][check_slot] = -1;
				continue;
			}
			if (tf2_players[client][player_loadout0][check_slot] == -1) {
				continue;
			}
			tf2_players[client][player_loadout0][check_slot] = -1;
			tf2_players[client][player_loadout1][check_slot] = -1;
			is_new_loadout = true;
		} else {
			new item_index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if (tf2_players[client][player_loadout0][check_slot] != item_index) {
				tf2_players[client][player_loadout0][check_slot] = item_index;
				is_new_loadout = true;
			}
			tf2_players[client][player_loadout1][check_slot] = EntIndexToEntRef(entity);
		}
	}
	
	if (gameme_plugin[sdkhook_available]) {
		if (is_new_loadout) {
			tf2_players[client][player_loadout_updated] = true;
		}
		CreateTimer(0.2, log_weapon_loadout, userid);
	} else {
		if (is_new_loadout) {
			log_weapon_loadout(INVALID_HANDLE, userid);
		}
	}
	return Plugin_Stop;
}


public Action: log_weapon_loadout(Handle: timer, any: userid)
{
	new client = GetClientOfUserId(userid);
	if ((client > 0) && (IsClientInGame(client))) {
		for (new i = 0; i < TF2_MAX_LOADOUT_SLOTS; i++) {
			if ((tf2_players[client][player_loadout0][i] != -1) && (!IsValidEntity(tf2_players[client][player_loadout1][i])) || (tf2_players[client][player_loadout1][i] == 0)) {
				tf2_players[client][player_loadout0][i] = -1;
				tf2_players[client][player_loadout1][i] = -1;
				tf2_players[client][player_loadout_updated] = true;
			}
		}
		if (tf2_players[client][player_loadout_updated] == false) {
			return Plugin_Stop;
		}
		tf2_players[client][player_loadout_updated] = false;
		LogToGame("\"%L\" %s \"%s\" (primary \"%d\") (secondary \"%d\") (melee \"%d\") (pda \"%d\") (pda2 \"%d\") (building \"%d\") (head \"%d\") (misc \"%d\")", client, "triggered", "player_loadout", tf2_players[client][player_loadout0][0], tf2_players[client][player_loadout0][1], tf2_players[client][player_loadout0][2], tf2_players[client][player_loadout0][3], tf2_players[client][player_loadout0][4], tf2_players[client][player_loadout0][5], tf2_players[client][player_loadout0][6], tf2_players[client][player_loadout0][7]); 
	}
	return Plugin_Stop;
}


public Action: OnTF2TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((attacker > 0) && (attacker <= MaxClients) && (attacker != victim) && (inflictor > MaxClients) && (damage > 0.0) && (IsValidEntity(inflictor)) && ((GetEntityFlags(victim) & (FL_ONGROUND | FL_INWATER)) == 0)) {
		decl String: weapon_str[64];
		GetEdictClassname(inflictor, weapon_str, 64);
		if ((weapon_str[3] == 'p') && (weapon_str[4] == 'r')) {
			switch(weapon_str[14]) {
				case 'r': {
					log_player_event(attacker, "triggered", "airshot_rocket");
					if (tf2_players[attacker][jump_status] == TF2_JUMP_ROCKET) {
						log_player_event(attacker, "triggered", "air2airshot_rocket");
					}
				}
				case 'p': {
					if (weapon_str[18] != 0) {
						log_player_event(attacker, "triggered", "airshot_sticky");
						if (tf2_players[attacker][jump_status] == TF2_JUMP_STICKY) {
							log_player_event(attacker, "triggered", "air2airshot_sticky");
						}
					} else {
						log_player_event(attacker, "triggered", "airshot_pipebomb");
						if (tf2_players[attacker][jump_status] == TF2_JUMP_STICKY) {
							log_player_event(attacker, "triggered", "air2airshot_pipebomb");
						}
					}
				}
				case 'a': {
					log_player_event(attacker, "triggered", "airshot_arrow");
				}
				case 'f': {
					if (damage > 10.0) {
						log_player_event(attacker, "triggered", "airshot_flare");
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


public OnTF2TakeDamage_Post(victim, attacker, inflictor, Float:damage, damagetype)
{
	if ((attacker > 0) && (attacker <= MaxClients)) {
		new weapon_index = -1;
		new idamage = RoundFloat(damage);
		decl String: weapon_str[64];

		if (inflictor <= MaxClients) {
			if (damagetype & DMG_BURN) {
				return;
			}
			if ((inflictor == attacker) && (damagetype & 1) && (damage == 1000.0)) {
				return;
			}
			GetClientWeapon(attacker, weapon_str, 64);
			weapon_index = get_tf2_weapon_index(weapon_str[TF2_WEAPON_PREFIX_LENGTH], attacker);
		} else if (IsValidEdict(inflictor)) {
			GetEdictClassname(inflictor, weapon_str, 64);
			if (weapon_str[TF2_WEAPON_PREFIX_LENGTH] == 'g') {
				return;
			} else if (weapon_str[3] == 'p') {
				weapon_index = get_tf2_weapon_index(weapon_str, attacker, inflictor);
			} else {
				if ((!(damagetype & DMG_CRUSH)) && (damagetype & DMG_CLUB) && (StrEqual(weapon_str, "tf_weapon_bat_wood"))) {
					weapon_index = get_tf2_weapon_index("ball", attacker);
				} else {
					weapon_index = get_tf2_weapon_index(weapon_str[TF2_WEAPON_PREFIX_LENGTH], attacker);
				}
			}
		}

		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][wdamage] += idamage;
			player_weapons[attacker][weapon_index][whits]++;
		}
	}
}


public Event_TF2RocketJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		new status = tf2_players[client][jump_status];
		if (status == TF2_JUMP_ROCKET_START) {
			tf2_players[client][jump_status] = TF2_JUMP_ROCKET;
			log_player_event(client, "triggered", "rocket_jump");
		} else if (status != TF2_JUMP_ROCKET) {
			tf2_players[client][jump_status] = TF2_JUMP_ROCKET_START;
		}
	}
}


public Event_TF2StickyJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		if (tf2_players[client][jump_status] != TF2_JUMP_STICKY) {
			tf2_players[client][jump_status] = TF2_JUMP_STICKY;
			log_player_event(client, "triggered", "sticky_jump");
		}
	}
}


public Event_TF2JumpLanded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		tf2_players[client][jump_status] = TF2_JUMP_NONE;
		
	}
}


public Event_TF2ObjectDeflected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new owner = GetClientOfUserId(GetEventInt(event, "ownerid"));
	
	if ((client > 0) && (owner > 0)) {
		new weapon_id = GetEventInt(event, "weaponid");
	
		switch (weapon_id)	{
			case TF_WEAPON_NONE: {
				log_player_player_event(client, owner, "triggered", "airblast_player", 1);
			}
			case TF_WEAPON_COMPOUND_BOW: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_arrow");
					if (weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_FLAREGUN: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_flare");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_ROCKETLAUNCHER: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_rocket");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_DIRECTHIT: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_rocket");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_GRENADE_DEMOMAN: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_promode");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
		}
		
	}
}


public OnHL2MPFireBullets(attacker, shots, String: weapon_str[])
{
	if ((attacker > 0) && (attacker <= MaxClients)) {
		decl String: weapon_name[32];
		GetClientWeapon(attacker, weapon_name, 32);
		new weapon_index = get_weapon_index(hl2mp_weapon_list, MAX_HL2MP_WEAPON_COUNT, weapon_name[7]);
		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][wshots]++;
		}
	}
}


public OnHL2MPTraceAttack(victim, attacker, inflictor, Float: damage, damagetype, ammotype, hitbox, hitgroup)
{
	if ((hitgroup > 0) && (attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		if (IsValidEntity(inflictor)) {
			decl String: inflictorclsname[64];
			if ((GetEntityNetClass(inflictor, inflictorclsname, sizeof(inflictorclsname)) && (strcmp(inflictorclsname, "CCrossbowBolt") == 0))) {
				hl2mp_players[victim][nextbow_hitgroup] = hitgroup;
				return;
			}
		}
		hl2mp_players[victim][next_hitgroup] = hitgroup;
	}
}


public OnHL2MPTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{	
	if ((attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		decl String: weapon_str[32];
		GetClientWeapon(attacker, weapon_str, 32);
		new weapon_index = -1;

		if (IsValidEntity(inflictor)) {
			decl String: inflictorclsname[64];
			if (GetEntityNetClass(inflictor, inflictorclsname, sizeof(inflictorclsname)) && strcmp(inflictorclsname, "CCrossbowBolt") == 0) {
				weapon_index = HL2MP_CROSSBOW;
			}
		}
		if (weapon_index == -1) {
			weapon_index = get_weapon_index(hl2mp_weapon_list, MAX_HL2MP_WEAPON_COUNT, weapon_str[7]);
		}

		new hitgroup = ((weapon_index == HL2MP_CROSSBOW) ? hl2mp_players[victim][nextbow_hitgroup] : hl2mp_players[victim][next_hitgroup]);
		if (hitgroup < 8) {
			hitgroup += LOG_HIT_OFFSET;
		}

		new bool: headshot = ((GetClientHealth(victim) <= 0) && (hitgroup == HITGROUP_HEAD));
		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += RoundToNearest(damage);
			player_weapons[attacker][weapon_index][hitgroup]++;
			if (headshot) {
				player_weapons[attacker][weapon_index][wheadshots]++;
			}
		}
		
		if (weapon_index == HL2MP_CROSSBOW) {
			hl2mp_players[victim][nextbow_hitgroup] = 0;
		} else {
			hl2mp_players[victim][next_hitgroup] = 0;
		}
		
	}
}


public OnZPSFireBullets(attacker, shots, String: weapon[])
{
	if ((attacker > 0) && (attacker <= MaxClients)) {
		decl String: weapon_name[32];
		GetClientWeapon(attacker, weapon_name, 32);
		new weapon_index = get_weapon_index(zps_weapon_list, MAX_ZPS_WEAPON_COUNT, weapon_name);
		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][wshots]++;
		}
	}
}


public OnZPSTraceAttack(victim, attacker, inflictor, Float:damage, damagetype, ammotype, hitbox, hitgroup)
{
	if ((hitgroup > 0) && (attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		zps_players[victim][next_hitgroup] = hitgroup;
	}
}


public OnZPSTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{	
	if ((attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		new hitgroup = zps_players[victim][next_hitgroup];
		if (hitgroup < 8) {
			hitgroup += LOG_HIT_OFFSET;
		}
		new bool: headshot = ((GetClientHealth(victim) <= 0) && (hitgroup == HITGROUP_HEAD));
		
		decl String: weapon_str[32];
		GetClientWeapon(attacker, weapon_str, 32);
		new weapon_index = get_weapon_index(zps_weapon_list, MAX_ZPS_WEAPON_COUNT, weapon_str);

		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += RoundToNearest(damage);
			if (headshot) {
				player_weapons[attacker][weapon_index][wheadshots]++;
			}
		}
		zps_players[victim][next_hitgroup] = 0;
	}
}


stock AddPluginServerTag(const String:tag[]) 
{
	if ((gameme_plugin[sv_tags] == INVALID_HANDLE) ||
	    ((gameme_plugin[engine_version] != Engine_CSS) && (gameme_plugin[engine_version] != Engine_HL2DM) &&
	     (gameme_plugin[engine_version] != Engine_DODS) && (gameme_plugin[engine_version] != Engine_TF2) &&
	     (gameme_plugin[engine_version] != Engine_NuclearDawn) && (gameme_plugin[engine_version] != Engine_Left4Dead) &&
	     (gameme_plugin[engine_version] != Engine_Left4Dead2) && (gameme_plugin[engine_version] != Engine_CSGO))) {
		return;
	}
	
	if (FindStringInArray(gameme_plugin[custom_tags], tag) == -1) {
		PushArrayString(gameme_plugin[custom_tags], tag);
	}
	
	decl String: current_tags[128];
	GetConVarString(gameme_plugin[sv_tags], current_tags, 128);
	if (StrContains(current_tags, tag) > -1) {
		LogToGame("gameME gameserver tag already exists [%s]", current_tags);
		return;
	}
	
	decl String: new_tags[128];
	Format(new_tags, sizeof(new_tags), "%s%s%s", current_tags, (current_tags[0] != 0) ? "," : "", tag);
	
	new flags = GetConVarFlags(gameme_plugin[sv_tags]);
	SetConVarFlags(gameme_plugin[sv_tags], flags & ~FCVAR_NOTIFY);
	gameme_plugin[ignore_next_tag_change] = true;
	SetConVarString(gameme_plugin[sv_tags], new_tags);
	gameme_plugin[ignore_next_tag_change] = false;
	SetConVarFlags(gameme_plugin[sv_tags], flags);

	LogToGame("Added gameME gameserver tag [%s]", new_tags);
}
