#pragma semicolon 1
#pragma tabsize 0
#define DEBUG

#define PLUGIN_AUTHOR "steamId=crackersarenoice"
#define PLUGIN_VERSION "0.10"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>



new bool:oyun;
new sayim;
new dalgasuresi;
new bool:zombiee;
//new dalga;
//new maxdalga = 10;
// red insan


public Plugin:myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_test", test);
	CreateTimer(1.0, hazirlik, _, TIMER_REPEAT);
	CreateTimer(1.0, oyun1, _, TIMER_REPEAT);
	HookEvent("teamplay_round_start", round);
	HookEvent("player_death", death);
	HookEvent("player_spawn", spawn);
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_teams_unbalance_limit 0");
}

public Action:test(client, args)
{
	if (oyun)
	{
		PrintToChatAll("true");
		PrintToChatAll("%02d:%02d", sayim / 60, sayim % 60);
	}
	PrintToChatAll("%d", TakimdakiOyuncular(2));
	PrintToChatAll("%d", TakimdakiOyuncular(3));
}
public Action:round(Handle:event, const String:name[], bool:dontBroadcast)
{
	oyun = false;
	sayim = 60;
	dalgasuresi = 120;
}
public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		zombiee = true;
		if (!oyun)
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
		}
		SetEntityRenderColor(client, 0, 255, 0, 0);
	} else {
		zombiee = false;
		SetEntityRenderColor(client, 255, 255, 255, 0);
	}
}
public Action:death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TF2_GetClientTeam(victim) == TFTeam_Red)
	{
		if (oyun)
		{
			zombi(victim);
		}
	}
}

public Action:hazirlik(Handle:timer, any:client)
{
	sayim--;
	if (sayim <= 60 && sayim > 0)
	{
		PrintHintTextToAll("Oyunun baþlamasýna::%02d:%02d", sayim / 60, sayim % 60);
		dalgasuresi = 120;
		oyun = false;
		if (client > 0 && TF2_GetClientTeam(client) == TFTeam_Blue && zombiee)
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
		}
	} else {
		oyun = true;
		zombi(rastgelezombi());
	}
}

public Action:oyun1(Handle:timer, any:id)
{
	dalgasuresi--;
	if (dalgasuresi <= 120 && dalgasuresi > 0 && oyun)
	{
		PrintHintTextToAll("Süre:%02d:%02d", dalgasuresi / 60, dalgasuresi % 60);
		for (new i = 0; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && id > 0)
			{
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
		if (TakimdakiOyuncular(2) == 0)
		{
			ServerCommand("mp_forcewin", 2);
		}
		if (dalgasuresi <= 0)
		{
			if (TakimdakiOyuncular(3) > 0)
			{
				SetCommandFlags("mp_forcewin", 3);
			}
			
			oyun = false;
			sayim = 60;
		}
	}
}

rastgelezombi()
{
	new oyuncular[MAXPLAYERS + 1];
	new num;
	for (new i = 0; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && TF2_GetClientTeam(i) != TFTeam_Spectator)
		{
			oyuncular[num++] = i;
		}
		return oyuncular[GetRandomInt(0, num - 1)];
	}
	return 0;
}

zombi(client)
{
	if (client > 0)
	{
		TF2_ChangeClientTeam(client, TFTeam_Blue);
	}
	CreateTimer(0.1, silah, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:silah(Handle:timer, any:client)
{
	for (new i = 0; i <= 5; i++)
	{
		if (client > 0 && i != 2 && TF2_GetClientTeam(client) == TFTeam_Blue)
		{
			TF2_RemoveWeaponSlot(client, i);
		}
	}
	if (client > 0)
	{
		new silah1 = GetPlayerWeaponSlot(client, 2);
		if (IsValidEdict(silah1))
		{
			EquipPlayerWeapon(client, silah1);
		}
	}
}
TakimdakiOyuncular(iTakim)
{
	new iSayi;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == iTakim)
		{
			iSayi++;
		}
	}
	return iSayi;
} 
