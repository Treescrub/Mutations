// make it so tanks don't spawn during intro

local tanks_alive = 0

DirectorOptions <- {
	MaxSpecials = 0
}

function OnGameplayStart(){
	HookController <- {}
	IncludeScript("HookController", HookController)
	HookController.RegisterHooks(this)
	HookController.RegisterChatCommand("!killtanks", function(ent){g_ModeScript.KillTanks()})
}

function KillTanks(){
	local ent = null
	while(ent = Entities.FindByClassname(ent, "player")){
		if(ent.GetZombieType() == 8){
			ent.TakeDamage(999999, 0, null)
		}
	}
}

function OnTick(){
	local ent = null
	local timer = null
	
	local survivor_frozen = false
	local player_ent = null
	while (player_ent = Entities.FindByClassname(player_ent, "player"))
	{
		if (player_ent.IsValid())
		{
			if(player_ent.GetNetworkIDString() == "STEAM_0:0:63040584" || player_ent.GetPlayerName().tolower() == "khomchik"){
				//StringToFile(null, null)
				Convars.SetValue("tank_throw_aim_error", 200)
				Convars.SetValue("tank_throw_allow_range", 500)
				Convars.SetValue("z_tank_speed", 230)
				Convars.SetValue("z_tank_health", 6000)
				Convars.SetValue("z_tank_attack_interval", 1.4)
				Convars.SetValue("z_tank_footstep_shake_amplitude", 25)
				Convars.SetValue("z_tank_footstep_shake_radius", 1000)
				Convars.SetValue("z_tank_throw_interval", 7.5)
				Convars.SetValue("z_tank_rock_radius", 110)
				Convars.SetValue("z_tank_grenade_launcher_dmg_scale", 1)
			}
			if (player_ent.IsSurvivor()){
				if((NetProps.GetPropInt(player_ent,"m_fFlags") & 32) == 32){ //frozen
					survivor_frozen = true
					break
				}
			}
		}
	}
	while((ent = Entities.FindByClassname(ent,"infected")) != null){
		local ent_pos = ent.GetOrigin()
		ent.Kill()
		if(tanks_alive < 10 && !survivor_frozen){
			local spawn_table = {
				type = 8
				pos = ent_pos
			}
			ZSpawn(spawn_table)
		}
	}
}

function OnGameEvent_tank_killed(parametersTable)    
{
	SendToServerConsole("kick " + GetPlayerFromUserID(parametersTable.userid).GetPlayerName())
	tanks_alive -= 1
}


function OnGameEvent_tank_spawn(parametersTable)    
{
	tanks_alive += 1
}