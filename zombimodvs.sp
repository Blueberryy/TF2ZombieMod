#pragma semicolon 1
#pragma tabsize 0
#define DEBUG

#define PLUGIN_AUTHOR "steamId=crackersarenoice"
#define PLUGIN_VERSION "0.10"
#define sarkir01 "left4fortress/rabies01.mp3"
#define PLAYERBUILTOBJECT_ID_DISPENSER 0
#define PLAYERBUILTOBJECT_ID_TELENT    1
#define PLAYERBUILTOBJECT_ID_TELEXIT   2
#define PLAYERBUILTOBJECT_ID_SENTRY    3

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>


//new Handle:zm_tDalgasuresi = INVALID_HANDLE;
//new Handle:zm_tHazirliksuresi = INVALID_HANDLE;
new Handle:MusicCookie;
new bool:oyun;
new sayim;
new dalgasuresi;
new bool:kazanan;
new bool:deneme = false;
new bool:oyuncumuzik;
new bool:mapzf = false;
new bool:setupbitimi = false;
new sayimsetup;

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
	zombimod();
	setuptime();
}
public OnClientPutInServer(id)
{
	SDKHook(id, SDKHook_OnTakeDamage, OnTakeDamage);
	xpoz[id][0] = 0.0, xpoz[id][1] = 0.0, xpoz[id][2] = 0.0;
}
public OnPluginStart()
{
	RegConsoleCmd("sm_msc", msc);
	RegConsoleCmd("sm_test", test);
	CreateTimer(1.0, hazirlik, _, TIMER_REPEAT);
	CreateTimer(1.0, oyun1, _, TIMER_REPEAT);
	CreateTimer(60.0, yazi1, _, TIMER_REPEAT);
	CreateTimer(120.0, yazi2, _, TIMER_REPEAT);
	CreateTimer(90.0, yazi3, _, TIMER_REPEAT);
	HookEvent("teamplay_round_start", round);
	HookEvent("player_death", death);
	HookEvent("player_spawn", spawn);
	HookEvent("player_builtobject", event_PlayerBuiltObject);
	HookEvent("teamplay_setup_finished", setup);
	//HookEvent("player_team", team);
	ServerCommand("sm_cvar tf_obj_upgrade_per_hit 0");
	ServerCommand("sm_cvar tf_sentrygun_metal_per_shell 201");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_teams_unbalance_limit 0");
	ServerCommand("mp_respawnwavetime 0 ");
	ServerCommand("mp_restartgame 1 ");
	ServerCommand("mp_disable_respawn_times 1 ");
	ServerCommand("sm_cvar mp_waitingforplayers_time 0");
	MusicCookie = RegClientCookie("oyuncu_mzk_ayari", "Muzik Ayarı", CookieAccess_Public);
	AddCommandListener(hook_JoinClass, "joinclass");
	AddCommandListener(BlockedCommands, "autoteam");
}
public mzk(Handle hMuzik, MenuAction action, client, item)
{
	if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0:
			{
				MuzikAc(client);
				OyuncuMuzikAyari(client, true);
			}
			
			case 1:
			{
				MuzikDurdurma(client);
				OyuncuMuzikAyari(client, false);
			}
		}
	}
}
public Action:BlockedCommands(client, const String:command[], argc)
{
	return Plugin_Handled;
}
public Action:hook_JoinClass(client, const String:command[], argc)
{
	if (dalgasuresi > 0 && oyun && TF2_GetClientTeam(client) != TFTeam_Blue)
	{
		PrintToChat(client, "[TF2Z]Oyun esnasında sınıf değiştiremezsin!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:setup(Handle:event, const String:name[], bool:dontBroadcast)
{
	setupbitimi = true;
}
public Action:event_PlayerBuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index1 = GetEventInt(event, "index");
	new object1 = GetEventInt(event, "object");
	if (object1 == PLAYERBUILTOBJECT_ID_DISPENSER)
	{
		SetEntProp(index1, Prop_Send, "m_bDisabled", 1);
		SetEntProp(index1, Prop_Send, "m_iMaxHealth", 250);
	}
	else if (object1 == PLAYERBUILTOBJECT_ID_SENTRY)
	{
		SetEntProp(index1, Prop_Send, "m_bDisabled", 1);
		SetEntProp(index1, Prop_Send, "m_iMaxHealth", 75);
	}
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
//----------------------MENU HANDLE------------------------------------------
public Action:msc(client, args)
{
	Menu hMuzik = new Menu(mzk);
	hMuzik.SetTitle("Müzik bölmesi");
	hMuzik.AddItem("Aç", "Aç");
	hMuzik.AddItem("Kapa", "Kapa");
	hMuzik.ExitButton = false;
	hMuzik.Display(client, 20);
	
}
///////////////////////////////////////////////////////////////////////////////
public Action:test(client, args)
{
	if (oyun)
	{
		PrintToChat(client, "Oyun:true");
		PrintToChat(client, "Hazırlık:%02d:%02d", sayim / 60, sayim % 60);
	}
	PrintToChat(client, "Red:%d", TakimdakiOyuncular(2));
	PrintToChat(client, "Blue:%d", TakimdakiOyuncular(3));
	//zombikacis();
	if (mapzf)
	{
		PrintToServer("[TF2Z]Harita ZF haritasidir.");
	}
	PrintToChat(client, "setup:%d", sayimsetup);
}
public Action:round(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	oyun = false;
	sayim = 30;
	dalgasuresi = 380;
	sayimsetup = 30;
	kazanan = false;
	zombimod();
	setuptime();
}
public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	//decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		//zombiee = true; gereksiz
		SetEntityHealth(client, 390);
		SetEntityRenderColor(client, 0, 255, 0, 0);
		if (!oyun && sayim > 0 && sayim <= 30)
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
			PrintToChat(client, "[TF2Z]Oyun Başlamadan Zombi Olamazsın!");
		}
		
		else if (oyun && dalgasuresi > 0 && dalgasuresi < 350)
		{
			SetEntityRenderColor(client, 0, 255, 0, 0);
			zombi(client);
			if (xpoz[client][0] != 0.0 && xpoz[client][1] != 0.0 && xpoz[client][2] != 0.0)
			{
				//Doğduğu yerde zombi olması. ya da zombi olduğu yerde doğması.
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
				//Escape modunda engineerler built yapamazlar.
				//TF2_RemoveWeaponSlot(client, 3);
			}
			case TFClass_Soldier:
			{
				//sınıflar arası dengeleme
				//TF2_RemoveWeaponSlot(client, 0);
				//PrintToChat(client, "[TF2Z]Soldierken zombilere karşı roketini kullanamazsın.");
			}
		}
	}
}
public Action:death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.3, dogus, victim, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:dogus(Handle:timer, any:id)
{
	if (TF2_GetClientTeam(id) == TFTeam_Red && oyun)
	{
		zombi(id);
		GetClientAbsOrigin(id, xpoz[id]);
		HUD(-1.0, 0.2, 6.0, 255, 0, 0, 2, "\n☠☠☠\n%N", id);
	}
}
public Action:hazirlik(Handle:timer, any:client)
{
	sayim--;
	if (sayim <= 30 && sayim > 0)
	{
		izleyicikontrolu();
		HUD(-1.0, 0.2, 6.0, 255, 255, 0, 1, "Hazırlık:%02d:%02d", sayim / 60, sayim % 60);
		HUD(0.02, 0.10, 1.0, 0, 255, 0, 5, "☠Z O M B I☠:%d", TakimdakiOyuncular(3));
		HUD(-0.02, 0.10, 1.0, 255, 255, 255, 6, "I N S A N:%d", TakimdakiOyuncular(2));
		//PrintHintTextToAll("Oyunun başlamasına::%02d:%02d", sayim / 60, sayim % 60);
		dalgasuresi = 350;
		oyun = false;
	} else {
		oyun = true;
		if (TakimdakiOyuncular(3) == 0)
		{
			zombi(rastgelezombi());
		}
	}
}

