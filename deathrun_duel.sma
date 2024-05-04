#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <cromchat>

#define PLUGIN "Deathrun Duel"	
#define VERSION "1.0"
#define AUTHOR "MrShark45"

#pragma tabsize 0
#pragma semicolon 1

//disable knife regen task while duel is active
#define TASK_REGEN_ID 9321

#define TASK_DUEL_START_ID 6989
#define TASK_DUEL_PROGRESS_ID 1337

new szSound[] = {"duel/start.wav"};
new szCountSounds[3][] = {
	"fvox/one.wav",
	"fvox/two.wav",
	"fvox/three.wav"
};

new bool:duelStarted;
new gTerroId;
new gCtId;

new gCvarDuelTime;

new float:duelTime;

new g_msgsync;

new duelRemainingTime;
new duelStartTime;

new g_fwDuelWon;

public plugin_init(){
	register_plugin(PLUGIN,VERSION,AUTHOR);

	register_clcmd("say /duel", "Menu");

	register_clcmd("drop", "BlockDrop");

	RegisterHam(Ham_Player_Jump, "player", "BlockJump");

	register_clcmd("say /shop", "BlockShop");

	RegisterHam( Ham_Touch, "armoury_entity", "BlockPickup" ); 

	RegisterHam( Ham_Touch, "weaponbox", "BlockPickup" );

	RegisterHam(Ham_Killed, "player", "player_killed");

	RegisterHam(Ham_TakeDamage, "player", "player_take_damage");

	gCvarDuelTime = register_cvar("duel_time", "60.0");

	register_event("HLTV", "Event_RoundStart", "a", "1=0", "2=0");

	register_logevent("Event_RoundEnd", 2, "1=Round_End");

	register_event("CurWeapon","Event_CurWeapon","b");

	g_fwDuelWon = CreateMultiForward( "player_won_duel", ET_IGNORE, FP_CELL );

	duelTime = float:get_pcvar_float(gCvarDuelTime);

	g_msgsync = CreateHudSyncObj();

	CC_SetPrefix("&x04[DR]");
}

public plugin_cfg() {
	register_dictionary("deathrun_duel.txt");
}

public plugin_precache(){
	precache_sound(szSound);
	for(new i;i<3;i++)
		precache_sound(szCountSounds[i]);
}

public Event_RoundStart(){
	duelStarted = false;
	duelRemainingTime = get_pcvar_num(gCvarDuelTime);
	duelStartTime = 3;
}

public Event_RoundEnd(){
	remove_task(TASK_DUEL_PROGRESS_ID);
	remove_task(TASK_DUEL_START_ID);
	fm_set_rendering(gCtId, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 20);
	fm_set_rendering(gTerroId, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 20);
}

public Event_CurWeapon(id){
	new currWeapon = read_data(2);
	new currAmmo = read_data(3);
	new ammoCount;

	if(duelStarted){
		if(currWeapon == CSW_KNIFE)
			return PLUGIN_CONTINUE;
		if(currAmmo > 3){
			switch(currWeapon){
				case CSW_DEAGLE:	ammoCount = 1;
				case CSW_MP5NAVY:	ammoCount = 3;
				case CSW_FAMAS:		ammoCount = 3;
				case CSW_P90:		ammoCount = 3;
				case CSW_AUG:		ammoCount = 3;
				case CSW_AK47:		ammoCount = 3;
				case CSW_M4A1:		ammoCount = 3;
				case CSW_M3:		ammoCount = 3;
				case CSW_HEGRENADE:	ammoCount = 1;
				case CSW_SCOUT:		ammoCount = 255;
				case CSW_AWP:		ammoCount = 255;
			}
			SetAmmo(id, currWeapon, ammoCount);
		}
	}
	return PLUGIN_CONTINUE;
}

public player_killed(victim, attacker){
	if(!is_user_connected(attacker)) return HAM_IGNORED;

	new iReturn;

	if(duelStarted){
		ExecuteForward( g_fwDuelWon, iReturn, attacker );
	}

	return HAM_IGNORED;
}

public player_take_damage(id, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_connected(attacker) || !duelStarted) return HAM_IGNORED;

	SetHamParamFloat(4, damage);
	return HAM_HANDLED;
} 


public SetAmmo(id, weaponName, amount){

	new weaponEnt = get_weapon_ent(id, weaponName);
	if(pev_valid(weaponEnt))
	{
		cs_set_weapon_ammo(weaponEnt, amount);
	}
	
}

