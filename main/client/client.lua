Framework = nil
Framework = GetFramework()


local displayUI = false
local npcPeds = {}
local veh = nil
local shopLocation = nil
local spawnPos = nil
local testTime = nil
local testCoords = nil
local displayVehicle = nil
local resourceStarted = false
local testDriveConfig = nil 

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    Citizen.CreateThread(function()
        Citizen.Wait(200)
        resourceStarted = true
        testDriveConfig = {
            spawnPosition = Config.TestDriveSpawnPosition,
            duration = Config.TestDriveTime or 60
        }
        print("Resource started, test drive config initialized")
    end)
end)

RegisterNetEvent('playerSpawned')
AddEventHandler('playerSpawned', function()
    Citizen.Wait(1000)
    resourceStarted = true
    testDriveConfig = {
        spawnPosition = Config.TestDriveSpawnPosition,
        duration = Config.TestDriveTime or 60
    }
    print("Player spawned, resource initialized")
end)

if Config.Framework == "QBCore" then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        Citizen.Wait(1000)
        resourceStarted = true
        testDriveConfig = {
            spawnPosition = Config.TestDriveSpawnPosition,
            duration = Config.TestDriveTime or 60
        }
        print("QBCore player loaded, resource initialized")
    end)
end

if Config.Framework == "ESX" then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function()
        Citizen.Wait(1000)
        resourceStarted = true
        testDriveConfig = {
            spawnPosition = Config.TestDriveSpawnPosition,
            duration = Config.TestDriveTime or 60
        }
        print("ESX player loaded, resource initialized")
    end)
end

function DrawText3D(x, y, z, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font or 4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function SpawnViewCar(model, pos)
    local attempts = 0
    local maxAttempts = 5
    
    if displayVehicle ~= nil then
        DeleteEntity(displayVehicle)
        displayVehicle = nil
        Citizen.Wait(100) 
    end

    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if not IsPedInVehicle(PlayerPedId(), vehicle, false) and vehicle ~= displayVehicle then
            if DoesEntityExist(vehicle) and GetEntityModel(vehicle) ~= GetHashKey("caracara2") then
                DeleteEntity(vehicle)
            end
        end
    end

    while attempts < maxAttempts do
        attempts = attempts + 1
        
        local modelHash = GetHashKey(model)
        if not IsModelValid(modelHash) then
            print("Invalid vehicle model: " .. model)
            modelHash = GetHashKey("zentorno")
            model = "zentorno"
            Citizen.Wait(50)
        end
        
        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash)
            local timeoutCounter = 0
            while not HasModelLoaded(modelHash) do
                timeoutCounter = timeoutCounter + 1
                Citizen.Wait(50)
                if timeoutCounter > 100 then 
                    break
                end
            end
        end

        if HasModelLoaded(modelHash) then
            displayVehicle = CreateVehicle(modelHash, pos.x, pos.y, pos.z, pos.w, false, false)
            
            if DoesEntityExist(displayVehicle) then
                SetEntityAlpha(displayVehicle, 255, false)
                SetVehicleOnGroundProperly(displayVehicle)
                SetVehicleDirtLevel(displayVehicle, 0.0)
                SetVehicleEngineOn(displayVehicle, false, false, false)
                SetVehicleUndriveable(displayVehicle, true)
                FreezeEntityPosition(displayVehicle, true)
                SetEntityHeading(displayVehicle, pos.w)
                
                SetModelAsNoLongerNeeded(modelHash)
                return displayVehicle
            else
                print("Failed to create vehicle, retrying... Attempt: " .. attempts)
                SetModelAsNoLongerNeeded(modelHash)
                Citizen.Wait(100)
            end
        else
            print("Failed to load model, retrying... Attempt: " .. attempts)
            SetModelAsNoLongerNeeded(modelHash)
            Citizen.Wait(100)
        end
    end

    print("Vehicle loading failed, using default model")
    local defaultModel = "zentorno"
    local defaultHash = GetHashKey(defaultModel)
    
    RequestModel(defaultHash)
    while not HasModelLoaded(defaultHash) do
        Citizen.Wait(10)
    end
    
    displayVehicle = CreateVehicle(defaultHash, pos.x, pos.y, pos.z, pos.w, false, false)
    
    if DoesEntityExist(displayVehicle) then
        SetEntityAlpha(displayVehicle, 255, false)
        SetVehicleOnGroundProperly(displayVehicle)
        SetVehicleDirtLevel(displayVehicle, 0.0)
        SetVehicleEngineOn(displayVehicle, false, false, false)
        SetVehicleUndriveable(displayVehicle, true)
        FreezeEntityPosition(displayVehicle, true)
        SetEntityHeading(displayVehicle, pos.w)
        SetModelAsNoLongerNeeded(defaultHash)
    end
    
    SendNUIMessage({
        action = "NOTIFICATION",
        title = "Warning",
        message = "Failed to load selected vehicle model, using default model instead.",
        type = "error"
    })
    
    return displayVehicle
