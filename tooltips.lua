local _, ns = ...
local Tooltips = ns.Tooltips
local GlobalHooks = Tooltips.GlobalHooks
local GameTooltipHooks = Tooltips.GameTooltipHooks
local ItemRefTooltipHooks = Tooltips.ItemRefTooltipHooks

-- Blizzard API
local TradeSkillFrame = _G.TradeSkillFrame
local GetSpellInfo = _G.GetSpellInfo
local GetItemGem = _G.GetItemGem
local GetActionInfo = _G.GetActionInfo
local UnitBuff = _G.UnitBuff
local UnitDebuff = _G.UnitDebuff
local UnitAura = _G.UnitAura
local GetSpellBookItemInfo = _G.GetSpellBookItemInfo
local GetTalentInfoByID = _G.GetTalentInfoByID
local GetPvpTalentInfoByID = _G.GetPvpTalentInfoByID
local UnitGUID = _G.UnitGUID

local kinds = {
    spell = "SpellID",
    item = "ItemID",
    unit = "NPC ID",
    quest = "QuestID",
    talent = "TalentID",
    achievement = "AchievementID",
    criteria = "CriteriaID",
    ability = "AbilityID",
    currency = "CurrencyID",
    artifactpower = "ArtifactPowerID",
    enchant = "EnchantID",
    bonus = "BonusID",
    gem = "GemID",
    mount = "MountID",
    companion = "CompanionID",
    macro = "MacroID",
    equipmentset = "EquipmentSetID",
    visual = "VisualID",
    source = "SourceID",
    species = "SpeciesID",
    icon = "IconID"
}

local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then return true end
    end
    return false
end

local function hook(table, fn, cb)
    if table and table[fn] then
        hooksecurefunc(table, fn, cb)
    end
end

local function hookScript(table, fn, cb)
    if table and table:HasScript(fn) then
        table:HookScript(fn, cb)
    end
end

local function addLine(tooltip, id, kind)
    if not id or id == "" or not tooltip or not tooltip.GetName then return end
    if type(id) == "table" and #id == 1 then id = id[1] end

    -- Check if we already added to this tooltip. Happens on the talent frame
    local frame, text
    local name = tooltip:GetName()
    if not name then return end
    for i = 1,15 do
        frame = _G[name .. "TextLeft" .. i]
        if frame then text = frame:GetText() end
        if text and string.find(text, kind) then return end
    end

    local left, right
    if type(id) == "table" then
        left = NORMAL_FONT_COLOR_CODE .. kind .. "s" .. FONT_COLOR_CODE_CLOSE
        right = HIGHLIGHT_FONT_COLOR_CODE .. table.concat(id, ", ") .. FONT_COLOR_CODE_CLOSE
    else
        left = NORMAL_FONT_COLOR_CODE .. kind .. FONT_COLOR_CODE_CLOSE
        right = HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE
    end

    tooltip:AddDoubleLine(left, right)

    if kind == kinds.spell then
        iconId = select(3, GetSpellInfo(id))
        if iconId then addLine(tooltip, iconId, kinds.icon) end
    elseif kind == kinds.item then
        iconId = C_Item.GetItemIconByID(id)
        if iconId then addLine(tooltip, iconId, kinds.icon) end
    end

    tooltip:Show()
end

local function addLineByKind(self, id, kind)
    if not kind or not id then return end
    if kind == "spell" or kind == "enchant" or kind == "trade" then
        addLine(self, id, kinds.spell)
    elseif kind == "talent" then
        addLine(self, id, kinds.talent)
    elseif kind == "quest" then
        addLine(self, id, kinds.quest)
    elseif kind == "achievement" then
        addLine(self, id, kinds.achievement)
    elseif kind == "item" then
        addLine(self, id, kinds.item)
    elseif kind == "currency" then
        addLine(self, id, kinds.currency)
    elseif kind == "summonmount" then
        addLine(self, id, kinds.mount)
    elseif kind == "companion" then
        addLine(self, id, kinds.companion)
    elseif kind == "macro" then
        addLine(self, id, kinds.macro)
    elseif kind == "equipmentset" then
        addLine(self, id, kinds.equipmentset)
    elseif kind == "visual" then
        addLine(self, id, kinds.visual)
    end
