#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <serversys>
#include <serversys-zones>

#pragma semicolon 1
#pragma newdecls required

// Select all zones
char g_cQuery_Select[] = "SELECT id, type, name, target, posx1, posy1, posz1, posx2, posy2, posz2 FROM zones WHERE map = %d;";
// Delete a zone
char g_cQuery_Remove[] = "DELETE FROM zones WHERE id = %d;";
// Insert a zone that's hooking a pre-made map entity
char g_cQuery_InsertMapZone[] = "INSERT INTO zones(map, type, name, target) VALUES(%d, '%s', '%s', '%s');";
// Insert a zone that's from a player-made rectangle
char g_cQuery_InsertOurZone[] = "INSERT INTO zones(map, type, name, posx1, posy1, posz1, posx2, posy2, posz2) VALUES(%d, '%s', '%s', %f, %f, %f, %f, %f, %f);";

bool LateLoaded = false;

int LoadAttempts = 0;

int g_iMapID = 0;
int g_iRoundIndex = 0;

int g_iZoneTypeCount = 0;
int g_iZoneCount = 0;

char g_cZoneTypes[MAX_ZONE_TYPES][32];
char g_cZoneTypes_Class[MAX_ZONE_TYPES][32];

int g_iZoneID[MAX_ZONES];
int  g_iZones[MAX_ZONES];
float g_fZones_Pos[MAX_ZONES][2][3];
char g_cZones_Type[MAX_ZONES][32];
char g_cZones_Target[MAX_ZONES][32];
char g_cZones_Name[MAX_ZONES][64];

Handle Forward_OnCreated;
Handle Forward_OnStartTouch;
Handle Forward_OnTouch;
Handle Forward_OnEndTouch;

#include "serversys/zones_setup.sp";

public Plugin myinfo = {
	name = "[Server-Sys] Zones",
	author = "cam",
	description = "Zones plugin for other plugin use.",
	version = SERVERSYS_VERSION,
	url = SERVERSYS_URL
};

public void OnPluginStart(){
	HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
	RegPluginLibrary("serversys-zones");

	CreateNative("Sys_Zones_RegisterZoneType", Native_RegisterZoneType);

	Forward_OnStartTouch = CreateGlobalForward("OnZoneStartTouch", ET_Event, Param_Cell, Param_Cell, Param_String);
	Forward_OnTouch = CreateGlobalForward("OnZoneTouch", ET_Event, Param_Cell, Param_Cell, Param_String);
	Forward_OnEndTouch = CreateGlobalForward("OnZoneEndTouch", ET_Event, Param_Cell, Param_Cell, Param_String);
	Forward_OnCreated = CreateGlobalForward("OnZoneCreated", ET_Event, Param_String, Param_Cell);

	LateLoaded = late;
	return APLRes_Success;
}

public Action Command_HookTrigger(int client, int args){
	if(args >= 2){
		char trigger[32];
		char type[32];
		char name[64];
		GetCmdArg(1, type, 32);
		GetCmdArg(2, trigger, 32);

		PrintTextChat(client, "%d registered zones", g_iZoneTypeCount);
		for(int i = 0; i < g_iZoneTypeCount; i++){
			if(strlen(g_cZoneTypes[i]) > 0){
				PrintTextChat(client, "Registered zone: %s", g_cZoneTypes[i]);
			}
			if(StrEqual(g_cZoneTypes[i], type, false)){
				strcopy(g_cZones_Type[g_iZoneCount], 32, type);
				strcopy(g_cZones_Target[g_iZoneCount], 32, trigger);
				if(args >= 3){
					GetCmdArg(3, name, 64);
					strcopy(g_cZones_Name[g_iZoneCount], 64, name);
				}
				g_iZoneCount++;
				PrintTextChat(client, "Added hook of type {%s} with the targetname {%s} and name {%s}", type, trigger, (args >= 3 ? name : "N/A"));
				CreateTimer(0.3, CheckZones, g_iRoundIndex);
				return Plugin_Handled;
			}
		}
	}else{
		PrintTextChat(client, "Need more args. <zonetype> <maptrigger> <assignedname>");
	}

	return Plugin_Handled;
}

