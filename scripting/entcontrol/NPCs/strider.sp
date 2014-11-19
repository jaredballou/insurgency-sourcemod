/* 
	------------------------------------------------------------------------------------------
	EntControl::Strider
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitStrider()
{
	PrecacheModel("models/Combine_Strider.mdl");
}

/*
	------------------------------------------------------------------------------------------
	Command_Strider
	------------------------------------------------------------------------------------------
*/
public Action:Command_Strider(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	decl Float:position[3];
    	
	if(GetPlayerEye(client, position))
		Strider_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Strider_Spawn
	------------------------------------------------------------------------------------------
*/
public Strider_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/Combine_Strider.mdl", StriderThink, "npc_strider", "default");
	
	SDKHook(monster, SDKHook_OnTakeDamage, StriderDamageHook);
	//MakeDamage(fakeClient, target, damage, DMG_ACID, 1.0, NULL_FLOAT_VECTOR);
	BaseNPC_SetAnimation(monster, "physflinch1");
}

/* 
	------------------------------------------------------------------------------------------
	StriderAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:StriderThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEdict(monster) && IsValidEntity(monster))
	{
		new Float:vEntPosition[3], Float:angles[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		// Bottom
		angles[0] = 90.0;
		angles[1] = 0.0;
		angles[2] = 0.0;
		new Handle:traceBottom = TR_TraceRayFilterEx(vEntPosition, angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterWall);

		if(TR_DidHit(traceBottom))
		{
			TR_GetEndPosition(vEntPosition, traceBottom);
			
			vEntPosition[2] += 250.0;
			TeleportEntity(monster, NULL_VECTOR, NULL_VECTOR, vEntPosition);
		}

		CloseHandle(traceBottom);
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	StriderDamageHook
	------------------------------------------------------------------------------------------
*/
public Action:StriderDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:soundfile[32];
	Format(soundfile, sizeof(soundfile), "npc/strider/strider_pain%i.wav", GetRandomInt(1, 6));
	
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), soundfile))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, StriderDamageHook);
		
		BaseNPC_PlaySound(monster, "npc/strider/strider_die1.wav");
	}
	
	return (Plugin_Handled);
}