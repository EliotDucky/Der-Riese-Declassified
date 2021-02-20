#using scripts\zm\_zm_weap_cymbal_monkey;
#using scripts\zm\_zm_spawner;
#using scripts\codescripts\struct;
#using scripts\shared\flag_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\sound_shared;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_net;
#using scripts\zm\_zm_utility;
#using scripts\zm\zm_ducky_sound;

#insert scripts\zm\zm_monkey_upgrade.gsh;


#precache("hintstring", "Press ^3[{+activate}]^7 for Simian Bombs");
#precache("fx", "zombie/fx_powerup_on_green_zmb"); //CHANGE THIS TO RED

//REQUIRED: SET UP SOUND USUAL WAY, ADD THE NAME OF THE RED POWERUP FX TO ZONE
//	ADD SCRIPT_MODEL OF UPGRADED MONKEY PICKUP MODEL IN THE PLACE YOU WANT IT TO SPAWN,
//		TRIGGERNAME: UPGRADE_SCRIPT_MODEL_SPAWN
//IF ISSUES WITH MODEL SPAWNING, PRECACHE AND ADD TO ZONE

#namespace mnk_u;

/*IMPORTANT STUFF

monkey bomb weapon at level.weaponZMCymbalMonkey
upgraded at level.w_cymbal_monkey_upgraded
model at level.cymbal_monkey_model
	level._effect["grenade_samantha_steal"]
	level._effect["monkey_glow"]
give upgrade to player by `player _zm_weap_cymbal_monkey::player_give_cymbal_monkey_upgraded()`
check kills by function linked in zm_spawner::register_zombie_death_event_callback(&function_name)
Once u picked up notify to stop pickup function & swap monkey in box
furnace_monkey_upgrade
exploder::exploder( "furnace_monkey_upgrade" );
exploder::stop_exploder( "furnace_monkey_upgrade" );

*/

function autoexec init(){
	level thread startup();
}

//self is level
function startup(){
	level thread precacheFX();
	level flag::wait_till("initial_blackscreen_passed");
	level.mnk_u_counting = false;
	level.mnk_u_kills_remaining = REQ_KILLS;
	zm_spawner::register_zombie_death_event_callback(&trackMonkKills);
	level.mnk_u_pickup_trig = GetEnt(PICKUP_MNK_UPGRADE_TRIG, "targetname");
	level.mnk_u_pickup_trig SetHintString("");
	level.mnk_u_pickup_trig SetCursorHint("HINT_NOICON");

	level.mnk_u_world_model = GetEnt(UPGRADE_SCRIPT_MODEL_SPAWN, "targetname");
	level.mnk_u_world_model Hide();
	//callback::on_spawned(&mnkContinuity);
	//callback::on_connect(&mnkContinuity);
}

function precacheFX(){
	if(!isdefined(level._effect)){
		level._effect = [];
	}
	level._effect["powerup_on_red"] = MNK_U_RED_POWERUP;
}

//self is dead zombie
function trackMonkKills(player){
	if(isdefined(self) && self.damageWeapon === level.weaponZMCymbalMonkey && IsPlayer(player)){
		level.mnk_u_kills_remaining--;
		wait(0.05);
		if(DEV_MODE && !level.mnk_u_counting){
			level.mnk_u_counting = true;
			IPrintLnBold("Remaining Kills for Mnk Upgrade: " +level.mnk_u_kills_remaining);
			wait(0.05);
			level.mnk_u_counting = false;
		}
		if(level.mnk_u_kills_remaining <= 0 && !level.mnk_u_counting){
			level.mnk_u_counting = true;
			wait(0.05);
			zm_spawner::deregister_zombie_death_event_callback(&trackMonkKills);
			level thread furnaceWaitFor();
		}
	}
}

//self is level
function furnaceWaitFor(){
	level endon("death");
	level.mnk_can_furnace = true;
	level thread zm_utility::really_play_2D_sound(MNK_U_KILLS_COMPLETE_SND);
	furnace_trig = GetEnt(FURNACE_TRIG_NAME, "targetname");
	if(!isdefined(furnace_trig)){
		return;
	}
	furnace_trig thread sound::loop_on_entity(MNK_U_FURNACE_LOOP_SND);
	level.mnk_u_frn_done = false;
	foreach(player in GetPlayers()){ //THIS IS THE ISSUE - THREAD AND NOTIFY WHEN DONE
		player thread furnacePlayerWaitfor(furnace_trig);
	}
}

