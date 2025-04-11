local MySQL = nil

if Config.Framework == "QBCore" or Config.Framework == "OLDQBCore" then
    MySQL = exports['oxmysql']
else
    MySQL = exports['mysql-async']
end

Framework = nil
Framework = GetFramework()
Citizen.Await(Framework)

if Config.Framework == "QBCore" or Config.Framework == "OLDQBCore" then
    Framework.Functions.CreateCallback("es-carshop:getMoney", function(source, cb)
        local Player = Framework.Functions.GetPlayer(source)
        if Player then
            local cash = Player.PlayerData.money.cash
            local bank = Player.PlayerData.money.bank
            local dirty = Player.PlayerData.money.crypto or 0
            cb(cash, bank, dirty)
        else
            cb(0, 0, 0)
        end
    end)

    RegisterServerEvent('es-carshop:removeMoney')
    AddEventHandler('es-carshop:removeMoney', function(amount, type)
        local src = source
        local Player = Framework.Functions.GetPlayer(src)
        
        if Player then
            if type == "cash" then
                if Player.PlayerData.money.cash >= amount then
                    Player.Functions.RemoveMoney("cash", amount, "test-drive-deposit")
                    TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Test drive deposit paid: $' .. amount, 'success')
                    return true
                else
                    TriggerClientEvent('es-carshop:notify', src, 'INSUFFICIENT FUNDS', 'You do not have enough cash!', 'error')
                    return false
                end
            elseif type == "bank" then
                if Player.PlayerData.money.bank >= amount then
                    Player.Functions.RemoveMoney("bank", amount, "test-drive-deposit")
                    TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Test drive deposit paid: $' .. amount, 'success')
                    return true
                else
                    TriggerClientEvent('es-carshop:notify', src, 'INSUFFICIENT FUNDS', 'You do not have enough money in your bank account!', 'error')
                    return false
                end
            end
        end
    end)
else
    Framework.RegisterServerCallback("es-carshop:getMoney", function(source, cb)
        local xPlayer = Framework.GetPlayerFromId(source)
        if xPlayer then
            local cash = xPlayer.getMoney()
            local bank = xPlayer.getAccount('bank').money
            local dirty = xPlayer.getAccount('black_money').money
            cb(cash, bank, dirty)
        else
            cb(0, 0, 0)
        end
    end)

    RegisterServerEvent('es-carshop:removeMoney')
    AddEventHandler('es-carshop:removeMoney', function(amount, type)
        local src = source
        local xPlayer = Framework.GetPlayerFromId(src)
        
        if xPlayer then
            if type == "cash" then
                if xPlayer.getMoney() >= amount then
                    xPlayer.removeMoney(amount)
                    TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Test drive deposit paid: $' .. amount, 'success')
                    return true
                else
                    TriggerClientEvent('es-carshop:notify', src, 'INSUFFICIENT FUNDS', 'You do not have enough cash!', 'error')
                    return false
                end
            elseif type == "bank" then
                if xPlayer.getAccount('bank').money >= amount then
                    xPlayer.removeAccountMoney('bank', amount)
                    TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Test drive deposit paid: $' .. amount, 'success')
                    return true
                else
                    TriggerClientEvent('es-carshop:notify', src, 'INSUFFICIENT FUNDS', 'You do not have enough money in your bank account!', 'error')
                    return false
                end
            end
        end
    end)
end

RegisterServerEvent('es-carshop:returnDeposit')
AddEventHandler('es-carshop:returnDeposit', function(amount, type)
    local src = source
    
    if Config.Framework == "QBCore" then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney(type, amount, "test-drive-deposit-return")
            TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Test drive deposit returned: $' .. amount, 'success')
        end
    else
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            if type == "cash" then
                xPlayer.addMoney(amount)
            elseif type == "bank" then
                xPlayer.addAccountMoney('bank', amount)
            end
            TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Test drive deposit returned: $' .. amount, 'success')
        end
    end
end)

