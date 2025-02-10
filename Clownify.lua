local gearList = {}  -- your things
local lastSwapTime = {}  -- if you change your pants too fast you'll get dizzy again
local swapCount = {}  -- you know how you are...shoe obsessed. Strict limits on how many you're allowed to try on, we don't want an 'incident' like last time.
local stoppedSlots = {}  -- shoe limit hit, no more shoes for you.
local indecisionCounter = 2  -- Just make a decision already! You've got 6 pairs of shoes, you don't need to try them all on a million times! 
local timeIsMoney = 1  -- we're not waiting all day just for you to choose to wear *that* again

local _G = getfenv(0) -- OG has no _G :'(

-- "I'm not like the other boys"
local exceptionItems = {
    ["Twilight Cultist Mantle"] = true,
    ["Twilight Cultist Cowl"] = true,
    ["Twilight Cultist Robe"] = true
}

-- priest "I could wear plate if I wanted, but it's not worth the risk! It'll all seem like it's going well and then you realise you're wearing banana shoulders..."
local classArmorTypes = {
    ["Druid"] = { "Cloth", "Leather" },
    ["Rogue"] = { "Cloth", "Leather" },
    ["Shaman"] = { "Cloth", "Leather", "Mail" },
    ["Hunter"] = { "Cloth", "Leather", "Mail" },
    ["Paladin"] = { "Cloth", "Leather", "Mail", "Plate" },
    ["Warrior"] = { "Cloth", "Leather", "Mail", "Plate" },
    ["Priest"] = { "Cloth" },
    ["Mage"] = { "Cloth" },
    ["Warlock"] = { "Cloth" },
}

-- oh look at you! so classy!!
local playerClass = UnitClass("player")

-- fashion rules, weirdly strict, no shoes as shoulder pads
local gearSlots = {
    ["HEAD"] = { invSlot = 1, equipType = { "INVTYPE_HEAD" }, swapInterval = 0.15 },
    ["SHOULDER"] = { invSlot = 3, equipType = { "INVTYPE_SHOULDER" }, swapInterval = 0.18 },
    ["CLOAK"] = { invSlot = 15, equipType = { "INVTYPE_CLOAK" }, swapInterval = 0.2 },
    ["CHEST"] = { invSlot = 5, equipType = { "INVTYPE_CHEST", "INVTYPE_ROBE" }, swapInterval = 0.15 },
    ["WRIST"] = { invSlot = 9, equipType = { "INVTYPE_WRIST" }, swapInterval = 0.35 },
    ["HAND"] = { invSlot = 10, equipType = { "INVTYPE_HAND" }, swapInterval = 0.25 },
    ["WAIST"] = { invSlot = 6, equipType = { "INVTYPE_WAIST" }, swapInterval = 0.17 },
    ["LEGS"] = { invSlot = 7, equipType = { "INVTYPE_LEGS" }, swapInterval = 0.18 },
    ["FEET"] = { invSlot = 8, equipType = { "INVTYPE_FEET" }, swapInterval = 0.3 },
}

