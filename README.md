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
do this, simply run `ozengine make_lib.ozf` or simply
follow the next section to have it done automatically.

## Running
You can run the program with `make run`. This will compile the game if
needed and will make the image library before running. (Using this
with oz 2.0 will not work due to a bug with terminating the program.)

### Command-line Arguments
You can use the following arguments :
    * --delay (-d)(int)
    * --speed (-s)(int)
    * --probability (-p)(int)
    * --map (-m)(int)

You can simply append these arguments when using `ozengine main.oza`, but
when using `make run`, you'll have to define them using the ARGS variable,
for example:

```shell
make run ARGS="-d50 -s5 -p30 --map Map.txt"
```

This will then run `ozengine main.oza -d50 -s5 -p30 --map Map.txt`.
