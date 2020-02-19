/* TODO
Show-off Video:
	Show Features:
		Ragdolls
		Settings System
		Scoreboard
		Damage Falloff
		Respawning Items
		

General:
	https://www.gamemaps.com/details/15781 Check out for ideas
	Add support for maps (props, blockers, etc), then have spawn files
	Add spectator mode
	Improve placing tools
	
	Maps to make: Swamp Fever 5, No Mercy 1, No Mercy 5, Hard Rain 5, Dark Carnival 5, Dead Center 2, Parish 1, first maps
	
	Make recommended settings and command to reset to recommended settings (with a backup)?
	Make music system?
	Melee weapons?
	Add in-game small scoreboard?
	Call UpdateHUDTable(hudTable) in any hud changing functions to update instantly?
	Add language files?
	Different modes (2v2, no respawns)?
	More than 4 players?
	
Useful Info:
	Can stop all votes by setting m_activeIssueIndex on vote_controller to any positive integer
	HUD elements have a character limit

Changelog:
	v1.0.1
*/

IncludeScript("response_testbed")

PrecacheEntityFromTable({classname = "weapon_rifle_sg552"})
PrecacheEntityFromTable({classname = "weapon_smg_mp5"})
PrecacheEntityFromTable({classname = "weapon_sniper_awp"})
PrecacheEntityFromTable({classname = "weapon_sniper_scout"})


const INTEGER_MAX = 2147483647
const INTEGER_MIN = -2147483648

const TAB = "    "
const DOUBLE_TAB = "        "
const TRIPLE_TAB = "            "
const QUADRUPLE_TAB = "                "

const VOTE_CHANGE_DIFFICULTY = 0
const VOTE_RESTART_CAMPAIGN = 1
const VOTE_KICK = 2
const VOTE_CHANGE_CAMPAIGN = 3

const GRENADE_LAUNCHER_DAMAGETYPE = 16777280
const EXPLOSIVE_DAMAGETYPE = 134217792
const INFERNO_DAMAGETYPE = 2056
const FALL_DAMAGETYPE = 32

const DAMAGE_FALLOFF_UNITS = 1000 // damage reduction per this amount of units, the lower the falloff, the less damage is decreased

const PROPANETANK_MODEL = "models/props_junk/propanecanister001a.mdl"
const OXYGENTANK_MODEL = "models/props_equipment/oxygentank01.mdl"


class ConvarManager {
	constructor(convars){
		this.convars = convars
		if("HookController" in g_ModeScript){
			g_ModeScript.HookController.RegisterOnTick(this)
		}
	}
	
	function Enable(){
		enabled = true
	}
	
	function Disable(){
		enabled = false
	}
	
	function OnTick(){
		if(enabled){
			foreach(table in convars){
				if("name" in table){
					if("value" in table){
						Convars.SetValue(table["name"], table["value"])
					} else if("setting" in table){
						Convars.SetValue(table["name"], g_ModeScript.Game.GetSetting(table["setting"]))
					}
				}
			}
		}
	}
	
	convars = []
	enabled = true
}

class ItemManager {
	constructor(){
		g_ModeScript.HookController.RegisterHooks(this)
	}
	
	
	function Enable(){
		enabled = true
	}
	
	function Disable(){
		enabled = false
	}
	
	function SpawnItem(spawn){
		if(spawn.GetWeaponName().len() > 6 && spawn.GetWeaponName().slice(0, 6) == "melee_"){
			spawn.SetWeapon(g_ModeScript.SpawnMeleeWeapon(spawn.GetWeaponName().slice(6), spawn.GetOrigin(), QAngle(0, 0, 0)))
		} else {
			if(spawn.GetWeaponName() == "gnome"){
				spawn.SetWeapon(SpawnEntityFromTable("weapon_gnome", {origin = spawn.GetOrigin(), spawnflags = 2}))
				spawn.GetWeapon().SetGlowType(3)
				spawn.GetWeapon().SetGlowRange(9999999)
				spawn.GetWeapon().SetGlowColor(1, 0, 0)
			} else if(spawn.GetWeaponName() == "propanetank") {
				spawn.SetWeapon(SpawnEntityFromTable("prop_physics", {origin = spawn.GetOrigin(), spawnflags = 2, model = PROPANETANK_MODEL}))
			} else if(spawn.GetWeaponName() == "oxygentank"){
				spawn.SetWeapon(SpawnEntityFromTable("prop_physics", {origin = spawn.GetOrigin(), spawnflags = 2, model = OXYGENTANK_MODEL}))
			} else {
				spawn.SetWeapon(SpawnEntityFromTable("weapon_" + spawn.GetWeaponName(),{origin = spawn.GetOrigin()}))
			}
		}
		spawn.GetWeapon().SetAngles(spawn.GetAngles())
		spawn.SetPickedUp(false)
		//NetProps.SetPropInt(spawn.GetWeapon(), )
		spawn.GetWeapon().SetMoveType(0)
		if(g_ModeScript.Game.GetSetting(spawn.GetWeaponName() + "_clip_only") == 1){
			spawn.GetWeapon().SetClip(g_ModeScript.Game.GetWeaponSpawnAmmo(spawn.GetWeaponName()))
		} else {
			local ammo = g_ModeScript.Game.GetWeaponSpawnAmmo(spawn.GetWeaponName()) - spawn.GetWeapon().GetClip()
			if(ammo < 0){
				spawn.GetWeapon().SetClip(g_ModeScript.Game.GetWeaponSpawnAmmo(spawn.GetWeaponName()))
			} else {
				spawn.GetWeapon().SetReserveAmmo(ammo)
			}
		}
	}

	function SpawnAllItems(){
		foreach(spawn in g_ModeScript.DeathmatchItemSpawns){
			SpawnItem(spawn)
		}
	}
	
	function RespawnItems(){
		foreach(spawn in g_ModeScript.DeathmatchItemSpawns){
			if(spawn.GetPickedUp() && Time() >= spawn.GetPickupTime() + g_ModeScript.Game.GetWeaponRespawnTime(spawn.GetWeaponName())){
				SpawnItem(spawn)
			}
		}
	}
	
	function CleanupDroppedItems(){
		for(local i=0; i < droppedWeapons.len(); i+=1){
			local weapon = droppedWeapons[i]
			if(weapon != null && weapon.IsValid()){
				if(Time() >= weapon.GetScriptScope()["dropTime"] + g_ModeScript.Game.GetSetting("dropped_weapon_remove_time")){
					weapon.GetScriptScope()["alpha"] <- 255
					weapon.GetScriptScope()["pickupDisabled"] <- true
					weapon.SetSpawnFlags(2)
					weapon.SetPropInt("m_nRenderMode", 1)
					weapon.SetGlowType(3)
					weapon.SetGlowRange(999999)
					weapon.SetGlowColor(1, 0, 0)
					fadingWeapons.append(weapon)
				}
			} else {
				droppedWeapons.remove(i)
				i -= 1
			}
		}
	}
	
	function CleanupFadingItems(){
		for(local i=0; i < fadingWeapons.len(); i++){
			local weapon = fadingWeapons[i]
			if(weapon != null && weapon.IsValid()){
				weapon.GetScriptScope()["alpha"] = weapon.GetScriptScope()["alpha"] - 4.25
				if(weapon.GetScriptScope()["alpha"] > 0){
					weapon.SetAlpha(weapon.GetScriptScope()["alpha"])
				} else {
					weapon.Kill()
					fadingWeapons.remove(i)
				}
			} else {
				fadingWeapons.remove(i)
			}
		}
	}
	
	function CleanupAllItems(){
		foreach(ent in ::HookController.EntitiesByClassname("weapon_*")){
			ent.ValidateScriptScope()
			if(!("no_cleanup" in ent.GetScriptScope())){
				ent.Kill()
			}
		}
		foreach(ent in ::HookController.EntitiesByModel(PROPANETANK_MODEL)){
			ent.Kill()
		}
		foreach(ent in ::HookController.EntitiesByModel(OXYGENTANK_MODEL)){
			ent.Kill()
		}
	}
	
	function CleanupAllDeathmatchItems(){
		foreach(weapon in fadingWeapons){
			weapon.Kill()
		}
		foreach(weapon in droppedWeapons){
			weapon.Kill()
		}
		foreach(weapon in g_ModeScript.DeathmatchItemSpawns){
			weapon.GetWeapon().Kill()
			weapon.SetPickedUp(true)
		}
	}
	
	function WeaponDropped(weapon){
		weapon.ValidateScriptScope()
		weapon.GetScriptScope()["dropTime"] <- Time()
		droppedWeapons.append(weapon)
	}
	
	function OnTick(){
		if(enabled){
			foreach(spawn in g_ModeScript.DeathmatchItemSpawns){
				if(!spawn.GetPickedUp() && (spawn.GetWeapon() == null || !spawn.GetWeapon().IsValid())){
					spawn.SetPickedUp(true)
					spawn.SetPickupTime(Time())
				}
			}
			
			CleanupDroppedItems()
			CleanupFadingItems()
			RespawnItems()
		}
	}
	
	function OnInventoryChange(ent, removedWeapons, newWeapons){
		foreach(weapon in newWeapons){
			foreach(spawn in g_ModeScript.DeathmatchItemSpawns){
				if(weapon == spawn.GetWeapon() && !spawn.GetPickedUp()){
					spawn.SetPickedUp(true)
					spawn.SetPickupTime(Time())
				}
			}
			weapon.ValidateScriptScope()
			for(local i=0; i<droppedWeapons.len(); i+=1){
				if(droppedWeapons[i] == weapon){
					delete weapon.GetScriptScope()["dropTime"]
					droppedWeapons.remove(i)
					i -= 1
				}
			}
		}
		
		foreach(weapon in removedWeapons){
			if(weapon != null && weapon.IsValid()){
				WeaponDropped(weapon)
			}
		}
	}
	
	fadingWeapons = []
	droppedWeapons = []
	enabled = true
}

class PlayerManager {
	constructor(){
		g_ModeScript.HookController.RegisterOnTick(this)
	}
	
	function Enable(){
		enabled = true
	}
	
	function Disable(){
		enabled = false
	}
	
	function HandleRespawn(player){
		if(player.IsRespawning() && Time() >= player.GetRespawnEnd()){
			player.EndRespawn()
		}
	}
	
	function HandleGivingPistol(ent){
		if(!g_ModeScript.Game.IsStarted()){
			local invTable = {}
			GetInvTable(ent, invTable)
			if(!("slot1" in invTable)){
				ent.GiveItem("pistol")
			}
		}
	}
	
	function HandleAmmoPickup(player){
		local playerEnt = player.GetEntity()
		
		if(("pickupDisabled" in playerEnt.GetScriptScope() && playerEnt.GetScriptScope()["pickupDisabled"]) || player.IsRespawning()){
			return
		}
		
		local invTable = {}
		GetInvTable(playerEnt, invTable)
		for(local i=0; i <= 1; i++){
			if(("slot" + i) in invTable){
				foreach(ent in ::HookController.EntitiesByClassnameWithin(invTable["slot" + i].GetClassname(), playerEnt.GetOrigin(), g_ModeScript.Game.GetSetting("weapon_pickup_radius"))){
					ent.ValidateScriptScope()
					if(ent != invTable["slot" + i]){
						local traceTable = {
							start = playerEnt.EyePosition()
							end = ent.GetOrigin()
							ignore = playerEnt
						}
						TraceLine(traceTable)
						if(traceTable["hit"] && traceTable["enthit"] != Entities.FindByClassname(null,"worldspawn") && traceTable["enthit"] == ent){
							player.PickupAmmo(ent, invTable["slot" + i])
						}
					}
				}
			}
		}
	}
	
	function HandleShovingDisable(ent){
		if(ent != null && ent.GetActiveWeapon() != null && ent.GetActiveWeapon().IsValid()){
			local classname = ent.GetActiveWeapon().GetClassname()
			if(classname == "weapon_first_aid_kit" || classname == "weapon_adrenaline" || classname == "weapon_pain_pills"){
				ent.GetActiveWeapon().SetPropFloat("m_flNextSecondaryAttack", INTEGER_MAX)
			} else {
				ent.GetActiveWeapon().SetPropFloat("m_flNextSecondaryAttack", 0)
			}
		}
	}
	
	function HandleSpawningFromDead(player){
		if(player.GetEntity().IsDead() && player.GetEntity().GetPropInt("m_lifeState") != 2){
			player.SpawnFromDead()
		}
	}
	
