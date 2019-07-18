-- A very special thanks to merlight for the research done to make this possible!

QUALITYSORT_INVENTORY_QUICKSLOT  = 100
QUALITYSORT_CRAFTING_DECON       = 200
QUALITYSORT_CRAFTING_ENCHANTING  = 201
QUALITYSORT_CRAFTING_IMPROVEMENT = 202
QUALITYSORT_CRAFTING_REFINEMENT  = 203
QUALITYSORT_CRAFTING_RETRAIT     = 204

QUALITYSORT_DIR_DESC = 1
QUALITYSORT_DIR_ASC  = 2

QualitySort = {
    name    = "QualitySort",
    version = "2.1.0",
    title   = "|c99CCEFQuality Sort|r",
    author  = "|c99CCEFsilvereyes|r & |cEFEBBERandactyl|r",
    sortOrders = {
        ["enchantment"] = GetString(SI_ITEM_FORMAT_STR_AUGMENT_ITEM_TYPE),
        ["equipped"]    = GetString(SI_ITEM_FORMAT_STR_EQUIPPED),
        ["id"]          = GetString(SI_QUALITYSORT_ID),
        ["level"]       = GetString(SI_QUALITYSORT_LEVEL),
        ["masterWrit"]  = GetString(SI_QUALITYSORT_MASTER_WRIT),
        ["name"]        = GetString(SI_TRADINGHOUSEFEATURECATEGORY0),
        ["quality"]     = GetString(SI_MASTER_WRIT_DESCRIPTION_QUALITY),
        ["set"]         = GetString(SI_QUALITYSORT_SET),
        ["slot"]        = GetString(SI_QUALITYSORT_EQUIP_SLOT),
        ["style"]       = GetString(SI_SMITHING_HEADER_STYLE),
        ["trait"]       = GetString(SI_SMITHING_HEADER_TRAIT),
        ["vouchers"]    = GetString(SI_QUALITYSORT_VOUCHERS),
    },
    defaults = {
        automatic = true,
        sortOrder = {
            "quality",
            "equipped",
            "set",
            "slot",
            "name",
            "level",
            "trait",
            "enchantment",
            "style",
            "id",
            "vouchers",
            "masterWrit",
        },
        sortDirection = {
            ["enchantment"] = QUALITYSORT_DIR_ASC,
            ["equipped"]    = QUALITYSORT_DIR_ASC,
            ["id"]          = QUALITYSORT_DIR_ASC,
            ["level"]       = QUALITYSORT_DIR_ASC,
            ["masterWrit"]  = QUALITYSORT_DIR_ASC,
            ["name"]        = QUALITYSORT_DIR_ASC,
            ["quality"]     = QUALITYSORT_DIR_DESC,
            ["set"]         = QUALITYSORT_DIR_ASC,
            ["slot"]        = QUALITYSORT_DIR_ASC,
            ["style"]       = QUALITYSORT_DIR_ASC,
            ["trait"]       = QUALITYSORT_DIR_ASC,
            ["vouchers"]    = QUALITYSORT_DIR_ASC,
        },
    },
    sortByControls = {
        [ZO_PlayerInventorySortBy]                                      = { INVENTORY_BACKPACK, INVENTORY_QUEST_ITEM },
        [ZO_PlayerBankSortBy]                                           = INVENTORY_BANK,
        [ZO_GuildBankSortBy]                                            = INVENTORY_GUILD_BANK,
        [ZO_CraftBagSortBy]                                             = INVENTORY_CRAFT_BAG,
        [ZO_HouseBankSortBy]                                            = INVENTORY_HOUSE_BANK,
        [ZO_QuickSlotSortBy]                                            = QUALITYSORT_INVENTORY_QUICKSLOT,
        [ZO_SmithingTopLevelDeconstructionPanelInventorySortBy]         = QUALITYSORT_CRAFTING_DECON,
        [ZO_EnchantingTopLevelInventorySortBy]                          = QUALITYSORT_CRAFTING_ENCHANTING,
        [ZO_SmithingTopLevelImprovementPanelInventorySortBy]            = QUALITYSORT_CRAFTING_IMPROVEMENT,
        [ZO_SmithingTopLevelRefinementPanelInventorySortBy]             = QUALITYSORT_CRAFTING_REFINEMENT,
        [ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventorySortBy] = QUALITYSORT_CRAFTING_RETRAIT,
    },
}

local addon = QualitySort

