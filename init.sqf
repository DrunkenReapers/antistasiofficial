//Arma 3 - Antistasi by Barbolani
//Do whatever you want with this code, but credit me for the thousand hours spent making this.
enableSaving [ false, false ];

call AS_fnc_init_hq;

if (!isMultiPlayer) then {
    [] execVM "briefing.sqf";
    {if ((_x != comandante) and (_x != Petros) and (_x != server) and (_x!=garrison) and (_x != carreteras)) then {_grupete = group _x; deleteVehicle _x; deleteGroup _grupete}} forEach allUnits;
    [] execVM "musica.sqf";
    diag_log "Starting Antistasi SP";
    call compile preprocessFileLineNumbers "initVar.sqf";
    diag_log format ["Antistasi SP. InitVar done. Version: %1",antistasiVersion];
    call compile preprocessFileLineNumbers "initFuncs.sqf";
    diag_log "Antistasi SP. Funcs init finished";
    call compile preprocessFileLineNumbers "initZones.sqf";
    diag_log "Antistasi SP. Zones init finished";
    call compile preprocessFileLineNumbers "initPetros.sqf";
    lockedWeapons = lockedWeapons - unlockedWeapons;

    //Sparker's WarStatistics and roadblock spawning script. Remove these lines if you don't need it:
    //(from here)//
    call compile preprocessFileLineNumbers "WarStatistics\initVariables.sqf";
    call compile preprocessFileLineNumbers "WarStatistics\initFunctions.sqf";
    call compile preprocessFileLineNumbers "WarStatistics\initVariablesServer.sqf";
    //call compile preprocessFileLineNumbers "WarStatistics\initRoadblocks2.sqf";
    ws_grid = call ws_fnc_newGridArray;
    //(up to here)//

    HCciviles = 2;
    HCgarrisons = 2;
    HCattack = 2;
    hcArray = [HC1,HC2,HC3];
    serverInitDone = true;
    diag_log "Antistasi SP. serverInitDone is true. Arsenal loaded";
    [] execVM "modBlacklist.sqf";
};

waitUntil {(!isNil "saveFuncsLoaded") and (!isNil "serverInitDone")};

call jn_fnc_logistics_init;
cajaVeh call jn_fnc_garage_init;
caja call jn_fnc_arsenal_init;

[] execVM "Scripts\fn_advancedTowingInit.sqf";
[] execVM "Dialogs\welcome.sqf";

if(isServer) then {
    _serverHasID = profileNameSpace getVariable ["SS_ServerID",nil];
    if(isNil "_serverHasID") then {
        _serverID = str(round((random(100000)) + random 10000));
        profileNameSpace setVariable ["SS_ServerID",_serverID];
    };
    serverID = profileNameSpace getVariable "SS_ServerID";
    publicVariable "serverID";

    private _campaignID = round (random 100000);
    server setVariable ["AS_session_server", _campaignID, true];
    AS_session_server = _campaignID; publicVariable "AS_session_server";

    switchCom = false; publicVariable "switchCom";
    miembros = []; publicVariable "miembros";

    waitUntil {!isNil "serverID"};
    //enableRestart = [true, false] select (("AS_enableCampaignReset" call BIS_fnc_getParamValue) == 0);
    //publicVariable "enableRestart";
    if (serverName in servidoresOficiales) then {
        //[] execVM "orgPlayers\mList.sqf";
        [] call compile preprocessFileLineNumbers "orgPlayers\mList.sqf"; //Need to use this here, otherwise we get an empty miembros list by the time it is being checked further in this file. This would make some non-member a commander WITHOUT loading the campaign. Sparker.
        ["miembros"] call fn_loadData;

        //Output the member list
        diag_log "init.sqf: member list:";
        {
            diag_log format ["init.sqf: %1", _x];
        } forEach miembros;

        {
            if (([_x] call isMember) AND (isNull Slowhand)) then {
                Slowhand = _x;
                _x setRank "LIEUTENANT";
                [_x,"LIEUTENANT"] remoteExec ["ranksMP"];
                diag_log format ["init.sqf: selected commander from member list: %1", Slowhand];
            };
        } forEach playableUnits;
        publicVariable "Slowhand";
        diag_log format ["init.sqf: commander is: %1", Slowhand];
        if (isNull Slowhand) then {
            [] spawn AS_fnc_autoStart;
            diag_log "Antistasi MP Server. Players are in, no members";
        } else {
            diag_log "Antistasi MP Server. Players are in, member detected";
        };
    } else {
        waitUntil {!isNil "Slowhand"};
        waitUntil {isPlayer Slowhand};
    };
    fpsCheck = [] execVM "fpsCheck.sqf";
    [caja] call cajaAAF;
    if (activeJNA) then {
        ["complete"] call AS_fnc_JNA_pushLists;
    };
    [unlockedWeapons] spawn AS_fnc_weaponsCheck;
    diag_log "init.sqf: waiting for placementDone to be true...";
    waitUntil {!(isNil "placementDone")};
    diag_log "init.sqf: placementDone = true";
    distancias = [] spawn distancias3;
    resourcecheck = [] execVM "resourcecheck.sqf";
};

//Check worldname on dedicated server: is it altis or Altis? Sparker.
diag_log format ["Antistasi worldName: %1",worldName];