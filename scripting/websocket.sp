#pragma semicolon 1
#pragma dynamic 65536
#include <sourcemod>
#include <regex>
#include <socket>
#include <websocket>
#include <base64>
#include <sha1>

#define PLUGIN_VERSION "1.1"

#define DEBUG 0
#if DEBUG > 0
new String:g_sLog[PLATFORM_MAX_PATH];
#endif

/**
 * This implementation follows the draft version 17 of the websocket protocol specifications
 * http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-17
 */

// Used in the g_hMasterSocketPlugins child arrays
#define PLUGIN_HANDLE 0
#define PLUGIN_ERRORCALLBACK 1
#define PLUGIN_INCOMINGCALLBACK 2
#define PLUGIN_CLOSECALLBACK 3

#define CHILD_PLUGINHANDLE 0
#define CHILD_RECVCALL 1
#define CHILD_DISCCALL 2
#define CHILD_ERRCALL 3
#define CHILD_READYSTATECALL 4
#define CHILD_ARRAY_LENGTH 5

// Handshake header parsing
new Handle:g_hRegExKey;
new Handle:g_hRegExProtocol;

// Array of all master sockets we're listening on
new Handle:g_hMasterSockets;
new Handle:g_hMasterSocketHostPort;
new Handle:g_hMasterSocketIndexes;
// Array of arrays containing plugin handles which use this socket
new Handle:g_hMasterSocketPlugins;
new Handle:g_hMasterErrorForwards;
new Handle:g_hMasterCloseForwards;
new Handle:g_hMasterIncomingForwards;
// Array connecting g_hChildSockets with g_hMasterSockets
new Handle:g_hChildsMasterSockets;
// Array of child sockets spawned by a master socket. Child indexes are mapped to master sockets via g_hMasterChildSockets {child => master,...}
new Handle:g_hChildSockets;
// Array of arrays containing plugin handles which use this child socket
new Handle:g_hChildSocketPlugins;
new Handle:g_hChildSocketIndexes;
new Handle:g_hChildSocketHost;
new Handle:g_hChildSocketPort;
new Handle:g_hChildSocketReadyState;
new Handle:g_hChildErrorForwards;
new Handle:g_hChildReceiveForwards;
new Handle:g_hChildDisconnectForwards;
new Handle:g_hChildReadyStateChangeForwards;
//new Handle:g_hChildRandomParameter;

// This is passed as "handle" to plugins
new g_iLastSocketIndex = 0;


enum WebsocketFrameType {
	FrameType_Text = 1,
	FrameType_Binary = 2,
	FrameType_Close = 8,
	FrameType_Ping = 9,
	FrameType_Pong = 10
}

enum WebsocketFrame
{
	FIN,
	RSV1,
	RSV2,
	RSV3,
	WebsocketFrameType:OPCODE,
	MASK,
	PAYLOAD_LEN,
	String:MASKINGKEY[5],
	CLOSE_REASON
}

public Plugin:myinfo = 
{
	name = "Websocket",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Websocket protocol implementation",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("websocket");
	CreateNative("Websocket_Open", Native_Websocket_Open);
	CreateNative("Websocket_HookChild", Native_Websocket_HookChild);
	CreateNative("Websocket_HookReadyStateChange", Native_Websocket_HookReadyStateChange);
	CreateNative("Websocket_GetReadyState", Native_Websocket_GetReadyState);
	CreateNative("Websocket_Send", Native_Websocket_Send);
	CreateNative("Websocket_UnhookChild", Native_Websocket_UnhookChild);
	CreateNative("Websocket_Close", Native_Websocket_Close);
	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_websocket_version", PLUGIN_VERSION, "",FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	// Setup handshake http header parsing regexes
	new RegexError:iRegExError, String:sError[64];
	g_hRegExKey = CompileRegex("Sec-WebSocket-Key: (.*)\r\n", 0, sError, sizeof(sError), iRegExError);
	if(g_hRegExKey == INVALID_HANDLE)
	{
		SetFailState("Can't compile Sec-WebSocket-Key regex: %s (%d)", sError, _:iRegExError);
	}
	g_hRegExProtocol = CompileRegex("Sec-WebSocket-Protocol: (.*)\r\n", 0, sError, sizeof(sError), iRegExError);
	if(g_hRegExProtocol == INVALID_HANDLE)
	{
		SetFailState("Can't compile Sec-WebSocket-Protocol regex: %s (%d)", sError, _:iRegExError);
	}
	
	g_hMasterSockets = CreateArray();
	g_hMasterSocketHostPort = CreateArray(ByteCountToCells(128));
	g_hMasterSocketIndexes = CreateArray();
	g_hMasterSocketPlugins = CreateArray();
	g_hChildsMasterSockets = CreateArray();
	g_hChildSockets = CreateArray();
	g_hChildSocketIndexes = CreateArray();
	g_hChildSocketPlugins = CreateArray();
	g_hChildSocketHost = CreateArray(ByteCountToCells(64));
	g_hChildSocketPort = CreateArray();
	g_hChildSocketReadyState = CreateArray();
	
	g_hMasterErrorForwards = CreateArray();
	g_hMasterCloseForwards = CreateArray();
	g_hMasterIncomingForwards = CreateArray();
	g_hChildErrorForwards = CreateArray();
	g_hChildReceiveForwards = CreateArray();
	g_hChildDisconnectForwards = CreateArray();
	g_hChildReadyStateChangeForwards = CreateArray();
	
#if DEBUG > 0
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/websocket_debug.log");
#endif
}

public OnPluginEnd()
{
	while(GetArraySize(g_hMasterSockets))
		CloseMasterSocket(0);
}

