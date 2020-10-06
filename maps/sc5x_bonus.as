//Original By Adambean, Multilanguage Support By Lt.
CCVar@ cvar_SeekerType;
CCVar@ cvar_RandomSelectionTime;
float randomSelectionTime;
#include "../xp_phrase"

CBasePlayer@ FindSeeker()
{
    CBaseEntity@ pSeekerEntity = g_EntityFuncs.FindEntityByTargetname(null, "seeker");
    if (pSeekerEntity is null) {
        return null;
    }

    if (!pSeekerEntity.IsPlayer()) {
        return null;
    }

    CBasePlayer@ pSeeker = cast<CBasePlayer@>(pSeekerEntity);
    if (!pSeeker.IsConnected()) {
        return null;
    }

    return pSeeker;
}

void MapLoop()
{
    CBaseEntity@ pSeekerEntity  = null;
    CBasePlayer@ pSeeker        = null;
    CBasePlayer@ pPlayer        = null;

    // Player enforcements
    for (int i = 1; i <= g_Engine.maxClients; i++) {
        @pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);

        if (pPlayer is null) {
            continue;
        }

        if (!pPlayer.IsPlayer() or !pPlayer.IsConnected()) {
            continue;
        }

        // Restrict 3rd person view
        pPlayer.SetViewMode(ViewMode_FirstPerson);

        // Maximum speed
        /* Game version 5.23+ method... As of 5.23 the map will be able to do this itself without a script.
        if (g_Game.GetGameVersion() >= 523) {
            int iPlayerMaxSpeed = 270;
            if (pPlayer.pev.targetname == "seeker") {
                iPlayerMaxSpeed = 360;
            }
            if (pPlayer.GetMaxSpeed() != iPlayerMaxSpeed) {
                pPlayer.SetMaxSpeed(iPlayerMaxSpeed);
            }
        }
         */
        /* Game version 5.22- method...
         */
        if (g_Game.GetGameVersion() < 523) {
            float flPlayerSpeed = 270.0;
            if (pPlayer.pev.targetname == "seeker") {
                flPlayerSpeed = 360.0;
            }
            if (pPlayer.pev.maxspeed != flPlayerSpeed) {
                pPlayer.pev.maxspeed = flPlayerSpeed;
            }
        }
    }

    // Check the seeker is still valid, clean up otherwise
    @pSeekerEntity = g_EntityFuncs.FindEntityByTargetname(null, "seeker");
    if (pSeekerEntity !is null) {
        if (pSeekerEntity.IsPlayer()) {
            @pSeeker = cast<CBasePlayer@>(pSeekerEntity);

            if (!pSeeker.IsConnected()) {
                // Player is not connected, convert to hider
                pSeeker.pev.targetname = "hider";
                g_EntityFuncs.FireTargets("respawn_one", pSeeker, pSeeker, USE_TOGGLE, 0);
            }
        } else {
            // Entity is not a player
            pSeekerEntity.pev.targetname = "";
        }
    }

    // Seeker status message
    @pSeeker = FindSeeker();
    HUDTextParams sSeekerStatusMsgParams;

    sSeekerStatusMsgParams.channel      = 3;
    sSeekerStatusMsgParams.r1           = 100;
    sSeekerStatusMsgParams.g1           = 0;
    sSeekerStatusMsgParams.b1           = 0;
    sSeekerStatusMsgParams.r2           = 240;
    sSeekerStatusMsgParams.g2           = 0;
    sSeekerStatusMsgParams.b2           = 0;
    sSeekerStatusMsgParams.effect       = 1;
    sSeekerStatusMsgParams.fadeinTime   = 0;
    sSeekerStatusMsgParams.fadeoutTime  = 0;
    sSeekerStatusMsgParams.fxTime       = 0.1;
    sSeekerStatusMsgParams.holdTime     = 1.1;
    sSeekerStatusMsgParams.x            = -1;
    sSeekerStatusMsgParams.y            = 0.85;

    string szSeekerStatusMsg = "";
    if (pSeeker !is null) {
        sSeekerStatusMsgParams.g1       = 50;
        sSeekerStatusMsgParams.g2       = 120;
        sSeekerStatusMsgParams.effect   = 0;
 
    }
	int leftTime = 0;
	bool IsSekerSelectedByRandom = cvar_SeekerType.GetInt() == 1;
	if(IsSekerSelectedByRandom && pSeeker is null)
	{
		if(randomSelectionTime == -1)
		{				
			if(cvar_RandomSelectionTime.GetFloat() < 1.0)
			{
				randomSelectionTime = g_Engine.time - 0.1;
			}
			else
			{
				randomSelectionTime = g_Engine.time + cvar_RandomSelectionTime.GetFloat();
			}
		}
		leftTime = int(randomSelectionTime - g_Engine.time);
		
		if(leftTime <= 0)
		{
			CBasePlayer@ cRandom = GetRandomPlayer();
			if(cRandom !is null)
			{
				SetSeeker(@cRandom);
				ClientPrintAllML("SKR_RANDOM_SEEKER", {cRandom.pev.netname});
			}
			randomSelectionTime == -1;
		}
	}
	else
	{
		if(randomSelectionTime != -1) randomSelectionTime = -1;
	}
	
	
	//for ML Support
	for (int i = 1; i <= g_Engine.maxClients; i++) {
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if (pPlayer is null ||!pPlayer.IsPlayer() or !pPlayer.IsConnected()) continue;
		if(pSeeker !is null)
		{
			szSeekerStatusMsg = MLText(pPlayer, "SKR_CURRENT", {pSeeker.pev.netname});
		}
		else
		{
			if(IsSekerSelectedByRandom)
			{
				szSeekerStatusMsg = MLText(pPlayer, "SKR_STATUS_TIMER", {leftTime});
			}
			else
			{
				szSeekerStatusMsg = MLText(pPlayer, "SKR_STATUS");
			}

		}
		g_PlayerFuncs.HudMessage(pPlayer, sSeekerStatusMsgParams, szSeekerStatusMsg);
		
	}
    //g_PlayerFuncs.HudMessageAll(sSeekerStatusMsgParams, szSeekerStatusMsg);
}
CBasePlayer@ GetRandomPlayer()
{
	array<CBasePlayer@> players;
	uint totalplayer = 0;
    for (int i = 1; i <= g_Engine.maxClients; i++) {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer is null || !pPlayer.IsPlayer() or !pPlayer.IsConnected() || pPlayer.pev.targetname == "seeker") {
            continue;
        }
		players.insertLast(pPlayer);
		totalplayer++;
    }
	if(totalplayer == 0) return null;
	return @players[Math.RandomLong(0, totalplayer -1)];
}