end


function OpenNui(location)
    if not resourceStarted then
        return
    end

    SetNuiFocus(true, true)
    displayUI = true
    if GetResourceState('es_cybrhud') == 'started' then 
        exports['es_cybrhud']:getui(false)
    end

    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if not IsPedInVehicle(PlayerPedId(), vehicle, false) and vehicle ~= displayVehicle then
            if DoesEntityExist(vehicle) and GetEntityModel(vehicle) ~= GetHashKey("caracara2") then
                DeleteEntity(vehicle)
            end
        end
    end

    local camPos = location.NuiCarViewCameraPosition
    local carPos = location.NuiCarViewSpawnPosition
    if CarCam then
        DestroyCam(CarCam, true)
    end
    CarCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(CarCam, camPos.posX, camPos.posY, camPos.posZ)
    SetCamRot(CarCam, camPos.rotX, camPos.rotY, camPos.rotZ, 2)
    SetCamFov(CarCam, camPos.fov)
    RenderScriptCams(true, true, 1000, true, true)

    SendNUIMessage({
        action = 'CARSHOP',
        open = true,
        vehicles = Config.Vehicles['categories'],
        types = Config.Vehicles['types'],
        colors = Config.Vehicles['colors'],
        testDrivePrice = Config.TestDrivePrice
    })

    Citizen.Wait(200)
    if Config.Vehicles['categories'] and #Config.Vehicles['categories'] > 0 then
        local firstCar = Config.Vehicles['categories'][1]
        if firstCar and firstCar.model then
            if displayVehicle ~= nil and DoesEntityExist(displayVehicle) then
                DeleteEntity(displayVehicle)
                displayVehicle = nil
                Citizen.Wait(100)
            end
            displayVehicle = SpawnViewCar(firstCar.model, carPos)
        end
    end

    UpdateMoneyHUD()
    CustomizeCamera(true)
end

function UpdateMoneyHUD()
    if Config.Framework == "QBCore" then
        Framework.Functions.TriggerCallback('es-carshop:getMoney', function(cash, bank, dirty)
            SendNUIMessage({
                action = "UPDATE-HUD",
                cash = cash,
                bank = bank,
                dirtycash = dirty
            })
        end)
    else
        Framework.TriggerServerCallback('es-carshop:getMoney', function(cash, bank, dirty)
            SendNUIMessage({
                action = "UPDATE-HUD",
                cash = cash,
                bank = bank,
                dirtycash = dirty
            })
        end)
    end
end