//Call on player
//THREAD
function furnacePlayerWaitfor(furnace_trig){
	while(!level.mnk_u_frn_done){
		self waittill("grenade_fire", grenade, weapon);
		if(weapon === level.weaponZMCymbalMonkey){
			grenade waittill("stationary");
			if(grenade IsTouching(furnace_trig) && !level.mnk_u_frn_done){
				wait(0.05);
				level.mnk_u_frn_done = true;
				furnace_trig thread furnaceExecute(grenade);
			}
		}
	}
}

//Call on furnace_trig
function furnaceExecute(thrown_monkey){
	//Stop the call to the furnace sound loop
	self thread sound::stop_loop_on_entity(MNK_U_FURNACE_LOOP_SND);
	wait(0.05);

	self thread furnaceExploder();

	//Start the monkey screaming
	self ducky_sound::playOnEnt(MNK_U_FURNACE_SCREAM);
	//wait(SoundGetPlaybackTime(MNK_U_FURNACE_SCREAM)/1000);

	//Once finished, delete
	thrown_monkey Delete();

	//Spawn upgraded monkey
	level.mnk_u_world_model Show();
	/*
	spawn_loc = self.origin + (0, 0, 20);
	level.mnk_u_world_model = Spawn("script_model", spawn_loc);
	level.mnk_u_world_model SetModel(MNK_U_WORLD);
	wait(0.05);
	level.mnk_u_world_model RotateTo(FURNACE_ANGLES, 0.05);
	*/

	wait(WAIT_TWEAKER);

	//Sam taunts about monkey
	level thread ducky_sound::playOnEnt(MNK_U_SAM_TAUNT);

	//Rotate to right angles
	//level.mnk_u_world_model.angles = FURNACE_ANGLES;
	//wait(0.05);

	//Play The FX on the monkey
	PlayFXOnTag(level._effect["powerup_on_red"], level.mnk_u_world_model, "tag_head_animate");
	level.mnk_u_world_model sound::play_on_entity("zmb_spawn_powerup");

	//Play the powerup sound on the monkey
	level.mnk_u_world_model thread sound::loop_on_entity("zmb_spawn_powerup_loop");

	//Move the upgraded monkey model to the trigger
	level.mnk_u_world_model MoveTo(level.mnk_u_pickup_trig.origin - (0, 0, 10), 0.8);
	
	wait(0.5);


	players = GetPlayers();
	level.mnk_u_players_rem = 0;
	foreach(player in players){
		if(player zm_weapons::has_weapon_or_upgrade(level.weaponZMCymbalMonkey)
		&& !(player zm_weapons::has_upgrade(level.weaponZMCymbalMonkey))){
			level.mnk_u_pickup_trig SetHintStringForPlayer(player, "Press ^3[{+activate}]^7 for Simian Bombs");
			level.mnk_u_players_rem++;
		}
	}
	level thread mnkUWaitFor();
	level.zombie_weapons[level.weaponZMCymbalMonkey].is_in_box = false;
	level.zombie_weapons[level.w_cymbal_monkey_upgraded].is_in_box = true;
	level.mnk_can_furnace = false;
}

function furnaceExploder(){
	//Play the furnace fire
	level thread exploder::exploder(UPGRADE_FURNACE_FX);

	if(FURNACE_IGNITE != ""){
		self ducky_sound::playOnEnt(FURNACE_IGNITE);
	}
	wait(0.05);
	self thread sound::loop_on_entity(FURNACE_ROAST_SFX_LOOP);

	wait(8);

	//Stop the furnace fire
	level thread exploder::stop_exploder(UPGRADE_FURNACE_FX);
	self thread sound::stop_loop_on_entity(FURNACE_ROAST_SFX_LOOP);
	if(FURNACE_QUENCH != ""){
		wait(0.05);
		self ducky_sound::playOnEnt(FURNACE_QUENCH);
	}
}

//self is level
function mnkUWaitFor(){
	level endon("death");
	while(level.mnk_u_players_rem > 0){
		level.mnk_u_pickup_trig waittill("trigger", player);
		if(player zm_weapons::has_weapon_or_upgrade(level.weaponZMCymbalMonkey)
		&& !(player zm_weapons::has_upgrade(level.weaponZMCymbalMonkey))){
			level.mnk_u_pickup_trig SetHintStringForPlayer(player, "");
			level.mnk_u_players_rem--;
			level thread checkMonkeyModel();
			player _zm_weap_cymbal_monkey::player_give_cymbal_monkey_upgraded();
		}
	}
}

function checkMonkeyModel(){
	if(level.mnk_u_players_rem <= 0){
		level.mnk_u_world_model Delete();
	}
}