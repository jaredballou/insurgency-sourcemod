/**
 * ====================
 *     Entity Tools
 *   File: mapmodifier.sp
 *   Author: Greyscale
 * ==================== 
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <hooker>

#define VERSION "1.1"

#define QUEUE_MAXSIZE 64

new g_iEntCount;
new Handle:g_adtEntity = INVALID_HANDLE;
new Handle:g_tEntity = INVALID_HANDLE;

new Handle:cvarPSCBlock = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Entity Tools",
    author = "Greyscale",
    description = "Provides tools and a queue system to modify certain entities, block point_servercommand, etc.",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
    RegisterHook(HK_Spawn, OnSpawnFunction, true);
    
    // ======================================================================
    
    HookEvent("round_freeze_end", RoundFreezeEnd);
    HookEvent("round_end", RoundEnd);
    
    // ======================================================================
    
    RegAdminCmd("et_entity_queue", Command_EntityQueue, ADMFLAG_GENERIC, "mm_entity_queue <datamap/entinput> <delay> <entity> <datamap prop/input> <datamap value/variant value>");
    RegAdminCmd("et_entity_queue_remove", Command_QueueRemove, ADMFLAG_GENERIC, "mm_entity_queue_remove <index - use mm_entity_queue_list to view indexes>");
    RegAdminCmd("et_entity_queue_clear", Command_QueueClear, ADMFLAG_GENERIC, "mm_entity_queue_clear");
    RegAdminCmd("et_entity_queue_list", Command_QueueList, ADMFLAG_GENERIC, "mm_entity_queue_list");
    
    RegAdminCmd("et_entity", Command_Entity, ADMFLAG_GENERIC, "mm_entity <datamap/entinput> <entity> <datamap prop/input> <value/set variant>");
    // ======================================================================
    
    cvarPSCBlock = CreateConVar("et_psc_block", "1", "Block point_servercommand so maps can't execute commands from console (like annoying console text)");
    
    CreateConVar("gs_entitytools_version", VERSION, "[EntityTools] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    AutoExecConfig(true, "entitytools", "sourcemod/entitytools");
}

public OnMapStart()
{
    if (g_adtEntity != INVALID_HANDLE)
    {
        for (new x = 0; x < g_iEntCount; x++)
        {
            new Handle:datQueue = GetArrayCell(g_adtEntity, x);
            
            if (datQueue != INVALID_HANDLE)
                CloseHandle(datQueue);
        }
        
        CloseHandle(g_adtEntity);
    }
    
    if (g_tEntity != INVALID_HANDLE)
        CloseHandle(g_tEntity);
    
    g_iEntCount = 0;
    
    g_adtEntity = CreateArray(QUEUE_MAXSIZE);
    g_tEntity = CreateArray();
}

public OnConfigsExecuted()
{
    decl String:mapconfig[PLATFORM_MAX_PATH];
    
    GetCurrentMap(mapconfig, sizeof(mapconfig));
    Format(mapconfig, sizeof(mapconfig), "sourcemod/mapmodifier/%s.cfg", mapconfig);
    
    decl String:path[PLATFORM_MAX_PATH];
    Format(path, sizeof(path), "cfg/%s", mapconfig);
    
    if (FileExists(path))
    {
        ServerCommand("exec %s", mapconfig);
    }
}

public HookerOnEntityCreated(index, const String:classname[])
{
    new bool:pscblock = GetConVarBool(cvarPSCBlock);
    if (!pscblock)
        return;
    
    if(!StrEqual(classname, "point_servercommand", false))
        return;
    
    HookEntity(HKE_CBaseEntity, index);
}

public OnSpawnFunction(entity)
{
    RemoveEdict(entity);
}

public Action:RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:param1[16];
    decl String:param2[8];
    
    for (new x = 0; x < g_iEntCount; x++)
    {
        new Handle:tEntity = GetArrayCell(g_tEntity, x);
        
        if (tEntity != INVALID_HANDLE)
            CloseHandle(tEntity);
        
        new Handle:datQueue = GetArrayCell(g_adtEntity, x);
        
        ResetPack(datQueue);
        
        ReadPackString(datQueue, param1, sizeof(param1));
        ReadPackString(datQueue, param2, sizeof(param2));
        
        new Float:flDelay = StringToFloat(param2);
        
        tEntity = CreateTimer(flDelay, EntityQueueFired, x, TIMER_FLAG_NO_MAPCHANGE);
        
        SetArrayCell(g_tEntity, x, tEntity);
    }
}

public Action:EntityQueueFired(Handle:timer, any:index)
{
    decl String:param1[16];
    decl String:param2[8];
    decl String:param3[64];
    decl String:param4[64];
    decl String:param5[64];
    
    new Handle:datQueue = GetArrayCell(g_adtEntity, index);
        
    ResetPack(datQueue);
    
    ReadPackCell(datQueue);
    ReadPackString(datQueue, param1, sizeof(param1));
    ReadPackString(datQueue, param2, sizeof(param2));
    ReadPackString(datQueue, param3, sizeof(param3));
    ReadPackString(datQueue, param4, sizeof(param4));
    ReadPackString(datQueue, param5, sizeof(param5));
    
    ET_Entity(param1, param3, param4, param5);
    
    SetArrayCell(g_tEntity, index, INVALID_HANDLE);
}

ET_Entity(const String:type[], const String:classname[], const String:param1[], const String:param2[])
{
    new entity = -1;
    do
    {
        entity = FindEntityByClassname(entity, classname);
        
        if (entity != -1)
        {
            if (StrEqual(type, "datamap"))
            {
                ET_SetEntData(entity, param1, param2);
            }
            else if (StrEqual(type, "entinput"))
            {
                ET_AcceptEntityInput(entity, param1, param2);
            }
        }
    } while (entity != -1);
}

ET_SetEntData(entity, const String:prop[], const String:value[])
{
    new offset = FindDataMapOffs(entity, prop);
    if (offset == -1)
    {
        LogMessage("Invalid datamap property specified \"%s\" for entity %d", prop, entity);
        return;
    }
    
    if (IsStringArray(value, 3))
    {
        new Float:vec[3];
        StringToVector(value, vec);
        
        SetEntDataVector(entity, offset, vec, true);
    }
    else if (IsStringNumeric(value))
    {
        if (StrContains(value, ".") > -1)
        {
            SetEntDataFloat(entity, offset, StringToFloat(value), true);
        }
        else
        {
            SetEntData(entity, offset, StringToInt(value), true);
        }
    }
    else
    {
        SetEntDataString(entity, offset, value, 64, true);
    }
}

ET_AcceptEntityInput(entity, const String:input[], const String:variant[])
{
    if (!variant[0])
    {
        if (!AcceptEntityInput(entity, input))
            LogMessage("Couldn't fire input \"%s\" on entity %d", input, entity);
        
        return;
    }
    
    if (IsStringArray(variant, 3))
    {
        new Float:vec[3];
        StringToVector(variant, vec);
        
        SetVariantVector3D(vec);
    }
    else if (IsStringArray(variant, 4))
    {
        new color[4];
        StringToColor(variant, color);
        
        SetVariantColor(color);
    }
    else if (IsStringNumeric(variant))
    {
        if (StrContains(variant, ".") > -1)
        {
            SetVariantFloat(StringToFloat(variant));
        }
        else
        {
            SetVariantInt(StringToInt(variant));
        }
    }
    else
    {
        SetVariantString(variant);
    }
    
    if (!AcceptEntityInput(entity, input))
        LogMessage("Couldn't fire input \"%s\" on entity %d", input, entity);
}

bool:IsStringNumeric(const String:str[])
{
    new len = strlen(str);
    
    for (new i = 0; i < len; i++)
    {
        if (str[i] == ' ')
            continue;
        
        if (IsCharAlpha(str[i]))
            return false;
    }
    
    return true;
}

bool:IsStringArray(const String:str[], cells)
{
    if (!IsStringNumeric(str))
        return false;
    
    new len = strlen(str);
    
    new floatcount;
    new spacecount;
    
    for (new i = 0; i < len; i++)
    {
        if (str[i] == '.')
            floatcount++;
        
        if (str[i] == ' ')
            spacecount++;
    }
    
    return (floatcount == cells && spacecount == cells - 1);
}

StringToVector(const String:str[], Float:vec[3])
{
    decl String:buffers[3][16];
    ExplodeString(str, " ", buffers, 3, 16);
    
    for (new x = 0; x < 3; x++)
        vec[x] = StringToFloat(buffers[x]);
}

StringToColor(const String:str[], color[4])
{
    decl String:buffers[3][16];
    ExplodeString(str, " ", buffers, 3, 16);
    
    for (new x = 0; x < 4; x++)
        color[x] = StringToInt(buffers[x]);
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new x = 0; x < g_iEntCount; x++)
    {
        new Handle:tEntity = GetArrayCell(g_tEntity, x);
        
        if (tEntity != INVALID_HANDLE)
            CloseHandle(tEntity);
        
        SetArrayCell(g_tEntity, x, INVALID_HANDLE);
    }
}

public Action:Command_Entity(client, argc)
{
    if (argc < 3)
    {
        ReplyToCommand(client, "<datamap/entinput> <entity> <datamap prop/input> <datamap value/variant value>");
        return;
    }
    
    decl String:arg1[16];
    decl String:arg2[64];
    decl String:arg3[64];
    decl String:arg4[64];
    
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    GetCmdArg(3, arg3, sizeof(arg3));
    GetCmdArg(4, arg4, sizeof(arg4));
    
    ET_Entity(arg1, arg2, arg3, arg4);
}
       
public Action:Command_EntityQueue(client, argc)
{
    if (argc < 4)
    {
        ReplyToCommand(client, "<datamap/entinput> <delay> <entity> <datamap prop/input> <datamap value/variant value>");
        return;
    }
    
    decl String:arg1[16];
    decl String:arg2[8];
    decl String:arg3[64];
    decl String:arg4[64];
    decl String:arg5[64];
    
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    GetCmdArg(3, arg3, sizeof(arg3));
    GetCmdArg(4, arg4, sizeof(arg4));
    GetCmdArg(5, arg5, sizeof(arg5));
    
    new Handle:datQueue = CreateDataPack();
    
    WritePackString(datQueue, arg1);
    WritePackString(datQueue, arg2);
    WritePackString(datQueue, arg3);
    WritePackString(datQueue, arg4);
    WritePackString(datQueue, arg5);
    
    g_iEntCount++;
    PushArrayCell(g_adtEntity, datQueue);
    PushArrayCell(g_tEntity, INVALID_HANDLE);
}

public Action:Command_QueueRemove(client, argc)
{
    if (argc < 1)
    {
        ReplyToCommand(client, "mm_entity_queue_remove <index - use mm_entity_queue_list to view indexes>");
        return;
    }
    
    decl String:arg1[16];
    GetCmdArg(1, arg1, sizeof(arg1));
    
    new index = StringToInt(arg1);
    if (index < 0 || index >= g_iEntCount)
    {
        ReplyToCommand(client, "Invalid queue index given.");
        return;
    }
    
    new Handle:tEntity = GetArrayCell(g_tEntity, index);
        
    if (tEntity != INVALID_HANDLE)
        CloseHandle(tEntity);
    
    RemoveFromArray(g_adtEntity, index);
    RemoveFromArray(g_tEntity, index);
    
    g_iEntCount--;
    
    ReplyToCommand(client, "Successfully removed index %d from the entity queue.", index);
}

public Action:Command_QueueClear(client, argc)
{
    for (new x = 0; x < g_iEntCount; x++)
    {
        new Handle:tEntity = GetArrayCell(g_tEntity, x);
            
        if (tEntity != INVALID_HANDLE)
            CloseHandle(tEntity);
    }
    
    ClearArray(g_adtEntity);
    ClearArray(g_tEntity);
    
    g_iEntCount = 0;
    
    ReplyToCommand(client, "Successfully removed all queue entries.");
}

public Action:Command_QueueList(client, argc)
{
    decl String:param1[16];
    decl String:param2[8];
    decl String:param3[64];
    decl String:param4[64];
    decl String:param5[64];
    decl String:fired[8];
    
    ReplyToCommand(client, "[EntityTools] Listing Queued Entries");
    ReplyToCommand(client, "------------------------------------");
    ReplyToCommand(client, " ");
    
    for (new x = 0; x < g_iEntCount; x++)
    {
        new Handle:datQueue = GetArrayCell(g_adtEntity, x);
        new Handle:tEntity = GetArrayCell(g_tEntity, x);
        
        ResetPack(datQueue);
        
        ReadPackString(datQueue, param1, sizeof(param1));
        ReadPackString(datQueue, param2, sizeof(param2));
        ReadPackString(datQueue, param3, sizeof(param3));
        ReadPackString(datQueue, param4, sizeof(param4));
        ReadPackString(datQueue, param5, sizeof(param5));
        
        fired = tEntity != INVALID_HANDLE ? "no" : "yes";
        
        ReplyToCommand(client, "[%d] Type: %s | Delay: %s seconds | Entity Classname: %s | Datamap Property/Entity Input: %s | Datamap value/Variant value: \"%s\"", x, param1, param2, param3, param4, param5);
        ReplyToCommand(client, "Fired: %s", fired);
        ReplyToCommand(client, " ");
    }
    
    ReplyToCommand(client, "------------------------------------");
}