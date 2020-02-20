/*
	Starting firing, switching to another weapon, and switching back to the launcher freezes the game (Fixed by setting duration of attacks greater than 0)
*/

local VIEWMODEL = "models/weapons/melee/v_launcher.mdl"
local WORLDMODEL = "models/w_models/weapons/w_grenade_launcher.mdl"
local TRACE_MAX_DISTANCE = 99999

local controller = {}
IncludeScript("HookController", controller)
controller.RegisterCustomWeapon(VIEWMODEL, WORLDMODEL, "launcher")


local launchpower = 0

DirectorOptions <- {
	cm_NoSurvivorBots = 1
}

function FireGrenade(player, explosionEntity) {
	
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
	DoEntFire("!self", "Explode", "", 0, player, explosionEntity)
	EmitSoundOn("GrenadeLauncher.Explode", explosionEntity)
}

function NumSurvivors(){
	local count = 0
	
	local ent = null
	while(ent = Entities.FindByClassname(ent, "player")){
		if(ent != null && ent.IsValid() && ent.IsSurvivor()){
			count = count + 1
		}
	}
	
	return count
}

function SetLaunchPower(power){
	launchpower = power
}

function SetPowerText(text){
	
}

function SetDamageText(text){
	
}

function ResetPowerText(){
	
}

function ResetDamageText(){
	
}

function OnGameplayStart(){
	controller.Start()
	
	local ent = null
	while(ent = Entities.FindByClassname(ent,"trigger_hurt")){
		NetProps.SetPropInt(ent,"m_bitsDamageInflict",0)
	}
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

function AllowTakeDamage(params){
	local DamageType = params.DamageType
	local Victim = params.Victim
	local DamageDone = params.DamageDone
	
	if(Victim != null && Victim.IsValid() && Victim.GetClassname() == "player" && Victim.IsSurvivor()){
		if(DamageType == 64){
			Victim.SetVelocity(Vector(Victim.GetVelocity().x, Victim.GetVelocity().y, launchpower * 3.25 + 425))
			NetProps.SetPropFloat(Victim, "m_Local.m_flFallVelocity",0)
			if(launchpower > 15){
				params.DamageDone = launchpower / 10
			} else {
				params.DamageDone = 0
			}
		}
		if(DamageType == 32){
			return false
		}
		return true
	}
	if(DamageType == 64){
		params.DamageDone = (launchpower * (12.5 / NumSurvivors())) + 150
	}
	return true
}