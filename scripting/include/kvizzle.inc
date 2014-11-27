/*
Kvizzle
By F2


Features:
- Supports having several KVs open simultaneously
- Pseudo-Classes (like :first-child, :nth-child(n), :any-child)
- Checks (like :has-value(val))
- Actions (like :count, :section-name)
- A traversal stack (with KvizJumpToKey, KvizGoBack and KvizRewind)
- Escaping in path (with backslash)
- Read from file and write to file



Public functions:

- KvizEscape(String:dest[], destLen, const String:src[])

- Handle:KvizCreate(const String:name[])
- Handle:KvizCreateFromFile(const String:name[], const String:file[])
- bool:KvizToFile(Handle:kv, const String:file[], const String:kvizPath[] = "", any:...)
- bool:KvizClose(Handle:kv) {

- bool:KvizGetStringExact(Handle:kv, String:value[], valueLen, const String:path[], any:...)
- bool:KvizGetString(Handle:kv, String:value[], valueLen, const String:defVal[], const String:path[], any:...)
- bool:KvizSetString(Handle:kv, const String:value[], const String:path[], any:...)

- bool:KvizGetNumExact(Handle:kv, &value, const String:path[], any:...)
- KvizGetNum(Handle:kv, defVal, const String:path[], any:...)
- bool:KvizSetNum(Handle:kv, value, const String:path[], any:...)

- bool:KvizGetFloatExact(Handle:kv, &Float:value, const String:path[], any:...)
- Float:KvizGetFloat(Handle:kv, Float:defVal, const String:path[], any:...)
- bool:KvizSetFloat(Handle:kv, Float:value, const String:path[], any:...)

- bool:KvizGetVectorExact(Handle:kv, Float:value[3], const String:path[], any:...)
- bool:KvizGetVector(Handle:kv, Float:vec[3], const Float:defVal[3], const String:path[], any:...)
- bool:KvizSetVector(Handle:kv, Float:vec[3], const String:path[], any:...)

- bool:KvizGetColorExact(Handle:kv, &r, &g, &b, &a, const String:path[], any:...)
- bool:KvizGetColor(Handle:kv, &r, &g, &b, &a, defR, defG, defB, defA, const String:path[], any:...)
- bool:KvizSetColor(Handle:kv, r, g, b, a, const String:path[], any:...)

- bool:KvizGetUInt64Exact(Handle:kv, value[2], const String:path[], any:...)
- bool:KvizGetUInt64(Handle:kv, value[2], const defVal[2], const String:path[], any:...)
- bool:KvizSetUInt64(Handle:kv, value[2], const String:path[], any:...)

- bool:KvizDelete(Handle:kv, const String:path[], any:...)

- bool:KvizExists(Handle:kv, const String:path[], any:...)

- bool:KvizJumpToKey(Handle:kv, bool:create, const String:path[], any:...)
- bool:KvizGoBack(Handle:kv)
- bool:KvizRewind(Handle:kv)



TODO:
- Write more comments in the code ;)
*/

#if defined _kvizzle_included
 #endinput
#endif
#define _kvizzle_included

#define KVIZZLE_VERSION		"1.0.0"

// Customizable settings
const Kviz_iMaxContexts = 4; // Max number of simultaneously open Kvizzles. You can still use more, but the performance will degrade. However, if you set the number too high, then the performance will degrade when you have few Kvizzles opened simultaneously.
const Kviz_iMaxPathDepth = 32; // Max path depth... ie: aa.bb.cc.dd.ee(...).zz. Depth 32 equals 31 periods.
const Kviz_iMaxTraversalStack = 32; // Max size of the traversal stack. The size of the traversal stack gets increased by 1 every time you call KvizJumpToKey, and decreased by 1 every time you call KvizGoBack. You can set it to 0 by calling KvizRewind.
const Kviz_iMaxSectionLen = 128; // Max string length of a section in a Kv-file.
// ---------------------



const KVIZ_ACTION_NONE = 0;
const KVIZ_PSEUDO_FIRSTCHILD = 10;	// :first-child
const KVIZ_PSEUDO_LASTCHILD = 11;	// :last-child
const KVIZ_PSEUDO_NTHCHILD = 12;	// :nth-child
const KVIZ_PSEUDO_ANYCHILD = 13;	// :any-child
const KVIZ_PSEUDO_UP = 14;			// :parent, :up

const KVIZ_CHECK_MIN = 20;
const KVIZ_CHECK_HASVALUE = 21;		// :has-value, :has-value(text)
const KVIZ_CHECK_HASVALUE_CI = 22;	// :has-value-ci, :has-value-ci(text)
const KVIZ_CHECK_MAX = 29;

const KVIZ_ACTION_MIN = 30;
const KVIZ_ACTION_COUNT = 31;		// :count
const KVIZ_ACTION_SECTIONNAME = 32;	// :section-name
const KVIZ_ACTION_VALUE = 33;		// :value
const KVIZ_ACTION_VALUEORSECTION = 34; // :value-or-section


enum KvizData {
	Handle:Kviz_hKv,
	Kviz_iPositionPathCount,
	
	Kviz_iTraversalStack[Kviz_iMaxTraversalStack],
	Kviz_iTraversalStackLen,
	
	Kviz_iLRU,
}

new Kviz[Kviz_iMaxContexts][KvizData];
new String:Kviz_sPositionPath[Kviz_iMaxContexts][Kviz_iMaxPathDepth][Kviz_iMaxSectionLen];
new String:Kviz_sPositionPathPseudoClass[Kviz_iMaxContexts][Kviz_iMaxPathDepth][Kviz_iMaxSectionLen];
new Kviz_sPositionPathNthChild[Kviz_iMaxContexts][Kviz_iMaxPathDepth];
new Kviz_iCurrentContext = 0;
new Kviz_bInited = false;
new Handle:Kviz_hPseudoClassTrie = INVALID_HANDLE;
new Handle:Kviz_hArchiveKv;
new Handle:Kviz_hArchiveTraversalStack;
new Kviz_iLRUCounter = 0;




/** 
 * Escapes a string, so it can be used in a Kvizzle path.
 *
 * @param dest		Buffer to store the escaped string in. Can be the same as src.
 * @param destLen	Length of dest.
 * @param src		Source string that needs to be escaped.
 * @noreturn
 */
