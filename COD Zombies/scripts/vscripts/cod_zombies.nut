/*
	https://trello.com/b/EpltlNrv/cod-zombies
	
	DONE HUD
		score for each player
		current wave
	DONE special waves
		all hunter
		all charger
	DONE tank every 5 waves
	DONE powerups
		blink before expiring
	
		max ammo
		ammo upgrade (incendiary or explosive)
		nuke
	add css weapons to weapon_spawns
	score
		buy weapons
		increased on kill
		
	
	DONE how should waves spawn? over time
	how should damage/zombie amount scaling work? TEST zombie health increase, DONE amount increase
	what special waves?
	DONE regular zombies during tank/special waves? yes, but much less and last common in tank wave drops max ammo and/or css weapon
	DONE multiple tanks in a tank wave?
*/

enum Powerups {
	MAX_AMMO
	AMMO_UPGRADE
	NUKE
	DEATH_MACHINE
	RANDOM
}

enum AmmoUpgradeTypes {
	INCENDIARY = 1
	EXPLOSIVE = 2
}

enum SpecialWaves {
	HUNTERS
	CHARGERS
}

enum WaveTypes {
	NORMAL
	SPECIAL
	TANK
}


class ZombiesGame {
	constructor(){
		g_ModeScript.HookController.RegisterOnTick(this)
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
	
	function IsSpecialWave(){
		return wave_counter % GetSetting("special_wave") == 0
	}
	
	function IsTankWave(){
		return wave_counter % GetSetting("tank_wave") == 0
	}
	
	function GetZombieScore(){
		return GetSetting("zombie_initial_kill_score") + (wave_counter * GetSetting("zombie_kill_score_increase"))
	}
	
	function GetSpecialScore(){
		return GetSetting("special_initial_kill_score") + (wave_counter * GetSetting("special_kill_score_increase") / GetSetting("special_wave"))
	}
	
	function GetTankScore(){
		return GetSetting("tank_initial_kill_score") + (wave_counter * GetSetting("tank_kill_score_increase") / GetSetting("tank_wave"))
	}
	
	function GetZombieHealth(){
		return GetSetting("zombie_initial_health") + (wave_counter * GetSetting("zombie_health_increase"))
	}
	
	function GetSpecialHealth(){
		return GetSetting("special_initial_health") + (wave_counter * GetSetting("special_health_increase") / GetSetting("special_wave"))
	}
	
	function GetTankHealth(){
		return GetSetting("tank_initial_health") + (wave_counter * GetSetting("tank_health_increase") / GetSetting("tank_wave"))
	}
	
	function GetZombieDamage(){
		return GetSetting("zombie_initial_damage") + (wave_counter * GetSetting("zombie_damage_increase_per_wave"))
	}
	
	function GetSpecialDamage(){
		return GetSetting("special_initial_damage") + (wave_counter * GetSetting("special_damage_increase_per_wave") / GetSetting("special_wave"))
	}
	
	function GetTankDamage(){
		return GetSetting("tank_initial_damage") + (wave_counter * GetSetting("tank_damage_increase_per_wave") / GetSetting("tank_wave"))
	}
	
	function GetZombiesToSpawn(){
		return zombies_to_spawn
	}
	
	function GetZombieCount(){
		return GetSetting("zombie_initial_count")  + (wave_counter * GetSetting("zombie_increase_per_wave"))
	}
	
	function GetSpecialCount(){
		return GetSetting("special_initial_count")  + (wave_counter * GetSetting("special_increase_per_wave") / GetSetting("special_wave"))
	}
	
	function GetTankCount(){
		return GetSetting("tank_initial_count")  + (wave_counter * GetSetting("tank_increase_per_wave") / GetSetting("tank_wave"))
	}
	
	function GetCurrentTankCount(){
		local count = 0
		foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
			if(ent.GetZombieType() == g_ModeScript.HookController.ZombieTypes.TANK){
				count++
			}
		}
		return count
	}
	
	function GetInfectedCountGlowThreshold(){
		return (GetZombieCount() + GetSpecialCount() + GetTankCount()) * GetSetting("show_infected_glow_percent")
	}
	
	function StartWave(){
		started = true
		wave_start = Time()
		in_wave = true
		wave_counter++
		zombies_to_spawn = 0
		specials_to_spawn = 0
		tanks_to_spawn = 0
		
		foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
			ent.PlaySoundOnClient("MegaMobIncoming")
		}
		
		g_ModeScript.HUD.Fields.wave.dataval = "Wave: " + wave_counter.tostring()
		
		Convars.SetValue("z_health", GetZombieHealth())
		Convars.SetValue("z_charger_health", GetSpecialHealth())
		Convars.SetValue("z_hunter_health", GetSpecialHealth())
		Convars.SetValue("z_tank_health", GetTankHealth())
		
