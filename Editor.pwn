#include <a_vicemp>
#include <keysdefine>
#include <custommenu>

#define MAX_PLAYER_OBJECTS 50// Ìàêñèìàëüíîå êîëè÷åñòâî îáúåêòîâ íà èãðîêà

new Float:PlayerMoveSpeed[MAX_PLAYERS];
new Float:PlayerRotateSpeed[MAX_PLAYERS];
#define MOVE_SPEED 0.01
#define ROTATE_SPEED 0.02

#define NOCLIP_SPEED 1.5

#define COLOR_GREEN 0x00FF00FF
#define COLOR_RED 0xFF0000FF
#define COLOR_YELLOW 0xFFFF00FF
#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_BLUE 0x0000FFFF
#define COLOR_ORANGE 0xFF9900FF
#define COLOR_CYAN 0x00FFFFFF

enum EDIT_MODES
{
    EDIT_MODE_NONE = 0,
    EDIT_MODE_MOVE,
    EDIT_MODE_ROTATE,
    EDIT_MODE_MENU
}

new EditSubMode[MAX_PLAYERS];

enum objInfo
{
    bool:objActive,
    ObjId,
    Float:objX,
    Float:objY,
    Float:objZ,
    Float:objRX,
    Float:objRY,
    Float:objRZ,
    objModel
}
#define HOLDING(%0) ((newkeys & (%0)) == (%0))

new PlayerObjects[MAX_PLAYERS][MAX_PLAYER_OBJECTS][objInfo];
new CurrentObject[MAX_PLAYERS];
new EditingMode[MAX_PLAYERS];
new EditingTimer[MAX_PLAYERS];
new MenuState[MAX_PLAYERS]; // 0 - íåò ìåíþ, 1 - ãëàâíîå ìåíþ, 2 - ìåíþ îáúåêòîâ, 3 - ìåíþ ñïèñêà, 4 - ïîäòâåðæäåíèå, 5 - ñêîðîñòü
new ObjectMenuPage[MAX_PLAYERS];
new Text3D:ObjectLabel[MAX_PLAYERS][MAX_PLAYER_OBJECTS];

new bool:NoclipMode[MAX_PLAYERS];
new Float:NoclipPos[MAX_PLAYERS][3];
new Float:NoclipRot[MAX_PLAYERS][3];
new Float:NoclipPitch[MAX_PLAYERS];

new ObjectModels[] = {
    300, 301, 302, 303, 304, 305, 306, 307, 308, 309,
    310, 311, 312, 313, 314, 315, 316, 317, 318, 319,
    320, 321, 322, 323, 324, 330, 331, 332, 333, 334,
    335, 336, 337, 338, 339, 340, 341, 342, 343, 344,
    345, 346, 347, 348, 349, 350, 351, 352, 353, 354,
    355, 356, 357, 358, 359, 360, 361, 362, 363, 364,
    365, 366, 367, 368, 369, 370, 371, 372, 373, 374,
    375, 376, 377, 378, 379, 380, 381, 382, 383, 384,
    385, 386, 387, 388, 389, 390, 391, 392, 393, 394,
    395, 396, 397, 398, 399, 400, 401, 402, 403, 404,
    405, 406, 407, 408, 409, 410, 411, 412, 413, 414,
    415, 416, 417, 418, 419, 420, 421, 422, 423, 424,
    425, 426, 427, 428, 429, 430, 431, 432, 440, 441,
    442, 443, 444, 445, 446, 447, 448, 449, 450, 451,
    452, 453, 454, 455, 456, 457, 458, 459, 460, 461,
    462, 463, 464, 465, 466, 467, 468, 469, 470, 471,
    472, 473, 474, 475, 476, 477, 478, 500, 501, 502,
    503, 504, 505, 506, 507, 508, 509, 510, 511, 512,
    513, 514, 515, 516, 517, 518, 519, 520, 521, 522,
    523, 524, 525, 526, 527, 528, 529, 530, 531, 532,
    533, 534, 535, 536, 537, 538, 539, 540, 541, 542,
    543, 544, 545, 546, 547, 548, 549, 550, 551, 552,
    553, 554, 555, 556, 557, 558, 559, 560, 561, 562,
    563, 564, 565, 566, 567, 568, 569, 570, 571, 572,
    573, 574, 575, 576, 577, 578, 579, 580, 581, 582,
    583, 584, 588, 590, 591, 592, 593, 594, 595, 596,
    597, 598, 599, 600, 601, 602, 603, 604, 605, 606,
    607, 608, 633, 634, 635, 636, 637, 638
};

