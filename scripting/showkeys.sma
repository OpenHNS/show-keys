#include <amxmodx>
#include <reapi>

#define DELAY 0.05

new g_iPlayersKeys[MAX_PLAYERS + 1];

new Float:g_flHudTime[MAX_PLAYERS + 1];

new bool:g_bShowKeys[MAX_PLAYERS + 1];
new bool:g_bSpecKeys[MAX_PLAYERS + 1];

public plugin_init()  {
	register_plugin("Show keys", "1.0.0", "OpenHNS"); // WessTorn

	register_clcmd("say /showkeys", "cmdShowkeys");
	register_clcmd("say_team /showkeys", "cmdShowkeys");
	register_clcmd("say /sk", "cmdShowkeys");
	register_clcmd("say_team /sk", "cmdShowkeys");

	register_clcmd("say /speckeys", "cmdSpeckeys");
	register_clcmd("say_team /speckeys", "cmdSpeckeys");
	register_clcmd("say /spk", "cmdSpeckeys");
	register_clcmd("say_team /spk", "cmdSpeckeys");

	RegisterHookChain(RG_CBasePlayer_PostThink, "rgPlayerPostThink");
}

public client_connect(id) {
	g_bSpecKeys[id] = g_bShowKeys[id] = false;
	g_iPlayersKeys[id] = 0;
	g_flHudTime[id] = 0.0;
}

public client_disconnected(id) {
	g_bSpecKeys[id] = g_bShowKeys[id] = false;
	g_iPlayersKeys[id] = 0;
	g_flHudTime[id] = 0.0;
}

public rgPlayerPostThink(id) {
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

		set_dhudmessage(250, 250, 250, -1.0, 0.3, 0, 1.0, 0.1, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyWASD);

		set_dhudmessage(250, 250, 250, 0.4, 0.3, 0, 1.0, 0.1, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyJD);
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

		set_dhudmessage(250, 250, 250, -1.0, 0.3, 0, 1.0, 0.15, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyWASD);
		
		set_dhudmessage(250, 250, 250, 0.4, 0.3, 0, 1.0, 0.15, 0.0, 0.00);
		show_dhudmessage(id, "%s", szKeyJD);
	}
	return PLUGIN_HANDLED;
}