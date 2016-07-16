#pragma semicolon 1
#include <sourcemod>
#include <smjansson>
#include <test>

#define VERSION 		"0.0.1"


public Plugin:myinfo = {
	name 		= "SMJansson, Test, Create JSON",
	author 		= "Thrawn",
	description = "",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_smjansson_test_version", VERSION, "Tests all SMJansson natives.",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	new bool:bStepSuccess = false;

	new Handle:hTest = Test_New(100);
	Test_Ok(hTest, LibraryExists("jansson"), "Library is loaded");

	new Handle:hObj = json_object();
	Test_IsNot(hTest, hObj, INVALID_HANDLE, "Creating JSON Object");
	Test_Ok(hTest, json_is_object(hObj), "Type is Object");

	new Handle:hString =  json_string("value");
	Test_IsNot(hTest, hString, INVALID_HANDLE, "Creating JSON String");
	Test_Ok(hTest, json_is_string(hString), "Type is String");

	new String:sString[32];
	json_string_value(hString, sString, sizeof(sString));
	Test_Is_String(hTest, sString, "value", "Checking created JSON String value");

	Test_Ok(hTest, json_string_set(hString, "The answer is 42"), "Modifying string value");
	json_string_value(hString, sString, sizeof(sString));
	Test_Is_String(hTest, sString, "The answer is 42", "Checking modified JSON String value");

	bStepSuccess = json_object_set(hObj, "__String", hString);
	Test_Ok(hTest, bStepSuccess, "Attaching modified String to root object");
	CloseHandle(hString);


	new Float:fNumberValue;
	new Float:fReal;

	new Handle:hReal = json_real(1.23456789);
	Test_IsNot(hTest, hReal, INVALID_HANDLE, "Creating JSON Real");
	Test_Is(hTest, json_typeof(hReal), _:JSON_REAL, "Type is Real");

	fReal = json_real_value(hReal);
	Test_Is_Float(hTest, fReal, 1.23456789, "Checking created JSON Real value");
	fNumberValue = json_number_value(hReal);
	Test_Is_Float(hTest, fReal, 1.23456789, "Checking result of json_number_value");

	Test_Ok(hTest, json_real_set(hReal, -444.556), "Modifying real value");
	fReal = json_real_value(hReal);
	Test_Is_Float(hTest, fReal, -444.556, "Checking modified JSON Real value");

	fNumberValue = json_number_value(hReal);
	Test_Is_Float(hTest, fReal, -444.556, "Checking result of json_number_value");

	bStepSuccess = json_object_set(hObj, "__Float", hReal);
	Test_Ok(hTest, bStepSuccess, "Attaching modified Real to root object");
	CloseHandle(hReal);



	new iInteger;
	new Handle:hInteger = json_integer(42);
	Test_IsNot(hTest, hInteger, INVALID_HANDLE, "Creating JSON Integer");
	Test_Is(hTest, json_typeof(hInteger), _:JSON_INTEGER, "Type is Integer");

	iInteger = json_integer_value(hInteger);
	Test_Is(hTest, iInteger, 42, "Checking created JSON Integer value");
	fNumberValue = json_number_value(hInteger);
	Test_Is_Float(hTest, fNumberValue, 42.0, "Checking result of json_number_value");

	Test_Ok(hTest, json_integer_set(hInteger, 1337), "Modifying integer value");
	iInteger = json_integer_value(hInteger);
	Test_Is(hTest, iInteger, 1337, "Checking modified JSON Integer value");

	fNumberValue = json_number_value(hInteger);
	Test_Is_Float(hTest, fNumberValue, 1337.0, "Checking result of json_number_value");

	bStepSuccess = json_object_set(hObj, "__Integer", hInteger);
	Test_Ok(hTest, bStepSuccess, "Attaching modified Integer to root object");

	Test_Is(hTest, json_object_size(hObj), 3, "Object has the correct size");
	CloseHandle(hInteger);



	new String:sShouldBe[128] = "{\"__Float\": -444.55599975585938, \"__String\": \"The answer is 42\", \"__Integer\": 1337}";

	new String:sJSON[4096];
	json_dump(hObj, sJSON, sizeof(sJSON), 0);

	Test_Is_String(hTest, sJSON, sShouldBe, "Created JSON is ok");




	new Handle:hObjNested = json_object();
	bStepSuccess = json_object_set(hObj, "__NestedObject", hObjNested);
	Test_Ok(hTest, bStepSuccess, "Attaching new Object to root object");
	Test_Is(hTest, json_object_size(hObj), 4, "Object has the correct size");

	bStepSuccess = json_object_set_new(hObjNested, "__NestedString", json_string("i am nested"));
	Test_Ok(hTest, bStepSuccess, "Attaching new String to nested object (using reference stealing)");

	Test_Ok(hTest, json_object_del(hObj, "__Float"), "Deleting __Float element from root object");
	Test_Is(hTest, json_object_size(hObj), 3, "Object has the correct size");




	new Handle:hArray = json_array();
	Test_IsNot(hTest, hArray, INVALID_HANDLE, "Creating JSON Array");
	Test_Is(hTest, json_typeof(hArray), _:JSON_ARRAY, "Type is Array");

	new Handle:hFirst_String = json_string("1");
	new Handle:hSecond_Float = json_real(2.0);
	new Handle:hThird_Integer = json_integer(3);
	new Handle:hFourth_String = json_string("4");
	Test_Ok(hTest, json_array_append(hArray, hFirst_String), "Appending String to Array");
	CloseHandle(hFirst_String);
	Test_Is(hTest, json_array_size(hArray), 1, "Array has correct size");
	Test_Ok(hTest, json_array_append(hArray, hSecond_Float), "Appending Float to Array");
	CloseHandle(hSecond_Float);
	Test_Is(hTest, json_array_size(hArray), 2, "Array has correct size");
	Test_Ok(hTest, json_array_insert(hArray, 0, hThird_Integer), "Inserting Integer at position 0");
	CloseHandle(hThird_Integer);
	Test_Is(hTest, json_array_size(hArray), 3, "Array has correct size");
	Test_Ok(hTest, json_array_set(hArray, 1, hFourth_String), "Setting String at position 1");
	CloseHandle(hFourth_String);
	Test_Is(hTest, json_array_size(hArray), 3, "Array has correct size");

	bStepSuccess = json_object_set(hObjNested, "__Array", hArray);
	Test_Ok(hTest, bStepSuccess, "Attaching Array to nested object");
	CloseHandle(hObjNested);


	PrintToServer("      - Creating the same Array using reference stealing");
	new Handle:hArrayStealing = json_array();
	Test_Ok(hTest, json_array_append_new(hArrayStealing, json_string("1")), "Appending new String to Array");
	Test_Ok(hTest, json_array_append_new(hArrayStealing, json_real(2.0)), "Appending new Float to Array");
	Test_Ok(hTest, json_array_insert_new(hArrayStealing, 0, json_integer(3)), "Inserting new Integer at position 0");
	Test_Ok(hTest, json_array_set_new(hArrayStealing, 1, json_string("4")), "Setting new String at position 1");

	Test_Ok(hTest, json_equal(hArray, hArrayStealing), "Arrays are equal.");
	CloseHandle(hArrayStealing);
	CloseHandle(hArray);


	DeleteFile("testoutput.json");
	bStepSuccess = json_dump_file(hObj, "testoutput.json", 2);
	Test_Ok(hTest, bStepSuccess, "File written without errors");
	Test_Ok(hTest, FileExists("testoutput.json"), "Testoutput file exists");


	// Reload the written file
	new Handle:hReloaded = json_load_file("testoutput.json");
	Test_IsNot(hTest, hReloaded, INVALID_HANDLE, "Loading JSON from file.");

	Test_Ok(hTest, json_equal(hReloaded, hObj), "Written file and data in memory are equal");

	// Iterate over the reloaded file
	new Handle:hIterator = json_object_iter(hReloaded);
	Test_IsNot(hTest, hIterator, INVALID_HANDLE, "Creating an iterator for the reloaded object.");

	// Expecting three values in random order
	// Use a trie to look em up and delete them from it -> afterwards size must be 0
	new Handle:hTestTrie = CreateTrie();
	SetTrieValue(hTestTrie, "__String", _:JSON_STRING);
	SetTrieValue(hTestTrie, "__Integer", _:JSON_INTEGER);
	SetTrieValue(hTestTrie, "__NestedObject", _:JSON_OBJECT);

	while(hIterator != INVALID_HANDLE) {
		new String:sKey[128];
		json_object_iter_key(hIterator, sKey, sizeof(sKey));

		new Handle:hValue = json_object_iter_value(hIterator);
		new json_type:xType = json_typeof(hValue);

		new String:sType[32];
		Stringify_json_type(xType, sType, sizeof(sType));

		new json_type:xShouldBeType;
		GetTrieValue(hTestTrie, sKey, xShouldBeType);

		PrintToServer("      - Found key: %s (Type: %s)", sKey, sType);
		Test_Is(hTest, xShouldBeType, _:xType, "Type is correct");
		RemoveFromTrie(hTestTrie, sKey);

		if(xType == JSON_INTEGER) {
			new Handle:hIntegerOverwrite = json_integer(9001);
			Test_Ok(hTest, json_object_iter_set(hReloaded, hIterator, hIntegerOverwrite), "Overwriting integer value at iterator position");
			CloseHandle(hIntegerOverwrite);
		}

		if(xType == JSON_STRING) {
			Test_Ok(hTest, json_object_iter_set_new(hReloaded, hIterator, json_string("What is the \"Hitchhiker's guide to the galaxy\"?")), "Overwriting string value at iterator position (using reference stealing)");
		}

		if(xType == JSON_OBJECT) {
			new Handle:hTestTrieForArray = CreateTrie();
			SetTrieValue(hTestTrieForArray, "String", 0);
			SetTrieValue(hTestTrieForArray, "Integer", 0);
			SetTrieValue(hTestTrieForArray, "Real", 0);


			new Handle:hReloadedArray = json_object_get(hValue, "__Array");
			Test_IsNot(hTest, hReloadedArray, INVALID_HANDLE, "Getting JSON Array from reloaded object");
			Test_Is(hTest, json_array_size(hReloadedArray), 3, "Array has correct size");

			for(new iElement = 0; iElement < json_array_size(hReloadedArray); iElement++) {
				new Handle:hElement = json_array_get(hReloadedArray, iElement);
				new String:sArrayType[32];
				Stringify_json_type(json_typeof(hElement), sArrayType, sizeof(sArrayType));

				PrintToServer("      - Found element with type: %s", sArrayType);
				RemoveFromTrie(hTestTrieForArray, sArrayType);
				CloseHandle(hElement);
			}

			Test_Is(hTest, GetTrieSize(hTestTrieForArray), 0, "Looped over all array elements");
			CloseHandle(hTestTrieForArray);

			Test_Ok(hTest, json_array_remove(hReloadedArray, 2), "Deleting 3rd element from array");
			Test_Is(hTest, json_array_size(hReloadedArray), 2, "Array has correct size");

			new Handle:hArrayForExtending = json_array();
			new Handle:hStringForExtension = json_string("Extension 1");
			new Handle:hStringForExtension2 = json_string("Extension 2");
			json_array_append(hArrayForExtending, hStringForExtension);
			json_array_append(hArrayForExtending, hStringForExtension2);
			CloseHandle(hStringForExtension);
			CloseHandle(hStringForExtension2);

			Test_Ok(hTest, json_array_extend(hReloadedArray, hArrayForExtending), "Extending array");
			Test_Is(hTest, json_array_size(hReloadedArray), 4, "Array has correct size");

			Test_Ok(hTest, json_array_clear(hArrayForExtending), "Clearing array");
			Test_Is(hTest, json_array_size(hArrayForExtending), 0, "Array is empty");
			CloseHandle(hArrayForExtending);
			CloseHandle(hReloadedArray);
		}

		CloseHandle(hValue);
		hIterator = json_object_iter_next(hReloaded, hIterator);
	}
	Test_Is(hTest, GetTrieSize(hTestTrie), 0, "Iterator looped over all keys");
	CloseHandle(hTestTrie);
	Test_OkNot(hTest, json_equal(hReloaded, hObj), "Written file and data in memory are not equal anymore");

	PrintToServer("      - Creating the same object using json_pack");
	new Handle:hParams = CreateArray(64);
	PushArrayString(hParams,	"__String");
	PushArrayString(hParams,	"What is the \"Hitchhiker's guide to the galaxy\"?");
	PushArrayString(hParams,	"__Integer");
	PushArrayCell(hParams,		9001);
	PushArrayString(hParams,	"__NestedObject");
	PushArrayString(hParams,	"__NestedString");
	PushArrayString(hParams,	"i am nested");
	PushArrayString(hParams,	"__Array");
	PushArrayCell(hParams,		3);
	PushArrayString(hParams,	"4");
	PushArrayString(hParams,	"Extension 1");
	PushArrayString(hParams,	"Extension 2");
	new Handle:hPacked = json_pack("{ss,s:is{sss:[isss]}}", hParams);
	CloseHandle(hParams);
	Test_Ok(hTest, json_equal(hReloaded, hPacked), "Packed JSON is equal to manually created JSON");
	CloseHandle(hPacked);

	PrintToServer("      - Testing all json_pack values");
	new Handle:hParamsAll = CreateArray(64);
	PushArrayString(hParamsAll,	"String");
	PushArrayCell(hParamsAll,	42);
	PushArrayCell(hParamsAll,	13.37);
	PushArrayCell(hParamsAll,	20001.333);
	PushArrayCell(hParamsAll,	true);
	PushArrayCell(hParamsAll,	false);
	new Handle:hPackAll = json_pack("[sifrbnb]", hParamsAll);
	Test_Ok(hTest, json_is_array(hPackAll), "Packed JSON is an array");

	new String:sElementOne[32];
	json_array_get_string(hPackAll, 0, sElementOne, sizeof(sElementOne));
	Test_Is_String(hTest, sElementOne, "String", "Element 1 has the correct string value");
	Test_Is(hTest, json_array_get_int(hPackAll, 1), 42, "Element 2 has the correct integer value");
	Test_Is(hTest, json_array_get_float(hPackAll, 2), 13.37, "Element 3 has the correct float value");
	Test_Is(hTest, json_array_get_float(hPackAll, 3), 20001.333, "Element 4 has the correct float value");
	Test_Is(hTest, json_array_get_bool(hPackAll, 4), true, "Element 5 is boolean true.");

	new Handle:hElementFive = json_array_get(hPackAll, 5);
	Test_Is(hTest, json_typeof(hElementFive), JSON_NULL, "Element 6 is null.");
	CloseHandle(hElementFive);

	Test_Is(hTest, json_array_get_bool(hPackAll, 6), false, "Element 7 is boolean false.");

	CloseHandle(hParamsAll);


	PrintToServer("      - Creating new object with 4 keys via load");
	new Handle:hObjManipulation = json_load("{\"A\":1,\"B\":2,\"C\":3,\"D\":4}");
	Test_Ok(hTest, json_object_del(hObjManipulation, "D"), "Deleting element from object");
	Test_Is(hTest, json_object_size(hObjManipulation), 3, "Object size is correct");


	PrintToServer("      - Creating new object to update the previous one");
	new Handle:hObjUpdate = json_load("{\"A\":10,\"B\":20,\"C\":30,\"D\":40,\"E\":50,\"F\":60,\"G\":70}");
	Test_Ok(hTest, json_object_update_existing(hObjManipulation, hObjUpdate), "Updating existing keys");

	new Handle:hReadC = json_object_get(hObjManipulation, "C");
	Test_Is(hTest, json_integer_value(hReadC), 30, "Element update successful");
	Test_Is(hTest, json_object_size(hObjManipulation), 3, "Object size is correct");
	CloseHandle(hReadC);

	Test_Ok(hTest, json_object_update_missing(hObjManipulation, hObjUpdate), "Updating missing keys");
	new Handle:hReadF = json_object_get(hObjManipulation, "F");
	Test_Is(hTest, json_integer_value(hReadF), 60, "Element insertion via update successful");
	Test_Is(hTest, json_object_size(hObjManipulation), 7, "Object size is correct");
	CloseHandle(hReadF);

	Test_Ok(hTest, json_object_clear(hObjManipulation), "Clearing new object");
	Test_Is(hTest, json_object_size(hObjManipulation), 0, "Object is empty");

	PrintToServer("      - Adding one of the original four keys");
	new Handle:hBNew = json_integer(2);
	json_object_set(hObjManipulation, "B", hBNew);
	Test_Ok(hTest, json_object_update(hObjManipulation, hObjUpdate), "Updating all keys");
	CloseHandle(hBNew);
	CloseHandle(hObjUpdate);

	new Handle:hReadB = json_object_get(hObjManipulation, "B");
	Test_Is(hTest, json_integer_value(hReadB), 20, "Element update successful");
	CloseHandle(hReadB);

	Test_Is(hTest, json_object_size(hObjManipulation), 7, "Object size is correct");

	PrintToServer("      - Creating and adding an array to the object");
	new Handle:hCopyArray = json_array();
	new Handle:hNoMoreVariableNames = json_string("no more!");
	new Handle:hEvenLessVariableNames = json_string("less n less!");
	json_array_append(hCopyArray, hNoMoreVariableNames);
	json_array_append(hCopyArray, hEvenLessVariableNames);
	json_object_set(hObjManipulation, "Array", hCopyArray);


	new Handle:hCopy = json_copy(hObjManipulation);
	Test_IsNot(hTest, hCopy, INVALID_HANDLE, "Creating copy of JSON Object");
	Test_Is(hTest, json_object_size(hCopy), 8, "Object size is correct");
	Test_Ok(hTest, json_equal(hCopy, hObjManipulation), "Objects are equal");

	PrintToServer("      - Modifying the array of the original Object");
	new Handle:hEmptyVariableNames = json_string("empty!");
	json_array_append(hCopyArray, hEmptyVariableNames);

	Test_Ok(hTest, json_equal(hCopy, hObjManipulation), "Content of copy is still identical (was a shallow copy)");


	new Handle:hDeepCopy = json_deep_copy(hObjManipulation);
	Test_IsNot(hTest, hDeepCopy, INVALID_HANDLE, "Creating deep copy of JSON Object");
	Test_Is(hTest, json_object_size(hDeepCopy), 8, "Object size is correct");
	Test_Ok(hTest, json_equal(hDeepCopy, hObjManipulation), "Objects are equal");

	PrintToServer("      - Modifying the array of the original Object");
	new Handle:hDeadVariableNames = json_string("dead!");
	json_array_append(hCopyArray, hDeadVariableNames);
	CloseHandle(hCopyArray);

	Test_OkNot(hTest, json_equal(hDeepCopy, hObjManipulation), "Content of copy is not identical anymore (was a deep copy)");


	new Handle:hBooleanObject = json_object();
	json_object_set_new(hBooleanObject, "true1", json_true());
	json_object_set_new(hBooleanObject, "false1", json_false());
	json_object_set_new(hBooleanObject, "true2", json_boolean(true));
	json_object_set_new(hBooleanObject, "false2", json_boolean(false));
	json_object_set_new(hBooleanObject, "null", json_null());

	new String:sBooleanObjectDump[4096];
	json_dump(hBooleanObject, sBooleanObjectDump, sizeof(sBooleanObjectDump), 0);

	new String:sBooleanShouldBe[4096] = "{\"false2\": false, \"true1\": true, \"false1\": false, \"true2\": true, \"null\": null}";
	Test_Is_String(hTest, sBooleanObjectDump, sBooleanShouldBe, "Created JSON matches");

	CloseHandle(hBooleanObject);



	json_dump(hObj, sJSON, sizeof(sJSON));
	PrintToServer("\nJSON 1:\n-------------\n%s\n-------------\n", sJSON);


	new String:sJSONReloaded[4096];
	json_dump(hReloaded, sJSONReloaded, sizeof(sJSONReloaded), 2);
	PrintToServer("JSON 2:\n-------------\n%s\n-------------\n", sJSONReloaded);

	new String:sJSONManipulated[4096];
	json_dump(hObjManipulation, sJSONManipulated, sizeof(sJSONManipulated), 0);
	PrintToServer("JSON 3:\n-------------\n%s\n-------------\n", sJSONManipulated);


	PrintToServer("JSON 4:\n-------------\n%s\n-------------\n", sBooleanObjectDump);

	new String:sJSONPackAll[4096];
	json_dump(hPackAll, sJSONPackAll, sizeof(sJSONPackAll), 4);

	PrintToServer("JSON 5:\n-------------\n%s\n-------------\n", sJSONPackAll);

	CloseHandle(hPackAll);
	CloseHandle(hObj);
	CloseHandle(hObjManipulation);
	CloseHandle(hReloaded);

	// Finish testing
	Test_End(hTest);
	CloseHandle(hTest);
}
