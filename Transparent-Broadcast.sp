#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Fishy"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>

#pragma newdecls required

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
	
	//Tickets table must be created before others due to foreign key references	
	char TableCreateSQL[] = "CREATE TABLE IF NOT EXISTS `Transparent_Broadcast` ( `id` INT NOT NULL AUTO_INCREMENT , `message` TEXT NOT NULL , `type` VARCHAR(32) NOT NULL DEFAULT 'chat' , `breed` VARCHAR(32) NOT NULL DEFAULT 'global' , `game` VARCHAR(32) NOT NULL DEFAULT 'all' , `admin_only` TINYINT NOT NULL DEFAULT '0' , `enabled` TINYINT NOT NULL DEFAULT '1' , PRIMARY KEY (`id`), INDEX (`enabled`)) ENGINE = InnoDB CHARSET=utf8mb4 COLLATE utf8mb4_general_ci; Close";
	
	SQL_SetCharset(hDB, "utf8mb4");
			
	hDB.Query(OnTableCreate, TableCreateSQL, _, DBPrio_High);
	
	RegPluginLibrary("TB");

	//CreateNative("TB_AddBroadcast", NativeAddNotification);
	
	return APLRes_Success;
}

public void OnTableCreate(Database db, DBResultSet results, const char[] error, any pData)
{
	if (results == null)
	{
		SetFailState("Unable to create table: %s", error);
	}
}

public void OnPluginStart()
{
	
}
