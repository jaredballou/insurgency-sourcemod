/* 
	------------------------------------------------------------------------------------------
	EntControl::Soldier
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitSoldier()
{
	PrecacheModel("models/combine_soldier.mdl");
	PrecacheModel("models/weapons/w_shotgun.mdl");
	
	PrecacheSound("npc/combine_soldier/vo/overwatchrequestreinforcement.wav");
	PrecacheSound("npc/combine_soldier/pain1.wav");
	PrecacheSound("npc/combine_soldier/die1.wav");
	PrecacheSound("npc/soldier/claw_strike1.wav");
}

/*
	------------------------------------------------------------------------------------------
	Command_Soldier
	------------------------------------------------------------------------------------------
*/
public Action:Command_Soldier(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		Soldier_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/*
	------------------------------------------------------------------------------------------
	Soldier_Spawn
	------------------------------------------------------------------------------------------
*/
public Action:Soldier_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/combine_soldier.mdl", SoldierSeekThink, "npc_soldier", "CrouchIdle");

	SDKHook(monster, SDKHook_OnTakeDamage, SoldierDamageHook);
	
	CreateTimer(10.0, SoldierIdleThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	
	decl String:tmp[32];
	GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
	new monster_tmp = StringToInt(tmp);
	
	new weapon = CreateEntityByName("prop_dynamic_ornament");
	DispatchKeyValue(weapon, "model", "models/weapons/w_shotgun.mdl");
	DispatchKeyValue(weapon, "classname", "shotgun");
	DispatchSpawn(weapon);
	

	decl String:entIndex[6];
	IntToString(weapon, entIndex, sizeof(entIndex)-1);
	
	DispatchKeyValue(monster_tmp, "targetname", entIndex);
	
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetParent");
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetAttached");
}

/* 
	------------------------------------------------------------------------------------------
	SoldierAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:SoldierSeekThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		new target = BaseNPC_GetTarget(monster);
		new Float:vClientPosition[3], Float:vEntPosition[3], Float:vAngle[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			vEntPosition[2] += 20.0;
			if (GetVectorDistance(vClientPosition, vEntPosition, false) < 800.0 && BaseNPC_CanSeeEachOther(monster, target))
			{
				vClientPosition[2] -= 10.0;
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				//NormalizeVector(vAngle, vAngle);
				GetVectorAngles(vAngle, vAngle);

				Projectile(false, BaseNPC_GetOwner(monster), vEntPosition, vAngle, "models/Effects/combineball.mdl", gPlasmaSpeed, gPlasmaDamage, "weapons/Irifle/irifle_fire2.wav", true, Float:{0.4, 1.0, 1.0});
				
				BaseNPC_SetAnimation(monster, "shootSGc");
				SetEntityMoveType(monster, MOVETYPE_NONE);
			}
			else
			{
				BaseNPC_SetAnimation(monster, "Crouch_RunALL");
				SetEntityMoveType(monster, MOVETYPE_STEP);
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "CrouchIdle");
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}


/* 
	------------------------------------------------------------------------------------------
	SoldierIdleThink
	------------------------------------------------------------------------------------------
*/
public Action:SoldierIdleThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		BaseNPC_PlaySound(monster, "npc/combine_soldier/vo/overwatchrequestreinforcement.wav");
		
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
public Action:SoldierDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/combine_soldier/pain1.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, SoldierDamageHook);

		BaseNPC_Death(monster, attacker);
		
		BaseNPC_PlaySound(monster, "npc/combine_soldier/die1.wav");
	}
	
	return (Plugin_Handled);
}