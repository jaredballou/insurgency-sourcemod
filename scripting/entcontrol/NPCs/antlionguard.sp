/* 
	------------------------------------------------------------------------------------------
	EntControl::AntLionGuard
	by Raffael 'LeGone' Holz
	
	Flames by <eVa>Dog
	------------------------------------------------------------------------------------------
*/

public InitAntlionGuard()
{
	PrecacheModel("models/antlion_guard.mdl");
	PrecacheSound("npc/antlion_guard/foot_heavy2.wav");
	PrecacheSound("npc/antlion_guard/growl_idle.wav");
	PrecacheSound("npc/antlion_guard/angry1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_AntlionGuard
	------------------------------------------------------------------------------------------
*/
public Action:Command_AntlionGuard(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	decl Float:position[3];
	if(GetPlayerEye(client, position))
		AntLionGuard_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong entity"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	AntLionGuard_Spawn
	------------------------------------------------------------------------------------------
*/
public AntLionGuard_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/antlion_guard.mdl", AntlionGuardSeekThink, "npc_antlionguard", "idle");

	SDKHook(monster, SDKHook_OnTakeDamage, AntlionGuardDamageHook);

	CreateTimer(5.0, AntlionGuardFireThink, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/* 
	------------------------------------------------------------------------------------------
	AntlionGuardFireThink
	------------------------------------------------------------------------------------------
*/
public Action:AntlionGuardFireThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
		
	if (monster != INVALID_ENT_REFERENCE && BaseNPC_IsAlive(monster))
	{
		new target = BaseNPC_GetTarget(monster);
		if (target > 0)
		{
			new Float:vClientPosition[3], Float:vEntPosition[3], Float:vAngle[3];
			
			GetClientEyePosition(target, vClientPosition);
			GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
			vEntPosition[2] += 60.0;
			
			if (BaseNPC_CanSeeEachOther(monster, target, 500.0, 60.0))
			{
				BaseNPC_SetAnimation(monster, "fireattack");
				BaseNPC_SetAnimation(monster, "Run1", 0.0, 2.0);
				
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				NormalizeVector(vAngle, vAngle);
				GetVectorAngles(vAngle, vAngle);
		
				new String:tName[128];
				Format(tName, sizeof(tName), "target%i", monsterRef);
				
				// Create the Flame
				new String:flame_name[128];
				Format(flame_name, sizeof(flame_name), "Flame%i", monsterRef);
				new flame = CreateEntityByName("env_steam");
				DispatchKeyValue(flame,"targetname", flame_name);
				DispatchKeyValue(flame, "parentname", tName);
				DispatchKeyValue(flame,"SpawnFlags", "1");
				DispatchKeyValue(flame,"Type", "0");
				DispatchKeyValue(flame,"InitialState", "1");
				DispatchKeyValue(flame,"Spreadspeed", "10");
				DispatchKeyValue(flame,"Speed", "800");
				DispatchKeyValue(flame,"Startsize", "10");
				DispatchKeyValue(flame,"EndSize", "250");
				DispatchKeyValue(flame,"Rate", "15");
				DispatchKeyValue(flame,"JetLength", "400");
				DispatchKeyValue(flame,"RenderColor", "180 71 8");
				DispatchKeyValue(flame,"RenderAmt", "180");
				DispatchSpawn(flame);
				TeleportEntity(flame, vEntPosition, vAngle, NULL_VECTOR);
				SetVariantString(tName);
				AcceptEntityInput(flame, "SetParent", flame, flame, 0);

				SetVariantString("forward");
				AcceptEntityInput(flame, "SetParentAttachment", flame, flame, 0);
				AcceptEntityInput(flame, "TurnOn");

				// Create the Heat Plasma
				new String:flame_name2[128];
				Format(flame_name2, sizeof(flame_name2), "Flame2%i", monsterRef);
				new flame2 = CreateEntityByName("env_steam");
				DispatchKeyValue(flame2,"targetname", flame_name2);
				DispatchKeyValue(flame2, "parentname", tName);
				DispatchKeyValue(flame2,"SpawnFlags", "1");
				DispatchKeyValue(flame2,"Type", "1");
				DispatchKeyValue(flame2,"InitialState", "1");
				DispatchKeyValue(flame2,"Spreadspeed", "10");
				DispatchKeyValue(flame2,"Speed", "600");
				DispatchKeyValue(flame2,"Startsize", "50");
				DispatchKeyValue(flame2,"EndSize", "400");
				DispatchKeyValue(flame2,"Rate", "10");
				DispatchKeyValue(flame2,"JetLength", "500");
				DispatchSpawn(flame2);
				TeleportEntity(flame2, vEntPosition, vAngle, NULL_VECTOR);
				SetVariantString(tName);
				AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
				
				new Handle:flamedata;
				CreateDataTimer(1.0, KillFlame, flamedata);
				WritePackCell(flamedata, flame);
				WritePackCell(flamedata, flame2);
				WritePackCell(flamedata, monsterRef);
				
				IgniteEntity(target, 5.0, false, 1.5, false);
				
				SetEntityMoveType(monster, MOVETYPE_NONE);
			}
		}
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	KillFlame
	------------------------------------------------------------------------------------------
*/
public Action:KillFlame(Handle:timer, Handle:flamedata)
{
	ResetPack(flamedata);
	new ent1 = ReadPackCell(flamedata);
	new ent2 = ReadPackCell(flamedata);
	new monster = EntRefToEntIndex(ReadPackCell(flamedata));
	CloseHandle(flamedata);
	
	new String:classname[256];
	
	if (IsValidEdict(ent1) && IsValidEntity(ent1))
    {
		AcceptEntityInput(ent1, "TurnOff");
		GetEdictClassname(ent1, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
            RemoveEntity(ent1);
    }
	
	if (IsValidEdict(ent2) && IsValidEntity(ent2))
    {
		AcceptEntityInput(ent2, "TurnOff");
		GetEdictClassname(ent2, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
            RemoveEntity(ent2);
    }
	
	SetEntityMoveType(monster, MOVETYPE_STEP);
}

/* 
	------------------------------------------------------------------------------------------
	AntlionGuardSeekThink
	------------------------------------------------------------------------------------------
*/
public Action:AntlionGuardSeekThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && BaseNPC_IsAlive(monster))
	{
		new target = BaseNPC_GetTarget(monster);
		
		if (target > 0)
		{
			if (BaseNPC_CanSeeEachOther(monster, target, 120.0, 60.0))
			{
				BaseNPC_HurtPlayer(monster, target, 57);
				BaseNPC_PlaySound(monster, "npc/antlion_guard/foot_heavy2.wav");
				BaseNPC_SetAnimationTime(monster); // Will set the internal-blocking-timer to 0.0.
				BaseNPC_SetAnimation(monster, "physthrow", 1.4);
			}
			else
			{
				BaseNPC_SetAnimation(monster, "uprun1");
			}
		}
		else
		{
			BaseNPC_PlaySound(monster, "npc/antlion_guard/growl_idle.wav");
			BaseNPC_SetAnimation(monster, "idle", 12.8);
		}

		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	AntlionGuardDamageHook
	------------------------------------------------------------------------------------------
*/
public Action:AntlionGuardDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/antlion_guard/angry1.wav"))
		SDKUnhook(monster, SDKHook_OnTakeDamage, AntlionGuardDamageHook);
	
	return (Plugin_Handled);
}