		if(IsTankWave()){
			wave_type = WaveTypes.TANK
			tanks_to_spawn = GetTankCount()
			zombies_to_spawn = GetZombieCount() * GetSetting("tank_wave_zombie_ratio")
		} else if(IsSpecialWave()){
			wave_type = WaveTypes.SPECIAL
			special_type = RandomInt(0, 1)
			specials_to_spawn = GetSpecialCount()
		} else {
			wave_type = WaveTypes.NORMAL
			zombies_to_spawn = GetZombieCount()
		}
	}

	function EndWave(){
		in_wave = false
		wave_end = Time()
		foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
			g_ModeScript.HookController.SendCommandToClient(ent, "play wave_complete")
			//ent.PlaySoundOnClient("Event.LeavingSafety_Survival")
		}
	}
	
	function SpawnZombie(){
		if(g_ModeScript.SpawnInfected(g_ModeScript.HookController.ZombieTypes.COMMON)){
			zombies_to_spawn--
			last_zombie_spawn = Time()
		}
	}
	
	function SpawnSpecial(zombieType){
		if(g_ModeScript.SpawnInfected(zombieType)){
			specials_to_spawn--
			last_special_spawn = Time()
		}
	}
	
	function SpawnTank(){
		if(GetCurrentTankCount() < 2 && g_ModeScript.SpawnInfected(g_ModeScript.HookController.ZombieTypes.TANK)){
			tanks_to_spawn--
			last_tank_spawn = Time()
		}
	}
	
	function OnTick(){
		if(Time() >= wave_start + 6){
			foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
				ent.StopSound("MegaMobIncoming")
			}
		}
		if(!started){
			return
		}
		if(in_wave){
			if(zombies_to_spawn <= 0 && specials_to_spawn <= 0 && tanks_to_spawn <= 0){
				local totalInfected = g_ModeScript.GetTotalInfected()
				if(totalInfected == 0){
					EndWave()
				}
				if(totalInfected <= GetInfectedCountGlowThreshold()){
					foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
						ent.ValidateScriptScope()
						if(ent.GetTeam() == 3 && ent.GetZombieType() != g_ModeScript.HookController.ZombieTypes.TANK){
							if("lastPos" in ent.GetScriptScope() && "lastPosTime" in ent.GetScriptScope()){
								if((ent.GetScriptScope()["lastPos"] - ent.GetOrigin()).Length() > GetSetting("infected_cull_grace_radius")){
									ent.GetScriptScope()["lastPos"] = ent.GetOrigin()
									ent.GetScriptScope()["lastPosTime"] = Time()
								}
								if(Time() > ent.GetScriptScope()["lastPosTime"] + GetSetting("infected_cull_grace_time")){
									ent.TakeDamage(9999999, 0, null)
								}
							} else {
								ent.GetScriptScope()["lastPos"] <- ent.GetOrigin()
								ent.GetScriptScope()["lastPosTime"] <- Time()
							}
							if(ent.GetProp("m_lifeState")){ // dead/dying
								ent.SetGlowType(0)
							} else if(ent.GetGlowType() != 3){
								ent.SetGlowType(3)
								ent.SetGlowColor(255, 0, 255)
								ent.SetGlowRangeMin(250)
							}
						}
					}
					foreach(ent in g_ModeScript.HookController.EntitiesByClassname("infected")){
						ent.ValidateScriptScope()
						if("lastPos" in ent.GetScriptScope() && "lastPosTime" in ent.GetScriptScope()){
							if((ent.GetScriptScope()["lastPos"] - ent.GetOrigin()).Length() > GetSetting("infected_cull_grace_radius")){
								ent.GetScriptScope()["lastPos"] = ent.GetOrigin()
								ent.GetScriptScope()["lastPosTime"] = Time()
							}
							if(Time() > ent.GetScriptScope()["lastPosTime"] + GetSetting("infected_cull_grace_time")){
								ent.TakeDamage(9999999, 0, null)
							}
						} else {
							ent.GetScriptScope()["lastPos"] <- ent.GetOrigin()
							ent.GetScriptScope()["lastPosTime"] <- Time()
						}
						if(ent.GetProp("m_lifeState")){ // dead/dying
							ent.SetGlowType(0)
						} else if(ent.GetGlowType() != 3){
							ent.SetGlowType(3)
							ent.SetGlowColor(255, 0, 255)
							ent.SetGlowRangeMin(250)
						}
					}
				}
			}
			
			if(wave_type == WaveTypes.NORMAL){
				if(Time() < wave_start + GetSetting("zombie_initial_spawn_delay"))
					return
				
				local spawn_interval = RandomFloat(GetSetting("zombie_spawn_interval_min"), GetSetting("zombie_spawn_interval_max")) / zombies_to_spawn
				if(zombies_to_spawn > 0 && Time() >= last_zombie_spawn + spawn_interval){ // time to spawn a zombie!
					SpawnZombie()
				}
			}
			if(wave_type == WaveTypes.SPECIAL){
				if(Time() < wave_start + GetSetting("special_initial_spawn_delay"))
					return
				
				local spawn_interval = RandomFloat(GetSetting("special_spawn_interval_min"), GetSetting("special_spawn_interval_max")) / specials_to_spawn
				if(specials_to_spawn > 0 && Time() >= last_special_spawn + spawn_interval){ // time to spawn a special!
					local zombieType = 0
					if(special_type == SpecialWaves.HUNTERS){
						zombieType = g_ModeScript.HookController.ZombieTypes.HUNTER
					}
					if(special_type == SpecialWaves.CHARGERS){
						zombieType = g_ModeScript.HookController.ZombieTypes.CHARGER
					}
					SpawnSpecial(zombieType)
				}
			}
			if(wave_type == WaveTypes.TANK){
				local zombie_spawn_interval = RandomFloat(GetSetting("zombie_spawn_interval_min"), GetSetting("zombie_spawn_interval_max")) / zombies_to_spawn
				if(Time() >= wave_start + GetSetting("zombie_initial_spawn_delay") && zombies_to_spawn > 0 && Time() >= last_zombie_spawn + zombie_spawn_interval){ // time to spawn a zombie!
					SpawnZombie()
				}
				
				local tank_spawn_interval = RandomFloat(GetSetting("tank_spawn_interval_min"), GetSetting("tank_spawn_interval_max")) / tanks_to_spawn
				if(Time() >= wave_start + GetSetting("tank_initial_spawn_delay") && tanks_to_spawn > 0 && Time() >= last_tank_spawn + tank_spawn_interval){ // time to spawn a tank!
					SpawnTank()
				}
			}
		}
		if(!in_wave && Time() >= wave_end + GetSetting("wave_downtime")){
			StartWave()
		}
		foreach(ent in g_ModeScript.HookController.EntitiesByClassname("infected")){
			ent.ValidateScriptScope()
			if(!("mob_rush" in ent.GetScriptScope())){
				ent.SetProp("m_mobRush", 1)
				ent.GetScriptScope()["mob_rush"] <- true
			}
		}
	}
	
	started = false
	in_wave = false
	
	wave_counter = 0
	wave_type = WaveTypes.NORMAL
	special_type = 0
	wave_start = 0
	wave_end = 0
	
	zombies_to_spawn = 0
	specials_to_spawn = 0
	tanks_to_spawn = 0
	
	last_zombie_spawn = 0
	last_special_spawn = 0
	last_tank_spawn = 0
	
	settings = {
		fireaxe_name = "Fireaxe"
		crowbar_name = "Crowbar"
		cricket_bat_name = "Cricket Bat"
		katana_name = "Katana"
		baseball_bat_name = "Baseball Bat"
		knife_name = "Knife"
		electric_guitar_name = "Electric Guitar"
		machete_name = "Machete"
		frying_pan_name = "Frying Pan"
		tonfa_name = "Tonfa"
		
		first_aid_kit_name = "First Aid Kit"
		adrenaline_name = "Adrenaline"
		pain_pills_name = "Pain Pills"
		defibrillator_name = "Defibrillator"
		
		upgradepack_explosive_name = "Explosive Ammo Pack"
		upgradepack_incendiary_name = "Incendiary Ammo Pack"
		
		pipe_bomb_name = "Pipe Bomb"
		molotov_name = "Molotov"
		vomitjar_name = "Bile Jar"
		
		rifle_name = "M16"
		rifle_ak47_name = "AK47"
		rifle_desert_name = "SCAR"
		rifle_m60_name = "M60"
		
		hunting_rifle_name = "Hunting Rifle"
		sniper_awp_name = "AWP"
		sniper_military_name = "Military Sniper"
		sniper_scout_name = "Scout Sniper"
		
		smg_name = "SMG"
		smg_mp5_name = "MP5"
		smg_silenced_name = "Silenced SMG"
		
		autoshotgun_name = "Autoshotgun"
		shotgun_chrome_name = "Chrome Shotgun"
		shotgun_spas_name = "Spas Shotgun"
		pumpshotgun_name = "Pump Shotgun"
		
		grenade_launcher_name = "Grenade Launcher"
		
		pistol_name = "Pistol"
		pistol_magnum_name = "Desert Eagle"
		
		fireaxe_cost = 0
		crowbar_cost = 0
		cricket_bat_cost = 0
		katana_cost = 0
		baseball_bat_cost = 0
		knife_cost = 0
		electric_guitar_cost = 0
		machete_cost = 0
		frying_pan_cost = 0
		tonfa_cost = 0
		
		first_aid_kit_cost = 500
		adrenaline_cost = 100
		pain_pills_cost = 250
		defibrillator_cost = 1050
		
		upgradepack_explosive_cost = 150
		upgradepack_incendiary_cost = 75
		
		pipe_bomb_cost = 250
		molotov_cost = 100
		vomitjar_cost = 250
		
		rifle_cost = 100
		rifle_ak47_cost = 200
		rifle_desert_cost = 250
		rifle_m60_cost = -1
		
		hunting_rifle_cost = 800
		sniper_awp_cost = 850
		sniper_military_cost = 850
		sniper_scout_cost = 800
		
		smg_cost = 50
		smg_mp5_cost = 50
		smg_silenced_cost = 25
		
		autoshotgun_cost = 650
		shotgun_chrome_cost = 450
		shotgun_spas_cost = 700
		pumpshotgun_cost = 400
		
		grenade_launcher_cost = 1000
		
		pistol_cost = 0
		pistol_magnum_cost = 350
		
		
		
		show_infected_glow_percent = 0.05
		infected_cull_grace_radius = 150 // infected must move this far to not get culled
		infected_cull_grace_time = 7.5 // time to wait until culling if the infected hasn't moved far enough
		
		melee_damage_health_percent = 0.10
		grenade_launcher_damage_health_percent = 0.10
		
		regen_delay = 5
		regen_rate = 1 // health per tick
		
		door_use_time = 3
		
		item_cooldown_time = 0.5
		item_use_time = 1
		
		tank_wave = 5
		special_wave = 99999
		
		spawn_distance = 2000
		
		wave_downtime = 15
		
		upgraded_ammo_amount = 50
		
		tank_initial_spawn_delay = 20
		special_initial_spawn_delay = 10
		zombie_initial_spawn_delay = 5
		
		zombie_initial_kill_score = 5
		special_initial_kill_score = 15
		tank_initial_kill_score = 50
		
		zombie_kill_score_increase = 2
		special_kill_score_increase = 10
		tank_kill_score_increase = 15
		
		zombie_health_increase = 10
		special_health_increase = 25
		tank_health_increase = 100
		
		zombie_initial_health = 50
		special_initial_health = 350
		tank_initial_health = 2000
		
		tank_increase_per_wave = 1
		tank_damage_increase_per_wave = 1
		tank_initial_count = 1
		tank_initial_damage = 10
		
		special_increase_per_wave = 2
		special_damage_increase_per_wave = 1
		special_initial_count = 5
		special_initial_damage = 5
		
		zombie_increase_per_wave = 5
		zombie_damage_increase_per_wave = 0.25
		zombie_initial_count = 20
		zombie_initial_damage = 1
		
		tank_wave_zombie_ratio = 0.33
		
		tank_spawn_interval_min = 15
		tank_spawn_interval_max = 25
		special_spawn_interval_min = 7
		special_spawn_interval_max = 15
		zombie_spawn_interval_min = 0.25
		zombie_spawn_interval_max = 1
		
		powerup_drop_chance = 0.02
		powerup_lifetime = 15
		powerup_blink_time = 10
	}
}