public Native_Websocket_Open(Handle:plugin, numParams)
{
	new iSize = GetArraySize(g_hMasterSocketPlugins);
	new Handle:hMasterSocketPlugins, aPluginInfo[4];
	
	// Currently only one websocket per plugin is supported.
	new iPluginCount;
	for(new i=0;i<iSize;i++)
	{
		hMasterSocketPlugins = GetArrayCell(g_hMasterSocketPlugins, i);
		iPluginCount = GetArraySize(hMasterSocketPlugins);
		for(new p=0;p<iPluginCount;p++)
		{
			GetArrayArray(hMasterSocketPlugins, p, aPluginInfo, 4);
			if(Handle:aPluginInfo[PLUGIN_HANDLE] == plugin)
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Only one websocket per plugin allowed. You already got one open.");
				return _:INVALID_WEBSOCKET_HANDLE;
			}
		}
	}
	
	new iHostNameLength;
	GetNativeStringLength(1, iHostNameLength);
	if(iHostNameLength <= 0)
	{
		return _:INVALID_WEBSOCKET_HANDLE;
	}
	
	new String:sHostName[iHostNameLength+1];
	GetNativeString(1, sHostName, iHostNameLength+1);
	
	new iPort = GetNativeCell(2);
	
	new iIndex = -1;
	
	// Is there already a socket open on that hostname:port?
	decl String:sHostPort[128], String:sHostPortStored[128];
	Format(sHostPort, sizeof(sHostPort), "%s:%d", sHostName, iPort);
	iSize = GetArraySize(g_hMasterSocketHostPort);
	for(new i=0;i<iSize;i++)
	{
		GetArrayString(g_hMasterSocketHostPort, i, sHostPortStored, sizeof(sHostPortStored));
		// Yes there is. Just add this plugin to the listeners
		if(StrEqual(sHostPort, sHostPortStored, false))
		{
			iIndex = i;
			break;
		}
	}
	
	// Only create the socket, if it's not there already!
	new Handle:hErrorForward, Handle:hCloseForward, Handle:hIncomingForward, iPseudoHandle;
	if(iIndex == -1)
	{
		new Handle:hMasterSocket = SocketCreate(SOCKET_TCP, OnSocketError);
		
		if(SocketSetOption(hMasterSocket, SocketReuseAddr, 1) != 1)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Can't set SO_REUSEADDR option.");
			return _:INVALID_WEBSOCKET_HANDLE;
		}
		
		if(!SocketBind(hMasterSocket, sHostName, iPort))
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Unable to bind socket to %s:%d", sHostName, iPort);
			return _:INVALID_WEBSOCKET_HANDLE;
		}
		
		if(!SocketListen(hMasterSocket, OnSocketIncoming))
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Unable to listen on socket to %s:%d", sHostName, iPort);
			return _:INVALID_WEBSOCKET_HANDLE;
		}
		
		// Save the socket!
		iIndex = PushArrayCell(g_hMasterSockets, hMasterSocket);
		Debug(1, "Created socket on %s:%d #%d", sHostName, iPort, iIndex);
		// this should always be in sync with g_hMasterSockets
		iPseudoHandle = ++g_iLastSocketIndex;
		PushArrayCell(g_hMasterSocketIndexes, iPseudoHandle);
		// Create private forwards for this socket
		hIncomingForward = CreateForward(ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String);
		PushArrayCell(g_hMasterIncomingForwards, hIncomingForward);
		hErrorForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		PushArrayCell(g_hMasterErrorForwards, hErrorForward);
		hCloseForward = CreateForward(ET_Ignore, Param_Cell);
		PushArrayCell(g_hMasterCloseForwards, hCloseForward);
		
		SocketSetArg(hMasterSocket, iPseudoHandle);
		
		// Save the hostname:port combi to check, if there's already a socket open.
		// We just pass the handle to the plugin calling instead of creating a new socket.
		PushArrayString(g_hMasterSocketHostPort, sHostPort);
	}
	// There's already a connection open. Get the details
	else
	{
		iPseudoHandle = GetArrayCell(g_hMasterSocketIndexes, iIndex);
		hIncomingForward = Handle:GetArrayCell(g_hMasterIncomingForwards, iIndex);
		hErrorForward = Handle:GetArrayCell(g_hMasterErrorForwards, iIndex);
		hCloseForward = Handle:GetArrayCell(g_hMasterCloseForwards, iIndex);
		Debug(1, "Using old socket on %s:%d #%d", sHostName, iPort, iIndex);
	}
	
	// Add him to our private incoming connections forward for this socket
	new Function:fIncomingCallback = Function:GetNativeCell(3);
	if(!AddToForward(hIncomingForward, plugin, fIncomingCallback))
		LogError("Unable to add plugin to incoming callback");
	
	// Add him to our private error forward for this socket
	new Function:fErrorCallback = Function:GetNativeCell(4);
	if(!AddToForward(hErrorForward, plugin, fErrorCallback))
		LogError("Unable to add plugin to error callback");
	
	// Add him to our private close forward for this socket
	new Function:fCloseCallback = Function:GetNativeCell(5);
	if(!AddToForward(hCloseForward, plugin, fCloseCallback))
		LogError("Unable to add plugin to close callback");
	
	// Remember, that this plugin is using this socket. Required to determine, if we can close the socket, if no plugins are using it anymore.
	if(iIndex >= iSize)
	{
		hMasterSocketPlugins = CreateArray(4);
		PushArrayCell(g_hMasterSocketPlugins, hMasterSocketPlugins);
	}
	else
		hMasterSocketPlugins = GetArrayCell(g_hMasterSocketPlugins, iIndex);
	
	aPluginInfo[PLUGIN_HANDLE] = _:plugin;
	aPluginInfo[PLUGIN_ERRORCALLBACK] = _:fErrorCallback;
	aPluginInfo[PLUGIN_INCOMINGCALLBACK] = _:fIncomingCallback;
	aPluginInfo[PLUGIN_CLOSECALLBACK] = _:fCloseCallback;
	PushArrayArray(hMasterSocketPlugins, aPluginInfo, 4);
	
	return _:iPseudoHandle;
}

public Native_Websocket_Send(Handle:plugin, numParams)
{
	new WebsocketHandle:iPseudoChildHandle = WebsocketHandle:GetNativeCell(1);
	new iChildIndex;
	if(iPseudoChildHandle == INVALID_WEBSOCKET_HANDLE
	|| (iChildIndex = FindValueInArray(g_hChildSocketIndexes, _:iPseudoChildHandle)) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid child websocket handle.");
		return false;
	}
	
	new vFrame[WebsocketFrame];
	vFrame[OPCODE] = WebsocketSendType:GetNativeCell(2)==SendType_Text?FrameType_Text:FrameType_Binary;
	
	vFrame[PAYLOAD_LEN] = GetNativeCell(4);
	if(vFrame[PAYLOAD_LEN] == -1)
		GetNativeStringLength(3, vFrame[PAYLOAD_LEN]);
	
	new String:sPayLoad[vFrame[PAYLOAD_LEN]+1];
	
	GetNativeString(3, sPayLoad, vFrame[PAYLOAD_LEN]+1);
	
	vFrame[FIN] = 1;
	vFrame[CLOSE_REASON] = -1;
	SendWebsocketFrame(iChildIndex, sPayLoad, vFrame);
	return true;
}

