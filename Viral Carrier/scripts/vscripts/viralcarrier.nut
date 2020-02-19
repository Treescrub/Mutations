/* Powerups

Bile Bomb: acts as normal bile, commons cannot get biled. on destroyed, do trace recursion to find survivors within range, if any are within the range, apply boom
Eagle Eye: outlines of other survivors, but not the powerup activator
Elixir of Life: when the activator takes fatal damage, sets health to 65
Godmode: stops all damage and knockback
Adrenaline Shot: just adrenaline
Muddy Feet: not sure
Double Points: easy
*/

/* Development Map
	
	Add zombie blockers (use entity_blocker)
	Add hint on revive from incap
	Test zombies getting removed
*/

/* Bugs
	Point zombie does not play shove animation when already running to a run spot
*/

PrecacheEntityFromTable({classname = "prop_dynamic", model = "models/infected/common_male_fallen_survivor.mdl"})

PrecacheEntityFromTable({classname = "weapon_rifle_sg552"})
PrecacheEntityFromTable({classname = "weapon_smg_mp5"})
PrecacheEntityFromTable({classname = "weapon_sniper_awp"})
PrecacheEntityFromTable({classname = "weapon_sniper_scout"})

class CManager {
	enabled = true
	
	function Enable(){
		enabled = true
	}
	
	function Disable(){
		enabled = false
	}
	
	function GetEnabled(){
		return enabled
	}
}

// Manages almost all things to do with zombies
class CZombieManager extends CManager {
	spawner = null
	fleeTargets = null
	VitalCarrierGame = null
	
	lastCommonSpawn = 0
	lastHordeSpawn = 0
	lastPointZombieSpawn = 0
	spawnedPointZombies = 0
	respawningCommonsFromThreshold = false
	
	constructor(fleeTargets){
		spawner = SpawnEntityFromTable("commentary_zombie_spawner", {})
		this.fleeTargets = fleeTargets
		this.VitalCarrierGame = g_ModeScript.VitalCarrierGame
		g_ModeScript.HookController.RegisterOnTick(this)
	}
	
	function OnTick(){
		if(enabled){
			ManageCommons()
			ManagePointZombies()
		}
	}
	
	function ManageCommons(){
		if(g_ModeScript.VitalCarrierGame.IsStarted() && !g_ModeScript.VitalCarrierGame.IsGracePeriodStarted()){
			local commonCount = 0
			local common = null
			
			while(common = Entities.FindByClassname(common, "infected")){
				common.ValidateScriptScope()
				common.SetPropInt("m_mobRush", 1)
				if(!("pointZombie" in common.GetScriptScope()) && common.GetPropString("m_ModelName") != "models/infected/common_male_fallen_survivor.mdl"){
					foreach(area in g_MapScript.PlayAreas){
						if(!area.IsPointInside(common.GetOrigin())){
							common.Kill()
							ZSpawn({type = 0})
							break
						}
					}
					commonCount += 1
				}
			}
			
			if(Time() >= lastHordeSpawn + RandomInt(g_ModeScript.VitalCarrierGame.GetSetting("horde_spawn_time_min"), g_ModeScript.VitalCarrierGame.GetSetting("horde_spawn_time_max"))){
				for(local i=0; i < g_ModeScript.VitalCarrierGame.GetSetting("horde_zombies") - commonCount; i+=1){
					SpawnAndCheckCommon()
				}
				printl("Spawning horde!")
				lastHordeSpawn = Time()
			}
			
			if(commonCount <= g_ModeScript.VitalCarrierGame.GetSetting("zombies_spawn_threshold") && !respawningCommonsFromThreshold){
				respawningCommonsFromThreshold = true
				lastCommonSpawn = Time()
			} else if(commonCount >= g_ModeScript.VitalCarrierGame.GetSetting("zombies_max")){
				respawningCommonsFromThreshold = false
			}
			
			if(respawningCommonsFromThreshold && Time() >= lastCommonSpawn + g_ModeScript.VitalCarrierGame.GetSetting("zombies_spawn_rate")){
				SpawnAndCheckCommon()
				lastCommonSpawn = Time()
			}
		}
	}
	
	function ManagePointZombies(){
		if(g_ModeScript.VitalCarrierGame.IsStarted() && !g_ModeScript.VitalCarrierGame.IsGracePeriodStarted()){
			local common = null
			while(common = Entities.FindByClassname(common, "infected")){
				common.ValidateScriptScope()
				if("pointZombie" in common.GetScriptScope()){
					common.SetGlowColorVector(g_ModeScript.VitalCarrierGame.GetSetting("point_zombie_outline_color"))
					
					if("fleeing" in common.GetScriptScope() && common.GetScriptScope()["fleeing"]){
						if((common.GetScriptScope()["fleeTarget"] - common.GetOrigin()).Length() <= g_ModeScript.VitalCarrierGame.GetSetting("point_zombie_flee_retarget_tolerance")){
							local fleeTarget = FindNewFleeTarget(common)
							
							common.GetScriptScope()["fleeTarget"] = fleeTarget
							
							printl("Moving point zombie to new target")
							
							MoveZombieToTarget(common, fleeTarget)
						}
						
						local closestPlayer = g_ModeScript.FindClosestPlayer(common.GetOrigin())
						
						if((("lastHurt" in common.GetScriptScope() && Time() >= common.GetScriptScope()["lastHurt"] + g_ModeScript.VitalCarrierGame.GetSetting("point_zombie_attack_delay")) || !("lastHurt" in common.GetScriptScope())) && (closestPlayer.GetOrigin() - common.GetOrigin()).Length() <= g_ModeScript.VitalCarrierGame.GetSetting("point_zombie_attack_distance")){
							local traceTable = {
								start = common.GetOrigin() + Vector(0,0,62)
								end = closestPlayer.GetOrigin() + Vector(0,0,31)
								ignore = common
							}
							
							TraceLine(traceTable)
							
							if("enthit" in traceTable && traceTable["enthit"] == closestPlayer){
								CommandABot({cmd = 3, bot = common})
								CommandABot({cmd = 0, bot = common, target = closestPlayer})
								printl("Attacking player that got too close to a point zombie!")
								common.GetScriptScope()["fleeing"] = false
							}
						}
					}
				}
			}
			
			if(spawnedPointZombies < g_ModeScript.VitalCarrierGame.GetSetting("point_zombie_max") && Time() >= lastPointZombieSpawn + g_ModeScript.VitalCarrierGame.GetSetting("point_zombie_spawn_rate")){
				SpawnPointZombie()
			}
		}
	}
	
	
	function FindFarthestValidCommonFromPlayers(){
		local farthestDistance = 0
		local farthestCommon = null
		
		local common = null
		while(common = Entities.FindByClassname(common, "infected")){
			if(common.GetPropString("m_ModelName") != "models/infected/common_male_fallen_survivor"){
				local closestPlayer = g_ModeScript.FindClosestPlayer(common.GetOrigin())
				if((common.GetOrigin() - closestPlayer.GetOrigin()).Length() > farthestDistance){
					local inPlayAreas = true
					foreach(area in g_MapScript.PlayAreas){
						if(!area.IsPointInside(common.GetOrigin())){
							inPlayAreas = false
							break
						}
					}
					if(inPlayAreas){
						farthestDistance = (common.GetOrigin() - closestPlayer.GetOrigin()).Length()
						farthestCommon = common
					}
				}
			}
		}
		
		return farthestCommon
	}
	
	function CommonVisibleToPlayers(common){
		local survivor = null
		while(survivor = Entities.FindByClassname(survivor, "player")){
			if(survivor.IsSurvivor()){
				local traceTable = {
					start = survivor.EyePosition()
					end = common.GetOrigin()
					ignore = survivor
				}
				
				TraceLine(traceTable)
				
				if(traceTable.hit && traceTable.enthit == common){
					return true
				}
			}
		}
		return false
	}
	
	function ResetTimes(){
		lastCommonSpawn = Time()
		lastHordeSpawn = Time()
		lastPointZombieSpawn = Time()
	}
	
	function ResetCounts(){
		spawnedPointZombies = 0
	}
	
	function SpawnAndCheckCommon(timesRan = 0){
		if(timesRan < 5){
			local commonsBefore = []
			local commonsAfter = []
			local ent = null

			while(ent = Entities.FindByClassname(ent, "infected")){
				if(ent.IsValid() && ent.GetPropString("m_ModelName") != "models/infected/common_male_fallen_survivor.mdl"){
					commonsBefore.append(ent)
				}
			}
			
			ZSpawn({type = 0})
			
			ent = null
			while(ent = Entities.FindByClassname(ent, "infected")){
				if(ent.IsValid() && ent.GetPropString("m_ModelName") != "models/infected/common_male_fallen_survivor.mdl"){
					commonsAfter.append(ent)
				}
			}
			
			for(local i=0; i < commonsAfter.len(); i+=1){
				for(local j=0; j < commonsBefore.len(); j+=1){
					if(commonsAfter[i] == commonsBefore[j]){
						commonsAfter.remove(i)
						commonsBefore.remove(j)
						if(i > 0){
							i -= 1
						}
						break
					}
				}
			}
						
			for(local i=0; i< commonsAfter.len(); i++){
				if(NetProps.GetPropInt(commonsAfter[i], "m_mobRush") == 1){
					commonsAfter.remove(i)
					i--
				}
			}
					
			if(commonsAfter.len() > 0){
				if(CommonVisibleToPlayers(commonsAfter[0])){
					commonsAfter[0].Kill()
					printl("Common was visible by players while spawning, retrying")
					return SpawnAndCheckCommon(timesRan + 1)
				} else {
					return commonsAfter[0]
				}
			}
		} else {
			printl("ZSpawn #2 in SpawnAndCheckCommon")
			ZSpawn({type = 0})
		}
	}
	
	function FindFarthestFleeTargets(vector, targetCount){
		if(typeof(targetCount) == "float"){
			targetCount = (targetCount + 1).tointeger()
		}
		
		if(targetCount > fleeTargets.len()){
			printl("FindFarthestFleeTargets: targetCount too high, setting to max bound")
			targetCount = fleeTargets.len()
		}
		
		local targets = []
		targets.extend(fleeTargets)
		targets.sort(@(a,b) (vector - a).Length() <=> (vector - b).Length())
		
		return targets.slice(targets.len() - targetCount)
	}
	
