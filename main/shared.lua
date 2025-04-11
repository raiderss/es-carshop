Config = {}

Config.Framework = "QBCore"
Config.Discord = "" -- https://discord.com/developers/applications
Config.TestDrivePrice = 250 

function randomNumber(length)
    local result = ""
    for i = 1, length do
        result = result .. math.random(0,9)
    end
    return result
end

function randomCharacter(length)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local result = ""
    for i = 1, length do
        local rand = math.random(1, #charset)
        result = result .. string.sub(charset, rand, rand)
    end
    return result
end

Config.Vehicles = {
    ['categories'] = {
        {
            name = "Zentorno",
            model = "zentorno",
            brand = "Pegassi",
            price = 2350000,
            category = "super",
            stock = 10,
            specs = {
                speed = 345,
                acceleration = 2.8,
                handling = 9.2,
                fuelCapacity = 80
            }
        },
        {
            name = "T20",
            model = "t20",
            brand = "Progen",
            price = 2200000,
            category = "super",
            stock = 5,
            specs = {
                speed = 338,
                acceleration = 2.7,
                handling = 8.8,
                fuelCapacity = 75
            }
        },
        {
            name = "Sultan RS",
            model = "sultanrs",
            brand = "Karin",
            price = 850000,
            category = "sports",
            stock = 15,
            specs = {
                speed = 305,
                acceleration = 3.2,
                handling = 7.9,
                fuelCapacity = 65
            }
        },
        {
            name = "Elegy RH8",
            model = "elegy",
            brand = "Annis",
            price = 750000,
            category = "sports",
            stock = 20,
            specs = {
                speed = 295,
                acceleration = 3.4,
                handling = 8.5,
                fuelCapacity = 60
            }
        },
        {
            name = "Dominator",
            model = "dominator",
            brand = "Vapid",
            price = 450000,
            category = "muscle",
            stock = 25,
            specs = {
                speed = 280,
                acceleration = 3.8,
                handling = 6.8,
                fuelCapacity = 90
            }
        },
        {
            name = "Turismo R",
            model = "turismor",
            brand = "Grotti",
            price = 1950000,
            category = "super",
            stock = 8,
            specs = {
                speed = 335,
                acceleration = 2.9,
                handling = 9.0,
                fuelCapacity = 78
            }
        },
        {
            name = "Adder",
            model = "adder",
            brand = "Truffade",
            price = 2100000,
            category = "super",
            stock = 3,
            specs = {
                speed = 340,
                acceleration = 3.0,
                handling = 8.5,
                fuelCapacity = 85
            }
        },
        {
            name = "Comet SR",
            model = "comet5",
            brand = "Pfister",
            price = 950000,
            category = "sports",
            stock = 12,
            specs = {
                speed = 315,
                acceleration = 3.1,
                handling = 8.8,
                fuelCapacity = 70
            }
        },
        {
            name = "Banshee 900R",
            model = "banshee2",
            brand = "Bravado",
            price = 1100000,
            category = "sports",
            stock = 10,
            specs = {
                speed = 320,
                acceleration = 3.0,
                handling = 8.0,
                fuelCapacity = 72
            }
        },
        {
            name = "Gauntlet Hellfire",
            model = "gauntlet4",
            brand = "Bravado",
            price = 875000,
            category = "muscle",
            stock = 18,
            specs = {
                speed = 310,
                acceleration = 3.4,
                handling = 7.0,
                fuelCapacity = 88
            }
        },
        {
            name = "Drafter",
            model = "drafter",
            brand = "Obey",
            price = 780000,
            category = "sports",
            stock = 15,
            specs = {
                speed = 300,
                acceleration = 3.3,
                handling = 8.2,
                fuelCapacity = 68
            }
        },
        {
            name = "XA-21",
            model = "xa21",
            brand = "Ocelot",
            price = 1850000,
            category = "super",
            stock = 8,
            specs = {
                speed = 330,
                acceleration = 2.8,
                handling = 9.1,
                fuelCapacity = 75
            }
        },
        {
            name = "Itali GTO",
            model = "italigto",
            brand = "Grotti",
            price = 1650000,
            category = "sports",
            stock = 10,
            specs = {
                speed = 325,
                acceleration = 3.0,
                handling = 8.9,
                fuelCapacity = 72
            }
        },
        {
            name = "Bison",
            model = "bison",
            brand = "Bravado",
            price = 350000,
            category = "offroad",
            stock = 25,
            specs = {
                speed = 270,
                acceleration = 4.0,
                handling = 6.5,
                fuelCapacity = 95
            }
        },
        {
            name = "Dubsta",
            model = "dubsta",
            brand = "Benefactor",
            price = 450000,
            category = "suv",
            stock = 20,
            specs = {
                speed = 275,
                acceleration = 3.9,
                handling = 6.8,
                fuelCapacity = 100
            }
        },
        {
            name = "Hakuchou",
            model = "hakuchou",
            brand = "Shitzu",
            price = 380000,
            category = "motorcycle",
            stock = 15,
            specs = {
                speed = 330,
                acceleration = 2.5,
                handling = 7.5,
                fuelCapacity = 40
            }
        },
        {
            name = "Tempesta",
            model = "tempesta",
            brand = "Pegassi",
            price = 1800000,
            category = "super",
            stock = 7,
            specs = {
                speed = 330,
                acceleration = 2.9,
                handling = 9.3,
                fuelCapacity = 76
            }
        },
        {
            name = "Tornado",
            model = "tornado",
            brand = "Declasse",
            price = 280000,
            category = "sportsclassic",
            stock = 15,
            specs = {
                speed = 240,
                acceleration = 4.8,
                handling = 5.5,
                fuelCapacity = 70
            }
        },
        {
            name = "Osiris",
            model = "osiris",
            brand = "Pegassi",
            price = 1800000,
            category = "super",
            stock = 6,
            specs = {
                speed = 335,
                acceleration = 2.8,
                handling = 9.0,
                fuelCapacity = 77
            }
        },
        {
            name = "GT500",
            model = "gt500",
            brand = "Grotti",
            price = 900000,
            category = "sportsclassic",
            stock = 10,
            specs = {
                speed = 290,
                acceleration = 3.6,
                handling = 7.8,
                fuelCapacity = 65
            }
        }
    },
    ['types'] = {
        { id = 1, value = "all", label = "ALL VEHICLES" },
        { id = 2, value = "hypercar", label = "HYPERCAR" },
        { id = 3, value = "super", label = "SUPER" },
        { id = 4, value = "sports", label = "SPORTS" },
        { id = 5, value = "tuner", label = "TUNER" },
        { id = 6, value = "jdm", label = "JDM" },
        { id = 7, value = "drift", label = "DRIFT" },
        { id = 8, value = "rally", label = "RALLY" },
        { id = 9, value = "race", label = "RACE" },
        { id = 10, value = "luxury", label = "LUXURY" },
        { id = 11, value = "luxurysuv", label = "LUXURY SUV" },
        { id = 12, value = "suv", label = "SUV" },
        { id = 13, value = "muscle", label = "MUSCLE" },
        { id = 14, value = "classicsport", label = "CLASSIC SPORT" },
        { id = 15, value = "sportsclassic", label = "CLASSIC" },
        { id = 16, value = "electric", label = "ELECTRIC" },
        { id = 17, value = "concept", label = "CONCEPT" },
        { id = 18, value = "limited", label = "LIMITED" },
        { id = 19, value = "vintage", label = "VINTAGE" },
        { id = 20, value = "offroad", label = "OFFROAD" },
        { id = 21, value = "motorcycle", label = "MOTORCYCLE" },
        { id = 22, value = "compact", label = "COMPACT" }
    },
    ['colors'] = {
        { name = "Black", hex = "#0F0F0F" },
        { name = "White", hex = "#FFFFFF" },
        { name = "Red", hex = "#C00E1A" },
        { name = "Blue", hex = "#0E3FC0" },
        { name = "Green", hex = "#0EC044" },
        { name = "Yellow", hex = "#C0BD0E" },
        { name = "Orange", hex = "#C0680E" },
        { name = "Purple", hex = "#6E0EC0" },
        { name = "Pink", hex = "#C00E97" },
        { name = "Gray", hex = "#5A5A5A" }
    }
}

CustomizeCamera = function(self)
    isOpen = not self
    DisplayHud(isOpen)
    DisplayRadar(isOpen)
end

Config.GetVehFuel = function(Veh)
    return GetVehicleFuelLevel(Veh)
end

Config.Carkeys = function(Plate, vehicle)
    if Config.Framework == "QBCore" then
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', Plate)
        TriggerEvent('vehiclekeys:client:SetOwner', Plate)
        TriggerServerEvent('qb-vehiclekeys:server:SetVehicleOwner', Plate)
        SetVehicleEngineOn(vehicle, true, true, false)
    else
        TriggerEvent('vehiclekeys:client:SetOwner', Plate)
        SetVehicleEngineOn(vehicle, true, true, false)
    end
end

CustomizePlate = function()
    return string.upper(randomNumber(2) .. randomCharacter(3) .. randomNumber(3))
end

Config.Locations = {
    { 
        type = 'car',
        coords = vector3(-34.53, -1102.94, 25.42),
        hash = "a_m_o_soucent_01", 
        heading = 170.00, 
        marker = "VEHICLE SHOWROOM",
        interactionText = "~w~[E] Purchase Vehicle",
        blip = {
            ["active"] = true,
            ["name"] = "Car Dealership",
            ["colour"] = 4,
            ["id"] = 56
        },  
        NuiCarViewSpawnPosition = vector4(-47.777, -1097.021, 22.422, 0.0),
        NuiCarViewCameraPosition = {
            posX = -45.777,
            posY = -1102.021 + 10, 
            posZ = 25.422 + 2,
            rotX = -20.0, 
            rotY = 0,
            rotZ = 160.0, 
            fov = 60.00 
        },
        TestDriveTime = 60,
        TestDriveSpawnPosition = vector4(-874.34, -3226.6, 13.22, 60.82),
        BuyCarSpawnPositions = {
            [1] = vector4(-10.6716, -1096.76, 26.183, 100.5),
            [2] = vector4(-11.4883, -1099.59, 26.180, 100.5),
            [3] = vector4(-12.4124, -1102.35, 26.183, 100.5),
            [4] = vector4(-13.0040, -1105.23, 26.179, 100.5),
            [5] = vector4(-14.5665, -1108.37, 26.183, 100.5)
        },
    }, 
}

EYES = {
    Functions = {
        CreateBlips = function()
            for k,v in pairs(Config.Locations) do
                if v.blip["active"] then
                    local blip = AddBlipForCoord(v.coords)
                    SetBlipSprite(blip, v.blip["id"])
                    SetBlipScale(blip, 0.5)
                    SetBlipAsShortRange(blip, true)
                    SetBlipColour(blip, v.blip["colour"])
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(v.blip["name"])
                    EndTextCommandSetBlipName(blip)
                end
            end
        end
    }
}


function GetFramework()
    local Get = nil
    if Config.Framework == "ESX" then
        while Get == nil do
            TriggerEvent('esx:getSharedObject', function(Set) Get = Set end)
            Citizen.Wait(0)
        end
    elseif Config.Framework == "NewESX" then
        Get = exports['es_extended']:getSharedObject()
    elseif Config.Framework == "QBCore" then
        Get = exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == "OldQBCore" then
        while Get == nil do
            TriggerEvent('QBCore:GetObject', function(Set) Get = Set end)
            Citizen.Wait(200)
        end
    end
    return Get
end