QualitySort.extendedDataCache = {}
local extendedDataCache = QualitySort.extendedDataCache
local comparisonFunctions = { }
local function GetExtendedData(data)
    local uniqueId = zo_getSafeId64Key(data.uniqueId or GetItemUniqueId(data.bagId, data.slotIndex))
    if extendedDataCache[uniqueId] then
        return extendedDataCache[uniqueId]
    end
    local extendedData = { 
        uniqueId = uniqueId,
        bagId = data.bagId, 
        slotIndex = data.slotIndex,
    }
    local link = GetItemLink(extendedData.bagId, extendedData.slotIndex)
    local _, _, _, itemId, _, _, 
          enchantType, enchantSubType, enchantLevel, writ1, writ2, writ3, writ4, writ5, writ6, 
          itemStyle, _, _, _, charges, vouchers = ZO_LinkHandler_ParseLink(link)
    extendedData.itemId = tonumber(itemId)
    extendedData.link = link
    extendedData.championRank = GetItemLinkRequiredChampionPoints(link)
    extendedData.traitInfo = GetItemLinkTraitInfo(link)
    extendedData.itemStyle = GetItemLinkItemStyle(link)
    extendedData.equipType = GetItemLinkEquipType(link)
    local _, setName, _, _, _, setId = GetItemLinkSetInfo(link)
    extendedData.setId = setId
    extendedData.setName = setName
    if charges and tonumber(charges) > 0 then
        extendedData.enchantment = {
            charges = tonumber(charges),
            type = tonumber(enchantType),
            subType = tonumber(enchantSubType),
            level = tonumber(enchantLevel),
        }
    end
    if data.itemType == ITEMTYPE_MASTER_WRIT and vouchers then
        extendedData.masterWrit = {
            writ1 = tonumber(writ1), 
            writ2 = tonumber(writ2), 
            writ3 = tonumber(writ3), 
            writ4 = tonumber(writ4), 
            writ5 = tonumber(writ5), 
            writ6 = tonumber(writ6),
            vouchers = math.max(2, tonumber(string.format("%.0f", tonumber(vouchers)/10000)))
        }
    end
    if uniqueId ~= nil then
        extendedDataCache[uniqueId] = extendedData
    end
    return extendedData
end
local function NilOrLessThan(value1, value2)
    if value1 == nil then
        return true
    elseif value2 == nil then
        return false
    else
        return value1 < value2
    end
end
function comparisonFunctions.enchantment(item1, extData1, item2, extData2)
    if extData1.enchantment == extData2.enchantment then
        return
    end
    local enchant1 = extData1.enchantment
    local enchant2 = extData2.enchantment
    if enchant1 == nil then
        return true
    elseif enchant2 == nil then
        return false
    elseif enchant1.type ~= enchant2.type then
        return NilOrLessThan(enchant1.type, enchant2.type)
    elseif enchant1.subType ~= enchant2.subType then
        return NilOrLessThan(enchant1.subType, enchant2.subType)
    else
        return NilOrLessThan(enchant1.charges, enchant2.charges)
    end
end
function comparisonFunctions.equipped(item1, extData1, item2, extData2)
    if item1.bagId ~= item2.bagId then
        if item1.bagId == BAG_WORN then
            return true
        elseif item2.bagId == BAG_WORN then
            return false
        end
    end
end
function comparisonFunctions.id(item1, extData1, item2, extData2)
    if extData1.itemId ~= extData2.itemId then
        return NilOrLessThan(extData1.itemId, extData2.itemId)
    end
end
function comparisonFunctions.level(item1, extData1, item2, extData2)
    if item1.requiredLevel ~= item2.requiredLevel then
        return NilOrLessThan(item1.requiredLevel, item2.requiredLevel)
    end
    if extData1.championRank ~= extData2.championRank then
        return NilOrLessThan(extData1.championRank, extData2.championRank)
    end
end
function comparisonFunctions.masterWrit(item1, extData1, item2, extData2)
    if extData1.masterWrit == nil or extData2.masterWrit == nil then
        return
    end
    local writ1 = extData1.masterWrit
    local writ2 = extData2.masterWrit
    if writ1.writ1 ~= writ2.writ1 then
        return NilOrLessThan(writ1.writ1, writ2.writ1)
    elseif writ1.writ2 ~= writ2.writ2 then
        return NilOrLessThan(writ1.writ2, writ2.writ2)
    elseif writ1.writ3 ~= writ2.writ3 then
        return NilOrLessThan(writ1.writ3, writ2.writ3)
    elseif writ1.writ4 ~= writ2.writ4 then
        return NilOrLessThan(writ1.writ4, writ2.writ4)
    elseif writ1.writ5 ~= writ2.writ5 then
        return NilOrLessThan(writ1.writ5, writ2.writ5)
    else
        return NilOrLessThan(writ1.writ6, writ2.writ6)
    end
end
function comparisonFunctions.name(item1, extData1, item2, extData2)
    if item1.name ~= item2.name then
        return NilOrLessThan(item1.name, item2.name)
    end