new ObjectNames[][32] = {
    "Áàðüåð âîðîò áàðà", "Áîêñ áàðüåðà áàðà", "Ïîâîðîòíûé áàðüåð", "Ýëåêòðè÷åñêèå âîðîòà", "Ìàëåíüêèé çàáîð",
    "Âîðîòà ìåòðî", "Âõîä â òóííåëü", "Äîðîæíûé áàðüåð", "Âûñîêèé çàáîð", "Âîðîòà Columbian",
    "Äâåðü áàøíè", "Ïðàâàÿ ñòîðîíà ìåòðî", "Ëåâàÿ ñòîðîíà ìåòðî", "Âîðîòà àýðîïîðòà",
    "Ñïèðàëüíûé áàðüåð", "Áàðüåð 316", "Áàðüåð 317", "Áàðüåð 318", "Áàðüåð 319",
    "Áàðüåð 320", "Áàðüåð 321", "Áàðüåð 322", "Áàðüåð 323", "Áàðüåð 324",
    "Ìàëåíüêèé êàìåíü", "Ñòèðàëüíàÿ ìàøèíà", "Øèíà", "Ïëèòà", "Òîðãîâûé àâòîìàò",
    "Êåéñ", "Ïîæàðíûé ãèäðàíò", "Äåíüãè", "Ìèíà", "Áîëëàðä",
    "Îñâåùàåìûé áîëëàðä", "Òåëåôîííàÿ áóäêà", "Áî÷êà òèï 1", "Áî÷êà òèï 2", "Áî÷êà òèï 3",
    "Áî÷êà òèï 4", "Áî÷êà òèï 5", "Áî÷êà òèï 6", "Ïàëëåòà", "Ïðèáðåæíûé ôîíàðü",
    "Êàðòîííàÿ êîðîáêà", "Áî÷êà òèï 7", "Ôîíàðíûé ñòîëá ¹3", "Ìóñîðíàÿ êîðçèíà", "Ìóñîðíûé áàê",
    "Äîðîæíûé áàðüåð ðåìîíòà", "Çíàê àâòîáóñà", "Ôîíàðü òèï 1", "Ôîíàðü òèï 2", "Çíàê ïàðêîâêè",
    "Òåëåôîííûé çíàê", "Óðíà", "Êîíòåéíåð", "Áàðüåð òèï 2", "Êîíóñ",
    "Èêîíêà çäîðîâüÿ", "Èêîíêà áðîíè", "Èêîíêà àäðåíàëèíà", "Èêîíêà âçÿòêè", "Áóé",
    "Áåíçîêîëîíêà", "Íîâàÿ ðàìïà", "Ëèíèÿ", "Êàìåíü òèï 1", "Êàìåíü òèï 2",
    "Èêîíêà áîíóñà", "Èêîíêà áîíóñà 2", "Ôàëüøèâàÿ ìèøåíü", "Ñòîëá", "Ïåðåêëàäèíà",
    "Âçðûâàþùàÿñÿ áî÷êà", "Ðàçáèòîå ñòåêëî", "Èêîíêà êàìåðû", "Èêîíêà óáèéñòâ", "Òåëåãðàôíûé ñòîëá",
    "Øåçëîíã", "Êàìåííàÿ ñêàìåéêà", "Ìàéàìñêèé òåëåôîí", "Ìàéàìñêèé ãèäðàíò", "Îñòàíîâêà Ìàéàìè",
    "Ïî÷òîâûé ÿùèê", "Ðåêëàìíûé ùèò 1", "Ðåêëàìíûé ùèò 2", "Ðåêëàìíûé ùèò 3", "Äîðîæíûé çíàê 1",
    "Ìóñîðíàÿ êîðçèíà", "Äîðîæíûé çíàê 2", "Äîðîæíûé çíàê 3", "×åðíûé ìåøîê", "×åðíûé ìåøîê 2",
    "Ðåêëàìíûé ùèò 4", "Ðåêëàìíûé ùèò 5", "Ðåêëàìíûé ùèò 6", "Ïàðêîâî÷íûé ñ÷åò÷èê", "Ïàðêîâî÷íûé ñ÷åò÷èê 2",
    "ßùèê ñ îðóæèåì", "Èêîíêà íåäâèæèìîñòè", "Èêîíêà îäåæäû", "Èêîíêà íàâûêîâ", "Èêîíêà êàçèíî",
    "Ïîñûëêà", "Ïèêàï ñîõðàíåíèÿ", "Ïî÷òîâûé ÿùèê 2", "Ãàçåòíûé êèîñê", "Ïàðêîâàÿ ñêàìåéêà",
    "Ãàçåòíûé àâòîìàò", "Ïàðêîâûé ñòîë", "Ôîíàðíûé ñòîëá áîëüøîé", "Ñàäîâàÿ ñêàìåéêà", "Áàðüåð Ìàéàìè",
    "Êèîñê 1", "Êèîñê 2", "Êèîñê 3", "Êèîñê 4", "Êèîñê 5",
    "Ôîíàðíûé ñòîëá ìàëûé", "Äâîéíîé ôîíàðü", "Ñâåòîôîð", "Äîðîæíûé çíàê Ìàéàìè", "Ôîíàðü Ìàéàìè",
    "Ïðîæåêòîð", "Ïîñûëêà Êðåéãà", "Ïèêàï ìóçûêè", "Ïàëüìà 1", "Ïàëüìà 2",
    "Ïàëüìà 3", "Ïàëüìà 4", "Ïàëüìà 5", "Ïàëüìà 6", "Ïàëüìà 7",
    "Ïàëüìà 8", "Ïàëüìà 9", "Ïàëüìà 10", "Ïàëüìà 11", "Ïàëüìà 12",
    "Ïàëüìà 13", "Ïàëüìà 14", "Ïàëüìà 15", "Ïàëüìà 16", "Ïàëüìà 17",
    "Ïàëüìà 18", "Ïàëüìà 19", "Ïàëüìà 20", "Ðàñòåíèå â ãîðøêå", "Êóñò",
    "Ïëþù 1", "Ïëþù 2", "Ïëþù 3", "Ïëþù 4", "Ïëþù 5",
    "Ïëþù 6", "Ïëþù 7", "Ïëþù 8", "Ïëþù 9", "Ïëþù 10",
    "Ïëþù 11", "Ïëþù 12", "Ïëþù 13", "Ïëþù 14", "Ïëþù 15",
    "Ïëþù 16", "Ïëþù 17", "Ïàëüìà áîëüøàÿ", "Ìåäèà-ñöåíà", "Ìóñîðíûé áàê",
    "Íàðêîòèêè êðàñíûå", "Íàðêîòèêè çåëåíûå", "Íàðêîòèêè ñèíèå", "Íàðêîòèêè æåëòûå", "Íàðêîòèêè ôèîëåòîâûå",
    "Íàðêîòèêè ðîçîâûå", "Êëþ÷-êàðòà", "Áàííåð Love Fist", "Êîðîáêà ïèööû", "Ìèøåíü 1",
    "Ìèøåíü 2", "Ìèøåíü 3", "Ìèøåíü 4", "Ìèøåíü 5", "Ìèøåíü 6",
    "Ìèøåíü 7", "Ìèøåíü 8", "Ìèøåíü 9", "Ìèøåíü 10", "Øèïû ïîëèöèè",
    "Ñòóë", "Ñòîë", "Ñïóòíèêîâàÿ òàðåëêà", "Ñïóòíèê ìàëûé", "Êîíòðîëëåð",
    "Ïëÿæíûé ìÿ÷", "Ðûáà 1", "Ðûáà 2", "Ðûáà 3", "Ðûáà 4",
    "Ðûáà 5", "Ðûáà 6", "Ðûáà 7", "Ðûáà 8", "Ðûáà 9",
    "Ìåäóçà", "Àêóëà", "×åðåïàõà", "Äåëüôèí", "Ïåñ÷àíûé çàìîê",
    "Ïåñ÷àíûé çàìîê ìàëûé", "Ïîäâîäíàÿ ëîäêà", "Êîíäèöèîíåð 1", "Êîíäèöèîíåð 2", "Âåíòèëÿöèÿ",
    "Êàìåðà", "Àíòåííà", "Òðóáà", "Êîðîáêà", "ßùèê",
    "Ãåíåðàòîð", "Ðàäèàòîð", "Òðàìïëèí âîäíûé", "Òðàìïëèí íàçåìíûé", "Òðàìïëèí 2",
    "Äâîéíîé êîíäèöèîíåð", "Ðàäèî-áîìáà", "Øåçëîíã ïëÿæíûé", "Ïîëîòåíöå", "Çîíòèê",
    "Ñåòêà", "Ðàçáèòîå îêíî", "Êàíèñòðà", "Îêíî ïîëèöèè", "Çàáîð Ãàèòè",
    "Çàáîð Ãàèòè 2", "Äèíàìèò", "Òðàìïëèí 3", "Ýñêàëàòîð", "Ðàìïà",
    "Áëîê CI", "Áóòûëêà", "Áîêàë", "Ïåïåëüíèöà", "Áàðíàÿ ñòîéêà",
    "Ñòóë áàðíûé", "Êðóæêà", "Âðàùàþùååñÿ êðåñëî", "Ãàçîâàÿ ãðàíàòà", "Äîðîæíûé çíàê",
    "Çäàíèå Wash 1", "Çäàíèå Wash 2", "Çäàíèå Wash 3", "Çäàíèå Wash 4", "Çäàíèå Wash 5",
    "Çäàíèå Wash 6", "Çäàíèå Wash 7", "Ãðîá", "Ñòóë ìàëûé", "LOD ñàìîëåòà",
    "Learjet", "Ðàäàð", "Jumbo"
};

public OnFilterScriptInit()
{
    print("\n=========================================");
    print("Object Editor with Custom Menu v1.0");
    print("Developer by Alexander");
    print("https://vicemultiplayer.mybb.ru/");
    print("=========================================\n");
    return 1;
}

public OnFilterScriptExit()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        DestroyPlayerObjects(i);
        if(EditingTimer[i]) KillTimer(EditingTimer[i]);
        UnloadCustomMenuTextDraws(i);
        if(NoclipMode[i])
        {
            DisableNoclip(i);
        }
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    CurrentObject[playerid] = -1;
    EditingMode[playerid] = false;
    EditSubMode[playerid] = EDIT_MODE_NONE;
    EditingTimer[playerid] = 0;
    MenuState[playerid] = 0;
    ObjectMenuPage[playerid] = 0;

    PlayerMoveSpeed[playerid] = MOVE_SPEED;
    PlayerRotateSpeed[playerid] = ROTATE_SPEED;

    NoclipMode[playerid] = false;
    NoclipPitch[playerid] = 0.0;

    for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
    {
        PlayerObjects[playerid][i][objActive] = false;
        PlayerObjects[playerid][i][ObjId] = -1;
    }

    LoadCustomMenuTextdraws(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    DestroyPlayerObjects(playerid);
    if(EditingTimer[playerid]) KillTimer(EditingTimer[playerid]);
    UnloadCustomMenuTextDraws(playerid);
    if(NoclipMode[playerid])
    {
        DisableNoclip(playerid);
    }
    return 1;
}

