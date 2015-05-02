# PokemOz
This program is a pokemon game using the Oz language.
read on for the running instructions.

## Compiling
To compile the entire game, simply use `make`
which will compile all the functors needed to run the game
and will make an main.oza file which you can run using : 

```shell
ozengine main.oza
```

Before running the game make sure to also build the image library,
otherwise the game will leave you with a lackluster impression. To
do this, simply run `make lib` or simply follow the next section
to have it done automatically.

## Running
You can run the program with `make run`. This will compile the game if
needed and will make the image library before running.