void MapInit()
{
    g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
    g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
    g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @PlayerKilled);

    g_Scheduler.SetInterval("MapLoop", 1, -1);
	RegisterMLDirect("scripts/maps/sc5x_bonus.txt");
	@cvar_SeekerType = @CCVar("seeker_type", 0, "0: Manuel, 1: Random", ConCommandFlag::AdminOnly);
	@cvar_RandomSelectionTime = @CCVar("seeker_randomtime", 10, "Random seeker selecting cooldown", ConCommandFlag::AdminOnly);
	randomSelectionTime = -1;
}

HookReturnCode ClientSay(SayParameters@ pParams)
{
    CBasePlayer@ pPlayer    = pParams.GetPlayer();
    const CCommand@ args    = pParams.GetArguments();
    string szResponse       = "";

    if (pPlayer is null) {
        return HOOK_CONTINUE;
    }

    if (!pPlayer.IsPlayer() or !pPlayer.IsConnected()) {
        return HOOK_CONTINUE;
    }

    if (args.ArgC() < 1 || args[0][0] != ".") {
        return HOOK_CONTINUE;
    }

    if (!pPlayer.IsAlive()) {
        g_PlayerFuncs.SayText(pPlayer, MLText(pPlayer, "SKR_ERR_ALIVE"));
    }

    // Become a hider
    if (args[0] == ".hider") {
        if (pPlayer.pev.targetname == "hider") {
            g_PlayerFuncs.SayText(pPlayer, MLText(pPlayer, "SKR_ERR_ALHIDER"));

            return HOOK_HANDLED;
        }

        pPlayer.pev.targetname = "hider";
        g_EntityFuncs.FireTargets("respawn_one", pPlayer, pPlayer, USE_TOGGLE, 0);
        g_PlayerFuncs.SayText(pPlayer, MLText(pPlayer, "SKR_HIDER"));

        return HOOK_HANDLED;
    }

    // Become the seeker
    if (args[0] == ".seeker") {
		if(cvar_SeekerType.GetInt() == 1)
		{
			ClientPrintAllML("SKR_ERR_SEEKER");
			return HOOK_HANDLED;
		}
        if (pPlayer.pev.targetname == "seeker") {
            g_PlayerFuncs.SayText(pPlayer, MLText(pPlayer, "SKR_ERR_ALSEEKER"));

            return HOOK_HANDLED;
        }

        CBasePlayer@ pSeeker = FindSeeker();
        if (pSeeker !is null) {
			szResponse = MLText(pPlayer, "SKR_ERR_SKR", {pSeeker.pev.netname});
            g_PlayerFuncs.SayText(pPlayer, szResponse);

            return HOOK_HANDLED;
        }
		SetSeeker(@pPlayer);
        return HOOK_HANDLED;
    }

    // Check who the seeker is
    if (args[0] == ".whoseeker") {
        CBasePlayer@ pSeeker = FindSeeker();
        if (pSeeker !is null) {
			ClientPrintAllML("SKR_WHO_FIND", { pSeeker.pev.netname});
            //snprintf(szResponse, "The current seeker is \"%1\".\n", pSeeker.pev.netname);
           // g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, szResponse);
        } else {
			ClientPrintAllML("SKR_WHO_NOTEXISTS");
            //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "There is currently no seeker. If you want to be the seeker say ''.seeker'' in text chat.\n");
        }

        return HOOK_HANDLED;
    }

    return HOOK_CONTINUE;
}
void SetSeeker(CBasePlayer@ pPlayer)
{
    pPlayer.pev.targetname = "seeker";
    g_EntityFuncs.FireTargets("respawn_one", pPlayer, pPlayer, USE_TOGGLE, 0);
	g_PlayerFuncs.SayText(pPlayer, MLText(pPlayer, "SKR_SEEKER"));
}
void ClientPrintAllML(string mlName, array<string> params = {})
{
	for (int i = 1; i <= g_Engine.maxClients; i++) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if (pPlayer is null ||!pPlayer.IsPlayer() or !pPlayer.IsConnected()) continue;
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, MLText(pPlayer, mlName, params));
	}
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer)
{
    pPlayer.pev.targetname = "";
    return HOOK_HANDLED;
}

HookReturnCode PlayerKilled(CBasePlayer@ pKilledPlayer, CBaseEntity@ pKiller, int iInflictor)
{
    if (!pKiller.IsPlayer() || pKiller.pev.targetname != "seeker") {
        return HOOK_CONTINUE;
    }

    if (pKilledPlayer.pev.targetname != "hider") {
        return HOOK_CONTINUE;
    }

    CBasePlayer@ pSeeker = cast<CBasePlayer@>(pKiller);

    string szMessage = "";
	ClientPrintAllML("SKR_CAUGHT", {pKilledPlayer.pev.netname, pSeeker.pev.netname});
    //snprintf(szMessage, "Hider \"%1\" has been caught by seeker \"%2\".\n", pKilledPlayer.pev.netname, pSeeker.pev.netname);
    //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, szMessage);
    return HOOK_HANDLED;
}
