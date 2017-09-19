# About
Provides a simple utility for switching workspaces in i3. Inspired somewhat by GNOME 3's workspace switcher.

Normally, i3 will not create new workspaces when switching to the prev/next workspaces. Further, workspaces without windows are automatically closed. This forces users to use a short cut like Win+n to switch to workspace n if it does not have a window on it.

This tool switches simply by counting off workspaces. For example, if you currently have these workspaces active (ie, have windows on them):

```
+-+-+-+
|1|2|3|
+-+-+-+
```

and you are on workspace 3, then calling `i3switcher next` will move you to workspace 4, leaving you with these workspaces

```
+-+-+-+-+
|1|2|3|4|
+-+-+-+-+
```

calling `i3switcher next` again will move you to workspace 5, but leave you with

```
+-+-+-+-+
|1|2|3|5| # Notice that i3 removes 4 just like normal
+-+-+-+-+
```
