---@param got any
---@param want any
---@param label string?
function Assert_eq(got, want, label)
    local eq = got == want
    if not eq then
        error("Equality test failed" .. (label and ": " .. label or "") .. "\nGot:  " .. got .. "\nWant: " .. want)
    end
end
