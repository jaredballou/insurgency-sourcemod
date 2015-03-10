#include <sourcemod>
#include <sdktools>
#include <loghelper>

#define TEAM_SPECTATORS 1
#define TEAM_SECURITY 2
#define TEAM_INSURGENTS 3

#define MAX_DEFINABLE_WEAPONS 100
#define MAX_WEAPON_LEN 32
#define MAX_CONTROLPOINTS 32
#define PREFIX_LEN 7
#define WEAPON_STAT_FIELDS 15

enum RoundStats
{
	STAT_KILLS = 0,
	STAT_DEATHS,
	STAT_SHOTS,
	STAT_HITS,
	STAT_GRENADES,
	STAT_CAPTURES,
	STAT_CACHES,
	STAT_DMG_GIVEN,
	STAT_DMG_TAKEN,
	STAT_TEAMKILLS,
	STAT_SCORE,
	STAT_SUPPRESSIONS,
	STAT_ACCURACY,
}

new g_weapon_stats[MAXPLAYERS+1][MAX_DEFINABLE_WEAPONS][WEAPON_STAT_FIELDS];
new g_round_stats[MAXPLAYERS+1][RoundStats];

native Ins_GetWeaponIndex(String:weapon_name[]);
//native Ins_GetWeaponName(index);
//native Ins_GetRoleIndex(String:role_name[]);
native Ins_GetRoleName(squad,squad_slot);

stock AddFolderToDownloadTable(const String:Directory[], bool:recursive=false)
{
	decl String:FileName[64], String:Path[512];
	new Handle:Dir = OpenDirectory(Directory), FileType:Type;
	while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))
	{
		if(Type == FileType_Directory && recursive)
		{
			FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
			AddFolderToDownloadTable(FileName,recursive);
			continue;
		}
		if (Type != FileType_File)
			continue;
		FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
		AddFileToDownloadsTable(Path);
	}
	return;
}
native Ins_ObjectiveResource_GetProp(const String:prop[], size=4, element=0);
native Ins_GetWeaponGetMaxClip1(weapon);
native Float:Ins_ObjectiveResource_GetPropFloat(const String:prop[], size=4, element=0);
native Ins_ObjectiveResource_GetPropEnt(const String:prop[], element=0);
native bool:Ins_ObjectiveResource_GetPropBool(const String:prop[], element=0);
native Ins_ObjectiveResource_GetPropVector(const String:prop[], Float:vec[3], element=0);
native Ins_ObjectiveResource_GetPropString(const String:prop[], String:buffer[], maxlen);
native bool:Ins_InCounterAttack();
native Ins_GetPlayerScore(client);
//native GameLogic_();
native Ins_GetWeaponName(weaponid, String:buffer[], maxlen);
native Ins_GetWeaponId(String:weapon_name[]);



reset_round_stats(client)
{
	if (IsValidClient(client))
	{
		PrintToServer("[INSLIB] Running reset_round_stats for %N",client);
	}
	for (new i = 1; i < 13; i++)
	{
		g_round_stats[client][i] = 0;
	}
	g_round_stats[client][STAT_SCORE] = Ins_GetPlayerScore(client);
}
DoRoundAwards()
{
	PrintToServer("[INSLIB] Running DoRoundAwards");
	new iHighPlayer[RoundStats],iLowPlayer[RoundStats],iHighScore[RoundStats],iLowScore[RoundStats];
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			new m_iPlayerScore = Ins_GetPlayerScore(i);
			g_round_stats[i][STAT_SCORE] = (m_iPlayerScore - g_round_stats[i][STAT_SCORE]);
			g_round_stats[i][STAT_ACCURACY] = RoundToFloor((Float:g_round_stats[i][STAT_HITS] / Float:g_round_stats[i][STAT_SHOTS]) * 100.0);
			for (new s;s<sizeof(iHighPlayer);s++)
			{
				if ((g_round_stats[i][s] > iHighScore[s]) || (iHighPlayer[s] < 1))
				{
					iHighPlayer[s] = i;
					iHighScore[s] = g_round_stats[i][s];
				}
				if ((g_round_stats[i][s] < iLowScore[s]) || (iLowPlayer[s] < 1))
				{
					iLowPlayer[s] = i;
					iLowScore[s] = g_round_stats[i][s];
				}
			}
			PrintToServer("[INSLIB] Client %N KILLS %d, DEATHS %d, SHOTS %d, HITS %d, GRENADES %d, CAPTURES %d, CACHES %d, DMG_GIVEN %d, DMG_TAKEN %d, TEAMKILLS %d SCORE %d (total %d) SUPPRESSIONS %d",i,g_round_stats[i][STAT_KILLS],g_round_stats[i][STAT_DEATHS],g_round_stats[i][STAT_SHOTS],g_round_stats[i][STAT_HITS],g_round_stats[i][STAT_GRENADES],g_round_stats[i][STAT_CAPTURES],g_round_stats[i][STAT_CACHES],g_round_stats[i][STAT_DMG_GIVEN],g_round_stats[i][STAT_DMG_TAKEN],g_round_stats[i][STAT_TEAMKILLS],g_round_stats[i][STAT_SCORE],m_iPlayerScore,g_round_stats[i][STAT_SUPPRESSIONS]);
		}
		reset_round_stats(i);
	}
	LogPlayerEvent(iHighPlayer[STAT_SCORE], "triggered", "round_mvp");
	LogPlayerEvent(iHighPlayer[STAT_KILLS], "triggered", "round_kills");
	LogPlayerEvent(iHighPlayer[STAT_DEATHS], "triggered", "round_deaths");
	LogPlayerEvent(iHighPlayer[STAT_SHOTS], "triggered", "round_shots");
	LogPlayerEvent(iHighPlayer[STAT_HITS], "triggered", "round_hits");
	LogPlayerEvent(iHighPlayer[STAT_ACCURACY], "triggered", "round_accuracy");
	LogPlayerEvent(iHighPlayer[STAT_GRENADES], "triggered", "round_grenades");
	LogPlayerEvent(iHighPlayer[STAT_CAPTURES], "triggered", "round_captures");
	LogPlayerEvent(iHighPlayer[STAT_CACHES], "triggered", "round_caches");
	LogPlayerEvent(iHighPlayer[STAT_DMG_GIVEN], "triggered", "round_dmg_given");
	LogPlayerEvent(iHighPlayer[STAT_DMG_TAKEN], "triggered", "round_dmg_taken");
	LogPlayerEvent(iHighPlayer[STAT_SUPPRESSIONS], "triggered", "round_suppressions");
}
stock bool:IsValidClient(client) {

  return (client > 0 && client <= MaxClients &&
    IsClientConnected(client) && IsClientInGame(client) &&
    !IsClientReplay(client) && !IsClientSourceTV(client));

}

