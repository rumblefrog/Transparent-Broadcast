#if defined _Transparent_Broadcast_included
 #endinput
#endif
#define _Transparent_Broadcast_included

enum TB_Type
{
	TB_Chat,
	TB_Hint,
	TB_Center,
	TB_Menu,
	TB_TotalCount,
	TB_Invalid
}

/**
* Add a broadcast to database
* 
* @param type			Broadcast type (Chat, Hint, Center, or Menu)
* @param format			Format
* @param ...			Any additional formating data
* @noreturn				
*/
native int TB_AddBroadcast(TB_Type type, const char[] format, any ...);


public SharedPlugin __pl_Transparent_Broadcast =
{
	name = "Transparent_Broadcast",
	file = "Transparent_Broadcast.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};


#if !defined REQUIRE_PLUGIN
public __pl_Transparent_Broadcast_SetNTVOptional()
{
	MarkNativeAsOptional("TB_AddBroadcast");
}
#endif