--Cardinal Map Generation Quick-Start Template


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
p = tt_plains
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

--Here's a basic loop that will iterate through all squares in your map
for row = 1, gridSize do
	for col = 1, gridSize do
	
	--do stuff with the grid here
	--creating a basic checkerboard pattern
		if(row % 2 == 0) then
			if(col % 2 == 0) then
				terrainLayoutResult[row][col].terrainType = tt_continental_water
		end
		end
	end
end

--As a quick example, here is a basic thing you can do to add some random mountains to your map to get you started.
--Let's set a variable to a terrain type that will be randomly populated on the map. Change this to whatever type of terrain you want!
--You can find all of our terrain types in the Attribute Editor under map_gen -> map_gen_terrian_types
--If you make your own terrain type, you can use its name in any map layout to put it into your map!
--Let's assign ours as mountains, for example
terrainFeature = tt_mountains

--Now, we will loop through the map grid, and at each square we look at, we will grab a random number.
--Our function, worldGetRandom(), gives back a value between 0 and 1. You MUST use this function to get random numbers, otherwise
--multiplayer games will crash. (This function ensures that each player in a multiplayer session will get the same random number when called)
--Let's make a variable for our chance to spawn a mountain in each square. We'll make it 5%, as an example (try changing it, generating, and see what happens!)
terrainChance = 0.05

--Now, we do the actual loop
for row = 1, gridSize do
	for col = 1, gridSize do
		
		--get chance to place the feature
		if(worldGetRandom() < terrainChance) then
			--replace the current square with our feature we are spawning
			terrainLayoutResult[row][col].terrainType = terrainFeature
			
		end
	end
end

--now, the grid won't have guaranteed 5% mountain coverage, but it will have given each square a 5% chance to be a mountain. This is the basic way we 
--iterate through our maps and do 'passes' on the terrain to add or change features.
--For example, you may want to do a pass and change all those mountains into rolling hills, for some reason. Using the same loop structure, you can do
--a conditional check on each square to find the mountain squares, then do something with them.
-- for row = 1, gridSize do
-- 	for col = 1, gridSize do
		
-- 		--check for the terrain type you had chosen before
-- 		if(terrainLayoutResult[row][col].terrainType == terrainFeature) then
-- 			--knowing that you are looking at the correct type of square, do something with it
-- 			--terrainLayoutResult[row][col].terrainType = tt_hills_high_rolling
			
-- 		end
-- 	end
-- end