RegisterServerEvent('es-carshop:purchaseVehicle')
AddEventHandler('es-carshop:purchaseVehicle', function(vehicleData)
    print(json.encode(vehicleData))
    local src = source
    local price = vehicleData.price
    local model = vehicleData.model
    local props = vehicleData.props
    local paymentMethod = vehicleData.paymentMethod

    if Config.Framework == "QBCore" then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            if paymentMethod == "cash" and Player.PlayerData.money.cash >= price then
                Player.Functions.RemoveMoney("cash", price, "vehicle-purchase")
                local plate = GeneratePlate()
                props.plate = plate
                if GetResourceState('oxmysql') == 'started' then
                    exports.oxmysql:insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                        Player.PlayerData.license,
                        Player.PlayerData.citizenid,
                        model,
                        GetHashKey(model),
                        json.encode(props),
                        plate,
                        0
                    }, function(id)
                        if id and id > 0 then
                            TriggerClientEvent('es-carshop:finalizePurchase', src, true, props)
                            TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Vehicle purchased and registered successfully!', 'success')
                        else
                            Player.Functions.AddMoney("cash", price, "vehicle-purchase-failed")
                            TriggerClientEvent('es-carshop:notify', src, 'ERROR', 'Failed to register vehicle!', 'error')
                        end
                    end)
                end

            elseif paymentMethod == "bank" and Player.PlayerData.money.bank >= price then
                Player.Functions.RemoveMoney("bank", price, "vehicle-purchase")
                local plate = GeneratePlate()
                props.plate = plate
                if GetResourceState('oxmysql') == 'started' then
                    exports.oxmysql:insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                        Player.PlayerData.license,
                        Player.PlayerData.citizenid,
                        model,
                        GetHashKey(model),
                        json.encode(props),
                        plate,
                        0
                    }, function(id)
                        if id and id > 0 then
                            TriggerClientEvent('es-carshop:finalizePurchase', src, true, props)
                            TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Vehicle purchased and registered successfully!', 'success')
                        else
                            Player.Functions.AddMoney("bank", price, "vehicle-purchase-failed")
                            TriggerClientEvent('es-carshop:notify', src, 'ERROR', 'Failed to register vehicle!', 'error')
                        end
                    end)
                end
            else
                TriggerClientEvent('es-carshop:finalizePurchase', src, false)
                TriggerClientEvent('es-carshop:notify', src, 'INSUFFICIENT FUNDS', 'You cannot afford this vehicle!', 'error')
            end
        end
    else 
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            if paymentMethod == "cash" and xPlayer.getMoney() >= price then
                xPlayer.removeMoney(price)
                local plate = GeneratePlate()
                props.plate = plate
                if GetResourceState('oxmysql') == 'started' then
                    exports.oxmysql:insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)', {
                        xPlayer.identifier,
                        plate,
                        json.encode(props),
                        'car',
                        1
                    }, function(id)
                        if id and id > 0 then
                            TriggerClientEvent('es-carshop:finalizePurchase', src, true, props)
                            TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Vehicle purchased and registered successfully!', 'success')
                        else
                            xPlayer.addMoney(price)
                            TriggerClientEvent('es-carshop:notify', src, 'ERROR', 'Failed to register vehicle!', 'error')
                        end
                    end)
                end

            elseif paymentMethod == "bank" and xPlayer.getAccount('bank').money >= price then
                xPlayer.removeAccountMoney('bank', price)
                local plate = GeneratePlate()
                props.plate = plate
                if GetResourceState('oxmysql') == 'started' then
                    exports.oxmysql:insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)', {
                        xPlayer.identifier,
                        plate,
                        json.encode(props),
                        'car',
                        1
                    }, function(id)
                        if id and id > 0 then
                            TriggerClientEvent('es-carshop:finalizePurchase', src, true, props)
                            TriggerClientEvent('es-carshop:notify', src, 'SUCCESS', 'Vehicle purchased and registered successfully!', 'success')
                        else
                            xPlayer.addAccountMoney('bank', price)
                            TriggerClientEvent('es-carshop:notify', src, 'ERROR', 'Failed to register vehicle!', 'error')
                        end
                    end)
                end
            else
                TriggerClientEvent('es-carshop:finalizePurchase', src, false)
                TriggerClientEvent('es-carshop:notify', src, 'INSUFFICIENT FUNDS', 'You cannot afford this vehicle!', 'error')
            end
        end
    end
end)

function GeneratePlate()
    local plate = ""
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for i = 1, 8 do
        local rand = math.random(1, #charset)
        plate = plate .. string.sub(charset, rand, rand)
    end
    return plate
end