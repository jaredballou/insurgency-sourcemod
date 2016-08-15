#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	OnMapStart();
}

public OnMapStart() {
    new Handle:file = OpenFile("stringtables.txt", "w");
    new num = GetNumStringTables();
    decl String:name[32], String:str[256];
    for(new i = 0; i < num; i++) {
        GetStringTableName(i, name, sizeof(name));
        new size = GetStringTableNumStrings(i);
        WriteFileLine(file, "[%d] %s [%d/%d]", i, name, size, GetStringTableMaxStrings(i));
        for(new j = 0; j < size; j++) {
            ReadStringTable(i, j, str, sizeof(str));
            WriteFileLine(file, "\t[%d] %s", j, str);
            
            new length = GetStringTableDataLength(i, j);
            if(length > 0) {
                decl String:data[length + 1];
                GetStringTableData(i, j, data, length + 1);
                WriteFileLine(file, "\t\t%s", data);
            }
        }
    }
    
    CloseHandle(file);
}  