stock KvizEscape(String:dest[], destLen, const String:src[]) {
	decl String:buffer[destLen];
	new srcPos = 0, destPos = 0;
	while (destPos + 1 < destLen && src[srcPos] != '\0') {
		if (src[srcPos] == ':' || src[srcPos] == '.') {
			buffer[destPos++] = '\\';
			if (destPos == destLen)
				break;
		}
		buffer[destPos++] = src[srcPos++];
	}
	buffer[destPos] = '\0';
	strcopy(dest, destLen, buffer);
}

/** 
 * Creates an empty Kvizzle.
 *
 * @param name	The name of the root node.
 * @return		A new Kvizzle handle, or INVALID_HANDLE in case of error.
 */
stock Handle:KvizCreate(const String:name[]) {
	if (!Kviz_bInited)
		KvizInit();
	
	new Handle:kv = CreateKeyValues(name);
	if (kv == INVALID_HANDLE)
		return INVALID_HANDLE;
	if (!KvizSwitchContext(kv, true)) {
		CloseHandle(kv);
		return INVALID_HANDLE;
	}
	return kv;
}

/** 
 * Creates a Kvizzle based on a KeyValues file.
 *
 * @param name	The name of the root node.
 * @param file	The path for the KeyValues file.
 * @return		A new Kvizzle handle, or INVALID_HANDLE in case of error.
 */
stock Handle:KvizCreateFromFile(const String:name[], const String:file[]) {
	if (!Kviz_bInited)
		KvizInit();
	
	new Handle:kv = CreateKeyValues(name);
	if (kv == INVALID_HANDLE)
		return INVALID_HANDLE;
	if (!FileToKeyValues(kv, file)) {
		CloseHandle(kv);
		return INVALID_HANDLE;
	}
	if (!KvizSwitchContext(kv, true)) {
		CloseHandle(kv);
		return INVALID_HANDLE;
	}
	return kv;
}

/** 
 * Saves the Kvizzle (using the given path as the root) to a file.
 *
 * @param kv		Kvizzle Handle.
 * @param file		Path to the file where the Kvizzle will be saved.
 * @param kvizPath	The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			A new Kvizzle handle, or INVALID_HANDLE in case of error.
 * @error		Invalid Handle.
 */
stock bool:KvizToFile(Handle:kv, const String:file[], const String:kvizPath[] = "", any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), kvizPath, 4);
	new action;
	if (!KvizGoto(kv, path2, false, action))
		return false;
	
	return KeyValuesToFile(kv, file);
}

/** 
 * Closes the Kvizzle. Must be called once for every KvizCreate/KvizCreateFromFile.
 *
 * @param kv	Kvizzle Handle.
 * @return		True if the Kvizzle was open and is now closed. Otherwise false (eg. wrong handle, or it was already closed).
 * @error		Invalid Handle.
 */
stock bool:KvizClose(Handle:kv) {
	if (!KvizSwitchContext(kv))
		return false;
	
	KvizRemoveContext(kv);
	CloseHandle(kv);
	return true;
}


// ------------------
// Get/Set String
// ------------------

/** 
 * Retrieves a string value from the Kvizzle.
 *
 * @param kv		Kvizzle Handle.
 * @param value		Buffer to store the string value.
 * @param valueLen	Length of the buffer.		
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the string value was retrieved. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizGetStringExact(Handle:kv, String:value[], valueLen, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 5);
	new action;
	if (KvizGoto(kv, path2, false, action)) {
		switch (action) {
			case KVIZ_ACTION_NONE, KVIZ_ACTION_VALUE: {
				if (KvGetDataType(kv, NULL_STRING) == KvData_None)
					return false; // We are at a section: "xyz" { ... }
				KvGetString(kv, NULL_STRING, value, valueLen);
				return true;
			}
			case KVIZ_ACTION_SECTIONNAME: {
				KvGetSectionName(kv, value, valueLen);
				return true;
			}
			case KVIZ_ACTION_COUNT: {
				LogError("Kvizzle - KvizGetString does not support :count (in %s)", path);
				return false;
			}
			default:
				LogError("Kvizzle - Unknown action: %s / %i", path, action);
		}
	}
	
	return false;
}

/** 
 * Retrieves a string value from the Kvizzle, or the given default value if not found.
 *
 * @param kv		Kvizzle Handle.
 * @param value		Buffer to store the string value.
 * @param valueLen	Length of the buffer.
 * @param defVal	The default value to be used.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the string value was retrieved. False if the default value was used.
 * @error			Invalid Handle.
 */
stock bool:KvizGetString(Handle:kv, String:value[], valueLen, const String:defVal[], const String:path[], any:...) {
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 6);
	
	if (!KvizGetStringExact(kv, value, valueLen, "%s", path2)) {
		strcopy(value, valueLen, defVal);
		return false;
	}
	
	return true;
}

/** 
 * Sets a string value in the Kvizzle at the given path. If the path does not exist, it is created.
 *
 * @param kv		Kvizzle Handle.
 * @param value		The value to be written.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True on succes. Otherwise false (eg. wrong handle).
 * @error			Invalid Handle.
 */
stock bool:KvizSetString(Handle:kv, const String:value[], const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, true, action)) {
		if (action == KVIZ_ACTION_NONE || action == KVIZ_ACTION_VALUE) {
			KvSetString(kv, NULL_STRING, value);
			return true;
		} else if (action == KVIZ_ACTION_SECTIONNAME) {
			KvSetSectionName(kv, value);
			return true;
		} else {
			LogError("Kvizzle - KvizSetString does not support action %i (in %s)", action, path);
		}
	}
	return false;
}



// ------------------
// Get/Set Num
// ------------------

