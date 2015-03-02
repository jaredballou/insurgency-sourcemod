#define LOGHELPER_VERSION 4
#include <sourcemod>
#include <sdktools>

new String:g_team_list[16][64];
native Ins_GetWeaponIndex(String:weapon_name[]);
//native Ins_GetWeaponName(index);
//native Ins_GetRoleIndex(String:role_name[]);
native Ins_GetRoleName(squad,squad_slot);

stock GetTeams()
{
	new max_teams_count = GetTeamCount();
	for (new team_index = 0; (team_index < max_teams_count); team_index++)
	{
		decl String: team_name[64];
		GetTeamName(team_index, team_name, sizeof(team_name));
		if (strcmp(team_name, "") != 0)
		{
			g_team_list[team_index] = team_name;
		}
	}
}
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
native Float:Ins_ObjectiveResource_GetPropFloat(const String:prop[], size=4, element=0);
native Ins_ObjectiveResource_GetPropEnt(const String:prop[], element=0);
native bool:Ins_ObjectiveResource_GetPropBool(const String:prop[], element=0);
native Ins_ObjectiveResource_GetPropVector(const String:prop[], Float:vec[3], element=0);
native Ins_ObjectiveResource_GetPropString(const String:prop[], String:buffer[], maxlen);
native bool:Ins_InCounterAttack();
//native GameLogic_();
