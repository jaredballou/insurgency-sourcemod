/* 
	------------------------------------------------------------------------------------------
	EntControl::Rocket
	by Raffael 'LeGone' Holz
	------------------------------------------------------------------------------------------

	------------------------------------------------------------------------------------------
	Fixed_Rocket_Spawn
	------------------------------------------------------------------------------------------
*/
public Fixed_Rocket_Spawn(client)
{
	new Float:vAimPos[3];
	if (GetPlayerEye(client, vAimPos))
		Fixed_Base_Spawn(client, Fixed_Rocket_OnTrigger, vAimPos);
}

/* 
	------------------------------------------------------------------------------------------
	Fixed_Rocket_Fire
	------------------------------------------------------------------------------------------
*/
public Fixed_Rocket_Fire(gun, client, target, Float:vGunPos[3], Float:vAimPos[3], Float:vAngle[3])
{
	Projectile(true, client, vGunPos, vAngle, "models/weapons/w_missile_launch.mdl", gRocketSpeed, gRocketDamage, "weapons/rpg/rocketfire1.wav", true);
}

public Fixed_Rocket_OnTrigger(const String:output[], caller, activator, Float:delay)
{
	if(activator > 0 && activator <= MaxClients)
	{
		decl String:tmp[32];
		GetEntPropString(caller, Prop_Data, "m_iName", tmp, sizeof(tmp));
		Fixed_Base_Think(StringToInt(tmp), activator, Fixed_Rocket_Fire);
	}
}