	function HandleMeleeBoost(ent){
		if(ent.GetActiveWeapon() != null && (ent.GetActiveWeapon().GetClassname() == "weapon_melee" || ent.GetActiveWeapon().GetClassname() == "weapon_chainsaw")){
			ent.UseAdrenaline(0.034)
		}
	}
	
	function OnTick(){
		if(enabled){
			foreach(ent in ::HookController.PlayerGenerator()){ // Adds new players
				local player = g_ModeScript.FindPlayer(ent)
				if(player == null){
					g_ModeScript.DeathmatchPlayers.append(g_ModeScript.DeathmatchPlayer(ent))
					ent.Input("DisableLedgeHang")
				} else { // Handles current players
					HandleRespawn(player)
					HandleAmmoPickup(player)
					HandleGivingPistol(ent)
					HandleShovingDisable(ent)
					HandleSpawningFromDead(player)
					HandleMeleeBoost(ent)
				}
			}
			for(local i=0; i < g_ModeScript.DeathmatchPlayers.len(); i++){ // Removes invalid players
				if(!g_ModeScript.DeathmatchPlayers[i].IsValid()){
					g_ModeScript.DeathmatchPlayers.remove(i)
					i--
				}
			}
		}
	}

	enabled = true
}

class DeathmatchGame {
	function GetWeaponSpawnAmmo(weapon){
		return GetSetting(weapon + "_spawn_ammo")
	}
	
	function GetWeaponRespawnTime(weapon_name){
		return GetSetting(weapon_name + "_respawn_time")
	}

	function GetDamageModifier(weapon_name){
		return GetSetting(weapon_name + "_damage_modifier")
	}

	function GetHitgroupModifier(hitgroup){
		switch(hitgroup){
			case 1:{
				return GetSetting("head_multiplier")
			}
			case 2:{
				return GetSetting("neck_multiplier")
			}
			case 3:{
				return GetSetting("torso_multiplier")
			}
			default:{
				if(hitgroup >= 4 && hitgroup <= 7){
					return GetSetting("other_multiplier")
				}
				return 1
			}
		}
	}

	function GetDamageFalloff(weapon_name){
		if(weapon_name == null){
			return 0
		}
		
		if(weapon_name.find("weapon_") != null){
			return g_ModeScript.Game.GetSetting(weapon_name.slice("weapon_".len()) + "_damage_falloff")
		} else {
			return g_ModeScript.Game.GetSetting(weapon_name + "_damage_falloff")
		}
	}
	
	function GetScoreToWin(){
		return score_to_win
	}
	
	function SetScoreToWin(score){
		score_to_win = score
	}
	
	function Start(){
		started = true
	}
	
	function Stop(){
		started = false
	}
	
	function IsStarted(){
		return started
	}
	
	function SetCountdownStartTime(time){
		countdown_start_time = time
	}
	
	function GetCountdownStartTime(){
		return countdown_start_time
	}
	
	function SetCountdownStarted(bool){
		countdown_start = bool
	}
	
	function IsCountdownStarted(){
		return countdown_start
	}
	
	function SetEnabled(bool){
		enabled = bool
	}
	
	function IsEnabled(){
		return enabled
	}
	
	function SetSetting(settingName, value){
		if(settingName in settings){
			settings[settingName] = value
			return true
		} else {
			return false
		}
	}
	
	function GetSetting(settingName){
		if(settingName in settings){
			return settings[settingName]
		} else {
			return -1
		}
	}
	
	function GetSettings(){
		return settings
	}
	
	function SetMatchStart(time){
		match_start = time
	}
	
	function GetMatchStart(){
		return match_start
	}
	
	function SetMatchTimerStarted(bool){
		match_timer_started = bool
	}
	
	function IsMatchTimerStarted(){
		return match_timer_started
	}
	
	function SetGameStopTime(time){
		game_stop_time = time
	}
	
	function GetGameStopTime(){
		return game_stop_time
	}

	started = false
	enabled = true
	countdown_start = false
	match_timer_started = false
	
	countdown_start_time = 0
	game_stop_time = 0
	score_to_win = 15
	match_start = 0
	
	settings = {
		weapon_pickup_radius = 48
		
		regen_time = 5
		regen_interval = 0.1
		regen_amount = 1
		
		pipe_bomb_beep_interval_delta = 0.0425
		pipe_bomb_beep_min_interval = 0.07
		pipe_bomb_timer_duration = 3
		
		first_aid_heal_percent = 0.7
		first_aid_kit_use_duration = 3
		pain_pills_decay_rate = 0.75
		pain_pills_health_value = 30

		match_time = 300
		respawn_time = 5
		countdown_time = 5
		leaderboard_show_time = 15
		
		killfeed_timeout = 5

		head_multiplier = 2
		neck_multiplier = 1.5
		torso_multiplier = 1
		other_multiplier = 0.5

		autoshotgun_ammo_limit = 30
		shotgun_spas_ammo_limit = 30
		pumpshotgun_ammo_limit = 32
		shotgun_chrome_ammo_limit = 32
		sniper_military_ammo_limit = 60
		sniper_awp_ammo_limit = 20
		sniper_scout_ammo_limit = 30
		hunting_rifle_ammo_limit = 45
		rifle_ammo_limit = 150
		rifle_ak47_ammo_limit = 120
		rifle_desert_ammo_limit = 120
		rifle_sg552_ammo_limit = 150
		rifle_m60_ammo_limit = 100
		smg_ammo_limit = 150
		smg_mp5_ammo_limit = 150
		smg_silenced_ammo_limit = 150
		grenade_launcher_ammo_limit = 5
		pistol_ammo_limit = 15
		pistol_magnum_ammo_limit = 8
		chainsaw_ammo_limit = 5
		
		autoshotgun_spawn_ammo = 20
		shotgun_spas_spawn_ammo = 20
		pumpshotgun_spawn_ammo = 16
		shotgun_chrome_spawn_ammo = 16
		sniper_military_spawn_ammo = 20
		sniper_awp_spawn_ammo = 20
		sniper_scout_spawn_ammo = 20
		hunting_rifle_spawn_ammo = 30
		rifle_spawn_ammo = 100
		rifle_ak47_spawn_ammo = 80
		rifle_desert_spawn_ammo = 120
		rifle_sg552_spawn_ammo = 100
		rifle_m60_spawn_ammo = 50
		smg_spawn_ammo = 100
		smg_mp5_spawn_ammo = 100
		smg_silenced_spawn_ammo = 100
		grenade_launcher_spawn_ammo = 2
		pistol_spawn_ammo = 15
		pistol_magnum_spawn_ammo = 8
		chainsaw_spawn_ammo = 3
		molotov_spawn_ammo = 1
		pipe_bomb_spawn_ammo = 1

		/*autoshotgun_ragdoll_modifier = 1.5
		shotgun_spas_ragdoll_modifier = 1.5
		pumpshotgun_ragdoll_modifier = 1.5
		shotgun_chrome_ragdoll_modifier = 1.5
		sniper_awp_ragdoll_modifier = 3
		sniper_military_ragdoll_modifier = 1.5
		sniper_scout_ragdoll_modifier = 2
		hunting_rifle_ragdoll_modifier = 1.5
		rifle_ragdoll_modifier = 1
		rifle_ak47_ragdoll_modifier = 1
		rifle_desert_ragdoll_modifier = 1
		rifle_sg552_ragdoll_modifier = 1
		rifle_m60_ragdoll_modifier = 1
		smg_ragdoll_modifier = 1
		smg_mp5_ragdoll_modifier = 1
		smg_silenced_ragdoll_modifier = 1
		grenade_launcher_ragdoll_modifier = 2
		pipe_bomb_ragdoll_modifier = 2
		pistol_ragdoll_modifier = 1
		pistol_magnum_ragdoll_modifier = 1*/

		autoshotgun_damage_modifier = 1
		shotgun_spas_damage_modifier = 1
		pumpshotgun_damage_modifier = 1
		shotgun_chrome_damage_modifier = 1
		sniper_awp_damage_modifier = 5
		sniper_military_damage_modifier = 2.5
		sniper_scout_damage_modifier = 3
		hunting_rifle_damage_modifier = 2.5
		rifle_damage_modifier = 1
		rifle_ak47_damage_modifier = 1
		rifle_desert_damage_modifier = 1
		rifle_sg552_damage_modifier = 1
		rifle_m60_damage_modifier = 2
		smg_damage_modifier = 1
		smg_mp5_damage_modifier = 1
		smg_silenced_damage_modifier = 1
		grenade_launcher_damage_modifier = 5
		pistol_damage_modifier = 1
		pistol_magnum_damage_modifier = 2
		chainsaw_damage_modifier = 3
		melee_damage_modifier = 4
		
		explosive_damage_modifier = 7.5
		fire_damage_modifier = 15
		
		autoshotgun_ammo_pickup_modifier = 0.5
		shotgun_spas_ammo_pickup_modifier = 0.5
		pumpshotgun_ammo_pickup_modifier = 0.5
		shotgun_chrome_ammo_pickup_modifier = 0.5
		sniper_awp_ammo_pickup_modifier = 0.5
		sniper_military_ammo_pickup_modifier = 0.5
		sniper_scout_ammo_pickup_modifier = 0.5
		hunting_rifle_ammo_pickup_modifier = 0.5
		rifle_ammo_pickup_modifier = 0.5
		rifle_ak47_ammo_pickup_modifier = 0.5
		rifle_desert_ammo_pickup_modifier = 0.5
		rifle_sg552_ammo_pickup_modifier = 0.5
		rifle_m60_ammo_pickup_modifier = 0.5
		smg_ammo_pickup_modifier = 0.5
		smg_mp5_ammo_pickup_modifier = 0.5
		smg_silenced_ammo_pickup_modifier = 0.5
		grenade_launcher_ammo_pickup_modifier = 0.5
		pistol_ammo_pickup_modifier = 1
		pistol_magnum_ammo_pickup_modifier = 1
		chainsaw_ammo_pickup_modifier = 0.5
		
		// damage reduction per 1000 units, the lower the falloff, the less damage is decreased
		autoshotgun_damage_falloff = 0.5
		shotgun_spas_damage_falloff = 0.5
		pumpshotgun_damage_falloff = 0.5
		shotgun_chrome_damage_falloff = 0.5
		sniper_awp_damage_falloff = 0.05
		sniper_military_damage_falloff = 0.1
		sniper_scout_damage_falloff = 0.125
		hunting_rifle_damage_falloff = 0.15
		rifle_damage_falloff = 0.25
		rifle_ak47_damage_falloff = 0.175
		rifle_desert_damage_falloff = 0.25
		rifle_sg552_damage_falloff = 0.225
		rifle_m60_damage_falloff = 0.3
		smg_damage_falloff = 0.45
		smg_mp5_damage_falloff = 0.45
		smg_silenced_damage_falloff = 0.5
		pistol_damage_falloff = 0.4
		pistol_magnum_damage_falloff = 0.3
		
		autoshotgun_respawn_time = 15
		shotgun_spas_respawn_time = 15
		pumpshotgun_respawn_time = 15
		shotgun_chrome_respawn_time = 15
		sniper_awp_respawn_time = 15
		sniper_military_respawn_time = 15
		sniper_scout_respawn_time = 15
		hunting_rifle_respawn_time = 15
		rifle_respawn_time = 15
		rifle_ak47_respawn_time = 15
		rifle_desert_respawn_time = 15
		rifle_sg552_respawn_time = 15
		rifle_m60_respawn_time = 15
		smg_respawn_time = 15
		smg_mp5_respawn_time = 15
		smg_silenced_respawn_time = 15
		grenade_launcher_respawn_time = 15
		pipe_bomb_respawn_time = 15
		molotov_respawn_time = 15
		pistol_respawn_time = 15
		pistol_magnum_respawn_time = 15
		adrenaline_respawn_time = 15
		pain_pills_respawn_time = 15
		first_aid_kit_respawn_time = 15
		chainsaw_respawn_time = 15
		gascan_respawn_time = 30
		propanetank_respawn_time = 30
		oxygentank_respawn_time = 30
		
		melee_katana_respawn_time = 30
		
		chainsaw_clip_only = 1
		rifle_m60_clip_only = 1
		
		fall_damage_modifier = 0.25
		
		no_shotgun_hitgroup_modifier = 1

		damage = 10
		
		respawn_minimum_distance = 250 // Spawns must be this far from players to be eligible for other players to spawn
		
		percentage_to_start = 75
		percentage_to_stop = 75
		percentage_to_change_level = 75
		
		max_health = 100
		
		dropped_weapon_remove_time = 15
		
		//self_damage_modifer = 0.5
	}
}

