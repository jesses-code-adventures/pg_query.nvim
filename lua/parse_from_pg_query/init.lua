require("utils")

---@class QueryParam
---@field index integer @The argument index in the sql query.
---@field field string @The name of the field in the query.
---@field field_type string? @The type of the field, which should be inferred from a live database. We assume we don't have access to this.
---@field value any? @The value to be used for this parameter when the query is rendered.

---@class QueryDetails @Query details parsed from pg_query_prepare --details.
---@field label string @The label of the query. Takes the `-- name:` annotation where available, else uses the fingerprint.
---@field fingerprint string @The unqiue fingerprint of the parsed query, which can be used to quickly check whether the query named `label` has changed, as the fingerprint would also change.
---@field params QueryParam[] @The parameters of the query, including the field name, the argument index, and optionally the field type and argument values.


--- takes a string containing key-value pairs with an arbitrary delimiter (defaults to " ") 
---@param details string[]
---@param key string
---@param key_value_delimiter string
---@return string?
local function parse_field_from_details(details, key, key_value_delimiter)
    for _, part in ipairs(details) do
        local lil_parts = Split(part, key_value_delimiter)
        local k = lil_parts[1]
        local value = table.concat(lil_parts, key_value_delimiter, 2)
        if key == k and value ~= nil then
            return Trim(value)
        end
    end
    return nil
end

---@param result string
---@return string[]
local function split_details_output(result)
    local resp = {}
    local details = Split(result, " ", 4)
    if #details == 0 then
        return resp
    end
    for _, deet in ipairs(details) do
        table.insert(resp, Trim(deet))
    end
    return resp
end

---@return QueryParam[]
local function parse_params_list_from_details(params_str)
    -- TODO: handle parsing values that contain commas within quotes or parentheses
    local params = {}
    local param_parts = Split(params_str, ",")
    for _, param in ipairs(param_parts) do
        local ps = Split(param, ":")
        local index = ps[1]
        local field = Trim(ps[2]) or nil
        local field_type = Trim(ps[3]) or nil
        table.insert(params, {index=index, field=field, field_type=field_type})
    end
    return params
end

---@param query string @A postgres query, as a string, to pass to pg_query_prepare --details.
---@return QueryDetails?
function Parse_query_details(query)
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

