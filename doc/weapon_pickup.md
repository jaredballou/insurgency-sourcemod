<a name="weapon_pickup">
### [INS] Weapon Pickup 0.1.0

Weapon Pickup logic for manipulating player inventory
 * [Source - scripting/weapon_pickup.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/weapon_pickup.sp?raw=true)
 * [Plugin - plugins/weapon_pickup.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/weapon_pickup.smx?raw=true)

#### Dependencies

 * [Source - scripting/include/smlib.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/smlib.inc?raw=true)
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Plugin - gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)
 * [Plugin - gamedata/sdkhooks.games/engine.insurgency.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/sdkhooks.games/engine.insurgency.txt?raw=true)

#### CVAR List

 * "sm_weapon_pickup_ammo" "1" // sets whether picking up a weapon the player already has will add to the player's ammo count
 * "sm_weapon_pickup_max_explosive" "3" // Maximum number of ammo that can be carried for explosives
 * "sm_weapon_pickup_enabled" "PLUGIN_WORKING" // sets whether weapon pickup manipulation is enabled
 * "sm_weapon_pickup_max_magazine" "12" // Maximum number of magazines that can be carried

#### Command List

 * "wp_weaponlist" // Lists all weapons. Usage: wp_weaponlist [target]
 * "wp_weaponslots" // Lists weapon slots. Usage: wp_weaponslots [target]
 * "wp_removeweapons" // Removes all weapons. Usage: wp_removeweapons [target]

