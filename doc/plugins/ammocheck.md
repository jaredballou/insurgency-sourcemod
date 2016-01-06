<a name='ammocheck'>
---
### Ammo Check 0.0.7</a>
Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine

 * [Plugin - ammocheck.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/ammocheck.smx?raw=true)
 * [Source - ammocheck.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/ammocheck.sp?raw=true)

Adds check_ammo command that client runs and gets RO2-style "Mag feels mostly full" estimation of remaining ammo. Reloading will also pop this up to alert player if they have inserted a magazine that is less than full. There are other workarounds and todos in the source code as well. Release candidate, no obvious bugs, but still needs a lot of polish.

#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_ammocheck_enabled" "1" //sets whether ammo check is enabled

#### Todo
 * [ ] Add client-side config on enable, display location, and to show after mag change
 * [ ] Show a reload animation partially to animate the check
 * [ ] Have the check command delay the next weapon attack to simulate removing and checking the magazine.

