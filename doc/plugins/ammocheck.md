### Ammo Check (version 0.0.6)
Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine

[Plugin](plugins/ammocheck.smx?raw=true) - [Source](scripting/ammocheck.sp)

Adds check_ammo command that client runs and gets RO2-style "Mag feels mostly full" estimation of remaining ammo. Reloading will also pop this up to alert player if they have inserted a magazine that is less than full. Future features I'd like to do are to show a reload animation partially to animate the check, and have the check command delay the next weapon attack to simulate removing and checking the magazine. Due to the way the theater system works, it's not practical to hard-code weapon data like magazine capacity in the plugin as similar CS and TF2 plugins do, so I have a hacky method that checks the 'm_iClip' variable and uses that to perform the math. There are other workarounds and todos in the source code as well. Release candidate, no obvious bugs, but still needs a lot of polish.

#### CVAR List
 * "sm_ammocheck_enabled" "1" //sets whether ammo check is enabled

