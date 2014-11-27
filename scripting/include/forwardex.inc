#if defined __forwardex_included_
 #endinput
#endif
#define __forwardex_included_

#define __forwardex_version_ "1.0.1"

enum Forward
{
	INVALID_FORWARD = -1,
};

enum ForwardId
{
	INVALID_FORWARD_ID = -1,
};

static Handle:g_hFwdExFwdListArray = INVALID_HANDLE;

stock FwdEx_Init()
{
	___startHandle();
}

stock FwdEx_End()
{
	___destroytHandle();
}

stock Forward:FwdEx_CreateForward()
{
	new Handle:array = CreateArray();

	return Forward:PushArrayCell(g_hFwdExFwdListArray, array);
}

stock FwdEx_DestroyForward(Forward:fwd)
{
	new Handle:array = GetArrayCell(g_hFwdExFwdListArray, _:fwd);
	if (array != INVALID_HANDLE)
	{
		new size = GetArraySize(array);
		for (new x = 0; x < size; x++)
		{
			new Handle:pack = GetArrayCell(g_hFwdExFwdListArray, x);
			CloseHandle(pack);
		}
		CloseHandle(array);
	}
	SetArrayCell(g_hFwdExFwdListArray, _:fwd, INVALID_HANDLE);
}

stock ForwardId:FwdEx_AddToForward(Forward:fwd, Handle:plugin, Function:func)
{
	new Handle:array = Handle:GetArrayCell(g_hFwdExFwdListArray, _:fwd);

	new Handle:pack = CreateDataPack();
	WritePackCell(pack, _:plugin);
	WritePackCell(pack, _:func);
	return ForwardId:PushArrayCell(array, pack);
}

stock FwdEx_RemoveFromForward(Forward:fwd, Handle:plugin, Function:func)
{
	new Handle:array = GetArrayCell(g_hFwdExFwdListArray, _:fwd);
	
	new size = GetArraySize(array);
	for (new i = 0; i < size; i++)
	{
		new Handle:pack = GetArrayCell(array, i);
		ResetPack(pack);

		new Handle:pl = Handle:ReadPackCell(pack);
		new Function:function = Function:ReadPackCell(pack);

		if (pl == plugin && function == func)
		{
			CloseHandle(pack);
			RemoveFromArray(array, i);
		}
	}
}

stock FwdEx_RemoveIdFromForward(Forward:fwd, ForwardId:id)
{
	new Handle:array = GetArrayCell(g_hFwdExFwdListArray, _:fwd);
	new Handle:pack = GetArrayCell(array, _:id);
	CloseHandle(pack);

	RemoveFromArray(array, _:id);
}

stock FwdEx_GetFwdCount(Forward:fwd)
{
	return GetArraySize(GetArrayCell(g_hFwdExFwdListArray, _:fwd));
}

stock Call_StartPrivateForward(Forward:fwd, ForwardId:id)
{
	new Handle:array = GetArrayCell(g_hFwdExFwdListArray, _:fwd);

	new Handle:pack = GetArrayCell(array, _:id);
	ResetPack(pack);
	new Handle:plugin = Handle:ReadPackCell(pack);
	new Function:func = Function:ReadPackCell(pack);
	Call_StartFunction(plugin, func);
}

static ___startHandle()
{
	if (g_hFwdExFwdListArray != INVALID_HANDLE)
	{
		CloseHandle(g_hFwdExFwdListArray);
	}
	g_hFwdExFwdListArray = CreateArray();
}

static ___destroytHandle()
{
	if (g_hFwdExFwdListArray != INVALID_HANDLE)
	{
		new size = GetArraySize(g_hFwdExFwdListArray), aSize;
		new Handle:array, Handle:pack;
		for (new i = 0; i < size; i++)
		{
			array = GetArrayCell(g_hFwdExFwdListArray, i);
			if (array != INVALID_HANDLE)
			{
				aSize = GetArraySize(array);
				for (new x = 0; x < aSize; x++)
				{
					pack = GetArrayCell(g_hFwdExFwdListArray, x);
					CloseHandle(pack);
				}
				CloseHandle(array);
			}
		}
		CloseHandle(g_hFwdExFwdListArray);
		g_hFwdExFwdListArray = INVALID_HANDLE;
	}
}