public Action:oyun1(Handle:timer, any:id)
{
	dalgasuresi--;
	if (dalgasuresi <= 350 && dalgasuresi > 0 && oyun)
	{
		izleyicikontrolu();
		HUD(-1.0, 0.2, 6.0, 255, 255, 0, 1, "Süre:%02d:%02d", dalgasuresi / 60, dalgasuresi % 60);
		HUD(0.02, 0.10, 1.0, 0, 255, 0, 5, "☠Z O M B I☠:%d", TakimdakiOyuncular(3));
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
			//ServerCommand("mp_restartgame 7 ");
			oyunuresetle();
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
			//kazanan = true;
			//ServerCommand("mp_restartgame 7 ");
			oyunuresetle();
		}
	}
}

stock rastgelezombi()
{
	new oyuncular[MaxClients + 1], num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			oyuncular[num++] = i;
		}
		//return oyuncular[GetRandomInt(0, num - 1)];
	}
	return (num == 0) ? 0 : oyuncular[GetRandomInt(0, num - 1)];
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
		kazanan = true;
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
public Action:yazi3(Handle:timer, any:id)
{
	PrintToChatAll("[TF2Z]Oyun içi müzikleri açmak veya kapatmak için [!msc] yazabilirsiniz.");
}
public Action:OnTakeDamage(id, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	//test edilicek!.
	new bool:bchanged;
	if (valid(id) && valid(attacker))
	{
		decl String:_weapon[32];
		GetEdictClassname(inflictor, _weapon, sizeof(_weapon));
		new String:cweapon[32];
		GetClientWeapon(attacker, cweapon, sizeof(cweapon));
		if (TF2_GetClientTeam(id) == TFTeam_Blue) // hasarı alan
		{
			if (!StrEqual(_weapon, "tf_weapon_grenadelauncher", false))
			{
				damage = 25.0;
				bchanged = true;
			}
		}
	}
	if (bchanged)return Plugin_Changed;
	return Plugin_Continue;
}
/*
-------------------ŞARKILAR-----------------------------
*/


