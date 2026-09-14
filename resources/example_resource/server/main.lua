-- This file documents the planned V0.3 Lua API.
-- It is discovered by V0.1 but is not executed yet.

function onPlayerJoin(player)
    outputChatBox(player.name .. " megérkezett Open Citybe!")

    local vehicle = createVehicle(
        "sedan_01",
        Vector3(12.0, 0.5, 8.0)
    )

    warpPlayerIntoVehicle(player, vehicle)
end

addEventHandler("onPlayerJoin", root, onPlayerJoin)
