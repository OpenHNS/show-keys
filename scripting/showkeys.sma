#include <amxmodx>
#include <reapi>
#include <nvault>

#define DELAY 0.05

new g_iVault;

new g_iPlayersKeys[MAX_PLAYERS + 1];

new Float:g_flHudTime[MAX_PLAYERS + 1];

new bool:g_bShowKeys[MAX_PLAYERS + 1];
new bool:g_bSpecKeys[MAX_PLAYERS + 1];

new Float:g_flMouseY[MAX_PLAYERS + 1];
new Float:g_flOldMouseY[MAX_PLAYERS + 1];

enum IS_MOUSE {
	e_mNot = 0,
	e_mLeft,
	e_mRight
};

new IS_MOUSE:g_ePlayersMouse[MAX_PLAYERS + 1];

public plugin_natives() {
	register_native("hns_get_player_showkeys", "native_get_player_showkeys");
	register_native("hns_get_player_speckeys", "native_get_player_speckeys");
}

public native_get_player_showkeys(amxx, params) {
	enum { id = 1 };
	return g_bShowKeys[get_param(id)];
}

public native_get_player_speckeys(amxx, params) {
	enum { id = 1 };
	return g_bSpecKeys[get_param(id)];
}

public plugin_init()  {
	register_plugin("Show keys", "1.0.1", "OpenHNS");

	register_clcmd("say /showkeys", "cmdShowkeys");
	register_clcmd("say_team /showkeys", "cmdShowkeys");
	register_clcmd("say /sk", "cmdShowkeys");
	register_clcmd("say_team /sk", "cmdShowkeys");

	register_clcmd("say /speckeys", "cmdSpeckeys");
	register_clcmd("say_team /speckeys", "cmdSpeckeys");
	register_clcmd("say /spk", "cmdSpeckeys");
	register_clcmd("say_team /spk", "cmdSpeckeys");

	RegisterHookChain(RG_PM_Move, "rgPM_Move", true);
}

public plugin_cfg() {
	g_iVault = nvault_open("showkeys");

	if (g_iVault == INVALID_HANDLE) {
		log_amx("showkeys.sma: plugin_cfg:: can't open file ^"showkeys.vault^"!");
	}
}

public client_connect(id) {
	if (g_iVault != INVALID_HANDLE) {
		new szAuthID[32];
		get_user_authid(id, szAuthID, charsmax(szAuthID));

		new szData[32], iTimeStamp;

		if (nvault_lookup(g_iVault, szAuthID, szData, charsmax(szData), iTimeStamp)) {
			new bShowKeys[3], bSpecKeys[3];

			parse(szData,
			 bShowKeys, charsmax(bShowKeys),
			 bSpecKeys, charsmax(bSpecKeys))

			g_bShowKeys[id] = str_to_num(bShowKeys) ? true : false;
			g_bSpecKeys[id] = str_to_num(bSpecKeys) ? true : false;

			nvault_remove(g_iVault, szAuthID);
		}
	}
}

public client_disconnected(id) {
	if (g_iVault != INVALID_HANDLE) {
		new szAuthID[32];
		get_user_authid(id, szAuthID, charsmax(szAuthID));

		new szData[32];

		formatex(szData, charsmax(szData), "^"%d^" ^"%d^"", 
		g_bShowKeys[id], g_bSpecKeys[id]);

		nvault_set(g_iVault, szAuthID, szData);
	}

	g_bSpecKeys[id] = g_bShowKeys[id] = false;
	g_iPlayersKeys[id] = 0;
	g_flHudTime[id] = 0.0;
	g_flMouseY[id] = 0.0;
	g_flOldMouseY[id] = 0.0;
	g_ePlayersMouse[id] = e_mNot;
}

public rgPM_Move(id) {
	new iButton = get_entvar(id, var_button);

	if (iButton & IN_FORWARD)
		g_iPlayersKeys[id] |= IN_FORWARD;

	if (iButton & IN_BACK)
		g_iPlayersKeys[id] |= IN_BACK;

	if (iButton & IN_MOVELEFT)
		g_iPlayersKeys[id] |= IN_MOVELEFT;

	if (iButton & IN_MOVERIGHT)
		g_iPlayersKeys[id] |= IN_MOVERIGHT;

	if (iButton & IN_DUCK)
		g_iPlayersKeys[id] |= IN_DUCK;

	if (iButton & IN_JUMP)
		g_iPlayersKeys[id] |= IN_JUMP;

	new Float:flAngles[3]; get_entvar(id, var_angles, flAngles);
	g_flMouseY[id] = flAngles[1];

	if (g_flMouseY[id] > g_flOldMouseY[id])
		g_ePlayersMouse[id] = e_mLeft;
	else if (g_flMouseY[id] < g_flOldMouseY[id])
		g_ePlayersMouse[id] = e_mRight;
	else
		g_ePlayersMouse[id] = e_mNot;

	g_flOldMouseY[id] = g_flMouseY[id];

	static Float:flTime;
	flTime = get_gametime();
	
	if((g_flHudTime[id] + DELAY) > flTime)
		return HC_CONTINUE;

	showKeysInfo(id);
	g_flHudTime[id] = flTime;
	g_iPlayersKeys[id] = 0;

	return HC_CONTINUE;
}

