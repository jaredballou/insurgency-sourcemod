//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#include <sourcemod>

new IMPULS_FLASHLIGHT = 100;
new Float:PressTime[MAXPLAYERS+1];
 
public Plugin:myinfo = 
{
	name = "Night Vision",
	author = "Jared Ballou",
	description = "NVGs",
	version = "0.0.1",
	url = "http://jballou.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_nightvision", sm_nightvision);
	AutoExecConfig(true, "nightvision"); 
}
public Action:sm_nightvision(client,args)
{
	if(IsClientInGame(client))SwitchNightVision(client);
}
//code from "Block Flashlight",
public Action:OnPlayerRunCmd(client, &buttons, &impuls, Float:vel[3], Float:angles[3], &weapon)
{
	if(impuls==IMPULS_FLASHLIGHT)
	{
		new Float:time=GetEngineTime();
		if(time-PressTime[client]<0.3)
		{
			SwitchNightVision(client); 				 
		}
		PressTime[client]=time; 
	}
}
SwitchNightVision(client)
{
	new d=GetEntProp(client, Prop_Send, "m_bNightVisionOn");
	if(d==0)
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn",1); 
		PrintHintText(client, "Night Vision On");
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn",0);
		PrintHintText(client, "Night Vision Off");	
	}
}

