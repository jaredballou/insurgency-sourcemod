/* 
	------------------------------------------------------------------------------------------
	EntControl::BaseVehicle
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

// Admin Flags
new Handle:gAdminFlagVehicles;

new gClientVehicle[MAXPLAYERS];

#define VEHICLE_SCREENOVERLAY "r_screenoverlay debug/yuv" // effects/flicker_256,effects/combine_binocoverlay
#define GUNMODEL "models/props_rooftop/Gutter_Pipe_128.mdl" // models/props_rooftop/roof_vent003.mdl
new gVehicleMuzzleFlash;
new gVehicleMuzzleSmoke;

public BaseVehicle_Init()
{
	gAdminFlagVehicles = CreateConVar("sm_entcontrol_v_fl", "z", "The needed Flag to spawn Vehicles");
	
	// PrecacheModel
	PrecacheModel("models/props_vehicles/apc001.mdl", true);
	PrecacheModel("models/props_vehicles/apc_tire001.mdl", true);
	PrecacheModel(GUNMODEL, true);

	PrecacheSound("ambient/explosions/explode_3.wav");
	PrecacheSound("ambient/explosions/explode_4.wav");
	PrecacheSound("vehicles/v8/v8_start_loop1.wav");
	PrecacheSound("vehicles/v8/v8_stop1.wav");

	gVehicleMuzzleFlash = PrecacheModel("materials/particle/warp1_warp.vmt");
	gVehicleMuzzleSmoke = PrecacheModel("materials/sprites/gunsmoke.vmt");
}

public BaseVehicle_Commands()
{
	RegConsoleCmd("sm_entcontrol_bv_spawn", Command_BaseVehicle_Spawn, "Spawn Test Vehicle");
}

public Action:Command_BaseVehicle_Spawn(client, args)
{
	if (!CanUseCMD(client, gAdminFlagVehicles)) return (Plugin_Handled);
	
	new Float:position[3];
	new String:tankRefAsString[32];
	
	if (!GetPlayerEye(client, position))
		return (Plugin_Handled);

	position[2] += 20.0;
	
	// ================== Now create the Tank ===================
	new tank = CreateEntityByName("prop_physics_override");
	new gun = CreateEntityByName("prop_dynamic");
	
	IntToString(EntIndexToEntRef(tank), tankRefAsString, sizeof(tankRefAsString)-1);

	//DispatchKeyValueFloat(tank, "physdamagescale", 1000.0);
	DispatchKeyValue(tank, "model", "models/props_vehicles/apc001.mdl");
	DispatchKeyValue(tank, "spawnflags", "256");
	DispatchKeyValue(tank, "targetname", tankRefAsString);
	DispatchKeyValue(gun, "classname", "vehicle");
	//DispatchKeyValue(tank, "massscale", "10000.0");
	DispatchSpawn(tank);
	
	BaseVehicle_SetOwner(tank, 0);
	BaseVehicle_SetTurret(tank, gun);

	SetEntityMoveType(tank, MOVETYPE_VPHYSICS);

	position[2] += 80.0;
	TeleportEntity(tank, position, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(tank, "EnableDamageForces");
	
	// ================== KEEP HEIGHT ==================
	new keepupright = CreateEntityByName("phys_keepupright");
	DispatchKeyValue(keepupright, "target", tankRefAsString);
	DispatchSpawn(keepupright);
	position[2] -= 80.0;
	
	TeleportEntity(keepupright, position, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(keepupright, "TurnOn");
	// ================== Now create the Weapon ==================
	SetEntityModel(gun, GUNMODEL);
	DispatchKeyValue(gun, "classname", "weapon_vehicle_turret");
	DispatchKeyValue(gun, "parent", tankRefAsString);
	DispatchSpawn(gun);	
	
	SetEntityMoveType(gun, MOVETYPE_FLY);
	
	position[2] += 140.0;
	position[1] += 25.0;
	TeleportEntity(gun, position, NULL_VECTOR, NULL_VECTOR);
	position[1] -= 25.0;
	
	// ================== PARENT THEM TOGETHER ==================
	SetVariantString(tankRefAsString);
	AcceptEntityInput(gun, "SetParent");
	
	// ================== CREATE WHEELS ==================
	// Front-right
	position[2] -= 100.0;
	position[0] += 60.0;
	position[1] += 77.0;
	CreateWheel(tank, position);
	
	// Front-left
	position[0] -= 110.0;
	CreateWheel(tank, position);
	
	// Back-left
	position[1] -= 153.0;
	CreateWheel(tank, position);
	
	// Back-right
	position[0] += 110.0;
	CreateWheel(tank, position);
	// ================== CHECK FOR USE ==================
	HookSingleEntityOutput(tank, "OnPlayerUse", OnUseFunc, false);
	
	return (Plugin_Handled);
}

public CreateWheel(vehicle, Float:position[3])
{
//return;
	new String:vehicleRefAsString[32], String:wheelRefAsString[32];
	IntToString(EntIndexToEntRef(vehicle), vehicleRefAsString, sizeof(vehicleRefAsString)-1);
	
	new wheel = CreateEntityByName("prop_physics_override");
	IntToString(EntIndexToEntRef(wheel), wheelRefAsString, sizeof(wheelRefAsString)-1);
	//DispatchKeyValueFloat(wheel, "physdamagescale", 1000.0);
	DispatchKeyValue(wheel, "model", "models/props_vehicles/apc_tire001.mdl");
	DispatchKeyValue(wheel, "targetname", wheelRefAsString);
	DispatchSpawn(wheel);

	SetEntityMoveType(wheel, MOVETYPE_VPHYSICS);
	TeleportEntity(wheel, position, NULL_VECTOR, NULL_VECTOR);
	
	new phys_constraint = CreateEntityByName("phys_ballsocket");
	DispatchKeyValue(phys_constraint, "attach2", wheelRefAsString);
	DispatchKeyValue(phys_constraint, "attach1", vehicleRefAsString);
	DispatchSpawn(phys_constraint);
	ActivateEntity(phys_constraint);

	TeleportEntity(phys_constraint, position, NULL_VECTOR, NULL_VECTOR);
}

public OnUseFunc(const String:output[], tank, ignorable, Float:delay)
{
	new client;

	// ================== FIND CLIENT ==================
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnectedIngame(i) && !IsFakeClient(i))
		{
			new target = GetClientAimTarget(i, false);
			if (target == tank)
			{
				client = i;
				break;
			}
		}
	}

	if (client == 0)
		return;
	
	if (gClientVehicle[client] == 0)
	{
		BaseVehicle_Enter(tank, client);
	}
	else
	{
		BaseVehicle_Leave(tank, client);
	}
}

public BaseVehicle_Enter(vehicle, client)
{
	if (BaseVehicle_GetOwner(vehicle))
	{
		CPrintToChat(client, "{greenyellow}Vehicle full!");
		return;
	}
	
	CPrintToChat(client, "{greenyellow}Entering Vehicle");
	gClientVehicle[client] = EntIndexToEntRef(vehicle);
	
	new Float:pos[3];
	GetEntPropVector(vehicle, Prop_Send, "m_vecOrigin", pos);

	// ================== PARENT CLIENT TO VEHICLE ==================
	SetEntityMoveType(client, MOVETYPE_NONE); 
	pos[2] += 20;
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	
	new String:tankRefAsString[32];
	IntToString(EntIndexToEntRef(vehicle), tankRefAsString, sizeof(tankRefAsString)-1);
	SetVariantString(tankRefAsString);
	AcceptEntityInput(client, "SetParent");
	
	BaseVehicle_SetOwner(vehicle, client);
	
	// Third-Person
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);
	
	Colorize(client, INVISIBLE, false);
	
	//SetEntProp(client, Prop_Send, "m_iFOV", 75);
	
	// Screen overlay
	ClientCommand(client, VEHICLE_SCREENOVERLAY);
	
	// Play start sound
	EmitSoundToAll("vehicles/v8/v8_start_loop1.wav", vehicle);
}

public BaseVehicle_Leave(vehicle, client)
{
	if (BaseVehicle_GetOwner(vehicle) != client)
	{
		CPrintToChat(client, "{greenyellow}Vehicle already full!");
		return;
	}
	
	CPrintToChat(client, "{greenyellow}Leaving Vehicle");
	AcceptEntityInput(client, "ClearParent");
	SetEntityMoveType(client, MOVETYPE_WALK); 
	gClientVehicle[client] = 0;
	BaseVehicle_SetOwner(vehicle, 0);
	
	// First Person
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);
	
	Colorize(client, VISIBLE, false);
	
	// Undo Screenoverlay
	ClientCommand(client, "r_screenoverlay 0");
	
	// Stop loop sound
	StopSound(vehicle, SNDCHAN_AUTO, "vehicles/v8/v8_start_loop1.wav");
	
	// Play stop sound
	EmitSoundToAll("vehicles/v8/v8_stop1.wav", vehicle);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_Base_Think
	------------------------------------------------------------------------------------------
*/
public BaseVehicle_Think(vehicle, client)
{
	new Float:vAngle[3], Float:vAngleVehicle[3], Float:vOrigin[3], Float:vAimPos[3], Float:vGunPos[3];

	new gun = BaseVehicle_GetTurret(vehicle);
	new owner = BaseVehicle_GetOwner(vehicle);
	
	if (owner == client)
	{
		GetClientEyePosition(client, vOrigin);
		GetClientEyeAngles(client, vAngle);
		
		if (vAngle[0] > 5.0)
			vAngle[0] = 5.0;
		else if (vAngle[0] < -35.0)
			vAngle[0] = -35.0;

		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngle, MASK_VISIBLE, RayType_Infinite, TraceASDF, client);

		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(vAimPos, trace);
			new target = TR_GetEntityIndex(trace);
			CloseHandle(trace);
			
			GetEntPropVector(vehicle, Prop_Send, "m_angRotation", vAngleVehicle);
			
			SubtractVectors(vAngle, vAngleVehicle, vAngleVehicle);
			
			if (vAngleVehicle[0] + 270.0 > 360.0)
				vAngleVehicle[0] -= 90.0;
			else
				vAngleVehicle[0] += 270.0;
			
			TeleportEntity(gun, NULL_VECTOR, vAngleVehicle, NULL_VECTOR);
			
			GetEntPropVector(vehicle, Prop_Send, "m_vecOrigin", vOrigin);
			vGunPos[0] = vOrigin[0];
			vGunPos[1] = vOrigin[1];
			vGunPos[2] = vOrigin[2];
			
			new button = GetClientButtons(client);
			if (button & IN_ATTACK)
			{
				/*
				SetVariantString("fire");
				AcceptEntityInput(gun, "SetAnimation");
				*/
				
				// ================== MUZZLEFLASH ==================
				GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vAngle, 100.0);
				AddVectors(vGunPos, vAngle, vGunPos);
				vGunPos[1] += 25;
				vGunPos[2] += 80.0;
				
				TE_SetupGlowSprite(vGunPos, gVehicleMuzzleFlash, 0.1, 0.75, 255);
				TE_SendToAll();
				TE_SetupGlowSprite(vGunPos, gVehicleMuzzleSmoke, 0.8, 1.5, 255);
				TE_SendToAll();
				// ================== -MUZZLEFLASH ==================
				
				vOrigin[2] += 25.0;
				TE_SetupBeamRingPoint(vOrigin, 0.0, 750.0, gVehicleMuzzleSmoke, gVehicleMuzzleSmoke, 0, 0, 0.1, 5.0, 1.0, {100, 100, 100, 200}, 0, 0);
				TE_SendToAll();
				
				EmitSoundToAll("ambient/explosions/explode_4.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vGunPos);
				EmitSoundToAll("ambient/explosions/explode_3.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vAimPos);
				makeexplosion(client, -1, vAimPos, "", 100);
				
				new shake = CreateEntityByName("env_shake");
				if (DispatchSpawn(shake))
				{
					DispatchKeyValueFloat(shake, "amplitude", 150.0);
					DispatchKeyValueFloat(shake, "radius", 500.0);
					DispatchKeyValueFloat(shake, "duration", 1.0);
					DispatchKeyValueFloat(shake, "frequency", 500.0);
					
					AcceptEntityInput(shake, "StartShake");
					
					TeleportEntity(shake, vGunPos, NULL_VECTOR, NULL_VECTOR);

					RemoveEntity(shake, 1.0);
				}
				
				// push back the vehicle
				new pushback = CreateEntityByName("point_push");
				DispatchKeyValue(pushback, "enabled", "1");
				DispatchKeyValue(pushback, "magnitude", "50.0");
				DispatchKeyValue(pushback, "radius", "250.0");
				DispatchKeyValue(pushback, "inner_radius", "50.0");
				DispatchKeyValue(pushback, "spawnflags", "24");
				DispatchSpawn(pushback);

				TeleportEntity(pushback, vGunPos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(pushback, "Enable");

				// Remove our Entity
				RemoveEntity(pushback, 0.1);
				
				// physExplode
				new physExplode = CreateEntityByName("point_push");
				DispatchKeyValue(physExplode, "enabled", "1");
				DispatchKeyValue(physExplode, "magnitude", "500.0");
				DispatchKeyValue(physExplode, "radius", "500.0");
				DispatchKeyValue(physExplode, "inner_radius", "50.0");
				DispatchKeyValue(physExplode, "spawnflags", "24");
				DispatchSpawn(physExplode);

				TeleportEntity(physExplode, vAimPos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(physExplode, "Enable");

				// Remove our Entity
				RemoveEntity(physExplode, 0.1);
				
				sendfademsg(client, 25, 25, FFADE_OUT, 255, 255, 255, 25);
			}
		}
	}
}

public Action:BaseVehicle_Update(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (gClientVehicle[i] != 0 && IsClientConnectedIngame(i) && !IsFakeClient(i))
		{
			BaseVehicle_Think(gClientVehicle[i], i);
		}
	}
	
	return (Plugin_Continue);
}

