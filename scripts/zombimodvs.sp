/*
Class Base Speed Reference:
Scout - 400
Soldier - 240
Pyro - 300
Demoman - 280
Heavy - 230
Engineer - 300
Medic - 320
Sniper - 300
Spy - 300
*/


#pragma semicolon 1
#pragma tabsize 0
#define DEBUG

#define PLUGIN_AUTHOR "steamId=crackersarenoice"
#define PLUGIN_VERSION "1.02"
#define sarkir01 "left4fortress/rabies01.mp3"
#define PLAYERBUILTOBJECT_ID_DISPENSER 0
#define PLAYERBUILTOBJECT_ID_TELENT    1
#define PLAYERBUILTOBJECT_ID_TELEXIT   2
#define PLAYERBUILTOBJECT_ID_SENTRY    3

#define TF_CLASS_DEMOMAN		4
#define TF_CLASS_ENGINEER		9
#define TF_CLASS_HEAVY			6
#define TF_CLASS_MEDIC			5
#define TF_CLASS_PYRO				7
#define TF_CLASS_SCOUT			1
#define TF_CLASS_SNIPER			2
#define TF_CLASS_SOLDIER		3
#define TF_CLASS_SPY				8
#define TF_CLASS_UNKNOWN		0

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>


new Handle:zm_tDalgasuresi = INVALID_HANDLE;
new Handle:zm_tHazirliksuresi = INVALID_HANDLE;
new Handle:MusicCookie;
new bool:oyun;
new sayim;
new dalgasuresi;
new bool:kazanan;
//new bool:oyuncumuzik;
new sayimsetup;
new bool:timer1 = false;
new flspeed;

