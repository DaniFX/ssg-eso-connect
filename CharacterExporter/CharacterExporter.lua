local addonName = "CharacterExporter"

CharacterExporterData = CharacterExporterData or {}

local function GetAttributeName(attributeId)
    if attributeId == POWERTYPE_HEALTH then return "Salute"
    elseif attributeId == POWERTYPE_MAGICKA then return "Magicka"
    elseif attributeId == POWERTYPE_STAMINA then return "Stamina"
    else return "Sconosciuto" end
end

local function GetRaceName(raceId)
    local _, name = GetRaceInfo(raceId)
    return name or "Sconosciuta"
end

local function GetAllianceName(alliance)
    if alliance == ALLIANCE_ALDMERI_DOMINION then return "Aldmeri Dominion"
    elseif alliance == ALLIANCE_EBONHEART_PACT then return "Ebonheart Pact"
    elseif alliance == ALLIANCE_DAGGERFALL_COVENANT then return "Daggerfall Covenant"
    else return "Sconosciuta" end
end

local function GetChampionPoints()
    local level = GetUnitLevel("player")
    if level == 50 then
        return GetUnitChampionPoints("player")
    end
    return 0
end

local function CollectCharacterData()
    local data = {}
    data.timestamp = GetTimeStamp()
    data.characterName = GetUnitName("player")
    data.accountName = GetDisplayName()
    data.level = GetUnitLevel("player")
    data.championPoints = GetChampionPoints()
    data.classId, data.className = GetUnitClass("player")
    data.raceId, data.raceName = GetUnitRace("player")
    data.alliance = GetUnitAlliance("player")
    data.allianceName = GetAllianceName(data.alliance)

    -- Attributes
    data.attributes = {}
    local powerTypes = {
        [POWERTYPE_HEALTH] = { name = "Salute" },
        [POWERTYPE_MAGICKA] = { name = "Magicka" },
        [POWERTYPE_STAMINA] = { name = "Stamina" }
    }
    
    for powerType, info in pairs(powerTypes) do
        local powerValue, powerMax, powerEffectiveMax = GetUnitPower("player", powerType)
        data.attributes[powerType] = {
            name = info.name,
            current = powerValue,
            max = powerMax,
            effectiveMax = powerEffectiveMax
        }
    end

    -- Stats
    data.stats = {}
    local function safeAddStat(name, value)
        if value and type(value) == "number" and value ~= 0 then
            data.stats[name] = value
        end
    end
    
    safeAddStat("Massima Salute", data.attributes[POWERTYPE_HEALTH].max)
    safeAddStat("Massima Magicka", data.attributes[POWERTYPE_MAGICKA].max)
    safeAddStat("Massima Stamina", data.attributes[POWERTYPE_STAMINA].max)

    -- Equipment
    data.equipment = {}
    local equipSlots = {
        [EQUIP_SLOT_HEAD] = "Elmo",
        [EQUIP_SLOT_CHEST] = "Torace",
        [EQUIP_SLOT_SHOULDERS] = "Spalle",
        [EQUIP_SLOT_HAND] = "Mani",
        [EQUIP_SLOT_WAIST] = "Vita",
        [EQUIP_SLOT_LEGS] = "Gambe",
        [EQUIP_SLOT_FEET] = "Piedi",
        [EQUIP_SLOT_MAIN_HAND] = "Arma Principale",
        [EQUIP_SLOT_OFF_HAND] = "Arma Secondaria",
        [EQUIP_SLOT_POISON] = "Veleni",
        [EQUIP_SLOT_RING1] = "Anello 1",
        [EQUIP_SLOT_RING2] = "Anello 2",
        [EQUIP_SLOT_NECK] = "Collana"
    }
    for slotId, slotName in pairs(equipSlots) do
        local bagId = BAG_WORN
        local slotIndex = slotId
        local itemId = GetItemId(bagId, slotIndex)
        if itemId and itemId > 0 then
            local itemName = GetItemName(bagId, slotIndex)
            local quality = GetItemQuality(bagId, slotIndex)
            local icon, _, _, _, _, _, _ = GetItemInfo(bagId, slotIndex)
            local displayQuality = {"Grigio", "Verde", "Blu", "Viola", "Oro", "Epico"}
            data.equipment[slotName] = {
                name = itemName,
                quality = displayQuality[quality + 1] or "Sconosciuta",
                icon = icon
            }
        end
    end

    -- Skills
    data.skills = {}
    for skillType = 1, 3 do
        local numSlots = GetNumSkillSlots(skillType)
        data.skills[skillType] = {}
        for i = 1, numSlots do
            local skillId, abilityId, slotType = GetSkillSlotInfo(skillType, i)
            if skillId and skillId > 0 then
                local skillName = GetSkillName(skillType, i)
                data.skills[skillType][i] = skillName
            end
        end
    end

    return data
end

local function ExportToSavedVars(data)
    local charName = data.characterName
    local megaserver = GetWorldName()
    local accountName = data.accountName
    
    -- Ensure structure exists
    if not CharacterExporterData[megaserver] then CharacterExporterData[megaserver] = {} end
    if not CharacterExporterData[megaserver][accountName] then CharacterExporterData[megaserver][accountName] = {} end
    
    -- Assign data (with a version tracker for parsers)
    data.DataVersion = 1 
    CharacterExporterData[megaserver][accountName][charName] = data
    
    ZO_Alert(UI_ALERT_CATEGORY_ALERTS, nil, "[CharacterExporter] Dati esportati su SavedVariables!")
end

local function SLASH_COMMAND_EXPORT(arg)
    local data = CollectCharacterData()
    ExportToSavedVars(data)
    CHAT_SYSTEM:AddMessage("[CharacterExporter] Dati del personaggio esportati correttamente. Ricordati di fare /reloadui o chiudere il gioco per salvarli su disco.")
end

local function OnAddOnLoaded(event, addonNameLoaded)
    if addonNameLoaded ~= addonName then return end
    EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED)
    
    CharacterExporterData = CharacterExporterData or {}
    
    ZO_Alert(UI_ALERT_CATEGORY_ALERTS, nil, "[CharacterExporter] Caricato! Usa /export per salvare i dati.")
end

EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
SLASH_COMMANDS["/export"] = SLASH_COMMAND_EXPORT