CloneCurrentObject(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Íåò âûáðàííîãî îáúåêòà äëÿ êîïèðîâàíèÿ!");
        return 0;
    }

    new freeSlot = -1;
    for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
    {
        if(!PlayerObjects[playerid][i][objActive])
        {
            freeSlot = i;
            break;
        }
    }

    if(freeSlot == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Äîñòèãíóò ëèìèò îáúåêòîâ (50)! Íåëüçÿ ñîçäàòü êîïèþ.");
        return 0;
    }

    new srcIdx = CurrentObject[playerid];

    new Float:x, Float:y, Float:z;
    x = PlayerObjects[playerid][srcIdx][objX];
    y = PlayerObjects[playerid][srcIdx][objY];
    z = PlayerObjects[playerid][srcIdx][objZ];

    new Float:offsetX = 1.0, Float:offsetY = 1.0;

    new newObjId = CreateObject(
        PlayerObjects[playerid][srcIdx][objModel],
        x + offsetX,
        y + offsetY,
        z,
        PlayerObjects[playerid][srcIdx][objRX],
        PlayerObjects[playerid][srcIdx][objRY],
        PlayerObjects[playerid][srcIdx][objRZ]
    );

    PlayerObjects[playerid][freeSlot][objActive] = true;
    PlayerObjects[playerid][freeSlot][ObjId] = newObjId;
    PlayerObjects[playerid][freeSlot][objX] = x + offsetX;
    PlayerObjects[playerid][freeSlot][objY] = y + offsetY;
    PlayerObjects[playerid][freeSlot][objZ] = z;
    PlayerObjects[playerid][freeSlot][objRX] = PlayerObjects[playerid][srcIdx][objRX];
    PlayerObjects[playerid][freeSlot][objRY] = PlayerObjects[playerid][srcIdx][objRY];
    PlayerObjects[playerid][freeSlot][objRZ] = PlayerObjects[playerid][srcIdx][objRZ];
    PlayerObjects[playerid][freeSlot][objModel] = PlayerObjects[playerid][srcIdx][objModel];

    if(EditingMode[playerid])
    {
        if(PlayerObjects[playerid][CurrentObject[playerid]][objActive])
        {
            ToggleObjectArrow(PlayerObjects[playerid][CurrentObject[playerid]][ObjId], false);
        }
        ToggleObjectArrow(newObjId, true);
    }

    CurrentObject[playerid] = freeSlot;

    CreateObjectLabel(playerid, freeSlot);

    new msg[128];
    format(msg, sizeof(msg), "Ñîçäàíà êîïèÿ îáúåêòà #%d -> #%d (ñìåùåíà íà +%.1f +%.1f)",
        srcIdx + 1, freeSlot + 1, offsetX, offsetY);
    SendClientMessage(playerid, COLOR_GREEN, msg);

    return 1;
}
public OnPlayerKeyPress(playerid, key)
{
    if(PlayerCustomMenuCreated[playerid] == 1 && MenuState[playerid] == 2)
    {
        if(key == WK_KEY_3)
        {
            new totalObjects = sizeof(ObjectModels);
            new maxPages = (totalObjects + 6) / 7;

            if(ObjectMenuPage[playerid] < maxPages - 1)
            {
                ObjectMenuPage[playerid]++;
                ShowObjectSelectionMenu(playerid);
            }
            else
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Ýòî ïîñëåäíÿÿ ñòðàíèöà!");
            }
            return 1;
        }
        if(key == WK_KEY_4)
        {
            if(ObjectMenuPage[playerid] > 0)
            {
                ObjectMenuPage[playerid]--;
                ShowObjectSelectionMenu(playerid);
            }
            else
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Ýòî ïåðâàÿ ñòðàíèöà!");
            }
            return 1;
        }
    }

    if(key == WK_KEY_U)
    {
        if(!NoclipMode[playerid])
        {
            EnableNoclip(playerid);
        }
        else
        {
            DisableNoclip(playerid);
        }
        return 1;
    }

    if(key == WK_KEY_Y)
    {
        ShowSpeedMenu(playerid);
        return 1;
    }
    if(key == WK_KEY_M)
    {
        ShowMainMenu(playerid);
        return 1;
    }

    if(key == WK_KEY_1)
    {
        SelectPreviousObject(playerid);
        return 1;
    }

    if(key == WK_KEY_2)
    {
        SelectNextObject(playerid);
        return 1;
    }

    if(key == WK_KEY_N)
    {
        DeleteCurrentObject(playerid);
        return 1;
    }

    if(key == WK_KEY_H)
    {
        if(CurrentObject[playerid] == -1)
        {
            if(HasAnyObject(playerid))
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Ñíà÷àëà âûáåðèòå îáúåêò (1/2 èëè ìåíþ)");
                ShowObjectListMenu(playerid);
            }
            else
                SendClientMessage(playerid, COLOR_RED, "Ñíà÷àëà ñîçäàéòå îáúåêò!");
            return 1;
        }

        if(!EditingMode[playerid])
        {
            EditingMode[playerid] = true;
            TogglePlayerControllable(playerid, false);

            new objIndex = CurrentObject[playerid];
            if(PlayerObjects[playerid][objIndex][objActive])
            {
                ToggleObjectArrow(PlayerObjects[playerid][objIndex][ObjId], true);
            }

            ShowEditModeMenu(playerid);
        }
        else
        {
            EditingMode[playerid] = false;
            EditSubMode[playerid] = EDIT_MODE_NONE;
            TogglePlayerControllable(playerid, true);

            new objIndex = CurrentObject[playerid];
            if(PlayerObjects[playerid][objIndex][objActive])
            {
                ToggleObjectArrow(PlayerObjects[playerid][objIndex][ObjId], false);
            }

            SendClientMessage(playerid, COLOR_RED, "========== ÐÅÆÈÌ ÐÅÄÀÊÒÈÐÎÂÀÍÈß ÂÛÊËÞ×ÅÍ ==========");
        }
        return 1;
    }

    if(key == WK_KEY_C)
    {
        SaveObjectsToLog(playerid);
        return 1;
    }
	if(key == WK_KEY_X)
	{
	    CloneCurrentObject(playerid);
		return 1;
	}
    if(key == WK_KEY_5)
    {
        TogglePlayerControllable(playerid, false);
        return 1;
    }
    if(key == WK_KEY_6)
    {
        TogglePlayerControllable(playerid, true);
        return 1;
    }

    if(NoclipMode[playerid])
    {
        new Float:speed = NOCLIP_SPEED;
        new Float:yaw = NoclipRot[playerid][0];
        new Float:pitch = NoclipPitch[playerid];

        if(key == WK_KEY_NUM_8)
        {
            NoclipPos[playerid][0] += speed * floatsin(-yaw, degrees) * floatcos(pitch, degrees);
            NoclipPos[playerid][1] += speed * floatcos(-yaw, degrees) * floatcos(pitch, degrees);
            NoclipPos[playerid][2] += speed * floatsin(pitch, degrees);
            UpdateNoclipCamera(playerid);
        }
        else if(key == WK_KEY_NUM_2)
        {
            NoclipPos[playerid][0] -= speed * floatsin(-yaw, degrees) * floatcos(pitch, degrees);
            NoclipPos[playerid][1] -= speed * floatcos(-yaw, degrees) * floatcos(pitch, degrees);
            NoclipPos[playerid][2] -= speed * floatsin(pitch, degrees);
            UpdateNoclipCamera(playerid);
        }
        else if(key == WK_KEY_NUM_4)
        {
            NoclipPos[playerid][0] += speed * floatsin(-yaw - 90.0, degrees);
            NoclipPos[playerid][1] += speed * floatcos(-yaw - 90.0, degrees);
            UpdateNoclipCamera(playerid);
        }
        else if(key == WK_KEY_NUM_6)
        {
            NoclipPos[playerid][0] += speed * floatsin(-yaw + 90.0, degrees);
            NoclipPos[playerid][1] += speed * floatcos(-yaw + 90.0, degrees);
            UpdateNoclipCamera(playerid);
        }
        else if(key == WK_KEY_NUM_PLUS)
        {
            NoclipPos[playerid][2] += speed;
            UpdateNoclipCamera(playerid);
        }
        else if(key == WK_KEY_NUM_DASH)
        {
            NoclipPos[playerid][2] -= speed;
            UpdateNoclipCamera(playerid);
        }
        else if(key == WK_KEY_NUM_7)
        {
            NoclipRot[playerid][0] += 5.0;
            UpdateNoclipCamera(playerid);

            new msg[128];
            format(msg, sizeof(msg), "Ïîâîðîò: %.1f | Íàêëîí: %.1f", NoclipRot[playerid][0], NoclipPitch[playerid]);
            SendClientMessage(playerid, COLOR_WHITE, msg);
        }
        else if(key == WK_KEY_NUM_9)
        {
            NoclipRot[playerid][0] -= 5.0;
            UpdateNoclipCamera(playerid);

            new msg[128];
            format(msg, sizeof(msg), "Ïîâîðîò: %.1f | Íàêëîí: %.1f", NoclipRot[playerid][0], NoclipPitch[playerid]);
            SendClientMessage(playerid, COLOR_WHITE, msg);
        }
        else if(key == WK_KEY_NUM_1)
        {
            if(NoclipPitch[playerid] < 85.0)
            {
                NoclipPitch[playerid] += 2.0;
                UpdateNoclipCamera(playerid);

                new msg[128];
                format(msg, sizeof(msg), "Íàêëîí ââåðõ: %.1f ãðàäóñîâ", NoclipPitch[playerid]);
                SendClientMessage(playerid, COLOR_WHITE, msg);
            }
            else
            {
                SendClientMessage(playerid, COLOR_RED, "Äîñòèãíóò ìàêñèìàëüíûé íàêëîí ââåðõ (85°)");
            }
        }
        else if(key == WK_KEY_NUM_3)
        {
            if(NoclipPitch[playerid] > -85.0)
            {
                NoclipPitch[playerid] -= 2.0;
                UpdateNoclipCamera(playerid);

                new msg[128];
                format(msg, sizeof(msg), "Íàêëîí âíèç: %.1f ãðàäóñîâ", NoclipPitch[playerid]);
                SendClientMessage(playerid, COLOR_WHITE, msg);
            }
            else
            {
                SendClientMessage(playerid, COLOR_RED, "Äîñòèãíóò ìàêñèìàëüíûé íàêëîí âíèç (-85°)");
            }
        }
        else if(key == WK_KEY_NUM_5)
        {
            NoclipPitch[playerid] = 0.0;
            UpdateNoclipCamera(playerid);
            SendClientMessage(playerid, COLOR_WHITE, "Íàêëîí ñáðîøåí");
        }
    }

    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(PlayerCustomMenuCreated[playerid] == 1)
    {
        OnPlayerChangeKeyCustomMenu(playerid, newkeys);
        return 1;
    }

    if(!EditingMode[playerid] || CurrentObject[playerid] == -1)
        return 1;

    new objIndex = CurrentObject[playerid];
    if(!PlayerObjects[playerid][objIndex][objActive])
        return 1;

    new Float:x, Float:y, Float:z;
    new Float:rx, Float:ry, Float:rz;
    new Float:moveSpeed = PlayerMoveSpeed[playerid];
    new bool:updated = false;

    GetObjectPos(PlayerObjects[playerid][objIndex][ObjId], x, y, z);
    GetObjectRot(PlayerObjects[playerid][objIndex][ObjId], rx, ry, rz);

    if(EditSubMode[playerid] == EDIT_MODE_MOVE)
    {
        if(newkeys == ONFOOT_KEY_UP)
        {
            new Float:angle;
            GetPlayerFacingAngle(playerid, angle);
            x += moveSpeed * floatsin(-angle, degrees);
            y += moveSpeed * floatcos(-angle, degrees);
            updated = true;
        }
        if(newkeys == ONFOOT_KEY_DOWN)
        {
            new Float:angle;
            GetPlayerFacingAngle(playerid, angle);
            x -= moveSpeed * floatsin(-angle, degrees);
            y -= moveSpeed * floatcos(-angle, degrees);
            updated = true;
        }
        if(newkeys == ONFOOT_KEY_LEFT)
        {
            new Float:angle;
            GetPlayerFacingAngle(playerid, angle);
            x += moveSpeed * floatsin(-angle - 90.0, degrees);
            y += moveSpeed * floatcos(-angle - 90.0, degrees);
            updated = true;
        }
        if(newkeys == ONFOOT_KEY_RIGHT)
        {
            new Float:angle;
            GetPlayerFacingAngle(playerid, angle);
            x += moveSpeed * floatsin(-angle + 90.0, degrees);
            y += moveSpeed * floatcos(-angle + 90.0, degrees);
            updated = true;
        }
        if(HOLDING(ONFOOT_KEY_UP | ONFOOT_KEY_SPRINT))
        {
            z += moveSpeed;
            updated = true;
        }
        if(HOLDING(ONFOOT_KEY_DOWN | ONFOOT_KEY_SPRINT))
        {
            z -= moveSpeed;
            updated = true;
        }
        if(updated)
        {
            SetObjectPos(PlayerObjects[playerid][objIndex][ObjId], x, y, z);
        }
    }

    if(EditSubMode[playerid] == EDIT_MODE_ROTATE)
    {
        if(newkeys == ONFOOT_KEY_UP)
        {
            rx += PlayerRotateSpeed[playerid];
            updated = true;
        }
        if(newkeys == ONFOOT_KEY_DOWN)
        {
            rx -= PlayerRotateSpeed[playerid];
            updated = true;
        }
        if(newkeys == ONFOOT_KEY_LEFT)
        {
            ry += PlayerRotateSpeed[playerid];
            updated = true;
        }
        if(newkeys == ONFOOT_KEY_RIGHT)
        {
            ry -= PlayerRotateSpeed[playerid];
            updated = true;
        }
        if(HOLDING(ONFOOT_KEY_UP | ONFOOT_KEY_SPRINT))
        {
			rz += PlayerRotateSpeed[playerid];
            updated = true;
        }
        if(HOLDING(ONFOOT_KEY_DOWN | ONFOOT_KEY_SPRINT))
        {
            rz -= PlayerRotateSpeed[playerid];
            updated = true;
        }

        if(updated)
        {
            SetObjectRot(PlayerObjects[playerid][objIndex][ObjId], rx, ry, rz);
        }
    }

    if(updated)
    {
        GetObjectPos(PlayerObjects[playerid][objIndex][ObjId],
            PlayerObjects[playerid][objIndex][objX],
            PlayerObjects[playerid][objIndex][objY],
            PlayerObjects[playerid][objIndex][objZ]);

        GetObjectRot(PlayerObjects[playerid][objIndex][ObjId],
            PlayerObjects[playerid][objIndex][objRX],
            PlayerObjects[playerid][objIndex][objRY],
            PlayerObjects[playerid][objIndex][objRZ]);

        UpdateObjectLabel(playerid, objIndex);

        new msg[128];
        format(msg, sizeof(msg), "Ïîçèöèÿ: %.2f, %.2f, %.2f | Ïîâîðîò: RX: %.2f RY: %.2f RZ: %.2f",
            PlayerObjects[playerid][objIndex][objX],
            PlayerObjects[playerid][objIndex][objY],
            PlayerObjects[playerid][objIndex][objZ],
            PlayerObjects[playerid][objIndex][objRX],
            PlayerObjects[playerid][objIndex][objRY],
            PlayerObjects[playerid][objIndex][objRZ]);
        SendClientMessage(playerid, COLOR_WHITE, msg);
    }

    return 1;
}

