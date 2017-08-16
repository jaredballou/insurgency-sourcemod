//=========== (C) Copyright 1999 Valve, L.L.C. All rights reserved. ===========
//
// The copyright to the contents herein is the property of Valve, L.L.C.
// The contents may be used and/or copied only with the written permission of
// Valve, L.L.C., or in accordance with the terms and conditions stipulated in
// the agreement/contract under which the contents have been supplied.
//=============================================================================

// No spaces in event names, max length 32
// All strings are case sensitive
// total game event byte length must be < 1024
//
// valid data key types are:
//   none   : value is not networked
//   string : a zero terminated string
//   bool   : unsigned int, 1 bit
//   byte   : unsigned int, 8 bit
//   short  : signed int, 16 bit
//   long   : signed int, 32 bit
//   float  : float, 32 bit

"ModEvents"
{
//////////////////////////////////////////////////////////////////////
// Player events
//////////////////////////////////////////////////////////////////////
	"player_hurt"
	{
		"priority" "short"
		"attacker" "short"
		"dmg_health" "short"
		"health" "byte"
		"damagebits" "long"
		"hitgroup" "short"
		"weapon" "string"
		"weaponid" "short"
		"userid" "short"
	}

	"player_footstep"
	{
		"userid" "short"
	}

	"player_jump"
	{
		"userid" "short"
	}

	"player_blind"
	{
		"userid" "short"
	}

	"player_falldamage"
	{
		"userid" "short"
		"damage" "float"
	}

	"player_stats_updated"
	{
	}

	"player_avenged_teammate"
	{
		"avenger_id" "short"
		"avenged_player_id" "short"
	}

	"player_decal"
	{
		"userid" "short"
	}

	"player_death"
	{
		"deathflags" "short"
		"attacker" "short"
		"customkill" "short"
		"lives" "short"
		"attackerteam" "short"
		"damagebits" "long"
		"weapon" "string"
		"weaponid" "short"
		"userid" "short"
		"priority" "short"
		"team" "short"
		"y" "float"
		"x" "float"
		"z" "float"
		"assister" "short"
	}

	"player_drop"
	{
		"userid" "short"
		"entity" "short"
	}

	"player_receive_supply"
	{
		"userid" "short"
		"ammount" "short"
	}

	"player_first_spawn"
	{
		"userid" "short"
	}

	"player_pick_squad"
	{
		"squad_slot" "byte"
		"squad" "byte"
		"userid" "short"
		"class_template" "string"
	}

	"player_suppressed"
	{
		"attacker" "short"
		"victim" "short"
	}
//////////////////////////////////////////////////////////////////////
// Weapon events
//////////////////////////////////////////////////////////////////////
	"weapon_fire"
	{
		"weaponid" "short"
		"userid" "short"
		"shots" "byte"
	}

	"weapon_fire_on_empty"
	{
		"weapon" "string"
		"userid" "short"
	}

	"weapon_outofammo"
	{
		"userid" "short"
	}

	"weapon_reload"
	{
		"userid" "short"
	}

	"weapon_pickup"
	{
		"weaponid" "short"
		"userid" "short"
	}

	"weapon_deploy"
	{
		"weaponid" "short"
		"userid" "short"
	}

	"weapon_holster"
	{
		"weaponid" "short"
		"userid" "short"
	}

	"weapon_ironsight"
	{
		"weaponid" "short"
		"userid" "short"
	}

	"weapon_lower_sight"
	{
		"weaponid" "short"
		"userid" "short"
	}

	"weapon_focus_enter"
	{
		"weaponid" "short"
		"userid" "short"
	}

	"weapon_focus_exit"
	{
		"weaponid" "short"
		"userid" "short"
	}

	"weapon_firemode"
	{
		"weaponid" "short"
		"userid" "short"
		"firemode" "byte"
	}

	"grenade_thrown"
	{
		"entityid" "long"
		"userid" "short"
		"id" "short"
	}

	"grenade_detonate"
	{
		"userid" "short"
		"effectedEnemies" "short"
		"y" "float"
		"x" "float"
		"entityid" "long"
		"z" "float"
		"id" "short"
	}
//////////////////////////////////////////////////////////////////////
// Game events
//////////////////////////////////////////////////////////////////////
	"game_start"
	{
		"priority" "short"
	}

	"game_teams_switched"
	{
	}

	"game_newmap"
	{
		"mapname" "string"
	}

	"game_end"
	{
		"team2_score" "short"
		"winner" "byte"
		"team1_score" "short"
	}
//////////////////////////////////////////////////////////////////////
// Round events
//////////////////////////////////////////////////////////////////////
	"round_start"
	{
		"priority" "short"
		"timelimit" "short"
		"lives" "short"
		"gametype" "short"
	}

	"round_end"
	{
		"reason" "byte"
		"winner" "byte"
		"message" "string"
		"message_string" "string"
	}

	"round_freeze_end"
	{
	}

	"round_restart"
	{
	}

	"round_begin"
	{
	}

	"round_timer_changed"
	{
		"delta" "float"
	}

	"round_level_advanced"
	{
		"level" "short"
	}
//////////////////////////////////////////////////////////////////////
// Objective events
//////////////////////////////////////////////////////////////////////
	"controlpoint_initialized"
	{
	}

	"controlpoint_captured"
	{
		"priority" "short"
		"cp" "byte"
		"cappers" "string"
		"cpname" "string"
		"team" "byte"
		"oldteam" "byte"
	}

	"controlpoint_neutralized"
	{
		"priority" "short"
		"cp" "byte"
		"cappers" "string"
		"cpname" "string"
		"team" "byte"
		"oldteam" "byte"
	}

	"controlpoint_endtouch"
	{
		"owner" "short"
		"player" "short"
		"team" "short"
		"area" "byte"
	}

	"controlpoint_starttouch"
	{
		"area" "byte"
		"object" "short"
		"player" "short"
		"team" "short"
		"owner" "short"
		"type" "short"
	}
//////////////////////////////////////////////////////////////////////
// Miscellaneous events
//////////////////////////////////////////////////////////////////////
	"door_moving"
	{
		"entindex" "long"
		"userid" "short"
	}

	"nav_blocked"
	{
		"area" "long"
		"blocked" "bool"
	}

	"nav_generate"
	{
	}

	"achievement_info_loaded"
	{
	}

	"rank_mgr_ranks_calculated"
	{
	}

	"spec_target_updated"
	{
	}

	"spec_mode_updated"
	{
	}

	"hltv_changed_mode"
	{
		"newmode" "long"
		"oldmode" "long"
		"obs_target" "long"
	}

	"show_freezepanel"
	{
		"hits_taken" "short"
		"damage_given" "short"
		"hits_given" "short"
		"killer" "short"
		"damage_taken" "short"
		"victim" "short"
	}

	"hide_freezepanel"
	{
	}

	"freezecam_started"
	{
	}

	"achievement_earned"
	{
		"player" "byte"
		"achievement" "short"
	}

	"client_disconnect"
	{
	}

	"inventory_open"
	{
	}

	"inventory_close"
	{
	}

	"enter_spawnzone"
	{
		"userid" "short"
	}

	"exit_spawnzone"
	{
		"userid" "short"
	}

	"missile_launched"
	{
		"entityid" "long"
		"userid" "short"
		"id" "short"
	}

	"missile_detonate"
	{
		"userid" "short"
		"y" "float"
		"x" "float"
		"entityid" "long"
		"z" "float"
		"id" "short"
	}

	"smoke_grenade_expire"
	{
		"userid" "short"
		"y" "float"
		"x" "float"
		"entityid" "long"
		"z" "float"
		"id" "short"
	}

	"flag_pickup"
	{
		"priority" "short"
		"userid" "short"
	}

	"flag_drop"
	{
		"priority" "short"
		"userid" "short"
	}

	"flag_captured"
	{
		"priority" "short"
		"cp" "short"
		"userid" "short"
	}

	"flag_returned"
	{
		"priority" "short"
		"userid" "short"
	}

	"flag_reset"
	{
		"priority" "short"
		"team" "short"
	}

	"object_destroyed"
	{
		"team" "byte"
		"attacker" "byte"
		"cp" "short"
		"index" "short"
		"type" "byte"
		"weapon" "string"
		"weaponid" "short"
		"assister" "byte"
		"attackerteam" "byte"
	}

	"time_class"
	{
		"seconds" "float"
		"userid" "short"
		"class" "short"
	}

	"time_weapon"
	{
		"seconds" "float"
		"weapon" "short"
		"userid" "short"
	}

	"training_timer"
	{
		"duration" "float"
	}

	"instructor_ai_difficulty"
	{
		"rounds_failed" "byte"
		"ai_win" "bool"
	}

	"stat_summary_updated"
	{
		"localplayer" "bool"
	}

	"stat_local_load_start"
	{
	}

	"stat_local_load_finish"
	{
	}

	"stat_leaderboard_updated"
	{
	}

	"radio_requested"
	{
		"requesting_player"		"short"
		"team"					"short"
	}

	"artillery_requested"
	{
		"requesting_player"		"short"
		"radio_player"			"short"
		"team"					"short"
		"type"					"string"
		"lethal"				"bool"
		"target_x"				"float"
		"target_y"				"float"
		"target_z"				"float"
	}
	
	"artillery_failed"
	{
		"requesting_player"		"short"
		"radio_player"			"short"
		"team"					"short"
		"type"					"string"
		"lethal"				"bool"
		"reason"				"string"
	}
	
	"artillery_called"
	{
		"requesting_player"		"short"
		"radio_player"			"short"
		"team"					"short"
		"type"					"string"
		"lethal"				"bool"
		"target_x"				"float"
		"target_y"				"float"
		"target_z"				"float"		
	}
}