	function FindNewFleeTarget(zombie, attacker = null){
		if(!("fleeTarget" in zombie.GetScriptScope())){
			return fleeTargets[RandomInt(0, fleeTargets.len() - 1)]
		}
		if(attacker != null){
			local targets = FindFarthestFleeTargets(attacker.GetOrigin(), 3)
			return targets[RandomInt(0, targets.len() - 1)]
		}
		local targets = []
		targets.extend(fleeTargets)
		targets.remove(targets.find(zombie.GetScriptScope()["fleeTarget"]))
		return targets[RandomInt(0, targets.len() - 1)]
	}
	
	function MoveZombieToTarget(zombie, pos){
		local command = {
			cmd = 1
			bot = zombie
			pos = pos
		}
		CommandABot(command)
	}
	
	function OnPointZombieShoved(zombie, attacker){
			zombie.ValidateScriptScope()
			
			local fleeTarget = FindNewFleeTarget(zombie, attacker)
			
			zombie.GetScriptScope()["fleeing"] <- true
			zombie.GetScriptScope()["fleeTarget"] <- fleeTarget
			zombie.GetScriptScope()["lastHurt"] <- Time()
			
			local checkFunction = function(){
				return zombie.GetPropInt("m_nSequence") < 122 || zombie.GetPropInt("m_nSequence") > 141
			}
			
			local callFunction = function(){
				g_ModeScript.ZombieManager.MoveZombieToTarget(zombie, fleeTarget)
			}
			
			local taskFunction = function(){
				g_ModeScript.HookController.RegisterFunctionListener(checkFunction, callFunction, {zombie = zombie, fleeTarget = fleeTarget}, true)
			}
			
			g_ModeScript.HookController.ScheduleTask(taskFunction, {zombie = zombie, fleeTarget = fleeTarget, callFunction = callFunction, checkFunction = checkFunction}, 0.033)
	}
	
	function OnPointZombieDamaged(zombie, attacker){
			zombie.ValidateScriptScope()
			
			local fleeTarget = FindNewFleeTarget(zombie, attacker)
			
			zombie.GetScriptScope()["fleeing"] <- true
			zombie.GetScriptScope()["fleeTarget"] <- fleeTarget
			zombie.GetScriptScope()["lastHurt"] <- Time()
			
			MoveZombieToTarget(zombie, fleeTarget)
	}
	
	function OnPointZombieKilled(zombie, killer){
			if("pointsToReceive" in killer.GetScriptScope()){
				g_ModeScript.FindPlayer(killer).IncreaseScore(killer.GetScriptScope()["pointsToReceive"])
			} else {
				g_ModeScript.FindPlayer(killer).IncreaseScore()
			}
			
			g_ModeScript.ResetBot(zombie)
			g_ModeScript.SpawnPointZombieSmoke(zombie.GetOrigin() + Vector(0,0,32))
			g_ModeScript.ShowPointZombieKilledHint(killer)
			
			lastPointZombieSpawn = Time()
			spawnedPointZombies--
			
			zombie.GetScriptScope()["pointZombie"] = false
			zombie.GetScriptScope()["dead"] <- true
			
			/* Death alert sound
				Instructor.ImportantLessonStart
			*/
			
			local traceTable = {
				start = zombie.GetOrigin()
				mask = 3
				end = zombie.GetOrigin() - Vector(0,0,99999)
			}
			
			TraceLine(traceTable)
			
			if(traceTable.hit){
				g_ModeScript.LaunchFirework(traceTable.pos)
			} else {
				printl("Failed to find spot for firework!")
			}
			
			local func = function(){
				g_ModeScript.RemoveFallenSurvivorItems(zombie)
				g_ModeScript.DropFallenSurvivorItems(zombie)
				if("fleeing" in zombie.GetScriptScope()){
					g_ModeScript.ResetBot(zombie)
				} else {
					zombie.Kill()
				}
			}
			
			g_ModeScript.HookController.ScheduleTask(func, {zombie = zombie}, 0.033)
	}
	
	function SpawnActualPointZombie(common){
		spawner.SetOrigin(common.GetOrigin())
		
		local survivor = null
		while(survivor = Entities.FindByClassname(survivor, "player")){
			if(survivor.IsSurvivor()){
				EmitSoundOnClient("Bot.StuckSound", survivor)
			}
		}
		
		Say(null, "A point zombie just spawned!", false)
		
		g_ModeScript.ShowPointZombieSpawnedHint()
		
		spawnedPointZombies++
		
		common.Kill()
		
		local targetname = UniqueString()
		
		DoEntFire("!self","SpawnZombie", "common_male_fallen_survivor," + targetname,0,null,spawner)
		
		local func = function(){
			local pointZombie = Entities.FindByName(null, targetname)
			
			pointZombie.ValidateScriptScope()
			pointZombie.GetScriptScope()["pointZombie"] <- true
			
			pointZombie.SetGlowType(3)
			pointZombie.SetGlowRange(VitalCarrierGame.GetSetting("point_zombie_outline_range"))
			
			pointZombie.SetGlowColorVector(VitalCarrierGame.GetSetting("point_zombie_outline_color"))
		}
		g_ModeScript.HookController.ScheduleTask(func, {targetname = targetname, VitalCarrierGame = g_ModeScript.VitalCarrierGame}, 0.033)
	}
	
	function SpawnPointZombie(){
		printl("Spawning point zombie")
		// Pick furthest common from survivors, change to point zombie. If no commons, spawn common and change to point zombie
		local commonsBefore = []
		local commonsAfter = []
		local ent = null

		while(ent = Entities.FindByClassname(ent, "infected")){
			if(ent.IsValid() && ent.GetModelName() != "models/infected/common_male_fallen_survivor.mdl"){
				commonsBefore.append(ent)
			}
		}
		
		local common = FindFarthestValidCommonFromPlayers()
		if(commonsBefore.len() > 0 && common != null && !CommonVisibleToPlayers(common) && (g_ModeScript.FindClosestPlayer(common.GetOrigin()).GetOrigin() - common.GetOrigin()).Length() > 500){
			SpawnActualPointZombie(common)
		} else {
			ZSpawn({type = 0})
			
			ent = null
			while(ent = Entities.FindByClassname(ent, "infected")){
				if(ent.IsValid() && ent.GetModelName() != "models/infected/common_male_fallen_survivor.mdl"){
					commonsAfter.append(ent)
				}
			}
			
			for(local i=0; i < commonsAfter.len(); i+=1){
				for(local j=0; j < commonsBefore.len(); j+=1){
					if(commonsAfter[i] == commonsBefore[j]){
						commonsAfter.remove(i)
						commonsBefore.remove(j)
						if(i > 0){
							i -= 1
						}
						break
					}
				}
			}
			
			if(commonsAfter.len() == 0){
				printl("Failed to find spawn for a point zombie! Trying again...")
				SpawnPointZombie()
				return
			} else {
				if(CommonVisibleToPlayers(commonsAfter[0])){
					commonsAfter[0].Kill()
					SpawnPointZombie()
					return
				}
				foreach(area in g_MapScript.PlayAreas){
					if(!area.IsPointInside(commonsAfter[0].GetOrigin())){
						printl("Retrying point zombie spawn (not inside play area)")
						commonsAfter[0].Kill()
						SpawnPointZombie()
						return
					}
				}
				SpawnActualPointZombie(commonsAfter[0])
			}
		}
	}
}

// Manages almost all things to do with survivors
class CSurvivorManager extends CManager {
	players = []
	playerSpawns = []
	
	constructor(playerSpawns){
		this.playerSpawns = playerSpawns
		g_ModeScript.HookController.RegisterBileExplodeListener(this)
		g_ModeScript.HookController.RegisterOnTick(this)
	}

	function OnTick(){
		EnsureValidPlayers()
		CheckForDownedSurvivors()
	}
	
	
	function GetPlayers(){
		return players
	}
	
	
	function OnBileExplode(thrower, position){
		if(VitalCarrierGame.IsStarted() && thrower != null){
			local playersBiled = []
			
			local survivor = null
			while(survivor = Entities.FindByClassname(survivor, "player")){
				if(survivor != thrower && (survivor.GetOrigin() - position).Length() <= VitalCarrierGame.GetSetting("bile_max_distance")){
					local traceTable = {
						start = position
						end = survivor.GetOrigin() + Vector(0,0,31)
					}
					
					TraceLine(traceTable)
					
					if(traceTable.hit && traceTable.enthit != Entities.FindByClassname(null, "worldspawn") && traceTable.enthit == survivor){
						playersBiled.append(survivor)
						survivor.HitWithVomit()
						g_ModeScript.ShowPlayerBiledHint(survivor)
						survivor.SetPropFloat("m_itTimer.m_duration", VitalCarrierGame.GetSetting("player_biled_duration"))
						survivor.SetPropFloat("m_itTimer.m_timestamp", Time() + VitalCarrierGame.GetSetting("player_biled_duration"))
						
						survivor.SetGlowType(3)
						survivor.SetGlowRange(999999)
						survivor.SetGlowColorVector(VitalCarrierGame.GetSetting("player_biled_color"))
						
						local resetFunc = function(){
							ent.SetGlowType(0)
							ent.SetGlowRange(0)
							ent.SetGlowColor(-1)
						}
						
						HookController.ScheduleTask(resetFunc, {ent = survivor}, VitalCarrierGame.GetSetting("player_biled_duration"))
					}
				}
			}
			
			if(playersBiled.len() == 1){
				Say(null, playersBiled[0].GetPlayerName() + " just got covered in bile!", false)
			} else if(playersBiled.len() > 1){
				local message = ""
				for(local i=0; i<playersBiled.len(); i++){
					if(i == playersBiled.len() - 1){
						message += "and " + playersBiled[i].GetPlayerName() + " just got covered in bile!"
					} else {
						message += playersBiled[i].GetPlayerName() + ", "
					}
				}
			}
		}
	}
	
	function UnfreezeAllPlayers(){
		foreach(player in players){
			player.GetEntity().RemoveFlag(32)
			player.GetEntity().SetMoveType(2)
		}
	}
	
	function ClearAllPlayersWeapons(){
		foreach(player in players){
			local invTable = {}
			GetInvTable(player.GetEntity(), invTable)
			for(local i=0; i <= 5; i+=1){
				if(("slot" + i) in invTable && invTable["slot" + i] != null){
					invTable["slot" + i].Kill()
				}
			}
		}
	}
	
