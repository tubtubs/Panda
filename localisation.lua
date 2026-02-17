PA_NAME     = "Panda"
PA_VERSION  = "0.1"
PA_FULLNAME = format("%s v%s", PA_NAME, PA_VERSION)

PA_MAXTABS = 2
PA_CAT1 = "Disenchanting"
PA_CAT2 = "Options"

PA_BLACKLISTBTN_TOOLTIP = "Right click again to blacklist this item.\nLeft click to cancel."
PA_UNBLACKLISTBTN_TOOLTIP = "Right click again to unblacklist this item.\nLeft click to cancel."
PA_DEEMPTY_TOOLTIP = "No equipment found, check filters and inventory."
PA_DE_TOOLTIP = "Click an item to disenchant.\nRight click an item to blacklist."

PA_RARITY = {
    ["poor"] = {
        color = "|cff9d9d9d",
        name = "|cff9d9d9dPoor|r",
        value = "0"
    },
    ["common"] = {
        color = "|cffffffff",
        name = "|cffffffffCommon|r",
        value = "1"
    },
    ["uncommon"] = {
        color = "|cff1eff00",
        name = "|cFF1EFF00Uncommon|r",
        value = "2"
    },
    ["rare"] = {
        color = "|cff0070dd",
        name = "|cFF0070ddRare|r",
        value = "3"
    },
    ["epic"] = {
        color = "|cffa335ee",
        name = "|cffa335eeEpic|r",
        value = "4"
    },
    ["legendary"] = {
        color = "|cffff8000",
        name = "|cffff8000Epic|r",
        value = "5"
    }
}
PA_DEFAULT_RARITY = PA_RARITY["uncommon"].value