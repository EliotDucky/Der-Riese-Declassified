
#using scripts\shared\system_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\sound_shared;

#insert scripts\shared\version.gsh;

#precache("client_fx", "der_riese/fx_der_soul_swap"); //Change to soul FX name
#insert scripts\zm\_zm_der_meme_song_quest.gsh;
#insert scripts\shared\shared.gsh;

#namespace _zm_der_meme_song_quest;

//REGISTER_SYSTEM( "zm_der_meme_song_quest", &__init__, undefined )

function autoexec __init__system__(){
	system::register("_zm_der_meme_song_quest", &__init__, undefined, undefined);
}

function __init__(){
	init_fx();
	register_clientfields();
}

function init_fx(){
	if(!isdefined(level._effect["enemy_soul"])){
		level._effect["enemy_soul"] = MEME_SOUL_FX;
	}
}

function register_clientfields(){
	clientfield::register("scriptmover", "zm_der_meme_song_soul_fx", VERSION_DLC1, 1, "int", &playSoulFX, 0, 0);
}

//Call On: dead zombie or revised: empty model to move
function playSoulFX(localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump){
	if(newVal == 1){
		/*
		fx_model = Spawn(localClientNum, self.origin, "script_model");
		fx_model.angles = self.angles;
		fx_model SetModel("tag_origin");
		wait(0.016);
		*/
		//IPrintLnBold(localClientNum, level._effect["enemy_soul"]);
		self.soul_fx = PlayFXOnTag(localClientNum, level._effect["enemy_soul"], self, "tag_origin");
		/*
		wait(0.016);
		dest = GetEnt(localClientNum, "meme_song_deposit", "targetname").origin;
		dist = Distance(fx_model.origin, dest);
		vel = 12;
		time = dist/vel;
		fx_model MoveTo(dest, time);
		fx_model waittill("movedone");
		sound::play_in_space(localClientNum, MEME_SONG_SOUL_SOUND, dest);
		fx_model Delete();
		*/
	}else if(newVal == 0){
		KillFX( localClientNum, self.soul_fx );
		//IPrintLnBold(localClientNum, "fx dead");
	}
	
}