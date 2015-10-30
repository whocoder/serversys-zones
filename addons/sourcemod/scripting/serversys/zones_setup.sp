/**
* Setup functionality
*
* I added this to another file to get it out of my way.
*/

#define MENU_SELECTION_ADD_1 "add_zone";
#define MENU_SELECTION_DEL_1 "del_zone";
#define MENU_SELECTION_DIS_1 "dis_zone";

#define MENU_SELECTION_ADD_2_1 "type_map";
#define MENU_SELECTION_ADD_2_2 "type_new";

#define SETUP_NOP 0;
#define SETUP_ADD 1;
#define SETUP_DEL 2;
#define SETUP_DIS 3;
#define SETUP_CHAT_TRIGGER 4;
#define SETUP_CHAT_NAME 5;


int g_iSetup[MAXPLAYERS+1];
bool g_bSetup_DrawZones[MAXPLAYERS+1];
char g_cSetup_Type[MAXPLAYERS+1][32];
float g_fSetup_Pos[MAXPLAYERS+1][2][3];

public void OnAllPluginsLoaded(){
	Sys_RegisterChatCommand("!zones /zones .zones", Command_Zones);
}

public Action Command_Zones(int client, const char[] cmd, const char[] args){
	if((0 < client <= MaxClients) && IsClientInGame(client)){
		g_iSetup[client] = SETUP_NOP;
		Menu Menu_Zones_Home = CreateMenu(Menu_Zones_Home_Handler);
		Menu_Zones_Home.SetTitle("%t", "Zones Menu Title");

		Menu_Zones_Home.AddItem(MENU_SELECTION_ADD_1, "Add a zone", ITEMDRAW_DEFAULT);
		Menu_Zones_Home.AddItem(MENU_SELECTION_DEL_1, "Remove a zone", ITEMDRAW_DEFAULT);
		//Menu_Zones_Home.AddItem(MENU_SELECTION_DIS_1, "Display a zone", ITEMDRAW_DEFAULT);

		Menu_Zones_Home.Display(client, MENU_TIME_FOREVER);
	}
}

public int Menu_Zones_Home_Handler(Menu menu, MenuAction action, int param1, int param2){
    if(action == MenuAction_Select && (0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;

		char selection[32];
		if(menu.GetItem(param2, selection, sizeof(selection))){
			if(StrEqual(selection, MENU_SELECTION_ADD_1)){
				g_iSetup[client] = SETUP_ADD;

				Menu add_zone = CreateMenu(Menu_Zones_Add_Handler);
				add_zone.SetTitle("%t", "Add a zone title");

				for(int i = 0; i < g_iZoneTypeCount; i++){
					if(strlen(g_cZoneTypes[i]) > 1){
						add_zone.AddItem(g_cZoneTypes[i], g_cZoneTypes[i], ITEMDRAW_DEFAULT);
					}
				}

				Sys_KillHandle(menu);
				add_zone.Display(client, MENU_TIME_FOREVER);
			}
			if(StrEqual(selection, MENU_SELECTION_DEL_1)){
				g_iSetup[client] = SETUP_DEL;
			}
			if(StrEqual(selection, MENU_SELECTION_DIS_1)){
				g_iSetup[client] = SETUP_DIS;
			}
		}
	}else{
		Sys_KillHandle(menu);
	}
}

public int Menu_Zones_Add_Handler(Menu menu, MenuAction action, int param1, int param2){
    if(action == MenuAction_Select && (0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;

		char selection[32];
		if(menu.GetItem(param2, selection, sizeof(selection))){
			for(int i = 0; i < g_iZoneCount; i++){
				if((strlen(g_cZoneTypes[i]) > 0) && StrEqual(g_cZoneTypes[i], selection, false)){
					strcopy(g_cSetup_Type[client], sizeof(g_cSetup_Type[client]), selection);

					Menu select_menu = CreateMenu(Menu_Zones_Add_Select_Handler);
					select_menu.SetTitle("%t", "Select zone adding method");
					select_menu.AddItem(MENU_SELECTION_ADD_2_1, "Pre-existing map zone", ITEMDRAW_DEFAULT);
					select_menu.AddItem(MENU_SELECTION_ADD_2_2, "Create new custom zone", ITEMDRAW_DEFAULT);

					Sys_KillHandle(menu);
					select_menu.Display(client, MENU_TIME_FOREVER);
				}
			}
		}else
			Sys_KillHandle(menu);
	}else
		Sys_KillHandle(menu);
}

public int Menu_Zones_Add_Select_Handler(Menu menu, MenuAction action, int param1, int param2){
    if(action == MenuAction_Select && (0 < param1 <= MaxClients) && IsClientInGame(param1)){
		int client = param1;

		char selection[32];
		if(menu.GetItem(param2, selection, sizeof(selection))){
			if(StrEqual(selection, MENU_SELECTION_ADD_2_1, false)){
				g_iSetup[client] = SETUP_CHAT_TRIGGER;
				PrintTextChat(client, "%t", "Type zone targetname now");
			}
			if(StrEqual(selection, MENU_SELECTION_ADD_2_2, false)){

			}
		}
	}
}