/*
-------------------ZOMBİ KAÇIŞ BÖLÜMÜ-------------------
*/
// SETUP timerini değiştirdik
//Team round timer setup bitmeden setupun yerine geçtiğinden o  classname i kullandık.
setuptime()
{
	new ent1 = FindEntityByClassname(MaxClients + 1, "team_round_timer");
	if (ent1 == -1)
	{
		return;
	}
	if (sayim > 0)
	{
		CreateTimer(1.0, Timer_SetTimeSetup, ent1, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:Timer_SetTimeSetup(Handle:timer, any:ent1)
{
	SetVariantInt(30);
	sayimsetup--;
	AcceptEntityInput(ent1, "SetTime");
}
zombimod()
{
	new ent = FindEntityByClassname(MaxClients + 1, "team_round_timer");
	if (ent == -1)
	{
		return;
	}
	/*
	decl String:prefix[16];
	GetCurrentMap(prefix, sizeof(prefix));
	if(strcmp("zf_", prefix))
	{
		mapzf = true;
		CreateTimer(1.0, Timer_SetTime, ent, TIMER_FLAG_NO_MAPCHANGE);
    }
    else if(!strcmp("zf_", prefix))
    {
    	mapzf = false;
    }
    */
	decl String:mapv[256];
	GetCurrentMap(mapv, sizeof(mapv));
	if (!StrContains(mapv, "zf_", false)) //(strcmp("zf_%s", mapv))
	{
		if(sayim < 0)
		{
			CreateTimer(1.0, Timer_SetTime, ent, TIMER_FLAG_NO_MAPCHANGE);
	    }
		//CreateTimer(1.0, Timer_SetTime, ent, TIMER_FLAG_NO_MAPCHANGE);
		mapzf = true;
	} else {
		mapzf = false;
	}
}
public Action:Timer_SetTime(Handle:timer, any:ent)
{
	SetVariantInt(380); // 600 sec ~ 10min
	AcceptEntityInput(ent, "SetTime");
	//SetVariantInt(380); // 600 sec ~ 10min
	//AcceptEntityInput(ent, "SetTime");
}
zombikacis()
{
	new id = GetClientOfUserId(id);
	new bool:zombikaciss;
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	if (strcmp("ze_%s", map) && deneme)
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
//mp_restartgame'dan daha çabuk yöntem.
oyunuresetle()
{
	//new id = TakimdakiOyuncular(2);
	//new id1 = TakimdakiOyuncular(3);
	//new oyuncu[MaxClients + 1], num;
	if (kazanan)
	{
		CreateTimer(15.0, res, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:res(Handle:timer, any:id)
{
	new oyuncu[MaxClients + 1], num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			oyuncu[num++] = i;
			ChangeClientTeam(i, 2);
		}
	}
}
izleyicikontrolu()
{
	new id = GetClientOfUserId(id);
	new oyuncular[MaxClients + 1], num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 1)
		{
			oyuncular[num++] = i;
			if (!oyun && sayim > 0)
			{
				ChangeClientTeam(i, 2);
				PrintToChat(i, "[TF2Z]Oyun Başlarken İzleyici Mod'a geçilemez");
			} else {
				ChangeClientTeam(i, 3);
				PrintToChat(i, "[TF2Z]Oyun Başlarken İzleyici Mod'a geçilemez");
			}
		}
	}
}
MuzikDurdurma(client)
{
	//StopSound(client, SNDCHAN_AUTO, snd1);
	PrintToChat(client, "[TF2Z]Müzikler durduruldu.");
}
MuzikAc(client)
{
	//sesler = true;
	PrintToChat(client, "[TF2Z]Müzikler açıldı.");
}
//vsh
/*
SetClientSoundOptions(client, excepttype, bool:on)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	new String:strCookie[32];
	if (on) strCookie = "1";
	else strCookie = "0";
	if (excepttype == SOUNDEXCEPT_VOICE) SetClientCookie(client, VoiceCookie, strCookie);
	else SetClientCookie(client, MusicCookie, strCookie);
}
*/
OyuncuMuzikAyari(client, bool:acik)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	if (IsFakeClient(client))
	{
		return;
	}
	new String:strCookie[32];
	if (acik)
	{
		strCookie = "1";
		PrintToChat(client, "acik");
	} else {
		strCookie = "0";
		PrintToChat(client, "kapali");
		SetClientCookie(client, MusicCookie, strCookie);
	}
}
valid(id)
{
	if (id > 0 && id <= MaxClients && IsClientInGame(id))
	{
		return true;
	}
	return false;
} 