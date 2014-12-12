//////////////////////////////////////////////////////////////////
// Grenade Smoke Color By HSFighter / www.hsfighter.net
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.3.4"

#undef REQUIRE_PLUGIN
#include <updater>


/* Updater */
#define UPDATE_URL	"http://update.hsfighter.net/sourcemod/grenadesmokecolor/grenadesmokecolor.txt"


//////////////////////////////////////////////////////////////////
// Declare variables and handles
//////////////////////////////////////////////////////////////////

new Handle:g_SmokecolorEnabled;
new Handle:g_SmokecolorMode;

new Handle:g_hCVColor;
new Handle:g_hCVTColor;
new Handle:g_hCVCTColor;

// new Handle:TimeHandle;

new Float:g_HSV_Temp = 0.0;

//////////////////////////////////////////////////////////////////
// Plugin info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
	name = "Grenade Smoke Color",
	author = "HSFighter",
	description = "Adds color to grenade smoke",
	version = PLUGIN_VERSION,
	url = "www.hsfighter.net"
}


//////////////////////////////////////////////////////////////////
// Start plugin
//////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	CreateConVar("sm_grenadesmokecolor_version", PLUGIN_VERSION, "Grenade Smoke Color Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_SmokecolorEnabled      = CreateConVar("sm_grenadesmokecolor_enable",    "1",         "Enable/Disable Plugin");
	g_hCVTColor              = CreateConVar("sm_grenadesmokecolor_t_color",   "255 0 0",   "What color should the CS:S terrorist smoke be? Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN);	
	g_hCVCTColor             = CreateConVar("sm_grenadesmokecolor_ct_color",  "0 0 255",   "What color should the CS:S counter-terrorist smoke be ? Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN);
	g_hCVColor               = CreateConVar("sm_grenadesmokecolor_color",     "225 255 0", "What Defined color should smoke be? Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN);	
	g_SmokecolorMode         = CreateConVar("sm_grenadesmokecolor_mode",      "0",         "Colormode for smoke (0 = Team color, 1 = Random color, 2 = Multi color change, 3 = Defined color [sm_grenadesmokecolor_color])", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	
	// Hook events
	HookEvent("grenade_detonate", grenade_detonate);

	// Updater
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	// Create config
	AutoExecConfig(true, "plugin.grenadesmokecolor");
	
}


public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	PrintToServer("Created %s # %d",classname,entity);
} 


//////////////////////////////////////////////////////////////////
// Hook event grenade detonate and color the smoke
//////////////////////////////////////////////////////////////////

public grenade_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("[GSC] grenade_detonate called");
	// Check if plugin is enabled
	if(GetConVarInt(g_SmokecolorEnabled) != 1) return;
	
	// Get client ID of this event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new entityid = GetClientOfUserId(GetEventInt(event, "entityid"));
	new id = GetClientOfUserId(GetEventInt(event, "id"));
	decl String:classname[32];
	GetEntityClassname(id, classname, sizeof(classname));

	if (!IsValidClient(client)) return;
	
	// Get coordinates of this event
	new Float:a[3], Float:b[3];
	a[0] = GetEventFloat(event, "x");
	a[1] = GetEventFloat(event, "y");
	a[2] = GetEventFloat(event, "z");
	
	PrintToServer("[GSC] looking for client %d classname %s # %d at %f %f %f",client,classname,id,a[0],a[1],a[2]);
	new checkok = 0;
	new ent = -1;
	
/*
	// List all entitys by classname
	while((ent = FindEntityByClassname(ent, "env_particlesmokegrenade")) != -1)
	{
		// Get entity coordinates
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", b);
		PrintToServer("[GSC] checking xyz %f %f %f to %f %f %f",a[0],a[1],a[2],b[0],b[1],b[2]);
		
		// If entity same coordinates some event coordinates
		if(a[0] == b[0] && a[1] == b[1] && a[2] == b[2])
		{		
			checkok = 1;
			break;
		}
	}
*/
	PrintToServer("[GSC] checkok is %d",checkok);
    
	if (1 == 1) //checkok == 0)
	{
		// Create light
		new iEntity = CreateEntityByName("light_dynamic");
		PrintToServer("[GSC] ientity %d",iEntity);
		
		if (iEntity != -1)
		{
			// Retrieve entity
			new iRef = EntIndexToEntRef(iEntity);
			PrintToServer("[GSC] iref %d",iRef);

			
			decl String:sBuffer[64];
			// Select Action Mode
			switch (GetConVarInt(g_SmokecolorMode))
			{
				// Team Color
				case 0:
				{
					// Get client team
					new player_team_index = GetClientTeam(client);
					
					new String: game_folder[64];
					GetGameFolderName(game_folder, 64);
					
					switch (player_team_index) 
					{	
						case 1:
						{
							GetConVarString(g_hCVColor, sBuffer, sizeof(sBuffer));
						}
						case 2:
						{
							GetConVarString(g_hCVTColor, sBuffer, sizeof(sBuffer));
						}
						case 3:
						{
							GetConVarString(g_hCVCTColor, sBuffer, sizeof(sBuffer));
						}
					}
					
					DispatchKeyValue(iEntity, "_light", sBuffer);
				}
				// Random Color
				case 1:
				{
					g_HSV_Temp = GetRandomFloat(1.0, 360.0);
					
					new Float:flRed, Float:flGreen, Float:flBlue;
					HSVtoRGB(g_HSV_Temp, 1.0, 1.0, flRed, flGreen, flBlue );	
					Format(sBuffer, sizeof(sBuffer), "%i %i %i", RoundFloat(flRed*255.0), RoundFloat(flGreen*255.0), RoundFloat(flBlue*255.0));
					DispatchKeyValue(iEntity, "_light", sBuffer);
				}			
				// Multi color change
				case 2:
				{					
					new Float:rand = GetRandomFloat(0.1, 0.2);
					CreateTimer(rand, Checktime, iRef, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				// Definet color
				case 3:
				{
					GetConVarString(g_hCVColor, sBuffer, sizeof(sBuffer));
					DispatchKeyValue(iEntity, "_light", sBuffer);
				}
			}	
			
			Format(sBuffer, sizeof(sBuffer), "smokelight_%d", iEntity);
			DispatchKeyValue(iEntity,"targetname", sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%f %f %f", a[0], a[1], a[2]);
			DispatchKeyValue(iEntity, "origin", sBuffer);
			DispatchKeyValue(iEntity, "iEntity", "-90 0 0");
			DispatchKeyValue(iEntity, "pitch","-90");
			DispatchKeyValue(iEntity, "distance","256");
			DispatchKeyValue(iEntity, "spotlight_radius","96");
			DispatchKeyValue(iEntity, "brightness","3");
			DispatchKeyValue(iEntity, "style","6");
			DispatchKeyValue(iEntity, "spawnflags","1");
			DispatchSpawn(iEntity);
			AcceptEntityInput(iEntity, "DisableShadow");
			
			AcceptEntityInput(iEntity, "TurnOn");
			
			CreateTimer(20.0, Delete, iRef, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

//////////////////////////////////////////////////////////////////
// Multi color change timer
//////////////////////////////////////////////////////////////////

public Action:Checktime(Handle:colortimer, any:ref){

	new entity= EntRefToEntIndex(ref);
	
	if (!IsValidEntity(entity)) return Plugin_Stop;

	if (entity != -1)
	{
		
		decl String:sBuffer[64];
		g_HSV_Temp = g_HSV_Temp + 3.0;	
		new Float:flRed, Float:flGreen, Float:flBlue;
		HSVtoRGB(g_HSV_Temp, 1.0, 1.0, flRed, flGreen, flBlue );	
		//PrintHintTextToAll ("Debug: %i -->> r=%i g=%i b=%i", RoundFloat(g_HSV_Temp), RoundFloat(flRed*255.0), RoundFloat(flGreen*255.0), RoundFloat(flBlue*255.0));
		Format(sBuffer, sizeof(sBuffer), "%i %i %i", RoundFloat(flRed*255.0), RoundFloat(flGreen*255.0), RoundFloat(flBlue*255.0));
		if (g_HSV_Temp >= 360.0) g_HSV_Temp = 0.0;
		DispatchKeyValue(entity, "_light", sBuffer);
	}
	
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// Check client
//////////////////////////////////////////////////////////////////

public bool:IsValidClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
	{
		return false;
	}
	return true;
}


//////////////////////////////////////////////////////////////////
// HSV to RGB color
//////////////////////////////////////////////////////////////////

HSVtoRGB(&Float:h, Float:s, Float:v, &Float:r, &Float:g, &Float:b){

	if (s == 0)
	{
		r = v;  g = v;  b = v;
	} else {
		
		new Float:fHue, Float:fValue, Float:fSaturation;
		new Float:f;  new Float:p,Float:q,Float:t;
		if (h == 360.0) h = 0.0;
		fHue = h / 60.0;
		new i = RoundToFloor(fHue);
		f = fHue - i;
		fValue = v;
		fSaturation = s;
		p = fValue * (1.0 - fSaturation);
		q = fValue * (1.0 - (fSaturation * f));
		t = fValue * (1.0 - (fSaturation * (1.0 - f)));
		switch (i) 
		{
			case 1: 
			{
				r = q; g = fValue; b = p; 
			}
			case 2: 
			{
				r = p; g = fValue; b = t;
			}
			case 3: 
			{
				r = p; g = q; b = fValue;
			}
			case 4:
			{
				r = t; g = p; b = fValue;
			}
			case 5:
			{
				r = fValue; g = p; b = q; 
			}
			default:
			{
				r = fValue; g = t; b = p; 
			}	
		}
	}
}


//////////////////////////////////////////////////////////////////
// Delete entitys
//////////////////////////////////////////////////////////////////

public Action:Delete(Handle:timer, any:iRef)
{
	
	new entity= EntRefToEntIndex(iRef);
	
	if (entity != INVALID_ENT_REFERENCE)
	{
		if (IsValidEdict(entity)) AcceptEntityInput(entity, "kill");
	}
	
	/*
	if (GetConVarInt(g_SmokecolorMode) == 2)
	{
		if (TimeHandle[iRef] != INVALID_HANDLE)
		{
			CloseHandle(TimeHandle[iRef]);
			TimeHandle[iRef] = INVALID_HANDLE;
		}
	}  
	*/
}

//////////////////////////////////////////////////////////////////
// End Plugin
//////////////////////////////////////////////////////////////////
