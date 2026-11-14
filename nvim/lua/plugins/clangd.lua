-- C/C++ in catkin workspaces. Extends the lang.clangd extra (lazyvim.json), which:
--   * roots clangd at the git repo, but catkin writes one compile_commands.json per
--     package, at <ws>/build/<pkg>/, so clangd never finds a compilation database;
--   * does not pass --query-driver, so the Mason clangd cannot find the system
--     libstdc++ headers ('chrono' file not found, std::shared_ptr unknown, ...).
-- Outside a catkin workspace both fall back to the extra's behaviour.

--- Directory of the nearest catkin package (package.xml) above `file`, if any.
local function catkin_package_root(file)
  local xml = vim.fs.find("package.xml", { upward = true, path = vim.fs.dirname(file) })[1]
  return xml and vim.fs.dirname(xml)
end

--- <ws>/build/<pkg> for a package living under <ws>/src, if its database exists.
local function catkin_build_dir(pkg_root)
  local ws = pkg_root:match("^(.-)/src/")
  local lines = vim.fn.readfile(pkg_root .. "/package.xml")
  local name = table.concat(lines, "\n"):match("<name>%s*([^<%s]+)%s*</name>")
  if not (ws and name) then
    return nil
  end
  local dir = string.format("%s/build/%s", ws, name)
  return vim.uv.fs_stat(dir .. "/compile_commands.json") and dir or nil
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local clangd = opts.servers.clangd
      local base_cmd = vim.list_extend(vim.deepcopy(clangd.cmd), {
        "--query-driver=/usr/bin/c++,/usr/bin/cc,/usr/bin/*g++*,/usr/bin/*gcc*,/usr/bin/clang*",
      })

      clangd.root_dir = function(bufnr, on_dir)
        local file = vim.api.nvim_buf_get_name(bufnr)
        local root = catkin_package_root(file)
        if not root then
          root = vim.fs.root(bufnr, vim.lsp.config.clangd.root_markers or { ".git" })
        end
        -- Always start clangd; single files outside any project use their own directory.
        on_dir(root or vim.fs.dirname(file))
      end

      clangd.cmd = function(dispatchers, config)
        local cmd = vim.deepcopy(base_cmd)
        local build_dir = config.root_dir
          and vim.uv.fs_stat(config.root_dir .. "/package.xml")
          and catkin_build_dir(config.root_dir)
        if build_dir then
          table.insert(cmd, "--compile-commands-dir=" .. build_dir)
        end
        return vim.lsp.rpc.start(cmd, dispatchers, { cwd = config.cmd_cwd, env = config.cmd_env })
      end
    end,
  },
}
