local utils = require("utils")

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

local M = {}

---@return string
function M.Get_nearest_sql_command()
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local start_coord = getSqlStartCoord(lines, { row = cursor_row, col = cursor_col })
    local end_coord = getSqlEndCoord(lines, { row = cursor_row, col = cursor_col })
    local relevant_lines = {}
    for i = start_coord.row, end_coord.row do
        table.insert(relevant_lines, lines[i])
    end
    return utils.Trim(table.concat(relevant_lines, "\n"))
end

return M
