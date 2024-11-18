local _, ns = ...
local Tooltips = ns.Tooltips

if (Tooltips.isRetail) then return end

local isClassic = Tooltips.isClassic
local GameTooltipHooks = Tooltips.GameTooltipHooks

-- blizzard
local BankFrame = _G.BankFrame
local MerchantFrame = _G.MerchantFrame
local SetTooltipMoney = _G.SetTooltipMoney
local GetItemInfo = _G.GetItemInfo

-- constants
local overridePrice = nil
local SELL_PRICE = _G.SELL_PRICE or "Sell Price"
local SELL_PRICE_TEXT = format("%s:", SELL_PRICE)
local FIRST_KEYRING_INVSLOT = 107

local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4
local NUM_BANKBAGSLOTS = _G.NUM_BANKBAGSLOTS or 6
local CONTAINER_BAG_OFFSET = _G.CONTAINER_BAG_OFFSET or 19
local CharacterBags = {}

local BAG_FIRST_CONTAINER_ID = C_Container.ContainerIDToInventoryID(1)
local BAG_LAST_CONTAINER_ID = C_Container.ContainerIDToInventoryID(NUM_BAG_SLOTS)
for i = BAG_FIRST_CONTAINER_ID, BAG_LAST_CONTAINER_ID do
    CharacterBags[i] = true
end

local BANK_FIRST_CONTAINER_ID = C_Container.ContainerIDToInventoryID(NUM_BAG_SLOTS + 1)
local BANK_LAST_CONTAINER_ID = C_Container.ContainerIDToInventoryID(NUM_BAG_SLOTS + NUM_BANKBAGSLOTS)
for i = BANK_FIRST_CONTAINER_ID, BANK_LAST_CONTAINER_ID do
    CharacterBags[i] = true
end

local function IsMerchant(self)
	if MerchantFrame:IsShown() then
		local name = self:GetOwner():GetName()
		if name then
			return not (name:find("Character") or name:find("TradeSkill"))
		end
	end
end

-- source was only really used for auctionator
local function ShouldShowPrice(self, source)
	return not IsMerchant(self)
end

-- OnTooltipSetItem fires twice for recipes
local function IsRecipe(self, classID, isOnTooltipSetItem)
	if classID == Enum.ItemClass.Recipe and isOnTooltipSetItem then
		self.isFirstMoneyLine = not self.isFirstMoneyLine
		return self.isFirstMoneyLine
	end
end

-- modify the tooltip when pressing shift, has a small delay
-- local _SetTooltipMoney = SetTooltipMoney
Tooltips.SetTooltipMoney = function(frame, money, ...)
	if IsShiftKeyDown() and overridePrice then
		SetTooltipMoney(frame, overridePrice, ...)
	else
		SetTooltipMoney(frame, money, ...)
		overridePrice = nil
	end
end

local function AddVendorPrice(self, hasWrathTooltip, source, count, item, isOnTooltipSetItem)
	if ShouldShowPrice(self, source) then
		count = count or 1
		item = item or select(2, self:GetItem())
		if item then
			local sellPrice, classID = select(11, GetItemInfo(item))
			if sellPrice and sellPrice > 0 and not IsRecipe(self, classID, isOnTooltipSetItem) then
				local isShift = IsShiftKeyDown() and count > 1
				local displayPrice = isShift and sellPrice or sellPrice * count
				if isClassic then
					Tooltips.SetTooltipMoney(self, displayPrice, nil, SELL_PRICE_TEXT)
				elseif isWrath then
					if hasWrathTooltip then
						if isShift then
							overridePrice = displayPrice
						end
					else
						Tooltips.SetTooltipMoney(self, displayPrice, nil, SELL_PRICE_TEXT)
					end
				end
				self:Show()
			end
		end
	end
end

local function AddCompactVendorPrice(self, count, item)
	VP:SetPrice(self, false, "Compat", count, item, true)
end

GameTooltipHooks.SetAction = function(self, slot)
    if GetActionInfo(slot) == "item" then
        AddVendorPrice(self, true, "SetAction", GetActionCount(slot))
    end
end

GameTooltipHooks.SetAuctionItem = function(self, auctionType, index)
    local _, _, count = GetAuctionItemInfo(auctionType, index)
    AddVendorPrice(self, false, "SetAuctionItem", count)
end

GameTooltipHooks.SetAuctionSellItem = function(self)
    if (not GetAuctionSellItemInfo) then return end
    local _, _, count = GetAuctionSellItemInfo()
    AddVendorPrice(self, true, "SetAuctionSellItem", count)
end

GameTooltipHooks.SetBagItem = function(self, bag, slot)
    if (not C_Container or not C_Container.GetContainerItemInfo) then return end
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and info.stackCount then
        AddVendorPrice(self, true, "SetBagItem", info.stackCount)
    end
end

-- SetBagItemChild
-- SetBuybackItem -- already shown
-- SetCompareItem
GameTooltipHooks.SetCraftItem = function(self, index, reagent)
    if (not GetCraftReagentInfo or not GetCraftReagentItemLink) then return end
    local _, _, count = GetCraftReagentInfo(index, reagent)
     -- otherwise returns an empty link
    local itemLink = GetCraftReagentItemLink(index, reagent)
    AddVendorPrice(self, true, "SetCraftItem", count, itemLink)
end

GameTooltipHooks.SetCraftSpell = function(self)
    AddVendorPrice(self, true, "SetCraftSpell")
