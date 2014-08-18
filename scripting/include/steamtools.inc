#if defined _steamtools_included
#endinput
#endif
#define _steamtools_included

#define USE_CUSTOM_STEAMID -1

/**
 * Called after SteamTools has completely finished loading. 
 * No features are available before this point.
 *
 * @noreturn
 */
forward Steam_FullyLoaded();
forward Steam_Shutdown();


/**
 * Gets the current status of VAC on the server.
 *
 * @return A bool representing the current VAC status.
 */
native bool:Steam_IsVACEnabled();

/**
 * Gets the server's external IP address, as reported by Steam.
 *
 * @param octets Reference to an array to be filled with the octets of 
 *               the IP address.
 * 
 * @noreturn
 */
native Steam_GetPublicIP(octets[4]);


/**
 * Is fired when the Steam master servers report that your server is 
 * outdated
 *
 * @return Plugin_Continue to continue normal operation or Plugin_Handled 
 *         to block the regular console message.
 */
forward Action:Steam_RestartRequested();


/**
 * Requests a client's status in a Steam group.
 * Response is returned in Steam_GroupStatusResult forward.
 *
 * @param client         Client index.
 * @param groupAccountID 32-bit account ID of group.
 *
 * @return A bool representing whether or not the request was sent to 
 *         Steam.
 */
native bool:Steam_RequestGroupStatus(client, groupAccountID);

/**
 * Called when a response to a group status request is recieved.
 * This is called for all responses recieved, not just ones requested by 
 * your plugin.
 *
 * @param client         Client index.
 * @param groupAccountID 32-bit account ID of group. Make sure to check 
 *                       this agaist the ID you are expecting.
 * @param groupMember    Whether or not the client is a member in the 
 *                       specified group.
 * @param groupMember    Whether or not the client is an officer in the 
 *                       specified group.
 *
 * @noreturn
 */
forward Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer);

#pragma deprecated No longer operational
native Steam_RequestGameplayStats();
forward Steam_GameplayStats(rank, totalConnects, totalMinutesPlayed);


native Steam_RequestServerReputation();
forward Steam_Reputation(reputationScore, bool:banned, bannedIP, bannedPort, bannedGameID, banExpires);


/**
 * Gets the current Steam connection state, the forwards below fire 
 * whenever this changes.
 *
 * @return Steam connection state.
 */
native bool:Steam_IsConnected();

/**
 * Fired upon a successfull connection to Steam.
 * Is also fired for late-loaded plugins.
 *
 * @noreturn
 */
forward Steam_SteamServersConnected();

/**
 * Fired upon disconnection from Steam.
 * Is also fired for late-loaded plugins.
 *
 * For plugins loaded with the server, this will normally be fired right
 * after Steam_FullyLoaded, closly followed by Steam_SteamServersConnected 
 * if a successfull connection is established.
 *
 * @noreturn
 */
forward Steam_SteamServersDisconnected();

/**
 * Sets an entry in the server's list of rules. This list is used to 
 * build the response to the A2S_RULES query and is generally known as 
 * the list of public convars.
 *
 * @param key   Name of the key to set, is created if it does not already
 *              exist.
 * @param value Value of the key to set, the named key is removed if this 
 *              is blank.
 *
 * @noreturn
 */
native Steam_SetRule(const String:key[], const String:value[]);

/**
 * Clears the server's list of rules. This list is used to build the 
 * response to the A2S_RULES query and is generally known as the list of 
 * public convars.
 *
 * @noreturn
 */
native Steam_ClearRules();


native Steam_ForceHeartbeat();

#pragma deprecated No longer operational
native bool:Steam_AddMasterServer(const String:serverAddress[]);
#pragma deprecated No longer operational
native bool:Steam_RemoveMasterServer(const String:serverAddress[]);
#pragma deprecated No longer operational
native Steam_GetNumMasterServers();
#pragma deprecated No longer operational
native Steam_GetMasterServerAddress(server, String:serverAddress[], maxlength);

native Steam_SetGameDescription(String:gameDescription[]);

native Steam_RequestStats(client);
forward Steam_StatsReceived(client);
forward Steam_StatsUnloaded(client);
native Steam_GetStat(client, const String:statName[]);
native Float:Steam_GetStatFloat(client, const String:statName[]);
native bool:Steam_IsAchieved(client, const String:achievementName[]);


native Steam_GetNumClientSubscriptions(client);
native Steam_GetClientSubscription(client, index);

native Steam_GetNumClientDLCs(client);
native Steam_GetClientDLC(client, index);

stock bool:Steam_CheckClientSubscription(client, subid)
{
	new subCount = Steam_GetNumClientSubscriptions(client);
	for (new x = 0; x < subCount; x++)
	{
		if (Steam_GetClientSubscription(client, x) == subid)
		{
			return true;
		}
	}

	return false;
}

stock bool:Steam_CheckClientDLC(client, appid)
{
	new subCount = Steam_GetNumClientDLCs(client);
	for (new x = 0; x < subCount; x++)
	{
		if (Steam_GetClientDLC(client, x) == appid)
		{
			return true;
		}
	}

	return false;
}

native Steam_GetCSteamIDForClient(client, String:steamID[], maxlength);

native bool:Steam_SetCustomSteamID(const String:renderedID[]);
native bool:Steam_GetCustomSteamID(String:renderedID[], maxlength);

