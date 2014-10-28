/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This file is part of the SourceMod/SourcePawn SDK.
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
 */

#if defined _hooker_included
  #endinput
#endif
#define _hooker_included

enum HookType
{
	HK_GameNameDescription = 0,
	HK_WeaponDrop,
	HK_WeaponCanUse,
	HK_WeaponCanSwitchTo,
	HK_OnChangeActiveWeapon,
	HK_Touch,
	HK_StartTouch,
	HK_EndTouch,
	HK_EventKilled,
	HK_OnTakeDamage,
	HK_TraceAttack,
	HK_Spawn,
	HK_EntityThink,
	HK_ClientPreThink,
	HK_ClientPostThink,
	HK_PlayerJump,
	HK_PlayerDuck,
	HK_CommitSuicide,
	HK_Respawn,
	HK_SetModel,
	HK_ShowViewPortPanel,
	HK_ImpulseCommands
};
enum HK_Ents
{
	HKE_CBaseEntity = 0,
	HKE_CCSPlayer,
	HKE_CTFPlayer,
	HKE_CDODPlayer,
	HKE_CHL2MP_Player,
	HKE_CINSPlayer
};
funcenum Hooks
{
	Action:public(client, weapon),
	public(client, weapon),
	Action:public(client, oldweapon, newweapon),
	public(client, oldweapon, neweapon),
	Action:public(toucher, touched),
	public(toucher, touched),
	Action:public(client, &inflictor, &attacker, &Float:Damage, &DamageType, &AmmoType),
	public(client, inflictor, attacker, Damage, DamageType, AmmoType),
	Action:public(index),
	public(index),
	Action:public(const String:GameName[], maxlen),
	public(index, const String:ModelName[]),
	Action:public(index, const String:Name[]),
	public(index, const String:Name[])
};
/**
 * Adds a Hook to a function
 *
 * @param type			type of hook.
 * @param func			function name to send the hook to.
 * @param post			post hook or pre hook, pre=false and post=true.
 * @noreturn	
 */
native RegisterHook(HookType:type, Hooks:func, bool:post=false);

/**
 * Adds hooks to the entity, then hooks will be retrieved using RegisterHook.
 * @param type				type of entity
 * @param EntityIndex		Entity index.
 * @noreturn
 * @error					if entity is invalid or entity has been just created but has no propterties.
 */
native HookEntity(HK_Ents:type, EntityIndex);
/**
 * Removes players hook.
 *
 * @param EntityIndex		Entity index.
 * @noreturn
*/
native UnHookPlayer(HK_Ents:type, PlayerIndex);

/**
* Forward called when an entity is created.
* @param EntIndex			index of the entity that just got created.
* @param Classname			classname of the entity that got created.
*/
forward HookerOnEntityCreated(EntIndex, const String:Classname[]);


public Extension:__ext_hooker =
{
	name = "Hooker Extension",
	file = "hooker.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};