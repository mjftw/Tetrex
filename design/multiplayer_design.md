# Multiplayer Design

## Game stages - Starting the game

Game status: "players_joining"

* People can join from the lobby

### From point of view of Player 1

* When first player joins show a "Waiting for other players..." banner
* When second player joins show a "Ready?" button
* When pressed, check if other players ready

  * If not, display a "Waiting for other players to be ready..." banner
  * If yes, display a 3... 2... 1... countdown, start the game

### From point of view of Player 2..n

* When joining show a "Ready?" button
* When pressed, check if other players ready
  * If not, display a "Waiting for other players to be ready..." banner
  * If yes, display a 3... 2... 1... countdown, start the game

## Game stages - Playing

Game status: "playing"

* People can no longer join from the lobby, game shows as "in progress"
* Peple can press a "spectate" button
  * This will give them a view showing the boards (not hold & up next) for all players
  * **This will come later!**

### From the point of view of Player 1

* They see their full board in the centre of their screen
  * There is a border & padding around their board area to make it clear that it is separate from the other players boards
* They see small versions of the other players boards to the left and right of their board
  * They do not see the "hold" and "up" next tiles for other players
  * Other players boards have toned down colours so it is clear that it is not their board
* If they leave the page, their game continues playing without them
  * They can rejoin by going to the same URL, or via the Lobby
* When they complete a row, a blocking row is added to all other player's boards
  * *May need to tweak how many rows they complete before adding blocking rows based on number of players*
* When the board eventually fills to the top, they have lost
  * A "You have died :(" banner is added to their screen
  * They can either press a "Spectate" or "Back to Lobby" button


### From the point of view of Player 2..n

* When an opponent dies, their preview gets a red X across it and it gets greyed out to show they have died
* When an opponent leaves the game, treat it as a death and display it the same
* When all opponents die, a "WINNER!" banner is added to their screen
  * They can press a "Back to lobby" button

## Game stags - End

Game status: "finished"

Once the winner presses  "Back to lobby":

* All players are kicked from the game and put back in the Lobby
* The game data is now cleaned up
