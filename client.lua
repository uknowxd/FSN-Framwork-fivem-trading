function buyStock(stock, amount)
    amount = tonumber(amount)
    if(amount > 0 and amount)then
        TriggerServerEvent("nextz_trading:buyStock", stock, amount)
    end
end

function sellStock(stock, amount)
    amount = tonumber(amount)
    if(amount > 0 and amount)then
        TriggerServerEvent("nextz_trading:sellStock", stock, amount)
    end
end

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })    
end)

RegisterNUICallback('buy', function(data, cb)
    buyStock(data.stock, data.amount)
end)

RegisterNUICallback('sell', function(data, cb)
    sellStock(data.stock, data.amount)
end)

function enableMenu()
    TriggerServerEvent("nextz_trading:updateStocks")

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open'
    })
end

RegisterNetEvent("nextz_trading:updateStocks")
AddEventHandler("nextz_trading:updateStocks", function(stocks)
    SendNUIMessage({
        type = 'update',
        stocks = json.encode(stocks)
    })
end)

RegisterNetEvent("nextz_trading:setClientToUpdate")
AddEventHandler("nextz_trading:setClientToUpdate", function()
    TriggerServerEvent("nextz_trading:updateStocks")
end)

function disableMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
end

RegisterCommand('updatestocks', function(source, args)
    TriggerServerEvent("nextz_trading:updateStocks")
end, false)

RegisterCommand('exchange', function(source, args)
    enableMenu()
end, false)

RegisterCommand('closestocks', function(source, args)
    disableMenu()
end, false)

RegisterCommand('bstock', function(source, args)
    buyStock(args[1], args[2])
end, false)

RegisterCommand('sstock', function(source, args)
    sellStock(args[1], args[2])
end, false)