end

local function addFromData(tooltip, data, kind)
    if kind == kinds.unit and data.guid then
        local id = tonumber(data.guid:match("-(%d+)-%x+$"), 10)
        if id and data.guid:match("%a+") ~= "Player" then addLine(tooltip, id, kind) end
    elseif data.id then
        addLine(tooltip, data.id, kind)
    end
end

-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua
if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
        if not data or not data.type then return end
        if data.type == Enum.TooltipDataType.Spell then
            addFromData(tooltip, data, kinds.spell)
        elseif data.type == Enum.TooltipDataType.Item then
            addFromData(tooltip, data, kinds.item)
        elseif data.type == Enum.TooltipDataType.Unit then
            addFromData(tooltip, data, kinds.unit)
        elseif data.type == Enum.TooltipDataType.Currency then
            addFromData(tooltip, data, kinds.currency)
        elseif data.type == Enum.TooltipDataType.UnitAura then
            addFromData(tooltip, data, kinds.spell)
        elseif data.type == Enum.TooltipDataType.Mount then
            addFromData(tooltip, data, kinds.mount)
        elseif data.type == Enum.TooltipDataType.Achievement then
            addFromData(tooltip, data, kinds.achievement)
        elseif data.type == Enum.TooltipDataType.EquipmentSet then
            addFromData(tooltip, data, kinds.equipmentset)
        elseif data.type == Enum.TooltipDataType.RecipeRankInfo then
            addFromData(tooltip, data, kinds.spell)
        elseif data.type == Enum.TooltipDataType.Totem then
            addFromData(tooltip, data, kinds.spell)
        elseif data.type == Enum.TooltipDataType.Toy then
            addFromData(tooltip, data, kinds.item)
        elseif data.type == Enum.TooltipDataType.Quest then
            addFromData(tooltip, data, kinds.quest)
        elseif data.type == Enum.TooltipDataType.Macro then
            addFromData(tooltip, data, kinds.macro)
        end
    end)
end

Tooltips.SetHyperlink = function(self, link)
    local kind, id = string.match(link,"^(%a+):(%d+)")
    addLineByKind(self, id, kind)
end

