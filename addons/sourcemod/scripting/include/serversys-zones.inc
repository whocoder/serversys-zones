#if defined _serversys_zones_included
  #endinput
#endif
#define _serversys_zones_included


#define MAX_ZONE_TYPES 30
#define MAX_ZONES 64

enum Zones_SetupState {
	SETUP_NONE = 0,
	SETUP_MAIN = 1,
	SETUP_ADD_SELECT_TYPE = 2,
	SETUP_ADD_SELECT_METHOD = 3,
	SETUP_ADD_LISTENING_TRIGGER = 4,
	SETUP_ADD_CREATING_ZONE = 5,
	SETUP_ADD_LISTENING_NAME = 6,
	SETUP_ADD_LISTENING_VISIBLE = 7,
	SETUP_ADD_LISTENING_WIDTH = 8,
	SETUP_DIS_SELECT_ZONE = 9,
	SETUP_DIS_SELECT_ACTION = 10
}

/**
* Register your zone type for use in the plugin.
*
* @param type			The string identifier for the zone's type.
* @param entity 		Optional entity type to use. For entities that trigger
*						the plugin's forwards, use trigger_multiple or leave it blank. If you
* 						wanted to create a wall with a zone, you could use prop_dynamic.
*/
native void Sys_Zones_RegisterZoneType(const char[] type, const char[] entity = "trigger_multiple");

/**
* Check if zones are currently in a loading state or totally useable.
*/
native bool Sys_Zones_Loading();

/**
* Get the setup state of a client index.
*
* @param client         The client index to retrieve for.
*/
native Zones_SetupState Sys_Zones_GetSetupState(int client);

/**
* Called when a zone entity is created. For CS:GO, this is on round_start.
*   Return Plugin_Stop to prevent us from tracking this entity
*   (you can do what you please with it then), or Plugin_Handled to
*   prevent us from hooking its touches.
*
* @param type			The string identifier for the zone's type.
* @param zone			The entity index for the entity.
*/
forward Action OnZoneCreated(const char[] type, int zone);

/**
* Called when SDKHook_StartTouch is called.
*
* @param entity			The entity that touched the zone.
* @param zone			The entity index of the zone.
* @param type			The string identifier for the zone's type.
*/
forward Action OnZoneStartTouch(int entity, int zone, const char[] type);

/**
* Called when SDKHook_Touch is called.
*
* @param entity			The entity that touched the zone.
* @param zone			The entity index of the zone.
* @param type			The string identifier for the zone's type.
*/
forward Action OnZoneTouch(int entity, int zone, const char[] type);

/**
* Called when SDKHook_EndTouch is called.
*
* @param entity			The entity that touched the zone.
* @param zone			The entity index of the zone.
* @param type			The string identifier for the zone's type.
*/
forward Action OnZoneEndTouch(int entity, int zone, const char[] type);

public SharedPlugin __pl_serversys_zones =
{
	name = "serversys-zones",
	file = "serversys-zones.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if defined REQUIRE_PLUGIN
public __pl_serversys_zones_SetNTVOptional(){
    MarkNativeAsOptional("Sys_Zones_RegisterZoneType");
    MarkNativeAsOptional("Sys_Zones_GetSetupState");
}
#endif
