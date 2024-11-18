# pg_query.nvim

neovim wrapper for [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git).

## prerequisites

If you're planning to clone this repo, you should start there and run `make init` to download and install `pg_query_utils`.

If not, you'll need to install [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git) yourself and ensure that `pg_query_prepare` is available in your PATH.

## installation

### lazy

```lua
--- vim.fn.stdpath("config")/lua/plugins/pg_query.lua
return {
    {
        "jesses-code-adventures/pg_query.nvim",
        keys = {
            { "<leader>wq", function() require("pg_query").write(); end, mode = "n", desc = "Write postgres query" },
        },
        config = function()
            require("pg_query").setup()
        end
    }
}
```

## dev installation

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

- [x] cache queries as fingerprints in XDG_HOME (`vim.fn.stdpath("data")`) with their default values.
- [ ] find better way than caching by fingerprint name, as the fingerprints are too volatile to use as keys.
- [ ] have a Write command that allows you to update the default values. Should be done with a floating window.
- [ ] have a Run command that allows you to execute the query with the fingerprint below the cursor, with its default values.
- [ ] ability to execute the command in a tmux window called pg_query and run using psql/nice pager.
- [ ] ability to execute the command in a new nvim split like dadbod, maybe even just using dadbod.