class ZombiesPowerup {
	constructor(origin){
		spawnTime = Time()
		this.origin = origin
		g_ModeScript.HookController.RegisterOnTick(this)
	}
	
	function GetSpawnTime(){
		return spawnTime
	}
	
	function GetModel(){
		return model
	}
	
	function GetOrigin(){
		return origin
	}
	
	function StartBlinking(){
		if(model && model.IsValid()){
			model.SetRenderFX(17)
			model.SetProp("m_Glow.m_bFlashing", 1)
		}
	}
	
	function IsUsed(){
		return used
	}
	
	function OnUsed(user){
		used = true
		this.user = user
		if(model && model.IsValid()){
			model.Kill()
		}
		DoAction(user)
	}
	
	function OnExpired(){
		if(model && model.IsValid()){
			model.Kill()
		}
	}
	
	function OnTick(){}
	
	function DoAction(){}
	
	used = false
	origin = null
	spawnTime = null
	model = null
	user = null
}

class MaxAmmo extends ZombiesPowerup {
	constructor(origin){
		base.constructor(origin)
		model = SpawnEntityFromTable("prop_dynamic", {origin = origin, model = "models/props_unique/spawn_apartment/coffeeammo.mdl"})
		//model.SetProp("m_flModelScale", 3)
		model.Input("Color", "255 0 0")
		
		model.SetGlowType(3)
		model.SetGlowColor(255, 0, 0)
		model.SetGlowRange(500)
	}
	
