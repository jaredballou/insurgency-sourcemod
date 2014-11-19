/* 
	------------------------------------------------------------------------------------------
	EntControl::Barney
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitBarney()
{
	PrecacheModel("models/barney.mdl");
	PrecacheModel("models/weapons/w_pistol.mdl");
	
	PrecacheSound("vo/npc/Barney/ba_laugh01.wav");
	PrecacheSound("vo/npc/Barney/ba_laugh02.wav");
	PrecacheSound("vo/npc/Barney/ba_oldtimes.wav");
	PrecacheSound("vo/npc/Barney/ba_pain09.wav");
	PrecacheSound("vo/npc/Barney/ba_no01.wav");
	PrecacheSound("vo/npc/Barney/ba_losttouch.wav");
	PrecacheSound("weapons/deagle/deagle-1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Barney
	------------------------------------------------------------------------------------------
*/
public Action:Command_Barney(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	decl Float:position[3];
	if (GetPlayerEye(client, position))
		Barney_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Barney_Spawn
	------------------------------------------------------------------------------------------
*/
public Barney_Spawn(Float:position[3])
{
	new monster = BaseNPC_Spawn(position, "models/barney.mdl", BarneySeekThink, "npc_barney", "wave");
	
	SDKHook(monster, SDKHook_OnTakeDamage, BarneyDamageHook);
	
	CreateTimer(10.0, BarneyIdleThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	SDKHook(monster, SDKHook_Touch, Barney_Touch);
}

/* 
	------------------------------------------------------------------------------------------
	Barney_Touch
	------------------------------------------------------------------------------------------
*/
public Action:Barney_Touch(monster, other)
{
	if (other)
	{
		decl String:tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		new monster_tmp = StringToInt(tmp);
			
		decl String:targetname[32];
		GetEntPropString(monster_tmp, Prop_Data, "m_iName", targetname, sizeof(targetname));
		
		if (StrEqual(targetname, ""))
		{
			new String:edictname[32];
			GetEdictClassname(other, edictname, 32);

			if (StrEqual("weapon_deagle", edictname) || StrEqual("func_buyzone", edictname))
			{
				new weapon = CreateEntityByName("prop_dynamic_ornament");
				DispatchKeyValue(weapon, "model", "models/weapons/w_pistol.mdl");
				DispatchKeyValue(weapon, "classname", "Deagle");
				DispatchSpawn(weapon);
				
				decl String:entIndex[6];
				IntToString(weapon, entIndex, sizeof(entIndex)-1);
				
				DispatchKeyValue(monster_tmp, "targetname", entIndex);
				
				SetVariantString(entIndex);
				AcceptEntityInput(weapon, "SetParent");
				SetVariantString(entIndex);
				AcceptEntityInput(weapon, "SetAttached");
				
				BaseNPC_SetAnimation(monster, "pickup");
				
				if (StrEqual("weapon_deagle", edictname))
					RemoveEntity(other);
			}
			else if (StrEqual("func_breakable", edictname) || StrEqual("func_breakable_surf", edictname))
			{
				BaseNPC_SetAnimation(monster, "swing");
				
				BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_losttouch.wav");
				
				AcceptEntityInput(other, "Break");
			}
			else if (StrEqual(edictname, "prop_physics")
				|| StrEqual(edictname, "prop_physics_multiplayer")
				|| StrEqual(edictname, "func_physbox")
				|| StrEqual(edictname, "player")
				|| StrEqual(edictname, "phys_magnet"))
			{
				decl String:entIndex[6];
				IntToString(other, entIndex, sizeof(entIndex)-1);
				
				DispatchKeyValue(monster_tmp, "targetname", entIndex);
				DispatchKeyValue(other, "classname", entIndex);
				
				IntToString(monster_tmp, entIndex, sizeof(entIndex)-1);
				SetVariantString(entIndex);
				AcceptEntityInput(other, "SetParent");
				SetVariantString(entIndex);
				AcceptEntityInput(other, "SetAttached");
				
				BaseNPC_SetAnimation(monster, "pickup");
			}
		}
	}

	return (Plugin_Continue);
}

/* 
	------------------------------------------------------------------------------------------
	BarneyAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:BarneySeekThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		decl String:tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		new monster_tmp = StringToInt(tmp);
		
		new target = BaseNPC_GetTarget(monster);
		decl Float:vClientPosition[3], Float:vEntPosition[3], Float:vAngle[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			
			decl String:targetname[32];
			GetEntPropString(monster_tmp, Prop_Data, "m_iName", targetname, sizeof(targetname));
			new Float:distance = GetVectorDistance(vClientPosition, vEntPosition, false);
			
			decl String:weaponClass[32];
			GetEdictClassname(StringToInt(targetname), weaponClass, 16);
			
			if (distance < 120.0 && BaseNPC_CanSeeEachOther(monster, target))
			{				
				BaseNPC_SetAnimation(monster, "swing");
				
				BaseNPC_HurtPlayer(monster, target, 15, 120.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_laugh02.wav");
			}
			else if (distance < 800.0 && StrEqual(weaponClass, "Deagle") && BaseNPC_CanSeeEachOther(monster, target))
			{
				BaseNPC_SetAnimation(monster, "shootp1");
				
				BaseNPC_HurtPlayer(monster, target, 30, 800.0, NULL_FLOAT_VECTOR, 0.5);
				
				BaseNPC_PlaySound(monster, "weapons/deagle/deagle-1.wav", 0.5);
				
				BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_laugh01.wav");
				
				SetEntityMoveType(monster, MOVETYPE_NONE);
				
				// Muzzle
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				GetVectorAngles(vAngle, vAngle);

				GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vAngle, vAngle);
				ScaleVector(vAngle, 20.0);
				AddVectors(vEntPosition, vAngle, vEntPosition);

				vEntPosition[2] -= 50.0;
				TE_SetupGlowSprite(vEntPosition, gMuzzle1, 1.1, 1.25, 255);
				TE_SendToAll();
			}
			else if (!StrEqual(targetname, "") && !StrEqual(weaponClass, "Deagle"))
			{
				new prop = StringToInt(targetname);
				BaseNPC_SetAnimation(monster, "throw1");
				AcceptEntityInput(prop, "ClearParent");
	
				DispatchKeyValue(monster_tmp, "targetname", "");
				DispatchKeyValue(prop, "classname", "prop_physics_multiplayer");
				
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				NormalizeVector(vAngle, vAngle);
				ScaleVector(vAngle, 5000.0);

				TeleportEntity(prop, NULL_VECTOR, NULL_VECTOR, vAngle);
			}
			else
			{
				if (StrEqual(targetname, ""))
					BaseNPC_SetAnimation(monster, "run_all");
				else
					BaseNPC_SetAnimation(monster, "run_holding_all");
					
				SetEntityMoveType(monster, MOVETYPE_STEP);
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "idle_subtle");
		}
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	BarneyIdleThink
	------------------------------------------------------------------------------------------
*/
public Action:BarneyIdleThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEntity(monster))
	{
		decl Float:vEntPosition[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_oldtimes.wav");
		
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
public Action:BarneyDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "vo/npc/Barney/ba_pain09.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, BarneyDamageHook);

		BaseNPC_Death(monster, attacker);
		
		decl Float:position[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", position);
		BaseNPC_PlaySound(monster, "vo/npc/Barney/ba_no01.wav");
		
		SDKUnhook(monster, SDKHook_Touch, Barney_Touch);
	}
	
	return (Plugin_Handled);
}