
curGarage = nil
vehicle = nil
rgb = {}
spawnedVehs = {}

curVehName = ""

--- CallBacks 
ServerCallbacks = {}
CurrentRequestId = 0

function TriggerServerCallback(name,cb,...)
    ServerCallbacks[CurrentRequestId] = cb
    TriggerServerEvent(GetCurrentResourceName()..'triggerServerCallback',name,CurrentRequestId,...)
    if CurrentRequestId < 65535 then
        CurrentRequestId = CurrentRequestId + 1
    else
        CurrentRequestId = 0
    end
end

RegisterNetEvent(GetCurrentResourceName()..'serverCallback')
AddEventHandler(GetCurrentResourceName()..'serverCallback', function(requestId,...)
    ServerCallbacks[requestId](...)
    ServerCallbacks[requestId] = nil
end)

 
Citizen.CreateThread(function()
    for k,va in pairs(Config.Vehicles) do 
        for i,v in pairs(Config.Vehicles[k]) do
          if k == "super" then 
            v.fuel = math.random(80, 100)
            v.consumption = 3
            v.trunk = Config.TrunkCapacity
         elseif k == "vans" then 
            v.fuel = math.random(80, 100)
            v.consumption = 2
            v.trunk = Config.TrunkVanCapacity
         else 
            v.fuel = math.random(80, 100)
            v.consumption = 1
            v.trunk = Config.TrunkCapacity
         end
        end
    end
	
	for i,v in pairs(Config.Shops) do 
	   blip = AddBlipForCoord(v.coord.x, v.coord.y, v.coord.z)
       SetBlipSprite(blip, 225)
       SetBlipDisplay(blip, 4)
       SetBlipScale(blip, 0.7)
       SetBlipColour(blip, 0)
       SetBlipAsShortRange(blip, true)
       BeginTextCommandSetBlipName("STRING")
       AddTextComponentString(v.name)
       EndTextCommandSetBlipName(blip)
	end
 
end)
 
Citizen.CreateThread(function() 
     while 1 > 0 do 
      sleepThread = 2000
      plyCoords = GetEntityCoords(PlayerPedId())
        auth = false

      for k,v in pairs(Config.Shops) do
         if GetDistanceBetweenCoords(plyCoords, v.coord)  <= v.dist then 
            sleepThread = 0

               DrawText3D(v.coord.x , v.coord.y  , v.coord.z, '[E] - '..v.name)
               auth = true

            if auth == true and IsControlJustPressed(1, 38) and GetDistanceBetweenCoords(plyCoords, v.coord) <= 1.5 then 
               initGarage(k)
               Wait(1500)
            end
         end
      end
      Citizen.Wait(sleepThread)
     end
end)

cam = nil
function initGarage(x)
   curGarage = Config.Shops[x]
   SetEntityVisible(PlayerPedId(), 0)
   cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 0)
   SetCamCoord(cam, curGarage.camCoord)
   SetCamRot(cam, curGarage.camRot, 2)
   SetCamActive(cam, true)
   RenderScriptCams(true, true, 1)
   SendNUIMessage({ action = "load", garage = curGarage })
   SetNuiFocus(1, 1)
   DisplayRadar(0)
end

function destroyCam()
    if DoesCamExist(cam) then
        DestroyCam(cam, true)
        RenderScriptCams(false, true, 1)
        cam = nil
    end
end

RegisterNUICallback("close", function(data, cb)
    --SetPedCoordsKeepVehicle(PlayerPedId(), curGarage.coord)
	SetEntityCoords(PlayerPedId(), curGarage.coord)
	DisplayRadar(1)
    SetNuiFocus(0, 0)
    destroyCam()
    SetEntityVisible(PlayerPedId(), 1)
    deleteLastCar() 
end)


RegisterNUICallback("testdrive", function(data, cb)
    SetNuiFocus(0, 0)
	SetEntityVisible(PlayerPedId(), 1)
    destroyCam()
    startTestDrive()
end)

isTestDriving = false
function startTestDrive(dealer_object)
    if isTestDriving then
        return
    end
    if vehicle and DoesEntityExist(vehicle) then
        FreezeEntityPosition(vehicle,false)
        SetVehicleUndriveable(vehicle,false)
		SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
        SetPedCoordsKeepVehicle(PlayerPedId(), Config.TestDrive.coords)
		SendNUIMessage({ action = "startTest" })
    end
    local finished = nil
    CreateThread(function()
        local start = GetGameTimer()/1000
        while GetGameTimer()/1000 - start < Config.TestDrive.seconds and DoesEntityExist(vehicle) and not IsEntityDead(PlayerPedId()) do
            if #(GetEntityCoords(PlayerPedId()) - Config.TestDrive.coords) > Config.TestDrive.range then
                SetPedCoordsKeepVehicle(PlayerPedId(), Config.TestDrive.coords)
            end
            if GetVehiclePedIsIn(PlayerPedId(), false) == 0 and DoesEntityExist(vehicle) then
                SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
            end
            Wait(1000)
        end
        SetPedCoordsKeepVehicle(PlayerPedId(), curGarage.carSpawnCoord)
        FreezeEntityPosition(vehicle, true)
        SetVehicleUndriveable(vehicle, true)
        ClearPedTasksImmediately(PlayerPedId())
        SetEntityCoords(PlayerPedId(), curGarage.coord)
        finished = true
		SendNUIMessage({ action = "stopTest" })
		deleteLastCar() 

    end)
    while finished == nil or not finished do
        Wait(0)
    end
    return
