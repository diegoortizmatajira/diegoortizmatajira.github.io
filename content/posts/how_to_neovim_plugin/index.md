+++
date = '2025-09-06T14:11:56-04:00'
draft = true
title = 'How to create a Neovim plugin'
+++

This article's intention is to explain how to create a basic neovim plugin,
letting you understand the basics about its structure, how to add functionality,
add customizable config and finally expose new commands for users.

## Table of content

<!-- toc -->

- [Why Create a Neovim Plugin?](#why-create-a-neovim-plugin)
- [Tutorial Steps](#tutorial-steps)
  - [Step 1. Create a new repository](#step-1-create-a-new-repository)
  - [Step 2. Plugin File Structure](#step-2-plugin-file-structure)
  - [Step 3. Initial code for the plugin](#step-3-initial-code-for-the-plugin)
  - [Step 4. Testing your new plugin](#step-4-testing-your-new-plugin)
    - [Testing in a clean setup](#testing-in-a-clean-setup)
    - [Adding your plugin to your existing setup](#adding-your-plugin-to-your-existing-setup)
    - [Packer](#packer)
    - [Lazy.nvim](#lazynvim)
  - [Step 5. Adding config settings](#step-5-adding-config-settings)
  - [Step 6. Defining Functionality](#step-6-defining-functionality)
  - [Step 7. Exposing Commands](#step-7-exposing-commands)
  - [Step 8. Implementing the actual logic for the plugin](#step-8-implementing-the-actual-logic-for-the-plugin)

<!-- tocstop -->

## Why Create a Neovim Plugin?

Neovim isn't just a text editor—it's a productivity powerhouse for developers,
writers, and creators alike. What's truly exciting about Neovim is its ability
to adapt to your workflow through plugins. Whether you're looking to automate
repetitive tasks, enhance your coding experience, or add a personal touch to
your editor, plugins can make it happen. And the best part? You can create your
own plugin tailored to your needs, even if you're new to coding or Neovim.
Let's dive into how to make that happen!

## Tutorial Steps

Please follow those steps using your tools of preference.

### Step 1. Create a new repository

First step to create a plugin for people to include it in their Neovim setups
is to create a public repository.

- You can create it in github.com
- You must select the name for the plugin, when written in lua for neovim you
  can add ".nvim" to make it explicit.
- Add a description for your repository.
- You can choose to create a README.md file
- You can add a default .gitignore file

  ![Repository creation in github](./assets/2025-09-21-12-23-47.png)

Now you must clone the repository in your local machine (I will use
`~/Development/contrib/` as the location for my plugin repository folder):

- You can do it from the code editor directly (i.e. Neovim, VsCode, Sublime, etc.)
- Using a git UI client (i.e. [Github
  desktop](https://github.com/apps/desktop),
  [GitKraken](https://www.gitkraken.com/git-client),
  [SourceTree](https://www.sourcetreeapp.com/), etc.)
- Using your terminal:

  ```
  git clone <Your repository url>
  ```

  For this tutorial my repository url is:

  ```
  git clone git@github.com:diegoortizmatajira/workspace-scratch-files.nvim.git
  ```

Now you are ready to start working in your plugin.

### Step 2. Plugin File Structure

Before diving into code, it’s important to understand how plugins are
organized. At its core, a Neovim plugin is just a collection of script files,
often written in Lua or Vimscript. These files are responsible for adding
functionality to your editor.

Here’s a simple structure to keep in mind where `myplugin` is the name you gave
to your plugin:

```
myplugin.nvim/
├── lua/
│   └── myplugin/
│       └── init.lua
└── README.md
```

- **lua/**: This folder contains all Lua scripts.
- **myplugin/**: A namespace for your plugin files.
- **init.lua**: This is the entry point for your plugin.

Keeping your plugin well-structured not only helps you stay organized but also
makes it easier for others to contribute.

For this tutorial we'll start by creating the following basic structure:

```
~/Development/contrib/workspace-scratch-files.nvim/..
├── lua
│   └── workspace-scratch-files
│       └── init.lua
├── .gitignore
├── LICENSE
└── README.md
```

### Step 3. Initial code for the plugin

In `workspace-scratch-files/init.lua`, start with something simple like:

```lua
local M = {}

function M.setup()
    -- Your setup code here
    vim.notify("Workspace Scratch Files initialized")
end

return M
```

This will give you a working plugin that simply prints a message when setup.

### Step 4. Testing your new plugin

If you want to test your plugin, you have two options:

- Testing it in a clean setup
- Adding the plugin to your existing setup

#### Testing in a clean setup

You can create a test `init.lua` file and start Neovim with this init config file.

```
nvim -u <your test init.lua>

```

For example you can add a `test/init.lua` file with the next content:

```lua
--- You will be adding your plugin code the runtime path (to use it without a
--- plugin manager)

vim.opt.runtimepath:prepend(vim.fn.getcwd())

local plugin = require("workspace-scratch-files")
plugin.setup()

```

Then, from the **root folder in your repository** you can run the following command
in a terminal (this tells Neovim to use our test init config file):

```bash
nvim -u test/init.lua
```

And you will see this (note the message at the bottom):

![Clean run for the plugin](assets/2025-09-21-13-43-04.png)

#### Adding your plugin to your existing setup

If you want to add your plugin, you will need to add your repository path into
your plugin manager as a new plugin, those instructions will depend on your
plugin manager:

#### Packer

```lua
use {
    "~/Development/contrib/workspace-scratch-files.nvim",
    config = function()
        require("workspace-scratch-files").setup()
    end
}
```

#### Lazy.nvim

```lua
{
    dir = "~/Development/contrib/workspace-scratch-files.nvim",
    opts = {}
}
```

And you will see your normal setup and the new plugin added to it (note the
notification popup at the bottom-right corner):

![New plugin added to existing config](assets/2025-09-21-14-05-58.png)

{{< alert alert-info >}}
You can see the code in the repository at this stage in github at the
[Steps-1-to-3](https://github.com/diegoortizmatajira/workspace-scratch-files.nvim/tree/steps-1-to-3)
tag
{{< /alert >}}

### Step 5. Adding config settings

Create a `workspace-scratch-files/config.lua` module file.

It is recommended (Not mandatory) to add comments and annotations to the types
definitions, to help any further development to be consistent and
self-documented.

```lua
--- @class Scratch.config
--- @field test_message string A test message for demonstration purposes.

local C = {
    --- Default configuration settings for the Scratch plugin.
    --- @type Scratch.config
    default = {
        test_message = "Hello from Scratch plugin!",
    },
    --- Current configuration settings for the Scratch plugin.
    --- @type Scratch.config?
    current = nil,
}

--- Updates the current configuration with a new configuration.
--- If the provided configuration is not a table or is nil, the update is ignored.
--- @param new_config? Scratch.config new configuraton to be applied
function C.update(new_config)
    --- Initializes or overrides the current configuration with the new configuration.
    --- If no current configuration exists, it defaults to the default configuration.
    C.current = vim.tbl_deep_extend("force", C.current or C.default, new_config
        or {})
end

return C
```

Back into `workspace-scratch-files/init.lua`, modify the code to use our config module

```lua
local config = require("workspace-scratch-files.config")

local M = {}

function M.setup(opts)
    config.update(opts)
    -- Your setup code here
    vim.notify(config.current.test_message)
end

return M
```

if we just run our test environment without adding specific configuration, we
will get the default message:

![Running with default config](assets/2025-09-22-07-59-54.png)

If we provide custom settings in our clean setup(`test/init.lua`):

```lua {hl_lines=["7-9"]}
--- You will be adding your plugin code the runtime path (to use it without a
--- plugin manager)

vim.opt.runtimepath:prepend(vim.fn.getcwd())

local plugin = require("workspace-scratch-files")
plugin.setup({
    test_message = "This is a custom test message!",
})

```

or modify the plugin options in our plugin manager:

- Packer

  ```lua {hl_lines=["4-6"]}
  use {
    "~/Development/contrib/workspace-scratch-files.nvim",
    config = function()
        require("workspace-scratch-files").setup({
            test_message = "This is a custom test message!",
        })
    end
  }
  ```

- Lazy.nvim

  ```lua {hl_lines=["3-5"]}
  {
    dir = "~/Development/contrib/workspace-scratch-files.nvim",
    opts = {
        test_message = "This is a custom test message!",
    }
  }
  ```

You will see something like the following result (see customized message at the bottom):

![Custom message from settings](assets/2025-09-22-09-21-26.png)

### Step 6. Defining Functionality

Now we are going to create the code that defines the functionality we want to
expose.

Note: We can implement this part directly in init.lua, but it is recommended to
have a clear separation of responsibilities:

- init.lua: Only exposes the setup method and commands to neovim.
- individual additional modules implement specific features only, this way it
  is easier to manage how they are implemented.

So, we are going to create an individual module for the actual implementation
of our features, we can start just creating the placeholders for each function.

Let's create a new file `workspace-scratch-files/core.lua` with:

```lua
local M = {}

function M.delete_scratch_file(file_path)
    vim.notify("Deleting scratch file: " .. file_path)
end

function M.search_scratch_files()
    vim.notify("Searching scratch files...")
end

function M.create_scratch_file()
    vim.notify("Creating a new scratch file...")
end

return M

```

Actual implementation will be done later, for now we have defined our features
in this core module.

### Step 7. Exposing Commands

Exposing commands makes it easy for users to interact with your plugin. Always
choose clear and descriptive names for these commands. Use
[vim.api.nvim_create_user_command](<https://neovim.io/doc/user/api.html#nvim_create_user_command()>)
to define them, as shown below.

`workspace-scratch-files/init.lua`:

```lua {hl_lines=[2,"10-19"]}
local config = require("workspace-scratch-files.config")
local core = require("workspace-scratch-files.core")

local M = {}

function M.setup(opts)
    config.update(opts)
    -- Your setup code here
    vim.notify(config.current.test_message)
    -- Create user commands: ScratchDelete, ScratchSearch, ScratchNew
    vim.api.nvim_create_user_command("ScratchNew", function()
        core.create_scratch_file()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("ScratchSearch", function()
        core.search_scratch_files()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("ScratchDelete", function()
        core.delete_scratch_file()
    end, { nargs = 0 })
end

return M
```

Now you can run your neovim test environment and see our three commands
available in neovim (If you run them, they will display their corresponding
test messages):

![New commands available](assets/2025-09-22-11-17-28.png)

For example if you execute `:ScratchSearch` you will see:

![Sample execution of ScratchSearch](assets/2025-09-22-11-18-11.png)

{{< alert alert-info >}}
You can see the code in the repository at this stage in github at the
[Steps-4-to-7](https://github.com/diegoortizmatajira/workspace-scratch-files.nvim/tree/Steps-4-to-7)
tag
{{< /alert >}}

### Step 8. Implementing the actual logic for the plugin

---

By the end of these steps, you’ll have created a basic Neovim plugin and
exposed commands that users can run. From here, the possibilities are
endless—explore Neovim’s API and Lua’s capabilities to build something truly
unique!
