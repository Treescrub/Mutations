/*
	HUD
		score for each player
		current wave
		zombies remaining
	special waves
		all hunter
		all charger
	tank every 5 waves
	powerups
		max ammo
		ammo upgrade (incendiary or explosive)
		nuke
	
*/

class ZombiesGame {
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
	
	tank_wave_counter = 0
	special_wave_counter = 0
	
	settings = {
		tank_wave = 5
		powerup_drop_chance = 0.05
		powerup_lifetime = 15
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
			model.SetRenderFX(4)
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
	}
	
	function OnExpired(){
		if(model && model.IsValid()){
			model.Kill()
		}
	}
	
	function OnTick(){}
	
	used = false
	origin = null
	spawnTime = null
	model = null
	user = null
}

class MaxAmmo extends ZombiesPowerup {
	constructor(origin){
		base.constructor(origin)
		model = SpawnEntityFromTable("prop_physics", {origin = origin, model = "props_collectables/backpack.mdl"})
	}
	
	function OnTick(){
		
	}
}

class AmmoUpgrade extends ZombiesPowerup {
	constructor(origin){
		base.constructor(origin)
		model = SpawnEntityFromTable("prop_physics", {origin = origin, model = "props_collectables/backpack.mdl"})
	}
	
	function OnTick(){
		if(user != null){
			
		}
	}
}

class Nuke extends ZombiesPowerup {
	constructor(origin){
		base.constructor(origin)
		model = SpawnEntityFromTable("prop_physics", {origin = origin, model = "props_collectables/backpack.mdl"})
	}
	
	function OnTick(){
		
	}
}

HookController <- {}
IncludeScript("HookController", HookController)
HookController.IncludeImprovedMethods()
HookController.RegisterHooks(this)

HUD <- {
	Fields = {
		wave = { slot = g_ModeScript.HUD_MID_TOP, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG, name = "wave" }
		zombies = { slot = g_ModeScript.HUD_MID_BOT, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG, name = "zombies" }
		player1 = { slot = g_ModeScript.HUD_TICKER, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG, name = "player1" }
		player2 = { slot = g_ModeScript.HUD_TICKER, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG, name = "player2" }
		player3 = { slot = g_ModeScript.HUD_TICKER, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG, name = "player3" }
		player4 = { slot = g_ModeScript.HUD_TICKER, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG, name = "player4" }
	}
}

Game <- ZombiesGame()

const NUM_POWERUPS = 3

enum Powerups {
	MAX_AMMO
	AMMO_UPGRADE
	NUKE
}

enum SpecialWaves {
	HUNTERS
	CHARGERS
}

local spawnedPowerups = []
local waveCount = 0

function StartWave(){
	if(Game.IsTankWave()){
		
	} else if(Game.IsSpecialWave()){
		local type = RandomInt(0, 1)
		if(type == SpecialWaves.HUNTERS){
			
		} else if(type == SpecialWaves.CHARGERS){
			
		}
	}
}

function EndWave(){
	
}

function DropPowerup(){
	local powerup = RandomInt(0, NUM_POWERUPS - 1)
	if(powerup == Powerups.MAX_AMMO){
		spawnedPowerups.append(MaxAmmo())
	}
	if(powerup == Powerups.AMMO_UPGRADE){
		spawnedPowerups.append(AmmoUpgrade())
	}
	if(powerup == Powerups.NUKE){
		spawnedPowerups.append(Nuke())
	}
}

function OnTick(){
	for(local i=0; i < spawnedPowerups.len(); i++){
		local powerup = spawnedPowerups[i]
		if(powerup.IsUsed()){
			delete spawnedPowerups[i]
			continue
		}
		if(Time() >= powerup.GetSpawnTime() + Game.GetSetting("powerup_lifetime")){
			powerup.OnExpired()
		}
		foreach(player in HookController.PlayerGenerator()){
			if(!player.IsBot() && player.IsSurvivor() && (player.GetOrigin() + Vector(0, 0, 31) - powerup.GetOrigin()).Length() < 64){
				local traceTable = {
					start = player.GetOrigin() + Vector(0, 0, 31)
					end = powerup.GetOrigin()
					ignore = player
				}
				TraceLine(traceTable)
				
				if(("enthit" in traceTable && traceTable["enthit"] == powerup.GetModel()) || traceTable["pos"] == powerup.GetOrigin()){
					powerup.OnUsed(player)
				}
			}
		}
	}
}