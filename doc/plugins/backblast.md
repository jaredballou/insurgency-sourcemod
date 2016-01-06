<a name='backblast'>
---
### Backblast 0.0.2</a>
Adds backblast to rocket based weapons

 * [Plugin - backblast.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/backblast.smx?raw=true)
 * [Source - backblast.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/backblast.sp?raw=true)

Adds backblast to AT4 and RPG. Still in progress, this is not yet fully functional.

#### CVAR List
 * "sm_backblast_enabled" "1" //sets whether bot naming is enabled
 * "sm_backblast_damage" "80" //Max damage from backblast
 * "sm_backblast_damage_range" "15" //Distance in meters from firing to hurt players in backblast
 * "sm_backblast_max_range" "25" //Max range for backblast to affect players visually
 * "sm_backblast_cone_angle" "90" //Angle behind firing to include in backblast effect
 * "sm_backblast_wall_distance" "5" //Distance in meters to wall where player firing will hurt himself

#### Todo
 * [X] Add CVARs to control cone angle, kill range, and total effect range
 * [ ] Use flashbang effect as standin for non-lethal backblast
 * [X] Add CVAR for wall proximity, hurt or kill player if too close to a wall behind them
 * [ ] On weapon fire for AT4/RPG, get all clients in a radius, determine angle, and apply damage or effect accordingly

