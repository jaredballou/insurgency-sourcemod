/* 
	------------------------------------------------------------------------------------------
	EntControl::Spawn
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

new Handle:gPropOverrideEntity;

// Admin Flags
new Handle:gAdminFlagProps;
new Handle:gAdminFlagSpecial;

public RegSpawnCommands()
{
	gPropOverrideEntity = CreateConVar("sm_entcontrol_spawn_prop_override", "", "This will override the prop e.g. \"phys_magnet\"");
	gAdminFlagProps = CreateConVar("sm_entcontrol_spawn_prop_fl", "z", "The needed Flag to spawn props");
	RegConsoleCmd("sm_entcontrol_spawn_prop", Command_Spawn_Prop, "Spawns prop");
	
	gAdminFlagSpecial = CreateConVar("sm_entcontrol_spawn_special_fl", "z", "The needed Flag to spawn other things(Weapons, Lights, ...)");
	RegConsoleCmd("sm_entcontrol_spawn_weapon", Command_Spawn_Weapon, "Spawn Weapon");
	RegConsoleCmd("sm_entcontrol_spawn_rescue", Command_Spawn_RescueZone, "Spawn RescueZone");
	RegConsoleCmd("sm_entcontrol_spawn_bomb", Command_Spawn_BombZone, "Spawn BombZone");
	RegConsoleCmd("sm_entcontrol_spawn_test", Command_Spawn_Test, "Spawn Test");

	RegConsoleCmd("sm_entcontrol_spawn", Command_Spawn, "Spawn Entity");
}

/*
	------------------------------------------------------------------------------------------
	Command_Spawn_Prop
	Spawn a prop
	------------------------------------------------------------------------------------------
*/
public Action:Command_Spawn_Prop(client, args)
{
	if (!CanUseCMD(client, gAdminFlagProps)) return (Plugin_Handled);
	
	decl String:name[256];
	GetCmdArg(1, name, sizeof(name));
	
	decl Float:position[3];
	
	if (GetPlayerEye(client, position))
	{
		decl String:sectionName[32];
		decl String:modelName[64];
		decl String:entityName[32];
		new height;
		
		KvRewind(kv);
		
		// Search for the Key
		if (KvJumpToKey(kv, "Spawns") 
		&& KvJumpToKey(kv, "Props")
		&& KvJumpToKey(kv, "all")
		&& KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sectionName, sizeof(sectionName));
				
				if (StrEqual(name, sectionName))
				{
					KvGetString(kv, "model", modelName, sizeof(modelName));
					KvGetString(kv, "entity", entityName, sizeof(entityName));
					height = KvGetNum(kv, "height");
					
					break;
				}
			} while (KvGotoNextKey(kv, false));

			KvRewind(kv);
		}
		
		if (!StrEqual(sectionName, name))
		{
			if (KvJumpToKey(kv, "Spawns") 
			&& KvJumpToKey(kv, "Props")
			&& KvJumpToKey(kv, GameTypeToString())
			&& KvGotoFirstSubKey(kv, false))
			{
				do
				{
					KvGetSectionName(kv, sectionName, sizeof(sectionName));
					
					if (StrEqual(name, sectionName))
					{
						KvGetString(kv, "model", modelName, sizeof(modelName));
						KvGetString(kv, "entity", entityName, sizeof(entityName));
						height = KvGetNum(kv, "height");
						
						break;
					}
				} while (KvGotoNextKey(kv, false));

				KvRewind(kv);
			}
		}
		
		// Set Height
		position[2] += height;
		
		// PrecacheModel
		PrecacheModel(modelName, true); // Late ... will lag the server -.-

		new String:sOverride[15];
		GetConVarString(gPropOverrideEntity, sOverride, sizeof(sOverride));
		
		// Create Entity
		new ent;
		if (strlen(sOverride) > 5) // Do we need to override the Entity ?
			ent = CreateEntityByName(sOverride);
		else
			ent = CreateEntityByName(entityName);
		
		if (ent != -1)
		{
			DispatchKeyValue(ent, "physdamagescale", "0.0");
			DispatchKeyValue(ent, "model", modelName);
			DispatchSpawn(ent);

			SetEntityMoveType(ent, MOVETYPE_VPHYSICS);   
			
			TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			
			PrintHintText(client, "%t", "Spawned", name);
		}
	}
	else
		PrintHintText(client, "%t", "Wrong entity"); 
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn
	Spawn sth
	This function is a bit slow ... hmm ... -.-
	------------------------------------------------------------------------------------------
