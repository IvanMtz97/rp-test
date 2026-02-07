#include <a_samp>
#include <core>
#include <float>
#include <zcmd>
#include <sscanf2>
#include <a_mysql>
#include <streamer>

#define	SECONDS_TO_LOGIN 	30

#define MAX_TRUCKS 20
#define MAX_HOUSES 500

#define MYSQL_HOST "localhost"
#define MYSQL_USER "root"
#define MYSQL_PASS "Randomly97."
#define MYSQL_NAME "rp"

new g_MysqlRaceCheck[MAX_PLAYERS];

#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_SIGNED_OUT 0x9b9b9b
#define COLOR_SUCCESS 0x69ff61AA
#define COLOR_ERROR 0xff4d4fAA
#define COLOR_INFO 0x47a0ffAA
#define COLOR_PM 0xfff700AA

enum Jobs {
	JOB_TRUCKER,
};

enum {
	DIALOG_UNUSED,
	DIALOG_LOGIN,
	DIALOG_REGISTER,
};

enum TRUCK {
	vehicle,
	driver,
	bool:is_loaded,
	bool:did_deliver,
	deliver_dynamic_cp,
	deliver_static_cp,
	load_dynamic_cp,
	load_static_cp,
	final_dynamic_cp,
	final_static_cp,
	bool:in_route,
};

new Trucks[MAX_TRUCKS][TRUCK];

enum HOUSE {
	id,
	Float:x,
	Float:y,
	Float:z,
	price,
	name[45],
	description[255],
	owner,
	interior_id,
	Float:interior_x,
	Float:interior_y,
	Float:interior_z,
	virtual_world,
	bool: is_not_owned,
	owner_nick[MAX_PLAYER_NAME],
};
new Houses[MAX_HOUSES][HOUSE];

enum Minigame {
	NO_ZONE,
	WWZONE,
	RWZONE,
	AD,
	DUEL,
};

enum PLAYER {
	id,
	ip[17],
	nick[MAX_PLAYER_NAME],
	rank,
	password[65],
	salt[17],
	interior,
	Cache: Cache_ID,
	bool: is_logged_in,
	loggin_attempts,
	login_timer,
	v_timer,
	vehicle_id,
	skin,
	money,
	minigame[Minigame],

	dmg_given_td_timer,
	dmg_received_td_timer,
	Text: DMGGivenTD,
	Text: DMGReceivedTD,
	Float:dmg_given,
	Float:dmg_received,
	dmg_given_to,
	dmg_received_from,

	blocked_pms,
	blocked_goto,
	streak,
	
	Float:last_x,
	Float:last_y,
	Float:last_z,

	job_one[Jobs],
};
new Players[MAX_PLAYERS][PLAYER];

new MySQL: dbclient;

new Float:trucksSpawns[][MAX_TRUCKS] =
{
	{1133.9000000, 1896.7000000, 11.6000000, -89.8050000},
	{1091.4000000, 1889.6000000, 11.6000000, 179.4730000},
	{1134.0000000, 1904.1000000, 11.6000000, -90.2390000},
	{1134.0000000, 1920.3000000, 11.6000000, -89.7370000},
	{1082.6000000, 1889.7000000, 11.6000000, 179.4730000},
	{1133.9004000, 1911.5000000, 11.6000000, -89.7420000},
	{1134.2000000, 1926.3000000, 11.6000000, -89.7420000},
	{1134.2000000, 1934.7000000, 11.6000000, -89.7420000},
	{1107.1000000, 1935.0000000, 11.6000000, 90.2340000},
	{1106.9000000, 1926.1000000, 11.6000000, 90.2310000},
	{1106.7000000, 1920.3000000, 11.6000000, 90.2310000},
	{1106.9000000, 1911.4000000, 11.6000000, 90.2310000},
	{1107.1000000, 1904.0000000, 11.6000000, 90.2310000},
	{1107.2000000, 1896.6000000, 11.6000000, 90.2310000},
	{1091.4000000, 1916.8000000, 11.6000000, -0.4420000},
	{1082.7000000, 1916.8000000, 11.6000000, -0.4450000},
	{1076.6000000, 1916.6000000, 11.6000000, -0.4450000},
	{1067.9000000, 1916.7000000, 11.6000000, -0.4450000},
	{1060.4000000, 1916.8000000, 11.6000000, -0.4450000},
	{1053.0000000, 1916.8000000, 11.6000000, -0.4450000}
};

#pragma tabsize 0

