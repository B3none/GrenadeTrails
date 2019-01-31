#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

Handle g_Enabled = INVALID_HANDLE;
Handle g_AllowPlayers = INVALID_HANDLE;
Handle g_DefaultAlpha = INVALID_HANDLE;
Handle g_DefaultOn = INVALID_HANDLE;
Handle g_EnableHETrails = INVALID_HANDLE;
Handle g_EnableFlashTrails = INVALID_HANDLE;
Handle g_EnableSmokeTrails = INVALID_HANDLE;
Handle g_EnableDecoyTrails = INVALID_HANDLE;
Handle g_EnableMolotovTrails = INVALID_HANDLE;
Handle g_EnableIncTrails = INVALID_HANDLE;
Handle g_HEColor = INVALID_HANDLE;
Handle g_FlashColor = INVALID_HANDLE;
Handle g_SmokeColor = INVALID_HANDLE;
Handle g_DecoyColor = INVALID_HANDLE;
Handle g_MolotovColor = INVALID_HANDLE;
Handle g_IncColor = INVALID_HANDLE;
Handle g_TrailTime = INVALID_HANDLE;
Handle g_TrailFadeTime = INVALID_HANDLE;
Handle g_TrailWidth = INVALID_HANDLE;

int g_iBeamSprite;
bool Trails[MAXPLAYERS+1];

// Temp array since you can't return arrays
TempColorArray[] = {0, 0, 0, 0};

// List of colors since I couldn't get Enum Arrays to work
g_ColorAqua[] = {0,255,255};
g_ColorBlack[] = {0,0,0};
g_ColorBlue[] = {0,0,255};
g_ColorFuschia[] = {255,0,255};
g_ColorGray[] = {128,128,128};
g_ColorGreen[] = {0,128,0};
g_ColorLime[] = {0,255,0};
g_ColorMaroon[] = {128,0,0};
g_ColorNavy[] = {0,0,128};
g_ColorRed[] = {255,0,0};
g_ColorWhite[] = {255,255,255};
g_ColorYellow[] = {255,255,0};
g_ColorSilver[]	= {192,192,192};
g_ColorTeal[] = {0,128,128};
g_ColorPurple[] = {128,0,128};
g_ColorOlive[] = {128,128,0};