	function TeleportPlayersToSpawns() {
		local spawns = []
		spawns.extend(playerSpawns)
		
		foreach(player in players){
			local random = RandomInt(0, spawns.len() - 1)
			player.GetEntity().SetOrigin(spawns[random].GetOrigin())
			spawns.remove(random)
		}
	}

	function GiveAllPlayersPistols(){
		local player = null
		while(player = Entities.FindByClassname(player, "player")){
			if(player.IsSurvivor()){
				player.GiveItem("pistol")
			}
		}
	}

	function CheckForDownedSurvivors(){
		local survivor = null
		while(survivor = Entities.FindByClassname(survivor, "player")){
			if(survivor.IsSurvivor() && survivor.IsIncapacitated()){
				OnSurvivorDowned(survivor)
			}
		}
	}
	
	function OnSurvivorDowned(entity){
		entity.ValidateScriptScope()
		if("reviveOnIncap" in entity.GetScriptScope() && entity.GetScriptScope()["reviveOnIncap"]){
			entity.ReviveFromIncap()
			entity.SetHealth(VitalCarrierGame.GetSetting("elixir_of_life_revive_health"))
			entity.SetHealthBuffer(VitalCarrierGame.GetSetting("elixir_of_life_revive_temp_health"))
			entity.GetScriptScope()["reviveOnIncap"] <- false
			entity.SetReviveCount(0)
			EmitSoundOnClient("Hint.BigReward", entity)
		} else {
			local otherPlayersDead = true
			local ent = null
			while(ent = Entities.FindByClassname(ent, "player")){
				if(ent.IsSurvivor() && ent != entity && !ent.IsDead()){
					otherPlayersDead = false
				}
			}
			
			if(otherPlayersDead){
				g_ModeScript.ZombieManager.Disable()
				VitalCarrierGame.SetGracePeriodStarted(false)
				HookController.ScheduleTask(function(){g_ModeScript.StopGame()}, {}, VitalCarrierGame.GetSetting("end_delay"))
			}
			
			g_ModeScript.ShowPlayerKilledHint(entity)
			Say(null, entity.GetPlayerName() + " has died.", false)
			
			entity.TakeDamage(9999, 1, null)
		}
	}
	
	function EnsureValidPlayers(){
		local currentPlayers = []
		
		for(local i=0; i < players.len(); i+=1){
			if(players[i] == null){
				players.remove(i)
				i -= 1
			} else {
				currentPlayers.append(players[i].GetEntity())
			}
		}
		
		local ent = null
		while(ent = Entities.FindByClassname(ent, "player")){
			if(ent.IsSurvivor()){
				DoEntFire("!self","SetGlowEnabled","0",0,null,ent)
				if(currentPlayers.find(ent) == null){
					players.append(g_ModeScript.Player(ent))
				}
			}
		}
	}
}

// Manages powerups and their spawning
class CPowerupManager extends CManager {
	
	usedPowerups = []
	powerupSpawns = []
	
	constructor(powerupSpawns){
		this.powerupSpawns = powerupSpawns
		g_ModeScript.HookController.RegisterOnTick(this)
	}

	function OnTick(){
		TeleportPowerups()
		RespawnPowerups()
		CheckUsedPowerups()
	}
	
	
	function GetPowerupSpawns(){
		return powerupSpawns
	}
	
	
	function OnPowerupPickup(activator, powerupSpawn){
		local powerup = powerupSpawn.GetPowerup().GetScriptScope()["powerupClass"]
		
		powerupSpawn.Disable()
		
		activator.ValidateScriptScope()
		powerup.DoEffect(activator)
		usedPowerups.append(g_ModeScript.UsedPowerup(powerup, activator, Time()))
		Say(null, activator.GetPlayerName() + " has activated the " + powerup.name + " powerup!", false)
		
		local disabledPowerups = []
		disabledPowerups.extend(powerupSpawns)
		
		for(local i=0; i<disabledPowerups.len(); i++){
			if(!disabledPowerups[i].GetDisabled()){
				disabledPowerups.remove(i)
				i--
			}
		}
		
		if(disabledPowerups.len() > 0){
			disabledPowerups.append(powerupSpawn)
			powerupSpawn.Enable()
		}
		
		local enabledPowerup = disabledPowerups[RandomInt(0, disabledPowerups.len() - 1)]
		
		enabledPowerup.Enable()
		enabledPowerup.SetPickupTime(Time())
		enabledPowerup.SetPickedUp(true)
		
		powerupSpawn.SetPickedUp(true)
		powerupSpawn.SetPickupTime(Time())
	}
	
	function SpawnInitialPowerups(){
		local spawns = []
		spawns.extend(powerupSpawns)
		for(local i=0; i < g_ModeScript.VitalCarrierGame.GetSetting("powerup_max_spawned"); i++){
			local random = RandomInt(0, spawns.len() - 1)
			SpawnPowerup(spawns[random])
			spawns.remove(random)
		}
		foreach(spawn in spawns){
			spawn.Disable()
		}
	}
	
	function ClearAllPowerupEffects(){
		for(local i=0; i < usedPowerups.len(); i+=1){
			local powerup = usedPowerups[i]
			powerup.GetPowerupClass().ClearEffect(powerup.GetEntity())
			usedPowerups.remove(i)
			i--
		}
	}

	function ClearAllPowerupEntities(){
		foreach(powerup in powerupSpawns){
			if(powerup.GetPowerup() != null){
				powerup.GetPowerup().Kill()
			}
		}
	}

	function SpawnDroppedPowerup(origin){
		local powerup = SpawnEntityFromTable("prop_physics", {model = "models/props_junk/gnome.mdl", origin = origin})
		powerup.ValidateScriptScope()
		powerup.GetScriptScope()["droppedPowerup"] <- true
		powerup.GetScriptScope()["powerupClass"] <- g_ModeScript.powerups[RandomInt(0, g_ModeScript.powerups.len() - 1)]
	}

	function SpawnPowerup(spawn){
		local validPowerupClasses = []
		validPowerupClasses.extend(g_ModeScript.powerups)
		local powerup = SpawnEntityFromTable("prop_physics", {model = "models/props_junk/gnome.mdl",origin = spawn.GetOrigin()})
		spawn.SetPickedUp(false)
		spawn.SetPowerup(powerup)
		spawn.Enable()
		powerup.SetAngles(spawn.GetAngles())
		powerup.ValidateScriptScope()
		foreach(powerupSpawn in powerupSpawns){
			if(!powerupSpawn.GetPickedUp()){
				if(powerupSpawn.GetPowerupName() == null){
					for(local i=0; i < validPowerupClasses.len(); i++){
						if(validPowerupClasses[i].name == powerupSpawn.GetPowerupName()){
							validPowerupClasses.remove(i)
							break
						}
					}
				} else {
					for(local i=0; i < validPowerupClasses.len(); i++){
						if(validPowerupClasses[i].name == spawn.GetPowerupName()){
							powerup.GetScriptScope()["powerupClass"] <- validPowerupClasses[i]
							return
						}
					}
				}
			}
		}
		
		if(validPowerupClasses.len() == 0){
			validPowerupClasses.extend(g_ModeScript.powerups)
		}
		
		powerup.GetScriptScope()["powerupClass"] <- validPowerupClasses[RandomInt(0, validPowerupClasses.len() - 1)]
		return
	}
	
	function RespawnPowerups(){
		foreach(spawn in powerupSpawns){
			if(spawn.GetPickedUp() && !spawn.GetDisabled() && Time() >= spawn.GetPickupTime() + VitalCarrierGame.GetSetting("powerup_respawn_time")){
				SpawnPowerup(spawn)
			}
		}
	}
	
	function CheckUsedPowerups(){
		for(local i=0; i < usedPowerups.len(); i+=1){
			local powerup = usedPowerups[i]
			if(powerup.GetDuration() != -1 && Time() >= powerup.GetTimeUsed() + powerup.GetDuration()){
				powerup.GetPowerupClass().ClearEffect(powerup.GetEntity())
				usedPowerups.remove(i)
				i -= 1
			}
		}
	}
	
	function TeleportPowerups(){
		foreach(spawn in powerupSpawns){
			if(!spawn.GetPickedUp() && spawn.GetPowerup() != null && spawn.GetPowerup().IsValid()){
				spawn.GetPowerup().SetOrigin(spawn.GetOrigin())
				spawn.GetPowerup().SetAngles(spawn.GetAngles())
			}
		}
	}
}

// Manages items and their respawning and fading
class CItemManager extends CManager {
	itemSpawns = []
	currentItemSpawns = []
	droppedWeapons = []
	fadingWeapons = []
	
	constructor(itemSpawns){
		this.itemSpawns = itemSpawns
		g_ModeScript.HookController.RegisterOnTick(this)
	}

	function OnTick(){
		CleanupDroppedItems()
		CleanupFadingItems()
		RespawnItems()
	}

	function SetItemSpawns(itemSpawns){
		this.itemSpawns = itemSpawns
	}
	
	
	function OnInventoryChange(player, removed_weapons, new_weapons){
		foreach(new_weapon in new_weapons){
			foreach(spawn in currentItemSpawns){
				if(new_weapon == spawn.GetWeapon()){
					spawn.SetPickedUp(true)
					spawn.SetPickupTime(Time())
				}
			}
			new_weapon.ValidateScriptScope()
			for(local i=0; i<droppedWeapons.len(); i+=1){
				if(droppedWeapons[i] == new_weapon){
					droppedWeapons.remove(i)
					i -= 1
				}
			}
		}
		
		foreach(weapon in removed_weapons){
			if(weapon != null && weapon.IsValid()){
				weapon.ValidateScriptScope()
				weapon.GetScriptScope()["dropTime"] <- Time()
				droppedWeapons.append(weapon)
			}
		}
	}
	
	function GetWeaponRespawnTime(weapon_name){
		if(VitalCarrierGame.GetSetting(weapon_name + "_respawn_time") != -1){
			return VitalCarrierGame.GetSetting(weapon_name + "_respawn_time")
		}
		return 15
	}
	
	function RollItemSpawns(){
		currentItemSpawns.clear()
		foreach(spawn in itemSpawns){
			if(spawn.CheckSpawnChance()){
				currentItemSpawns.append(spawn)
			}
		}
	}
	
