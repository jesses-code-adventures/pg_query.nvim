require("utils")

---Save query details to the disk.
---Parameter values are not saved here, this is the file representing the query itself.
---@param query_details QueryDetails?
local function save_query_details_no_params(file_path, query_details)
    if not query_details then
        return
    end
    local file = Open_or_error(file_path, "w")
    if not file then
        error("Failed to open file for writing: " .. file_path)
    end
    if query_details.params_variant then
        for _, param in ipairs(query_details.params) do
            file:write(param.value .. "\n")
        end
        return
    end
    for _, param in ipairs(query_details.params) do
        local line = string.format("%s,%s,%s", param.index, param.field, param.field_type or "")
        file:write(line .. "\n")
    end
    file:close()
end

---@param file_path string
---@return QueryParam[]
local function Parse_query_file(file_path)
    local file = Open_or_error(file_path)
    local params = {}
    for line in file:lines() do
        local parts = Split(line, ",")
        local index = parts[1]
        local field = (#parts > 1 and #parts[2] > 0) and parts[2] or nil
        local field_type = (#parts > 2 and #parts[3] > 0) and parts[3] or nil
        table.insert(params, {index = index, field = field, field_type = field_type})
    end
    file:close()
    return params
end


---@param query_details table @The query_details table to update.
---@param index integer @The index of the param to update.
---@param new_value any @The new value to set.
local function update_query_param(query_details, index, new_value)
    for _, param in ipairs(query_details.params) do
        if tonumber(param.index) == tonumber(index) then
            param.value = new_value
            return true
        end
    end
    return false
end

---@param file_path string
---@param details QueryDetails
function Parse_query_values(file_path, details)
    local file = Open_or_error(file_path)
    local lines = file:lines()
    local i = 1
    for line in lines do
        if i <= #details.params then
            local success = update_query_param(details, i, line)
            if not success then
                error("failed to update param " .. i .. " with line " .. line)
            end
        end
        i = i + 1
    end
    file:close()
    return true
end

---@param file_path string?
---@param details QueryDetails?
---@return QueryDetails?
function Write_query_details_no_params(file_path, details)
    if details == nil then
        print("No query found")
        return nil
    end
    save_query_details_no_params(file_path, details)
    return details
end
