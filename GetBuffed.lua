local GB = CreateFrame('Frame')
local GBScanner = CreateFrame('Frame')
GBScanner:Hide()

GBScanner:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
GBScanner:SetScript("OnUpdate", function()
    local plus = 3
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        GB.checkMyBuffs()
    end
end)

local GBScannerHelper = CreateFrame('Frame')
GBScannerHelper:Hide()
GBScannerHelper:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
GBScannerHelper:SetScript("OnUpdate", function()
    local plus = 0.5
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        GB.checkMyBuffs()
        GBScannerHelper:Hide()
    end
end)

GB:RegisterEvent("ADDON_LOADED")

GB.RaidBuffs = {}

GB:SetScript("OnEvent", function()
    if event then
        if event == "ADDON_LOADED" and arg1 == 'GetBuffed' then
            if not GB_BUFFS then
                GB_BUFFS = {}
            end
            getglobal('GBMain'):SetBackdropColor(0, 0, 0, .5)
            getglobal('GBSettings'):SetBackdropColor(0, 0, 0, .5)
            GB.cacheItems()
            GBScanner:Show()
        end
    end
end)

function GB.cacheItems()
    for _, data in next, GB.consumables do

        local _, _, itemLink = string.find(data.itemLink, "(item:%d+:%d+:%d+:%d+)");

        local linkEx = string.split(itemLink, ':')
        data.id = tonumber(linkEx[2])

        local name, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Show()
        GameTooltip:Hide()
    end

    GB.checkMyBuffs()
end

GB.settingsFrames = {}

function GB.populateSettings()

    GB.cacheItems()

    local settingsBuffs = 0

    if not GB_BUFFS then
        GB_BUFFS = {}
        for _, data in next, GB.consumables do
            GB_BUFFS[data.id] = '0'
        end
    end

    local i = 0;
    local left = 10
    local top = i
    local rowLimit = 23
    local secondRowLimit = 41
    for _, data in next, GB.consumables do

        i = i + 1
        top = -22 * i
        if i >= rowLimit then
            left = 205
            top = -22 * (i - rowLimit) - 22
        end
        if i >= secondRowLimit then
            left = 405
            top = -22 * (i - secondRowLimit) - 22
        end
        if not GB.settingsFrames[data.id] then
            GB.settingsFrames[data.id] = CreateFrame('Frame', 'sBuff' .. data.id, getglobal("GBSettings"), 'GBSettingsConsumable')
        end

        GB.settingsFrames[data.id]:SetPoint("TOPLEFT", getglobal("GBSettings"), "TOPLEFT", left, top)
        if data.name == 'separator' then
            GB.settingsFrames[data.id]:Hide()
        else
            GB.settingsFrames[data.id]:Show()
        end

        getglobal("sBuff" .. data.id .. "WatchBuff"):SetID(data.id)
        getglobal("sBuff" .. data.id .. "WatchBuff"):SetChecked(GB_BUFFS[data.id] == '1')

        local _, _, itemLink = string.find(data.itemLink, "(item:%d+:%d+:%d+:%d+)");
        local name, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

        if name then

            getglobal("sBuff" .. data.id .. 'Item'):SetNormalTexture(tex)
            getglobal("sBuff" .. data.id .. 'Item'):SetPushedTexture(tex)
            GB.addButtonOnEnterTooltip(getglobal("sBuff" .. data.id .. "Item"), data.itemLink)
            GB.addButtonOnEnterTooltip(getglobal("sBuff" .. data.id .. "WatchBuff"), data.itemLink)

            if GB_BUFFS[data.id] == '1' then
                settingsBuffs = settingsBuffs + 1
                --SetDesaturation(getglobal("sBuff" .. i .. 'Item'):GetNormalTexture(), 0)
                getglobal("sBuff" .. data.id .. 'ItemName'):SetText('|cffffffff' .. name)
            else
                --SetDesaturation(getglobal("sBuff" .. i .. 'Item'):GetNormalTexture(), 1)
                getglobal("sBuff" .. data.id .. 'ItemName'):SetText('|cff888888' .. name)
            end

        end

    end

    local separators = 0
    for _, data in next, GB.consumables do
        separators = separators + (data.name == 'separator' and 1 or 0)
    end
    getglobal('GBSettingsTitle'):SetText('Get Buffed Settings (' .. settingsBuffs .. '/' .. table.getn(GB.consumables) - separators .. ')')

