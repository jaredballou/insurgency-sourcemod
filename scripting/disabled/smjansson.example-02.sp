#pragma semicolon 1
#include <sourcemod>
#include <smjansson>

/*
 *
 * Example: Parsing a JSON string
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

new String:g_sPadding[128] = "  ";

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

	ProcessElement("root", hObj);

	CloseHandle(hObj);
}


public ProcessElement(String:sKey[], Handle:hObj) {
	switch(json_typeof(hObj)) {
		case JSON_OBJECT: {
			// It's another object
			PrintToServer("%s- %s, object with %i elements", g_sPadding, sKey, json_object_size(hObj));
			StrCat(g_sPadding, sizeof(g_sPadding), "  ");
			IterateJsonObject(Handle:hObj);
			strcopy(g_sPadding, sizeof(g_sPadding), g_sPadding[2]);
		}

		case JSON_ARRAY: {
			// It's another array
			PrintToServer("%s- %s, array with %i elements", g_sPadding, sKey, json_array_size(hObj));
			StrCat(g_sPadding, sizeof(g_sPadding), "  ");
			IterateJsonArray(Handle:hObj);
			strcopy(g_sPadding, sizeof(g_sPadding), g_sPadding[2]);
		}

		case JSON_STRING: {
			new String:sString[1024];
			json_string_value(hObj, sString, sizeof(sString));
			PrintToServer("%s- %-35s %s", g_sPadding, sKey, sString);
		}

		case JSON_INTEGER: {
			PrintToServer("%s- %-35s %i", g_sPadding, sKey, json_integer_value(hObj));
		}

		case JSON_REAL: {
			PrintToServer("%s- %-35s %f", g_sPadding, sKey, json_real_value(hObj));
		}

		case JSON_TRUE: {
			PrintToServer("%s- %-35s %s", g_sPadding, sKey, "TRUE");
		}

		case JSON_FALSE: {
			PrintToServer("%s- %-35s %s", g_sPadding, sKey, "FALSE");
		}

		case JSON_NULL: {
			PrintToServer("%s- %-35s %s", g_sPadding, sKey, "NULL");
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