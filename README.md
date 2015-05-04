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
do this, simply run `ozc -c make_lib.oz` followed by `ozengine make_lib.ozf` or simply follow the next section to have it done automatically.

## Running
You can run the program with `make run`. This will compile the game if
needed and will make the image library before running. (Using this
with oz 2.0 will not work due to a bug when terminating the program.)

To terminate the program in Oz 2.0 close the window and hit C-c in the terminal.  This won't happen in Oz 1.4.

### Command-line Arguments
You can use the following arguments :
    * --delay (-d)(int) : the delay for most of the animations
    * --speed (-s)(int) : the speed of the trainers
    * --probability (-p)(int) : how probable wild pokemoz are
    * --map (-m)(string) : the name of the map file
    * --npc (-n)(string) : the name of the enemy file
    * --ai (-a)(boolean) : whether to run the ai (it's slow on some maps)
    * --autorun (-r)(boolean)
    * --autofight (-f)(boolean)

You can simply append these arguments when using `ozengine main.oza`, but
when using `make run`, you'll have to define them using the ARGS variable,
for example:

```shell
make run ARGS="-d50 -s5 -p30 --map Map.txt"
```

This will then run `ozengine main.oza -d50 -s5 -p30 --map Map.txt`.

## Playing

You can play the game with the arrows and <a> and <z>.
