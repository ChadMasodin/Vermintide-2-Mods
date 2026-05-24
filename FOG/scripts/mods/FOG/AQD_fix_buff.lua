local mod = get_mod("FOG") --Get the mod

mod:dofile("scripts/settings/dlcs/celebrate/celebrate_buff_settings")

local dlc = DLCSettings.celebrate
local buff_templates = dlc.buff_templates

--Add dlc buff templates
if buff_templates then
	table.merge_recursive(BuffTemplates, buff_templates)
end

local add_sub_buffs_to_core_buffs = dlc.add_sub_buffs_to_core_buffs

if add_sub_buffs_to_core_buffs then
	for i = 1, #add_sub_buffs_to_core_buffs, 1 do
		local data = add_sub_buffs_to_core_buffs[i]
		BuffTemplates[data.buff_name].buffs[#BuffTemplates[data.buff_name].buffs + 1] = data.sub_buff_to_add
	end
end

--Add dlc buff function templates
local buff_function_templates = dlc.buff_function_templates

if buff_function_templates then
	for name, buff_function in pairs(buff_function_templates) do
		BuffFunctionTemplates.functions[name] = buff_function
	end
end

--Add dlc group buff templates
local group_buff_templates = dlc.group_buff_templates

if group_buff_templates then
	table.merge_recursive(GroupBuffTemplates, group_buff_templates)
end

local sorted_bt_keys = table.keys(buff_templates)
local sorted_gbt_keys = table.keys(group_buff_templates)

table.sort(sorted_bt_keys)
table.sort(sorted_gbt_keys)

mod:info("#NetworkLookup.buff_templates: " .. tostring(#NetworkLookup.buff_templates))
for i,buff_name in ipairs(sorted_bt_keys) do
	NetworkLookup.buff_templates[buff_name] = 1000 + (i-1)
	NetworkLookup.buff_templates[1000 + (i-1)] = buff_name
	mod:info("bt: " .. tostring(NetworkLookup.buff_templates[buff_name]) .. " " .. buff_name)
end

mod:info("#NetworkLookup.group_buff_templates: " .. tostring(#NetworkLookup.group_buff_templates))
for i,buff_name in ipairs(sorted_gbt_keys) do
	NetworkLookup.group_buff_templates[buff_name] = 1000 + (i-1)
	NetworkLookup.group_buff_templates[1000 + (i-1)] = buff_name
	mod:info("gbt: " .. tostring(NetworkLookup.group_buff_templates[buff_name]) .. " " .. buff_name)
end

for buff_name,_ in pairs(buff_templates) do
	mod:info("2 bt: " .. buff_name)
end

for buff_name,_ in pairs(group_buff_templates) do
	mod:info("2 gbt: " .. buff_name)
end