#pragma semicolon 1
#pragma tabsize 0
#define DEBUG

#define PLUGIN_AUTHOR "steamId=crackersarenoice"
#define PLUGIN_VERSION "0.10"
#define sarkir01 "left4fortress/rabies01.mp3"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>


//new Handle:zm_tDalgasuresi = INVALID_HANDLE;
//new Handle:zm_tHazirliksuresi = INVALID_HANDLE;
new bool:oyun;
new sayim;
new dalgasuresi;
//new bool:zombiee; gereksiz
//new dalga;
//new maxdalga = 10;
// red insan
//pozisyon
new Float:xpoz[MAXPLAYERS + 1][3];

public Plugin:myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};
public OnMapStart()
{
}
public OnClientPutInServer(id)
{
	SDKHook(id, SDKHook_OnTakeDamage, OnTakeDamage);
	xpoz[id][0] = 0.0, xpoz[id][1] = 0.0, xpoz[id][2] = 0.0;
}
public OnPluginStart()
{
	RegConsoleCmd("sm_test", test);
	CreateTimer(1.0, hazirlik, _, TIMER_REPEAT);
	CreateTimer(1.0, oyun1, _, TIMER_REPEAT);
	CreateTimer(15.0, yazi1, _, TIMER_REPEAT);
	CreateTimer(25.0, yazi2, _, TIMER_REPEAT);
	HookEvent("teamplay_round_start", round);
	HookEvent("player_death", death);
	HookEvent("player_spawn", spawn);
	//HookEvent("player_team", team);
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_teams_unbalance_limit 0");
	ServerCommand("mp_respawnwavetime 0 ");
	ServerCommand("mp_restartgame 1 ");
	ServerCommand("mp_disable_respawn_times 1 ");
}

/*
public Action:team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!oyun && sayim > 0)
	{
		if(TF2_GetClientTeam(id) == TFTeam_Blue)
		{
			TF2_ChangeClientTeam(id, TFTeam_Red);
		}
	}
}
*/