end

--SetHyperlink -- item information is not readily available
GameTooltipHooks.SetInboxItem = function(self, messageIndex, attachIndex)
    local count, itemID
    if attachIndex then
        count = select(4, GetInboxItem(messageIndex, attachIndex))
    else
        count, itemID = select(14, GetInboxHeaderInfo(messageIndex))
    end
    AddVendorPrice(self, false, "SetInboxItem", count, itemID)
end

GameTooltipHooks.SetInventoryItem = function(self, unit, slot)
    local count = (not CharacterBags[slot]) and GetInventoryItemCount(unit, slot) or nil
    if slot < FIRST_KEYRING_INVSLOT then
        AddVendorPrice(self, BankFrame:IsShown(), "SetInventoryItem", count)
    end
end

--SetInventoryItemByID
--SetItemByID
GameTooltipHooks.SetLootItem = function(self, slot)
    local _, _, count = GetLootSlotInfo(slot)
    AddVendorPrice(self, false, "SetLootItem", count)
end

GameTooltipHooks.SetLootRollItem = function(self, rollID)
    local _, _, count = GetLootRollItemInfo(rollID)
    AddVendorPrice(self, false, "SetLootRollItem", count)
end

--SetMerchantCostItem -- alternate currency
--SetMerchantItem -- already shown
GameTooltipHooks.SetQuestItem = function(self, questType, index)
    local _, _, count = GetQuestItemInfo(questType, index)
    AddVendorPrice(self, false, "SetQuestItem", count)
end

SetQuestLogItem = function(self, _, index)
    local _, _, count = GetQuestLogRewardInfo(index)
    AddVendorPrice(self, false, "SetQuestLogItem", count)
end

--SetRecipeReagentItem -- retail
--SetRecipeResultItem -- retail
SetSendMailItem = function(self, index)
    local count = select(4, GetSendMailItem(index))
    AddVendorPrice(self, true, "SetSendMailItem", count)
end

SetTradePlayerItem = function(self, index)
    local _, _, count = GetTradePlayerItemInfo(index)
    AddVendorPrice(self, true, "SetTradePlayerItem", count)
end

SetTradeSkillItem = function(self, index, reagent)
    local count
    if reagent then
        count = select(3, GetTradeSkillReagentInfo(index, reagent))
    else -- show minimum instead of maximum count
        count = GetTradeSkillNumMade(index)
    end
    AddVendorPrice(self, false, "SetTradeSkillItem", count)
end

SetTradeTargetItem = function(self, index)
    local _, _, count = GetTradeTargetItemInfo(index)
    AddVendorPrice(self, false, "SetTradeTargetItem", count)
end

SetTrainerService = function(self, index)
    AddVendorPrice(self, true, "SetTrainerService")
end

local Auctioneer = {
	AucAdvAppraiserFrame = function(self)
		local itemID = select(2, self:GetItem()):match("item:(%d+)")
		for _, v in pairs(AucAdvAppraiserFrame.list) do
			if v[1] == itemID then
				AddCompactVendorPrice(self, v[6])
				break
			end
		end
	end,
	AucAdvSearchUiAuctionFrame = function(self)
		local row = self:GetOwner():GetID()
		local count = AucAdvanced.Modules.Util.SearchUI.Private.gui.sheet.rows[row][4]
		AddCompactVendorPrice(self, tonumber(count:GetText()))
	end,
	AucAdvSimpFrame = function(self)
		AddCompactVendorPrice(self, AucAdvSimpFrame.detail[1])
	end,
}

function Tooltips:EnableVendorPrice()
    GameTooltip:HookScript("OnHide", function()
        overridePrice = nil
    end)

    ItemRefTooltip:HookScript("OnTooltipSetItem", function(self)
        local item = select(2, self:GetItem())
        if item then
            local sellPrice, classID = select(11, GetItemInfo(item))
            if sellPrice and sellPrice > 0 and not IsRecipe(self, classID, true) then
                Tooltips.SetTooltipMoney(self, sellPrice, nil, SELL_PRICE_TEXT)
            end
        end
    end)

    GameTooltip:HookScript("OnTooltipSetItem", function(self)
        if AucAdvanced and AuctionFrame:IsShown() then
            for name, func in pairs(Auctioneer) do
                local frame = _G[frame]
                if frame:IsShown() then
                    func(self)
                    break
                end
            end
        elseif AuctionFaster and VP:IsShown(AuctionFrame) and AuctionFrame.selectedTab >= 4 then
            local count
            if AuctionFrame.selectedTab == 4 then -- sell
                local item = self:GetOwner().item
                count = item and item.count
            elseif AuctionFrame.selectedTab == 5 then -- buy
                local hoverRowData = AuctionFaster.hoverRowData
                count = hoverRowData and hoverRowData.count -- provided by AuctionFaster
            end
            AddCompactVendorPrice(self, count)
        elseif AtlasLoot and VP:IsShown(_G["AtlasLoot_GUI-Frame"]) then
            AddCompactVendorPrice(self)
        else -- Chatter, Prat: check for active chat windows
            local mouseFocus = GetMouseFocus and GetMouseFocus()
            if mouseFocus and mouseFocus:GetObjectType() == "FontString" then
                for i = 1, FCF_GetNumActiveChatFrames() do
                    if _G["ChatFrame"..i]:IsMouseOver() then
                        AddCompactVendorPrice(self)
                        break
                    end
                end
            end
        end
    end)
end
