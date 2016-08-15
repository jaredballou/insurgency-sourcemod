#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
    name = "Entity Logger",
    description = "Log all entities for debugging purposes.",
    author = "necavi",
    version = "1.0",
    url = "http://necavi.org/"
};

public OnPluginStart() 
{
    RegServerCmd("sm_logentity", Command_LogEntities, "Log all entities to a config file.");
}

public Action:Command_LogEntities(args) 
{
    LogEntities();
    return Plugin_Handled;
}

LogEntities() {
    new ent = -1;
    new counter = 0;
    new String:classname[128];
    new Handle:classnames = CreateArray(128);
    new Handle:classnameCounts = CreateArray();
    new index = -1;
    while((ent = FindEntityByClassname(ent, "*")) != -1) 
    {
        if(IsValidEntity(ent)) 
        {
            index = FindStringInArray(classnames, classname);
            if(index > -1)
            {
                SetArrayCell(classnameCounts, index, GetArrayCell(classnameCounts, index) + 1);
            }
            else
            {
                PushArrayString(classnames, classname);
                PushArrayCell(classnameCounts, 1);
            }
            counter++;
        }
    }
    
    new String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "logs/entities.log");
    new Handle:file = OpenFile(path, "w");
    WriteFileLine(file, "==== Entity List ====");
    for(new i = 0; i < GetArraySize(classnames); i++)
    {
        GetArrayString(classnames, i, classname, sizeof(classname));
        WriteFileLine(file, "[%d] Count: %d Classname: %s.", i + 1, GetArrayCell(classnameCounts, i), classname);
    }
    CloseHandle(classnames);
    CloseHandle(classnameCounts);
    WriteFileLine(file, "Total entities: %d.", counter);
    PrintToServer("%d entities have been logged to %s.", counter, path);
    FlushFile(file);
    CloseHandle(file);
}  
