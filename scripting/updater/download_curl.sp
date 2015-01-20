
/* Extension Helper - cURL */

Download_cURL(const String:url[], const String:dest[])
{
	decl String:sURL[MAX_URL_LENGTH];
	PrefixURL(sURL, sizeof(sURL), url);
	
	new Handle:hFile = curl_OpenFile(dest, "wb");
	
	if (hFile == INVALID_HANDLE)
	{
		decl String:sError[256];
		FormatEx(sError, sizeof(sError), "Error writing to file: %s", dest);
		DownloadEnded(false, sError);
		return;
	}
	
	new CURL_Default_opt[][2] = {
		{_:CURLOPT_NOSIGNAL,		1},
		{_:CURLOPT_NOPROGRESS,		1},
		{_:CURLOPT_TIMEOUT,			30},
		{_:CURLOPT_CONNECTTIMEOUT,	60},
		{_:CURLOPT_VERBOSE,			0}
	};
	
	new Handle:headers = curl_slist();
	curl_slist_append(headers, "Pragma: no-cache");
	curl_slist_append(headers, "Cache-Control: no-cache");
	
	new Handle:hDLPack = CreateDataPack();
	WritePackCell(hDLPack, _:hFile);
	WritePackCell(hDLPack, _:headers);
	
	new Handle:curl = curl_easy_init();
	curl_easy_setopt_int_array(curl, CURL_Default_opt, sizeof(CURL_Default_opt));
	curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, hFile);
	curl_easy_setopt_string(curl, CURLOPT_URL, url);
	curl_easy_setopt_handle(curl, CURLOPT_HTTPHEADER, headers);
	curl_easy_perform_thread(curl, OnCurlComplete, hDLPack);
}

public OnCurlComplete(Handle:curl, CURLcode:code, any:hDLPack)
{
	ResetPack(hDLPack);
	CloseHandle(Handle:ReadPackCell(hDLPack));	// hFile
	CloseHandle(Handle:ReadPackCell(hDLPack));	// headers
	CloseHandle(hDLPack);
	CloseHandle(curl);
	
	if(code == CURLE_OK)
	{
		DownloadEnded(true);
	}
	else
	{
		decl String:sError[256];
		curl_easy_strerror(code, sError, sizeof(sError));
		Format(sError, sizeof(sError), "cURL error: %s", sError);
		DownloadEnded(false, sError);
	}
}