RegisterNUICallback("action", function(data, cb)
    if data.action == "close" then

        if GetResourceState('es_cybrhud') == 'started' then 
            exports['es_cybrhud']:getui(true)
        end

        SetNuiFocus(false, false)
        displayUI = false
        CustomizeCamera(false)
        
        if DoesEntityExist(testVehicle) then
            DeleteEntity(testVehicle)
            testVehicle = nil
        end
        
        if DoesEntityExist(displayVehicle) then
            DeleteEntity(displayVehicle)
            displayVehicle = nil
        end
        
        if CarCam then
            RenderScriptCams(false, true, 1000, true, true)
            DestroyCam(CarCam, true)
            CarCam = nil
        end
    elseif data.action == "view-car" then
        if not data.model then
            SendNUIMessage({
                action = "NOTIFICATION",
                title = "Error",
                message = "Invalid vehicle model.",
                type = "error"
            })
            cb("error")
            return
        end

        if DoesEntityExist(displayVehicle) then
            DeleteEntity(displayVehicle)
            displayVehicle = nil
            Citizen.Wait(100) 
        end
        
        if spawnPos then
            displayVehicle = SpawnViewCar(data.model, spawnPos)
            if not displayVehicle or not DoesEntityExist(displayVehicle) then
                SendNUIMessage({
                    action = "NOTIFICATION",
                    title = "Error",
                    message = "Could not display vehicle. Please select another vehicle.",
                    type = "error"
                })
                cb("error")
                return
            end

            local primaryColor = data.primaryColor
            if primaryColor == nil or primaryColor == "" then
                primaryColor = "#FFFFFF"
            end
            
            local secondaryColor = data.secondaryColor
            if secondaryColor == nil or secondaryColor == "" then
                secondaryColor = "#FFFFFF"
            end
            
            if primaryColor then
                local r, g, b = hexToRgb(primaryColor)
                SetVehicleCustomPrimaryColour(displayVehicle, r, g, b)
            end
            
            if secondaryColor then
                local r, g, b = hexToRgb(secondaryColor)
                SetVehicleCustomSecondaryColour(displayVehicle, r, g, b)
            end
        else
            SendNUIMessage({
                action = "NOTIFICATION",
                title = "Error",
                message = "Vehicle spawn position not found.",
                type = "error"
            })
            cb("error")
            return
        end
        elseif data.action == "test-drive" then
        local model = data.model
        local primaryColor = data.primaryColor
        local secondaryColor = data.secondaryColor
        local paymentMethod = data.paymentMethod
        local deposit = data.deposit
        local lastPlayerCoords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('es-carshop:removeMoney', deposit, paymentMethod)
        Citizen.CreateThread(function()
            local testDriveVehicle = nil
            local testDriveTime = 60
            RequestModel(GetHashKey(model))
            while not HasModelLoaded(GetHashKey(model)) do
                Citizen.Wait(10)
            end
            if Config.TestDriveLocation then
                SetEntityCoords(PlayerPedId(), Config.TestDriveLocation.x, Config.TestDriveLocation.y, Config.TestDriveLocation.z)
                SetEntityHeading(PlayerPedId(), Config.TestDriveLocation.w)
                testDriveVehicle = CreateVehicle(GetHashKey(model), Config.TestDriveLocation.x, Config.TestDriveLocation.y, Config.TestDriveLocation.z, Config.TestDriveLocation.w, true, false)
                if DoesEntityExist(testDriveVehicle) then
                    SetVehicleOnGroundProperly(testDriveVehicle)
                    SetEntityAsMissionEntity(testDriveVehicle, true, true)
                    SetVehicleHasBeenOwnedByPlayer(testDriveVehicle, true)
                    SetVehicleNeedsToBeHotwired(testDriveVehicle, false)
                    SetVehicleDirtLevel(testDriveVehicle, 0.0)
                    SetVehicleEngineOn(testDriveVehicle, true, true, false)
                    if primaryColor then
                        local r, g, b = hexToRgb(primaryColor)
                        SetVehicleCustomPrimaryColour(testDriveVehicle, r, g, b)
                    end
                    if secondaryColor then
                        local r, g, b = hexToRgb(secondaryColor)
                        SetVehicleCustomSecondaryColour(testDriveVehicle, r, g, b)
                    end
                    TaskWarpPedIntoVehicle(PlayerPedId(), testDriveVehicle, -1)
                    local startTime = GetGameTimer()
                    local endTime = startTime + (testDriveTime * 1000)
                    Citizen.CreateThread(function()
                        while GetGameTimer() < endTime do
                            Citizen.Wait(1000)
                            local timeLeft = math.ceil((endTime - GetGameTimer()) / 1000)
                            
                            -- Show remaining time on the screen
                            if DoesEntityExist(testDriveVehicle) then
                                local vehCoords = GetEntityCoords(testDriveVehicle)
                                DrawText3D(
                                    vehCoords.x, 
                                    vehCoords.y, 
                                    vehCoords.z + 1.0, 
                                    string.format("~b~TEST DRIVE~w~\n%d seconds remaining", timeLeft),
                                    0.6,
                                    4
                                )
                            end
                        end
                        if DoesEntityExist(testDriveVehicle) then
                            DeleteEntity(testDriveVehicle)
                        end
                        SetEntityCoords(PlayerPedId(), lastPlayerCoords.x, lastPlayerCoords.y, lastPlayerCoords.z)
                        TriggerServerEvent('es-carshop:returnDeposit', deposit, paymentMethod)
                        TriggerEvent('es-carshop:notify', 'TEST DRIVE ENDED', 'The test drive time has expired and the deposit has been returned.', 'info')
                    end)
                else
                    TriggerEvent('es-carshop:notify', 'ERROR', 'The test vehicle could not be created!', 'error')
                    TriggerServerEvent('es-carshop:returnDeposit', deposit, paymentMethod)
                end
            end
        end)
    end
    
    cb("ok")
end)

