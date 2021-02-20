#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\sound_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#precache( "client_fx", "explosions/fx_exp_dest_barrel_sm" );
#precache( "client_fx", "dlc5/prototype/fx_barrel_ignite" );

#namespace zm_prototype_exploding_barrels;

function autoexec __init__sytem__()
{
	system::register("zm_prototype_barrels", &__init__, undefined, undefined);
}

function __init__()
{
	init_barrel_fx();

	clientfield::register("scriptmover", "exploding_barrel_burn_fx", 21000, 1, "int", &function_66d46c7d, 0, 0);
	clientfield::register("scriptmover", "exploding_barrel_explode_fx", 21000, 1, "int", &function_b6fe19c5, 0, 0);
}

function init_barrel_fx()
{
	level.breakables_fx["barrel"]["explode"] = "explosions/fx_exp_dest_barrel_sm";
	level.breakables_fx["barrel"]["burn_start"] = "dlc5/prototype/fx_barrel_ignite";
}

function function_66d46c7d(localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump)
{
	if(newVal)
	{
		self.var_39bdc445 = PlayFXOnTag(localClientNum, level.breakables_fx["barrel"]["burn_start"], self, "tag_fx_btm");
	}
}

function function_b6fe19c5(localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump)
{
	if(newVal)
	{
		if(isdefined(self.var_39bdc445))
		{
			stopfx(localClientNum, self.var_39bdc445);
		}
		self.var_4360e059 = PlayFXOnTag(localClientNum, level.breakables_fx["barrel"]["explode"], self, "tag_fx_btm");
	}
}