main()
{
	print("\n----------------------------------");
	print("  Bare Script\n");
	print("----------------------------------\n");
}

public OnPlayerConnect(playerid)
{
	GameTextForPlayer(playerid,"~w~SA-MP: ~r~Bare Script",5000,5);

	static const empty_player[PLAYER];
	Players[playerid] = empty_player;
	GetPlayerName(playerid, Players[playerid][nick], MAX_PLAYER_NAME);
	GetPlayerIp(playerid, Players[playerid][ip], 16);
	new query[103];
	mysql_format(dbclient, query, sizeof query, "SELECT * FROM `users` WHERE `nick` = '%e' LIMIT 1", Players[playerid][nick]);
	print(query);
	mysql_tquery(dbclient, query, "OnCheckSessionLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);

	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
	// Trucks
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (vehicleid == Trucks[i][vehicle] && !ispassenger) {
			Trucks[i][driver] = playerid;
			break;
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid) {
	// Trucks
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (vehicleid == Trucks[i][vehicle] && Trucks[i][driver] == playerid) {
			// Trucks[i][driver] = -1;
			break;
		}
	}
	return 1;
}

public OnVehicleSpawn(vehicleid) {
	// Trucks
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (vehicleid == Trucks[i][vehicle] && Trucks[i][in_route]) {
			SetupTruck(trucksSpawns[i][0], trucksSpawns[i][1], trucksSpawns[i][2], trucksSpawns[i][3], i);
			break;
		}
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason) {
	if (Players[playerid][is_logged_in]) {

		// Trucks
		for(new i = 0; i < MAX_TRUCKS; i++) {
			if(Trucks[i][driver] == playerid) {
				FailTruckerRoute(playerid);
				break;
			}
		}

		new query[250];
		GetPlayerPos(playerid, Players[playerid][last_x], Players[playerid][last_y], Players[playerid][last_z]);
		mysql_format(dbclient, query, sizeof query, "UPDATE `users` SET `last_x` = %f, `last_y` = %f, `last_z` = %f WHERE `id` = '%d';", Players[playerid][last_x], Players[playerid][last_y], Players[playerid][last_z], Players[playerid][id]);
		mysql_tquery(dbclient, query);
	}

	return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid) {
	// Trucks
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (checkpointid == Trucks[i][load_dynamic_cp]) {
			StartTruckerDeliverActivity(playerid);
			break;
		}

		if (checkpointid == Trucks[i][deliver_dynamic_cp]) {
			StartTruckerFinishRouteActivity(playerid);
			break;
		}

		if (checkpointid == Trucks[i][final_dynamic_cp]) {
			FinishTruckerRoute(playerid);
			break;
		}
	}
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	new idx;
	new cmd[256];
	
	cmd = strtok(cmdtext, idx);

	if(strcmp(cmd, "/yadayada", true) == 0) {
    	return 1;
	}

	return 0;
}

public OnPlayerSpawn(playerid)
{
	// Trucks
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (Trucks[i][driver] == playerid) {
			FailTruckerRoute(playerid);
			break;
		}
	}

	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	// Trucks
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (Trucks[i][driver] == playerid) {
			FailTruckerRoute(playerid);
			break;
		}
	}
	return 1;
}

public OnVehicleDeath(vehicleid, killerid) {

	// Trucks
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (vehicleid == Trucks[i][vehicle]) {
			FailTruckerRoute(Trucks[i][driver]);
			break;
		}
	}
}

