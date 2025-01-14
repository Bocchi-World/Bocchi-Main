local v3 = {
    "https://raw.githubusercontent.com/Ngducok/doing-some-shit/refs/heads/main/UI.lua",
    "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/pickcard.lua",
    "https://raw.githubusercontent.com/Ngducok/doing-some-shit/refs/heads/main/hey.lua",
    "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/FPSBooster.lua"
}

for v1, v2 in ipairs(v3) do
    local success, result = pcall(function()
        task.wait(0.5) 
        return game:HttpGet(v2)
    end)
    
    if success then
        pcall(function()
            loadstring(result)()
        end)
    end
end
