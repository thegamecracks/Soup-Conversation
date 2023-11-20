/*
Function: TGC_fnc_kbWasSaid

Description:
    Checks if the given speaker has said the given sentence.
    See also: https://community.bistudio.com/wiki/kbWasSaid

Parameters:
    Object speaker:
        The speaker of the sentence.
    Object receiver:
        The receiver of the sentence.
    String topic:
        The topic name in CfgSentences >> mission.
    String sentence:
        The sentence ID to check.
    Number maxAge:
        The allowed time for a sentence to be said.
    String container:
        (Optional, default missionName)
        The class name containing the topic.

Examples:
    (begin example)
        [suzaku, lelouch, "Soup", "Soup25", 10] call TGC_fnc_kbWasSaid;
    (end)

Author:
    thegamecracks

*/
params [
    "_speaker",
    "_receiver",
    "_topic",
    "_sentence",
    "_maxAge",
    ["_mission", missionName]
];

_sentence = toLower _sentence;

private _sentences = _speaker getVariable "TGC_fnc_kbWasSaid_sentences";
if (isNil "_sentences") exitWith {false};

private _sent = _sentences get [_mission, _topic, _sentence];
if (isNil "_sent") exitWith {false};
if (count _sent < 1) exitWith {false};

private _sentAfter = time - _maxAge;
{
    if (_x # 0 < _sentAfter) exitWith {false};
    if (_x # 1 isEqualTo _receiver) exitWith {true};
    false
} forEachReversed _sent