public Native_Websocket_HookChild(Handle:plugin, numParams)
{
	new WebsocketHandle:iPseudoChildHandle = WebsocketHandle:GetNativeCell(1);
	new iChildIndex;
	if(iPseudoChildHandle == INVALID_WEBSOCKET_HANDLE
	|| (iChildIndex = FindValueInArray(g_hChildSocketIndexes, _:iPseudoChildHandle)) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid child websocket handle.");
		return false;
	}
	
	new Handle:hReceiveForward = Handle:GetArrayCell(g_hChildReceiveForwards, iChildIndex);
	new Handle:hErrorForward = Handle:GetArrayCell(g_hChildErrorForwards, iChildIndex);
	new Handle:hDisconnectForward = Handle:GetArrayCell(g_hChildDisconnectForwards, iChildIndex);
	
	// Did this plugin already hook the child socket? Replace callbacks!
	new Handle:hChildSocketPlugin = Handle:GetArrayCell(g_hChildSocketPlugins, iChildIndex);
	new iPluginCount = GetArraySize(hChildSocketPlugin);
	new Function:aPluginInfo[CHILD_ARRAY_LENGTH];
	new iPluginInfoIndex = -1;
	for(new p=0;p<iPluginCount;p++)
	{
		GetArrayArray(hChildSocketPlugin, p, aPluginInfo, CHILD_ARRAY_LENGTH);
		if(plugin == Handle:aPluginInfo[CHILD_PLUGINHANDLE])
		{
			iPluginInfoIndex = p;
			// Only remove, if there are already callbacks set. This could happen, if ReadyStateChange was called before HookChild.
			if(Function:aPluginInfo[CHILD_RECVCALL] != INVALID_FUNCTION)
			{
				RemoveFromForward(hReceiveForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_RECVCALL]);
				RemoveFromForward(hDisconnectForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_DISCCALL]);
				RemoveFromForward(hErrorForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_ERRCALL]);
				break;
			}
		}
	}
	
	aPluginInfo[CHILD_RECVCALL] = GetNativeCell(2);
	aPluginInfo[CHILD_DISCCALL] = GetNativeCell(3);
	aPluginInfo[CHILD_ERRCALL] = GetNativeCell(4);
	
	// This is the first call to a hooking function on this socket for this plugin.
	if(iPluginInfoIndex == -1)
	{
		// Store this plugin's callbacks to be able to remove them from the forward by the time the child socket disconnects
		aPluginInfo[CHILD_PLUGINHANDLE] = _:plugin;
		aPluginInfo[CHILD_READYSTATECALL] = _:INVALID_FUNCTION;
		
		PushArrayArray(hChildSocketPlugin, aPluginInfo, CHILD_ARRAY_LENGTH);
	// This plugin is already known.
	} else {
		SetArrayArray(hChildSocketPlugin, iPluginInfoIndex, aPluginInfo, CHILD_ARRAY_LENGTH);
	}
	
	// Add his callbacks to the private forwards
	if(!AddToForward(hReceiveForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_RECVCALL]))
		LogError("Unable to add plugin to recv callback");
	if(!AddToForward(hDisconnectForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_DISCCALL]))
		LogError("Unable to add plugin to disc callback");
	if(!AddToForward(hErrorForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_ERRCALL]))
		LogError("Unable to add plugin to err callback");
	
	return true;
}

// Return the ready state of a child socket
public Native_Websocket_HookReadyStateChange(Handle:plugin, numParams)
{
	new WebsocketHandle:iPseudoChildHandle = WebsocketHandle:GetNativeCell(1);
	new iChildIndex;
	if(iPseudoChildHandle == INVALID_WEBSOCKET_HANDLE
	|| (iChildIndex = FindValueInArray(g_hChildSocketIndexes, _:iPseudoChildHandle)) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid child websocket handle.");
		return false;
	}
	
	new Handle:hReadyStateChangeForward = Handle:GetArrayCell(g_hChildReadyStateChangeForwards, iChildIndex);
	
	// Check, if this plugin already hooked this socket.
	new Handle:hChildSocketPlugin = Handle:GetArrayCell(g_hChildSocketPlugins, iChildIndex);
	new iPluginCount = GetArraySize(hChildSocketPlugin);
	new any:aPluginInfo[CHILD_ARRAY_LENGTH];
	new iPluginInfoIndex = -1;
	for(new p=0;p<iPluginCount;p++)
	{
		GetArrayArray(hChildSocketPlugin, p, aPluginInfo, CHILD_ARRAY_LENGTH);
		if(plugin == Handle:aPluginInfo[CHILD_PLUGINHANDLE])
		{
			iPluginInfoIndex = p;
			// Replace the callback, if we already stored one.
			if(Function:aPluginInfo[CHILD_READYSTATECALL] != INVALID_FUNCTION)
			{
				RemoveFromForward(hReadyStateChangeForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_READYSTATECALL]);
				break;
			}
		}
	}
	
	// Save the function to call.
	aPluginInfo[CHILD_READYSTATECALL] = Function:GetNativeCell(2);
	
	// This is the first call for a plugin to call a hooking function.
	if(iPluginInfoIndex == -1)
	{
		aPluginInfo[CHILD_PLUGINHANDLE] = _:plugin;
		aPluginInfo[CHILD_RECVCALL] = _:INVALID_FUNCTION;
		aPluginInfo[CHILD_ERRCALL] = _:INVALID_FUNCTION;
		aPluginInfo[CHILD_DISCCALL] = _:INVALID_FUNCTION;
		
		PushArrayArray(hChildSocketPlugin, aPluginInfo, CHILD_ARRAY_LENGTH);
	}
	else
	{
		SetArrayArray(hChildSocketPlugin, iPluginInfoIndex, aPluginInfo, CHILD_ARRAY_LENGTH);
	}
	
	if(!AddToForward(hReadyStateChangeForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_READYSTATECALL]))
		LogError("Unable to add plugin to readystate change callback");
	
	return true;
}

// Return the ready state of a child socket
public Native_Websocket_GetReadyState(Handle:plugin, numParams)
{
	new WebsocketHandle:iPseudoChildHandle = WebsocketHandle:GetNativeCell(1);
	new iChildIndex;
	if(iPseudoChildHandle == INVALID_WEBSOCKET_HANDLE
	|| (iChildIndex = FindValueInArray(g_hChildSocketIndexes, _:iPseudoChildHandle)) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid child websocket handle.");
		return false;
	}
	
	return GetArrayCell(g_hChildSocketReadyState, iChildIndex);
}

