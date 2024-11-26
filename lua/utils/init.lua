---@param file_path string
---@param mode string?
---@return file*
function Open_or_error(file_path, mode)
    local file = io.open(file_path, mode)
    if not file then
        error("Failed to open file for writing: " .. file_path)
    end
    return file
end

---@param file_path string
---@return boolean
function Exists(file_path)
    local file = io.open(file_path, "r")
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

---@return string
function Get_temp_dir()
    return vim.fn.stdpath("data") .. "/pg_query/"
end

---@param label string
---@return string
function Get_query_temp_path(label)
    return Get_temp_dir() .. label
end


---@param s string 
---@return string
function Trim(s)
    if not s then
        return s
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end


---@param value string
---@param delim string
---@param max_occurances number?
---@return string[]
function Split(value, delim, max_occurances)
    local parts = {}
    local pattern = "([^" .. delim .. "]+)"
    local idx = 1
    local matched = value:gmatch(pattern)
    for part in matched do
      table.insert(parts, part)
      idx = idx + 1
      if max_occurances ~= nil and idx > max_occurances then
          -- TODO: could be improved, will break on lists where multiple keys have the same value which shouldn't happen but who knows
          local found = value:find(part)
          if found == nil then
              error("this should never happen")
          end
          local remaining = value:sub(found)
          parts[max_occurances] = table.concat({parts[max_occurances], remaining}, delim)
          return parts
      end
    end
    return parts
end

---@param command string
---@param mode string?
---@return boolean, string|"exit"|"signal"?
function Run_command(command, mode)
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

---@param binary_name string
---@return boolean
function Ensure_binary_available(binary_name)
    local success, _ = Run_command("which ".. binary_name)
    if not success then
        error(binary_name .. " not available, install " .. " or add it to your PATH")
    end
    return success
end
