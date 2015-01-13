#include <sourcemod>
#include <sdktools>
#include <smlib>
#define PLUGIN_VERSION				"0.0.1"
#define PLUGIN_DESCRIPTION "Test weapons"

new g_WeaponParent;

public Plugin:myinfo =
{
	name = "[INS] Test Weapons",
	author = "Jared Ballou",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com"
};

public OnPluginStart()
{
	PrintToServer("[TestWeapons] OnPluginStart");
	FindWeapons();
}
public FindWeapons()
{
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if(
(StrContains(name, "logic") > -1)
 || (StrContains(name, "game") > -1)
 || (StrContains(name, "team") > -1)
 || (StrContains(name, "manager") > -1)
 || (StrContains(name, "proxy") > -1)
 || (StrContains(name, "theater") > -1)
) {
				new String:m_iName[64],String:m_iszWeaponName[64],String:m_iClassname[64],String:m_iGlobalname[64],String:m_iszScriptId[64];
				GetEntPropString(i, Prop_Data, "m_iClassname", m_iClassname, sizeof(m_iClassname));
				GetEntPropString(i, Prop_Data, "m_iGlobalname", m_iGlobalname, sizeof(m_iGlobalname));
				GetEntPropString(i, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
//				= GetEntProp(i, Prop_Send, "");
				PrintToServer("[TEST] Found %s  m_iClassname %s, m_iGlobalname %s, m_iName %s", name, m_iClassname, m_iGlobalname, m_iName);

			}
		}
	}
}
