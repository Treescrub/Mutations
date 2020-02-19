local controller = {}
IncludeScript("HookController",controller)
controller.RegisterHooks(this)

DirectorOptions <- {
	CommonLimit = 50
	MobMaxSize = 50
}

function OnGameplayStart(){
	controller.Start()
}

function OnTick(){
	local player = null
	while(player = Entities.FindByClassname(player,"player")){
		if(player.IsValid() && !player.IsSurvivor() && !player.IsDead()){
			DoEntFire("!self","Addoutput","rendermode 6",0,null,player)
		}
	}
	
	local witch = null
	while(witch = Entities.FindByClassname(witch,"witch")){
		if(witch.IsValid()){
			DoEntFire("!self","Addoutput","renderfx 15",0,null,witch)
		}
	}
}