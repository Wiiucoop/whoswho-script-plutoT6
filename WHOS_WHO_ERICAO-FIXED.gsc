#include maps\mp\_utility;
#include maps\mp\_visionset_mgr;
#include maps\mp\_music;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\gametypes_zm\_gv_actions;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\animscripts\zm_combat;
#include maps\mp\animscripts\zm_utility;
#include maps\mp\animscripts\utility;
#include maps\mp\animscripts\shared;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_weap_cymbal_monkey;
#include maps\mp\zombies\_zm_clone;
#include maps\mp\zombies\_zm_chugabud;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\gametypes_zm\_clientids;




init() //checked matches cerberus output
{
	level.chugabud_laststand_func = ::chugabud_laststand;	
	level thread chugabud_hostmigration();
	add_custom_limited_weapon_check( ::is_weapon_available_in_chugabud_corpse );
	level thread onPlayerConnect();
	thread startCustomPerkMachines();
}



onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
		
        if(isDefined(level.player_out_of_playable_area_monitor))
                   level.player_out_of_playable_area_monitor = false;
        player thread onPlayerSpawned();
		
    }
} 


onPlayerSpawned()
{
    self.stopThreading = false;
    self endon("disconnect");
	self.hasTombs = false;

	thread onPlayerDowned();
}


