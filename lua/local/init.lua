require("utils")


---Save query details to the disk.
---If theres no params, only the query file will be saved.
---If there are params, the values will be written to the disk, with a file name per params_variant.
---If there's no params_variant, the 
---@param query_details QueryDetails?
local function save_query_details(file_path, query_details)
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
    print(file_path)
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

---@param file_path string
---@param params QueryParam[]
---@return QueryParam[]
function Parse_query_values(file_path, params)
    local file = Open_or_error(file_path)
    -- TODO: handle situations where order of values has changed 
    -- TODO: then handle situations where values have been deleted or added.
    local lines = file:lines()
    for i, param in ipairs(params) do
        param.value = lines[i]
    end
    file:close()
    return params
end


---@param file_path string?
---@param details QueryDetails?
---@return QueryDetails?
function Write_query_details(file_path, details)
    if details == nil then
        print("No query found")
        return nil
    end
    save_query_details(file_path, details)
    return details
end
