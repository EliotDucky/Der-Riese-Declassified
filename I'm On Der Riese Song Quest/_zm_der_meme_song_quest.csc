
#using scripts\shared\system_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\sound_shared;

#insert scripts\shared\version.gsh;

#precache("client_fx", "der_riese/fx_der_soul_swap"); //Change to soul FX name
#insert scripts\zm\_zm_der_meme_song_quest.gsh;
#insert scripts\shared\shared.gsh;

#namespace _zm_der_meme_song_quest;

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

//Call On: empty model to move
function playSoulFX(localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump){
	if(newVal == 1){
		self.soul_fx = PlayFXOnTag(localClientNum, level._effect["enemy_soul"], self, "tag_origin");
	}else if(newVal == 0){
		KillFX( localClientNum, self.soul_fx );
	}
	
}