	function DoAction(user){
		foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
			// TODO special case for chainsaw/m60/grenade launcher
			ent.GiveItem("ammo")
		}
	}
}

class AmmoUpgrade extends ZombiesPowerup {
	constructor(origin){
		base.constructor(origin)
		type = RandomInt(AmmoUpgradeTypes.INCENDIARY, AmmoUpgradeTypes.EXPLOSIVE)
		local modelName = null
		if(type == AmmoUpgradeTypes.INCENDIARY){
			modelName = "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
		} else if(type == AmmoUpgradeTypes.EXPLOSIVE){
			modelName = "models/w_models/weapons/w_eq_explosive_ammopack.mdl"
		}
		model = SpawnEntityFromTable("prop_dynamic", {origin = origin, model = modelName})
		model.SetProp("m_flModelScale", 2)
		
		model.SetGlowType(3)
		model.SetGlowColor(255, 0, 0)
		model.SetGlowRange(500)
	}
	
	function DoAction(user){
		foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
			local inventory = {}
			GetInvTable(ent, inventory)
			
			if("slot0" in inventory){
				if(inventory["slot0"].HasProp("m_upgradeBitVec")){
					inventory["slot0"].SetUpgrades(inventory["slot0"].GetProp("m_upgradeBitVec") | type)
					inventory["slot0"].SetUpgradedAmmoLoaded(inventory["slot0"].GetClip())
					//inventory["slot0"].SetUpgradedAmmoLoaded(g_ModeScript.Game.GetSetting("upgraded_ammo_amount"))
				}
			}
		}
	}
	
	type = null
}

class Nuke extends ZombiesPowerup {
	constructor(origin){
		base.constructor(origin)
		model = SpawnEntityFromTable("prop_dynamic", {origin = origin, angles = "-45 15 0 ", model = "models/missiles/f18_agm65maverick.mdl"})
		model.SetProp("m_flModelScale", 0.4)
		
		model.SetGlowType(3)
		model.SetGlowColor(255, 0, 0)
		model.SetGlowRange(500)
	}
	
	function DoAction(user){
		foreach(ent in g_ModeScript.HookController.EntitiesByClassname("infected")){
			ent.TakeDamage(99999, 0, user)
		}
		foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
			if(ent.GetTeam() == 3){
				if(ent.GetZombieType() != 8){
					ent.TakeDamage(99999, 0, user)
				} else {
					ent.TakeDamage(ent.GetMaxHealth() / 2, 0, user)
				}
			}
		}
	}
}

class DeathMachine extends ZombiesPowerup {
	constructor(origin){
		base.constructor(origin)
		model = SpawnEntityFromTable("prop_dynamic_override", {origin = origin, angles = "-45 15 0 ", model = "models/w_models/weapons/w_m60.mdl"})
		model.SetProp("m_flModelScale", 1.25)
		
		model.SetGlowType(3)
		model.SetGlowColor(255, 0, 0)
		model.SetGlowRange(500)
	}
	
	function DoAction(user){
		user.GiveItem("rifle_m60")
	}
}

HookController <- {}
IncludeScript("HookController", HookController)
HookController.IncludeImprovedMethods()
HookController.RegisterHooks(this)
HookController.RegisterBileExplodeListener(this)
HookController.RegisterChatCommand("!script", function(ent, input){compilestring(input)()}, true)

HUD <- {
	Fields = {
		wave = { slot = HUD_MID_TOP, dataval = "Wave: 1",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG, name = "wave" }
		player1 = { slot = HUD_RIGHT_TOP, dataval = "",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG, name = "player1" }
		player2 = { slot = HUD_RIGHT_BOT, dataval = "",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG, name = "player2" }
		player3 = { slot = HUD_LEFT_TOP, dataval = "",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG, name = "player3" }
		player4 = { slot = HUD_LEFT_BOT, dataval = "",flags = HUD_FLAG_ALIGN_LEFT | HUD_FLAG_NOBG, name = "player4" }
	}
}

PrecacheEntityFromTable({classname = "prop_dynamic", model = "models/props_collectables/backpack.mdl"})
PrecacheEntityFromTable({classname = "prop_dynamic", model = "models/props_unique/spawn_apartment/coffeeammo.mdl"})
PrecacheEntityFromTable({classname = "prop_dynamic", model = "models/missiles/f18_agm65maverick.mdl"})

HUDSetLayout(HUD)

HUDPlace(HUD_MID_TOP, 0, 0.8, 0.15, 0.05)
HUDPlace(HUD_RIGHT_TOP, 0.8, 0.8, 0.2, 0.05)
HUDPlace(HUD_RIGHT_BOT, 0.8, 0.77, 0.2, 0.05)
HUDPlace(HUD_LEFT_TOP, 0.8, 0.74, 0.2, 0.05)
HUDPlace(HUD_LEFT_BOT, 0.8, 0.71, 0.2, 0.05)


const SPAWN_RADIUS = 750
const SPAWN_RADIUS_GRACE = 250

const MAX_SPAWN_TRIES = 10

DirectorOptions <- {
	cm_NoSurvivorBots = true
	
	SpawnSetPosition = Vector(0, 0, 0)
	SpawnSetRadius = SPAWN_RADIUS
	SpawnSetRule = SPAWN_POSITIONAL
	
	cm_WanderingZombieDensityModifier = 0
	cm_ProhibitBosses = true
	NoMobSpawns = true
	BileMobSize = 0
	WitchLimit = 0
	BoomerLimit = 0
	SpitterLimit = 0
	JockeyLimit = 0
	SmokerLimit = 0
	HunterLimit = 0
	ChargerLimit = 0
	CommonLimit = 0
	TankLimit = 30
}

Game <- ZombiesGame()

local ghostSpecial = null

const CHAINSAW_MAX_AMMO = 30
const M60_MAX_AMMO = 150
const GRENADE_LAUNCHER_MAX_AMMO = 30
const NUM_POWERUPS = 3
const MAX_FLOAT = 2147483647.0

local spawnedPowerups = []
local itemUseQueue = []

