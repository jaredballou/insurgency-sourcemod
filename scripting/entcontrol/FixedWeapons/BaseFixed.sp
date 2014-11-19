/* 
	------------------------------------------------------------------------------------------
	EntControl::FixedBase
	by Raffael 'LeGone' Holz
	
	Thanks to blodia (http://forums.alliedmods.net/showthread.php?t=129597)
	------------------------------------------------------------------------------------------
*/


#include "FixedWeapons/mg.sp"
#include "FixedWeapons/plasma.sp"
#include "FixedWeapons/rocket.sp"

public FixedBase_Init()
{
	PrecacheModel("models/props_combine/bunker_gun01.mdl");
	
	InitFixedMG();
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_Base_Spawn
	------------------------------------------------------------------------------------------
*/
public Fixed_Base_Spawn(client, Function:OnTriggerFunc, Float:vAimPos[3])
{
	new gun = CreateEntityByName("prop_dynamic");
	SetEntityModel(gun, "models/props_combine/bunker_gun01.mdl");
	DispatchKeyValue(gun, "classname", "weapon_fixedgun");
	DispatchSpawn(gun);	
	
	TeleportEntity(gun, vAimPos, NULL_VECTOR, NULL_VECTOR);
	
	// Spawn
	new trigger = CreateEntityByName("trigger_multiple");
	TeleportEntity(trigger, vAimPos, NULL_VECTOR, NULL_VECTOR);
	if (trigger != -1)
	{
		//DispatchKeyValue(trigger, "start", "-200 -200 0");
		//DispatchKeyValue(trigger, "end", "200 200 100");
		DispatchKeyValue(trigger, "spawnflags", "1");
		
		decl String:entIndex[6];
		IntToString(gun, entIndex, sizeof(entIndex)-1);
		DispatchKeyValue(trigger, "targetname", entIndex);
	}

	DispatchSpawn(trigger);
	ActivateEntity(trigger);

	AcceptEntityInput(trigger, "Enable");
	
	// WTF?! xD
	SetEntityModel(trigger, "models/props_combine/bunker_gun01.mdl");

	new Float:minbounds[3] = {-50.0, -50.0, 0.0};
	new Float:maxbounds[3] = {50.0, 50.0, 50.0};
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxbounds);

	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
	
	/*
	new enteffects = GetEntProp(trigger, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(trigger, Prop_Send, "m_fEffects", enteffects);
	*/
	
	DrawBoundingBox(trigger, client);
	
	HookSingleEntityOutput(trigger, "OnTrigger", OnTriggerFunc, false);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_Base_Think
	------------------------------------------------------------------------------------------
*/
public Fixed_Base_Think(gun, client, Function:func)
{
	new Float:vAngle[3], Float:vOrigin[3], Float:vAimPos[3], Float:vGunPos[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngle);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngle, MASK_VISIBLE, RayType_Infinite, TraceASDF, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vAimPos, trace);
		new target = TR_GetEntityIndex(trace);
		CloseHandle(trace);
		
		GetEntPropVector(gun, Prop_Send, "m_vecOrigin", vGunPos);
		
		vGunPos[2] += 7.0;
		MakeVectorFromPoints(vGunPos, vAimPos, vAngle);
		GetVectorAngles(vAngle, vAngle);
		
		TeleportEntity(gun, NULL_VECTOR, vAngle, NULL_VECTOR);
		
		if (target)
			TE_SetupBeamPoints(vGunPos, vAimPos, gLaser1, 0, 0, 0, 0.25, 1.0, 1.0, 0, 0.0, {0, 255, 0, 255}, 0);
		else
			TE_SetupBeamPoints(vGunPos, vAimPos, gLaser1, 0, 0, 0, 0.25, 1.0, 1.0, 0, 0.0, {255, 0, 0, 255}, 0);
		TE_SendToAll();
		
		new button = GetClientButtons(client);
		if (button & IN_ATTACK)
		{
			// Tricky xD
			Call_StartFunction(GetMyHandle(), func);
			Call_PushCell(gun);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushArray(vGunPos, 3);
			Call_PushArray(vAimPos, 3);
			Call_PushArray(vAngle, 3);
			Call_Finish();
			
			SetVariantString("fire");
			AcceptEntityInput(gun, "SetAnimation");
			
			vGunPos[2] += 11.0;
			
			GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vAngle, vAngle);
			ScaleVector(vAngle, 20.0);
			AddVectors(vGunPos, vAngle, vGunPos);
			
			TE_SetupGlowSprite(vGunPos, gHalo1, 0.1, 0.5, 255);
			TE_SendToAll();

			new shake = CreateEntityByName("env_shake");
			
			if(DispatchSpawn(shake))
			{
				DispatchKeyValueFloat(shake, "amplitude", 12.0);
				DispatchKeyValueFloat(shake, "radius", 500.0);
				DispatchKeyValueFloat(shake, "duration", 0.5);
				DispatchKeyValueFloat(shake, "frequency", 200.0);
				
				AcceptEntityInput(shake, "StartShake");
				
				TeleportEntity(shake, vGunPos, NULL_VECTOR, NULL_VECTOR);

				RemoveEntity(shake, 0.5);
			}
			
			sendfademsg(client, 25, 25, FFADE_OUT, 255, 255, 255, 25);
		}
	}
}