public Native_Websocket_UnhookChild(Handle:plugin, numParams)
{
	new WebsocketHandle:iPseudoChildHandle = WebsocketHandle:GetNativeCell(1);
	new iChildIndex;
	if(iPseudoChildHandle == INVALID_WEBSOCKET_HANDLE
	|| (iChildIndex = FindValueInArray(g_hChildSocketIndexes, _:iPseudoChildHandle)) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid child websocket handle.");
		return;
	}
	
	new Handle:hReceiveForward = Handle:GetArrayCell(g_hChildReceiveForwards, iChildIndex);
	new Handle:hDisconnectForward = Handle:GetArrayCell(g_hChildDisconnectForwards, iChildIndex);
	new Handle:hErrorForward = Handle:GetArrayCell(g_hChildErrorForwards, iChildIndex);
	new Handle:hReadyStateChangeForward = Handle:GetArrayCell(g_hChildReadyStateChangeForwards, iChildIndex);
	
	new Handle:hChildSocketPlugin = GetArrayCell(g_hChildSocketPlugins, iChildIndex);
	new iPluginCount = GetArraySize(hChildSocketPlugin);
	new aPluginInfo[CHILD_ARRAY_LENGTH];
	for(new p=0;p<iPluginCount;p++)
	{
		GetArrayArray(hChildSocketPlugin, p, aPluginInfo, CHILD_ARRAY_LENGTH);
		if(Handle:aPluginInfo[CHILD_PLUGINHANDLE] == plugin)
		{
			// Remove the caller from all forwards
			if(Function:aPluginInfo[CHILD_RECVCALL] != INVALID_FUNCTION)
			{
				RemoveFromForward(hReceiveForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_RECVCALL]);
				RemoveFromForward(hDisconnectForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_DISCCALL]);
				RemoveFromForward(hErrorForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_ERRCALL]);
			}
			// Did this plugin call Websocket_HookReadyStateChange?
			if(Function:aPluginInfo[CHILD_READYSTATECALL] != INVALID_FUNCTION)
				RemoveFromForward(hReadyStateChangeForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_READYSTATECALL]);
			RemoveFromArray(hChildSocketPlugin, p);
			break;
		}
	}
	
	// No plugin is using this anymore. Close the connection.
	if(GetArraySize(hChildSocketPlugin) == 0)
		CloseConnection(iChildIndex, 1000, "");
}

public Native_Websocket_Close(Handle:plugin, numParams)
{
	new WebsocketHandle:iPseudoHandle = WebsocketHandle:GetNativeCell(1);
	new iIndex;
	if(iPseudoHandle == INVALID_WEBSOCKET_HANDLE
	|| (iIndex = FindValueInArray(g_hMasterSocketIndexes, iPseudoHandle)) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid websocket handle.");
		return;
	}
	
	CloseMasterSocket(iIndex);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg)
{
	new iIndex = FindValueInArray(g_hMasterSocketIndexes, arg);
	// That should never happen :/
	if(iIndex != -1)
	{
		CloseMasterSocket(iIndex, true, errorType, errorNum);
	}
	else
		CloseHandle(socket);
}

CloseMasterSocket(iIndex, bool:bError = false, errorType=-1, errorNum=-1)
{
	new iPseudoHandle = GetArrayCell(g_hMasterSocketIndexes, iIndex);
	new Handle:hErrorForward = GetArrayCell(g_hMasterErrorForwards, iIndex);
	new Handle:hIncomingForward = GetArrayCell(g_hMasterIncomingForwards, iIndex);
	new Handle:hCloseForward = GetArrayCell(g_hMasterCloseForwards, iIndex);
	
	// Close all child sockets first.
	new iChildSockets = GetArraySize(g_hChildsMasterSockets);
	for(new i=0;i<iChildSockets;i++)
	{
		if(GetArrayCell(g_hChildsMasterSockets, i) == iIndex)
			CloseConnection(i, 1001, "");
	}
	
	// Only bother notifying other plugins, if there are still any listening at all.
	if(GetForwardFunctionCount(hIncomingForward) > 0)
	{
		// There's been an error.
		if(bError)
		{
			// Inform plugins there's been an error
			Call_StartForward(hErrorForward);
			Call_PushCell(WebsocketHandle:iPseudoHandle);
			Call_PushCell(errorType);
			Call_PushCell(errorNum);
			Call_PushCell(0); // Dummy value as the master socket doesn't use the any:data paramter.
			Call_Finish();
		}
		else
		{
			Call_StartForward(hCloseForward);
			Call_PushCell(WebsocketHandle:iPseudoHandle);
			Call_Finish();
		}
		
		// Loop through all plugins using this socket
		new Handle:hPlugins = GetArrayCell(g_hMasterSocketPlugins, iIndex);
		new iPluginCount = GetArraySize(hPlugins);
		new aPluginInfo[4];
		// This master socket is gone, remove forward
		for(new p=0;p<iPluginCount;p++)
		{
			GetArrayArray(hPlugins, p, aPluginInfo, 4);
			
			if(!IsPluginStillLoaded(Handle:aPluginInfo[PLUGIN_HANDLE]))
				continue;
			
			// Remove it from forwards.
			RemoveFromForward(hErrorForward, Handle:aPluginInfo[PLUGIN_HANDLE], Function:aPluginInfo[PLUGIN_ERRORCALLBACK]);
			RemoveFromForward(hIncomingForward, Handle:aPluginInfo[PLUGIN_HANDLE], Function:aPluginInfo[PLUGIN_INCOMINGCALLBACK]);
			RemoveFromForward(hCloseForward, Handle:aPluginInfo[PLUGIN_HANDLE], Function:aPluginInfo[PLUGIN_CLOSECALLBACK]);
		}
		CloseHandle(hPlugins);
	}
	
	RemoveFromArray(g_hMasterSocketPlugins, iIndex);
	CloseHandle(hErrorForward);
	CloseHandle(hIncomingForward);
	CloseHandle(hCloseForward);
	RemoveFromArray(g_hMasterErrorForwards, iIndex);
	RemoveFromArray(g_hMasterIncomingForwards, iIndex);
	RemoveFromArray(g_hMasterCloseForwards, iIndex);
	RemoveFromArray(g_hMasterSocketHostPort, iIndex);
	
	// Close the actual master socket
	CloseHandle(Handle:GetArrayCell(g_hMasterSockets, iIndex));
	
	RemoveFromArray(g_hMasterSockets, iIndex);
	RemoveFromArray(g_hMasterSocketIndexes, iIndex);
}

