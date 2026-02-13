
--[[
                            ***PANDA***
* A simple vanilla wow addon that makes quick work of disenchanting.
* Panda provides an updating window with 1 click disenchant buttons for the equipment in your bags.
* Includes filters for bind on pickup, and an easy to use blacklist.
* Click on the minimap icon, or type /panda to learn more

TODO:
Minimap Icon [CHECK]
Init System [CHECK]
Query inventory
-tooltips
Onclick function
Casting Bar appearance
BoP filtering
Blacklisting

]]--
local libIcon = LibStub("LibDBIcon-1.0");
local libData = LibStub("LibDataBroker-1.1");

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
	elseif (event=="BAG_UPDATE") then
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
function PandaDEFrame_Update()

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
	info.tooltipTitle = PA_RARITY["uncommon"].name;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_SMART;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = PA_RARITY["rare"].name
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = PA_RARITY["rare"].value
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	info.tooltipTitle = PA_RARITY["uncommon"].name;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_ALWAYS;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = PA_RARITY["epic"].name
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = PA_RARITY["epic"].value
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	info.tooltipTitle = PA_RARITY["uncommon"].name;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_NEVER;
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
