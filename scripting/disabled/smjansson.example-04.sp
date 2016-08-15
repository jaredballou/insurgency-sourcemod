#pragma semicolon 1
#include <sourcemod>
#include <smjansson>

/*
 *
 * Example: Converting key-values to JSON
 *
 */
public OnPluginStart() {
	// Load some random keyvalues file
	new String:sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "scripts/items/items_game.txt");

	new Handle:hKV = CreateKeyValues("");
	FileToKeyValues(hKV, sPath);

	// Convert it to JSON
	new Handle:hObj = KeyValuesToJSON(hKV);

	// And finally save the JSON object to a file
	// with indenting set to 2.
	Format(sPath, sizeof(sPath), "scripts/items/items_game.json");
	json_dump_file(hObj, sPath, 2);

	// Close the Handle to the JSON object, i.e. free it's memory
	// and free the Handle.
	CloseHandle(hObj);
}



stock Handle:KeyValuesToJSON(Handle:kv) {
	new Handle:hObj = json_object();

	//Traverse the keyvalues structure
	IterateKeyValues(kv, hObj);

	//return output
	return hObj;
}

IterateKeyValues(&Handle:kv, &Handle:hObj) {
	do {
		new String:sSection[255];
		KvGetSectionName(kv, sSection, sizeof(sSection));

		new String:sValue[255];
		KvGetString(kv, "", sValue, sizeof(sValue));

		new bool:bIsSubSection = ((KvNodesInStack(kv) == 0) || (KvGetDataType(kv, "") == KvData_None && KvNodesInStack(kv) > 0));

		//new KvDataTypes:type = KvGetDataType(kv, "");
		//LogMessage("Section: %s, Value: %s, Type: %d", sSection, sValue, type);

		if(!bIsSubSection) {
		//if(type != KvData_None) {
			json_object_set_new(hObj, sSection, json_string(sValue));
		} else {
			//We have no value, this must be another section
			new Handle:hChild = json_object();

			if (KvGotoFirstSubKey(kv, false)) {
				IterateKeyValues(kv, hChild);
				KvGoBack(kv);
			}

			json_object_set_new(hObj, sSection, hChild);
		}

	} while (KvGotoNextKey(kv, false));
}