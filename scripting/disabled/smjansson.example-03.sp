#pragma semicolon 1
#include <sourcemod>
#include <smjansson>

/*
 *
 * Example: Converting a JSON string to KeyValues
 *
 * {
 * 	"id": "0001",
 * 	"type": "donut",
 * 	"name": "Cake",
 * 	"ppu": 0.55,
 * 	"batters":
 * 		{
 * 			"batter":
 * 				[
 * 					{ "id": "1001", "type": "Regular" },
 * 					{ "id": "1002", "type": "Chocolate" },
 * 					{ "id": "1003", "type": "Blueberry" },
 * 					{ "id": "1004", "type": "Devil's Food" }
 * 				]
 * 		},
 * 	"topping":
 * 		[
 * 			{ "id": "5001", "type": "None" },
 * 			{ "id": "5002", "type": "Glazed" },
 * 			{ "id": "5005", "type": "Sugar" },
 * 			{ "id": "5007", "type": "Powdered Sugar" },
 * 			{ "id": "5006", "type": "Chocolate with Sprinkles" },
 * 			{ "id": "5003", "type": "Chocolate" },
 * 			{ "id": "5004", "type": "Maple" }
 * 		]
 * }
 *
 */

new Handle:g_hKV;

public OnPluginStart() {
	new String:sJSON[4096] = "{ \"id\": \"0001\", \"type\": \"donut\", \"name\": \"Cake\", \"ppu\": 0.55,";
	StrCat(sJSON, sizeof(sJSON), "\"batters\": { \"batter\": [ { \"id\": \"1001\", \"type\": \"Regular\" },");
	StrCat(sJSON, sizeof(sJSON), "{ \"id\": \"1002\", \"type\": \"Chocolate\" }, { \"id\": \"1003\", \"type\": \"Blueberry\" },");
	StrCat(sJSON, sizeof(sJSON), "{ \"id\": \"1004\", \"type\": \"Devil's Food\" } ] },");
	StrCat(sJSON, sizeof(sJSON), "\"topping\": [ { \"id\": \"5001\", \"type\": \"None\" }, { \"id\": \"5002\", \"type\": \"Glazed\" },");
	StrCat(sJSON, sizeof(sJSON), "{ \"id\": \"5005\", \"type\": \"Sugar\" }, { \"id\": \"5007\", \"type\": \"Powdered Sugar\" },");
	StrCat(sJSON, sizeof(sJSON), "{ \"id\": \"5006\", \"type\": \"Chocolate with Sprinkles\" }, { \"id\": \"5003\", ");
	StrCat(sJSON, sizeof(sJSON), "\"type\": \"Chocolate\" }, { \"id\": \"5004\", \"type\": \"Maple\" } ]}");

	// Create a new JSON object
	new Handle:hObj = json_load(sJSON);

	g_hKV = CreateKeyValues("root");

	ProcessElement("root", hObj);

	KeyValuesToFile(g_hKV, "json-kv.out");
	CloseHandle(g_hKV);

	CloseHandle(hObj);
}


public ProcessElement(String:sKey[], Handle:hObj) {
	switch(json_typeof(hObj)) {
		case JSON_OBJECT: {
			// It's another object
			KvJumpToKey(g_hKV, sKey, true);
			IterateJsonObject(Handle:hObj);
			KvGoBack(g_hKV);
		}

		case JSON_ARRAY: {
			// It's another array
			KvJumpToKey(g_hKV, sKey, true);
			IterateJsonArray(Handle:hObj);
			KvGoBack(g_hKV);
		}

		case JSON_STRING: {
			new String:sString[1024];
			json_string_value(hObj, sString, sizeof(sString));
			KvSetString(g_hKV, sKey, sString);
		}

		case JSON_INTEGER: {
			KvSetNum(g_hKV, sKey, json_integer_value(hObj));
		}

		case JSON_REAL: {
			KvSetFloat(g_hKV, sKey, json_real_value(hObj));
		}

		case JSON_TRUE: {
			KvSetNum(g_hKV, sKey, 1);
		}

		case JSON_FALSE: {
			KvSetNum(g_hKV, sKey, 0);
		}

		case JSON_NULL: {
			KvSetString(g_hKV, sKey, "");
		}
	}

}


public IterateJsonArray(Handle:hArray) {
	for(new iElement = 0; iElement < json_array_size(hArray); iElement++) {
		new Handle:hValue = json_array_get(hArray, iElement);
		new String:sElement[4];
		IntToString(iElement, sElement, sizeof(sElement));
		ProcessElement(sElement, hValue);

		CloseHandle(hValue);
	}
}


public IterateJsonObject(Handle:hObj) {
	new Handle:hIterator = json_object_iter(hObj);

	while(hIterator != INVALID_HANDLE) {
		new String:sKey[128];
		json_object_iter_key(hIterator, sKey, sizeof(sKey));

		new Handle:hValue = json_object_iter_value(hIterator);

		ProcessElement(sKey, hValue);

		CloseHandle(hValue);
		hIterator = json_object_iter_next(hObj, hIterator);
	}
}