public cmdShowkeys(id) {
	g_bShowKeys[id] = !g_bShowKeys[id];

	if (!g_bShowKeys[id])
		client_print_color(id, print_team_blue, "[^3Showkeys^1] Show keys ^3disabled^1.");
	else
		client_print_color(id, print_team_blue, "[^3Showkeys^1] Show keys ^3enabled^1.");
}

public cmdSpeckeys(id) {
	g_bSpecKeys[id] = !g_bSpecKeys[id];

	if (!g_bShowKeys[id])
		client_print_color(id, print_team_blue, "[^3Showkeys^1] Spec show keys ^3disabled^1.");
	else
		client_print_color(id, print_team_blue, "[^3Showkeys^1] Spec show keys ^3enabled^1.");
}

public showKeysInfo(id) {
	if (is_user_alive(id)) {
		if (!g_bShowKeys[id])
			return PLUGIN_HANDLED;

		static szKeyWASD[16];
		formatex(szKeyWASD, charsmax(szKeyWASD), "%s^n%s %s %s",  
			g_iPlayersKeys[id] & IN_FORWARD ? "W" : ".", 
			g_iPlayersKeys[id] & IN_MOVELEFT ? "A" : ".", 
			g_iPlayersKeys[id] & IN_BACK ? "S" : ".", 
			g_iPlayersKeys[id] & IN_MOVERIGHT ? "D" : ".");

		static szKeyJD[16];
		formatex(szKeyJD, charsmax(szKeyJD), "%s^n%s",
			g_iPlayersKeys[id] & IN_JUMP ? "jump" : " ",
			g_iPlayersKeys[id] & IN_DUCK ? "duck" : " ");

		static szKeyMouse[16];
		formatex(szKeyMouse, charsmax(szKeyMouse), "%s %s",
			g_ePlayersMouse[id] == e_mLeft ? "<--" : " ",
			g_ePlayersMouse[id] == e_mRight ? "-->" : " ");

		set_dhudmessage(250, 250, 250, -1.0, 0.3, 0, 1.0, 0.1, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyWASD);

		set_dhudmessage(250, 250, 250, 0.4, 0.3, 0, 1.0, 0.1, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyJD);

		set_dhudmessage(250, 250, 250, 0.55, 0.32, 0, 1.0, 0.1, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyMouse);
	} else {
		if (!g_bSpecKeys[id])
			return PLUGIN_HANDLED;

		new iSpecMode = get_entvar(id, var_iuser1);
		if(iSpecMode != 2 && iSpecMode != 4)
			return PLUGIN_HANDLED;

		new iTarget = get_entvar(id, var_iuser2);
		if(iTarget == id)
			return PLUGIN_HANDLED;
		
		if(!is_user_alive(iTarget))
			g_iPlayersKeys[iTarget] = 0;

		static szKeyWASD[16];
		formatex(szKeyWASD, charsmax(szKeyWASD), "%s^n%s %s %s",  
		g_iPlayersKeys[iTarget] & IN_FORWARD ? "W" : ".",				
		g_iPlayersKeys[iTarget] & IN_MOVELEFT ? "A" : ".", 
		g_iPlayersKeys[iTarget] & IN_BACK ? "S" : ".", 
		g_iPlayersKeys[iTarget] & IN_MOVERIGHT ? "D" : ".");

		static szKeyJD[16];
		formatex(szKeyJD, charsmax(szKeyJD), "%s^n%s",
		g_iPlayersKeys[iTarget] & IN_JUMP ? "jump" : " ",				
		g_iPlayersKeys[iTarget] & IN_DUCK ? "duck" : " ");

		static szKeyMouse[16];
		formatex(szKeyMouse, charsmax(szKeyMouse), "%s %s",
			g_ePlayersMouse[iTarget] == e_mLeft ? "<--" : " ",
			g_ePlayersMouse[iTarget] == e_mRight ? "-->" : " ");

		set_dhudmessage(250, 250, 250, -1.0, 0.3, 0, 1.0, 0.15, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyWASD);
		
		set_dhudmessage(250, 250, 250, 0.4, 0.3, 0, 1.0, 0.15, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyJD);

		set_dhudmessage(250, 250, 250, 0.55, 0.32, 0, 1.0, 0.1, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyMouse);
	}
	return PLUGIN_HANDLED;
}