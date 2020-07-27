/*
Raptor Init field:

0 = this spawn{
  waitUntil{!(isNil "G_RAP_bDone")};
  waitUntil{G_RAP_bDone};
  sleep 20;
  GC = [(getPosATL _this), [], "alpha", _this] call Fnc_RAP_MkRaptor;
};
*/

G_RAP_bDone = false;

Fnc_RAP_MkRaptor  = {//call
if(isNil   "G_RAP_aRaptors") then{ G_RAP_aRaptors   = []; };
if(isNil "G_RAP_aCanAddRem") then{ G_RAP_aCanAddRem = true; };
//if(isNil  "G_RAP_spwMainAI") then{ G_RAP_spwMainAI  = ScriptNull; };

params["_Pos", "_aClass", "_Faction", "_RAPTOR"];
if((count _this) <= 3) then{ _RAPTOR = ObjNull; };

if((count _aClass) == 0) then{
_aClass = [
  "babe_RAPTOR_F", 
  "babe_RAPTOR_2_F", 
  "babe_RAPTOR_3_F", 
  "babe_RAPTOR_4_F", 
  "babe_RAPTOR_5_F", 
  "babe_RAPTOR_6_F", 
  "babe_RAPTORb_F", 
  "babe_RAPTORb_2_F", 
  "babe_RAPTORb_3_F", 
  "babe_RAPTORb_4_F", 
  "babe_RAPTORb_5_F", 
  "babe_RAPTORb_6_F"
];
};

if(isNull _RAPTOR) then{
  _RAPTOR = createAgent [(selectRandom _aClass), _Pos, [], 0, "CAN_COLLIDE"];
  _RAPTOR setDir 0;
} else{
  _Dir   = getDir _RAPTOR;
  _Class = typeOf _RAPTOR;
  deleteVehicle _RAPTOR;
  _RAPTOR = createAgent [_Class, _Pos, [], 0, "CAN_COLLIDE"];
  _RAPTOR setDir _Dir;
};
_RAPTOR setVectorUp (surfaceNormal (getPos _RAPTOR));
_RAPTOR disableAI "FSM";
_RAPTOR setBehaviour "CARELESS";

_RAPTOR setVariable ["BIS_fnc_animalBehaviour_disable", true];
_RAPTOR setVariable ["vRAP_aProcess", [
  ScriptNull, ScriptNull, ScriptNull, ScriptNull, ScriptNull, ScriptNull, ScriptNull
], false];
_RAPTOR setVariable ["vRAP_aSTATES",[
  ["PATROL",  ["Fnc_RAP_DoPATROL",  "Fnc_RAP_EndPATROL",  0]],
  ["CHASE",   ["Fnc_RAP_DoCHASE",   "Fnc_RAP_EndCHASE",   1]],
  ["ATTACK1", ["Fnc_RAP_DoATTACK1", "Fnc_RAP_EndATTACK1", 2]],
  ["ATTACK2", ["Fnc_RAP_DoATTACK2", "Fnc_RAP_EndATTACK2", 3]],
  ["TOEAT",   ["Fnc_RAP_DoTOEAT",   "Fnc_RAP_EndTOEAT",   4]],
  ["EATING",  ["Fnc_RAP_DoEATING",  "Fnc_RAP_EndEATING",  5]],
  ["UNCONS",  ["Fnc_RAP_DoUNCONS",  "Fnc_RAP_EndUNCONS",  6]]
], false];
_RAPTOR setVariable ["vRAP_WP0",         _Pos, false];//ATL
_RAPTOR setVariable ["vRAP_STATE",   "PATROL", false];
_RAPTOR setVariable ["vRAP_TARGET",   ObjNull, false];
_RAPTOR setVariable ["vRAP_bNoFallDmg", false, false];
_RAPTOR setVariable ["vRAP_TimeAttck1",  time, false];
_RAPTOR setVariable ["vRAP_TimeAttck2",  time, false];
_RAPTOR setVariable ["vRAP_ANIMevID",      -1, false];
_RAPTOR setVariable ["vRAP_tLastUncons", -999, false];
_RAPTOR setVariable ["vRAP_bOnAlert",   false, false];
_RAPTOR setVariable ["vRAP_bUnstuck",   false, false];
_RAPTOR setVariable ["vRAP_LastUnStuck", -999, false];
_RAPTOR setVariable ["vRAP_PosEat", (getPosWorld _RAPTOR), false];

_RAPTOR setVariable ["vRAP_PatrolRad",    1e2, false];
_RAPTOR setVariable ["vRAP_MaxChase",     300, false];
_RAPTOR setVariable ["vRAP_minRoamDist",   75, false];
_RAPTOR setVariable ["vRAP_Faction", _Faction, false];

_RAPTOR addEventHandler ["Hit",             Fnc_RAP_HndlHit];
_RAPTOR addEventHandler ["HandleDamage",    Fnc_RAP_HndlDmg];
_RAPTOR addEventHandler ["Killed",       Fnc_RAP_HndlKilled];
_RAPTOR addEventHandler ["FiredNear",     Fnc_RAP_HndlFNear];

G_RAP_aRaptors pushback _RAPTOR;
[_RAPTOR] call Fnc_RAP_DoPATROL;
//if(isNull G_RAP_spwMainAI) then{ G_RAP_spwMainAI = [] spawn Fnc_RAP_MainAI; };

_RAPTOR
};
Fnc_RAP_MainAI    = {//call not used anymore
private _TickMain = time;
private _TickTrgt = time;
private _TARGET   = ObjNull;

waitUntil{
if((time - _TickMain) >= 1) then{
G_RAP_aCanAddRem = false;

{//foreach G_RAP_aRaptors
  if(alive _x) then{
    if((_x getVariable ["vRAP_STATE", ""]) != "PATROL") then{
      //[_x] call Fnc_RAP_StateChange;
    };

    if((time - _TickTrgt) >= 2) then{
      if(_x getVariable ["vRAP_STATE", ""] == "PATROL") then{
        //[_x] call Fnc_RAP_getTarget;
      };
      _TickTrgt = time;
    };

    if(_x getVariable ["vRAP_STATE", ""] == "CHASE") then{
      _TARGET = _x getVariable ["vRAP_TARGET", ObjNull];
      _dCHASE = _x getVariable ["vRAP_MaxChase",   1e0];
      if(((getPosWorld _TARGET) vectorDistance (getPosWorld _x)) >= _dCHASE) then{
        [_x, "PATROL", [_x], true] call Fnc_RAP_ToState;
      } else{
        _x setDestination [(getPosATL _TARGET), "LEADER DIRECT", false];
        _x forceSpeed 8.33;
      };
    };
  };
}foreach G_RAP_aRaptors;

G_RAP_aCanAddRem = true;
_TickMain = time;
};

false
};

};
Fnc_RAP_getTarget = {//call
private _RAPTOR = _this select 0;

private _bCanTarget = false;
private _bTargetNOW = false;
private _TargObj    = ObjNull;
private _aTargets   = [];
private _DetectSpd  = 0;
private _Dist       = 0;
private _FACTN = _RAPTOR getVariable ["vRAP_Faction", ""];

_aTypes = ["LandVehicle", "Plane", "Helicopter", "Ship", "CAManBase", "Animal"];
{//foreach _aNear
  ScopeName "NearLoop";
  if((_x getVariable ["vRAP_Faction", ""]) != _FACTN) then{
    _bCanTarget = false;
    _bTargetNOW = false;
    _Dist = (getPosWorld _x) vectorDistance (getPosWorld _RAPTOR);

    switch (true) do{
      case (_x isKindOf "CAManBase") : {
        if((vehicle _x) == _x) then{
          switch (true) do{
            case((_Dist <=  50) && ((random 1) < 0.20)) : { _bTargetNOW = true; };//fast prone
            case(_Dist <=  50) : { _bTargetNOW = ((vectorMagnitude velocity _x) >= 1.50); };//fast prone
            case(_Dist <= 100) : { _bTargetNOW = ((vectorMagnitude velocity _x) >= 1.75); };//slow walk
            case(_Dist <= 200) : { _bCanTarget = ((vectorMagnitude velocity _x) >= 5.20); _bTargetNOW = false; };//slow jog
            default{ _bCanTarget = ((vectorMagnitude (velocity _x)) >= 6.50); _bTargetNOW = false; };
          };
          if(_bTargetNOW) then{ _TargObj = _x; breakOut "NearLoop"; };

          _bCanTarget = _bCanTarget && !(surfaceIsWater (getPosWorld _x));
          if(_bCanTarget)then{ _aTargets pushback _x; };
        };
      };
      case (_x isKindOf "Animal") : {
        _bCanTarget = _Dist <= 50;
        _bCanTarget = _bCanTarget && !(surfaceIsWater (getPosWorld _x));
        if(_bCanTarget) then{ _TargObj = _x; breakOut "NearLoop"; };
      };
      case ([(typeOf _x), ["Ship", "LandVehicle"]] call Fnc_IsKindOf) : {
        _bCanTarget = (({(alive _x)} count (crew _x)) >= 1);
        _bCanTarget = _bCanTarget || (isEngineOn _x);
        _bCanTarget = _bCanTarget && !(surfaceIsWater (getPosWorld _x));
        if(_bCanTarget)then{ _aTargets pushback _x; };
      };
      case ([(typeOf _x), ["Plane", "Helicopter"]] call Fnc_IsKindOf) : {
        _bCanTarget = (((getPosATL _x) select 2) <= 2);
        _bCanTarget = _bCanTarget && (({(alive _x)} count (crew _x)) >= 1);
        _bCanTarget = _bCanTarget || (isEngineOn _x);
        _bCanTarget = _bCanTarget && !(surfaceIsWater (getPosWorld _x));
        if(_bCanTarget)then{ _aTargets pushback _x; };
      };
    };
  };
}foreach ((getPosWorld _RAPTOR) nearEntities [_aTypes, 200]);

if(isNull _TargObj) then{
  if((count _aTargets) > 0) then{ _TargObj = (_aTargets select 0); };
};

private _bRet = false;
if(!(isNull _TargObj)) then{
  _RAPTOR setVariable ["vRAP_TARGET", _TargObj, false];
  _bRet = true;
};

_bRet
};
Fnc_RAP_ToState   = {//call
params["_RAPTOR", "_ToSTATE", "_aArg", "_bKill"];

private _aProc   = _RAPTOR getVariable ["vRAP_aProcess", []];
private _aStates = _RAPTOR getVariable ["vRAP_aSTATES",  []];
private _STATE0  = _RAPTOR getVariable ["vRAP_STATE",    ""];
private _iSTATE  = _aStates findIf {(_x select 0) == _STATE0};

if(_bKill) then{
if(_iSTATE != -1) then{
  _vState = (_aStates select _iSTATE) select 1;
  _iProc  = _vState select 2;

  terminate (_aProc select _iProc);
  _aProc set [_iProc, ScriptNull];
  _RAPTOR setVariable ["vRAP_aProcess", _aProc, false];

  [_RAPTOR] call (missionNamespace getVariable [(_vState select 1), "Fnc_Dummy"]);
};
};

_iSTATE  = _aStates findIf {(_x select 0) == _ToSTATE};
if(_iSTATE != -1) then{
  _aArg call (missionNamespace getVariable [(((_aStates select _iSTATE) select 1) select 0), "Fnc_Dummy"]);
};

};