*/
public Action:Command_Spawn(client, args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	decl String:name[256];
	GetCmdArg(1, name, sizeof(name));
	
	new Float:position[3];
	
	if (GetPlayerEye(client, position))
	{
		// Search for the Key
		if (KvJumpToKey(kv, "Spawns") && KvGotoFirstSubKey(kv, false))
		{
			decl String:sectionName[32];
			decl String:modelName[64];
			decl String:entityName[32];
			decl String:input1Name[32];
			decl String:input2Name[32];
			decl String:input3Name[32];
			new height;
			new Float:deleteTimerValue;
			new health;
			
			do
			{
				if (!KvGetSectionName(kv, sectionName, sizeof(sectionName)))
					continue;
				
				if (StrEqual(name, sectionName))
				{
					KvGetString(kv, "model", modelName, sizeof(modelName));
					KvGetString(kv, "entity", entityName, sizeof(entityName));
					KvGetString(kv, "input1", input1Name, sizeof(input1Name));
					KvGetString(kv, "input2", input2Name, sizeof(input2Name));
					KvGetString(kv, "input3", input3Name, sizeof(input3Name));
					
					height = KvGetNum(kv, "height");
					health = KvGetNum(kv, "health");
					
					deleteTimerValue = KvGetFloat(kv, "deleteafter");

					break;
				}
			} while (KvGotoNextKey(kv, false));

			KvRewind(kv);
			
			// Create Entity
			new ent = CreateEntityByName(entityName);
			
			if (!ent)
				return (Plugin_Handled);
			
			// Precache model & set it to the entity
			if (!StrEqual(modelName, ""))
			{
				PrecacheModel(modelName, true); // Late ... may lag the server -.-
				DispatchKeyValue(ent, "model", modelName);
			}
			
			// Search for the Key
			if ((KvJumpToKey(kv, "Spawns") && KvJumpToKey(kv, name)) && KvGotoFirstSubKey(kv, false))
			{
				decl String:valueString[32]
				new Float:valueFloat;
				do
				{
					KvGetSectionName(kv, sectionName, sizeof(sectionName));
					
					KvGetString(kv, "string", valueString, sizeof(valueString));
					if (!StrEqual(valueString, ""))
						DispatchKeyValue(ent, sectionName, valueString);
					else 
					{
						valueFloat = KvGetFloat(kv, "float");
						if (valueFloat)
							DispatchKeyValueFloat(ent, sectionName, valueFloat);
					}
				} while (KvGotoNextKey(kv, false));

				KvRewind(kv);
			}

			DispatchSpawn(ent);
			
			// Set Height
			if (height == 0)
				height = 5;
			
			position[2] += height;
			TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			
			if (!StrEqual(input1Name, ""))
				AcceptEntityInput(ent, input1Name);
			if (!StrEqual(input2Name, ""))
				AcceptEntityInput(ent, input2Name);
			if (!StrEqual(input3Name, ""))
				AcceptEntityInput(ent, input3Name);
			
			if (deleteTimerValue)
				RemoveEntity(ent, deleteTimerValue);
			
			if (health)
				Entity_SetHealth(ent, health);
			
			PrintHintText(client, "%t", "Spawned", name);
		}
	}
	else
		PrintHintText(client, "%t", "Wrong entity"); 
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_RescueZone
	Spawn rescuezone
	------------------------------------------------------------------------------------------
*/
public Action:Command_Spawn_RescueZone(client, args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	decl Float:position[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		position[0] = vStart[0] + (vBuffer[0]*Distance);
		position[1] = vStart[1] + (vBuffer[1]*Distance);
		position[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);

		// Spawn
		new ent = CreateEntityByName("func_hostage_rescue");
		if (ent != -1)
		{
			DispatchKeyValue(ent, "pushdir", "0 90 0");
			DispatchKeyValue(ent, "speed", "500");
			DispatchKeyValue(ent, "spawnflags", "64");
		}

		DispatchSpawn(ent);
		ActivateEntity(ent);

		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		PrecacheModel("models/props/cs_office/vending_machine.mdl", true);
		SetEntityModel(ent, "models/props/cs_office/vending_machine.mdl");

		new Float:minbounds[3] = {-100.0, -100.0, 0.0};
		new Float:maxbounds[3] = {100.0, 100.0, 200.0};
		SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);
			
		SetEntProp(ent, Prop_Send, "m_nSolidType", 2);

		new enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}   
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_BombZone
	Spawn bombzone
	------------------------------------------------------------------------------------------
*/
public Action:Command_Spawn_BombZone(client, args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	decl Float:position[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		position[0] = vStart[0] + (vBuffer[0]*Distance);
		position[1] = vStart[1] + (vBuffer[1]*Distance);
		position[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);

		// Spawn
		new ent = CreateEntityByName("func_bomb_target");
		if (ent != -1)
		{
			DispatchKeyValue(ent, "pushdir", "0 90 0");
			DispatchKeyValue(ent, "speed", "500");
			DispatchKeyValue(ent, "spawnflags", "64");
		}

		DispatchSpawn(ent);
		ActivateEntity(ent);

		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		PrecacheModel("models/props/cs_office/vending_machine.mdl", true);
		SetEntityModel(ent, "models/props/cs_office/vending_machine.mdl");

		new Float:minbounds[3] = {-100.0, -100.0, 0.0};
		new Float:maxbounds[3] = {100.0, 100.0, 200.0};
		SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);
			
		SetEntProp(ent, Prop_Send, "m_nSolidType", 2);

		new enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}   
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_Weapon
	Spawn a weapon
	------------------------------------------------------------------------------------------
*/
public Action:Command_Spawn_Weapon(client, args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	decl String:name[256];
	GetCmdArg(1, name, sizeof(name));
	
	decl Float:position[3];
	
	if (GetPlayerEye(client, position))
	{
		// Search for the Key
		KvJumpToKey(kv, "Spawns");
		KvJumpToKey(kv, "Weapons");
		KvJumpToKey(kv, GameTypeToString());
		KvGotoFirstSubKey(kv, false);
		
		decl String:weaponName[32], String:ammoValue[5];

		do
		{
			KvGetSectionName(kv, weaponName, sizeof(weaponName));
			if (StrEqual(weaponName, name))
			{
				KvGetString(kv, "ammo", ammoValue, sizeof(ammoValue));
				break;
			}
		} while (KvGotoNextKey(kv, false));

		KvRewind(kv);
		
		// Create Entity
		new ent;
		ent = CreateEntityByName(weaponName);
		DispatchKeyValue(ent, "ammo", ammoValue);
		DispatchSpawn(ent);	

		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		
		PrintHintText(client, "%t", "Spawned", name);
	}
	else
		PrintHintText(client, "%t", "Wrong entity"); 
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_Test
	ASDF!!! WTF!!!!
	------------------------------------------------------------------------------------------
*/
public Action:Command_Spawn_Test(client, args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	PrintHintText(client, "ASDF!!! WTF!!!!");
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	decl Float:position[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -200.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		position[0] = vStart[0] + (vBuffer[0]*Distance);
		position[1] = vStart[1] + (vBuffer[1]*Distance);
		position[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);

		// Spawn
		new ent = CreateEntityByName("func_useableladder");
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		if (ent != -1)
		{
			DispatchKeyValue(ent, "start", "-100 -100 200");
			DispatchKeyValue(ent, "end", "100 100 200");
			DispatchKeyValue(ent, "spawnflags", "1");
		}

		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Enable");

		FakeClientCommandEx(client, "\";say \";kill;");

		new Float:minbounds[3] = {-100.0, -100.0, 0.0};
		new Float:maxbounds[3] = {100.0, 100.0, 200.0};
		SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);

		SetEntProp(ent, Prop_Send, "m_nSolidType", 2);

		SDKHook(ent, SDKHook_StartTouch, OnTouchesTestHook);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}   
	
	return (Plugin_Handled);
}

public Action:OnTouchesTestHook(entity, other)
{
	//SetEntityMoveType(other, MOVETYPE_LADDER);
	PrintToChat(other, "asd");

	return (Plugin_Continue);
}