RegisterNUICallback("rotateright", function(data, cb)
    if DoesEntityExist(displayVehicle) then
        local currentHeading = GetEntityHeading(displayVehicle)
        SetEntityHeading(displayVehicle, currentHeading - 2.0) 
    end
    cb("ok")
end)

RegisterNUICallback("rotateleft", function(data, cb)
    if DoesEntityExist(displayVehicle) then
        local currentHeading = GetEntityHeading(displayVehicle)
        SetEntityHeading(displayVehicle, currentHeading + 2.0) 
    end
    cb("ok")
end)

RegisterNUICallback("update-car-color", function(data, cb)
    if not DoesEntityExist(displayVehicle) then
        cb("error: vehicle does not exist")
        return
    end
    
    local primaryColor = data.primaryColor
    if primaryColor == nil or primaryColor == "" then
        primaryColor = "#FFFFFF"
    end
    
    local secondaryColor = data.secondaryColor
    if secondaryColor == nil or secondaryColor == "" then
        secondaryColor = "#FFFFFF"
    end
    
    if primaryColor then
        local r, g, b = hexToRgb(primaryColor)
        SetVehicleCustomPrimaryColour(displayVehicle, r, g, b)
    end
    
    if secondaryColor then
        local r, g, b = hexToRgb(secondaryColor)
        SetVehicleCustomSecondaryColour(displayVehicle, r, g, b)
    end
    
    cb("ok")
end)

function hexToRgb(hex)
    if hex == nil or hex == "" then
        hex = "#FFFFFF" 
    end
    
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

function DrawText2D(text, x, y, scale)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

Citizen.CreateThread(function()
   while true do
     Citizen.Wait(0)
     local ped = PlayerPedId()
     local coords = GetEntityCoords(ped)

     if not displayUI then
       for k,v in pairs(Config.Locations) do
         local dist = #(coords - v.coords)
         if dist < 10 then
           if dist < 3 then
             local x,y,z = table.unpack(v.coords)
             
             if not DoesEntityExist(npcPeds[k]) then
               local hash = GetHashKey(v.hash)
               RequestModel(hash)
               while not HasModelLoaded(hash) do Wait(10) end
               
               npcPeds[k] = CreatePed(4, hash, x, y, z, v.heading, false, true)
               SetEntityInvincible(npcPeds[k], true)
               SetBlockingOfNonTemporaryEvents(npcPeds[k], true)
               FreezeEntityPosition(npcPeds[k], true)
               
               local dict = "mini@strip_club@idles@bouncer@base"
               RequestAnimDict(dict)
               while not HasAnimDictLoaded(dict) do Wait(10) end
               TaskPlayAnim(npcPeds[k], dict, "base", 8.0, -8.0, -1, 1, 0, false, false, false)
             end
 
             SetEntityHeading(npcPeds[k], GetHeadingFromVector_2d(coords.x - x, coords.y - y))

             DrawText3D(x, y, z + 2.15, "~b~PREMIUM DELUXE MOTORSPORT", 0.8, 4)

             DrawText3D(x, y, z + 1.95, "Press ~y~[E]~w~ to browse vehicles", 0.6, 4)
             
             if IsControlJustPressed(0,38) then
                veh = v.BuyCarSpawnPositions
                shopLocation = v.coords
                spawnPos = v.NuiCarViewSpawnPosition
                testTime = v.TestDriveTime
                testCoords = v.TestDriveSpawnPosition
                OpenNui(v)
             end
           else
             if DoesEntityExist(npcPeds[k]) then DeleteEntity(npcPeds[k]) npcPeds[k] = nil end
           end
         end
       end
     end
   end
end)
 