/** 
 * Retrieves an integer value from the Kvizzle.
 *
 * @param kv		Kvizzle Handle.
 * @param value		Integer value, set by reference.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and its value was indeed an integer. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizGetNumExact(Handle:kv, &value, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:strvalue[64];
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, false, action)) {
		switch (action) {
			case KVIZ_ACTION_NONE, KVIZ_ACTION_VALUE: {
				if (KvGetDataType(kv, NULL_STRING) == KvData_None)
					return false; // We are at a section: "xyz" { ... }
				KvGetString(kv, NULL_STRING, strvalue, sizeof(strvalue));
				if (StringToIntEx(strvalue, value) == strlen(strvalue))
					return true;
				return false;
			}
			case KVIZ_ACTION_SECTIONNAME: {
				KvGetSectionName(kv, strvalue, sizeof(strvalue));
				if (StringToIntEx(strvalue, value) == strlen(strvalue))
					return true;
				return false;
			}
			case KVIZ_ACTION_COUNT: {
				value = 0;
				if (KvGotoFirstSubKey(kv, false)) {
					do {
						value++;
					} while (KvGotoNextKey(kv, false));
					KvGoBack(kv);
				}
				
				return true;
			}
			default:
				LogError("Kvizzle - Unknown action: %s / %i", path, action);
		}
	}
	
	return false;
}

/** 
 * Retrieves an integer value from the Kvizzle, or the default value if the path does not exist.
 *
 * @param kv		Kvizzle Handle.
 * @param defVal	The default value.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			The retrieved integer value, if the path existed. Otherwise, the default value.
 * @error			Invalid Handle.
 */
stock KvizGetNum(Handle:kv, defVal, const String:path[], any:...) {
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	
	new value;
	if (!KvizGetNumExact(kv, value, "%s", path2))
		return defVal;
	
	return value;
}

/** 
 * Sets an integer value in the Kvizzle at the given path. If the path does not exist, it is created.
 *
 * @param kv		Kvizzle Handle.
 * @param value		The value to be written.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True on succes. Otherwise false (eg. wrong handle).
 * @error			Invalid Handle.
 */
stock bool:KvizSetNum(Handle:kv, value, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, true, action)) {
		if (action == KVIZ_ACTION_NONE || action == KVIZ_ACTION_VALUE) {
			KvSetNum(kv, NULL_STRING, value);
			return true;
		} else if (action == KVIZ_ACTION_SECTIONNAME) {
			decl String:strvalue[64];
			IntToString(value, strvalue, sizeof(strvalue));
			KvSetSectionName(kv, strvalue);
			return true;
		} else {
			LogError("Kvizzle - KvizSetNum does not support action %i (in %s)", action, path);
		}
	}
	return false;
}




// ------------------
// Get/Set UInt64
// ------------------

/** 
 * Retrieves an UInt64 value from the Kvizzle.
 *
 * @param kv		Kvizzle Handle.
 * @param value		Buffer to store the UInt64 value.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the UInt64 value was retrieved. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizGetUInt64Exact(Handle:kv, value[2], const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, false, action)) {
		switch (action) {
			case KVIZ_ACTION_NONE, KVIZ_ACTION_VALUE: {
				if (KvGetDataType(kv, NULL_STRING) == KvData_None)
					return false; // We are at a section: "xyz" { ... }
				// It turns out, KvGetUInt64 doesn't use the default value, if the kv-value is malformatted. In that case it just returns {0,0}.
				KvGetUInt64(kv, NULL_STRING, value);
				return true;
			}
			case KVIZ_ACTION_SECTIONNAME:
				LogError("Kvizzle - KvizGetUInt64 does not support :section-name (in %s)", path);
			case KVIZ_ACTION_COUNT:
				LogError("Kvizzle - KvizGetUInt64 does not support :count (in %s)", path);
			default:
				LogError("Kvizzle - Unknown action: %s / %i", path, action);
		}
	}
	
	return false;
}

/** 
 * Retrieves an UInt64 value from the Kvizzle, or the default value if the path does not exist.
 *
 * @param kv		Kvizzle Handle.
 * @param value		Buffer to store the UInt64 value.
 * @param defVal	Default value.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the UInt64 value was retrieved. False if the default value was used.
 * @error			Invalid Handle.
 */
stock bool:KvizGetUInt64(Handle:kv, value[2], const defVal[2], const String:path[], any:...) {
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 5);
	
	if (!KvizGetUInt64Exact(kv, value, "%s", path2)) {
		value[0] = defVal[0];
		value[1] = defVal[1];
		return false;
	}
	
	return true;
}

/** 
 * Sets an UInt64 value in the Kvizzle at the given path. If the path does not exist, it is created.
 *
 * @param kv		Kvizzle Handle.
 * @param value		The value to be written.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True on succes. Otherwise false (eg. wrong handle).
 * @error			Invalid Handle.
 */
stock bool:KvizSetUInt64(Handle:kv, value[2], const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, true, action)) {
		if (action == KVIZ_ACTION_NONE || action == KVIZ_ACTION_VALUE) {
			KvSetUInt64(kv, NULL_STRING, value);
			return true;
		} else if (action == KVIZ_ACTION_SECTIONNAME)
			LogError("Kvizzle - KvizSetUInt64 does not support :section-name (in %s)", path);
		else
			LogError("Kvizzle - KvizSetUInt64 does not support action %i (in %s)", action, path);
	}
	return false;
}




// ------------------
// Get/Set Color
// ------------------

/** 
 * Retrieves a color value from the Kvizzle.
 *
 * @param kv		Kvizzle Handle.
 * @param r			Red value, set by reference.
 * @param g			Green value, set by reference. 
 * @param b			Blue value, set by reference. 
 * @param a			Alpha value, set by reference. 
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the color value was retrieved. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizGetColorExact(Handle:kv, &r, &g, &b, &a, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 7);
	new action;
	if (KvizGoto(kv, path2, false, action)) {
		switch (action) {
			case KVIZ_ACTION_NONE, KVIZ_ACTION_VALUE: {
				if (KvGetDataType(kv, NULL_STRING) == KvData_None)
					return false; // We are at a section: "xyz" { ... }
				KvGetColor(kv, NULL_STRING, r, g, b, a);
				return true;
			}
			case KVIZ_ACTION_SECTIONNAME:
				LogError("Kvizzle - KvizGetColor does not support :section-name (in %s)", path);
			case KVIZ_ACTION_COUNT:
				LogError("Kvizzle - KvizGetColor does not support :count (in %s)", path);
			default:
				LogError("Kvizzle - Unknown action: %s / %i", path, action);
		}
	}
	
	return false;
}

/** 
 * Retrieves a color value from the Kvizzle, or the given default value if the path does not exist.
 *
 * @param kv		Kvizzle Handle.
 * @param r			Red value, set by reference.
 * @param g			Green value, set by reference. 
 * @param b			Blue value, set by reference. 
 * @param a			Alpha value, set by reference. 
 * @param defR		Default red value.
 * @param defG		Default green value.
 * @param defB		Default blue value.
 * @param defA		Default alpha value.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the color value was retrieved. False if the default values were used.
 * @error			Invalid Handle.
 */
