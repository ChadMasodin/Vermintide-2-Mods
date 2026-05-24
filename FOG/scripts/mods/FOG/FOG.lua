local mod = get_mod("FOG") --Get the mod

local pt = mod:persistent_table("pt", {init = true}) --Create/Get a VMF persistent table so we can know when we first load 
if pt.init then
	--Get the highest sort_order
	local highestSortOrder = 0
	for _,area in pairs(AreaSettings) do
		if area.sort_order and area.sort_order > highestSortOrder then
			highestSortOrder = area.sort_order
		end
	end
	AreaSettings.celebrate.sort_order = highestSortOrder+1 --Let's give the The Feast of Grimnir area the next sort_order
	
	--Manually load the package containing the video material so that it doesn't get unloaded when the mod is unloaded
    local mod_handle = mod:get_internal_data("mod_handle")
	resource_handle = Mod.resource_package(mod_handle, "resource_packages/FOG/AQD_video_material")
	resource_handle:load()
	if not resource_handle:has_loaded() then resource_handle:flush() end

	pt.init = false
end

--Let's give the A Quiet Drink area some proper info
AreaSettings.celebrate.video_settings = {
	material_name = "area_video_celebrate",
	resource = "video/area_video_celebrate"
}
AreaSettings.celebrate.display_name = "level_name_dlc_dwarf_fest"
AreaSettings.celebrate.description_text = "nco_dal_loading_screen_a_02"
AreaSettings.celebrate.level_image = "level_image_dlc_dwarf_fest"
AreaSettings.celebrate.menu_sound_event = "Play_hud_menu_area_dwarf"
AreaSettings.celebrate.long_description_text = "nco_dal_loading_screen_a_02"

--Make it not be excluded
AreaSettings.celebrate.exclude_from_area_selection = false

ActSettings.act_celebrate.display_name = "level_name_dlc_dwarf_fest"

LevelSettings.dlc_dwarf_fest.description_text = "nco_dal_loading_screen_a_01"
LevelSettings.dlc_celebrate_crawl.description_text = "nik_loading_screen_crawl_01"
LevelSettings.dlc_celebrate_crawl.loot_objectives = { --There are no tomes or grims in this mission
	loot_die = 0,
	tome = 0,
	grimoire = 0,
	painting_scrap = 3
}

if not DLCSettings.celebrate.additional_settings.buff then
	mod:dofile("scripts/mods/FOG/AQD_fix_buff")
end

if not GameActs.act_celebrate then
	GameActs.act_celebrate = {
        "dlc_celebrate_crawl"
	}
end

if not rawget(NetworkLookup.act_keys,"dlc_celebrate_crawl") then
	NetworkLookup.act_keys[#NetworkLookup.act_keys+1] = "dlc_celebrate_crawl"
	NetworkLookup.act_keys.dlc_celebrate_crawl = #NetworkLookup.act_keys
end

if not rawget(NetworkLookup.unlockable_level_keys,"dlc_celebrate_crawl") then
	NetworkLookup.unlockable_level_keys[#NetworkLookup.unlockable_level_keys+1] = "dlc_celebrate_crawl"
	NetworkLookup.unlockable_level_keys.dlc_celebrate_crawl = #NetworkLookup.unlockable_level_keys
end

local level_game_mode = "adventure"
if not table.find(UnlockableLevelsByGameMode[level_game_mode], "dlc_celebrate_crawl") then
	UnlockableLevelsByGameMode[level_game_mode][#UnlockableLevelsByGameMode[level_game_mode] + 1] = "dlc_celebrate_crawl"
end

if not table.find(MapPresentationActs, "act_celebrate") then
	MapPresentationActs[#MapPresentationActs + 1] = "act_celebrate"
end

if not table.find(UnlockableLevels, "dlc_celebrate_crawl") then
	UnlockableLevels[#UnlockableLevels+1] = "dlc_celebrate_crawl"
	mod:dofile("scripts/mods/FOG/AQD_fix_statistics")
end

mod.on_all_mods_loaded = function()
	local scoreboard_extension = get_mod("scoreboard_extension") --Get the scoreboard_extension mod

	if scoreboard_extension then
		mod:dofile("scripts/mods/FOG/AQD_stat_tracking")
	end
end