end

GBScanner.frames = {}

function GB.checkMyBuffs()

    local currentBuffs = 0
    local watchedBuffs = 0
    local foundBuffs = {}

    getglobal('GBMain'):SetHeight(20)
    getglobal('GBMain'):SetAlpha(0.5)

    for _, data in next, GB.consumables do
        if GB_BUFFS[data.id] and GB_BUFFS[data.id] == '1' then
            foundBuffs[data.id] = 0
            watchedBuffs = watchedBuffs + 1
        end
    end

    --DEFAULT_CHAT_FRAME:AddMessage('----------')

    for j = 0, 32 do
        local buffName, duration = GB.GetUnitBuff(j)

        if buffName then
            for _, data in next, GB.consumables do
                if buffName == data.name then
                    if GB_BUFFS[data.id] then
                        if GB_BUFFS[data.id] == '1' then
                            currentBuffs = currentBuffs + 1
                            foundBuffs[data.id] = duration
                            --DEFAULT_CHAT_FRAME:AddMessage(buffName .. ' ' .. duration)
                        end
                    end
                end
            end
        end
    end

    for index in next, GBScanner.frames do
        GBScanner.frames[index]:Hide()
    end

    local index = 0
    local timeThreshold = 3 * 60
    for id, data in next, foundBuffs do
        if data == 0 or data < timeThreshold then
            index = index + 1

            if not GBScanner.frames[id] then
                GBScanner.frames[id] = CreateFrame('Frame', 'cBuff' .. id, getglobal("GBMain"), 'GBStatusConsumable')
            end

            GBScanner.frames[id]:SetPoint("TOPLEFT", getglobal("GBMain"), "TOPLEFT", 5, -23 * index - 5)
            GBScanner.frames[id]:Show()

            local _, _, itemLink = string.find(GB.linkFromId(id), "(item:%d+:%d+:%d+:%d+)");
            local name, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

            if name then

                local itemCount = 0
                for bag = 0, NUM_BAG_SLOTS do
                    for slot = 1, GetContainerNumSlots(bag) do
                        local bagItemLink = GetContainerItemLink(bag, slot)
                        if bagItemLink then
                            local consumableName = GetItemInfo(itemLink)

                            local _, _, bItemLink = string.find(bagItemLink, "(item:%d+:%d+:%d+:%d+)");
                            local bagItemName = GetItemInfo(bItemLink)

                            if consumableName == bagItemName then
                                local _, count = GetContainerItemInfo(bag, slot)
                                itemCount = itemCount + count
                            end
                        end
                    end
                end

                if data < timeThreshold and data > 0 then
                    getglobal("cBuff" .. id .. 'ItemName'):SetText('|cffdddddd(|cffff8888' .. math.floor(data / 60) .. 'm|cffdddddd)' .. name)
                else
                    getglobal("cBuff" .. id .. 'ItemName'):SetText('|cffdddddd' .. name)
                end
                getglobal("cBuff" .. id .. 'ItemCount'):SetText(itemCount)

                getglobal("cBuff" .. id .. 'Item'):SetID(id)
                getglobal("cBuff" .. id .. 'Item'):SetNormalTexture(tex)
                getglobal("cBuff" .. id .. 'Item'):SetPushedTexture(tex)

                GB.addButtonOnEnterTooltip(getglobal("cBuff" .. id .. "Item"), GB.linkFromId(id))

                getglobal('GBMain'):SetHeight(30 + 23 * index)
                getglobal('GBMain'):SetAlpha(1)

            end

        end
    end

    getglobal("GBMainTitle"):SetText("Buffs " .. currentBuffs .. "/" .. watchedBuffs)

end

function markWatched(id, check)
    GB_BUFFS[id] = check and '1' or '0'
    GB.checkMyBuffs()

    local _, _, itemLink = string.find(GB.linkFromId(id), "(item:%d+:%d+:%d+:%d+)");
    local name = GetItemInfo(itemLink)

    if name then

        if check then
            getglobal("sBuff" .. id .. 'ItemName'):SetText('|cffffffff' .. name)
            --SetDesaturation(getglobal("sBuff" .. id .. 'Item'):GetNormalTexture(), 0)
        else
            getglobal("sBuff" .. id .. 'ItemName'):SetText('|cff888888' .. name)
            --SetDesaturation(getglobal("sBuff" .. id .. 'Item'):GetNormalTexture(), 1)
        end

        local settingsBuffs = 0
        for _, data in next, GB_BUFFS do
            if data == '1' then
                settingsBuffs = settingsBuffs + 1
            end
        end

        local separators = 0
        for _, data in next, GB.consumables do
            separators = separators + (data.name == 'separator' and 1 or 0)
        end
        getglobal('GBSettingsTitle'):SetText('Get Buffed Settings (' .. settingsBuffs .. '/' .. table.getn(GB.consumables) - separators .. ')')

    end

