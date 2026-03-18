
--[[
                            ***PANDA***
* A simple vanilla wow addon that makes quick work of disenchanting.
* Panda provides an updating window with 1 click disenchant buttons for the equipment in your bags.
* Includes filters for bind on pickup, and an easy to use blacklist.
* Click on the minimap icon, or type /panda to learn more

TODO:
Minimap Icon [CHECK]
Init System [CHECK]
Query inventory [CHECK]
-tooltips [CHECK?]
Onclick function [CHECK]
Casting Bar appearance -> might be overrated
BoP filtering - managed to scan it with tooltips [CHECK]
Blacklisting - probably manageable [CHECK]
Make window movable[CHECK]
Need to be able to reset window position
-Slash command
-Minimap Icon Menu

]]--
local libIcon = LibStub("LibDBIcon-1.0");
local libData = LibStub("LibDataBroker-1.1");
local ClickedDEButton = 0;
local J = jKwery

--Event handler/init
function PandaBorder_OnEvent()
	if (event=="PLAYER_LOGIN") then -- Variables Loaded
		if (not PA_Vars) then
			PA_Vars = {
				DE_Filters = {
					BoP_toggle = false,
					BlackList_toggle = false,
					Blacklist = {},
					QualityThreshold = PA_DEFAULT_RARITY
				},
				hideMinimapIcon = false,
			}
		end
		if Panda_Icon == nil then
            Panda_Icon = {
                hide = false
            };
        end

		PA_MinimapIconRegister()
	elseif (event=="SPELLCAST_START") then
		if (arg1 == "Disenchant" and ClickedDEButton ~=0) then
			castBar = getglobal("PandaDEFrameDECastFrame".. ClickedDEButton .."_StatusBar")
			castFlashTex = getglobal("PandaDEFrameDECastFrame".. ClickedDEButton .."_OverText")
			castFrame = getglobal("PandaDEFrameDECastFrame".. ClickedDEButton)
			castBar:SetValue(0)
			castBar:SetStatusBarColor(0.3, 0.6, 1)
			castFlashTex:SetVertexColor(1, 1, 1, 0)
			--castLabel:SetText(arg1)	
			J:Sequence({
				J:Progress(castBar, 0, 0),
				J:FadeIn(castFrame, 0.2),

				-- Cast 1: Frostbolt fills to 100%
				J:Progress(castBar, 100, 2.8, "linear"),

				-- Success: green flash then turn bar green
				J:Group({
				J:Tween(castFlashTex, {
					type = "color", from = {0.2,1,0.4,0}, to = {0.2,1,0.4,0.6}, duration = 0.08,
				}),
				J:Tween(castFlashTex, {
					type = "color", from = {0.2,1,0.4,0.6}, to = {0.2,1,0.4,0}, duration = 0.3,
					onStart = function() castBar:SetStatusBarColor(0.2, 1, 0.4) end,
				}),
				}),
				J:Delay(0.5),
				J:FadeOut(castFrame, 0.3),
			})
		end
	elseif (event=="SPELLCAST_STOP") then
		castFrame = getglobal("PandaDEFrameDECastFrame".. ClickedDEButton)
		if castFrame and not castFrame:IsShown() then
			ClickedDEButton = 0
		end
	elseif (event=="SPELLCAST_INTERRUPTED") then
		if ClickedDEButton ~= 0 then
			castBar = getglobal("PandaDEFrameDECastFrame".. ClickedDEButton .."_StatusBar")
			castFlashTex = getglobal("PandaDEFrameDECastFrame".. ClickedDEButton .."_OverText")
			castFrame = getglobal("PandaDEFrameDECastFrame".. ClickedDEButton)
			J:Sequence({
			-- Interrupt: red flash + shake + label change
				J:Group({
				J:Shake(castFrame, 5, 0.4),
				J:Sequence({
					J:Tween(castFlashTex, {
					type = "color", from = {1,0.1,0.1,0}, to = {1,0.1,0.1,0.7}, duration = 0.07,
					}),
					J:Tween(castFlashTex, {
					type = "color", from = {1,0.1,0.1,0.7}, to = {1,0.1,0.1,0}, duration = 0.4,
					}),
				}),
				J:Tween(castFrame, {
					type = "custom", from = 0, to = 0, duration = 0.01,
					setter = function()
					castBar:SetStatusBarColor(1, 0.2, 0.2)
					--castLabel:SetText("Interrupted!")
					end,
				}),
				J:Delay(0.8),
				J:FadeOut(castFrame, 0.3),
				J:Stop(),
				}),
			})
			ClickedDEButton = 0;
		end
	elseif (event=="BAG_UPDATE") then
		if PandaDEFrame:IsShown() then
			PandaDEFrame_Update()
		end
	end
