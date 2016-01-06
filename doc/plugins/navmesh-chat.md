<a name='navmesh-chat'>
---
### Navmesh Chat 0.0.1</a>
Puts navmesh area into chat

 * [Plugin - navmesh-chat.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/navmesh-chat.smx?raw=true)
 * [Source - navmesh-chat.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/navmesh-chat.sp?raw=true)

Adds prefix to all chat messages (selectable team or all) that includes grid coordinates, area name (if named in navmesh). For radio commands, it adds those and also a distance and direction related to the player. This plugin is currently complex in that it relies on parsing the map overview data from the Data repository existing in the Insurgency game root directory, cloned to insurgency-data. This has a lot of work to do, especially in getting the overview data from the engine directly rather than hacking around it. This is still very much under active development and could blow up your server, but I'd appreciate testing and feedback.

#### Dependencies
 * [Source Include - navmesh.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/navmesh.inc?raw=true)
 * [translations/insurgency.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/insurgency.phrases.txt?raw=true)

#### CVAR List
 * "sm_navmesh_chat_enabled" "1" //sets whether this plugin is enabled
 * "sm_navmesh_chat_teamonly" "1" //sets whether to prepend to all messages or just team messages
 * "sm_navmesh_chat_grid" "1" //Include grid coordinates
 * "sm_navmesh_chat_place" "1" //Include place name from navmesh
 * "sm_navmesh_chat_distance" "1" //Include distance to speaker
 * "sm_navmesh_chat_direction" "1" //Include direction to speaker

#### Todo
 * [ ] Get grid/overlay data from engine directly
 * [X] Create CVARs to decide if prefix is attached to all chat, team only, or just admins
 * [X] Put grid in front of all chat messages
 * [ ] Put grid, distance, and direction with radio voice commands
 * [ ] Add in-game markers for wider array of tasks
 * [ ] Add support for commands that target location other than player's current position (i.e. "grenade over there")
 * [ ] Replace spotting box with callout of distance/direction, add map marker