	function ClearAllItems(){
		local RemoveAllEntities = g_ModeScript.RemoveAllEntities
		RemoveAllEntities("weapon_hunting_rifle")
		RemoveAllEntities("weapon_molotov")
		RemoveAllEntities("weapon_pain_pills")
		RemoveAllEntities("weapon_pipe_bomb")
		RemoveAllEntities("weapon_vomitjar")
		RemoveAllEntities("weapon_pistol_magnum")
		RemoveAllEntities("weapon_pistol")
		RemoveAllEntities("weapon_pumpshotgun")
		RemoveAllEntities("weapon_rifle_ak47")
		RemoveAllEntities("weapon_rifle_desert")
		RemoveAllEntities("weapon_rifle_m60")
		RemoveAllEntities("weapon_rifle_sg552")
		RemoveAllEntities("weapon_rifle")
		RemoveAllEntities("weapon_shotgun_chrome")
		RemoveAllEntities("weapon_shotgun_spas")
		RemoveAllEntities("weapon_smg_mp5")
		RemoveAllEntities("weapon_smg_silenced")
		RemoveAllEntities("weapon_smg")
		RemoveAllEntities("weapon_sniper_awp")
		RemoveAllEntities("weapon_sniper_military")
		RemoveAllEntities("weapon_sniper_scout")
		RemoveAllEntities("weapon_upgradepack_explosive")
		RemoveAllEntities("weapon_upgradepack_incendiary")
		RemoveAllEntities("weapon_first_aid_kit")
		RemoveAllEntities("weapon_adrenaline")
		RemoveAllEntities("weapon_melee")
		RemoveAllEntities("weapon_defibrillator")
		
		RemoveAllEntities("weapon_spawn")
		
		RemoveAllEntities("weapon_hunting_rifle_spawn")
		RemoveAllEntities("weapon_molotov_spawn")
		RemoveAllEntities("weapon_pain_pills_spawn")
		RemoveAllEntities("weapon_pipe_bomb_spawn")
		RemoveAllEntities("weapon_vomitjar_spawn")
		RemoveAllEntities("weapon_pistol_magnum_spawn")
		RemoveAllEntities("weapon_pistol_spawn")
		RemoveAllEntities("weapon_pumpshotgun_spawn")
		RemoveAllEntities("weapon_rifle_ak47_spawn")
		RemoveAllEntities("weapon_rifle_desert_spawn")
		RemoveAllEntities("weapon_rifle_m60_spawn")
		RemoveAllEntities("weapon_rifle_sg552_spawn")
		RemoveAllEntities("weapon_rifle_spawn")
		RemoveAllEntities("weapon_shotgun_chrome_spawn")
		RemoveAllEntities("weapon_shotgun_spas_spawn")
		RemoveAllEntities("weapon_smg_mp5_spawn")
		RemoveAllEntities("weapon_smg_silenced_spawn")
		RemoveAllEntities("weapon_smg_spawn")
		RemoveAllEntities("weapon_sniper_awp_spawn")
		RemoveAllEntities("weapon_sniper_military_spawn")
		RemoveAllEntities("weapon_sniper_scout_spawn")
		RemoveAllEntities("weapon_upgradepack_explosive_spawn")
		RemoveAllEntities("weapon_upgradepack_incendiary_spawn")
		RemoveAllEntities("weapon_first_aid_kit_spawn")
		RemoveAllEntities("weapon_adrenaline_spawn")
		RemoveAllEntities("weapon_melee_spawn")
		RemoveAllEntities("weapon_defibrillator_spawn")
		
		RemoveAllEntities("weapon_item_spawn")
		RemoveAllEntities("weapon_ammo_spawn")
		
		foreach(spawn in currentItemSpawns){
			if(!spawn.GetPickedUp() && spawn.GetWeapon() != null && spawn.GetWeapon().IsValid()){
				spawn.GetWeapon().Kill()
			}
			spawn.SetPickedUp(false)
		}
	}
	
	function SpawnItem(spawn){
		spawn.SetWeapon(SpawnEntityFromTable("weapon_" + spawn.GetWeaponName(),{origin = spawn.GetOrigin()}))
		spawn.GetWeapon().SetAngles(spawn.GetAngles())
		spawn.SetPickedUp(false)
		spawn.GetWeapon().SetMoveType(0)
		spawn.GetWeapon().SetReserveAmmo(g_ModeScript.VitalCarrierGame.GetSetting(spawn.GetWeaponName() + "_ammo"))
	}

	function SpawnInitialItems(){
		foreach(spawn in currentItemSpawns){
			SpawnItem(spawn)
		}
	}
	
	function RespawnItems(){
		foreach(spawn in currentItemSpawns){
			if(spawn.GetPickedUp() && Time() >= spawn.GetPickupTime() + GetWeaponRespawnTime(spawn.GetWeaponName())){
				SpawnItem(spawn)
			}
		}
	}
	
	function CleanupDroppedItems(){
		for(local i=0; i < droppedWeapons.len(); i+=1){
			local weapon = droppedWeapons[i]
			if(weapon != null && weapon.IsValid()){
				if(Time() >= weapon.GetScriptScope()["dropTime"] + g_ModeScript.VitalCarrierGame.GetSetting("dropped_weapon_remove_time")){
					weapon.ValidateScriptScope()
					weapon.GetScriptScope()["alpha"] <- 255
					NetProps.SetPropInt(weapon, "m_spawnflags", 2)
					NetProps.SetPropInt(weapon, "m_nRenderMode", 1)
					NetProps.SetPropInt(weapon, "m_Glow.m_iGlowType", 3)
					NetProps.SetPropInt(weapon, "m_Glow.m_nGlowRange", 99999999)
					NetProps.SetPropInt(weapon, "m_Glow.m_glowColorOverride", 1)
					fadingWeapons.append(weapon)
				}
			} else {
				droppedWeapons.remove(i)
				i -= 1
			}
		}
	}
	
	function CleanupFadingItems(){
		for(local i=0;i<fadingWeapons.len();i+=1){
			local weapon = fadingWeapons[i]
			if(weapon != null && weapon.IsValid()){
				weapon.GetScriptScope()["alpha"] = weapon.GetScriptScope()["alpha"] - 4.25
				if(weapon.GetScriptScope()["alpha"] > 0){
					DoEntFire("!self","Alpha",weapon.GetScriptScope()["alpha"].tointeger().tostring(),0,null,weapon)
				} else {
					weapon.Kill()
					fadingWeapons.remove(i)
				}
			} else {
				fadingWeapons.remove(i)
			}
		}
	}
}

// Manages match timer, countdown, grace period, and HUD
class CMatchManager extends CManager {
	
	constructor(){
		g_ModeScript.HookController.RegisterOnTick(this)
	}

	function OnTick(){
		DoGracePeriod()
		DoCountdown()
		DoMatchTimer()
	}
	
	function ShowMatchTimer(){
		g_ModeScript.HUD.Fields.match_timer.flags = g_ModeScript.HUD.Fields.match_timer.flags & ~g_ModeScript.HUD_FLAG_NOTVISIBLE
	}

	function ShowCountdownTimer(){
		g_ModeScript.HUD.Fields.countdown.flags = g_ModeScript.HUD.Fields.countdown.flags & ~g_ModeScript.HUD_FLAG_NOTVISIBLE
	}

	function ShowGracePeriodTimer(){
		g_ModeScript.HUD.Fields.grace_period_timer.flags = g_ModeScript.HUD.Fields.grace_period_timer.flags & ~g_ModeScript.HUD_FLAG_NOTVISIBLE
	}

	function ShowScoreboard(){
		g_ModeScript.HUD.Fields.scoreboard.dataval = ""
		
		local players = []
		players.extend(g_ModeScript.SurvivorManager.GetPlayers())
		players.sort(function(a,b){
			if(a > b){
				return 1
			} else if(a < b){
				return -1
			}
			return 0
		})
		
		//players.reverse()
		
		foreach(player in players){
			g_ModeScript.HUD.Fields.scoreboard.dataval += player.GetEntity().GetPlayerName() + ": " + player.GetScore() + "\n\n"
		}
		
		g_ModeScript.HUD.Fields.scoreboard.flags = HUD.Fields.scoreboard.flags & ~g_ModeScript.HUD_FLAG_NOTVISIBLE
		g_ModeScript.HookController.ScheduleTask(function(){g_ModeScript.MatchManager.HideScoreboard()}, {}, VitalCarrierGame.GetSetting("scoreboard_show_time"))
	}

	function HideMatchTimer(){
		g_ModeScript.HUD.Fields.match_timer.flags = g_ModeScript.HUD.Fields.match_timer.flags | g_ModeScript.HUD_FLAG_NOTVISIBLE
	}

	function HideCountdownTimer(){
		g_ModeScript.HUD.Fields.countdown.flags = g_ModeScript.HUD.Fields.countdown.flags | g_ModeScript.HUD_FLAG_NOTVISIBLE
	}

	function HideGracePeriodTimer(){
		g_ModeScript.HUD.Fields.grace_period_timer.flags = g_ModeScript.HUD.Fields.grace_period_timer.flags | g_ModeScript.HUD_FLAG_NOTVISIBLE
	}

	function HideScoreboard(){
		g_ModeScript.HUD.Fields.scoreboard.flags = g_ModeScript.HUD.Fields.scoreboard.flags | g_ModeScript.HUD_FLAG_NOTVISIBLE
	}

	function HideTimers(){
		HideMatchTimer()
		HideCountdownTimer()
		HideGracePeriodTimer()
	}
	
	function BeginCountdown(){
		g_ModeScript.VitalCarrierGame.SetCountdownStartTime(Time())
		g_ModeScript.VitalCarrierGame.SetCountdownStarted(true)
		ShowCountdownTimer()
		g_ModeScript.HUD.Fields.countdown.dataval = "" + g_ModeScript.VitalCarrierGame.GetSetting("countdown_time")
	}
	
	function DoGracePeriod(){
		if(g_ModeScript.VitalCarrierGame.IsGracePeriodStarted()){
			local time = g_ModeScript.VitalCarrierGame.GetSetting("grace_period_time") - (Time() - g_ModeScript.VitalCarrierGame.GetGracePeriodStartTime())
			if(time <= 0){
				Say(null, "Grace period has ended. Here they come!", false)
				ShowMatchTimer()
				g_ModeScript.VitalCarrierGame.SetGracePeriodStarted(false)
				g_ModeScript.VitalCarrierGame.SetMatchStart(Time())
				g_ModeScript.VitalCarrierGame.SetMatchTimerStarted(true)
				g_ModeScript.ZombieManager.ResetTimes()
				g_ModeScript.ZombieManager.SpawnPointZombie()
			} else if(time <= 0.15){
				HideGracePeriodTimer()
			} else {
				g_ModeScript.HUD.Fields.grace_period_timer.dataval = "" + ceil(time)
			}
		}
	}

