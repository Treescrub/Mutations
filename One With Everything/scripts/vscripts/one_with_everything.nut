local VIEWMODEL = "models/weapons/melee/v_launcher.mdl"
local WORLDMODEL = "models/w_models/weapons/w_grenade_launcher.mdl"
local TRACE_MAX_DISTANCE = 99999

local EXPLOSION_ENTITY =
{
	iRadiusOverride = 135
	fireballsprite = "sprites/zerogxplode.spr"
	ignoredClass = 0
	iMagnitude = 500
	rendermode = 5
	spawnflags = 2 | 64 // Repeatable | No Sound
	origin = Vector(0, 0, 0)
}

local controller = {}
IncludeScript("HookController",controller)
controller.RegisterHooks(this)
controller.RegisterCustomWeapon(VIEWMODEL, WORLDMODEL, "launcher")

class Jumper {
	constructor(ent){
		entity = ent
	}
	
	function GetEntity(){
		return entity
	}
	
	function GetDoubleJumped(){
		return double_jumped
	}
	
	function SetDoubleJumped(bool){
		double_jumped = bool
	}
	
	function SetInAir(bool){
		in_air = stopped_being_on_ground
		stopped_being_on_ground = bool
	}
	
	function IsInAir(){
		return in_air
	}
	
	double_jumped = false
	stopped_being_on_ground = false
	in_air = false
	entity = null
}

local HUD = {
	Fields = {
		time 	= { slot = HUD_RIGHT_TOP, dataval = "Time: 0", flags = HUD_FLAG_NOBG | HUD_FLAG_ALIGN_CENTER, name = "time" }
		power	= { slot = HUD_LEFT_TOP, dataval = "Power: 0%", flags = HUD_FLAG_ALIGN_CENTER, name = "power" }
		damage 	= { slot = HUD_MID_TOP, dataval = "Damage: 0", flags = HUD_FLAG_ALIGN_CENTER, name = "damage" }
	}
}

HUDSetLayout(HUD)

local jumper = null
local explosionEntity = SpawnEntityFromTable("env_explosion", EXPLOSION_ENTITY)
local adrenaline_time = 0

local launchpower = 0

DirectorOptions <-
{
	cm_NoSurvivorBots = 1
	cm_SpecialRespawnInterval = 25
	cm_MaxSpecials = 2
	cm_AutoReviveFromSpecialIncap = 1
	SurvivorMaxIncapacitatedCount = 1
	TankHitDamageModifierCoop = 0.5
	SpitterLimit = 0
	CommonLimit = 40
	SpecialInitialSpawnDelayMax = 25
	SpecialInitialSpawnDelayMin = 35
}



function IncreaseAdrenaline(amount, ent){
	adrenaline_time += amount
	HUD.Fields.time.dataval = "Time: " + ceil(adrenaline_time)
	ent.UseAdrenaline(adrenaline_time)
}



function GetOppositeVector(vector){
	if(vector == null || vector.Length() == 0){
		return null
	}
	return vector * (-1 / vector.Length())
}

function FireGrenade(player) {
	local traceStartPoint = player.EyePosition()	
	local traceEndpoint = player.EyePosition() + (player.EyeAngles().Forward() * TRACE_MAX_DISTANCE)
	
	local traceTable =
	{
		start = player.EyePosition()
		end = traceEndpoint
		ignore = player
	}
	TraceLine(traceTable) // Performs the trace.
	
	explosionEntity.SetOrigin(traceTable.pos)
	
	// BOOM!
	NetProps.SetPropEntity(explosionEntity, "m_hInflictor", player)
	DoEntFire("!self", "Explode", "", 0, player, explosionEntity)
	EmitSoundOn("GrenadeLauncher.Explode", explosionEntity)
}

function SetLaunchPower(power){
	launchpower = power
}

function SetPowerText(text){
	HUD.Fields.power.dataval = text
}

function SetDamageText(text){
	HUD.Fields.damage.dataval = text
}

function ResetPowerText(){
	SetPowerText("Power: 0%")
}

function ResetDamageText(){
	SetDamageText("Damage: 0")
}



function OnTick(){
	if(jumper == null){
		jumper = Jumper(Ent(1))
	}
	if(jumper.GetEntity() != null && jumper.GetEntity().IsValid()){
		if((NetProps.GetPropInt(jumper.GetEntity(),"m_fFlags") & 1)){
			jumper.SetDoubleJumped(false)
			jumper.SetInAir(false)
		} else {
			jumper.SetInAir(true)
		}
	}
	if(adrenaline_time < 0.033){
		adrenaline_time = 0
	} else {
		adrenaline_time -= 0.033
	}
	HUD.Fields.time.dataval = "Time: " + ceil(adrenaline_time)
}

function OnGameplayStart(){
	controller.Start()
	Convars.SetValue("z_gun_swing_coop_min_penalty",10)
	Convars.SetValue("z_gun_swing_coop_max_penalty",13)
	
	local ent = null
	while(ent = Entities.FindByClassname(ent,"trigger_hurt")){
		NetProps.SetPropInt(ent,"m_bitsDamageInflict",0)
	}
	
	local ent = null
	while(ent = Entities.FindByClassname(ent,"weapon_adrenaline_spawn")){
		ent.Kill()
	}
	
	if(SessionState.MapName.find("c3m1") != null){
		EntFire("ferry_winch_stop","Trigger")
		EntFire("ferry_winch_stop","Trigger","",1)
		EntFire("ferry_door_left_exit","Close","",2)
		EntFire("ferry_door_right_exit","Close","",2)
		EntFire("ferry_button_proxy","Kill","",2)
		EntFire("rental_breakable1_clip","Kill","",2)
		EntFire("swamp_clip_brush","Kill","",2)
		EntFire("ferry_sign_trigger","Enable","",2)
		EntFire("ferry_button","Kill","",2.1)
		EntFire("ferry_winch_start","Trigger","",2.1)
		EntFire("ferry_tram","SetSpeed","1",4)
		EntFire("ferry_tram_push","Kill","",62)
		EntFire("ferry_tram_hurt_trigger","Enable","",67)
		EntFire("ferry_tram_incap_trigger","Enable","",77)
	}
}

