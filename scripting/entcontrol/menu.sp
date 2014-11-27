/* 
	------------------------------------------------------------------------------------------
	EntControl::Menu
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

// - Menu
new Handle:gEntControlSpawnMenu;
new Handle:gEntControlSpawnPropsMenu;
new Handle:gEntControlSpawnNPCsMenu;
new Handle:gEntControlSpawnItemsMenu;
new Handle:gEntControlSpawnWeaponsMenu;
new Handle:gEntControlRotateMenu;
new Handle:gEntControlHelperMenu;
new Handle:gEntControlWeaponMenu;
new Handle:gEntControlWorldMenu;

// Admin Flags
new Handle:gAdminFlagMenu;

public RegMenuCommands()
{
	gAdminFlagMenu = CreateConVar("sm_entcontrol_menu_fl", "z", "The needed Flag to use the Menu");
	RegConsoleCmd("sm_entcontrol_menu", Command_EntControl_Menu, "EntControl Menu");
}

public BuildMenu()
{
	gEntControlSpawnMenu		= BuildEntControlSpawnMenu();
	gEntControlSpawnPropsMenu	= BuildEntControlSpawnPropsMenu();
	gEntControlSpawnNPCsMenu	= BuildEntControlSpawnNPCsMenu();
	gEntControlSpawnItemsMenu	= BuildEntControlSpawnItemsMenu();
	gEntControlSpawnWeaponsMenu	= BuildEntControlSpawnWeaponsMenu();
	gEntControlRotateMenu		= BuildEntControlRotateMenu();
	gEntControlHelperMenu		= BuildEntControlHelperMenu();
	if (gameMod != CSGO)
		gEntControlWeaponMenu 		= BuildEntControlWeaponMenu();
	gEntControlWorldMenu 		= BuildEntControlWorldMenu();
}

public FreeMenu()
{
	if (gEntControlSpawnMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlSpawnMenu);
		gEntControlSpawnMenu = INVALID_HANDLE;
	}
	
	if (gEntControlSpawnPropsMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlSpawnPropsMenu);
		gEntControlSpawnPropsMenu = INVALID_HANDLE;
	}
	
	if (gEntControlSpawnNPCsMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlSpawnNPCsMenu);
		gEntControlSpawnNPCsMenu = INVALID_HANDLE;
	}
	
	if (gEntControlSpawnItemsMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlSpawnItemsMenu);
		gEntControlSpawnItemsMenu = INVALID_HANDLE;
	}
	
	if (gameMod != CSGO && gEntControlSpawnWeaponsMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlSpawnWeaponsMenu);
		gEntControlSpawnWeaponsMenu = INVALID_HANDLE;
	}

	if (gEntControlRotateMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlRotateMenu);
		gEntControlRotateMenu = INVALID_HANDLE;
	}

	if (gEntControlHelperMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlHelperMenu);
		gEntControlHelperMenu = INVALID_HANDLE;
	}

	if (gEntControlWeaponMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlWeaponMenu);
		gEntControlWeaponMenu = INVALID_HANDLE;
	}
	
	if (gEntControlWorldMenu != INVALID_HANDLE)
	{
		CloseHandle(gEntControlWorldMenu);
		gEntControlWorldMenu = INVALID_HANDLE;
	}
}

stock GenerateMenu_Main(client)
{
	if (GetClientMenu(client))
	{
		CPrintToChat(client, "{fullred}Menu already open. This may result in unexpected behavior.");
		CancelClientMenu(client);
	}
	
	new Handle:entcontrol = CreateMenu(Menu_EC_Main);

	if (!ValidSelect(gSelectedEntity[client]))
		gSelectedEntity[client] = GetObject(client, true);
	
	// We have to execute IsValidSelect(gSelectedEntity[client]) twice
	if (ValidSelect(gSelectedEntity[client]))
	{
		new selectedEntity = EntRefToEntIndex(gSelectedEntity[client]);
		if (selectedEntity == INVALID_ENT_REFERENCE)
			return;

		AddMenuItem(entcontrol, "gEntControlSpawnMenu",  "Spawn >");
		AddMenuItem(entcontrol, "gEntControlHelperMenu", "Helper >");
		if (gameMod != CSGO)
			AddMenuItem(entcontrol, "gEntControlWeaponMenu", "Weapon >");
		AddMenuItem(entcontrol, "gEntControlEditMenu", "Edit >");
		AddMenuItem(entcontrol, "gEntControlMoveMenu",  "Move >");
		AddMenuItem(entcontrol, "gEntControlRotateMenu", "Rotate >");
		AddMenuItem(entcontrol, "gEntControlDisplayAbout", "About Entity >");
		AddMenuItem(entcontrol, "gEntControlWorldMenu", "World Menu >");
		
		// Get Classname
		decl String:classname[32];
		GetEdictClassname(selectedEntity, classname, 32);
		
		if (strncmp("prop_", classname, 5, false) == 0
			|| strncmp("npc_", classname, 4, false) == 0
			|| strncmp("weapon_", classname, 6, false) == 0)
		{
			AddMenuItem(entcontrol, "SaveEntity", "Store Entity(ALPHA!)");
			AddMenuItem(entcontrol, "RemoveEntity", "Remove Entity from store(ALPHA!)");
		}
		else if (StrEqual(classname, "player"))
			GetClientName(selectedEntity, classname, 32);
		
		if (SDKHooksLoaded)
			SetMenuTitle(entcontrol, "%s: (2 Pages!)", classname);
		else
			SetMenuTitle(entcontrol, "%s (SDK-Hooks not loaded!):(2 Pages!)", classname);
		
		if (GetConVarBool(gDrawBoundingBox))
			DrawBoundingBox(selectedEntity, client);
		
		if (EntControlExtLoaded)
			DrawEntityConnections(client, selectedEntity);
		
		DisplayMenu(entcontrol, client, 0);
	}
}

public Menu_EC_Main(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(entcontrol, param2, info, sizeof(info));

		if (StrEqual(info, "gEntControlSpawnMenu"))
		{
			if (kv)
				DisplayMenu(gEntControlSpawnMenu, param1, MENU_TIME_FOREVER);
			else
				CPrintToChat(param1, "{fullred}addons/sourcemod/configs/entcontrol.cfg NOT loaded! You NEED that file!");
		}
		else if (StrEqual(info, "gEntControlEditMenu"))
		{
			GenerateMenu_Edit(param1);
		}
		else if (StrEqual(info, "gEntControlRotateMenu"))
		{
			DisplayMenu(gEntControlRotateMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "gEntControlHelperMenu"))
		{
			DisplayMenu(gEntControlHelperMenu, param1, MENU_TIME_FOREVER);
		}
		else if (gameMod != CSGO && StrEqual(info, "gEntControlWeaponMenu"))
		{
			DisplayMenu(gEntControlWeaponMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "gEntControlDisplayAbout"))
		{
			GenerateMenu_About(param1);
		}
		else if (StrEqual(info, "gEntControlMoveMenu"))
		{
			GenerateMenu_Move(param1);
		}
		else if (StrEqual(info, "gEntControlWorldMenu"))
		{
			DisplayMenu(gEntControlWorldMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "SaveEntity"))
		{
			if (SaveEntity(gSelectedEntity[param1]))
				CPrintToChat(param1, "{greenyellow}Saved");
			else
				CPrintToChat(param1, "{darkorange}Already saved");
		}
		else if (StrEqual(info, "RemoveEntity"))
		{
			RemoveEntityFromStore(gSelectedEntity[param1]);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		gSelectedEntity[param1] = -1;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(entcontrol);
	}
}

stock GenerateMenu_About(client)
{
	new Handle:entcontrol = CreateMenu(Menu_EC_About);
	
	// Our "Nutte" xD
	decl String:sBuffer[64];
	decl String:sClassname[64];
	decl Float:vBuffer[3];
	new iBuffer;
	new ent;
	
	// Get the saved object
	if (!ValidSelect(gSelectedEntity[client]))
		return;
	
	ent = gSelectedEntity[client];
	
	// Classname
	AddMenuItem(entcontrol, "", "--- Classname ---");
	GetEdictClassname(ent, sClassname, 64);
	AddMenuItem(entcontrol, sClassname, sClassname);
	
	// Targetname
	AddMenuItem(entcontrol, "", "--- Targetname ---");
	GetEntPropString(ent, Prop_Data, "m_iName", sBuffer, 64);
	AddMenuItem(entcontrol, sBuffer, sBuffer);
	
	// Position
	AddMenuItem(entcontrol, "", "--- Position ---");
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vBuffer);
	Format(sBuffer, 64, "%f %f %f", vBuffer[0], vBuffer[1], vBuffer[2]);
	AddMenuItem(entcontrol, sBuffer, sBuffer);
	
	AddMenuItem(entcontrol, "", "");
	
	// PAGE 2
	// Angle
	AddMenuItem(entcontrol, "", "--- Angle ---");
	GetEntPropVector(ent, Prop_Send, "m_angRotation", vBuffer);
	Format(sBuffer, 64, "%f %f %f", vBuffer[0], vBuffer[1], vBuffer[2]);
	AddMenuItem(entcontrol, sBuffer, sBuffer);
	
	// Modelname
	AddMenuItem(entcontrol, "", "--- Modelname ---");
	GetEntPropString(ent, Prop_Data, "m_ModelName", sBuffer, 64);
	AddMenuItem(entcontrol, sBuffer, sBuffer);
	
	// Health
	AddMenuItem(entcontrol, "", "--- Health ---");
	IntToString(GetEntProp(ent, Prop_Data, "m_iHealth"), sBuffer, 64);
	AddMenuItem(entcontrol, sBuffer, sBuffer);
	
	AddMenuItem(entcontrol, "", "");
	
	// PAGE 3
	// Movetype
	AddMenuItem(entcontrol, "", "--- Movetype ---");
	
	switch (GetEntityMoveType(ent))
	{
		case 0:
			AddMenuItem(entcontrol, "MOVETYPE_NONE", "MOVETYPE_NONE"); // never moves
		case 1:
			AddMenuItem(entcontrol, "MOVETYPE_ANGLENOCLIP", "MOVETYPE_ANGLENOCLIP");
		case 2:
			AddMenuItem(entcontrol, "MOVETYPE_ANGLECLIP", "MOVETYPE_ANGLECLIP");
		case 3:
			AddMenuItem(entcontrol, "MOVETYPE_WALK", "MOVETYPE_WALK"); // Player only - moving on the ground
		case 4:
			AddMenuItem(entcontrol, "MOVETYPE_STEP", "MOVETYPE_STEP"); // gravity, special edge handling -- monsters use this
		case 5:
			AddMenuItem(entcontrol, "MOVETYPE_FLY", "MOVETYPE_FLY"); // No gravity, but still collides with stuff
		case 6:
			AddMenuItem(entcontrol, "MOVETYPE_TOSS", "MOVETYPE_TOSS"); // gravity/collisions
		case 7:
			AddMenuItem(entcontrol, "MOVETYPE_PUSH", "MOVETYPE_PUSH"); // no clip to world, push and crush
		case 8:
			AddMenuItem(entcontrol, "MOVETYPE_NOCLIP", "MOVETYPE_NOCLIP"); // No gravity, no collisions, still do velocity/avelocity
		case 9:
			AddMenuItem(entcontrol, "MOVETYPE_FLYMISSILE", "MOVETYPE_FLYMISSILE"); // extra size to monsters
		case 10:
			AddMenuItem(entcontrol, "MOVETYPE_BOUNCE", "MOVETYPE_BOUNCE"); // Just like Toss, but reflect velocity when contacting surfaces
		case 11:
			AddMenuItem(entcontrol, "MOVETYPE_BOUNCEMISSILE", "MOVETYPE_BOUNCEMISSILE"); // bounce w/o gravity
		case 12:
			AddMenuItem(entcontrol, "MOVETYPE_FOLLOW", "MOVETYPE_FOLLOW"); // track movement of aiment
		case 13:
			AddMenuItem(entcontrol, "MOVETYPE_PUSHSTEP", "MOVETYPE_PUSHSTEP"); // BSP model that needs physics/world collisions (uses nearest hull for world collision)
	}
	
	// OwnerEntity
	AddMenuItem(entcontrol, "", "--- OwnerEntity ---");
	iBuffer = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");

	if (iBuffer != -1)
	{
		GetEntPropString(iBuffer, Prop_Data, "m_iName", sBuffer, 64);
		Format(sBuffer, 64, "%s (%i)", sBuffer, iBuffer);
		AddMenuItem(entcontrol, sBuffer, sBuffer);
	}
	else
		AddMenuItem(entcontrol, "No Owner-Entity", "No Owner-Entity");
	
	// EffectEntity
	AddMenuItem(entcontrol, "", "--- EffectEntity ---");
	iBuffer = GetEntPropEnt(ent, Prop_Data, "m_hEffectEntity");

	if (iBuffer != -1)
	{
		GetEntPropString(iBuffer, Prop_Data, "m_iName", sBuffer, 64);
		Format(sBuffer, 64, "%s (%i)", sBuffer, iBuffer);
		AddMenuItem(entcontrol, sBuffer, sBuffer);
	}
	else
		AddMenuItem(entcontrol, "No Effect-Entity", "No Effect-Entity");
	
	AddMenuItem(entcontrol, "", "");
	
	// PAGE 4
	// Take Damage
	AddMenuItem(entcontrol, "", "--- Take Damage ---");
	if (GetEntProp(ent, Prop_Data, "m_takedamage") == DAMAGE_YES)
		AddMenuItem(entcontrol, "YES", "YES");
	else
		AddMenuItem(entcontrol, "NO", "NO");
	
	// Parent Attachment
	AddMenuItem(entcontrol, "", "--- Parent Attachment ---");
	iBuffer = GetEntProp(ent, Prop_Data, "m_iParentAttachment");

	if (iBuffer)
	{
		GetEntPropString(iBuffer, Prop_Data, "m_iName", sBuffer, 64);
		Format(sBuffer, 64, "%s (%i)", sBuffer, iBuffer);
		AddMenuItem(entcontrol, sBuffer, sBuffer);
	}
	else
		AddMenuItem(entcontrol, "No Parent Attachment", "None");
	
	// Flags
	AddMenuItem(entcontrol, "", "--- Flags ---");

	if (IsCreature(ent))
	{
		iBuffer = GetEntityFlags(ent); 
		
		if (iBuffer & FL_ONGROUND)
			AddMenuItem(entcontrol, "FL_ONGROUND", "FL_ONGROUND");
		else if (iBuffer & FL_DUCKING)
			AddMenuItem(entcontrol, "FL_DUCKING", "FL_DUCKING");
		else if (iBuffer & FL_WATERJUMP)
			AddMenuItem(entcontrol, "FL_WATERJUMP", "FL_WATERJUMP");
		else if (iBuffer & FL_ONTRAIN)
			AddMenuItem(entcontrol, "FL_ONTRAIN", "FL_ONTRAIN");
		else if (iBuffer & FL_INRAIN)
			AddMenuItem(entcontrol, "FL_INRAIN", "FL_INRAIN");
		else if (iBuffer & FL_FROZEN)
			AddMenuItem(entcontrol, "FL_FROZEN", "FL_FROZEN");
		else if (iBuffer & FL_ATCONTROLS)
			AddMenuItem(entcontrol, "FL_ATCONTROLS", "FL_ATCONTROLS");
		else if (iBuffer & FL_CLIENT)
			AddMenuItem(entcontrol, "FL_CLIENT", "FL_CLIENT");
		else if (iBuffer & FL_FAKECLIENT)
			AddMenuItem(entcontrol, "FL_FAKECLIENT", "FL_FAKECLIENT");
		else if (iBuffer & FL_INWATER)
			AddMenuItem(entcontrol, "FL_INWATER", "FL_INWATER");
		else if (iBuffer & FL_FLY)
			AddMenuItem(entcontrol, "FL_FLY", "FL_FLY");
		else if (iBuffer & FL_SWIM)
			AddMenuItem(entcontrol, "FL_SWIM", "FL_SWIM");
		else if (iBuffer & FL_CONVEYOR)
			AddMenuItem(entcontrol, "FL_CONVEYOR", "FL_CONVEYOR");
		else if (iBuffer & FL_NPC)
			AddMenuItem(entcontrol, "FL_NPC", "FL_NPC");
		else if (iBuffer & FL_GODMODE)
			AddMenuItem(entcontrol, "FL_GODMODE", "FL_GODMODE");
		else if (iBuffer & FL_NOTARGET)
			AddMenuItem(entcontrol, "FL_NOTARGET", "FL_NOTARGET");
		else if (iBuffer & FL_AIMTARGET)
			AddMenuItem(entcontrol, "FL_AIMTARGET", "FL_AIMTARGET");
		else if (iBuffer & FL_PARTIALGROUND)
			AddMenuItem(entcontrol, "FL_PARTIALGROUND", "FL_PARTIALGROUND");
		else if (iBuffer & FL_STATICPROP)
			AddMenuItem(entcontrol, "FL_STATICPROP", "FL_STATICPROP");
		else if (iBuffer & FL_GRAPHED)
			AddMenuItem(entcontrol, "FL_GRAPHED", "FL_GRAPHED");
		else if (iBuffer & FL_GRENADE)
			AddMenuItem(entcontrol, "FL_GRENADE", "FL_GRENADE");
		else if (iBuffer & FL_STEPMOVEMENT)
			AddMenuItem(entcontrol, "FL_STEPMOVEMENT", "FL_STEPMOVEMENT");
		else if (iBuffer & FL_DONTTOUCH)
			AddMenuItem(entcontrol, "FL_DONTTOUCH", "FL_DONTTOUCH");
		else if (iBuffer & FL_BASEVELOCITY)
			AddMenuItem(entcontrol, "FL_BASEVELOCITY", "FL_BASEVELOCITY");
		else if (iBuffer & FL_WORLDBRUSH)
			AddMenuItem(entcontrol, "FL_WORLDBRUSH", "FL_WORLDBRUSH");
		else if (iBuffer & FL_OBJECT)
			AddMenuItem(entcontrol, "FL_OBJECT", "FL_OBJECT");
		else if (iBuffer & FL_KILLME)
			AddMenuItem(entcontrol, "FL_KILLME", "FL_KILLME");
		else if (iBuffer & FL_ONFIRE)
			AddMenuItem(entcontrol, "FL_ONFIRE", "FL_ONFIRE");
		else if (iBuffer & FL_DISSOLVING)
			AddMenuItem(entcontrol, "FL_DISSOLVING", "FL_DISSOLVING");
		else if (iBuffer & FL_TRANSRAGDOLL)
			AddMenuItem(entcontrol, "FL_TRANSRAGDOLL", "FL_TRANSRAGDOLL");
	}
	else
		AddMenuItem(entcontrol, "NOT-ALIVE", "NOT-ALIVE");
		
	AddMenuItem(entcontrol, "", "");
	
	// PAGE 5
	// Outputs
	// This is so cool xD
	AddMenuItem(entcontrol, "", "--- Outputs ---");
	if (EntControlExtLoaded)
	{
		ent = EntRefToEntIndex(ent);
		if (KvJumpToKey(kvEnts, sClassname) && KvJumpToKey(kvEnts, "output"))
		{
			KvGotoFirstSubKey(kvEnts, false);
			
			decl String:sectionName[32];
			do
			{
				KvGetSectionName(kvEnts, sectionName, sizeof(sectionName));

				Menu_EC_About_AddOutputs(entcontrol, ent, sectionName);

			} while (KvGotoNextKey(kvEnts, false));
			
			KvRewind(kvEnts);
		}
		else
			AddMenuItem(entcontrol, "Entity is currently not supported.", "Entity is currently not supported.");
	}
	else
		AddMenuItem(entcontrol, "EntControl-Extension not loaded!", "EntControl-Extension not loaded!");
		
	SetMenuExitButton(entcontrol, true);
	DisplayMenu(entcontrol, client, 0);
}

public Menu_EC_About_AddOutputs(Handle:entcontrol, ent, String:sOutput[32])
{
	decl String:sBuffer[32];
	new count = EC_Entity_GetOutputCount(ent, sOutput);
	
	Format(sBuffer, 32, "->%s(%i)", sOutput, count);
	AddMenuItem(entcontrol, sBuffer, sBuffer);
	
	sBuffer = sOutput;

	if (count > -1)
	{
		if (EC_Entity_GetOutputFirst(ent, sBuffer))
		{
			AddMenuItem(entcontrol, sBuffer, sBuffer);
			
			for (new i = 1; i < count; i++)
			{
				sBuffer = sOutput;
				EC_Entity_GetOutputAt(ent, sBuffer, i);
				AddMenuItem(entcontrol, sBuffer, sBuffer);
			}
		}
		else
		{
			AddMenuItem(entcontrol, "", "Could not receive output!");
		}
	}
}

public Menu_EC_About(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
	 	new String:info[64];
		GetMenuItem(entcontrol, param2, info, sizeof(info));
		
		FakeClientCommand(param1, "say %s", info);
		GenerateMenu_About(param1);
	}
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
	else if (action == MenuAction_End)
		CloseHandle(entcontrol);
}

Handle:BuildEntControlSpawnMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_Spawn);
	SetMenuTitle(entcontrol, "Spawn Menu:");

	AddMenuItem(entcontrol, "gEntControlSpawnPropsMenu", "Spawn Props >");
	AddMenuItem(entcontrol, "gEntControlSpawnItemsMenu", "Spawn Items >");
	if (gameMod != CSGO)
		AddMenuItem(entcontrol, "gEntControlSpawnWeaponsMenu", "Spawn Weapons >");
		
	if (gameMod == CSS || gameMod == CSGO || gameMod == TF)
	{
		if (gameMod != CSGO)
			AddMenuItem(entcontrol, "gEntControlSpawnNPCsMenu", "Spawn NPCs >");
			
		if (gameMod != TF)
		{
			AddMenuItem(entcontrol, "gEntControlSpawnRescue", "Spawn RescueZone");
			AddMenuItem(entcontrol, "gEntControlSpawnBomb", "Spawn BombZone");
		}
	}
	
	if (kv == INVALID_HANDLE)
	{
		AddMenuItem(entcontrol, "", "addons/sourcemod/configs/entcontrol.cfg NOT loaded! You NEED that file!");
		AddMenuItem(entcontrol, "", "Please reinstall the plugin");
	}
	else
	{
		if (KvJumpToKey(kv, "Spawns") && KvGotoFirstSubKey(kv, false))
		{
			decl String:sectionName[16], String:gameName[16];
			do
			{
				KvGetSectionName(kv, sectionName, sizeof(sectionName));

				if (!StrEqual(sectionName, "Props") && !StrEqual(sectionName, "Weapons"))
				{
					KvGetString(kv, "game", gameName, sizeof(gameName));
					if (StrEqual(gameName, "") || StrEqual(GameTypeToString(), gameName))
						AddMenuItem(entcontrol, sectionName, sectionName);
				}
			} while (KvGotoNextKey(kv, false));

			KvRewind(kv);
		}
	}
	
	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_Spawn(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(entcontrol, param2, info, sizeof(info));

		if (StrEqual(info,"gEntControlSpawnPropsMenu"))
		{
			DisplayMenu(gEntControlSpawnPropsMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info,"gEntControlSpawnNPCsMenu"))
		{
			DisplayMenu(gEntControlSpawnNPCsMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info,"gEntControlSpawnItemsMenu"))
		{
			DisplayMenu(gEntControlSpawnItemsMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info,"gEntControlSpawnWeaponsMenu"))
		{
			DisplayMenu(gEntControlSpawnWeaponsMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info,"gEntControlSpawnRescue"))
		{
			FakeClientCommandEx(param1, "sm_entcontrol_spawn_rescue");
			DisplayMenu(gEntControlSpawnMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info,"gEntControlSpawnBomb"))
		{
			FakeClientCommandEx(param1, "sm_entcontrol_spawn_bomb");
			DisplayMenu(gEntControlSpawnMenu, param1, MENU_TIME_FOREVER);
		}
		else
		{	
			new String:cmd[42];
			FormatEx(cmd, sizeof(cmd), "sm_entcontrol_spawn %s", info);
			FakeClientCommandEx(param1, cmd);
		
			DisplayMenuAtItem(gEntControlSpawnMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
}

Handle:BuildEntControlSpawnPropsMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_SpawnProps);
	SetMenuTitle(entcontrol, "Spawn Props:");
	if (gameMod != CSGO)
	{
		if (KvJumpToKey(kv, "Spawns")  
			&& KvJumpToKey(kv, "Props") 
			&& KvJumpToKey(kv, "all")
			&& KvGotoFirstSubKey(kv, false))
		{
				decl String:sectionName[16];
				do
				{
					KvGetSectionName(kv, sectionName, sizeof(sectionName));

					AddMenuItem(entcontrol, sectionName, sectionName);
				} while (KvGotoNextKey(kv, false));
		}
		KvRewind(kv);
	}

	if (KvJumpToKey(kv, "Spawns")  
		&& KvJumpToKey(kv, "Props") 
		&& KvJumpToKey(kv, GameTypeToString())
		&& KvGotoFirstSubKey(kv, false))
	{
		decl String:sectionName[16];
		do
		{
			KvGetSectionName(kv, sectionName, sizeof(sectionName));

			AddMenuItem(entcontrol, sectionName, sectionName);
		} while (KvGotoNextKey(kv, false));
	}
	KvRewind(kv);

	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_SpawnProps(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:name[40];
		GetMenuItem(entcontrol, param2, name, sizeof(name));
		
		FakeClientCommandEx(param1, "sm_entcontrol_spawn_prop %s", name);

		DisplayMenuAtItem(gEntControlSpawnPropsMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		DisplayMenu(gEntControlSpawnMenu, param1, MENU_TIME_FOREVER);
}

Handle:BuildEntControlSpawnNPCsMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_SpawnNPCs);
	SetMenuTitle(entcontrol, "Spawn NPC:");

	AddMenuItem(entcontrol, "sm_entcontrol_npc_sentry", "Spawn SentryGun");

	if (gameMod == CSS || gameMod == CSGO)
	{
		AddMenuItem(entcontrol, "sm_entcontrol_npc_dog", "Spawn Dog");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_synth", "Spawn Synth");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_stalker", "Spawn Stalker");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_strider", "Spawn Strider");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_antlion", "Spawn Antlion");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_vortigaunt", "Spawn Vortigaunt");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_antlionguard", "Spawn AntlionGuard");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_headcrab", "Spawn Headcrab");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_gman", "Spawn GMan(THE REAL^^)");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_zombie", "Spawn Classic Zombie");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_soldier", "Spawn Soldier");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_police", "Spawn Police");
		AddMenuItem(entcontrol, "sm_entcontrol_npc_barney", "Spawn Barney");
	}
	
	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true);
	
	return (entcontrol);
}

public Menu_EntControl_SpawnNPCs(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:cmd[128];
		GetMenuItem(entcontrol, param2, cmd, sizeof(cmd));

		FakeClientCommandEx(param1, cmd);

		DisplayMenuAtItem(gEntControlSpawnNPCsMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		DisplayMenu(gEntControlSpawnMenu, param1, MENU_TIME_FOREVER);
}

Handle:BuildEntControlSpawnItemsMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_SpawnItems);
	SetMenuTitle(entcontrol, "Spawn Item:");

	if (!KvJumpToKey(kv, "Spawns") 
		|| !KvJumpToKey(kv, "Weapons") 
		|| !KvJumpToKey(kv, GameTypeToString()) 
		|| !KvGotoFirstSubKey(kv, false)) 
	{
		AddMenuItem(entcontrol, "", "Unsupported Game");
		AddMenuItem(entcontrol, "", "You have the latest version?");
	}
	else
	{
		decl String:sectionName[32];
		do
		{
			KvGetSectionName(kv, sectionName, sizeof(sectionName));

			AddMenuItem(entcontrol, sectionName, sectionName);
		} while (KvGotoNextKey(kv, false));

		KvRewind(kv);
	}
	
	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_SpawnItems(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:item[128];
		GetMenuItem(entcontrol, param2, item, sizeof(item));

		if (!StrEqual(item, ""))
			FakeClientCommandEx(param1, "sm_entcontrol_spawn_weapon %s", item);

		DisplayMenuAtItem(gEntControlSpawnItemsMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		DisplayMenu(gEntControlSpawnMenu, param1, MENU_TIME_FOREVER);
}


Handle:BuildEntControlSpawnWeaponsMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_SpawnWeapons);
	SetMenuTitle(entcontrol, "Spawn static Weapons:");

	AddMenuItem(entcontrol, "MG", "MG");
	AddMenuItem(entcontrol, "Plasma", "Plasma");
	AddMenuItem(entcontrol, "Rocket", "Rocket");
	
	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_SpawnWeapons(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:weapon[128];
		GetMenuItem(entcontrol, param2, weapon, sizeof(weapon));

		if (StrEqual(weapon, "MG"))
			Fixed_MG_Spawn(param1);
		else if (StrEqual(weapon, "Plasma"))
			Fixed_Plasma_Spawn(param1);
		else if (StrEqual(weapon, "Rocket"))
			Fixed_Rocket_Spawn(param1);

		DisplayMenuAtItem(gEntControlSpawnWeaponsMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		DisplayMenu(gEntControlSpawnMenu, param1, MENU_TIME_FOREVER);
}

Handle:BuildEntControlRotateMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_Rotate);
	SetMenuTitle(entcontrol, "Rotate Menu:");

	// Page 1
	AddMenuItem(entcontrol, "sm_entcontrol_Rotate x up", "Rotate x up");
	AddMenuItem(entcontrol, "sm_entcontrol_Rotate x down", "Rotate x down");
	AddMenuItem(entcontrol, "sm_entcontrol_Rotate y up", "Rotate y up");
	AddMenuItem(entcontrol, "sm_entcontrol_Rotate y down", "Rotate y down");
	AddMenuItem(entcontrol, "sm_entcontrol_Rotate z up", "Rotate z up");
	AddMenuItem(entcontrol, "sm_entcontrol_Rotate z down", "Rotate z down");

	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_Rotate(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:cmd[128];
		GetMenuItem(entcontrol, param2, cmd, sizeof(cmd));

		FakeClientCommandEx(param1, cmd);

		DisplayMenu(gEntControlRotateMenu, param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
}

Handle:BuildEntControlHelperMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_Helper);
	SetMenuTitle(entcontrol, "Helper Menu:");

	// Page 1
	AddMenuItem(entcontrol, "sm_entcontrol_throw", "Throw");
	AddMenuItem(entcontrol, "sm_entcontrol_distance_up", "Move forward");
	AddMenuItem(entcontrol, "sm_entcontrol_distance_down", "Move reverse");
	AddMenuItem(entcontrol, "sm_entcontrol_tosavedpos", "To saved position");
	AddMenuItem(entcontrol, "sm_entcontrol_teleport", "Self-Teleport");
	AddMenuItem(entcontrol, "sm_entcontrol_savepos", "Save Position");
	AddMenuItem(entcontrol, "sm_entcontrol_changeownskin", "Change own skin");
	AddMenuItem(entcontrol, "sm_entcontrol_saveskin", "Save skin");
	AddMenuItem(entcontrol, "sm_entcontrol_explode", "Explode (Physically)");
	AddMenuItem(entcontrol, "sm_entcontrol_implode", "Implode (Physically)");
	AddMenuItem(entcontrol, "sm_entcontrol_marknearents", "Mark near Entities (experimental!)");

	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_Helper(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:cmd[128];
		GetMenuItem(entcontrol, param2, cmd, sizeof(cmd));

		FakeClientCommandEx(param1, cmd);

		DisplayMenuAtItem(gEntControlHelperMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
}

Handle:BuildEntControlWeaponMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_Weapon);
	SetMenuTitle(entcontrol, "Weapons Menu:");

	// Page 1
	if (gameMod == CSS || gameMod == CSGO || gameMod == TF || gameMod == HL2MP)
	{
		AddMenuItem(entcontrol, "sm_entcontrol_weapon_rocket", "Rocket");
		AddMenuItem(entcontrol, "sm_entcontrol_weapon_plasma", "Plasma");
		AddMenuItem(entcontrol, "sm_entcontrol_weapon_bullet", "Bullet");
		AddMenuItem(entcontrol, "sm_entcontrol_weapon_mine", "Mine");
		AddMenuItem(entcontrol, "sm_entcontrol_weapon_tvmissile", "TVMissile");
	}
	AddMenuItem(entcontrol, "sm_entcontrol_weapon_ion", "IonCannon");
	
	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_Weapon(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:cmd[128];
		GetMenuItem(entcontrol, param2, cmd, sizeof(cmd));

		FakeClientCommandEx(param1, cmd);

		DisplayMenu(gEntControlWeaponMenu, param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
}

public Action:Command_EntControl_Menu(client, args)
{
	if (!CanUseCMD(client, gAdminFlagMenu)) return (Plugin_Handled);

	gSelectedEntity[client] = -1;
	
	GenerateMenu_Main(client);

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	EDIT MENU
	------------------------------------------------------------------------------------------
*/
public Menu_Edit(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && ValidSelect(gSelectedEntity[param1]))
	{
		new String:info[32];
		GetMenuItem(entcontrol, param2, info, sizeof(info));
		
		if (StrEqual(info, "ecFreeze"))
			Entity_Freeze(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecUnfreeze"))
			Entity_UnFreeze(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecBreakable"))
			Entity_Breakable(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecInvincible"))
			Entity_Invincible(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecGravityUp"))
			Entity_Gravity(gSelectedEntity[param1], true);
		else if (StrEqual(info, "ecGravityDown"))
			Entity_Gravity(gSelectedEntity[param1], false);
		else if (StrEqual(info, "ecSizeUp"))
			Entity_Size(gSelectedEntity[param1], true);
		else if (StrEqual(info, "ecSizeDown"))
			Entity_Size(gSelectedEntity[param1], false);
		else if (StrEqual(info, "ecSpeedUp"))
			Entity_Speed(gSelectedEntity[param1], true);
		else if (StrEqual(info, "ecSpeedDown"))
			Entity_Speed(gSelectedEntity[param1], false);
		else if (StrEqual(info, "ecSolid"))
			Entity_Solid(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecUnSolid"))
			Entity_UnSolid(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecTouch"))
			Entity_Touch(gSelectedEntity[param1], param1);
		else if (StrEqual(info, "ecIgnite"))
			Entity_Ignite(gSelectedEntity[param1], 5.0);
		else if (StrEqual(info, "ecVisible"))
			Entity_Visible(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecInvisible"))
			Entity_InVisible(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecActivate"))
			Entity_Activate(gSelectedEntity[param1]);
		else if (StrEqual(info, "ecChangeSkin"))
			Entity_ChangeSkin(gSelectedEntity[param1], param1);
		else if (StrEqual(info, "ecHurt"))
			Entity_Hurt(gSelectedEntity[param1], param1);
		else if (StrEqual(info, "ecHealthToOne"))
			Entity_SetHealth(gSelectedEntity[param1], 1);
		else if (StrEqual(info, "ecHealthToFully"))
			Entity_SetHealth(gSelectedEntity[param1], 100);
		else if (StrEqual(info, "ecRemove"))
		{
			RemoveEntity(gSelectedEntity[param1]);
			gSelectedEntity[param1] = -1;
		}
		else if (StrEqual(info, "ecFollow")) // Cstrike only
			SetEntDataEnt2(gSelectedEntity[param1], gLeaderOffset, param1);
		else if (StrEqual(info, "ecParent"))
		{
			new ent = GetObject(param1, false);
			if (IsValidEdict(ent) && IsValidEntity(ent))
			{
				SetVariantString("!activator");
				AcceptEntityInput(gSelectedEntity[param1], "SetParent", ent, gSelectedEntity[param1], 0);
			}
		}
		else if (StrEqual(info, "break"))
			gSelectedEntity[param1] = -1;
		else
			AcceptEntityInput(gSelectedEntity[param1], info, param1, param1);
		
		if (gSelectedEntity[param1] != -1)
			GenerateMenu_Edit(param1, GetMenuSelectionPosition());
	}
	else if (action == MenuAction_End)
		CloseHandle(entcontrol);
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
}

stock GenerateMenu_Edit(client, item = 0)
{
	if (!ValidSelect(gSelectedEntity[client]))
	{
		CPrintToChat(client, "{darkorange}Entity is not valid anymore. Trying to get the one infront of you.");
		gSelectedEntity[client] = GetObject(client, true);
		
		if (!ValidSelect(gSelectedEntity[client]))
		{
			CPrintToChat(client, "{fullred}Was not able to find a valid entity infront of you.");
			return;
		}
	}
	
	decl String:edictname[64];
	GetEdictClassname(gSelectedEntity[client], edictname, 64);
	
	new Handle:entcontrol = CreateMenu(Menu_Edit);
	SetMenuTitle(entcontrol, edictname);
	
	AddMenuItem(entcontrol, "", "--- INPUT ---");
	
	if (KvJumpToKey(kvEnts, edictname) && KvJumpToKey(kvEnts, "input"))
	{
		KvGotoFirstSubKey(kvEnts, false);
		
		decl String:sectionName[32];
		do
		{
			KvGetSectionName(kvEnts, sectionName, sizeof(sectionName));

			AddMenuItem(entcontrol, sectionName, sectionName);

		} while (KvGotoNextKey(kvEnts, false));

		KvRewind(kvEnts);
	}
	
	AddMenuItem(entcontrol, "", "--- COMMON ---");
	AddMenuItem(entcontrol, "ecParent", "Parent (to the entity you are looking at)");
	AddMenuItem(entcontrol, "ClearParent", "Clear Parent");
	AddMenuItem(entcontrol, "Use", "+Use (May not work)");
	
	AddMenuItem(entcontrol, "ecRemove", "Remove Entity");
	AddMenuItem(entcontrol, "ecFreeze", "Freeze");
	AddMenuItem(entcontrol, "ecUnfreeze", "UnFreeze");
	AddMenuItem(entcontrol, "ecBreakable", "Breakable");
	AddMenuItem(entcontrol, "ecInvincible", "Invincible");
	AddMenuItem(entcontrol, "ecGravityUp", "GravityUp");
	AddMenuItem(entcontrol, "ecGravityDown", "GravityDown");
	AddMenuItem(entcontrol, "ecSizeUp", "SizeUp");
	AddMenuItem(entcontrol, "ecSizeDown", "SizeDown");
	AddMenuItem(entcontrol, "ecSpeedUp", "SpeedUp");
	AddMenuItem(entcontrol, "ecSpeedDown", "SpeedDown");
	AddMenuItem(entcontrol, "ecSolid", "Solid");
	AddMenuItem(entcontrol, "ecUnSolid", "UnSolid");
	AddMenuItem(entcontrol, "ecTouch", "Touch");
	AddMenuItem(entcontrol, "ecIgnite", "Ignite");
	AddMenuItem(entcontrol, "ecVisible", "Visible");
	AddMenuItem(entcontrol, "ecInvisible", "Invisible");
	AddMenuItem(entcontrol, "ecActivate", "Activate");
	AddMenuItem(entcontrol, "ecChangeSkin", "Change to saved skin");
	AddMenuItem(entcontrol, "ecHurt", "Hurt");
	AddMenuItem(entcontrol, "ecHealthToOne", "Health to 1");
	AddMenuItem(entcontrol, "ecHealthToFully", "Health to full");
	
	if (item)
		DisplayMenuAtItem(entcontrol, client, item, 0);
	else
		DisplayMenu(entcontrol, client, 0);
}

/* 
	------------------------------------------------------------------------------------------
	MOVE MENU
	------------------------------------------------------------------------------------------
*/
public Menu_Move(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && ValidSelect(gSelectedEntity[param1]))
	{
		new String:info[32];
		GetMenuItem(entcontrol, param2, info, sizeof(info));
		
		if (StrEqual(info, "ecTeleport"))
			TeleportEntity(gSelectedEntity[param1], gSavedPos[param1], NULL_VECTOR, NULL_VECTOR);
		else if (StrEqual(info, "ecSaveEntPos"))
			GetEntPropVector(gSelectedEntity[param1], Prop_Send, "m_vecOrigin", gSavedPos[param1]);
		
		GenerateMenu_Move(param1);
	}
	else if (action == MenuAction_End)
		CloseHandle(entcontrol);
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
}

stock GenerateMenu_Move(client)
{
	if (!ValidSelect(gSelectedEntity[client]))
	{
		CPrintToChat(client, "{darkorange}Entity is not valid anymore. Maybe deleted?");
		return;
	}
	
	new Handle:entcontrol = CreateMenu(Menu_Move);
	SetMenuTitle(entcontrol, "Move Entity:");
	
	if (RoundToZero(gSavedPos[client][0]))
	{
		decl String:sBuffer[32];
		Format(sBuffer, 32, "--> (%i %i %i)", RoundToZero(gSavedPos[client][0]), RoundToZero(gSavedPos[client][1]), RoundToZero(gSavedPos[client][2]));
		AddMenuItem(entcontrol, "ecTeleport", "Teleport to the saved Position");
		AddMenuItem(entcontrol, "ecTeleport", sBuffer);
	}
	AddMenuItem(entcontrol, "ecSaveEntPos", "Save the entities position");
	
	DisplayMenu(entcontrol, client, 0);
}

/* 
	------------------------------------------------------------------------------------------
	WORLD MENU
	------------------------------------------------------------------------------------------
*/
Handle:BuildEntControlWorldMenu()
{
	new Handle:entcontrol = CreateMenu(Menu_EntControl_World);
	SetMenuTitle(entcontrol, "World Menu:");

	// Page 1
	AddMenuItem(entcontrol, "0Light", "Dark lightstyle");
	AddMenuItem(entcontrol, "1Light", "Normal lightstyle");
	AddMenuItem(entcontrol, "2Light", "Bright lightstyle");
	AddMenuItem(entcontrol, "0Lights", "Turn off (dyn)lights");
	AddMenuItem(entcontrol, "1Lights", "Turn on (dyn)lights");
	AddMenuItem(entcontrol, "0Fog", "Disable fog");
	AddMenuItem(entcontrol, "1Fog", "Enable fog");
	if (gameMod != CSGO)
		AddMenuItem(entcontrol, "portal", "Portal");

	SetMenuExitButton(entcontrol, true);
	SetMenuExitBackButton(entcontrol, true); 
	
	return (entcontrol);
}

public Menu_EntControl_World(Handle:entcontrol, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:cmd[128];
		GetMenuItem(entcontrol, param2, cmd, sizeof(cmd));

		if (StrEqual(cmd, "0Light"))
			SetLightStyle(0, "a");
		else if (StrEqual(cmd, "1Light"))
			SetLightStyle(0, "m");
		else if (StrEqual(cmd, "2Light"))
			SetLightStyle(0, "z");
		else if (StrEqual(cmd, "0Lights"))
			World_TurnOffLights();
		else if (StrEqual(cmd, "1Lights"))
			World_TurnOnLights();
		else if (StrEqual(cmd, "0Fog"))
			World_DisableFog();
		else if (StrEqual(cmd, "1Fog"))
			World_EnableFog();
		else if (StrEqual(cmd, "portal"))
			Portal_Shoot(param1);
			
		DisplayMenu(gEntControlWorldMenu, param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
		GenerateMenu_Main(param1);
}