public OnSocketIncoming(Handle:socket, Handle:newSocket, const String:remoteIP[], remotePort, any:arg)
{
	new iIndex = FindValueInArray(g_hMasterSocketIndexes, arg);
	// This isn't handled by anything?! GO AWAY!!1
	if(iIndex == -1)
	{
		CloseHandle(newSocket);
		return;
	}
	
	// Hook this child socket. Let the magic begin!
	SocketSetReceiveCallback(newSocket, OnChildSocketReceive);
	SocketSetDisconnectCallback(newSocket, OnChildSocketDisconnect);
	SocketSetErrorCallback(newSocket, OnChildSocketError);
	
	new iPseudoChildHandle = ++g_iLastSocketIndex;
	new Handle:hIncomingForward = GetArrayCell(g_hMasterIncomingForwards, iIndex);
	
	// There are no plugins listening anymore?! They didn't call WebSocket_Close in OnPluginEnd.
	if(!GetForwardFunctionCount(hIncomingForward))
	{
		CloseHandle(newSocket);
		CloseMasterSocket(iIndex);
		return;
	}
	
	SocketSetArg(newSocket, iPseudoChildHandle);
	
	// Save this connection in our arrays
	PushArrayCell(g_hChildSockets, newSocket);
	// Make sure we remember the master socket!
	PushArrayCell(g_hChildsMasterSockets, iIndex);
	PushArrayCell(g_hChildSocketIndexes, iPseudoChildHandle);
	PushArrayString(g_hChildSocketHost, remoteIP);
	PushArrayCell(g_hChildSocketPort, remotePort);
	PushArrayCell(g_hChildSocketPlugins, CreateArray(CHILD_ARRAY_LENGTH));
	PushArrayCell(g_hChildSocketReadyState, State_Connecting);
	
	// Create the private forwards for this socket
	new Handle:hReceiveForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Any);
	PushArrayCell(g_hChildReceiveForwards, hReceiveForward);
	new Handle:hErrorForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Any);
	PushArrayCell(g_hChildErrorForwards, hErrorForward);
	new Handle:hDisconnectForward = CreateForward(ET_Ignore, Param_Cell, Param_Any);
	PushArrayCell(g_hChildDisconnectForwards, hDisconnectForward);
	new Handle:hReadyStateChangeForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Any);
	PushArrayCell(g_hChildReadyStateChangeForwards, hReadyStateChangeForward);
	
	// TODO start a timouttimer which closes the connection, if no valid http upgrade request is received in time.
}

public OnChildSocketError(Handle:socket, const errorType, const errorNum, any:arg)
{
	new iIndex = FindValueInArray(g_hChildSocketIndexes, arg);
	// This isn't handled by anything?! GO AWAY!!1
	if(iIndex == -1)
	{
		CloseHandle(socket);
		return;
	}
	
	new Handle:hErrorForward = Handle:GetArrayCell(g_hChildErrorForwards, iIndex);
	
	Call_StartForward(hErrorForward);
	Call_PushCell(GetArrayCell(g_hChildSocketIndexes, iIndex));
	Call_PushCell(errorType);
	Call_PushCell(errorNum);
	Call_Finish();
	
	CloseChildSocket(iIndex, false);
}

public OnChildSocketDisconnect(Handle:socket, any:arg)
{
	Debug(1, "Child socket disconnected");
	new iIndex = FindValueInArray(g_hChildSocketIndexes, arg);
	// This isn't handled by anything?! GO AWAY!!1
	if(iIndex == -1)
	{
		CloseHandle(socket);
		return;
	}
	CloseChildSocket(iIndex);
}

