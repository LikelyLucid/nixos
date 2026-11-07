local function fail(message)
  io.stderr:write("FAIL: " .. message .. "\n")
  vim.cmd("cquit 1")
end

local loaded, config = pcall(require, "blink.cmp.config")
if not loaded then fail("could not load blink.cmp configuration: " .. tostring(config)) end

local sources = config.sources or {}
local defaults = sources.default or {}
if not vim.tbl_contains(defaults, "copilot") then
  fail("copilot is missing from blink.cmp default sources")
end

local provider = (sources.providers or {}).copilot
if type(provider) ~= "table" then fail("blink-copilot provider is missing") end
if provider.module ~= "blink-copilot" then fail("copilot provider module is not blink-copilot") end
if provider.name ~= "copilot" then fail("copilot provider name is not copilot") end
if provider.async ~= true then fail("copilot provider is not asynchronous") end
if provider.score_offset ~= 100 then fail("copilot provider score offset is not 100") end

print("blink-copilot is enabled as an asynchronous default completion source")
vim.cmd("qa!")
