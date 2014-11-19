/* 
	------------------------------------------------------------------------------------------
	EntControl::Edit
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

// Admin Flags
new Handle:gAdminFlagEdit;

public RegEditCommands()
{
	gAdminFlagEdit = CreateConVar("sm_entcontrol_edit_fl", "z", "The needed Flag to edit entities");
	RegConsoleCmd("sm_entcontrol_freeze", Command_Freeze, "Freeze Object");
	RegConsoleCmd("sm_entcontrol_unfreeze", Command_UnFreeze, "UnFreeze Object");
	RegConsoleCmd("sm_entcontrol_breakable", Command_Breakable, "Breakable Object");
	RegConsoleCmd("sm_entcontrol_invincible", Command_Invincible, "Invincible Object");
	RegConsoleCmd("sm_entcontrol_gravity", Command_Gravity, "Gravity of Object");
	RegConsoleCmd("sm_entcontrol_size", Command_Size, "Size of Object");
	RegConsoleCmd("sm_entcontrol_speed", Command_Speed, "Speed of Object");
	RegConsoleCmd("sm_entcontrol_touch", Command_Touch, "Touch Object");
	RegConsoleCmd("sm_entcontrol_ignite", Command_Ignite, "Ignite Object");
	RegConsoleCmd("sm_entcontrol_visible", Command_Visible, "Visible Object");
	RegConsoleCmd("sm_entcontrol_invisible", Command_Invisible, "Invisible Object");
	RegConsoleCmd("sm_entcontrol_solid", Command_Solid, "Block Object");
	RegConsoleCmd("sm_entcontrol_unsolid", Command_UnSolid, "NoBlock Object");
	RegConsoleCmd("sm_entcontrol_activate", Command_Activate, "Activate Object");
	RegConsoleCmd("sm_entcontrol_healthtoone", Command_HealthToOne, "Health to 1 Object");
	RegConsoleCmd("sm_entcontrol_healthtofull", Command_HealthToFull, "Health to 100 Object");
	RegConsoleCmd("sm_entcontrol_changeskin", Command_ChangeSkin, "Change the skin");
	RegConsoleCmd("sm_entcontrol_hurt", Command_Hurt, "Hurt Object(MUCH DMG!)");
	RegConsoleCmd("sm_entcontrol_rm", Command_Rm, "Remove Object");
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Freeze
	Freeze the entity
	------------------------------------------------------------------------------------------
*/
stock Entity_Freeze(ent)
{
	SetEntityMoveType(ent, MOVETYPE_NONE);
}

public Action:Command_Freeze(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);
	
	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Freeze(ent);
		
		gObj[client]=-1;
		
		PrintHintText(client, "%t", "Frozen");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Freeze
	Freeze the entity
	------------------------------------------------------------------------------------------
*/
stock Entity_UnFreeze(ent)
{
	new String:edictname[64];
	GetEdictClassname(ent, edictname, 64);
	
	if (GetEntityMoveType(ent) == MOVETYPE_NONE)
	{
		if (StrEqual("player", edictname))
			SetEntityMoveType(ent, MOVETYPE_WALK);
		else
			SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	}

	new Float:position[3];
	TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, position);
}