public OnChildSocketReceive(Handle:socket, const String:receiveData[], const dataSize, any:arg)
{
	Debug(2, "Child socket receives data: %s", receiveData);
	
	new iIndex = FindValueInArray(g_hChildSocketIndexes, arg);
	// This isn't handled by anything?! GO AWAY!!1
	if(iIndex == -1)
	{
		CloseHandle(socket);
		return;
	}
	
	new WebsocketReadyState:iReadyState = GetArrayCell(g_hChildSocketReadyState, iIndex);
	switch(iReadyState)
	{
		// We received the http upgrade request
		// Send the correct response to complete the handshake!
		case State_Connecting:
		{
			new RegexError:iRegexError;
			// Get the key
			new iSubStrings = MatchRegex(g_hRegExKey, receiveData, iRegexError);
			if(iSubStrings == -1)
			{
				LogError("Can't find the Key in the http protocol upgrade request.");
				CloseChildSocket(iIndex);
				return;
			}
			new String:sKey[256];
			if(!GetRegexSubString(g_hRegExKey, 1, sKey, sizeof(sKey)))
			{
				LogError("Failed to extract security key.");
				CloseChildSocket(iIndex);
				return;
			}
			
			Debug(2, "Key: %s", sKey);
			
			new String:sSHA1Hash[21], String:sResponseKey[41];
			Format(sKey, sizeof(sKey), "%s258EAFA5-E914-47DA-95CA-C5AB0DC85B11", sKey);
			SHA1String(sKey, sSHA1Hash, false);
			EncodeBase64(sResponseKey, sizeof(sResponseKey), sSHA1Hash, 20);
			
			Debug(2, "ResponseKey: %s", sResponseKey);
			
			iSubStrings = MatchRegex(g_hRegExProtocol, receiveData, iRegexError);
			new String:sProtocol[256];
			if(iSubStrings != -1)
			{
				if(!GetRegexSubString(g_hRegExProtocol, 1, sProtocol, sizeof(sProtocol)))
				{
					Format(sProtocol, sizeof(sProtocol), "");
					// It's not required to specify a subprotocol!
					/*LogError("Failed to extract sub protocols.");
					CloseChildSocket(iIndex);
					return;*/
				}
			}
			
			// Inform plugins, there's an incoming request 
			new iMasterIndex = GetArrayCell(g_hChildsMasterSockets, iIndex);
			
			new Handle:hIncomingForward = GetArrayCell(g_hMasterIncomingForwards, iMasterIndex);
			Call_StartForward(hIncomingForward);
			Call_PushCell(WebsocketHandle:GetArrayCell(g_hMasterSocketIndexes, iMasterIndex));
			Call_PushCell(WebsocketHandle:GetArrayCell(g_hChildSocketIndexes, iIndex));
			decl String:remoteIP[65];
			GetArrayString(g_hChildSocketHost, iIndex, remoteIP, sizeof(remoteIP));
			Call_PushString(remoteIP);
			Call_PushCell(GetArrayCell(g_hChildSocketPort, iIndex));
			// TODO SM_PARAM_STRING_UTF8 might be wrong here? SM_PARAM_STRING_COPY?
			new String:sProtocolReturn[256];
			strcopy(sProtocolReturn, sizeof(sProtocolReturn), sProtocol);
			Call_PushStringEx(sProtocolReturn, sizeof(sProtocolReturn), SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
			
			new Action:iResult;
			Call_Finish(iResult);
			
			// TODO be more friendly in refusing connections by sending a proper http header.
			// Someone doesn't like this connection..
			if(iResult >= Plugin_Handled)
			{
				Debug(1, "IncomingForward is >= Plugin_Handled. Closing child socket.");
				// Uhm.. Just because of that one? plugin denying the connection, we need to revert any Websocket_HookChild call..
				CloseChildSocket(iIndex);
				
				return;
			}
			
			// Check if any plugin called Websocket_HookChild and close the socket, if not.
			new Handle:hChildSocketPlugins = GetArrayCell(g_hChildSocketPlugins, iIndex);
			if(GetArraySize(hChildSocketPlugins) == 0)
			{
				Debug(1, "No plugin hooked the new child socket. Closing child socket.");
				CloseChildSocket(iIndex);
				
				return;
			}
			
			// Make sure the server offered this protocol the plugin chose.
			// Should probably error out here?
			if(StrContains(sProtocol, sProtocolReturn) == -1)
			{
				Debug(1, "Plugin chose non-existant subprotocol. Offered: \"%s\" - Chosen: \"%s\"", sProtocol, sProtocolReturn);
				Format(sProtocolReturn, sizeof(sProtocolReturn), "");
			}
			else
				Format(sProtocolReturn, sizeof(sProtocolReturn), "\r\nSec-Websocket-Protocol: %s", sProtocol);
			
			// Prepare HTTP request
			decl String:sHTTPRequest[512];
			Format(sHTTPRequest, sizeof(sHTTPRequest), "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: %s%s\r\n\r\n", sResponseKey, sProtocolReturn);
			SocketSend(socket, sHTTPRequest);
			
			Debug(2, "Responding: %s", sHTTPRequest);
			
			SetArrayCell(g_hChildSocketReadyState, iIndex, State_Open);
			
			// Inform the other plugins of the change.
			new Handle:hReadyStateChangeForward = GetArrayCell(g_hChildReadyStateChangeForwards, iIndex);
			
			Call_StartForward(hReadyStateChangeForward);
			Call_PushCell(WebsocketHandle:GetArrayCell(g_hChildSocketIndexes, iIndex));
			Call_PushCell(GetArrayCell(g_hChildSocketReadyState, iIndex));
			Call_Finish();
		}
		// We're open to receive info! Parse the input.
		case State_Open:
		{
			new vFrame[WebsocketFrame], String:sPayLoad[dataSize-1];
			ParseFrame(vFrame, receiveData, dataSize, sPayLoad);
			if(!PreprocessFrame(iIndex, vFrame, sPayLoad))
			{
				// Call forward
				//SendWebsocketFrame(iIndex, sPayLoad, vFrame);
				new Handle:hReceiveForward = Handle:GetArrayCell(g_hChildReceiveForwards, iIndex);
				Call_StartForward(hReceiveForward);
				Call_PushCell(arg);
				new WebsocketSendType:iType;
				if(vFrame[OPCODE]==FrameType_Text)
					iType = SendType_Text;
				else
					iType = SendType_Binary;
				Call_PushCell(iType);
				Call_PushString(sPayLoad);
				Call_PushCell(vFrame[PAYLOAD_LEN]);
				Call_Finish();
			}
		}
	}
}

// Closes a child socket and cleans up the arrays
CloseChildSocket(iChildIndex, bool:bFireForward=true)
{
	Debug(1, "Closing child socket #%d", iChildIndex);
	new Handle:hReceiveForward = Handle:GetArrayCell(g_hChildReceiveForwards, iChildIndex);
	new Handle:hDisconnectForward = Handle:GetArrayCell(g_hChildDisconnectForwards, iChildIndex);
	new Handle:hErrorForward = Handle:GetArrayCell(g_hChildErrorForwards, iChildIndex);
	new Handle:hReadyStateChangeForward = Handle:GetArrayCell(g_hChildReadyStateChangeForwards, iChildIndex);
	
	if(bFireForward)
	{
		Call_StartForward(hDisconnectForward);
		Call_PushCell(GetArrayCell(g_hChildSocketIndexes, iChildIndex));
		Call_Finish();
	}
	
	new Handle:hChildSocket = Handle:GetArrayCell(g_hChildSockets, iChildIndex);
	
	RemoveFromArray(g_hChildSockets, iChildIndex);
	RemoveFromArray(g_hChildsMasterSockets, iChildIndex);
	RemoveFromArray(g_hChildSocketHost, iChildIndex);
	RemoveFromArray(g_hChildSocketPort, iChildIndex);
	RemoveFromArray(g_hChildSocketReadyState, iChildIndex);
	new Handle:hChildSocketPlugin = GetArrayCell(g_hChildSocketPlugins, iChildIndex);
	new iPluginCount = GetArraySize(hChildSocketPlugin);
	new aPluginInfo[CHILD_ARRAY_LENGTH];
	for(new p=0;p<iPluginCount;p++)
	{
		GetArrayArray(hChildSocketPlugin, p, aPluginInfo, CHILD_ARRAY_LENGTH);
		if(!IsPluginStillLoaded(Handle:aPluginInfo[CHILD_PLUGINHANDLE]))
			continue;
		if(Function:aPluginInfo[CHILD_RECVCALL] != INVALID_FUNCTION)
		{
			RemoveFromForward(hReceiveForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_RECVCALL]);
			RemoveFromForward(hDisconnectForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_DISCCALL]);
			RemoveFromForward(hErrorForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_ERRCALL]);
		}
		if(Function:aPluginInfo[CHILD_READYSTATECALL] != INVALID_FUNCTION)
		{
			RemoveFromForward(hReadyStateChangeForward, Handle:aPluginInfo[CHILD_PLUGINHANDLE], Function:aPluginInfo[CHILD_READYSTATECALL]);
		}
	}
	CloseHandle(hChildSocketPlugin);
	RemoveFromArray(g_hChildSocketPlugins, iChildIndex);
	RemoveFromArray(g_hChildSocketIndexes, iChildIndex);
	
	CloseHandle(hReceiveForward);
	CloseHandle(hDisconnectForward);
	CloseHandle(hErrorForward);
	CloseHandle(hReadyStateChangeForward);
	
	RemoveFromArray(g_hChildReceiveForwards, iChildIndex);
	RemoveFromArray(g_hChildErrorForwards, iChildIndex);
	RemoveFromArray(g_hChildDisconnectForwards, iChildIndex);
	RemoveFromArray(g_hChildReadyStateChangeForwards, iChildIndex);
	
	CloseHandle(hChildSocket);
}