end



--Minimap Button Setup
function PA_MinimapIconRegister()
    local iconData = libData:NewDataObject("Panda icon data", {
        OnClick = function()
            if PandaBorder:IsShown() then
                PandaBorder:Hide();
            else
                PandaBorder:Show();
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText(PA_FULLNAME);
        end,
        icon = [[Interface\Addons\Panda\Assets\Panda.blp]]
    });

    libIcon:Register("Panda icon", iconData, Panda_Icon);
end

--=UI Code=--
--Border Code
function PandaBorder_OnShow()
	-- if no subframe is shown, default to the DE one.
	if not PandaDEFrame:IsShown() and not PandaOptionsFrame:IsShown() then
		PandaDEFrame:Show()
	end
end
--TabPanel Code
function PandaBorder_OnLoad()
	this:RegisterEvent("PLAYER_LOGIN");
	this:RegisterEvent("BAG_UPDATE");
	this:RegisterEvent("SPELLCAST_START")
	this:RegisterEvent("SPELLCAST_STOP")
	this:RegisterEvent("SPELLCAST_INTERRUPTED")

    PanelTemplates_SetNumTabs(this, PA_MAXTABS);
end

function PandaBorderButton_OnClick()
    id = this:GetID()
    if (id == 1) then
        PandaOptionsFrame:Hide()
        PandaDEFrame:Show()
    elseif (id==2) then
        PandaOptionsFrame:Show()
        PandaDEFrame:Hide()
    end
end

function PandaPanel_OnShow()
	PanelTemplates_SetTab(PandaBorder, this:GetID());
end

--DE Code
PA_DEBUTTONS_NUM = 6
NUM_BAG_SLOTS = 4
PA_DEItemList = {}
PA_DENumItems = 0

function PA_DEButtonTooltip()
	local scrollOffset = FauxScrollFrame_GetOffset(PandaDEFrameDEScrollFrame);
	id = this:GetID()
	itemID = PA_DEItemList[id + scrollOffset].id
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
	GameTooltip:SetBagItem(PA_DEItemList[id + scrollOffset].bag,
	PA_DEItemList[id + scrollOffset].slot);
	GameTooltip:Show();
end

function PA_GetColor(rarity)
	for i,j in pairs(PA_RARITY) do
		if tonumber(j.value) == rarity then
			return j.color
		end
	end
end

function PandaDEFrame_Update()
	--get item list
	Panda_GetAllItemsFromBag()
	PA_DENumItems = getn(PA_DEItemList)
	local scrollOffset = FauxScrollFrame_GetOffset(PandaDEFrameDEScrollFrame);
	local index;

	--start changing display buttons

	for i=1, PA_DEBUTTONS_NUM do
		buttontxt = getglobal("PandaDEFrameDEButton"..i.."Name");
		button = getglobal("PandaDEFrameDEButton"..i);
		buttonicon = getglobal("PandaDEFrameDEButton"..i.."Icon");
		blacklistButton = getglobal("PandaDEFrameBlackListButton"..i)
		blacklistButton:Hide();
		index = (scrollOffset) + i;
		if index <= PA_DENumItems then
			button:Show()
			color = PA_GetColor(PA_DEItemList[index].rarity)
			buttonicon:SetTexture(PA_DEItemList[index].icon)
			buttontxt:SetText(color .. PA_DEItemList[index].name)
		else
			button:Hide()
		end
	end
	FauxScrollFrame_Update(PandaDEFrameDEScrollFrame, PA_DENumItems , PA_DEBUTTONS_NUM, PA_DEBUTTONS_NUM);
	if PA_DENumItems ~= 0 then
		PandaDEFrameEmptyList:Hide()
	else
		PandaDEFrameEmptyList:Show()
	end
