/* 
	------------------------------------------------------------------------------------------
	EntControl::Stalker
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitStalker()
{
	PrecacheModel("models/stalker.mdl");
	
	PrecacheSound("npc/stalker/stalker_footstep_left1.wav");
	PrecacheSound("npc/stalker/stalker_footstep_left2.wav");
	PrecacheSound("npc/stalker/stalker_footstep_right1.wav");
	PrecacheSound("npc/stalker/stalker_footstep_right2.wav");
	
	PrecacheSound("weapons/gauss/fire1.wav");
	PrecacheSound("npc/stalker/go_alert2.wav");
	PrecacheSound("npc/stalker/go_alert2a.wav");
	PrecacheSound("npc/vort/attack_shoot.wav");
}

/*
	------------------------------------------------------------------------------------------
	Command_Stalker
	------------------------------------------------------------------------------------------
*/
public Action:Command_Stalker(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	new Float:position[3];
    
	if (GetPlayerEye(client, position))
		Stalker_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Stalker_Spawn
	------------------------------------------------------------------------------------------
*/
public Stalker_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/stalker.mdl", StalkerThink, "npc_stalker", "idle1");
	
	SDKHook(monster, SDKHook_OnTakeDamage, StalkerDamageHook);
}

/* 
	------------------------------------------------------------------------------------------
	StalkerAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:StalkerThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && IsValidEdict(monster) && IsValidEntity(monster))
	{
		new target = BaseNPC_GetTarget(monster);
		new Float:vClientPosition[3], Float:vEntPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			new random = GetRandomInt(0, 3);
			if (random == 0 && BaseNPC_CanSeeEachOther(monster, target))
			{
				//BaseNPC_SetAnimation(monster, "idle1");
				BaseNPC_PlaySound(monster, "weapons/gauss/fire1.wav");
				
				// Light
				new ent = CreateEntityByName("light_dynamic");

				DispatchKeyValue(ent, "_light", "255 0 0 255");
				DispatchKeyValue(ent, "brightness", "1");
				DispatchKeyValueFloat(ent, "spotlight_radius", 200.0);
				DispatchKeyValueFloat(ent, "distance", 200.0);
				DispatchKeyValue(ent, "style", "6");

				// SetEntityMoveType(ent, MOVETYPE_NOCLIP); 
				DispatchSpawn(ent);
				AcceptEntityInput(ent, "TurnOn");
			
				TeleportEntity(ent, vEntPosition, NULL_VECTOR, NULL_VECTOR);
				
				RemoveEntity(ent, 0.25);
				
				vEntPosition[2] += 60;
				vClientPosition[0] += GetRandomFloat(-25.0, 25.0);
				vClientPosition[1] += GetRandomFloat(-25.0, 25.0);
				vClientPosition[2] += GetRandomFloat(-25.0, 25.0);
				
				TE_SetupBeamPoints(vEntPosition, vClientPosition, gLaser1, 0, 0, 0, 0.25, 2.0, 2.0, 0, 0.1, {255, 0, 0, 255}, 3);
				TE_SendToAll();
				
				//makeexplosion(0, -1, vClientPosition, "", 20);
				BaseNPC_HurtPlayer(monster, target, 10, 1000.0, NULL_FLOAT_VECTOR);
				
				/*
				new Handle:data = CreateDataPack();
				WritePackCell(data, monster)
				WritePackCell(data, target);
				WritePackFloat(data, 0.0);
				WritePackFloat(data, vEntPosition[0]);
				WritePackFloat(data, vEntPosition[1]);
				WritePackFloat(data, vEntPosition[2]);
				WritePackFloat(data, vClientPosition[0]);
				WritePackFloat(data, vClientPosition[1]);
				WritePackFloat(data, vClientPosition[2]);
				
				CreateTimer(0.5, Stalker_Attack1_Timer, data, TIMER_FLAG_NO_MAPCHANGE);
				*/
			}
			else if ((random == 1 || random == 2)/* && BaseNPC_CanSeeEachOther(monster, target)*/)
			{
				new Float:vPosTop[3];
				for (new i = 0; i < 20; i++)
				{
					vEntPosition[0] = vClientPosition[0] + GetRandomFloat(-256.0, 256.0);
					vEntPosition[1] = vClientPosition[1] + GetRandomFloat(-256.0, 256.0);
					vEntPosition[2] = vClientPosition[2];
					
					// Top
					new Float:angles[3];
					angles[0] = -90.0;
					angles[1] = 0.0;
					angles[2] = 0.0;
					new Handle:traceTop = TR_TraceRayFilterEx(vEntPosition, angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

					if(TR_DidHit(traceTop))
					{
						TR_GetEndPosition(vPosTop, traceTop);
						CloseHandle(traceTop);
						
						// Bottom
						angles[0] = 90.0;
						angles[1] = 0.0;
						angles[2] = 0.0;
						new Handle:traceBottom = TR_TraceRayFilterEx(vEntPosition, angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

						if(TR_DidHit(traceBottom))
						{
							//This is the first function i ever saw that anything comes before the handle
							TR_GetEndPosition(vEntPosition, traceBottom);
							CloseHandle(traceBottom);
							
							break;
						}
						else
							CloseHandle(traceBottom);
					}
					else
						CloseHandle(traceTop);
				}
				
				BaseNPC_PlaySound(monster, "npc/vort/attack_shoot.wav");
				TeleportEntity(monster, vEntPosition, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				BaseNPC_SetAnimation(monster, "walk", 2.5);
				BaseNPC_PlaySound(monster, "npc/stalker/stalker_footstep_left1.wav");
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "idle1", 3.0);
		}
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	Stalker_Attack1_Timer
	------------------------------------------------------------------------------------------
*/
/*
public Action:Stalker_Attack1_Timer(Handle:timer, Handle:data)
{
	ResetPack(data);
	new Float:vEntPosition[3], Float:vClientPosition[3];
	new monster = ReadPackCell(data);
	new target = ReadPackCell(data);
	new Float:time = ReadPackFloat(data);
	vEntPosition[0] = ReadPackFloat(data);
	vEntPosition[1] = ReadPackFloat(data);
	vEntPosition[2] = ReadPackFloat(data);
	vClientPosition[0] = ReadPackFloat(data);
	vClientPosition[1] = ReadPackFloat(data);
	vClientPosition[2] = ReadPackFloat(data);
	
	if (BaseNPC_CanSeeEachOther(monster, target))
	{
		GetClientEyePosition(target, vClientPosition);
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		vEntPosition[2] += 60;
	}
	
	vClientPosition[0] += GetRandomFloat(-15.0, 15.0);
	vClientPosition[1] += GetRandomFloat(-15.0, 15.0);
	vClientPosition[2] += GetRandomFloat(-15.0, 15.0);
	
	TE_SetupBeamPoints(vEntPosition, vClientPosition, gLaser1, 0, 0, 0, 0.25, 1.0, 1.0, 0, 0.1, {255, 0, 0, 255}, 3);
	TE_SendToAll();
	
	makeexplosion(0, -1, vClientPosition, "", 20);
	
	time += 0.5;
	if (time < 2.0)
	{
		new Handle:dataNew = CreateDataPack();
		WritePackCell(dataNew, monster)
		WritePackCell(dataNew, target);
		WritePackFloat(dataNew, time);
		WritePackFloat(dataNew, vEntPosition[0]);
		WritePackFloat(dataNew, vEntPosition[1]);
		WritePackFloat(dataNew, vEntPosition[2]);
		WritePackFloat(dataNew, vClientPosition[0]);
		WritePackFloat(dataNew, vClientPosition[1]);
		WritePackFloat(dataNew, vClientPosition[2]);
		
		CreateTimer(0.5, Stalker_Attack1_Timer, data, TIMER_FLAG_NO_MAPCHANGE);
	}
}
*/
/* 
	------------------------------------------------------------------------------------------
	StalkerDamageHook
	------------------------------------------------------------------------------------------
*/
public Action:StalkerDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/stalker/go_alert2.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, StalkerDamageHook);
		
		BaseNPC_PlaySound(monster, "npc/stalker/go_alert2a.wav");
	}
	
	return (Plugin_Handled);
}