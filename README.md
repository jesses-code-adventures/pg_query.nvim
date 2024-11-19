# pg_query.nvim

neovim wrapper for [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git).

## prerequisites

If you're planning to clone this repo, you should start there and run `make init` to download and install `pg_query_utils`.

If not, you'll need to install [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git) yourself and ensure that `pg_query_prepare` is available in your PATH. Currently, using this script handles the installation process for you.

```bash
git clone --recurse-submodules --depth 1 https://github.com/timwmillard/pg_query_utils.git && \
    cd pg_query_utils && \
    sed -i '' '/^all:/s/pg_describe_query.*//;' Makefile && \
    make && \
    mkdir -p "$$HOME/.local/bin" && \
    cp pg_query_prepare "$$HOME/.local/bin" && \
    cp pg_query_json "$$HOME/.local/bin" && \
    cp pg_query_fingerprint "$$HOME/.local/bin" && \
    cd .. && \
    rm -rf pg_query_utils;
```

## installation

### lazy

```lua
return {
    {
        "jesses-code-adventures/pg_query.nvim",
        keys = {
            { "<leader>wq", function() require("pg_query").write(); end, mode = "n", desc = "Write postgres query" },
        }
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
        dev = dev,
        dir = dev and path or nil,
        enabled = true,
        lazy = false,
        keys = {
            { "<leader>wq", function() require("pg_query").write(); end, mode = "n", desc = "Write postgres query" },
        }
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