function GetTotalInfected(){
	local infectedCount = 0
	foreach(ent in g_ModeScript.HookController.EntitiesByClassname("player")){
		if(ent.GetTeam() == 3 && ent.GetProp("m_lifeState") == 0){
			infectedCount++
		}
	}
	foreach(ent in g_ModeScript.HookController.EntitiesByClassname("infected")){
		if(ent.GetProp("m_lifeState") == 0){
			infectedCount++
		}
	}
	
	return infectedCount
}

function DropPowerup(origin, powerup = Powerups.RANDOM){
	if(powerup == Powerups.RANDOM){
		powerup = RandomInt(0, Powerups.RANDOM - 1)
	}
	if(powerup == Powerups.MAX_AMMO){
		printl("dropping max ammo")
		spawnedPowerups.append(MaxAmmo(origin))
	}
	if(powerup == Powerups.AMMO_UPGRADE){
		printl("dropping ammo upgrade")
		spawnedPowerups.append(AmmoUpgrade(origin))
	}
	if(powerup == Powerups.NUKE){
		printl("dropping nuke")
		spawnedPowerups.append(Nuke(origin))
	}
	if(powerup == Powerups.DEATH_MACHINE){
		printl("dropping death machine")
		spawnedPowerups.append(DeathMachine(origin))
	}
}

function ResetPlayerScores(){
	foreach(ent in HookController.PlayerGenerator()){
		ent.ValidateScriptScope()
		if("score" in ent.GetScriptScope()){
			ent.GetScriptScope()["score"] = 0
		}
	}
}

function UpdatePlayerScores(){
	local scores = []
	foreach(ent in HookController.PlayerGenerator()){
		if(ent.IsSurvivor()){
			ent.ValidateScriptScope()
			if(!("score" in ent.GetScriptScope())){
				ent.GetScriptScope()["score"] <- 0
			}
			scores.append(ent)
		}
	}
	scores.sort(function(a, b){
		if(a.GetScriptScope()["score"] < b.GetScriptScope()["score"]) return -1
		if(a.GetScriptScope()["score"] > b.GetScriptScope()["score"]) return 1
		return 0
	})
	for(local i=0; i < scores.len(); i++){
		local playerName = scores[i].GetPlayerName()
		/*if(playerName.len() > 16){
			playerName = playerName.slice(0, 14) + "..."
		}*/
		HUD.Fields["player" + (i + 1)].dataval = scores[i].GetScriptScope()["score"] + " - " + playerName
	}
	for(local i=4; i > scores.len(); i--){
		HUD.Fields["player" + i].dataval = ""
	}
}

function AllowTakeDamage(params){
	local attacker = params.Attacker
	local victim = params.Victim
	local weapon = params.Weapon
	local damagetype = params.DamageType
	
	//printl(params.DamageType)
	
	if(victim && attacker){
		if(victim.GetClassname() == "player" && victim.IsSurvivor()){
			if(attacker.GetClassname() == "infected"){
				attacker.ValidateScriptScope()
				attacker.GetScriptScope()["lastPosTime"] <- Time()
				params["DamageDone"] = Game.GetZombieDamage()
			}
			if(attacker.GetClassname() == "player" && !attacker.IsSurvivor()){
				if(attacker.GetZombieType() != HookController.ZombieTypes.TANK){
					params["DamageDone"] = Game.GetSpecialDamage()
				} else {
					params["DamageDone"] = Game.GetTankDamage()
				}
			}
		}
		if((victim.GetClassname() == "infected" || (victim.GetClassname() == "player" && victim.GetTeam() == 3)) && attacker.GetClassname() == "player"){
			if(weapon){
				if(weapon.GetClassname() == "weapon_melee"){
					printl("infected meleed")
					if(victim.GetClassname() == "infected"){
						params["DamageDone"] = Game.GetZombieHealth() * Game.GetSetting("melee_damage_health_percent")
					} else {
						if(victim.GetZombieType() == 8){
							params["DamageDone"] = Game.GetTankHealth() * Game.GetSetting("melee_damage_health_percent")
						} else {
							params["DamageDone"] = Game.GetSpecialHealth() * Game.GetSetting("melee_damage_health_percent")
						}
					}
				}
			}
			if((damagetype & HookController.DamageTypes.BLAST) && (damagetype & HookController.DamageTypes.PLASMA)){ // grenade launcher
				/*if(victim.GetClassname() == "infected"){
					victim.TakeDamage(Game.GetZombieHealth() * Game.GetSetting("grenade_launcher_damage_health_percent"), 0, null)
					return false
					params["DamageDone"] = Game.GetZombieHealth() * Game.GetSetting("grenade_launcher_damage_health_percent")
				} else {
					if(victim.GetZombieType() == 8){
						params["DamageDone"] = Game.GetTankHealth() * Game.GetSetting("grenade_launcher_damage_health_percent")
					} else {
						params["DamageDone"] = Game.GetSpecialHealth() * Game.GetSetting("grenade_launcher_damage_health_percent")
					}
				}*/
			}
		}
	}
	
	return true
}

function PlayerCanSeePosition(player, end){
	local traceTable = {
		start = player.EyePosition()
		end = end
		ignore = player
	}
	TraceLine(traceTable)
	
	if((traceTable["pos"] - end).Length() < 1){
		return true
	}
	
	return false
}

function IsMelee(name){
	return name == "fireaxe" || name == "crowbar" || name == "cricket_bat" || name == "katana" || name == "baseball_bat" || name == "knife" || name == "electric_guitar" || name == "machete" || name == "frying_pan" || name == "tonfa"
}

function GetAverageSurvivorPosition(){
	local averageSurvivorPosition = Vector(0, 0, 0)
	local survivorCount = 0
	foreach(ent in HookController.PlayerGenerator()){
		if(ent.IsSurvivor()){
			survivorCount++
			averageSurvivorPosition += ent.GetOrigin()
		}
	}
	averageSurvivorPosition = averageSurvivorPosition.Scale(1.0 / survivorCount)
	
	return averageSurvivorPosition
}

function GetFarthestDistanceFromSurvivorAverage(){
	local averagePosition = GetAverageSurvivorPosition()
	local farthest = 0
	
	foreach(ent in HookController.PlayerGenerator()){
		if(ent.IsSurvivor()){
			local distance = (ent.GetOrigin() - averagePosition).Length()
			if(distance > farthest){
				farthest = distance
			}
		}
	}
	
	return farthest
}

