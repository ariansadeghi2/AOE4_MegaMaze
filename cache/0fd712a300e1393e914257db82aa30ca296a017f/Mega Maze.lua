--Mze generation map based on Recursive backtracking algorithm

--Set up variables for each of the terrain types you plan to use in the course grid layout.

--more terrain types can be added as needed / created



--create the course grid. This is the table that holds the terrain types that will be used to generate the map in a 2D grid
--In order for the mapgen system to pick up your layout, you MUST have a table called terrainLayoutResult
--terrainLayoutResult is formatted for you using our SetUpGrid function. Each square can have a few parameters in dot notation:
--terrainLayoutResult[row][col].terrainType    <-- specifies the terrain at that grid square to generate
--terrainLayoutResult[row][col].playerIndex    <-- spawns the specified player index from the lobby on that square.
--We have several functions that act to sort out the player indices and their team assignments. The TeamMappingTable (created in the player starts section)
--holds all this info in an organized way.
terrainLayoutResult = {}    -- set up initial table for coarse map grid

--setting useful variables to reference world dimensions. This sets the map to our defualt resolution of 40m per grid square, which is reccommended.
--when generating our maps, each square on the grid is represented by a terrain type (hills, mountain, plains, etc) whose height is determined
--by a height/width calculation. When you change grid resolution, this calculation is affected. For example, with a higher resolution grid
--(for example 25m vs the standard 40m), all terrain features will be generated smaller, which in the case of things like mountains, can
--affect their ability to create impasse on the map. Use a custom resolution at your own discretion, but do not expect that all terrain
--will work as intended. Terrain types have been tuned at the default 40m resolution. 
gridHeight, gridWidth, gridSize = SetCoarseGrid()


--If you wish to set a custom resolution, use the following function. A higher resolution, keeping the caveats in mind, is often useful for making
--things like island maps, or maze-like maps where you need higher granularity in your terrain features.
--gridRes = 25
--gridHeight, gridWidth, gridSize = SetCustomCoarseGrid(gridRes)

if (gridHeight % 2 == 0) then -- height is even so subtract 1 (we want odd numbered grid sizes so that there is a center line in map)
	gridHeight = gridHeight - 1
end

if (gridWidth % 2 == 0) then -- width is even so subtract 1 (we want odd numbered grid sizes so that there is a center line in map)
	gridWidth = gridWidth - 1
end


gridSize = gridWidth -- set resolution of coarse map
--NOTE: AoE4 MapGen is designed to generate square maps. The grid you will be working with will always need to have gridWidth = gridHeight

--set the number of players. this info is grabbed from the lobby
playerStarts = worldPlayerCount

--IF YOU ARE CREATING A TOTALLY PROCEDURAL MAP LAYOUT------------------------------------------

--the "none" type will be randomly filled by your AE data template
n = tt_none

--these are terrain types that define specific geographic features
--each terrain type defines a single square on your map grid, where each square's size is determined by the grid resolution set above.
--The terrain type data (located in the Attribute Editor under map_gen -> map_gen_terrain_type) contains parameters for the physical
--properties of the terrain square, like overall height, amplitude (how 'spiky' the land is), and whether the terrain will tend upwards
--(for hills and mountains) or downwards (for valleys)
--Terrain type data also holds other properties like if the square is a lake source, and if it spawns any local objects/resources.
--If you create your own terrain types, reference them in any map layout by assigning a variable (or direct square on the grid) to the file name
--of your custom terrain type. eg terrainLayoutResult[row][col].terrainType = tt_my_custom_terrain_type


h = tt_hills
s = tt_mountains_small
m = tt_mountains
i = tt_impasse_mountains
b = tt_hills_low_rolling
mr = tt_hills_med_rolling
hr = tt_hills_high_rolling
low = tt_plateau_low
med = tt_plateau_med
high = tt_plateau_high
--p = tt_plains
p= tt_valley
t = tt_impasse_trees_plains
v = tt_valley

--bounty squares are used to populate an area of the map with extra resources
bb = tt_bounty_berries_flatland
bg = tt_bounty_gold_plains

--the following are markers used to determine player and settlement spawn points
s = tt_player_start_hills
sp = tt_settlement_plains
sh = tt_settlement_hills
seb = tt_settlement_hills_high_rolling


--BASIC MAP SETUP-------------------------------------------------------------------------------------------------
-- setting up the map grid

--this sets up your terrainLayoutResult table correctly to be able to loop through and set new terrain squares
terrainLayoutResult = SetUpGrid(gridSize, p, terrainLayoutResult)

baseGridSize = 13
mapMidPoint = math.ceil(gridSize / 2)

--set a few more useful values to use in creating specific types of map features
mapHalfSize = math.ceil(gridSize/2)
mapQuarterSize = math.ceil(gridSize/4)
mapEighthSize = math.ceil(gridSize/8)

--do map specific stuff around here


-- Function to shuffle the array
function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.floor(worldGetRandom() * (i - 1)) + 1
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Function to carve paths in the maze
function carveMaze(x, y)
    directions = shuffle({{1, 0}, {0, 1}, {-1, 0}, {0, -1}})
    
    for i, dir in ipairs(directions) do
        local nx, ny = x + dir[1]*2, y + dir[2]*2
        if nx > 0 and nx <= gridSize and ny > 0 and ny <= gridSize and terrainLayoutResult[nx][ny].terrainType == t then
            terrainLayoutResult[nx][ny].terrainType = p
            terrainLayoutResult[x + dir[1]][y + dir[2]].terrainType = p
            carveMaze(nx, ny)
        end
    end
end

