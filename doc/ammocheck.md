<a name="ammocheck">
### Ammo Check 1.0.2

Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine
 * [Source - scripting/ammocheck.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/ammocheck.sp?raw=true)
 * [Plugin - plugins/ammocheck.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/ammocheck.smx?raw=true)

#### Dependencies

 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List

 * "sm_ammocheck_attack_delay" "1" // Delay in seconds until next attack when checking ammo
 * "sm_ammocheck_enabled" "1" // sets whether ammo check is enabled

#### Command List

 * "check_ammo" // Check ammo of the current weapon