public Action:test(client, args)
{
	if (oyun)
	{
		PrintToChatAll("Oyun:true");
		PrintToChatAll("Hazırlık:%02d:%02d", sayim / 60, sayim % 60);
	}
	PrintToChatAll("Red:%d", TakimdakiOyuncular(2));
	PrintToChatAll("Blue:%d", TakimdakiOyuncular(3));
	//zombikacis();
}
public Action:round(Handle:event, const String:name[], bool:dontBroadcast)
{
	oyun = false;
	sayim = 30;
	dalgasuresi = 350;
}
public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		//zombiee = true; gereksiz
		SetEntityHealth(client, 390);
		SetEntityRenderColor(client, 0, 255, 0, 0);
		if (!oyun && sayim > 0 && sayim <= 30)
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
		}
		
		else if (oyun && dalgasuresi > 0 && dalgasuresi < 350)
		{
			zombi(client);
			if (xpoz[client][0] != 0.0 && xpoz[client][1] != 0.0 && xpoz[client][2] != 0.0)
			{
				TeleportEntity(client, xpoz[client], NULL_VECTOR, NULL_VECTOR);
				SetEntProp(client, Prop_Send, "m_bDucked", 1);
				xpoz[client][0] = 0.0, xpoz[client][1] = 0.0, xpoz[client][2] = 0.0;
			}
		}
		
	} else {
		//zombiee = false; gereksiz
		SetEntityRenderColor(client, 255, 255, 255, 0);
	}
	if (TF2_GetClientTeam(client) == TFTeam_Red)
	{
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Engineer:
			{
				TF2_RemoveWeaponSlot(client, 3);
				/*
				for (new i = 0; i <= target_count; i++)
				{
					new iEnt = -1;
					iEnt = FindEntityByClassname(iEnt, "obj_sentrygun");
					AcceptEntityInput(iEnt, "kill");
			    }
			    */
			}
		}
	}
}
public Action:death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	/*
	if (TF2_GetClientTeam(victim) == TFTeam_Red)
	{
		if (oyun)
		{
			zombi(victim);
			HUD(-1.0, 0.2, 6.0, 255, 0, 0, 2, "\n\n%N", victim);
		}
	}
	*/
	CreateTimer(0.3, dogus, victim, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:dogus(Handle:timer, any:id)
{
	if (TF2_GetClientTeam(id) == TFTeam_Red && oyun)
	{
		zombi(id);
		GetClientAbsOrigin(id, xpoz[id]);
		HUD(-1.0, 0.2, 6.0, 255, 0, 0, 2, "\n\n%N", id);
	}
}
public Action:hazirlik(Handle:timer, any:client)
{
	sayim--;
	if (sayim <= 30 && sayim > 0)
	{
		HUD(-1.0, 0.2, 6.0, 255, 255, 0, 1, "Hazırlık:%02d:%02d", sayim / 60, sayim % 60);
		HUD(0.02, 0.10, 1.0, 0, 255, 0, 5, "Z O M B I:%d", TakimdakiOyuncular(3));
		HUD(-0.02, 0.10, 1.0, 255, 255, 255, 6, "I N S A N:%d", TakimdakiOyuncular(2));
		//PrintHintTextToAll("Oyunun başlamasına::%02d:%02d", sayim / 60, sayim % 60);
		dalgasuresi = 350;
		oyun = false;
		/*
		if (client > 0 && TF2_GetClientTeam(client) == TFTeam_Blue && zombiee)
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
		}
		*/
	} else {
		oyun = true;
		zombi(rastgelezombi());
	}
}

public Action:oyun1(Handle:timer, any:id)
{
	dalgasuresi--;
	if (dalgasuresi <= 350 && dalgasuresi > 0 && oyun)
	{
		HUD(-1.0, 0.2, 6.0, 255, 255, 0, 1, "Süre:%02d:%02d", dalgasuresi / 60, dalgasuresi % 60);
		HUD(0.02, 0.10, 1.0, 0, 255, 0, 5, "Z O M B I:%d", TakimdakiOyuncular(3));
		HUD(-0.02, 0.10, 1.0, 255, 255, 255, 6, "I N S A N:%d", TakimdakiOyuncular(2));
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
		if (TakimdakiOyuncular(2) == 0) //2 red 3 blue
		{
			kazanantakim(3);
			ServerCommand("mp_restartgame 7 ");
		}
		else if (TakimdakiOyuncular(2) == 1)
		{
			//HUD(-1.0, 0.2, 6.0, 255, 255, 255, 1, "\n\n\nTEK KİŞİ KALDI!");
		}
	}
	else if (dalgasuresi <= 0 && oyun)
	{
		if (TakimdakiOyuncular(2) > 0)
		{
			kazanantakim(2);
			ServerCommand("mp_restartgame 7 ");
		}
	}
}

rastgelezombi()
{
	new oyuncular[MAXPLAYERS + 1];
	new num;
	for (new i = 1; i <= MaxClients; i++)
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
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, 3);
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
		//TF2_ChangeClientTeam(client, TFTeam_Blue);
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
	if (client > 0 && TF2_GetClientTeam(client) == TFTeam_Blue)
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
kazanantakim(takim)
{
	new ent = FindEntityByClassname(-1, "team_control_point_master"); //game_round_win
	if (ent == -1) // < 1  ya da == -1
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
	} else {
		SetVariantInt(takim);
		//AcceptEntityInput(ent, "Enable");SetTeam
		AcceptEntityInput(ent, "SetWinner");
	}
}
HUD(Float:x, Float:y, Float:Sure, r, g, b, kanal, const String:message[], any:...)
{
	SetHudTextParams(x, y, Sure, r, g, b, 255, 0, 6.0, 0.1, 0.2);
	new String:buffer[256];
	VFormat(buffer, sizeof(buffer), message, 9);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ShowHudText(i, kanal, buffer);
		}
	}
}

/*
---------------------CHAT TEXTLERİ---------------------
*/
public Action:yazi1(Handle:timer, any:id)
{
	PrintToChatAll("[TF2Z]Hazırlık süresi 30(varsayılan) saniyedir.");
}
public Action:yazi2(Handle:timer, any:id)
{
	PrintToChatAll("[TF2Z]Hayatta kalmaya çalışın!");
}
public Action:OnTakeDamage(id, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	//
}
/*
-------------------ŞARKILAR-----------------------------
*/


/*
-------------------ZOMBİ KAÇIŞ BÖLÜMÜ-------------------
*/

zombikacis()
{
	new id = GetClientOfUserId(id);
	new bool:zombikaciss;
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	if (strcmp("ze_%s", map))
	{
		zombikaciss = true;
		PrintToChatAll("[TF2Z]Ze modu aktifleştirildi.");
		if (TakimdakiOyuncular(3) > 0)
		{
			id = TakimdakiOyuncular(3);
			SetEntProp(id, Prop_Data, "m_iHealth", 500);
			SetEntProp(id, Prop_Send, "m_iMaxHealth", 500);
		}
		else if (TF2_GetClientTeam(id) == TFTeam_Red)
		{
			switch (TF2_GetPlayerClass(id))
			{
				case TFClass_Medic:
				{
					SetEntProp(id, Prop_Data, "m_iHealth", 90);
					SetEntProp(id, Prop_Send, "m_iMaxHealth", 90);
				}
				
			}
		}
	} else {
		LogError("[TF2Z]Zombie Escape Modu etkinleştirilmedi. Harita uygun değil.");
		zombikaciss = false;
	}
}

