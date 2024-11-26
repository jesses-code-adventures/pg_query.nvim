local utils = require("utils")
local from_vim_sql = require("parse_from_vim.sql")
local edit_params_window = require("ui.window")

local function init()
    if not utils.Ensure_binary_available("pg_query_prepare") then
        return
    end
    local success, msg = utils.Run_command("mkdir -p " .. utils.Get_temp_dir())
    if not success then
        error("Could not create pg_query temp_dir: " .. msg)
    end
end

---@class QueryParam
---@field index integer
---@field field string 
---@field field_type string?
---@field value any | nil

---@class QueryDetails
---@field label string
---@field fingerprint string
---@field params QueryParam[]


--- takes a string containing key-value pairs with an arbitrary delimiter (defaults to " ") 
---@param details string[]
---@param key string
---@param key_value_delimiter string
---@return string?
local function parse_field_from_details(details, key, key_value_delimiter)
    for _, part in ipairs(details) do
        local lil_parts = utils.Split(part, key_value_delimiter)
        local k = lil_parts[1]
        local value = table.concat(lil_parts, key_value_delimiter, 2)
        if key == k and value ~= nil then
            return utils.Trim(value)
        end
    end
    return nil
end

---@param result string
---@return string[]
local function split_details_output(result)
    local resp = {}
    local details = utils.Split(result, " ", 4)
    if #details == 0 then
        return resp
    end
    for _, deet in ipairs(details) do
        table.insert(resp, utils.Trim(deet))
    end
    return resp
end

---@return QueryParam[]
local function parse_params_list_from_details(params_str)
    -- TODO: handle parsing values that contain commas within quotes or parentheses
    local params = {}
    local param_parts = utils.Split(params_str, ",")
    for _, param in ipairs(param_parts) do
        local ps = utils.Split(param, ":")
        local index = ps[1]
        local field = utils.Trim(ps[2]) or nil
        local field_type = utils.Trim(ps[3]) or nil
        table.insert(params, {index=index, field=field, field_type=field_type})
    end
    return params
end

---@param query string
---@return QueryDetails?
local function parse_query_details(query)
    local handle = io.popen("echo '" .. query .. "' | pg_query_prepare --details")
    if not handle then
        error("failed to get io handle in pg_query.write()")
    end
    local result = handle:read("*a")
    handle:close()
    local details = split_details_output(result)
    if #details == 0 then
        return nil
    end
    local label = parse_field_from_details(details, "query", "=")
    local fingerprint = parse_field_from_details(details, "fingerprint", "=")
    local params_str = parse_field_from_details(details, "params", "=")
    if params_str == nil then
        return { label = label, fingerprint = fingerprint, params = {} }
    end
    return { label = label, fingerprint = fingerprint, params = parse_params_list_from_details(params_str) }
end

---@param query_details QueryDetails
local function save_query_details(query_details)
    if #query_details.params == 0 then
        return
    end
    local file_path = utils.Get_query_temp_path(query_details.label)
    local file = utils.Open_or_error(file_path, "w")
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
    local file = utils.Open_or_error(file_path)
    local params = {}
    for line in file:lines() do
        local parts = utils.Split(line, ",")
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
function M.write()
    local query = from_vim_sql.Get_nearest_sql_command()
    local details = parse_query_details(query)
    if details == nil then
        print("No query found")
        return nil
    end
    save_query_details(details)
    return details
end

function M.edit_params()
    local details = M.write()
    if details == nil then
        print("No query found")
        return
    end
    M.buf = edit_params_window.show_query_params(details.params)
end

function M.restore_lines()
    edit_params_window.restore_lines(M.buf)
end

function M.render()
    local query = from_vim_sql.Get_nearest_sql_command()
    local details = parse_query_details(query)
    if details == nil then
        print("No query found")
        return
    end
    local file_path = utils.Get_query_temp_path(details.label)
    local param_values = utils.Exists(file_path) and parse_query_param_values(file_path) or {}
    local replaced = render_inplace_placeholders(query, param_values)
    local command = "echo \"" .. replaced .. '"' .. " | " .. M.output_cmd
    utils.Run_command(command)
end

function M.setup(opts)
    opts = opts or {}
    M.output_cmd = opts.output_cmd or "pbcopy"
    init()
end

return M
