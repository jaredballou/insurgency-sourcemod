<a name='compass'>
---
### Compass 0.0.6</a>
Puts a compass in the game

 * [Plugin - compass.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/compass.smx?raw=true)
 * [Source - compass.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/compass.sp?raw=true)

Adds a check_compass command that clients can use and get their ordinal direction where they are looking in relation to where they stand. Like a compass. Release ready, no known bugs.

#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [translations/compass.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/compass.phrases.txt?raw=true)

#### CVAR List
 * "sm_compass_enabled" "1" //Enables compass
 * "sm_compass_direction" "1" //Display direction in ordinal directions
 * "sm_compass_bearing" "1" //Display bearing in degrees
 * "sm_compass_timer" "0" //If greater than 0, display compass to players every X seconds.
 * "sm_compass_default_enabled" "1" //Default compass
 * "sm_compass_default_timer" "60" //Default compass
 * "sm_compass_default_display" "1" //Default compass
 * "sm_compass_default_direction" "1" //Default compass
 * "sm_compass_default_bearing" "1" //Default compass

