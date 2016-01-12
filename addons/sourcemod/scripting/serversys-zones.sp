#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <smlib>
#include <serversys>
#include <serversys-zones>

#pragma semicolon 1
#pragma newdecls required

#define TRIGGER_STRING_SIZE 32
#define CLASS_STRING_SIZE 32
#define NAME_STRING_SIZE 64
#define TYPE_STRING_SIZE 32

char g_cQuery_Select[] = "SELECT id, value, type, name, target, posx1, posy1, posz1, posx2, posy2, posz2 FROM zones WHERE map = %d;";
char g_cQuery_Remove[] = "DELETE FROM zones WHERE id = %d;";
char g_cQuery_InsertMapZone[] = "INSERT INTO zones(map, type, value, target, name) VALUES(%d, '%s', %d, '%s', '%s');";
char g_cQuery_InsertMapZone_NoName[] = "INSERT INTO zones(map, type, value, target) VALUES(%d, '%s', %d, '%s');";
char g_cQuery_InsertNewZone[] = "INSERT INTO zones(map, type, value, posx1, posy1, posz1, posx2, posy2, posz2, name) VALUES(%d, '%s', %d, %f, %f, %f, %f, %f, %f, '%s');";
char g_cQuery_InsertNewZone_NoName[] = "INSERT INTO zones(map, type, value, posx1, posy1, posz1, posx2, posy2, posz2, name) VALUES(%d, '%s', %d, %f, %f, %f, %f, %f, %f, '%s');";

bool LateLoaded = false;
bool Loading = true;
int LoadAttempts = 0;

int g_iMapID = 0;
int g_iRoundIndex = 0;

int g_iZoneTypeCount = 0;
int g_iZoneCount = 0;

char g_cZoneTypes[MAX_ZONE_TYPES][TYPE_STRING_SIZE];
char g_cZoneTypes_Class[MAX_ZONE_TYPES][CLASS_STRING_SIZE];

int g_iZoneVal[MAX_ZONES];
int g_iZoneID[MAX_ZONES];
int  g_iZones[MAX_ZONES];
float g_fZones_Pos[MAX_ZONES][2][3];
char g_cZones_Type[MAX_ZONES][TYPE_STRING_SIZE];
char g_cZones_Target[MAX_ZONES][TRIGGER_STRING_SIZE];
char g_cZones_Name[MAX_ZONES][NAME_STRING_SIZE];

Zones_SetupState g_iSetup[MAXPLAYERS+1];
int g_iSetup_Displaying[MAXPLAYERS+1];
char g_cSetup_Type[MAXPLAYERS+1][TYPE_STRING_SIZE];
char g_cSetup_Trigger[MAXPLAYERS+1][TRIGGER_STRING_SIZE];
char g_cSetup_Name[MAXPLAYERS+1][NAME_STRING_SIZE];
bool g_bSetup_Visible[MAXPLAYERS+1];
float g_fSetup_Width[MAXPLAYERS+1];
float g_fSetup_Pos[MAXPLAYERS+1][2][3];
int g_iSetup_GridSnapping[MAXPLAYERS+1] = {1, ...}; // Doubles (1, 2, 4, 8, 16, 32, 64) - 0 Could theoretically work
int g_iSetup_Value[MAXPLAYERS+1];

bool g_bSettings_FireWhenLoading = true;
bool g_bSettings_AllowVis = false;
float g_fSettings_DefaultWidth = 2.0;
char g_cCommand_Zones[128];

Handle Forward_OnCreated;
Handle Forward_OnStartTouch;
Handle Forward_OnTouch;
Handle Forward_OnEndTouch;

#include "serversys/zones_load.sp"
#include "serversys/zones_setup.sp"

public Plugin myinfo = {
	name = "[Server-Sys] Zones (Beta)",
	author = "cam",
	description = "Zones plugin for other plugin's advanced incorporation.",
	version = SERVERSYS_VERSION,
	url = SERVERSYS_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
	RegPluginLibrary("serversys-zones");

	CreateNative("Sys_Zones_RegisterZoneType", Native_RegisterZoneType);
	CreateNative("Sys_Zones_GetSetupState", Native_GetSetupState);

	Forward_OnStartTouch = CreateGlobalForward("OnZoneStartTouch", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell);
	Forward_OnTouch = CreateGlobalForward("OnZoneTouch", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell);
	Forward_OnEndTouch = CreateGlobalForward("OnZoneEndTouch", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell);
	Forward_OnCreated = CreateGlobalForward("OnZoneCreated", ET_Event, Param_String, Param_Cell, Param_Cell, Param_Cell);

	LateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart(){
	LoadTranslations("serversys.zones.phrases");
	LoadConfig();

	if(GetEngineVersion() == Engine_CSGO)
		HookEventEx("round_prestart", Event_RoundStart, EventHookMode_Post); // Sometimes round_start isn't called? This also makes zones available during warmup.
	else
		HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
}

void LoadConfig(char[] map_name = ""){
	KeyValues kv = CreateKeyValues("Server-Sys Zones");
	char Config_Path[PLATFORM_MAX_PATH];

	if(Sys_InMap() && (strlen(map_name) > 2) && Sys_UseMapConfigs()){
		BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/maps/%s/zones.cfg", map_name);

		if(!(FileExists(Config_Path)) || !(kv.ImportFromFile(Config_Path)))
			BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/zones.cfg");
	}else{
		BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/zones.cfg");
	}

	if(!(FileExists(Config_Path)) || !(kv.ImportFromFile(Config_Path))){
		delete kv;
		SetFailState("[serversys] zones :: Cannot read from configuration file: %s", Config_Path);
	}

	kv.GetString("setup_command", g_cCommand_Zones, sizeof(g_cCommand_Zones), "!zones /zones .zones");
	g_bSettings_FireWhenLoading = view_as<bool>(kv.GetNum("fire_when_loading", 0));
	g_bSettings_AllowVis = view_as<bool>(kv.GetNum("allow_visibility", 1));
	g_fSettings_DefaultWidth = kv.GetFloat("default_width", 2.0);

	delete kv;
}

public void OnAllPluginsLoaded(){
	if(LateLoaded && Sys_InMap()){
		if(Sys_GetMapID() > 0){
			g_iMapID = Sys_GetMapID();

			TryLoad(g_iMapID);
		}
	}

	Sys_RegisterChatCommand(g_cCommand_Zones, Command_Zones);
}

public void OnMapStart(){
	Loading = true;
}

public void OnMapIDLoaded(int mapid){
	g_iMapID = mapid;

	Loading = true;
	LoadAttempts = 0;
	TryLoad(mapid);
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

public int Native_GetSetupState(Handle plugin, int numParams){
	int client = GetNativeCell(1);

	if((0 < client <= MaxClients) && IsClientInGame(client)){
		return view_as<int>(g_iSetup[client]);
	}else
		return view_as<int>(SETUP_NONE);
}
