-- Main config file of GW2Minion

wt_global_information = {}
wt_global_information.Currentprofession = nil
wt_global_information.Now = 0
wt_global_information.PVP = false
wt_global_information.MainWindow = { Name = "GW2Minion", x=100, y=100 , width=170, height=150 }
wt_global_information.BtnStart = { Name="StartStop" ,Event = "GUI_REQUEST_RUN_TOGGLE" }
wt_global_information.BtnPulse = { Name="Pulse" ,Event = "Debug.Pulse" }
wt_global_information.AttackEnemiesLevelMaxRangeAbovePlayerLevel = 3  
wt_global_information.CurrentMarkerList = nil
wt_global_information.SelectedMarker = nil
wt_global_information.AttackRange = 1200
wt_global_information.MaxLootDistance = 1200
wt_global_information.lastrun = 0
wt_global_information.InventoryFull = 0
wt_global_information.CurrentVendor = 0
gw2minion = { }

if (Settings.GW2MINION.version == nil ) then
	-- Init Settings for Version 1
	Settings.GW2MINION.version = 1.0
	Settings.GW2MINION.gEnableLog = "0"
end

if (Settings.GW2MINION.version == 1.0 ) then
	Settings.GW2MINION.version = 1.1
	Settings.GW2MINION.gGW2MinionPulseTime = "150"
end

function wt_global_information.OnUpdate( event, tickcount )
	wt_global_information.Now = tickcount

	gGW2MiniondeltaT = tostring(tickcount - wt_global_information.lastrun)
	if (tickcount - wt_global_information.lastrun > tonumber(gGW2MinionPulseTime)) then
		wt_global_information.lastrun = tickcount	
		wt_core_controller.Run()
		--GUI_RefreshWindow(wt_global_information.MainWindow.Name)
	end	
	
end

-- Module Event Handler
function gw2minion.HandleInit()
	wt_debug("received Module.Initalize")	
	GUI_NewWindow(wt_global_information.MainWindow.Name,wt_global_information.MainWindow.x,wt_global_information.MainWindow.y,wt_global_information.MainWindow.width,wt_global_information.MainWindow.height)
	GUI_NewButton(wt_global_information.MainWindow.Name, wt_global_information.BtnStart.Name , wt_global_information.BtnStart.Event)
	GUI_NewButton(wt_global_information.MainWindow.Name, wt_global_information.BtnPulse.Name , wt_global_information.BtnPulse.Event)
	GUI_NewField(wt_global_information.MainWindow.Name,"Pulse Time (ms)","gGW2MinionPulseTime");
	GUI_NewCheckbox(wt_global_information.MainWindow.Name,"Enable Log","gEnableLog");
	GUI_NewField(wt_global_information.MainWindow.Name,"State","gGW2MinionState");
	GUI_NewField(wt_global_information.MainWindow.Name,"Effect","gGW2MinionEffect");
	GUI_NewField(wt_global_information.MainWindow.Name,"dT","gGW2MiniondeltaT");
	
	gEnableLog = Settings.GW2MINION.gEnableLog
	gGW2MinionPulseTime = Settings.GW2MINION.gGW2MinionPulseTime 
	wt_debug("GUI Setup done")
	wt_core_controller.requestStateChange(wt_core_state_idle)
end

function gw2minion.GUIVarUpdate(Event,NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if ( k == "gEnableLog" or k == "gGW2MinionPulseTime" ) then
			Settings.GW2MINION[tostring(k)] = v
		end
	end
end

function wt_global_information.Reset()
	wt_core_controller.requestStateChange(wt_core_state_idle)
	wt_global_information.CurrentMarkerList = nil
	wt_global_information.SelectedMarker = nil
	wt_global_information.AttackRange = 1200
	wt_global_information.MaxLootDistance = 1200
	wt_global_information.lastrun = 0
	wt_global_information.InventoryFull = 0
	wt_global_information.CurrentVendor = 0
	wt_core_state_idle.selectedMarkerIndex = 0
	wt_core_state_vendoring.junksold = false 
	wt_core_state_combat.CurrentTarget = 0
	c_check_aggro.TargetList = {}
	wt_core_state_idle.selectedMarkerList = { }
	c_check_aggro.TargetList = {}
	-- ???
end



-- Register Event Handlers
RegisterEventHandler("Module.Initalize",gw2minion.HandleInit)
RegisterEventHandler("Gameloop.Update",wt_global_information.OnUpdate)
RegisterEventHandler("GUI.Update",gw2minion.GUIVarUpdate)
