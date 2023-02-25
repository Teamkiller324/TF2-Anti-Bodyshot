#pragma semicolon 1
#pragma newdecls required
#include <multicolors>
#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define MaxPlayers 33

public Plugin myinfo = {
	name = "[TF2] Anti-Bodyshot",
	author = "Tk /id/Teamkiller324",
	description = "Makes sure people doesn't noscope",
	version = "1.0.2",
	url = "https://steamcommunity.com/id/Teamkiller324"
}

int g_Bodyshot[MaxPlayers+1];

ConVar bodyshot_limit
, bodyshot_enable
, bodyshot_punish
, bodyshot_reset
, bodyshot_random;

public void OnPluginStart()	{
	bodyshot_limit = CreateConVar("sm_antibodyshot_limit", "4", "The limit of how many bodyshots till client gets punished \n Minimum 1", _, true, 1.0);
	bodyshot_enable = CreateConVar("sm_antibodyshot_enable", "1", "Should Anti-Bodyshot be enabled or disabled?", _, true, _, true, 1.0);
	bodyshot_punish = CreateConVar("sm_antibodyshot_punish", "1", "What kind of punishment should client be given? \0 = Nothing \n1 = Kick the player \n2 = Make player bleed \n3 = Ignite the player \n4 = Freeze player \n5 = Timebomb player \n6 Kill the player", _, true, _, true, 6.0);
	bodyshot_reset = CreateConVar("sm_antibodyshot_reset", "1", "Should bodyshot count be reset on death?",	_, true, _, true, 1.0);
	bodyshot_random = CreateConVar("sm_antibodyshot_random", "0", "Should the bodyshot punishment be selected randomly? (antibodyshot punish will be ignored if on)", _, true, _, true, 1.0);
	
	HookEvent("player_death", view_as<EventHook>(Event_PlayerDeath), EventHookMode_Pre);
	
	AutoExecConfig(true, "tf2_antibodyshot");
}

public void OnClientDisconnect(int client) {
	g_Bodyshot[client] = 0;
}

void Event_PlayerDeath(Event event) {
	if(!bodyshot_enable.BoolValue) return;
	
	int	client = GetClientOfUserId(event.GetInt("attacker"));
	
	if(!IsValidClient(client)) return;
	if(TF2_GetPlayerClass(client) != TFClass_Sniper) return;
	if(!GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)) return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"))
	, custom = event.GetInt("customkill");
	
	if(victim == client && bodyshot_reset.BoolValue) {
		g_Bodyshot[client] = 0;
		return;
	}
	
	bool headshot = false;
	
	switch(custom) {
		case 1:	headshot = true;
		default: headshot = false;
	}
	
	switch(headshot) {
		case false: g_Bodyshot[client]++;
		case true: g_Bodyshot[client]--;
	}
	
	if(g_Bodyshot[client] < 0) g_Bodyshot[client] = 0;
	else if(g_Bodyshot[client] > bodyshot_limit.IntValue) g_Bodyshot[client] = bodyshot_limit.IntValue;
	else if(g_Bodyshot[client] == bodyshot_limit.IntValue) bodyshot_check_punishment(client);
}

char killroll[][] = {
	"explode",
	"kill"
};

void bodyshot_check_punishment(int client) {
	switch(bodyshot_random.BoolValue) {
		case true: punish_client(client, GetRandomInt(1, 6));
		case false: punish_client(client, bodyshot_punish.IntValue);
	}
	
	g_Bodyshot[client] = 0;
}

void punish_client(int client, int punishment) {
	switch(punishment) {
		case 1:	KickClient(client, "[Anti-Bodyshot] Kicked for doing too many bodyshots (Limit: %d)", bodyshot_limit.IntValue);
		case 2:	TF2_MakeBleed(client, client, 10.0);
		case 3:	TF2_IgnitePlayer(client, client);
		case 4:	ServerCommand("sm_freeze #%i", GetClientUserId(client));
		case 5:	ServerCommand("sm_timebomb #%i", GetClientUserId(client));
		case 6:	FakeClientCommandEx(client, killroll[GetRandomInt(0, 1)]);
	}
}

bool IsValidClient(int client) {
	if(client < 1 || client > MaxPlayers) return false;
	if(!IsValidEntity(client)) return false;
	if(!IsClientConnected(client)) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientReplay(client)) return false;
	if(IsClientSourceTV(client)) return false;
	if(IsClientObserver(client)) return false;
	if(GetClientTeam(client) < 1) return false;
	return true;
}