-- totally normal addon contents
-- honestly...I'm not sure those shoes go with that mace
local mostlyKindWords = {
    "Did someone just cast Rank 3 Eroticism on you?",
    "Myspace is divided - you're either the best or worst dressed person ever",
    "Just tell it's what the cool kids are wearing...it's like totally BiS biatch!",
    "Looking like that? Chuck Norris would do terrible things to you...you know you'd love it",
    "OMG! Everyone on TeamSpeak is going to say how hot you look!",
    "*Tips Fedora*",
    "Ring ding ding daa baa, Baa aramba baa bom baa barooumba",
    "*www.fraps.com*",
	"Unregistered HyperCam 2",
    "Yeah! Now go dance on that mailbox! Get that bag! You go girl!!! $$$$$$$",
    "You're obviously the main character",
    "All the one shouldered noobs are going to be so jealous",
    "They just have to go, 'cause they don't know wack",
    "Don't listen to them babe, it's just the aspect ratio making you look fat",
    "Why is Thottbot not telling me where you got those pants from?",
    "People see you looking like that, getting everybody fired up",
    "She smiled at you on the Deeprun Tram, she was with another..playerClass.. But you won't lose no sleep cause you've got a plan",
    "I'd probably be just as crazy about you if you were my own "..playerClass,
    "Sha, sha-ba-da, sha-ba-da-ca, feel good",
    "We all know you like to move it, move it!",
    "I think you have too many shoes, Shut up!",
    "Those shoes are mine, betch",
    "\rShoes,\rShoes,\rShoes,\rOh my god,\rShoes",
    "\rLet's get some shoes,\rLet's get some shoes,\rLet's get some shoes,\rLet's get some shoes",
    "\rThese shoes rule,\rThese shoes suck,\rThese shoes rule,\rThese shoes suck",
    "\rThese shoes are three hundred fucking dollars,\rLet's get 'em",
    "Alo, salut, sunt eu un haiduc",
    "O RLY?",
    "All their guild base will belong to you",
    "\r\"Baby, I been havin a tough night so treat me nice aight?\"\r\"Aight\"\r\"Slip out of those \124cff1eff00\124Hitem:9999::::::::80:::::\124h[Black Mageweave Leggings]\124h\124r baby, yeah.\"\r\"I slip out of my \124cff1eff00\124Hitem:9999::::::::80:::::\124h[Black Mageweave Leggings]\124h\124r, just for you, "..UnitName("player")..".\"\r\"Oh yeah, aight. Aight, I put on my \124cff0070dd\124Hitem:14136::::::::60:::::\124h[Robe of Winter Night]\124h\124r and \124cffffffff\124Hitem:7::::::::80:::::\124h[The Greatest Wizzard Hat]\124h\124r.\"",
	"\rThe "..(GetInventoryItemLink("player", 8) or "shoes").." on my feet (I bought it)".."\rThe "..(GetInventoryItemLink("player",5) or "clothes").." I\'m wearing (I bought it),\rThe "..(GetInventoryItemLink("player",11) or "ring").." I\'m rocking (I bought it),\rThe "..(GetInventoryItemLink("player",9) or "watch").." I\'m wearing (I bought it),\r\'Cause I depend on me if I want it,"
	}

-- why you got to be like this? just follow the rules man!
local function IsItemException(sName)
    -- Normalize the name to lowercase and remove any extra spaces (optional)
    local normalizedName = string.lower(sName):gsub("%s+", "")  -- remove all whitespace

    for exceptionItem, _ in pairs(exceptionItems) do
        -- Normalize both item name and exception name
        if string.lower(exceptionItem):gsub("%s+", "") == normalizedName then
            return true
        end
    end

    return false
end

-- tell them how nice they look
local function printRandomMessage()
    local index = math.random(1, table.getn(mostlyKindWords))
    DEFAULT_CHAT_FRAME:AddMessage(mostlyKindWords[index])
end

-- "No, officer it's not mine. I'm just holding it for a friend!"
local function IsItemSoulbound(bag, slot)
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")  
    GameTooltip:SetBagItem(bag, slot)  

    local numLines = GameTooltip:NumLines()
    if numLines >= 2 then
        local secondLine = _G["GameTooltipTextLeft2"]:GetText()
        GameTooltip:Hide()  -- Explicitly hide the tooltip after checking
        if secondLine and string.find(secondLine, "Soulbound") then
            return true  
        end
    else
        GameTooltip:Hide()  -- Hide it even if there aren’t enough lines
    end

    return false  
end

-- is it wearable or are leather chaps too much for you? Think about your weak little legs, they could never!
local function IsItemWearable(sSubType, iQuality, bag, slot, sName)
	if exceptionItems[sName] then --check for rebellious rule breaking items...they're better than other items, VIP life for them!
		--print(sName.." is special")
        return true
    end

    local isArmor = false
    for _, armorType in ipairs(classArmorTypes[playerClass]) do
        if sSubType == armorType then
            isArmor = true
            break 
        end
    end
    
    if not isArmor then return false end

    if iQuality <= 1 then return true end
	GameTooltip:Hide()
    return IsItemSoulbound(bag, slot)  
