# Vim: start here

You know `h j k l`. This guide adds a few commands at a time.
Do one step, try it, then move on. Do not rush: a week on
steps 1-6 is normal.

Practice in a scratch file so you cannot break anything:

```
nvim /tmp/practice.txt
```

## Three rules that save you

```
 Esc Esc   Lost? Press this and you are back in control.
 u         Undo. Made a mistake? Press u.
 :q!       Leave without saving (type it, press Enter).
```

## Step 1: Type some text

Vim has two modes. Normal mode is for commands (where you start).
Insert mode is for typing.

```
 i     start typing (insert mode)
 Esc   stop typing (back to normal mode)
```

Try it: press `i`, type these three lines (Enter between them),
then press `Esc`:

```
the quick brown fox
jumps over the lazy dog
and runs away
```

## Step 2: Move around

You know `h j k l`. Add these (in normal mode):

```
 w    next word          b    previous word
 0    start of line      $    end of line
 gg   top of the file    G    bottom of the file
```

Try it: press `gg`, then `w` three times, then `$`, then `G`.

## Step 3: Delete and undo

```
 x    delete one character     dd   delete the whole line
 dw   delete one word
 u    undo                     Ctrl-r   redo
```

Try it: press `gg`, then `w` to reach "quick", then `dw`. The
word disappears. Press `u` and it comes back. Press `Ctrl-r` to
delete it again. Then try `dd` on a line and `u`.

## Step 4: Copy and paste

```
 yy   copy the line       p    paste it below
```

Try it: press `yy` on the first line, then `p`. Now it is there
twice.

## Step 5: Search

```
 /fox then Enter   jump to "fox"
 n                 next match        N   previous match
```

Try it: type `/lazy` and press Enter.

## Step 6: Save and quit

```
 Ctrl-s   save        :q   quit        :q!   quit, discard changes
```

Try it: press `Ctrl-s`, then type `:q` and press Enter.

You now know enough to start real work. Come back here when a
step feels automatic.

## Level 2: verbs and objects (after about a week)

A command is a verb plus an object. Learn the verbs once and they
combine with everything.

```
 VERBS     d delete     c change     y copy
 OBJECTS   w word       $ to end of line     iw whole word
           ip paragraph (use ap to include the blank line)
```

```
 dw   delete word           cw   change word
 y$   copy to end of line   ciw  change the whole word
 ci(  change inside ( )     dap  delete a paragraph
 3dd  delete 3 lines        .    repeat the last change
 V    select whole lines (then j, k, then d to delete)
```

Try it: put the cursor in a word, press `ciw`, type a new word,
press `Esc`. Move to another word and press `.`: the same change
happens again.

## Level 3: finding things (this config)

`<leader>` is Space. Press it and wait: which-key shows the rest.

```
 <leader>ff  find files          <leader>/   grep the project
 <leader>,   switch buffer       <leader>e   file explorer
 <leader>sr  search and replace across the project
 s           flash: jump to any visible text (type s, then letters)
 %           matching bracket    Ctrl-o / Ctrl-i  jump back / forward
```

## Level 4: code (needs a language server)

Works in C++, Python, CMake and YAML files.

```
 gd  go to definition     gr  references      K  hover docs
 <leader>cr  rename       <leader>ca  code action
 <leader>cf  format       <leader>xx  all diagnostics
 ]d / [d  next / previous diagnostic
 <leader>ch  switch between header and source (C/C++)
```

## Level 5: reviewing agent changes

```
 <leader>gv   Diffview of the working tree
 <leader>gV   history of this file
 <leader>gg   lazygit
 ]h / [h      next / previous changed hunk (git-tracked files)
 <leader>ghp  preview hunk
 <leader>ghs  stage hunk
 <leader>ghr  reset hunk
 <leader>ab   send this buffer to Claude
 <leader>as   send the selection (visual mode)
 <leader>aa   accept a Claude diff
 <leader>ad   deny a Claude diff
```

Do not edit a file your agent is still changing;
read it first, then edit.

## Later

Macros (`qq` to record, `q` to stop, `@q` to replay), and more
text objects. Run `vimtutor` any time for a guided tour.
