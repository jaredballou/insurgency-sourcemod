/* 
	------------------------------------------------------------------------------------------
	EntControl::Move
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

// Admin Flags
new Handle:gAdminFlagThrow;
new Handle:gAdminFlagDistance;

new Handle:gAdminCanThrowSelf = INVALID_HANDLE;

public RegMoveCommands()
{
	gAdminFlagThrow = CreateConVar("sm_entcontrol_throw_fl", "z", "The needed Flag to throw objects");
	RegConsoleCmd("sm_entcontrol_throw", Command_Throw, "Throw Object");
	
	gAdminFlagDistance = CreateConVar("sm_entcontrol_distance_fl", "z", "The needed Flag to change the distance");
	RegConsoleCmd("sm_entcontrol_distance_up", Command_DistanceUp, "Distance Up");
	RegConsoleCmd("sm_entcontrol_distance_down", Command_DistanceDown, "Distance Down");

	gAdminCanThrowSelf = CreateConVar("sm_entcontrol_throw_self", "0", "Self-Throwing?");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Throw
	Throws the entity forward
	------------------------------------------------------------------------------------------
*/
public Action:Command_Throw(client, args)
{
	if (!CanUseCMD(client, gAdminFlagThrow))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanThrowSelf)) // I know this may be slow ... but we need the ability to change the cvar every time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);

	if (ent != -1)
	{
		new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
		new Float:viewang[3];

		// get client info
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
        
		// update object 
		vecPos[0]+=vecDir[0]*1000.0;
		vecPos[1]+=vecDir[1]*1000.0;
		vecPos[2]+=vecDir[2]*1000.0;

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecDir);

		SubtractVectors(vecPos, vecDir, vecVel);
		ScaleVector(vecVel, 10.0);
		TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vecVel);

		new String:edictname[128];
		GetEdictClassname(ent, edictname, 128);

		if (StrEqual(edictname, "player"))
			LogAction(client, 0, "%L throw %L", client, ent);
		else
			LogAction(client, 0, "%L throw %s", client, edictname);
		
		gObj[client] = -1;
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
} 

/* 
	------------------------------------------------------------------------------------------
	Command_DistanceUp
	Modifies the distance between the client and the entity
	------------------------------------------------------------------------------------------
*/
public Action:Command_DistanceUp(client, args)
{  
	if (!CanUseCMD(client, gAdminFlagDistance) || !ValidGrab(client)) return (Plugin_Handled);

	gDistance[client] += 20;
	
	PrintHintText(client, "%t", "Distance", gDistance[client]);	

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_DistanceDown
	Modifies the distance between the client and the entity
	------------------------------------------------------------------------------------------
*/
public Action:Command_DistanceDown(client, args)
{  
	if (!CanUseCMD(client, gAdminFlagDistance) || !ValidGrab(client)) return (Plugin_Handled);

	gDistance[client] -= 20;
	
	PrintHintText(client, "%t", "Distance", gDistance[client]); 

	return (Plugin_Handled);
}