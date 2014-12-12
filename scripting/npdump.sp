#include <sourcemod>
#include <netprops>

public OnPluginStart() {
    DumpNetpropsLikeSM(GetSendTableByNetclass("CINSPlayer"), 0);
}

public DumpNetpropsLikeSM(Handle:hSendTable, level) {
    new iCount = GetNumProps(hSendTable);
    new String:sPad[16];
    for(new i = 0; i < level; i++)
        Format(sPad, sizeof(sPad), "%s ", sPad);

    for(new i = 0; i < iCount; i++) {
        new Handle:hProp = GetProp(hSendTable, i);

        new String:sName[64];
        GetPropName(hProp, sName, sizeof(sName));

        new String:sType[64];
        if(!GetTypeString(hProp, sType, sizeof(sType))) {
            Format(sType, sizeof(sType), "%i", GetType(hProp));
        }

        if(GetType(hProp) == DPT_DataTable) {
            new Handle:hDataTable = GetDataTable(hProp);
            new String:sDataTableName[64];
            GetTableName(hDataTable, sDataTableName, sizeof(sDataTableName));

            LogMessage("%sSub-Class Table (%i Deep): %s (offset %d)", sPad, level, sDataTableName, GetOffset(hProp));
            DumpNetpropsLikeSM(hDataTable, level+1);
        } else {
            LogMessage("%s-Member: %s (offset %d) (type %s) (bits %d)", sPad, sName, GetOffset(hProp), sType, GetBits(hProp));
        }

    }
}  