	function DoCountdown(){
		if(g_ModeScript.VitalCarrierGame.IsCountdownStarted()){
			local time = g_ModeScript.VitalCarrierGame.GetSetting("countdown_time") - (Time() - g_ModeScript.VitalCarrierGame.GetCountdownStartTime())
			if(ceil(time) <= 0){
				g_ModeScript.SurvivorManager.GiveAllPlayersPistols()
				g_ModeScript.SurvivorManager.UnfreezeAllPlayers()
				ShowGracePeriodTimer()
				Convars.SetValue("cl_viewbob",1)
				Convars.SetValue("crosshair",1)
				g_ModeScript.VitalCarrierGame.Start()
				g_ModeScript.VitalCarrierGame.SetCountdownStarted(false)
				g_ModeScript.VitalCarrierGame.SetGracePeriodStarted(true)
				g_ModeScript.VitalCarrierGame.SetGracePeriodStartTime(Time())
				Say(null, "Grace period has started. Prepare for the infected!", false) 
			} else if(time <= 0.15){
				HideCountdownTimer()
			} else {
				g_ModeScript.HUD.Fields.countdown.dataval = "" + ceil(time)
			}
		}
	}

	function DoMatchTimer(){
		if(g_ModeScript.VitalCarrierGame.IsMatchTimerStarted()){
			local time = g_ModeScript.VitalCarrierGame.GetSetting("match_time") - (Time() - g_ModeScript.VitalCarrierGame.GetMatchStart())
			if(ceil(time) <= 0){
				g_ModeScript.StopGame()
			} else if(time <= 0.15){
				g_ModeScript.HUD.Fields.match_timer.flags = HUD.Fields.match_timer.flags | g_ModeScript.HUD_FLAG_NOTVISIBLE
			} else {
				local seconds = ceil(time) % 60
				local minutes = floor(ceil(time) / 60)
				if(seconds < 10){
					g_ModeScript.HUD.Fields.match_timer.dataval = "" + minutes + ":0" + seconds
				} else {
					g_ModeScript.HUD.Fields.match_timer.dataval = "" + minutes + ":" + seconds
				}
			}
		}
	}
}


class CVitalCarrierGame {
	started = false
	enabled = true
	countdown_start = false
	match_timer_started = false
	grace_period_started = false
	
	grace_period_start_time = 0
	countdown_start_time = 0
	game_stop_time = 0
	match_start = 0
	
	settings = {	
		autoshotgun_ammo = 90
		shotgun_spas_ammo = 90
		pumpshotgun_ammo = 56
		shotgun_chrome_ammo = 56
		sniper_military_ammo = 180
		sniper_awp_ammo = 180
		sniper_scout_ammo = 180
		hunting_rifle_ammo = 150
		rifle_ammo = 360
		rifle_ak47_ammo = 360
		rifle_desert_ammo = 360
		rifle_sg552_ammo = 360
		rifle_m60_ammo = 0
		smg_ammo = 650
		smg_mp5_ammo = 650
		smg_silenced_ammo = 650
		grenade_launcher_ammo = 9
		pistol_ammo = 0
		pistol_magnum_ammo = 0
		chainsaw_ammo = 20
		
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
		pistol_magnum_respawn_time = 15
		adrenaline_respawn_time = 15
		pain_pills_respawn_time = 15
		first_aid_kit_respawn_time = 15
		vomitjar_respawn_time = 15
		
		powerup_respawn_time = 15
		
		percentage_to_start = 75
		percentage_to_stop = 75
		percentage_to_change_level = 75
		
		max_health = 100
		
		countdown_time = 5
		
		match_time = 300
		
		point_zombie_outline_range = 2000
		point_zombie_outline_color = Vector(240, 200, 65)
		point_zombie_item_drop_chance = 0.5
		point_zombie_pain_pills_drop_chance = 0.5
		point_zombie_adrenaline_drop_chance = 0.25
		point_zombie_powerup_drop_chance = 0.25
		point_zombie_melee_damage_modifier = 0.25
		point_zombie_chainsaw_damage_modifier = 0.1
		point_zombie_grenade_launcher_damage_modifier = 0.34
		point_zombie_m60_damage_modifier = 0.1
		point_zombie_flee_retarget_tolerance = 200 // when the point zombies get within this distance of their current target, they will retarget
		point_zombie_attack_distance = 200 // when a player gets within this distance, the point zombie will attack them until hit
		point_zombie_attack_delay = 5 // after getting hurt, point zombies will wait this long before attacking players that get too close
		point_zombie_max = 1
		point_zombie_spawn_rate = 15 // 1 point zombie per this amount of seconds
		
		hint_point_zombie_killed_timeout = 3
		hint_point_zombie_killed_color = Vector(255, 255, 255)
		
		hint_point_zombie_spawned_timeout = 3
		hint_point_zombie_spawned_color = Vector(255, 255, 255)
		
		hint_player_killed_timeout = 5
		hint_player_killed_color = Vector(255, 100, 100)
		
		hint_player_biled_timeout = 5
		hint_player_biled_color = Vector(255,255,255)
		
		player_biled_duration = 20
		player_biled_color = Vector(200, 18, 184)
		
		elixir_of_life_revive_health = 75
		elixir_of_life_revive_temp_health = 0
		
		bile_max_distance = 500 // max distance that bile can bile players from
		
		zombies_max = 15
		zombies_spawn_threshold = 10
		zombies_spawn_rate = 2 // 1 common per this amount of seconds
		
		horde_zombies = 30
		horde_spawn_time_min = 45
		horde_spawn_time_max = 75
		
		powerup_max_spawned = 5 //maximum powerups spawned at a time
		
		end_delay = 10 //delay before stopping game after last survivor has been killed
		
		grace_period_time = 20
		
		scoreboard_show_time = 15
		
		dropped_weapon_remove_time = 15
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
			return -1
		}
	}
	
	function GetSetting(settingName){
		if(settingName in settings){
			return settings[settingName]
		} else {
			return -1
		}
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
	
	function SetGracePeriodStarted(bool){
		grace_period_started = bool
	}
	
	function IsGracePeriodStarted(){
		return grace_period_started
	}
	
	function SetGracePeriodStartTime(time){
		grace_period_start_time = time
	}
	
	function GetGracePeriodStartTime(){
		return grace_period_start_time
	}
}

class g_ModeScript.UsedPowerup {
	powerupClass = null
	timeUsed = null
	duration = null
	entity = null

	constructor(powerupClass, entity, timeUsed){
		this.powerupClass = powerupClass
		this.entity = entity
		this.timeUsed = timeUsed
		duration = powerupClass.duration
	}
	
	function GetPowerupClass(){
		return powerupClass
	}
	
	function GetEntity(){
		return entity
	}
	
	function GetTimeUsed(){
		return timeUsed
	}
	
	function GetDuration(){
		return duration
	}
}

class Player {
	entity = null
	score = 0
	votedToStart = false
	votedToStop = false
	
	constructor(entity){
		this.entity = entity
	}
	
	function GetEntity(){
		return entity
	}
	
	function IncreaseScore(amount = 1){
		score += amount
	}
	
	function ResetHealth(){
		entity.SetReviveCount(0)
		entity.SetHealth(g_ModeScript.VitalCarrierGame.GetSetting("max_health"))
		entity.SetHealthBuffer(0)
	}
	
	function SpawnFromDead(){
	local character = g_ModeScript.GetAvailableCharacter(entity)
	
	local origin = g_ModeScript.InitialPlayerSpawns[RandomInt(0, InitialPlayerSpawns.len() - 1)].GetOrigin()
	
	if(origin == null){
		local survivor = null
		while(survivor = Entities.FindByClassname(survivor, "player")){
			if(survivor.IsSurvivor() && survivor != entity){
				origin = survivor.GetOrigin()
			}
		}
	} else {
		origin = origin.GetOrigin()
	}
	
	local deathModel = SpawnEntityFromTable("survivor_death_model", {origin = origin})
	entity.SetPropInt("m_survivorCharacter", character)
	NetProps.SetPropInt(deathModel, "m_nCharacterType", character)
	entity.ReviveByDefib()
	entity.SetHealth(100)
}
	
	function ResetScore(){
		score = 0
	}
	
	function GetScore(){
		return score
	}
	
	function SetVotedToStart(bool){
		votedToStart = bool
	}
	
	function GetVotedToStart(){
		return votedToStart
	}
	
	function SetVotedToStop(bool){
		votedToStop = bool
	}
	
	function GetVotedToStop(){
		return votedToStop
	}
}

class g_MapScript.PlayerSpawn {
	origin = null
	angles = null
	
	constructor(origin, angles){
		this.origin = origin
		this.angles = angles
	}
	
	function GetOrigin(){
		return origin
	}
	
	function GetAngles(){
		return angles
	}
}

class g_MapScript.ItemSpawn {
	weaponName = null
	origin = null
	angles = null
	weapon = null
	pickupTime = 0
	pickedUp = false
	spawnChance = 0
	
	constructor(weaponName, origin, angles, spawnChance = 100){
		this.weaponName = weaponName
		this.origin = origin
		this.angles = angles
		this.spawnChance = spawnChance
	}
	
	function CheckSpawnChance(){
		return RandomInt(0, 100) < spawnChance
	}
	
	function GetWeaponName(){
		if(typeof(weaponName) == "array"){
			return weaponName[RandomInt(0, weaponName.len() - 1)]
		} else {
			return weaponName
		}
	}
	
	function GetWeapon(){
		return weapon
	}
	
	function GetOrigin(){
		return origin
	}
	
	function GetAngles(){
		return angles
	}
	
	function GetPickedUp(){
		return pickedUp
	}
	
	function SetWeapon(ent){
		weapon = ent
	}
	
	function SetPickedUp(bool){
		pickedUp = bool
	}
	
	function GetPickupTime(){
		return pickupTime
	}
	
	function SetPickupTime(time){
		pickupTime = time
	}
}

class g_MapScript.PowerupSpawn {
	origin = null
	angles = null
	powerupName = null
	powerup = null
	pickupTime = 0
	pickedUp = false
	disabled = false
	
	constructor(origin, angles, powerupName = null){
		this.powerupName = powerupName
		this.origin = origin
		this.angles = angles
	}
	