public Plugin:myinfo = 
{
	name = "Zombie Escape/Survival", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "tf2türkiye.com"
};
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plug-in only works for Team Fortress 2. // Eklenti sadece Team Fortress 2 için tasarlandı.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
public OnMapStart()
{  //Ayarların yüklenmesi.
	zombimod();
	setuptime();
	ServerCommand("mp_restartround 1");
}
public OnClientPutInServer(id)
{
	SDKHook(id, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnClientConnected(id)
{
	if (id > 0 && IsClientInGame(id) && dalgasuresi > 0 && oyun && TakimdakiOyuncular(3) > 0 && !IsPlayerAlive(id) && sayim <= 0)
	{
		ChangeClientTeam(id, 3);
	}
}
public OnPluginStart()
{
	//Konsol Komutları
	RegConsoleCmd("sm_msc", msc);
	RegConsoleCmd("sm_menu", zmenu);
	//Zamanlayıcılar
	CreateTimer(1.0, hazirlik, _, TIMER_REPEAT);
	CreateTimer(1.0, oyun1, _, TIMER_REPEAT);
	CreateTimer(200.0, yazi1, _, TIMER_REPEAT);
	CreateTimer(220.0, yazi2, _, TIMER_REPEAT);
	CreateTimer(120.0, yazi4, _, TIMER_REPEAT);
	CreateTimer(190.0, yazi3, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_SetTimeSetupSayim, _, TIMER_REPEAT);
	//Convarlar
	zm_tHazirliksuresi = CreateConVar("zm_setup", "30", "Setup suresi/Hazirlik Suresi", FCVAR_NOTIFY | FCVAR_PLUGIN);
	zm_tDalgasuresi = CreateConVar("zm_dalgasuresi", "380", "Setup bittikten sonraki round zamani", FCVAR_NOTIFY | FCVAR_PLUGIN);
	//Olaylar
	HookEvent("teamplay_round_start", round);
	HookEvent("player_death", death);
	HookEvent("player_spawn", spawn);
	HookEvent("player_builtobject", event_PlayerBuiltObject);
	HookEvent("teamplay_setup_finished", setup);
	HookEvent("teamplay_point_captured", captured, EventHookMode_Post);
	HookEvent("player_hurt", HookPlayerHurt);
	HookEvent("post_inventory_application", Event_Resupply);
	//Esas ayarlar
	//ServerCommand("sm_cvar tf_obj_upgrade_per_hit 0");
	//ServerCommand("sm_cvar tf_sentrygun_metal_per_shell 201");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_teams_unbalance_limit 0");
	ServerCommand("mp_respawnwavetime 0 ");
	ServerCommand("mp_restartgame 1 ");
	ServerCommand("mp_disable_respawn_times 1 ");
	ServerCommand("sm_cvar mp_waitingforplayers_time 0");
	//Tercihler
	MusicCookie = RegClientCookie("oyuncu_mzk_ayari", "Muzik Ayarı", CookieAccess_Public);
	//Komut takibi
	AddCommandListener(hook_JoinClass, "joinclass");
	AddCommandListener(BlockedCommands, "autoteam");
	AddCommandListener(BlockedCommandsteam, "jointeam");
}
public Action:Event_Resupply(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TFTeam_Blue)
	{
		zombi(client); //Oyuncular resupply cabinete dokunduğu zaman silahlarını tekrar silmek için. (Zombilerin)
	}
	
	return Plugin_Continue;
}

public HookPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(iUserId);
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client > 0 && IsClientInGame(client) && oyun && sayim <= 0)
	{
		if (GetClientTeam(client) == 3)
		{
			CreateTimer(4.0, Regenerate, client, TIMER_REPEAT); //Health regen zamanlayıcısı (5 saniyede +hp)
		}
	}
	new damagebits = GetEventInt(event, "damagebits");
	if (damagebits & DMG_FALL)
	{
		return;
	}
	if (attacker && TF2_GetPlayerClass(attacker) != TFClass_Scout) //Scoutun topları tek atmamalı.
	{
		zombi(client);
	}
}
public Action:Regenerate(Handle:timer, any:client)
{
	if (client > 0 && IsClientInGame(client))
	{
		new ClientHealth = GetClientHealth(client); //Şuanki hp
		new maxhp = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client); //Max hp
		if (ClientHealth < maxhp && GetClientTeam(client) == 3 && TF2_GetPlayerClass(client) != TFClass_Medic) //Oyuncunun o an sahip olduğu hp maxhp den büyük değilse regen verilebilir.
		{
			SetEntProp(client, Prop_Data, "m_iHealth", ClientHealth + 11); // +5hp
		}
		if (ClientHealth >= maxhp)
		{
			KillTimer(timer);
		}
	}
}
public Action:captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	kazanantakim(2);
	oyunuresetle(); //Control point capture edildiği zaman resetlenme gerçekleşicek
}
public Action:zmenu(client, args)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "ZF Esas Menü");
	DrawPanelItem(panel, "Yardim");
	DrawPanelItem(panel, "Tercihler");
	DrawPanelItem(panel, "Yapımcılar");
	DrawPanelItem(panel, "Kapat");
	SendPanelToClient(panel, client, panel_HandleMain, 10);
	CloseHandle(panel);
}
public panel_HandleMain(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				Yardim(param1);
			}
			case 2:
			{
				mzkv2(param1);
			}
			case 3:Yapimcilar(param1);
			default:return;
		}
	}
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
public Action:BlockedCommandsteam(client, const String:command[], argc)
{
	if (dalgasuresi > 0 && oyun) //Round başladığı halde oyuncular takım değiştirmeye çalışırsa engellensin
	{
		PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCOyun esnasında ya da setup zamanında takım değiştirilemez!");
		return Plugin_Handled; // Engellemeyi uygula
	}
	if (!oyun && sayim > 0 && sayim < 10 && TF2_GetClientTeam(client) != TFTeam_Blue && TF2_GetClientTeam(client) != TFTeam_Spectator) // Round başlamadığı zaman oyuncular zombi olmaya çalışırsa engellensin.
	{  // 10 saniye kala kimse takım değiştiremez.
		PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCOyun başlamadan zombi olamazsın!");
		return Plugin_Handled; //Engellemeyi uygula
	}
	return Plugin_Continue; // Eğer öyle bir olay yoksa da plugin çalışmaya devam edicek.
}
public Action:hook_JoinClass(client, const String:command[], argc)
{
	if (sayim <= 0 && oyun && TF2_GetClientTeam(client) == TFTeam_Red)
	{
		PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCOyun esnasında sınıf değiştiremezsin!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:setup(Handle:event, const String:name[], bool:dontBroadcast)
{
	zombimod(); //Round timerin işlemesi için
	PrintToChatAll("\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCHazırlık bitti!");
}
public Action:event_PlayerBuiltObject(Handle:event, const String:name[], bool:dontBroadcast) //Garip bir şekilde çalışmıyor.
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
public Action:round(Handle:event, const String:name[], bool:dontBroadcast)
{
	oyun = false; // Setup bitmeden round başlayamaz
	sayim = GetConVarInt(zm_tHazirliksuresi); //Setup zamanlayicisinin convarın değerini alması için
	dalgasuresi = GetConVarInt(zm_tDalgasuresi); //Round zamanlayicisinin convarın değerini alması için
	kazanan = false;
	zombimod();
	setuptime();
}
public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		if (!oyun && sayim > 0 && sayim <= zm_tHazirliksuresi)
		{
			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, 2);
			SetEntProp(client, Prop_Send, "m_lifeState", 0);
			TF2_RespawnPlayer(client);
			PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCOyun Başlamadan Zombi Olamazsın!");
		}
		if (oyun && dalgasuresi > 0 && dalgasuresi <= zm_tDalgasuresi)
		{
			SetEntityRenderColor(client, 0, 255, 0, 0);
			zombi(client);
			switch (TF2_GetPlayerClass(client))
			{
				case TFClass_Scout:
				{
					flspeed = 280.0;
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", flspeed);
				}
			}
		}
	} else {
		SetEntityRenderColor(client, 255, 255, 255, 0);
		discizgi();
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Spy:
			{
				TF2_RemoveWeaponSlot(client, 3);
			}
			case TFClass_Engineer:
			{
				if (sinifsayisi(TFClass_Engineer) > 2)
				{
					SetEntProp(client, Prop_Send, "m_lifeState", 2);
					TF2_SetPlayerClass(client, TFClass_Scout);
					SetEntProp(client, Prop_Send, "m_lifeState", 0);
					TF2_RespawnPlayer(client);
					PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCEngineer limiti aşıldı (2)!");
				}
			}
		}
	}
}
//ForcePlayerSuicide
public Action:death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	//CreateTimer(0.3, dogus, victim, TIMER_FLAG_NO_MAPCHANGE);
	//new deathFlags = GetUserFlagBits(victim);
	if (GetEventInt(event, "death_flags") & 32) // Sahte ölüm
	{
		return;
	}
	if (GetClientTeam(victim) == 2 && oyun)
	{
		zombi(victim);
		HUD(-1.0, 0.2, 6.0, 255, 0, 0, 2, "\n☠☠☠\n%N", victim);
	}
}
public Action:hazirlik(Handle:timer, any:client)
{
	sayim--;
	if (sayim <= zm_tHazirliksuresi && sayim > 0)
	{
		//izleyicikontrolu();
		HUD(-1.0, 0.2, 6.0, 255, 255, 0, 1, "Setup:%02d:%02d", sayim / 60, sayim % 60);
		HUD(0.02, 0.10, 1.0, 0, 255, 0, 5, "☠Z O M B I☠:%d", TakimdakiOyuncular(3));
		HUD(-0.02, 0.10, 1.0, 255, 255, 255, 6, "I N S A N:%d", TakimdakiOyuncular(2));
		dalgasuresi = GetConVarInt(zm_tDalgasuresi);
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
	if (dalgasuresi <= zm_tDalgasuresi && dalgasuresi > 0 && oyun)
	{
		//izleyicikontrolu();
		HUD(-1.0, 0.2, 6.0, 255, 255, 0, 1, "Round:%02d:%02d", dalgasuresi / 60, dalgasuresi % 60);
		HUD(0.02, 0.10, 1.0, 0, 255, 0, 5, "☠Zombiler☠:%d", TakimdakiOyuncular(3));
		HUD(-0.02, 0.10, 1.0, 255, 255, 255, 6, "İnsanlar:%d", TakimdakiOyuncular(2));
		if (TakimdakiOyuncular(2) == 0) //2 red 3 blue
		{
			kazanantakim(3);
			oyunuresetle();
		}
	}
	else if (dalgasuresi <= 0 && oyun)
	{
		if (TakimdakiOyuncular(2) > 0)
		{
			kazanantakim(2);
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
		SetEntityRenderColor(client, 0, 255, 0, 0);
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
public Action:yazi1(Handle:timer, any:id)
{
	PrintToChatAll("\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCHazırlık süresi 30(varsayılan) saniyedir.");
}
public Action:yazi2(Handle:timer, any:id)
{
	PrintToChatAll("\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCHayatta kalmaya çalışın!");
}
public Action:yazi3(Handle:timer, any:id)
{
	PrintToChatAll("\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCOyun içi müzikleri açmak veya kapatmak için [!msc] yazabilirsiniz.");
}
public Action:yazi4(Handle:timer, any:id)
{
	PrintToChatAll("\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCOyun hakkında bilgi için [!menu] yazabilirsiniz.");
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}
	new weaponId;
	(attacker == inflictor) ? (weaponId = ClientWeapon(attacker)) : (weaponId = inflictor); // Karsilastirma ? IfTrue : IfFalse;
	
	if (IsValidEntity(weaponId) && GetClientTeam(attacker) == 3)
	{  // weaponId != -1
		decl String:sWeapon[80];
		sWeapon[0] = '\0';
		GetEntityClassname(weaponId, sWeapon, 32);
		if (StrEqual(sWeapon, "tf_weapon_bat") || StrEqual(sWeapon, "tf_weapon_bat_fish") || 
			StrEqual(sWeapon, "tf_weapon_shovel") || StrEqual(sWeapon, "tf_weapon_katana") || StrEqual(sWeapon, "tf_weapon_fireaxe") || 
			StrEqual(sWeapon, "tf_weapon_bottle") || StrEqual(sWeapon, "tf_weapon_sword") || StrEqual(sWeapon, "tf_weapon_fists") || 
			StrEqual(sWeapon, "tf_weapon_wrench") || StrEqual(sWeapon, "tf_weapon_robot_arm") || StrEqual(sWeapon, "tf_weapon_bonesaw") || 
			StrEqual(sWeapon, "tf_weapon_club"))
		{
			//damage = 350.0;
			//return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
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
	SetVariantInt(GetConVarInt(zm_tHazirliksuresi));
	sayimsetup = sayim;
	AcceptEntityInput(ent1, "SetTime");
}
public Action:Timer_SetTimeSetupSayim(Handle:timer, any:id)
{
	if (sayim > 0)
	{
		sayimsetup--;
	}
}
zombimod()
{
	new ent = FindEntityByClassname(MaxClients + 1, "team_round_timer");
	if (ent == -1)
	{
		return;
	}
	decl String:mapv[6];
	GetCurrentMap(mapv, sizeof(mapv));
	if (!StrContains(mapv, "zf_", false))
	{
		if (sayim < 0 && sayimsetup <= 1)
		{
			timer1 = true;
		} else {
			timer1 = false;
		}
	}
	else if (!StrContains(mapv, "szf_", false))
	{
		if (sayim < 0 && sayimsetup <= 1)
		{
			timer1 = true;
		} else {
			timer1 = false;
		}
	}
	else if (!StrContains(mapv, "zm_", false))
	{
		if (sayim < 0 && sayimsetup <= 1)
		{
			timer1 = true;
		} else {
			timer1 = false;
		}
	}
	else if (!StrContains(mapv, "zom_", false))
	{
		if (sayim < 0 && sayimsetup <= 1)
		{
			timer1 = true;
		} else {
			timer1 = false;
		}
	}
	else if (!StrContains(mapv, "zs_", false))
	{
		if (sayim < 0 && sayimsetup <= 1)
		{
			timer1 = true;
		} else {
			timer1 = false;
		}
	}
	if (timer1)
	{
		CreateTimer(1.0, Timer_SetTime, ent, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:Timer_SetTime(Handle:timer, any:ent)
{
	SetVariantInt(GetConVarInt(zm_tDalgasuresi)); // 600 sec ~ 10min
	AcceptEntityInput(ent, "SetTime");
}
//mp_restartgame'dan daha çabuk yöntem.
oyunuresetle()
{
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
			SetEntProp(i, Prop_Send, "m_lifeState", 2); //Öldürmeden swap teams yapmak için.
			ChangeClientTeam(i, 2);
			SetEntProp(i, Prop_Send, "m_lifeState", 0); //Öldürmeden swap teams yapmak için.
			TF2_RespawnPlayer(i);
		}
	}
}
MuzikDurdurma(client)
{
	//StopSound(client, SNDCHAN_AUTO, snd1);
	PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCMüzikler durduruldu.");
}
MuzikAc(client)
{
	PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCMüzikler açıldı.");
}

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
	} else {
		strCookie = "0";
		SetClientCookie(client, MusicCookie, strCookie);
	}
}
stock bool:IsValidClient(client, bool:nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}
ClientWeapon(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}
//Menü Ayarları
Yardim(client)
{
	Menu hYardim = new Menu(yrd);
	hYardim.SetTitle("ZF Yardım Bölmesi(bilgi)");
	hYardim.AddItem("ZF Hakkında", "ZF Hakkında");
	hYardim.AddItem("Kapat", "Kapat");
	hYardim.ExitButton = false;
	hYardim.Display(client, 20);
}
public yrd(Handle hYardim, MenuAction action, client, item)
{
	if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0:
			{
				HakkindaK(client);
			}
			case 1:
			{
				CloseHandle(hYardim);
			}
		}
	}
}
public HakkindaK(client)
{
	new Handle:panel = CreatePanel();
	
	SetPanelTitle(panel, "ZF Hakkında");
	DrawPanelText(panel, "----------------------------------------------");
	DrawPanelText(panel, "Zombie Fortress, oyuncuları zombiler ve insanlar");
	DrawPanelText(panel, "arası ölümcül bir savaşa sokan custom moddur.");
	DrawPanelText(panel, "Insanlar bu bitmek bilmeyen salgında hayatta kalmalıdır.");
	DrawPanelText(panel, "Eğer insan infekte(ölürse) zombi olur.");
	DrawPanelText(panel, "----------------------------------------------");
	DrawPanelText(panel, "Modu Kodlayan:steamId=crackersarenoice - Deniz");
	DrawPanelItem(panel, "Yardım menüsüne geri dön.");
	DrawPanelItem(panel, "Kapat");
	SendPanelToClient(panel, client, panel_HandleOverview, 10);
	CloseHandle(panel);
}
public panel_HandleOverview(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:Yardim(param1);
			default:return;
		}
	}
}
public Yapimcilar(client)
{
	new Handle:panel = CreatePanel();
	
	SetPanelTitle(panel, "Yapimci");
	DrawPanelText(panel, "Kodlayan:steamId=crackersarenoice - Deniz");
	DrawPanelItem(panel, "Yardim Menüsüne Geri Dön");
	DrawPanelItem(panel, "Kapat");
	SendPanelToClient(panel, client, panel_HandleYapimci, 10);
	CloseHandle(panel);
}
public panel_HandleYapimci(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:Yardim(param1);
			default:return;
		}
	}
}
public mzkv2(client)
{
	new Handle:panel = CreatePanel();
	
	SetPanelTitle(panel, "Tercihler - Müzik");
	DrawPanelItem(panel, "Aç");
	DrawPanelItem(panel, "Kapa");
	DrawPanelItem(panel, "Yardım menüsüne geri dön.");
	DrawPanelItem(panel, "Kapat");
	SendPanelToClient(panel, client, panel_HandleMuzik, 10);
	CloseHandle(panel);
}
public panel_HandleMuzik(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:MuzikAc(param1), OyuncuMuzikAyari(param1, true);
			case 2:MuzikDurdurma(param1), OyuncuMuzikAyari(param1, false);
			case 3:Yardim(param1);
			default:return;
		}
	}
}
sinifsayisi(siniff)
{
	new iSinifNum;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && TF2_GetPlayerClass(i) == siniff && TF2_GetClientTeam(i) == TFTeam_Red)
		{
			iSinifNum++;
		}
	}
	return iSinifNum;
}
discizgi()
{
	//new color[4];
	//color[0] = 255;
	//color[1] = 255;
	//color[2] = 255;
	//color[3] = 255;
	new oyuncu[MaxClients + 1], num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			oyuncu[num++] = i;
			SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			//SetVariantColor(color);
		}
	}
} 