end

function GBClear_All_OnClick()
    local i = 0
    for _, data in next, GB.consumables do
        i = i + 1
        GB_BUFFS[data.id] = '0'
        getglobal("sBuff" .. data.id .. "WatchBuff"):SetChecked(false)
    end
    GB_BUFFS = {}
    GB.populateSettings()
    GB.checkMyBuffs()
end

function GBUseConsumable_OnClick(id)

    local bagId = -1
    local itemSlot = -1
    local consumable = ''
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local bagItemLink = GetContainerItemLink(bag, slot)

            if bagItemLink then

                local _, _, itemLink = string.find(GB.linkFromId(id), "(item:%d+:%d+:%d+:%d+)");
                local consumableName = GetItemInfo(itemLink)

                if consumableName then

                    consumable = consumableName

                    local _, _, bItemLink = string.find(bagItemLink, "(item:%d+:%d+:%d+:%d+)");
                    local bagItemName = GetItemInfo(bItemLink)

                    if consumableName == bagItemName then
                        bagId = bag
                        itemSlot = slot
                        break
                    end
                end
            end
        end
    end

    if bagId ~= -1 and itemSlot ~= -1 then
        UseContainerItem(bagId, itemSlot, true)
        GBScannerHelper:Show()

    else
        DEFAULT_CHAT_FRAME:AddMessage("[GetBuffed] Cannot find " .. consumable .. " in bags.")
    end

end

function GBSettingsButton_OnClick()
    if getglobal('GBSettings'):IsVisible() then
        getglobal('GBSettings'):Hide()
    else
        GB.populateSettings()
        getglobal('GBSettings'):Show()
    end
end

