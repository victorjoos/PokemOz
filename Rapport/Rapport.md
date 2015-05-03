% PokemOz
% Antoine Vanderschueren and Victor Joos
%
# Component Diagram
Our component diagram is based in a large part on the lift example in section 5.4 of CTMCP [^ctmcp].

[^ctmcp]: VAN ROY, P., HARIDI, S., *Concepts, Techniques, and Models of Computer Programming*, The MIT Press, Cambridge.

![Component Diagram of the PokemOz game](ComponentDiagram.pdf)

Every one of these components are modeled using `NewPortObject` or an alternative `NewPortObjectKillable` which allows the game to stop the thread when it is no longer needed, to save on resources.

# State Diagrams
In this section we will show a state diagram for most of the components described above. This will hopefully provide an easy way to understand the high-level working of the program.

## Tile
![Tile State Diagram](TileState.pdf)
A Tile on the map has an easy state diagram. Each tile has a set of fixed coordinates that can be used by other port-objects to send a tile some messages, through the MapController. The `reserved` and `leaving` intermediate states allow a tile to refuse new Trainers wanting to go on a tile while another trainer is not yet on the tile, but is animating to it at the moment.


## PlayerController
![PlayerController State Diagram](TrainerControllerState.pdf)
This state diagram shows the states of both the PlayerController and the Trainer port-objects.

## FightController
![FightController State Diagram](FightControllerState.pdf)
The last important port-object is the FightController, which uses.