end

function Panda_GetAllItemsFromBag()
	PA_DEItemList = {}
	for slot=0, NUM_BAG_SLOTS do
		for index=1, GetContainerNumSlots(slot) do
			--local item = GetContainerItemLink(0, index)
			if(GetContainerItemLink(slot, index)) then
				--print(item)
				local _, _, itemID = string.find(GetContainerItemLink(slot,index), "item:(%d+):%d+:%d+:%d+")
				local texture, _, _, quality, _, _, _ = GetContainerItemInfo(slot,index)
				--local durMin, durMax = GetContainerItemDurability(slot, index)
				-- texture, itemCount, locked, quality, readable, lootable, itemLink
				--DEFAULT_CHAT_FRAME:AddMessage(itemID)
				if(itemID ~= nil) then
					found = 0
					if PA_Vars.DE_Filters.BlackList_toggle then
						for i=1, getn(PA_Vars.DE_Filters.Blacklist) do
								--DEFAULT_CHAT_FRAME:AddMessage(format("%s",i))
							if PA_Vars.DE_Filters.Blacklist[i] == itemID then
								found = 1
								break
							end
						end
					end

					--print(itemID)
					local itemName, _, itemRarity, _, _, itemType, itemSubType, itemEquipLoc, _, _, _ = GetItemInfo(itemID)
					if PA_Vars.DE_Filters.BoP_toggle then
						GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
						GameTooltip:SetBagItem(slot, index)
						for i = 1, GameTooltip:NumLines() do
							local leftText = getglobal("GameTooltipTextLeft" .. i):GetText()
							--DEFAULT_CHAT_FRAME:AddMessage(leftText)
							if leftText == "Soulbound" then
								found = 1
								break
								--DEFAULT_CHAT_FRAME:AddMessage(itemName .. "Item is Soulbound")
							end
						end
						GameTooltip:Hide()
					end
					-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice
					--DEFAULT_CHAT_FRAME:AddMessage(itemName)
					--table.insert(Insert, {index = index, itemID = itemID, itemSellPrice = itemSellPrice, itemName = itemName})
					if (found == 0 and itemEquipLoc~= "" and itemEquipLoc~= "INVTYPE_TABARD" and itemEquipLoc~= "INVTYPE_BODY" 
					and itemEquipLoc~= "INVTYPE_BAG" and itemEquipLoc~= "INVTYPE_QUIVER"
					and itemEquipLoc~= "INVTYPE_AMMO" ) then
						if tonumber(PA_Vars.DE_Filters.QualityThreshold) <= quality
							and tonumber(PA_RARITY["common"].value) < quality
							and quality ~= tonumber(PA_RARITY["legendary"].value) then
						info = {
							bag = slot,
							slot = index,
							id = itemID, 
							name = itemName,
							icon = texture,
							rarity = quality,
						}
						table.insert(PA_DEItemList, info)
						--DEFAULT_CHAT_FRAME:AddMessage(format("itemID: %s itemName: %s itemType: %s itemSubType: %s quality: %s texture: %s", itemID, itemName, itemType, itemEquipLoc, quality, texture))
						end
					end
					--DEFAULT_CHAT_FRAME:AddMessage(format("%s %s %s", a, b ,itemName))
				end
			end
		end
	end
	--DEFAULT_CHAT_FRAME:AddMessage(format("Size: %s", getn(PA_DEItemList)))
end

function PandaDEFrameQualityThresholdDropdown_OnLoad()
    UIDropDownMenu_Initialize(this, PandaDEFrameQualityThresholdDropdown_Initialize);
	--if (PA_Vars) then --if its first run just load the default rarity
    --	UIDropDownMenu_SetSelectedValue(this,PA_Vars.DE_Filters.QualityThreshold)
	--else
	--	UIDropDownMenu_SetSelectedValue(this,PA_DEFAULT_RARITY)
	--end
	UIDropDownMenu_SetWidth(90, PandaDEFrameQualityThresholdDropdown);
end

