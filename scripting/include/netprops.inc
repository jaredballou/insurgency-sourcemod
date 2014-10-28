#if defined _netprops_included_
	#endinput
#endif
#define _netprops_included_

enum SendPropType {
	DPT_Int=0,
	DPT_Float,
	DPT_Vector,
	DPT_VectorXY,
	DPT_String,
	DPT_Array,	// An array of the base types (can't be of datatables).
	DPT_DataTable,
	DPT_NUMSendPropTypes
};

/**
 * Returns a handle to the SendTable for a specific netclass.
 *
 * @param netclass      netclass name.
 * @return              Handle to a SendTable or INVALID_HANDLE on error.
 */
native Handle:GetSendTableByNetclass(const String:netclass[]);

/**
 * Returns the amount of netprops a SendTable holds.
 * This does not count recursively!
 *
 * @param hSendTable    Handle to a SendTable object.
 * @return              Returns the number of netprops in the table.
 */
native GetNumProps(Handle:hSendTable);

/**
 * Returns a handle to a NetProp object at the given index of a SendTable.
 *
 * @param hSendTable    Handle to a SendTable object.
 * @param iIndex    	Position of the Netprop in the table.
 * @return              Handle to a NetProp object or INVALID_HANDLE on error.
 */
native Handle:GetProp(Handle:hSendTable, iIndex);

/**
 * Retrieves the table name from a SendTable
 *
 * @param hSendTable    Handle to a SendTable object.
 * @param sName    		Buffer to store the name in.
 * @param size			Maximum length of the sName buffer.
 * @return              String length of the returned name.
 */
native GetTableName(Handle:hSendTable, String:sName[], size);

/**
 * Retrieves the name of a NetProp Object
 *
 * @param hProp		    Handle to a NetProp object.
 * @param sName    		Buffer to store the name in.
 * @param size			Maximum length of the sName buffer.
 * @return              String length of the returned name.
 */
native GetPropName(Handle:hProp, String:sName[], size);

/**
 * Returns a handle to the SendTable of a NetProp with type DPT_DataTable.
 *
 * @param hProp		    Handle to a NetProp object.
 * @return              Handle to a SendTable or INVALID_HANDLE on error.
 */
native Handle:GetDataTable(Handle:hProp);

/**
 * Retrieves the SendPropType of a NetProp object.
 *
 * @param hProp		    Handle to a NetProp object.
 * @return              SendPropType value of the NetProp object.
 */
native SendPropType:GetType(Handle:hProp);

/**
 * Retrieves the SendPropType of a NetProp object as a human readable string.
 *
 * @param hProp		    Handle to a NetProp object.
 * @param sType    		Buffer to store the type in.
 * @param size			Maximum length of the sType buffer.
 * @return              String length of the returned type.
 */
native GetTypeString(Handle:hProp, String:sType[], size);

/**
 * Retrieves the number of bits a NetProp object has.
 *
 * @param hProp		    Handle to a NetProp object.
 * @return              The number of bits of the netprops
 */
native GetBits(Handle:hProp);

/**
 * Retrieves the actual offset of a NetProp object.
 * This function will correctly compute nested offsets.
 * There is no need to calculate offsets yourself. It uses the same
 * method as FindSendPropInfo().
 *
 * @param hProp		    Handle to a NetProp object.
 * @return              The offset of the netprop
 */
native GetOffset(Handle:hProp);



/**
 * Do not edit below this line!
 */
public Extension:__ext_netprops =
{
	name = "Netprops",
	file = "netprops.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};