#pragma semicolon 1
#include <sourcemod>
#include <smjansson>

/*
 *
 * Example: Creating this JSON string
 * {"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}
 *
 */
public OnPluginStart() {
	// Create a new JSON object
	new Handle:hObj = json_object();


	// Create new JSON strings/integer and 'set' them on the JSON object
	// Hint: We don't need to close the handles of the values we push,
	//       because we are using the reference stealing method
	//       json_object_set_new()
	json_object_set_new(hObj, "jsonrpc", json_string("2.0"));
	json_object_set_new(hObj, "method", json_string("subtract"));
	json_object_set_new(hObj, "id", json_integer(1));


	// Create a new JSON array and add the two integers to it.
	// Again, we don't need to close the hArray Handle, because we've
	// pushed it to the object by reference stealing.
	// This also means that the hArray handle won't be valid anymore
	// afterwards.
	new Handle:hArray = json_array();
	json_array_append_new(hArray, json_integer(42));
	json_array_append_new(hArray, json_integer(23));
	json_object_set_new(hObj, "params", hArray);


	// And finally transform the JSON object to a JSON string
	// with indenting set to 0.
	new String:sJSON[4096];
	json_dump(hObj, sJSON, sizeof(sJSON), 0);


	// And output it.
	PrintToServer("Created JSON is:\n%s\n", sJSON);


	// Close the Handle to the JSON object, i.e. free it's memory
	// and free the Handle.
	CloseHandle(hObj);
}