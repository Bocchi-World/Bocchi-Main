local a = game:GetService("Players")
local c = a.LocalPlayer
local b = "https://discord.gg/pGmepY6TC"

if setclipboard then
    pcall(setclipboard, b)
end

if not c then
    error("LocalPlayer is nil - script is not running on the client")
end

c:Kick(
    "Please join our Discord server to get the latest script!\n\n" ..
    "Discord invite copied to your clipboard.\n" ..
    b
)
