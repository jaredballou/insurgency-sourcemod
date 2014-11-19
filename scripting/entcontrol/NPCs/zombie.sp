/* 
	------------------------------------------------------------------------------------------
	EntControl::Zombie
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitZombie()
{
	PrecacheModel("models/Zombie/Classic.mdl");
	PrecacheSound("npc/zombie/zombie_die1.wav");
	PrecacheSound("npc/zombie/claw_miss1.wav");
	
	PrecacheSound("npc/zombie/foot1.wav");
	PrecacheSound("npc/zombie/foot2.wav");
	PrecacheSound("npc/zombie/foot3.wav");
	
	decl String:sound[48];
	for (new i = 1; i <= 14; i++)
	{
		Format(sound, sizeof(sound), "npc/zombie/zombie_voice_idle%i.wav", i);
		PrecacheSound(sound);
	}
	
	for (new i = 1; i <= 6; i++)
	{
		Format(sound, sizeof(sound), "npc/zombie/zombie_pain%i.wav", i);
		PrecacheSound(sound);
	}
}

/*
	------------------------------------------------------------------------------------------
	Command_Zombie
	------------------------------------------------------------------------------------------
*/
public Action:Command_Zombie(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	new Float:position[3];
    	
	if(GetPlayerEye(client, position))
		Zombie_Spawn(position);
	else
		PrintHintText(client, "%t", "Wrong Position"); 

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Zombie_Spawn
	------------------------------------------------------------------------------------------
*/
public Zombie_Spawn(Float:position[3])
{
	// Spawn
	new monster = BaseNPC_Spawn(position, "models/Zombie/Classic.mdl", ZombieThink, "npc_zombie", "Idle01");
	
	SDKHook(monster, SDKHook_OnTakeDamage, ZombieDamageHook);
	
	CreateTimer(1.0, ZombieIdleThink, EntIndexToEntRef(monster), TIMER_FLAG_NO_MAPCHANGE);
}

/* 
	------------------------------------------------------------------------------------------
	ZombieAttackThink
	------------------------------------------------------------------------------------------
*/
public Action:ZombieThink(Handle:timer, any:monsterRef)
{
	#if defined DEBUG
		LogMessage("ZombieThink()::START");
	#endif
	
	new monster = EntRefToEntIndex(monsterRef);
	if (monster != INVALID_ENT_REFERENCE && BaseNPC_IsAlive(monster))
	{
		new target = BaseNPC_GetTarget(monster);
		decl Float:vClientPosition[3], Float:vEntPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		
		if (target > 0)
		{
			GetClientEyePosition(target, vClientPosition);
			new Float:distance = GetVectorDistance(vClientPosition, vEntPosition, false);
			if ((distance < 130.0) && BaseNPC_CanSeeEachOther(monster, target))
			{
				new Float:punchangle[3];
				
				BaseNPC_SetAnimationTime(monster);
				switch (GetRandomInt(0, 5))
				{
					case 0:
					{
						punchangle[0]=-30.0;
						punchangle[1]=-30.0;
						punchangle[2]=0.0;
						
						BaseNPC_SetAnimation(monster, "attackA");
						BaseNPC_PlaySound(monster, "npc/zombie/claw_miss1.wav", 0.7);
					}
					case 1:
					{
						punchangle[0]=-15.0;
						punchangle[1]=-30.0;
						punchangle[2]=0.0;
						
						BaseNPC_SetAnimation(monster, "attackB");
						BaseNPC_PlaySound(monster, "npc/zombie/claw_miss1.wav", 0.7);
					}
					case 2:
					{
						punchangle[0]=-15.0;
						punchangle[1]=30.0;
						punchangle[2]=0.0;
						
						BaseNPC_SetAnimation(monster, "attackC");
						BaseNPC_PlaySound(monster, "npc/zombie/claw_miss1.wav", 0.7);
					}
					case 3:
					{
						punchangle[0]=30.0;
						punchangle[1]=30.0;
						punchangle[2]=0.0;
						
						BaseNPC_SetAnimation(monster, "attackD");
						BaseNPC_PlaySound(monster, "npc/zombie/claw_miss1.wav", 0.7);
					} 
					case 4:
					{
						punchangle[0]=30.0;
						punchangle[1]=15.0;
						punchangle[2]=0.0;
						
						BaseNPC_SetAnimation(monster, "attackE");
						BaseNPC_PlaySound(monster, "npc/zombie/claw_miss1.wav", 0.7);
					}
					case 5:
					{
						punchangle[0]=30.0;
						punchangle[1]=-15.0;
						punchangle[2]=0.0;
						
						BaseNPC_SetAnimation(monster, "attackF");
						BaseNPC_PlaySound(monster, "npc/zombie/claw_miss1.wav");
					}
					default:
						LogError("Zombie:ZombieSeekThink - Attack -> Wrong Random");
				}
				
				BaseNPC_HurtPlayer(monster, target, 30, 120.0, punchangle, 0.5);
			}
			else
			{
				switch (GetRandomInt(0, 3))
				{
					case 0:
					{
						BaseNPC_SetAnimation(monster, "walk", 2.5);
						BaseNPC_PlaySound(monster, "npc/zombie/foot1.wav");
					}
					case 1:
					{
						BaseNPC_SetAnimation(monster, "walk2", 3.0);
						BaseNPC_PlaySound(monster, "npc/zombie/foot2.wav");
					}
					case 2:
					{
						BaseNPC_SetAnimation(monster, "walk3", 3.0);
						BaseNPC_PlaySound(monster, "npc/zombie/foot3.wav");
					}
					case 3:
					{
						BaseNPC_SetAnimation(monster, "walk4", 3.0);
						BaseNPC_PlaySound(monster, "npc/zombie/foot3.wav");
					}
					default:
						LogError("Zombie:ZombieSeekThink - Idle -> Wrong Random");
				}
			}
		}
		else
		{
			BaseNPC_SetAnimation(monster, "Idle01", 3.0);
		}

		#if defined DEBUG
			LogMessage("ZombieThink()::REPEAT");
		#endif

		return (Plugin_Continue);
	}
	else
	{
		#if defined DEBUG
			LogMessage("ZombieThink()::STOP_FINAL");
		#endif
		
		return (Plugin_Stop);
	}
}

	
/* 
	------------------------------------------------------------------------------------------
	ZombieIdleThink
	------------------------------------------------------------------------------------------
*/
public Action:ZombieIdleThink(Handle:timer, any:monsterRef)
{	
	#if defined DEBUG
		LogMessage("ZombieIdleThink()::START");
	#endif
	
	new monster = EntRefToEntIndex(monsterRef);
	if (monster != INVALID_ENT_REFERENCE && notBetweenRounds && BaseNPC_IsAlive(monster))
	{
		decl Float:vEntPosition[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);

		decl String:soundfile[48];
		Format(soundfile, sizeof(soundfile), "npc/zombie/zombie_voice_idle%i.wav", GetRandomInt(1, 14));

		BaseNPC_PlaySound(monster, soundfile);
		
		CreateTimer(GetRandomFloat(1.0, 10.0), ZombieIdleThink, EntIndexToEntRef(monster), TIMER_FLAG_NO_MAPCHANGE);
		
		#if defined DEBUG
			LogMessage("ZombieIdleThink()::REPEAT");
		#endif
		
		return (Plugin_Stop);
	}
	
	#if defined DEBUG
		LogMessage("ZombieIdleThink()::STOP");
	#endif
	
	return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	ZombieDamageHook
	------------------------------------------------------------------------------------------
*/
public Action:ZombieDamageHook(monster, &attacker, &inflictor, &Float:damage, &damagetype)
{
	BaseNPC_SetAnimation(monster, "physflinch1");
	
	decl String:soundfile[32];
	Format(soundfile, sizeof(soundfile), "npc/zombie/zombie_pain%i.wav", GetRandomInt(1, 6));
	
	if (BaseNPC_Hurt(monster, attacker, RoundToZero(damage), soundfile))
	{
		SDKUnhook(monster, SDKHook_OnTakeDamage, ZombieDamageHook);

		BaseNPC_PlaySound(monster, "npc/zombie/zombie_die1.wav");
	}
	
	return (Plugin_Handled);
}