stock bool:KvizGetColor(Handle:kv, &r, &g, &b, &a, defR, defG, defB, defA, const String:path[], any:...) {
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 11);
	
	if (!KvizGetColorExact(kv, r, g, b, a, "%s", path2)) {
		r = defR;
		g = defG;
		b = defB;
		a = defA;
		return false;
	}
	
	return true;
}

/** 
 * Sets a color value in the Kvizzle at the given path. If the path does not exist, it is created.
 *
 * @param kv		Kvizzle Handle.
 * @param r			Red value.
 * @param g			Green value. 
 * @param b			Blue value. 
 * @param a			Alpha value. 
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True on succes. Otherwise false (eg. wrong handle).
 * @error			Invalid Handle.
 */
stock bool:KvizSetColor(Handle:kv, r, g, b, a, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 7);
	new action;
	if (KvizGoto(kv, path2, true, action)) {
		if (action == KVIZ_ACTION_NONE || action == KVIZ_ACTION_VALUE) {
			KvSetColor(kv, NULL_STRING, r, g, b, a);
			return true;
		} else if (action == KVIZ_ACTION_SECTIONNAME) {
			decl String:strvalue[64];
			FormatEx(strvalue, sizeof(strvalue), "%i %i %i %i", r, g, b, a);
			KvSetSectionName(kv, strvalue);
			return true;
		} else
			LogError("Kvizzle - KvizSetColor does not support action %i (in %s)", action, path);
	}
	return false;
}





// ------------------
// Get/Set Float
// ------------------

/** 
 * Retrieves a float value from the Kvizzle.
 *
 * @param kv		Kvizzle Handle.
 * @param value		The retrieved float value, set by reference.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the retrieved value was indeed a float. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizGetFloatExact(Handle:kv, &Float:value, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:strvalue[64];
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, false, action)) {
		switch (action) {
			case KVIZ_ACTION_NONE, KVIZ_ACTION_VALUE: {
				if (KvGetDataType(kv, NULL_STRING) == KvData_None)
					return false; // We are probably at a section: "xyz" { ... }
				KvGetString(kv, NULL_STRING, strvalue, sizeof(strvalue));
				if (StringToFloatEx(strvalue, value) == strlen(strvalue))
					return true;
				return false;
			}
			case KVIZ_ACTION_SECTIONNAME: {
				KvGetSectionName(kv, strvalue, sizeof(strvalue));
				if (StringToFloatEx(strvalue, value) == strlen(strvalue))
					return true;
				return false;
			}
			case KVIZ_ACTION_COUNT:
				LogError("Kvizzle - KvizGetFloat does not support :count (in %s)", path);
			default:
				LogError("Kvizzle - Unknown action: %s / %i", path, action);
		}
	}
	
	return false;
}

/** 
 * Retrieves a float value from the Kvizzle, or the given default value if the path does not exist.
 *
 * @param kv		Kvizzle Handle.
 * @param defVal	The default value.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			Returns the retrieved float value, or the default value if the path does not exist.
 * @error			Invalid Handle.
 */
stock Float:KvizGetFloat(Handle:kv, Float:defVal, const String:path[], any:...) {
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	
	new Float:value;
	if (!KvizGetFloatExact(kv, value, "%s", path2))
		return defVal;
	
	return value;
}

/** 
 * Sets a float value in the Kvizzle at the given path. If the path does not exist, it is created.
 *
 * @param kv		Kvizzle Handle.
 * @param value		The value to be written.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True on succes. Otherwise false (eg. wrong handle).
 * @error			Invalid Handle.
 */
stock bool:KvizSetFloat(Handle:kv, Float:value, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, true, action)) {
		if (action == KVIZ_ACTION_NONE || action == KVIZ_ACTION_VALUE) {
			KvSetFloat(kv, NULL_STRING, value);
			return true;
		} else if (action == KVIZ_ACTION_SECTIONNAME) {
			decl String:strvalue[64];
			FloatToString(value, strvalue, sizeof(strvalue));
			KvSetSectionName(kv, strvalue);
			return true;
		} else
			LogError("Kvizzle - KvizSetFloat does not support action %i (in %s)", action, path);
	}
	return false;
}




// ------------------
// Get/Set Vector
// ------------------

/** 
 * Retrieves a vector value from the Kvizzle.
 *
 * @param kv		Kvizzle Handle.
 * @param value		Buffer to store the vector value.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the vector value was retrieved. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizGetVectorExact(Handle:kv, Float:value[3], const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:strvalue[64];
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, false, action)) {
		switch (action) {
			case KVIZ_ACTION_NONE, KVIZ_ACTION_VALUE: {
				if (KvGetDataType(kv, NULL_STRING) == KvData_None)
					return false; // We are at a section: "xyz" { ... }
				KvGetString(kv, NULL_STRING, strvalue, sizeof(strvalue));
				if (KvizStringToVector(strvalue, value))
					return true;
				return false;
			}
			case KVIZ_ACTION_SECTIONNAME: {
				KvGetSectionName(kv, strvalue, sizeof(strvalue));
				if (KvizStringToVector(strvalue, value))
					return true;
				return false;
			}
			case KVIZ_ACTION_COUNT:
				LogError("Kvizzle - KvizGetFloat does not support :count (in %s)", path);
			default:
				LogError("Kvizzle - Unknown action: %s / %i", path, action);
		}
	}
	
	return false;
}

/** 
 * Retrieves a vector value from the Kvizzle, or the default value if the path does not exist.
 *
 * @param kv		Kvizzle Handle.
 * @param value		Buffer to store the vector value.
 * @param defVal	The default value.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path existed and the vector value was retrieved. False if the default value was used.
 * @error			Invalid Handle.
 */
