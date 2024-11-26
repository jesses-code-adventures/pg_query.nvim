require("utils")
require("parse_from_vim")
require("parse_from_pg_query")
local edit_params_window = require("ui.window")

local function init()
    if not Ensure_binary_available("pg_query_prepare") then
        return
    end
    local success, msg = Run_command("mkdir -p " .. Get_temp_dir())
    if not success then
        error("Could not create pg_query temp_dir: " .. msg)
    end
end

---@param query_details QueryDetails
local function save_query_details(query_details)
    -- TODO: we need to check if there are existing values, and merge those with our details.
    --       this should include ensuring values are moved appropriately if the order of the arguments has changed.
    --       we could use the fingerprint, to essentially "invalidate the cache" on the stored values and perform the reordering process.
    --       there should also be an option to retain the values passed with query_details, in case they are newer than the values on disk.
    if #query_details.params == 0 then
        return
    end
    local file_path = Get_query_temp_path(query_details.label)
    local file = Open_or_error(file_path, "w")
    if not file then
        error("Failed to open file for writing: " .. file_path)
    end
    for _, param in ipairs(query_details.params) do
    local line = string.format("%s,%s,%s,%s", param.index, param.field, param.field_type or "", param.value or "")
        file:write(line .. "\n")
    end
    file:close()
    print(file_path)
end

---@param file_path string
---@return QueryParam[]
local function parse_query_param_values(file_path)
    local file = Open_or_error(file_path)
    local params = {}
    for line in file:lines() do
        local parts = Split(line, ",")
        local index = parts[1]
        local field = (#parts > 1 and #parts[2] > 0) and parts[2] or nil
        local field_type = (#parts > 2 and #parts[3] > 0) and parts[3] or nil
        -- TODO: currently if the value is an array, such as with IN statements, this will evaluate to a string which could be nicer.
        local value = (#parts > 3 and #parts[4] > 0) and table.concat(parts, ", ", 4) or nil
        table.insert(params, {index = index, field = field, field_type = field_type, value = value})
    end
    file:close()
    return params
end

---takes an sql query and a list of default params and replaces the query's placeholders with the values.
---@param query string
---@param params QueryParam[]
---@return string
local function render_inplace_placeholders(query, params)
    for _, param in ipairs(params) do
        if param.value == nil then
            param.value = "''" -- TODO: throw error when updating arguments is enabled
            -- error("expected a value for field \"" .. param.field .. "\" (argument index " .. param.index .. "), received nil.")
        end
        -- TODO: handle > single digit indexes
        local placeholder = " $" .. param.index .. ""
        query = query:gsub(placeholder, " " .. param.value .. " ")
    end
    return query
end

local M = {}

---@return QueryDetails?
local function write_query_details_from_editor()
    local query = Get_nearest_sql_command()
    local details = Parse_query_details(query)
    if details == nil then
        print("No query found")
        return nil
    end
    save_query_details(details)
    return details
end

function M.write()
    local details = write_query_details_from_editor()
    if details == nil then
        print("No query found")
        return
    end
    M.buf = edit_params_window.edit_query_values(details.params, {fields_align_right=M.fields_align_right, field_separator=M.field_separator})
end

function M.render()
    local query = Get_nearest_sql_command()
    local details = Parse_query_details(query)
    if details == nil then
        print("No query found")
        return
    end
    local file_path = Get_query_temp_path(details.label)
    local param_values = Exists(file_path) and parse_query_param_values(file_path) or {}
    local replaced = render_inplace_placeholders(query, param_values)
    local command = "echo \"" .. replaced .. '"' .. " | " .. M.output_cmd
    Run_command(command)
end

---@class PgQueryOpts
---@field output_cmd string @The CLI program to pipe your SQL queries into. Defaults to 'pbcopy'.
---@field field_separator string @The string separating the query values you're editing and the field name. Defaults to ' ✦ '.
---@field fields_align_right boolean @In the edit buffer, align the field names to the right of the buffer. Defaults to false.

---@param opts PgQueryOpts
function M.setup(opts)
    opts = opts or {}
    M.output_cmd = opts.output_cmd or "pbcopy"
    M.field_separator = opts.field_separator or " ✦ "
    M.fields_align_right = opts.fields_align_right or false
    init()
end

return M
