#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\sound_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_utility;

#namespace zm_prototype_exploding_barrels;

function autoexec __init__sytem__()
{
	system::register("zm_prototype_barrels", &__init__, undefined, undefined);
}

function __init__()
{
	level.zombie_lethal_grenade_player_init = GetWeapon( "special_ger_grenade" );
	var_37ec7c95 = 0;
	a_barrels = GetEntArray("explodable_barrel", "targetname");
	if(isdefined(a_barrels) && a_barrels.size > 0)
	{
		var_37ec7c95 = 1;
	}
	a_barrels = GetEntArray("explodable_barrel", "script_noteworthy");
	if(isdefined(a_barrels) && a_barrels.size > 0)
	{
		var_37ec7c95 = 1;
	}
	if(!var_37ec7c95)
	{
		return;
	}
	clientfield::register("scriptmover", "exploding_barrel_burn_fx", 21000, 1, "int");
	clientfield::register("scriptmover", "exploding_barrel_explode_fx", 21000, 1, "int");
	level.barrelExpSound = "exp_redbarrel";
	level.barrelIngSound = "exp_redbarrel_ignition";
	level.barrelHealth = 350;
	level.barrelExplodingThisFrame = 0;
	level.red_barrel_reward_wpn = GetWeapon("special_ger_grenade");
	level.red_barrels_complete = false;
	callback::on_spawned(&giveUpgradeWhenReady);
	Array::thread_all(GetEntArray("explodable_barrel", "targetname"), &explodable_barrel_think);
	Array::thread_all(GetEntArray("explodable_barrel", "script_noteworthy"), &explodable_barrel_think);
	level thread function_28ed3370();
}

function function_66d46c7d()
{
	self clientfield::set("exploding_barrel_burn_fx", 1);
}

function function_b6fe19c5()
{
	self clientfield::set("exploding_barrel_explode_fx", 1);
}

function explodable_barrel_think()
{
	if(self.classname != "script_model")
	{
		return;
	}
	self endon("exploding");
	self.damageTaken = 0;
	self SetCanDamage(1);
	for(;;)
	{
		self waittill("damage", amount, attacker, direction_vec, p, type);
		//IPrintLnBold(attacker.name);
		if( type == "MOD_RIFLE_BULLET" || type == "MOD_PISTOL_BULLET" || type == "MOD_HEAD_SHOT" || type == "MOD_CRUSH" || type == "MOD_MELEE" || type == "MOD_IMPACT")
		{
			continue;
		}
		if(isdefined(self.script_requires_player) && self.script_requires_player && (!isPlayer(attacker) && (isdefined(attacker.classname) && attacker.classname != "worldspawn")))
		{
			continue;
		}
		if(isdefined(self.script_selfisattacker) && self.script_selfisattacker)
		{
			self.damageOwner = self;
		}
		else
		{
			self.damageOwner = attacker;
		}
		if(level.barrelExplodingThisFrame)
		{
			wait(RandomFloat(1));
		}
		self.damageTaken = self.damageTaken + amount;
		if(self.damageTaken == amount)
		{
			self thread explodable_barrel_burn();
		}
	}
}

function explodable_barrel_burn()
{
	count = 0;
	startedfx = 0;
	while(self.damageTaken < level.barrelHealth)
	{
		if(!startedfx)
		{
			function_66d46c7d();
			level thread sound::play_in_space(level.barrelIngSound, self.origin);
			startedfx = 1;
		}
		if(count > 20)
		{
			count = 0;
		}
		if(count == 0)
		{
			self.damageTaken = self.damageTaken + 10 + RandomFloat(10);
			badplace_cylinder("", 1, self.origin, 128, 250, "axis");
			self playsound("exp_barrel_fuse");
		}
		count++;
		wait(0.05);
	}
	self thread explodable_barrel_explode();
}

