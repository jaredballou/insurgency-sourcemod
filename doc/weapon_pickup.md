### weapon_pickup
'''[INS] Weapon Pickup 0.1.0'''

Weapon Pickup logic for manipulating player inventory

 * [Source - scripting/weapon_pickup.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/weapon_pickup.sp?raw=true)
 * [Plugin - plugins/weapon_pickup.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/weapon_pickup.smx?raw=true)

#### Dependencies
 * [Source - scripting/include/smlib.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/smlib.inc?raw=true)
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Plugin - gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)
 * [Plugin - gamedata/sdkhooks.games/engine.insurgency.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/sdkhooks.games/engine.insurgency.txt?raw=true)
#### CVAR List
 * "sm_weapon_pickup_max_magazine" "12" // $data['description']
 * "sm_weapon_pickup_ammo" "1" // $data['description']
 * "sm_weapon_pickup_version" "PLUGIN_VERSION" // $data['description']
 * "sm_weapon_pickup_enabled" "PLUGIN_WORKING" // $data['description']
 * "sm_weapon_pickup_max_explosive" "3" // $data['description']
#### Command List
 * "wp_weaponlist" // $data['description']
 * "wp_weaponslots" // $data['description']
 * "wp_removeweapons" // $data['description']
