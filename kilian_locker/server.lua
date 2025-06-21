local json = require("json")
ESX = exports["es_extended"]:getSharedObject()

-- 📦 Helper function: Load existing locker contents
local function getCurrentLocker(identifier, cb)
    MySQL.single('SELECT * FROM kilian_locker_db WHERE identifier = ?', { identifier }, function(result)
        if result then
            cb(json.decode(result.items or '[]'), json.decode(result.weapons or '[]'))
        else
            cb({}, {})
        end
    end)
end

-- Get current player weapon loadout
ESX.RegisterServerCallback('kilian_locker:getPlayerLoadout', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.getLoadout())
end)

-- 📥 Store items and weapons in locker
RegisterServerEvent('kilian_locker:storeItems')
AddEventHandler('kilian_locker:storeItems', function(newItems, newWeapons)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    getCurrentLocker(identifier, function(currentItems, currentWeapons)
        -- Merge items
        local itemMap = {}
        for _, item in ipairs(currentItems) do
            itemMap[item.name] = item.count
        end

        for _, item in ipairs(newItems) do
            local invItem = xPlayer.getInventoryItem(item.name)
            local amount = tonumber(item.count)
            if invItem and amount > 0 and invItem.count >= amount then
                xPlayer.removeInventoryItem(item.name, amount, false)
                itemMap[item.name] = (itemMap[item.name] or 0) + amount
            else
                print(('[Locker] %s tried to store invalid item: %s x%s'):format(identifier, item.name, amount))
            end
        end

        local mergedItems = {}
        for name, count in pairs(itemMap) do
            table.insert(mergedItems, { name = name, count = count })
        end

        -- Merge weapons
        local weaponMap = {}
        for _, w in ipairs(currentWeapons) do
            weaponMap[w.name] = w.ammo
        end

        for _, weapon in ipairs(newWeapons) do
            if xPlayer.hasWeapon(weapon.name) then
                xPlayer.removeWeapon(weapon.name)
                weaponMap[weapon.name] = weapon.ammo -- Replace ammo if already stored
            else
                print(('[Locker] %s tried to store invalid weapon: %s'):format(identifier, weapon.name))
            end
        end

        local mergedWeapons = {}
        for name, ammo in pairs(weaponMap) do
            table.insert(mergedWeapons, { name = name, ammo = ammo })
        end

        -- Save locker state to database
        MySQL.update('REPLACE INTO kilian_locker_db (identifier, items, weapons) VALUES (?, ?, ?)', {
            identifier,
            json.encode(mergedItems),
            json.encode(mergedWeapons)
        })
    end)
end)

-- 📤 Retrieve items and weapons from locker
RegisterServerEvent('kilian_locker:takeItems')
AddEventHandler('kilian_locker:takeItems', function(items, weapons)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    -- Give items back
    for _, item in pairs(items) do
        xPlayer.addInventoryItem(item.name, item.count)
    end

    for _, weapon in pairs(weapons) do
        xPlayer.addWeapon(weapon.name, weapon.ammo)
    end

    -- Clear locker
    MySQL.update('DELETE FROM kilian_locker_db WHERE identifier = ?', { identifier })
end)

-- 📄 Get contents of the locker (callback)
ESX.RegisterServerCallback('kilian_locker:getLockerContents', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    getCurrentLocker(identifier, function(items, weapons)
        cb(items, weapons)
    end)
end)
