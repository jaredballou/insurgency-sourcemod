### Navmesh Chat (version 0.0.1)
Puts navmesh area into chat

[Plugin](plugins/navmesh-chat.smx?raw=true) - [Source](scripting/navmesh-chat.sp)

Adds prefix to all chat messages (selectable team or all) that includes grid coordinates, area name (if named in navmesh). For radio commands, it adds those and also a distance and direction related to the player. This plugin is currently complex in that it relies on parsing the map overview data from the Data repository existing in the Insurgency game root directory, cloned to insurgency-data. This has a lot of work to do, especially in getting the overview data from the engine directly rather than hacking around it. This is still very much under active development and could blow up your server, but I'd appreciate testing and feedback.

#### Dependencies
 * [translations/insurgency.phrases.txt](translations/insurgency.phrases.txt&raw=true)

#### CVAR List
 * sm_navmesh_chat_enabled: sets whether this plugin is enabled (default: 1)
 * sm_navmesh_chat_teamonly: sets whether to prepend to all messages or just team messages (default: 1)
 * sm_navmesh_chat_grid: Include grid coordinates (default: 1)
 * sm_navmesh_chat_place: Include place name from navmesh (default: 1)
 * sm_navmesh_chat_distance: Include distance to speaker (default: 1)
 * sm_navmesh_chat_direction: Include direction to speaker (default: 1)

#### Todo
 * [ ] Get grid/overlay data from engine directly
 * [X] Create CVARs to decide if prefix is attached to all chat, team only, or just admins
 * [X] Put grid in front of all chat messages
 * [ ] Put grid, distance, and direction with radio voice commands
 * [ ] Add in-game markers for wider array of tasks
 * [ ] Add support for commands that target location other than player's current position (i.e. "grenade over there")
 * [ ] Replace spotting box with callout of distance/direction, add map marker


