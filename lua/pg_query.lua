---@param value string 
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

--- @param binary_name string
local function ensure_binary_available(binary_name)
    local handle = io.popen("which " .. binary_name)
    if not handle then
      error("Failed to get handle for binary: " .. binary_name)
      return false
    end
    local result = handle:read("*a")
    handle:close()
    if result == "" then
        print(binary_name .. " is not installed.")
        return false
    else
        return true
    end
end

local function init()
    if not ensure_binary_available("pg_query_fingerprint") then
        return
    end
    if not ensure_binary_available("pg_query_json") then
        return
    end
    if not ensure_binary_available("pg_query_prepare") then
        return
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
---
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

---@class QueryDetails
---@field fingerprint string
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
    return { fingerprint = trim(split(parts[1], "=")[2]), params = {} }
  end
  local fingerprint = trim(split(parts[1], "=")[2])
  local params_str = trim(split(parts[2], "=")[2])
  local param_parts = split(params_str, ",")
  local params = {}
  for _, param in ipairs(param_parts) do
    local ps = split(param, ":")
    local index = ps[1]
    local value = trim(ps[2]) or nil
    table.insert(params, {index=index, field=value})
  end
  return { fingerprint = fingerprint, params = params }
end


local M = {}

function M.write()
  local query = get_nearest_sql_command()
  local details = parse_query_details(query)
  print(vim.inspect(details))
end

function M.setup(opts)
    opts = opts or {}
    init()
end

return M
