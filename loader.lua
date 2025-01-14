local links = {
    "https://raw.githubusercontent.com/Ngducok/doing-some-shit/refs/heads/main/UI.lua",
    "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/pickcard.lua",
    "https://raw.githubusercontent.com/Ngducok/doing-some-shit/refs/heads/main/hey.lua"
    "https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/FPSBooster.lua"
}

for _, link in ipairs(links) do
    pcall(function()
        loadstring(game:HttpGet(link))()
    end)
end
