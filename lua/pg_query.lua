---@param s string 
---@return string
local function trim(s)
    if not s then
        return s
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param value string
---@param delim string
---@return string[]
local function split(value, delim)
    local parts = {}
    local pattern = "([^" .. delim .. "]+)"
    for part in value:gmatch(pattern) do
      table.insert(parts, part)
    end
    return parts
end

---@param file_path string
---@param mode string?
---@return file*
local function open_or_error(file_path, mode)
    local file = io.open(file_path, mode)
    if not file then
        error("Failed to open file for writing: " .. file_path)
    end
    return file
end

---@return string
local function temp_dir() 
    return vim.fn.stdpath("data") .. "/pg_query/"
end

---@param label string
---@return string
local function get_query_temp_path(label)
    return temp_dir() .. label
end


---@param command string
---@param mode string?
---@return boolean, string|"exit"|"signal"?
local function run_command(command, mode)
    local handle = io.popen(command, mode)
    if handle then
        local result = handle:read("*a")
        local success, reason, exit_code = handle:close()
        if success then
            return true, result
        else
            print("Command failed: " .. (reason or "unknown") .. "\nexit code: " .. exit_code)
            return false, reason
        end
    else
        print("Failed to start command " .. command)
        return false, nil
    end
end

--- @param binary_name string
local function ensure_binary_available(binary_name)
    local success, _ = run_command("which ".. binary_name)
    if not success then
        error(binary_name .. " not available, install " .. " or add it to your PATH")
    end
    return success
end

local function init()
    if not ensure_binary_available("pg_query_prepare") then
        return
    end
    local success, msg = run_command("mkdir -p " .. temp_dir())
    if not success then
        error("Could not create pg_query temp_dir: " .. msg)
    end
end


---@class FilePoint
---@field row number
---@field col number

---@param lines string[]
---@param cursor FilePoint
---@return FilePoint
local function getSqlStartCoord(lines, cursor)
    local row = cursor.row
    local col = cursor.col
    while row > 0 do
        local line = lines[row]
        while col > 0 do
            if line:sub(col, col) == ";" then
                return { row = row + 1, col = col}
            end
            col = col - 1
        end
        row = row - 1
        if row > 0 then
            col = #lines[row]
        end
    end
    return { row = 1, col = 0 } -- default to start of file if no semicolon is found
end

---@param lines string[]
---@param cursor FilePoint
---@return FilePoint
local function getSqlEndCoord(lines, cursor)
    local row = cursor.row
    local col = cursor.col
    while row <= #lines do
        local line = lines[row]
        while col <= #line do
            if line:sub(col, col) == ";" then
                return { row = row, col = col }
            end
            col = col + 1
        end
        row = row + 1
        col = 1
    end
    return { row = #lines, col = #lines[#lines] } -- default to end of file if no semicolon is found
end

---@return string
local function get_nearest_sql_command()
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local start_coord = getSqlStartCoord(lines, { row = cursor_row, col = cursor_col })
    local end_coord = getSqlEndCoord(lines, { row = cursor_row, col = cursor_col })
    local relevant_lines = {}
    for i = start_coord.row, end_coord.row do
        table.insert(relevant_lines, lines[i])
    end
    return trim(table.concat(relevant_lines, "\n"))
end

---@class QueryParam
---@field index integer
---@field field string 
---@field value any | nil

---@class QueryDetails
---@field label string
---@field params QueryParam[]

---@param query string
---@return QueryDetails
local function parse_query_details(query)
    local handle = io.popen("echo '" .. query .. "' | pg_query_prepare --details")
    if not handle then
        error("failed to get io handle in pg_query.write()")
    end
    local result = handle:read("*a")
    handle:close()
    local parts = split(result, " ")
    if #parts == 0 then
        error("invalid query: " .. result)
    end
    if #parts == 1 then
        return { label = trim(split(parts[1], "=")[2]), params = {} }
    end
    local label = trim(split(parts[1], "=")[2])
    local params_str = trim(split(parts[2], "=")[2])
    local param_parts = split(params_str, ",")
    local params = {}
    for _, param in ipairs(param_parts) do
        local ps = split(param, ":")
        local index = ps[1]
        local value = trim(ps[2]) or nil
        table.insert(params, {index=index, field=value})
    end
    return { label = label, params = params }
end

---@param query_details QueryDetails
local function save_query_details(query_details)
    if #query_details.params == 0 then
        return
    end
    local file_path = get_query_temp_path(query_details.label)
    local file = open_or_error(file_path, "w")
    if not file then
        error("Failed to open file for writing: " .. file_path)
    end
    for _, param in ipairs(query_details.params) do
    local line = string.format("%s,%s,%s", param.index, param.field, param.value or "")
        file:write(line .. "\n")
    end
    file:close()
    print("saved query details to " .. file_path)
end

---@param file_path string
---@return QueryParam[]
local function parse_query_param_values(file_path)
    local file = open_or_error(file_path)
    local params = {}
    for line in file:lines() do
        local parts = split(line, ",")
        local index = parts[1]
        local field = #parts > 1 and parts[2] or nil
        local value = #parts > 2 and parts[3] or nil
        table.insert(params, {index = index, field = field, value = value})
    end
    file:close()
    return params
end

local M = {}

function M.write()
    local query = get_nearest_sql_command()
    local details = parse_query_details(query)
    save_query_details(details)
end

function M.render()
    local query = get_nearest_sql_command()
    local label = parse_query_details(query).label
    local params = parse_query_param_values(get_query_temp_path(label))
    print("got params " .. vim.inspect(params))
    -- local command = "echo \"" .. query .. '"' .. " | " .. M.output_cmd
    -- run_command(command)
end

function M.setup(opts)
    opts = opts or {}
    M.output_cmd = opts.output_cmd or "pbcopy"
    init()
end

return M
