/* 
	------------------------------------------------------------------------------------------
	EntControl::Plasma
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------

	------------------------------------------------------------------------------------------
	Fixed_Plasma_Spawn
	------------------------------------------------------------------------------------------
*/
public Fixed_Plasma_Spawn(client)
{
	new Float:vAimPos[3];
	if (GetPlayerEye(client, vAimPos))
		Fixed_Base_Spawn(client, Fixed_Plasma_OnTrigger, vAimPos);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_Plasma_Fire
	------------------------------------------------------------------------------------------
*/
public Fixed_Plasma_Fire(gun, client, target, Float:vGunPos[3], Float:vAimPos[3], Float:vAngle[3])
{
	Projectile(true, client, vGunPos, vAngle, "models/Effects/combineball.mdl", gPlasmaSpeed, gPlasmaDamage, "weapons/Irifle/irifle_fire2.wav", true, Float:{0.4, 1.0, 1.0});
}

public Fixed_Plasma_OnTrigger(const String:output[], caller, activator, Float:delay)
{
	if(activator > 0 && activator <= MaxClients)
	{
		decl String:tmp[32];
		GetEntPropString(caller, Prop_Data, "m_iName", tmp, sizeof(tmp));
		Fixed_Base_Think(StringToInt(tmp), activator, Fixed_Plasma_Fire);
	}
}