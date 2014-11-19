/* 
	------------------------------------------------------------------------------------------
	EntControl::MG
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------
*/

public InitFixedMG()
{
	PrecacheModel("models/Shells/shell_762nato.mdl");
	
	PrecacheSound("weapons/smg1/smg1_fire1.wav");
	PrecacheSound("player/pl_shell2.wav");
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_MG_Spawn
	------------------------------------------------------------------------------------------
*/
public Fixed_MG_Spawn(client)
{
	new Float:vAimPos[3];
	if (GetPlayerEye(client, vAimPos))
		Fixed_Base_Spawn(client, Fixed_MG_OnTrigger, vAimPos);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_MG_Fire
	------------------------------------------------------------------------------------------
*/
public Fixed_MG_Fire(gun, client, target, Float:vGunPos[3], Float:vAimPos[3], Float:vAngle[3])
{
	if (target)
		MakeDamage(client, target, 25, DMG_BULLET, 1.0, vGunPos);
	
	new Float:fDirection[3] = {-90.0, 0.0, 0.0};
	env_shooter(fDirection, 1.0, 0.1, fDirection, 200.0, 120.0, 120.0, vGunPos, "models/Shells/shell_762nato.mdl");
	
	EmitSoundToAll("weapons/smg1/smg1_fire1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vGunPos);
	EmitSoundToAll("player/pl_shell2.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vGunPos);
}

public Fixed_MG_OnTrigger(const String:output[], caller, activator, Float:delay)
{
	if(activator > 0 && activator <= MaxClients)
	{
		decl String:tmp[32];
		GetEntPropString(caller, Prop_Data, "m_iName", tmp, sizeof(tmp));
		Fixed_Base_Think(StringToInt(tmp), activator, Fixed_MG_Fire);
	}
}