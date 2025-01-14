
local v3 = {
    {url = "https://raw.githubusercontent.com/Ngducok/doing-some-shit/refs/heads/main/UI.lua", delay = 0.5},
    {url = "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/pickcard.lua", delay = 0.5},
    {url = "https://raw.githubusercontent.com/Ngducok/doing-some-shit/refs/heads/main/hey.lua", delay = 0.5},
    {url = "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/FPSBooster.lua", delay = 0.5, requireFPS = true}
}

for v1, v2 in ipairs(v3) do
    task.spawn(function()
        if v2.requireFPS and not getgenv().FPS then return end
        local success = pcall(function()
            loadstring(game:HttpGet(v2.url))()
        end)
        if not success then task.wait(v2.delay) end
    end)
end