public Action:Command_UnFreeze(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_UnFreeze(ent);

		gObj[client]=-1;
		
		PrintHintText(client, "%t", "UnFrozen");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Breakable
	Make it breakable
	------------------------------------------------------------------------------------------
*/
stock Entity_Breakable(ent)
{
	SetEntProp(ent, Prop_Data, "m_takedamage", 2, 1);
}

public Action:Command_Breakable(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Breakable(ent);
		PrintHintText(client, "%t", "Breakable");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Invincible
	Make it invincible
	------------------------------------------------------------------------------------------
*/
stock Entity_Invincible(ent)
{
	SetEntProp(ent, Prop_Data, "m_takedamage", 0, 1);
}

public Action:Command_Invincible(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Invincible(ent);
		PrintHintText(client, "%t", "Invincible");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}  

/* 
	------------------------------------------------------------------------------------------
	Entity_Gravity
	Modify gravity
	------------------------------------------------------------------------------------------
*/
stock Float:Entity_Gravity(ent, bool:isUpOrDown)
{
	// Get the gravity
	new Float:gravity = GetEntPropFloat(ent, Prop_Data, "m_flGravity");

	if (isUpOrDown)
		gravity += 0.1;
	else
		gravity -= 0.1;

	SetEntPropFloat(ent, Prop_Data, "m_flGravity", gravity);
	
	return (gravity);
}

public Action:Command_Gravity(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);

	if (ent != -1)
	{
		decl String:arg1[12];
		new bool:isUpOrDown;

		if (args != 1)
			ReplyToCommand(client, "<up> or <down> ?");
		else
		{
			GetCmdArg(1, arg1, sizeof(arg1));
	
			if (StrEqual(arg1, "up"))
				isUpOrDown = true;
			else if (StrEqual(arg1, "down"))
				isUpOrDown = false;
			else
			{
				ReplyToCommand(client, "Argument 2: Only UP or DOWN is supported!");
				return (Plugin_Handled);
			}

			PrintHintText(client, "%t", "Gravity", Entity_Gravity(ent, isUpOrDown));
		}
	}
	else
		PrintHintText(client, "%t", "Wrong entity");
	

	return (Plugin_Handled);
}  

/* 
	------------------------------------------------------------------------------------------
	Entity_Size
	Modify size
	------------------------------------------------------------------------------------------
*/
stock Float:Entity_Size(ent, bool:isUpOrDown)
{
	// Get the gravity
	new Float:size = GetEntPropFloat(ent, Prop_Data, "m_flModelScale");

	if (isUpOrDown)
		size += 0.1;
	else
		size -= 0.1;

	SetEntPropFloat(ent, Prop_Data, "m_flModelScale", size);
	
	return (size);
}

public Action:Command_Size(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		new String:edictname[64];
		GetEdictClassname(ent, edictname, 64);

		if (StrContains(edictname, "func_") != 0)
		{
			decl String:arg1[12];
			new bool:isUpOrDown;

			if (args != 1)
				ReplyToCommand(client, "<up> or <down> ?");
			else
			{
				GetCmdArg(1, arg1, sizeof(arg1));
		
				if (StrEqual(arg1, "up"))
					isUpOrDown = true;
				else if (StrEqual(arg1, "down"))
					isUpOrDown = false;
				else
				{
					ReplyToCommand(client, "Argument 2: Only UP or DOWN is supported!");
					return (Plugin_Handled);
				}

				PrintHintText(client, "%t", "Size", Entity_Size(ent, isUpOrDown));
			}
		}
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity");
	}
	
	return (Plugin_Handled);
}  

/* 
	------------------------------------------------------------------------------------------
	Entity_Speed
	Modify speed
	------------------------------------------------------------------------------------------
*/
stock Float:Entity_Speed(ent, bool:isUpOrDown)
{
	// Get the gravity
	new Float:speed = GetEntPropFloat(ent, Prop_Data, "m_flLaggedMovementValue");

	if (isUpOrDown)
		speed += 0.1;
	else
		speed -= 0.1;

	SetEntPropFloat(ent, Prop_Data, "m_flLaggedMovementValue", speed);
	
	return (speed);
}

