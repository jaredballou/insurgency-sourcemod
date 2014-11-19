/* 
	------------------------------------------------------------------------------------------
	EntControl::Synth
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitSynth()
{
	PrecacheModel("models/synth.mdl");
	PrecacheModel("models/manhack.mdl");

	PrecacheSound("npc/manhack/bat_away.wav");
	PrecacheSound("npc/manhack/gib.wav");
	PrecacheSound("npc/strider/striderx_die1.wav");
	PrecacheSound("npc/strider/striderx_pain2.wav");
	
	new String:sound[37];
	for (new i = 1; i <= 6; i++)
	{
		Format(sound, sizeof(sound), "npc/strider/strider_step%i.wav", i);
		PrecacheSound(sound);
	}
}

/*
	------------------------------------------------------------------------------------------
	Command_Synth
	------------------------------------------------------------------------------------------
*/
public Action:Command_Synth(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	new Float:position[3];
	if (GetPlayerEye(client, position))
		Synth_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Synth_Spawn
	------------------------------------------------------------------------------------------
*/
public Synth_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/synth.mdl", SynthThink, "npc_synth", "idle01");
	SetEntityMoveType(monster, MOVETYPE_NONE);
	
	SDKHook(monster, SDKHook_OnTakeDamage, Synth_DamageHook);
}

/* 
	------------------------------------------------------------------------------------------
	SynthAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:SynthThink(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE && BaseNPC_IsAlive(monster))
	{
		new target = BaseNPC_GetTarget(monster);
		new Float:vClientPosition[3], Float:vEntPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			new random = GetRandomInt(0, 3);
			if (random == 1)
			{
				SetEntityMoveType(monster, MOVETYPE_NONE);
				BaseNPC_SetAnimation(monster, "chargeend", 0.87);
				
				DrawIonBeam(vEntPosition);
				TE_SetupBeamRingPoint(vEntPosition, 0.0, 1000.0, gGlow1, gHalo1, 0, 0, 0.5, 20.0, 4.0, {255, 255, 255, 255}, 0, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(vEntPosition, 0.0, 1000.0, gGlow1, gHalo1, 0, 0, 0.7, 20.0, 4.0, {255, 255, 255, 255}, 0, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(vEntPosition, 0.0, 1000.0, gGlow1, gHalo1, 0, 0, 0.9, 20.0, 4.0, {255, 255, 255, 255}, 0, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(vEntPosition, 0.0, 1000.0, gGlow1, gHalo1, 0, 0, 1.4, 20.0, 4.0, {255, 255, 255, 255}, 0, 0);
				TE_SendToAll();

				// Light
				new ent = CreateEntityByName("light_dynamic");

				DispatchKeyValue(ent, "_light", "120 120 255 255");
				DispatchKeyValue(ent, "brightness", "5");
				DispatchKeyValueFloat(ent, "spotlight_radius", 1000.0);
				DispatchKeyValueFloat(ent, "distance", 1000.0);
				DispatchKeyValue(ent, "style", "6");
				
				// SetEntityMoveType(ent, MOVETYPE_NOCLIP); 
				DispatchSpawn(ent);
				AcceptEntityInput(ent, "TurnOn");
				
				TeleportEntity(ent, vEntPosition, NULL_VECTOR, NULL_VECTOR);
				
				RemoveEntity(ent, 0.5);
				
				vEntPosition[2] += 15.0;
				//makeexplosion(IsClientConnectedIngame(client) ? client : 0, -1, vEntPosition, "", 300);
				
				env_shake(vEntPosition, 120.0, 1000.0, 3.0, 250.0);
				
				EmitSoundToAll("weapons/physcannon/energy_disintegrate4.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
				
				// Knockback
				new Float:vReturn[3], Float:dist;
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
					{	
						GetClientEyePosition(i, vClientPosition);

						dist = GetVectorDistance(vClientPosition, vEntPosition, false);
						if (dist < 1000.0/* && BaseNPC_CanSeeEachOther(monster, i)*/)
						{
							MakeVectorFromPoints(vEntPosition, vClientPosition, vReturn);
							NormalizeVector(vReturn, vReturn);
							ScaleVector(vReturn, 5000.0);

							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vReturn);
						}
					}
				}
			}
			else if (random == 2)
			{
				/*
				CreateTimer(0.0, Synth_Shoot_Bullet_Timer, monster, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.5, Synth_Shoot_Bullet_Timer, monster, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, Synth_Shoot_Bullet_Timer, monster, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.5, Synth_Shoot_Bullet_Timer, monster, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.9, Synth_Shoot_Bullet_Timer, monster, TIMER_FLAG_NO_MAPCHANGE);
				*/
				
				SetEntityMoveType(monster, MOVETYPE_NONE);
				BaseNPC_SetAnimation(monster, "chargeend", 0.87);
				
				Synth_RocketAttack(monster);
			}
			else if (random == 3)
			{
				SetEntityMoveType(monster, MOVETYPE_NONE);
				BaseNPC_SetAnimation(monster, "chargeend", 0.87);
				
				Synth_Manhack(monster);
				
				BaseNPC_PlaySound(monster, "npc/manhack/gib.wav");
			}
			else
			{
				SetEntityMoveType(monster, MOVETYPE_STEP);
				BaseNPC_SetAnimation(monster, "walk01", 1.97);
				decl String:soundfile[40];
				Format(soundfile, sizeof(soundfile), "npc/strider/strider_step%i.wav", GetRandomInt(1, 6));

				BaseNPC_PlaySound(monster, soundfile);
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "idle01", 6.16);
		}
		
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	Synth_Shoot_Bullet_Timer
	------------------------------------------------------------------------------------------