end



RegisterNUICallback("moveright", function(data)
	moveCarRight(2)
end)

RegisterNUICallback("moveleft", function(data)
	moveCarLeft(2)
end)


RegisterNUICallback("buy", function(data, cb)
    local PlayerPed = PlayerPedId()
    
    local veh = getVehicleFromName(curVehName)
    
	TriggerServerCallback("vrp_vehshop:checkPrice", function(pg)  
        if pg == true then 
            Citizen.CreateThread(function() 
                RequestModel(GetHashKey(veh.name))
                while not HasModelLoaded(GetHashKey(veh.name)) do
                   Wait(1000)
                end
                local xVehicle = CreateVehicle(veh.name, curGarage.deliveryCoord, true, false)
                SetVehicleNumberPlateText(xVehicle, GetVehicleNumberPlateText(vehicle))
                 SetVehicleCustomPrimaryColour(xVehicle, tonumber(rgb.r), tonumber(rgb.g), tonumber(rgb.b))
                 SetVehicleCustomSecondaryColour(xVehicle, tonumber(rgb.r), tonumber(rgb.g), tonumber(rgb.b))
                SetPedIntoVehicle(PlayerPed, xVehicle, -1)
                Wait(500)
                TriggerServerEvent('vrp_vehshop:server:givecar', GetVehicleProperties(xVehicle))
                rgb = {}
				DisplayRadar(1)
                SetNuiFocus(0, 0)
                destroyCam()
                SetEntityVisible(PlayerPed, 1)
                deleteLastCar() 
           end)
           Wait(500)
           cb(pg) 
        else 
           cb(false)
        end 
    end, { price = veh.price })
end)

function getVehicleFromName(x)
   for k,va in pairs(curGarage.Vehicles) do 
      for i,v in pairs(curGarage.Vehicles[k]) do
         if v.name == x then 
            return v
         end
      end
   end
end
 
RegisterNUICallback("checkPlatePrice", function(data, cb)
    plate = data.plate 
	TriggerServerCallback("vrp_vehshop:checkPlatePrice", function(pg)  cb(pg) if pg == true then SetVehicleNumberPlateText(vehicle, plate) end end, plate)
end)

function moveCarRight(value)
    if vehicle and DoesEntityExist(vehicle) then
        SetEntityRotation(vehicle, GetEntityRotation(vehicle) + vector3(0,0,value), false, false, 2, false)
    end
end

function moveCarLeft(value)
    if vehicle and DoesEntityExist(vehicle) then
        SetEntityRotation(vehicle, GetEntityRotation(vehicle) - vector3(0,0,value), false, false, 2, false)
    end
end
 
RegisterNUICallback("setcolour", function(data)
	if DoesEntityExist(vehicle) then
        rgb = data.rgb
		SetVehicleCustomPrimaryColour(vehicle, tonumber(data.rgb.r), tonumber(data.rgb.g), tonumber(data.rgb.b))
	end
end)
 
RegisterNUICallback("showCar", function(data, cb) showCar(data.name) end)
 
function deleteLastCar() 
    for i,v in pairs(spawnedVehs) do
       if DoesEntityExist(v) then
          DeleteEntity(v)
       end
       table.remove(spawnedVehs, i)
    end
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        vehicle = nil
    end
end
 