public Action:Command_Speed(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
		
	if (ent != -1)
	{
		decl String:arg1[12];
		new bool:isUpOrDown;

		if (args != 1)
			ReplyToCommand(client, "<up> or <down> ?");
		else
		{
			GetCmdArg(1, arg1, sizeof(arg1));
	
			if (StrEqual(arg1, "up"))
				isUpOrDown = true;
			else if (StrEqual(arg1, "down"))
				isUpOrDown = false;
			else
			{
				ReplyToCommand(client, "Argument 2: Only UP or DOWN is supported!");
				return (Plugin_Handled);
			}

			// Change Speed and print it to the client
			PrintHintText(client, "%t", "Speed", Entity_Speed(ent, isUpOrDown));
		}
	}
	else
		PrintHintText(client, "%t", "Wrong entity");
	

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Touch
	Similar to +use, but more aggressive.
	------------------------------------------------------------------------------------------
*/
stock Entity_Touch(ent, client)
{
	new String:edictname[64];
	GetEdictClassname(ent, edictname, 64);
	
	if (StrEqual(edictname, "func_button"))
		AcceptEntityInput(ent, "Press", client, client);
	else if (StrEqual(edictname, "func_door") 
		|| StrEqual(edictname, "func_rotating") 
		|| StrEqual(edictname, "func_doof_rotating")
		|| StrEqual(edictname, "prop_door_rotating")
		|| StrEqual(edictname, "func_tracktrain"))
		AcceptEntityInput(ent, "Toggle", client, client);
	else if (StrEqual(edictname, "prop_dynamic"))
		AcceptEntityInput(ent, "TurnOn", client, client);
	else if (StrEqual(edictname, "func_breakable")
		|| StrEqual(edictname, "func_breakable_surf"))
		AcceptEntityInput(ent, "Break", client, client);
	else if (StrEqual(edictname, "hostage_entity"))
		SetEntDataEnt2(ent, gLeaderOffset, client);
	else
		AcceptEntityInput(ent, "Use", client, client);
}

public Action:Command_Touch(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Touch(ent, client);
		
		PrintHintText(client, "%t", "Touched");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}  

/* 
	------------------------------------------------------------------------------------------
	Entity_Ignite
	Burn it
	------------------------------------------------------------------------------------------
*/
stock Entity_Ignite(ent, Float:duration)
{
	IgniteEntity(ent, duration);
}

public Action:Command_Ignite(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Ignite(ent, 5.0);

		PrintHintText(client, "%t", "Ignited");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");


	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Visible
	Make it visible
	------------------------------------------------------------------------------------------
*/
stock Entity_Visible(ent)
{
	SetEntityRenderMode(ent, RENDER_NORMAL);
	SetEntityRenderColor(ent, 255, 255, 255, 255);
}

public Action:Command_Visible(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Visible(ent);

		PrintHintText(client, "%t", "Visible");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");


	return (Plugin_Handled);
}


/* 
	------------------------------------------------------------------------------------------
	Entity_InVisible
	Make it invisible
	------------------------------------------------------------------------------------------
*/
stock Entity_InVisible(ent)
{
	SetEntityRenderMode(ent, RENDER_NONE);
	SetEntityRenderColor(ent, 0, 0, 0, 0);
}

public Action:Command_Invisible(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_InVisible(ent);
		
		PrintHintText(client, "%t", "Invisible")
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Solid
	Make it solid
	------------------------------------------------------------------------------------------
*/
stock Entity_Solid(ent)
{
	new String:edictname[128];
	GetEdictClassname(ent, edictname, 128);
	if (!StrEqual(edictname, "player"))
		SetEntData(ent, gCollisionOffset, 5, 4, true);
	else
		SetEntData(ent, gCollisionOffset, 0, 4, true);
}

public Action:Command_Solid(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Solid(ent);
		
		PrintHintText(client, "%t", "Solid");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_UnSolid
	Make it unsolid
	------------------------------------------------------------------------------------------
*/
stock Entity_UnSolid(ent)
{
	SetEntData(ent, gCollisionOffset, 2, 4, true);
}

public Action:Command_UnSolid(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_UnSolid(ent);

		PrintHintText(client, "%t", "Unsolid");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_Activate
	Make it activate
	------------------------------------------------------------------------------------------
*/
stock Entity_Activate(ent)
{
	ActivateEntity(ent);
}

public Action:Command_Activate(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_Activate(ent);

		PrintHintText(client, "%t", "Activated");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_SetHealth
	Change HP to x
	------------------------------------------------------------------------------------------
*/
stock Entity_SetHealth(ent, health)
{
	// SetEntityHealth(ent, health);
	SetEntProp(ent, Prop_Data, "m_iHealth", health);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_GetHealth
	Get Health
	------------------------------------------------------------------------------------------
*/
stock Entity_GetHealth(entity)
{
	return (GetEntProp(entity, Prop_Data, "m_iHealth"));
}

public Action:Command_HealthToOne(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_SetHealth(ent, 1);

		PrintHintText(client, "%t", "HealthToOne");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_HealthToFull
	Change HP to 100
	------------------------------------------------------------------------------------------
*/
public Action:Command_HealthToFull(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
	{
		Entity_SetHealth(ent, 1);

		PrintHintText(client, "%t", "HealthToFull");
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Entity_ChangeSkin
	Change the skin to the one we saved
	------------------------------------------------------------------------------------------
*/
stock Entity_ChangeSkin(ent, client)
{
	new String:edictname[128];
	GetEdictClassname(ent, edictname, 128);
	if ((strncmp("prop_", edictname, 5, false) == 0)
		|| (strncmp("hosta", edictname, 5, false) == 0)
		|| StrEqual("player", edictname))
	{
		if (StrEqual(gSavedSkin[client], ""))
			PrintHintText(client, "%t", "SaveSkinFirst");
		else
		{
			SetEntityModel(ent, gSavedSkin[client]); 

			Colorize(client, INVISIBLE, true);

			PrintHintText(client, "%t", "SkinChanged");
		}
	}
	else
		PrintHintText(client, "%t", "Wrong entity");
}

public Action:Command_ChangeSkin(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent = GetObject(client, false);
	if (ent != -1)
		Entity_ChangeSkin(ent, client);
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}  

/* 
	------------------------------------------------------------------------------------------
	Entity_Hurt
	Make VERY much damage
	------------------------------------------------------------------------------------------
*/
stock Entity_Hurt(ent, client)
{
	decl Float:position[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
	MakeDamage(client, ent, 100000, DMG_ACID, 1.0, position);
}

public Action:Command_Hurt(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent;
	if (GetConVarBool(gAdminCanModSelf)) // I know this might be slow ... but we need the ability to change the cvar any time
		ent = GetObject(client);
	else
		ent = GetObject(client, false);
	
	if (ent != -1)
		Entity_Hurt(ent, client);
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}  

/* 
	------------------------------------------------------------------------------------------
	Command_Rm
	Remove the given Entity
	------------------------------------------------------------------------------------------
*/
public Action:Command_Rm(client, args)
{
	if (!CanUseCMD(client, gAdminFlagEdit))
		return (Plugin_Handled);

	new ent = GetObject(client, false);
	if (ent != -1)
		RemoveEntity(ent);
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
} 