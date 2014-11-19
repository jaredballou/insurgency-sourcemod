/* 
	------------------------------------------------------------------------------------------
	EntControl::World
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

stock World_TurnOffLights()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "light")) != INVALID_ENT_REFERENCE)
		if (IsValidEdict(entity) && IsValidEntity(entity))
			AcceptEntityInput(entity, "TurnOff");
}

stock World_TurnOnLights()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "light")) != INVALID_ENT_REFERENCE)
		if (IsValidEdict(entity) && IsValidEntity(entity))
			AcceptEntityInput(entity, "TurnOn");
}

stock World_EnableFog()
{
	new fog = -1;
	fog = FindEntityByClassname(fog, "env_fog_controller");
	
	if (fog != -1)
	{
		AcceptEntityInput(fog, "TurnOn");
	}
}

stock World_DisableFog()
{
	new fog = -1;
	fog = FindEntityByClassname(fog, "env_fog_controller");
	
	if (fog != -1)
	{
		AcceptEntityInput(fog, "TurnOff");
	}
}