class g_ModeScript.DeathmatchPlayer {
	viewcontroller = null
	entity = null
	ragdoll = null
	
	currentKiller = null
	
	last_weapons = null
	last_attacker = null
	last_attack_weapon_name = null
	last_attack_weapon = null
	last_velocity = null
	
	map_vote = null
	voted_to_start = false
	voted_to_stop = false
	respawning = false
	
	last_damaged = 0
	kills = 0
	deaths = 0
	respawn_end = 0
	armor = 0
	
	constructor(ent){
		entity = ent
		viewcontroller = SpawnEntityFromTable("point_viewcontrol", {acceleration = 99999,targetattachment = "eyes", spawnflags = 40})
	}

	function IsValid(){
		return entity != null && entity.IsValid()
	}
	
	function SetNewHealth(attacker, damage, type){
		local ent = GetEntity()
		local player = g_ModeScript.FindPlayer(ent)
		local health = ent.GetHealth()
		local temp_health = ent.GetHealthBuffer()
		
		if(health + temp_health - damage < 1){
			player.Kill(attacker, type == INFERNO_DAMAGETYPE)
		} else {
			if(temp_health - damage >= 0){
				ent.SetHealthBuffer(temp_health - damage)
			} else {
				ent.SetHealthBuffer(0)
				ent.SetHealth(health + temp_health - damage)
			}
		}
	}
	
	function Kill(killer, killedByFire = false){
		SetCurrentKiller(killer)
		
		local ent = GetEntity()
		
		if(ent.GetActiveWeapon() != null){
			for(local i = 0; i < 10; i++){
				if(ent.GetPropEntityArray("m_hMyWeapons", i) != null){
					ent.SetAmmo(ent.GetPropEntityArray("m_hMyWeapons", i), 0)
				}
			}
		}
		
		ent.PlaySound("Player.StopVoice")
		
		ent.SetPropInt("m_iCurrentUseAction", 0)
		
		EmitSoundOnClient("Hint.LittleReward", killer)
		
		local useActionTarget = ent.GetPropEntity("m_useActionTarget")
		if(useActionTarget){
			ent.SetPropEntity("m_useActionTarget", null)
			useActionTarget.SetPropEntity("m_useActionOwner", null)
		}
		
		//ent.AddFlag(64)
		
		if(ent.GetPropInt("m_bAdrenalineActive")){
			ent.UseAdrenaline(0)
		}
		//ent.SetPropInt("m_bAdrenalineActive", 0)
		ent.SetPropEntity("m_hZoomOwner", null)
		ent.SetPropEntity("m_hUseEntity", null)
		
		ent.SetPropInt("m_usingMountedGun", 0)
		ent.SetPropInt("m_usingMountedWeapon", 0)
		
		ent.SetPropInt("m_iFOV", 0)
		
		DropWeapons()
		SetDead()
		
		GetViewcontrollerEntity().SetOrigin(ent.EyePosition())
		if(killer != null && killer != Entities.FindByClassname(null, "worldspawn") && killer != ent && killer.GetClassname() != "trigger_hurt"){
			killer.SetName(UniqueString())
			GetViewcontrollerEntity().Input("AddOutput","target " + killer.GetName())
		} else {
			GetViewcontrollerEntity().Input("AddOutput","target " + UniqueString())
		}
		EnableViewcontroller()
		
		local ragdollEnt = SpawnRagdoll()
		
		if(killedByFire){
			ragdollEnt.SetPropInt("m_bOnFire", 1)
		}
		
		if(killer == null || !killer.IsValid() || killer == Entities.FindByClassname(null, "worldspawn") || ent == killer || killer.GetClassname() != "player"){
			GetViewcontrollerEntity().SetAngles(ent.EyeAngles())
		} else {
			GetViewcontrollerEntity().SetAngles(g_ModeScript.FindAngleBetweenPoints(ent.EyePosition(), killer.EyePosition()))
		}
		
		ragdollEnt.SetAngles(ent.EyeAngles())
		
		if((killer != null && killer == Entities.FindByClassname(null,"worldspawn")) || killer == null || killer.GetClassname() != "player"){
			g_ModeScript.DeathmatchKillfeed.AddKillfeedLine("World ⇒ " + ent.GetPlayerName(), g_ModeScript.Game.GetSetting("killfeed_timeout"))
		} else {
			g_ModeScript.DeathmatchKillfeed.AddKillfeedLine(killer.GetPlayerName() + " ⇒ " + ent.GetPlayerName(), g_ModeScript.Game.GetSetting("killfeed_timeout"))
		}
		
		if(killer != null && killer != Entities.FindByClassname(null,"worldspawn") && killer.GetClassname() == "player"){
			local killerPlayer = g_ModeScript.FindPlayer(killer)
			if(killerPlayer != null && killer != ent){
				killerPlayer.IncreaseKills()
			}
		}
		IncreaseDeaths()
		StartRespawn()
	}
	
	function PickupAmmo(weapon, playerWeapon){
		local weapon_name = g_ModeScript.RemoveSubstring(weapon.GetClassname(), "weapon_")
		local clipOnly = g_ModeScript.Game.GetSetting(weapon_name + "_clip_only") == 1
		
		local clip = 0
		if(!clipOnly){
			clip = playerWeapon.GetClip()
		}
		local max_ammo = g_ModeScript.Game.GetSetting(weapon_name + "_ammo_limit") - clip
		local player_ammo = 0
		local weapon_ammo = 0
		if(clipOnly){
			player_ammo = playerWeapon.GetClip()
			weapon_ammo = weapon.GetClip()
		} else {
			player_ammo = entity.GetAmmo(weapon)
			weapon_ammo = weapon.GetReserveAmmo() + weapon.GetClip()
		}
		
		if(player_ammo >= max_ammo){
			return
		}
		
		local ammo = player_ammo + ((weapon_ammo) * g_ModeScript.Game.GetSetting(weapon_name + "_ammo_pickup_modifier"))
		
		ammo = ammo > max_ammo ? max_ammo : ammo
		ammo = ceil(ammo)
		
		printl("Player ammo: " + player_ammo)
		printl("Weapon ammo: " + weapon_ammo)
		printl("Max ammo: " + max_ammo)
		printl("Clip: " + clip)
		printl("Ammo: " + ammo)
		
		if(clipOnly){
			playerWeapon.SetClip(ammo)
		} else {
			entity.SetAmmo(weapon, ammo)
		}
		
		entity.PlaySoundOnClient("BaseCombatCharacter.AmmoPickup")
		foreach(spawn in g_ModeScript.DeathmatchItemSpawns){
			if(spawn.GetWeapon() == weapon){
				spawn.SetPickedUp(true)
				spawn.SetPickupTime(Time())
			}
		}
		weapon.Kill()
	}
	
	function DropWeapons(){
		local playerEnt = entity
		
		local invTable = {}
		GetInvTable(playerEnt, invTable)
		for(local i=0; i <= 5; i++){
			if(("slot" + i) in invTable){
				local ent = invTable["slot" + i]
				if(i == 0){
					local dropped_weapon = SpawnEntityFromTable(ent.GetClassname(),{origin = (playerEnt.EyePosition())})
					dropped_weapon.SetPropInt("m_upgradeBitVec", ent.GetPropInt("m_upgradeBitVec"))
					dropped_weapon.SetPropInt("m_nUpgradedPrimaryAmmoLoaded", ent.GetPropInt("m_nUpgradedPrimaryAmmoLoaded"))
					dropped_weapon.SetReserveAmmo(playerEnt.GetAmmo(ent))
					dropped_weapon.ValidateScriptScope()
					dropped_weapon.SetClip(ent.GetClip())
					dropped_weapon.GetValidatedScriptScope()["drop_time"] <- Time()
					g_ModeScript.DeathmatchItemManager.WeaponDropped(dropped_weapon)
					dropped_weapon.SetVelocity(entity.GetVelocity())
					ent.Kill()
				} else if(i == 1 && ent.GetClassname() == "weapon_chainsaw"){
					ent.StopSound("Chainsaw.Idle")
					ent.StopSound("Chainsaw.Start")
					ent.Kill()
				} else {
					ent.Kill()
				}
			}
		}
		if("Held" in invTable){
			invTable["Held"].Kill()
		}
	}
	
	function ResetHealth(){
		entity.SetReviveCount(0)
		entity.SetHealth(g_ModeScript.Game.GetSetting("max_health"))
		entity.SetHealthBuffer(0)
		entity.ReviveFromIncap()
	}
	
	function SpawnFromDead(){
		local ent = entity
		local character = ent.GetPropInt("m_survivorCharacter")
		
		if(character > 7){
			local l4d2Characters = true
			local availableL4D2Characters = [0, 1, 2, 3]
			local availableL4D1Characters = [4, 5, 6, 7]
			
			foreach(survivor in HookController.EntitiesByClassname("player")){
				if(survivor.IsSurvivor() && survivor != ent){
					if(availableL4D1Characters.find(survivor.GetPropInt("m_survivorCharacter"))){
						l4d2Characters = false
					}
					if(l4d2Characters){
						local characterIndex = availableL4D2Characters.find(survivor.GetPropInt("m_survivorCharacter"))
						availableL4D2Characters.remove(characterIndex)
					} else {
						local characterIndex = availableL4D1Characters.find(survivor.GetPropInt("m_survivorCharacter"))
						availableL4D1Characters.remove(characterIndex)
					}
				}
			}
			
			if(l4d2Characters){
				character = availableL4D2Characters[RandomInt(0, availableL4D2Characters.len() - 1)]
			} else {
				character = availableL4D1Characters[RandomInt(0, availableL4D1Characters.len() - 1)]
			}
		}
		
		local origin = g_ModeScript.DeathmatchInitialPlayerSpawns[RandomInt(0, g_ModeScript.DeathmatchInitialPlayerSpawns.len() - 1)].GetOrigin()
		
		if(g_ModeScript.Game.IsStarted()){
			origin = g_ModeScript.GetRandomSpawn().GetOrigin()
		}
		
		local deathModel = SpawnEntityFromTable("survivor_death_model", {origin = origin})
		ent.SetPropInt("m_survivorCharacter", character)
		deathModel.SetPropInt("m_nCharacterType", character)
		ent.ReviveByDefib()
		ent.SetHealth(100)
	}
	
	function SpawnRagdoll(){
		local ragdollEnt = SpawnEntityFromTable("cs_ragdoll",{modelindex = entity.GetModelIndex(), origin = entity.GetOrigin()})
		ragdollEnt.SetPropEntity("m_hPlayer", entity)
		//NetProps.SetPropInt(ragdollEnt, "m_nForceBone", 1)
		//NetProps.SetPropInt(ragdollEnt, "m_iDeathFrame", 2)
		//NetProps.SetPropInt(ragdollEnt, "m_ragdollType", 4)
		//NetProps.SetPropInt(ragdollEnt, "m_bClientSideAnimation", 1)
		ragdoll = ragdollEnt
		return ragdoll
	}

	function StartRespawn(){ // Start the respawn state
		//entity.AddFlag(64)
		SetRespawning(true)
		SetRespawnEnd(Time() + g_ModeScript.Game.GetSetting("respawn_time"))
	}
	
	function EndRespawn(){ // End the respawn state
		entity.RemoveFlag(64)
		SetCurrentKiller(null)
		local spawn = g_ModeScript.GetRandomSpawn()
		entity.SetOrigin(spawn.GetOrigin())
		entity.SetAngles(spawn.GetAngles())
		SetRespawning(false)
		//entity.RemoveFlag(1 << 14)
		//NetProps.SetPropInt(ragdoll, "m_nRenderMode", 1)
		//DoEntFire("!self", "Alpha", "125", 0, null, ragdoll)
		ResetHealth()
		ragdoll.Kill()
		DisableViewcontroller()
		SetAlive()
		entity.GiveItem("pistol")
	}
	
	function IncreaseKills(){
		kills += 1
	}
	
	function SetKills(amount){
		kills = amount
	}
	
	function GetKills(){
		return kills
	}
	
	function IncreaseDeaths(){
		deaths += 1
	}
	
	function SetDeaths(amount){
		deaths = amount
	}
	
