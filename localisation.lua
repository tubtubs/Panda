PA_NAME     = "Panda"
PA_VERSION  = "0.1"
PA_FULLNAME = format("%s v%s", PA_NAME, PA_VERSION)

PA_MAXTABS = 2
PA_CAT1 = "Disenchanting"
PA_CAT2 = "Options"

PA_RARITY = {
    ["uncommon"] = {
        name = "|cFF1EFF00Uncommon|r",
        value = "1"
    },
    ["rare"] = {
        name = "|cFF0070ddRare|r",
        value = "2"
    },
    ["epic"] = {
        name = "|cffa335eeEpic|r",
        value = "3"
    }
}
PA_DEFAULT_RARITY = PA_RARITY["uncommon"].value