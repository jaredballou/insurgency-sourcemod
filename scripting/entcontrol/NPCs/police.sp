/* 
	------------------------------------------------------------------------------------------
	EntControl::Police
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitPolice()
{
	PrecacheModel("models/police.mdl");
	PrecacheModel("models/weapons/w_stunbato.mdl");
	
	PrecacheSound("npc/metropolice/vo/freeman.wav");
	PrecacheSound("npc/metropolice/pain1.wav");
	PrecacheSound("npc/metropolice/die1.wav");
	PrecacheSound("weapons/stunstick/stunstick_impact1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Police
	------------------------------------------------------------------------------------------
*/
public Action:Command_Police(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	decl Float:position[3];
	if(GetPlayerEye(client, position))
		Police_Spawn(position, client);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Police_Spawn
	------------------------------------------------------------------------------------------
*/
stock Police_Spawn(Float:position[3], owner = 0)
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/police.mdl", PoliceSeekThink, "npc_police", "Idle_Baton");
	
	SDKHook(monster, SDKHook_OnTakeDamage, PoliceDamageHook);
	
	CreateTimer(10.0, PoliceIdleThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	if (owner)
		BaseNPC_SetOwner(monster, owner);
	
	decl String:tmp[32];
	GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
	new monster_tmp = StringToInt(tmp);
	
	new weapon = CreateEntityByName("prop_dynamic_ornament");
	DispatchKeyValue(weapon, "model", "models/weapons/w_stunbaton.mdl");
	DispatchKeyValue(weapon, "classname", "stunstick");
	DispatchSpawn(weapon);
	
	decl String:entIndex[6];
	IntToString(EntIndexToEntRef(weapon), entIndex, sizeof(entIndex)-1);
	DispatchKeyValue(monster_tmp, "targetname", entIndex);
	
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetParent");
	SetVariantString(entIndex);
	AcceptEntityInput(weapon, "SetAttached");
}

/* 
	------------------------------------------------------------------------------------------
	PoliceAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:PoliceSeekThink(Handle:timer, any:monsterRef)
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
			if ((GetVectorDistance(vClientPosition, vEntPosition, false) < 120.0))
			{
				BaseNPC_SetAnimation(monster, "swing");
				
				BaseNPC_HurtPlayer(monster, target, 30, 120.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "weapons/stunstick/stunstick_impact1.wav");
			}
			else
			{
				BaseNPC_SetAnimation(monster, "walk_hold_baton_angry");
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "Idle_Baton");
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}


/* 
	------------------------------------------------------------------------------------------
	PoliceIdleThink
	------------------------------------------------------------------------------------------
*/
public Action:PoliceIdleThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		BaseNPC_PlaySound(monster, "npc/metropolice/vo/freeman.wav");
		
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
public Action:PoliceDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/metropolice/pain1.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, PoliceDamageHook);

		BaseNPC_Death(monster, attacker);

		BaseNPC_PlaySound(monster, "npc/metropolice/die1.wav");
	}
	
	return (Plugin_Handled);
}