stock bool:KvizGetVector(Handle:kv, Float:vec[3], const Float:defVal[3], const String:path[], any:...) {
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 5);
	
	if (!KvizGetVectorExact(kv, vec, "%s", path2)) {
		vec[0] = defVal[0];
		vec[1] = defVal[1];
		vec[2] = defVal[2];
		return false;
	}
	
	return true;
}

/** 
 * Sets a vector value in the Kvizzle at the given path. If the path does not exist, it is created.
 *
 * @param kv		Kvizzle Handle.
 * @param vec		The value to be written.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True on succes. Otherwise false (eg. wrong handle).
 * @error			Invalid Handle.
 */
stock bool:KvizSetVector(Handle:kv, Float:vec[3], const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	new action;
	if (KvizGoto(kv, path2, true, action)) {
		if (action == KVIZ_ACTION_NONE || action == KVIZ_ACTION_VALUE) {
			KvSetVector(kv, NULL_STRING, vec);
			return true;
		} else if (action == KVIZ_ACTION_SECTIONNAME) {
			decl String:strvalue[128];
			Format(strvalue, sizeof(strvalue), "%f %f %f", vec[0], vec[1], vec[2]);
			KvSetSectionName(kv, strvalue);
			return true;
		} else
			LogError("Kvizzle - KvizSetVector does not support action %i (in %s)", action, path);
	}
	return false;
}




/** 
 * Deletes a node at the given path.
 *
 * @param kv		Kvizzle Handle.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the node was found and deleted. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizDelete(Handle:kv, const String:path[], any:...) {
	// NOTE: Be aware that when you delete something, the value of a pseudo-class might change. In that case, we will need to remove that pseudo-class from the path stack. However, for first-child, last-child and nth-child it is not a problem. any-child and parent are not saved on the path stack.
	
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 3);
	new action;
	if (!KvizGoto(kv, path2, false, action) || action != KVIZ_ACTION_NONE)
		return false;
	
	new ret = KvDeleteThis(kv);
	//PrintToServer("Delete=%i", ret);
	if (ret == 1) {
		new pathDepth = Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount] - 1;
		KvGetSectionName(kv, Kviz_sPositionPath[Kviz_iCurrentContext][pathDepth], sizeof(Kviz_sPositionPath[][]));
		//Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][pathDepth][0] = '\0';
		//PrintToServer("new section: %s", Kviz_sPositionPath[Kviz_iCurrentContext][pathDepth]);
		return true;
	} else if (ret == -1) {
		Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]--;
		return true;
	} else {
		return false;
	}
}

/** 
 * Jump to a key in the Kvizzle. All subsequent calls to Kv* will be relative to this path, until KvizGoBack is called.
 *
 * @note			This adds to the internal traversal stack.
 * @param kv		Kvizzle Handle.
 * @param create	If set to true, the path will be created if it does not exist.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the jump was successful. Otherwise false (eg. when create is false and the path does not exist).
 * @error			Invalid Handle.
 */
stock bool:KvizJumpToKey(Handle:kv, bool:create, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 4);
	
	new action;
	if (!KvizGoto(kv, path2, create, action, true) || action != KVIZ_ACTION_NONE)
		return false;
	
	Kviz[Kviz_iCurrentContext][Kviz_iTraversalStack][Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen]] = Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount];
	Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen]++;
	return true;
}

/** 
 * Pops one element off the traversal stack. Should be used together with KvizJumpToKey.
 *
 * @param kv		Kvizzle Handle.
 * @return			True if an element was popped off the traversal stack. False if the traversal stack was empty.
 * @error			Invalid Handle.
 */
stock bool:KvizGoBack(Handle:kv) {
	if (!KvizSwitchContext(kv))
		return false;
	
	if (Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen] == 0)
		return false;
	
	Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen]--;
	return true;
}

/** 
 * Rewinds the traversal stack.
 *
 * @param kv		Kvizzle Handle.
 * @return			True if the traversal stack was successfully rewinded. Otherwise false (eg. wrong handle).
 * @error			Invalid Handle.
 */
stock bool:KvizRewind(Handle:kv) {
	if (!KvizSwitchContext(kv))
		return false;
	
	while (KvizGoBack(kv)) { }
	return true;
}

/** 
 * Checks if a Kvizzle path exists.
 *
 * @param kv		Kvizzle Handle.
 * @param path		The Kvizzle path to be formatted.
 * @param ...		Variable number of format parameters.
 * @return			True if the path exists. Otherwise false.
 * @error			Invalid Handle.
 */
stock bool:KvizExists(Handle:kv, const String:path[], any:...) {
	if (!KvizSwitchContext(kv))
		return false;
	
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 3);
	
	new action;
	if (KvizGoto(kv, path2, false, action)) {
		if (action != KVIZ_ACTION_NONE)
			LogError("Kvizzle - KvizExists doesn't support actions (%s)", path);
		
		return true;
	} 
	
	return false;
}

// An alias for KvizExists
stock bool:KvizExist(Handle:kv, const String:path[], any:...) {
	decl String:path2[256];
	VFormat(path2, sizeof(path2), path, 3);
	
	return KvizExists(kv, "%s", path2);
}







// ------------------
// Private functions
// ------------------