*/
public Action:Synth_Shoot_Bullet_Timer(Handle:timer, any:monsterRef)
{
	new monster = EntRefToEntIndex(monsterRef);
	
	if (monster != INVALID_ENT_REFERENCE)
	{
		new target = BaseNPC_GetTarget(monster);
		new Float:vAngle[3];
		new Float:vClientPosition[3], Float:vEntPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);

			vClientPosition[2] -= 10.0;
			MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
			vClientPosition[2] += 10.0;
			//NormalizeVector(vAngle, vAngle);
			GetVectorAngles(vAngle, vAngle);

			Projectile(false, BaseNPC_GetOwner(monster), vEntPosition, vAngle, "models/weapons/w_missile_launch.mdl", gBulletSpeed, gBulletDamage, "weapons/ar2/fire1.wav");
			
			vEntPosition[2] -= 5.0;
			TE_SetupGlowSprite(vEntPosition, gMuzzle1, 0.1, 0.25, 255);
			TE_SendToAll();
		}
	}
}

/* 
	------------------------------------------------------------------------------------------
	Synth_RocketAttack
	Shoots the Synth´s rocket
	------------------------------------------------------------------------------------------
*/
stock Synth_RocketAttack(monster)
{
	new Float:vAngle[3], Float:vEntPosition[3], Float:vClientPosition[3], entity;
	new target = BaseNPC_GetTarget(monster);
	
	GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
	GetClientEyePosition(target, vClientPosition);
	
	vEntPosition[2] += 45;
	
	vClientPosition[2] -= 10.0;
	MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
	GetVectorAngles(vAngle, vAngle);

	Projectile(false, BaseNPC_GetOwner(entity), vEntPosition, vAngle, "models/weapons/w_missile_launch.mdl", gRocketSpeed, gRocketDamage, "weapons/rpg/rocketfire1.wav", true);
}