public OnGameModeInit()
{
	SetGameModeText("Bare Script");
	ShowPlayerMarkers(1);
	ShowNameTags(1);
	AllowAdminTeleport(1);

	new MySQLOpt: option_id = mysql_init_options();	
	mysql_set_option(option_id, AUTO_RECONNECT, true);
	dbclient = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_NAME, option_id);
	UsePlayerPedAnims();
	if (dbclient == MYSQL_INVALID_HANDLE || mysql_errno(dbclient) != 0) {
		new db_err_message[128];
		format(db_err_message, sizeof(db_err_message), "[DB] Error connecting to database: %i", mysql_errno(dbclient));
		print(db_err_message);
		SendRconCommand("exit");
	} else {
		print("[DB] Connected to database successfully");
		InitializeHouses();
		InitializeTrucks();
	}

	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
	switch(dialogid) {
		case DIALOG_UNUSED: return 1;

		case DIALOG_REGISTER: {
			if (!response) return Kick(playerid);

			if (strlen(inputtext) <= 5 || strlen(inputtext) > 20) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registro", "Tu contrasena debe cumplir lo siguiente:\n- Mas de 5 caracteres\n- Menor a 20 caracteres\nPorfavor ingresa la contrasena:", "Registrarme", "Cancelar");

			for (new i = 0; i < 16; i++) Players[playerid][salt][i] = random(94) + 33;
			SHA256_PassHash(inputtext, Players[playerid][salt], Players[playerid][password], 65);

			new query[500];
			mysql_format(dbclient, query, sizeof query, "INSERT INTO users (`nick`, `password`, `salt`, `rank`, `is_banned`, `ip`, `is_logged_in`, `interior`) VALUES ('%e', '%e', '%e', 1, 0, '%e', 1, 0);", Players[playerid][nick], Players[playerid][password], Players[playerid][salt], Players[playerid][ip]);
			print(query);
			mysql_tquery(dbclient, query, "OnPlayerRegister", "d", playerid);
		}

		case DIALOG_LOGIN: {
			if (!response) return Kick(playerid);

			new hashed_pass[65];
			SHA256_PassHash(inputtext, Players[playerid][salt], hashed_pass, 65);

			if (strcmp(hashed_pass, Players[playerid][password]) == 0) {
				SetPlayerColor(playerid, COLOR_WHITE);
				SendClientMessage(playerid, COLOR_SUCCESS, "Has ingresado exitosamente.");
				PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
				cache_set_active(Players[playerid][Cache_ID]);
				cache_delete(Players[playerid][Cache_ID]);

				KillTimer(Players[playerid][login_timer]);
				Players[playerid][login_timer] = 0;
				Players[playerid][is_logged_in] = true;
				Players[playerid][blocked_pms] = 0;
				Players[playerid][blocked_goto] = 0;

				if (Players[playerid][last_x] != 0.0 && Players[playerid][last_y] != 0.0 && Players[playerid][last_z] != 0.0) {
					SetSpawnInfo(playerid, NO_TEAM, 0, Players[playerid][last_x], Players[playerid][last_y], Players[playerid][last_z], 0.0, 0, 0, 0, 0, 0, 0);
				} else {
					SetSpawnInfo(playerid, NO_TEAM, 0, 1958.3783, 1343.1572, 15.3746, 0.0, 0, 0, 0, 0, 0, 0);
				}
				SetTimerEx("DelayedSpawn", 1000, false, "d", playerid);
				GivePlayerMoney(playerid, Players[playerid][money]);
			} else {
				Players[playerid][loggin_attempts]++;

				if (Players[playerid][loggin_attempts] >= 3) {
					SendClientMessage(playerid, COLOR_ERROR, "Has introducido la contrasena mal repetidas veces (3).");
					DelayedKick(playerid);
				} else {
					ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Contrasena incorrecta!\nIngresa la contrasena correcta:", "Login", "Abort");
				}
			}

		}
	}

	return 1;
}

strtok(const string[], &index)
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}

CMD:givemoney(playerid, params[]) {
  new playerMoney, targetid, ammount, playerName[MAX_PLAYER_NAME], targetPlayerName[MAX_PLAYER_NAME];
  playerMoney = GetPlayerMoney(playerid);
  if (playerMoney < ammount) {
    SendClientMessage(playerid, -1, "You don't have enough money");
    return 1;
  }
  GetPlayerName(playerid, playerName, sizeof(playerName));
  GetPlayerName(targetid, targetPlayerName, sizeof(targetPlayerName));
  if(sscanf(params, "ui", targetid, ammount)) {
    SendClientMessage(playerid, -1, "Usage: /givemoney [playerid] [ammount]");
    return 1;
  }
  if(targetid == playerid) {
    SendClientMessage(playerid, -1, "You can't give money to yourself");
    return 1;
  }
  if(!IsPlayerConnected(targetid)) {
    SendClientMessage(playerid, -1, "Player not found");
    return 1;
  }

  if(ammount <= 0) {
    SendClientMessage(playerid, -1, "Ammount must be greater than 0");
    return 1;
  }

  GivePlayerMoney(targetid, ammount);
  new msg[128];
  format(msg, sizeof(msg), "$%i given to player %s", ammount, targetPlayerName);
  SendClientMessage(playerid, -1, msg);
  format(msg, sizeof(msg), "$%i given to you by %s", ammount, playerName);
  SendClientMessage(targetid, -1, msg);
  PlayerPlaySound(targetid, 1054, 0.0, 0.0, 0.0);
  return 1;
}