/*
	------------------------------------------------------------------------------------------
	BaseVehicle_GetTurret
	This will get the mounted turret
	------------------------------------------------------------------------------------------
*/
stock BaseVehicle_GetTurret(vehicle)
{
	return (GetEntPropEnt(vehicle, Prop_Send, "m_hOwnerEntity"));
}

/*
	------------------------------------------------------------------------------------------
	BaseVehicle_SetTurret
	This will set the mounted turret
	------------------------------------------------------------------------------------------
*/
stock BaseVehicle_SetTurret(vehicle, turret)
{
	SetEntPropEnt(vehicle, Prop_Send, "m_hOwnerEntity", turret);
}

/*
	------------------------------------------------------------------------------------------
	BaseVehicle_GetOwner
	This will get the owner
	------------------------------------------------------------------------------------------
*/
stock BaseVehicle_GetOwner(vehicle)
{
	return (GetEntProp(vehicle, Prop_Data, "m_iHammerID"));
}

/*
	------------------------------------------------------------------------------------------
	BaseVehicle_SetOwner
	This will set the owner
	------------------------------------------------------------------------------------------
*/
stock BaseVehicle_SetOwner(vehicle, owner)
{
	SetEntProp(vehicle, Prop_Data, "m_iHammerID", owner, 4);
}