end
function comparisonFunctions.set(item1, extData1, item2, extData2)
    if extData1.setId ~= extData2.setId then
        return NilOrLessThan(extData1.setName, extData2.setName)
    end
end
function comparisonFunctions.slot(item1, extData1, item2, extData2)
    if extData1.equipType ~= extData2.equipType then
        return NilOrLessThan(extData1.equipType, extData2.equipType)
    end
end
function comparisonFunctions.style(item1, extData1, item2, extData2)
    if extData1.itemStyle ~= extData2.itemStyle then
        return NilOrLessThan(extData1.itemStyle, extData2.itemStyle)
    end
end
function comparisonFunctions.trait(item1, extData1, item2, extData2)
    if extData1.traitInfo ~= extData2.traitInfo then
        return NilOrLessThan(extData1.traitInfo, extData2.traitInfo)
    end
end
function comparisonFunctions.vouchers(item1, extData1, item2, extData2)
    if extData1.masterWrit ~= nil and extData2.masterWrit ~= nil then
        return NilOrLessThan(extData1.masterWrit.vouchers, extData2.masterWrit.vouchers)
    end
end

function QualitySort.orderByItemQuality(item1, item2)
  
    local self = QualitySort
    
    -- Sort first by quality
    if item1.quality ~= item2.quality then
        if self.settings.sortDirection.quality == QUALITYSORT_DIR_ASC then
            return NilOrLessThan(item1.quality, item2.quality)
        else
            return NilOrLessThan(item2.quality, item1.quality)
        end
    end
    
    if item1.questIndex or item2.questIndex then
        return NilOrLessThan(item1.name, item2.name)
    end
    
    -- Get extended data for the two data slots
    local extData1 = GetExtendedData(item1)
    local extData2 = GetExtendedData(item2)
    
    -- Perform comparisons in the configured sort order
    for optionIndex, option in ipairs(self.settings.sortOrder) do
        local compare = comparisonFunctions[option]
        if compare then
            local result
            if self.settings.sortDirection[self.settings.sortOrder[optionIndex]] == QUALITYSORT_DIR_ASC then
                result = compare(item1, extData1, item2, extData2)
            else
                result = compare(item2, extData2, item1, extData1)
            end
            if result ~= nil then
                return result
            end
        end
    end
    
    -- And finally, sort by item unique id, to make sure relative order stays the same on update
    return NilOrLessThan(extData1.uniqueId, extData2.uniqueId)
end
local function sortFunction(entry1, entry2, sortKey, sortOrder)
    local res
    if type(sortKey) == "function" then
        if sortOrder == ZO_SORT_ORDER_UP then
            res = sortKey(entry1.data, entry2.data)
        else
            res = sortKey(entry2.data, entry1.data)
        end
    else
        local sortKeys = ZO_Inventory_GetDefaultHeaderSortKeys()
        res = ZO_TableOrderingFunction(entry1.data, entry2.data, sortKey, sortKeys, sortOrder)
    end
    return res
end
function QualitySort.initCustomInventorySortFn(inventory)
    inventory.sortFn = function(entry1, entry2)
        local sortKey = inventory.currentSortKey
        local sortOrder = inventory.currentSortOrder
        return sortFunction(entry1, entry2, sortKey, sortOrder)
    end
end
function QualitySort.initSortFunction(owner)
    owner.sortFunction = function(entry1, entry2)
        local sortKey = owner.sortHeaders:GetCurrentSortKey()
        local sortOrder = owner.sortHeaders:GetSortDirection()
        return sortFunction(entry1, entry2, sortKey, sortOrder)
    end
end
local function Prehook_NameHeader_SetWidth(nameHeader, width)
    return true
end
local function ShiftRightAnchorOffsetX(header, relativeTo, shiftX, qualityHeader)
    if header == relativeTo or header == qualityHeader then
        return
    end
    local isValidAnchor, point, anchorRelativeTo, relativePoint, offsetX, offsetY, anchorConstrains = header:GetAnchor(0)
    if not isValidAnchor or anchorRelativeTo ~= relativeTo then
        return
    end
    if (relativePoint == RIGHT or relativePoint == TOPRIGHT or relativePoint == BOTTOMRIGHT) then
        header:ClearAnchors()
        -- If the original offset is less than the width of the quality header, 
        -- just anchor it to the right of the quality header instead
        local leftPoint = offsetX + shiftX
        if point == RIGHT or point == TOPRIGHT or point == BOTTOMRIGHT then
            leftPoint = leftPoint - header:GetWidth()
        end
        
        if leftPoint < qualityHeader:GetWidth() then
            header:SetAnchor(LEFT, qualityHeader, relativePoint, 0, offsetY, anchorConstrains)
        
        -- Otherwise, shift the original anchor
        else
            header:SetAnchor(point, relativeTo, relativePoint, offsetX + shiftX, offsetY, anchorConstrains)
        end
    end