startCustomPerkMachines()
{
	if(level.disableAllCustomPerks == 0)
	{
		if(getDvar("mapname") == "zm_buried") //buried
		{
				level thread CustomPerkMachine( "zombie_perk_bottle_marathon", "zombie_vending_revive_on", "Who's Who", 2000, (-732, -1084, 10.47), "specialty_finalstand", (0, 90, 0) );
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{																			      
				level thread CustomPerkMachine( "zombie_perk_bottle_revive", "zombie_vending_revive_on", "Who's Who", 2000, (697, 460, -57), "specialty_finalstand", (5, 250, 0) );
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			level thread CustomPerkMachine( "zombie_perk_bottle_revive", "p6_zm_tm_vending_revive_on", "Who's Who", 2000, (906, 912, 66), "specialty_finalstand", (0, -90, 0) );
		}
		else if ( getDvar( "ui_zm_mapstartlocation" ) == "town" ) //town
		{
			level thread CustomPerkMachine( "zombie_perk_bottle_revive", "zombie_vending_revive_on", "Who's Who", 2000, (1447.74, -1620, -60), "specialty_finalstand", (0, 180, 0) );
		}
		else if ( getDvar( "ui_zm_mapstartlocation" ) == "farm" ) //farm
		{
			level thread CustomPerkMachine( "zombie_perk_bottle_revive", "zombie_vending_revive_on", "Who's Who", 2000, (8516, -5600, 50), "specialty_finalstand", (0, 0, 0) );
		}
		else if(getDvar("mapname") == "zm_transit" && !getdvar( "ui_zm_gamemodegroup" ) == "zsurvival") //Spawns on Tranzit only and NOT on bus depot survival
		{
			level thread CustomPerkMachine( "zombie_perk_bottle_revive", "zombie_vending_revive_on", "Who's Who", 2000, (-7272, 4585, -56), "specialty_finalstand", (0, 180, 0) );
		}
	}
}


CustomPerkMachine( bottle, model, perkname, cost, origin, perk, angles ) //custom perk system. 
{
	level endon( "end_game" );
	if(!isDefined(level.customPerkNum))
		level.customPerkNum = 1;
	else
		level.customPerkNum += 1;
	collision = spawn("script_model", origin);
    collision setModel("collision_geo_cylinder_32x128_standard");
    collision rotateTo(angles, .1);
	RPerks = spawn( "script_model", origin );
	RPerks setModel( model );
	RPerks rotateTo(angles, .1);
	trig SetHintString("Hold ^3&&1^7 for "+perkname+" [Cost: " + cost + "]");
	trig = spawn("trigger_radius", origin, 1, 25, 25);
	trig SetCursorHint( "HINT_NOICON" );
	trig SetHintString("Hold ^3&&1^7 for "+perkname+" [Cost: " + cost + "]");
	for(;;)
	{
		trig waittill("trigger", player);
		if(player useButtonPressed() && player.score >= cost)
		{
			wait .25;
			if(player useButtonPressed())
			{
				if(!player hasPerk(perk))
				{
					player playsound( "zmb_cha_ching" ); //money SFX
					player.score -= cost; //take points
					level.trig hide();
					player thread GivePerk( bottle, perk, perkname ); //give perk
					wait 2;
					level.trig show();
				}
				else
					player iprintln("^2You already have "+perkname+"!");
			}
		}
	}
}

GivePerk( model, perk, perkname )
{
	self DisableOffhandWeapons();
	self DisableWeaponCycling();
	weaponA = self getCurrentWeapon();
	weaponB = model;
	self GiveWeapon( weaponB );
	self SwitchToWeapon( weaponB );
	self waittill( "weapon_change_complete" );
	self EnableOffhandWeapons();
	self EnableWeaponCycling();
	self TakeWeapon( weaponB );
	self SwitchToWeapon( weaponA );
	self setperk( perk );
	self maps\mp\zombies\_zm_audio::playerexert( "burp" );
	self setblur( 4, 0.1 );
	wait 0.1;
	self setblur( 0, 0.1 );
	if(perk == "specialty_finalstand")
	{
		self.lives = 1;
		self.hasperkspecialtychugabud = 1;
		self notify( "perk_chugabud_activated" );
		self thread drawCustomPerkHUD("specialty_quickrevive_zombies", 0, (0.125, 0.125, 0.125));

	}

}



drawCustomPerkHUD(perk, x, color, perkname) //perk hud
{
    if(!isDefined(self.icon1))
    {
    	x = -408;
    	if(getDvar("mapname") == "zm_buried" || getDvar("mapname") == "zm_tomb")
    		self.icon1 = self drawshader( perk, x, 293, 24, 25, color, 100, 0 );
    	else
    		self.icon1 = self drawshader( perk, x, 320, 24, 25, color, 100, 0 );
    }
    else if(!isDefined(self.icon2))
    {
    	x = -378;
    	if(getDvar("mapname") == "zm_buried" || getDvar("mapname") == "zm_tomb")
    		self.icon2 = self drawshader( perk, x, 293, 24, 25, color, 100, 0 );
    	else
    		self.icon2 = self drawshader( perk, x, 320, 24, 25, color, 100, 0 );
    }
    else if(!isDefined(self.icon3))
    {
    	x = -348;
    	if(getDvar("mapname") == "zm_buried" || getDvar("mapname") == "zm_tomb")
    		self.icon3 = self drawshader( perk, x, 293, 24, 25, color, 100, 0 );
    	else
    		self.icon3 = self drawshader( perk, x, 320, 24, 25, color, 100, 0 );
    }
    else if(!isDefined(self.icon4))
    {
    	x = -318;
    	if(getDvar("mapname") == "zm_buried" || getDvar("mapname") == "zm_tomb")
    		self.icon4 = self drawshader( perk, x, 293, 24, 25, color, 100, 0 );
    	else
    		self.icon4 = self drawshader( perk, x, 320, 24, 25, color, 100, 0 );
    }
}

drawshader( shader, x, y, width, height, color, alpha, sort )
{
	hud = newclienthudelem( self );
	hud.elemtype = "icon";
	hud.color = color;
	hud.alpha = alpha;
	hud.sort = sort;
	hud.children = [];
	hud setparent( level.uiparent );
	hud setshader( shader, width, height );
	hud.x = x;
	hud.y = y;
	return hud;
}















chugabug_precache() 
{
}

chugabud_player_init() 
{
}

onPlayerDowned()
{
	self endon("disconnect");
	level endon("end_game");
	
	for(;;)
	{

		self waittill_any( "player_downed", "fake_death", "entering_last_stand");

    		self unsetperk( "specialty_finalstand" ); //removes the whos who perk functionality
    		self.icon1 Destroy();self.icon1 = undefined; //deletes the perk icons and resets the variable
    		self.icon2 Destroy();self.icon2 = undefined; //deletes the perk icons and resets the variable
    		self.icon3 Destroy();self.icon3 = undefined; //deletes the perk icons and resets the variable
    		self.icon4 Destroy();self.icon4 = undefined; //deletes the perk icons and resets the variable

	}
}

chugabud_laststand() //Main WW code contained here
{

	if(self hasPerk("specialty_scavenger")){
		self.hasTombs = true;

	}
	self endon( "player_suicide" );
	self endon( "disconnect" );
	self endon( "chugabud_bleedout" );
	
	self maps\mp\zombies\_zm_laststand::increment_downed_stat();
	self.ignore_insta_kill = 1;
	self.health = self.maxhealth;
	self maps\mp\zombies\_zm_chugabud::chugabud_save_loadout();
	self maps\mp\zombies\_zm_chugabud::chugabud_fake_death();
	wait 3;
	if ( isDefined( self.insta_killed ) && self.insta_killed || isDefined( self.disable_chugabud_corpse ) )
	{
		create_corpse = 0;
	}
	else
	{
		create_corpse = 1;
	}
	if ( create_corpse == 1 )
	{
		if ( isDefined( level._chugabug_reject_corpse_override_func ) )
		{
			reject_corpse = self [[ level._chugabug_reject_corpse_override_func ]]( self.origin );
			if ( reject_corpse )
			{
				create_corpse = 0;
			}
		}
	}

	if ( create_corpse == 1 )
	{

		self thread activate_chugabud_effects_and_audio();
		corpse = self chugabud_spawn_corpse();
		corpse thread chugabud_corpse_revive_icon( self );
		self.e_chugabud_corpse = corpse;
		corpse thread chugabud_corpse_cleanup_on_spectator( self );
	}
	self chugabud_fake_revive();
	wait 0.1;
	self.ignore_insta_kill = undefined;
	self.disable_chugabud_corpse = undefined;
	if ( create_corpse == 0 )
	{
		self notify( "chugabud_effects_cleanup" );
		return;
	}
	bleedout_time = getDvarFloat( "player_lastStandBleedoutTime" );
	self thread chugabud_bleed_timeout( bleedout_time, corpse );
	self thread chugabud_handle_multiple_instances( corpse );
	corpse waittill( "player_revived", e_reviver );
	if ( isDefined( e_reviver ) && e_reviver == self )
	{
		self notify( "whos_who_self_revive" );
	}
	self perk_abort_drinking( 0.1 );
	self maps\mp\zombies\_zm_perks::perk_set_max_health_if_jugg( "health_reboot", 1, 0 );
	self setorigin( corpse.origin );
	self setplayerangles( corpse.angles );
	if ( self player_is_in_laststand() )
	{
		self thread chugabud_laststand_cleanup( corpse, "player_revived" );
		self enableweaponcycling();
		self enableoffhandweapons();
		self auto_revive( self, 1 );
		return;
	}
	self chugabud_laststand_cleanup( corpse, undefined );
}

chugabud_laststand_cleanup( corpse, str_notify ) 
{
	if ( isDefined( str_notify ) )
	{
		self waittill( str_notify );
	}
	self chugabud_give_loadout();
	self chugabud_corpse_cleanup( corpse, 1 );
}

chugabud_bleed_timeout( delay, corpse ) 
{
	self endon( "player_suicide" );
	self endon( "disconnect" );
	corpse endon( "death" );
	wait delay;
	if ( isDefined( corpse.revivetrigger ) )
	{
		while ( corpse.revivetrigger.beingrevived )
		{
			wait 0.01;
		}
	}
	if ( isDefined( self.loadout.perks ) && flag( "solo_game" ) )
	{
		for ( i = 0; i < self.loadout.perks.size; i++ )
		{
			perk = self.loadout.perks[ i ];
			if ( perk == "specialty_quickrevive" )
			{

				arrayremovevalue( self.loadout.perks, self.loadout.perks[ i ] );
				corpse notify( "player_revived" );
				return;
			}
		}
	}
	self chugabud_corpse_cleanup( corpse, 0 );
}

chugabud_corpse_cleanup( corpse, was_revived )
{
	self notify( "chugabud_effects_cleanup" );
	if ( was_revived )
	{
		playsoundatposition( "zmb_phdflop_explo", corpse.origin );
		if(getDvar("mapname") == "zm_tomb")
		{
			playfx( level._effect[ "divetonuke_groundhit" ], corpse.origin );
		}else{
		playfx( level._effect[ "poltergeist" ], corpse.origin );
		}
	}
	else
	{
		playsoundatposition( "zmb_phdflop_explo", corpse.origin );
		if(getDvar("mapname") == "zm_tomb")
		{
			playfx( level._effect[ "divetonuke_groundhit" ], corpse.origin );
		}else{
		playfx( level._effect[ "poltergeist" ], corpse.origin );
		}
		self notify( "chugabud_bleedout" );
	}
	if ( isDefined( corpse.revivetrigger ) )
	{
		corpse notify( "stop_revive_trigger" );
		corpse.revivetrigger delete();
		corpse.revivetrigger = undefined;
	}
	if ( isDefined( corpse.revive_hud_elem ) )
	{
		corpse.revive_hud_elem destroy();
		corpse.revive_hud_elem = undefined;
	}
	self.loadout = undefined;
	wait 0.1;
	corpse delete();
	self.e_chugabud_corpse = undefined;
}

chugabud_handle_multiple_instances( corpse )
{
	corpse endon( "death" );

	self waittill( "perk_chugabud_activated" );
	self chugabud_corpse_cleanup( corpse, 0 );
}

chugabud_spawn_corpse() 
{
	corpse = maps\mp\zombies\_zm_clone::spawn_player_clone( self, self.origin, undefined, self.whos_who_shader );
	corpse.angles = self.angles;
	corpse maps\mp\zombies\_zm_clone::clone_give_weapon( "m1911_zm" );
	corpse maps\mp\zombies\_zm_clone::clone_animate( "laststand" );
	corpse.revive_hud = self chugabud_revive_hud_create();
	corpse thread maps\mp\zombies\_zm_laststand::revive_trigger_spawn();
	return corpse;
}

chugabud_revive_hud_create() 
{
	self.revive_hud = newclienthudelem( self );
	self.revive_hud.alignx = "center";
	self.revive_hud.aligny = "middle";
	self.revive_hud.horzalign = "center";
	self.revive_hud.vertalign = "bottom";
	self.revive_hud.y = -50;
	self.revive_hud.foreground = 1;
	self.revive_hud.font = "default";
	self.revive_hud.fontscale = 1.5;
	self.revive_hud.alpha = 0;
	self.revive_hud.color = ( 1, 1, 1 );
	self.revive_hud settext( "" );
	return self.revive_hud;
}

chugabud_save_loadout() 
{
	primaries = self getweaponslistprimaries();
	currentweapon = self getcurrentweapon();
	self.loadout = spawnstruct();
	self.loadout.player = self;
	self.loadout.weapons = [];
	self.loadout.score = self.score;
	self.loadout.current_weapon = -1;
	index = 0;
	foreach ( weapon in primaries )
	{
		logline1 = "weapon: " + weapon + "\n";
		logprint( logline1 );
		self.loadout.weapons[ index ] = maps\mp\zombies\_zm_weapons::get_player_weapondata( self, weapon );
		if ( weapon == currentweapon || self.loadout.weapons[ index ][ "alt_name" ] == currentweapon )
		{
			self.loadout.current_weapon = index;
		}
		index++;
	}
	self.loadout.equipment = self get_player_equipment();
	if ( isDefined( self.loadout.equipment ) )
	{
		self equipment_take( self.loadout.equipment );
	}
	self.loadout save_weapons_for_chugabud( self );
	if ( self hasweapon( "claymore_zm" ) )
	{
		self.loadout.hasclaymore = 1;
		self.loadout.claymoreclip = self getweaponammoclip( "claymore_zm" );
	}

	
	self.loadout.perks = chugabud_save_perks( self );
	
	self chugabud_save_grenades();
	if ( maps\mp\zombies\_zm_weap_cymbal_monkey::cymbal_monkey_exists() )
	{
		self.loadout.zombie_cymbal_monkey_count = self getweaponammoclip( "cymbal_monkey_zm" );
	}
}

chugabud_save_grenades() 
{
	if ( self hasweapon( "emp_grenade_zm" ) )
	{
		self.loadout.hasemp = 1;
		self.loadout.empclip = self getweaponammoclip( "emp_grenade_zm" );
	}
	lethal_grenade = self get_player_lethal_grenade();
	if ( self hasweapon( lethal_grenade ) )
	{
		self.loadout.lethal_grenade = lethal_grenade;
		self.loadout.lethal_grenade_count = self getweaponammoclip( lethal_grenade );
	}
	else
	{
		self.loadout.lethal_grenade = undefined;
	}
}

chugabud_give_loadout() 
{
	if(self.hasTombs == true){
		
		self thread maps\mp\zombies\_zm_perks::give_perk("specialty_scavenger");
		self.hasTombs = false;
	}	
	self takeallweapons();
	loadout = self.loadout;
	
	primaries = self getweaponslistprimaries();
	if ( loadout.weapons.size > 1 || primaries.size > 1 )
	{
		foreach ( weapon in primaries )
		{
			self takeweapon( weapon );
		}
	}
	i = 0;
	while ( i < loadout.weapons.size )
	{
		if ( !isDefined( loadout.weapons[ i ] ) )
		{
			i++;
			continue;
		}
		if ( loadout.weapons[ i ][ "name" ] == "none" )
		{
			i++;
			continue;
		}
		self maps\mp\zombies\_zm_weapons::weapondata_give( loadout.weapons[ i ] );
		i++;
	}
	if ( loadout.current_weapon >= 0 && isDefined( loadout.weapons[ loadout.current_weapon ][ "name" ] ) )
	{
		self switchtoweapon( loadout.weapons[ loadout.current_weapon ][ "name" ] );
	}
	self giveweapon( "knife_zm" );
	self maps\mp\zombies\_zm_equipment::equipment_give( self.loadout.equipment );
	loadout restore_weapons_for_chugabud( self );
	self chugabud_restore_claymore();
	self.score = loadout.score;
	self.pers[ "score" ] = loadout.score;
	perk_array = maps\mp\zombies\_zm_perks::get_perk_array( 1 );
	for ( i = 0; i < perk_array.size; i++ )
	{
		perk = perk_array[ i ];
		self unsetperk( perk );
		self.num_perks--;
		self set_perk_clientfield( perk, 0 );
	}
	if ( isDefined( loadout.perks ) && loadout.perks.size > 0 )
	{
		i = 0;
		while ( i < loadout.perks.size )
		{
			if ( self hasperk( loadout.perks[ i ] ) )
			{
				i++;
				continue;
			}
			else if ( loadout.perks[ i ] == "specialty_quickrevive" && flag( "solo_game" ) )
			{
				level.solo_game_free_player_quickrevive = 1;
			}
			if ( loadout.perks[ i ] == "specialty_finalstand" )
			{
				i++;
				continue;
			}
			else
			{
				maps\mp\zombies\_zm_perks::give_perk( loadout.perks[ i ] );
			}
			i++;
		}

	}

	self chugabud_restore_grenades();
	if ( maps\mp\zombies\_zm_weap_cymbal_monkey::cymbal_monkey_exists() )
	{
		if ( loadout.zombie_cymbal_monkey_count )
		{
			self maps\mp\zombies\_zm_weap_cymbal_monkey::player_give_cymbal_monkey();
			self setweaponammoclip( "cymbal_monkey_zm", loadout.zombie_cymbal_monkey_count );
		}
	}
	

}




chugabud_restore_grenades() 
{
	if ( isDefined( self.loadout.hasemp ) && self.loadout.hasemp )
	{
		self giveweapon( "emp_grenade_zm" );
		self setweaponammoclip( "emp_grenade_zm", self.loadout.empclip );
	}
	if ( isDefined( self.loadout.lethal_grenade ) )
	{
		self giveweapon( self.loadout.lethal_grenade );
		self setweaponammoclip( self.loadout.lethal_grenade, self.loadout.lethal_grenade_count );
	}
}

chugabud_restore_claymore()
{
	if ( isDefined( self.loadout.hasclaymore ) && self.loadout.hasclaymore && !self hasweapon( "claymore_zm" ) )
	{
		self giveweapon( "claymore_zm" );
		self set_player_placeable_mine( "claymore_zm" );
		self setactionslot( 4, "weapon", "claymore_zm" );
		self setweaponammoclip( "claymore_zm", self.loadout.claymoreclip );
	}
}

chugabud_fake_death() 
{
	level notify( "fake_death" );
	self notify( "fake_death" );
	self takeallweapons();
	self allowstand( 0 );
	self allowcrouch( 0 );
	self allowprone( 1 );
	self.ignoreme = 1;
	self enableinvulnerability();
	wait 0.1;
	self freezecontrols( 1 );
	wait 0.9;
}

chugabud_fake_revive() 
{
	level notify( "fake_revive" );
	self notify( "fake_revive" );
	spawnpoint = chugabud_get_spawnpoint();
	if ( isDefined( level._chugabud_post_respawn_override_func ) )
	{
		self [[ level._chugabud_post_respawn_override_func ]]( spawnpoint.origin );
	}
	if ( isDefined( level.chugabud_force_corpse_position ) )
	{
		if ( isDefined( self.e_chugabud_corpse ) )
		{
			self.e_chugabud_corpse forceteleport( level.chugabud_force_corpse_position );
		}
		level.chugabud_force_corpse_position = undefined;
	}
	if ( isDefined( level.chugabud_force_player_position ) )
	{
		spawnpoint.origin = level.chugabud_force_player_position;
		level.chugabud_force_player_position = undefined;
	}
	self setorigin( spawnpoint.origin );
	self setplayerangles( spawnpoint.angles );
	self allowstand( 1 );
	self allowcrouch( 1 );
	self allowprone( 1 );
	self.ignoreme = 0;
	self setstance( "stand" );
	self freezecontrols( 0 );
	self giveweapon( "knife_zm" );
	self give_start_weapon( 1 );
	self.score = self.loadout.score;
	self.pers[ "score" ] = self.loadout.score;
	self giveweapon( "frag_grenade_zm" );
	self setweaponammoclip( "frag_grenade_zm", 2 );
	self chugabud_restore_claymore();
	wait 1;
	self disableinvulnerability();
}

chugabud_get_spawnpoint() 
{
	spawnpoint = undefined;
	if ( get_chugabug_spawn_point_from_nodes( self.origin, 500, 700, 64, 1 ) )
	{
		spawnpoint = level.chugabud_spawn_struct;
	}
	if ( !isDefined( spawnpoint ) )
	{
		if ( get_chugabug_spawn_point_from_nodes( self.origin, 100, 400, 64, 1 ) )
		{
			spawnpoint = level.chugabud_spawn_struct;
		}
	}
	if ( !isDefined( spawnpoint ) )
	{
		if ( get_chugabug_spawn_point_from_nodes( self.origin, 50, 400, 256, 0 ) )
		{
			spawnpoint = level.chugabud_spawn_struct;
		}
	}
	if ( !isDefined( spawnpoint ) )
	{
		spawnpoint = maps\mp\zombies\_zm::check_for_valid_spawn_near_team( self, 1 );
	}
	if ( !isDefined( spawnpoint ) )
	{
		match_string = "";
		location = level.scr_zm_map_start_location;
		if ( (location == "default" || location == "" ) && isdefined( level.default_start_location ) ) 
		{
			location = level.default_start_location;
		}
		match_string = level.scr_zm_ui_gametype + "_" + location;
		spawnpoints = [];
		structs = getstructarray( "initial_spawn", "script_noteworthy" );
		if ( isdefined( structs ) )
		{
			foreach ( struct in structs )
			{
				if ( isdefined( struct.script_string ) )
				{
					tokens = strtok( struct.script_string, " " );
					i = 0;
					while ( i < tokens.size )
					{
						if ( tokens[ i ] == match_string )
						{
							spawnpoints[ spawnpoints.size ] = struct;
						}
						i++;
					}
				}
			}
		}
		if ( !isDefined( spawnpoints ) || spawnpoints.size == 0 )
		{
			spawnpoints = getstructarray( "initial_spawn_points", "targetname" );
		}
		/*
/#
		assert( isDefined( spawnpoints ), "Could not find initial spawn points!" );
#/
		*/
		spawnpoint = maps\mp\zombies\_zm::getfreespawnpoint( spawnpoints, self );
	}

	return spawnpoint;
}

get_chugabug_spawn_point_from_nodes( v_origin, min_radius, max_radius, max_height, ignore_targetted_nodes )
{
	if ( !isDefined( level.chugabud_spawn_struct ) )
	{
		level.chugabud_spawn_struct = spawnstruct();
	}
	found_node = undefined;
	a_nodes = getnodesinradiussorted( v_origin, max_radius, min_radius, max_height, "pathnodes" );
	if ( isDefined( a_nodes ) && a_nodes.size > 0 )
	{
		a_player_volumes = getentarray( "player_volume", "script_noteworthy" );
		index = a_nodes.size - 1;
		i = index;
		while ( i >= 0 )
		{
			n_node = a_nodes[ i ];
			if ( ignore_targetted_nodes == 1 )
			{
				if ( isDefined( n_node.target ) )
				{
					i--;
					continue;
				}
			}
			if ( !positionwouldtelefrag( n_node.origin ) )
			{
				if ( maps\mp\zombies\_zm_utility::check_point_in_enabled_zone( n_node.origin, 1, a_player_volumes ) )
				{
					v_start = ( n_node.origin[ 0 ], n_node.origin[ 1 ], n_node.origin[ 2 ] + 30 );
					v_end = ( n_node.origin[ 0 ], n_node.origin[ 1 ], n_node.origin[ 2 ] - 30 );
					trace = bullettrace( v_start, v_end, 0, undefined );
					if ( trace[ "fraction" ] < 1 )
					{
						override_abort = 0;
						if ( isDefined( level._chugabud_reject_node_override_func ) )
						{
							override_abort = [[ level._chugabud_reject_node_override_func ]]( v_origin, n_node );
						}
						if ( !override_abort )
						{
							found_node = n_node;
							break;
						}
					}
				}
			}
			i--;
		}
	}
	if ( isDefined( found_node ) )
	{
		level.chugabud_spawn_struct.origin = found_node.origin;
		v_dir = vectornormalize( v_origin - level.chugabud_spawn_struct.origin );
		level.chugabud_spawn_struct.angles = vectorToAngles( v_dir );
		return 1;
	}
	return 0;
}

force_corpse_respawn_position( forced_corpse_position )
{
	level.chugabud_force_corpse_position = forced_corpse_position;
}

force_player_respawn_position( forced_player_position ) 
{
	level.chugabud_force_player_position = forced_player_position;
}

save_weapons_for_chugabud( player ) //checked changed to match cerberus output
{
	self.chugabud_melee_weapons = [];
	for ( i = 0; i < level._melee_weapons.size; i++ )
	{
		self save_weapon_for_chugabud( player, level._melee_weapons[ i ].weapon_name );
	}
}

save_weapon_for_chugabud( player, weapon_name ) 
{
	if ( player hasweapon( weapon_name ) )
	{
		self.chugabud_melee_weapons[ weapon_name ] = 1;
	}
}

restore_weapons_for_chugabud( player ) 
{
	for ( i = 0; i < level._melee_weapons.size; i++ )
	{
		self restore_weapon_for_chugabud( player, level._melee_weapons[ i ].weapon_name );
	}
	self.chugabud_melee_weapons = undefined;
}

restore_weapon_for_chugabud( player, weapon_name ) 
{
	if ( !isDefined( weapon_name ) || !isDefined( self.chugabud_melee_weapons ) || !isDefined( self.chugabud_melee_weapons[ weapon_name ] ) )
	{
		return;
	}
	if ( isDefined( self.chugabud_melee_weapons[ weapon_name ] ) && self.chugabud_melee_weapons[ weapon_name ] )
	{
		player giveweapon( weapon_name );
		player set_player_melee_weapon( weapon_name );
		self.chugabud_melee_weapons[ weapon_name ] = 0;
	}
}

chugabud_save_perks( ent ) 
{
	perk_array = ent get_perk_array( 1 );
	foreach ( perk in perk_array )
	{
		ent unsetperk( perk );
	}
	return perk_array;
}







playchugabudtimeraudio() 
{
	self endon( "chugabud_grabbed" );
	self endon( "chugabud_timedout" );
	player = self.player;
	self thread playchugabudtimerout( player );
	while ( 1 )
	{
		player playsoundtoplayer( "zmb_chugabud_timer_count", player );
		wait 1;
	}
}

playchugabudtimerout( player )
{
	self endon( "chugabud_grabbed" );
	self waittill( "chugabud_timedout" );
	player playsoundtoplayer( "zmb_chugabud_timer_out", player );
}

chugabud_hostmigration() 
{
	level endon( "end_game" );
	level notify( "chugabud_hostmigration" );
	level endon( "chugabud_hostmigration" );
	while ( 1 )
	{
		level waittill( "host_migration_end" );
		chugabuds = getentarray( "player_chugabud_model", "script_noteworthy" );
	}
}

player_revived_cleanup_chugabud_corpse() 
{
}

player_has_chugabud_corpse() 
{
	if ( isDefined( self.e_chugabud_corpse ) )
	{
		return 1;
	}
	return 0;
}

is_weapon_available_in_chugabud_corpse( weapon, player_to_check ) 
{
	count = 0;
	upgradedweapon = weapon;
	if ( isDefined( level.zombie_weapons[ weapon ] ) && isDefined( level.zombie_weapons[ weapon ].upgrade_name ) )
	{
		upgradedweapon = level.zombie_weapons[ weapon ].upgrade_name;
	}
	players = getplayers();
	if ( isDefined( players ) )
	{
		player_index = 0;
		while ( player_index < players.size )
		{
			player = players[ player_index ];
			if ( isDefined( player_to_check ) && player != player_to_check )
			{
				player_index++;
				continue;
			}
			if ( player player_has_chugabud_corpse() )
			{
				if ( isDefined( player.loadout ) && isDefined( player.loadout.weapons ) )
				{
					for ( i = 0; i < player.loadout.weapons.size; i++ )
					{
						chugabud_weapon = player.loadout.weapons[ i ];
						if ( isDefined( chugabud_weapon ) && chugabud_weapon[ "name" ] == weapon || chugabud_weapon[ "name" ] == upgradedweapon )
						{
							count++;
						}
					}
				}
			}
			player_index++;
		}
	}
	return count;
}

chugabud_corpse_cleanup_on_spectator( player ) 
{
	self endon( "death" );
	player endon( "disconnect" );
	while ( 1 )
	{
		if ( player.sessionstate == "spectator" )
		{
			break;
		}
		wait 0.01;
	}
	player chugabud_corpse_cleanup( self, 0 );
}

chugabud_corpse_revive_icon( player ) 
{
	self endon( "death" );
	height_offset = 30;
	index = player.clientid;
	hud_elem = newhudelem();
	self.revive_hud_elem = hud_elem;
	hud_elem.x = self.origin[ 0 ];
	hud_elem.y = self.origin[ 1 ];
	hud_elem.z = self.origin[ 2 ] + height_offset;
	hud_elem.alpha = 1;
	hud_elem.archived = 1;
	hud_elem setshader( "waypoint_revive", 5, 5 );
	hud_elem setwaypoint( 1 );
	hud_elem.hidewheninmenu = 1;
	hud_elem.immunetodemogamehudsettings = 1;
	while ( 1 )
	{
		if ( !isDefined( self.revive_hud_elem ) )
		{
			break;
		}
		hud_elem.x = self.origin[ 0 ];
		hud_elem.y = self.origin[ 1 ];
		hud_elem.z = self.origin[ 2 ] + height_offset;
		wait 0.01;
	}
}

activate_chugabud_effects_and_audio() 
{
	self useServerVisionSet(true);
	self SetVisionSetforPlayer("zombie_turned", 0);
	self playsoundtoplayer( "tst_test_system", self );
	self thread deactivate_chugabud_effects_and_audio();
}

deactivate_chugabud_effects_and_audio() //checked matches cerberus output
{	
	self waittill_any( "death", "chugabud_effects_cleanup", "spawned_player" );
	self useservervisionset( 0 );
	self setvisionsetforplayer( "default", 0 );
}