function PandaDEFrameQualityThresholdDropdown_Initialize()
	--local selectedValue = UIDropDownMenu_GetSelectedValue(PandaDEFrameQualityThresholdDropdown);
	--if (PA_Vars) then --if its first run just load the default rarity
    --	selectedValue = PA_Vars.DE_Filters.QualityThreshold
	--else
	--	selectedValue = PA_DEFAULT_RARITY
	--end
	
	local info;

	info = {};
	info.text = PA_RARITY["uncommon"].name;
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = PA_RARITY["uncommon"].value
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = PA_RARITY["rare"].name
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = PA_RARITY["rare"].value
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = PA_RARITY["epic"].name
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = PA_RARITY["epic"].value
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	UIDropDownMenu_AddButton(info);
end

function PandaDEFrameQualityThresholdDropdown_OnClick()
    UIDropDownMenu_SetSelectedValue(PandaDEFrameQualityThresholdDropdown, this.value);
	PA_Vars.DE_Filters.QualityThreshold = this.value;
	PandaDEFrame_Update() -- going to need to update buttons after changing threshold
end

function PandaDEFrame_OnShow()
	--Settings
	--BOP
	if PA_Vars.DE_Filters.BoP_toggle then
		PandaDEFrameBOPFilterCheckButton:SetChecked(1)
	else
		PandaDEFrameBOPFilterCheckButton:SetChecked(0)
	end
	--Blacklist
	if PA_Vars.DE_Filters.BlackList_toggle then
		PandaDEFrameBlacklistFilterCheckButton:SetChecked(1)
	else
		PandaDEFrameBlacklistFilterCheckButton:SetChecked(0)
	end
	--Rarity threshold
	UIDropDownMenu_Initialize(this, PandaDEFrameQualityThresholdDropdown_Initialize);
	UIDropDownMenu_SetSelectedValue(PandaDEFrameQualityThresholdDropdown, PA_Vars.DE_Filters.QualityThreshold)
	UIDropDownMenu_SetWidth(90, PandaDEFrameQualityThresholdDropdown);
	PandaDEFrame_Update()
end


function PandaDEFrameBOPFilterCheckButton_OnClick()
	PA_Vars.DE_Filters.BoP_toggle = not PA_Vars.DE_Filters.BoP_toggle
	PandaDEFrame_Update()
end

function PandaDEFrameBlackListFilterCheckButton_OnClick()
	PA_Vars.DE_Filters.BlackList_toggle = not PA_Vars.DE_Filters.BlackList_toggle
	PandaDEFrame_Update()
end

function PandaDEButton_OnClick()
	local scrollOffset = FauxScrollFrame_GetOffset(PandaDEFrameDEScrollFrame);
	id = this:GetID()
	ClickedDEButton = id
	item = PA_DEItemList[id + scrollOffset]
	blacklistButton = getglobal("PandaDEFrameBlackListButton"..id)
	if arg1 == 'LeftButton' then
		CastSpellByName("Disenchant")
		PickupContainerItem(item.bag, item.slot)
		PA_HideAllBlackListButtons()
	end
end

function PA_HideAllBlackListButtons()
	for i=1, PA_DEBUTTONS_NUM do
		blacklistButton = getglobal("PandaDEFrameBlackListButton"..i)
		blacklistButton:Hide()
	end
end

function PandaDEButton_OnMouseDown()
	id = this:GetID()
	if arg1 == 'RightButton' then
		PA_HideAllBlackListButtons()
		blacklistButton = getglobal("PandaDEFrameBlackListButton"..id)
		blacklistButton:Show()
	end
end