EnableNoclip(playerid)
{
    if(NoclipMode[playerid]) return 0;

    GetPlayerPos(playerid, NoclipPos[playerid][0], NoclipPos[playerid][1], NoclipPos[playerid][2]);
    GetPlayerFacingAngle(playerid, NoclipRot[playerid][0]);
    NoclipPitch[playerid] = 0.0;
    
    TogglePlayerControllable(playerid, false);

    UpdateNoclipCamera(playerid);

    NoclipMode[playerid] = true;

    SendClientMessage(playerid, 0x00FF00FF, "========== NOCLIP ÐÅÆÈÌ ÂÊËÞ×ÅÍ ==========");
    SendClientMessage(playerid, 0xFFFFFFFF, "Num 8/Num 2 - âïåðåä/íàçàä | Num 4/Num 6 - âëåâî/âïðàâî");
    SendClientMessage(playerid, 0xFFFFFFFF, "Num 7/Num 9 - ïîâîðîò | Num 1/Num 3 - íàêëîí ââåðõ/âíèç");
    SendClientMessage(playerid, 0xFFFFFFFF, "Num + - ââåðõ | Num - - âíèç | Num 5 - ñáðîñ íàêëîíà");
    SendClientMessage(playerid, 0xFFFF00FF, "U - âûêëþ÷èòü noclip");

    return 1;
}

DisableNoclip(playerid)
{
    if(!NoclipMode[playerid]) return 0;

    TogglePlayerControllable(playerid, true);
    SetCameraBehindPlayer(playerid);

    SetPlayerPos(playerid, NoclipPos[playerid][0], NoclipPos[playerid][1], NoclipPos[playerid][2]);
    SetPlayerFacingAngle(playerid, NoclipRot[playerid][0]);

    NoclipMode[playerid] = false;

    SendClientMessage(playerid, 0xFF0000FF, "========== NOCLIP ÐÅÆÈÌ ÂÛÊËÞ×ÅÍ ==========");

    return 1;
}

UpdateNoclipCamera(playerid)
{
    if(!NoclipMode[playerid]) return 0;

    new Float:camX, Float:camY, Float:camZ;
    new Float:lookX, Float:lookY, Float:lookZ;

    camX = NoclipPos[playerid][0];
    camY = NoclipPos[playerid][1];
    camZ = NoclipPos[playerid][2] + 1.0;

    new Float:yaw = NoclipRot[playerid][0];
    new Float:pitch = NoclipPitch[playerid];

    new Float:distance = 5.0;

    lookX = camX + distance * floatsin(-yaw, degrees) * floatcos(pitch, degrees);
    lookY = camY + distance * floatcos(-yaw, degrees) * floatcos(pitch, degrees);
    lookZ = camZ + distance * floatsin(pitch, degrees);

    SetPlayerCameraPos(playerid, camX, camY, camZ);
    SetPlayerCameraLookAt(playerid, lookX, lookY, lookZ);

    return 1;
}