	function GetDeaths(){
		return deaths
	}
	
	function SetAlive(){
		entity.SetPropInt("m_lifeState",0)
	}

	function SetDead(){
		entity.SetPropInt("m_lifeState",1)
	}
	
	function SetCurrentKiller(ent){
		currentKiller = ent
	}
	
	function GetCurrentKiller(){
		return currentKiller
	}
	
	function GetEntity(){
		return entity
	}
	
	function EnableViewcontroller(){
		viewcontroller.Enable()
	}

	function DisableViewcontroller(){
		viewcontroller.Disable()
	}
	
	function SetViewcontrollerEntity(ent){
		viewcontroller = ent
	}
	
	function GetViewcontrollerEntity(){
		return viewcontroller
	}
	
	function IsRespawning(){
		return respawning
	}
	
	function SetRespawning(bool){
		respawning = bool
	}
	
	function SetRespawnEnd(time){
		respawn_end = time
	}
	
	function GetRespawnEnd(){
		return respawn_end
	}
	
	function GetRagdoll(){
		return ragdoll
	}
	
	function SetLastAttacker(ent){
		last_attacker = ent
	}
	
	function GetLastAttacker(){
		return last_attacker
	}
	
	function SetLastAttackWeaponName(name){
		last_attack_weapon_name = name
	}
	
	function GetLastAttackWeaponName(){
		return last_attack_weapon_name
	}
	
	function SetLastAttackWeapon(ent){
		last_attack_weapon = ent
	}
	
	function GetLastAttackWeapon(){
		return last_attack_weapon
	}
	
	function SetLastDamaged(time){
		last_damaged = time
	}
	
	function GetLastDamaged(){
		return last_damaged
	}
	
	function SetVotedToStart(bool){
		voted_to_start = bool
	}
	
	function GetVotedToStart(){
		return voted_to_start
	}
	
	function SetVotedToStop(bool){
		voted_to_stop = bool
	}
	
	function GetVotedToStop(){
		return voted_to_stop
	}
	
	function SetMapVote(map){
		map_vote = map
	}
	
	function GetMapVote(){
		return map_vote
	}
	
	function SetLastWeapons(array){
		last_weapons = array
	}
	
	function GetLastWeapons(array){
		return last_weapons
	}
	
	function SetLastVelocity(velocity){
		last_velocity = velocity
	}
	
	function GetLastVelocity(){
		return last_velocity
	}
}

class g_MapScript.PlayerSpawn {
	constructor(origin, angles){
		this.origin = origin
		this.angles = angles
	}
	
	function GetAngles(){
		return angles
	}
	
	function GetOrigin(){
		return origin
	}
	
	origin = null
	angles = null
}

class g_MapScript.DeathmatchItemSpawn {
	constructor(weaponName, origin, angles){
		this.weaponName = weaponName
		this.origin = origin
		this.angles = angles
	}
	
	function Spawn(){
		weapon = SpawnEntityFromTable("weapon_" + weaponName, {origin = origin})
		weapon.SetAngles(angles)
		weapon.SetMoveType(0)
		g_ModeScript.SetSpawnAmmo(weapon, g_ModeScript.GetSpawnAmmo(weaponName))
		picked_up = false
	}
	
	function GetWeaponName(){
		return weaponName
	}
	
	function GetOrigin(){
		return origin
	}
	
	function GetAngles(){
		return angles
	}
	
	function SetWeapon(ent){
		weapon = ent
	}
	
	function GetWeapon(){
		return weapon
	}
	
	function SetPickedUp(bool){
		picked_up = bool
	}
	
	function GetPickedUp(){
		return picked_up
	}
	
	function SetPickupTime(time){
		pickup_time = time
	}
	
	function GetPickupTime(){
		return pickup_time
	}
	
	picked_up = false
	
	angles = null
	origin = null
	weaponName = null
	weapon = null
	pickup_time = 0
}

class g_ModeScript.KillfeedLine {
	constructor(text, timeout){
		this.text = text
		this.timeout = Time() + timeout
	}
	
	function GetText(){
		return text
	}
	
	function GetTimeout(){
		return timeout
	}
	
	text = ""
	timeout = -1
}

class Killfeed {
	constructor(maxLines, hudField){
		getroottable().g_ModeScript.HookController.RegisterOnTick(this)
		this.maxLines = maxLines
		this.hudField = hudField
	}
	
	function AddKillfeedLine(text, timeout){
		lines.append(g_ModeScript.KillfeedLine(text, timeout))
		
		if(lines.len() > maxLines){
			lines.remove(0)
		}
		
		UpdateHUD()
	}
	
	function UpdateHUD(){
		local newText = ""
		for(local i=0; i < lines.len(); i++){
			newText += lines[i].GetText()
			if(i != lines.len() - 1){
				newText += "\n"
			}
		}
		hudField.dataval = newText
	}
	
	function HandleTimeouts(){
		for(local i=0; i < lines.len(); i++){
			if(Time() >= lines[i].GetTimeout()){
				lines.remove(i)
				i--
			}
		}
	}
	
	function GetHud(){
		return hudField
	}
	
	function OnTick(){
		HandleTimeouts()
		UpdateHUD()
	}
	
	maxLines = -1
	hudField = null
	lines = []
}

HUD <- {
	Fields = {
		start_countdown = { slot = HUD_TICKER, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG | HUD_FLAG_NOTVISIBLE, name = "start_countdown" }
		killfeed = { slot = HUD_MID_TOP, dataval = "",flags = HUD_FLAG_ALIGN_RIGHT | HUD_FLAG_NOBG, name = "killfeed" }
		message_display = { slot = HUD_MID_BOT, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG | HUD_FLAG_NOTVISIBLE, name = "message_display" }
		match_timer = { slot = HUD_RIGHT_TOP, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOTVISIBLE, name = "match_timer" }
		scoreboard_players = { slot = HUD_RIGHT_BOT, dataval = "",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOTVISIBLE, name = "scoreboard_players" } // the part showing names
		scoreboard_scores = { slot = HUD_LEFT_TOP, dataval = "",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG | HUD_FLAG_NOTVISIBLE, name = "scoreboard_scores" } // the part showing kills/deaths
		scoreboard_labels = { slot = HUD_LEFT_BOT, dataval = "",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOTVISIBLE | HUD_FLAG_NOBG, name = "scoreboard_labels" } // the part showing name, kill, death labels
	}
}

HUDSetLayout(HUD)

HUDPlace(HUD_TICKER, 0.45, 0.45, 0.1, 0.1) // start_countdown
HUDPlace(HUD_MID_TOP, 0.6, 0, 0.4, 0.2) // killfeed
HUDPlace(HUD_MID_BOT, 0.125, 0.2, 0.75, 0.2) // message_display
HUDPlace(HUD_RIGHT_TOP, 0.45, 0, 0.10, 0.05) // match_timer
HUDPlace(HUD_RIGHT_BOT, 0.25, 0.25, 0.5, 0.5) // scoreboard_players
HUDPlace(HUD_LEFT_TOP, 0.55, 0.43, 0.25, 0.3) // scoreboard_scores
HUDPlace(HUD_LEFT_BOT, 0.25, 0.25, 0.5, 0.25) // scoreboard_labels

DeathmatchResponseRules <- [{
	name = "FriendlyFire",
	criteria = [["concept", "PlayerFriendlyFire"]],
	responses = [{scenename = ""}],
	group_params = RGroupParams({permitrepeats = true, sequential = false, norepeat = false})
}]

DirectorOptions <- {
	cm_NoSurvivorBots = true
	ProhibitBosses = true
	CommonLimit = 0
	MaxSpecials = 0
}

local placerAxis = null

local propPlacerEnabled = false
local propPlacerProp = null
local propPlacerScale = 1

local blockerPlacerEnabled = false
local blockerPlacerPos = null
local blockerPlacerMins = Vector(-32, -32, -32)
local blockerPlacerMaxs = Vector(32, 32, 32)
local blockerPlacerScale = 2

local itemPlacerEnabled = false
local itemPlacerEntity = null
local itemPlacerScale = 1
local itemPlacerWeapon = null

Game <- DeathmatchGame()

DeathmatchConvarManager <- null
DeathmatchKillfeed <- null
DeathmatchPlayerManager <- null
DeathmatchItemManager <- null
DeathmatchPlayers <- []
DeathmatchItemSpawns <- []
DeathmatchInitialPlayerSpawns <- []
DeathmatchPlayerSpawns <- []

function ConvertVectorToVectorConstructor(vector){
	return "Vector(" + vector.x + ", " + vector.y + ", " + vector.z + ")"
}

function StringToVector(string){
	string = strip(string)
	
	local x = 0
	local y = 0
	local z = 0
	local index = 0
	local foundVal = ""
	foreach(char in string){
		if(char.tochar() != "\t" && char.tochar() != " "){
			foundVal += char.tochar()
		} else {
			if(foundVal.len() > 0){
				if(index == 0){
					x = foundVal.tofloat()
				} else if(index == 1){
					y = foundVal.tofloat()
				}
				foundVal = ""
				index++
			}
		}
	}
	z = foundVal.tofloat()
	return Vector(x, y, z)
}

function StringToQAngle(string){
	string = strip(string)
	
	local x = 0
	local y = 0
	local z = 0
	local index = 0
	local foundVal = ""
	foreach(char in string){
		if(char.tochar() != "\t" && char.tochar() != " "){
			foundVal += char.tochar()
		} else {
			if(foundVal.len() > 0){
				if(index == 0){
					x = foundVal.tofloat()
				} else if(index == 1){
					y = foundVal.tofloat()
				}
				foundVal = ""
				index++
			}
		}
	}
	z = foundVal.tofloat()
	return QAngle(x, y, z)
}

function StopIntro(){
	local info_director = Entities.FindByClassname(null, "info_director")
	info_director.Input("ReleaseSurvivorPositions")
	info_director.Input("FinishIntro")
	EntFire("camera_intro", "Disable")
	EntFire("camera_intro_survivor_01", "Disable")
	EntFire("camera_intro_survivor_02", "Disable")
	EntFire("camera_intro_survivor_03", "Disable")
	EntFire("camera_intro_survivor_04", "Disable")
}

function ExecuteScript(ent, input){
	compilestring(input)()
}

function SendClientCommand(ent, command){
	local commandEntity = SpawnEntityFromTable("point_clientcommand", {})
	commandEntity.Input("Command", command, 0, ent, commandEntity)
	commandEntity.Input("Kill", "", 0.033, null, commandEntity)
}

function FindPlayer(ent){
	foreach(player in DeathmatchPlayers){
		if(player.GetEntity() == ent){
			return player
		}
	}
}

function GetAvailableCharacter(ent){
	local l4d2Characters = true
	local availableL4D2Characters = [0, 1, 2, 3]
	local availableL4D1Characters = [4, 5, 6, 7]
	
	foreach(survivor in HookController.EntitiesByClassname("player")){
		if(survivor.IsSurvivor() && survivor != ent){
			if(availableL4D1Characters.find(GetCharacter(survivor))){
				l4d2Characters = false
			}
			if(l4d2Characters){
				local characterIndex = availableL4D2Characters.find(GetCharacter(survivor))
				availableL4D2Characters.remove(characterIndex)
			} else {
				local characterIndex = availableL4D1Characters.find(GetCharacter(survivor))
				availableL4D1Characters.remove(characterIndex)
			}
		}
	}
	
	if(l4d2Characters){
		return availableL4D2Characters[RandomInt(0, availableL4D2Characters.len() - 1)]
	} else {
		return availableL4D1Characters[RandomInt(0, availableL4D1Characters.len() - 1)]
	}
}

function GetRandomSpawn(){
	local bestSpawn = null
	local spawns = []
	spawns.extend(DeathmatchPlayerSpawns)
	if(spawns != null && spawns.len() > 0){
		local found_good_spawn = false
		local random = RandomInt(0,spawns.len()-1)
		while(!found_good_spawn){
			local lowestDistance = 99999
			local lowestDistancePlayer = null
			found_good_spawn = true
			foreach(player in DeathmatchPlayers){
				if((player.GetEntity().GetOrigin() - spawns[random].GetOrigin()).Length() < lowestDistance){
					lowestDistance = (player.GetEntity().GetOrigin() - spawns[random].GetOrigin()).Length()
					lowestDistancePlayer = player
				}
				if((player.GetEntity().GetOrigin() - spawns[random].GetOrigin()).Length() <= Game.GetSetting("respawn_minimum_distance")){
					found_good_spawn = false
				}
			}
			if(bestSpawn == null || lowestDistance > (lowestDistancePlayer.GetEntity().GetOrigin() - bestSpawn.GetOrigin()).Length()){
				bestSpawn = spawns[random]
			}
			if(!found_good_spawn){
				spawns.remove(random)
				
				random = RandomInt(0,spawns.len()-1)
			}
		}
		return spawns[random]
	} else {
		return bestSpawn
	}
}