-- Initialize the grid with walls (trees)
for row = 1, gridSize do
    for col = 1, gridSize do
        terrainLayoutResult[row][col] = {terrainType = t}
    end
end

-- Start carving the maze from the center
startX, startY = 1, 1
terrainLayoutResult[startX][startY].terrainType = p
carveMaze(startX, startY)

-- Place player starts, resources, and other map features here after the maze is generated

-- NOTE: This script assumes that the `SetUpGrid` function has already been called to initialize the `terrainLayoutResult` table.
-- You may need to adapt the script to fit within the actual scripting capabilities of the Age of Empires 4 content editor.


-- SETUP PLAYER STARTS-------------------------------------------------------------------------------------------------


teamsList, playersPerTeam = SetUpTeams()

--The Team Mapping Table is created from the info in the lobby. It is a table containing each team and which players make them up.
--Formatted as follows if you need to use it for something in your map:
--teamMappingTable[teamIndex].players[playerIndex].playerID
teamMappingTable = CreateTeamMappingTable()
	
--the following are variables that control player spawn distances using the PlacePlayerStarts function.
--PlacePlayerStartsRing is the function used in many of our procedural skirmish maps. It will either cluster or spread out players and teams
--based on if "Teams Together" or "Teams Apart" is chosen in the lobby.
--It will automatically place players and an open area for them to build around the map based on terrain you give it to both spawn on and avoid.
--It will also place players within a "donut" shape around the map, so that players don't spawn right in the centre of the map, or in the direct corners, for balance

--minPlayerDistance is the closest that any 2 players can be, in absolute distance based on the resolution of your grid.
--maps with higher grid resolution (should you choose to do this) will require larger player and team distance values, otherwise you
--will see teams and players spawning closer than intended.
--Making this number larger will give more space between every player, even those on the same team.
minPlayerDistance = 3.5

--minTeamDistance is the closest any members of different teams can spawn. Making this number larger will push teams further apart.
minTeamDistance = 8.5

--edgeBuffer controls how many grid squares need to be between the player spawns and the edge of the map.
edgeBuffer = 1

--innerExclusion defines what percentage out from the centre of the map is "off limits" from spawning players.
--setting this to 0.4 will mean that the middle 40% of squares will not be eligable for spawning (so imagine the centre point, and 20% of the map size in all directions)
innerExclusion = 0.4

--cornerThreshold is used for making players not spawn directly in corners. It describes the number of squares away from the corner that are blocked from spawns.
cornerThreshold = 2

--playerStartTerrain is the terrain type containing the standard distribution of starting resources. If you make a custom set of starting resources, 
--and have them set as a local distribution on your own terrain type, use that here
playerStartTerrain = tt_player_start_classic_plains

--impasseTypes is a list of terrain types that the spawning function will avoid when placing players. It will ensure that players are not placed on or
--adjacent to squares in this list
impasseTypes = {}
table.insert(impasseTypes, tt_impasse_mountains)
table.insert(impasseTypes, tt_mountains)
table.insert(impasseTypes, tt_plateau_med)
table.insert(impasseTypes, tt_ocean)
table.insert(impasseTypes, tt_river)
table.insert(impasseTypes, tt_impasse_trees_plains)

--impasseDistance is the distance away from any of the impasseTypes that a viable player start needs to be. All squares closer than the impasseDistance will
--be removed from the list of squares players can spawn on.
impasseDistance = 0

--topSelectionThreshold is how strict you want to be on allies being grouped as closely as possible together. If you make this number larger, the list of closest spawn
--locations will expand, and further locations may be chosen. I like to keep this number very small, as in the case of 0.02, it will take the top 2% of spawn options only.
topSelectionThreshold = 0.02

--startBufferTerrain is the terrain that can get placced around player spawns. This terrain will stomp over other terrain. We use this to guarantee building space around player starts.
startBufferTerrain = tt_plains

--startBufferRadius is the radius in which we place the startBufferTerrain around each player start
startBufferRadius = 0

--placeStartBuffer is a boolean (either true or false) that we use to tell the function to place the start buffer terrain or not. True will place the terrain, false will not.
placeStartBuffer = false

terrainLayoutResult = PlacePlayerStartsRing(teamMappingTable, minTeamDistance, minPlayerDistance, edgeBuffer, innerExclusion, cornerThreshold, impasseTypes, impasseDistance, topSelectionThreshold, playerStartTerrain, startBufferTerrain, startBufferRadius, placeStartBuffer, terrainLayoutResult)


--]]

---------------------------------------------------------------------------------------------------------------------------------------------------------------

--WATER FEATURES-------------------------------------------------------------------------------------------------

--Lake Features
--If you want interior bodies of water (eg inland), using lakes is a great option. We have the terrain types tt_lake_shallow and tt_lake_deep, which both
--generate water, and when connected to other lake squares, will fill the area with a water basin. Note that using only shallow lake squares will
--result in shallow swampy terrain, and may not necessarily be deep enough to block units with water depth, or be enough to spawn boats.


--Ocean Features

--If you wish to use oceans on your map, there are a few bits of data work to do to ensure that oceans genearte properly:
--In your map layout data (look in the Attribute Editor, under map_gen\map_gen_layout) look at the 'oceans' data. 
--There will be a field called 'ocean_height', which defaults to -100. This is to ensure that water is not generated
--in dry valleys on land maps. For creating an ocean map, start with an ocean_height value of 5.
--Additionally, use the tt_ocean terrain type, and ensure that it exists in a contiguous blob, with at least part of the area
--touching the edge of the map. Oceans will not be created without touching the edge of the map. For interior bodies of water, use lakes.