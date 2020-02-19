/* TODO
	Add zedtime start and end sounds from KF2
	Make it chances, not points?
*/

/* Changelog
	v1.1
		ZED Time activations can no longer chain together potentially indefinitely
		Now easier to activate ZED Time over longer periods of time
		Headshots now help activate ZED Time faster
		Increased common limit to have more zombies to shoot when ZED Time activates
		Players now move faster in ZED Time
		Increased ZED Time
*/

/*
Scores
	Survivor killed - 200
	Tank killed - 150
	Witch killed - 150
	Survivor downed - 60
	Boomer killed - 50
	Smoker, Charger, Jockey, Hunter killed - 40
	Survivor boomed by explosion - 30
	Spitter killed - 30
	Common killed - 15
	Player hurt - damage amount
	
Modifiers
	Killed by explosion - 2
	Killed by fire - 1.5
	Killed by headshot - 1.5
	Averaged team intensity - the higher the intensity, the higher the points
*/

HookController <- {}
IncludeScript("HookController", HookController)
HookController.RegisterHooks(this)
HookController.IncludeImprovedMethods()

local points = 0
local stopZedTime = 999999999
local zedTimeCount = 0

local correction = SpawnEntityFromTable("color_correction", {StartDisabled = true, fadeInDuration = 0.5, fadeOutDuration = 0.1, minfalloff = 1, maxfalloff = 0, filename = "materials/correction/zedtime.raw", exclusive = true})

const HEADSHOT_MODIFIER = 1.5
const ZED_TIME_COUNT_RESET = 15
const MAX_ZED_TIME_ACTIVATIONS = 4
local POINT_DECAY_RATE = 1 / 20
const ZED_TIME_THRESHOLD = 75
const ZED_TIME_REDUCTION = 40
const ZED_TIME = 2
const ZED_TIMESCALE = 0.4

DirectorOptions <- {
	CommonLimit = 45
}


local scores = {
	survivor_killed = 200
	tank_killed = 150
	witch_killed = 150
	survivor_downed = 60
	boomer_killed = 50
	smoker_killed = 40
	charger_killed = 40
	jockey_killed = 40
	hunter_killed = 40
	survivor_boomed = 30
	spitter_killed = 30
	common_killed = 15
}


function AddPoints(score){
	points += score
	printl("added " + score + " points, new points: " + points)
}

function DecayPoints(){
	points = points - (POINT_DECAY_RATE / ((GetAveragedSurvivorIntensity() + 75) / 100.0))
	if(points < 0){
		points = 0
	}
}

function GetModifier(ent, damageType){
	if(damageType == HookController.DamageTypes.BLAST){
		return 2.0
	}
	if(damageType == HookController.DamageTypes.BURN){
		return 1.5
	}
	return 1.0
}

function GetInfectedScore(ent){
	if(ent.IsPlayer() && ent.GetZombieType() == HookController.ZombieTypes.TANK){
		return scores["tank_killed"]
	}
	if(ent.GetClassname() == "witch"){
		return scores["witch_killed"]
	}
	if(ent.IsPlayer() && ent.GetZombieType() == HookController.ZombieTypes.BOOMER){
		return scores["boomer_killed"]
	}
	if(ent.IsPlayer() && ent.GetZombieType() == HookController.ZombieTypes.SMOKER){
		return scores["smoker_killed"]
	}
	if(ent.IsPlayer() && ent.GetZombieType() == HookController.ZombieTypes.CHARGER){
		return scores["charger_killed"]
	}
	if(ent.IsPlayer() && ent.GetZombieType() == HookController.ZombieTypes.JOCKEY){
		return scores["jockey_killed"]
	}
	if(ent.IsPlayer() && ent.GetZombieType() == HookController.ZombieTypes.HUNTER){
		return scores["hunter_killed"]
	}
	if(ent.IsPlayer() && ent.GetZombieType() == HookController.ZombieTypes.SPITTER){
		return scores["spitter_killed"]
	}
	if(ent.GetClassname() == "infected"){
		return scores["common_killed"]
	}
}