function KillEntitiesByClassname(...){
	foreach(classname in vargv){
		foreach(ent in HookController.EntitiesByClassname(classname)){
			if(classname == "molotov_projectile"){
				StopSoundOn("Molotov.Loop", ent)
			}
			ent.Kill()
		}
	}
}

function RemoveSpaces(str){
	local newStr = ""
	
	foreach(char in str){
		if(char != 32){
			newStr += char.tochar()
		}
	}
	
	return newStr
}

function RemoveSubstring(str, substr){
	if(str.len() == 0){
		return str
	}
	
	local index = str.find(substr)
	while(index != null){
		str = str.slice(0, index) + str.slice(substr.len())
		index = str.find(substr)
	}
	
	return str
}

/*function StringToVector(string){
	local args = split(string, " ")
	return Vector(args[0], args[1], args[2])
}

function StringToQAngle(string){
	local args = split(string, " ")
	return QAngle(args[0], args[1], args[2])
}*/

function RemoveGrabbables(){
	foreach(ent in HookController.EntitiesByModel("models/props_junk/gascan001a.mdl")){
		ent.Kill()
	}
	foreach(ent in HookController.EntitiesByModel("models/props_junk/explosive_box001.mdl")){
		ent.Kill()
	}
	foreach(ent in HookController.EntitiesByModel("models/props_junk/propanecanister001a.mdl")){
		ent.Kill()
	}
	foreach(ent in HookController.EntitiesByModel("models/props_equipment/oxygentank01.mdl")){
		ent.Kill()
	}
}

function MovePlayersToSpawnPoints(spawns){
	if(spawns != null && spawns.len() > 0){
		local index = 0
		
		foreach(ent in HookController.PlayerGenerator()){
			ent.SetOrigin(spawns[index].GetOrigin())
			ent.SetAngles(spawns[index].GetAngles())
			index++
			if(index >= spawns.len()){
				index = 0
			}
		}
	}
}

function IsHost(player){
	local isDedicatedServer = Entities.FindByClassname(null,"terror_gamerules").GetPropInt("m_bIsDedicatedServer")
	
	return player == Ent("!player") && isDedicatedServer == 0
}

function FailCurrentVote(){
	local voteController = Entities.FindByClassname(null,"vote_controller")
	
	printl("potential votes for current vote: " + voteController.GetPropInt("m_potentialVotes"))
	voteController.SetPropInt("m_votesNo", 99)
	voteController.SetPropInt("m_votesYes", 0)
	
	/*
	local task = function(){
		
	}
	
	controller.ScheduleTask(task, {voteController = voteController}, 0.1)*/
}

function CheckForVote(issue){
	local voteController = Entities.FindByClassname(null, "vote_controller")
	
	local activeIssue = voteController.GetPropInt("m_activeIssueIndex")
	local potentialVotes = voteController.GetPropInt("m_potentialVotes")
	local yesVotes = voteController.GetPropInt("m_votesYes")
	local noVotes = voteController.GetPropInt("m_votesNo")

	if(activeIssue == issue && noVotes != potentialVotes && yesVotes != 0){
		return true
	} else {
		return false
	}
}

function VotesToStart(){
	local votes = 0
	foreach(player in DeathmatchPlayers){
		if(player.GetVotedToStart()){
			votes += 1
		}
	}
	return votes
}

function VotesToStop(){
	local votes = 0
	foreach(player in DeathmatchPlayers){
		if(player.GetVotedToStop()){
			votes += 1
		}
	}
	return votes
}

function ChangeSetting(ent, input){
	local args = split(input, " ")
	if(args.len() == 2){
		Game.SetSetting(args[0], args[1].tofloat())
		SaveSettings()
	}
}

function SaveSettings(){
	local text = ""
	local settings = []
	
	foreach(key,val in Game.GetSettings()){
		settings.append({key = key, val = val})
	}
	
	local function sortFunc(a,b){
		if(a["key"] > b["key"]){
			return 1
		} else if(a["key"] < b["key"]){
			return -1
		}
		return 0
	}
	settings.sort(sortFunc)
	
	foreach(setting in settings){
		text += setting["key"] + "=" + setting["val"] + "\n"
	}
	
	StringToFile("deathmatch_settings.cfg", text)
}

function LoadSettings(){
	local text = FileToString("deathmatch_settings.cfg")
	
	if(text == null){
		SaveSettings()
		return
	}
	
	local newText = ""
	
	foreach(char in text){
		if(char != 32){
			newText += char.tochar()
		}
	}
	
	local settingsFound = []
	
	while(newText.find("=")){
		local key = newText.slice(0, newText.find("="))
		if(key in Game.GetSettings()){
			local value = -1
			if(newText.find("\n")){
				value = newText.slice(newText.find("=") + 1, newText.find("\n"))
				newText = newText.slice(newText.find("\n") + 1)
			} else {
				value = newText.slice(newText.find("=") + 1, newText.find("\0"))
				newText = newText.slice(newText.find("\0"))
			}
			Game.SetSetting(key, value.tofloat())
			settingsFound.append(key)
		} else {
			if(newText.find("\n")){
				newText = newText.slice(newText.find("\n") + 1)
			} else {
				newText = newText.slice(newText.len())
			}
		}
	}
	
	local newSettings = []
	
	foreach(key,val in Game.GetSettings()){
		local foundKey = false
		
		for(local j=0; j < settingsFound.len(); j++){
			if(key == settingsFound[j]){
				foundKey = true
			}
		}
		
		if(!foundKey){
			newSettings.append(key)
		}
	}
	
	if(newSettings.len() > 0){
		SaveSettings()
	}
}

function FindAngleBetweenPoints(pos1, pos2){
	local yaw = atan2(pos1.y - pos2.y, pos1.x - pos2.x) * (180/PI) + 180
	local pitch = atan2(pos1.z - pos2.z, sqrt(pow(pos1.x - pos2.x, 2) + pow(pos1.y - pos2.y, 2))) * (180/PI)
	
	return QAngle(pitch, yaw, 0)
}


// Dev functions
function TogglePropPlacer(args = null){
	propPlacerEnabled = !propPlacerEnabled
	
	local argsArray = split(args, " ")
	
	if(propPlacerEnabled){
		if(placerAxis == null){
			placerAxis = "yaw"
		}
		Ent(1).Input("Alpha", 0)
		Ent(1).SetMoveType(8)
		Ent(1).AddFlag(1 << 6)
		Ent(1).SetThirdperson(true)
	} else {
		Ent(1).Input("Alpha", 255)
		Ent(1).SetMoveType(2)
		Ent(1).RemoveFlag(1 << 6)
		Ent(1).SetThirdperson(false)
	}
	if(propPlacerEnabled){
		if(args != null){
			propPlacerProp = SpawnEntityFromTable("prop_" + argsArray[1], {model = argsArray[0], origin = Ent(1).GetOrigin(), spawnflags = 8})
		} else {
			local ent = Entities.FindByClassnameNearest("prop_*", Ent(1).GetOrigin(), 64)
			if(ent != null){
				propPlacerProp = ent
			}
		}
	}
}

function ManagePropPlacer(){
	if(propPlacerEnabled){
		Ent(1).SetOrigin(propPlacerProp.GetOrigin())
		if(placerAxis == "xy"){
			if(Ent(1).GetButtonMask() & 512){ // left
				propPlacerProp.SetOrigin(propPlacerProp.GetOrigin() + Vector(0, propPlacerScale, 0))
			} else if(Ent(1).GetButtonMask() & 1024){ // right
				propPlacerProp.SetOrigin(propPlacerProp.GetOrigin() + Vector(0, -propPlacerScale, 0))
			} else if(Ent(1).GetButtonMask() & 8){ // forward
				propPlacerProp.SetOrigin(propPlacerProp.GetOrigin() + Vector(propPlacerScale, 0, 0))
			} else if(Ent(1).GetButtonMask() & 16){ // back
				propPlacerProp.SetOrigin(propPlacerProp.GetOrigin() + Vector(-propPlacerScale, 0, 0))
			}
		} else if(placerAxis == "z"){
			if(Ent(1).GetButtonMask() & 8){ // forward
				propPlacerProp.SetOrigin(propPlacerProp.GetOrigin() + Vector(0, 0, propPlacerScale))
			} else if(Ent(1).GetButtonMask() & 16){ // back
				propPlacerProp.SetOrigin(propPlacerProp.GetOrigin() + Vector(0, 0, -propPlacerScale))
			}
		} else {
			if(Ent(1).GetButtonMask() & 512){ // left
				local offset = QAngle(0, 0, 0)
				if(placerAxis == "yaw"){
					offset = QAngle(0, 1, 0)
				} else if(placerAxis == "pitch"){
					offset = QAngle(1, 0, 0)
				} else if(placerAxis == "roll"){
					offset = QAngle(0, 0, 1)
				}
				propPlacerProp.SetAngles(propPlacerProp.GetAngles() + offset)
			} else if(Ent(1).GetButtonMask() & 1024){ // right
				local offset = QAngle(0, 0, 0)
				if(placerAxis == "yaw"){
					offset = QAngle(0, -1, 0)
				} else if(placerAxis == "pitch"){
					offset = QAngle(-1, 0, 0)
				} else if(placerAxis == "roll"){
					offset = QAngle(0, 0, -1)
				}
				propPlacerProp.SetAngles(propPlacerProp.GetAngles() + offset)
			}
		}
	}
}

function ToggleBlockerPlacer(){
	blockerPlacerEnabled = !blockerPlacerEnabled
	
	if(blockerPlacerEnabled){
		if(placerAxis == null){
			placerAxis = "xy"
		}
		blockerPlacerPos = Ent(1).GetOrigin()
		Ent(1).Input("Alpha", 0)
		Ent(1).SetMoveType(8)
		Ent(1).AddFlag(1 << 6)
		Ent(1).SetThirdperson(true)
	} else {
		Ent(1).Input("Alpha", 255)
		Ent(1).SetMoveType(2)
		Ent(1).RemoveFlag(1 << 6)
		Ent(1).SetThirdperson(false)
	}
}

function ManageBlockerPlacer(){
	if(blockerPlacerEnabled){
		if(placerAxis == "xy"){
			if(Ent(1).GetButtonMask() & 512){ // left
				blockerPlacerPos += Vector(0, blockerPlacerScale, 0)
			} else if(Ent(1).GetButtonMask() & 1024){ // right
				blockerPlacerPos += Vector(0, -blockerPlacerScale, 0)
			} else if(Ent(1).GetButtonMask() & 8){ // forward
				blockerPlacerPos += Vector(blockerPlacerScale, 0, 0)
			} else if(Ent(1).GetButtonMask() & 16){ // back
				blockerPlacerPos += Vector(-blockerPlacerScale, 0, 0)
			}
		} else if(placerAxis == "z"){
			if(Ent(1).GetButtonMask() & 8){ // forward
				blockerPlacerPos += Vector(0, 0, blockerPlacerScale)
			} else if(Ent(1).GetButtonMask() & 16){ // back
				blockerPlacerPos += Vector(0, 0, -blockerPlacerScale)
			}
		} else if(placerAxis == "size_xy"){
			if(Ent(1).GetButtonMask() & 512){ // left
				blockerPlacerMins += Vector(0, blockerPlacerScale / 2.0, 0)
				blockerPlacerMaxs -= Vector(0, blockerPlacerScale / 2.0, 0)
			} else if(Ent(1).GetButtonMask() & 1024){ // right
				blockerPlacerMins -= Vector(0, blockerPlacerScale / 2.0, 0)
				blockerPlacerMaxs += Vector(0, blockerPlacerScale / 2.0, 0)
			} else if(Ent(1).GetButtonMask() & 8){ // forward
				blockerPlacerMins -= Vector(blockerPlacerScale / 2.0, 0, 0)
				blockerPlacerMaxs += Vector(blockerPlacerScale / 2.0, 0, 0)
			} else if(Ent(1).GetButtonMask() & 16){ // back
				blockerPlacerMins += Vector(blockerPlacerScale / 2.0, 0, 0)
				blockerPlacerMaxs -= Vector(blockerPlacerScale / 2.0, 0, 0)
			}
		} else if(placerAxis == "size_z"){
			if(Ent(1).GetButtonMask() & 8){ // forward
				blockerPlacerMins -= Vector(0, 0, blockerPlacerScale / 2.0)
				blockerPlacerMaxs += Vector(0, 0, blockerPlacerScale / 2.0)
			} else if(Ent(1).GetButtonMask() & 16){ // back
				blockerPlacerMins += Vector(0, 0, blockerPlacerScale / 2.0)
				blockerPlacerMaxs -= Vector(0, 0, blockerPlacerScale / 2.0)
			}
		} else {
			if(Ent(1).GetButtonMask() & 512){ // left
				local offset = QAngle(0, 0, 0)
				if(placerAxis == "yaw"){
					offset = QAngle(0, 1, 0)
				} else if(placerAxis == "pitch"){
					offset = QAngle(1, 0, 0)
				} else if(placerAxis == "roll"){
					offset = QAngle(0, 0, 1)
				}
			} else if(Ent(1).GetButtonMask() & 1024){ // right
				local offset = QAngle(0, 0, 0)
				if(placerAxis == "yaw"){
					offset = QAngle(0, -1, 0)
				} else if(placerAxis == "pitch"){
					offset = QAngle(-1, 0, 0)
				} else if(placerAxis == "roll"){
					offset = QAngle(0, 0, -1)
				}
			}
		}
		Ent(1).SetOrigin(blockerPlacerPos)
		DebugDrawBox(blockerPlacerPos, blockerPlacerMins, blockerPlacerMaxs, 255, 0, 0, 30, 0.065)
	}
}

