#if defined _serversys_zones_included
  #endinput
#endif
#define _serversys_zones_included


#define MAX_ZONE_TYPES 30
#define MAX_ZONES 64

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
}
#endif
