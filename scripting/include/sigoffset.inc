#if defined _sigoffset_included
    #endinput
#endif
#define _sigoffset_included
#include <core>

/**
 * Scans for a function in the memory and returns an index used to call it
 *
 * @param functionname	The name of the function (E.G. CBaseAnimating::Ignite)
 * @param address		Signature address to scan for
 * @param mask			Signature mask
 * @param len			Length of the signature in bytes
 * @param linuxaddress	The linux symbol name used for the function
 * @return				Index for calling, -1 means a failure in the scan
 */
native SignatureScanFind(const String:functionname[], const String:address[], const String:mask[], len, const String:linuxaddress[]);

#define SIGTYPE_CBASEENTITY 0
#define SIGTYPE_CBASEPLAYER 1
#define SIGTYPE_CBASEANIMATING 2
#define SIGTYPE_CCSPLAYER 3

enum SigEnum
{
	PARAM_INT=0,
	PARAM_FLOAT,
	PARAM_CONST_CHAR_PTR,
	PARAM_VECTOR,
	PARAM_QANGLE,
	PARAM_CBASEENTITY,
	PARAM_CBASEPLAYER,
	PARAM_CBASEANIMATING,
	PARAM_CCSPLAYER,
	PARAM_RECIPIENTFILTER
};

/**
 * Call a previously scanned function using the returned index from SignatureScanFind
 *
 * @param functionindex		What SignatureScanFind spat out at you
 * @param playerindex		The playerindex associated with the function
 * @param functiontype		The classtype for function, see SigFuncType
 * @param[x] argtype		Datatype of argument, see SigEnum
 * @param[y] arg			Argument for function
 * The last to arguments (argtype and arg) repeat for how many arguments the function actually requires
 * If you want to use cbase stuff, provide the type and an ent index
 * @return					If there was a failure in the function, it will return -1, otherwise, 1
 */
native any:SignatureScanCall(functionindex, playerindex, functiontype, any:...);

/**
 * Call a previously scanned function using the returned index from SignatureScanFind, but without an index for a specific entity
 *
 * @param functionindex		What SignatureScanFind spat out at you
 * @param[x] argtype		Datatype of argument, see SigEnum
 * @param[y] arg			Argument for function
 * The last to arguments (argtype and arg) repeat for how many arguments the function actually requires
 * If you want to use cbase stuff, provide the type and an ent index
 * @return					If there was a failure in the function, it will return -1, otherwise, 1
 */
native any:SignatureScanCall_NoIndex(functionindex,any:...);
native SignatureScan_HandleToIndex(Handle:hand);
/**
 * @endsection
 */

/**
 * Do not edit below this line!
 */
public Extension:__ext_sigoffset = 
{
	name = "Signature and Offset Extension",
	file = "sigoffset.ext",
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
