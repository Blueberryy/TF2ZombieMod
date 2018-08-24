#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#define FFADE_IN            (0x0001)        // Just here so we don't pass 0 into the function
#define FFADE_OUT           (0x0002)        // Fade out (not in)
#define FFADE_MODULATE      (0x0004)        // Modulate (don't blend)
#define FFADE_STAYOUT       (0x0008)        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE         (0x0010)        // Purges all other fades, replacing them with this one

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

new UserMsg:g_FadeUserMsgId;

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
	HookEvent("player_spawn", spawn);
	HookEvent("player_death", death);
	g_FadeUserMsgId = GetUserMessageId("Fade");
}
public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == TFTeam_Blue)
	{
		SetClientOverlay(client, "debug/yuv");
		BlindPlayer(client, 155);
        }
        else if(GetClientTeam(client) == TFTeam_Red)
        {
        	        SetClientOverlay(client, " ");
        }
	CreateTimer(10.0, thingo, client, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	BlindPlayer(client, 255);
	CreateTimer(8.0, thingo, client, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:thingo(Handle:timer, any:client)
{
	BlindPlayer(client, 0);
}
SetClientOverlay(client, String:strOverlay[])
{
	new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	
	ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
}
BlindPlayer(client, iAmount)
{
	new iTargets[2];
	iTargets[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, iTargets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if(iAmount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}else{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, iAmount);
	
	EndMessage();
}