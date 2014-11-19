/* 
	------------------------------------------------------------------------------------------
	EntControl::Natives
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public RegisterNatives()
{
	CreateNative("EC_NPC_Spawn", Native_NPC_Spawn);
}

public Native_NPC_Spawn(Handle:plugin, numParams)
{
	new Float:position[3];
	new npcNameLength;
	
	// Get the npc-name
	GetNativeStringLength(1, npcNameLength);
	if (npcNameLength > 0)
	{
		new String:npcName[npcNameLength + 1];
		GetNativeString(1, npcName, npcNameLength + 1);
		
		// Get the npc-position
		position[0] = Float:GetNativeCell(2);
		position[1] = Float:GetNativeCell(3);
		position[2] = Float:GetNativeCell(4);
		
		// Try to spawn the npc
		BaseNPC_SpawnByName(npcName, position);
	}
}