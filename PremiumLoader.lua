if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(math.random())
local games = {
    [10611639] = "https://api.luarmor.net/files/v4/loaders/2e9943b189ff4e3f73e0f93f10a7fe22.lua", 
}
local loader = games[game.CreatorId]

if loader then
    loadstring(game:HttpGet(loader))()
end