ShowSpeedMenu(playerid)
{
    CreatePlayerCustomMenu(playerid, 6);

    new title[64];
    format(title, sizeof(title), "Íàñòðîéêà ñêîðîñòè (Òåêóùàÿ: M-%.2f R-%.1f)",
        PlayerMoveSpeed[playerid], PlayerRotateSpeed[playerid]);

    SetPlayerStringCustomMenu(playerid, 0, title);
    SetPlayerStringCustomMenu(playerid, 1, "Ïåðåìåùåíèå: Ìåäëåííî (0.1)");
    SetPlayerStringCustomMenu(playerid, 2, "Ïåðåìåùåíèå: Íîðìàëüíî (0.25)");
    SetPlayerStringCustomMenu(playerid, 3, "Ïåðåìåùåíèå: Áûñòðî (0.5)");
    SetPlayerStringCustomMenu(playerid, 4, "Âðàùåíèå: Ìåäëåííî (1.0)");
    SetPlayerStringCustomMenu(playerid, 5, "Âðàùåíèå: Íîðìàëüíî (2.0)");
    SetPlayerStringCustomMenu(playerid, 6, "Âðàùåíèå: Áûñòðî (4.0)");

    MenuState[playerid] = 5;
    ShowCustomMenuForPlayer(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Âûáåðèòå ñêîðîñòü ñòðåëêàìè, Enter - âûáîð");
    return 1;
}
ShowEditModeMenu(playerid)
{
    CreatePlayerCustomMenu(playerid, 3);

    SetPlayerStringCustomMenu(playerid, 0, "Âûáåðèòå ðåæèì ðåäàêòèðîâàíèÿ");
    SetPlayerStringCustomMenu(playerid, 1, "Ïåðåìåùàòü îáúåêò");
    SetPlayerStringCustomMenu(playerid, 2, "Âðàùàòü îáúåêò");
    SetPlayerStringCustomMenu(playerid, 3, "Îòìåíà");

    EditSubMode[playerid] = EDIT_MODE_MENU;
    ShowCustomMenuForPlayer(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Èñïîëüçóéòå ñòðåëêè äëÿ íàâèãàöèè, Enter - âûáîð, Ïðîáåë - âûõîä");
    return 1;
}
ShowMainMenu(playerid)
{
    CreatePlayerCustomMenu(playerid, 9);

    SetPlayerStringCustomMenu(playerid, 0, "Ìåíþ óïðàâëåíèÿ îáúåêòàìè");
    SetPlayerStringCustomMenu(playerid, 1, "Ñîçäàòü îáúåêò");
    SetPlayerStringCustomMenu(playerid, 2, "Âûáðàòü îáúåêò");
    SetPlayerStringCustomMenu(playerid, 3, "Óäàëèòü îáúåêò");
    SetPlayerStringCustomMenu(playerid, 4, "Ðåæèì ðåäàêòèðîâàíèÿ");
    SetPlayerStringCustomMenu(playerid, 5, "Ñîõðàíèòü â ôàéë");
    SetPlayerStringCustomMenu(playerid, 6, "Çàãðóçèòü èç ôàéëà");
    SetPlayerStringCustomMenu(playerid, 7, "Ñïèñîê îáúåêòîâ");
    SetPlayerStringCustomMenu(playerid, 8, "Ñîõðàíèòü â ëîã (C)");
    SetPlayerStringCustomMenu(playerid, 9, "Äóáëèðîâàòü îáúåêò(X)");

    MenuState[playerid] = 1;
    ShowCustomMenuForPlayer(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Èñïîëüçóéòå ñòðåëêè äëÿ íàâèãàöèè, Enter - âûáîð, Ïðîáåë - âûõîä");
    return 1;
}

public OnPlayerEnterCustomMenu(playerid, playercustommenuid)
{
    new id = playercustommenuid;

    if(MenuState[playerid] == 1)
    {
        HideCustomMenuForPlayer(playerid);
        ClearCustomMenuTempDate(playerid);

        if(id == 1)
        {
            ObjectMenuPage[playerid] = 0;
            SetTimerEx("ShowObjectSelectionMenuEx", 100, 0, "d", playerid);
        }
        else if(id == 2)
        {
            if(HasAnyObject(playerid))
                SetTimerEx("ShowObjectListMenuEx", 100, 0, "d", playerid);
            else
                SendClientMessage(playerid, COLOR_RED, "Ó âàñ íåò ñîçäàííûõ îáúåêòîâ!");
        }
        else if(id == 3)
        {
            if(CurrentObject[playerid] != -1)
                SetTimerEx("ShowDeleteConfirmationEx", 100, 0, "d", playerid);
            else
                SendClientMessage(playerid, COLOR_RED, "Íåò âûáðàííîãî îáúåêòà!");
        }
        else if(id == 4)
        {
            ToggleEditingMode(playerid);
        }
        else if(id == 5)
        {
            SaveObjectsToFile(playerid);
        }
        else if(id == 6)
        {
            LoadObjectsFromFile(playerid);
        }
        else if(id == 7)
        {
            SetTimerEx("ShowObjectListMenuEx", 100, 0, "d", playerid);
        }
        else if(id == 8)
        {
            SaveObjectsToLog(playerid);
        }
        else if(id == 9)
        {
            CloneCurrentObject(playerid);
        }
    }
    else if(EditSubMode[playerid] == EDIT_MODE_MENU)
    {
        HideCustomMenuForPlayer(playerid);
        ClearCustomMenuTempDate(playerid);

        if(id == 1)
        {
            EditSubMode[playerid] = EDIT_MODE_MOVE;
            SendClientMessage(playerid, COLOR_GREEN, "========== ÐÅÆÈÌ ÏÅÐÅÌÅÙÅÍÈß ==========");
            SendClientMessage(playerid, COLOR_WHITE, "W/S - âïåðåä/íàçàä | A/D - âëåâî/âïðàâî");
            SendClientMessage(playerid, COLOR_WHITE, "Shift+W/S - ââåðõ/âíèç");
            SendClientMessage(playerid, COLOR_YELLOW, "H - âûêëþ÷èòü ðåæèì ðåäàêòèðîâàíèÿ");
            SendClientMessage(playerid, COLOR_YELLOW, "5 - çàìîðîçêà ïåðñîíàæà");
            SendClientMessage(playerid, COLOR_YELLOW, "6 - ðàçìîðîçêà ïåðñîíàæà");
        }
        else if(id == 2)
        {
            EditSubMode[playerid] = EDIT_MODE_ROTATE;
            SendClientMessage(playerid, COLOR_GREEN, "========== ÐÅÆÈÌ ÂÐÀÙÅÍÈß ==========");
            SendClientMessage(playerid, COLOR_WHITE, "Q/E - âðàùåíèå ïî ãîðèçîíòàëè (RZ)");
            SendClientMessage(playerid, COLOR_WHITE, "Shift+Q/E - íàêëîí (RX)");
            SendClientMessage(playerid, COLOR_WHITE, "A/D - âðàùåíèå ïî âåðòèêàëè (RY)");
            SendClientMessage(playerid, COLOR_YELLOW, "H - âûêëþ÷èòü ðåæèì ðåäàêòèðîâàíèÿ");
            SendClientMessage(playerid, COLOR_YELLOW, "5 - çàìîðîçêà ïåðñîíàæà");
            SendClientMessage(playerid, COLOR_YELLOW, "6 - ðàçìîðîçêà ïåðñîíàæà");
        }
        else if(id == 3)
        {
            EditingMode[playerid] = false;
            EditSubMode[playerid] = EDIT_MODE_NONE;
            TogglePlayerControllable(playerid, true);

            new objIndex = CurrentObject[playerid];
            if(PlayerObjects[playerid][objIndex][objActive])
            {
                ToggleObjectArrow(PlayerObjects[playerid][objIndex][ObjId], false);
            }

            SendClientMessage(playerid, COLOR_RED, "Ðåæèì ðåäàêòèðîâàíèÿ îòìåíåí");
        }
    }
    else if(MenuState[playerid] == 2)
    {
        new totalObjects = sizeof(ObjectModels);
        new selectedModel = ObjectMenuPage[playerid] * 7 + (id - 1);

        if(selectedModel >= 0 && selectedModel < totalObjects)
        {
            HideCustomMenuForPlayer(playerid);
            ClearCustomMenuTempDate(playerid);

            CreateObjectWithModel(playerid, ObjectModels[selectedModel]);
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Íåâåðíûé âûáîð");
            HideCustomMenuForPlayer(playerid);
            ClearCustomMenuTempDate(playerid);
        }
    }
    else if(MenuState[playerid] == 3)
    {
        new count = 0;
        new selectedIdx = -1;
        for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
        {
            if(PlayerObjects[playerid][i][objActive])
            {
                count++;
                if(count == id)
                {
                    selectedIdx = i;
                    break;
                }
            }
        }

        if(selectedIdx != -1)
        {
            CurrentObject[playerid] = selectedIdx;
            HideCustomMenuForPlayer(playerid);
            ClearCustomMenuTempDate(playerid);

            ShowObjectInfo(playerid, selectedIdx);
            SendClientMessage(playerid, COLOR_GREEN, "Îáúåêò âûáðàí! Íàæìèòå H äëÿ ðåäàêòèðîâàíèÿ.");
        }
        else
        {
            HideCustomMenuForPlayer(playerid);
            ClearCustomMenuTempDate(playerid);
        }
    }
    else if(MenuState[playerid] == 4)
    {
        HideCustomMenuForPlayer(playerid);
        ClearCustomMenuTempDate(playerid);

        if(id == 1)
        {
            DeleteCurrentObject(playerid);
        }
        else
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Óäàëåíèå îòìåíåíî");
        }
    }
    else if(MenuState[playerid] == 5)
    {
        HideCustomMenuForPlayer(playerid);
        ClearCustomMenuTempDate(playerid);

        switch(id)
        {
            case 1:
            {
                PlayerMoveSpeed[playerid] = 0.01;
                SendClientMessage(playerid, COLOR_GREEN, "Ñêîðîñòü ïåðåìåùåíèÿ: 0.1 (Ìåäëåííî)");
            }
            case 2:
            {
                PlayerMoveSpeed[playerid] = 0.5;
                SendClientMessage(playerid, COLOR_GREEN, "Ñêîðîñòü ïåðåìåùåíèÿ: 0.25 (Íîðìàëüíî)");
            }
            case 3:
            {
                PlayerMoveSpeed[playerid] = 1.5;
                SendClientMessage(playerid, COLOR_GREEN, "Ñêîðîñòü ïåðåìåùåíèÿ: 0.5 (Áûñòðî)");
            }
            case 4:
            {
                PlayerRotateSpeed[playerid] = 0.02;
                SendClientMessage(playerid, COLOR_GREEN, "Ñêîðîñòü âðàùåíèÿ: 1.0 (Ìåäëåííî)");
            }
            case 5:
            {
                PlayerRotateSpeed[playerid] = 1.0;
                SendClientMessage(playerid, COLOR_GREEN, "Ñêîðîñòü âðàùåíèÿ: 2.0 (Íîðìàëüíî)");
            }
            case 6:
            {
                PlayerRotateSpeed[playerid] = 2.0;
                SendClientMessage(playerid, COLOR_GREEN, "Ñêîðîñòü âðàùåíèÿ: 4.0 (Áûñòðî)");
            }
        }

        new msg[128];
        format(msg, sizeof(msg), "Òåêóùèå íàñòðîéêè: Ïåðåìåùåíèå: %.2f, Âðàùåíèå: %.1f",
            PlayerMoveSpeed[playerid], PlayerRotateSpeed[playerid]);
        SendClientMessage(playerid, COLOR_WHITE, msg);
    }
    return 1;
}

public OnPlayerExitCustomMenu(playerid)
{
    HideCustomMenuForPlayer(playerid);
    ClearCustomMenuTempDate(playerid);
    MenuState[playerid] = 0;
    ObjectMenuPage[playerid] = 0;
    SendClientMessage(playerid, COLOR_WHITE, "Ìåíþ çàêðûòî");
    return 1;
}

forward ShowObjectSelectionMenuEx(playerid);
public ShowObjectSelectionMenuEx(playerid)
{
    ShowObjectSelectionMenu(playerid);
}

forward ShowObjectListMenuEx(playerid);
public ShowObjectListMenuEx(playerid)
{
    ShowObjectListMenu(playerid);
}

forward ShowDeleteConfirmationEx(playerid);
public ShowDeleteConfirmationEx(playerid)
{
    ShowDeleteConfirmation(playerid);
}

ShowObjectSelectionMenu(playerid)
{
    new totalObjects = sizeof(ObjectModels);
    new startIdx = ObjectMenuPage[playerid] * 7;
    new menuItems = 0;

    if(startIdx + 7 > totalObjects)
        menuItems = totalObjects - startIdx;
    else
        menuItems = 7;

    if(menuItems <= 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Íåò îáúåêòîâ äëÿ îòîáðàæåíèÿ");
        return 0;
    }

    CreatePlayerCustomMenu(playerid, menuItems + 1);

    new title[64];
    new maxPages = (totalObjects + 6) / 7;
    format(title, sizeof(title), "Âûáåðèòå îáúåêò (Ñòð. %d/%d)", ObjectMenuPage[playerid] + 1, maxPages);
    SetPlayerStringCustomMenu(playerid, 0, title);

    for(new i = 0; i < menuItems; i++)
    {
        SetPlayerStringCustomMenu(playerid, i + 1, ObjectNames[startIdx + i]);
    }

    MenuState[playerid] = 2;
    ShowCustomMenuForPlayer(playerid);

    SendClientMessage(playerid, COLOR_YELLOW, "Ñòðåëêè/3-4: ëèñòàòü ñòðàíèöû | Ïðîáåë/Backspace: âûõîä");

    return 1;
}

ShowObjectListMenu(playerid)
{
    new count = 0;

    for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
    {
        if(PlayerObjects[playerid][i][objActive])
            count++;
    }

    if(count == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Ó âàñ íåò ñîçäàííûõ îáúåêòîâ!");
        return 0;
    }

    new menuItems = (count > 7) ? 7 : count;

    CreatePlayerCustomMenu(playerid, menuItems + 1);

    SetPlayerStringCustomMenu(playerid, 0, "Âàøè îáúåêòû");

    new itemIndex = 1;
    for(new i = 0; i < MAX_PLAYER_OBJECTS && itemIndex <= menuItems; i++)
    {
        if(PlayerObjects[playerid][i][objActive])
        {
            new objName[64];
            new modelIndex = GetModelIndex(PlayerObjects[playerid][i][objModel]);
            new modelName[32];

            if(modelIndex != -1)
                format(modelName, 32, ObjectNames[modelIndex]);
            else
                format(modelName, 32, "Unknown");

            format(objName, sizeof(objName), "#%d: %s", i + 1, modelName);
            SetPlayerStringCustomMenu(playerid, itemIndex, objName);
            itemIndex++;
        }
    }

    if(count > 7)
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Ïîêàçàíû ïåðâûå 7 îáúåêòîâ.");
    }

    MenuState[playerid] = 3;
    ShowCustomMenuForPlayer(playerid);
    return 1;
}

ShowDeleteConfirmation(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Íåò âûáðàííîãî îáúåêòà!");
        return 0;
    }
    CreatePlayerCustomMenu(playerid, 3);

    new confirmMsg[64];
    format(confirmMsg, 64, "Óäàëèòü îáúåêò #%d?", CurrentObject[playerid] + 1);
    SetPlayerStringCustomMenu(playerid, 0, confirmMsg);
    SetPlayerStringCustomMenu(playerid, 1, "Äà");
    SetPlayerStringCustomMenu(playerid, 2, "Íåò");

    MenuState[playerid] = 4;
    ShowCustomMenuForPlayer(playerid);
    return 1;
}

