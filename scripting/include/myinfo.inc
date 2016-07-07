#if !defined PLUGIN_AUTHOR
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#endif
#if !defined PLUGIN_DESCRIPTION
#define PLUGIN_DESCRIPTION "New Plugin"
#endif
#if !defined PLUGIN_NAME
#define PLUGIN_NAME "[INS] New Plugin"
#endif
#if !defined PLUGIN_URL
#define PLUGIN_URL "http://jballou.com/insurgency"
#endif
#if !defined PLUGIN_VERSION
#define PLUGIN_VERSION "0.0.1"
#endif
#if !defined PLUGIN_WORKING
#define PLUGIN_WORKING "0"
#endif
#if !defined PLUGIN_LOG_PREFIX
#define PLUGIN_LOG_PREFIX "INS"
#endif
#if !defined PLUGIN_FILE
#define PLUGIN_FILE "newplugin"
#endif
#if !defined UPDATE_URL
#define UPDATE_URL_FORMAT(%1)    "http://ins.jballou.com/sourcemod/update-%1.txt"
#define UPDATE_URL UPDATE_URL_FORMAT(PLUGIN_FILE)
#endif

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};