CMD:enter(playerid, params[]) {
	new Float:distance;
	for (new i = 0; i < MAX_HOUSES; i++) {
		distance = GetPlayerDistanceFromPoint(playerid, Houses[i][x], Houses[i][y], Houses[i][z]);
		if (distance <= 3.0) {
			printf("Validating %d owner vs playerid %d == %d", Houses[i][is_not_owned], Houses[i][owner], playerid);
			if (!Houses[i][is_not_owned] && Houses[i][owner] == Players[playerid][id]) {
				SendClientMessage(playerid, COLOR_SUCCESS, "Entering house");	
			} else {
				SendClientMessage(playerid, -1, "You are not the owner of this house");
			}
		}
	}
	return 1;
}

CMD:camtp(playerid, params[]) {
	SetPlayerPos(playerid, 1105.11804, 1877.649658, 10.820312);
	GivePlayerWeapon(playerid, 35, 9999);
	return 1;
}

CMD:startjob(playerid, params[]) {
	new jobparams[50];
	if(sscanf(params, "s", jobparams)) {
		SendClientMessage(playerid, -1, "Usage: /startjob [job]");
		return 1;
	}
	if(strcmp(jobparams, "trucker", true) == 0) {
		Players[playerid][job_one] = JOB_TRUCKER;
		SendClientMessage(playerid, COLOR_SUCCESS, "You started the job Trucker");
		return 1;
	}
	return 1;
}

CMD:truck(playerid, params[]) {
	new action[50];

	if (sscanf(params, "s[50]", action)) {
		SendClientMessage(playerid, -1, "Usage: /truck cancel|load");
		return 1;
	}

	if (Players[playerid][job_one] != JOB_TRUCKER) {
		SendClientMessage(playerid, -1, "You are not a trucker");
		return 1;
	}

	if (strcmp(action, "cancel", true) == 0) {
		for (new i = 0; i < MAX_TRUCKS; i++) {
			if (Trucks[i][driver] == playerid) {
				if (Trucks[i][in_route]) {
					FailTruckerRoute(playerid);
				} else {
					SendClientMessage(playerid, -1, "You are not in a route");
				}
				break;
			}
		}
		return 1;
	}

	if (strcmp(action, "load", true) == 0) {
		for (new i = 0; i < MAX_TRUCKS; i++) {
			if (Trucks[i][driver] == playerid) {
				if (!Trucks[i][in_route]) {
					if (!Trucks[i][is_loaded]) {
						if (!Trucks[i][did_deliver]) {
							if (Trucks[i][load_dynamic_cp] == -1) {
								StartTruckerLoadActivity(playerid);
							} else {
								SendClientMessage(playerid, -1, "Load is already waiting for you");
							}
						} else {
							SendClientMessage(playerid, -1, "You must get back to the warehouse");
						}
					} else {
						SendClientMessage(playerid, -1, "You already have a load");
					}
				} else {
					SendClientMessage(playerid, -1, "You are already in a route");
				}
				return 1;
			}
		}

		SendClientMessage(playerid, -1, "You don't have a truck");
		return 1;
	}

	return 1;
}

forward InitializeHouses();
public InitializeHouses() {
	new query[500];
	mysql_format(dbclient, query, sizeof query, "SELECT u.nick as owner_nick, h.id, h.x, h.y, h.z, h.price, h.name, h.description, h.owner, h.interior_id, h.interior_x, h.interior_y, h.interior_z, h.virtual_world FROM houses h LEFT JOIN users u ON h.owner = u.id;");
	print(query);
	mysql_tquery(dbclient, query, "OnHousesLoaded", "");
}

