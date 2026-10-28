local a = game:GetService("Players")
local b = "https://discord.gg/pGmepY6TC"
local c = a.LocalPlayer

if setclipboard then
    pcall(setclipboard, b)
end

if c then
    c:Kick(
        "Please join our Discord server to get the latest script!\n\n" ..
        "Discord invite copied to your clipboard.\n" ..
        b
    )
else
    warn("Kick failed: LocalPlayer is nil")
end
