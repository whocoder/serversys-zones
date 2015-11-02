/**
* Loading, hooking, creating functionality.
*/

void TryLoad(int mapid){
	char query[255];
	Format(query, sizeof(query), g_cQuery_Select, mapid);

	Loading = true;

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

public Action Event_RoundStart(Handle event, const char[] name, bool PreventBroadcast){
	g_iRoundIndex++;
	CreateTimer(1.5, CheckZones, g_iRoundIndex, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action CheckZones(Handle timer, int roundindex){
	if(g_iRoundIndex != roundindex)
		return Plugin_Stop;

	for(int i = 0; i < MAX_ZONES; i++){
		if((g_iZones[i] < 1 || !IsValidEntity(g_iZones[i])) && strlen(g_cZones_Type[i]) > 0){
			if(strlen(g_cZones_Target[i]) > 0){
				FindZone(i);
			}else{
				CreateZone(i);
			}
		}
	}

	Loading = false;

	// This timer is single-use
	return Plugin_Stop;
}

void FindZone(int i){
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
		return;
	}

	if(Loading && !g_bSettings_FireWhenLoading)
		return;

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
