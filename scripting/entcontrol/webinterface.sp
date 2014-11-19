/* 
	------------------------------------------------------------------------------------------
	EntControl::WebInterface
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public RegWebinterfaceCommands()
{
	RegConsoleCmd("sm_entcontrol_webinterface", Command_Open_Webinterface, "Open the webinterface");
}

/* 
	------------------------------------------------------------------------------------------
	Command_Open_Webinterface
	That command will open the webinterface. The CVAR "ip" will be used to find the ip-address of the server.
	This way is not the best way, but it´s working for most of cases.
	------------------------------------------------------------------------------------------
*/
public Action:Command_Open_Webinterface(client, args)
{
	if (client)
	{
		new String:IP[128];
		
		EC_Web_GetIP(IP);
		
		if (IP[0] == '\0')
		{
			GetConVarString(FindConVar("ip"), IP, sizeof(IP));
			if (StrEqual(IP, "localhost"))
			{
				new hostip = GetConVarInt(FindConVar("hostip"));
				if (hostip > 0)
					Format(IP, sizeof(IP), "%i.%i.%i.%i", hostip >>> 24 & 255, hostip >>> 16 & 255, hostip >>> 8 & 255, hostip & 255);
			}
		}

		new port = EC_Web_GetPort();
		if (port == 0)
		{
			CPrintToChat(client, "{red}Webserver-Module is not running!");
			CPrintToChat(client, "{red}To enable it set sm_entcontrol_http_enabled 1");
			CPrintToChat(client, "{red}And don´t forget to set sm_entcontrol_http_port as well");
			return (Plugin_Handled);
		}
		
		Format(IP, sizeof(IP), "http://%s:%i/entcontrol/index.html", IP, EC_Web_GetPort());
		ShowMOTDPanel(client, "Entcontrol", IP, MOTDPANEL_TYPE_URL);
	}
	
	return (Plugin_Handled);
}

public HTML_DrawEntityList(String:result[], maxresultlength)
{
	new count = GetEntityCount();
	for (new i=0; i<=count; i++)
	{
		if (IsValidEntity(i))
		{
			new ref = EntIndexToEntRef(i);
			
			decl String:classname[64];
			if (GetEntityClassname(ref, classname, sizeof(classname)))
			{
				Format(result, maxresultlength, "%s<tr><td><a href=\"showentityinfo.html?ref=%d\">%d</a></td><td>%s</td></tr>", result, ref, i, classname);
			}
		}
	}
}

public HTML_DrawEntityInputs(entityRef, String:result[], maxresultlength)
{
	new entity = EntRefToEntIndex(entityRef);
	decl String:classname[32];
	if (IsValidEntity(entity))
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		
		if (KvJumpToKey(kvEnts, classname) && KvJumpToKey(kvEnts, "input"))
		{
			KvGotoFirstSubKey(kvEnts, false);
			
			decl String:sectionName[32];
			do
			{
				KvGetSectionName(kvEnts, sectionName, sizeof(sectionName));
				Format(result, maxresultlength, "%s-><a href=\"modifyentity.html?ref=%i&func=%s\">%s</a><br/>", result, entityRef, sectionName, sectionName);
			} while (KvGotoNextKey(kvEnts, false));

			KvRewind(kvEnts);
		}
		else
		{
			strcopy(result, maxresultlength, "Entity is currently not supported.");
		}		
	}
}