function SpawnInfected(type){
	local averageSurvivorPosition = Vector(0, 0, 0)
	local randomPitch = RandomFloat(-90, 90)
	local randomYaw = RandomFloat(0, 360)
	local farthestSurvivorFromAverage = 0
	
	local survivorCount = 0
	foreach(ent in HookController.PlayerGenerator()){
		if(ent.IsSurvivor()){
			survivorCount++
			averageSurvivorPosition += ent.GetOrigin()
		}
	}
	averageSurvivorPosition = averageSurvivorPosition.Scale(1.0 / survivorCount)
	
	foreach(ent in HookController.PlayerGenerator()){
		if(ent.IsSurvivor()){
			local distance = (ent.GetOrigin() - averageSurvivorPosition).Length()
			if(distance > farthestSurvivorFromAverage){
				farthestSurvivorFromAverage = distance
			}
		}
	}
	
	//ghostSpecial.SetOrigin(averageSurvivorPosition + (QAngle(0, randomYaw, 0).Forward() * (Game.GetSetting("spawn_distance") + farthestSurvivorFromAverage)))
	
	//local positionCandidate = ghostSpecial.TryGetPathableLocationWithin(250)
	local positionCandidate = averageSurvivorPosition + (QAngle(0, randomYaw, 0).Forward() * (Game.GetSetting("spawn_distance") + farthestSurvivorFromAverage))
	
	/*foreach(ent in HookController.PlayerGenerator()){
		if(ent.IsSurvivor()){
			if(PlayerCanSeePosition(ent, positionCandidate) || PlayerCanSeePosition(ent, positionCandidate + Vector(0, 0, 31)) || PlayerCanSeePosition(ent, positionCandidate + Vector(0, 0, 62))){
				SpawnInfected(type)
				return
			}
		}
	}*/
	
	//ghostSpecial.SetOrigin(Vector(99999, 99999, 99999))
	
	/*if(!ZSpawn({type = type, pos = positionCandidate})){
		SpawnInfected(type)
	}*/
	local tries = 0
	while(!ZSpawn({type = type/*, pos = positionCandidate*/})){
		if(tries >= MAX_SPAWN_TRIES){
			return false
		}
		printl("Failed to spawn infected, trying again...")
		tries++
	}
	return true
}

function UseCanceled(target){
	for(local i=0; i < itemUseQueue.len(); i++){
		if(itemUseQueue[i]["target"] == target){
			itemUseQueue.remove(i)
			target.GetScriptScope()["disabled"] <- Time()
			return
		}
	}
}

function UseFinished(target){ // TODO HANDLE MELEES
	for(local i=0; i < itemUseQueue.len(); i++){
		if(itemUseQueue[i]["target"] == target){
			local player = itemUseQueue[i]["player"]
			itemUseQueue.remove(i)
			if("door" in target.GetScriptScope()){
				if(player.GetScriptScope()["score"] >= target.GetScriptScope()["price"]){
					UnlockDoor(target, player, target.GetScriptScope()["door"], target.GetScriptScope()["price"])
				}
				return
			}
			
			target.GetScriptScope()["disabled"] <- Time()
			
			local weapon = target.GetScriptScope()["weapon"]
			local cost = g_ModeScript.Game.GetSetting(weapon + "_cost")
			if(player.GetScriptScope()["score"] >= cost){
				local invTable = {}
				GetInvTable(player, invTable)
				
				if(IsMelee(weapon) || weapon == "pistol" || weapon == "pistol_magnum" || weapon == "upgradepack_explosive" || weapon == "upgradepack_incendiary" || weapon == "molotov" || weapon == "pipe_bomb" || weapon == "vomitjar" || weapon == "first_aid_kit" || weapon == "defibrillator" || weapon == "pain_pills" || weapon == "adrenaline"){
					if(("slot1" in invTable && (invTable["slot1"].GetClassname() == "weapon_" + weapon || weapon == invTable["slot1"].GetProp("m_strMapSetScriptName"))) || ("slot2" in invTable && invTable["slot2"].GetClassname() == "weapon_" + weapon) || ("slot3" in invTable && invTable["slot3"].GetClassname() == "weapon_" + weapon) || ("slot4" in invTable && invTable["slot4"].GetClassname() == "weapon_" + weapon)){
						player.PlaySoundOnClient("Buttons.snd11")
						return
					}
				}
				
				player.GetScriptScope()["score"] -= cost
				g_ModeScript.UpdatePlayerScores()
				
				if("slot0" in invTable && invTable["slot0"].GetClassname() == "weapon_" + weapon){
					printl("giving ammo")
					if(weapon == "rifle_m60"){
						invTable["slot0"].SetClip(M60_MAX_AMMO)
					} else if(weapon == "grenade_launcher"){
						player.SetAmmo(invTable["slot0"], GRENADE_LAUNCHER_MAX_AMMO)
					} else {
						player.GiveItem("ammo")
					}
				} else if(weapon == "chainsaw" && "slot1" in invTable && invTable["slot1"].GetClassname() == "weapon_" + weapon){
					invTable["slot1"].SetClip(CHAINSAW_MAX_AMMO)
				} else {
					if(IsMelee(weapon)){
						player.GiveItem(weapon)
					} else {
						player.GiveItem("weapon_" + weapon)
					}
				}
			}
		}
	}
}

function OnGameEvent_player_death(params){
	local attacker = null
	if("attacker" in params){
		attacker = GetPlayerFromUserID(params.attacker)
	}
	
	local infected = null
	if("userid" in params){
		infected = GetPlayerFromUserID(params.userid)
	}
	if("entityid" in params){
		infected = EntIndexToHScript(params.entityid)
	}
	
	if(!infected || !infected.IsValid()){
		return
	}
	
	if(attacker && attacker.GetClassname() == "player" && attacker.IsSurvivor() && (infected.GetClassname() == "infected" || (infected.GetClassname() == "player" && infected.GetTeam() == 3))){
		if(infected.GetClassname() == "infected"){
			attacker.GetScriptScope()["score"] += Game.GetZombieScore()
		} else if(infected.GetClassname() == "player"){
			if(infected.GetZombieType() != HookController.ZombieTypes.TANK){
				attacker.GetScriptScope()["score"] += Game.GetSpecialScore()
			} else {
				attacker.GetScriptScope()["score"] += Game.GetTankScore()
			}
		}
		
		local powerupDrop = RandomFloat(0, 1)
		if(GetTotalInfected() == 0 && Game.GetZombiesToSpawn() <= 0 && Game.IsTankWave()){
			printl("possible max ammo drop")
			local weaponDrop = RandomFloat(0, 1)
			if(powerupDrop < 0.5){
				DropPowerup(infected.GetOrigin() + Vector(0, 0, 32), Powerups.MAX_AMMO)
			}
			if(weaponDrop < 0.5){
				//DropCSSWeapon(infected.GetOrigin())
			}
		} else if(powerupDrop < Game.GetSetting("powerup_drop_chance")){
			DropPowerup(infected.GetOrigin() + Vector(0, 0, 32))
		}
	}
	UpdatePlayerScores()
}

