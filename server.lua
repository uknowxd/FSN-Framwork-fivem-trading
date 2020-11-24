local ready = false

stocks = {}

local config = {
    pricingTimer = GetConvarInt("nextz_trading_pricingTimer", 30000),
    minRandom = GetConvarInt("nextz_trading_minRandom", 2),
    maxRandom = GetConvarInt("nextz_trading_maxRandom", 20),
    divider = GetConvarInt("nextz_trading_divider", 10),
    lowestBasePercent = GetConvarInt("nextz_trading_lowestBasePercent", 70),
    highestBacePercent = GetConvarInt("nextz_trading_highestBasePercent", 200),
    addDefault = GetConvarInt("nextz_trading_addDefault", 1),
    maxStocks = GetConvarInt("nextz_trading_maxStocks", 99999999),
}

local userStockCache = {}

function shallowCopy(target, source)
    for k,v in pairs(source) do
        target[k] = v
    end
end

-- Randomize pricing based on baseWorth
Citizen.CreateThread(function()
    while true do
        math.randomseed(os.time())
     
        for i=1,#stocks do
            if(stocks[i].worth == 0)then
                stocks[i].worth = math.ceil(stocks[i].baseWorth * (math.random(config.minRandom, config.maxRandom) / config.divider))
            else
                stocks[i].worth = math.ceil(stocks[i].worth * (math.random(config.minRandom, config.maxRandom) / config.divider))
                if(stocks[i].worth < ((stocks[i].baseWorth / 100) * config.lowestBasePercent))then
                    stocks[i].worth = math.ceil((stocks[i].baseWorth / 100) * config.lowestBasePercent)
                end

                if(stocks[i].worth > ((stocks[i].baseWorth / 100) * config.highestBacePercent))then
                    stocks[i].worth = math.ceil((stocks[i].baseWorth / 100) * config.highestBacePercent)
                end
            end
        end

        TriggerClientEvent("nextz_trading:setClientToUpdate", -1)
        Citizen.Wait(config.pricingTimer)
    end
end)

AddEventHandler("nextz_trading:addStock", function(abr, name, baseWorth)
    table.insert(stocks, {abr = abr, name = name, worth = 0, baseWorth = baseWorth})
end)


if(config.addDefault)then
    TriggerEvent("nextz_trading:addStock", "FSN", "FSN-FRAMWORK", 1500)
    TriggerEvent("nextz_trading:addStock", "NZN", "NEXTZ-NETWORK", 1300)
    TriggerEvent("nextz_trading:addStock", "NP", "NextZ-Project", 1400)
end

RegisterServerEvent("nextz_trading:updateStocks")
AddEventHandler("nextz_trading:updateStocks", function()
    local _source = source
    local user = exports.fsn_main:fsn_CharID(_source)
    local steamid = GetPlayerIdentifiers(source)
    steamid = steamid[1]

    if(user)then
        userStockCache[steamid] = {}

        shallowCopy(userStockCache[steamid], stocks)

        for i=1,#userStockCache[steamid] do
        userStockCache[steamid][i].owned = 0
        end

     MySQL.Async.fetchAll('SELECT * FROM nextz_trading WHERE owner=@owner', {['@owner'] = steamid}, function(ostocks)
            for j=1,#ostocks do
                for i=1,#userStockCache[steamid] do
                    if(userStockCache[steamid] and ostocks[j].stock)then
                       if(userStockCache[steamid][i].abr == ostocks[j].stock)then
                           userStockCache[steamid][i].owned = ostocks[j].amount
                        end
                    end
                end
            end

            TriggerClientEvent("nextz_trading:updateStocks", _source, userStockCache[steamid])
        end)
    end
end)