/* 
	------------------------------------------------------------------------------------------
	Synth_Manhack
	Shoots the Synth´s Manhack
	------------------------------------------------------------------------------------------
*/
stock Synth_Manhack(monster)
{
	new Float:vAngle[3], Float:vAngleVector[3], Float:vResultPosition[3], Float:vEntPosition[3], Float:vClientPosition[3], entity;
	new target = BaseNPC_GetTarget(monster);
	
	GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
	GetClientEyePosition(target, vClientPosition);
	
	vEntPosition[2] += 45;
	
	vClientPosition[2] -= 10.0;
	MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
	GetVectorAngles(vAngle, vAngle);
	GetAngleVectors(vAngle, vAngleVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngleVector, vAngleVector);
	ScaleVector(vAngleVector, 100.0);
	AddVectors(vEntPosition, vAngleVector, vResultPosition);
	NormalizeVector(vAngleVector, vAngleVector);
	ScaleVector(vAngleVector, 300.0);

	entity = CreateEntityByName("hegrenade_projectile");
	
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", monster);
	
	setm_takedamage(entity, DAMAGE_YES);
	DispatchKeyValue(entity, "DefaultAnim", "fly");
	DispatchSpawn(entity);

	SetEntityModel(entity, "models/manhack.mdl");
	
	TeleportEntity(entity, vResultPosition, vAngle, vAngleVector);

	SDKHook(entity, SDKHook_StartTouch, Synth_ManhackTouchHook);
	SDKHook(entity, SDKHook_OnTakeDamage, Synth_ManhackDamageHook);

	CreateTimer(0.5, Synth_ManhackSeekThink, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	SetEntityMoveType(entity, MOVETYPE_FLY);
}

public Action:Synth_ManhackTouchHook(entity, other)
{
	if(other/* && IsEntityCollidable(other, true, true, true)*/)
		Synth_ManhackExplode(entity);

	return (Plugin_Continue);
}

public Action:Synth_ManhackDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype)
{
	Synth_ManhackJustDie(entity);

	return (Plugin_Continue);
}

public Action:Synth_ManhackSeekThink(Handle:Timer, any:entityRef)
{
	new entity = EntRefToEntIndex(entityRef);
	
	if (entity != INVALID_ENT_REFERENCE && IsValidEdict(entity) && IsValidEntity(entity))
	{
		new monster = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (IsValidEdict(monster) && IsValidEntity(monster))
		{
			new target = BaseNPC_GetTarget(monster);
			if (target > 0 && BaseNPC_CanSeeEachOther(entity, target))
			{
				new Float:vEntPosition[3], Float:vClientPosition[3], Float:vAngle[3], Float:vAngleVector[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntPosition);
				GetClientEyePosition(target, vClientPosition);
				
				MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
				GetVectorAngles(vAngle, vAngle);
				GetAngleVectors(vAngle, vAngleVector, NULL_VECTOR, NULL_VECTOR);
				AddVectors(vEntPosition, vAngleVector, vClientPosition);
				NormalizeVector(vAngleVector, vAngleVector);
				ScaleVector(vAngleVector, 300.0);
				
				TE_SetupGlowSprite(vEntPosition, gGlow1, 0.2, 0.5, 255);
				TE_SendToAll();
			
				TeleportEntity(entity, NULL_VECTOR, vAngle, vAngleVector);
				
				BaseNPC_PlaySound(entity, "npc/manhack/bat_away.wav");
			}
			
			return (Plugin_Continue);
		}
		else
			RemoveEntity(entity);
	}

	return (Plugin_Stop);
}

stock Synth_ManhackExplode(entity)
{
	SDKUnhook(entity, SDKHook_StartTouch, Synth_ManhackTouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, Synth_ManhackDamageHook);

	if(IsValidEdict(entity) && IsValidEntity(entity))
	{
		new Float:vEntPosition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntPosition);

		RemoveEntity(entity);
		vEntPosition[2] = vEntPosition[2] + 15.0;

		makeexplosion(0, -1, vEntPosition, "", 200);

		EmitSoundToAll("weapons/explode3.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
	}
}

stock Synth_ManhackJustDie(entity)
{
	SDKUnhook(entity, SDKHook_StartTouch, Synth_ManhackTouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, Synth_ManhackDamageHook);

	if(IsValidEdict(entity) && IsValidEntity(entity))
		RemoveEntity(entity);
}

/* 
	------------------------------------------------------------------------------------------
	Synth_DamageHook
	------------------------------------------------------------------------------------------
*/
public Action:Synth_DamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:classname[32];
	GetEdictClassname(attacker, classname, 32);
	
	if (StrEqual(classname, "player") && BaseNPC_Hurt(monster, attacker, RoundToZero(damage), "npc/strider/striderx_pain2.wav"))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, Synth_DamageHook);
		
		BaseNPC_PlaySound(monster, "npc/strider/striderx_die1.wav");
		BaseNPC_Dissolve(monster);
	}
	
	return (Plugin_Handled);
}