native Steam_RenderedIDToCSteamID(const String:renderedID[], String:steamID[], maxlength);
native Steam_CSteamIDToRenderedID(const String:steamID[], String:renderedID[], maxlength);

native Steam_GroupIDToCSteamID(groupID, String:steamID[], maxlength);
native Steam_CSteamIDToGroupID(const String:steamID[]);

enum HTTPRequestHandle
{
	INVALID_HTTP_HANDLE = 0,
};

enum HTTPMethod
{
	HTTPMethod_Invalid = 0,
	HTTPMethod_GET,
	HTTPMethod_HEAD,
	HTTPMethod_POST,
};

enum HTTPStatusCode
{
	HTTPStatusCode_Invalid =						0,

	// Informational codes
	HTTPStatusCode_Continue =						100,
	HTTPStatusCode_SwitchingProtocols =				101,

	// Success codes
	HTTPStatusCode_OK =								200,
	HTTPStatusCode_Created =						201,
	HTTPStatusCode_Accepted =						202,
	HTTPStatusCode_NonAuthoritative =				203,
	HTTPStatusCode_NoContent =						204,
	HTTPStatusCode_ResetContent =					205,
	HTTPStatusCode_PartialContent =					206,

	// Redirection codes
	HTTPStatusCode_MultipleChoices =				300,
	HTTPStatusCode_MovedPermanently =				301,
	HTTPStatusCode_Found =							302,
	HTTPStatusCode_SeeOther =						303,
	HTTPStatusCode_NotModified =					304,
	HTTPStatusCode_UseProxy =						305,
	HTTPStatusCode_TemporaryRedirect =				307,

	// Error codes
	HTTPStatusCode_BadRequest =						400,
	HTTPStatusCode_Unauthorized =					401,
	HTTPStatusCode_PaymentRequired =				402,
	HTTPStatusCode_Forbidden =						403,
	HTTPStatusCode_NotFound =						404,
	HTTPStatusCode_MethodNotAllowed =				405,
	HTTPStatusCode_NotAcceptable =					406,
	HTTPStatusCode_ProxyAuthRequired =				407,
	HTTPStatusCode_RequestTimeout =					408,
	HTTPStatusCode_Conflict =						409,
	HTTPStatusCode_Gone =							410,
	HTTPStatusCode_LengthRequired =					411,
	HTTPStatusCode_PreconditionFailed =				412,
	HTTPStatusCode_RequestEntityTooLarge =			413,
	HTTPStatusCode_RequestURITooLong =				414,
	HTTPStatusCode_UnsupportedMediaType =			415,
	HTTPStatusCode_RequestedRangeNotSatisfiable =	416,
	HTTPStatusCode_ExpectationFailed =				417,
	
	// Server error codes
	HTTPStatusCode_InternalServerError =			500,
	HTTPStatusCode_NotImplemented =					501,
	HTTPStatusCode_BadGateway =						502,
	HTTPStatusCode_ServiceUnavailable =				503,
	HTTPStatusCode_GatewayTimeout =					504,
	HTTPStatusCode_HTTPVersionNotSupported =		505,
};

funcenum HTTPRequestComplete
{
	public(HTTPRequestHandle:HTTPRequest, bool:requestSuccessful, HTTPStatusCode:statusCode),
	public(HTTPRequestHandle:HTTPRequest, bool:requestSuccessful, HTTPStatusCode:statusCode, any:contextData),
};

native HTTPRequestHandle:Steam_CreateHTTPRequest(HTTPMethod:HTTPRequestMethod, const String:absoluteURL[]);
native Steam_SetHTTPRequestNetworkActivityTimeout(HTTPRequestHandle:HTTPRequest, timeoutSeconds);
native Steam_SetHTTPRequestHeaderValue(HTTPRequestHandle:HTTPRequest, const String:headerName[], const String:headerValue[]);
native Steam_SetHTTPRequestGetOrPostParameter(HTTPRequestHandle:HTTPRequest, const String:paramName[], const String:paramValue[]);
native bool:Steam_SendHTTPRequest(HTTPRequestHandle:HTTPRequest, HTTPRequestComplete:callbackFunction, any:contextData = 0);
native Steam_DeferHTTPRequest(HTTPRequestHandle:HTTPRequest);
native Steam_PrioritizeHTTPRequest(HTTPRequestHandle:HTTPRequest);
native Steam_GetHTTPResponseHeaderSize(HTTPRequestHandle:HTTPRequest, const String:headerName[]);
native Steam_GetHTTPResponseHeaderValue(HTTPRequestHandle:HTTPRequest, const String:headerName[], String:headerValueBuffer[], bufferSize);
native Steam_GetHTTPResponseBodySize(HTTPRequestHandle:HTTPRequest);
native Steam_GetHTTPResponseBodyData(HTTPRequestHandle:HTTPRequest, String:bodyDataBuffer[], bufferSize);
native Steam_WriteHTTPResponseBody(HTTPRequestHandle:HTTPRequest, const String:filePath[]);
native Steam_ReleaseHTTPRequest(HTTPRequestHandle:HTTPRequest);
native Float:Steam_GetHTTPDownloadProgressPercent(HTTPRequestHandle:HTTPRequest);

public Extension:__ext_SteamTools = 
{
	name = "SteamTools",
	file = "steamtools.ext",
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
}
