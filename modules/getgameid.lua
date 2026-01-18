local gameId = tostring(game.GameId)
if setclipboard then
    setclipboard(gameId)
    print("Game ID copied to clipboard: " .. gameId)
else
    warn("Exploiter cant method setclipboard.")
end
