<a name='botcount'>
---
### Bot Counter 0.0.2</a>
Shows Bots Left Alive

 * [Plugin - botcount.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botcount.smx?raw=true)
 * [Source - botcount.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botcount.sp?raw=true)

Displays a popup to players every 60 seconds by default identifying remaining enemy players alive. Beginning of a "UAV" feature, my goal is to create an entity on the map that can be used to get this information rather than just spamming it. Release ready, no known bugs.

#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_botcount_enabled" "0" //sets whether bot naming is enabled
 * "sm_botcount_timer" "60" //Frequency to show count

