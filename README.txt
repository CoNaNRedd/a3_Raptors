Disclaimer:
Assets from McRuppert and BadBenson,
https://www.armaholic.com/page.php?id=27163
https://forums.bohemia.net/forums/topic/195969-raptors-zombies-and-more/

I wrote this simple AI because the original AI was broken.
I repacked the Addon to exclude "babe_raptors_modules" and Use Assets from "babe_raptors".
There was a problem with the animations. Everytime the raptor went Idle, It played dead after a while.
I decided to empty "variantsAI" under each State in CfgMoves and the problem went away.

To Include in your mission:	

1)Install the addon folder @Raptors and Activate It.
2)Copy RaptorAI.sqf to your mission root folder
3)In your mission init.sqf append:
  if(isServer) then {
    [] spawn{ [] ExecVM "RaptorAI.sqf"; };
  };

**There are 2 methods to spawn the raptors:

1)Placing them using the Editor, make sure to write this in the raptor's Init field:
  0 = this spawn{
    waitUntil{!(isNil "G_RAP_bDone")};
    waitUntil{G_RAP_bDone};
    sleep 20;
    GC = [(getPosATL _this), [], "alpha", _this] call Fnc_RAP_MkRaptor;
  };
2)Calling the function:
  _RAPTOR = [_POSITION, [], "alpha"] call Fnc_RAP_MkRaptor;

    **PARAMETERS:
      1: (array) - position ATL
      2: (array) - raptor class array, if empty it will use any of the following randomly:
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
      3: (string) - raptor faction, raptors will not attack other raptors/players/vehicles with the same faction
    **RETURN:
      (Agent) - the raptor

notes:
  - when placing the raptor from the editor, it will take some time to active.
  
