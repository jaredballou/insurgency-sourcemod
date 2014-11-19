/* 
	------------------------------------------------------------------------------------------
	EntControl::Rotate
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

// Admin Flags
new Handle:gAdminFlagRotate;

public RegRotateCommands()
{
	gAdminFlagRotate = CreateConVar("sm_entcontrol_rotate_fl", "z", "The needed Flag to rotate an object");
	RegConsoleCmd("sm_entcontrol_rotate", Command_Rotate, "Rotate Object");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Rotate
	Rotate the entity
	------------------------------------------------------------------------------------------
*/
public Action:Command_Rotate(client, args)
{  
	if (!CanUseCMD(client, gAdminFlagRotate)) return (Plugin_Handled);

	new obj = gSelectedEntity[client];
	if (obj != -1)
	{
		decl String:arg1[12], String:arg2[12];
		decl Float:angle; // Should I use INT instead ? hmmm ...
		decl Float:vel[3];

		if (args < 2)
		{
			ReplyToCommand(client, "Usage: X/Y/Z UP/DOWN");
			return (Plugin_Handled);
		}
	
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
	
		if (StrEqual(arg2, "up"))
		{
			angle = 45.0;
		}	
		else if (StrEqual(arg2, "down"))
		{
			angle = -45.0;
		}
		else
		{
			ReplyToCommand(client, "Argument 2: Only UP or DOWN supported!");
			return (Plugin_Handled);
		}

		GetEntPropVector(obj, Prop_Send, "m_angRotation", vel);

		if (StrEqual(arg1, "x"))
		{
			if (vel[0] + angle > 180)
				vel[0] = -180 + angle;
			else if (vel[0] + angle < -180)
				vel[0] = 180 + angle;
			else
				vel[0] += angle;
		}
		else if (StrEqual(arg1, "y"))
		{
			if (vel[1] + angle > 180)
				vel[1] = -180 + angle;
			else if (vel[1] + angle < -180)
				vel[1] = 180 + angle;
			else
				vel[1] += angle;
		}
		else if (StrEqual(arg1, "z"))
		{
			if (vel[2] + angle > 180)
				vel[2] = -180 + angle;
			else if (vel[2] + angle < -180)
				vel[2] = 180 + angle;
			else
				vel[2] += angle;
		}

		TeleportEntity(obj, NULL_VECTOR, vel, NULL_VECTOR);

		PrintHintText(client, "Angles: X(%f) Y(%f) Z(%f)", vel[0], vel[1], vel[2]); 
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}
