#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "DOI UberBolt",
	author = "FeuerSturm",
	description = "Damage multiplier and reload enhancer for bolt action rifles",
	version = PLUGIN_VERSION,
	url = "https://feuersturm.info"
}

#define BUTTON_RELOAD 			(1 << 11)
#define UPGRADE_NONE			-1
#define UPGRADE_STRIPPERCLIP	6
#define UPGRADESLOT_MAGAZINE	8

new String:g_BARifle[3][] =
{
	"weapon_springfield", "weapon_k98", "weapon_enfield"
}
new MaxAmmo[3] = { 5, 5, 10 }
new MinAmmo[3] = { 0, 0, 5 }

new m_upgradeSlots
new bool:bHasStripperClip[MAXPLAYERS+1]

new bool:g_Enabled = true
new bool:g_EnhancedReload = true

new Handle:doi_uberbolt_enabled = INVALID_HANDLE
new Handle:doi_uberbolt_dmgmultiplier = INVALID_HANDLE
new Handle:doi_uberbolt_enhancedreload = INVALID_HANDLE

public OnPluginStart()
{
	doi_uberbolt_enabled = CreateConVar("doi_uberbolt_enabled", "1", "<1/0> enable/disable DOI UberBolt!", _, true, 0.0, true, 1.0)
	doi_uberbolt_dmgmultiplier = CreateConVar("doi_uberbolt_dmgmultiplier", "3.0", "<#.#> set damage multiplier for Bolt Action Rifles", _, true, 1.0, false)
	doi_uberbolt_enhancedreload = CreateConVar("doi_uberbolt_enhancedreload", "1", "<1/0> enable/disable reloading single bullets even when using stripper clips", _, true, 0.0, true, 1.0)
	HookConVarChange(doi_uberbolt_enabled, OnConVarChange)
	HookConVarChange(doi_uberbolt_enhancedreload, OnConVarChange)
}

public OnMapStart()
{
	m_upgradeSlots = FindSendPropInfo("CINSWeapon", "m_upgradeSlots")
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage)
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost)
    bHasStripperClip[client] = false
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!g_Enabled || GetConVarFloat(doi_uberbolt_dmgmultiplier) == 1.0 || victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients || attacker != inflictor || !IsClientInGame(victim) || !IsClientInGame(attacker))
	{
		return Plugin_Continue
	}
	if(damagetype & DMG_BULLET)
	{
		decl String:WeaponName[MAX_NAME_LENGTH]
		GetClientWeapon(attacker, WeaponName, sizeof(WeaponName))
		if(IsBoltAction(WeaponName))
		{
			damage *= GetConVarFloat(doi_uberbolt_dmgmultiplier)
			return Plugin_Changed
		}
	}
	return Plugin_Continue
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!g_Enabled || !g_EnhancedReload)
	{
		return Plugin_Continue
	}
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(buttons & BUTTON_RELOAD && GetClientTeam(client) > 1)
		{
			if(bHasStripperClip[client])
			{
				new String:WeaponName[MAX_NAME_LENGTH]
				GetClientWeapon(client, WeaponName, sizeof(WeaponName))
				if(IsBoltAction(WeaponName))
				{
					new BARifle
					for(new i = 0; i < 3; i++)
					{
						if(strcmp(WeaponName, g_BARifle[i]) == 0)
						{
							BARifle = i
						}
					}
					new wpn = GetPlayerWeaponSlot(client, 0)
					new m_iClip1 = GetEntProp(wpn, Prop_Send, "m_iClip1")
					if(m_iClip1 == MaxAmmo[BARifle])
					{
						return Plugin_Continue
					}
					if(m_iClip1 < MaxAmmo[BARifle] && m_iClip1 > MinAmmo[BARifle])
					{
						SetEntData(wpn, m_upgradeSlots + UPGRADESLOT_MAGAZINE, UPGRADE_NONE, 4, true)
						return Plugin_Continue
					}
					if(m_iClip1 <= MinAmmo[BARifle])
					{
						SetEntData(wpn, m_upgradeSlots + UPGRADESLOT_MAGAZINE, UPGRADE_STRIPPERCLIP, 4, true)
						return Plugin_Continue
					}
				}
			}
		}
	}
	return Plugin_Continue
}

public OnWeaponEquipPost(client, weapon)
{
	if(g_Enabled && g_EnhancedReload)
	{
		if(client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			if(weapon != -1 && IsValidEdict(weapon))
			{
				decl String:WeaponName[MAX_NAME_LENGTH]
				GetEdictClassname(weapon, WeaponName, sizeof(WeaponName))
				if(IsBoltAction(WeaponName))
				{
					RequestFrame(RequestFrameCallback:GetStripperClip, any:client)
					return
				}
				bHasStripperClip[client] = false
			}
		}
	}
	bHasStripperClip[client] = false
}

public GetStripperClip(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0)
	if(weapon != -1)
	{
		decl String:WeaponName[MAX_NAME_LENGTH]
		GetEdictClassname(weapon, WeaponName, sizeof(WeaponName))
		if(IsBoltAction(WeaponName))
		{
			if(GetEntData(weapon, m_upgradeSlots + UPGRADESLOT_MAGAZINE) == UPGRADE_STRIPPERCLIP)
			{
				bHasStripperClip[client] = true
			}
			else
			{
				bHasStripperClip[client] = false
			}
		}
	}
}

public bool:IsBoltAction(String:WeaponName[])
{
	if(strcmp(WeaponName, g_BARifle[0]) == 0 || strcmp(WeaponName, g_BARifle[1]) == 0 || strcmp(WeaponName, g_BARifle[2]) == 0)
	{
		return true
	}
	return false
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:old_Enabled = g_Enabled
	g_Enabled = GetConVarBool(doi_uberbolt_enabled)
	new bool:old_EnhancedReload = g_EnhancedReload
	g_EnhancedReload = GetConVarBool(doi_uberbolt_enhancedreload)
	
	if (old_Enabled != g_Enabled || old_EnhancedReload != g_EnhancedReload)
	{
		if (!g_Enabled || !g_EnhancedReload)
		{
			for(new client = 1; client <= MaxClients; client++)
			{
				if(bHasStripperClip[client])
				{
					new weapon = GetPlayerWeaponSlot(client, 0)
					if(weapon != -1)
					{
						decl String:WeaponName[MAX_NAME_LENGTH]
						GetEdictClassname(weapon, WeaponName, sizeof(WeaponName))
						if(IsBoltAction(WeaponName))
						{
							SetEntData(weapon, m_upgradeSlots + UPGRADESLOT_MAGAZINE, UPGRADE_STRIPPERCLIP, 4, true)
						}
					}
				}
			}
		}
	}
}