/*function WillDie(ent, damage){
	if(ent.IsPlayer()){
		if(ent.IsSurvivor()){
			return ent.GetHealth() + ent.GetHealthBuffer() - damage <= 0
		} else {
			return ent.GetHealth() - damage <= 0
		}
	} else {
		return ent.GetHealth() - damage <= 0
	}
}*/

function GetIntensityModifier(){
	return (GetAveragedSurvivorIntensity() + 75) / 100.0
}

function GetAveragedSurvivorIntensity(){
	local average = 0
	local count = 0
	foreach(survivor in HookController.SurvivorGenerator()){
		if(!survivor.IsDead()){
			average += survivor.GetProp("m_clientIntensity")
			count++
		}
	}
	
	if(count == 0){
		return 0
	}
	
	return average / count
}

function PlayZedTimeStart(){
	/*local sound = SpawnEntityFromTable("ambient_generic", {message = "Instructor.LessonStart", spawnflags = 33, origin = Ent(1).GetOrigin()})
	sound.Input("PlaySound")
	HookController.ScheduleTask(function(){sound.Kill()}, ZED_TIME, {sound = sound})*/
	foreach(player in HookController.PlayerGenerator()){
		player.PlaySoundOnClient("Hint.Critical")
	}
}

function PlayZedTimeStop(){
	/*foreach(player in HookController.PlayerGenerator()){
		player.PlaySoundOnClient("Hint.BigReward")
	}*/
}

function StartZedTime(){
	points = ZED_TIME_REDUCTION
	HookController.SetTimescale(ZED_TIMESCALE, 0.01, 0.01)
	if(Time() >= stopZedTime){
		PlayZedTimeStart()
	}
	zedTimeCount++
	stopZedTime = Time() + ZED_TIME
	correction.Enable()
	foreach(player in HookController.PlayerGenerator()){
		player.SetProp("m_flLaggedMovementValue", 1.2)
	}
}

function StopZedTime(){
	HookController.SetTimescale(1, 0.05, 0.05)
	correction.Disable()
	points = 0
	PlayZedTimeStop()
	foreach(player in HookController.PlayerGenerator()){
		player.SetProp("m_flLaggedMovementValue", 1)
	}
}

function OnTick(){
	if(Time() >= stopZedTime + ZED_TIME_COUNT_RESET){
		zedTimeCount = 0
	}
	if(points >= ZED_TIME_THRESHOLD && zedTimeCount <= MAX_ZED_TIME_ACTIVATIONS){
		StartZedTime()
	}
	if(Time() >= stopZedTime){
		StopZedTime()
	}
	DecayPoints()
}

function AllowTakeDamage(params){
	local attacker = params["Attacker"]
	local victim = params["Victim"]
	local damage = params["DamageDone"]
	local damageType = params["DamageType"]
	
	return true
}

function OnGameEvent_player_hurt(params){
	if("userid" in params && "dmg_health" in params){
		local victim = GetPlayerFromUserID(params["userid"])
		local damage = params["dmg_health"]
		
		if(victim.IsSurvivor()){
			AddPoints(damage)
		}
	}
}

function OnGameEvent_player_now_it(params){
	if(params["exploded"]){
		AddPoints(scores["survivor_boomed"] * GetIntensityModifier())
	}
}

function OnGameEvent_player_death(params){
	local ent = null
	if("userid" in params){
		ent = GetPlayerFromUserID(params["userid"])
	} else {
		ent = EntIndexToHScript(params["entityid"])
	}
	if(ent.IsPlayer() && ent.IsSurvivor()){
		AddPoints(scores["survivor_killed"] * GetIntensityModifier())
	} else {
		AddPoints(GetInfectedScore(ent) * GetIntensityModifier() * GetModifier(ent, params["type"]) * ("headshot" in params && params["headshot"] ? HEADSHOT_MODIFIER : 1))
	}
}

function OnGameEvent_player_incapacitated(params){
	AddPoints(scores["survivor_downed"] * GetIntensityModifier())
}

function OnGameplayStart(){
	HookController.SetTimescale(1)
}