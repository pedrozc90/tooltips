local addon, ns = ...

local Tooltips = CreateFrame("Frame")
Tooltips.GlobalHooks = {}
Tooltips.GameTooltipHooks = {}
Tooltips.ItemRefTooltipHooks = {}

Tooltips.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
Tooltips.isBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
Tooltips.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Tooltips.isWotLK = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)

ns.Tooltips = Tooltips