function ToggleItemPlacer(args = null){
	itemPlacerEnabled = !itemPlacerEnabled
	
	if(itemPlacerEnabled){
		if(placerAxis == null){
			placerAxis = "yaw"
		}
		Ent(1).Input("Alpha", 0)
		Ent(1).SetMoveType(8)
		Ent(1).AddFlag(1 << 6)
		Ent(1).SetThirdperson(true)
		if(args != null){
			if(args.len() > 6 && args.slice(0, 6) == "melee_"){
				itemPlacerEntity = g_ModeScript.SpawnMeleeWeapon(args.slice(6), Ent(1).GetOrigin(), QAngle(0, 0, 0))
				itemPlacerWeapon = args
				itemPlacerEntity.SetMoveType(0)
			} else {
				itemPlacerEntity = SpawnEntityFromTable("weapon_" + args, {model = args, origin = Ent(1).GetOrigin(), spawnflags = 2})
				itemPlacerWeapon = args
				itemPlacerEntity.SetMoveType(0)
			}
		} else {
			local traceTable = {
				start = Ent(1).EyePosition()
				end = Ent(1).EyePosition() + Ent(1).EyeAngles().Forward() * 99999
				ignore = Ent(1)
			}
			TraceLine(traceTable)
			if(traceTable.hit && traceTable.enthit != null && traceTable.enthit != Entities.FindByClassname(null, "worldspawn")){
				itemPlacerEntity = traceTable.enthit
				itemPlacerWeapon = itemPlacerEntity.GetClassname().slice(8)
				itemPlacerEntity.SetMoveType(0)
			}
		}
	} else {
		Ent(1).Input("Alpha", 255)
		Ent(1).SetMoveType(2)
		Ent(1).RemoveFlag(1 << 6)
		Ent(1).SetThirdperson(false)
	}
}

function ManageItemPlacer(){
	if(itemPlacerEnabled){
		Ent(1).SetOrigin(itemPlacerEntity.GetOrigin() - Vector(0, 0, 48))
		if(placerAxis == "xy"){
			if(Ent(1).GetButtonMask() & 512){ // left
				itemPlacerEntity.SetOrigin(itemPlacerEntity.GetOrigin() + Vector(0, itemPlacerScale, 0))
			} else if(Ent(1).GetButtonMask() & 1024){ // right
				itemPlacerEntity.SetOrigin(itemPlacerEntity.GetOrigin() + Vector(0, -itemPlacerScale, 0))
			} else if(Ent(1).GetButtonMask() & 8){ // forward
				itemPlacerEntity.SetOrigin(itemPlacerEntity.GetOrigin() + Vector(itemPlacerScale, 0, 0))
			} else if(Ent(1).GetButtonMask() & 16){ // back
				itemPlacerEntity.SetOrigin(itemPlacerEntity.GetOrigin() + Vector(-itemPlacerScale, 0, 0))
			}
		} else if(placerAxis == "z"){
			if(Ent(1).GetButtonMask() & 8){ // forward
				itemPlacerEntity.SetOrigin(itemPlacerEntity.GetOrigin() + Vector(0, 0, itemPlacerScale))
			} else if(Ent(1).GetButtonMask() & 16){ // back
				itemPlacerEntity.SetOrigin(itemPlacerEntity.GetOrigin() + Vector(0, 0, -itemPlacerScale))
			}
		} else {
			if(Ent(1).GetButtonMask() & 512){ // left
				local offset = QAngle(0, 0, 0)
				if(placerAxis == "yaw"){
					offset = QAngle(0, 1, 0)
				} else if(placerAxis == "pitch"){
					offset = QAngle(1, 0, 0)
				} else if(placerAxis == "roll"){
					offset = QAngle(0, 0, 1)
				}
				itemPlacerEntity.SetAngles(itemPlacerEntity.GetAngles() + offset)
			} else if(Ent(1).GetButtonMask() & 1024){ // right
				local offset = QAngle(0, 0, 0)
				if(placerAxis == "yaw"){
					offset = QAngle(0, -1, 0)
				} else if(placerAxis == "pitch"){
					offset = QAngle(-1, 0, 0)
				} else if(placerAxis == "roll"){
					offset = QAngle(0, 0, -1)
				}
				itemPlacerEntity.SetAngles(itemPlacerEntity.GetAngles() + offset)
			}
		}
	}
}

function UserConsoleCommand(ent, arg){
	if(arg == "votestart"){
		g_ModeScript.VoteToStart(ent)
	} else if(arg == "votestop"){
		g_ModeScript.VoteToStop(ent)
	} else if(arg == "forcestart"){
		g_ModeScript.ForceStart(ent)
	} else if(arg == "forcestop"){
		g_ModeScript.ForceStop(ent)
	} else if(arg == "kill"){
		g_ModeScript.FindPlayer(ent).Kill(ent)
	} else if(arg == "showhost"){
		if(g_ModeScript.IsHost(ent)){
			g_ModeScript.SendClientCommand(ent, "show_menu Host")
		}
	}
	
	if(arg == "yaw"){
		placerAxis = "yaw"
	} else if(arg == "pitch"){
		placerAxis = "pitch"
	} else if(arg == "roll"){
		placerAxis = "roll"
	} else if(arg == "xy"){
		placerAxis = "xy"
	} else if(arg == "z"){
		placerAxis = "z"
	} else if(arg == "reset"){
		if(propPlacerEnabled){
			propPlacerProp.SetAngles(QAngle(0, 0, 0))
		} else if(itemPlacerEnabled){
			itemPlacerEntity.SetAngles(QAngle(0, 0, 0))
		}
	} else if(arg.len() > 5 && arg.slice(0, 5) == "scale"){
		if(propPlacerEnabled){
			propPlacerScale = arg.slice(5).tofloat()
		} else if(blockerPlacerEnabled){
			blockerPlacerScale = arg.slice(5).tofloat()
		} else if(itemPlacerEnabled){
			itemPlacerScale = arg.slice(5).tofloat()
		}
	} else if(arg == "print"){
		if(propPlacerEnabled){
			printl("SpawnEntityFromTable(\"prop_\", {model = \"" + propPlacerProp.GetModelName() + "\", origin = Vector(" + propPlacerProp.GetOrigin().x + ", " + propPlacerProp.GetOrigin().y + ", " + propPlacerProp.GetOrigin().z + "), angles = \"" + propPlacerProp.GetAngles().ToKVString().slice(0, propPlacerProp.GetAngles().ToKVString().len() - 2) + "\", solid = 6, spawnflags = 8})")
		} else if(blockerPlacerEnabled){
			printl("SpawnEntityFromTable(\"env_player_blocker\", {initialstate = 1, mins = " + g_ModeScript.ConvertVectorToVectorConstructor(blockerPlacerMins) + ", maxs = " + g_ModeScript.ConvertVectorToVectorConstructor(blockerPlacerMaxs) + ", origin = " + g_ModeScript.ConvertVectorToVectorConstructor(blockerPlacerPos) + "})")
		} else if(itemPlacerEnabled){
			printl("DeathmatchItemSpawn(\"" + itemPlacerWeapon + "\", Vector(" + itemPlacerEntity.GetOrigin().x + ", " + itemPlacerEntity.GetOrigin().y + ", " + itemPlacerEntity.GetOrigin().z + "), QAngle(" + itemPlacerEntity.GetAngles().x + ", " + itemPlacerEntity.GetAngles().y + ", " + itemPlacerEntity.GetAngles().z + ")),")
		}
	} else if(arg == "size_xy"){
		placerAxis = "size_xy"
	} else if(arg == "size_z"){
		placerAxis = "size_z"
	}
}


function FileExists(filePath){
	return FileToString(filePath) != null
}

function GetMapFileName(){
	return "deathmatch_spawns_" + SessionState.MapName + ".txt"
}

function SaveToMapFile(){
	local string = ""
	string += "ItemSpawns {\n"
	foreach(spawn in DeathmatchItemSpawns){
		string += "\t" + spawn.GetWeaponName() + ", " + spawn.GetOrigin().x + " " + spawn.GetOrigin().y + " " + spawn.GetOrigin().z + ", " + spawn.GetAngles().x + " " + spawn.GetAngles().y + " " + spawn.GetAngles().z + "\n"
	}
	string += "}\n\nPlayerSpawns {\n"
	foreach(spawn in DeathmatchPlayerSpawns){
		string += "\t" + spawn.GetOrigin().x + " " + spawn.GetOrigin().y + " " + spawn.GetOrigin().z + ", " + spawn.GetAngles().x + " " + spawn.GetAngles().y + " " + spawn.GetAngles().z + "\n"
	}
	string += "}\n\nInitialPlayerSpawns {\n"
	foreach(spawn in DeathmatchInitialPlayerSpawns){
		string += "\t" + spawn.GetOrigin().x + " " + spawn.GetOrigin().y + " " + spawn.GetOrigin().z + ", " + spawn.GetAngles().x + " " + spawn.GetAngles().y + " " + spawn.GetAngles().z + "\n"
	}
	string += "}"
	StringToFile(GetMapFileName(), string)
}

function ExecuteMapFileCode(){
	local filePath = GetMapFileName()
	local file = FileToString(filePath)
	
	if(file == null){
		printl("Deathmatch map file \"" + filePath + "\" is invalid: File does not exist or is too large")
		return
	}
	if(file.tolower().find("code") == null){
		return false
	}
	
	local code = compilestring(file.slice(file.find("{", file.tolower().find("code") + 1), file.find("}", file.find("{", file.tolower().find("code") + 1))))
	code()
	return true
}