	function Enable(){
		disabled = false
	}
	
	function Disable(){
		disabled = true
	}
	
	function GetDisabled(){
		return disabled
	}
	
	function GetOrigin(){
		return origin
	}
	
	function GetAngles(){
		return angles
	}
	
	function GetPowerupName(){
		if(typeof(powerupName) == "array"){
			return powerupName[RandomInt(0, powerupName.len() - 1)]
		} else {
			return powerupName
		}
	}
	
	function SetPickupTime(time){
		pickupTime = time
	}
	
	function GetPickupTime(){
		return pickupTime
	}
	
	function SetPickedUp(bool){
		pickedUp = bool
	}
	
	function GetPickedUp(){
		return pickedUp
	}
	
	function SetPowerup(ent){
		powerup = ent
	}
	
	function GetPowerup(){
		return powerup
	}
}

class g_MapScript.Area {
	point1 = null
	point2 = null
	
	constructor(point1, point2){
		this.point1 = point1
		this.point2 = point2
	}
	
	function Max(a, b, c = null){
		if(c == null){
			if(a < b){
				return b
			} else {
				return a
			}
		} else {
			if(b <= a && c <= a){
				return a
			}
			if(a <= b && c <= b){
				return b
			}
			if(a <= c && b <= c){
				return c
			}
		}
	}
	
	function Min(a, b){
		if(a < b){
			return a
		} else {
			return b
		}
	}
	
	function GetNearestPointOnPerimeter(pos){
		
	}
	
	function IsPointInside(pos){
		return (pos.x <= Max(point1.x, point2.x) && pos.x >= Min(point1.x, point2.x)) && (pos.y <= Max(point1.y, point2.y) && pos.y >= Min(point1.y, point2.y)) && (pos.z <= Max(point1.z, point2.z) && pos.z >= Min(point1.z, point2.z))
	}
}

class g_MapScript.CommonBlocker {
	area = null
	
	constructor(pos1, pos2){
		area = g_MapScript.Area(pos1, pos2)
		g_ModeScript.HookController.RegisterTickFunction(CheckForCommons)
	}
	
	function CheckForCommons(){
		local common = null
		while(common = Entities.FindByClassname(common, "infected")){
			local mins = NetProps.GetPropVector(common, "m_vecMins")
			local maxs = NetProps.GetPropVector(common, "m_vecMaxs")
			if(area.IsPointInside(common.GetOrigin() + mins)){
				
			} else if(area.IsPointInside(common.GetOrigin() + maxs)){
				
			}
		}
	}
}

class VitalCarrierPowerup {
	duration = -1
	name = null
	
	function DoEffect(entity){}
	
	function ClearEffect(entity){}
}

class ElixirOfLifePowerup extends VitalCarrierPowerup {
	name = "Elixir of Life"
	
	function DoEffect(entity){
		entity.ValidateScriptScope()
		entity.GetScriptScope()["reviveOnIncap"] <- true
	}
}

class DoublePointsPowerup extends VitalCarrierPowerup {
	duration = 15
	name = "Double Points"
	
	function DoEffect(entity){
		entity.ValidateScriptScope()
		entity.GetScriptScope()["pointsToReceive"] <- 2
	}
	
	function ClearEffect(entity){
		if(entity){
			entity.ValidateScriptScope()
			entity.GetScriptScope()["pointsToReceive"] <- 1
		}
	}
}

class GodmodePowerup extends VitalCarrierPowerup {
	duration = 15
	name = "Godmode"
	
	function DoEffect(entity){
		entity.AddFlag(16384)
	}
	
	function ClearEffect(entity){
		entity.RemoveFlag(16384)
	}
}

class AdrenalineShotPowerup extends VitalCarrierPowerup {
	duration = 15
	name = "Adrenaline Shot"
	
	function DoEffect(entity){
		entity.UseAdrenaline(duration)
		entity.SetHealthBuffer(entity.GetHealthBuffer() + 50)
		entity.SetPropFloat("m_flLaggedMovementValue", entity.GetPropFloat("m_flLaggedMovementValue") * 1.25)
	}
	
	function ClearEffect(entity){
		entity.SetPropFloat("m_flLaggedMovementValue", entity.GetPropFloat("m_flLaggedMovementValue") / 1.25)
	}
}

class MuddyFeetPowerup extends VitalCarrierPowerup {
	duration = 15
	name = "Muddy Feet"
	
	function DoEffect(entity){
		local ent = null
		while(ent = Entities.FindByClassname(ent, "player")){
			if(ent.IsSurvivor() && ent != entity){
				NetProps.SetPropFloat(ent, "m_flLaggedMovementValue", NetProps.GetPropFloat(ent, "m_flLaggedMovementValue") * 0.75)
			}
		}
	}
	
	function ClearEffect(entity){
		local ent = null
		while(ent = Entities.FindByClassname(ent, "player")){
			if(ent.IsSurvivor() && ent != entity){
				NetProps.SetPropFloat(ent, "m_flLaggedMovementValue", NetProps.GetPropFloat(ent, "m_flLaggedMovementValue") / 0.75)
			}
		}
	}
}


powerups <- [ElixirOfLifePowerup, DoublePointsPowerup, GodmodePowerup, AdrenalineShotPowerup, MuddyFeetPowerup]

VitalCarrierGame <- CVitalCarrierGame()

InitialPlayerSpawns <- null

ZombieManager <- null
ItemManager <- null
PowerupManager <- null
SurvivorManager <- null
MatchManager <- null

HUD <- {
	Fields = {
		countdown = { slot = HUD_TICKER, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG | HUD_FLAG_NOTVISIBLE, name = "countdown" }
		grace_period_timer = { slot = HUD_RIGHT_BOT, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOTVISIBLE, name = "grace_period_timer" }
		message_display = { slot = HUD_MID_BOT, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOBG | HUD_FLAG_NOTVISIBLE, name = "message_display" }
		scoreboard = { slot = HUD_MID_TOP, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOTVISIBLE, name = "scoreboard" }
		match_timer = { slot = HUD_RIGHT_TOP, dataval = "",flags = HUD_FLAG_ALIGN_CENTER | HUD_FLAG_NOTVISIBLE, name = "match_timer" }
	}
}

HUDSetLayout(HUD)

HUDPlace(HUD_TICKER, 0.45, 0.45, 0.1, 0.1)
HUDPlace(HUD_MID_BOT, 0.125, 0.2, 0.75, 0.2)
HUDPlace(HUD_MID_TOP, 0.25, 0.25, 0.5, 0.5)
HUDPlace(HUD_RIGHT_TOP, 0.45, 0, 0.10, 0.05)
HUDPlace(HUD_RIGHT_BOT, 0.45, 0, 0.10, 0.05)

DirectorOptions <- {
	CommonLimit = 0
	BoomerLimit = 0
	ChargerLimit = 0
	HunterLimit = 0
	JockeyLimit = 0
	SmokerLimit = 0
	SpitterLimit = 0
	
	FallenSurvivorPotentialQuantity = 999999
	FallenSurvivorSpawnChance = 1
	
	PreferredSpecialDirection = SPAWN_FAR_AWAY_FROM_SURVIVORS
	
	ZombieSpawnRange = 2000
	PreferredMobDirection = SPAWN_FAR_AWAY_FROM_SURVIVORS
	ClearedWandererRespawnChance = 100
	
	ZombieDiscardRange = 999999
	
	ZombieDontClear = true
	
	//SpawnSetRule = SPAWN_POSITIONAL
	SpawnSetPosition = Vector(-6403, -2207, -231)
	SpawnSetRadius = 2700
	
	ProhibitBosses = true
	cm_NoSurvivorBots = true
}

function IsValidMapScript(){
	return "PlayerSpawns" in g_MapScript && "ItemSpawns" in g_MapScript && "PowerupSpawns" in g_MapScript && "PointZombieFleeTargets" in g_MapScript
}

function RemoveAllEntities(classname){
	local ent = null
	while(ent = Entities.FindByClassname(ent, classname)){
		ent.Kill()
	}
}

function ResetBot(ent){
	CommandABot({cmd = 3, bot = ent})
}

function FindPlayer(ent){
	foreach(player in SurvivorManager.GetPlayers()){
		if(player.GetEntity() == ent){
			return player
		}
	}
}

function FindClosestPlayer(vector){
	local closestPlayer = null
	local closestDistance = 99999
	
	local player = null
	while(player = Entities.FindByClassname(player, "player")){
		if(player.IsSurvivor() && (player.GetOrigin() - vector).Length() < closestDistance){
			closestPlayer = player
			closestDistance = (player.GetOrigin() - vector).Length()
		}
	}
	
	return closestPlayer
}

function EnoughVotesToStart(votes){
	return ((votes * 100) / SurvivorManager.GetPlayers().len() >= VitalCarrierGame.GetSetting("percentage_to_start"))
}

function EnoughVotesToStop(votes){
	return ((votes * 100) / SurvivorManager.GetPlayers().len() >= VitalCarrierGame.GetSetting("percentage_to_stop"))
}

function GetVotesToStart(){
	local votes = 0
	foreach(player in SurvivorManager.GetPlayers()){
		if(player.GetVotedToStart()){
			votes += 1
		}
	}
	return votes
}

function GetVotesToStop(){
	local votes = 0
	foreach(player in SurvivorManager.GetPlayers()){
		if(player.GetVotedToStop()){
			votes += 1
		}
	}
	return votes
}

function StopGame(){
	if(VitalCarrierGame.IsStarted()){
		VitalCarrierGame.Stop()
		VitalCarrierGame.SetMatchTimerStarted(false)
		VitalCarrierGame.SetCountdownStarted(false)
		VitalCarrierGame.SetGracePeriodStarted(false)
		
		Convars.SetValue("cl_viewbob",1)
		Convars.SetValue("crosshair",1)
		SurvivorManager.UnfreezeAllPlayers()
		MatchManager.HideTimers()
		MatchManager.ShowScoreboard()
		
		local common = null
		while(common = Entities.FindByClassname(common, "infected")){
			common.Kill()
		}
		
		foreach(player in SurvivorManager.GetPlayers()){
			player.SetVotedToStop(false)
			player.GetEntity().ReviveByDefib()
			player.ResetHealth()
			if(player.GetEntity().GetPropInt("m_survivorCharacter") > 7){
				player.SpawnFromDead()
			}
		}
		Say(null,"Game has been stopped",false)
	}
}

