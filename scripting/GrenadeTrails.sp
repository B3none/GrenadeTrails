/*
*   THIS IS NOT MY CODE I HAVE UPDATED IT TO THE LATEST SYNTAX
*   ORIGINAL AUTHOR: https://forums.alliedmods.net/member.php?u=248386
*   ORIGINAL PLUGIN: https://forums.alliedmods.net/showthread.php?t=240668
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

Handle g_Enabled = INVALID_HANDLE;
Handle g_AllowPlayers = INVALID_HANDLE;
Handle g_DefaultAlpha = INVALID_HANDLE;
Handle g_DefaultOn = INVALID_HANDLE;
Handle g_EnableHETails = INVALID_HANDLE;
Handle g_EnableFlashTails = INVALID_HANDLE;
Handle g_EnableSmokeTails = INVALID_HANDLE;
Handle g_EnableDecoyTails = INVALID_HANDLE;
Handle g_EnableMolotovTails = INVALID_HANDLE;
Handle g_EnableIncTails = INVALID_HANDLE;
Handle g_HEColor = INVALID_HANDLE;
Handle g_FlashColor = INVALID_HANDLE;
Handle g_SmokeColor = INVALID_HANDLE;
Handle g_DecoyColor = INVALID_HANDLE;
Handle g_MolotovColor = INVALID_HANDLE;
Handle g_IncColor = INVALID_HANDLE;
Handle g_TailTime = INVALID_HANDLE;
Handle g_TailFadeTime = INVALID_HANDLE;
Handle g_TailWidth = INVALID_HANDLE;

any g_iBeamSprite;
bool Tails[MAXPLAYERS+1];

TempColorArray[] = {0, 0, 0, 0}; //temp array since you can't return arrays

//Ugly list of colors since I couldn't get Enum Arrays to work
g_ColorAqua[] 	= {0,255,255};
g_ColorBlack[]	= {0,0,0};
g_ColorBlue[] 	= {0,0,255};
g_ColorFuschia[] 	= {255,0,255};
g_ColorGray[] 	= {128,128,128};
g_ColorGreen[] 	= {0,128,0};
g_ColorLime[] 	= {0,255,0};
g_ColorMaroon[] 	= {128,0,0};
g_ColorNavy[] 	= {0,0,128};
g_ColorRed[] 		= {255,0,0};
g_ColorWhite[] 	= {255,255,255};
g_ColorYellow[]	= {255,255,0};
g_ColorSilver[]	= {192,192,192};
g_ColorTeal[]		= {0,128,128};
g_ColorPurple[]	= {128,0,128};
g_ColorOlive[]	= {128,128,0};
//end colors

public Plugin myinfo =
{
	name = "Nade Tails",
	author = "InternetBully, edits by B3none",
	version = "2.0",
	description = "Adds tails to projectiles // Updated to new syntax by B3none",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_tails", Cmd_Tails, "Toggles grenade tails.");
	
	//CVARs
	g_Enabled 				= CreateConVar("sm_tails_enabled", "1", "Enables Nade Tails (0/1).", _, true, 0.0, true, 1.0);
	g_AllowPlayers 		= CreateConVar("sm_tails_allowplayers", "1", "Allow players to use nade tails with !tails (0/1)", _, true, 0.0, true, 1.0);
	g_DefaultAlpha		= CreateConVar("sm_tails_defaultalpha", "255", "Default alpha for trails (0 is invisible, 255 is solid).", _, true, 0.0, true, 255.0);
	g_DefaultOn			= CreateConVar("sm_tails_defaulton", "1", "Tails on for all users, Set to 0 to require user to type !tails to use", _, true, 0.0, true, 1.0);
	
	//Projectiles to put tails on
	g_EnableHETails		= CreateConVar("sm_tails_hegrenade", "1", "Enables Nade Tails on HE Grenades (0/1).", _, true, 0.0, true, 1.0);
	g_EnableFlashTails	= CreateConVar("sm_tails_flashbang", "1", "Enables Nade Tails on Flashbangs (0/1).", _, true, 0.0, true, 1.0);
	g_EnableSmokeTails	= CreateConVar("sm_tails_smoke", "1", "Enables Nade Tails on Smoke Grenades (0/1).", _, true, 0.0, true, 1.0);
	g_EnableDecoyTails	= CreateConVar("sm_tails_decoy", "1", "Enables Nade Tails on Decoy Grenades (0/1).", _, true, 0.0, true, 1.0);
	g_EnableMolotovTails	= CreateConVar("sm_tails_molotov", "1", "Enables Nade Tails on Molotovs (0/1).", _, true, 0.0, true, 1.0);
	g_EnableIncTails		= CreateConVar("sm_tails_incendiary", "1", "Enables Nade Tails on Incendiary Grenades (0/1).", _, true, 0.0, true, 1.0);
	
	//TE_SetupBeamFollow CVARs -- Colors
	g_HEColor				= CreateConVar("sm_tails_hecolor", "random", "Tail color on HE Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_FlashColor			= CreateConVar("sm_tails_flashcolor", "random", "Tail color on Flashbangs. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_SmokeColor			= CreateConVar("sm_tails_smokecolor", "random", "Tail color on Smoke Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_DecoyColor			= CreateConVar("sm_tails_decoycolor", "random", "Tail color on Decoy Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20,147 225\"");
	g_MolotovColor		= CreateConVar("sm_tails_molotovcolor", "random", "Tail color on Molotovs. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_IncColor				= CreateConVar("sm_tails_inccolor", "random", "Tail color on Incendiary Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	
	//size and time
	g_TailTime 			= CreateConVar("sm_tails_tailtime", "20.0", "Time the tail stays visible.", _, true, 0.0, true, 25.0);
	g_TailFadeTime		= CreateConVar("sm_tails_tailfadetime", "1", "Time for tail to fade over.", _);
	g_TailWidth			= CreateConVar("sm_tails_tailwidth", "1.0", "Width of the tail.", _);
	
	AutoExecConfig(true);
}

public void OnClientPutInServer(int client)
{
	Tails[client] = false;
}

public Action Cmd_Tails(int client, int args)
{
	if(!GetConVarBool(g_Enabled))
		ReplyToCommand(client, "Nade Tails is disabled");
	else if(GetConVarBool(g_AllowPlayers))
	{
		Tails[client] = !Tails[client];
		ReplyToCommand(client, "Nade Tails %s", Tails[client] ? "Enabled" : "Disabled");
	}
	else 
		ReplyToCommand(client, "Nade Tails is not authorized for players to use");
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

Action GetSetColor(Handle hColorCvar)
{
	char sCvar[32];
	GetConVarString(hColorCvar, sCvar, sizeof(sCvar));
	
	if(StrContains(sCvar, "aqua", false) != -1)
	{
		TempColorArray[0] = g_ColorAqua[0];
		TempColorArray[1] = g_ColorAqua[1];
		TempColorArray[2] = g_ColorAqua[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "black", false) != -1)
	{
		TempColorArray[0] = g_ColorBlack[0];
		TempColorArray[1] = g_ColorBlack[1];
		TempColorArray[2] = g_ColorBlack[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "blue", false) != -1)
	{
		TempColorArray[0] = g_ColorBlue[0];
		TempColorArray[1] = g_ColorBlue[1];
		TempColorArray[2] = g_ColorBlue[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "fuschia", false) != -1)
	{
		TempColorArray[0] = g_ColorFuschia[0];
		TempColorArray[1] = g_ColorFuschia[1];
		TempColorArray[2] = g_ColorFuschia[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "gray", false) != -1)
	{
		TempColorArray[0] = g_ColorGray[0];
		TempColorArray[1] = g_ColorGray[1];
		TempColorArray[2] = g_ColorGray[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "green", false) != -1)
	{
		TempColorArray[0] = g_ColorGreen[0];
		TempColorArray[1] = g_ColorGreen[1];
		TempColorArray[2] = g_ColorGreen[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "lime", false) != -1)
	{
		TempColorArray[0] = g_ColorLime[0];
		TempColorArray[1] = g_ColorLime[1];
		TempColorArray[2] = g_ColorLime[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "maroon", false) != -1)
	{
		TempColorArray[0] = g_ColorMaroon[0];
		TempColorArray[1] = g_ColorMaroon[1];
		TempColorArray[2] = g_ColorMaroon[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "navy", false) != -1)
	{
		TempColorArray[0] = g_ColorNavy[0];
		TempColorArray[1] = g_ColorNavy[1];
		TempColorArray[2] = g_ColorNavy[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "red", false) != -1)
	{
		TempColorArray[0] = g_ColorRed[0];
		TempColorArray[1] = g_ColorRed[1];
		TempColorArray[2] = g_ColorRed[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "white", false) != -1)
	{
		TempColorArray[0] = g_ColorWhite[0];
		TempColorArray[1] = g_ColorWhite[1];
		TempColorArray[2] = g_ColorWhite[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "yellow", false) != -1)
	{
		TempColorArray[0] = g_ColorYellow[0];
		TempColorArray[1] = g_ColorYellow[1];
		TempColorArray[2] = g_ColorYellow[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "silver", false) != -1)
	{
		TempColorArray[0] = g_ColorSilver[0];
		TempColorArray[1] = g_ColorSilver[1];
		TempColorArray[2] = g_ColorSilver[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "teal", false) != -1)
	{
		TempColorArray[0] = g_ColorTeal[0];
		TempColorArray[1] = g_ColorTeal[1];
		TempColorArray[2] = g_ColorTeal[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "purple", false) != -1)
	{
		TempColorArray[0] = g_ColorPurple[0];
		TempColorArray[1] = g_ColorPurple[1];
		TempColorArray[2] = g_ColorPurple[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "olive", false) != -1)
	{
		TempColorArray[0] = g_ColorOlive[0];
		TempColorArray[1] = g_ColorOlive[1];
		TempColorArray[2] = g_ColorOlive[2];
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, "random", false) != -1)
	{
		TempColorArray[0] = GetRandomInt(0,255);
		TempColorArray[1] = GetRandomInt(0,255);
		TempColorArray[2] = GetRandomInt(0,255);
		TempColorArray[3] = GetConVarInt(g_DefaultAlpha);
	}
	else if(StrContains(sCvar, " ") != -1) //this is a manually entered color
	{
		char sTemp[4][6];
		ExplodeString(sCvar, " ", sTemp, sizeof(sTemp), sizeof(sTemp[]));
		TempColorArray[0] = StringToInt(sTemp[0]);
		TempColorArray[1] = StringToInt(sTemp[1]);
		TempColorArray[2] = StringToInt(sTemp[2]);
		PrintToChatAll("%s", sTemp[3]);
		if(StrEqual(sTemp[3], ""))
			TempColorArray[3] = 225;
		else
			TempColorArray[3] = StringToInt(sTemp[3]);
	}
}

public void OnEntityCreated(int entity, const char []classname)
{
	if(GetConVarBool(g_Enabled) && IsValidEntity(entity)) SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned); //don't draw tails if we disable the plugin while people have tails enabled
}

public void OnEntitySpawned(int entity)
{
	char class_name[32];
	GetEdictClassname(entity, class_name, 32);
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if(StrContains(class_name, "projectile") != -1 && IsValidEntity(entity) && (((GetConVarBool(g_AllowPlayers) || isOwner(owner)) && Tails[owner]) || GetConVarBool(g_DefaultOn)))
	{
		if(StrContains(class_name, "hegrenade") != -1 && GetConVarBool(g_EnableHETails))
			GetSetColor(g_HEColor);
		else if(StrContains(class_name, "flashbang") != -1 && GetConVarBool(g_EnableFlashTails))
			GetSetColor(g_FlashColor);
		else if(StrContains(class_name, "smoke") != -1 && GetConVarBool(g_EnableSmokeTails))
			GetSetColor(g_SmokeColor);
		else if(StrContains(class_name, "decoy") != -1 && GetConVarBool(g_EnableDecoyTails))
			GetSetColor(g_DecoyColor);
		else if(StrContains(class_name, "molotov") != -1 && GetConVarBool(g_EnableMolotovTails))
			GetSetColor(g_MolotovColor);
		else if(StrContains(class_name, "incgrenade") != -1 && GetConVarBool(g_EnableIncTails))
			GetSetColor(g_IncColor);
		TE_SetupBeamFollow(entity, g_iBeamSprite, 0, GetConVarFloat(g_TailTime), GetConVarFloat(g_TailWidth), GetConVarFloat(g_TailWidth), GetConVarInt(g_TailFadeTime), TempColorArray);
		TE_SendToAll();
	}
}

public bool isOwner(int client)
{
	return CheckCommandAccess(client, "tails_menu", ADMFLAG_ROOT);
}