function ParseMapFile(){
	local filePath = GetMapFileName()
	local file = FileToString(filePath).tolower()
	
	if(file == null){
		printl("Deathmatch map file \"" + filePath + "\" is invalid: File does not exist or is too large")
		return
	}
	if(file.find("itemspawns") == null){
		printl("Deathmatch map file \"" + filePath + "\" is invalid: ItemSpawns does not exist")
		return
	}
	if(file.find("playerspawns") == null){
		printl("Deathmatch map file \"" + filePath + "\" is invalid: PlayerSpawns does not exist")
		return
	}
	if(file.find("initialplayerspawns") == null){
		printl("Deathmatch map file \"" + filePath + "\" is invalid: InitialPlayerSpawns does not exist")
		return
	}
	
	DeathmatchItemSpawns.clear()
	DeathmatchPlayerSpawns.clear()
	DeathmatchInitialPlayerSpawns.clear()
	
	local lines = null
	local index = null
	// Parse ItemSpawns
	index = file.find("itemspawns")
	lines = split(file.slice(file.find("{", index) + 1, file.find("}", index)), "\n")
	foreach(line in lines){
		// Parse into DeathmatchItemSpawns
		line = strip(line)
		if(line.len() == 0){
			continue
		}
		local index1 = line.find(",")
		local index2 = line.find(",", index1 + 1)
		
		local weapon = strip(line.slice(0, index1))
		local origin = StringToVector(strip(line.slice(index1 + 1, index2)))
		local angles = StringToQAngle(strip(line.slice(index2 + 1)))
		
		DeathmatchItemSpawns.append(DeathmatchItemSpawn(weapon, origin, angles))
	}
	// Parse PlayerSpawns
	index = file.find("playerspawns")
	lines = split(file.slice(file.find("{", index) + 1, file.find("}", index)), "\n")
	foreach(line in lines){
		// Parse into PlayerSpawns
		line = strip(line)
		if(line.len() == 0){
			continue
		}
		local index1 = line.find(",")
		
		local origin = StringToVector(strip(line.slice(0, index1)))
		local angles = StringToQAngle(strip(line.slice(index1 + 1)))
		
		DeathmatchPlayerSpawns.append(PlayerSpawn(origin, angles))
	}
	// Parse InitialPlayerSpawns
	index = file.find("initialplayerspawns")
	lines = split(file.slice(file.find("{", index) + 1, file.find("}", index)), "\n")
	foreach(line in lines){
		// Parse into PlayerSpawns
		line = strip(line)
		if(line.len() == 0){
			continue
		}
		local index1 = line.find(",")
		
		local origin = StringToVector(strip(line.slice(0, index1)))
		local angles = StringToQAngle(strip(line.slice(index1 + 1)))
		
		DeathmatchInitialPlayerSpawns.append(PlayerSpawn(origin, angles))
	}
	
	if(DeathmatchPlayerSpawns.len() < 4){
		printl("Deathmatch ParseMapFile WARNING:")
		error("\tLess than 4 player spawns will cause unintended behaviour or errors\n\n")
	}
	if(DeathmatchInitialPlayerSpawns.len() < 4){
		printl("Deathmatch ParseMapFile WARNING:")
		error("\tLess than 4 initial player spawns will cause unintended behaviour or errors\n\n")
	}
}


function Spectate(ent){
	//ent.SetPropInt("m_iTeamNum", 1)
	ent.SetPropInt("m_fEffects", 0)
	//ent.SetPropInt("movetype", 8)
	//ent.SetPropInt("m_iPlayerState", 4)
	ent.SetPropInt("m_lifeState", 2)
	ent.SetPropInt("m_iObserverMode", 4)
}

function ReloadSettings(ent){
	if(IsHost(ent)){
		LoadSettings()
	}
}


function ShowStartCountdown(){
	HUD.Fields.start_countdown.flags = HUD.Fields.start_countdown.flags & ~HUD_FLAG_NOTVISIBLE
}

function HideStartCountdown(){
	HUD.Fields.start_countdown.flags = HUD.Fields.start_countdown.flags | HUD_FLAG_NOTVISIBLE
}

function ShowMatchTimer(){
	HUD.Fields.match_timer.flags = HUD.Fields.match_timer.flags & ~HUD_FLAG_NOTVISIBLE
}

function HideMatchTimer(){
	HUD.Fields.match_timer.flags = HUD.Fields.match_timer.flags | HUD_FLAG_NOTVISIBLE
}

function ShowScoreboard(){
	local playerScores = []
	foreach(player in DeathmatchPlayers){
		playerScores.append({ent = player.GetEntity(), kills = player.GetKills(), deaths = player.GetDeaths()})
	}
	local function sortFunc(a,b){
		if(a["kills"] > b["kills"]){
			return -1
		} else if(a["kills"] < b["kills"]){
			return 1
		}
		return 0
	}
	playerScores.sort(sortFunc)
	//playerScores.reverse()
	HUD.Fields.scoreboard_labels.dataval = TAB + "Player" + QUADRUPLE_TAB + QUADRUPLE_TAB + TAB + "   " + "Kills" + DOUBLE_TAB + "  " + "Deaths\n\n\n"
	HUD.Fields.scoreboard_players.dataval = "\n\n\n\n\n"
	for(local i=0; i<playerScores.len(); i+=1){
		HUD.Fields.scoreboard_players.dataval += TAB + playerScores[i]["ent"].GetPlayerName() + "\n\n"
		HUD.Fields.scoreboard_scores.dataval += TAB + playerScores[i]["kills"] + QUADRUPLE_TAB + playerScores[i]["deaths"] + "\n\n"
	}
	HUD.Fields.scoreboard_labels.flags = HUD.Fields.scoreboard_labels.flags & ~HUD_FLAG_NOTVISIBLE
	HUD.Fields.scoreboard_players.flags = HUD.Fields.scoreboard_players.flags & ~HUD_FLAG_NOTVISIBLE
	HUD.Fields.scoreboard_scores.flags = HUD.Fields.scoreboard_scores.flags & ~HUD_FLAG_NOTVISIBLE
	if(DeathmatchPlayers.len() == 2){
		HUDPlace(HUD_LEFT_TOP, 0.55, 0.3975, 0.25, 0.3)
	} else if(DeathmatchPlayers.len() == 3 || DeathmatchPlayers.len() == 1){
		HUDPlace(HUD_LEFT_TOP, 0.55, 0.4, 0.25, 0.3)
	} else if(DeathmatchPlayers.len() == 4){
		HUDPlace(HUD_LEFT_TOP, 0.55, 0.43, 0.25, 0.3)
	}
}

function HideScoreboard(){
	HUD.Fields.scoreboard_players.flags = HUD.Fields.scoreboard_players.flags | HUD_FLAG_NOTVISIBLE
	HUD.Fields.scoreboard_players.dataval = ""
	
	HUD.Fields.scoreboard_labels.flags = HUD.Fields.scoreboard_labels.flags | HUD_FLAG_NOTVISIBLE
	HUD.Fields.scoreboard_labels.dataval = ""
	
	HUD.Fields.scoreboard_scores.flags = HUD.Fields.scoreboard_scores.flags | HUD_FLAG_NOTVISIBLE
	HUD.Fields.scoreboard_scores.dataval = ""
}


function VoteToStart(ent){
	if(!Game.IsStarted()){
		local player = FindPlayer(ent)
		
		if(player.GetVotedToStart()){
			player.SetVotedToStart(false)
			
			local remainingVotes = (ceil((Game.GetSetting("percentage_to_start") * DeathmatchPlayers.len()).tofloat()/100) - VotesToStart())
			Say(null, ent.GetPlayerName() + " has cancelled their vote to start. (" + remainingVotes + " more votes required)",false)
			return
		}
		
		player.SetVotedToStart(true)
		local votes = VotesToStart()
		if(votes * 100 / DeathmatchPlayers.len() >= Game.GetSetting("percentage_to_start")){
			StartCountdown()
		} else {
			local remainingVotes = (ceil((Game.GetSetting("percentage_to_start") * DeathmatchPlayers.len()).tofloat()/100) - votes)
			Say(null, ent.GetPlayerName() + " has voted to start. (" + remainingVotes + " more votes required)",false)
		}
	} else {
		Say(null,"Cannot vote to start if the game is already started!",false)
	}
}

function VoteToStop(ent){
	if(Game.IsStarted()){
		local player = FindPlayer(ent)
		
		if(player.GetVotedToStop()){
			player.SetVotedToStop(false)
			
			local remainingVotes = (ceil((Game.GetSetting("percentage_to_start") * DeathmatchPlayers.len()).tofloat()/100) - VotesToStop())
			Say(null, ent.GetPlayerName() + " has cancelled their vote to stop. (" + remainingVotes + " more votes required)",false)
			return
		}
		
		player.SetVotedToStop(true)
		local votes = VotesToStop()
		if(votes * 100 / DeathmatchPlayers.len() >= Game.GetSetting("percentage_to_stop")){
			StopGame()
		} else {
			local remainingVotes = (ceil((Game.GetSetting("percentage_to_stop") * DeathmatchPlayers.len()).tofloat()/100) - votes)
			Say(null, ent.GetPlayerName() + " has voted to stop. (" + remainingVotes + " more votes required)",false)
		}
	} else {
		Say(null,"Cannot vote to stop if the game is already stopped!",false)
	}
}

function ForceStart(ent){
	if(IsHost(ent) && !Game.IsStarted()){
		StartCountdown()
	}
}

function ForceStop(ent){
	if(IsHost(ent) && Game.IsStarted()){
		StopGame()
	}
}


function StartCountdown(){ // start the countdown
	Convars.SetValue("cl_viewbob",0)
	Convars.SetValue("crosshair",0)
	
	HideScoreboard()
	ShowStartCountdown()
	
	HookController.StopTimer(HUD.Fields.start_countdown)
	HookController.StopTimer(HUD.Fields.match_timer)
	
	DeathmatchItemManager.CleanupAllItems()
	DeathmatchItemManager.SpawnAllItems()
	
	KillEntitiesByClassname("info_goal_infected_chase", "inferno", "vomitjar_projectile", "molotov_projectile", "pipe_bomb_projectile", "grenade_launcher_projectile")

	Game.Start()
	
	foreach(player in DeathmatchPlayers){
		local ent = player.GetEntity()
		local spawn = GetRandomSpawn()
		ent.SetOrigin(spawn.GetOrigin())
		ent.SetAngles(spawn.GetAngles())
		
		ent.AddFlag(32)
		ent.SetMoveType(0)
		ent.SetPropInt("m_bAdrenalineActive", 0)
		player.ResetHealth()
		player.SetVotedToStart(false)
		player.SetKills(0)
		player.SetDeaths(0)
	}
	
	foreach(weapon in DeathmatchItemSpawns){
		weapon.SetPickedUp(false)
	}
	
	Game.SetCountdownStartTime(Time())
	Game.SetCountdownStarted(true)
	HookController.RegisterTimer(HUD.Fields.start_countdown, Game.GetSetting("countdown_time"), function(){g_ModeScript.StartGame()})
	HUD.Fields.start_countdown.dataval = "" + Game.GetSetting("countdown_time")
	Say(null,"Game has started",false)
}

function StartGame(){ // start the game
	foreach(player in DeathmatchPlayers){
		player.GetEntity().GiveItem("pistol")
		
		player.GetEntity().RemoveFlag(32)
		player.GetEntity().SetMoveType(2)
		
		player.GetEntity().SetPropFloat("m_Local.m_flFallVelocity", 0)
	}
	
	Convars.SetValue("cl_viewbob",1)
	Convars.SetValue("crosshair",1)
	
	Game.SetCountdownStarted(false)
	ShowMatchTimer()
	HideStartCountdown()
	HideScoreboard()
	HookController.RegisterTimer(HUD.Fields.match_timer, Game.GetSetting("match_time"), function(){g_ModeScript.StopGame()}, true, true)
}

function StopGame(){ // stop the game
	Game.Stop()
	Game.SetMatchTimerStarted(false)
	Game.SetGameStopTime(Time())
	Game.SetCountdownStarted(false)
	
	Convars.SetValue("cl_viewbob",1)
	Convars.SetValue("crosshair",1)
	HideMatchTimer()
	HideStartCountdown()
	ShowScoreboard()
	HookController.StopTimer(HUD.Fields.start_countdown)
	HookController.StopTimer(HUD.Fields.match_timer)
	HookController.ScheduleTask(function(){g_ModeScript.HideScoreboard()}, Game.GetSetting("leaderboard_show_time"))
	foreach(player in DeathmatchPlayers){
		player.SetVotedToStop(false)
		player.ResetHealth()
		
		if(player.IsRespawning()){
			player.EndRespawn()
		}
		if(player.GetEntity().IsDead()){
			player.SpawnFromDead()
		}
		
		player.GetEntity().RemoveFlag(32)
		player.GetEntity().SetMoveType(2)
		
		if(player.GetEntity().GetActiveWeapon() == null){
			player.GetEntity().GiveItem("pistol")
		}
	}
	Say(null,"Game has been stopped",false)
}