public HTML_DrawEntityOutputs(entity, String:result[], maxresultlength)
{
	entity = EntRefToEntIndex(entity);
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		if (GetEntityClassname(entity, classname, sizeof(classname)) && KvJumpToKey(kvEnts, classname) && KvJumpToKey(kvEnts, "output"))
		{
			KvGotoFirstSubKey(kvEnts, false);
			
			decl String:sectionName[32];
			do
			{
				KvGetSectionName(kvEnts, sectionName, sizeof(sectionName));

				decl String:sBuffer[32];
				new count = EC_Entity_GetOutputCount(entity, sectionName);
				
				Format(result, maxresultlength, "%s%s(%i)<br/>", result, sectionName, count);
				
				sBuffer = sectionName;

				if (count > -1)
				{
					if (EC_Entity_GetOutputFirst(entity, sBuffer))
					{
						Format(result, maxresultlength, "%s->%s<br/>", result, sBuffer);
						
						for (new i = 1; i < count; i++)
						{
							sBuffer = sectionName;
							EC_Entity_GetOutputAt(entity, sBuffer, i);
							Format(result, maxresultlength, "%s->%s<br/>", result, sBuffer);
						}
					}
					else
					{
						strcopy(result, maxresultlength, "Could not receive output!");
					}
				}

			} while (KvGotoNextKey(kvEnts, false));
			
			KvRewind(kvEnts);
		}
		else
		{
			strcopy(result, maxresultlength, "Entity is currently not supported.");
		}
	}
}