public BlockDrop(id){
	if(duelStarted){
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public BlockPickup(iEntity, id){
	return duelStarted ? HAM_SUPERCEDE : HAM_IGNORED;
}

public BlockJump(id){
	if(duelStarted){
		static oldbuttons;  
		oldbuttons = pev( id, pev_oldbuttons ); 
		if( oldbuttons & IN_JUMP && pev(id, pev_flags) & FL_ONGROUND){
			static Float:velocity[3];
			pev(id,pev_velocity,velocity);
			velocity[2] = -floatabs(velocity[2]);
			set_pev(id,pev_velocity,velocity);
		}
	}
	return HAM_IGNORED;
}

public BlockShop(id){
	if(duelStarted && is_user_alive(id)){
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
	
public Menu(id){
	new players[32];
	new players2[32];
	new CTAlive;
	new TAlive;

	get_players(players, TAlive, "ace", "TERRORIST");
	get_players(players2, CTAlive, "ace", "CT");

	gCtId = players2[0];
	gTerroId = players[0];

	if(cs_get_user_team(id) != CS_TEAM_CT){
		CC_SendMessage(id, "%L", id, "DUEL_IF_CT_MSG");
		//chat_color(id, "!g[DR]!n Poti face duel doar daca esti !gCT!n.");
		return PLUGIN_HANDLED;
	}
	
	if(CTAlive != 1 || gCtId != id ){
		CC_SendMessage(id, "%L", id, "DUEL_IF_LAST_CT_MSG");
		//chat_color(id, "!g[DR]!n Poti face duel doar daca esti ultimul !gCT!n in viata!n.");
		return PLUGIN_HANDLED;
	}

	if(TAlive == 0){
		CC_SendMessage(id, "%L", id, "DUEL_IF_TERRORIST_ALIVE_MSG");
		//chat_color(id, "!g[DR]!n Poti face duel numai daca exista un !gTerorist!n in viata!n.");
		return PLUGIN_HANDLED;
	}

	new menu = menu_create( "\rAlege arma!:", "menu_handler" );
	
	menu_additem( menu, "\rKnife", "", 0 );
	menu_additem( menu, "\rDeagle", "", 0 );
	menu_additem( menu, "\rMP5", "", 0 );
	menu_additem( menu, "\rAK47", "", 0 );
	menu_additem( menu, "\rP90", "", 0 );
	menu_additem( menu, "\rAUG", "", 0 );
	menu_additem( menu, "\rScout", "", 0 );
	menu_additem( menu, "\rM4A1", "", 0 );
	menu_additem( menu, "\rFamas", "", 0 );
	menu_additem( menu, "\rShotgun", "", 0 );
	menu_additem( menu, "\rGrenade", "", 0 );
	menu_additem( menu, "\rAWP", "", 0 );
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );

	menu_setprop(menu, MPROP_EXITNAME, "EXIT^n^n\r");

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\d");
	
	menu_display( id, menu, 0 );

	return 0;

}


public menu_handler( id, menu, item ){
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	new players[32];
	new players2[32];
	new CTAlive;
	new TAlive;

	get_players(players, TAlive, "ace", "TERRORIST");
	get_players(players2, CTAlive, "ace", "CT");

	gCtId = players2[0];
	gTerroId = players[0];

	if(cs_get_user_team(id) != CS_TEAM_CT){
		CC_SendMessage(id, "%L", id, "DUEL_IF_CT_MSG");
		//chat_color(id, "!g[DR]!n Poti face duel doar daca esti !gCT!n.");
		return PLUGIN_HANDLED;
	}
	
	if(CTAlive != 1 || gCtId != id ){
		CC_SendMessage(id, "%L", id, "DUEL_IF_LAST_CT_MSG");
		//chat_color(id, "!g[DR]!n Poti face duel doar daca esti ultimul !gCT!n in viata!n.");
		return PLUGIN_HANDLED;
	}

	if(TAlive == 0){
		CC_SendMessage(id, "%L", id, "DUEL_IF_TERRORIST_ALIVE_MSG");
		//chat_color(id, "!g[DR]!n Poti face duel numai daca exista un !gTerorist!n in viata!n.");
		return PLUGIN_HANDLED;
	}
	if ( item == MENU_EXIT )
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}

	DuelStart();
	new weaponName[32];
	switch( item )
	{
		case 0: weaponName = "weapon_knife";
		case 1: weaponName = "weapon_deagle";
		case 2: weaponName = "weapon_mp5navy";
		case 3: weaponName = "weapon_ak47";
		case 4: weaponName = "weapon_p90";
		case 5: weaponName = "weapon_aug";
		case 6: weaponName = "weapon_scout";
		case 7: weaponName = "weapon_m4a1";
		case 8: weaponName = "weapon_famas";
		case 9: weaponName = "weapon_m3";
		case 10: weaponName = "weapon_hegrenade";
		case 11: weaponName = "weapon_awp";
	}
	GiveWeapon(id, weaponName);
	GiveWeapon(gTerroId, weaponName);
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}


public GiveWeapon(id, weaponName[32]){
	new weaponId = get_weaponid(weaponName);
	fm_strip_user_weapons(id);
	set_pdata_int(id, 116, 0);

	give_item(id, weaponName);
	engclient_cmd(id, weaponName);
	if(weaponId != 29)
		cs_set_user_bpammo(id, weaponId, 999);
}

public DuelStart(){
	
	duelStarted = true;

	fm_set_rendering(gCtId, kRenderFxGlowShell, 0, 0, 250, kRenderNormal, 7);
	fm_set_rendering(gTerroId, kRenderFxGlowShell, 250, 0, 0, kRenderNormal, 7);

	set_task(1.0, "DuelStartHud", TASK_DUEL_START_ID,_,_, "a", 5);

	fm_give_item(gCtId,"CSW_VESTHELM");
	fm_set_user_health(gCtId,200);
	cs_set_user_armor(gCtId, 200, CS_ARMOR_VESTHELM);

	fm_give_item(gTerroId,"CSW_VESTHELM");
	fm_set_user_health(gTerroId,200);
	cs_set_user_armor(gTerroId, 200, CS_ARMOR_VESTHELM);

	set_user_godmode(gCtId, 1);
	set_user_godmode(gTerroId, 1);
}

public DuelStartHud(){
	if(duelStartTime<=0){
		set_task(1.0, "DuelHUD", TASK_DUEL_PROGRESS_ID,_,_, "a", duelTime);
		set_user_godmode(gCtId, 0);
		set_user_godmode(gTerroId, 0);
		remove_task(TASK_DUEL_START_ID);
		play_sound(0, szSound);

		set_user_maxspeed(gCtId, 250.0);
		set_user_maxspeed(gTerroId, 250.0);
		
		set_user_gravity(gCtId, 1.0);
		set_user_gravity(gTerroId, 1.0);

		return PLUGIN_CONTINUE;
	}

	set_hudmessage(0, 64, 255, -1.0, 0.3, 2, 1.0, 1.0, 0.01, 0.01, -1);
	ShowSyncHudMsg(0, g_msgsync, "Duelul incepe in : %d", duelStartTime);
	
	play_sound(0, szCountSounds[duelStartTime-1]);
	duelStartTime-=1;

	return PLUGIN_CONTINUE;
	
}

public DuelHUD(){
	if(duelRemainingTime<=0){
		user_kill(gCtId);
		user_kill(gTerroId);
		remove_task(TASK_DUEL_PROGRESS_ID);
	}
	
	if(task_exists(TASK_REGEN_ID + gCtId)) remove_task(TASK_REGEN_ID + gCtId);
	if(task_exists(TASK_REGEN_ID + gTerroId)) remove_task(TASK_REGEN_ID + gTerroId);

	set_hudmessage(200, 0, 0, -1.0, 0.3, 1, 1.0, 1.0, 0.01, 0.01, -1);
	ShowSyncHudMsg(0, g_msgsync, "Timp ramas pentru duel : %d", duelRemainingTime);
	duelRemainingTime-=1;
}

stock get_weapon_ent(id,wpnid=0,wpnName[]=""){
		// who knows what wpnName will be
		static newName[24];

		// need to find the name
		if(wpnid && wpnid<33) get_weaponname(wpnid,newName,23);

		// go with what we were told
		else formatex(newName,23,"%s",wpnName);

		// prefix it if we need to
		if(!equal(newName,"weapon_",7))
				format(newName,23,"weapon_%s",newName);

		return fm_find_ent_by_owner(get_maxplayers(),newName,id);
}

/*stock chat_color(const id, const input[], any:...){
	new iCount = 1;
	new iPlayers[32];

	static sMsg[191];

	vformat(sMsg, 190, input, 3);

	replace_all(sMsg, 190, "!g", "^4");
	replace_all(sMsg, 190, "!n", "^1");
	replace_all(sMsg, 190, "!t", "^3");

	if(id)
		iPlayers[0] = id;

	else
		get_players(iPlayers, iCount, "ch");

	for(new i = 0; i < iCount; i++)
		if(is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"),_, iPlayers[i]);
			write_byte(iPlayers[i]);
			write_string(sMsg);
			message_end();
		}
}*/

play_sound(id, sound[])
{
	send_audio(id, sound, PITCH_NORM);
}

stock send_audio(id, audio[], pitch)
{
	new audio_track[128];
	format(audio_track, 127, "%s", audio);
	if(containi(audio, "sound/") == -1)
		format(audio_track, 127, "sound/%s", audio);
	
	static msg_send_audio;
	
	if(!msg_send_audio) {
		msg_send_audio = get_user_msgid("SendAudio");
	}

	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msg_send_audio, _, id);
	write_byte(id);
	write_string(audio);
	write_short(pitch);
	message_end();
}