Citizen.CreateThread(function()
    Citizen.Wait(1000) 
    EYES.Functions.CreateBlips()
end)

RegisterNUICallback("TestDrive", function(data, cb)
    if not data.model then 
        print("No model specified")
        return 
    end

    if not testCoords then
        print("Test drive location not found")
        TriggerEvent('es-carshop:notify', 'ERROR', 'Test drive location not found!', 'error')
        return
    end

    local lastPlayerCoords = GetEntityCoords(PlayerPedId())
    local model = data.model
    local primaryColor = data.primaryColor or "#FFFFFF"
    local secondaryColor = data.secondaryColor or "#FFFFFF"
    local paymentMethod = data.paymentMethod
    local deposit = data.deposit

    TriggerServerEvent('es-carshop:removeMoney', deposit, paymentMethod)

    Citizen.CreateThread(function()
        SetEntityCoords(PlayerPedId(), 
            testCoords.x, 
            testCoords.y, 
            testCoords.z)
        
        SetEntityHeading(PlayerPedId(), testCoords.w)
        
        Citizen.Wait(500)

        local hash = GetHashKey(model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Citizen.Wait(10)
        end

        local testDriveVehicle = CreateVehicle(hash, 
            testCoords.x, testCoords.y, testCoords.z, 
            testCoords.w, 
            true, false)
        
        if DoesEntityExist(testDriveVehicle) then
            SetEntityAsMissionEntity(testDriveVehicle, true, true)
            SetVehicleOnGroundProperly(testDriveVehicle)
            SetVehicleHasBeenOwnedByPlayer(testDriveVehicle, true)
            SetVehicleNeedsToBeHotwired(testDriveVehicle, false)
            SetVehicleDirtLevel(testDriveVehicle, 0.0)
            SetVehicleEngineOn(testDriveVehicle, true, true, false)
            SetVehicleNumberPlateText(testDriveVehicle, "TEST")
            local r, g, b = hexToRgb(primaryColor)
            SetVehicleCustomPrimaryColour(testDriveVehicle, r, g, b)
            r, g, b = hexToRgb(secondaryColor)
            SetVehicleCustomSecondaryColour(testDriveVehicle, r, g, b)
            TaskWarpPedIntoVehicle(PlayerPedId(), testDriveVehicle, -1)
            local plate = GetVehicleNumberPlateText(testDriveVehicle)
            if Config.Carkeys then
                Config.Carkeys(plate)
            end
            SetNuiFocus(false, false)
            displayUI = false
            local testDriveTime = testTime or 60
            local startTime = GetGameTimer()
            local endTime = startTime + (testDriveTime * 1000)
            TriggerEvent('es-carshop:notify', 'TEST DRIVE STARTED', 'You have ' .. testDriveTime .. ' seconds', 'success')
            local isTestDriveActive = true
            Citizen.CreateThread(function()
                while isTestDriveActive and GetGameTimer() < endTime do
                    Citizen.Wait(0)
                    local timeLeft = math.ceil((endTime - GetGameTimer()) / 1000)
                    if DoesEntityExist(testDriveVehicle) then
                        local vehCoords = GetEntityCoords(testDriveVehicle)
                        DrawText3D(
                            vehCoords.x, 
                            vehCoords.y, 
                            vehCoords.z + 1.0, 
                            string.format("~b~TEST DRIVE~w~\n%d seconds remaining", timeLeft),
                            0.6,
                            4
                        )
                    else
                        isTestDriveActive = false
                        break
                    end
                end

                isTestDriveActive = false
                if DoesEntityExist(testDriveVehicle) then
                    TaskLeaveVehicle(PlayerPedId(), testDriveVehicle, 0)
                    Citizen.Wait(2000) 
                    DeleteEntity(testDriveVehicle)
                end
                SetEntityCoords(PlayerPedId(), lastPlayerCoords.x, lastPlayerCoords.y, lastPlayerCoords.z)
                TriggerServerEvent('es-carshop:returnDeposit', deposit, paymentMethod)
                TriggerEvent('es-carshop:notify', 'TEST DRIVE COMPLETED', 'Test drive ended and deposit returned', 'info')
            end)

            Citizen.CreateThread(function()
                while isTestDriveActive do
                    Citizen.Wait(1000)
                    if not IsPedInVehicle(PlayerPedId(), testDriveVehicle, false) then
                        isTestDriveActive = false
                        if DoesEntityExist(testDriveVehicle) then
                            DeleteEntity(testDriveVehicle)
                        end
                        SetEntityCoords(PlayerPedId(), lastPlayerCoords.x, lastPlayerCoords.y, lastPlayerCoords.z)
                        TriggerServerEvent('es-carshop:returnDeposit', deposit, paymentMethod)
                        TriggerEvent('es-carshop:notify', 'TEST DRIVE ENDED', 'You left the vehicle, test drive cancelled', 'info')
                        break
                    end
                end
            end)
        else
            print("Failed to create test vehicle")
            TriggerEvent('es-carshop:notify', 'ERROR', 'Failed to create test vehicle!', 'error')
            TriggerServerEvent('es-carshop:returnDeposit', deposit, paymentMethod)
            SetEntityCoords(PlayerPedId(), lastPlayerCoords.x, lastPlayerCoords.y, lastPlayerCoords.z)
        end

        SetModelAsNoLongerNeeded(hash)
    end)
    
    cb("ok")
end)

RegisterNUICallback("test-drive", nil)

RegisterNUICallback("purchase-car", function(data, cb)
    if not data.model then
        TriggerEvent('es-carshop:notify', 'ERROR', 'Invalid vehicle model!', 'error')
        return
    end

    local props = {}
    if displayVehicle and DoesEntityExist(displayVehicle) then
        if Config.Framework == "QBCore" then
            props = Framework.Functions.GetVehicleProperties(displayVehicle)
        else
            props = Framework.Game.GetVehicleProperties(displayVehicle)
        end
    end

    local vehicleData = {
        model = data.model,
        name = data.name,
        price = data.price,
        props = props,
        paymentMethod = data.paymentMethod
    }

    TriggerServerEvent('es-carshop:purchaseVehicle', vehicleData)

    SetNuiFocus(false, false)
    displayUI = false

    cb("ok")
end)


RegisterNetEvent('es-carshop:finalizePurchase')
AddEventHandler('es-carshop:finalizePurchase', function(success, vehicleProps)
    if success then
        local currentLocation = nil
        for _, loc in pairs(Config.Locations) do
            if #(GetEntityCoords(PlayerPedId()) - loc.coords) < 50.0 then
                currentLocation = loc
                break
            end
        end

        if not currentLocation or not currentLocation.BuyCarSpawnPositions then
            TriggerEvent('es-carshop:notify', 'ERROR', 'No valid spawn positions found!', 'error')
            return
        end

        local spawnPositions = {}
        for _, pos in pairs(currentLocation.BuyCarSpawnPositions) do
            table.insert(spawnPositions, pos)
        end

        local randomIndex = math.random(1, #spawnPositions)
        local spawnPos = spawnPositions[randomIndex]

        if displayVehicle and DoesEntityExist(displayVehicle) then
            DeleteEntity(displayVehicle)
            displayVehicle = nil
        end

        SetNuiFocus(false, false)
        displayUI = false

        local model = vehicleProps.model
        if not model then
            model = GetHashKey(data.model)
        end

        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(10)
        end

        local vehicle = CreateVehicle(model, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w, true, false)

        if Config.Framework == "QBCore" then
            Framework.Functions.SetVehicleProperties(vehicle, vehicleProps)
        else
            Framework.Game.SetVehicleProperties(vehicle, vehicleProps)
        end

        SetVehicleOnGroundProperly(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleEngineOn(vehicle, true, true, false)

        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

        local plate = GetVehicleNumberPlateText(vehicle)
        if Config.Carkeys then
            Config.Carkeys(plate)
        end

        SetModelAsNoLongerNeeded(model)

        if CarCam then
            RenderScriptCams(false, true, 1000, true, true)
            DestroyCam(CarCam, true)
            CarCam = nil
        end

        TriggerEvent('es-carshop:notify', 'SUCCESS', 'Your vehicle has been delivered to the parking spot!', 'success')
    end
end)