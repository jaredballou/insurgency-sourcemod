/* 
	------------------------------------------------------------------------------------------
	EntControl::Helper
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

new String:gSavedSkin[128][MAXPLAYERS+1];

// Admin Flags
new Handle:gAdminFlagHelper;

public RegHelperCommands()
{
	gAdminFlagHelper = CreateConVar("sm_entcontrol_helper_fl", "z", "The needed Flag to use the helper commands");
	RegConsoleCmd("sm_entcontrol_teleport", Command_Teleport, "Teleport");
	RegConsoleCmd("sm_entcontrol_changeownskin", Command_ChangeOwnSkin, "Change your own skin");
	RegConsoleCmd("sm_entcontrol_saveskin", Command_SaveSkin, "Save skin");	
	RegConsoleCmd("sm_entcontrol_explode", Command_Explode, "Explode (Physically)");
	RegConsoleCmd("sm_entcontrol_implode", Command_Implode, "Implode (Physically)");
	RegConsoleCmd("sm_entcontrol_marknearents", Command_MarkNearEnts, "Mark near Entities");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Teleport
	Teleport to the aimed position
	ToDo: Improve the code ...
	------------------------------------------------------------------------------------------
*/
public Action:Command_Teleport(client, args)
{
	if (!CanUseCMD(client, gAdminFlagHelper)) return (Plugin_Handled);

	decl Float:position[3];
	if (GetPlayerEye(client, position))
		TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
	else 
		PrintHintText(client, "%t", "Wrong entity"); 
	
	return (Plugin_Handled);
}
// End of rip xD

/* 
	------------------------------------------------------------------------------------------
	Command_ChangeOwnSkin
	Change own skin to what we are looking at
	------------------------------------------------------------------------------------------
*/
public Action:Command_ChangeOwnSkin(client, args)
{
	if (!CanUseCMD(client, gAdminFlagHelper)) return (Plugin_Handled);
	
	new ent = TraceToEntity(client);
	if (ent==-1 && !(IsValidEdict(ent) && IsValidEntity(ent))) 
 		return (Plugin_Handled);

	new String:edictname[128];
	GetEdictClassname(ent, edictname, 128);
	if ((strncmp("prop_", edictname, 5, false) == 0)
		|| (strncmp("hosta", edictname, 5, false) == 0)
		|| (strncmp("npc_", edictname, 4, false) == 0)
		|| StrEqual("player", edictname))
	{
		new String:model[128];
		GetEntPropString(ent, Prop_Data, "m_ModelName", model, 128);
		SetEntityModel(client, model);

		Colorize(client, INVISIBLE, true);

		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
 		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		CreateTimer(2.0, FirstPerson, client);
	}

	return (Plugin_Handled);
}

public Action:FirstPerson(Handle:timer, any:client) 
{
	if (IsClientConnectedIngame(client))
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
	}
}

/* 
	------------------------------------------------------------------------------------------
	Command_SaveSkin
	Save the skin to what we are looking at
	------------------------------------------------------------------------------------------
*/
public Action:Command_SaveSkin(client, args)
{
	if (!CanUseCMD(client, gAdminFlagHelper))
		return (Plugin_Handled);

	new obj = GetObject(client);
	if (obj != -1)
	{
		new String:edictname[128];
		GetEdictClassname(obj, edictname, 128);
		if ((strncmp("prop_", edictname, 5, false) == 0)
			|| (strncmp("hosta", edictname, 5, false) == 0)
			|| (strncmp("phys_", edictname, 5, false) == 0)
			|| StrEqual("player", edictname))
			GetEntPropString(obj, Prop_Data, "m_ModelName", gSavedSkin[client], 128);
	}
	else
		PrintHintText(client, "%t", "Wrong entity");

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Explode
	Just the point_brush entity:
	From valve: Push sphere that will push any physics props or entity that has a movement 
	type set (e.g. NPCs) away from its origin. 
	It will not push parented objects -- so if you want to keep some entities rooted, 
	you can parent them temporarily to something static.
	------------------------------------------------------------------------------------------
*/
public Action:Command_Explode(client, args)
{
	if (!CanUseCMD(client, gAdminFlagHelper)) return (Plugin_Handled);

	decl Float:position[3];
	if (!GetPlayerEye(client, position))
		GetClientEyePosition(client, position);
	
	// Spawn
	new ent = CreateEntityByName("point_push");
	DispatchKeyValue(ent, "enabled", "1");
	DispatchKeyValue(ent, "magnitude", "500.0");
	DispatchKeyValue(ent, "radius", "500.0");
	DispatchKeyValue(ent, "inner_radius", "50.0");
	DispatchKeyValue(ent, "spawnflags", "24");
	DispatchSpawn(ent);

	TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent, "Enable");

	// Remove our Entity
	RemoveEntity(ent, 0.1);

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Implode
	Just the point_brush entity:
	From valve: Push sphere that will push any physics props or entity that has a movement 
	type set (e.g. NPCs) away from its origin. 
	It will not push parented objects -- so if you want to keep some entities rooted, 
	you can parent them temporarily to something static.
	------------------------------------------------------------------------------------------
*/
public Action:Command_Implode(client, args)
{
	if (!CanUseCMD(client, gAdminFlagHelper)) return (Plugin_Handled);

	decl Float:position[3];
	if (!GetPlayerEye(client, position))
		GetClientEyePosition(client, position);
	
	// Spawn
	new ent = CreateEntityByName("point_push");
	DispatchKeyValue(ent, "enabled", "1");
	DispatchKeyValue(ent, "magnitude", "-500.0");
	DispatchKeyValue(ent, "radius", "500.0");
	DispatchKeyValue(ent, "inner_radius", "50.0");
	DispatchKeyValue(ent, "spawnflags", "24");
	DispatchSpawn(ent);

	TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent, "Enable");
	
	// Remove our Entity
	RemoveEntity(ent, 0.1);

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_MarkNearEnts
	------------------------------------------------------------------------------------------
*/
public Action:Command_MarkNearEnts(client, args)
{
	if (!CanUseCMD(client, gAdminFlagHelper)) return (Plugin_Handled);

	decl Float:vEntityPos[3], Float:vClientPos[3];
	
	GetClientEyePosition(client, vClientPos);
	
	new entityCount = GetMaxEntities()-100;
	for (new ent = 2; ent < entityCount; ent++)
	{
		if (IsValidEdict(ent) && IsValidEntity(ent))
		{
			decl String:class[32], PropFieldType:type;

			if(GetEntityNetClass(ent, class, sizeof class) && (FindSendPropInfo(class, "m_vecOrigin", type)) != -1 && type == PropField_Vector) 
			{
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vEntityPos);
				//GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vEntityPos);
				if (GetVectorDistance(vClientPos, vEntityPos, false) < 1500.0)
				{
					TE_SetupGlowSprite(vEntityPos, gHalo1, 5.0, 0.5, 255);
					TE_SendToClient(client);
					/*
					if(GetEntityNetClass(ent, class, sizeof class) && (FindSendPropInfo(class, "m_vecMins", type)) != -1 && type == PropField_Vector) 
					{
						DrawBoundingBox(ent);
					}
					else
					{
						TE_SetupGlowSprite(vEntityPos, gHalo1, 5.0, 0.5, 255);
						TE_SendToClient(client);
					}
					*/
				}
			}
		}
	}

	return (Plugin_Handled);
}