GB.consumables = {
    { name = 'Flask of the Titans', itemLink = '\124cffffffff\124Hitem:13510:0:0:0:0:0:0:0:0\124h[Flask of the Titans]\124h\124r' },
    { name = 'Distilled Wisdom', itemLink = '\124cffffffff\124Hitem:13511:0:0:0:0:0:0:0:0\124h[Flask of Distilled Wisdom]\124h\124r' },
    { name = 'Supreme Power', itemLink = '\124cffffffff\124Hitem:13512:0:0:0:0:0:0:0:0\124h[Flask of Supreme Power]\124h\124r' },
    { name = 'Chromatic Resistance', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Spirit of Zanza', itemLink = '\124cff1eff00\124Hitem:20079:0:0:0:0:0:0:0:0\124h[Spirit of Zanza]\124h\124r' },
    { name = 'Swiftness of Zanza', itemLink = '\124cff1eff00\124Hitem:20081:0:0:0:0:0:0:0:0\124h[Swiftness of Zanza]\124h\124r' },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Rage of Ages', itemLink = "\124cffffffff\124Hitem:8410:0:0:0:0:0:0:0:0\124h[R.O.I.D.S.]\124h\124r" },
    { name = 'Strike of the Scorpok', itemLink = "\124cffffffff\124Hitem:8412:0:0:0:0:0:0:0:0\124h[Ground Scorpok Assay]\124h\124r" },
    { name = 'Infallible Mind', itemLink = "\124cffffffff\124Hitem:8423:0:0:0:0:0:0:0:0\124h[Cerebral Cortex Compound]\124h\124r" },
    { name = 'Spiritual Domination', itemLink = "\124cffffffff\124Hitem:8424:0:0:0:0:0:0:0:0\124h[Gizzard Gum]\124h\124r" },
    { name = 'Spirit of Boar', itemLink = "\124cffffffff\124Hitem:8411:0:0:0:0:0:0:0:0\124h[Lung Juice Cocktail]\124h\124r" },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Juju Power', itemLink = "\124cffffffff\124Hitem:12451:0:0:0:0:0:0:0:0\124h[Juju Power]\124h\124r" },
    { name = 'Juju Might', itemLink = "\124cffffffff\124Hitem:12460:0:0:0:0:0:0:0:0\124h[Juju Might]\124h\124r" },
    { name = 'Juju Ember', itemLink = "\124cffffffff\124Hitem:12455:0:0:0:0:0:0:0:0\124h[Juju Ember]\124h\124r" },
    { name = 'Juju Chill', itemLink = "\124cffffffff\124Hitem:12457:0:0:0:0:0:0:0:0\124h[Juju Chill]\124h\124r" },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Armor', itemLink = "\124cffffffff\124Hitem:8951:0:0:0:0:0:0:0:0\124h[Elixir of Greater Defense]\124h\124r" },
    { name = 'Greater Armor', itemLink = "\124cffffffff\124Hitem:13445:0:0:0:0:0:0:0:0\124h[Elixir of Superior Defense]\124h\124r" },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Elixir of the Mongoose', itemLink = "\124cffffffff\124Hitem:13452:0:0:0:0:0:0:0:0\124h[Elixir of the Mongoose]\124h\124r" },
    { name = 'Elixir of Giants', itemLink = "\124cffffffff\124Hitem:9206:0:0:0:0:0:0:0:0\124h[Elixir of Giants]\124h\124r" },
    { name = 'Winterfall Firewater', itemLink = "\124cffffffff\124Hitem:12820:0:0:0:0:0:0:0:0\124h[Winterfall Firewater]\124h\124r" },
    { name = 'Greater Agility', itemLink = "\124cffffffff\124Hitem:9187:0:0:0:0:0:0:0:0\124h[Elixir of Greater Agility]\124h\124r" },
    { name = 'Health II', itemLink = "\124cffffffff\124Hitem:3825:0:0:0:0:0:0:0:0\124h[Elixir of Fortitude]\124h\124r" },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Regeneration', itemLink = "\124cffffffff\124Hitem:20004:0:0:0:0:0:0:0:0\124h[Major Troll's Blood Potion]\124h\124r" },
    { name = 'Gift of Arthas', itemLink = "\124cffffffff\124Hitem:9088:0:0:0:0:0:0:0:0\124h[Gift of Arthas]\124h\124r" },
    { name = 'Mana Regeneration', itemLink = "\124cffffffff\124Hitem:20007:0:0:0:0:0:0:0:0\124h[Mageblood Potion]\124h\124r" },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Greater Arcane Elixir', itemLink = "\124cffffffff\124Hitem:13454:0:0:0:0:0:0:0:0\124h[Greater Arcane Elixir]\124h\124r" },
    { name = 'Shadow Power', itemLink = "\124cffffffff\124Hitem:9264:0:0:0:0:0:0:0:0\124h[Elixir of Shadow Power]\124h\124r" }, --Elixir of Shadow Power
    { name = 'Greater Firepower', itemLink = "\124cffffffff\124Hitem:21546:0:0:0:0:0:0:0:0\124h[Elixir of Greater Firepower]\124h\124r" },
    { name = 'Frost Power', itemLink = "\124cffffffff\124Hitem:17708:0:0:0:0:0:0:0:0\124h[Elixir of Frost Power]\124h\124r" },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Crystal Ward', itemLink = "\124cffffffff\124Hitem:11564:0:0:0:0:0:0:0:0\124h[Crystal Ward]\124h\124r" },
    { name = 'Crystal Spire', itemLink = "\124cffffffff\124Hitem:11567:0:0:0:0:0:0:0:0\124h[Crystal Spire]\124h\124r" },

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Arcane Protection', itemLink = "\124cffffffff\124Hitem:13461:0:0:0:0:0:0:0:0\124h[Greater Arcane Protection Potion]\124h\124r" }, --Greater
    { name = 'Fire Protection', itemLink = "\124cffffffff\124Hitem:13457:0:0:0:0:0:0:0:0\124h[Greater Fire Protection Potion]\124h\124r" }, --Greater
    { name = 'Frost Protection', itemLink = "\124cffffffff\124Hitem:13456:0:0:0:0:0:0:0:0\124h[Greater Frost Protection Potion]\124h\124r" }, --Greater
    { name = 'Nature Protection', itemLink = "\124cffffffff\124Hitem:13458:0:0:0:0:0:0:0:0\124h[Greater Nature Protection Potion]\124h\124r" }, --Greater
    { name = 'Shadow Protection', itemLink = "\124cffffffff\124Hitem:13459:0:0:0:0:0:0:0:0\124h[Greater Shadow Protection Potion]\124h\124r" }, --Greater

    { name = 'separator', itemLink = '\124cffffffff\124Hitem:13513:0:0:0:0:0:0:0:0\124h[Flask of Chromatic Resistance]\124h\124r' },

    { name = 'Mana Regeneration', itemLink = "\124cffffffff\124Hitem:13931:0:0:0:0:0:0:0:0\124h[Nightfin Soup]\124h\124r" }, -- conflict with mageblood
    { name = 'Increased Intellect', itemLink = "\124cffffffff\124Hitem:18254:0:0:0:0:0:0:0:0\124h[Runn Tum Tuber Surprise]\124h\124r" },
    { name = 'Increased Stamina', itemLink = "\124cffffffff\124Hitem:21023:0:0:0:0:0:0:0:0\124h[Dirge's Kickin' Chimaerok Chops]\124h\124r" },
    { name = 'Increased Stamina', itemLink = "\124cffffffff\124Hitem:51717:0:0:0:0:0:0:0:0\124h[Magic Mushroom]\124h\124r" },
    { name = 'Fizzy Energy Drink', itemLink = "\124cffffffff\124Hitem:23176:0:0:0:0:0:0:0:0\124h[Fizzy Energy Drink]\124h\124r" },
    { name = 'Blessed Sunfruit Juice', itemLink = "\124cffffffff\124Hitem:13813:0:0:0:0:0:0:0:0\124h[Blessed Sunfruit Juice]\124h\124r" },
    { name = 'Increased Agility', itemLink = "\124cffffffff\124Hitem:13928:0:0:0:0:0:0:0:0\124h[Grilled Squid]\124h\124r" },
    { name = 'Increased Agility', itemLink = "\124cffffffff\124Hitem:51711:0:0:0:0:0:0:0:0\124h[Sweet Mountain Berry]\124h\124r" },
    { name = 'Well Fed', itemLink = "\124cffffffff\124Hitem:20452:0:0:0:0:0:0:0:0\124h[Smoked Desert Dumplings]\124h\124r" }, -- ???
    { name = 'Dragonbreath Chili', itemLink = "\124cffffffff\124Hitem:12217:0:0:0:0:0:0:0:0\124h[Dragonbreath Chili]\124h\124r" },
    { name = 'Rumsey Rum Black Label', itemLink = "\124cffffffff\124Hitem:21151:0:0:0:0:0:0:0:0\124h[Rumsey Rum Black Label]\124h\124r" },
    { name = 'Gordok Green Grog', itemLink = "\124cff1eff00\124Hitem:18269:0:0:0:0:0:0:0:0\124h[Gordok Green Grog]\124h\124r" },

}

