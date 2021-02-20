#using scripts\shared\sound_shared;
#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\exploder_shared;

#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_ai_dogs;
#using scripts\zm\_zm_spawner;

#precache("hintstring", "Press ^3[{+activate}]^7 to play ^5I'm on Der Riese^7 [COPYRIGHT WARNING]");
//#precache("fx", "smoke/fx_smk_vehicle_sector"); //Change to soul FX name

#insert scripts\zm\_zm_der_meme_song_quest.gsh;
#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;
#insert scripts\shared\archetype_shared\archetype_shared.gsh;

#namespace _zm_der_meme_song_quest;

//REGISTER_SYSTEM( "zm_der_meme_song_quest", &__init__, undefined)

/*
935 Manuals Triggers:
trigger_use
targetname: "meme_song_pickup"
target: [the manual script_model]
script_int: [the numbered position of it on the shelf (excluding the one already on the shelf)]

Bookshelf Trigger:
trigger_use
targetname: "meme_song_deposit"
target: "bookshelf_manuals"

Bookshelf Manuals:
script_model
targetname: "bookshelf_manuals"
script_int: [the numbered position of the shelf, correlating to the pickup book]

Bookshelf Soul Chest Volume:
info_volume
targetname: "bookshelf_soul_chest"
*/

function autoexec __init__(){
	system::register("_zm_der_meme_song_quest", &setup, undefined, undefined);
}

function setup(){
	clientfield::register("scriptmover", "zm_der_meme_song_soul_fx", VERSION_DLC1, 1, "int");

	level.meme_song_parts = [];
	pickup_trigs = GetEntArray("meme_song_pickup", "targetname");
	bookshelf_trig = GetEnt("meme_song_deposit", "targetname");
	
	array::thread_all(pickup_trigs, &memeBookTrigWaitfor);
	wait(0.05);
	bookshelf_trig thread memeBookshelfWaitfor();
}

//Call On: manual pickup trig
//THREAD
function memeBookTrigWaitfor(){
	//Initialise each book pickup to false
	array::add(level.meme_song_parts, false);

	self UseTriggerRequireLookAt();
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");

	pos = -1;
	model = undefined;
	if(!(isdefined(self.script_int) && isdefined(self.target))){
		return;
	}else{
		pos = self.script_int;
		model = GetEnt(self.target, "targetname");
	}

	level flag::wait_till("initial_blackscreen_passed");
	

	self waittill("trigger", p);

	//Play pickup sound
	self thread sound::play_on_entity(MEME_SONG_PICKUP_SOUND);

	level.meme_song_parts[pos] = true;
	model Delete();
	self Delete();
}

//Call On: bookshelf trigger
//THREAD
function memeBookshelfWaitfor(){
	self UseTriggerRequireLookAt();
	self SetCursorHint("HINT_NOICON");
	self SetHintString("");

	book_shows = GetEntArray(self.target, "targetname");
	//Put in script_int order
	book_shows = orderStructs(book_shows);
	foreach(book in book_shows){
		book Hide();
	}

	//Prep soul box
	level.meme_volume = GetEntArray("bookshelf_soul_chest", "targetname");
	level.meme_kills = 0;
	level.meme_soul_loc = self.origin;

	placed = 0;
	wait(0.05);
	while(placed < level.meme_song_parts.size){
		self waittill("trigger", p);
		for(i = 0; i<level.meme_song_parts.size; i++){
			if(level.meme_song_parts[i]){
				book_shows[i] Show();
				self thread sound::play_on_entity(MEME_SONG_PLACE_SOUND);
				placed++;
				level.meme_song_parts[i] = false;
			}
		}
	}

	exploder::exploder("meme_song_light");
	//Register callbacks
	zm_spawner::register_zombie_death_event_callback(&soulChest);
	zm_ai_dogs::register_dog_death_event_callback(&soulChest);

	while(level.meme_kills < MEME_SONG_SOUL_KILLS){
		wait(0.05);
		continue;
	}

	zm_spawner::deregister_zombie_death_event_callback(&soulChest);
	zm_ai_dogs::deregister_dog_death_event_callback(&soulChest);

	self SetHintString("Press ^3[{+activate}]^7 to play ^5I'm on Der Riese^7 [COPYRIGHT WARNING]");
	self waittill("trigger", player);
	//PLAYSOUND WITH PRIORITY
	//IPrintLnBold("IM ON DER RIESE");
	level thread zm_audio::sndMusicSystem_PlayState( "meme" );
	exploder::stop_exploder("meme_song_light");

	wait(0.05);
	self Delete();
}

//Call On: Dead enemy
function soulChest(){
	if(isdefined(self) && !level.meme_kills < MEME_SONG_SOUL_KILLS){
		foreach(vol in level.meme_volume){
			if(self IsTouching(vol)){
				level.meme_kills++;
				//IPrintLnBold(level.meme_kills);
				
				soul_tag = "j_spineupper";
				if(self.archetype == ARCHETYPE_ZOMBIE_DOG){
					soul_tag = "j_neck";
				}

				loc = self GetTagOrigin(soul_tag);
				fx_model = Spawn("script_model", loc);
				fx_model.angles = self.angles;
				fx_model SetModel("tag_origin");
				fx_model PlaySound("zmb_shard_soul_leave");
				wait(0.05);
				//PlayFXOnTag(MEME_SOUL_FX, fx_model, "tag_origin");
				fx_model clientfield::set("zm_der_meme_song_soul_fx", 1);
				wait(0.05);
				fx_model PlayLoopSound("zmb_shard_soul_lp");

				dist = Distance(loc, level.meme_soul_loc);
				vel = MEME_SONG_SOUL_VELOCITY;
				time = dist/vel;
				fx_model MoveTo(level.meme_soul_loc, time);
				fx_model waittill("movedone");
				fx_model PlaySound("zmb_shard_soul_impact");
				fx_model Delete();
				return;
			}
		}
	}
}

function private orderStructs(structs){
	new_structs = [];
	for(i = 0; i<structs.size; i++){
		foreach(_struct in structs){
			if(isdefined(_struct.script_int) && _struct.script_int == i){
				array::add(new_structs, _struct);
			}
		}
	}
	return new_structs;
}