function showCar(modelName)
    local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))
    
	Citizen.CreateThread(function()
 
        deleteLastCar() 

		local modelHash = model
        modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

        if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
            RequestModel(modelHash)
    
            while not HasModelLoaded(modelHash) do
                Citizen.Wait(1)
            end
        end

        
		vehicle = CreateVehicle(model, curGarage.carSpawnCoord, false, false)
        curVehName = modelName
		SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
        table.insert(spawnedVehs, vehicle)
		local timeout = 0

		SetEntityAsMissionEntity(vehicle, true, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetVehRadioStation(vehicle, 'OFF')
		SetModelAsNoLongerNeeded(model)
		RequestCollisionAtCoord(curGarage.carSpawnCoord.x, curGarage.carSpawnCoord.y, curGarage.carSpawnCoord.z)

		while not HasCollisionLoadedAroundEntity(vehicle) and timeout < 2000 do
			Citizen.Wait(0)
			timeout = timeout + 1
		end

		if cb then
			cb(vehicle)
		end
	end)
end


 


 

function DrawText3D(x, y, z, text)
	SetTextScale(0.30, 0.30)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 250
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end





function GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        local extras = {}

        for extraId = 0, 12 do
            if DoesExtraExist(vehicle, extraId) then
                local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
                extras[tostring(extraId)] = state
            end
        end

        if GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) ~= -1 then
            modLivery = GetVehicleLivery(vehicle)
        else
            modLivery = GetVehicleMod(vehicle, 48)
        end

        return {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
            bodyHealth = GetVehicleBodyHealth(vehicle),
            engineHealth = GetVehicleEngineHealth(vehicle),
            tankHealth = GetVehiclePetrolTankHealth(vehicle),
            fuelLevel = GetVehicleFuelLevel(vehicle),
            dirtLevel = GetVehicleDirtLevel(vehicle),
            color1 = colorPrimary,
            color2 = colorSecondary,
            pearlescentColor = pearlescentColor,
            interiorColor = GetVehicleInteriorColor(vehicle),
            dashboardColor = GetVehicleDashboardColour(vehicle),
            wheelColor = wheelColor,
            wheels = GetVehicleWheelType(vehicle),
            windowTint = GetVehicleWindowTint(vehicle),
            xenonColor = GetVehicleXenonLightsColour(vehicle),
            neonEnabled = {
                IsVehicleNeonLightEnabled(vehicle, 0),
                IsVehicleNeonLightEnabled(vehicle, 1),
                IsVehicleNeonLightEnabled(vehicle, 2),
                IsVehicleNeonLightEnabled(vehicle, 3)
            },
            neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
            extras = extras,
            tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),
            modSpoilers = GetVehicleMod(vehicle, 0),
            modFrontBumper = GetVehicleMod(vehicle, 1),
            modRearBumper = GetVehicleMod(vehicle, 2),
            modSideSkirt = GetVehicleMod(vehicle, 3),
            modExhaust = GetVehicleMod(vehicle, 4),
            modFrame = GetVehicleMod(vehicle, 5),
            modGrille = GetVehicleMod(vehicle, 6),
            modHood = GetVehicleMod(vehicle, 7),
            modFender = GetVehicleMod(vehicle, 8),
            modRightFender = GetVehicleMod(vehicle, 9),
            modRoof = GetVehicleMod(vehicle, 10),
            modEngine = GetVehicleMod(vehicle, 11),
            modBrakes = GetVehicleMod(vehicle, 12),
            modTransmission = GetVehicleMod(vehicle, 13),
            modHorns = GetVehicleMod(vehicle, 14),
            modSuspension = GetVehicleMod(vehicle, 15),
            modArmor = GetVehicleMod(vehicle, 16),
            modTurbo = IsToggleModOn(vehicle, 18),
            modSmokeEnabled = IsToggleModOn(vehicle, 20),
            modXenon = IsToggleModOn(vehicle, 22),
            modFrontWheels = GetVehicleMod(vehicle, 23),
            modBackWheels = GetVehicleMod(vehicle, 24),
            modCustomTiresF = GetVehicleModVariation(vehicle, 23),
            modCustomTiresR = GetVehicleModVariation(vehicle, 24),
            modPlateHolder = GetVehicleMod(vehicle, 25),
            modVanityPlate = GetVehicleMod(vehicle, 26),
            modTrimA = GetVehicleMod(vehicle, 27),
            modOrnaments = GetVehicleMod(vehicle, 28),
            modDashboard = GetVehicleMod(vehicle, 29),
            modDial = GetVehicleMod(vehicle, 30),
            modDoorSpeaker = GetVehicleMod(vehicle, 31),
            modSeats = GetVehicleMod(vehicle, 32),
            modSteeringWheel = GetVehicleMod(vehicle, 33),
            modShifterLeavers = GetVehicleMod(vehicle, 34),
            modAPlate = GetVehicleMod(vehicle, 35),
            modSpeakers = GetVehicleMod(vehicle, 36),
            modTrunk = GetVehicleMod(vehicle, 37),
            modHydrolic = GetVehicleMod(vehicle, 38),
            modEngineBlock = GetVehicleMod(vehicle, 39),
            modAirFilter = GetVehicleMod(vehicle, 40),
            modStruts = GetVehicleMod(vehicle, 41),
            modArchCover = GetVehicleMod(vehicle, 42),
            modAerials = GetVehicleMod(vehicle, 43),
            modTrimB = GetVehicleMod(vehicle, 44),
            modTank = GetVehicleMod(vehicle, 45),
            modWindows = GetVehicleMod(vehicle, 46),
            modLivery = modLivery,
        }
    else
        return
    end
end