forward OnHousesLoaded();
public OnHousesLoaded() {
	if(cache_num_rows() > 0) {
		new houselabel[255];
		for(new i = 0; i < cache_num_rows(); i++) {
			cache_get_value_int(i, "id", Houses[i][id]);
			cache_get_value_float(i, "x", Houses[i][x]);
			cache_get_value_float(i, "y", Houses[i][y]);
			cache_get_value_float(i, "z", Houses[i][z]);
			cache_get_value_int(i, "price", Houses[i][price]);
			cache_get_value(i, "name", Houses[i][name]);
			cache_get_value(i, "description", Houses[i][description]);
			cache_get_value_int(i, "owner", Houses[i][owner]);
			cache_get_value_int(i, "interior_id", Houses[i][interior_id]);
			cache_get_value_float(i, "interior_x", Houses[i][interior_x]);
			cache_get_value_float(i, "interior_y", Houses[i][interior_y]);
			cache_get_value_float(i, "interior_z", Houses[i][interior_z]);
			cache_get_value_int(i, "virtual_world", Houses[i][virtual_world]);
			cache_is_value_name_null(i, "owner", Houses[i][is_not_owned]);

			if (!Houses[i][is_not_owned]) {
				cache_get_value(i, "owner_nick", Houses[i][owner_nick]);
				format(houselabel, sizeof houselabel, "%s\n%s\nOwner: {FFFFFF}%s", Houses[i][name], Houses[i][description], Houses[i][owner_nick]);
			} else {
				format(houselabel, sizeof houselabel, "%s\n%s\nFor Sale", Houses[i][name], Houses[i][description]);
			}

			Create3DTextLabel(houselabel, COLOR_SUCCESS, Houses[i][x], Houses[i][y], Houses[i][z], 20.0, 0, 0);
		}
	}
	printf("%d houses loaded", cache_num_rows());
}

forward OnCheckSessionLoaded(playerid, race_check);
public OnCheckSessionLoaded(playerid, race_check) {
	print("OnCheckSessionLoaded");
	if (race_check != g_MysqlRaceCheck[playerid]) return Kick(playerid);

	new message[200];
	if(cache_num_rows() > 0) {
		cache_get_value_int(0, "id", Players[playerid][id]);
		cache_get_value(0, "password", Players[playerid][password], 65);
		cache_get_value(0, "salt", Players[playerid][salt], 17);
		cache_get_value_int(0, "skin", Players[playerid][skin]);
		cache_get_value_int(0, "money", Players[playerid][money]);
		cache_get_value_float(0, "last_x", Players[playerid][last_x]);
		cache_get_value_float(0, "last_y", Players[playerid][last_y]);
		cache_get_value_float(0, "last_z", Players[playerid][last_z]);
		Players[playerid][Cache_ID] = cache_save();
		format(message, sizeof message, "Esta cuenta (%s) esta registrada. Ingresa la contrasena:", Players[playerid][nick]);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", message, "Login", "Cancelar");
		Players[playerid][login_timer] = SetTimerEx("OnLoginTimeout", SECONDS_TO_LOGIN * 1000, false, "d", playerid);
	} else {
		format(message, sizeof message, "Bienvenido %s, ingresa tu contrasena para registrarte:", Players[playerid][nick]);
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registro", message, "Registrarme", "Cancelar");
	}
	return 1;
}

forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	Players[playerid][id] = cache_insert_id();

	SendClientMessage(playerid, COLOR_SUCCESS, "Registrado exitosamente!");
	PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);

	Players[playerid][is_logged_in] = true;
	SetSpawnInfo(playerid, NO_TEAM, 0, 1958.3783, 1343.1572, 15.3746, 0.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
	SetPlayerColor(playerid, COLOR_WHITE);
	return 1;
}

DelayedKick(playerid, time = 200)
{
	SetTimerEx("_KickPlayerDelayed", time, false, "d", playerid);
	return 1;
}

forward InitializeTrucks();
public InitializeTrucks() {
	for (new i = 0; i < MAX_TRUCKS; i++) {
		SetupTruck(trucksSpawns[i][0], trucksSpawns[i][1], trucksSpawns[i][2], trucksSpawns[i][3], i);
	}
}

forward SetupTruck(Float: truck_x, Float: truck_y, Float: truck_z, Float: truck_angle, index);
public SetupTruck(Float: truck_x, Float: truck_y, Float: truck_z, Float: truck_angle, index) {
	Trucks[index][vehicle] = CreateVehicle(578, truck_x, truck_y, truck_z, truck_angle, 245, 245, 180);
	Trucks[index][driver] = -1;
	Trucks[index][is_loaded] = false;
	Trucks[index][did_deliver] = false;
	Trucks[index][load_dynamic_cp] = -1;
	Trucks[index][load_static_cp] = -1;
	Trucks[index][deliver_dynamic_cp] = -1;
	Trucks[index][deliver_static_cp] = -1;
	Trucks[index][final_dynamic_cp] = -1;
	Trucks[index][final_static_cp] = -1;
	Trucks[index][in_route] = false;
}

forward DelayedSpawn(playerid);
public DelayedSpawn(playerid) {
	SpawnPlayer(playerid);
}

