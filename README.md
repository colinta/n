 n
===

`n` was written specifically so that I could check the status on my Sublime Text 2 packages.  They live in my .../Packages folder, along with a bunch of *other* packages.  The workflow I wanted (and, of course, `n` achieves) is something like this:

Note: The first command, `b subl`, uses <https://github.com/rockymeza/b>

```
~ > b subl
Packages > n MoveText FileDiffs SimpleMovement
MoveText > n
FileDiffs > n
SimpleMovement > n
Packages >
```

So that's neat, it cycles through each entry that was specified at the start.

To help with "where am I?" and "oops" and "COOL!" kind of situations, there are some commands you can pass as the first argument.  Actually, *everything* you can do is broken into `__n_cmd` functions.  Calling `n --something` will look for a `__n_something` command and execute it with the remaining arguments.

In this way, `n folder1 folder2` is the same as `n --set folder1 folder2` and `n` is the same as `n --next`.

The full list of commands is:

* `n --set $@`:
  Starts a new `n` session, and assigns the folders "$@" to it
* `n --next` or `n -n`:
  cd to the next entry
* `n --prev` or `n -p`:
  cd to the previous entry
* `n --curr` or `n -c`:
  cd to the current entry
* `n --reset` or `n -0`:
  cd to the "root" folder (where `n --set` was initiated)
* `n --list` or `n -l`:
  Lists the folders in the current session, and marks the current entry
* `n --shell` or `n -i`:
  This is neat!  It creates a subshell in each folder.  `ctrl+d` (`logout`) will go to the *next subshell*.  If you have good `ctrl+o`-foo, you can perform some complicated operations this way.
* `n --save` or `n -s`:
  Saves the current session to `.n_saved` in the "root" folder.
* `n --recall` or `n -r`:
  Recalls a session by looking for `.n_saved` in the current folder.
* `n --exec $@`
  Goes to each folder and executes the commands in $@ in each.
  You should *quote* these commands.  See example below.


Examples
========

 list
------

```
~ > b subl
Packages > n MoveText FileDiffs SimpleMovement
MoveText > n --list
~/Library/Application Support/Sublime Text 2/Packages
 * MoveText
   FileDiffs
   SimpleMovement
```

 next / prev
-------------

```
MoveText > n
FileDiffs > n --prev
MoveText > n --next
FileDiffs > cd ..
```

 reset / curr
 -------------

```
Packages > n --curr
FileDiffs > n
SimpleMovement > n --list
~/Library/Application Support/Sublime Text 2/Packages
   MoveText
   FileDiffs
 * SimpleMovement
SimpleMovement > n --reset
Packages > n
```

 shell
-------

```
MoveText > n --shell
>>> in MoveText (1 of 3) <<<
MoveText > logout
>>> in FileDiffs (2 of 3) <<<
FileDiffs > logout
>>> in SimpleMovement (3 of 3) <<<
SimpleMovement > logout
<<< AND WE'RE BACK >>>
```

 exec
------

```
MoveText > n -exec 'ls -1' 'echo HI'
>>> in MoveText (1 of 3) <<<
move_text.py
...
HI
>>> in FileDiffs (2 of 3) <<<
file_diffs.py
...
HI
>>> in SimpleMovements (3 of 3) <<<
simple_movements.py
...
HI
<<< AND WE'RE BACK >>>
```

 save / restore
----------------

```
MoveText > cd ..
Packages > n -s
Packages > n -r
MoveText > n --list
~/Library/Application Support/Sublime Text 2/Packages
 * MoveText
   FileDiffs
   SimpleMovement
```

Enjoy!