CreateObjectWithModel(playerid, modelid)
{
    new freeSlot = -1;
    for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
    {
        if(!PlayerObjects[playerid][i][objActive])
        {
            freeSlot = i;
            break;
        }
    }

    if(freeSlot == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Âû äîñòèãëè ìàêñèìàëüíîãî êîëè÷åñòâà îáúåêòîâ (50)!");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new Float:angle;
    GetPlayerFacingAngle(playerid, angle);

    x += 3.0 * floatsin(-angle, degrees);
    y += 3.0 * floatcos(-angle, degrees);

    new objectId = CreateObject(modelid, x, y, z, 0.0, 0.0, 0.0);

    PlayerObjects[playerid][freeSlot][objActive] = true;
    PlayerObjects[playerid][freeSlot][ObjId] = objectId;
    PlayerObjects[playerid][freeSlot][objX] = x;
    PlayerObjects[playerid][freeSlot][objY] = y;
    PlayerObjects[playerid][freeSlot][objZ] = z;
    PlayerObjects[playerid][freeSlot][objRX] = 0.0;
    PlayerObjects[playerid][freeSlot][objRY] = 0.0;
    PlayerObjects[playerid][freeSlot][objRZ] = 0.0;
    PlayerObjects[playerid][freeSlot][objModel] = modelid;

    if(EditingMode[playerid])
    {
        if(CurrentObject[playerid] != -1 && PlayerObjects[playerid][CurrentObject[playerid]][objActive])
        {
            ToggleObjectArrow(PlayerObjects[playerid][CurrentObject[playerid]][ObjId], false);
        }
        ToggleObjectArrow(objectId, true);
    }

    CurrentObject[playerid] = freeSlot;

    CreateObjectLabel(playerid, freeSlot);

    new msg[128];
    new modelIndex = GetModelIndex(modelid);
    new modelName[32];
    if(modelIndex != -1)
        format(modelName, 32, ObjectNames[modelIndex]);
    else
        format(modelName, 32, "Unknown");

    format(msg, sizeof(msg), "Ñîçäàí îáúåêò #%d [ID: %d] (%s)", freeSlot + 1, modelid, modelName);
    SendClientMessage(playerid, COLOR_GREEN, msg);

    if(!EditingMode[playerid])
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Èñïîëüçóéòå H äëÿ âõîäà â ðåæèì ðåäàêòèðîâàíèÿ");
    }

    return 1;
}

