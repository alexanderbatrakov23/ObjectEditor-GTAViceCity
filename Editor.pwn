#include <a_vicemp>
#include <keysdefine>
#include <custommenu>

#define MAX_PLAYER_OBJECTS 50// Максимальное количество объектов на игрока

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
new MenuState[MAX_PLAYERS]; // 0 - нет меню, 1 - главное меню, 2 - меню объектов, 3 - меню списка, 4 - подтверждение, 5 - скорость
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
    "Барьер ворот бара", "Бокс барьера бара", "Поворотный барьер", "Электрические ворота", "Маленький забор",
    "Ворота метро", "Вход в туннель", "Дорожный барьер", "Высокий забор", "Ворота Columbian",
    "Дверь башни", "Правая сторона метро", "Левая сторона метро", "Ворота аэропорта",
    "Спиральный барьер", "Барьер 316", "Барьер 317", "Барьер 318", "Барьер 319",
    "Барьер 320", "Барьер 321", "Барьер 322", "Барьер 323", "Барьер 324",
    "Маленький камень", "Стиральная машина", "Шина", "Плита", "Торговый автомат",
    "Кейс", "Пожарный гидрант", "Деньги", "Мина", "Боллард",
    "Освещаемый боллард", "Телефонная будка", "Бочка тип 1", "Бочка тип 2", "Бочка тип 3",
    "Бочка тип 4", "Бочка тип 5", "Бочка тип 6", "Паллета", "Прибрежный фонарь",
    "Картонная коробка", "Бочка тип 7", "Фонарный столб №3", "Мусорная корзина", "Мусорный бак",
    "Дорожный барьер ремонта", "Знак автобуса", "Фонарь тип 1", "Фонарь тип 2", "Знак парковки",
    "Телефонный знак", "Урна", "Контейнер", "Барьер тип 2", "Конус",
    "Иконка здоровья", "Иконка брони", "Иконка адреналина", "Иконка взятки", "Буй",
    "Бензоколонка", "Новая рампа", "Линия", "Камень тип 1", "Камень тип 2",
    "Иконка бонуса", "Иконка бонуса 2", "Фальшивая мишень", "Столб", "Перекладина",
    "Взрывающаяся бочка", "Разбитое стекло", "Иконка камеры", "Иконка убийств", "Телеграфный столб",
    "Шезлонг", "Каменная скамейка", "Майамский телефон", "Майамский гидрант", "Остановка Майами",
    "Почтовый ящик", "Рекламный щит 1", "Рекламный щит 2", "Рекламный щит 3", "Дорожный знак 1",
    "Мусорная корзина", "Дорожный знак 2", "Дорожный знак 3", "Черный мешок", "Черный мешок 2",
    "Рекламный щит 4", "Рекламный щит 5", "Рекламный щит 6", "Парковочный счетчик", "Парковочный счетчик 2",
    "Ящик с оружием", "Иконка недвижимости", "Иконка одежды", "Иконка навыков", "Иконка казино",
    "Посылка", "Пикап сохранения", "Почтовый ящик 2", "Газетный киоск", "Парковая скамейка",
    "Газетный автомат", "Парковый стол", "Фонарный столб большой", "Садовая скамейка", "Барьер Майами",
    "Киоск 1", "Киоск 2", "Киоск 3", "Киоск 4", "Киоск 5",
    "Фонарный столб малый", "Двойной фонарь", "Светофор", "Дорожный знак Майами", "Фонарь Майами",
    "Прожектор", "Посылка Крейга", "Пикап музыки", "Пальма 1", "Пальма 2",
    "Пальма 3", "Пальма 4", "Пальма 5", "Пальма 6", "Пальма 7",
    "Пальма 8", "Пальма 9", "Пальма 10", "Пальма 11", "Пальма 12",
    "Пальма 13", "Пальма 14", "Пальма 15", "Пальма 16", "Пальма 17",
    "Пальма 18", "Пальма 19", "Пальма 20", "Растение в горшке", "Куст",
    "Плющ 1", "Плющ 2", "Плющ 3", "Плющ 4", "Плющ 5",
    "Плющ 6", "Плющ 7", "Плющ 8", "Плющ 9", "Плющ 10",
    "Плющ 11", "Плющ 12", "Плющ 13", "Плющ 14", "Плющ 15",
    "Плющ 16", "Плющ 17", "Пальма большая", "Медиа-сцена", "Мусорный бак",
    "Наркотики красные", "Наркотики зеленые", "Наркотики синие", "Наркотики желтые", "Наркотики фиолетовые",
    "Наркотики розовые", "Ключ-карта", "Баннер Love Fist", "Коробка пиццы", "Мишень 1",
    "Мишень 2", "Мишень 3", "Мишень 4", "Мишень 5", "Мишень 6",
    "Мишень 7", "Мишень 8", "Мишень 9", "Мишень 10", "Шипы полиции",
    "Стул", "Стол", "Спутниковая тарелка", "Спутник малый", "Контроллер",
    "Пляжный мяч", "Рыба 1", "Рыба 2", "Рыба 3", "Рыба 4",
    "Рыба 5", "Рыба 6", "Рыба 7", "Рыба 8", "Рыба 9",
    "Медуза", "Акула", "Черепаха", "Дельфин", "Песчаный замок",
    "Песчаный замок малый", "Подводная лодка", "Кондиционер 1", "Кондиционер 2", "Вентиляция",
    "Камера", "Антенна", "Труба", "Коробка", "Ящик",
    "Генератор", "Радиатор", "Трамплин водный", "Трамплин наземный", "Трамплин 2",
    "Двойной кондиционер", "Радио-бомба", "Шезлонг пляжный", "Полотенце", "Зонтик",
    "Сетка", "Разбитое окно", "Канистра", "Окно полиции", "Забор Гаити",
    "Забор Гаити 2", "Динамит", "Трамплин 3", "Эскалатор", "Рампа",
    "Блок CI", "Бутылка", "Бокал", "Пепельница", "Барная стойка",
    "Стул барный", "Кружка", "Вращающееся кресло", "Газовая граната", "Дорожный знак",
    "Здание Wash 1", "Здание Wash 2", "Здание Wash 3", "Здание Wash 4", "Здание Wash 5",
    "Здание Wash 6", "Здание Wash 7", "Гроб", "Стул малый", "LOD самолета",
    "Learjet", "Радар", "Jumbo"
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
        SendClientMessage(playerid, COLOR_RED, "Нет выбранного объекта для копирования!");
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
        SendClientMessage(playerid, COLOR_RED, "Достигнут лимит объектов (50)! Нельзя создать копию.");
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
    format(msg, sizeof(msg), "Создана копия объекта #%d -> #%d (смещена на +%.1f +%.1f)",
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
                SendClientMessage(playerid, COLOR_YELLOW, "Это последняя страница!");
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
                SendClientMessage(playerid, COLOR_YELLOW, "Это первая страница!");
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
                SendClientMessage(playerid, COLOR_YELLOW, "Сначала выберите объект (1/2 или меню)");
                ShowObjectListMenu(playerid);
            }
            else
                SendClientMessage(playerid, COLOR_RED, "Сначала создайте объект!");
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

            SendClientMessage(playerid, COLOR_RED, "========== РЕЖИМ РЕДАКТИРОВАНИЯ ВЫКЛЮЧЕН ==========");
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
            format(msg, sizeof(msg), "Поворот: %.1f | Наклон: %.1f", NoclipRot[playerid][0], NoclipPitch[playerid]);
            SendClientMessage(playerid, COLOR_WHITE, msg);
        }
        else if(key == WK_KEY_NUM_9)
        {
            NoclipRot[playerid][0] -= 5.0;
            UpdateNoclipCamera(playerid);

            new msg[128];
            format(msg, sizeof(msg), "Поворот: %.1f | Наклон: %.1f", NoclipRot[playerid][0], NoclipPitch[playerid]);
            SendClientMessage(playerid, COLOR_WHITE, msg);
        }
        else if(key == WK_KEY_NUM_1)
        {
            if(NoclipPitch[playerid] < 85.0)
            {
                NoclipPitch[playerid] += 2.0;
                UpdateNoclipCamera(playerid);

                new msg[128];
                format(msg, sizeof(msg), "Наклон вверх: %.1f градусов", NoclipPitch[playerid]);
                SendClientMessage(playerid, COLOR_WHITE, msg);
            }
            else
            {
                SendClientMessage(playerid, COLOR_RED, "Достигнут максимальный наклон вверх (85°)");
            }
        }
        else if(key == WK_KEY_NUM_3)
        {
            if(NoclipPitch[playerid] > -85.0)
            {
                NoclipPitch[playerid] -= 2.0;
                UpdateNoclipCamera(playerid);

                new msg[128];
                format(msg, sizeof(msg), "Наклон вниз: %.1f градусов", NoclipPitch[playerid]);
                SendClientMessage(playerid, COLOR_WHITE, msg);
            }
            else
            {
                SendClientMessage(playerid, COLOR_RED, "Достигнут максимальный наклон вниз (-85°)");
            }
        }
        else if(key == WK_KEY_NUM_5)
        {
            NoclipPitch[playerid] = 0.0;
            UpdateNoclipCamera(playerid);
            SendClientMessage(playerid, COLOR_WHITE, "Наклон сброшен");
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
        format(msg, sizeof(msg), "Позиция: %.2f, %.2f, %.2f | Поворот: RX: %.2f RY: %.2f RZ: %.2f",
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

    SendClientMessage(playerid, 0x00FF00FF, "========== NOCLIP РЕЖИМ ВКЛЮЧЕН ==========");
    SendClientMessage(playerid, 0xFFFFFFFF, "Num 8/Num 2 - вперед/назад | Num 4/Num 6 - влево/вправо");
    SendClientMessage(playerid, 0xFFFFFFFF, "Num 7/Num 9 - поворот | Num 1/Num 3 - наклон вверх/вниз");
    SendClientMessage(playerid, 0xFFFFFFFF, "Num + - вверх | Num - - вниз | Num 5 - сброс наклона");
    SendClientMessage(playerid, 0xFFFF00FF, "U - выключить noclip");

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

    SendClientMessage(playerid, 0xFF0000FF, "========== NOCLIP РЕЖИМ ВЫКЛЮЧЕН ==========");

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
    format(title, sizeof(title), "Настройка скорости (Текущая: M-%.2f R-%.1f)",
        PlayerMoveSpeed[playerid], PlayerRotateSpeed[playerid]);

    SetPlayerStringCustomMenu(playerid, 0, title);
    SetPlayerStringCustomMenu(playerid, 1, "Перемещение: Медленно (0.1)");
    SetPlayerStringCustomMenu(playerid, 2, "Перемещение: Нормально (0.25)");
    SetPlayerStringCustomMenu(playerid, 3, "Перемещение: Быстро (0.5)");
    SetPlayerStringCustomMenu(playerid, 4, "Вращение: Медленно (1.0)");
    SetPlayerStringCustomMenu(playerid, 5, "Вращение: Нормально (2.0)");
    SetPlayerStringCustomMenu(playerid, 6, "Вращение: Быстро (4.0)");

    MenuState[playerid] = 5;
    ShowCustomMenuForPlayer(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Выберите скорость стрелками, Enter - выбор");
    return 1;
}
ShowEditModeMenu(playerid)
{
    CreatePlayerCustomMenu(playerid, 3);

    SetPlayerStringCustomMenu(playerid, 0, "Выберите режим редактирования");
    SetPlayerStringCustomMenu(playerid, 1, "Перемещать объект");
    SetPlayerStringCustomMenu(playerid, 2, "Вращать объект");
    SetPlayerStringCustomMenu(playerid, 3, "Отмена");

    EditSubMode[playerid] = EDIT_MODE_MENU;
    ShowCustomMenuForPlayer(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Используйте стрелки для навигации, Enter - выбор, Пробел - выход");
    return 1;
}
ShowMainMenu(playerid)
{
    CreatePlayerCustomMenu(playerid, 9);

    SetPlayerStringCustomMenu(playerid, 0, "Меню управления объектами");
    SetPlayerStringCustomMenu(playerid, 1, "Создать объект");
    SetPlayerStringCustomMenu(playerid, 2, "Выбрать объект");
    SetPlayerStringCustomMenu(playerid, 3, "Удалить объект");
    SetPlayerStringCustomMenu(playerid, 4, "Режим редактирования");
    SetPlayerStringCustomMenu(playerid, 5, "Сохранить в файл");
    SetPlayerStringCustomMenu(playerid, 6, "Загрузить из файла");
    SetPlayerStringCustomMenu(playerid, 7, "Список объектов");
    SetPlayerStringCustomMenu(playerid, 8, "Сохранить в лог (C)");
    SetPlayerStringCustomMenu(playerid, 9, "Дублировать объект(X)");

    MenuState[playerid] = 1;
    ShowCustomMenuForPlayer(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Используйте стрелки для навигации, Enter - выбор, Пробел - выход");
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
                SendClientMessage(playerid, COLOR_RED, "У вас нет созданных объектов!");
        }
        else if(id == 3)
        {
            if(CurrentObject[playerid] != -1)
                SetTimerEx("ShowDeleteConfirmationEx", 100, 0, "d", playerid);
            else
                SendClientMessage(playerid, COLOR_RED, "Нет выбранного объекта!");
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
            SendClientMessage(playerid, COLOR_GREEN, "========== РЕЖИМ ПЕРЕМЕЩЕНИЯ ==========");
            SendClientMessage(playerid, COLOR_WHITE, "W/S - вперед/назад | A/D - влево/вправо");
            SendClientMessage(playerid, COLOR_WHITE, "Shift+W/S - вверх/вниз");
            SendClientMessage(playerid, COLOR_YELLOW, "H - выключить режим редактирования");
            SendClientMessage(playerid, COLOR_YELLOW, "5 - заморозка персонажа");
            SendClientMessage(playerid, COLOR_YELLOW, "6 - разморозка персонажа");
        }
        else if(id == 2)
        {
            EditSubMode[playerid] = EDIT_MODE_ROTATE;
            SendClientMessage(playerid, COLOR_GREEN, "========== РЕЖИМ ВРАЩЕНИЯ ==========");
            SendClientMessage(playerid, COLOR_WHITE, "Q/E - вращение по горизонтали (RZ)");
            SendClientMessage(playerid, COLOR_WHITE, "Shift+Q/E - наклон (RX)");
            SendClientMessage(playerid, COLOR_WHITE, "A/D - вращение по вертикали (RY)");
            SendClientMessage(playerid, COLOR_YELLOW, "H - выключить режим редактирования");
            SendClientMessage(playerid, COLOR_YELLOW, "5 - заморозка персонажа");
            SendClientMessage(playerid, COLOR_YELLOW, "6 - разморозка персонажа");
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

            SendClientMessage(playerid, COLOR_RED, "Режим редактирования отменен");
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
            SendClientMessage(playerid, COLOR_RED, "Неверный выбор");
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
            SendClientMessage(playerid, COLOR_GREEN, "Объект выбран! Нажмите H для редактирования.");
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
            SendClientMessage(playerid, COLOR_YELLOW, "Удаление отменено");
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
                SendClientMessage(playerid, COLOR_GREEN, "Скорость перемещения: 0.1 (Медленно)");
            }
            case 2:
            {
                PlayerMoveSpeed[playerid] = 0.5;
                SendClientMessage(playerid, COLOR_GREEN, "Скорость перемещения: 0.25 (Нормально)");
            }
            case 3:
            {
                PlayerMoveSpeed[playerid] = 1.5;
                SendClientMessage(playerid, COLOR_GREEN, "Скорость перемещения: 0.5 (Быстро)");
            }
            case 4:
            {
                PlayerRotateSpeed[playerid] = 0.02;
                SendClientMessage(playerid, COLOR_GREEN, "Скорость вращения: 1.0 (Медленно)");
            }
            case 5:
            {
                PlayerRotateSpeed[playerid] = 1.0;
                SendClientMessage(playerid, COLOR_GREEN, "Скорость вращения: 2.0 (Нормально)");
            }
            case 6:
            {
                PlayerRotateSpeed[playerid] = 2.0;
                SendClientMessage(playerid, COLOR_GREEN, "Скорость вращения: 4.0 (Быстро)");
            }
        }

        new msg[128];
        format(msg, sizeof(msg), "Текущие настройки: Перемещение: %.2f, Вращение: %.1f",
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
    SendClientMessage(playerid, COLOR_WHITE, "Меню закрыто");
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
        SendClientMessage(playerid, COLOR_RED, "Нет объектов для отображения");
        return 0;
    }

    CreatePlayerCustomMenu(playerid, menuItems + 1);

    new title[64];
    new maxPages = (totalObjects + 6) / 7;
    format(title, sizeof(title), "Выберите объект (Стр. %d/%d)", ObjectMenuPage[playerid] + 1, maxPages);
    SetPlayerStringCustomMenu(playerid, 0, title);

    for(new i = 0; i < menuItems; i++)
    {
        SetPlayerStringCustomMenu(playerid, i + 1, ObjectNames[startIdx + i]);
    }

    MenuState[playerid] = 2;
    ShowCustomMenuForPlayer(playerid);

    SendClientMessage(playerid, COLOR_YELLOW, "Стрелки/3-4: листать страницы | Пробел/Backspace: выход");

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
        SendClientMessage(playerid, COLOR_RED, "У вас нет созданных объектов!");
        return 0;
    }

    new menuItems = (count > 7) ? 7 : count;

    CreatePlayerCustomMenu(playerid, menuItems + 1);

    SetPlayerStringCustomMenu(playerid, 0, "Ваши объекты");

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
        SendClientMessage(playerid, COLOR_YELLOW, "Показаны первые 7 объектов.");
    }

    MenuState[playerid] = 3;
    ShowCustomMenuForPlayer(playerid);
    return 1;
}