function StartGame(){
	if(!VitalCarrierGame.IsStarted()){
		MatchManager.HideScoreboard()
		Convars.SetValue("cl_viewbob",0)
		Convars.SetValue("crosshair",0)
		
		ZombieManager.Enable()
		
		SurvivorManager.TeleportPlayersToSpawns()
		SurvivorManager.ClearAllPlayersWeapons()
		
		PowerupManager.ClearAllPowerupEffects()
		PowerupManager.ClearAllPowerupEntities()
		local ent = null
		while(ent = Entities.FindByClassname(ent, "player")){
			if(ent.IsValid() && ent.IsSurvivor()){
				NetProps.SetPropInt(ent, "m_fFlags",(NetProps.GetPropInt(ent, "m_fFlags" ) | 32))
				NetProps.SetPropInt(ent, "movetype",0)
				FindPlayer(ent).ResetHealth()
				if(NetProps.GetPropInt(ent,"m_bAdrenalineActive") == 1){
					ent.UseAdrenaline(0)
				}
			}
		}
		
		
		RemoveAllEntities("info_goal_infected_chase")
		RemoveAllEntities("inferno")
		RemoveAllEntities("vomitjar_projectile")
		RemoveAllEntities("molotov_projectile")
		RemoveAllEntities("pipe_bomb_projectile")
		RemoveAllEntities("grenade_launcher_projectile")
	
		ItemManager.RollItemSpawns()
		ItemManager.ClearAllItems()
		ItemManager.SpawnInitialItems()
		PowerupManager.SpawnInitialPowerups()
		
		foreach(player in SurvivorManager.GetPlayers()){
			player.SetVotedToStart(false)
			player.ResetScore()
		}
		
		MatchManager.BeginCountdown()
		Say(null,"Game has started",false)
	}
}

// Chat commands
function PlayerVotedToStart(ent){
	if(!VitalCarrierGame.IsStarted()){
		FindPlayer(ent).SetVotedToStart(true)
		local votes = GetVotesToStart()
		if(EnoughVotesToStart(votes)){
			StartGame()
		} else {
			Say(null,ent.GetPlayerName() + " has voted to start. (" + (ceil((VitalCarrierGame.GetSetting("percentage_to_start") * SurvivorManager.GetPlayers().len()).tofloat()/100) - votes) + " more votes required)",false)
		}
	} else {
		Say(null,"Cannot vote to start if the game is already started!",false)
	}
}

function PlayerVotedToStop(ent){
	if(VitalCarrierGame.IsStarted()){
		FindPlayer(ent).SetVotedToStop(true)
		local votes = GetVotesToStop()
		if(EnoughVotesToStop(votes)){
			StopGame()
		} else {
			Say(null,ent.GetPlayerName() + " has voted to stop. (" + (ceil((VitalCarrierGame.GetSetting("percentage_to_stop") * SurvivorManager.GetPlayers().len()).tofloat()/100) - votes) + " more votes required)",false)
		}
	} else {
		Say(null,"Cannot vote to stop if the game is already stopped!",false)
	}
}

function ToggleGodMode(ent){
	if(NetProps.GetPropInt(ent, "m_fFlags") & 16384){
		NetProps.SetPropInt(ent, "m_fFlags", NetProps.GetPropInt(ent, "m_fFlags") & ~16384)
	} else {
		NetProps.SetPropInt(ent, "m_fFlags", NetProps.GetPropInt(ent, "m_fFlags") | 16384)
	}
}

function SpawnPointZombie(){
	ZombieManager.SpawnPointZombie()
}

function ClearAllZombies(){
	local common = null
	while(common = Entities.FindByClassname(common, "infected")){
		CommandABot({cmd = 3, bot = common})
		common.Kill()
	}
	ZombieManager.ResetCounts()
}

function SayScores(ent){
	Say(null, "Your score is: " + FindPlayer(ent).GetScore(), false)
}

function EnableZombies(){
	ZombieManager.Enable()
}

function DisableZombies(){
	ZombieManager.Disable()
}


function MovePlayersToSpawnPoints(spawns){
	if(spawns != null && spawns.len() > 0){
		local index = 0
		
		local ent = null
		while(ent = Entities.FindByClassname(ent, "player")){
			ent.SetOrigin(spawns[index].GetOrigin())
			ent.SetAngles(spawns[index].GetAngles())
			index++
			if(index >= spawns.len()){
				index = 0
			}
		}
	}
}

function ShowPointZombieKilledHint(player){
	local hint = SpawnEntityFromTable("env_instructor_hint", {hint_caption = player.GetPlayerName() + " just killed a point zombie!", hint_static = 1, hint_icon_offscreen = "icon_alert_red", hint_icon_onscreen = "icon_alert_red", hint_timeout = VitalCarrierGame.GetSetting("hint_point_zombie_killed_timeout"), hint_color = VitalCarrierGame.GetSetting("hint_point_zombie_killed_color"), hint_auto_start = 0, hint_instance_type = 0})
	local playerHint = SpawnEntityFromTable("env_instructor_hint", {hint_caption = "You killed a point zombie!", hint_static = 1, hint_icon_offscreen = "icon_alert_red", hint_icon_onscreen = "icon_alert_red", hint_timeout = VitalCarrierGame.GetSetting("hint_point_zombie_killed_timeout"), hint_color = VitalCarrierGame.GetSetting("hint_point_zombie_killed_color"), hint_auto_start = 0, hint_instance_type = 0})
	local survivor = null
	while(survivor = Entities.FindByClassname(survivor, "player")){
		if(survivor.IsSurvivor()){
			local name = UniqueString()
			NetProps.SetPropString(survivor, "m_iName", name)
			if(survivor != player){
				printl("Showing hint that " + player + " killed a point zombie to " + survivor)
				DoEntFire("!self", "ShowHint", "0", 0, survivor, hint)
			} else {
				printl("Showing hint that " + player + " killed a point zombie to themself")
				DoEntFire("!self", "ShowHint", "0", 0, survivor, playerHint)
			}
		}
	}
	
	local removalFunc = function(){
		hint.Kill()
		playerHint.Kill()
	}
	
	HookController.ScheduleTask(removalFunc, {hint = hint, playerHint = playerHint}, VitalCarrierGame.GetSetting("hint_point_zombie_killed_timeout") + 5)
}

function ShowPointZombieSpawnedHint(){
	local hint = SpawnEntityFromTable("env_instructor_hint", {hint_caption = "A point zombie just spawned!", hint_static = 1, hint_icon_offscreen = "icon_alert_red", hint_icon_onscreen = "icon_alert_red", hint_timeout = VitalCarrierGame.GetSetting("hint_point_zombie_spawned_timeout"), hint_color = VitalCarrierGame.GetSetting("hint_point_zombie_spawned_color"), hint_auto_start = 0})
	DoEntFire("!self", "ShowHint", "0", 0, null, hint)
	HookController.ScheduleTask(function(){hint.Kill()}, {hint = hint}, VitalCarrierGame.GetSetting("hint_point_zombie_spawned_timeout") + 5)
}

function ShowPlayerBiledHint(player){
	//local hintTargetName = UniqueString()
	local playerName = UniqueString()
	NetProps.SetPropString(player, "m_iName", playerName)
	local hint = SpawnEntityFromTable("env_instructor_hint", {hint_caption = player.GetPlayerName() + " is covered in bile!", hint_static = 0, hint_icon_offscreen = "icon_alert_red", hint_icon_onscreen = "icon_alert_red", hint_timeout = VitalCarrierGame.GetSetting("hint_player_biled_timeout"), hint_color = VitalCarrierGame.GetSetting("hint_player_biled_color"), hint_auto_start = 0, hint_icon_offset = 31, hint_target = playerName})
	//local hintTarget = SpawnEntityFromTable("info_target_instructor_hint", {targetname = hintTargetName, origin = player.GetOrigin()})
	//EntFire(hintTargetName, "SetParent", playerName)
	local survivor = null
	while(survivor = Entities.FindByClassname(survivor, "player")){
		if(survivor.IsSurvivor()){
			if(survivor != player && Time() >= NetProps.GetPropFloat(survivor, "m_itTimer.m_timestamp")){
				printl("Showing hint to " + survivor + " that " + player + " has been biled")
				DoEntFire("!self", "ShowHint", "0", 0, survivor, hint)
			}
		}
	}
	
	HookController.ScheduleTask(function(){hint.Kill()}, {hint = hint}, VitalCarrierGame.GetSetting("hint_player_biled_timeout") + 5)
}

function ShowPlayerKilledHint(player){
	local hint = SpawnEntityFromTable("env_instructor_hint", {hint_caption = player.GetPlayerName() + " has died.", hint_static = 1, hint_icon_offscreen = "icon_blank", hint_icon_onscreen = "icon_blank", hint_timeout = VitalCarrierGame.GetSetting("hint_player_killed_timeout"), hint_color = VitalCarrierGame.GetSetting("hint_player_killed_color"), hint_auto_start = 0})
	local survivor = null
	while(survivor = Entities.FindByClassname(survivor, "player")){
		if(survivor.IsSurvivor()){
			local name = UniqueString()
			NetProps.SetPropString(survivor, "m_iName", name)
			if(survivor != player){
				DoEntFire("!self", "ShowHint", "0", 0, survivor, hint)
			}
		}
	}
	
	HookController.ScheduleTask(function(){hint.Kill()}, {hint = hint}, VitalCarrierGame.GetSetting("hint_player_killed_timeout") + 5)
}
	
function RemoveFallenSurvivorItems(fallenSurvivor){
	if(fallenSurvivor != null){
		if(Entities.FindByClassnameNearest("weapon_pipe_bomb", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64) != null){
			Entities.FindByClassnameNearest("weapon_pipe_bomb", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64).Kill()
		}
		if(Entities.FindByClassnameNearest("weapon_molotov", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64) != null){
			Entities.FindByClassnameNearest("weapon_molotov", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64).Kill()
		}
		if(Entities.FindByClassnameNearest("weapon_pain_pills", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64) != null){
			Entities.FindByClassnameNearest("weapon_pain_pills", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64).Kill()
		}
		if(Entities.FindByClassnameNearest("weapon_first_aid_kit", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64) != null){
			Entities.FindByClassnameNearest("weapon_first_aid_kit", fallenSurvivor.GetOrigin() + Vector(0,0,31), 64).Kill()
		}
	}
}

