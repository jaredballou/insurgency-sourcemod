#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION				"0.0.1"
#define PLUGIN_DESCRIPTION "Test props"

public Plugin:myinfo =
{
	name = "[INS] entpropelements",
	author = "Jared Ballou",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com"
};

public OnPluginStart()
{
	new PropType:proptype = Prop_Data;
	new target,ammo,max,i,weapon,String:classname[64];
        for (target = 1; target <= MaxClients; target++)
        {
                if (IsClientInGame(target))
                {
			weapon = GetEntDataEnt2(target, FindSendPropInfo("CINSPlayer", "m_hActiveWeapon"));
			if (weapon > -1)
			{
				GetEntityClassname(weapon, classname, sizeof(classname));
				new m_iPrimaryAmmoType = GetEntProp(weapon, proptype, "m_iPrimaryAmmoType");
				new m_iClip1 = GetEntProp(weapon, proptype, "m_iClip1");
				new bool:m_bChamberedRound = GetEntData(weapon, FindSendPropInfo("CINSWeaponBallistic", "m_bChamberedRound"),1);
				PrintToServer("Client %d (%N) weapon %s id %d chambered %i m_iPrimaryAmmoType %d m_iClip1 %d", target,target,classname,weapon,m_bChamberedRound,m_iPrimaryAmmoType,m_iClip1);
			}
			max = GetEntPropArraySize(target, proptype, "m_iAmmo");
			for (i = 0; i < max; i++)
			{
				if ((ammo = GetEntProp(target, proptype, "m_iAmmo", _, i)) > 0)
					PrintToServer("Client %d (%N) Slot %d, Ammo %d", target,target,i, ammo);
			}
		}
	}
}