function OnKeyPressStart_Jump(player){
	if(player != null && player.IsValid() && player.IsSurvivor()){
		if((NetProps.GetPropInt(player,"m_fFlags") & 1) == 0 && !jumper.GetDoubleJumped()){
			if(jumper.IsInAir()){
				local velocity = player.GetVelocity()
				player.SetVelocity(Vector(velocity.x, velocity.y, 350))
				NetProps.SetPropFloat(player,"m_Local.m_flFallVelocity",0)
				jumper.SetDoubleJumped(true)
			} else {
				jumper.SetInAir(true)
			}
		}
	}
}

function OnGameEvent_witch_killed(params)    
{
	local userid = params.userid
	local witchid = params.witchid
	local oneshot = params.oneshot
	if(userid != -1){
		local amount = 5
		if(oneshot == 1){
			amount = 7.5
		}
		//IncreaseAdrenaline(amount,GetPlayerFromUserID(userid))
	}
}

function OnGameEvent_adrenaline_used(params)    
{
	local userid = params.userid
	IncreaseAdrenaline(0,GetPlayerFromUserID(userid))
}

function OnGameEvent_player_spawn(params){
	local userid = params.userid
	local player = GetPlayerFromUserID(userid)
		
	if(player.IsValid() && player.IsSurvivor() && !player.IsDead()){
		local invTable = {}
		GetInvTable(player, invTable)
		if("slot1" in invTable && NetProps.GetPropString(invTable["slot1"], "m_ModelName") != VIEWMODEL){
			player.GiveItem("launcher")
		}
	}
}

function OnGameEvent_player_death(params)
{
	local victim = null
	local attacker = null
	local attackerId = null
	local attackerEntId = null
	
	if("attackerentid" in params && params["attackerentid"] != null){
		attackerEntId = params["attackerentid"]
	}
	if ("userid" in params)
	{
		if (params["userid"] != null && params["userid"] != ""){
			victim = GetPlayerFromUserID(params["userid"])
		}
	}else if ("entityid" in params){
		if (params["entityid"] != null && params["entityid"] != "")
		victim = EntIndexToHScript(params["entityid"])
	}
	
	if ("attacker" in params)
	{
		if (params["attacker"] != null && params["attacker"] != ""){
			if(attackerEntId != null && EntIndexToHScript(attackerEntId) == explosionEntity){
				attacker = Ent(1)
			} else {
				attacker = GetPlayerFromUserID(params["attacker"])
			}
		}
	}
	if(attacker != null){
		if (victim.GetClassname() == "infected")
		{
			if(params.weapon == "melee"){
				IncreaseAdrenaline(1.2, attacker)
			} else {
				IncreaseAdrenaline(0.8, attacker)
			}
		} else {
			if(victim != attacker){
				if(victim.GetClassname() != "witch"){
					if(victim.GetZombieType() > 0 && victim.GetZombieType() < 7){
						if(params.weapon == "melee" || params.weapon == "player"){
							IncreaseAdrenaline(8, attacker)
						} else {
							IncreaseAdrenaline(4, attacker)
						}
					} else if(victim.GetZombieType() == 8){
						if(params.weapon == "melee"){
							IncreaseAdrenaline(12,attacker)
						} else {
							IncreaseAdrenaline(8, attacker)
						}
					}
				} else {
					IncreaseAdrenaline(5, attacker)
				}
			}
		}
	}
}

function AllowTakeDamage(params){
	local DamageType = params["DamageType"]
	local Victim = params["Victim"]
	local DamageDone = params["DamageDone"]
	
	if(Victim != null && Victim.IsValid() && Victim.IsPlayer() && Victim.IsSurvivor()){
		if(DamageType == 32){
			params["DamageDone"] = params["DamageDone"] / 2
		}
	}
	
	if(Victim != null && Victim.IsValid() && Victim.GetClassname() == "player" && Victim.IsSurvivor()){
		if(DamageType == 64){
			local playerLookAngles = Victim.EyeAngles()
			if(playerLookAngles.x < 90 && playerLookAngles.x > 83){
				playerLookAngles = QAngle(90, playerLookAngles.y, playerLookAngles.z)
			}
			local launchVector = ((GetOppositeVector(playerLookAngles.Forward())) * ((launchpower * 3.25) + 425))
			launchVector = Vector(launchVector.x / 1.25, launchVector.y / 1.25, launchVector.z)
			
			Victim.SetVelocity(launchVector + Vector(Victim.GetVelocity().x, Victim.GetVelocity().y, Victim.GetVelocity().z / 3))
			jumper.SetDoubleJumped(false)
			jumper.SetInAir(true)
			NetProps.SetPropFloat(Victim, "m_Local.m_flFallVelocity",0)
			if(launchpower > 15){
				params["DamageDone"] = launchpower / 10
			} else {
				params["DamageDone"] = 0
			}
		}
		if(DamageType == 32){
			return false
		}
		return true
	}
	if(DamageType == 64){
		params["DamageDone"] = (launchpower * 12.5) + 150
	}
	return true
}