
local function loads(url)
    local success = pcall(function()
        loadstring(game:HttpGet(url))()
    end)

    return success
end

local function hookurl()
    local scriptUrls = {
        "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/1.lua",
        "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/2.lua",
        "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/3.lua"
    }

    for _, url in ipairs(scriptUrls) do
        local success = loads(url)
        print(success)
    end
end

hookurl()