--For more complex scripting examples, check out our existing procedural maps that came with the game, or the advanced map template.
--The advanced map template contains various functions with parameters that will create different types of maps. These functions are more complex, 
--and may require more tuning and experimentation to get the most out of them.
--[[
-- QUICKSTART MAP ARCHETYPE GENERATORS --------------------------------------------------------------------------------
--We have several functions that will generate a specific type of map randomly - these are great as a quick option to give you a baseline
--map of a specific style that you can then further hand edit, or generate with different seeds until you find one you like with custom parameters.

--These are the functions that are used to generate MegaRandom, in all varieties. Additionally, the island functions are used to generate all our island
--maps (Archipelago, Warring Islands, Channel, MegaRandom's island styles)

--The following functions all use a list of open terrain and impasse terrain. Edit these lists with the terrain types you want to use when 
--generating these layouts.

basicTerrain = {}
table.insert(basicTerrain, tt_plains)
table.insert(basicTerrain, tt_hills_gentle_rolling)
table.insert(basicTerrain, tt_hills_low_rolling)
table.insert(basicTerrain, tt_hills_med_rolling)
table.insert(basicTerrain, tt_plateau_low)
table.insert(basicTerrain, tt_valley_shallow)


impasseTerrain = {}
table.insert(impasseTerrain, tt_mountains)
table.insert(impasseTerrain, tt_impasse_mountains)
table.insert(impasseTerrain, tt_lake_deep)
table.insert(impasseTerrain, tt_plateau_standard)
table.insert(impasseTerrain, tt_plateau_med)


--This function will create a map with no specific impasse features.
--You specify the overall amount of impasse you want on the map, and the map is randomly filled with terrain from your basicTerrain list
--The random impasse is also chosen from your list of impasse terrain.
--For example, if you want an open map with lakes dotted everywhere, have only plains in your basic terrain, and deep lakes in your impasse terrain.

--set impasseChance based on how open you want the map to be.
impasseChance = 0.12
CreateOpenMap(basicTerrain, impasseTerrain, impasseChance, terrainLayoutResult)


--The following function will create a map with a specified number of choke points. This works by taking your specified impasse types and
--creating lines of that terrain across the map, with a number of gaps on the line. If two lines of impasse ever cross, there will be a zone
--of pathable terrain created at the intersection to ensure playability of the map.

--impasseLines determines how many lines of impasse you want randomly crossing the map. Lower numbers work for a more clearly defined map.
impasseLines = 2

--min and max gaps gives a range of choke points to be created per line of impasse. Again, lower numbers make for more defined maps.
minGaps = 1
maxGaps = 2

--min and max edge determines how close to the edge of the grid the lines can start and end. 
--for example, keep your min and max around half the grid size to get a line of terrain splitting the map down the centre.
minEdge = math.ceil(#terrainLayoutResult * 0.25)
maxEdge = math.ceil(#terrainLayoutResult * 0.75)

CreateChokeMap(basicTerrain, impasseTerrain, impasseLines, minGaps, maxGaps, minEdge, maxEdge, terrainLayoutResult)


--The following function will create a map that is maze-like, in that there are paths of traversable terrain between lots of impasse.
--The maze is created by picking a random grid square from each column, then randomly connecting some of these points together with flat terrain.
--the colGap variable determines how many squares vertically must be between squares in adjacent columns.
colGap = 3
CreateMazeMap(basicTerrain, impasseTerrain, colGap, terrainLayoutResult)



--The following function will create a map that contains a central defendable area 
--centreFeatureNum determines how many of these rings of impasse to create on the map. Lower numbers make a more defined map
centreFeatureNum = 2

--min and max feature radius control the size constraints of the impasse features, in grid squares.
minFeatureRadius = 2
maxFeatureRadius = 3

--impasseChance is the likelihood of the rest of the map to be spawned as impasse.
--Note, the higher this number gets, the less definition your centre feature will have (it will blend with the rest of the impasse)
impasseChance = 0.125

CreateCentreMap(basicTerrain, impasseTerrain, centreFeatureNum, minFeatureRadius, maxFeatureRadius, impasseChance, terrainLayoutResult)



--The following functions create island maps. These are the functions used to generate maps like Archipelago.



--The CreateIslandsTeamsTogether function creates at least one island per team and puts all players from a team on the same island.

--The CreateIslandsTeamsApart function creates one island per player.

--numIslands is the number of islands to geneate in the map. 
numIslands = 5
--weightTable is a table of values that hold the islands that will be created and their weight values. 
--A higher weighted island will have a larger chance of being expanded in size as the map is built.
weightTable = {}
--Adjust the range of values for the extra island weights to create larger or smaller additional islands.
--In this example, the islands that will be spawning teams always get a weight of 1 to help ensure that players spawn with enough room to build.
minExtraIslandWeight = 0.3
maxExtraIslandWeight = 0.6
for i = 1, numIslands do
	currentData = {}
	currentIslandWeight = 0
	if(i <= numTeams) then
		currentIslandWeight = 1
	else
		currentIslandWeight = Normalize(worldGetRandom(), minExtraIslandWeight, maxExtraIslandWeight)
	end
	currentData = {
		i,
		currentIslandWeight
	}
	table.insert(weightTable, currentData)
	
end


--land coverage is a value from 0 to 1 and specifies the percentage of the map to be covered in land. eg a map with 0.75 landCoverage will have 75% of the grid squares consist of land terrain types
--distanceBetweenIslands is how far apart initial island seeding points are
--edgeGap is the number of squares around the edge of the map that island land squares cannot occupy
--islandGap is the number of spaces between island shores
--the teamMappingTable (created with the CreateTeamMappingTable function) holds which players are on which teams and sets up islands appropriately
--playerStartTerrain is whatever type of terrain you are using to spawn your starting resources
--cliffChance denotes the likelihood of a cliff spawning on the shore of an island (gives a non-landable beach)
--inlandTerrainChance is a number from 0 to 1 denoting the chance to change a square of island land terrain into one of the other types passed in
--inlandTerrain is a table of terrain types that can be chosen to replace basic plains on islands (based on the inlandTerrainChance parameter)
--Here is a basic inlandTerrain table you can edit. Replace these terrain types with whatever you want your islands to be potentially comprised of.
inlandTerrain = {}
table.insert(inlandTerrain, tt_hills_low_rolling)
table.insert(inlandTerrain, tt_mountains_small)
table.insert(inlandTerrain, tt_plateau_low)
table.insert(inlandTerrain, tt_plateau_standard)


CreateIslandsTeamsTogether(weightTable, landCoverage, distanceBetweenIslands, edgeGap, islandGap, teamMappingTable, playerStartTerrain, cliffChance, inlandTerrainChance, inlandTerrain, terrainGrid)

--The CreateIslandsTeamsApart function works with the same parameters, but spreads the players around differently. Make sure to use an island number greater than or equal to the # of players.
CreateIslandsTeamsApart(weightTable, landCoverage, distanceBetweenIslands, edgeGap, islandGap, teamMappingTable, playerStartTerrain, cliffChance, inlandTerrainChance, inlandTerrain, terrainGrid)


--For more complex scripting examples, check out our existing procedural maps that came with the game.
--]]

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

--impasseDistance is the distance away from any of the impasseTypes that a viable player start needs to be. All squares closer than the impasseDistance will
--be removed from the list of squares players can spawn on.
impasseDistance = 2.5

--topSelectionThreshold is how strict you want to be on allies being grouped as closely as possible together. If you make this number larger, the list of closest spawn
--locations will expand, and further locations may be chosen. I like to keep this number very small, as in the case of 0.02, it will take the top 2% of spawn options only.
topSelectionThreshold = 0.02

--startBufferTerrain is the terrain that can get placced around player spawns. This terrain will stomp over other terrain. We use this to guarantee building space around player starts.
startBufferTerrain = tt_plains

--startBufferRadius is the radius in which we place the startBufferTerrain around each player start
startBufferRadius = 2

--placeStartBuffer is a boolean (either true or false) that we use to tell the function to place the start buffer terrain or not. True will place the terrain, false will not.
placeStartBuffer = true

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

