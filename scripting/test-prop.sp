#include <sourcemod>
#include <sdktools>
#include <smlib>
#define PLUGIN_VERSION				"0.0.1"
#define PLUGIN_DESCRIPTION "Test props"

new g_WeaponParent;

public Plugin:myinfo =
{
	name = "[INS] Test Props",
	author = "Jared Ballou",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com"
};

public OnPluginStart()
{
	g_WeaponParent = FindSendPropOffs("CINSWeapon", "m_hOwnerEntity");
	PrintToServer("[TestProp] OnPluginStart");
	RegConsoleCmd("get_props", Command_GetProps);
}
doitnow(weapon_entity_index=-1)
{
	new Handle:gameconf; // gamedata config 

    if( (gameconf = LoadGameConfigFile("insurgency.games")) == INVALID_HANDLE ) 
    { 
        PrintToServer("LoadGameConfigFile \"insurgency.games\" INVALID_HANDLE"); 
        return Plugin_Handled; 
    } 

    if(GameConfGetOffset(gameconf, "GetMaxClip1") == -1) 
    { 
        CloseHandle(gameconf); 
        PrintToServer("GameConfGetOffset \"GetMaxClip1\" -1"); 
        return Plugin_Handled; 
    } 

    // CBaseCombatWeapon:: 
    // First SDKCall parameter, entity index (weapon). 
    StartPrepSDKCall(SDKCall_Entity); 

    // virtual function index (offset) 
    //PrepSDKCall_SetVirtual(310); // Use gamedata file instead, OS Win/Linux/Mac 
    if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "GetMaxClip1")) 
    { 
        SetFailState("PrepSDKCall_SetFromConf false, nothing found"); 
    } 
    CloseHandle(gameconf); 

    // GetMaxClip1(void)const 
    // SDKCall return as integer value. 
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue); 

    new Handle:hCall= EndPrepSDKCall(); 

    if( weapon_entity_index != -1 ) 
    { 
        new value; 
     
        value = SDKCall(hCall, weapon_entity_index); 
        PrintToServer("weapon index %i SDKCall GetMaxClip1 return value %i", weapon_entity_index, value); 
    } 

    CloseHandle(hCall); 
    return Plugin_Handled; 
}
public OnMapStart()
{
	PrintToServer("[TestProp] OnMapStart");

	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if(StrContains(weapon, "weapon_") == 0)
			{
			PrintToServer("[TestProp] Entity %d classname %s",i,weapon);
		    new m_iPrimaryAmmoType        = GetEntProp(i, Prop_Send, "m_iPrimaryAmmoType"); // Ammo type
		    new m_iSecondaryAmmoType    = GetEntProp(i, Prop_Send, "m_iSecondaryAmmoType");
    new m_iClip1 = -1;
    new m_iClip2 = -1;
    new m_iAmmo_prim     = -1;
    new m_iAmmo_sec     = -1;
	new m_iPrimaryAmmoCount = -1;
	new m_iSecondaryAmmoCount = -1;


    // Primary ammo
    if(m_iPrimaryAmmoType != -1)
    {
        m_iClip1 = GetEntProp(i, Prop_Send, "m_iClip1"); // weapon clip amount bullets
    }
    if(m_iSecondaryAmmoType != -1)
    {
        m_iClip2 = GetEntProp(i, Prop_Send, "m_iClip2");
    }

    // Output
    PrintToServer("\nIndex %i = classname %s\n- PrimAmmoType %i & m_iClip1 %i & m_iPrimaryAmmoCount %i\n- SecAmmoType %i & m_iClip2 %i & m_iSecondaryAmmoCount %i\n- Player m_iAmmo prim %i & sec %i",
                i,
                weapon,
                m_iPrimaryAmmoType,
                m_iClip1,
		m_iPrimaryAmmoCount,
                m_iSecondaryAmmoType,
                m_iClip2,
		m_iSecondaryAmmoCount,
                m_iAmmo_prim,
                m_iAmmo_sec);

		}
		doitnow(i);
	}
	}
return;
	for (new i=1; i<=MaxClients; i++)
	{
		{
			GetProps(i);
		}
	}
	
}
public Action:Command_GetProps(client, args)
{
	OnMapStart();
//	GetProps(client);
}
GetProps(client)
{
	if((!IsClientInGame(client)) || !IsClientConnected(client))
	{
		return;
	}
	PrintToServer("[TestProp] GetProps %d starting",client);

	new String:classname[30];
	GetEntityClassname(client, classname, sizeof(classname));
	PrintToServer("[TestProp] GetProps classname %s",classname);
	new Handle:ammoOffset;
	new Handle:clipOffset;

	ammoOffset = FindSendPropInfo("CINSPlayer", "m_iAmmo");
	clipOffset = FindSendPropInfo("CINSWeaponBase", "m_iClip1");
	new myweaponsoffset = FindSendPropOffs("CINSPlayer", "m_hMyWeapons");
	new weapon = GetEntDataEnt2(client, FindSendPropInfo("CINSPlayer", "m_hActiveWeapon"));
	if (weapon == -1)
	{
		PrintToServer("[TestProp] GetProps weapon failed",client);
		return;
	}
    // Entity classname
    GetEntityClassname(weapon, classname, sizeof(classname));

    // Weapon ammo types
    new m_iPrimaryAmmoType        = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); // Ammo type
    new m_iSecondaryAmmoType    = GetEntProp(weapon, Prop_Send, "m_iSecondaryAmmoType");

    new m_iClip1 = -1;
    new m_iClip2 = -1;
    new m_iAmmo_prim     = -1;
    new m_iAmmo_sec     = -1;
	new m_iPrimaryAmmoCount = -1;
	new m_iSecondaryAmmoCount = -1;


    // Primary ammo
    if(m_iPrimaryAmmoType != -1)
    {
        m_iClip1 = GetEntProp(weapon, Prop_Send, "m_iClip1"); // weapon clip amount bullets
        m_iAmmo_prim = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
//	m_iPrimaryAmmoCount = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoCount");

        // SetEntProp(weapon, Prop_Send, "m_iClip1", 99); // Set weapon clip ammunition
        // SetEntProp(client, Prop_Send, "m_iAmmo", 99, _, m_iPrimaryAmmoType); // Set player ammunition of this weapon primary ammo type
    }

    // Secondary ammo (Not usefull in cs:s)
    if(m_iSecondaryAmmoType != -1)
    {
        m_iClip2 = GetEntProp(weapon, Prop_Send, "m_iClip2");
        m_iAmmo_sec = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iSecondaryAmmoType);
//	m_iSecondaryAmmoCount = GetEntProp(weapon, Prop_Send, "m_iSecondaryAmmoCount");
    }

    // Output
    PrintToServer("\nIndex %i = classname %s\n- PrimAmmoType %i & m_iClip1 %i & m_iPrimaryAmmoCount %i\n- SecAmmoType %i & m_iClip2 %i & m_iSecondaryAmmoCount %i\n- Player m_iAmmo prim %i & sec %i",
                weapon,
                classname,
                m_iPrimaryAmmoType,
                m_iClip1,
		m_iPrimaryAmmoCount,
                m_iSecondaryAmmoType,
                m_iClip2,
		m_iSecondaryAmmoCount,
                m_iAmmo_prim,
                m_iAmmo_sec);
}