ShowDeleteConfirmation(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Нет выбранного объекта!");
        return 0;
    }
    CreatePlayerCustomMenu(playerid, 3);

    new confirmMsg[64];
    format(confirmMsg, 64, "Удалить объект #%d?", CurrentObject[playerid] + 1);
    SetPlayerStringCustomMenu(playerid, 0, confirmMsg);
    SetPlayerStringCustomMenu(playerid, 1, "Да");
    SetPlayerStringCustomMenu(playerid, 2, "Нет");

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
        SendClientMessage(playerid, COLOR_RED, "Вы достигли максимального количества объектов (50)!");
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

    format(msg, sizeof(msg), "Создан объект #%d [ID: %d] (%s)", freeSlot + 1, modelid, modelName);
    SendClientMessage(playerid, COLOR_GREEN, msg);

    if(!EditingMode[playerid])
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Используйте H для входа в режим редактирования");
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
        format(header, sizeof(header), "// Объекты игрока %s (ID: %d) - %d/%d/%d\r\n", playerName, playerid, day, month, year);
        fwrite(file, header);
        fwrite(file, "// Формат: CreateObject(modelid, x, y, z, rx, ry, rz);\r\n\r\n");

        for(new i = 0; i < MAX_PLAYER_OBJECTS; i++)
        {
            if(PlayerObjects[playerid][i][objActive])
            {
                format(line, sizeof(line),
                    "CreateObject(%d, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f); // Объект #%d\r\n",
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
        format(msg, sizeof(msg), "Сохранено %d объектов в файл: %s", count, logFile);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SendClientMessage(playerid, COLOR_ORANGE, "Файл сохранен в папку с сервером. Можете скопировать");
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Ошибка при создании файла лога!");
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
        SendClientMessage(playerid, COLOR_RED, "У вас нет объектов для выбора!");
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

    SendClientMessage(playerid, COLOR_RED, "Нет других объектов!");
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
        SendClientMessage(playerid, COLOR_RED, "У вас нет объектов для выбора!");
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

    SendClientMessage(playerid, COLOR_RED, "Нет других объектов!");
    return 0;
}

DeleteCurrentObject(playerid)
{
    if(CurrentObject[playerid] == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "Нет выбранного объекта!");
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

        SendClientMessage(playerid, COLOR_GREEN, "Объект удален!");

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
            SendClientMessage(playerid, COLOR_YELLOW, "Сначала выберите объект (1/2 или меню)");
            ShowObjectListMenu(playerid);
        }
        else
            SendClientMessage(playerid, COLOR_RED, "Сначала создайте объект!");
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

        SendClientMessage(playerid, COLOR_GREEN, "========== РЕЖИМ РЕДАКТИРОВАНИЯ ВКЛЮЧЕН ==========");
        SendClientMessage(playerid, COLOR_WHITE, "W/S - вперед/назад | A/D - влево/вправо");
        SendClientMessage(playerid, COLOR_WHITE, "Shift+W/S - вверх/вниз | Q/E - вращение | Shift+Q/E - наклон");
        SendClientMessage(playerid, COLOR_YELLOW, "H - выключить режим и разморозиться");

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

        SendClientMessage(playerid, COLOR_RED, "========== РЕЖИМ РЕДАКТИРОВАНИЯ ВЫКЛЮЧЕН ==========");
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
        format(msg, sizeof(msg), "Сохранено %d объектов в файл %s", count, filename);
        SendClientMessage(playerid, COLOR_GREEN, msg);
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Ошибка при сохранении файла!");
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
        format(msg, sizeof(msg), "Загружено %d объектов из файла %s", count, filename);
        SendClientMessage(playerid, COLOR_GREEN, msg);

        if(count > 0)
        {
            CurrentObject[playerid] = 0;
            ShowObjectInfo(playerid, 0);
        }
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Файл с объектами не найден!");
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
        "Объект #%d\nВладелец: %s\nМодель: %d (%s)",
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
        "Выбран объект #%d | Модель: %d (%s) | Позиция: %.2f, %.2f, %.2f | Поворот: %.2f, %.2f, %.2f",
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
