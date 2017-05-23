/*
 *  Transparent Broadcast - One of the simplest broadcasting plugin
 *  
 *  Copyright (C) 2017 RumbleFrog
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#define PLUGIN_AUTHOR "Fishy"
#define PLUGIN_VERSION "1.0.2"

#include <sourcemod>
#include <morecolors>
#include <Transparent_Broadcast>

#pragma newdecls required

//<!-- Main -->
Database hDB;

int Row = 1;
int RowCount;

float Interval;
float CacheLife;

char Cache[512][3][255];
char Breed[32];
char GameType[32];

Handle Broadcast;
Handle CacheVoid;

Regex CountDown;

//<!-- Convars -->
ConVar cInterval;
ConVar cCacheLife;
ConVar cBreed;

public Plugin myinfo = 
{
	name = "Transparent Broadcast",
	author = PLUGIN_AUTHOR,
	description = "One of the simplest broadcasting plugin",
	version = PLUGIN_VERSION,
	url = "https://keybase.io/rumblefrog"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hDB = SQL_Connect("transparent_broadcast", true, error, err_max);
	
	if (hDB == INVALID_HANDLE)
		return APLRes_Failure;
	
	char TableCreateSQL[] = "CREATE TABLE IF NOT EXISTS `Transparent_Broadcast` ( `id` INT NOT NULL AUTO_INCREMENT , `message` TEXT NOT NULL , `type` VARCHAR(32) NOT NULL DEFAULT 'chat' , `breed` VARCHAR(255) NOT NULL DEFAULT 'global' , `game` VARCHAR(255) NOT NULL DEFAULT 'all' , `admin_only` TINYINT NOT NULL DEFAULT '0' , `enabled` TINYINT NOT NULL DEFAULT '1' , PRIMARY KEY (`id`), INDEX (`enabled`)) ENGINE = InnoDB CHARSET=utf8mb4 COLLATE utf8mb4_general_ci";
	
	SQL_SetCharset(hDB, "utf8mb4");
			
	hDB.Query(OnTableCreate, TableCreateSQL);
	
	RegPluginLibrary("Transparent_Broadcast");

	CreateNative("TB_AddBroadcast", NativeAddBroadcast);
	
	return APLRes_Success;
}

public void OnTableCreate(Database db, DBResultSet results, const char[] error, any pData)
{
	if (results == null)
		SetFailState("Unable to create table: %s", error);
}

public void OnPluginStart()
{
	RegexError CountDownError;
	char RegexErr[255];
	
	
	CreateConVar("sm_tb_version", PLUGIN_VERSION, "Transparent Broadcast Version", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	cInterval = CreateConVar("sm_tb_interval", "30.0", "TB Broadcasting Interval", FCVAR_NONE, true, 1.0);
	cCacheLife = CreateConVar("sm_tb_cachelife", "600.0", "TB Cache Lifespan", FCVAR_NONE, true, 60.0);
	cBreed = CreateConVar("sm_tb_breed", "global", "TB Global ID Identifier", FCVAR_NONE);
	
	AutoExecConfig(true, "Transparent_Broadcast");
	
	Interval = cInterval.FloatValue;
	HookConVarChange(cInterval, OnConvarChange);
	
	CacheLife = cCacheLife.FloatValue;
	HookConVarChange(cCacheLife, OnConvarChange);
	
	cBreed.GetString(Breed, sizeof Breed);
	HookConVarChange(cBreed, OnConvarChange);
	
	GetGameFolderName(GameType, sizeof GameType);
	
	CountDown = new Regex("{CountDown:([0-9]+)}", PCRE_CASELESS, RegexErr, sizeof RegexErr, CountDownError);
	
	if (CountDownError != REGEX_ERROR_NONE)
		SetFailState("Failed to compile regex: %s", RegexErr);
	
	LoadToCache();
	
	RegAdminCmd("sm_tbpreview", CmdPreview, ADMFLAG_CHAT, "Previews broadcast output");
	RegAdminCmd("sm_tbaddbroadcast", CmdAddBroadcast, ADMFLAG_CHAT, "Add a broadcast to database");
	RegAdminCmd("sm_tbreloadcache", CmdVoidCache, ADMFLAG_CHAT, "Voids cache");
	RegAdminCmd("sm_tbdumpcache", CmdDumpCache, ADMFLAG_CHAT, "Dumps cache");
	RegAdminCmd("sm_tbtriggerbroadcast", CmdTriggerBroadcast, ADMFLAG_CHAT, "Manually triggers broadcast");
	
	RegAdminCmd("tb_admin", CmdVoid, ADMFLAG_GENERIC, "Transparent Broadcast Admin Permission Check");
	
	Broadcast = CreateTimer(Interval, Timer_Broadcast, _, TIMER_REPEAT);
	CacheVoid = CreateTimer(CacheLife, Timer_CacheVoid, _, TIMER_REPEAT);
}

void LoadToCache()
{
	char Select_Query[1024];
	
	Format(Select_Query, sizeof Select_Query, "SELECT * FROM `Transparent_Broadcast` WHERE `breed` IN('global', '%%%s%%') AND `game` IN('all', '%%%s%%') AND `enabled` = 1", Breed, GameType);
	
	hDB.Query(SQL_OnLoadToCache, Select_Query);
}

public void SQL_OnLoadToCache(Database db, DBResultSet results, const char[] error, any pData)
{
	if (results == null)
		SetFailState("Failed to fetch broadcasts: %s", error); 
		
	RowCount = results.RowCount;
	
	if (Row > RowCount)
		Row = 1;
	
	for (int i = 1; i <= RowCount; i++)
	{
		results.FetchRow();
		
		results.FetchString(1, Cache[i][0], sizeof Cache[][]);
		results.FetchString(2, Cache[i][1], sizeof Cache[][]);
		results.FetchString(5, Cache[i][2], sizeof Cache[][]);
	}
}

public Action Timer_Broadcast(Handle timer)
{
	if (RowCount == 0)
		return;
		
	char Message[255];
	
	strcopy(Message, sizeof Message, Cache[Row][0]);
	
	TB_Type Type = GetBroadcastType(Cache[Row][1]);
	bool AdminOnly = (StringToInt(Cache[Row][2]) == 0) ? false : true;
	
	FormatArguments(Message, sizeof Message);
	
	switch (Type)
	{
		case TB_Chat:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (Client_IsValid(i) && PermCheck(AdminOnly, i))
					CPrintToChat(i, Message);
			}
		}
		case TB_Hint:
		{
			CRemoveTags(Message, sizeof Message);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (Client_IsValid(i) && PermCheck(AdminOnly, i))
					PrintHintText(i, Message);
			}
		}
		case TB_Center:
		{
			CRemoveTags(Message, sizeof Message);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (Client_IsValid(i) && PermCheck(AdminOnly, i))
					PrintCenterText(i, Message);
			}
		}
		case TB_Menu:
		{
			CRemoveTags(Message, sizeof Message);
			
			Panel hPl = new Panel();
			hPl.DrawText(Message);
			hPl.CurrentKey = 10;
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (Client_IsValid(i) && PermCheck(AdminOnly, i))
					hPl.Send(i, VoidMenu, 10);
			}
			
			delete hPl;
		}
	}
	
	if (Row >= RowCount)
		Row = 1;
	else
		Row++;
}

public Action Timer_CacheVoid(Handle timer)
{
	LoadToCache();
}

TB_Type GetBroadcastType(const char[] type)
{
	if (StrEqual(type, "chat", false))
		return TB_Chat;
		
	if (StrEqual(type, "hint", false))
		return TB_Hint;
		
	if (StrEqual(type, "center", false))
		return TB_Center;
		
	if (StrEqual(type, "menu", false))
		return TB_Menu;
		
	return TB_Invalid;
}

int GetBroadcastTypeInverse(TB_Type Type, char[] buffer, int size)
{
	switch(Type)
	{
		case TB_Chat:
		{
			Format(buffer, size, "chat");
			return 1;
		}
		case TB_Hint:
		{
			Format(buffer, size, "hint");
			return 1;
		}
		case TB_Center:
		{
			Format(buffer, size, "center");
			return 1;
		}
		case TB_Menu:
		{
			Format(buffer, size, "menu");
			return 1;
		}
		default:
			return -1;
	}
	
	return -1;
}

void FormatArguments(char[] Message, int size)
{
    char Replacement[64];
    RegexError ret;
    
    if (StrContains(Message, "\\n") != -1)
    {
        Format(Replacement, sizeof Replacement, "%c", 13);
        ReplaceString(Message, size, "\\n", Replacement);
    }
    
    int Count = CountDown.Match(Message, ret);
        
    if (Count > 0)
    {
        if (ret == REGEX_ERROR_NONE)
        {
            int CTime = GetTime(), TimeOffset, Days, Hours, Minutes, Seconds;
            char RegexMatch[64], RegexTime[32];
            
            for (int i = 0; i < Count; i++)
            {        	
                
                CountDown.GetSubString(0, RegexMatch, sizeof RegexMatch);
                CountDown.GetSubString(1, RegexTime, sizeof RegexTime);
                
                TimeOffset = (StringToInt(RegexTime) - CTime);
                
                Days = RoundToFloor((TimeOffset / 86400) * 1.0);
                Hours = RoundToFloor(((TimeOffset % 86400) / 3600) * 1.0);
                Minutes = RoundToFloor(((TimeOffset % 3600) / 60) * 1.0);
                Seconds = (TimeOffset % 60);
                
                Format(Replacement, sizeof Replacement, "%i days %i hours %i minutes and %i seconds", Days, Hours, Minutes, Seconds);
                
                ReplaceString(Message, size, RegexMatch, Replacement, false);
            }
        }
    }
    
    if (StrContains(Message, "{currentmap}", false) != -1)
    {
        GetCurrentMap(Replacement, sizeof Replacement);
        ReplaceString(Message, size, "{currentmap}", Replacement, false);
    }
    
    if (StrContains(Message, "{timeleft}", false) != -1)
    {
        int iMins, iSecs, iTimeLeft;
        
        if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0)
        {
            iMins = iTimeLeft / 60;
            iSecs = iTimeLeft % 60;
        }
        
        Format(Replacement, sizeof Replacement, "%d:%02d", iMins, iSecs);
        ReplaceString(Message, size, "{timeleft}", Replacement, false);
    }
    
    ConVar hConVar;
    char sConVar[64], sSearch[64], sReplace[64];
    int iEnd = -1, iStart = StrContains(Message, "{"), iStart2;
    
    while (iStart != -1)
    {
        
    	iEnd = StrContains(Message[iStart + 1], "}");
    
    	if (iEnd == -1)
        	break;
    
    	strcopy(sConVar, iEnd + 1, Message[iStart + 1]);
    	Format(sSearch, sizeof(sSearch), "{%s}", sConVar);
    
    	if ((hConVar = FindConVar(sConVar)))
    	{
        	hConVar.GetString(sReplace, sizeof sReplace);
        	ReplaceString(Message, size, sSearch, sReplace, false);
    	}
    
    	iStart2 = StrContains(Message[iStart + 1], "{");
        
        if (iStart2 == -1)
            break;
        
        iStart += iStart2 + 1;
    }
}

public void OnConvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == cBreed)
	{
		cBreed.GetString(Breed, sizeof Breed);
		LoadToCache();
	}
	if (convar == cCacheLife)
	{
		CacheLife = cCacheLife.FloatValue;
		KillTimer(CacheVoid);
		CacheVoid = CreateTimer(CacheLife, Timer_CacheVoid, _, TIMER_REPEAT);
	}
	if (convar == cInterval)
	{
		Interval = cInterval.FloatValue;
		KillTimer(Broadcast);
		Broadcast = CreateTimer(Interval, Timer_Broadcast, _, TIMER_REPEAT);
	}
}

public int NativeAddBroadcast(Handle plugin, int numParams)
{
	if (numParams > 6)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Requires 6 parameters");
		return;
	}
	
	TB_Type Type = view_as<TB_Type>(GetNativeCell(1));
	char Type_Buffer[16];
	
	if (GetBroadcastTypeInverse(Type, Type_Buffer, sizeof Type_Buffer) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid broadcast type");
		return;
	}
	
	int written;
	char Breed_Buffer[255], Game_Buffer[255], Message[255], Insert_Query[1024];
	
	GetNativeString(2, Breed_Buffer, sizeof Breed_Buffer);
	GetNativeString(3, Game_Buffer, sizeof Game_Buffer);
	
	int AO = GetNativeCell(4);
	int E = GetNativeCell(5);
	
	FormatNativeString(0, 6, 7, sizeof Message, written, Message);
	
	Format(Insert_Query, sizeof Insert_Query, "INSERT INTO `Transparent_Broadcast` (`message`, `type`, `breed`, `game`, `admin_only`, `enabled`) VALUES ('%s', '%s', '%s', '%s', '%i', '%i')", Message, Type_Buffer, Breed_Buffer, Game_Buffer, AO, E);
	
	hDB.Query(SQL_OnNativeAddBroadcast, Insert_Query);
}

public void SQL_OnNativeAddBroadcast(Database db, DBResultSet results, const char[] error, any pData)
{
	if (results == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Failed to insert broadcast");
		return;
	}
	
	LoadToCache();
}

public Action CmdTriggerBroadcast(int client, int args)
{
	if (Broadcast == INVALID_HANDLE)
	{
		ReplyToCommand(client, "Invalid timer");
		return Plugin_Handled;
	}
	
	TriggerTimer(Broadcast);
	
	return Plugin_Handled;
}

public Action CmdDumpCache(int client, int args)
{
	CPrintToChat(client, "{lightseagreen}[TB] {grey}Check console for output.");
	
	for (int i = 1; i <= RowCount; i++)
		PrintToConsole(client, "%s | %s | %s", Cache[i][0], Cache[i][1], Cache[i][2]);
		
	return Plugin_Handled;
}

public Action CmdVoidCache(int client, int args)
{
	LoadToCache();
	
	ReplyToCommand(client, "{lightseagreen}[TB] {grey}Cache Invalidated. Reloading...");
	
	return Plugin_Handled;
}

public Action CmdAddBroadcast(int client, int args)
{
	if (args < 6)
	{
		ReplyToCommand(client, "{lightseagreen}[TB] {aqua}sm_tbaddbroadcast {chartreuse}<type> <breed> <game> <admin_only?> <enabled?> <message>");
		return Plugin_Handled;
	}
	
	char Type_Buffer[16], Breed_Buffer[255], Game_Buffer[255], AO_Buffer[4], E_Buffer[4], Arg[64], Message[255];
	
	GetCmdArg(1, Type_Buffer, sizeof Type_Buffer);
	GetCmdArg(2, Breed_Buffer, sizeof Breed_Buffer);
	GetCmdArg(3, Game_Buffer, sizeof Game_Buffer);
	GetCmdArg(4, AO_Buffer, sizeof AO_Buffer);
	GetCmdArg(5, E_Buffer, sizeof E_Buffer);
	
	for (int i = 6; i <= args; i++)
	{
		GetCmdArg(i, Arg, sizeof Arg);
		Format(Message, sizeof Message, "%s %s", Message, Arg);
	}
	
	TB_Type Type = GetBroadcastType(Type_Buffer);
	bool AO = view_as<bool>(StringToInt(AO_Buffer));
	bool E = view_as<bool>(StringToInt(E_Buffer));
	
	TB_AddBroadcast(Type, Breed_Buffer, Game_Buffer, AO, E, Message);
	
	return Plugin_Handled;
}

public Action CmdPreview(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "{lightseagreen}[TB] {aqua}sm_previewtb {chartreuse}<type> <message>");
		return Plugin_Handled;
	}
	
	TB_Type Type;
	char TypeBuffer[32], Arg[64], Message[255];
	
	GetCmdArg(1, TypeBuffer, sizeof TypeBuffer);
	
	for (int i = 2; i <= args; i++)
	{
		GetCmdArg(i, Arg, sizeof Arg);
		Format(Message, sizeof Message, "%s %s", Message, Arg);
	}
	
	Type = GetBroadcastType(TypeBuffer);
	
	switch (Type)
	{
		case TB_Chat:
			CPrintToChat(client, Message);
		case TB_Hint:
		{
			CRemoveTags(Message, sizeof Message);
			
			PrintHintText(client, Message);
		}
		case TB_Center:
		{
			CRemoveTags(Message, sizeof Message);
			
			PrintCenterText(client, Message);
		}
		case TB_Menu:
		{
			CRemoveTags(Message, sizeof Message);
			
			Panel hPl = new Panel();
			hPl.DrawText(Message);
			hPl.CurrentKey = 10;
			
			hPl.Send(client, VoidMenu, 10);
			
			delete hPl;
		}
	}
	
	return Plugin_Handled;
}

public Action CmdVoid(int client, int args)
{
	ReplyToCommand(client, "Voided");
	
	return Plugin_Handled;
}

public int VoidMenu(Menu menu, MenuAction action, int param1, int param2) {}

bool PermCheck(bool AdminOnly, int client)
{
	if (AdminOnly == false || CheckCommandAccess(client, "tb_admin", ADMFLAG_GENERIC))
		return true;
		
	return false;
}

stock bool Client_IsValid(int iClient, bool bAlive = false)
{
	if (iClient >= 1 && iClient <= MaxClients && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) &&
	
	(bAlive == false || IsPlayerAlive(iClient)))
	{
		return true;
	}

	return false;
}