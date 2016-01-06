<a name='looting'>
---
### Looting 0.0.1</a>
Adds ability to loot items from dead bodies

 * [Plugin - looting.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/looting.smx?raw=true)
 * [Source - looting.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/looting.sp?raw=true)

Allows looting bodies for ammo. Not yet functional.

#### CVAR List
 * "sm_looting_enabled" "1" //sets whether looting is enabled
 * "sm_looting_mode" "1" //sets looting mode - 0: Loot per mag, 1: Loot all ammo

#### Todo
 * [ ] On player death, copy ammo array to ragdoll.
 * [ ] On command execute, pull ammo from ragdoll and add to current player.
 * [ ] Create CVAR to determine if one looting action gets all ammo, or per magazine.
 * [ ] Create functionality when standing over player to either have a "search" command, or just tell the player if he stands over a ragdoll for X seconds.
 * [ ] Add feature to drop weapons, and ammo.
 * [ ] Get model for magazines for dropped mags.
 * [ ] Add CVAR option to simply drop ammo box or all magazines on death (like a munitions pinata).

