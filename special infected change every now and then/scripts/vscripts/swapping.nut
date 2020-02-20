DirectorOptions <- {
	DominatorLimit = 10
	MaxSpecials = 4
}

local last_change = Time()
local last_special = 0

function Update(){
	if(Time() >= last_change + 60){
		local random = RandomInt(1,6)
		while(random == last_special){
			random = RandomInt(1,6)
		}
		DirectorOptions["SmokerLimit"] <- 0
		DirectorOptions["BoomerLimit"] <- 0
		DirectorOptions["HunterLimit"] <- 0
		DirectorOptions["SpitterLimit"] <- 0
		DirectorOptions["JockeyLimit"] <- 0
		DirectorOptions["ChargerLimit"] <- 0
		switch(random){
			case 1:{
				DirectorOptions["SmokerLimit"] <- 10
				break
			}
			case 2:{
				DirectorOptions["BoomerLimit"] <- 10
				break
			}
			case 3:{
				DirectorOptions["HunterLimit"] <- 10
				break
			}
			case 4:{
				DirectorOptions["SpitterLimit"] <- 10
				break
			}
			case 5:{
				DirectorOptions["JockeyLimit"] <- 10
				break
			}
			case 6:{
				DirectorOptions["ChargerLimit"] <- 10
				break
			}
		}
		last_change = Time()
		last_special = random
	}
}