ParseFrame(vFrame[WebsocketFrame], const String:receiveDataLong[], const dataSize, String:sPayLoad[])
{
	// We're only interested in the first 8 bits.. what's that rest?!
	new receiveData[dataSize];
	for(new i=0;i<dataSize;i++)
	{
		receiveData[i] = receiveDataLong[i]&0xff;
		Debug(3, "%d (%c): %08b", i, receiveData[i], receiveData[i]);
	}
	
	decl String:sByte[9];
	Format(sByte, sizeof(sByte), "%08b", receiveData[0]);
	Debug(3, "First byte: %s", sByte);
	vFrame[FIN] = sByte[0]=='1'?1:0;
	vFrame[RSV1] = sByte[1]=='1'?1:0;
	vFrame[RSV2] = sByte[2]=='1'?1:0;
	vFrame[RSV3] = sByte[3]=='1'?1:0;
	vFrame[OPCODE] = WebsocketFrameType:bindec(sByte[4]);
	
	Format(sByte, sizeof(sByte), "%08b", receiveData[1]);
	Debug(3, "Second byte: %s", sByte);
	vFrame[MASK] = sByte[0]=='1'?1:0;
	vFrame[PAYLOAD_LEN] = bindec(sByte[1]);
	
	new iOffset = 2;
	
	vFrame[MASKINGKEY][0] = '\0';
	if(vFrame[PAYLOAD_LEN] > 126)
	{
		new String:sLoongLength[49];
		for(new i=2;i<8;i++)
			Format(sLoongLength, sizeof(sLoongLength), "%s%08b", sLoongLength, receiveData[i]);
		
		vFrame[PAYLOAD_LEN] = bindec(sLoongLength);
		iOffset += 6;
	}
	else if(vFrame[PAYLOAD_LEN] > 125)
	{
		new String:sLongLength[17];
		for(new i=2;i<4;i++)
			Format(sLongLength, sizeof(sLongLength), "%s%08b", sLongLength, receiveData[i]);
		
		vFrame[PAYLOAD_LEN] = bindec(sLongLength);
		iOffset += 2;
	}
	if(vFrame[MASK])
	{
		for(new i=iOffset,j=0;j<4;i++,j++)
			vFrame[MASKINGKEY][j] = receiveData[i];
		vFrame[MASKINGKEY][4] = '\0';
		iOffset += 4;
	}
	
	for(new i=iOffset,j=0;j<vFrame[PAYLOAD_LEN];i++,j++)
		sPayLoad[j] = receiveData[i];
	sPayLoad[vFrame[PAYLOAD_LEN]] = '\0';
	
	Debug(2, "dataSize: %d", dataSize);
	Debug(2, "FIN: %d", vFrame[FIN]);
	Debug(2, "RSV1: %d", vFrame[RSV1]);
	Debug(2, "RSV2: %d", vFrame[RSV2]);
	Debug(2, "RSV3: %d", vFrame[RSV3]);
	Debug(2, "OPCODE: %d", _:vFrame[OPCODE]);
	Debug(2, "MASK: %d", vFrame[MASK]);
	Debug(2, "PAYLOAD_LEN: %d", vFrame[PAYLOAD_LEN]);
	Debug(2, "PAYLOAD(pre unmask): %s", sPayLoad);
	
	// Unmask
	if(vFrame[MASK])
	{
		new String:sPayloadBuffer[vFrame[PAYLOAD_LEN]+1];
		strcopy(sPayloadBuffer, vFrame[PAYLOAD_LEN]+1, sPayLoad);
		strcopy(sPayLoad, vFrame[PAYLOAD_LEN]+1, "");
		for(new i=0;i<vFrame[PAYLOAD_LEN];i++)
		{
			Format(sPayLoad, vFrame[PAYLOAD_LEN]+1, "%s%c", sPayLoad, sPayloadBuffer[i]^vFrame[MASKINGKEY][i%4]);
		}
	}
	
	// Client requested connection close
	if(vFrame[OPCODE] == FrameType_Close)
	{
		// first 2 bytes are close reason
		new String:sCloseReason[65];
		for(new i=0;i<2;i++)
			Format(sCloseReason, sizeof(sCloseReason), "%s%08b", sCloseReason, sPayLoad[i]&0xff);
		
		vFrame[CLOSE_REASON] = bindec(sCloseReason);
		
		strcopy(sPayLoad, dataSize-1, sPayLoad[2]);
		vFrame[PAYLOAD_LEN] -= 2;
		
		Debug(2, "CLOSE_REASON: %d", vFrame[CLOSE_REASON]);
	}
	else
	{
		vFrame[CLOSE_REASON] = -1;
	}
	
	Debug(2, "PAYLOAD: %s", sPayLoad);
	
	// TODO: utf8_decode
}

bool:PreprocessFrame(iIndex, vFrame[WebsocketFrame], String:sPayLoad[])
{
	if(vFrame[FIN] != 1)
	{
		LogError("Received fragmented frame from client. This hasn't been implemented yet.");
		CloseConnection(iIndex, 1003, "Fragments not supported");
		return false;
	}
	
	switch(vFrame[OPCODE])
	{
		case FrameType_Text:
		{
			return false;
		}
		case FrameType_Binary:
		{
			return false;
		}
		case FrameType_Close:
		{
			// We're done here.
			if(GetArrayCell(g_hChildSocketReadyState, iIndex) == State_Closing)
			{
				CloseChildSocket(iIndex);
				return true;
			}
			
			// Just mirror it back
			SendWebsocketFrame(iIndex, sPayLoad, vFrame);
			SetArrayCell(g_hChildSocketReadyState, iIndex, State_Closing);
			
			new Handle:hReadyStateChangeForward = GetArrayCell(g_hChildReadyStateChangeForwards, iIndex);
			
			// Inform the other plugins of the change.
			Call_StartForward(hReadyStateChangeForward);
			Call_PushCell(WebsocketHandle:GetArrayCell(g_hChildSocketIndexes, iIndex));
			Call_PushCell(GetArrayCell(g_hChildSocketReadyState, iIndex));
			Call_Finish();
			
			CloseChildSocket(iIndex);
			return true;
		}
		case FrameType_Ping:
		{
			vFrame[OPCODE] = FrameType_Pong;
			SendWebsocketFrame(iIndex, sPayLoad, vFrame);
			return true;
		}
		case FrameType_Pong:
		{
			return true;
		}
	}
	
	// This is an unknown OPCODE?! OMG
	LogError("Received invalid opcode = %d", _:vFrame[OPCODE]);
	CloseConnection(iIndex, 1002, "Invalid opcode");
	return true;
}

bool:SendWebsocketFrame(iIndex, String:sPayLoad[], vFrame[WebsocketFrame])
{
	new WebsocketReadyState:iReadyState = GetArrayCell(g_hChildSocketReadyState, iIndex);
	if(iReadyState != State_Open)
	{
		return false;
	}
	
	new length = vFrame[PAYLOAD_LEN];
	
	Debug(1, "Preparing to send payload %s (%d)", sPayLoad, length);
	
	decl String:sFrame[length+14];
	if(PackFrame(sPayLoad, sFrame, vFrame))
	{
		if(length > 65535)
			length += 10;
		else if(length > 125)
			length += 4;
		else
			length += 2;
		if(vFrame[CLOSE_REASON] != -1)
			length += 2;
		Debug(1, "Sending: \"%s\"", sFrame);
		Debug(2, "FIN: %d", vFrame[FIN]);
		Debug(2, "RSV1: %d", vFrame[RSV1]);
		Debug(2, "RSV2: %d", vFrame[RSV2]);
		Debug(2, "RSV3: %d", vFrame[RSV3]);
		Debug(2, "OPCODE: %d", _:vFrame[OPCODE]);
		Debug(2, "MASK: %d", vFrame[MASK]);
		Debug(2, "PAYLOAD_LEN: %d", vFrame[PAYLOAD_LEN]);
		Debug(2, "PAYLOAD: %s", sPayLoad);
		Debug(2, "CLOSE_REASON: %d", vFrame[CLOSE_REASON]);
		Debug(2, "Frame: %s", sFrame);
		SocketSend(GetArrayCell(g_hChildSockets, iIndex), sFrame, length);
		return true;
	}
	
	return false;
}

