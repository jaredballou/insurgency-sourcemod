/* 
	------------------------------------------------------------------------------------------
	EntControl::Portal
	by Raffael 'LeGone' Holz
	I stopped working on the camera part ... it´s currently (24.02.2012) not possible :-/
	------------------------------------------------------------------------------------------
*/

new gRedPortal;
new gPortalWarp;

public Portal_Init()
{
	PrecacheSound("ambient/energy/force_field_loop1.wav");
	PrecacheSound("beams/beamstart5.wav");
	
	gPortalWarp = PrecacheModel("materials/particle/warp1_warp.vmt");
	PrecacheModel("models/effects/portalrift.mdl");
}

public Portal_Shoot(client)
{
	new Float:vAimPos[3], Float:vAimAngle[3];
	if (GetPlayerEyeWithAngle(client, vAimPos, vAimAngle))
		Portal_Create(vAimPos, vAimAngle);
	else
		PrintToChat(client, "{fullred}Failed to create portal");
}

public Portal_Create(Float:vPos[3], Float:vAimAngle[3])
{
	new Float:vAngle[3];
	GetAngleVectors(vAimAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngle, vAngle);
	ScaleVector(vAngle, 5.0);
	AddVectors(vPos, vAngle, vPos);
	
	new portal = Portal_CreatePortal(vPos, vAimAngle);
	if (portal == -1)
		return;
	new cam = Portal_CreateCamera(vPos, vAimAngle);
	
	Portal_CreateInfoCameraLink(portal, cam);
}

public bool:Portal_EnoughSpaceForHuman(Float:vBluePortalPos[3], Float:vAimAngle[3])
{
	decl Float:vMin[3], Float:vMax[3]; 

	// To get the mods client-size
	GetClientMins(1, vMin); 
	GetClientMaxs(1, vMax); 

	new Float:vOrigin[3], Float:vAngle[3];
	vOrigin[0] = vBluePortalPos[0];
	vOrigin[1] = vBluePortalPos[1];
	vOrigin[2] = vBluePortalPos[2];
	vAngle[0] = vAimAngle[0];
	vAngle[1] = vAimAngle[1];
	vAngle[2] = vAimAngle[2];
	
	vAngle[0] = 90.0;
	vAngle[1] += 180.0;
	vAngle[0] = 0.0;
	vAngle[1] -= 180.0;
	GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngle, vAngle);
	ScaleVector(vAngle, 100.0);
	AddVectors(vOrigin, vAngle, vOrigin);

	TR_TraceHullFilter(vOrigin, vOrigin, vMin, vMax, MASK_SOLID, TraceHullForRoom);

	if (TR_DidHit())
	{
		TR_GetEndPosition(vAngle);
		
		TE_SetupBeamPoints(vOrigin, vAngle, gLaser1, 0, 0, 0, 2.0, 1.0, 1.0, 0, 0.0, {255, 0, 0, 255}, 0);
		TE_SendToAll();
		
		TE_SetupBeamPoints(vBluePortalPos, vOrigin, gLaser1, 0, 0, 0, 2.0, 1.0, 1.0, 0, 0.0, {0, 255, 0, 255}, 0);
		TE_SendToAll();
		
		TE_SetupBeamPoints(vBluePortalPos, vAngle, gLaser1, 0, 0, 0, 2.0, 1.0, 1.0, 0, 0.0, {0, 255, 0, 255}, 0);
		TE_SendToAll();
		return (false);
	}
	
	return (true);
}

public bool:TraceHullForRoom(entity, contentsMask) 
{ 
    return (true); 
}  

public Portal_CreatePortal(Float:vBluePortalPos[3], Float:vAimAngle[3])
{
	decl String:sPortal[6];

	if (!Portal_EnoughSpaceForHuman(vBluePortalPos, vAimAngle))
	{
		CPrintToChatAll("{orange}There is not enough room for creating portals!");
		return (-1);
	}

	new bluePortal = CreateEntityByName("prop_dynamic");
	if (bluePortal != -1)
	{
		IntToString(bluePortal, sPortal, sizeof(sPortal)-1);
		
		SetEntityModel(bluePortal, "models/effects/portalrift.mdl");
		DispatchKeyValue(bluePortal, "classname", sPortal);
		DispatchKeyValue(bluePortal, "targetname", sPortal);
		DispatchKeyValue(bluePortal, "disableshadows", "1");
		DispatchSpawn(bluePortal);
		
		SetVariantString("open");
		AcceptEntityInput(bluePortal, "SetAnimation");
		
		vAimAngle[0] = 90.0;
		vAimAngle[1] += 180.0;
		TeleportEntity(bluePortal, vBluePortalPos, vAimAngle, NULL_VECTOR);
		
		//CreateTimer(1.6, Portal_StopAnimation, EntIndexToEntRef(bluePortal), TIMER_FLAG_NO_MAPCHANGE);
		
		// Scale down the portal
		SetEntPropFloat(bluePortal, Prop_Send, "m_flModelScale", 0.1);
		
		if (gRedPortal && IsValidEdict(gRedPortal) && IsValidEntity(gRedPortal))
		{
			new redDestination = Portal_CreateDestination(gRedPortal);
			new blueDestination = Portal_CreateDestination(bluePortal);
			Portal_CreateTeler(bluePortal, redDestination);
			Portal_CreateTeler(gRedPortal, blueDestination);

			gRedPortal = 0;
		}
		else
			gRedPortal = bluePortal;
	}
	else
		LogError("Portal_CreatePortal(...)->Unable to create prop_dynamic");
		
	return (bluePortal);
}