forward StartTruckerLoadActivity(playerid);
public StartTruckerLoadActivity(playerid) {
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (Trucks[i][driver] == playerid) {
			Trucks[i][in_route] = true;
			GameTextForPlayer(playerid, "~y~Get your load at the warehouse", 3000, 4);
			Trucks[i][load_dynamic_cp] = CreateDynamicCP(978.0, 2096.8, 10.8, 10, 0, 0, playerid, 100.0);
			Trucks[i][load_static_cp] = SetPlayerCheckpoint(playerid, 978.0, 2096.8, 10.8, 10.0);
			break;
		}
	}
}

forward StartTruckerDeliverActivity(playerid);
public StartTruckerDeliverActivity(playerid) {
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (Trucks[i][driver] == playerid) {
			Trucks[i][is_loaded] = true;
			GameTextForPlayer(playerid, "~y~Deliver your load at the point", 3000, 4);
			DestroyDynamicCP(Trucks[i][load_dynamic_cp]);
			DisablePlayerCheckpoint(playerid);
			Trucks[i][load_dynamic_cp] = -1;
			Trucks[i][load_static_cp] = -1;
			Trucks[i][deliver_dynamic_cp] = CreateDynamicCP(-60.5, -1135.8, 1.1, 10, 0, 0, playerid, 100.0);
			Trucks[i][deliver_static_cp] = SetPlayerCheckpoint(playerid, -60.5, -1135.8, 1.1, 10.0);
			break;
		}
	}
}

forward StartTruckerFinishRouteActivity(playerid);
public StartTruckerFinishRouteActivity(playerid) {
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (Trucks[i][driver] == playerid) {
			Trucks[i][did_deliver] = true;
			GameTextForPlayer(playerid, "~y~Go back to the warehouse to finish your route", 3000, 4);
			DestroyDynamicCP(Trucks[i][deliver_dynamic_cp]);
			DisablePlayerCheckpoint(playerid);
			Trucks[i][deliver_dynamic_cp] = -1;
			Trucks[i][deliver_static_cp] = -1;
			Trucks[i][final_dynamic_cp] = CreateDynamicCP(1069.812500, 1859.337280, 10.820312, 10, 0, 0, playerid, 100.0);
			Trucks[i][final_static_cp] = SetPlayerCheckpoint(playerid, 1069.812500, 1859.337280, 10.820312, 10);
			break;
		}
	}
}

forward FinishTruckerRoute(playerid);
public FinishTruckerRoute(playerid) {
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (Trucks[i][driver] == playerid) {
			Trucks[i][driver] = -1;
			Trucks[i][is_loaded] = false;
			Trucks[i][did_deliver] = false;
			Trucks[i][in_route] = false;
			Trucks[i][load_dynamic_cp] = -1;
			Trucks[i][load_static_cp] = -1;
			Trucks[i][deliver_dynamic_cp] = -1;
			Trucks[i][deliver_static_cp] = -1;
			Trucks[i][final_dynamic_cp] = -1;
			Trucks[i][final_static_cp] = -1;
			DestroyDynamicCP(Trucks[i][final_dynamic_cp]);
			DisablePlayerCheckpoint(playerid);
			GameTextForPlayer(playerid, "~g~You have finished your route", 3000, 4);
			RemovePlayerFromVehicle(playerid);
			GivePlayerMoney(playerid, 1000);
			SetVehicleToRespawn(Trucks[i][vehicle]);
			break;
		}
	}
}

forward FailTruckerRoute(playerid);
public FailTruckerRoute(playerid) {
	for (new i = 0; i < MAX_TRUCKS; i++) {
		if (Trucks[i][driver] == playerid) {
			Trucks[i][driver] = -1;
			Trucks[i][is_loaded] = false;
			Trucks[i][did_deliver] = false;
			Trucks[i][in_route] = false;
			Trucks[i][load_dynamic_cp] = -1;
			Trucks[i][load_static_cp] = -1;
			Trucks[i][deliver_dynamic_cp] = -1;
			Trucks[i][deliver_static_cp] = -1;
			Trucks[i][final_dynamic_cp] = -1;
			Trucks[i][final_static_cp] = -1;
			DestroyDynamicCP(Trucks[i][final_dynamic_cp]);
			DisablePlayerCheckpoint(playerid);
			GameTextForPlayer(playerid, "~r~You have failed your route", 3000, 4);
			RemovePlayerFromVehicle(playerid);
			SetVehicleToRespawn(Trucks[i][vehicle]);
			break;
		}
	}
}