Tooltips.OnTooltipSetItem = function(self)
    local link = select(2, self:GetItem())
    if not link then return end

    local itemString = string.match(link, "item:([%-?%d:]+)")
    if not itemString then return end

    local enchantid = ""
    local bonusid = ""
    local gemid = ""
    local bonuses = {}
    local itemSplit = {}

    for v in string.gmatch(itemString, "(%d*:?)") do
        if v == ":" then
            itemSplit[#itemSplit + 1] = 0
        else
            itemSplit[#itemSplit + 1] = string.gsub(v, ":", "")
        end
    end

    for index = 1, tonumber(itemSplit[13]) do
        bonuses[#bonuses + 1] = itemSplit[13 + index]
    end

    local gems = {}
    if GetItemGem then
        for i=1, 4 do
            local _, gemLink = GetItemGem(link, i)
            if gemLink then
                local gemDetail = string.match(gemLink, "item[%-?%d:]+")
                gems[#gems + 1] = string.match(gemDetail, "item:(%d+):")
            elseif flags == 256 then
                gems[#gems + 1] = "0"
            end
        end
    end

    local id = string.match(link, "item:(%d*)")
    if (id == "" or id == "0") and TradeSkillFrame ~= nil and TradeSkillFrame:IsVisible() and GetMouseFocus().reagentIndex then
        local selectedRecipe = TradeSkillFrame.RecipeList:GetSelectedRecipeID()
        for i = 1, 8 do
            if GetMouseFocus().reagentIndex == i then
                id = C_TradeSkillUI.GetRecipeReagentItemLink(selectedRecipe, i):match("item:(%d*)") or nil
                break
            end
        end
    end

    if id then
        addLine(self, id, kinds.item)
        if itemSplit[2] ~= 0 then
            enchantid = itemSplit[2]
            addLine(self, enchantid, kinds.enchant)
        end
        if #bonuses ~= 0 then addLine(self, bonuses, kinds.bonus) end
        if #gems ~= 0 then addLine(self, gems, kinds.gem) end
    end
end

function Tooltips:OnLoadBlizzardAchievementUI()
    if AchievementFrameAchievementsContainer then
        for i, button in ipairs(AchievementFrameAchievementsContainer.buttons) do
            hookScript(button, "OnEnter", function()
                GameTooltip:SetOwner(button, "ANCHOR_NONE")
                GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
                addLine(GameTooltip, button.id, kinds.achievement)
                GameTooltip:Show()
            end)

            hookScript(button, "OnLeave", function()
                GameTooltip:Hide()
            end)

            local hooked = {}
            hook(_G, "AchievementButton_GetCriteria", function(index, renderOffScreen)
                local frame = _G["AchievementFrameCriteria" .. (renderOffScreen and "OffScreen" or "") .. index]
                if frame and not hooked[frame] then
                    hookScript(frame, "OnEnter", function(self)
                        local button = self:GetParent() and self:GetParent():GetParent()
                        if not button or not button.id then return end
                        local criteriaid = select(10, GetAchievementCriteriaInfo(button.id, index))
                        if criteriaid then
                            GameTooltip:SetOwner(button:GetParent(), "ANCHOR_NONE")
                            GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
                            addLine(GameTooltip, button.id, kinds.achievement)
                            addLine(GameTooltip, criteriaid, kinds.criteria)
                            GameTooltip:Show()
                        end
                    end)

                    hookScript(frame, "OnLeave", function()
                        GameTooltip:Hide()
                    end)

                    hooked[frame] = true
                end
            end)
        end
    end
end

function Tooltips:OnLoadBlizzardCollections()
    hook(_G, "WardrobeCollectionFrame_SetAppearanceTooltip", function(self, sources)
        local visualIDs = {}
        local sourceIDs = {}
        local itemIDs = {}

        for i = 1, #sources do
            if sources[i].visualID and not contains(visualIDs, sources[i].visualID) then table.insert(visualIDs, sources[i].visualID) end
            if sources[i].sourceID and not contains(visualIDs, sources[i].sourceID) then table.insert(sourceIDs, sources[i].sourceID) end
            if sources[i].itemID and not contains(visualIDs, sources[i].itemID) then table.insert(itemIDs, sources[i].itemID) end
        end

        if #visualIDs ~= 0 then addLine(GameTooltip, visualIDs, kinds.visual) end
        if #sourceIDs ~= 0 then addLine(GameTooltip, sourceIDs, kinds.source) end
        if #itemIDs ~= 0 then addLine(GameTooltip, itemIDs, kinds.item) end
    end)

    -- Pet Journal selected pet info icon
    hookScript(PetJournalPetCardPetInfo, "OnEnter", function(self)
        if not C_PetJournal or not C_PetBattles.GetPetInfoBySpeciesID then return end
        if PetJournalPetCard.speciesID then
            local npcId = select(4, C_PetJournal.GetPetInfoBySpeciesID(PetJournalPetCard.speciesID));
            addLine(GameTooltip, PetJournalPetCard.speciesID, kinds.species);
            addLine(GameTooltip, npcId, kinds.unit);
        end
    end);
end

function Tooltips:OnLoadBlizzardGarrisonUI()
    -- ability id
    hook(_G, "AddAutoCombatSpellToTooltip", function (self, info)
        if info and info.autoCombatSpellID then
            addLine(self, info.autoCombatSpellID, kinds.ability)
        end
    end)
end

-- Hooks
GameTooltipHooks.SetHyperlink = Tooltips.SetHyperlink
ItemRefTooltipHooks.SetHyperlink = Tooltips.SetHyperlink

GameTooltipHooks.SetAction = function(self, slot)
    if (not GetActionInfo) then return end
    local kind, id = GetActionInfo(slot)
    addLineByKind(self, id, kind)
end

GameTooltipHooks.SetUnitBuff = function(self, ...)
    if not UnitBuff then return end
    local id = select(10, UnitBuff(...))
    addLine(self, id, kinds.spell)
end

GameTooltipHooks.SetUnitDebuff = function(self, ...)
    if not UnitDebuff then return end
    local id = select(10, UnitDebuff(...))
    addLine(self, id, kinds.spell)
end

GameTooltipHooks.SetUnitAura = function(self, ...)
    if not UnitAura then return end
    local id = select(10, UnitAura(...))
    addLine(self, id, kinds.spell)
end

GameTooltipHooks.SetSpellByID = function(self, id)
    addLineByKind(self, id, kinds.spell)
end

GlobalHooks.SetItemRef = function(link, ...)
    local id = tonumber(link:match("spell:(%d+)"))
    addLine(ItemRefTooltip, id, kinds.spell)
end

GlobalHooks.SpellButton_OnEnter = function(self)
    if not SpellBook_GetSpellBookSlot then return end
    local slot = SpellBook_GetSpellBookSlot(self)
    local spellID = select(2, GetSpellBookItemInfo(slot, SpellBookFrame.bookType))
    addLine(GameTooltip, spellID, kinds.spell)
end

GameTooltipHooks.SetRecipeResultItem = function(self, id)
    addLine(self, id, kinds.spell)
end

GameTooltipHooks.SetRecipeRankInfo = function(self, id)
    addLine(self, id, kinds.spell)
end

GameTooltipHooks.SetArtifactPowerByID = function(self, powerID)
    if not C_ArtifactUI or not C_ArtifactUI.GetPowerInfo then return end
    local powerInfo = C_ArtifactUI.GetPowerInfo(powerID)
    addLine(self, powerID, kinds.artifactpower)
    addLine(self, powerInfo.spellID, kinds.spell)
end

GameTooltipHooks.SetTalent = function(self, id)
    if (not GetTalentInfoByID) then return end
    local spellID = select(6, GetTalentInfoByID(id))
    addLine(self, id, kinds.talent)
    addLine(self, spellID, kinds.spell)
end

GameTooltipHooks.SetPvpTalent = function(self, id)
    if not GetPvpTalentInfoByID then return end
    local spellID = select(6, GetPvpTalentInfoByID(id))
    addLine(self, id, kinds.talent)
    addLine(self, spellID, kinds.spell)
end

-- Season of Discovery Runes
-- how the fuck do you get the rune info ???
GameTooltipHooks.SetEngravingRune = function(self, id)
    if (not C_Engraving) then return end
    addLine(self, id, "SkillLineAbilityID")
end
  
-- Pet Journal team icon
GameTooltipHooks.SetCompanionPet = function(self, petID)
    if (not C_PetJournal or not C_PetJournal.GetPetInfoByPetID) then return end
    local speciesID = select(1, C_PetJournal.GetPetInfoByPetID(petID));
    if speciesID then
    local npcId = select(4, C_PetJournal.GetPetInfoBySpeciesID(speciesID));
        addLine(GameTooltip, speciesID, kinds.species);
        addLine(GameTooltip, npcId, kinds.unit);
    end
end

GameTooltipHooks.SetToyByItemID = function(self, id)
    addLine(self, id, kinds.item)
end

GameTooltipHooks.SetRecipeReagentItem = function(self, id)
    addLine(self, id, kinds.item)
end

GlobalHooks.etBattleAbilityButton_OnEnter = function(self)
    if (not C_PetBattles or not C_PetBattles.GetActivePet) then return end
    if (not C_PetBattles or not C_PetBattles.GetAbilityInfo) then return end
    local petIndex = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY)
    if self:GetEffectiveAlpha() > 0 then
        local id = select(1, C_PetBattles.GetAbilityInfo(LE_BATTLE_PET_ALLY, petIndex, self:GetID()))
        if id then
            local oldText = PetBattlePrimaryAbilityTooltip.Description:GetText(id)
            PetBattlePrimaryAbilityTooltip.Description:SetText(oldText .. "\r\r" .. kinds.ability .. "|cffffffff " .. id .. "|r")
        end
    end
end

GlobalHooks.PetBattleAura_OnEnter = function(self)
    if (not C_PetBattles or not C_PetBattles.GetAuraInfo) then return end
    local parent = self:GetParent()
    local id = select(1, C_PetBattles.GetAuraInfo(parent.petOwner, parent.petIndex, self.auraIndex))
    if id then
        local oldText = PetBattlePrimaryAbilityTooltip.Description:GetText(id)
        PetBattlePrimaryAbilityTooltip.Description:SetText(oldText .. "\r\r" .. kinds.ability .. "|cffffffff " .. id .. "|r")
    end
end

GameTooltipHooks.SetCurrencyToken = function(self, index)
    if (not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyListLink) then return end
    local id = tonumber(string.match(C_CurrencyInfo.GetCurrencyListLink(index),"currency:(%d+)"))
    addLine(self, id, kinds.currency)
end

GameTooltipHooks.SetCurrencyByID = function(self, id)
    addLine(self, id, kinds.currency)
end

GameTooltipHooks.SetCurrencyTokenByID = function(self, id)
    addLine(self, id, kinds.currency)
end

GlobalHooks.QuestMapLogTitleButton_OnEnter = function(self)
    if (not C_QuestLog or not C_QuestLog.GetQuestIDForLogIndex) then return end
    local id = C_QuestLog.GetQuestIDForLogIndex(self.questLogIndex)
    addLine(GameTooltip, id, kinds.quest)
end

GlobalHooks.TaskPOI_OnEnter = function(self)
    if self and self.questID then addLine(GameTooltip, self.questID, kinds.quest) end
end

function Tooltips:Enable()
    -- GameTooltip
    for fn, callback in pairs(GameTooltipHooks) do
        hook(GameTooltip, fn, callback)
    end

    hookScript(GameTooltip, "OnTooltipSetSpell", function(self)
        local id = select(2, self:GetSpell())
        addLine(self, id, kinds.spell)
    end)

    hookScript(GameTooltip, "OnTooltipSetUnit", function(self)
        if not C_PetBattles or not C_PetBattles.IsInBattle then return end
        if C_PetBattles.IsInBattle() then return end
        local unit = select(2, self:GetUnit())
        if unit then
            local guid = UnitGUID(unit) or ""
            local id = tonumber(guid:match("-(%d+)-%x+$"), 10)
            if id and guid:match("%a+") ~= "Player" then addLine(GameTooltip, id, kinds.unit) end
        end
    end)
      
    hookScript(GameTooltip, "OnTooltipSetItem", Tooltips.OnTooltipSetItem)

    -- ItemRefTooltip
    for fn, callback in pairs(ItemRefTooltipHooks) do
        hook(ItemRefTooltip, fn, callback)
    end

    hookScript(ItemRefTooltip, "OnTooltipSetItem", Tooltips.OnTooltipSetItem)
    hookScript(ItemRefShoppingTooltip1, "OnTooltipSetItem", Tooltips.OnTooltipSetItem)
    hookScript(ItemRefShoppingTooltip2, "OnTooltipSetItem", Tooltips.OnTooltipSetItem)
    hookScript(ShoppingTooltip1, "OnTooltipSetItem", Tooltips.OnTooltipSetItem)
    hookScript(ShoppingTooltip2, "OnTooltipSetItem", Tooltips.OnTooltipSetItem)

    -- Globals
    for fn, callback in pairs(GlobalHooks) do
        hook(_G, fn, callback)
    end

    if (self.EnableVendorPrice) then
        self:EnableVendorPrice()
    end
end

Tooltips:RegisterEvent("ADDON_LOADED")
Tooltips:RegisterEvent("PLAYER_LOGIN")
Tooltips:SetScript("OnEvent", function(self, event, ...)
    -- call one of the event handlers
    self[event](self, ...)
end)

function Tooltips:ADDON_LOADED(addon, _)
    if (addon == "Blizzard_AchievementUI") then
        self:OnLoadBlizzardAchievementUI()
    elseif (addon == "Blizzard_Collections") then
        self:OnLoadBlizzardCollections()
    elseif (addon == "Blizzard_GarrisonUI") then
        self:OnLoadBlizzardGarrisonUI()
    end
end

function Tooltips:PLAYER_LOGIN()
    self:Enable()
end