end
local function GetBagIdForInventoryType(inventoryType)
    for bagId, bagInventoryType in pairs(PLAYER_INVENTORY.bagToInventoryType) do
        if inventoryType == bagInventoryType then
            return bagId
        end
    end
end
local function GetSortHeaders(sortByControl)
    local self = QualitySort
    local flag = self.sortByControls[sortByControl]
    if type(flag) == "table" then
        flag = flag[1]
    end
    local inventory = PLAYER_INVENTORY.inventories[flag]
    if inventory then
        return inventory.sortHeaders
    end
    inventory = sortByControl:GetParent()
    local owner = inventory.owner
    return owner.sortHeaders
end
local function PurgeCacheForInventoryType(inventoryManager, inventoryType)
    if inventoryType == INVENTORY_QUEST_ITEM then return end
    local bagId = GetBagIdForInventoryType(inventoryType)
    if not bagId then return end
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
    local itemsToPurge = {}
    for uniqueId, extendedData in pairs(extendedDataCache) do
        local slotData = bagCache[extendedData.slotIndex]
        if not slotData or zo_getSafeId64Key(slotData.uniqueId) ~= uniqueId then
            table.insert(itemsToPurge, uniqueId)
        end
    end
    for i=1, #itemsToPurge do
        extendedDataCache[itemsToPurge[i]] = nil
    end
end
local function OnSortByControlEffectivelyShown(sortByControl)
    local self = QualitySort
    local qualityHeader = GetControl(sortByControl, "Quality")
    if self.settings.automatic then
        zo_callLater(function()
                         local sortHeaders = GetSortHeaders(sortByControl)
                         sortHeaders:OnHeaderClicked(qualityHeader, false, false, qualityHeader.initialDirection)
                     end, 20)
    end
end
function QualitySort.addSortByQuality(flags, sortByControl)
  
    local self = QualitySort
  
    local newNameWidth = 80
    local qualityWidth = 80
    local nameHeader = sortByControl:GetNamedChild("Name")
    local nameWidth = nameHeader:GetWidth()
    local shiftX = nameWidth - newNameWidth
    
    -- Make the name header narrower to avoid overlap with the quality header.
    nameHeader:SetWidth(newNameWidth)
    
    -- Disable changing the name header's width again
    ZO_PreHook(nameHeader, "SetWidth", Prehook_NameHeader_SetWidth)
    
    -- Create the quality header
    local qualityHeader = CreateControlFromVirtual("$(parent)Quality", sortByControl, "ZO_SortHeader")
    
    -- Anchor the quality header to the right side of the name header
    qualityHeader:SetAnchor(LEFT, nameHeader, RIGHT)
    qualityHeader:SetDimensions(qualityWidth, 20)

    -- Shift all headers that are anchored to the right side of the name header
    -- over to account for the decreased name header width.
    for i=1,sortByControl:GetNumChildren() do
        local child = sortByControl:GetChild(i)
        ShiftRightAnchorOffsetX(child, nameHeader, shiftX, qualityHeader)
    end
    
    ZO_SortHeader_Initialize(qualityHeader, GetString(SI_MASTER_WRIT_DESCRIPTION_QUALITY), self.orderByItemQuality,
                             ZO_SORT_ORDER_UP, TEXT_ALIGN_RIGHT, "ZoFontHeader")

    if type(flags) ~= "table" then
        flags = { flags }
    end
    for _, flag in ipairs(flags) do
        local inventory = PLAYER_INVENTORY.inventories[flag]
        if inventory then
            self.initCustomInventorySortFn(inventory)
        else
            self.initSortFunction(sortByControl:GetParent().owner)
        end
    end
    GetSortHeaders(sortByControl):AddHeader(qualityHeader)
    
    ZO_PreHookHandler(sortByControl, "OnEffectivelyShown", OnSortByControlEffectivelyShown)
end


function QualitySort.printVersion()
    d(QualitySort.name.." version "..QualitySort.version)
end

function QualitySort.onAddonLoaded(eventCode, addonName)
    local self = QualitySort
    if addonName ~= self.name then return end

    EVENT_MANAGER:UnregisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, self.onAddonLoaded)
    
    self:SetupOptions()

    ZO_QuickSlot.owner = QUICKSLOT_WINDOW
    
    for sortByControl, flags in pairs(self.sortByControls) do
        self.addSortByQuality(flags, sortByControl)
    end
    
    ZO_PreHook(PLAYER_INVENTORY, "ApplySort", PurgeCacheForInventoryType)
    SLASH_COMMANDS["/qualitysort"] = self.printVersion
end

EVENT_MANAGER:RegisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, QualitySort.onAddonLoaded)
