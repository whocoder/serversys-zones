/**
* Setup, drawing, deleting functionality.
*/

#define MENU_SELECTION_ADD "add_zone"
#define MENU_SELECTION_DIS "dis_zone"
#define MENU_SELECTION_ADD_TRIGGER "type_map"
#define MENU_SELECTION_ADD_CREATE  "type_new"

#define MENU_SELECTION_DELETE "dis_delete"

public Action OnClientSayCommand(int client, const char[] command, const char[] args){
	if((0 < client <= MaxClients) && IsClientInGame(client)){
		int arglen = strlen(args);
		if(arglen < 1)
			return Plugin_Continue;

		if(StrEqual(args, "cancel", false) && (g_iSetup[client] != SETUP_NONE)){
			g_iSetup[client] = SETUP_NONE;
			g_iSetup_Displaying[client] = 0;

			Format(g_cSetup_Trigger[client], TRIGGER_STRING_SIZE, "");
			Format(g_cSetup_Name[client], NAME_STRING_SIZE, "");
			Format(g_cSetup_Type[client], TYPE_STRING_SIZE, "");
			return Plugin_Stop;
		}

		if(g_iSetup[client] == SETUP_ADD_LISTENING_TRIGGER){
			bool found = false;

			for(int entity = 0; entity < (GetMaxEntities() * 2); entity++){
				if(!IsValidEntity(entity))
					continue;

				char targetname[32];
				GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

				if(StrEqual(targetname, args, false))
					found = true;
			}

			if(found){
				Format(g_cSetup_Trigger[client], TRIGGER_STRING_SIZE, "%s", args);

				g_iSetup[client] = SETUP_ADD_LISTENING_NAME;
				CPrintToChat(client, "%t", "Give the zone a name");
			}else{
				CPrintToChat(client, "%t", "No targetname match found", args);
				CPrintToChat(client, "%t", "Enter zone targetname");
			}

			return Plugin_Stop;
		}

		if(g_iSetup[client] == SETUP_ADD_LISTENING_NAME){
			if(!(StrEqual(args, "0", false) || StrEqual(args, "none", false) || StrEqual(args, "no", false))){
				Format(g_cSetup_Name[client], NAME_STRING_SIZE, "%s", args);
			}

			if(g_bSettings_AllowVis){
				g_iSetup[client] = SETUP_ADD_LISTENING_VISIBLE;
				CPrintToChat(client, "%t", "Pick zone visibility");
			}else{
				FinishSetup(client);
			}

			return Plugin_Stop;
		}

		if(g_iSetup[client] == SETUP_ADD_LISTENING_VISIBLE){
			bool match = false;
			if(StrEqual(args, "no", false)){
				match = true;
				g_bSetup_Visible[client] = false;
			}
			if(StrEqual(args, "yes", false)){
				match = true;
				g_bSetup_Visible[client] = true;
			}

			if(match){
				if(g_bSetup_Visible[client]){
					g_iSetup[client] = SETUP_ADD_LISTENING_WIDTH;
					CPrintToChat(client, "%t", "Enter zone width");
				}else{
					FinishSetup(client);
				}
			}else{
				CPrintToChat(client, "%t", "Pick zone visibility");
			}

			return Plugin_Stop;
		}

		if(g_iSetup[client] == SETUP_ADD_LISTENING_WIDTH){
			float width = StringToFloat(args);
			g_fSetup_Width[client] = (width == 0.0 ? g_fSettings_DefaultWidth : width);

			CPrintToChat(client, "%t", "Add optional value");
			return Plugin_Stop;
		}

		if(g_iSetup[client] == SETUP_ADD_LISTENING_VALUE){
			g_iSetup_Value[client] = StringToInt(args);

			FinishSetup(client);
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public void Command_Zones(int client, const char[] cmd, const char[] args){
	if((0 < client <= MaxClients) && IsClientInGame(client)){
		CPrintToChat(client, "%t", "You may cancel any time");

		g_iSetup[client] = SETUP_MAIN;
		Menu Menu_Zones_Home = CreateMenu(Menu_Zones_Home_Handler);
		Menu_Zones_Home.SetTitle("%t", "Zones Menu Title");

		char buffer[64];

		Format(buffer, sizeof(buffer), "%t", "Add a zone menu option");
		Menu_Zones_Home.AddItem(MENU_SELECTION_ADD, buffer, ITEMDRAW_DEFAULT);

		Format(buffer, sizeof(buffer), "%t", "Display a zone menu option");
		Menu_Zones_Home.AddItem(MENU_SELECTION_DIS, buffer, ITEMDRAW_DEFAULT);

		Menu_Zones_Home.Display(client, MENU_TIME_FOREVER);
	}
}

public int Menu_Zones_Home_Handler(Menu menu, MenuAction action, int param1, int param2){
	if((0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;

		if(action == MenuAction_Select){
			char selection[32];
			if(menu.GetItem(param2, selection, sizeof(selection))){
				if(StrEqual(selection, MENU_SELECTION_ADD)){
					g_iSetup[client] = SETUP_ADD_SELECT_TYPE;

					Menu add_zone = CreateMenu(Menu_Zones_Add_Handler);
					add_zone.SetTitle("%t", "Add a zone menu title");

					for(int i = 0; i < g_iZoneTypeCount; i++){
						if(strlen(g_cZoneTypes[i]) > 1){
							add_zone.AddItem(g_cZoneTypes[i], g_cZoneTypes[i], ITEMDRAW_DEFAULT);
						}
					}

					Sys_KillHandle(menu);
					add_zone.Display(client, MENU_TIME_FOREVER);
				}
				if(StrEqual(selection, MENU_SELECTION_DIS)){
					g_iSetup[client] = SETUP_DIS_SELECT_ZONE;

					Menu dis_zone = CreateMenu(Menu_Zones_Display_Handler);
					dis_zone.SetTitle("%t", "Display a zone menu title");

					for(int i = 0; i < g_iZoneCount; i++){
						if(strlen(g_cZones_Type[i]) > 1){
							char str[8];
							Format(str, sizeof(str), "%d", i);
							char infostr[128];
							Format(infostr, sizeof(infostr), "%t - %s | %t - %d (%t - %d)", "Zone type", g_cZones_Type[i], "Zone hard ID", g_iZoneID[i], "Zone soft ID", i);
							dis_zone.AddItem(str, infostr, ITEMDRAW_DEFAULT);
						}
					}

					Sys_KillHandle(menu);
					dis_zone.Display(client, MENU_TIME_FOREVER);
				}
			}
		}else{
			Sys_KillHandle(menu);
			g_iSetup[client] = SETUP_NONE;
		}
	}else
		Sys_KillHandle(menu);
}

public int Menu_Zones_Display_Handler(Menu menu, MenuAction action, int param1, int param2){
	if(action == MenuAction_Select && (0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;

		char selection[8];
		if(menu.GetItem(param2, selection, sizeof(selection))){
			int picked = StringToInt(selection);

			g_iSetup_Displaying[client] = picked;

			Menu act = CreateMenu(Menu_Zones_Display_Action_Handler);
			act.SetTitle("%t", "Zone display action menu");

			char buffer[64];
			Format(buffer, sizeof(buffer), "%t", "Delete zone");
			act.AddItem(MENU_SELECTION_DELETE, buffer, ITEMDRAW_DEFAULT);
		}
	}
}

public int Menu_Zones_Display_Action_Handler(Menu menu, MenuAction action, int param1, int param2){
    if(action == MenuAction_Select && (0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;
		char selection[32];
		if(menu.GetItem(param2, selection, sizeof(selection))){
			if(StrEqual(selection, MENU_SELECTION_DELETE, false)){
				DeleteZone(Sys_GetPlayerID(client), g_iSetup_Displaying[client]);
			}
		}
	}
}

public int Menu_Zones_Add_Handler(Menu menu, MenuAction action, int param1, int param2){
	if((0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;

		if(action == MenuAction_Select){
			char selection[32];
			if(menu.GetItem(param2, selection, sizeof(selection))){
				for(int i = 0; i < g_iZoneCount; i++){
					if((strlen(g_cZoneTypes[i]) > 0) && StrEqual(g_cZoneTypes[i], selection, false)){
						Format(g_cSetup_Type[client], TYPE_STRING_SIZE, "%s", selection);

						g_iSetup[client] = SETUP_ADD_SELECT_METHOD;

						Menu select_menu = CreateMenu(Menu_Zones_Add_Select_Handler);
						select_menu.SetTitle("%t", "Select zone adding method");
						char buffer[64];

						Format(buffer, sizeof(buffer), "%t", "Pre-existing map zone");
						select_menu.AddItem(MENU_SELECTION_ADD_TRIGGER, buffer, ITEMDRAW_DEFAULT);

						Format(buffer, sizeof(buffer), "%t", "Create new custom zone");
						select_menu.AddItem(MENU_SELECTION_ADD_CREATE, buffer, ITEMDRAW_DEFAULT);

						Sys_KillHandle(menu);
						select_menu.Display(client, MENU_TIME_FOREVER);
					}
				}
			}else{
				Sys_KillHandle(menu);
				g_iSetup[client] = SETUP_NONE;
			}
		}else{
			Sys_KillHandle(menu);
			g_iSetup[client] = SETUP_NONE;
		}
	}else
		Sys_KillHandle(menu);
}

public int Menu_Zones_Add_Select_Handler(Menu menu, MenuAction action, int param1, int param2){
    if(action == MenuAction_Select && (0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;

		char selection[32];
		if(menu.GetItem(param2, selection, sizeof(selection))){
			if(StrEqual(selection, MENU_SELECTION_ADD_TRIGGER, false)){
				g_iSetup[client] = SETUP_ADD_LISTENING_TRIGGER;
				CPrintToChat(client, "%t", "Enter zone targetname");
			}
			if(StrEqual(selection, MENU_SELECTION_ADD_CREATE, false)){
				g_iSetup[client] = SETUP_ADD_CREATING_ZONE;
				// Create creation menu here
				// Needs lot more work
			}
		}
	}
}


void FinishSetup(int client){
	g_iSetup[client] = SETUP_NONE;

	if(!((0 < client <= MaxClients) && IsClientInGame(client)))
		return;

	if((strlen(g_cSetup_Type[client]) < 1)){
		CPrintToChat(client, "%t", "There was an error in setup");
		return;
	}

	bool mapbased = (strlen(g_cSetup_Trigger[client]) > 0);
	bool hasname = (strlen(g_cSetup_Name[client]) > 0);

	char query[2048];

	if(mapbased){
		Format(query, sizeof(query), (hasname ? g_cQuery_InsertMapZone : g_cQuery_InsertMapZone_NoName),
			g_iMapID, g_cSetup_Type[client], g_iSetup_Value[client], g_cSetup_Trigger[client],
			(hasname ? g_cSetup_Name[client] : ""));
	}else{
		Format(query, sizeof(query), (hasname ? g_cQuery_InsertNewZone : g_cQuery_InsertNewZone_NoName),
			g_iMapID, g_cSetup_Type[client], g_iSetup_Value[client],
			g_fSetup_Pos[client][0][0], g_fSetup_Pos[client][0][1], g_fSetup_Pos[client][0][2],
			g_fSetup_Pos[client][1][0], g_fSetup_Pos[client][1][1], g_fSetup_Pos[client][1][2],
			(hasname ? g_cSetup_Name[client] : ""));
	}

	// DBPrio_High for all zone-related stuff as it could affect
	// gameplay. This matters.
	Sys_DB_TQuery(Sys_InsertZone_CB, query, g_iMapID, DBPrio_High);
}


public void Sys_InsertZone_CB(Handle owner, Handle hndl, const char[] error, int mapid){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] zones :: Error inserting zone: %s", error);
		LoadAttempts++;
		return;
	}

	if(mapid == g_iMapID){
		CPrintToChatAll("%t", "Zones are being live reloaded");

		LoadAttempts = 0;
		TryLoad(mapid);
	}
}


void DeleteZone(int client, int zone){
	char query[1024];
	Format(query, sizeof(query), g_cQuery_Remove, g_iZoneID[zone]);
// not done
// to do
}