public Action:EC_OnWebserverCallFunction(const userID, const String:function[], const String:arg[], String:result[])
{
	new Float:vector3d[3];
	decl String:container3[3][128];

	//PrintToServer("Entcontrol->Call to function %s(%s)\n", function, arg);
	
	strcopy(result, EC_MAXHTTPRESULT, "");
	
	if (StrEqual(function, "DrawEntityList"))
	{
		HTML_DrawEntityList(result, EC_MAXHTTPRESULT);
	}
	else if (StrEqual(function, "GetEntPropString"))
	{
		ExplodeString(arg, ",", container3, sizeof(container3), sizeof(container3[]));
		
		new entity = StringToInt(container3[0]);
		if (IsValidEntity(entity))
		{
			if (StrEqual(container3[1], "Prop_Data"))
				GetEntPropString(entity, Prop_Data, container3[2], result, EC_MAXHTTPRESULT);
			else
				GetEntPropString(entity, Prop_Send, container3[2], result, EC_MAXHTTPRESULT);
		}
	}
	else if (StrEqual(function, "GetEntPropVector"))
	{
		ExplodeString(arg, ",", container3, sizeof(container3), sizeof(container3[]));
		
		new entity = StringToInt(container3[0]);
		if (IsValidEntity(entity))
		{
			if (StrEqual(container3[1], "Prop_Data"))
				GetEntPropVector(entity, Prop_Data, container3[2], vector3d);
			else
				GetEntPropVector(entity, Prop_Send, container3[2], vector3d);
			
			Format(result, EC_MAXHTTPRESULT, "%f %f %f", vector3d[0], vector3d[1], vector3d[2]);
		}
	}
	else if (StrEqual(function, "GetEntProp"))
	{
		ExplodeString(arg, ",", container3, sizeof(container3), sizeof(container3[]));
		
		new entity = StringToInt(container3[0]);
		if (IsValidEntity(entity))
		{
			if (StrEqual(container3[1], "Prop_Data"))
				Format(result, EC_MAXHTTPRESULT, "%d", GetEntProp(entity, Prop_Data, container3[2]));
			else
				Format(result, EC_MAXHTTPRESULT, "%d", GetEntProp(entity, Prop_Send, container3[2]));
		}
	}
	else if (StrEqual(function, "GetEntityMoveType"))
	{
		new entity = StringToInt(arg);
		if (IsValidEntity(entity))
		{
			switch (GetEntityMoveType(entity))
			{
				case 0:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_NONE"); // never moves
				case 1:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_ANGLENOCLIP");
				case 2:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_ANGLECLIP");
				case 3:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_WALK"); // Player only - moving on the ground
				case 4:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_STEP"); // gravity, special edge handling -- monsters use this
				case 5:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_FLY"); // No gravity, but still collides with stuff
				case 6:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_TOSS"); // gravity/collisions
				case 7:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_PUSH"); // no clip to world, push and crush
				case 8:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_NOCLIP"); // No gravity, no collisions, still do velocity/avelocity
				case 9:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_FLYMISSILE"); // extra size to monsters
				case 10:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_BOUNCE"); // Just like Toss, but reflect velocity when contacting surfaces
				case 11:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_BOUNCEMISSILE"); // bounce w/o gravity
				case 12:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_FOLLOW"); // track movement of aiment
				case 13:
					strcopy(result, EC_MAXHTTPRESULT, "MOVETYPE_PUSHSTEP"); // BSP model that needs physics/world collisions (uses nearest hull for world collision)
			}
		}
	}
	else if (StrEqual(function, "GetEntityFlags"))
	{
		new entity = StringToInt(arg);
		if (IsValidEntity(entity))
		{
			new flags = GetEntityFlags(entity);
			
			if (flags)
			{
				if (flags & FL_ONGROUND)
					StrCat(result, EC_MAXHTTPRESULT, "FL_ONGROUND");
				if (flags & FL_DUCKING)
					StrCat(result, EC_MAXHTTPRESULT, "FL_DUCKING");
				if (flags & FL_WATERJUMP)
					StrCat(result, EC_MAXHTTPRESULT, "FL_WATERJUMP");
				if (flags & FL_ONTRAIN)
					StrCat(result, EC_MAXHTTPRESULT, "FL_ONTRAIN");
				if (flags & FL_INRAIN)
					StrCat(result, EC_MAXHTTPRESULT, "FL_INRAIN");
				if (flags & FL_FROZEN)
					StrCat(result, EC_MAXHTTPRESULT, "FL_FROZEN");
				if (flags & FL_ATCONTROLS)
					StrCat(result, EC_MAXHTTPRESULT, "FL_ATCONTROLS");
				if (flags & FL_CLIENT)
					StrCat(result, EC_MAXHTTPRESULT, "FL_CLIENT");
				if (flags & FL_FAKECLIENT)
					StrCat(result, EC_MAXHTTPRESULT, "FL_FAKECLIENT");
				if (flags & FL_INWATER)
					StrCat(result, EC_MAXHTTPRESULT, "FL_INWATER");
				if (flags & FL_FLY)
					StrCat(result, EC_MAXHTTPRESULT, "FL_FLY");
				if (flags & FL_SWIM)
					StrCat(result, EC_MAXHTTPRESULT, "FL_SWIM");
				if (flags & FL_CONVEYOR)
					StrCat(result, EC_MAXHTTPRESULT, "FL_CONVEYOR");
				if (flags & FL_NPC)
					StrCat(result, EC_MAXHTTPRESULT, "FL_NPC");
				if (flags & FL_GODMODE)
					StrCat(result, EC_MAXHTTPRESULT, "FL_GODMODE");
				if (flags & FL_NOTARGET)
					StrCat(result, EC_MAXHTTPRESULT, "FL_NOTARGET");
				if (flags & FL_AIMTARGET)
					StrCat(result, EC_MAXHTTPRESULT, "FL_AIMTARGET");
				if (flags & FL_PARTIALGROUND)
					StrCat(result, EC_MAXHTTPRESULT, "FL_PARTIALGROUND");
				if (flags & FL_STATICPROP)
					StrCat(result, EC_MAXHTTPRESULT, "FL_STATICPROP");
				if (flags & FL_GRAPHED)
					StrCat(result, EC_MAXHTTPRESULT, "FL_GRAPHED");
				if (flags & FL_GRENADE)
					StrCat(result, EC_MAXHTTPRESULT, "FL_GRENADE");
				if (flags & FL_STEPMOVEMENT)
					StrCat(result, EC_MAXHTTPRESULT, "FL_STEPMOVEMENT");
				if (flags & FL_DONTTOUCH)
					StrCat(result, EC_MAXHTTPRESULT, "FL_DONTTOUCH");
				if (flags & FL_BASEVELOCITY)
					StrCat(result, EC_MAXHTTPRESULT, "FL_BASEVELOCITY");
				if (flags & FL_WORLDBRUSH)
					StrCat(result, EC_MAXHTTPRESULT, "FL_WORLDBRUSH");
				if (flags & FL_OBJECT)
					StrCat(result, EC_MAXHTTPRESULT, "FL_OBJECT");
				if (flags & FL_KILLME)
					StrCat(result, EC_MAXHTTPRESULT, "FL_KILLME");
				if (flags & FL_ONFIRE)
					StrCat(result, EC_MAXHTTPRESULT, "FL_ONFIRE");
				if (flags & FL_DISSOLVING)
					StrCat(result, EC_MAXHTTPRESULT, "FL_DISSOLVING");
				if (flags & FL_TRANSRAGDOLL)
					StrCat(result, EC_MAXHTTPRESULT, "FL_TRANSRAGDOLL");
			}
			else
			{
				strcopy(result, EC_MAXHTTPRESULT, "NO FLAGS");
			}
		}
	}
	else if (StrEqual(function, "GetEntityInputs"))
	{
		HTML_DrawEntityInputs(StringToInt(arg), result, EC_MAXHTTPRESULT);
	}
	else if (StrEqual(function, "GetEntityOutputs"))
	{
		HTML_DrawEntityOutputs(StringToInt(arg), result, EC_MAXHTTPRESULT);
	}
	else if (StrEqual(function, "ModifyEntity"))
	{
		decl String:containerModEnt[2][32];
		ExplodeString(arg, ",", containerModEnt, sizeof(containerModEnt), sizeof(containerModEnt[]));
		
		new client = GetClientOfUserId(userID);
		new entity = EntRefToEntIndex(StringToInt(containerModEnt[0]));
		if (IsValidEntity(entity))
		{
			decl String:modFunc[32];
			strcopy(modFunc, 32, containerModEnt[1]);
			
			if (StrEqual(modFunc, "Freeze"))
				Entity_Freeze(entity);
			else if (StrEqual(modFunc, "Unfreeze"))
				Entity_UnFreeze(entity);
			else if (StrEqual(modFunc, "Breakable"))
				Entity_Breakable(entity);
			else if (StrEqual(modFunc, "Invincible"))
				Entity_Invincible(entity);
			else if (StrEqual(modFunc, "GravityUp"))
				Entity_Gravity(entity, true);
			else if (StrEqual(modFunc, "GravityDown"))
				Entity_Gravity(entity, false);
			else if (StrEqual(modFunc, "SizeUp"))
				Entity_Size(entity, true);
			else if (StrEqual(modFunc, "SizeDown"))
				Entity_Size(entity, false);
			else if (StrEqual(modFunc, "SpeedUp"))
				Entity_Speed(entity, true);
			else if (StrEqual(modFunc, "SpeedDown"))
				Entity_Speed(entity, false);
			else if (StrEqual(modFunc, "Solid"))
				Entity_Solid(entity);
			else if (StrEqual(modFunc, "UnSolid"))
				Entity_UnSolid(entity);
			else if (StrEqual(modFunc, "Touch"))
				Entity_Touch(entity, client);
			else if (StrEqual(modFunc, "Ignite"))
				Entity_Ignite(entity, 5.0);
			else if (StrEqual(modFunc, "Visible"))
				Entity_Visible(entity);
			else if (StrEqual(modFunc, "Invisible"))
				Entity_InVisible(entity);
			else if (StrEqual(modFunc, "Activate"))
				Entity_Activate(entity);
			else if (StrEqual(modFunc, "ChangeSkin"))
				Entity_ChangeSkin(entity, client);
			else if (StrEqual(modFunc, "Hurt"))
				Entity_Hurt(entity, client);
			else if (StrEqual(modFunc, "HealthToOne"))
				Entity_SetHealth(entity, 1);
			else if (StrEqual(modFunc, "HealthToFully"))
				Entity_SetHealth(entity, 100);
			else if (StrEqual(modFunc, "Remove"))
				RemoveEntity(entity);
			else
				AcceptEntityInput(entity, modFunc, client, client);
		}
		else
		{
			strcopy(result, EC_MAXHTTPRESULT, "Invalid Entity!");
		}
		
		strcopy(result, EC_MAXHTTPRESULT, "DONE!");
	}
	else
	{
		return (Plugin_Continue);
	}
	
	return (Plugin_Stop);
}