SaveObjectsToLog(playerid)
{
    new count = 0;
    new logFile[64];
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    new year, month, day;
    getdate(year, month, day);
    format(logFile, sizeof(logFile), "objects_%s_%d-%d-%d.txt", playerName, year, month, day);

    new File:file = fopen(logFile, io_write);
    if(file)
    {
        new line[256];
        new header[256];
        format(header, sizeof(header), "// Îáúåêòû èãðîêà %s (ID: %d) - %d/%d/%d\r\n", playerName, playerid, day, month, year);
        fwrite(file, header);
        fwrite(file, "// Ôîðìàò: CreateObject(modelid, x, y, z, rx, ry, rz);\r\n\r\n");

        for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
        {
            if(PlayerObjects[playerid][i][objActive])
            {
                format(line, sizeof(line),
                    "CreateObject(%d, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f); // Îáúåêò #%d\r\n",
                    PlayerObjects[playerid][i][objModel],
                    PlayerObjects[playerid][i][objX],
                    PlayerObjects[playerid][i][objY],
                    PlayerObjects[playerid][i][objZ],
                    PlayerObjects[playerid][i][objRX],
                    PlayerObjects[playerid][i][objRY],
                    PlayerObjects[playerid][i][objRZ],
                    i + 1
                );
                fwrite(file, line);
                count++;
            }
        }
        fclose(file);
        printf("=========================================");
        printf("Objects saved for player %s (ID: %d)", playerName, playerid);
        printf("File: %s", logFile);
        printf("Total objects: %d", count);
        printf("=========================================");

        new msg[128];
        format(msg, sizeof(msg), "Ñîõðàíåíî %d îáúåêòîâ â ôàéë: %s", count, logFile);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SendClientMessage(playerid, COLOR_ORANGE, "Ôàéë ñîõðàíåí â ïàïêó ñ ñåðâåðîì. Ìîæåòå ñêîïèðîâàòü");
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Îøèáêà ïðè ñîçäàíèè ôàéëà ëîãà!");
    }
    return 1;
}

GetModelIndex(modelid)
{
    for(new i = 0; i < sizeof(ObjectModels); i++)
    {
        if(ObjectModels[i] == modelid)
            return i;
    }
    return -1;
}

HasAnyObject(playerid)
{
    for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
    {
        if(PlayerObjects[playerid][i][objActive])
            return 1;
    }
    return 0;
}

SelectNextObject(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
        {
            if(PlayerObjects[playerid][i][objActive])
            {
                CurrentObject[playerid] = i;

                if(EditingMode[playerid])
                {
                    if(PlayerObjects[playerid][CurrentObject[playerid]][objActive])
                    {
                        ToggleObjectArrow(PlayerObjects[playerid][CurrentObject[playerid]][ObjId], false);
                    }
                    ToggleObjectArrow(PlayerObjects[playerid][i][ObjId], true);
                }

                ShowObjectInfo(playerid, i);
                return 1;
            }
        }
        SendClientMessage(playerid, COLOR_RED, "Ó âàñ íåò îáúåêòîâ äëÿ âûáîðà!");
        return 0;
    }

    new next = CurrentObject[playerid] + 1;
    for(new i = next; i < MAX_PLAYER_OBJECTS; i++)
    {
        if(PlayerObjects[playerid][i][objActive])
        {
            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][CurrentObject[playerid]][ObjId], false);
            }

            CurrentObject[playerid] = i;

            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][i][ObjId], true);
            }

            ShowObjectInfo(playerid, i);
            return 1;
        }
    }

    for(new i = 0; i < CurrentObject[playerid]; i++)
    {
        if(PlayerObjects[playerid][i][objActive])
        {
            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][CurrentObject[playerid]][ObjId], false);
            }

            CurrentObject[playerid] = i;

            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][i][ObjId], true);
            }

            ShowObjectInfo(playerid, i);
            return 1;
        }
    }

    SendClientMessage(playerid, COLOR_RED, "Íåò äðóãèõ îáúåêòîâ!");
    return 0;
}

SelectPreviousObject(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        for(new i = MAX_PLAYER_OBJECTS - 1; i >= 0; i--)
        {
            if(PlayerObjects[playerid][i][objActive])
            {
                CurrentObject[playerid] = i;

                if(EditingMode[playerid])
                {
                    ToggleObjectArrow(PlayerObjects[playerid][i][ObjId], true);
                }

                ShowObjectInfo(playerid, i);
                return 1;
            }
        }
        SendClientMessage(playerid, COLOR_RED, "Ó âàñ íåò îáúåêòîâ äëÿ âûáîðà!");
        return 0;
    }

    new prev = CurrentObject[playerid] - 1;
    for(new i = prev; i >= 0; i--)
    {
        if(PlayerObjects[playerid][i][objActive])
        {
            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][CurrentObject[playerid]][ObjId], false);
            }

            CurrentObject[playerid] = i;

            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][i][ObjId], true);
            }

            ShowObjectInfo(playerid, i);
            return 1;
        }
    }

    for(new i = MAX_PLAYER_OBJECTS - 1; i > CurrentObject[playerid]; i--)
    {
        if(PlayerObjects[playerid][i][objActive])
        {
            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][CurrentObject[playerid]][ObjId], false);
            }

            CurrentObject[playerid] = i;

            if(EditingMode[playerid])
            {
                ToggleObjectArrow(PlayerObjects[playerid][i][ObjId], true);
            }

            ShowObjectInfo(playerid, i);
            return 1;
        }
    }

    SendClientMessage(playerid, COLOR_RED, "Íåò äðóãèõ îáúåêòîâ!");
    return 0;
}

DeleteCurrentObject(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Íåò âûáðàííîãî îáúåêòà!");
        return 0;
    }

    new objIndex = CurrentObject[playerid];
    if(PlayerObjects[playerid][objIndex][objActive])
    {
        if(EditingMode[playerid])
        {
            ToggleObjectArrow(PlayerObjects[playerid][objIndex][ObjId], false);
        }

        DestroyObject(PlayerObjects[playerid][objIndex][ObjId]);
        DestroyObjectLabel(playerid, objIndex);

        PlayerObjects[playerid][objIndex][objActive] = false;
        PlayerObjects[playerid][objIndex][ObjId] = -1;

        SendClientMessage(playerid, COLOR_GREEN, "Îáúåêò óäàëåí!");

        SelectNextObject(playerid);
    }
    return 1;
}

