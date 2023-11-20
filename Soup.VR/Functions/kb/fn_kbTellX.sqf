/*
Function: TGC_fnc_kbTellX

Description:
    An incomplete rewrite of BIS_fnc_kbTell that re-implements
    built-in Conversation commands to support multiplayer.
    This function should be remote executed on every client.

    WORK IN PROGRESS:
        Not all parameters are implemented.

    WARNING:
        This function has no effect on dedicated servers as it cannot
        correctly play sounds and as such know when a sound ends.

    BREAKING CHANGE:
        This requires each sentence defined in your *.bikb
        file to have a CfgSounds entry of the same name.

Parameters:
    String topic:
        The topic name in CfgSentences >> mission.
    String container:
        (Optional, default missionName)
        The class name containing the topic.
    String section:
        (Optional, default "")
        (NOT IMPLEMENTED)
        - String:
            If an empty string, all sentences will be played.
            A non-empty string can specify a specific variant.
        - [startingSentence(, endingSentence)]:
            Play all sentences between the given start and end.
            startingSentence and endingSentence can be:
            - false (default) to play first/last sentence,
              true to play random sentence
            - String: full sentence name ("04_intro_team_PLA_0")
            - [actorID(, sentenceID)]: ["PLA", 0] or just ["PLA_0"]
    Boolean | Code | Object | String radioMode:
        (Optional, default false)
        - False:
            Radio communications are automatically used when the speaker
            and receiver are far apart.
        - True:
            Radio communications is forced.
        - String:
            (NOT IMPLEMENTED)
            The name of the radio channel, original or custom.
        - Code:
            (NOT IMPLEMENTED)
            Provides a return value of one of the above.
    Array | Code sentenceCode:
        (Optional, default {})
        WORK IN PROGRESS:
            The index will always start from 0, and the receiver will always
            be the same as the speaker.
        The code to be spawned at the start of every sentence.
        An array can alternatively be passed in the format [code, arguments].
        During execution, _this will be [speaker, receiver, sentenceID, index, arguments].
    Array | Boolean units:
        (Optional, default false or value of 'BIS_fnc_kbTell_createDummy' variable)
        - Array:
            Replacement units for those defined in CfgSentences
            (in chronological order).
        - True:
            (NOT IMPLEMENTED)
            Dummy logics will be created for all actor units
            that don't exist.
    Number volumeCoef:
        (Optional, default 0.1)
        During the conversation, music and sound will be multiplied by this value.
    Boolean disableRadio:
        (Optional, default true)
        If true, radio protocol messages are disabled during the conversation.

Examples:
    (begin example)
        ["Soup"] remoteExec ["TGC_fnc_kbTellX"];
    (end)

Author:
    thegamecracks

*/
if (isDedicated) exitWith {};
if (!canSuspend) exitWith {_this spawn TGC_fnc_kbTellX};

scopeName "main";
params [
    "_topic",
    ["_mission", missionName],
    ["_section", ""],
    ["_radioMode", false],
    ["_sentenceCode", {}],
    ["_units", false],
    ["_volumeCoef", 0.1],
    ["_disableRadio", true]
];
_sentenceCode params ["_sentenceCode", ["_sentenceCodeParams", []]];

private _audibleDistance = 100;
private _radioDistance = 20;
private _textDistance = 40;
private _getSoundConfig = {
    params ["_name"];
    {
        private _config = _x >> "CfgSounds" >> _name;
        if (!isNull _config) exitWith {_config};
        configNull
    } forEach [missionConfigFile, campaignConfigFile, configFile]
};

private _topicConfig = [_mission, _topic] call bis_fnc_kbTopicConfig;
if (isNil "_topicConfig") exitWith {
    ["topic '%1' not found in '%2'", _topic, _mission] call BIS_fnc_error;
};
private _sentencesConfig = _topicConfig >> "Sentences";

private _bikbFile = getText (_topicConfig >> "file");
if (_bikbFile isEqualTo "") exitwith {
    ["'file' param not found in '%1'", _topic] call BIS_fnc_error;
};
private _bikbConfig = loadConfig _bikbFile;
if (isNull _bikbConfig) exitWith {
    ["file '%1' does not exist for '%2'", _bikbFile, _topic] call BIS_fnc_error;
};

