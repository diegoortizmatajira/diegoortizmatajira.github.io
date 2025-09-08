+++
date = '2025-09-06T14:11:56-04:00'
draft = true
title = 'How to create a Neovim plugin'
+++

This article intention is to explain how to create a basic neovim plugin,
letting you understand th basics about its structure, how to add functionality,
add customizable config, expose new commands for users.

## Why Create a Neovim Plugin?

Neovim isn't just a text editor—it's a productivity powerhouse for developers,
writers, and creators alike. What's truly exciting about Neovim is its ability
to adapt to your workflow through plugins. Whether you're looking to automate
repetitive tasks, enhance your coding experience, or add a personal touch to
your editor, plugins can make it happen. And the best part? You can create your
own plugin tailored to your needs, even if you're new to coding or Neovim.
Let's dive into how to make that happen!

## Plugin File Structure

Before diving into code, it’s important to understand how plugins are
organized. At its core, a Neovim plugin is just a collection of script files,
often written in Lua or Vimscript. These files are responsible for adding
functionality to your editor.

Here’s a simple structure to keep in mind:

```
my-awesome-plugin/
├── lua/
│   └── myplugin/
│       ├── init.lua
│       └── features.lua
└── README.md
```

- **lua/**: This folder contains all Lua scripts.
- **myplugin/**: A namespace for your plugin files.
- **init.lua**: This is the entry point for your plugin.
- **features.lua**: A separate file where you organize specific functionalities.

Keeping your plugin well-structured not only helps you stay organized but also
makes it easier for others to contribute.

## Steps

### Creating the Repository

First things first, create a Git repository to host your plugin code. This will
allow you to track changes and share your work with others.

If you're unfamiliar with Git, here’s a quick way to get started:

1. Open your terminal and navigate to the folder where you want to store your
   plugin.
2. Run the following commands:

   ```bash
   mkdir my-awesome-plugin
   cd my-awesome-plugin
   git init
   ```

3. Create a `README.md` file to describe your plugin.

### Scaffolding

Once your repository is ready, set up the file structure we discussed earlier.
You can create these files manually, or use a script to generate them. For
example:

```bash
mkdir -p lua/myplugin
cd lua/myplugin
nvim init.lua
```

In `init.lua`, start with something simple like:

```lua
-- This is the entry point for your plugin
print("Hello from My Awesome Plugin!")
```

This will give you a working plugin that simply prints a message when loaded.

### Referencing Your Plugin in Your Neovim Setup

To test your plugin, you need to tell Neovim where to find it. Add the plugin’s
path to your runtime path by editing your `init.lua` or `init.vim` file:

```lua
vim.opt.runtimepath:prepend("/path/to/my-awesome-plugin")
```

Restart Neovim and you should see the "Hello from My Awesome Plugin!" message.

### Adding Functionality

Now comes the fun part—adding features to your plugin. Let’s say you want to
create a command that echoes "Hello, [a custom name]!".

For more advanced functionality, you can create a separate Lua module
(`features.lua`) and call its functions from `init.lua`:

`features.lua`:

```lua
local M = {}

function M.greet(name)
  print("Hello, " .. name .. "!")
end

return M
```

### Adding config settings

Create a config.lua file.

```lua
local M = {
    default = {},
    current= {},
}
```

### Exposing Commands

Exposing commands makes it easy for users to interact with your plugin. Always
choose clear and descriptive names for these commands. Use
`vim.api.nvim_create_user_command` to define them, as shown above.

`init.lua`:

```lua
local features = require("myplugin.features")

vim.api.nvim_create_user_command(
  'Greet',
  function(opts)
    features.greet(opts.args)
  end,
  { nargs = 1 }
)
```

Now you can run `:Greet Alice` and see "Hello, Alice!" in your Neovim.

---

By the end of these steps, you’ll have created a basic Neovim plugin and
exposed commands that users can run. From here, the possibilities are
endless—explore Neovim’s API and Lua’s capabilities to build something truly
unique!