end

-- Just show me what you've got...don't be shy
local function rummage()
    gearList = {}  
    swapCount = {} 
    stoppedSlots = {} 

    for slotName, _ in pairs(gearSlots) do
        gearList[slotName] = {}  
        swapCount[slotName] = 0  
        stoppedSlots[slotName] = false  
    end
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local bagItem = GetContainerItemLink(bag, slot)
            if bagItem then
                local _, _, itemString = string.find(bagItem, "(item:%d+:%d+:%d+:%d+)")
                local sName, sLink, iQuality, iLevel, sType, sSubType, iCount, itemEquipLoc = GetItemInfo(itemString)

                if IsItemWearable(sSubType, iQuality, bag, slot, sName) then
                    for slotName, slotData in pairs(gearSlots) do
                        if gearSlots[slotName] and itemEquipLoc then
                            for _, equipType in pairs(slotData.equipType) do
                                if itemEquipLoc == equipType then
                                    table.insert(gearList[slotName], { bag = bag, slot = slot })
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Why do you have 27 hats, that's too many hats! Fine...which one is the least serial killery?
local function EquipRandomGear(slotName)
    local slotData = gearSlots[slotName]
    local items = gearList[slotName]

    if not items or table.getn(items) == 0 then return end

    local numItems = table.getn(items)
    local swapInterval = timeIsMoney / (indecisionCounter * numItems)

    local maxSwaps = numItems * indecisionCounter
    if swapCount[slotName] >= maxSwaps then
        if not stoppedSlots[slotName] then
            stoppedSlots[slotName] = true
        end
        return
    end

    if GetTime() - (lastSwapTime[slotName] or 0) < swapInterval then return end

    -- it's supposed to be random, don't peak you'll spoil the suprise
    for i = table.getn(items), 2, -1 do
		local j = math.random(i)
		items[i], items[j] = items[j], items[i]  -- shoes in, shoes out..err shake them all about?
	end

    local item = items[1]  -- some times you'll get a hat that makes you look good, other times you'll wonder why RNJesus hates you so much...it's because you've been bad, you know that...
    UseContainerItem(item.bag, item.slot, 1)

    swapCount[slotName] = swapCount[slotName] + 1
    lastSwapTime[slotName] = GetTime()
end

-- shoes check, pants check, gloves check, hat?
local function AllSwapsFinished()
    for slotName, _ in pairs(gearSlots) do
        if table.getn(gearList[slotName]) > 0 and not stoppedSlots[slotName] then
            return false  
        end
    end
    return true  
end

-- THE FUN NEVER ENDS! DON'T YOU GO SPOILING THINGS! I NEED THIS!!!
local function stopClownify()
    if clownifyFrame then
        clownifyFrame:SetScript("OnUpdate", nil)
        clownifyFrame:Hide()
        clownifyFrame = nil
		printRandomMessage()		
    end
end

-- So, you're thinking about maybe getting a new look?
local function clownify()
    --DEFAULT_CHAT_FRAME:AddMessage("You're going to look so good...just *so* good!!")   --shhh don't tell anyone this is here *secret*
    rummage() --let's see what you've got
    if not clownifyFrame then
        clownifyFrame = CreateFrame("Frame")
        clownifyFrame:SetScript("OnUpdate", function()
            for slotName, _ in pairs(gearSlots) do
                EquipRandomGear(slotName)
            end

            if AllSwapsFinished() then
                stopClownify()
            end
        end)
    end
end


-- sometimes things just need to work, everything doesn't have to be exciting
local clownifyMMButton = CreateFrame("Button", "ClownifyButton", Minimap)
clownifyMMButton:SetWidth(32)
clownifyMMButton:SetHeight(32)
clownifyMMButton:SetFrameStrata("MEDIUM")
clownifyMMButton:SetFrameLevel(10)
clownifyMMButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local icon = clownifyMMButton:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Addons\\Clownify\\Clownify.tga")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", clownifyMMButton, "CENTER", 0, 0)