function DropFallenSurvivorItems(fallenSurvivor){
	if(RandomFloat(0,1) <= VitalCarrierGame.GetSetting("point_zombie_item_drop_chance")){
		if(RandomFloat(0,1) <= VitalCarrierGame.GetSetting("point_zombie_adrenaline_drop_chance")){
			SpawnEntityFromTable("weapon_adrenaline", {origin = fallenSurvivor.GetOrigin() + Vector(0,0,31)})
		} else if(RandomFloat(0,1) <= VitalCarrierGame.GetSetting("point_zombie_pain_pills_drop_chance")){
			SpawnEntityFromTable("weapon_pain_pills", {origin = fallenSurvivor.GetOrigin() + Vector(0,0,31)})
		} else if(RandomFloat(0,1) <= VitalCarrierGame.GetSetting("point_zombie_powerup_drop_chance")){
			PowerupManager.SpawnDroppedPowerup(fallenSurvivor.GetOrigin())
		}
	}
}

function SpawnPointZombieSmoke(origin){
	local particleSystem = SpawnEntityFromTable("info_particle_system", {origin = origin, effect_name = "aircraft_destroy_smokepufflong", angles = Vector(0, 0, 0)})
	
	DoEntFire("!self", "Start", "0", 0, null, particleSystem)
	
	HookController.ScheduleTask(function(){particleSystem.Kill()}, {particleSystem = particleSystem}, 1)
}

function LaunchFirework(origin){
	local particleSystem = SpawnEntityFromTable("info_particle_system", {origin = origin, effect_name = "fireworks_01", angles = Vector(0, 90, 0)})
	DoEntFire("!self", "Start", "0", 0, null, particleSystem)
	EmitSoundOn("c2m5.fireworks_launch", particleSystem)
	
	local burstSoundFunc = function(){
		ent.SetOrigin(pos)
		EmitSoundOn("c2m5.fireworks_burst", ent)
	}
	
	local removalFunc = function(){
		ent.Kill()
	}
	
	HookController.ScheduleTask(burstSoundFunc, {ent = particleSystem, pos = origin + Vector(0,0,1600)}, 1.9)
	
	HookController.ScheduleTask(removalFunc, {ent = particleSystem}, 6)
}

function GetAvailableCharacter(ent){
	local l4d2Characters = true
	local availableL4D2Characters = [0, 1, 2, 3]
	local availableL4D1Characters = [4, 5, 6, 7]
	
	local survivor = null
	while(survivor = Entities.FindByClassname(survivor, "player")){
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
		return availableL4D2Characters[RandomInt(0, availableL4D2Characters.len() - 1)]
	} else {
		return availableL4D1Characters[RandomInt(0, availableL4D1Characters.len() - 1)]
	}
}


function OnInventoryChange(player, removed_weapons, new_weapons){
	ItemManager.OnInventoryChange(player, removed_weapons, new_weapons)
}

function AllowTakeDamage(params){
	local victim = params.Victim
	local attacker = params.Attacker
	local weapon = params.Weapon
	
	victim.ValidateScriptScope()
	attacker.ValidateScriptScope()
	
	//printl("type: " + params.DamageType)
	//printl("damage: " + params.DamageDone)
	//printl("weapon: " + weapon)
	//printl("time: " + Time())
	//printl("attacker: " + attacker)
	//printl("victim dead: " + (NetProps.GetPropInt(victim, "m_lifeState") == 1))
	//printl("health after damage: " + (victim.GetHealth() + victim.GetHealthBuffer() - params.DamageDone))
	
	
	if(victim != null && victim.GetClassname() == "player" && victim.IsSurvivor() && !VitalCarrierGame.IsStarted()){
		return false
	}
	if(victim != null && victim.GetClassname() == "player" && victim.IsSurvivor() && attacker != null && attacker.GetClassname() == "player" && attacker.IsSurvivor() && attacker != victim){
		return false
	}
	/*if(victim != null && victim.GetClassname() == "player" && victim.IsSurvivor() && (victim.GetHealth() + victim.GetHealthBuffer() - params.DamageDone) <= 0 && NetProps.GetPropInt(victim, "m_lifeState") == 0 && !(NetProps.GetPropInt(victim, "m_fFlags") & 16384)){
		// triggers multiple times sometimes because common hits will not actually count
		return OnTakeFatalDamage(victim)
	}*/
	if(victim != null && victim.GetClassname() == "infected" && params.DamageDone > 0){
		if("pointZombie" in victim.GetScriptScope() && !("dead" in victim.GetScriptScope())){
			if(weapon != null && params.DamageDone > 0){
				if(weapon.GetClassname() == "weapon_melee"){
					params.DamageDone = NetProps.GetPropInt(victim, "m_iMaxHealth") * VitalCarrierGame.GetSetting("point_zombie_melee_damage_modifier")
				} else if(weapon.GetClassname() == "weapon_chainsaw"){
					params.DamageDone = NetProps.GetPropInt(victim, "m_iMaxHealth") * VitalCarrierGame.GetSetting("point_zombie_chainsaw_damage_modifier")
				} else if(weapon.GetClassname() == "weapon_rifle_m60"){
					params.DamageDone = NetProps.GetPropInt(victim, "m_iMaxHealth") * VitalCarrierGame.GetSetting("point_zombie_m60_damage_modifier")
				}
			} else if(weapon == null){
				if(params.DamageType = 16777280){
					//grenade launcher damage is applied twice, so half the damage modifier
					params.DamageDone = NetProps.GetPropInt(victim, "m_iMaxHealth") * VitalCarrierGame.GetSetting("point_zombie_grenade_launcher_damage_modifier") / 2
					if(victim.GetHealth() - params.DamageDone <= 0){
						ZombieManager.OnPointZombieKilled(victim, attacker)
						return true
					}
					victim.SetHealth(victim.GetHealth() - params.DamageDone)
					ZombieManager.OnPointZombieDamaged(victim, attacker)
					return false
				}
			}
			if(victim.GetHealth() - params.DamageDone <= 0){
				ZombieManager.OnPointZombieKilled(victim, attacker)
				return true
			}
			ZombieManager.OnPointZombieDamaged(victim, attacker)
		}
	}
	return true
}

function OnGameplayStart(){
	if(!IsValidMapScript()){
		VitalCarrierGame.SetEnabled(false)
		HUD.Fields.message_display.flags = HUD.Fields.message_display.flags & ~HUD_FLAG_NOTVISIBLE
		HUD.Fields.message_display.dataval = "This map is unsupported, please contact Daroot Leafstorm."
	} else {
		IncludeScript("ImprovedScripting")
		
		HookController <- {}
		IncludeScript("HookController", HookController)
		HookController.RegisterHooks(this)
		
		ZombieManager = CZombieManager(g_MapScript["PointZombieFleeTargets"])
		ItemManager = CItemManager(g_MapScript["ItemSpawns"])
		PowerupManager = CPowerupManager(g_MapScript["PowerupSpawns"])
		SurvivorManager = CSurvivorManager(g_MapScript["PlayerSpawns"])
		MatchManager = CMatchManager()
		
		InitialPlayerSpawns = g_MapScript.InitialPlayerSpawns
		
		HookController.RegisterChatCommand("!start", function(ent){g_ModeScript.PlayerVotedToStart(ent)}, false)
		HookController.RegisterChatCommand("!stop", function(ent){g_ModeScript.PlayerVotedToStop(ent)}, false)
		HookController.RegisterChatCommand("!god", function(ent){g_ModeScript.ToggleGodMode(ent)}, false)
		HookController.RegisterChatCommand("!clearall", function(ent){g_ModeScript.ClearAllZombies()}, false)
		HookController.RegisterChatCommand("!spawnpointzombie", function(ent){g_ModeScript.SpawnPointZombie()}, false)
		HookController.RegisterChatCommand("!enablezombies", function(ent){g_ModeScript.EnableZombies()}, false)
		HookController.RegisterChatCommand("!disablezombies", function(ent){g_ModeScript.DisableZombies()}, false)
		HookController.RegisterChatCommand("!score", function(ent){g_ModeScript.SayScores(ent)}, false)
		HookController.RegisterChatCommand("!forcestart", function(ent){g_ModeScript.StartGame()}, false)
		HookController.RegisterChatCommand("!forcestop", function(ent){g_ModeScript.StopGame()}, false)
		HookController.RegisterChatCommand("!script", function(ent, input){compilestring(input)()}, true)
		
		HookController.ScheduleTask(SurvivorManager.GiveAllPlayersPistols, {}, 0.033)
		ItemManager.ClearAllItems()
		//SpawnInitialItems()
		//SpawnInitialPowerups()
		MovePlayersToSpawnPoints(g_MapScript.InitialPlayerSpawns)
	}
}

function OnGameEvent_entity_shoved(params){
	local ent = EntIndexToHScript(params.entityid)
	if(ent != null){
		ent.ValidateScriptScope()
		if("pointZombie" in ent.GetScriptScope() && !("dead" in ent.GetScriptScope())){
			ZombieManager.OnPointZombieShoved(ent, GetPlayerFromUserID(params.attacker))
		}
	}
}

function OnGameEvent_player_spawn(params){
	local userid = params.userid
	if(!VitalCarrierGame.IsStarted()){
		local ent = GetPlayerFromUserID(userid)
		if(ent != null && ent.IsValid() && !ent.IsDead() && ent.GetActiveWeapon() == null){
			ent.GiveItem("pistol")
		}
	}
}

function OnGameEvent_player_use(params){
	local player = GetPlayerFromUserID(params.userid)
	local item = EntIndexToHScript(params.targetid)
	item.ValidateScriptScope()
	if("powerupClass" in item.GetScriptScope()){
		if(!("droppedPowerup" in item.GetScriptScope())){
			foreach(spawn in PowerupManager.GetPowerupSpawns()){
				if(spawn.GetPowerup() == item){
					PowerupManager.OnPowerupPickup(player, spawn)
					break
				}
			}
		}
		local invTable = {}
		GetInvTable(player, invTable)
		invTable["slot5"].Kill()
	}
}

function OnGameEvent_player_connect_full(params){
	local ent = GetPlayerFromUserID(params["userid"])
	
	if("HookController" in g_ModeScript && !VitalCarrierGame.IsStarted()){
		HookController.ScheduleTask(function(){g_ModeScript.FindPlayer(ent).SpawnFromDead()}, {ent = ent}, 0.1)
	}
}