function OnGameEvent_player_use(params){
	local player = GetPlayerFromUserID(params.userid)
	local target = EntIndexToHScript(params.targetid)
	
	printl(target)
	if(target.GetPropEntity("m_hScriptUseTarget") != null){
		/*printl("disabled" in target.GetPropEntity("m_hScriptUseTarget").GetScriptScope())
		if("disabled" in target.GetPropEntity("m_hScriptUseTarget").GetScriptScope()){
			printl(Time() >= target.GetPropEntity("m_hScriptUseTarget").GetScriptScope()["disabled"] + Game.GetSetting("item_cooldown_time"))
		}
		printl(itemUseQueue.len())*/
		
		if(!("disabled" in target.GetPropEntity("m_hScriptUseTarget").GetScriptScope()) || Time() >= target.GetPropEntity("m_hScriptUseTarget").GetScriptScope()["disabled"] + Game.GetSetting("item_cooldown_time")){
			local foundPlayer = null
			for(local i=0; i < itemUseQueue.len(); i++){
				local table = itemUseQueue[i]
				if(table["player"] == player){
					foundPlayer = i
					break
				}
			}
			
			if(!foundPlayer){
				//printl("appending to queue")
				itemUseQueue.append({player = player, target = target.GetPropEntity("m_hScriptUseTarget"), time = Time()})
			} else if(Time() >= itemUseQueue[foundPlayer]["time"] + Game.GetSetting("item_use_time")){
				printl("failed to remove previous use action")
				itemUseQueue.remove(foundPlayer)
				itemUseQueue.append({player = player, target = target.GetPropEntity("m_hScriptUseTarget"), time = Time()})
			}
		}
	}
}

function OnGameEvent_survival_round_start(params){
	Game.StartWave()
}

function OnBileExplode(thrower, startPosition, position){
	foreach(ent in HookController.EntitiesByClassname("infected")){
		printl(ent)
		local traceTable = {
			start = ent.GetOrigin()
			end = ent.GetOrigin() - Vector(0, 0, 128)
			ignore = ent
		}
		TraceLine(traceTable)
		if(!("hit" in traceTable)){
			printl("Culling " + ent)
			ent.Kill()
		}
	}
}

function AddBuyableDoor(ent){
	local price = ent.GetName().slice("zombies_door".len(), ent.GetName().find("_", "zombies_door".len())).tointeger()
	
	local useTarget = SpawnEntityFromTable("point_script_use_target", {model = ent.GetName()})
	useTarget.ValidateScriptScope()
	useTarget.GetScriptScope()["OnUseCanceled"] <- function(){g_ModeScript.UseCanceled(self)}
	useTarget.GetScriptScope()["OnUseFinished"] <- function(){g_ModeScript.UseFinished(self)}
	useTarget.GetScriptScope()["door"] <- ent
	useTarget.GetScriptScope()["price"] <- price

	useTarget.ConnectOutput("OnUseCanceled", "OnUseCanceled")
	useTarget.ConnectOutput("OnUseFinished", "OnUseFinished")
	
	useTarget.SetProgressBarFinishTime(g_ModeScript.Game.GetSetting("door_use_time"))
	useTarget.SetProgressBarText("Open Door")
	useTarget.SetProgressBarSubText(price + " points")
}

function UnlockDoor(target, player, door, cost){
	door.Input("Unlock")
	door.Input("Open")
	player.GetScriptScope()["score"] -= cost
	UpdatePlayerScores()
	target.Kill()
}

function OnGameplayStart(){
	ResetPlayerScores()
	UpdatePlayerScores()
	
	foreach(ent in HookController.EntitiesByName("zombies_door*")){
		AddBuyableDoor(ent)
	}
	
	EntFire("survival_nav_blocker", "UnblockNav")
	/*EntFire("relay_delete_coop_survivors", "Trigger")
	EntFire("relay_survivor_spawn", "Trigger")
	EntFire("relay_setup_survival", "Trigger", "", 0.001)
	EntFire("delete_coop_ents_postIO", "Trigger", "", 0.001)*/
	
	//Convars.SetValue("mp_gamemode", "Coop")
	
	HookController.DoNextTick(function(){
		local entitiesToSpawn = []
		foreach(ent in g_ModeScript.HookController.EntitiesByClassname("weapon_*_spawn")){
			printl(ent)
			if(ent.GetClassname().find("_spawn") == null){
				continue
			}
			if(ent.GetClassname() != "weapon_ammo_spawn"){
				if(ent.GetClassname() != "weapon_spawn"){
					//printl("spawning " + ent.GetClassname().slice(0, ent.GetClassname().find("_spawn")))
					//SpawnEntityFromTable(ent.GetClassname().slice(0, ent.GetClassname().find("_spawn")), {origin = ent.GetOrigin(), angles = ent.GetAngles().ToKVString(), spawnflags = 3})
					local name = UniqueString("cod_zombies_item_spawn")
					local weaponName = ent.GetClassname().slice("weapon_".len(), ent.GetClassname().find("_spawn"))
					if(weaponName == "melee"){
						weaponName = ent.GetProp("m_iszMeleeWeapon")
					}
					local prop = SpawnEntityFromTable("prop_dynamic_override", {model = ent.GetProp("m_ModelName"), origin = ent.GetOrigin(), angles = ent.GetAngles().ToKVString(), targetname = name})
					prop.ValidateScriptScope()
					prop.GetScriptScope()["weapon"] <- weaponName
					
					prop.SetGlowType(2)
					prop.SetGlowColor(200, 200, 200)
					prop.SetGlowRange(200)
					//prop.SetGlowRangeMin(50)
					
					local useTarget = SpawnEntityFromTable("point_script_use_target", {model = name})
					useTarget.ValidateScriptScope()
					useTarget.GetScriptScope()["OnUseCanceled"] <- function(){g_ModeScript.UseCanceled(self)}
					useTarget.GetScriptScope()["OnUseFinished"] <- function(){g_ModeScript.UseFinished(self)}
					useTarget.GetScriptScope()["weapon"] <- weaponName
					
					useTarget.ConnectOutput("OnUseCanceled", "OnUseCanceled")
					useTarget.ConnectOutput("OnUseFinished", "OnUseFinished")
					
					useTarget.SetProgressBarFinishTime(g_ModeScript.Game.GetSetting("item_use_time"))
					useTarget.SetProgressBarText("Buy " + g_ModeScript.Game.GetSetting(weaponName + "_name"))
					useTarget.SetProgressBarSubText(g_ModeScript.Game.GetSetting(weaponName + "_cost") + " points")
					
					ent.Kill()
				}
			} else {
				ent.Kill()
			}
		}
		
		foreach(ent in g_ModeScript.HookController.EntitiesByClassname("upgrade_laser_sight")){
			ent.Kill()
		}
	})
	
	/*ZSpawn({type = HookController.ZombieTypes.BOOMER, pos = Vector(0, 0, 0)})
	HookController.DoNextTick(function(){
		foreach(ent in g_ModeScript.HookController.PlayerGenerator()){
			if(ent.GetZombieType() == g_ModeScript.HookController.ZombieTypes.BOOMER){
				printl(ent)
				ent.RemoveFlag(128)
				ent.RemoveFlag(256)
				ent.AddFlag(g_ModeScript.HookController.Flags.FROZEN)
				ent.SetProp("m_isGhost", 1)
				ghostSpecial = ent
				return
			}
		}
	})*/
}

