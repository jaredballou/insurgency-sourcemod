#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define VERSION "1.0"

#define TEAM_SPECTATORS 1
#define TEAM_SECURITY 2
#define TEAM_INSURGENTS 3
#define MAX_LINE_WIDTH 64


public Plugin:myinfo =
{
	name = "Display Teams",
	author = "Qrio",
	description = "Displays the Players in each Team.",
	version = VERSION,
	url = "http://www.clandie.net"
}

public OnPluginStart()
{
	// Register chat commands for rank panels
	RegConsoleCmd("say", cmd_Say);
	RegConsoleCmd("say_team", cmd_Say);
	// Register console commands for rank panels
	RegConsoleCmd("sm_teams", cmd_ShowTeams);

}

// Parse chat for TEAMS trigger.
public Action:cmd_Say(client, args)
{
	decl String:Text[192];
	new String:Command[64];
	new Start = 0;

	GetCmdArgString(Text, sizeof(Text));

	if (Text[strlen(Text)-1] == '"')
	{
		Text[strlen(Text)-1] = '\0';
		Start = 1;
	}

	if (strcmp(Command, "say2", false) == 0)
		Start += 4;

	if (strcmp(Text[Start], "teams", false) == 0)
	{
		cmd_ShowTeams(client, 0);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/* Display Players in each Team */
public Action:cmd_ShowTeams(client, args)
{
	BuildPrintPanel(client);
}
public Action:RefreshPanel(Handle:Timer, any:client)
{
	CreateTimer(3.0, RefreshPanel, client, TIMER_REPEAT);
	BuildPrintPanel(client);
	return Plugin_Continue;
}

//build players list menu
public BuildPrintPanel(client)
{
	decl String:clientname[40], sectionname[40], myName[64];
	new num_sec = 0, num_ins = 0, team = 0, total_sec, total_ins;

	//new Handle:menu = CreateMenu(MenuHandler_PlayerSelect);

	//SetMenuTitle(menu, "[L4D/L4D2] Players & Teams");
	//SetMenuExitBackButton(menu, true);

	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "Remaining Players");

	new maxplayers = GetMaxClients();

	//Count the survivors and infected players in server
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			team = GetClientTeam(i);
			if (team == TEAM_SECURITY)
			{
				num_sec++;
			}
			if (team == TEAM_INSURGENTS)
			{
				num_ins++;
			}
		}
	}
	total_ins = GetTeamClientCount(TEAM_INSURGENTS);
	total_sec = GetTeamClientCount(TEAM_SECURITY);
	//Display the survivor players to the menu/panel
	Format(sectionname, sizeof(sectionname),"%s (%i/%i):", "Security", num_sec, total_sec);
	DrawPanelText(menu,sectionname);

	new myCount = 0;
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SECURITY)
		{
			myCount++;
			GetClientName(i, myName, sizeof(myName));
			Format(clientname, sizeof(clientname),"%i. %s", myCount, myName);
			DrawPanelText(menu,clientname);
		}
	}
	DrawPanelText(menu," ");

	//Display the infected players to the menu/panel
	Format(sectionname, sizeof(sectionname),"%s (%i/%i)", "Insurgents", num_ins, total_ins);
	DrawPanelText(menu,sectionname);

	DrawPanelText(menu," ");
	
	SendPanelToClient(menu,client,MenuHandler_NoSelect,MENU_TIME_FOREVER);
}
/* >>> End Display Players in each Team */

public MenuHandler_NoSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu!=INVALID_HANDLE) CloseHandle(menu);
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}
