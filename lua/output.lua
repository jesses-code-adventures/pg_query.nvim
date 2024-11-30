---takes an sql query and a list of default params and replaces the query's placeholders with the values.
---@param query string
---@param params QueryParam[]
---@param skip_comment boolean
---@return string
function Render_inplace_placeholders(query, params, skip_comment)
    if skip_comment then
        query = query:gsub("^%s*--[^\n]*\n", "") -- Remove single-line comments
        query = query:gsub("^%s*/%*.-%*/%s*", "") -- Remove block comments
    end
    for _, param in ipairs(params) do
        if param.value == nil then
            error("expected a value for field \"" .. param.field .. "\" (argument index " .. param.index .. "), received nil.")
        end
        local placeholder = "$" .. param.index
        local replacement
        if type(param.value) == "string" then
            replacement = "'" .. param.value:gsub("'", "''") .. "'" -- escape single quotes
        else
            replacement = tostring(param.value)
        end
        query = query:gsub("(%W)" .. placeholder .. "(%W)", "%1" .. replacement .. "%2")
        query = query:gsub("^" .. placeholder .. "(%W)", replacement .. "%1")
        query = query:gsub("(%W)" .. placeholder .. "$", "%1" .. replacement)
    end
    return query
end
