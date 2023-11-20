/*
Function: TGC_fnc_kbTellXUnlocks

Description:
    Unlocks the given units from a conversation.

Parameters:
    Array units:
        The units to be unlocked.

Examples:
    (begin example)
        [[speaker1, speaker2]] call TGC_fnc_kbTellXUnlock;
    (end)

Author:
    thegamecracks

*/
params ["_units"];
if (_units isEqualType objNull) then {_units = [_units]};
{_x setVariable ["TGC_fnc_kbTellXLock", nil]} forEach _units;