function OnTick(){
	//printl(ghostSpecial)
	
	for(local i=0; i < spawnedPowerups.len(); i++){
		local powerup = spawnedPowerups[i]
		if(powerup.IsUsed()){
			printl("used")
			spawnedPowerups.remove(i)
			i--
			continue
		}
		if(Time() >= powerup.GetSpawnTime() + Game.GetSetting("powerup_lifetime")){
			printl("powerup expired")
			powerup.OnExpired()
			spawnedPowerups.remove(i)
			i--
			continue
		}
		if(Time() >= powerup.GetSpawnTime() + Game.GetSetting("powerup_blink_time")){
			powerup.StartBlinking()
		}
		foreach(player in HookController.PlayerGenerator()){
			if(!player.IsBot() && player.IsSurvivor() && (player.GetOrigin() + Vector(0, 0, 31) - powerup.GetOrigin()).Length() < 64){
				local traceTable = {
					start = player.GetOrigin() + Vector(0, 0, 31)
					end = powerup.GetOrigin()
					ignore = player
				}
				TraceLine(traceTable)
				
				if(("enthit" in traceTable && traceTable["enthit"] == powerup.GetModel()) || (traceTable["pos"] - powerup.GetOrigin()).Length() < 1){
					powerup.OnUsed(player)
				}
			}
		}
	}
	
	//Ent(1).SetHealthBuffer(Ent(1).GetHealthBuffer() + 1)
	//Ent(1).SetHealth(Ent(1).GetHealth() + 1)
	
	foreach(ent in HookController.PlayerGenerator()){
		ent.ValidateScriptScope()
		if("damageCount" in ent.GetScriptScope() && ent.GetProp("m_iDamageCount") > ent.GetScriptScope()["damageCount"]){
			ent.GetScriptScope()["lastHit"] <- Time()
		}
		if("lastHit" in ent.GetScriptScope() && !ent.IsIncapacitated() && Time() >= ent.GetScriptScope()["lastHit"] + Game.GetSetting("regen_delay")){
			if(ent.GetHealth() + ent.GetHealthBuffer() < ent.GetMaxHealth()){
				ent.SetHealthBuffer(ent.GetHealthBuffer() + Game.GetSetting("regen_rate"))
			} else {
				ent.SetHealth(ent.GetMaxHealth())
				ent.SetHealthBuffer(0)
			}
		}
		ent.GetScriptScope()["damageCount"] <- ent.GetProp("m_iDamageCount")
		
		if(ent.GetActiveWeapon()){
			if((ent.GetActiveWeapon().GetClassname() == "weapon_rifle_m60" || ent.GetActiveWeapon().GetClassname() == "weapon_chainsaw")){
				if(ent.GetActiveWeapon().GetClip() <= 1 || ent.GetActiveWeapon().GetClip() == 255){
					ent.AddDisabledButton(HookController.Keys.ATTACK)
					ent.GetActiveWeapon().SetProp("m_flNextPrimaryAttack", MAX_FLOAT)
					ent.GetActiveWeapon().SetClip(255)
				} else if(ent.GetActiveWeapon().GetProp("m_flNextPrimaryAttack") >= MAX_FLOAT - 1){
					ent.RemoveDisabledButton(HookController.Keys.ATTACK)
					ent.GetActiveWeapon().SetProp("m_flNextPrimaryAttack", Time())
				}
			} else if(ent.HasDisabledButton(HookController.Keys.ATTACK)) {
				ent.RemoveDisabledButton(HookController.Keys.ATTACK)
			}
		}
	}
	
	foreach(ent in HookController.EntitiesByClassname("point_script_use_target")){
		ent.ValidateScriptScope()
		if("disabled" in ent.GetScriptScope()){
			if(Time() < ent.GetScriptScope()["disabled"] + Game.GetSetting("item_cooldown_time")){ // still in cooldown
				ent.StopUse()
			}
		}
	}
	DirectorOptions.SpawnSetPosition = GetAverageSurvivorPosition() + QAngle(RandomFloat(-15, 15), RandomFloat(-180, 180), 0).Forward().Scale(SPAWN_RADIUS + GetFarthestDistanceFromSurvivorAverage() + (GetFarthestDistanceFromSurvivorAverage() < SPAWN_RADIUS_GRACE ? SPAWN_RADIUS : 0))
}