
/* Extension Helper - SteamTools */

Download_SteamTools(const String:url[], const String:dest[])
{
	decl String:sURL[MAX_URL_LENGTH];
	PrefixURL(sURL, sizeof(sURL), url);
	
	new Handle:hDLPack = CreateDataPack();
	WritePackString(hDLPack, dest);

	new HTTPRequestHandle:hRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, sURL);
	Steam_SetHTTPRequestHeaderValue(hRequest, "Pragma", "no-cache");
	Steam_SetHTTPRequestHeaderValue(hRequest, "Cache-Control", "no-cache");
	Steam_SendHTTPRequest(hRequest, OnSteamHTTPComplete, hDLPack);
}

public OnSteamHTTPComplete(HTTPRequestHandle:HTTPRequest, bool:requestSuccessful, HTTPStatusCode:statusCode, any:hDLPack)
{
	decl String:sDest[PLATFORM_MAX_PATH];
	ResetPack(hDLPack);
	ReadPackString(hDLPack, sDest, sizeof(sDest));
	CloseHandle(hDLPack);
	
	if (requestSuccessful && statusCode == HTTPStatusCode_OK)
	{
		Steam_WriteHTTPResponseBody(HTTPRequest, sDest);
		DownloadEnded(true);
	}
	else
	{
		decl String:sError[256];
		FormatEx(sError, sizeof(sError), "SteamTools error (status code %i). Request successful: %s", _:statusCode, requestSuccessful ? "True" : "False");
		DownloadEnded(false, sError);
	}
	
	Steam_ReleaseHTTPRequest(HTTPRequest);
}

/* Keep track of SteamTools load state. */
new bool:g_bSteamLoaded;

public Steam_FullyLoaded()
{
	g_bSteamLoaded = true;
}

public Steam_Shutdown()
{
	g_bSteamLoaded = false;
}