stock KvizInit() {
	if (Kviz_bInited)
		return;
	Kviz_bInited = true;
	
	Kviz_hPseudoClassTrie = CreateTrie();
	SetTrieValue(Kviz_hPseudoClassTrie, ":first-child", KVIZ_PSEUDO_FIRSTCHILD);
	SetTrieValue(Kviz_hPseudoClassTrie, ":last-child", KVIZ_PSEUDO_LASTCHILD);
	SetTrieValue(Kviz_hPseudoClassTrie, ":nth-child", KVIZ_PSEUDO_NTHCHILD);
	SetTrieValue(Kviz_hPseudoClassTrie, ":any-child", KVIZ_PSEUDO_ANYCHILD);
	SetTrieValue(Kviz_hPseudoClassTrie, ":up", KVIZ_PSEUDO_UP);
	SetTrieValue(Kviz_hPseudoClassTrie, ":parent", KVIZ_PSEUDO_UP);
	
	SetTrieValue(Kviz_hPseudoClassTrie, ":has-value", KVIZ_CHECK_HASVALUE);
	SetTrieValue(Kviz_hPseudoClassTrie, ":has-value-ci", KVIZ_CHECK_HASVALUE_CI);
	
	SetTrieValue(Kviz_hPseudoClassTrie, ":count", KVIZ_ACTION_COUNT);
	SetTrieValue(Kviz_hPseudoClassTrie, ":section-name", KVIZ_ACTION_SECTIONNAME);
	SetTrieValue(Kviz_hPseudoClassTrie, ":key", KVIZ_ACTION_SECTIONNAME);
	SetTrieValue(Kviz_hPseudoClassTrie, ":value", KVIZ_ACTION_VALUE);
	SetTrieValue(Kviz_hPseudoClassTrie, ":value-or-section", KVIZ_ACTION_VALUEORSECTION);
	
	Kviz_hArchiveKv = CreateArray();
	Kviz_hArchiveTraversalStack = CreateArray(Kviz_iMaxTraversalStack+1);
}


stock bool:KvizGoto(Handle:kv, const String:path[], bool:create, &action, bool:jumpToValues = true, depth = 0) {
	action = KVIZ_ACTION_NONE;
	if (path[0] == '\0') {
		// Go to root
		new rootDepth = -1;
		if (Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen] != 0)
			rootDepth = Kviz[Kviz_iCurrentContext][Kviz_iTraversalStack][Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen] - 1] - 1;
		KvizRollBack(kv, rootDepth);
		return true;
	} else if (Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen] != 0) {
		return KvizGoto2(kv, path, create, action, jumpToValues, Kviz[Kviz_iCurrentContext][Kviz_iTraversalStack][Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen] - 1]);
	} else {
		return KvizGoto2(kv, path, create, action, jumpToValues, 0);
	}
}

