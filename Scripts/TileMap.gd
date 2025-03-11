extends TileMapLayer

# --------------------------- #
var Highlighted: Vector2i = Vector2i(-1, -1)
# --------------------------- #
var Tiles: Dictionary
var RemainingTiles: Array
var FlagsPlaced: int = 0
var Bombs: int = 0
# --------------------------- #
var Width: int = 20		# Max 25
var Height: int = 10	# Max 11
# --------------------------- #
var Died: bool = false
var Won: bool = false
var AwaitingFirstClick: bool = true
# --------------------------- #

func _ready() -> void:
	# Position and populate the board with blank tiles.
	global_position = Vector2((1280 - 50 * Width) / 2, 112 + (720 - 112 - 50 * Height) / 2)
	
	# Set TileMap atlas values.
	for Tile in range(Width * Height):
		set_cell(Vector2(Tile % Width, Tile / Width), 0, Vector2(3, 1))
	
	AwaitingFirstClick = true

func _process(delta: float) -> void:
	# Get mouse position and highlight the current cell
	var CurrentTile = GetTileFromGlobal(get_viewport().get_mouse_position())
	var CurrentTileIndex = CurrentTile[0] + CurrentTile[1] * Width
	
	if Highlighted != Vector2i(-1, -1) and Highlighted != CurrentTile:
		set_cell(Highlighted, 0, get_cell_atlas_coords(Highlighted) - Vector2i(0, 2))

	Highlighted = CurrentTile

	if get_cell_atlas_coords(Highlighted)[1] < 2:
		set_cell(Highlighted, 0, get_cell_atlas_coords(Highlighted) + Vector2i(0, 2))
	
	# Reset
	if Input.is_action_just_pressed("Reset"):
		AwaitingFirstClick = true
		for Tile in Tiles: set_cell(Vector2(Tile % Width, Tile / Width), 0, Vector2(3, 1))
	
	# Generate a new game when first tile is clicked.
	if AwaitingFirstClick:
		$"../Environment/HUD/RemainingTiles".text = "Click any tile to start."
		if Input.is_action_just_pressed("LeftClick"):
			$"../Environment/AudioManager".PlaySFX("tile")
			GenerateGame(CurrentTileIndex)

		
	if not AwaitingFirstClick:
		# Text
		if Died: 
			$"../Environment/HUD/RemainingTiles".text = "You died.\nPress \"r\" to reset"
		elif RemainingTiles.size() == 0 and FlagsPlaced <= Bombs: 
			$"../Environment/HUD/RemainingTiles".text = "You win!"
			
		else:
			$"../Environment/HUD/RemainingTiles".text = "Safe tiles remaining: " + str(RemainingTiles.size()) + "\nMines remaining: " + str(Bombs - FlagsPlaced)

			if Input.is_action_just_pressed("LeftClick"):
				if get_cell_atlas_coords(CurrentTile) == Vector2i(3, 3):
					$"../Environment/AudioManager".PlaySFX("tile")
					RevealTile(CurrentTileIndex)
					print(RemainingTiles.size())
					
			elif Input.is_action_just_pressed("RightClick"):
				if get_cell_atlas_coords(CurrentTile) == Vector2i(3, 3):
					$"../Environment/AudioManager".PlaySFX("flagdown")
					FlagsPlaced += 1
					if Bombs - FlagsPlaced == 5: $"../Environment/AudioManager".SwitchTrack()
					set_cell(CurrentTile, 0, Vector2i(2, 3))
				elif get_cell_atlas_coords(CurrentTile) == Vector2i(2, 3):
					$"../Environment/AudioManager".PlaySFX("flagup")
					FlagsPlaced -= 1
					if Bombs - FlagsPlaced == 6: $"../Environment/AudioManager".SwitchTrack()
					set_cell(CurrentTile, 0, Vector2i(3, 3))

func RevealTile(ID: int):
	RemainingTiles.erase(ID)
	
	if Tiles[ID] == -1:
		set_cell(Vector2(ID % Width, ID / Width), 0, Vector2(1, 1))
		Died = true
		$"../Environment/AudioManager".PlaySFX("bomb")
	elif Tiles[ID] == 0:
		set_cell(Vector2(ID % Width, ID / Width), 0, Vector2(0, 0))
		for Neighbour in GetValidNeighbours(ID).duplicate():
			if get_cell_atlas_coords(Vector2(Neighbour % Width, Neighbour / Width)) == Vector2i(3, 1):
				RevealTile(Neighbour)
	else:
		set_cell(Vector2(ID % Width, ID / Width), 0, Vector2(Tiles[ID], 0))
		
func GetTileFromGlobal(Global: Vector2):
	return self.local_to_map(self.to_local(Global))

func GetValidNeighbours(ID: int):
		var ValidNeighbours: Array
		if ID % Width != 0:
			ValidNeighbours.append(ID - 1) 
			if floor(ID / Width) != 0:
				ValidNeighbours.append(ID - Width - 1)
			if floor(ID / Width) != Height - 1:
				ValidNeighbours.append(ID + Width - 1)
		if ID % Width != Width - 1:
			ValidNeighbours.append(ID + 1) 
			if floor(ID / Width) != 0:
				ValidNeighbours.append(ID - Width + 1)
			if floor(ID / Width) != Height - 1:
				ValidNeighbours.append(ID + Width + 1)
		if floor(ID / Width) != 0:
			ValidNeighbours.append(ID - Width) 
		if floor(ID / Width) != Height - 1:
			ValidNeighbours.append(ID + Width)
		return ValidNeighbours

func GenerateGame(Centre: int):
	Tiles = {}
	Highlighted = Vector2i(-1, -1)
	RemainingTiles = []
	Died = false
	AwaitingFirstClick = false
	FlagsPlaced = 0
	
	var ValidTiles: Array = range(Width * Height)
	var MineTiles: Array = []
	
	# Remove the initial click from the bomb pool.
	ValidTiles.erase(Centre)
	for Tile in GetValidNeighbours(Centre):
		ValidTiles.erase(Tile)
	
	# Randomly populate tiles with bombs.
	ValidTiles.shuffle()
	Bombs = (Width * Height / 6)
	while (MineTiles.size() < Bombs):
		MineTiles.append(ValidTiles.pop_back())

	# Add the removed tiles back.
	ValidTiles.append(Centre)
	for Tile in GetValidNeighbours(Centre):
		ValidTiles.append(Tile)

	# Populate the dictionary.
	for Tile in MineTiles:
		Tiles[Tile] = -1
		
		# Increment all non-bomb neighbours.
		for Neighbour in GetValidNeighbours(Tile):
			if Neighbour not in Tiles.keys(): Tiles[Neighbour] = 1
			elif Tiles[Neighbour] != -1: Tiles[Neighbour] += 1
	
	# Add the remaining blank tiles.
	for Tile in ValidTiles:
		if not Tiles.has(Tile):	Tiles[Tile] = 0
		
	# Set TileMap atlas values.
	for Tile in Tiles.keys():
		if Tiles[Tile] == -1: print(Tile)
		set_cell(Vector2(Tile % Width, Tile / Width), 0, Vector2(3, 1))
		if Tiles[Tile] > -1: RemainingTiles.append(Tile)

	# Reveal the initial tile.
	RevealTile(Centre)
