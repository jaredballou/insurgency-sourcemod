/* 
	------------------------------------------------------------------------------------------
	EntControl::SentryGun
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitSentryGun()
{
	PrecacheModel("models/Combine_turrets/Floor_turret.mdl");
	PrecacheSound("weapons/ar2/fire1.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Sentry
	Spawns the Sentrygun
	------------------------------------------------------------------------------------------
*/
public Action:Command_Sentry(client, args)
{
	if (!CanUseCMD(client, gAdminFlagNPC)) return (Plugin_Handled);
	
	decl Float:position[3];
	if(GetPlayerEye(client, position))
		Sentry_Spawn(position, client);
	else
		PrintHintText(client, "%t", "Wrong Position");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Sentry_Spawn
	Spawns the Sentrygun
	------------------------------------------------------------------------------------------
*/
stock Sentry_Spawn(Float:position[3], owner = 0)
{
	// Spawn
	new entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "physdamagescale", "0.0");
	DispatchKeyValue(entity, "model", "models/Combine_turrets/Floor_turret.mdl");
	DispatchKeyValue(entity, "classname", "npc_sentrygun");
	DispatchSpawn(entity);
	
	SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	SetEntityModel(entity, "models/Combine_turrets/Floor_turret.mdl");
	
	TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
	
	SetEntProp(entity, Prop_Data, "m_iHealth", 150);
	
	CreateTimer(0.1, SentrySeekThink, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	if (owner)
		BaseNPC_SetOwner(entity, owner);
	
	SDKHook(entity, SDKHook_OnTakeDamage, SentryDamageHook);
}

/* 
	------------------------------------------------------------------------------------------
	SentrySeekThink
	------------------------------------------------------------------------------------------
*/
public Action:SentrySeekThink(Handle:timer, any:entityRef)
{
	new entity = EntRefToEntIndex(entityRef);
	
	if (entity != INVALID_ENT_REFERENCE && BaseNPC_IsAlive(entity))
	{
		new Float:vAngle[3], Float:anglevector[3], Float:vEntPosition[3];
		
		if (FindFirstTargetInRange(entity, vAngle, vEntPosition) != -1)
		{
			Projectile(false, BaseNPC_GetOwner(entity), vEntPosition, vAngle, "models/weapons/w_missile_launch.mdl", gBulletSpeed, gBulletDamage, "weapons/ar2/fire1.wav");

			TeleportEntity(entity, NULL_VECTOR, vAngle, NULL_VECTOR);
			
			GetAngleVectors(vAngle, anglevector, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(anglevector, anglevector);
			ScaleVector(anglevector, 20.0);
			AddVectors(vEntPosition, anglevector, vEntPosition);

			vEntPosition[2] -= 5.0;
			TE_SetupGlowSprite(vEntPosition, gMuzzle1, 0.1, 0.25, 255);
			TE_SendToAll();
		}
			
		return (Plugin_Continue);
	}
	else
		return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	SentryDamageHook
	------------------------------------------------------------------------------------------
*/
public Action:SentryDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new health = GetEntProp(entity, Prop_Data, "m_iHealth");
	health -= RoundToZero(damage);
	
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
	
	if (health <= 0)
		SentryActive(entity);

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	SentryActive
	------------------------------------------------------------------------------------------
*/
stock SentryActive(entity)
{
	SDKUnhook(entity, SDKHook_OnTakeDamage, SentryDamageHook);

	if(IsValidEntity(entity) && IsValidEdict(entity))
	{
		decl Float:vEntPosition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntPosition);

		RemoveEntity(entity);
		vEntPosition[2] += 15.0;

		makeexplosion(fakeClient, -1, vEntPosition, "", 100);
	}
}