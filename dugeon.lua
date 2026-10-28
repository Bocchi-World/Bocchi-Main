repeat task.wait() until game:IsLoaded()

local a = game:GetService("Players")
local b = "https://discord.gg/pGmepY6TC"
local c = a.LocalPlayer

assert(c, "LocalPlayer is nil")

if setclipboard then
    pcall(setclipboard, b)
end

task.wait(0.5)

c:Kick(
    "Please join our Discord server to get the latest script!\n\n" ..
    "Discord invite copied to your clipboard.\n" ..
    b
)