stock bool:KvizGoto2(Handle:kv, const String:path[], bool:create, &action, bool:jumpToValues, depth) {
	decl String:key[128];
	new endPos = 0, destPos = 0;
	while (path[endPos] != '.' && path[endPos] != '\0' && !(path[endPos] == ':' && endPos != 0)) {
		if (path[endPos] == '\\') {
			if (path[endPos+1] == '\0') {
				key[destPos++] = path[endPos++];
			} else {
				endPos++;
				key[destPos++] = path[endPos++];
			}
		} else {
			key[destPos++] = path[endPos++];
		}
	}
	
	if (endPos == 0)
		return false;
	
	key[destPos] = '\0';
	
	new bool:isPseudoClass = key[0] == ':';
	new bool:isAction = false, bool:isCheck = false;
	new pseudoClass;
	decl String:pseudoClassTag[128];
	decl String:pseudoClassParms[128];
	new bool:pseudoClassHasParm = false;
	new pseudoParmInt;
	
	if (isPseudoClass) {
		new pseudoClassParmsLen = 0;
		new pseudoClassTagLen = 0;
		for (new i = 0; i < sizeof(key) && key[i] != '\0'; i++) {
			if (key[i] == '(') {
				pseudoClassHasParm = true;
				key[i] = '\0';
			} else if (pseudoClassHasParm) {
				if (key[i] == ')') {
					break;
				} else {
					pseudoClassParms[pseudoClassParmsLen++] = key[i];
				}
			} else {
				pseudoClassTag[i] = key[i];
				pseudoClassTagLen++;
			}
		}
		pseudoClassTag[pseudoClassTagLen] = '\0';
		pseudoClassParms[pseudoClassParmsLen] = '\0';
		
		if (!GetTrieValue(Kviz_hPseudoClassTrie, pseudoClassTag, pseudoClass)) {
			LogError("Kvizzle - Unknown pseudo class: %s", key);
			return false;
		}
		
		if (pseudoClassParmsLen != 0)
			pseudoParmInt = StringToInt(pseudoClassParms);
		
		if (pseudoClass == KVIZ_PSEUDO_FIRSTCHILD) {
			pseudoClassTag = "nth-child";
			pseudoClass = KVIZ_PSEUDO_NTHCHILD;
			pseudoParmInt = 1;
			strcopy(key, sizeof(key), "nth-child(1)");
		}
		
		isAction = pseudoClass >= KVIZ_ACTION_MIN;
		isCheck = pseudoClass >= KVIZ_CHECK_MIN && pseudoClass <= KVIZ_CHECK_MAX;
	}
	
	new bool:alreadyInPosition = false;
	if (isAction) {
		alreadyInPosition = true;
		depth--; // We are not going any deeper in this step.
	} else if (isCheck) {
		alreadyInPosition = true;
		depth--; // We are not going any deeper in this step.
	} else {
		if (isPseudoClass && pseudoClass == KVIZ_PSEUDO_UP) {
			new rootDepth = -1;
			new traversalStackLen = Kviz[Kviz_iCurrentContext][Kviz_iTraversalStackLen];
			if (traversalStackLen != 0)
				rootDepth = Kviz[Kviz_iCurrentContext][Kviz_iTraversalStack][traversalStackLen - 1] - 1;
			alreadyInPosition = true;
			depth -= 2;
			if (depth < rootDepth) {
				LogError("Kvizzle - :up used on root node (%s)", path);
				depth = rootDepth;
			}
		} else if (depth < Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]) {
			if (isPseudoClass) {
				if (pseudoClass == KVIZ_PSEUDO_NTHCHILD && Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth] != 0) {
					new currentChildNum = Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth];
					new newChildNum = pseudoParmInt;
					if (currentChildNum == newChildNum) {
						alreadyInPosition = true;
					} else if (currentChildNum < newChildNum) {
						KvizRollBack(kv, depth);
						while (currentChildNum < newChildNum) {
							if (!KvGotoNextKey(kv, !jumpToValues)) {
								//PrintToServer("Fast nth-child: Not found - setting to :nth-child(%i)", currentChildNum);
								KvGetSectionName(kv, Kviz_sPositionPath[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPath[][]));
								Format(Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPathPseudoClass[][]), ":nth-child(%i)", currentChildNum);
								Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth] = currentChildNum;
								return false;
							}
							currentChildNum++;
							//PrintToServer("Fast nth-child: GotoNextKey(%i)", currentChildNum);
						}
						KvGetSectionName(kv, Kviz_sPositionPath[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPath[][]));
						strcopy(Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPathPseudoClass[][]), key);
						Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth] = currentChildNum;
						alreadyInPosition = true;
					} else {
						KvizRollBack(kv, depth-1);
					}
				} else if (pseudoClass != KVIZ_PSEUDO_ANYCHILD && StrEqual(Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth], key)) {
					alreadyInPosition = true;
				} else {
					KvizRollBack(kv, depth-1);
				}
			} else {
				if (StrEqual(Kviz_sPositionPath[Kviz_iCurrentContext][depth], key)) {
					alreadyInPosition = true;
				} else {
					KvizRollBack(kv, depth-1);
				}
			}
		}
	}
	
	if (!alreadyInPosition) {
		if (isPseudoClass) {
			switch (pseudoClass) {
				case KVIZ_PSEUDO_LASTCHILD: {
					//PrintToServer("Go to last child");
					if (!KvGotoFirstSubKey(kv, !jumpToValues))
						return false;
					while (KvGotoNextKey(kv, !jumpToValues)) { }
					
					KvGetSectionName(kv, Kviz_sPositionPath[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPath[][]));
					strcopy(Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPathPseudoClass[][]), key);
					Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth] = 0;
					Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]++;
				}
				case KVIZ_PSEUDO_NTHCHILD: {
					//PrintToServer("Go to %ith child", pseudoParmInt);
					if (!KvGotoFirstSubKey(kv, !jumpToValues))
						return false;
					
					new currentChildNum = 0;
					new bool:childFound = false;
					do {
						currentChildNum++;
						if (currentChildNum == pseudoParmInt) {
							childFound = true;
							break;
						}
					} while (KvGotoNextKey(kv, !jumpToValues));
					
					if (!childFound) {
						KvGetSectionName(kv, Kviz_sPositionPath[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPath[][]));
						Format(Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPathPseudoClass[][]), ":nth-child(%i)", currentChildNum);
						Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth] = currentChildNum;
						Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]++;
						return false;
					}
					
					KvGetSectionName(kv, Kviz_sPositionPath[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPath[][]));
					strcopy(Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPathPseudoClass[][]), key);
					Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth] = pseudoParmInt;
					Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]++;
				}
				case KVIZ_PSEUDO_ANYCHILD: {
					if (!KvGotoFirstSubKey(kv, !jumpToValues))
						return false;
					
					Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]++;
					
					new currentChildNum = 0;
					do {
						currentChildNum++;
						
						// We must set the position path values before calling KvGoto recursively. This is because :up should be able to overwrite the values.
						KvGetSectionName(kv, Kviz_sPositionPath[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPath[][]));
						Format(Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPathPseudoClass[][]), ":nth-child(%i)", currentChildNum);
						Kviz_sPositionPathNthChild[Kviz_iCurrentContext][depth] = currentChildNum;
						
						if (path[endPos] == '\0') {
							KvizRollBack(kv, depth);
							return true;
						}
						
						if (KvizGoto2(kv, path[path[endPos] == ':' ? endPos : endPos+1], create, action, jumpToValues, depth + 1))
							return true;
						
						KvizRollBack(kv, depth);
					} while (KvGotoNextKey(kv, !jumpToValues));
					
					return false;
				}
				default:
					KvizThrowError(kv, "Unknown pseudoClass (%s / %i) - Please contact F2", key, pseudoClass);
			}
		} else {
			//PrintToServer("JumpToKey: %s", key);
			if (!KvJumpToKey(kv, key, create))
				return false;
			
			strcopy(Kviz_sPositionPath[Kviz_iCurrentContext][depth], sizeof(Kviz_sPositionPath[][]), key);
			Kviz_sPositionPathPseudoClass[Kviz_iCurrentContext][depth][0] = '\0';
			Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]++;
		}
	} else if (isAction) {
		action = pseudoClass;
	} else if (isCheck) {
		switch (pseudoClass) {
			case KVIZ_CHECK_HASVALUE, KVIZ_CHECK_HASVALUE_CI: {
				if (KvGetDataType(kv, NULL_STRING) == KvData_None)
					return false;
				
				if (pseudoClassHasParm) {
					// :has-value .. check that the node has the specified string value
					decl String:strvalue[256];
					KvGetString(kv, NULL_STRING, strvalue, sizeof(strvalue));
					if (!StrEqual(strvalue, pseudoClassParms, pseudoClass == KVIZ_CHECK_HASVALUE))
						return false;
				} else {
					// :has-value .. check that the node has a value (ie. it is not a section)
					// --- we already did that above.
				}
			}
			default:
				KvizThrowError(kv, "Unknown pseudoClass (%s / %i) - Please contact F2", key, pseudoClass);
		}
	}
	
	if (path[endPos] == '\0') {
		KvizRollBack(kv, depth); // If we were in "A.B.C" before, and we are now navigating to "A.B", then make sure to remove "C" from the stack.
		
		if (action == KVIZ_ACTION_VALUEORSECTION) {
			new KvDataTypes:dataType = KvGetDataType(kv, NULL_STRING);
			if (dataType == KvData_None)
				action = KVIZ_ACTION_SECTIONNAME;
			else
				action = KVIZ_ACTION_VALUE;
		}
		return true;
	}
	
	if (action != KVIZ_ACTION_NONE)
		return false; // You cannot use an action in the middle of a path
	
	if (!KvizGoto2(kv, path[path[endPos] == ':' ? endPos : endPos+1], create, action, jumpToValues, depth + 1))
		return false;
	
	return true;
}

stock KvizRollBack(Handle:kv, destPos) {
	while (Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount] > destPos+1) {
		//PrintToServer("GoBack");
		KvGoBack(kv);
		Kviz[Kviz_iCurrentContext][Kviz_iPositionPathCount]--;
	}
}

