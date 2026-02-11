
--[[
                            ***PANDA***
* A simple vanilla wow addon that makes quick work of disenchanting.
* Panda provides an updating window with 1 click disenchant buttons for the equipment in your bags.
* Includes filters for bind on pickup, and an easy to use blacklist.
* Click on the minimap icon, or type /panda to learn more

]]--

--=UI Code=--
--TabPanel Code
function PandaBorder_OnLoad()
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
function PandaDEFrameQualityThresholdDropdown_OnLoad()
    UIDropDownMenu_Initialize(this, PandaDEFrameQualityThresholdDropdown_Initialize);
    UIDropDownMenu_SetSelectedValue(this,"1")
	UIDropDownMenu_SetWidth(90, PandaDEFrameQualityThresholdDropdown);
end

function PandaDEFrameQualityThresholdDropdown_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(PandaDEFrameQualityThresholdDropdown);
	local info;

	info = {};
	info.text = "|cFF1EFF00Uncommon|r";
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = "1"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	info.tooltipTitle = CAMERA_SMART;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_SMART;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "|cFF0070ddRare|r";
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = "2"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	info.tooltipTitle = CAMERA_ALWAYS;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_ALWAYS;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "|cffa335eeEpic|r";
	info.func = PandaDEFrameQualityThresholdDropdown_OnClick;
	info.value = "3"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	end
	info.tooltipTitle = CAMERA_NEVER;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_NEVER;
	UIDropDownMenu_AddButton(info);
end

function PandaDEFrameQualityThresholdDropdown_OnClick()
    UIDropDownMenu_SetSelectedValue(PandaDEFrameQualityThresholdDropdown, this.value);
	if ( UIDropDownMenu_GetSelectedID(UIOptionsFrameCameraDropDown) == 3 ) then
		--OptionsFrame_DisableSlider(UIOptionsFrameSlider2);
	else
		--OptionsFrame_EnableSlider(UIOptionsFrameSlider2);
	end
end

function PandaDEFrame_OnShow()

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
        PandaDEFrame:Show()
        PandaBorder:Show()
    elseif  arg == PA_OPT2 then
        PandaOptionsFrame:Show()
        PandaDEFrame:Hide()
    else
        DEFAULT_CHAT_FRAME:AddMessage(PA_SLASHUNKNOWN,1,0.3,0.3)
    end
end

SlashCmdList['PANDA'] = TextMenu