public Portal_CreateDestination(portal)
{
	new Float:vPos[3], Float:vAngle[3];
	new target = CreateEntityByName("info_target");

	decl String:sTargetName[64];
	IntToString(target, sTargetName, sizeof(sTargetName)-1);
	DispatchKeyValue(target, "spawnflags", "0");
	DispatchKeyValue(target, "targetname", sTargetName);

	DispatchSpawn(target);
	ActivateEntity(target);

	GetEntPropVector(portal, Prop_Send, "m_angRotation", vAngle);
	GetEntPropVector(portal, Prop_Send, "m_vecOrigin", vPos);
	
	vAngle[0] = 0.0;
	vAngle[1] -= 180.0;
	GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngle, vAngle);
	ScaleVector(vAngle, 100.0);
	AddVectors(vPos, vAngle, vPos);
	
	TeleportEntity(target, vPos, NULL_VECTOR, NULL_VECTOR);
	
	return (target);
}

public Portal_CreateTeler(portal, target)
{
	new trigger = CreateEntityByName("trigger_teleport");

	decl String:sTargetName[64];
	IntToString(target, sTargetName, sizeof(sTargetName)-1);
	DispatchKeyValue(trigger, "spawnflags", "5184");
	DispatchKeyValue(trigger, "StartDisabled", "0");
	DispatchKeyValue(trigger, "target", sTargetName); 

	DispatchSpawn(trigger);
	ActivateEntity(trigger);
	
	// WTF?! xD
	SetEntityModel(trigger, "models/effects/portalrift.mdl");

	new Float:minbounds[3] = {-50.0, -50.0, 0.0};
	new Float:maxbounds[3] = {40.0, 20.0, 100.0};
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxbounds);

	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);

	
	new enteffects = GetEntProp(trigger, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(trigger, Prop_Send, "m_fEffects", enteffects); 
	
	
	new Float:vPos[3];
	GetEntPropVector(portal, Prop_Send, "m_vecOrigin", vPos);
	vPos[2] -= 40.0;
	TeleportEntity(trigger, vPos, NULL_VECTOR, NULL_VECTOR);
	
	SDKHook(trigger, SDKHook_Touch, Portal_StartTouch);
	HookSingleEntityOutput(trigger, "OnEndTouch", Portal_OnTouching, false);
	vPos[2] += 40.0;

	// Loopsound
	EmitSoundToAll("ambient/energy/force_field_loop1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vPos);
	
	// Light
	new light = CreateEntityByName("light_dynamic");

	DispatchKeyValue(light, "_light", "200 255 200 255");
	DispatchKeyValue(light, "brightness", "1");
	DispatchKeyValueFloat(light, "spotlight_radius", 200.0);
	DispatchKeyValueFloat(light, "distance", 200.0);
	DispatchKeyValue(light, "style", "5");
	
	DispatchSpawn(light);
	AcceptEntityInput(light, "TurnOn");
	
	TeleportEntity(light, vPos, NULL_VECTOR, NULL_VECTOR);
	
	// Implode/Explode xD
	new point_push = CreateEntityByName("point_push");
	DispatchKeyValue(point_push, "enabled", "1");
	DispatchKeyValue(point_push, "magnitude", "25.0");
	DispatchKeyValue(point_push, "radius", "250.0");
	DispatchKeyValue(point_push, "inner_radius", "50.0");
	DispatchKeyValue(point_push, "spawnflags", "24");
	DispatchSpawn(point_push);

	TeleportEntity(point_push, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(point_push, "Enable");
	
	return (trigger);
}

public Action:Portal_StartTouch(entity, other)
{
	/*
	new Float:vecOrigin[3], Float:vecMins[3], Float:vecMaxs[3];
	GetEntPropVector(other, Prop_Send, "m_vecOrigin", vecOrigin);           
	GetEntPropVector(other, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(other, Prop_Send, "m_vecMaxs", vecMaxs);
	decl String:targetAsString[32];
	GetEntPropString(other, Prop_Data, "m_iName", targetAsString, 32);
	new target = StringToInt(targetAsString);

	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_SOLID, TraceEntityFilterNotItself, target);

	if (TR_DidHit())
	{
		PrintToChatAll("TR_DidHit");
		return (Plugin_Handled);
	}
	*/
	
	new Float:pos[3];
	GetEntPropVector(other, Prop_Send, "m_vecOrigin", pos);
	
	if (GetEntPropFloat(other, Prop_Data, "m_flLastPhysicsInfluenceTime") + 1.5 > GetEngineTime()) // half a second cooldown
	{
		makeexplosion(0, -1, pos, "", 100);
		CPrintToChatAll("{greenyellow}Portal just destroyed the object to pretend loop-teleporting.");
		RemoveEntity(other);
		return (Plugin_Handled);
	}
	
	TE_SetupGlowSprite(pos, gPortalWarp, 0.25, 1.0, 255);
	TE_SendToAll();
	
	return (Plugin_Continue);
}

public bool:TraceEntityFilterNotItself(iEntity, iContentsMask, any:entity) 
{ 
    return (iEntity != entity); 
}  

public Portal_OnTouching(const String:output[], caller, activator, Float:delay)
{
	if (activator > 0)
	{
		if (activator <= MaxClients)
			sendfademsg(activator, 50, 50, FFADE_OUT, 200, 255, 200, 255);
		
		new Float:timeNow = GetEngineTime();
		if (GetEntPropFloat(activator, Prop_Data, "m_flLastPhysicsInfluenceTime") + 1.49 < timeNow) // half a second cooldown
		{
			new Float:vPos[3];
			GetEntPropVector(activator, Prop_Send, "m_vecOrigin", vPos);
			EmitSoundToAll("beams/beamstart5.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vPos);
			
			SetEntPropFloat(activator, Prop_Send, "m_flModelScale", 0.2);
			CreateTimer(0.7, Portal_ResizeToNormal, EntIndexToEntRef(activator), TIMER_FLAG_NO_MAPCHANGE);
			
			DrawDissolverBox(activator);
			
			TE_SetupGlowSprite(vPos, gPortalWarp, 0.25, 1.0, 255);
			TE_SendToAll();
			
			TE_SetupBeamRingPoint(vPos, 0.0, 500.0, gGlow1, gHalo1, 0, 0, 1.4, 10.0, 2.0, {255, 255, 255, 255}, 0, 0);
			TE_SendToAll();
			
			SetEntPropFloat(activator, Prop_Data, "m_flLastPhysicsInfluenceTime", timeNow);
			//TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public Action:Portal_ResizeToNormal(Handle:Timer, any:entityRef)
{
	new entity = EntRefToEntIndex(entityRef);

	if (entity != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.0);
		DrawDissolverBox(entity);
	}
}
/*
public Action:Portal_StopAnimation(Handle:Timer, any:portalRef)
{
	new portal = EntRefToEntIndex(portalRef);
 
	if (portal != INVALID_ENT_REFERENCE)
	{
		SetVariantFloat(0.0);
		AcceptEntityInput(portal, "SetPlaybackRate");
	}
}
*/
/*
	------------------------------------------------------------------------------------------
	Not possible :-/
	------------------------------------------------------------------------------------------
*/
public Portal_CreateCamera(Float:vCamPos[3], Float:vAimAngle[3])
{
	decl String:sCamera[6];
	
	/*
	vAngle[0] = 0.0;
	vAngle[1] -= 180.0;
	GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngle, vAngle);
	ScaleVector(vAngle, 100.0);
	AddVectors(vPos, vAngle, vPos);
	*/
	
	new cam = CreateEntityByName("point_camera");
	if (cam != -1)   
	{
		IntToString(EntIndexToEntRef(cam), sCamera, sizeof(sCamera)-1);
		DispatchKeyValue(cam, "targetname", sCamera);  
		DispatchKeyValue(cam, "FOV", "45");
		DispatchKeyValue(cam, "spawnflags", "0"); 
		TeleportEntity(cam, vCamPos, vAimAngle, NULL_VECTOR);
		DispatchSpawn(cam);
		
		//AcceptEntityInput(cam, "SetOnAndTurnOthersOff");
		
		new ent = -1;  
		while ((ent = FindEntityByClassname(ent, "func_monitor")) != -1)  
		{  
			SetVariantString(sCamera);
			AcceptEntityInput(ent, "SetCamera");
			PrintToServer("FOUND");	 
		}
	}
	
	TE_SetupGlowSprite(vCamPos, gHalo1, 10.0, 0.5, 255);
	TE_SendToAll();
	
	return (cam);
}

public Portal_CreateInfoCameraLink(monitor, camera)
{
	decl String:sMonitorName[64], String:sCameraName[64];
	GetEntPropString(monitor, Prop_Data, "m_iName", sMonitorName, 64);
	GetEntPropString(camera, Prop_Data, "m_iName", sCameraName, 64);
	
	new link = CreateEntityByName("info_camera_link");
	DispatchKeyValue(link, "m_hTargetEntity", sMonitorName);
	DispatchSpawn(link);
	//ActivateEntity(link);
	
	SetVariantString(sCameraName);
	AcceptEntityInput(link, "SetCamera");
	
	return (link);
}