ToggleEditingMode(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        if(HasAnyObject(playerid))
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Ñíà÷àëà âûáåðèòå îáúåêò (1/2 èëè ìåíþ)");
            ShowObjectListMenu(playerid);
        }
        else
            SendClientMessage(playerid, COLOR_RED, "Ñíà÷àëà ñîçäàéòå îáúåêò!");
        return 0;
    }

    EditingMode[playerid] = !EditingMode[playerid];

    if(EditingMode[playerid])
    {
        TogglePlayerControllable(playerid, false);

        new objIndex = CurrentObject[playerid];
        if(PlayerObjects[playerid][objIndex][objActive])
        {
            ToggleObjectArrow(PlayerObjects[playerid][objIndex][ObjId], true);
        }

        SendClientMessage(playerid, COLOR_GREEN, "========== ÐÅÆÈÌ ÐÅÄÀÊÒÈÐÎÂÀÍÈß ÂÊËÞ×ÅÍ ==========");
        SendClientMessage(playerid, COLOR_WHITE, "W/S - âïåðåä/íàçàä | A/D - âëåâî/âïðàâî");
        SendClientMessage(playerid, COLOR_WHITE, "Shift+W/S - ââåðõ/âíèç | Q/E - âðàùåíèå | Shift+Q/E - íàêëîí");
        SendClientMessage(playerid, COLOR_YELLOW, "H - âûêëþ÷èòü ðåæèì è ðàçìîðîçèòüñÿ");

        ShowObjectInfo(playerid, CurrentObject[playerid]);
    }
    else
    {
        TogglePlayerControllable(playerid, true);

        new objIndex = CurrentObject[playerid];
        if(PlayerObjects[playerid][objIndex][objActive])
        {
            ToggleObjectArrow(PlayerObjects[playerid][objIndex][ObjId], false);
        }

        SendClientMessage(playerid, COLOR_RED, "========== ÐÅÆÈÌ ÐÅÄÀÊÒÈÐÎÂÀÍÈß ÂÛÊËÞ×ÅÍ ==========");
    }
    return 1;
}

SaveObjectsToFile(playerid)
{
    new filename[64];
    GetPlayerName(playerid, filename, sizeof(filename));
    format(filename, sizeof(filename), "Objects_%s.ini", filename);

    new File:file = fopen(filename, io_write);
    if(file)
    {
        new count = 0;
        new line[256];

        for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
        {
            if(PlayerObjects[playerid][i][objActive])
            {
                format(line, sizeof(line), "%d,%f,%f,%f,%f,%f,%f\r\n",
                    PlayerObjects[playerid][i][objModel],
                    PlayerObjects[playerid][i][objX],
                    PlayerObjects[playerid][i][objY],
                    PlayerObjects[playerid][i][objZ],
                    PlayerObjects[playerid][i][objRX],
                    PlayerObjects[playerid][i][objRY],
                    PlayerObjects[playerid][i][objRZ]
                );
                fwrite(file, line);
                count++;
            }
        }
        fclose(file);

        new msg[128];
        format(msg, sizeof(msg), "Ñîõðàíåíî %d îáúåêòîâ â ôàéë %s", count, filename);
        SendClientMessage(playerid, COLOR_GREEN, msg);
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Îøèáêà ïðè ñîõðàíåíèè ôàéëà!");
    }
    return 1;
}

LoadObjectsFromFile(playerid)
{
    new filename[64];
    GetPlayerName(playerid, filename, sizeof(filename));
    format(filename, sizeof(filename), "Objects_%s.ini", filename);

    new File:file = fopen(filename, io_read);
    if(file)
    {
        DestroyPlayerObjects(playerid);

        new line[256];
        new modelid;
        new Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;
        new slot = 0;
        new count = 0;

        while(fread(file, line) && slot < MAX_PLAYER_OBJECTS)
        {
            new idx = 0;
            new numStr[16][32];
            new numCount = 0;
            new strPos = 0;

            while(line[idx] != '\0' && line[idx] != '\r' && line[idx] != '\n' && numCount < 16)
            {
                if(line[idx] == ',' || line[idx] == ' ')
                {
                    if(strPos > 0)
                    {
                        numStr[numCount][strPos] = '\0';
                        numCount++;
                        strPos = 0;
                    }
                }
                else
                {
                    numStr[numCount][strPos] = line[idx];
                    strPos++;
                }
                idx++;
            }

            if(strPos > 0 && numCount < 16)
            {
                numStr[numCount][strPos] = '\0';
                numCount++;
            }

            if(numCount >= 7)
            {
                modelid = floatround(floatstr(numStr[0]));
                x = floatstr(numStr[1]);
                y = floatstr(numStr[2]);
                z = floatstr(numStr[3]);
                rx = floatstr(numStr[4]);
                ry = floatstr(numStr[5]);
                rz = floatstr(numStr[6]);

                new objectId = CreateObject(modelid, x, y, z, rx, ry, rz);

                PlayerObjects[playerid][slot][objActive] = true;
                PlayerObjects[playerid][slot][ObjId] = objectId;
                PlayerObjects[playerid][slot][objX] = x;
                PlayerObjects[playerid][slot][objY] = y;
                PlayerObjects[playerid][slot][objZ] = z;
                PlayerObjects[playerid][slot][objRX] = rx;
                PlayerObjects[playerid][slot][objRY] = ry;
                PlayerObjects[playerid][slot][objRZ] = rz;
                PlayerObjects[playerid][slot][objModel] = modelid;

                CreateObjectLabel(playerid, slot);
                count++;
                slot++;
            }
        }
        fclose(file);

        new msg[128];
        format(msg, sizeof(msg), "Çàãðóæåíî %d îáúåêòîâ èç ôàéëà %s", count, filename);
        SendClientMessage(playerid, COLOR_GREEN, msg);

        if(count > 0)
        {
            CurrentObject[playerid] = 0;
            ShowObjectInfo(playerid, 0);
        }
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Ôàéë ñ îáúåêòàìè íå íàéäåí!");
    }
    return 1;
}

DestroyPlayerObjects(playerid)
{
    for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
    {
        if(PlayerObjects[playerid][i][objActive])
        {
            DestroyObject(PlayerObjects[playerid][i][ObjId]);
            DestroyObjectLabel(playerid, i);

            PlayerObjects[playerid][i][objActive] = false;
            PlayerObjects[playerid][i][ObjId] = -1;
        }
    }
    CurrentObject[playerid] = -1;
}

CreateObjectLabel(playerid, index)
{
    new label[128];
    new modelIndex = GetModelIndex(PlayerObjects[playerid][index][objModel]);
    new modelName[32];

    if(modelIndex != -1)
        format(modelName, 32, ObjectNames[modelIndex]);
    else
        format(modelName, 32, "Unknown");

    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    format(label, sizeof(label),
        "Îáúåêò #%d\nÂëàäåëåö: %s\nÌîäåëü: %d (%s)",
        index + 1, playerName,
        PlayerObjects[playerid][index][objModel],
        modelName
    );

    ObjectLabel[playerid][index] = Create3DTextLabel(
        label,
        0xFFFFFFFF,
        PlayerObjects[playerid][index][objX],
        PlayerObjects[playerid][index][objY],
        PlayerObjects[playerid][index][objZ] + 1.0,
        20.0,
        0,
        1
    );
}

UpdateObjectLabel(playerid, index)
{
    DestroyObjectLabel(playerid, index);
    CreateObjectLabel(playerid, index);
}

DestroyObjectLabel(playerid, index)
{
    if(IsValid3DTextLabel(ObjectLabel[playerid][index]))
    {
        Delete3DTextLabel(ObjectLabel[playerid][index]);
        ObjectLabel[playerid][index] = Text3D:INVALID_3DTEXT_ID;
    }
}

ShowObjectInfo(playerid, index)
{
    new modelIndex = GetModelIndex(PlayerObjects[playerid][index][objModel]);
    new modelName[32];

    if(modelIndex != -1)
        format(modelName, 32, ObjectNames[modelIndex]);
    else
        format(modelName, 32, "Unknown");

    new msg[256];
    format(msg, sizeof(msg),
        "Âûáðàí îáúåêò #%d | Ìîäåëü: %d (%s) | Ïîçèöèÿ: %.2f, %.2f, %.2f | Ïîâîðîò: %.2f, %.2f, %.2f",
        index + 1,
        PlayerObjects[playerid][index][objModel],
        modelName,
        PlayerObjects[playerid][index][objX],
        PlayerObjects[playerid][index][objY],
        PlayerObjects[playerid][index][objZ],
        PlayerObjects[playerid][index][objRX],
        PlayerObjects[playerid][index][objRY],
        PlayerObjects[playerid][index][objRZ]
    );
    SendClientMessage(playerid, COLOR_GREEN, msg);
}