function AllowTakeDamage(table){
	if(Game.IsEnabled()){
		local DamageDone = table.DamageDone
		local DamageType = table.DamageType
		local Victim = table.Victim
		local Attacker = table.Attacker
		local Weapon = table.Weapon
		
		/*printl("AllowTakeDamage Weapon: " + Weapon)
		printl("AllowTakeDamage Victim: " + Victim)
		printl("AllowTakeDamage Attacker: " + Attacker)
		printl("AllowTakeDamage DamageType: " + DamageType)*/
		if(Weapon != null && Weapon.GetClassname() == "weapon_chainsaw" && Victim.GetClassname() == "player" && Attacker != null && Attacker.GetClassname() == "player" && Victim.IsSurvivor()){
			if(Game.IsStarted()){
				local player = FindPlayer(Victim)
				table["DamageDone"] = Game.GetSetting("damage") * Game.GetSetting("chainsaw_damage_modifier")
				if(Victim.GetHealth() + Victim.GetHealthBuffer() - table["DamageDone"] < 1){
					player.Kill(Attacker)
					return false
				}
				return true
			} else {
				return false
			}
		}
		if(DamageType == EXPLOSIVE_DAMAGETYPE && Victim.GetClassname() == "player" && Attacker != null && Attacker.GetClassname() == "player" && Victim.IsSurvivor()){
			if(Game.IsStarted()){
				local player = FindPlayer(Victim)
				table["DamageDone"] = DamageDone * Game.GetSetting("explosive_damage_modifier")
				if(Victim.GetHealth() + Victim.GetHealthBuffer() - table["DamageDone"] < 1){
					player.Kill(Attacker)
					return false
				}
				return true
			} else {
				return false
			}
		}
		if(DamageType == INFERNO_DAMAGETYPE && Victim.GetClassname() == "player"){
			if(Game.IsStarted()){
				local player = FindPlayer(Victim)
				table["DamageDone"] = DamageDone * Game.GetSetting("fire_damage_modifier")
				if(Victim.GetHealth() + Victim.GetHealthBuffer() - table["DamageDone"] < 1){
					player.Kill(Attacker)
					return false
				}
				return true
			} else {
				return false
			}
		}
		if(DamageType != GRENADE_LAUNCHER_DAMAGETYPE && Victim.GetClassname() == "player" && Attacker != null && (Attacker.GetClassname() == "player" || Attacker.GetClassname() == "trigger_hurt") && Victim.IsSurvivor()){
			if(Game.IsStarted()){
				local player = FindPlayer(Victim)
				local damageModifier = 1
				local weapon = Weapon
				local hitgroup = Victim.GetPropInt("m_LastHitGroup")
				
				if(player.IsRespawning()){
					return false
				}
				
				if(weapon != null && weapon.IsValid() && weapon.GetClassname().find("weapon_") == 0){
					weapon = weapon.GetClassname().slice("weapon_".len())
				}
				if(weapon != null){
					damageModifier = Game.GetDamageModifier(weapon)
				}
				
				local damageFalloff = 1
				if(Attacker != null && Attacker.GetClassname() == "player" && Victim != null){
					local distance = (Victim.EyePosition() - Attacker.EyePosition()).Length()
					damageFalloff = 1 / (((distance * Game.GetDamageFalloff(weapon)) / DAMAGE_FALLOFF_UNITS) + 1)
				}
				
				if(Game.GetSetting("no_shotgun_hitgroup_modifier") && (weapon == "autoshotgun" || weapon == "shotgun_chrome" || weapon == "pumpshotgun" || weapon == "shotgun_spas")){
					table["DamageDone"] = Game.GetSetting("damage") * damageModifier * damageFalloff
				} else if(weapon == "melee" || weapon == "chainsaw"){
					table["DamageDone"] = Game.GetSetting("damage") * damageModifier
				} else {
					table["DamageDone"] = Game.GetSetting("damage") * Game.GetHitgroupModifier(hitgroup) * damageModifier * damageFalloff
				}
				if(Victim.GetHealth() + Victim.GetHealthBuffer() - table["DamageDone"] < 1){
					player.Kill(Attacker)
					return false
				}
				return true
			} else {
				return false
			}
		}
		if(DamageType == FALL_DAMAGETYPE && Victim != null && Victim.GetClassname() == "player" && Game.IsStarted()){
			local player = FindPlayer(Victim)
			table["DamageDone"] = DamageDone * Game.GetSetting("fall_damage_modifier")
			if(Victim.GetHealth() + Victim.GetHealthBuffer() - table["DamageDone"] < 1){
				player.Kill(Attacker)
				return false
			}
			return true
		}
		if(DamageType == GRENADE_LAUNCHER_DAMAGETYPE && Victim.GetClassname() == "player"){
			if(Game.IsStarted()){
				local player = FindPlayer(Victim)
				if(Victim.GetHealth() + Victim.GetHealthBuffer() - DamageDone < 1){
					player.Kill(Attacker)
					return false
				}
			} else {
				return false
			}
		}
		
		if(!Game.IsStarted()){
			return false
		}
	}
	return true
}

function OnTick(){
	if(CheckForVote(VOTE_CHANGE_DIFFICULTY)){
		FailCurrentVote()
		Say(null,"Voting to change difficulty is disabled!",false)
	}
	if(CheckForVote(VOTE_CHANGE_CAMPAIGN)){
		FailCurrentVote()
		Say(null,"Voting to change campaign is disabled!",false)
		Say(null,"Return to lobby and change map manually instead",false)
		//Say(null,"Use !votemap or return to lobby and change map manually instead",false)
	}
	if(CheckForVote(VOTE_RESTART_CAMPAIGN)){
		FailCurrentVote()
		Say(null,"Voting to restart campaign is disabled!",false)
		Say(null,"Return to lobby and change map manually instead",false)
		//Say(null,"Use !votemap or return to lobby and change map manually instead",false)
	}
	ManagePropPlacer()
	ManageBlockerPlacer()
	ManageItemPlacer()
	
	foreach(ent in HookController.EntitiesByClassname("survivor_death_model")){
		ent.Kill()
	}
}

function OnGameplayStart(){
	if("Map_PlayerSpawns" in g_MapScript && "Map_ItemSpawns" in g_MapScript && "Map_InitialPlayerSpawns" in g_MapScript){
		::HookController <- {}
		IncludeScript("HookController", HookController)
		HookController.RegisterHooks(this)
		HookController.RegisterOnTick(g_MapScript)
		HookController.IncludeImprovedMethods()
		
		HookController.DoNextTick(function(){
			local allSurvivorsFrozen = true
			foreach(ent in ::HookController.PlayerGenerator()){
				if(!(ent.HasFlag(1 << 5))){
					allSurvivorsFrozen = false
				}
			}
			
			if(allSurvivorsFrozen){
				HookController.DoNextTick(function(){g_ModeScript.MovePlayersToSpawnPoints(g_MapScript.Map_InitialPlayerSpawns)})
			}
			g_ModeScript.StopIntro()
		})
		
		HookController.RegisterChatCommand("!script", ExecuteScript, true)
		HookController.RegisterChatCommand("!start", function(ent){g_ModeScript.VoteToStart(ent)})
		HookController.RegisterChatCommand("!stop", function(ent){g_ModeScript.VoteToStop(ent)})
		HookController.RegisterChatCommand("!forcestart", function(ent){g_ModeScript.ForceStart(ent)})
		HookController.RegisterChatCommand("!forcestop", function(ent){g_ModeScript.ForceStop(ent)})
		HookController.RegisterChatCommand("!kill", function(ent){g_ModeScript.FindPlayer(ent).Kill(ent)})
		HookController.RegisterChatCommand("!reloadsettings", function(ent){g_ModeScript.ReloadSettings(ent)})
		HookController.RegisterChatCommand("!setting", function(ent, args){g_ModeScript.ChangeSetting(ent, args)}, true)
		HookController.RegisterChatCommand("!pp", function(ent){g_ModeScript.TogglePropPlacer()})
		HookController.RegisterChatCommand("!pp", function(ent, args){g_ModeScript.TogglePropPlacer(args)}, true)
		HookController.RegisterChatCommand("!bp", function(ent){g_ModeScript.ToggleBlockerPlacer()})
		HookController.RegisterChatCommand("!ip", function(ent){g_ModeScript.ToggleItemPlacer()})
		HookController.RegisterChatCommand("!ip", function(ent, args){g_ModeScript.ToggleItemPlacer(args)}, true)
		HookController.RegisterChatCommand("!spectate", function(ent){g_ModeScript.Spectate(ent)})
		
		if("Map_ResponseRules" in g_MapScript){
			DeathmatchResponseRules.extend(g_MapScript.Map_ResponseRules)
		}
		rr_ProcessRules(DeathmatchResponseRules)
		
		local convars = [
			{name = "z_difficulty", value = "Normal"},
			{name = "gameinstructor_enable", value = 0},
			{name = "director_no_death_check", value = 1},
			{name = "grenadelauncher_ff_scale", setting = "grenade_launcher_damage_modifier"},
			{name = "grenadelauncher_ff_scale_self", setting = "grenade_launcher_damage_modifier"},
			{name = "pipe_bomb_beep_interval_delta", setting = "pipe_bomb_beep_interval_delta"},
			{name = "pipe_bomb_timer_duration", setting = "pipe_bomb_timer_duration"},
			{name = "pipe_bomb_beep_min_interval", setting = "pipe_bomb_beep_min_interval"},
			{name = "inferno_friendly_fire_duration", value = 0},
			{name = "sv_disable_glow_survivors", value = 1}
			{name = "first_aid_heal_percent", setting = "first_aid_heal_percent"}
			{name = "first_aid_kit_use_duration", setting = "first_aid_kit_use_duration"}
			{name = "pain_pills_decay_rate", setting = "pain_pills_decay_rate"}
			{name = "pain_pills_health_value", setting = "pain_pills_health_value"}
		]
		
		DeathmatchConvarManager = ConvarManager(convars)
		DeathmatchKillfeed = Killfeed(Game.GetSetting("killfeed_timeout"), HUD.Fields.killfeed)
		DeathmatchPlayerManager = PlayerManager()
		DeathmatchItemManager = ItemManager()
		
		DeathmatchItemManager.CleanupAllItems()
		DeathmatchItemManager.SpawnAllItems()
		
		if(FileExists(GetMapFileName())){
			ParseMapFile()
		} else {
			DeathmatchPlayerSpawns = g_MapScript.Map_PlayerSpawns
			DeathmatchInitialPlayerSpawns = g_MapScript.Map_InitialPlayerSpawns
			DeathmatchItemSpawns = g_MapScript.Map_ItemSpawns
			
			SaveToMapFile()
		}
		
		Convars.SetValue("defibrillator_return_to_life_time", 0)
		Convars.SetValue("survivor_incap_max_fall_damage", 9999999) // Is this needed?
		Convars.SetValue("inferno_friendly_fire_duration", 0)
		Convars.SetValue("z_friendly_fire_forgiveness", 0)
		Convars.SetValue("sv_vote_creation_timer", 30)
		Convars.SetValue("sv_vote_plr_map_limit", 5)
		Convars.SetValue("survivor_friendly_fire_factor_normal", 1)
		Convars.SetValue("sv_vote_issue_change_difficulty_allowed",0)
		Convars.SetValue("sv_visiblemaxplayers", 8)
		
		KillEntitiesByClassname("info_survivor_rescue")
		
		MovePlayersToSpawnPoints(g_MapScript.Map_InitialPlayerSpawns)
		RemoveGrabbables()
		LoadSettings()
	} else {
		if(FileExists(GetMapFileName())){
			ParseMapFile()
			ExecuteMapFileCode()
		} else {
			Game.SetEnabled(false)
			HUD.Fields.message_display.flags = HUD.Fields.message_display.flags & ~HUD_FLAG_NOTVISIBLE
			HUD.Fields.message_display.dataval = "This map is unsupported"
		}
	}
}


function OnGameEvent_player_connect(params){
	if(!params["bot"]){
		Say(null, params["name"] + " has started connecting.", false)
	}
}

function OnGameEvent_player_connect_full(params){
	local ent = GetPlayerFromUserID(params.userid)
	Say(null, ent.GetPlayerName() + " has connected.", false)
}

function OnGameEvent_player_disconnect(params){
	if("bot" in params && !params["bot"]){
		local reason = params["reason"]
		
		local leaveMessage = " has left. (" + reason + ")"
		
		/*if(reason == "self"){
			leaveMessage = "has left."
		} else if(reason == "kick"){
			leaveMessage = "has been kicked."
		} else if(reason == "ban"){
			leaveMessage = "has been banned."
		} else if(reason == "cheat"){
			leaveMessage = "has been banned for cheating."
		} else if(reason == "error"){
			leaveMessage = "encountered an error."
		}*/
		
		Say(null, params["name"] + " " + leaveMessage, false)
	}
}