function PandaDEFrameBlackListButton_OnShow()
	id = this:GetID()
	blacklistButton = getglobal("PandaDEFrameBlackListButton"..id)
	if not PA_Vars.DE_Filters.BlackList_toggle then
		local scrollOffset = FauxScrollFrame_GetOffset(PandaDEFrameDEScrollFrame);
		id = this:GetID()
		item = PA_DEItemList[id + scrollOffset]
		found = 0
		for i=1, getn(PA_Vars.DE_Filters.Blacklist) do
			if PA_Vars.DE_Filters.Blacklist[i] == itemID then
				found = 1
				break
			end
		end
		if found == 1 then
			blacklistButton:SetNormalTexture([[Interface\Addons\Panda\Assets\undoblacklist.tga]])
			blacklistButton:SetScript("OnMouseDown",PandaDEFrameBlackListButton_UnBlackList)
			blacklistButton:SetScript("OnEnter",PandaDEFrameBlackListButton_UnBlackListTooltip)
		else
			blacklistButton:SetNormalTexture([[Interface\Addons\Panda\Assets\blacklist.tga]])
			blacklistButton:SetScript("OnMouseDown",PandaDEFrameBlackListButton_BlackList)
			blacklistButton:SetScript("OnEnter",PandaDEFrameBlackListButton_BlackListTooltip)
		end
	else
		blacklistButton:SetNormalTexture([[Interface\Addons\Panda\Assets\blacklist.tga]])
		blacklistButton:SetScript("OnMouseDown",PandaDEFrameBlackListButton_BlackList)
		blacklistButton:SetScript("OnEnter",PandaDEFrameBlackListButton_BlackListTooltip)
	end
end

function PandaDEFrameBlackListButton_BlackListTooltip()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
	GameTooltip:SetText(PA_BLACKLISTBTN_TOOLTIP);
	GameTooltip:Show()
end

function PandaDEFrameBlackListButton_UnBlackListTooltip()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
	GameTooltip:SetText(PA_UNBLACKLISTBTN_TOOLTIP);
	GameTooltip:Show()
end

function PandaDEFrameBlackListButton_BlackList()
	local scrollOffset = FauxScrollFrame_GetOffset(PandaDEFrameDEScrollFrame);
	id = this:GetID()
	item = PA_DEItemList[id + scrollOffset]
	if arg1 == 'LeftButton' then
		this:Hide()
	elseif arg1 == 'RightButton' then
		table.insert(PA_Vars.DE_Filters.Blacklist,item.id)
		this:Hide()
		PandaDEFrame_Update()
	end
end

function PandaDEFrameBlackListButton_UnBlackList()
	local scrollOffset = FauxScrollFrame_GetOffset(PandaDEFrameDEScrollFrame);
	id = this:GetID()
	item = PA_DEItemList[id + scrollOffset]
	if arg1 == 'LeftButton' then
		this:Hide()
	elseif arg1 == 'RightButton' then
		for i=1, getn(PA_Vars.DE_Filters.Blacklist) do
				--DEFAULT_CHAT_FRAME:AddMessage(format("%s",i))
			if PA_Vars.DE_Filters.Blacklist[i] == itemID then
				found = i
				break
			end
		end
		table.remove(PA_Vars.DE_Filters.Blacklist,found)
		this:Hide()
		PandaDEFrame_Update()
	end
end

--Slash command setup
SLASH_PANDA1 = '/Panda'
SLASH_PANDA2 = '/Pa'
PA_OPT1 = "show"
PA_OPT2 = "options"

PA_HELP0 = "|cFF00FF00" .. PA_NAME .. ":|r This is the help topic for |cFFFFFF00".. SLASH_PANDA1 .. " " ..
                    SLASH_PANDA2  .. ".|r\n"
PA_HELP1 = "|cFFFFFF00 " ..SLASH_PANDA2.. " " .. PA_OPT1 ..
"|r - Shows the morph helper window.\n"
PA_HELP2 = "|cFFFFFF00 " ..SLASH_PANDA2.. " " .. PA_OPT2 ..
"|r - Shows the morph helper window.\n"

PA_HELP = PA_HELP0 .. PA_HELP1 .. PA_HELP2
PA_SLASHUNKNOWN = "|cFF00FF00".. PA_NAME .. ":|r unknown command. Type" ..SLASH_PANDA1 .. " for commands"


local function TextMenu(arg)
    arg = string.lower(arg)
    if arg == "" then --print help
        for w in string.gfind(PA_HELP, "([^\r\n]+)") do
            DEFAULT_CHAT_FRAME:AddMessage(w,1,1,1)
        end
    elseif arg == PA_OPT1 then
        --PandaDEFrame:Show()
        PandaBorder:Show()
    elseif  arg == PA_OPT2 then
        PandaOptionsFrame:Show()
        PandaDEFrame:Hide()
    else
        DEFAULT_CHAT_FRAME:AddMessage(PA_SLASHUNKNOWN,1,0.3,0.3)
    end
end

SlashCmdList['PANDA'] = TextMenu
