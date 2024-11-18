# pg_query_utils.nvim

neovim wrapper for pg_query_utils.

## dev

run `make init` to install the `pg_query_utils` dev tools.

use the following `plugins/pg_query.lua` in your Lazy config to set up locally.

```lua
local dev = true
local path = vim.fn.expand("~/wherever/you/cloned/pg_query.nvim")

if not vim.loop.fs_stat(path) then
    return {}
end

return {
    {
        "jesses-code-adventures/pg_query.nvim",
        name = "pg_query",
        dir = dev and path or nil,
        dev = dev,
        enabled = true,
        lazy = false,
        config = function()
            require("pg_query").setup()
        end
    }
}
```

### todo

- [ ] cache queries as fingerprints in XDG_HOME (`vim.fn.stdpath("data")`) with their default values.
- [ ] have a Write command that allows you to update the default values. Should be done with a floating window.
- [ ] have a Run command that allows you to execute the query with the fingerprint below the cursor, with its default values.