function explodable_barrel_explode()
{
	self notify("exploding");
	self notify("death");
	up = anglesToUp(self.angles);
	worldup = anglesToUp(VectorScale((0, 1, 0), 90));
	dot = VectorDot(up, worldup);
	offset = (0, 0, 0);
	if(dot < 0.5)
	{
		start = self.origin + VectorScale(up, 22);
		end = PhysicsTrace(start, start + VectorScale((0, 0, -1), 64));
		offset = end - self.origin;
	}
	offset = offset + VectorScale((0, 0, 1), 4);
	function_b6fe19c5();
	wait(0.05);
	level thread sound::play_in_space(level.barrelExpSound, self.origin);
	PhysicsExplosionSphere(self.origin + offset, 100, 80, 1);
	PlayRumbleOnPosition("barrel_explosion", self.origin + VectorScale((0, 0, 1), 32));
	level notify("hash_83cc4809");
	level.barrelExplodingThisFrame = 1;
	self thread breakable_clip();
	if(isdefined(self.remove))
	{
		self.remove connectpaths();
		self.remove delete();
	}
	maxDamage = 250;
	if(isdefined(self.script_damage))
	{
		maxDamage = self.script_damage;
	}
	blastRadius = 250;
	if(isdefined(self.radius))
	{
		blastRadius = self.radius;
	}
	attacker = undefined;
	if(isdefined(self.damageOwner))
	{
		attacker = self.damageOwner;
	}
	level.lastExplodingBarrel["time"] = GetTime();
	level.lastExplodingBarrel["origin"] = self.origin + VectorScale((0, 0, 1), 30);
	self RadiusDamage(self.origin + VectorScale((0, 0, 1), 30), blastRadius, maxDamage, 1, attacker , "MOD_GRENADE");
	if(RandomInt(2) == 0)
	{
		self SetModel("p7_zm_nac_barrel_explosive_red_dmg_01");
	}
	else
	{
		self SetModel("p7_zm_nac_barrel_explosive_red_dmg_02");
	}
	if(dot < 0.5)
	{
		start = self.origin + VectorScale(up, 22);
		pos = PhysicsTrace(start, start + VectorScale((0, 0, -1), 64));
		self.origin = pos;
		self.angles = self.angles + VectorScale((0, 0, 1), 90);
	}
	waittillframeend;
	level.barrelExplodingThisFrame = 0;
}

function breakable_clip()
{
	if(isdefined(self.target))
	{
		targ = GetEnt(self.target, "targetname");
		if(targ.classname == "script_brushmodel")
		{
			self.remove = targ;
			return;
		}
	}
	if(isdefined(self.remove))
	{
		ArrayRemoveValue(level.breakables_clip, self.remove);
	}
}

function function_28ed3370()
{
	var_e1c041e0 = GetEntArray("explodable_barrel", "targetname");
	var_53c7b11b = GetEntArray("explodable_barrel", "script_noteworthy");
	if(isdefined(var_e1c041e0))
	{
		var_69238c0b = var_e1c041e0.size;
	}
	if(isdefined(var_53c7b11b))
	{
		var_69238c0b = var_69238c0b + var_53c7b11b.size;
	}
	for(var_1d2242bc = 0; var_1d2242bc < var_69238c0b; var_1d2242bc++)
	{
		level waittill("hash_83cc4809");
	}
	level.red_barrels_complete = true;
	level thread zm_utility::play_sound_2d("evt_grenade_upg_complete");
	foreach(player in GetPlayers())
	{
		player thread giveUpgradeWhenReady();
	}
}

function giveUpgradeWhenReady()
{
	if(level.red_barrels_complete)
	{
		while(self InLastStand())
		{
			wait(3);
		}
		if(isDefined(self zm_utility::get_player_lethal_grenade()))
		{
			self.current_lethal = self zm_utility::get_player_lethal_grenade();
			self TakeWeapon( self.current_lethal );
		}
		wait(0.05);
		self zm_weapons::weapon_give(level.red_barrel_reward_wpn);
	}
}