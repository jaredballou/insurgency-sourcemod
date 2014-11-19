/* 
	------------------------------------------------------------------------------------------
	EntControl::Gman
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitGMan()
{
	PrecacheModel("models/gman_high.mdl");
	PrecacheSound("vo/Citadel/gman_exit03.wav");
	PrecacheSound("vo/Citadel/gman_exit10.wav");
	PrecacheSound("player/pl_pain7.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_GMan
	------------------------------------------------------------------------------------------
*/
public Action:Command_GMan(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	decl Float:position[3];
	if (GetPlayerEye(client, position))
		GMan_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	GMan_Spawn
	------------------------------------------------------------------------------------------
*/
public GMan_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/gman.mdl", GManSeekThink, "npc_gman", "Wave");

	SDKHook(monster, SDKHook_OnTakeDamage, GManDamageHook);
	
	CreateTimer(10.0, GManTauntThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/* 
	------------------------------------------------------------------------------------------
	GManAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:GManSeekThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		new target = BaseNPC_GetTarget(monster);
		decl Float:vClientPosition[3], Float:vEntPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			if (GetVectorDistance(vClientPosition, vEntPosition, false) < 120.0 && BaseNPC_CanSeeEachOther(monster, target))
			{
				BaseNPC_HurtPlayer(monster, target, 80, 120.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "vo/Citadel/gman_exit10.wav");
				
				BaseNPC_SetAnimation(monster, "swing");
			}
			else
			{
				BaseNPC_SetAnimation(monster, "run_all");
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "idle01");
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	GManTauntThink
	------------------------------------------------------------------------------------------
*/
public Action:GManTauntThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		decl Float:vEntPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		BaseNPC_PlaySound(monster, "vo/Citadel/gman_exit03.wav");
		BaseNPC_SetAnimation(monster, "wave");
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	HeadCrabDamageHook
	------------------------------------------------------------------------------------------
*/
public Action:GManDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "player/pl_pain7.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, GManDamageHook);

		BaseNPC_Death(monster, attacker, 5);
	}
	
	return (Plugin_Handled);
}