public Action Event_RoundStart(Handle event, const char[] name, bool PreventBroadcast){
	g_iRoundIndex++;
	CreateTimer(1.5, CheckZones, g_iRoundIndex, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action CheckZones(Handle timer, int roundindex){
	if(g_iRoundIndex != roundindex)
		return Plugin_Stop;
	//if(!Sys_InRound())
	//	return Plugin_Stop;

	for(int i = 0; i < MAX_ZONES; i++){
		if((g_iZones[i] < 1 || !IsValidEntity(g_iZones[i])) && strlen(g_cZones_Type[i]) > 0){
			if(strlen(g_cZones_Target[i]) > 0){
				for(int entity = 0; entity < (GetMaxEntities() * 2); entity++){
					if(!IsValidEntity(entity))
						continue;

					char targetname[32];
					GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

					if(StrEqual(targetname, g_cZones_Target[i], false)){
						PrintToServer("Hooking zone of targetname %s and type %s.", g_cZones_Target[i], g_cZones_Type[i]);
						Action res = Plugin_Continue;
						Call_StartForward(Forward_OnCreated);
						Call_PushString(g_cZones_Type[i]);
						Call_PushCell(entity);
						Call_Finish(res);

						if(res == Plugin_Stop){
							g_iZones[i] = 0;
						}else{
							g_iZones[i] = entity;
							if(res != Plugin_Handled){
								SDKHook(entity, SDKHook_StartTouch, Hook_StartTouch);
								SDKHook(entity, SDKHook_EndTouch, Hook_EndTouch);
								SDKHook(entity, SDKHook_Touch, Hook_Touch);
							}
						}
					}
				}
			}else{
				CreateZone(i);
			}
		}
	}

	// This timer is single-use
	return Plugin_Stop;
}

void CreateZone(int i){
	int type = 0;
	for(int t=0;t<MAX_ZONE_TYPES;t++){
		if(StrEqual(g_cZones_Type[i], g_cZoneTypes[t], false)){
			type = t;
		}
	}

	if(type == 0)
		return;

	bool trigger = ((strlen(g_cZoneTypes_Class[type]) < 1) || ((strlen(g_cZoneTypes_Class[type]) > 0) && StrEqual(g_cZoneTypes_Class[type], "trigger_multiple", false)));

	int entity = CreateEntityByName((trigger ? "trigger_multiple" : g_cZoneTypes_Class[type]));
	if(entity != -1){
		if(trigger){
			SetEntityModel(entity, "models/error.mdl");
			DispatchKeyValue(entity, "spawnflags", "1");
			DispatchKeyValue(entity, "StartDisabled", "0");
			SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
		}

		DispatchSpawn(entity);
		ActivateEntity(entity);

		float pos[3];
		float bounds[2][3];

		for(int e = 0; e < 3; e++){
			if(g_fZones_Pos[i][0][e] != 0.0 && g_fZones_Pos[i][1][e] != 0.0){
				pos[e] = ((g_fZones_Pos[i][0][e] + g_fZones_Pos[i][1][e]) / 2);
			}

			float length = FloatAbs(g_fZones_Pos[i][0][e] - g_fZones_Pos[i][1][e]);
			bounds[0][e] = -(length / 2);
			bounds[1][e] = length / 2;
		}

		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropVector(entity, Prop_Send, "m_vecMins", bounds[0]);
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", bounds[1]);


		Action res = Plugin_Continue;
		Call_StartForward(Forward_OnCreated);
		Call_PushString(g_cZones_Type[i]);
		Call_PushCell(entity);
		Call_Finish(res);

		if(res == Plugin_Stop){
			g_iZones[i] = 0;
			AcceptEntityInput(entity, "Kill");
		}else{
			g_iZones[i] = entity;
			if(res != Plugin_Handled){
				SDKHook(entity, SDKHook_StartTouch, Hook_StartTouch);
				SDKHook(entity, SDKHook_EndTouch, Hook_EndTouch);
				SDKHook(entity, SDKHook_Touch, Hook_Touch);
			}
		}
	}

	return;
}

void HandleTouch(int zone, int other, Handle fwd){
	if((fwd == INVALID_HANDLE) || (other == 0) || (zone == 0)){
		PrintToServer("[server-sys] zones :: HandleTouch recieved some bullshit.");
	}

	for(int i = 0; i < MAX_ZONES; i++){
		if(g_iZones[i] == zone){
			Call_StartForward(fwd);
			Call_PushCell(other);
			Call_PushCell(zone);
			Call_PushString(g_cZones_Type[i]);
			Call_Finish();
		}
	}
}

public Action Hook_StartTouch(int zone, int other){
	if(zone < 1)
		return Plugin_Continue;

	HandleTouch(zone, other, Forward_OnStartTouch);
	return Plugin_Continue;
}

public Action Hook_Touch(int zone, int other){
	if(zone < 1)
		return Plugin_Continue;

	HandleTouch(zone, other, Forward_OnTouch);
	return Plugin_Continue;
}

public Action Hook_EndTouch(int zone, int other){
	if(zone < 1)
		return Plugin_Continue;

	HandleTouch(zone, other, Forward_OnEndTouch);
	return Plugin_Continue;
}

public void OnMapIDLoaded(int mapid){
	g_iMapID = mapid;
	LoadAttempts = 0;
	TryLoad(mapid);
}

void TryLoad(int mapid){
	char query[255];
	Format(query, sizeof(query), g_cQuery_Select, mapid);

	LoadAttempts++;
	Sys_DB_TQuery(Sys_LoadZones_CB, query, mapid, DBPrio_Normal);
}

public void Sys_LoadZones_CB(Handle owner, Handle hndl, const char[] error, int mapid){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] zones :: Error loading zones: %s", error);
		LoadAttempts++;
		return;
	}

	while(SQL_FetchRow(hndl)){
		if(SQL_IsFieldNull(hndl, 3) && SQL_IsFieldNull(hndl, 4))
			continue;

		g_iZoneID[g_iZoneCount] = SQL_FetchInt(hndl, 0);
		char temp_string32[32];
		char temp_string64[64];
		SQL_FetchString(hndl, 1, temp_string32, 32);
		strcopy(g_cZones_Type[g_iZoneCount], 32, temp_string32);
		SQL_FetchString(hndl, 2, temp_string64, 64);
		strcopy(g_cZones_Name[g_iZoneCount], 64, temp_string64);
		SQL_FetchString(hndl, 3, temp_string32, 32);
		strcopy(g_cZones_Target[g_iZoneCount], 32, temp_string32);
		g_fZones_Pos[g_iZoneCount][0][0] = SQL_FetchFloat(hndl, 4);
		g_fZones_Pos[g_iZoneCount][0][1] = SQL_FetchFloat(hndl, 5);
		g_fZones_Pos[g_iZoneCount][0][2] = SQL_FetchFloat(hndl, 6);
		g_fZones_Pos[g_iZoneCount][1][0] = SQL_FetchFloat(hndl, 7);
		g_fZones_Pos[g_iZoneCount][1][1] = SQL_FetchFloat(hndl, 8);
		g_fZones_Pos[g_iZoneCount][1][2] = SQL_FetchFloat(hndl, 9);

		g_iZoneCount++;
	}

	if(g_iRoundIndex > 0){
		CreateTimer(0.0, CheckZones, g_iRoundIndex, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public int Native_RegisterZoneType(Handle plugin, int numParams){
	char temp_string32[32];
	GetNativeString(1, temp_string32, 32);
	strcopy(g_cZoneTypes[g_iZoneTypeCount], 32, temp_string32);

	if(numParams > 1){
		GetNativeString(2, temp_string32, 32);
		strcopy(g_cZoneTypes_Class[g_iZoneTypeCount], 32, temp_string32);
	}

	g_iZoneTypeCount++;
}
