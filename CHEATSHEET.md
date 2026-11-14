# Cheatsheet

`<leader>` is Space. Press it and wait: which-key shows what is
available. Sections 1-3 are standard Vim and work anywhere.
Sections 4-6 are keys from this config; each was checked in a
running nvim.

Learn in this order and add nothing new until the previous section
feels automatic. New to Vim? Run `vimtutor` first (about 30
minutes, safe: it edits a temporary copy).

## 1. Survival kit (about 20 commands)

```
 MODES      i  type before cursor     a  type after cursor
            o  new line below
            Esc  back to normal mode (always the way out)

 SAVE/QUIT  Ctrl-s  save   :q  quit   :q!  quit, discard changes

 UNDO       u  undo        Ctrl-r  redo

 MOVE       w  next word      b  previous word
            0  line start     $  line end
            gg  top of file   G  bottom of file

 DELETE     x  one character   dd  whole line   dw  one word

 COPY/PASTE yy  copy line      p  paste

 SEARCH     /word Enter, then  n  next match   N  previous match
```

Lost? Press `Esc` twice, then `u`. To leave without saving: `:q!`.

## 2. Editing

```
 OPERATOR   d delete, c change, y copy, then a motion
 + MOTION   dw  delete word        c$  change to end of line
            y2w  copy 2 words

 COUNTS     3dd  delete 3 lines    5j  down 5 lines

 TEXT       ciw  change word       ci(  change inside ( )
 OBJECTS    dap  delete paragraph  yit  copy inside tag

 REPEAT     .  repeat the last change

 MACROS     qq  record into q (q to stop)     @q  replay

 VISUAL     v  select characters   V  select lines
            then d, y, > or <
```

## 3. Moving around

```
 %  matching bracket        { }  previous / next paragraph
 Ctrl-o / Ctrl-i  jump back / forward
 s  flash: jump to any visible text (type s, then the letters)
```

## 4. Finding things (this config)

```
 <leader>ff  find files          <leader>/   grep the project
 <leader>,   switch buffer       <leader>e   file explorer (Neo-tree)
 <leader>sr  search and replace across the project
```

## 5. Code (needs a language server: C++, Python, CMake, YAML)

```
 gd  go to definition     gr  references      K  hover docs
 <leader>cr  rename       <leader>ca  code action
 <leader>cf  format       <leader>xx  all diagnostics
 ]d / [d  next / previous diagnostic
 <leader>ch  switch between header and source (C/C++)
```

## 6. Reviewing agent changes

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
