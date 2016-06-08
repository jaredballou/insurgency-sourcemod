#if defined _websocket_included
  #endinput
#endif
#define _websocket_included

enum WebsocketReadyState {
	State_Connecting = 0,
	State_Open,
	State_Closing,
	State_Closed // Kinda unused
}

enum WebsocketHandle {
	INVALID_WEBSOCKET_HANDLE = 0
}

enum WebsocketSendType {
	SendType_Text = 0,
	SendType_Binary
}

/**
 * called if an unrecoverable error occured on the master socket
 *
 * @param WebsocketHandle	websocket	The websocket handle pointing to the calling websocket
 * @param cell_t			errorType	The error type, see defines in socket.inc
 * @param cell_t			errorNum	The errno, see errno.h for details
 * @noreturn
 */
functag WebsocketErrorCB public(WebsocketHandle:websocket, const errorType, const errorNum);

/**
 * called if a master websocket is closed
 *
 * @param WebsocketHandle	websocket	The websocket handle pointing to the calling websocket
 * @noreturn
 */
functag WebsocketCloseCB public(WebsocketHandle:websocket);

/**
 * triggered when a client connected to our websocket
 *
 * @param Handle	websocket		The websocket handle pointing to the calling listen-socket
 * @param Handle	newWebsocket	The websocket handle to the newly spawned child socket
 * @param String	remoteIP		The remote IP
 * @param cell_t	remotePort	The remote port
 * @param String	protocols 	The subprotocols the client supports seperated by commas. You have to choose one of the list, so "protocols" is only that one protocol.
 * @noreturn
 */
functag WebsocketIncomingCB Action:public(WebsocketHandle:websocket, WebsocketHandle:newWebsocket, const String:remoteIP[], remotePort, String:protocols[256]);

/**
 * triggered if a websocket receives data
 *
 * @note This is binary safe if you always use dataSize for operations on receiveData[]
 * @note packets may be split up into multiple chunks -> multiple calls to the receive callback
 * @note if not set otherwise by SocketSetOption(..., ConcatenateCallbacks, ...) receiveData will
 *       never be longer than 4096 characters including \0 terminator
 *
 * @param Handle	websocket		The socket handle pointing to the calling socket
 * @param String	receiveData	The data which arrived, 0-terminated at receiveData[dataSize]
 * @param cell_t	dataSize	The length of the arrived data excluding the 0-termination
 * @noreturn
 */
functag WebsocketReceiveCB public(WebsocketHandle:websocket, WebsocketSendType:iType, const String:receiveData[], const dataSize);

/**
 * called if a socket has been properly disconnected by the remote side
 *
 * @param Handle	websocket		The socket handle pointing to the calling socket
 * @noreturn
 */
functag WebsocketDisconnectCB public(WebsocketHandle:websocket);

/**
 * called if the readystate of a childsocket changes.
 * Only fires for ReadyState_Open and ReadyState_Closing.
 *
 * @param Handle	websocket		The socket handle pointing to the calling socket
 * @param WebsocketReadyState	readystate	The new readystate of the childsocket.
 * @noreturn
 */
functag WebsocketReadyStateChangedCB public(WebsocketHandle:websocket, WebsocketReadyState:readystate);

/**
 * Creates a websocket server which listens on the supplied ip:port combination.
 *
 * @param sHostName    	The IP to bind to.
 * @param iPort    		The port to listen on
 * @param inc    		The incoming child connection callback
 * @param we    		The error callback
 * @return        		A WebsocketHandle or INVALID_WEBSOCKET_HANDLE on error.
 */
native WebsocketHandle:Websocket_Open(const String:sHostName[], iPort, WebsocketIncomingCB:inc, WebsocketErrorCB:we, WebsocketCloseCB:clo);

/**
 * Hooks child socket's events
 *
 * @param childwebsocket    The child websocket to hook.
 * @param recv    			Data receive callback
 * @param disc    			The disconnect callback
 * @param we    			The error callback
 * @return        			True if child socket was hooked, false otherwise
 */
native bool:Websocket_HookChild(WebsocketHandle:childwebsocket, WebsocketReceiveCB:recv, WebsocketDisconnectCB:disc, WebsocketErrorCB:we);

/**
 * Hooks child socket's readystate changes
 *
 * @param childwebsocket    The child websocket to hook.
 * @param readystate   			ReadyState change callback
 * @return        			True if child socket was hooked, false otherwise
 */
native bool:Websocket_HookReadyStateChange(WebsocketHandle:childwebsocket, WebsocketReadyStateChangedCB:readystate);


/**
 * Sends text or binary data through the websocket
 *
 * @param childwebsocket    The child websocket to send to
 * @param type    			The datatype SendType_Text or SendType_Binary
 * @param sPayLoad 			The data to send
 * @param dataSize			If set, it's used as maxlength. Useful for binary data where \0 might be used before the end of the data.
 * @return        			True if child socket was hooked, false otherwise
 */
native bool:Websocket_Send(WebsocketHandle:childwebsocket, WebsocketSendType:type, const String:sPayload[], const dataSize=-1);

/**
 * Gets a child websocket's readyState.
 *
 * @param childwebsocket    The child websocket
 * @return        			The readyState
 */
native WebsocketReadyState:Websocket_GetReadyState(WebsocketHandle:childwebsocket);

/**
 * Unhooks a child socket's events: If there's no plugin listening anymore, the socket is closed.
 *
 * @param childwebsocket    The child websocket
 * @noreturn
 */
native Websocket_UnhookChild(WebsocketHandle:childwebsocket);

/**
 * Closes a listening master socket, created with Websocket_Open.
 * Note: The socket will still be open, if there are more plugins using it.
 * 
 * Call this in OnPluginEnd()!
 *
 * @param websocket    The master websocket
 * @noreturn
 */
native Websocket_Close(WebsocketHandle:websocket);

public SharedPlugin:__pl_websocket = 
{
	name = "websocket",
	file = "websocket.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_websocket_SetNTVOptional()
{
	MarkNativeAsOptional("Websocket_Open");
	MarkNativeAsOptional("Websocket_HookReadyStateChange");
	MarkNativeAsOptional("Websocket_HookChild");
	MarkNativeAsOptional("Websocket_Send");
	MarkNativeAsOptional("Websocket_GetReadyState");
	MarkNativeAsOptional("Websocket_UnhookChild");
	MarkNativeAsOptional("Websocket_Close");
}
#endif