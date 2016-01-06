<a name='hlstatsx'>
---
### HLstatsX CE Ingame Plugin 1.6.19</a>
Provides ingame functionality for interaction from an HLstatsX CE installation

 * [Plugin - hlstatsx.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/hlstatsx.smx?raw=true)
 * [Source - hlstatsx.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/hlstatsx.sp?raw=true)

Adds in-game support for HLStatsX servers to connect and send messages and other tasks. Adds color support, and a number of other features absent from the HLStatsX upstream version. Release ready, no known bugs.

#### Dependencies
 * [Third-Party Plugin: clientprefs](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/clientprefs.smx?raw=true)

#### CVAR List
 * "hlxce_webpage" "http://www.hlxcommunity.com" //http://www.hlxcommunity.com
 * "hlx_block_commands" "1" //If activated HLstatsX commands are blocked from the chat area
 * "hlx_message_prefix" "" //Define the prefix displayed on every HLstatsX ingame message
 * "hlx_protect_address" "" //Address to be protected for logging/forwarding
 * "hlx_server_tag" "1" //If enabled, adds \HLstatsX:CE\ to server tags on supported games. 1 = Enabled