Fnc_RAP_DoPATROL   = {//call
_GetNewPos = {
params["_RAPTOR"];

private _MaxRd = _RAPTOR getVariable ["vRAP_PatrolRad",  1e2];
private _MinD  = _RAPTOR getVariable ["vRAP_minRoamDist", 75];
private _CPos  = _RAPTOR getVariable ["vRAP_WP0", (getPosWorld _RAPTOR)];
private _RPos  = getPosWorld _RAPTOR;
        _RPos  = _RPos vectorAdd [0,0,-(_RPos select 2)]; 
private _Dist  = _RPos distance2D _CPos;
private _Pos   = [];

if(_Dist <= _MinD) then{
  _DirTo  = _RPos getDir _CPos;
  _MinRad = _MinD + _Dist + (random 25);
  _Pos = [_CPos, _MinRad, _MaxRd, (_DirTo-20), (_DirTo+20), 5, "MAN", "CCW", "NOLOSCHECK"] call Fnc_GetRadialPos;
} else{
  _aTmp    = [_RPos, _MinD, _CPos] call Fnc_GetArcTangentDirs;
  _DirFrom = _aTmp select 0;
  _DirTo   = _aTmp select 1;
  _Pos = [_CPos, 6, _MaxRd, _DirFrom, _DirTo, 5, "MAN", "CCW", "NOLOSCHECK"] call Fnc_GetRadialPos;
};

_Pos
};

params["_RAPTOR"];

private _MoveTo = [_RAPTOR] call _GetNewPos;
_RAPTOR setDestination [_MoveTo, "LEADER DIRECT", false];
_RAPTOR forceSpeed 8.33;//max spd: 30km/h - 8.33m/s
_RAPTOR setVariable ["MOVETO", _MoveTo, false];

_aStates = _RAPTOR getVariable ["vRAP_aSTATES",  []];
private _STATE  =  "PATROL";
private _iSTATE = _aStates findIf {(_x select 0) == _STATE};
        _iSTATE = ((_aStates select _iSTATE) select 1) select 2;

private _aSpawn = _RAPTOR getVariable ["vRAP_aProcess", []];
private _ProcID = ScriptNull;

if(isNull (_aSpawn select _iSTATE)) then{
  _ProcID = [_RAPTOR, _MoveTo] spawn Fnc_RAP_spwPATROL;
};

if(!(isNull _ProcID)) then{
  _aSpawn set [_iSTATE, _ProcID];
  _RAPTOR setVariable ["vRAP_aProcess", _aSpawn, false];
};

_RAPTOR setVariable ["vRAP_STATE", _STATE, false];
};
Fnc_RAP_DoCHASE    = {//call
params["_RAPTOR", "_TARGET"];
if(isNull _TARGET) exitwith{
  [_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
};

_RAPTOR setDestination [(getPosATL _TARGET), "LEADER DIRECT", false];
_RAPTOR forceSpeed 8.33;

_aStates = _RAPTOR getVariable ["vRAP_aSTATES",  []];
private _STATE  =  "CHASE";
private _iSTATE = _aStates findIf {(_x select 0) == _STATE};
        _iSTATE = ((_aStates select _iSTATE) select 1) select 2;

private _aSpawn = _RAPTOR getVariable ["vRAP_aProcess", []];
private _ProcID = ScriptNull;

if(isNull (_aSpawn select _iSTATE)) then{
  _ProcID = [_RAPTOR, _TARGET] spawn Fnc_RAP_spwCHASE;
};
if(!(isNull _ProcID)) then{
  _aSpawn set [_iSTATE, _ProcID];
  _RAPTOR setVariable ["vRAP_aProcess", _aSpawn, false];
};

_RAPTOR setVariable ["vRAP_TARGET",  _TARGET, false];
_RAPTOR setVariable ["vRAP_STATE",    _STATE, false];
};
Fnc_RAP_DoAttack1  = {//call
params["_RAPTOR", "_PosR", "_PosT", "_TARGET"];

_RAPTOR setVariable ["vRAP_bNoFallDmg", true, false];
[_RAPTOR, "AI_Attack_JumpAttack"] remoteExec ["switchMove", 0];

sleep 0.70;
_MaxJ = 1.33;
_Y0   = _PosR select 2;
_dHgt = (_PosT select 2) - _Y0;
_MaxJ = [(_dHgt+_MaxJ), _MaxJ] select (_dHgt <= 0);
_V0y  = sqrt(2*9.8*_MaxJ);
_Time = (_V0y + sqrt(_V0y^2 + 2*9.8*_Y0))/9.8;

_aVel = velocity _TARGET;
_aVel = _aVel vectorAdd [0,0,-(_aVel select 2)];
_PosT = _PosT vectorAdd (_aVel vectorMultiply _Time);

_aVel = _PosR vectorFromTo _PosT;
_aVel = vectorNormalized (_aVel vectorAdd [0,0,-(_aVel select 2)]);
_aVel = _aVel vectorMultiply ((((_PosR Distance2D _PosT)-1) max 0)/_Time);
_aVel = _aVel vectorMultiply 1.75;
_aVel = _aVel vectorAdd [0,0,_V0y];
_RAPTOR setVelocity _aVel;

_Snd = format ["babe_raptors\sounds\rap_%1.ogg", ((floor random 12) + 1)];
playSound3D [_Snd, ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 50];

[_RAPTOR, _TARGET] spawn Fnc_RAP_spwATTACK1;

_RAPTOR setVariable ["vRAP_TimeAttck1", time, false];
};
Fnc_RAP_DoAttack2  = {//call
params["_RAPTOR", "_TARGET"];

_RAPTOR playAction format["RaptorBiteGesture%1", ((floor random 3) + 1)];

_Snd = format ["babe_raptors\sounds\rap_%1.ogg", ((floor random 12) + 1)];
playSound3D [_Snd, ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 50];

private _aHitDam = [];
if(alive _TARGET) then{
  _PosR = getPosWorld _RAPTOR;
  _PosT = getPosWorld _TARGET;
  _dH   = (_PosR select 2) - (_PosT select 2);
  _bInFOV = [_PosR, _PosT, (getDir _RAPTOR), 60] call Fnc_inFOV;

  if(_bInFOV) then{
  if((abs _dH) <=  2) then{
    if(isPlayer _TARGET) then{
      if((vehicle _TARGET) == _TARGET) then{
        _aHitDam = getAllHitPointsDamage _TARGET;
        _TARGET setDamage((damage _TARGET)+ 0.25);
        {_TARGET setHitPointDamage [_x, ((_aHitDam select 2) select _foreachIndex)]; } foreach(_aHitDam select 0);

        [10] remoteExec ["BIS_fnc_bloodEffect",      _TARGET];
        [  ] remoteExec ["BIS_fnc_indicateBleeding", _TARGET];
        playSound3D ["babe_raptors\sounds\Human\RaptorJumpHitHuman.ogg", ObjNull, false, (ASLtoAGL (getPosASL _TARGET)), 5, 1, 50];
      };
    } else{
      _aHitDam = getAllHitPointsDamage _TARGET;
      _TARGET setDamage((damage _TARGET)+ 0.66);
      {_TARGET setHitPointDamage [_x, ((_aHitDam select 2) select _foreachIndex)]; } foreach(_aHitDam select 0);

      _Snd = format ["babe_raptors\sounds\HitCar%1.wss", ((floor random 3) + 1)];
      playSound3D [_Snd, ObjNull, false, (ASLtoAGL (getPosASL _TARGET)), 5, 1, 50];
    };
  };
  };
};

if(!(alive _TARGET)) then{
  if([(typeOf _TARGET), ["Animal", "CAManBase"]] call Fnc_IsKindOf) then{
    [_RAPTOR, "TOEAT", [_RAPTOR, (getPosWorld _TARGET)], true] call Fnc_RAP_ToState;
  };
};

_RAPTOR setVariable ["vRAP_TimeAttck2", time, false];
};
Fnc_RAP_DoTOEAT    = {//call
params["_RAPTOR", "_MoveTo"];//_MoveTo ASL

_RAPTOR setDestination [(ASLtoATL _MoveTo), "LEADER DIRECT", false];
_RAPTOR forceSpeed 4;//max spd: 30km/h - 8.33m/s
_RAPTOR setVariable ["MOVETO", _MoveTo, false];

_aStates = _RAPTOR getVariable ["vRAP_aSTATES",  []];
private _STATE  =  "TOEAT";
private _iSTATE = _aStates findIf {(_x select 0) == _STATE};
        _iSTATE = ((_aStates select _iSTATE) select 1) select 2;

private _aSpawn = _RAPTOR getVariable ["vRAP_aProcess", []];
private _ProcID = ScriptNull;

if(isNull (_aSpawn select _iSTATE)) then{
  _ProcID = [_RAPTOR, _MoveTo] spawn Fnc_RAP_spwTOEAT;
};
if(!(isNull _ProcID)) then{
  _aSpawn set [_iSTATE, _ProcID];
  _RAPTOR setVariable ["vRAP_aProcess", _aSpawn, false];
};

_RAPTOR setVariable ["vRAP_STATE",   _STATE, false];
_RAPTOR setVariable ["vRAP_PosEat", _MoveTo, false];
};
Fnc_RAP_DoEATING   = {//call
params["_RAPTOR"];

private _evID = -1;
if((_RAPTOR getVariable ["vRAP_ANIMevID", -1]) == -1) then{
_evID = _RAPTOR addEventHandler ["AnimDone", {
  params["_RAPTOR", "_Anim"];
  if(_Anim == "AI_Attack_JumpAttackEat") then{
    _RAPTOR spawn{
      private _PosEat = _this getVariable ["vRAP_PosEat", (getPosWorld _this)];
      sleep 2;
      if((_this getVariable ["vRAP_STATE", ""]) != "EATING") exitwith{};
      [_this, "babe_raptor_Idle"] remoteExec ["switchMove", 0];
      _this spawn{
        for "_i" from 1 to 3 do{
          playSound3D ["babe_raptors\sounds\rap_12.ogg", ObjNull, false, (ASLtoAGL (getPosASL _this)), 5, 1, 100];
          sleep (0.75 + (random 0.66));
        };
      };
      sleep 4;
      if(isNil "_this") exitwith{};
      if((_this getVariable ["vRAP_STATE", ""]) != "EATING") exitwith{};
      if((_PosEat vectorDistance (getPosWorld _this)) >= 4) then{
        [_this, "TOEAT", [_this, _PosEat], false] call Fnc_RAP_ToState;
      } else{
        [_this, "babe_raptor_Idle"] remoteExec ["switchMove", 0];
      };
    };
  };
}];
};
if(_evID != -1) then{ _RAPTOR setVariable ["vRAP_ANIMevID", _evID, false]; };

[_RAPTOR, "AI_Attack_JumpAttackEat"] remoteExec ["switchMove", 0];
playSound3D ["babe_raptors\sounds\rap_12.ogg", ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 100];

_aStates = _RAPTOR getVariable ["vRAP_aSTATES",  []];
private _STATE  =  "EATING";
private _iSTATE = _aStates findIf {(_x select 0) == _STATE};
        _iSTATE = ((_aStates select _iSTATE) select 1) select 2;

private _aSpawn = _RAPTOR getVariable ["vRAP_aProcess", []];
private _ProcID = ScriptNull;

if(isNull (_aSpawn select _iSTATE)) then{
  _ProcID = [_RAPTOR] spawn Fnc_RAP_spwEATING;
};
if(!(isNull _ProcID)) then{
  _aSpawn set [_iSTATE, _ProcID];
  _RAPTOR setVariable ["vRAP_aProcess", _aSpawn, false];
};

_RAPTOR setVariable ["vRAP_STATE", _STATE, false];
};
Fnc_RAP_DoUNCONS   = {//call
params["_RAPTOR"];

[_RAPTOR, "Unconscious"] remoteExec ["switchMove", 0];
_Snd = format ["babe_raptors\sounds\rap_%1.ogg", ((floor random 12) + 1)];
playSound3D [_Snd, ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 50];

_aStates = _RAPTOR getVariable ["vRAP_aSTATES",  []];
private _STATE  =  "UNCONS";
private _iSTATE = _aStates findIf {(_x select 0) == _STATE};
        _iSTATE = ((_aStates select _iSTATE) select 1) select 2;

private _aSpawn = _RAPTOR getVariable ["vRAP_aProcess", []];
private _ProcID = ScriptNull;

if(isNull (_aSpawn select _iSTATE)) then{
  _ProcID = [_RAPTOR] spawn Fnc_RAP_spwUNCONS;
};
if(!(isNull _ProcID)) then{
  _aSpawn set [_iSTATE, _ProcID];
  _RAPTOR setVariable ["vRAP_aProcess", _aSpawn, false];
};

_RAPTOR setVariable ["vRAP_STATE", _STATE, false];
};
Fnc_RAP_DoUnstuck  = {//call
params["_RAPTOR"];

if((time - (_RAPTOR getVariable ["vRAP_LastUnStuck", time])) <= 60) exitwith{
  _Dir = getDir _RAPTOR;
  _Pos = getPosATL _RAPTOR;
  _RAPTOR setPosATL (_RAPTOR getVariable ["vRAP_WP0", [0,0,0]]);

  _tmp = createAgent [(typeOf _RAPTOR), _Pos, [], 0, "CAN_COLLIDE"];
  _tmp setDir _Dir;
  _tmp setdamage 1;

  [_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
  _RAPTOR setVariable ["vRAP_LastUnStuck", time, false];
};

_RAPTOR setVariable ["vRAP_bNoFallDmg",  true, false];
_RAPTOR setVariable ["vRAP_bUnstuck",    true, false];
_RAPTOR setVariable ["vRAP_LastUnStuck", time, false];

_RAPTOR spawn{
  for "_i" from 1 to 5 do{
    _Dir = random 360;
    [_this, "babe_raptor_Run"] remoteExec ["switchMove", 0];
    _this spawn{ _this setAnimSpeedCoef 2; sleep 0.80; _this setAnimSpeedCoef 1; };
    _this setVelocity (([sin _Dir, cos _Dir, 0] vectorMultiply 8) vectorAdd [0,0,(sqrt(2*9.8*0.15))]);
    sleep 0.66;
  };

  _this setVectorUp [0,0,1];
  _this setVariable ["vRAP_bNoFallDmg", false, false];
  _this setVariable ["vRAP_bUnstuck",   false, false];

  if(alive _this) then{
    [_this, "PATROL", [_this], true] call Fnc_RAP_ToState;
  };
};

};
Fnc_RAP_PATROLdone = {//call
params["_RAPTOR", "_STATUS"];

if(_STATUS == "TARGETFOUND") then{
  _TARGET = _RAPTOR getVariable ["vRAP_TARGET", ObjNull];
  [_RAPTOR, "CHASE", [_RAPTOR, _TARGET], true] call Fnc_RAP_ToState;
};
if(_STATUS == "DONE") then{
  [_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
};
if(_STATUS == "TIMEOUT") then{
  [_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
};
if(_STATUS == "STUCK") then{
  [_RAPTOR] call Fnc_RAP_DoUnstuck;
};

};
Fnc_RAP_CHASEdone  = {//call
params["_RAPTOR", "_STATUS"];

if(_STATUS == "OUTRANGED") then{
  [_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
};
if(_STATUS == "DEADT") then{
  _TARGET = _RAPTOR getVariable ["vRAP_TARGET", _RAPTOR];
  [_RAPTOR, "TOEAT", [_RAPTOR, (getPosWorld _TARGET)], true] call Fnc_RAP_ToState;
};
if(_STATUS == "STUCK") then{
  [_RAPTOR] call Fnc_RAP_DoUnstuck;
};

};
Fnc_RAP_TOEATdone  = {//call
params["_RAPTOR", "_STATUS"];

if(_STATUS == "DONE") then{
  [_RAPTOR, "EATING", [_RAPTOR], true] call Fnc_RAP_ToState;
};
if(_STATUS == "TIMEOUT") then{
  [_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
};

};
Fnc_RAP_EndPATROL  = {//call
params["_RAPTOR"];

};
Fnc_RAP_EndCHASE   = {//call
params["_RAPTOR"];

_RAPTOR setVariable ["vRAP_TARGET", ObjNull];
};
Fnc_RAP_EndTOEAT   = {//call
params["_RAPTOR"];

_RAPTOR setVariable ["vRAP_PosEat", (getPosWorld _RAPTOR), false];
};
Fnc_RAP_EndEATING  = {//call
params["_RAPTOR"];

private _evID = _RAPTOR getVariable ["vRAP_ANIMevID", -1];
if(_evID >= 0) then{
  _RAPTOR removeEventHandler ["AnimDone", _evID];
  _RAPTOR setVariable ["vRAP_ANIMevID", -1, false];
};

};
Fnc_RAP_EndUNCONS  = {//call
params["_RAPTOR"];

};
Fnc_RAP_spwPATROL  = {//spawn
private _RAPTOR = _this select 0;
private _MoveTo = _this select 1;//ATL

private _STATUS = "";
private _PosR = getPosWorld _RAPTOR;
private _ETA  = 1.33 *(((ATLtoASL _MoveTo) vectorDistance _PosR)/12*8.33);
        _ETA  = (_ETA min 300) + time;

private _TrackTick = time;
private _bGotTargt = false;

private _PosCached = getPosWorld  _RAPTOR;
private _StuckTick = time;
private _bStuck    = false;
private _iStuck    = 0;

waitUntil{
  if(!(alive _RAPTOR)) exitwith{ _STATUS = "DEAD"; true };

  if((time - _TrackTick) >= 2.50) then{
    _bGotTargt = [_RAPTOR] call Fnc_RAP_getTarget;
    _TrackTick = time;
  };
  if(_bGotTargt) exitwith{ _STATUS = "TARGETFOUND"; true };

  _PosR = getPosWorld _RAPTOR;
  _dRemain = (ATLtoASL _MoveTo) vectorDistance _PosR;
  if(_dRemain <= 8.45) exitwith{ _STATUS = "DONE"; true };

  if((time - _ETA) >= 120) exitwith{ _STATUS = "TIMEOUT"; true };

  if((time - _StuckTick) >= 2.66) then{
    if(not (_RAPTOR getVariable ["vRAP_bUnstuck", true])) then{
      if((_PosCached vectorDistance _PosR) <= 3.40) then{
        _iStuck = _iStuck + 1;
      } else{
        _iStuck = 0;
      };
      if(_iStuck == 3) then{ _bStuck = true; };
      _PosCached = +_PosR;
      _StuckTick = time;
    };
  };
  if(_bStuck) exitwith{ _STATUS = "STUCK"; true };

  false
};

[_RAPTOR, _STATUS] call Fnc_RAP_PATROLdone;
};
Fnc_RAP_spwCHASE   = {//spawn
_FilterArray = {
private _ARR   = _this select 0;
private _FACTN = _this select 1;

private _aDel = [];
{//foreach _ARR
  if((_x getVariable ["vRAP_Faction", ""]) == _FACTN) then{
    _aDel pushback _foreachIndex;
  };
}foreach _ARR;

if((count _aDel) > 0) then{
  { _ARR deleteAt _x; }foreach _aDel;
};

_ARR
};

private _RAPTOR = _this select 0;
private _TARGET = _this select 1;

private _dMax = _RAPTOR getVariable ["vRAP_MaxChase", 300];
private _Pos0 = _RAPTOR getVariable ["vRAP_WP0", (getPos _RAPTOR)];
        _Pos0 = ATLtoASL _Pos0;
private _PosR = [];
private _PosT = [];
private _Dist = 0;
private _STATUS = "";
private _ComndTick = time;
private _TrackTick = time;

private _PosCached = getPosWorld  _RAPTOR;
private _StuckTick = time;
private _bStuck    = false;
private _iStuck    = 0;

waitUntil{
  _PosR = getPosWorld  _RAPTOR;
  _PosT = getPosWorld _TARGET;
  _Dist = _PosR distance2D _PosT;

  if((time - _ComndTick) >= 1.20) then{
    _RAPTOR setDestination [(ASLtoATL _PosT), "LEADER DIRECT", false];
    _RAPTOR forceSpeed 8.33;
    _ComndTick = time;
  };

  if((time - _TrackTick) >= 2.50) then{
    _FACTN = _RAPTOR getVariable ["vRAP_Faction", ""];
    _aNear = (getPosWorld _RAPTOR) nearEntities ["CAManBase", 50];
    _aNear = [_aNear, _FACTN] call _FilterArray;
    if((_aNear select 0) != _TARGET) then{
    if((_aNear select 0) != _RAPTOR) then{
      _TARGET = _aNear select 0;
      _PosT = getPosWorld _TARGET;
      _RAPTOR setVariable ["vRAP_TARGET", _TARGET];
      _RAPTOR setDestination [(getPosATL _TARGET), "LEADER DIRECT", false];
      _RAPTOR forceSpeed 8.33;
    };
    };
    _TrackTick = time;
  };

  if((time - _StuckTick) >= 2.66) then{
    if(not (_RAPTOR getVariable ["vRAP_bUnstuck", true])) then{
      if((_PosCached vectorDistance _PosR) <= 3.40) then{
        _iStuck = _iStuck + 1;
      } else{
        _iStuck = 0;
      };
      if(_iStuck == 3) then{ _bStuck = true; };
      _PosCached = +_PosR;
      _StuckTick = time;
    };
  };
  if(_bStuck) exitwith{ _STATUS = "STUCK"; true };

  if((_PosR vectorDistance _Pos0) >= _dMax) exitwith{ _STATUS = "OUTRANGED"; true };
  if(!(alive _TARGET)) exitwith{ _STATUS = "DEADT"; true };

  if(istouchingGround _RAPTOR) then{
    if((_Dist > 3) && (_Dist <= 12)) then{
      if((time - (_RAPTOR getVariable ["vRAP_TimeAttck1", time])) >= 3.66) then{
        [_RAPTOR, _PosR, _PosT, _TARGET] call Fnc_RAP_DoAttack1;
      };
    };
    if(_Dist <= 2) then{
      if((time - (_RAPTOR getVariable ["vRAP_TimeAttck2", time])) >= 1.66) then{
        [_RAPTOR, _TARGET] call Fnc_RAP_DoAttack2;
      };
    };
  };

  false
};

[_RAPTOR, _STATUS] call Fnc_RAP_CHASEdone;
};
Fnc_RAP_spwTOEAT   = {//spawn
private _RAPTOR = _this select 0;
private _MoveTo = _this select 1;

private _STATUS = "";
private _Time0 = time;

waitUntil{
  if(!(alive _RAPTOR)) exitwith{ _STATUS = "DEAD"; true };
  if((_MoveTo vectorDistance (getPosWorld _RAPTOR)) <= 2.20) exitwith{ _STATUS = "DONE"; true };
  if((time - _Time0) >= 120) exitwith{ _STATUS = "TIMEOUT"; true };
  false
};

[_RAPTOR, _STATUS] call Fnc_RAP_TOEATdone;
};
Fnc_RAP_spwATTACK1 = {//spawn
private _RAPTOR = _this select 0;
private _TARGET = _this select 1;
sleep 1;

private _Time0 = time;
waitUntil{
  if(istouchingGround _RAPTOR) exitwith{true};
  if((time - _Time0) >= 6) exitwith{true};
  false
};
_RAPTOR spawn{ _this setAnimSpeedCoef 2; sleep 1; _this setAnimSpeedCoef 1; };

private _aHitDam = [];
if(alive _RAPTOR) then{
  _RAPTOR setVariable ["vRAP_bNoFallDmg", false, false];
  playSound3D ["babe_raptors\sounds\rap_12.ogg", ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 50];

  if(alive _TARGET) then{
    _PosR = getPosWorld  _RAPTOR;
    _PosT = getPosWorld _TARGET;
    _Dist = _PosR vectorDistance _PosT;
    _dH   = (_PosR select 2) - (_PosT select 2);
    _bInFOV = [_PosR, _PosT, (getDir _RAPTOR), 80] call Fnc_inFOV;

    if(_bInFOV) then{
    if((abs _Dist) <=  5) then{
    if((abs   _dH) <=  5) then{
      if(isPlayer _TARGET) then{
        if((vehicle _TARGET) == _TARGET) then{
          _aHitDam = getAllHitPointsDamage _TARGET;
          _TARGET setDamage((damage _TARGET)+ 0.45);
          {_TARGET setHitPointDamage [_x, ((_aHitDam select 2) select _foreachIndex)]; } foreach(_aHitDam select 0);

          [10] remoteExec ["BIS_fnc_bloodEffect",      _TARGET];
          [  ] remoteExec ["BIS_fnc_indicateBleeding", _TARGET];
          _Snd = format ["babe_raptors\sounds\Human\RaptorJumpHitHuman.ogg"];
          playSound3D [_Snd, ObjNull, false, (ASLtoAGL (getPosASL _TARGET)), 5, 1, 50];
        };
      } else{
        _aHitDam = getAllHitPointsDamage _TARGET;
        _TARGET setDamage((damage _TARGET)+ 1);
        {_TARGET setHitPointDamage [_x, ((_aHitDam select 2) select _foreachIndex)]; } foreach(_aHitDam select 0);

        _Snd = format ["babe_raptors\sounds\HitCar%1.wss", ((floor random 3) + 1)];
        playSound3D [_Snd, ObjNull, false, (ASLtoAGL (getPosASL _TARGET)), 5, 1, 50];

        _Dir = _RAPTOR getDir _TARGET;
        _Psh = ([sin _Dir, cos _Dir, 0] vectorMultiply 2.22) vectorAdd [0,0,1+(random 2)];
        _TARGET setvelocity ((velocity _TARGET) vectorAdd _Psh);
      };
    };
    };
    };
  };

  if(!(alive _TARGET)) then{
    if([(typeOf _TARGET), ["Animal", "CAManBase"]] call Fnc_IsKindOf) then{
      [_RAPTOR, "TOEAT", [_RAPTOR, (getPosWorld _TARGET)], true] call Fnc_RAP_ToState;
    };
  };
};

};
Fnc_RAP_spwEATING  = {//spawn
private _RAPTOR = _this select 0;

sleep 40;
if(!((_RAPTOR getVariable ["vRAP_STATE", ""]) in ["TOEAT", "EATING"])) exitwith{};
[_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
};
Fnc_RAP_spwUNCONS  = {//spawn
private _RAPTOR = _this select 0;

sleep 8;
[_RAPTOR, "UnconsciousUp"] remoteExec ["switchMove", 0];
[_RAPTOR, "PATROL", [_RAPTOR], true] call Fnc_RAP_ToState;
};

Fnc_RAP_HndlDmg    = {//call
params["_RAPTOR", "_Selection", "_Damage", "_Killer", "_Projectile", "_HitIndex", "_Instigator", "_HitPoint"];

private _Return = [(_RAPTOR getHitIndex _HitIndex), (damage _RAPTOR)] select (_HitIndex == -1);

if( !(alive _RAPTOR) ) then{ _Damage = 0; };
if(_Return == _Damage) then{ _Damage = 0; };

if(_Damage > 0) then{
  if(isNull _Instigator) then{
    if((isNull _Killer) || (_Killer == _RAPTOR)) then{
      if(_RAPTOR getVariable ["vRAP_bNoFallDmg", false]) then{
        _Damage = 0;
      };
    };
  };

  if(!(isPlayer _Killer)) then{ _Damage = (_Damage * 0.20) min 0.20; };

  if((_RAPTOR getVariable ["vRAP_STATE", ""]) == "UNCONS") then{
    _Return = _Return + 0.034 + (random 0.054);
  } else{
    _Return = _Return + _Damage*(1 + (random 0.50));
    _Return = _Return + _Damage*([0, (0.33 + random 0.66 + random 0.33)] select (_Selection == "head"));
    if((_Return > 0.90) && ((random 1) < 0.33)) then{
      if((time - (_RAPTOR getVariable ["vRAP_tLastUncons", time])) >= 90) then{
        _Return = 0.90;
        _RAPTOR setVariable ["vRAP_tLastUncons", time, false];
        [_RAPTOR, "UNCONS", [_RAPTOR], true] call Fnc_RAP_ToState;
      };
    };
  };
};

_Return
};
Fnc_RAP_HndlKilled = {//call
params ["_RAPTOR", "_Killer", "_Instigator", "_bEffects"];

_Snd = format ["babe_raptors\sounds\rap_%1.ogg", ((floor random 12) + 1)];
playSound3D [_Snd, ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 50];

{ if(!(isNull _x)) then{ terminate _x; }; }foreach (_RAPTOR getVariable ["vRAP_aProcess", []]);

if(isNil "G_RAP_aCanAddRem") exitwith{};

_RAPTOR spawn{
  private _bSuccess = false;
  waitUntil{
    if(isNil "G_RAP_aCanAddRem") exitwith{true};
    if(G_RAP_aCanAddRem) exitwith{ _bSuccess = true; true};
    false
  };
  if(_bSuccess) then{ G_RAP_aRaptors = G_RAP_aRaptors - [_this]; };
};

};
Fnc_RAP_HndlHit    = {//call
params ["_RAPTOR", "_Firer", "_Damage", "_Instigator"];
  
[_RAPTOR, _Firer, _Instigator] call Fnc_RAP_Alert;
};
Fnc_RAP_HndlFNear  = {//call
params ["_RAPTOR", "_Firer", "_Distance", "_Weapon", "_Muzzle", "_Mode", "_Ammo", "_Instigator"];
[_RAPTOR, _Firer, _Instigator] call Fnc_RAP_Alert;
};
Fnc_RAP_Alert = {//call
params ["_RAPTOR", "_Firer", "_Instigator"];

if(_RAPTOR getVariable ["vRAP_bOnAlert", true]) exitwith{};
_RAPTOR setVariable ["vRAP_bOnAlert", true, false];

if(isNull _Firer) then{ _Firer = _Instigator; };
if(isNull _Firer) exitwith{};

if(_Firer == _RAPTOR) exitwith{};
if((_RAPTOR getVariable ["vRAP_STATE", ""]) == "UNCONS") exitwith{};
if((_RAPTOR getVariable ["vRAP_Faction", "x"]) == (_Firer getVariable ["vRAP_Faction", "y"])) exitwith{};

private _TARGET = _RAPTOR getVariable ["vRAP_TARGET", ObjNull];
if(_TARGET == _Firer) exitwith{};
if(isNull _TARGET) then{ _TARGET = _Firer; };

private _PosR = getPosWorld _RAPTOR;
private _PosT = getPosWorld _TARGET;
private _PosF = getPosWorld _Firer;
if((_PosR vectorDistance _PosF) > (_PosR vectorDistance _PosT)) exitwith{};

private _STATE  = _RAPTOR getVariable ["vRAP_STATE", ""];
switch(true) do{
case (_STATE in ["PATROL", "TOEAT", "EATING"]) : {
  if((_PosR vectorDistance _PosF) <= 200) then{
    playSound3D ["babe_raptors\sounds\rap_12.ogg", ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 50];
    [_RAPTOR, "CHASE", [_RAPTOR, _Firer], true] call Fnc_RAP_ToState;
  } else{
    //TODO: take Cover - COWARDING
  };
};
case (_STATE == "CHASE") : {
  playSound3D ["babe_raptors\sounds\rap_12.ogg", ObjNull, false, (ASLtoAGL (getPosASL _RAPTOR)), 5, 1, 50];
  _RAPTOR setVariable ["vRAP_TARGET", _Firer];
  _RAPTOR setDestination [(getPosATL _Firer), "LEADER DIRECT", false];
  _RAPTOR forceSpeed 8.33;
};
case (_STATE == "COWARDING") : {
  //TODO: if enough shots... go chase
};
};

_RAPTOR setVariable ["vRAP_bOnAlert", false, false];
};
Fnc_Dummy     = {//call

};

//Utility functions
Fnc_IsKindOf = {//call
params["_strC", "_aClass"];

private _bRet = false;

{//foreach _aClass
  ScopeName "FindLoop";
  if(_strC isKindOf _x) then{
    _bRet = true;
    breakOut "FindLoop";
  };
}foreach _aClass;

_bRet
};
Fnc_GetArcDivision = {//call returns [number of segments, angle step]
params["_Rad", "_SemiChord", "_Portion", "_MaxDiv"];

_AngStep = 2*asin(_SemiChord/_Rad);
_Div = (floor(_Portion/_AngStep)) min _MaxDiv;
_AngStep = _Portion/_Div;

_aRet = [_Div, _AngStep];
_aRet
};
Fnc_GetLineDivision = {//call returns [number of segments, separeation between each segements]
params["_Length", "_MinSep", "_MaxDiv"];

_MinSep = _MinSep max 3;
_Div    = (floor (_Length/_MinSep)) min _MaxDiv;
_Div    = _Div max 3;
_aRet   = [[_Div, (_Length/_Div)], [0, 0]] select (_Div <= 0);

_aRet
};
Fnc_HasWaterNear = {//call 
params["_Param1", "_Radius"];

private _Center = +_Param1;
private _bRet = false;

for "_Ang" from 0 to 360 step 10 do{
  ScopeName "FindWaterNearLoop";
  _Pos = _Center vectorAdd [_Radius*(sin _Ang), _Radius*(cos _Ang), 0];
  if(surfaceIsWater _Pos) then{ _bRet = true; breakOut "FindWaterNearLoop"; };
};

_bRet
};
Fnc_bIsOutside = {//call
params["_Pos"];//ASL

_IniPos = _Pos vectorAdd [0,0,1];
_EndPos = _IniPos vectorAdd [0,0,200];
private _aInt = lineIntersectsSurfaces[_IniPos, _EndPos, ObjNull, ObjNull, true, -1];

private _bRet = false;
if((count _aInt) == 0) then{
  _bRet = true;
} else{
  {//foreach _aInt
    ScopeName "FindLoop";
    _name = tolower (typeof (_x select 2));
    _bExclude = ((_name find "hangar") >= 0);
    _bExclude = _bExclude || ((_name find "_shed_") >= 0);
    if(_bExclude) then{ _bRet = true; breakOut "FindLoop"; };
  }foreach _aInt;
};

_bRet
};
Fnc_PosIsEmpty = {//call 
params["_Center", "_Rad"];//_Center - posAGL

private _aObj = _Center nearObjects ["All", (_Rad+50)];
private _bEmpty = true;

private["_ObjRad", "_ObjHgt"];
if((count _aObj) > 0) then{
  {//foreach _aObj
    ScopeName "FindLoop";
    if(!(_x isKindOf "CAManBase")) then{
      _BBox = boundingBoxReal _x;
      _V0 = _BBox select 0;
      _V1 = _BBox select 1;

      _ObjCen = getPosWorld _x;
      _ObjRad = (_V0 distance2D _V1)*0.66;
      _ObjHgt = abs((_V1 select 2) - (_V0 select 2));

      _CenASL = [(_Center select 0), (_Center select 1), (_ObjCen select 2)];
      if((_ObjCen vectorDistance _CenASL) < (0.66*(_Rad+_ObjRad))) then{
      if(_ObjHgt >= 1) then{
      if(_ObjRad >= 1) then{
        _bEmpty = false;
        breakOut "FindLoop";
      };
      };
      };
    };
  }foreach _aObj;
};

_bEmpty
};
Fnc_UnitCamDir = {//call
params["_Unit"];
_Unit = vehicle _Unit;
_ObjPos = getPosworld _Unit;
_NrthPos = _ObjPos vectorAdd [1,0,0];
_ViewPos = _ObjPos vectorAdd ((getCameraViewDirection _Unit) vectorMultiply 10);
_Dir = _NrthPos getDir _ViewPos;
_Dir
};
Fnc_inFOV = {//call returns bool true if To is in fov of From
params["_argFrom", "_argTo", "_Dir", "_semiFOV"];
_From = +_argFrom; _From set [2,0];
_To   = +_argTo;   _To   set [2,0];

_DotP = (_From vectorFromTo _To) vectorDotProduct [(sin _Dir), (cos _Dir), 0]; 

(_DotP >= (cos _semiFOV))
};
Fnc_FromHasLOSTo = {//call | returns bool, true if position _From has LOS to position _To
_GetFromPosVehicle = {
params["_Veh"];
_BBox = boundingBoxReal _Veh;
_V1 = _BBox select 1;
_V1z = _V1 select 2;
_Center = _Veh modelToWorldWorld [0,0,_V1z*1.10];
_Center
};

params["_Param1", "_ToPos", "_StrSize", "_ratio", "_ExObjB"];//ASL

private["_From", "_ExObj"];//ASL
if((typeName _Param1) == "OBJECT") then{
  if(_Param1 isKindOf "CAManbase") then{
    _From = eyePos _Param1;
  } else{
    _From = [_Param1] call _GetFromPosVehicle;
  };
  _ExObj = _Param1;
} else{//array
  _From = _Param1;
  _ExObj = ObjNull;
};
_ToPos = _ToPos vectorAdd [0,0,0.15];//ASL

if((count _this) < 4) then{ _ratio  = 0.58; };
if((count _this) < 5) then{ _ExObjB = ObjNull; };

private["_H", "_W", "_nRows", "_nCols", "_aBases"];
if(_StrSize == "MAN") then{//men sized
  _nRows = 4;
  _nCols = 3;//odd >= 3
  _H = 1.70/(_nRows-1);
  _W = 0.60/(_nCols-1);
};
if(_StrSize == "VEH") then{//car, tanks...
  _nRows = 5;
  _nCols = 5;
  _H = 1.70/(_nRows-1);
  _W = 2.40/(_nCols-1);
};
_aBases = [];

private["_bInLOS", "_nInLOS"];
_bInLOS = false;
_nInLOS = 0;

private["_uDir", "_uVUp"];
_vIni = +_From;  _vIni set [2, 0];
_vEnd = +_ToPos; _vEnd set [2, 0];
_uDir = _vIni vectorFromTo _vEnd;
_uVUp = _vEnd vectorFromTo (_vEnd vectorAdd [0,0,1]);

private["_iRow", "_Btmp"];
for "_iRow" from 0 to (_nRows-1) do{//for each row of a (Rows x Cols) matrix
  _aBases = [(_ToPos vectorAdd [0,0, _iRow*_H])];

  for "_n" from 1 to (1+(_nCols-3)/2) do{
    _Btmp = _uDir vectorCrossProduct _uVUp;//+x
    _Btmp = _ToPos vectorAdd (_Btmp vectorMultiply (_n*_W));
    _Btmp set [2, ((getTerrainHeightASL _Btmp)+0.15)];
    _Btmp = _Btmp vectorAdd [0, 0, (_iRow*_H)];
    _aBases pushback _Btmp;

    _Btmp = _uVUp vectorCrossProduct _uDir;//-x
    _Btmp = _ToPos vectorAdd (_Btmp vectorMultiply (_n*_W));
    _Btmp set [2, ((getTerrainHeightASL _Btmp)+0.15)];
    _Btmp = _Btmp vectorAdd [0, 0, (_iRow*_H)];
    _aBases pushback _Btmp;
  };

  {//foreach _B1 _Bc _B2
    _aIntx = lineIntersectsSurfaces[_From, _x, _ExObj, _ExObjB, true, 1];
    if((count _aIntx) == 0) then{ _nInLOS = _nInLOS + 1; };
  }foreach _aBases;
};

if(_nInLOS > 0) then{
if(_nInLOS >= (floor (_nRows*_nCols*_ratio))) then{//_ratio = 1 : 100% visible
  _bInLOS = true;
};
};

_bInLOS
};
Fnc_PosInLOS = {//call | returns bool, true if position is in LOS of any player
_GetFacingDir = {
params["_Unit"];
_Unit = vehicle _Unit;
_ObjPos = getPosworld _Unit;
_NrthPos = _ObjPos vectorAdd [1,0,0];
_ViewPos = _ObjPos vectorAdd ((getCameraViewDirection _Unit) vectorMultiply 10);
_Dir = _NrthPos getDir _ViewPos;
_Dir
};

params["_Param1", "_StrSize", "_aExPlyrs", "_bFullDist", "_ratio"];

private["_ToPos", "_ExObj"];
if((typeName _Param1) == "OBJECT") then{
  _PosW = getPosWorld _Param1; _PosW set [2, ((getPosATL _Param1) select 2)];
  _ToPos = ATLtoASL _PosW;
  _ExObj = _Param1;
} else{//array
  _ToPos = +_Param1;//ASL
  _ExObj = ObjNull;
};

if((count _this) < 2) then{ _StrSize  = ["VEH", "MAN"] select(_Param1 isKindOf "CAManbase"); };
if((count _this) < 3) then{ _aExPlyrs = []; };
if((count _this) < 4) then{ _bFullDist = false; };//if false, anything > 500m is not in LOS
if((count _this) < 5) then{ _ratio = 0.58; };

private _bInLOS = false;
private["_Player"];
{//foreach allPlayers
scopeName "PlayersLoop";
_Player = _x;
if(alive _Player) then{
if(!(_Player in _aExPlyrs)) then{
if( [(getPosWorld _Player), _ToPos, ([_Player] call Fnc_UnitCamDir), 45] call Fnc_inFOV) then{
if(_bFullDist || ((_Player distance2D _ToPos) <= 500)) then{
  _bInLOS = [(vehicle _Player), _ToPos, _StrSize, _ratio, _ExObj] call Fnc_FromHasLOSTo;
  if(_bInLOS) then{
    breakOut "PlayersLoop";
  };
};
};
};
};
}foreach(allPlayers - (entities "HeadlessClient_F"));

_bInLOS
};
Fnc_GetRadialPos = {//call | returns LAND PosATL, that is not in Line Of Sight of any player
//-----------------------------------------------------------------------
_LoopArcStep = {
params["_DirFrom", "_DirTo", "_Center", "_Rad", "_ObjDist", "_StrSize", "_RotDir", "_bDoLOS"];

_aArcDiv = [_Rad, 1.50, (_DirTo - _DirFrom), 360] call Fnc_GetArcDivision;
private _ArcDiv  = _aArcDiv select 0;
private _ArcStep = _aArcDiv select 1;

private _iArcInit = floor (random (_ArcDiv+1));
private _iArc = _RotDir*_iArcInit;
private _RetPos = [];

private["_TmpPos", "_bAproved"];
while {true} do{
ScopeName "iArcLoop";

_Arc = _DirFrom + _iArc*_ArcStep;
_TmpPos = [(_Center select 0), (_Center select 1), 0] vectorAdd [_Rad*(sin _Arc), _Rad*(cos _Arc), 0];

_bAproved = !(surfaceisWater _TmpPos);
if(_bAproved) then{ _bAproved = !([_TmpPos, 20] call Fnc_HasWaterNear); };
if(_bAproved) then{ _bAproved = [(ATLtoASL _TmpPos)] call Fnc_bIsOutside; };
if(_bAproved) then{ if(_ObjDist > 0) then{ _bAproved = [_TmpPos, _ObjDist] call Fnc_PosIsEmpty; }; };
if(_bAproved) then{ if(_bDoLOS) then{ _bAproved = !([(ATLtoASL _TmpPos), _StrSize, [], false, 0.34] call Fnc_PosInLOS); }; };
if(_bAproved) then{ _RetPos = +(_TmpPos); };

if(_ArcDiv == 0) then{ breakOut "iArcLoop"; };
if((count _RetPos) > 0) then{ breakOut "iArcLoop"; };
if(((abs _iArc) >= _ArcDiv) && (_iArcInit == 0)) then{ breakOut "iArcLoop"; };

_iArc = [(_iArc + _RotDir), 0] select ((abs _iArc) >= _ArcDiv);
if((abs _iArc) == _iArcInit) then{ breakOut "iArcLoop"; };
};

_RetPos
};
//-----------------------------------------------------------------------
params["_Center", "_MinRad", "_MaxRad", "_DirFrom", "_DirTo", "_ObjDist", "_StrSize", "_StrRotDir", "_StrLOS"];//_Center ATL

private _RotDir = 1;
if((count _this) >= 8) then{
if(_StrRotDir == "CCW") then{
  _RotDir = -1;
};
};

private _bDoLOS = true;
if((count _this) >= 9) then{
if(_StrLOS == "NOLOSCHECK") then{
  _bDoLOS = false;
};
};

_aRadDiv = [(_MaxRad - _MinRad), 3, 200] call Fnc_GetLineDivision;
private _RadDiv  = _aRadDiv select 0;
private _RadStep = _aRadDiv select 1;

private _iRadInit = floor (random (_RadDiv+1));
private _iRad = _iRadInit;
private _Pos = [];

while {true} do{
  ScopeName "iRadLoop";

  _iRd = _MinRad + _iRad*_RadStep;
  if(_iRd == 0) then{ breakOut "iRadLoop"; };

  _Pos = [_DirFrom, _DirTo, _Center, _iRd, _ObjDist, _StrSize, _RotDir, _bDoLOS] call _LoopArcStep;

  if(_RadDiv   ==   0) then{ breakOut "iRadLoop"; };
  if((count _Pos) > 0) then{ breakOut "iRadLoop"; };
  if((_iRad >= _RadDiv) && (_iRadInit == 0)) then{ breakOut "iRadLoop"; };

  _iRad = [(_iRad + 1), 0] select (_iRad == _RadDiv);
  if(_iRad == _iRadInit) then{ breakOut "iRadLoop"; };
};

if((count _Pos) == 0) then{ _Pos = +(_Center); };
_Pos
};
Fnc_GetArcTangentDirs = {//call
params["_Center", "_Rad", "_OuterPos"];

_Center   = [(_Center   select 0), (_Center   select 1)];
_OuterPos = [(_OuterPos select 0), (_OuterPos select 1)];

_Dist = _Center distance2D _OuterPos;
_Dist = _Dist max (_Rad + 30);

_Omega = _Center getDir _OuterPos;
_Alpha = aCos (_Rad / _Dist);

private _Theta_i = _Omega - _Alpha;
if(_Theta_i < 0) then{ _Theta_i = 360 + _Theta_i; };
_Theta_f = _Theta_i + 2*_Alpha;//use this instead of (_Theta_f = _Omega - _Alpha) so that (_Theta_f > _Theta_i) always

[_Theta_i, _Theta_f]
};

G_RAP_bDone = true;