private _priority = getNumber (_topicConfig >> "priority");
private _priorityCurrent = [] call BIS_fnc_kbPriority;
if !(_priority in _priorityCurrent) exitwith {
    [
        "Conversation '%1' for '%2' terminated, priority %3 is not in %4.",
        _topic,
        _mission,
        _priority,
        _priorityCurrent
    ] call BIS_fnc_logFormat;
};

private _sentences = [];
private _actorUnits = createHashMap;
{
    if (!isClass _x) then {continue};

    // TODO: section

    private _bikbSentence = _bikbConfig >> "Sentences" >> configName _x;
    if (isNull _bikbSentence) exitWith {
        [
            "'%1' not defined in %2 for '%3'",
            configName _x,
            _bikbFile,
            _topic
        ] call BIS_fnc_error;
        breakOut "main";
    };

    if isNull ([configName _x] call _getSoundConfig) exitWith {
        [
            "'%1' not defined in CfgSounds for '%2'",
            configName _x,
            _topic
        ] call BIS_fnc_error;
        breakOut "main";
    };

    private _actor = getText (_x >> "actor");
    if (_actor isEqualTo "") exitWith {
        [
            "'actor' param not defined for '%1' in '%2'",
            configName _x,
            _topic
        ] call BIS_fnc_error;
        breakOut "main";
    };
    private _unit = switch (true) do {
        case (_units isEqualType true): {
            // TODO create dummy units when units = true
            private _unit = missionNamespace getVariable _actor;
            if (isNull _unit) exitWith {
                [
                    "Unit %1 does not exist for %2 / %3",
                    _x,
                    _mission,
                    _topic
                ] call BIS_fnc_error;
                breakOut "main";
            };
            _unit
        };
        case (_units isEqualType []): {
            private _unit = _actorUnits get _actor;
            if (!isNil "_unit") exitWith {_unit};

            private _i = count _actorUnits;
            if (_i > count _units) exitWith {
                [
                    // TODO: tell the user how many units are needed
                    "Insufficient units (%1) provided for %2 / %3",
                    count _units,
                    _mission,
                    _topic
                ] call BIS_fnc_error;
                breakOut "main";
            };
            _units # _i
        };
        default {objNull};
    };

    private _text = getText (_bikbSentence >> "text");
    private _textPlain = getText (_bikbSentence >> "textPlain");

    _sentences pushBack [
        configName _x,
        _actor,
        _text,
        _textPlain
    ];
    _actorUnits set [_actor, _unit];
} forEach ("true" configClasses _sentencesConfig);

[values _actorUnits] call TGC_fnc_kbTellXLock;
["conversationStart", [_volumeCoef, _disableRadio]] call BIS_fnc_kbTellLocal;
{
    if (values _actorUnits findIf {!alive _x} > -1) exitWith {};

    _x params ["_sentence", "_actor", "_text", "_textPlain"];
    private _unit = _actorUnits get _actor;
    private _useRadio = switch (true) do {
        case (_radioMode isEqualTo true): {true};
        case (_radioMode isEqualTo false): {
            private _lastActor = _sentences select _forEachIndex - 1 select 1;
            private _lastUnit = _actorUnits get _lastActor;
            _unit distance _lastUnit > _radioDistance
        };
        // TODO radioMode String/Code
        default {
            ["Unsupported radio mode: %1", _radioMode] call BIS_fnc_error;
            breakOut "main";
        };
    };

    if (_useRadio || {player distance _unit < _textDistance}) then {
        if (_text isNotEqualTo "") then {
            _unit sideChat _text;
        };
        if (_textPlain isNotEqualTo "") then {
            [name _unit, _textPlain] spawn BIS_fnc_showSubtitle;
        };
    };

    private _sound = objNull;
    if (_useRadio) then {
        _sound = playSound [_sentence, true];
    } else {
        _sound = _unit say3D [_sentence, _audibleDistance, 1, true];
    };

    private _sentenceCodeHandle = [
        _unit,
        _unit, // TODO determine receiver
        toLower _sentence,
        _forEachIndex, // TODO sentenceIndex
        _sentenceCodeParams
    ] spawn _sentenceCode;

    waitUntil {
        sleep 0.01;
        if (!scriptDone _sentenceCodeHandle) exitWith {false};
        if (!alive _unit) exitWith {
            deleteVehicle _sound;
            true
        };
        isNull _sound
    };
} forEach _sentences;
["conversationEnd", [_volumeCoef, _disableRadio]] call BIS_fnc_kbTellLocal;
[values _actorUnits] call TGC_fnc_kbTellXUnlock;
