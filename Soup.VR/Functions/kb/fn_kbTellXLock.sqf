/*
Function: TGC_fnc_kbTellXLock

Description:
    Attempts to lock the given units for a conversation.
    This blocks until all units can be locked at the same time.

Parameters:
    Array units:
        The units to be locked.

Examples:
    (begin example)
        [[speaker1, speaker2]] call TGC_fnc_kbTellXLock;
    (end)

Author:
    thegamecracks

*/
params ["_units"];
if (_units isEqualType objNull) then {_units = [_units]};

waitUntil {
    sleep 0.01;
    _units findIf {!isNil {_x getVariable _fnc_scriptName}} isEqualTo -1
};

{_x setVariable ["TGC_fnc_kbTellXLock", true]} forEach _units;
