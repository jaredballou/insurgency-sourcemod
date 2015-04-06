### Backblast (version 0.0.2)
Adds backblast to rocket based weapons

[Plugin](plugins/backblast.smx?raw=true) - [Source](scripting/backblast.sp)

Adds backblast to AT4 and RPG. Still in progress, this is not yet fully functional.

#### CVAR List
 * sm_backblast_enabled: sets whether bot naming is enabled (default: 1)
 * sm_backblast_damage: Max damage from backblast (default: 80)
 * sm_backblast_damage_range: Distance in meters from firing to hurt players in backblast (default: 15)
 * sm_backblast_max_range: Max range for backblast to affect players visually (default: 25)
 * sm_backblast_cone_angle: Angle behind firing to include in backblast effect (default: 90)
 * sm_backblast_wall_distance: Distance in meters to wall where player firing will hurt himself (default: 5)

#### Todo
 * [X] Add CVARs to control cone angle, kill range, and total effect range
 * [X] Use flashbang effect as standin for non-lethal backblast
 * [X] Add CVAR for wall proximity, hurt or kill player if too close to a wall behind them
 * [X] On weapon fire for AT4/RPG, get all clients in a radius, determine angle, and apply damage or effect accordingly