public Plugin myinfo =
{
	name = "Grenade Trails",
	author = "B3none",
	version = "1.0.0",
	description = "Add grenade trails",
	url = "https://github.com/b3none"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_grenade_trails", Cmd_Trails, "Toggles grenade trails.");
	
	// CVARs
	g_Enabled = CreateConVar("sm_grenade_trails_enabled", "1", "Enables Grenade Trails (0/1).", _, true, 0.0, true, 1.0);
	g_AllowPlayers = CreateConVar("sm_grenade_trails_allowplayers", "1", "Allow players to use nade Trails with !trails (0/1)", _, true, 0.0, true, 1.0);
	g_DefaultAlpha = CreateConVar("sm_grenade_trails_defaultalpha", "255", "Default alpha for trails (0 is invisible, 255 is solid).", _, true, 0.0, true, 255.0);
	g_DefaultOn = CreateConVar("sm_grenade_trails_default_on", "1", "Trails on for all users, Set to 0 to require user to type !trails to use", _, true, 0.0, true, 1.0);
	
	// Grenades to put trails on
	g_EnableHETrails = CreateConVar("sm_grenade_trails_hegrenade", "1", "Enables Grenade Trails on HE Grenades (0/1).", _, true, 0.0, true, 1.0);
	g_EnableFlashTrails = CreateConVar("sm_grenade_trails_flashbang", "1", "Enables Grenade Trails on Flashbangs (0/1).", _, true, 0.0, true, 1.0);
	g_EnableSmokeTrails = CreateConVar("sm_grenade_trails_smoke", "1", "Enables Grenade Trails on Smoke Grenades (0/1).", _, true, 0.0, true, 1.0);
	g_EnableDecoyTrails = CreateConVar("sm_grenade_trails_decoy", "1", "Enables Grenade Trails on Decoy Grenades (0/1).", _, true, 0.0, true, 1.0);
	g_EnableMolotovTrails = CreateConVar("sm_grenade_trails_molotov", "1", "Enables Grenade Trails on Molotovs (0/1).", _, true, 0.0, true, 1.0);
	g_EnableIncTrails = CreateConVar("sm_grenade_trails_incendiary", "1", "Enables Grenade Trails on Incendiary Grenades (0/1).", _, true, 0.0, true, 1.0);
	
	//TE_SetupBeamFollow CVARs -- Colors
	g_HEColor = CreateConVar("sm_grenade_trails_hecolor", "random", "Trail color on HE Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_FlashColor = CreateConVar("sm_grenade_trails_flashcolor", "random", "Trail color on Flashbangs. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_SmokeColor = CreateConVar("sm_grenade_trails_smokecolor", "random", "Trail color on Smoke Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_DecoyColor = CreateConVar("sm_grenade_trails_decoycolor", "random", "Trail color on Decoy Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20,147 225\"");
	g_MolotovColor = CreateConVar("sm_grenade_trails_molotovcolor", "random", "Trail color on Molotovs. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	g_IncColor = CreateConVar("sm_grenade_trails_inccolor", "random", "Trail color on Incendiary Grenades. (use named colors like \"Aqua\" or \"Black\" or use RGBA like \"255 20 147 225\"");
	
	//size and time
	g_TrailTime = CreateConVar("sm_grenade_trails_Trailtime", "20.0", "Time the trail stays visible.", _, true, 0.0, true, 25.0);
	g_TrailFadeTime = CreateConVar("sm_grenade_trails_Trailfadetime", "1", "Time for trail to fade over.", _);
	g_TrailWidth = CreateConVar("sm_grenade_trails_Trailwidth", "1.0", "Width of the trail.", _);
	
	AutoExecConfig(true);
}

public void OnClientPutInServer(int client)
{
	Trails[client] = false;
}

public Action Cmd_Trails(int client, int args)
{
	if(!GetConVarBool(g_Enabled))
	{
		ReplyToCommand(client, "Grenade Trails is disabled");
	}
	else if(GetConVarBool(g_AllowPlayers))
	{
		Trails[client] = !Trails[client];
		ReplyToCommand(client, "Grenade Trails %s", Trails[client] ? "Enabled" : "Disabled");
	}
	else 
	{
		ReplyToCommand(client, "Grenade Trails is not authorized for players to use");
	}
	
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
		{
			TempColorArray[3] = 225;
		}
		else
		{
			TempColorArray[3] = StringToInt(sTemp[3]);
		}
	}
}

public void OnEntityCreated(int entity, const char []classname)
{
	if(GetConVarBool(g_Enabled) && IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned); // Don't show trails if we disable the plugin while people have trails enabled
	}
}

public void OnEntitySpawned(int entity)
{
	char class_name[32];
	GetEdictClassname(entity, class_name, 32);
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if(StrContains(class_name, "projectile") != -1 && IsValidEntity(entity) && (((GetConVarBool(g_AllowPlayers) || isOwner(owner)) && Trails[owner]) || GetConVarBool(g_DefaultOn)))
	{
		if(StrContains(class_name, "hegrenade") != -1 && GetConVarBool(g_EnableHETrails))
		{
			GetSetColor(g_HEColor);
		}
		else if(StrContains(class_name, "flashbang") != -1 && GetConVarBool(g_EnableFlashTrails))
		{
			GetSetColor(g_FlashColor);
		}
		else if(StrContains(class_name, "smoke") != -1 && GetConVarBool(g_EnableSmokeTrails))
		{
			GetSetColor(g_SmokeColor);
		}
		else if(StrContains(class_name, "decoy") != -1 && GetConVarBool(g_EnableDecoyTrails))
		{
			GetSetColor(g_DecoyColor);
		}
		else if(StrContains(class_name, "molotov") != -1 && GetConVarBool(g_EnableMolotovTrails))
		{
			GetSetColor(g_MolotovColor);
		}
		else if(StrContains(class_name, "incgrenade") != -1 && GetConVarBool(g_EnableIncTrails))
		{
			GetSetColor(g_IncColor);
		}
		
		TE_SetupBeamFollow(entity, g_iBeamSprite, 0, GetConVarFloat(g_TrailTime), GetConVarFloat(g_TrailWidth), GetConVarFloat(g_TrailWidth), GetConVarInt(g_TrailFadeTime), TempColorArray);
		TE_SendToAll();
	}
}

public bool isOwner(int client)
{
	return CheckCommandAccess(client, "Trails_menu", ADMFLAG_ROOT);
}
