local job = require('plenary.job')

local M = {}

---@return string?
function M.branch()
    local stderr = {}
    local stdout, result = job:new({
        command = 'git',
        args = { 'branch', '--show-current' },
        on_stderr = function(_, data)
            table.insert(stderr, data)
        end,
    }):sync()
    if #stderr == 0 and result == 0 and #stdout == 1 then
        return stdout[1]
    else
        return nil
    end
end

return M