bool:PackFrame(String:sPayLoad[], String:sFrame[], vFrame[WebsocketFrame])
{
	new length = vFrame[PAYLOAD_LEN];
	
	// We don't split frames (yet), so FIN is always 1.
	switch(vFrame[OPCODE])
	{
		case FrameType_Text:
		{
			sFrame[0] = 129; // (1<<0)|(1<<7) - Text-Frame (10000001):
		}
		case FrameType_Close:
		{
			sFrame[0] = 136; // (1<<3)|(1<<7) -  Close-Frame (10001000):
			length += 2; // Remember the 2byte close reason
		}
		case FrameType_Ping:
		{
			sFrame[0] = 137; // (1<<0)|(1<<3)|(1<<7) -  Ping-Frame (10001001):
		}
		case FrameType_Pong:
		{
			sFrame[0] = 138; // (1<<1)|(1<<3)|(1<<7) -  Pong-Frame (10001010):
		}
		default:
		{
			LogError("Trying to send frame with unknown opcode = %d", _:vFrame[OPCODE]);
			return false;
		}
	}
	
	new iOffset;
	
	// Add the length "byte" (7bit). We're only sending unmasked messages
	if(length > 65535)
	{
		sFrame[1] = 127;
		decl String:sLengthBin[65], String:sByte[9];
		Format(sLengthBin, 65, "%064b", length);
		for(new i=0,j=2;j<=10;i++)
		{
			if(i && !(i%8))
			{
				sFrame[j] = bindec(sByte);
				Format(sByte, 9, "");
				j++;
			}
			Format(sByte, 9, "%s%s", sByte, sLengthBin[i]);
		}
		
		// the most significant bit MUST be 0
		if(sFrame[2] > 127)
		{
			LogError("Can't send frame. Too much data.");
			return false;
		}
		iOffset = 9;
	}
	else if(length > 125)
	{
		sFrame[1] = 126;
		if(length < 256)
		{
			sFrame[2] = 0;
			sFrame[3] = length;
		}
		else
		{
			new String:sLengthBin[17], String:sByte[9];
			Format(sLengthBin, 17, "%016b", length);
			for(new i=0,j=2;i<=16;i++)
			{
				if(i && !(i%8))
				{
					sFrame[j] = bindec(sByte);
					Format(sByte, 9, "");
					j++;
				}
				Format(sByte, 9, "%s%s", sByte, sLengthBin[i]);
			}
		}
		iOffset = 4;
	}
	else
	{
		sFrame[1] = length;
		iOffset = 2;
	}
	
	// Make sure we didn't set the MASK bit by accident..
	sFrame[1] &= ~(1<<7);
	vFrame[MASK] = 0;
	
	// We got a closing reason. Add it right in front of the payload.
	if(vFrame[OPCODE] == FrameType_Close && vFrame[CLOSE_REASON] != -1)
	{
		new String:sCloseReasonBin[17], String:sByte[9];
		Format(sCloseReasonBin, 17, "%016b", vFrame[CLOSE_REASON]);
		for(new i=0,j=iOffset;i<=16;i++)
		{
			if(i && !(i%8))
			{
				sFrame[j] = bindec(sByte);
				Format(sByte, 9, "");
				j++;
			}
			Format(sByte, 9, "%s%s", sByte, sCloseReasonBin[i]);
		}
		iOffset += 2;
	}
	
	// Add the payload at the end.
	strcopy(sFrame[iOffset], length+iOffset, sPayLoad);
	
	return true;
}

// Close the connection by initiating the connection close handshake with the CLOSE opcode
CloseConnection(iIndex, iCloseReason, String:sPayLoad[])
{
	new vFrame[WebsocketFrame];
	vFrame[OPCODE] = FrameType_Close;
	vFrame[CLOSE_REASON] = iCloseReason;
	vFrame[PAYLOAD_LEN] = strlen(sPayLoad);
	SendWebsocketFrame(iIndex, sPayLoad, vFrame);
	SetArrayCell(g_hChildSocketReadyState, iIndex, State_Closing);
	
	new Handle:hReadyStateChangeForward = GetArrayCell(g_hChildReadyStateChangeForwards, iIndex);
	
	// Inform the other plugins of the change.
	Call_StartForward(hReadyStateChangeForward);
	Call_PushCell(WebsocketHandle:GetArrayCell(g_hChildSocketIndexes, iIndex));
	Call_PushCell(GetArrayCell(g_hChildSocketReadyState, iIndex));
	Call_Finish();
}

stock Debug(iDebugLevel, String:fmt[], any:...)
{
#if DEBUG > 0
	if(iDebugLevel > DEBUG)
		return;
	decl String:sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), fmt, 3);
	LogToFile(g_sLog, sBuffer);
#endif
}

stock GetIndexOfMasterSocket(Handle:socket)
{
	new iSize = GetArraySize(g_hMasterSockets);
	for(new i=0;i<iSize;i++)
	{
		if(GetArrayCell(g_hMasterSockets, i) == socket)
			return i;
	}
	return -1;
}

stock GetIndexOfChildSocket(Handle:socket)
{
	new iSize = GetArraySize(g_hChildSockets);
	for(new i=0;i<iSize;i++)
	{
		if(GetArrayCell(g_hChildSockets, i) == socket)
			return i;
	}
	return -1;
}

stock bindec(const String:sBinary[])
{
	new ret, len = strlen(sBinary);
	for(new i=0;i<len;i++)
	{
		ret = ret<<1;
		if(sBinary[i] == '1')
			ret |= 1;
	}
	return ret;
}

stock bool:IsPluginStillLoaded(Handle:plugin)
{
	new Handle:hIt = GetPluginIterator();
	new Handle:hPlugin;
	new bool:bPluginLoaded = false;
	while(MorePlugins(hIt))
	{
		hPlugin = ReadPlugin(hIt);
		if(hPlugin == plugin && GetPluginStatus(hPlugin) == Plugin_Running)
		{
			bPluginLoaded = true;
			break;
		}
	}
	CloseHandle(hIt);
	return bPluginLoaded;
}
