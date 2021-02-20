#using scripts\codescripts\struct;
#using scripts\shared\sound_shared;
#using scripts\shared\array_shared;
#using scripts\shared\exploder_shared;
#using scripts\zm\_zm_audio;
#using scripts\zm\zm_ducky_sound;

#insert scripts\zm\zm_der_punch_cards.gsh;

/*
Cards play in the order that they were picked up in

Punch Card Triggers:
targetname: punch_card_trig
target: [punch card models]

Punch Card Models:
script_int: [order setup in here]
	(So do Pernell as 0, Russian as 1)

Punch Card Machine Trigger:
targetname: punch_machine_trig
target: punch_machine_struct

Punch Machine Structs:
targetname: punch_machine_struct
script_string: start/end
Place where you want the origin of the cards to finish

Punch Machine Reels:
script_model
targetname: punch_card_reel
*/

function autoexec init(){
	level thread setup();
}

//Call On: Level
//THREAD
function setup(){
	//Add the audio in the correct order
	level.punch_card_times = [];
	addAudio(OSS_CARD);
	//array::add(level.punch_card_times, OSS_TIME);
	addAudio(RUS_CARD);
	//array::add(level.punch_card_times, RUS_TIME);

	//Get Trigs
	machine_trig = GetEnt("punch_machine_trig", "targetname");
	pickup_trigs = GetEntArray("punch_card_trig", "targetname");

	pickup_trigs = getRandomFromMultiple(pickup_trigs);

	//WaitFors
	machine_trig thread punchCardMachineTrigWaitFor();
	array::thread_all(pickup_trigs, &punchCardTrigWaitFor);
}

function addAudio(alias_name){
	if(!isdefined(level.punch_card_audio)){
		level.punch_card_audio = [];
	}
	level.punch_card_audio[level.punch_card_audio.size] = alias_name;
}

//Call On: Punch Card Machine Trigger
//THREAD
function punchCardMachineTrigWaitFor(){
	level endon("death");

	self SetCursorHint("HINT_NOICON");
	self SetHintString(&"ZOMBIE_NEED_POWER");
	self UseTriggerRequireLookAt();

	//Get Start and End locs
	insert_locs = struct::get_array("punch_machine_struct", "targetname");
	start_loc = (0,0,0);
	end_loc = start_loc;
	angle = undefined;
	foreach(loc in insert_locs){
		if(isdefined(loc.script_string) && loc.script_string == "start"){
			start_loc = loc.origin;
			angle = loc.angles;
		}else{
			end_loc = loc.origin;
		}
	}
	cards_played = 0;

	//Get the reels
	reels = GetEntArray("punch_card_reel", "targetname");

	//Waitfor power-on
	level waittill("power_on");
	self SetHintString("");

	while(cards_played <= level.punch_card_audio.size){
		self waittill("trigger", player);
		i = 0;

		//Play each in order if they have been picked up
		foreach(card in level.punch_cards){
			if(isdefined(card)){
				card insertCard(start_loc, end_loc, angle, reels);
				cards_played++;
				
				if(i < level.punch_cards.size-1){
					self waittill("trigger", player);
				}
				
			}
			
			i++;
		}

		//Delete all of the ones that have been picked up
		//After all have played
		/*
		foreach(card in level.punch_cards){
			card Delete();
		}
		level.punch_cards = [];
		*/
	}
}

//Call On: Punch Card Model
function insertCard(start=(0,0,0), end=(0,0,0), _angles, reels){
	if(isdefined(self.script_int)){
		to_play = level.punch_card_audio[self.script_int];
		move_time = 1.0;

		//Place the card
		self.origin = start;
		if(isdefined(_angles)){
			self.angles = _angles;
		}
		wait(0.05);
		self Show();
		self thread sound::play_on_entity(INSERT_SOUND);

		//Insert the card
		self MoveTo(end, move_time);
		self waittill("movedone");

		//Spin the reels
		foreach(reel in reels){
			reel thread reelSpin();
		}

		//Play the audio
		//self thread sound::play_on_entity(to_play);
		self ducky_sound::playOnEnt(to_play);
		//has built in waittill function but don't use
		//wait(level.punch_card_times[self.script_int]);

		//End the reels spinning
		foreach(reel in reels){
			reel notify("end_reel_play");
		}


		
		wait(0.5);

		//Remove the card
		
		self thread sound::play_on_entity(INSERT_SOUND);
		//self MoveTo(start, move_time);
		//self waittill("movedone");
		self Delete();
		
	}
}

//Call On: Reel to Spin
//THREAD
function reelSpin(){
	self endon("end_reel_play");
	while(true){
		self RotateRoll(360, 3);
		self waittill("rotatedone");
	}
}

//Call on Punch Card Triggers
//THREAD
function punchCardTrigWaitFor(){
	self endon("death");

	self SetCursorHint("HINT_NOICON");
	self SetHintString("");
	self UseTriggerRequireLookAt();

	model = GetEnt(self.target, "targetname");
	self waittill("trigger", p);

	//Pickup
	self thread sound::play_on_entity(PICKUP_SOUND);
	p thread zm_audio::create_and_play_dialog( "buildable", "part_pickup" );
	model pickupCard();
	self Delete();
}

//Call on Punch Card Model
function pickupCard(){
	self Hide();
	if(!isdefined(level.punch_cards)){
		level.punch_cards = [];
	}
	level.punch_cards[level.punch_cards.size] = self;
}

function getRandomFromMultiple(ents){
	all_ents = [];

	//group by script int
	for(i=0; i<ents.size; i++){
		ent = ents[i];
		model = GetEnt(ent.target, "targetname");
		if(isdefined(model.script_int)){
			if(!isdefined(all_ents[model.script_int])){
				all_ents[model.script_int] = [];
			}
			array::add(all_ents[model.script_int], ent);
		}
	}

	//Pick the locations
	final_ents = [];
	foreach(arr in all_ents){
		arr = array::randomize(arr);
		chosen = array::pop_front(arr);
		array::add(final_ents, chosen);

		//Delete the unused (used are popped out already)
		foreach(ent in arr){
			if(isdefined(ent.target)){
				model = GetEnt(ent.target, "targetname");
				model Delete();
			}
			ent Delete();
		}
	}

	return final_ents;
}