stock bool:KvizStringToVector(const String:strvalue[], Float:vec[3]) {
	new pos = 0;
	new consumed = StringToFloatEx(strvalue, vec[0]);
	if (consumed == 0 || strvalue[consumed] == '\0') {
		//PrintToServer("StringToVector - fail 1");
		return false;
	}
	pos = consumed+1;
	consumed = StringToFloatEx(strvalue[pos], vec[1]);
	if (consumed == 0 || strvalue[pos+consumed] == '\0') {
		//PrintToServer("StringToVector - fail 2");
		return false;
	}
	pos += consumed+1;
	consumed = StringToFloatEx(strvalue[pos], vec[2]);
	if (consumed > 0 && strvalue[pos+consumed] == '\0')
		return true;
	//PrintToServer("StringToVector - fail 3");
	return false;
}

stock KvizResetContext(context) {
	Kviz[context][Kviz_hKv] = INVALID_HANDLE;
	Kviz[context][Kviz_iPositionPathCount] = 0;
	Kviz[context][Kviz_iTraversalStackLen] = 0;
}

stock bool:KvizSwitchContext(Handle:kv, bool:mayCreate = false) {
	if (kv == INVALID_HANDLE) {
		KvizThrowError(kv, "kv was INVALID_HANDLE.");
	}
	
	for (new i = 0; i < Kviz_iMaxContexts; i++) {
		if (Kviz[Kviz_iCurrentContext][Kviz_hKv] == kv) {
			Kviz[Kviz_iCurrentContext][Kviz_iLRU] = ++Kviz_iLRUCounter;
			return true;
		}
		
		Kviz_iCurrentContext++;
		if (Kviz_iCurrentContext == Kviz_iMaxContexts)
			Kviz_iCurrentContext = 0;
	}
	
	if (KvizSwitchFromArchive(kv)) {
		Kviz[Kviz_iCurrentContext][Kviz_iLRU] = ++Kviz_iLRUCounter;
		return true;
	}
	
	if (!mayCreate) {
		LogError("Kvizzle - kv not found. Remember to call KvizCreate first!");
		return false;
	}
	
	Kviz_iCurrentContext = KvizGetFreeContext();
	Kviz[Kviz_iCurrentContext][Kviz_hKv] = kv;
	Kviz[Kviz_iCurrentContext][Kviz_iLRU] = ++Kviz_iLRUCounter;
	return true;
}

stock bool:KvizSwitchFromArchive(Handle:kv) {
	new archiveLen = GetArraySize(Kviz_hArchiveKv);
	for (new i = 0; i < archiveLen; i++) {
		new Handle:archiveKv = Handle:GetArrayCell(Kviz_hArchiveKv, i);
		if (archiveKv == kv) {
			new context = KvizGetFreeContext();
			
			decl String:path[256][128];
			
			new pathPos = 0;
			for (new kvDepth = KvNodesInStack(kv); kvDepth > 0; kvDepth = KvGoBack(kv) ? kvDepth - 1 : 0) {
				KvGetSectionName(kv, path[pathPos], sizeof(path[]));
				pathPos++;
			}
			
			decl String:kvizPos[256*128] = "";
			if (pathPos > 0) {
				// TODO: Can be optimized a lot, because StrCat is getting strlen all the time
				pathPos--;
				strcopy(kvizPos, sizeof(kvizPos), path[pathPos]);
				for (pathPos--; pathPos >= 0; pathPos--) {
					StrCat(kvizPos, sizeof(kvizPos), ".");
					KvizEscape(path[pathPos], sizeof(path[]), path[pathPos]);
					StrCat(kvizPos, sizeof(kvizPos), path[pathPos]);
				}
			}
			
			Kviz_iCurrentContext = context;
			Kviz[context][Kviz_hKv] = kv;
			Kviz[context][Kviz_iPositionPathCount] = 0;
			Kviz[context][Kviz_iTraversalStackLen] = 0;
			if (!StrEqual("", kvizPos)) {
				new action;
				if (!KvizGoto(kv, kvizPos, false, action))
					KvizThrowError(kv, "KvizSwitchFromArchive - KvizGoto failed - Please contact F2: %s", kvizPos);
			}
			
			new archiveTSLen = GetArrayCell(Kviz_hArchiveTraversalStack, i, 0);
			Kviz[context][Kviz_iTraversalStackLen] = archiveTSLen;
			for (new j = 0; j < archiveTSLen; j++) {
				Kviz[context][Kviz_iTraversalStack][j] = GetArrayCell(Kviz_hArchiveTraversalStack, i, j+1);
			}
			
			RemoveFromArray(Kviz_hArchiveKv, i);
			RemoveFromArray(Kviz_hArchiveTraversalStack, i);
			
			return true;
		}
	}
	
	return false;
}

stock KvizGetFreeContext() {
	new best = -1;
	for (new context = 0; context < Kviz_iMaxContexts; context++) {
		if (Kviz[context][Kviz_hKv] == INVALID_HANDLE)
			return context;
		
		if (best == -1 || Kviz[context][Kviz_iLRU] < Kviz[best][Kviz_iLRU])
			best = context;
	}
	
	KvizArchiveContext(best);
	KvizResetContext(best);
	return best;
}

stock KvizArchiveContext(context) {
	PushArrayCell(Kviz_hArchiveKv, Kviz[context][Kviz_hKv]);
	decl stack[Kviz_iMaxTraversalStack+1];
	stack[0] = Kviz[context][Kviz_iTraversalStackLen];
	for (new i = 0; i < stack[0]; i++)
		stack[i+1] = Kviz[context][Kviz_iTraversalStack][i];
	PushArrayArray(Kviz_hArchiveTraversalStack, stack);
	Kviz[context][Kviz_hKv] = INVALID_HANDLE;
}

stock bool:KvizRemoveContext(Handle:kv) {
	for (new i = 0; i < Kviz_iMaxContexts; i++) {
		if (Kviz[Kviz_iCurrentContext][Kviz_hKv] == kv) {
			Kviz[Kviz_iCurrentContext][Kviz_hKv] = INVALID_HANDLE;
			return true;
		}
		
		if (Kviz_iCurrentContext == 0)
			Kviz_iCurrentContext = Kviz_iMaxContexts - 1;
		else
			Kviz_iCurrentContext--;
	}
	
	return false;
}

stock KvizThrowError(Handle:kv, const String:text[], any:...) {
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), text, 2);
	ThrowError("Kvizzle - %s", buffer);
}

