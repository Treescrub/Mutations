IncludeScript("schizophrenia")

/*::GetPlayer <- function(){
	local ent = null
	local ents = []
	while(ent = Entities.FindByClassname(ent,"player")){
		if(ent.IsValid() && ent.IsSurvivor()){
			ents.append(ent)
		}
	}
	
	return ents[RandomInt(0, ents.len() - 1)]
}

::GetPlayerCount <- function(){
	local count = 0
	local ent = null
	while(ent = Entities.FindByClassname(ent, "player")){
		if(ent.IsSurvivor()){
			count += 1
		}
	}
	return count
}

::GetRandomSign <- function(){
	local sign = RandomInt(0,1)
	if(sign == 1){
		return 1
	} else {
		return -1
	}
}


class SoundManager {
	lastSpecialSound = 0
	lastSurvivorSound = 0
	lastWeatherSound = 0
	lastAmbientSound = 0
	
	weatherSounds = ["Weather.lightning_strike_1","Weather.lightning_strike_2","Weather.lightning_strike_3","Weather.lightning_strike_4","Weather.thunder_1","Weather.thunder_2","Weather.thunder_3","Weather.thunder_far_away_1","Weather.thunder_far_away_2","Weather.thunder_close_1","Weather.thunder_close_2","Weather.thunder_close_3","Weather.thunder_close_4"]
	ambientSounds = ["npc/infected/alert/becomealert/hiss01","ambient/creatures/town_scared_sob2","ambient/creatures/town_moan1","ambient/random_amb_sounds/randbridgegroan_12","ambient/random_amb_sounds/randbridgegroan_10","ambient/materials/metal5","ambient/materials/metal_rattle1","ambient/levels/caves/dist_growl1","ambient/levels/caves/dist_growl3","ambient/levels/citadel/strange_talk1","ambient/levels/citadel/strange_talk5","ambient/random_amb_sfx/cable_rattle03","play ambient/random_amb_sfx/fire_groan_02","ambient/random_amb_sfx/mall_random_11","ambient/random_amb_sfx/mall_random_12","ambient/random_amb_sfx/mall_random_14","ambient/random_amb_sfx/rur_random_coyote02"]
	survivorSounds = {
		nick = ["Gambler_WorldC5M2B14", "Gambler_WorldC3M2B24", "Gambler_WorldC3M2B23", "Gambler_WorldC3M2B22", "Gambler_WorldC2M210", "Gambler_World219", "Gambler_WaitHere01", "Gambler_StayTogetherInside04", "Gambler_StayTogetherInside07", "Gambler_StayTogetherInside01", "Gambler_Sorry07", "Gambler_Sorry06", "Gambler_Sorry03", "Gambler_ScreamWhilePounced06", "Gambler_ScreamWhilePounced05", "Gambler_ScreamWhilePounced05a", "Gambler_ScreamWhilePounced04a", "Gambler_ScreamWhilePounced03a", "Gambler_ScreamWhilePounced01", "Gambler_MiscDirectional66", "Gambler_MiscDirectional06", "Gambler_MiscDirectional03", "Gambler_LostCall05", "Gambler_LostCall04", "Gambler_LostCall03", "Gambler_LostCall02", "Gambler_LostCall01", "Gambler_LedgeHangStart03", "Gambler_LedgeHangStart04", "Gambler_LedgeHangMiddle02", "Gambler_LedgeHangFall02", "Gambler_LedgeHangFall01", "Gambler_LedgeHangEnd03", "Gambler_LedgeHangEnd02", "Gambler_Laughter17", "Gambler_Laughter16", "Gambler_Laughter15", "Gambler_Laughter06", "Gambler_Laughter03", "Gambler_Laughter01", "Gambler_IncapacitatedInjury05", "Gambler_IncapacitatedInjury04", "Gambler_IncapacitatedInjury03", "Gambler_IncapacitatedInjury02", "Gambler_IncapacitatedInjury01", "Gambler_HurtCritical06", "Gambler_HurtCritical05", "Gambler_HurtCritical04", "Gambler_Help05", "Gambler_Help04", "Gambler_Help01"]
		ellis = ["Mechanic_WorldC3M248", "Mechanic_WorldC3M249", "Mechanic_WorldC3M245", "Mechanic_WorldC3M242", "Mechanic_WorldC3M244", "Mechanic_WaitHere03", "Mechanic_TankPound04", "Mechanic_TankPound01", "Mechanic_ScreamWhilePounced07c", "Mechanic_ScreamWhilePounced06", "Mechanic_ScreamWhilePounced04a", "Mechanic_ScreamWhilePounced04", "Mechanic_MiscDirectional66", "Mechanic_LostCall04", "Mechanic_LostCall03", "Mechanic_LostCall01", "Mechanic_LedgeHangStart02", "Mechanic_LedgeHangStart01", "Mechanic_LedgeHangFall01", "Mechanic_LedgeHangEnd04", "Mechanic_LedgeHangEnd02", "Mechanic_LedgeHangEnd01", "Mechanic_Laughter14", "Mechanic_Laughter13b", "Mechanic_Laughter09", "Mechanic_Laughter05", "Mechanic_Laughter04", "Mechanic_IncapacitatedInjury06", "Mechanic_IncapacitatedInjury05", "Mechanic_IncapacitatedInjury04", "Mechanic_IncapacitatedInjury03", "Mechanic_IncapacitatedInjury02", "Mechanic_IncapacitatedInjury01", "Mechanic_HurtCritical05", "Mechanic_HurtCritical04", "Mechanic_HurtCritical01", "Mechanic_Help06", "Mechanic_Help05", "Mechanic_Help01"]
		rochelle = ["Producer_WaitHere01", "Producer_TankPound01", "Producer_TankPound03", "Producer_TankPound04", "Producer_ScreamWhilePounced05", "Producer_ScreamWhilePounced04a", "Producer_ScreamWhilePounced03", "Producer_ScreamWhilePounced02b", "Producer_ScreamWhilePounced01", "Producer_MiscDirectional65", "Producer_LostCall03", "Producer_LostCall05", "Producer_LostCall02", "Producer_LostCall01", "Producer_LedgeHangStart03", "Producer_LedgeHangStart02", "Producer_LedgeHangEnd02", "Producer_LedgeHangEnd01", "Producer_Laughter17", "Producer_Laughter14", "Producer_Laughter13", "Producer_Laughter12", "Producer_Laughter04", "Producer_Laughter01", "Producer_IncapacitatedInjury04", "Producer_IncapacitatedInjury03", "Producer_IncapacitatedInjury02", "Producer_IncapacitatedInjury01", "Producer_HurtCritical03", "Producer_HurtCritical01", "Producer_Help06", "Producer_Help05", "Producer_Help04", "Producer_Help08", "Producer_Help01"]
		coach = ["Coach_TankPound06", "Coach_TankPound05", "Coach_TankPound01", "Coach_ScreamWhilePounced05", "Coach_ScreamWhilePounced04", "Coach_ScreamWhilePounced03", "Coach_ScreamWhilePounced02a", "Coach_ScreamWhilePounced02", "Coach_ScreamWhilePounced01", "Coach_MiscDirectional68", "Coach_MiscDirectional66", "Coach_LostCall02", "Coach_LostCall01", "Coach_LedgeHangStart01", "Coach_LedgeHangMiddle02", "Coach_LedgeHangEnd03", "Coach_Laughter22", "Coach_Laughter14", "Coach_Laughter07", "Coach_Laughter04", "Coach_Laughter01", "Coach_IncapacitatedInjury11", "Coach_IncapacitatedInjury10", "Coach_IncapacitatedInjury07", "Coach_IncapacitatedInjury03", "Coach_IncapacitatedInjury01", "Coach_Help06", "Coach_Help02", "Coach_Help01", "Coach_Help04"]
		
		bill = ["Player.NamVet_TankPound02", "Player.NamVet_TankPound01", "Player.NamVet_TankPound03", "Player.NamVet_ScreamWhilePounced03", "Player.NamVet_ScreamWhilePounced02", "Player.NamVet_ScreamWhilePounced01", "Player.NamVet_AnswerLostCall02", "Player.NamVet_AnswerLostCall03", "Player.NamVet_AnswerLostCall04", "Player.NamVet_AnswerLostCall06", "Player.NamVet_CallForRescue01", "Player.NamVet_CallForRescue03", "Player.NamVet_CallForRescue05", "Player.NamVet_CallForRescue12", "Player.NamVet_DeathScream01", "Player.NamVet_DeathScream02", "Player.NamVet_DeathScream03", "Player.NamVet_DeathScream04", "Player.NamVet_DeathScream05", "Player.NamVet_DeathScream06", "Player.NamVet_DeathScream07", "Player.NamVet_DeathScream08", "npc.NamVet_Dying01", "npc.NamVet_Dying04", "npc.NamVet_Dying03", "Player.NamVet_ExertionCritical01", "Player.NamVet_ExertionCritical02", "Player.NamVet_ExertionCritical03", "Player.NamVet_ExertionCritical04", "Player.NamVet_ExertionMajor01", "Player.NamVet_ExertionMajor02", "Player.NamVet_Fall01", "Player.NamVet_Fall02", "Player.NamVet_Fall03", "Player.NamVet_Fall04", "Player.NamVet_FollowMe05", "Player.NamVet_FollowMe07", "Player.NamVet_Generic01", "npc.NamVet_Generic05", "npc.NamVet_GettingRevived12", "Player.NamVet_GoingToDie04", "npc.NamVet_GoingToDieLight05", "npc.NamVet_GRABBEDBYSMOKER01", "Player.NamVet_GrabbedBySmoker01a", "Player.NamVet_GrabbedBySmoker01b", "npc.NamVet_GRABBEDBYSMOKER02", "Player.NamVet_GrabbedBySmoker02a", "Player.NamVet_GrabbedBySmoker02b", "Player.NamVet_GrabbedBySmoker03", "Player.NamVet_GrabbedBySmoker04", "Player.NamVet_Help01", "Player.NamVet_Help03", "Player.NamVet_Help05", "Player.NamVet_Help06", "Player.NamVet_Help07", "Player.NamVet_Help11", "Player.NamVet_Help12", "Player.NamVet_HurtCritical01", "Player.NamVet_HurtCritical02", "Player.NamVet_HurtCritical04", "Player.NamVet_HurtCritical09", "npc.NamVet_IncapacitatedInitial03", "Player.NamVet_IncapacitatedInjury01", "Player.NamVet_IncapacitatedInjury02", "Player.NamVet_IncapacitatedInjury03", "Player.NamVet_IncapacitatedInjury04", "Player.NamVet_IncapacitatedInjury05", "npc.NamVet_Laughter01", "npc.NamVet_Laughter02", "npc.NamVet_Laughter04", "npc.NamVet_Laughter05", "npc.NamVet_Laughter06", "npc.NamVet_Laughter07", "npc.NamVet_Laughter08", "npc.NamVet_Laughter09", "npc.NamVet_Laughter10", "npc.NamVet_Laughter11", "npc.NamVet_Laughter12", "npc.NamVet_Laughter13", "npc.NamVet_Laughter14", "Player.NamVet_LedgeHangMiddle03", "Player.NamVet_LedgeHangMiddle05", "Player.NamVet_LedgeHangStart08"]
		louis = ["Player.Manager_TankPound01", "Player.Manager_TankPound02", "Player.Manager_TankPound03", "Player.Manager_TankPound04", "Player.Manager_TankPound05", "npc.Manager_SCREAMWHILEPOUNCED03C", "npc.Manager_SCREAMWHILEPOUNCED03B", "Player.Manager_ScreamWhilePounced03", "npc.Manager_SCREAMWHILEPOUNCED02B", "npc.Manager_SCREAMWHILEPOUNCED02A", "Player.Manager_ScreamWhilePounced02", "Player.Manager_ScreamWhilePounced01", "Player.Manager_AnswerLostCall02", "Player.Manager_AnswerLostCall01", "Player.Manager_CallForRescue04", "Player.Manager_CallForRescue05", "Player.Manager_DeathScream01", "Player.Manager_DeathScream02", "Player.Manager_DeathScream03", "Player.Manager_DeathScream04", "Player.Manager_DeathScream05", "Player.Manager_DeathScream06", "Player.Manager_DeathScream07", "Player.Manager_DeathScream08", "Player.Manager_DeathScream09", "Player.Manager_DeathScream10", "npc.Manager_Dying01", "Player.Manager_ExertionCritical01", "Player.Manager_ExertionMajor01", "Player.Manager_ExertionMinor01", "Player.Manager_Fall01", "Player.Manager_Fall02", "Player.Manager_Fall03", "Player.Manager_FollowMe04", "Player.Manager_FollowMe02", "Player.Manager_GoingToDie13", "npc.Manager_GRABBEDBYSMOKER01", "Player.Manager_GrabbedBySmoker01a", "Player.Manager_GrabbedBySmoker01b", "npc.Manager_GRABBEDBYSMOKER02", "Player.Manager_GrabbedBySmoker02a", "Player.Manager_GrabbedBySmoker02b", "npc.Manager_GRABBEDBYSMOKER03", "Player.Manager_GrabbedBySmoker03a", "Player.Manager_GrabbedBySmoker03b", "Player.Manager_GrabbedBySmoker04", "Player.Manager_Help01", "Player.Manager_Help02", "Player.Manager_Help03", "Player.Manager_Help05", "Player.Manager_Help06", "Player.Manager_Help09", "Player.Manager_Help10", "Player.Manager_HurtCritical01", "Player.Manager_HurtCritical02", "Player.Manager_HurtCritical03", "Player.Manager_IncapacitatedInjury01", "Player.Manager_IncapacitatedInjury02", "Player.Manager_IncapacitatedInjury03", "npc.Manager_Laughter02", "npc.Manager_Laughter04", "npc.Manager_Laughter05", "npc.Manager_Laughter13", "npc.Manager_Laughter14", "npc.Manager_Laughter20", "npc.Manager_Laughter21", "Player.Manager_LedgeHangStart02", "Player.Manager_Taunt07", "Player.Manager_Taunt08", "Player.Manager_Taunt09"]
		francis = ["Player.Biker_TankPound01", "Player.Biker_TankPound03", "Player.Biker_ScreamWhilePounced04", "Player.Biker_ScreamWhilePounced03", "Player.Biker_ScreamWhilePounced02", "Player.Biker_ScreamWhilePounced01", "Player.Biker_AnswerLostCall02", "Player.Biker_AnswerLostCall01", "Player.Biker_CallForRescue01", "Player.Biker_CallForRescue04", "Player.Biker_CallForRescue13", "Player.Biker_DeathScream01", "Player.Biker_DeathScream02", "Player.Biker_DeathScream03", "Player.Biker_DeathScream04", "Player.Biker_DeathScream05", "Player.Biker_DeathScream06", "Player.Biker_DeathScream07", "Player.Biker_DeathScream08", "Player.Biker_DeathScream09", "Player.Biker_DeathScream10", "npc.Biker_Dying01", "Player.Biker_ExertionCritical01", "Player.Biker_Fall01", "Player.Biker_Fall02", "Player.Biker_Fall03", "Player.Biker_FollowMe01", "Player.Biker_FollowMe04", "npc.Biker_GRABBEDBYSMOKER01", "Player.Biker_GrabbedBySmoker01a", "npc.Biker_GRABBEDBYSMOKER01B", "npc.Biker_GRABBEDBYSMOKER02", "Player.Biker_GrabbedBySmoker02a", "Player.Biker_GrabbedBySmoker02b", "npc.Biker_GRABBEDBYSMOKER02B", "Player.Biker_GrabbedBySmoker03", "Player.Biker_Help01", "Player.Biker_Help03", "Player.Biker_Help05", "Player.Biker_Help10", "Player.Biker_Help12", "Player.Biker_IncapacitatedInjury01", "Player.Biker_IncapacitatedInjury02", "Player.Biker_IncapacitatedInjury03", "Player.Biker_IncapacitatedInjury04", "Player.Biker_IncapacitatedInjury05", "Player.Biker_IncapacitatedInjury06", "npc.Biker_Laughter04", "npc.Biker_Laughter12", "npc.Biker_Laughter13", "npc.Biker_Laughter14", "npc.Biker_Laughter15", "Player.Biker_LedgeHangStart01", "Player.Biker_LedgeHangStart02"]
		zoey = ["Player.TeenGirl_TankPound01", "Player.TeenGirl_TankPound02", "Player.TeenGirl_TankPound04", "Player.TeenGirl_TankPound05", "Player.TeenGirl_ScreamWhilePounced06", "npc.TeenGirl_SCREAMWHILEPOUNCED04B", "npc.TeenGirl_SCREAMWHILEPOUNCED04A", "Player.TeenGirl_ScreamWhilePounced04", "npc.TeenGirl_SCREAMWHILEPOUNCED03", "npc.TeenGirl_SCREAMWHILEPOUNCED02B", "npc.TeenGirl_SCREAMWHILEPOUNCED02A", "Player.TeenGirl_ScreamWhilePounced02", "Player.TeenGirl_ScreamWhilePounced01", "Player.TeenGirl_AnswerLostCall07", "Player.TeenGirl_AnswerLostCall02", "Player.TeenGirl_AnswerLostCall03", "npc.TeenGirl_CALLFORRESCUE03", "Player.TeenGirl_CallForRescue04", "Player.TeenGirl_CallForRescue07", "npc.TeenGirl_CALLFORRESCUE09", "npc.TeenGirl_CALLFORRESCUE12", "Player.TeenGirl_CallForRescue13", "Player.TeenGirl_DeathScream01", "Player.TeenGirl_DeathScream02", "Player.TeenGirl_DeathScream03", "Player.TeenGirl_DeathScream04", "Player.TeenGirl_DeathScream05", "Player.TeenGirl_DeathScream06", "Player.TeenGirl_DeathScream07", "Player.TeenGirl_DeathScream08", "Player.TeenGirl_DeathScream09", "Player.TeenGirl_DeathScream10", "Player.TeenGirl_DeathScream11", "Player.TeenGirl_Dying01", "Player.TeenGirl_Dying02", "Player.TeenGirl_Dying04", "Player.TeenGirl_Dying05", "Player.TeenGirl_ExertionCritical01", "Player.TeenGirl_ExertionCritical04", "Player.TeenGirl_ExertionMinor01", "Player.TeenGirl_Fall01", "Player.TeenGirl_Fall02", "Player.TeenGirl_Fall03", "Player.TeenGirl_FollowMe03", "Player.TeenGirl_FollowMe05", "Player.TeenGirl_GoingToDie369", "Player.TeenGirl_GoingToDie370", "npc.TeenGirl_GRABBEDBYSMOKER01", "Player.TeenGirl_GrabbedBySmoker01a", "Player.TeenGirl_GrabbedBySmoker01b", "Player.TeenGirl_GrabbedBySmoker01c", "npc.TeenGirl_GRABBEDBYSMOKER02", "Player.TeenGirl_GrabbedBySmoker02a", "Player.TeenGirl_GrabbedBySmoker02b", "Player.TeenGirl_GrabbedBySmoker02c", "npc.TeenGirl_GRABBEDBYSMOKER03", "Player.TeenGirl_GrabbedBySmoker03c", "npc.TeenGirl_GRABBEDBYSMOKER04", "Player.TeenGirl_GrabbedBySmoker04b", "Player.TeenGirl_Help01", "Player.TeenGirl_Help02", "Player.TeenGirl_Help03", "Player.TeenGirl_Help04", "Player.TeenGirl_Help08", "Player.TeenGirl_Help13", "Player.TeenGirl_Help15", "Player.TeenGirl_Help16", "Player.TeenGirl_HurtCritical01", "Player.TeenGirl_HurtCritical03", "Player.TeenGirl_IncapacitatedInjury01", "Player.TeenGirl_IncapacitatedInjury02", "Player.TeenGirl_IncapacitatedInjury03", "Player.TeenGirl_IncapacitatedInjury04", "npc.TeenGirl_Laughter01", "npc.TeenGirl_Laughter02", "npc.TeenGirl_Laughter03", "npc.TeenGirl_Laughter04", "npc.TeenGirl_Laughter05", "npc.TeenGirl_Laughter06", "npc.TeenGirl_Laughter09", "npc.TeenGirl_Laughter10", "npc.TeenGirl_Laughter11", "npc.TeenGirl_Laughter12", "npc.TeenGirl_Laughter14", "Player.TeenGirl_LedgeHangStart03", "Player.TeenGirl_LedgeHangStart10"]
	}
	
	function PlaySounds(){
		PlaySpecialSound()
		PlaySurvivorSound()
		PlayWeatherSound()
		PlayAmbientSound()
	}
	
	function PlaySpecialSound(){
		if(Time() >= lastSpecialSound + (RandomInt(15, 25) / pow(GetPlayerCount(), 0.3)) && Director.HasAnySurvivorLeftSafeArea() && !(NetProps.GetPropInt(GetPlayer(),"m_fFlags") & 32)){
			soundTarget.SetOrigin(Vector(RandomInt(300, 1000) * GetRandomSign(), RandomInt(400,700) * GetRandomSign(),RandomInt(0,200) * GetRandomSign()) + GetPlayer().GetOrigin())
			
			local zombie = RandomInt(1,3)
			local sound = 0
			if(zombie == 1){
				zombie = "Jockey"
				sound = RandomInt(1,4)
			} else if(zombie == 2){
				zombie = "Hunter"
				sound = RandomInt(1,5)
			} else if(zombie == 3) {
				zombie = "Smoker"
				sound = RandomInt(1,5)
			}
			
			switch(sound){
				case 1:{
					sound = "Growl"
					break
				}
				case 2:{
					sound = "Alert"
					break
				}
				case 3:{
					sound = "Warn"
					break
				}
				case 4:{
					sound = "Recognize"
					break
				}
				case 5:{
					if(zombie == "Hunter"){
						sound = "Pounce"
					} else if(zombie == "Smoker"){
						sound = "TongueAttack"
					}
					break
				}
				default:
				{
					zombie = "Boomer"
					sound = "Detonate"
					break
				}
			}
			
			EmitSoundOn(zombie + "Zombie." + sound, soundTarget)
			lastSpecialSound = Time()
		}
	}
	
	function PlaySurvivorSound(){
		if(Time() >= lastSurvivorSound + (RandomInt(20,40) / pow(GetPlayerCount(), 0.25)) && Director.HasAnySurvivorLeftSafeArea()){
			soundTarget.SetOrigin(Vector(RandomInt(550,1000) * GetRandomSign(), RandomInt(550,1000) * GetRandomSign(), RandomInt(0,300) * GetRandomSign()) + GetPlayer().GetOrigin())
			if(RandomInt(0,100) <= 65){
				local character = GetCharacterDisplayName(GetPlayer())
				local survivor = RandomInt(0,2)
				
				local l4d1Survivors = ["Bill", "Louis", "Francis", "Zoey"]
				local l4d2Survivors = ["Nick", "Rochelle", "Ellis", "Coach"]
				
				local sound = null
				
				if(character == "Nick" || character == "Rochelle" || character == "Ellis" || character == "Coach"){
					l4d2Survivors.remove(l4d2Survivors.find(character))
					survivor = l4d2Survivors[survivor]
					local survivorSoundsArray = survivorSounds[survivor.tolower()]
					sound = survivorSoundsArray[RandomInt(0, survivorSoundsArray.len() - 1)]
				}
				if(character == "Bill" || character == "Louis" || character == "Francis" || character == "Zoey"){
					l4d1Survivors.remove(l4d1Survivors.find(character))
					survivor = l4d1Survivors[survivor]
					local survivorSoundsArray = survivorSounds[survivor.tolower()]
					sound = survivorSoundsArray[RandomInt(0, survivorSoundsArray.len() - 1)]
				}
				printl("Playing survivor sound: " + sound)
				EmitSoundOn(sound, soundTarget)
			}
			lastSurvivorSound = Time()
		}
	}
	
	function PlayWeatherSound(){
		if(Time() >= lastWeatherSound + RandomInt(25,40)){
			if(RandomInt(0,100) <= 50){
				EmitSoundOn(weatherSounds[RandomInt(0,weatherSounds.len()-1)], GetPlayer())
			}
			lastWeatherSound = Time()
		}
	}
	
	function PlayAmbientSound(){
		if(Time() >= RandomInt(20,30) + lastAmbientSound){
			lastAmbientSound = Time()
			if(RandomInt(0,100) <= 50){
				SendToServerConsole("play " + ambientSounds[RandomInt(0,ambientSounds.len()-1)])
			}
		}
	}
}

class FakeSpecialManager {
	lastFakeSpecial = 0
	
	function DoFakeSpecialSpawn(){
		if(Time() >= lastFakeSpecial + (RandomInt(20,30) / pow(GetPlayerCount(), 0.5)) && Director.HasAnySurvivorLeftSafeArea() && !(NetProps.GetPropInt(GetPlayer(),"m_fFlags") & 32)){
			lastFakeSpecial = Time()
			if(RandomInt(0,100) <= 75){
				local type = (RandomInt(1,3) * 2) - 1 // expands to either 1, 3, or 5
				
				local specialsBefore = []
				local specialsAfter = []
				
				local ent = null
				while(ent = Entities.FindByClassname(ent,"player")){
					if(ent.IsValid() && !ent.IsSurvivor()){
						specialsBefore.append(ent)
					}
				}
				
				ZSpawn({type = type})
				
				ent = null
				while(ent = Entities.FindByClassname(ent,"player")){
					if(ent.IsValid() && !ent.IsSurvivor()){
						specialsAfter.append(ent)
					}
				}
				
				for(local i=0; i < specialsAfter.len(); i+=1){
					for(local j=0; j < specialsBefore.len(); j+=1){
						if(specialsAfter[i] == specialsBefore[j]){
							specialsAfter.remove(i)
							specialsBefore.remove(j)
							if(i > 0){
								i -= 1
							}
							break
						}
					}
				}
				
				foreach(special in specialsAfter){
					special.ValidateScriptScope()
					special.GetScriptScope()["fakeSpecial"] <- true
				}
			}
		}
	}
}

local controller = {}
IncludeScript("HookController",controller)
controller.RegisterOnTick(this)

DirectorOptions <- {
	BoomerLimit = 0
	CommonLimit = 5
	ChargerLimit = 0
	SpitterLimit = 0
	
	DominatorLimit = 1
	HunterLimit = 1
	JockeyLimit = 1
	SmokerLimit = 1
	WitchLimit = 1
	TankLimit = 0
	MaxSpecials = 1
	
	SpecialInitialSpawnDelayMin = 10
	SpecialInitialSpawnDelayMax = 15
	SpecialRespawnInterval = 30
	
	FarAcquireRange = 400
	NearAcquireRange = 100
	NearAcquireTime = 0.75
	
	SurvivorMaxIncapacitatedCount = 2
	
	PreferredSpecialDirection = SPAWN_SPECIALS_IN_FRONT_OF_SURVIVORS
	
	ProhibitBosses = false
	ZombieSpawnInFog = true
	cm_NoSurvivorBots = true
	cm_AutoReviveFromSpecialIncap = true
}

::soundTarget <- null

local fakeSpecialManager = FakeSpecialManager()
local soundManager = SoundManager()

function GetClosestSurvivorDistance(vector){
	local closestDistance = 99999
	
	local player = null
	while(player = Entities.FindByClassname(player, "player")){
		if(player.IsSurvivor() && (player.GetOrigin() - vector).Length() < closestDistance){
			closestDistance = (player.GetOrigin() - vector).Length()
		}
	}
	
	return closestDistance
}

function DoFlowCheck(){
	if(Director.HasAnySurvivorLeftSafeArea()){
		local flow = Director.GetAveragedSurvivorSpeed()
		if(400 - flow >= 150){
			if(400 - flow > Convars.GetFloat("fog_end")){
				Convars.SetValue("fog_end", Convars.GetFloat("fog_end") + 1)
			} else if(400 - flow < Convars.GetFloat("fog_end")) {
				Convars.SetValue("fog_end", Convars.GetFloat("fog_end") - 1)
			}
		}
	}
}

function DoCommonCulling(){
	local common = null
	while(common = Entities.FindByClassname(common, "infected")){
		if(GetClosestSurvivorDistance(common.GetOrigin()) > 1000){
			common.Kill()
		}
	}
}

function SetDirectorOptions(){
	DirectorOptions.CommonLimit = 5
	DirectorOptions.JockeyLimit = 1
	DirectorOptions.SmokerLimit = 1
	DirectorOptions.HunterLimit = 1
	DirectorOptions.DominatorLimit = 1
	DirectorOptions.MaxSpecials = 1
	DirectorOptions.WitchLimit = 1
	DirectorOptions.TankLimit = 0
	DirectorOptions.ChargerLimit = 0
	DirectorOptions.SpecialRespawnInterval = 30 / pow(GetPlayerCount(), 0.5)
	DirectorOptions.FarAcquireRange = Convars.GetFloat("fog_end")
}

function OnGameplayStart(){
	controller.Start()
	soundTarget = SpawnEntityFromTable("info_target",{})
	
	Convars.SetValue("z_tank_health", Convars.GetFloat("z_tank_health")/(4 - GetPlayerCount()))
	
	if(SessionState.MapName.find("c7m1_") != null){
		local button = Entities.FindByName(null,"tankdoorin_button")
		button.ValidateScriptScope()
		button.GetScriptScope()["func"] <- function(){
			EntFire("tankdoorout_button","Unlock")
		}
		button.ConnectOutput("OnTimeUp", "func")
	}
}

function AllowTakeDamage(params){
	local attacker = params.Attacker
	local victim = params.Victim
	attacker.ValidateScriptScope()
	victim.ValidateScriptScope()
	if("fakeSpecial" in victim.GetScriptScope() && attacker != null && victim.IsValid() && attacker.IsValid() && victim.GetClassname() == "player" && attacker.GetClassname() == "player" && attacker.IsSurvivor()){
		victim.Kill()
		return false
	} else if("fakeSpecial" in attacker.GetScriptScope() && victim != null && attacker.IsValid() && victim.IsValid() && attacker.GetClassname() == "player" && victim.GetClassname() == "player" && victim.IsSurvivor()){
		attacker.Kill()
		return false
	}
	return true
}

function OnTick(){
	Convars.SetValue("fog_enable",1)
	Convars.SetValue("music_manager",0)

	SetDirectorOptions()

	DoFlowCheck()
	DoCommonCulling()
	fakeSpecialManager.DoFakeSpecialSpawn()
	
	soundManager.PlaySounds()
}

function OnGameEvent_tongue_grab(params){
	local ent = GetPlayerFromUserID(params.userid)
	local victim = GetPlayerFromUserID(params.victim)
	ent.ValidateScriptScope()
	if("fakeSpecial" in ent.GetScriptScope()){
		ent.Kill()
		StopSoundOn("Event.SmokerChoke", victim)
		StopSoundOn("Event.SmokerDrag", victim)
	}
}

function OnGameEvent_lunge_pounce(params){
	local ent = GetPlayerFromUserID(params.userid)
	local victim = GetPlayerFromUserID(params.victim)
	ent.ValidateScriptScope()
	if("fakeSpecial" in ent.GetScriptScope()){
		ent.Kill()
		StopSoundOn("Event.HunterPounce",victim)
	}
}

function OnGameEvent_charger_carry_start(params)    {
	local ent = GetPlayerFromUserID(params.userid)
	local victim = GetPlayerFromUserID(params.victim)
	ent.ValidateScriptScope()
	if("fakeSpecial" in ent.GetScriptScope()){
		ent.Kill()
		StopSoundOn("Event.ChargerSlam",victim)
	}
}*/