RegisterServerEvent('nextz_trading:buyStock')
AddEventHandler('nextz_trading:buyStock', function(stock, amount, test)
    local _source = source
    local user = exports.fsn_main:fsn_CharID(_source)
    local money = exports.fsn_main:fsn_GetWallet(_source)
    local steamid = GetPlayerIdentifiers(source)
    steamid = steamid[1]

    if(not user)then
        return
    end

    if(not ready)then
        return
    end

    local _stock = {}

    for i=1,#stocks do
        if stocks[i].abr == stock then
            _stock = stocks[i]
            break
        end
    end
    
    if(_stock.abr)then
       
        if (money >= (_stock.worth * amount))then
            TriggerClientEvent('fsn_bank:change:walletMinus', source, (_stock.worth * amount))
            MySQL.Async.fetchAll('SELECT * FROM nextz_trading WHERE owner=@owner', {['@owner'] = steamid}, function(ostocks)
                local done = false
                local newOwned = 0

                userStockCache[steamid] = {}

                for k,v in pairs(stocks)do
                    userStockCache[steamid][k] = v
                    userStockCache[steamid][k].owned = 0
                end

                for j=1,#ostocks do
                    for i=1,#userStockCache[steamid] do
                        if(userStockCache[steamid][i] and ostocks[j])then
                            if(userStockCache[steamid][i].abr == ostocks[j].stock)then
                                userStockCache[steamid][i].owned = ostocks[j].amount
                            end
                            
                            if(userStockCache[steamid][i].abr == ostocks[j].stock and ostocks[j].stock == stock)then
                                if(config.maxStocks < (ostocks[j].amount + amount))then
                                    newOwned = ostocks[j].amount
                                    done = true
                                    user.addMoney(_stock.worth * amount)
                                else
                                    userStockCache[steamid][i].owned = ostocks[j].amount + amount
                                    newOwned = userStockCache[steamid][i].owned
                                    done = true
                                end
                            end
                        end
                    end
                end
        
                if(done)then
                    MySQL.Async.execute("UPDATE nextz_trading SET amount=@amount WHERE owner=@owner AND stock=@stock", {['@stock'] = _stock.abr, ['@owner'] = steamid, ['@amount'] = newOwned}, function()
                        TriggerClientEvent("nextz_trading:setClientToUpdate", _source)                    end)
                else
                    MySQL.Async.execute("INSERT INTO nextz_trading(stock, owner, amount) VALUES (@stock, @owner, @amount)", {['@stock'] = _stock.abr, ['@owner'] = steamid, ['@amount'] = amount}, function()
                        TriggerClientEvent("nextz_trading:setClientToUpdate", _source)
                    end)
                end
            end)
        end
        TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'error', text = 'No Have Money.' })    
    else
        print("[nextz_trading] Unknowk stock " .. tostring(stock))
    end
end)

RegisterServerEvent('nextz_trading:sellStock')
AddEventHandler('nextz_trading:sellStock', function(stock, amount)
    local _source = source
    local user = exports.fsn_main:fsn_CharID(_source)
    local money = exports.fsn_main:fsn_GetWallet(_source)
    local steamid = GetPlayerIdentifiers(source)
    steamid = steamid[1]
    
    if(not user)then
        return
    end

    if(not ready)then
        return
    end

    local _stock = {}

    for i=1,#stocks do
        if stocks[i].abr == stock then
            _stock = stocks[i]
            break
        end
    end

    
    if(_stock.abr)then
        MySQL.Async.fetchAll('SELECT * FROM nextz_trading WHERE owner=@owner', {['@owner'] = steamid}, function(ostocks)
            local done = false
            local sold = 0
            local newOwned = 0

            userStockCache[steamid] = {}

            shallowCopy(userStockCache[steamid], stocks)
        
            for i=1,#userStockCache[steamid] do
               userStockCache[steamid][i].owned = 0
            end

            for j=1,#ostocks do
                for i=1,#userStockCache[steamid] do
                    if(userStockCache[steamid][i] and ostocks[j].stock)then
                        if(userStockCache[steamid][i].abr == ostocks[j].stock and stock == ostocks[j].stock) then
                            if(ostocks[j].amount >= amount)then
                                userStockCache[steamid][i].owned = ostocks[j].amount - amount
                                newOwned = userStockCache[steamid][i].owned
                                sold = amount
                                done = true
                            end

                            break
                        end
                    end
                end
            end
        
            if(done)then
                MySQL.Async.execute("UPDATE nextz_trading SET amount=@amount WHERE owner=@owner AND stock=@stock", {['@stock'] = _stock.abr, ['@owner'] = steamid, ['@amount'] = newOwned}, function()
                    TriggerClientEvent('fsn_bank:change:bankAdd', _source, (sold * _stock.worth))

                    TriggerClientEvent("nextz_trading:setClientToUpdate", _source)
                end)
            end
        end)
    else
        print("[nextz_trading] Unknowk stock " .. tostring(stock))
    end
end)

MySQL.ready(function ()
    ready = true
    print("[nextz_trading] Ready to accept queries!")
end)