function GB.linkFromId(id)

    for _, data in next, GB.consumables do
        if data.id == id then
            return data.itemLink
        end
    end

    return 0

end


-- Elemental Sharpening Stone
-- Consecrated Sharpening Stone
-- Elemental Sharpening Stone
-- scroll of protection IV

--hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()


function GB.addButtonOnEnterTooltip(frame, itemLink)

    if (string.find(itemLink, "|", 1, true)) then
        local ex = string.split(itemLink, "|")

        if not ex[2] or not ex[3] then
            return false
        end

        frame:SetScript("OnEnter", function(self)
            GBToolTip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
            GBToolTip:SetHyperlink(string.sub(ex[3], 2, string.len(ex[3])));
            GBToolTip:Show();
        end)
    else
        frame:SetScript("OnEnter", function(self)
            GBToolTip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
            GBToolTip:SetHyperlink(itemLink);
            GBToolTip:Show();
        end)
    end
    frame:SetScript("OnLeave", function(self)
        GBToolTip:Hide();
    end)
end

function GB.GetUnitBuff(i)
    GBToolTip:SetOwner(GBToolTip, "ANCHOR_NONE");
    GBToolTip:SetUnitBuff('player', i + 1)

    if GBToolTipTextLeft1:GetText() then
        local duration = GetPlayerBuffTimeLeft(GetPlayerBuff(i, "HELPFUL|HARMFUL|PASSIVE"))
        --DEFAULT_CHAT_FRAME:AddMessage(GBToolTipTextLeft1:GetText() .. ' ' .. math.floor(duration/60))
        return GB.trim(GBToolTipTextLeft1:GetText()), duration
    else
        return false, 0
    end

end

function GB.trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end
