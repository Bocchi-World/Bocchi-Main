local a = game:GetService("Players")
local c = a.LocalPlayer

local b = "https://discord.gg/pGmepY6TC"

if setclipboard then
    setclipboard(b)
end

player:Kick(
    "Please join our Discord server to get the latest script!\n\n" ..
    "Discord invite copied to your clipboard.\n" ..
    b
)