local border = clownifyMMButton:CreateTexture(nil, "ARTWORK")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetWidth(52)
border:SetHeight(52)
border:SetPoint("TOPLEFT", clownifyMMButton, "TOPLEFT", 0, 0)

clownifyMMButton:SetPoint("CENTER", Minimap, "CENTER", 80, -80)
clownifyMMButton:RegisterForDrag("LeftButton")
clownifyMMButton:SetMovable(true)

clownifyMMButton:SetScript("OnDragStart", function() this:StartMoving() end)
clownifyMMButton:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local mx, my = Minimap:GetCenter()
    local x, y = this:GetCenter()
    local angle = math.atan2(y - my, x - mx)
    local radius = Minimap:GetWidth() / 2 + 10
    this:ClearAllPoints()
    this:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end)

clownifyMMButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
clownifyMMButton:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        clownify()
    elseif arg1 == "RightButton" then
        stopClownify()
    end
end)

-- sensible messages, sensible addon
local uWu = {
    "Why so devoid of joy and whimsey?",
    "Why so tragically lacking in mirth and merriment?",
    "Why so utterly bereft of joy and jollity?",
    "Why so humorlessly detached from the silly and sublime?",
	"Why so aggressively allergic to fun and frolic?",
	"Why so cosmically opposed to mirth and magic?",
	"Why so shockingly deficient in capers and cavorting?",
	"Why so grievously bereft of chuckles and chortles?",
	"Why so existentially opposed to goofs and giggles?",
	"Why so criminally absent of giggles and giddiness?",
	"Why so recklessly negligent in the department of delight?"
}

-- Richard of York didn't brown in vain and neither shall we!
local function generateRainbowColor(index, total)
    local ratio = (index - 1) / (total - 1) -- Normalize from 0 to 1
    local r, g, b

    if ratio < 1/6 then
        r, g, b = 1, ratio * 6, 0        -- Red to Yellow
    elseif ratio < 2/6 then
        r, g, b = (2/6 - ratio) * 6, 1, 0 -- Yellow to Green
    elseif ratio < 3/6 then
        r, g, b = 0, 1, (ratio - 2/6) * 6 -- Green to Cyan
    elseif ratio < 4/6 then
        r, g, b = 0, (4/6 - ratio) * 6, 1 -- Cyan to Blue
    elseif ratio < 5/6 then
        r, g, b = (ratio - 4/6) * 6, 0, 1 -- Blue to Magenta
    else
        r, g, b = 1, 0, (6/6 - ratio) * 6 -- Magenta to Red
    end

    -- turns sensible argeebee it to evil https://www.wowhead.com/classic/spell=11641
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

-- hello!, hai! or so...err...like...errm...do you, you know..err...like come here often?
local function displayRandomMessage()
    local messageCount = 0
    for _ in pairs(uWu) do
        messageCount = messageCount + 1
    end
    local message = uWu[math.random(1, messageCount)]

    local coloredMessage = ""
    local totalLength = string.len(message)

    -- apply colors to each character, wow this does the same thing the addon does! That's like totally intended!!
    for i = 1, totalLength do
        local char = string.sub(message, i, i)
        local color = generateRainbowColor(i, totalLength) 
        coloredMessage = coloredMessage .. color .. char
    end

    coloredMessage = coloredMessage .. "|r" -- strings must be finished, even if they're are silly

    DEFAULT_CHAT_FRAME:AddMessage(coloredMessage)
end
-- fashionably late loading message
local f = CreateFrame("Frame")
local delay = 10  -- seconds
local elapsed = 0

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        f:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed >= delay then
				displayRandomMessage()
				f:UnregisterEvent("PLAYER_ENTERING_WORLD")  -- Unregister the specific event
                f:SetScript("OnUpdate", nil)
                f:SetScript("OnEvent", nil)
                f:Hide()
                f = nil  -- Allow garbage collection
            end
        end)
    end
end)


































-- what are you looking down here for? there's nothing down here...
