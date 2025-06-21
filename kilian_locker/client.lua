ESX = exports["es_extended"]:getSharedObject()

-- Locker locations
local storeLocker = vector3(480.01, -1011.83, 25.94)
--local storeLocker = vector3(473.25, -981.71, 28.01)
local takeLocker = vector3(481.21, -981.48, 28.01)

-- Open the locker menu for storing or retrieving
local function openLockerMenu(mode)
    ESX.TriggerServerCallback('kilian_locker:getLockerContents', function(items, weapons)
        local elements = {}

        if mode == 'store' then
            -- List player items
            local playerItems = ESX.GetPlayerData().inventory
            for _, item in pairs(playerItems) do
                if item.count > 0 then
                    table.insert(elements, {
                        label = item.label .. ' x' .. item.count,
                        value = item.name,
                        type = 'item',
                        count = item.count
                    })
                end
            end

            -- List player weapons (via server callback to avoid outdated data)
            ESX.TriggerServerCallback('kilian_locker:getPlayerLoadout', function(loadout)
                for _, weapon in ipairs(loadout) do
                    table.insert(elements, {
                        label = 'Weapon: ' .. weapon.label,
                        value = weapon.name,
                        type = 'weapon',
                        ammo = weapon.ammo
                    })
                end

                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'locker_menu', {
                    title = 'Store Items',
                    align = 'top-left',
                    elements = elements
                }, function(data, menu)
                    local selected = data.current

                    if selected.type == 'item' then
                        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'item_amount', {
                            title = 'Enter amount to store (max: ' .. selected.count .. ')'
                        }, function(data2, menu2)
                            local amount = tonumber(data2.value)
                            if amount == nil or amount <= 0 or amount > selected.count then
                                ESX.ShowNotification('Invalid amount')
                            else
                                TriggerServerEvent('kilian_locker:storeItems', {
                                    { name = selected.value, count = amount }
                                }, {})
                            end
                            menu2.close()
                            menu.close()
                        end, function(data2, menu2)
                            menu2.close()
                        end)

                    elseif selected.type == 'weapon' then
                        TriggerServerEvent('kilian_locker:storeItems', {}, {
                            { name = selected.value, ammo = selected.ammo }
                        })

                        -- Remove weapon locally from loadout cache
                        for i = #ESX.PlayerData.loadout, 1, -1 do
                            if ESX.PlayerData.loadout[i].name == selected.value then
                                table.remove(ESX.PlayerData.loadout, i)
                                break
                            end
                        end

                        ESX.ShowNotification('Weapon stored.')
                        menu.close()
                        Wait(300)
                        openLockerMenu('store')
                    end
                end, function(data, menu)
                    menu.close()
                end)
            end)

        elseif mode == 'take' then
            for _, item in pairs(items) do
                table.insert(elements, {
                    label = item.name .. ' x' .. item.count,
                    value = item.name,
                    type = 'item',
                    count = item.count
                })
            end
            for _, weapon in pairs(weapons) do
                table.insert(elements, {
                    label = 'Weapon: ' .. weapon.name,
                    value = weapon.name,
                    type = 'weapon',
                    ammo = weapon.ammo
                })
            end

            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'locker_menu', {
                title = 'Retrieve Items',
                align = 'top-left',
                elements = elements
            }, function(data, menu)
                TriggerServerEvent('kilian_locker:takeItems', items, weapons)
                menu.close()
            end, function(data, menu)
                menu.close()
            end)
        end
    end)
end

-- Proximity detection and keypress handling
CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())

        if #(playerCoords - storeLocker) < 1.5 then
            ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to store items.')
            if IsControlJustReleased(0, 38) then -- E key
                openLockerMenu('store')
            end
        elseif #(playerCoords - takeLocker) < 1.5 then
            ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to retrieve items.')
            if IsControlJustReleased(0, 38) then -- E key
                openLockerMenu('take')
            end
        end
    end
end)
