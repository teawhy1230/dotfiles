local nvim_lsp = require('lspconfig')
local on_attach = function(client, bufnr)
    -- https://github.com/nvim-lua/completion-nvim#setup
    require('completion').on_attach(client)
    -- https://github.com/nvim-lua/completion-nvim#recommended-setting
    -- Set completeopt to have a better completion experience
    -- set completeopt=menuone,noinsert,noselect
    vim.o.completeopt='menuone,noinsert,noselect'
    -- Avoid showing message extra message when using completion
    -- set shortmess+=c
    vim.o.shortmess = vim.o.shortmess .. 'c'

    -- Disable virtual text diagnostics
    -- :help lsp-handler-configuration
    -- https://zenn.dev/garypippi/articles/fe72e26c25563e4c44a9#virtual-text%E3%81%A7%E8%A1%A8%E7%A4%BA%E3%81%97%E3%81%AA%E3%81%84%E8%A8%AD%E5%AE%9A
    vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false })
    -- Open diagnostic window when the cursor moved to a line with some diagnostics.
    -- CursorMoved event could be slow, since it's hooked everytime the cursor moves.
    -- vim.cmd('autocmd CursorMoved * lua vim.lsp.util.show_line_diagnostics()')
    -- CursorHold event may be more efficient,
    -- vim.cmd('autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics()') -- Switch this off since cursor gets trapped in the diagnostic window
    -- although I will have to wait for 4 seconds until the window pops up.
    -- vim.cmd('autocmd CursorHold * lua vim.lsp.util.show_line_diagnostics()')
    -- The time can be configured by changing updatetime.
    -- But since updatetime is used to check whether to write swap file or not,
    -- configuring it could also slow neovim down.
    vim.o.updatetime = 500 -- 0.5 sec


    -- See :help nvim_buf_set_keymap() for info
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

    -- Configure the appearance of diagnostics.
    -- :help lsp-highlight-diagnostics
    -- https://vim-jp.org/vimdoc-ja/sign.html
    -- https://coffeeandcontemplation.dev/
    -- https://zenn.dev/garypippi/articles/fe72e26c25563e4c44a9
    vim.api.nvim_exec([[
    sign define LspDiagnosticsSignError text=✘
    sign define LspDiagnosticsSignWarning text=●
    sign define LspDiagnosticsSignInformation text=●
    sign define LspDiagnosticsSignHint text=●
    hi LspDiagnosticsSignError ctermfg=red
    hi LspDiagnosticsSignWarning ctermfg=yellow
    hi LspDiagnosticsSignInformation ctermfg=blue
    hi LspDiagnosticsSignHint ctermfg=green
    ]], false)

    -- Disable auto signature option in to avoid getting error at
    -- lsp.util.focusable_preview() called in util.lua in neovim.
    -- Call chain is probably
    -- autoOpenSignatureHelp @ completion-nvim
    -- vim.lsp.util.focusable_preview @ neovim:util.lua
    -- focusable_float
    -- api.nvim_set_current_win(win) (fail here)
    -- https://github.com/nvim-lua/completion-nvim/blob/dc4cf56e78aa5e7e782064411b22460597d72c36/lua/completion/signature_help.lua
    -- https://github.com/neovim/neovim/blob/370469be250de546df1a674d6d5cd41283bb6b3c/runtime/lua/vim/lsp/util.lua
    -- vim.g.completion_enable_auto_signature = 0  -- this works now
end


function system(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- root_dir has to be a function which returns the root directory
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/lspconfig.txt
function getcwd(fname)
    -- just ignore fname argument
    -- it's just required to match callback function signature
    -- remove new line from the end
    return system("pwd"):gsub("\n", "")
end


-- https://neovim.io/doc/user/lsp.html
function load_pylsp(nvim_lsp)
    function root_dir(fname)
        local root_files = {
            'pyproject.toml',
            'setup.py',
            'setup.cfg',
            'requirements.txt',
            'Pipfile',
        }
        return nvim_lsp.util.root_pattern(unpack(root_files))(fname) or nvim_lsp.util.find_git_ancestor(fname) or nvim_lsp.util.path.dirname(fname)
    end

    local venv_path = os.getenv("VIRTUAL_ENV")  -- could be nil
    local home = os.getenv("HOME")
    local pylsp_venv = home .. "/venvs/pylsp"
    local python_path = pylsp_venv .. "/bin/python"
    local pylsp_path = pylsp_venv .. "/bin/pylsp"

    if venv_path ~= nil then
        nvim_lsp["pylsp"].setup{
            cmd = { python_path, pylsp_path },
            on_attach = on_attach,
            filetypes = { "python "},
            root_dir = root_dir,
            settings = {
                -- pylsp.plugins.jedi.environment
                pylsp = {
                    plugins = {
                        jedi = {
                            environment = venv_path
                        },
                    },
                },
            },
        }
    else
        nvim_lsp["pylsp"].setup{
            cmd = { python_path, pylsp_path },
            on_attach = on_attach,
            filetype = { "python "},
            root_dir = root_dir,
        }
    end
end

function load_ccls(nvim_lsp)
    function root_dir(fname)
        return nvim_lsp.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname) or getcwd(fname)
    end
    nvim_lsp['ccls'].setup{
        cmd = { "ccls" },
        on_attach = on_attach,
        init_options = {
            cache = { directory = ".ccls-cache" }
        },
        root_dir = root_dir
    }

end

load_pylsp(nvim_lsp)
load_ccls(nvim_lsp)
