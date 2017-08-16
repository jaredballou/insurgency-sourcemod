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

"gameevents"
{
//////////////////////////////////////////////////////////////////////
// Player events
//////////////////////////////////////////////////////////////////////
	"player_team"
	{
		"disconnect" "bool"
		"silent" "bool"
		"userid" "short"
		"isbot" "bool"
		"oldteam" "byte"
		"team" "byte"
		"autoteam" "bool"
	}

	"player_hurt"
	{
		"attacker" "short"
		"userid" "short"
		"health" "byte"
	}

	"player_spawn"
	{
		"teamnum" "short"
		"userid" "short"
	}

	"player_use"
	{
		"userid" "short"
		"entity" "short"
	}

	"player_changename"
	{
		"newname" "string"
		"userid" "short"
		"oldname" "string"
	}

	"player_hintmessage"
	{
		"hintmessage" "string"
	}

	"player_decal"
	{
		"userid" "short"
	}

	"player_stats_updated"
	{
		"forceupload" "bool"
	}
//////////////////////////////////////////////////////////////////////
// Team events
//////////////////////////////////////////////////////////////////////
	"teamplay_broadcast_audio"
	{
		"sound" "string"
		"team" "byte"
	}
//////////////////////////////////////////////////////////////////////
// Game events
//////////////////////////////////////////////////////////////////////
	"game_init"
	{
	}

	"game_newmap"
	{
		"mapname" "string"
	}

	"game_start"
	{
		"objective" "string"
		"timelimit" "long"
		"roundslimit" "long"
		"fraglimit" "long"
	}
//////////////////////////////////////////////////////////////////////
// Round events
//////////////////////////////////////////////////////////////////////
	"round_start"
	{
		"objective" "string"
		"timelimit" "long"
		"fraglimit" "long"
	}

	"round_end"
	{
		"reason" "byte"
		"winner" "byte"
		"message" "string"
		"message_string" "string"
	}

	"round_start_pre_entity"
	{
	}
//////////////////////////////////////////////////////////////////////
// Voting events
//////////////////////////////////////////////////////////////////////
	"vote_started"
	{
		"initiator" "long"
		"issue" "string"
		"param1" "string"
		"team" "byte"
	}

	"vote_changed"
	{
		"potentialVotes" "byte"
		"vote_option4" "byte"
		"vote_option5" "byte"
		"vote_option1" "byte"
		"vote_option2" "byte"
		"vote_option3" "byte"
	}

	"vote_passed"
	{
		"details" "string"
		"param1" "string"
		"team" "byte"
	}

	"vote_failed"
	{
		"team" "byte"
	}

	"vote_cast"
	{
		"entityid" "long"
		"vote_option" "byte"
		"team" "short"
	}

	"vote_options"
	{
		"count" "byte"
		"option4" "string"
		"option5" "string"
		"option2" "string"
		"option3" "string"
		"option1" "string"
	}
//////////////////////////////////////////////////////////////////////
// Miscellaneous events
//////////////////////////////////////////////////////////////////////
	"hostname_changed"
	{
		"hostname" "string"
	}

	"break_breakable"
	{
		"entindex" "long"
		"material" "byte"
		"userid" "short"
	}

	"break_prop"
	{
		"entindex" "long"
		"userid" "short"
	}

	"entity_killed"
	{
		"entindex_killed" "long"
		"entindex_inflictor" "long"
		"entindex_attacker" "long"
		"damagebits" "long"
	}

	"achievement_earned"
	{
		"player" "byte"
		"achievement" "short"
	}

	"user_data_downloaded"
	{
	}

	"ragdoll_dissolved"
	{
		"entindex" "long"
	}

	"gameinstructor_draw"
	{
	}

	"gameinstructor_nodraw"
	{
	}

	"map_transition"
	{
	}

	"entity_visible"
	{
		"classname" "string"
		"entityname" "string"
		"userid" "short"
		"subject" "short"
	}

	"set_instructor_group_enabled"
	{
		"group" "string"
		"enabled" "short"
	}

	"instructor_server_hint_create"
	{
		"hint_replace_key" "string"
		"hint_icon_offset" "float"
		"hint_allow_nodraw_target" "bool"
		"hint_icon_onscreen" "string"
		"hint_activator_userid" "short"
		"hint_caption" "string"
		"hint_name" "string"
		"hint_timeout" "short"
		"hint_activator_caption" "string"
		"hint_color" "string"
		"hint_forcecaption" "bool"
		"hint_local_player_only" "bool"
		"hint_gamepad_binding" "string"
		"hint_icon_offscreen" "string"
		"hint_binding" "string"
		"hint_range" "float"
		"hint_target" "long"
		"hint_nooffscreen" "bool"
		"hint_flags" "long"
	}

	"instructor_server_hint_stop"
	{
		"hint_name" "string"
	}

	"read_game_titledata"
	{
		"controllerId" "short"
	}

	"write_game_titledata"
	{
		"controllerId" "short"
	}

	"reset_game_titledata"
	{
		"controllerId" "short"
	}
}

