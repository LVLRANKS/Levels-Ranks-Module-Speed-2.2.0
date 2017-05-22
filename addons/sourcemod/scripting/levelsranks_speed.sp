#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int		g_iSpeedLevel,
		g_iSpeedActivator[MAXPLAYERS+1];
float		g_fSpeedCount;
Handle	g_hSpeed = null;

public Plugin myinfo = {name = "[LR] Module - Speed", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS: LogMessage("[%s Speed] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Speed] Плагин работает только на CS:GO и CS:S", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("player_spawn", PlayerSpawn);
	g_hSpeed = RegClientCookie("LR_Speed", "LR_Speed", CookieAccess_Private);
	LoadTranslations("levels_ranks_speed.phrases");
	
	for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
		if(IsClientInGame(iClient))
		{
			if(AreClientCookiesCached(iClient))
			{
				OnClientCookiesCached(iClient);
			}
		}
	}
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/speed.ini");
	KeyValues hLR_Speed = new KeyValues("LR_Speed");

	if(!hLR_Speed.ImportFromFile(sPath) || !hLR_Speed.GotoFirstSubKey())
	{
		SetFailState("[%s Speed] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_Speed.Rewind();

	if(hLR_Speed.JumpToKey("Settings"))
	{
		g_iSpeedLevel = hLR_Speed.GetNum("rank", 0);
		g_fSpeedCount = hLR_Speed.GetFloat("value", 1.2);
	}
	else SetFailState("[%s Speed] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_Speed;
}

public void PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{	
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(iClient) && !g_iSpeedActivator[iClient] && (LR_GetClientRank(iClient) >= g_iSpeedLevel))
	{
		SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", g_fSpeedCount);
	}
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == g_iSpeedLevel)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);

		if(LR_GetClientRank(iClient) >= g_iSpeedLevel)
		{
			switch(g_iSpeedActivator[iClient])
			{
				case 0: FormatEx(sText, sizeof(sText), "%t", "Speed_On", g_fSpeedCount);
				case 1: FormatEx(sText, sizeof(sText), "%t", "Speed_Off", g_fSpeedCount);
			}

			hMenu.AddItem("Speed", sText);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%t", "Speed_RankClosed", g_fSpeedCount, g_iSpeedLevel);
			hMenu.AddItem("Speed", sText, ITEMDRAW_DISABLED);
		}
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == g_iSpeedLevel)
	{
		if(strcmp(sInfo, "Speed") == 0)
		{
			switch(g_iSpeedActivator[iClient])
			{
				case 0: g_iSpeedActivator[iClient] = 1;
				case 1: g_iSpeedActivator[iClient] = 0;
			}
			
			LR_MenuInventory(iClient);
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sCookie[8];
	GetClientCookie(iClient, g_hSpeed, sCookie, sizeof(sCookie));
	g_iSpeedActivator[iClient] = StringToInt(sCookie);
} 

public void OnClientDisconnect(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		char sBuffer[8];
		FormatEx(sBuffer, sizeof(sBuffer), "%i", g_iSpeedActivator[iClient]);
		SetClientCookie(iClient, g_hSpeed, sBuffer);		
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}