public BaseVehicle_Turn(tank, bool:right)
{
	new Float:angles[3], Float:angle;
	GetEntPropVector(tank, Prop_Send, "m_angRotation", angles);
	
	if (right)
		angle = -2.0;
	else
		angle = 2.0;
	
	if (angles[1] + angle > 180.0)
		angles[1] = -180.0 + angle;
	else if (angles[1] + angle < -180.0)
		angles[1] = 180.0 + angle;
	else
		angles[1] += angle;
	
	TeleportEntity(tank, NULL_VECTOR, angles, NULL_VECTOR);
}

public BaseVehicle_Move(vehicle, bool:backward)
{
	new Float:angles[3], Float:pos[3];
	GetEntPropVector(vehicle, Prop_Send, "m_angRotation", angles);
	GetEntPropVector(vehicle, Prop_Send, "m_vecOrigin", pos);
	
	/*
	GetVectorAngles(angles, angles);
	if (angles[1] + 90 > 180.0)
		angles[1] = -180.0 + 90;
	else if (angles[1] + 90 < -180.0)
		angles[1] = 180.0 + 90;
	else
		angles[1] += 90;
	*/
	
	if (angles[1] + 90 > 360)
		angles[1] -= 270;
	else
		angles[1] += 90;
	
	GetAngleVectors(angles, angles, NULL_VECTOR, NULL_VECTOR);
	//NormalizeVector(angles, angles);
	ScaleVector(angles, 300.0);
	
	if (backward)
		NegateVector(angles);

	angles[2] = 0.0;

	TeleportEntity(vehicle, NULL_VECTOR, NULL_VECTOR, angles);
}