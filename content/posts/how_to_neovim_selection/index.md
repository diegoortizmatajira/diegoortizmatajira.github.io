+++
date = '2025-10-03T10:42:00-04:00'
title = 'How to get selected text with Neovim and Lua'
draft = false
tags = [ 'Neovim' ]
categories = [ 'Development' ]
+++

This short article showcases some forms for retrieving the visual selected text or
treesitter node at cursor in Neovim using Lua and Neovim API.

<!--more-->

## Table of content

<!-- toc -->

- [Simple approach](#simple-approach)
- [Looking for current Treesitter node text](#looking-for-current-treesitter-node-text)

<!-- tocstop -->

## Simple approach

The following snipped will allow you to get the visual selection from a given
buffer (by providing the bufnr, or nil for current one).

It also takes into account if the current selection mode is `v` or `V` for full
lines selection.

```lua
--- Retrieves the visually selected text in the current buffer.
---
--- This function identifies the range of visually selected lines in the current
--- buffer and extracts the selected text. It adjusts the text boundaries to
--- ensure only the selected portion is included, considering both the start
--- and end columns of the selection.
---
--- The function is useful for scenarios where a specific portion of the text
--- needs to be processed, such as running a database query on a selected range
--- of lines.
---
--- @return string The text within the visually selected range, or an empty
--- string if no text is selected.
function get_visual_selection(bufnr)
    local mode = vim.api.nvim_get_mode().mode
    if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
        return "" -- Not in visual mode
    end
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local start = vim.fn.getpos("v")
    local end_ = vim.fn.getpos(".")
    local start_row = start[2] - 1
    local start_col = start[3] - 1
    local end_row = end_[2] - 1
    local end_col = end_[3] - 1

    -- A user can start visual selection at the end and move backwards
    -- Normalize the range to start < end
    if start_row == end_row and end_col < start_col then
        end_col, start_col = start_col, end_col
    elseif end_row < start_row then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    end
    if mode == "V" then
        start_col = 0
        local lines = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, true)
        end_col = #lines[1]
    end
    local lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row,
        end_col + 1, {})
    return table.concat(lines, "\n")
end

```

## Looking for current Treesitter node text

For some specific scenarios you may not only want to get the visually selected
text, but a entire block of text representing a specific code element (such as
a full SQL statement).

Using neovim API you can get the Treesitter node where your cursor is. But, if
you want to find a larger Treesitter node containing your current cursor, the
following set of functions may help you.

{{< alert alert-info >}}
For this code to work, you will need to have the `nvim-treesitter` plugin in
your setup ([nvim-treesitter plugin page](https://github.com/nvim-treesitter/nvim-treesitter)).
{{< /alert >}}

You can create a new lua module file with the following content.

```lua

local L = {}

--- Finds the index of a value in an array.
---
--- This function iterates over the provided array and checks if the specified value
--- is present. If found, it returns the index of the value. If the value is not found,
--- the function returns `nil`.
---
--- @param array table The array to search through.
--- @param value any The value to find in the array.
--- @return number|nil The index of the value if found, or `nil` otherwise.
local function index_of(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil -- si no se encuentra el valor
end

--- Retrieves matches from a parsed Treesitter query based on the specified parameters.
---
--- @param query_string string The Treesitter query string to be parsed.
--- @param lang string The language of the current buffer.
--- @param filter_func? fun(match: TSNode[], captures: string[]):boolean A
--- function to filter matches. Receives the match and captures as arguments.
--- @param map_func? fun(match: TSNode[], captures: string[]):any A function to
--- transform the captured node. Receives the match and captures as arguments.
--- @param max_results number|nil The maximum number of results to return.
---
--- @return table A list of captured nodes that match the query, filtered and
--- transformed as specified.
function L.get_matches(query_string, lang, filter_func, map_func, max_results)
    local ts_utils = require("nvim-treesitter.ts_utils")
    local ts_query = require("vim.treesitter.query")

    local bufnr = vim.api.nvim_get_current_buf()

    -- Parse the query
    local query = ts_query.parse(lang, query_string)

    -- Get the root syntax tree node
    local root = ts_utils.get_root_for_position(unpack(vim.api.nvim_win_get_cursor(0)))
    if not root then
        return {}
    end

    local results = {}
    local count = 0
    -- Iterate over matches
    for _, match, _ in query:iter_matches(root, bufnr, 0, -1) do
        if not filter_func or filter_func(match, query.captures) then
            local mapped_result = map_func and map_func(match, query.captures)
                or match
            if mapped_result then
                table.insert(results, mapped_result)
                count = count + 1
                if max_results and count >= max_results then
                    break
                end
            end
        end
    end
    return results
end

--- Gets the text of all captures that match the query
--- @param query_string string The treesitter query string
--- @param lang string The language of the current buffer
--- @param node_capture_name string The name of the capture that contains the
--- node to check
--- @param text_capture_name string|nil The name of the capture that contains
--- the text to return (if different from node_capture_name)
--- @param filter_func? fun(match: TSNode[], captures: string[]):boolean A
--- function to filter matches. Receives the match and captures as arguments.
--- @param max_results number|nil The maximum number of results to return.
--- @return string[] A list of texts of the captures that match the query
function L.get_match_texts(query_string, lang, node_capture_name,
    text_capture_name, filter_func, max_results)
    if not text_capture_name then
        text_capture_name = node_capture_name
    end
    return L.get_matches(query_string, lang, filter_func, function(match, captures)
        -- Return the text of the text capture
        local text_capture_index = index_of(captures, text_capture_name)
        if not text_capture_index then
            return nil
        end
        local captured_node = match[text_capture_index][1]
        local bufnr = vim.api.nvim_get_current_buf()
        return vim.treesitter.get_node_text(captured_node, bufnr)
    end, max_results)
end

--- Gets the text of the capture at the cursor position
--- @param query_string string The treesitter query string
--- @param lang string The language of the current buffer
--- @param node_capture_name string The name of the capture that contains the
--- node to check
--- @param text_capture_name string|nil The name of the capture that contains
--- the text to return (if different from node_capture_name)
--- @return string The text of the capture at the cursor position, or an empty
--- string if not found
function L.get_match_text_at_cursor(query_string, lang, node_capture_name, text_capture_name)
    local node_at_cursor = vim.treesitter.get_node()
    if not node_at_cursor then
        return ""
    end
    local matches = L.get_match_texts(
        query_string,
        lang,
        node_capture_name,
        text_capture_name,
        function(match, captures)
            -- Check if the node at cursor is within the captured node
            local capture_index = index_of(captures, node_capture_name)
            if not capture_index then
                return false
            end
            local captured_node = match[capture_index][1]
            return captured_node == node_at_cursor
                or vim.treesitter.is_ancestor(captured_node, node_at_cursor)
        end,
        1
    )
    return matches and matches[1] or ""
end

return L
```

Now you can use those functions with a Treesitter query and get the text you want.

Let's use a `docker-compose.yaml` file as example:

- It is a `YAML` file.
- There is a `yaml` treesitter parser.
- You want to obtain the list of service names.
- You want to obtain the service name where your cursor is located (you are in
  any position inside the service definition)

```lua
--- replace with the module you just build in the previous step
local ts = require('your_module_file')

--- Defines the query to retrieve locate the 'services' key and all their
--- defined children.
--- 'services-key': Used to locate the 'services' parent.
--- 'service-node': Used to identify the whole block of service definition,
---                 where your cursor may be.
--- 'service-name': Used to obtain only the name for a given service.
local ts_compose_services_query = [[
(block_mapping_pair
  key: ((flow_node) @services-key (#eq? @services-key "services"))
  value: (block_node
    (block_mapping (block_mapping_pair
      key: (flow_node) @service-name
    ) @service-node)
  )
)]],


--- Retrieves a list of services defined in a Docker Compose YAML file.
---
--- This function uses Tree-sitter to parse the YAML structure and extract
--- the names of all the services defined under the "services" key in a
--- Docker Compose file. It returns a table containing the service names.
---
--- @return table: A table of strings, where each string represents a service name.
--- @usage
--- local services = docker_compose_get_services()
--- for _, service in ipairs(services) do
---     print(service)
--- end
local function docker_compose_get_services()
    local services = ts.get_match_texts(L.ts_compose_services_query, "yaml",
        "service-node", "service-name")
    return services
end


--- Retrieves the Docker Compose service name at the current cursor position.
---
--- This function uses Tree-sitter to identify and extract the service name
--- under the cursor within a Docker Compose YAML file. If no service name
--- is found at the cursor, an empty string is returned.
---
--- @return string: The name of the service at the cursor, or an empty string if
--- no service is found.
--- @usage
--- local service = docker_compose_get_service_at_cursor()
--- if service ~= "" then
---     print("Service at cursor: " .. service)
--- else
---     print("No service found at cursor.")
--- end
local function docker_compose_get_service_at_cursor()
    local service = ts.get_match_text_at_cursor(L.ts_compose_services_query,
        "yaml", "service-node", "service-name")
    return service
end

--- Retrieves the Docker Compose service body at the current cursor position.
---
--- This function uses Tree-sitter to identify and extract the service body
--- under the cursor within a Docker Compose YAML file. If no service
--- is found at the cursor, an empty string is returned.
---
--- @return string: The name of the service at the cursor, or an empty string if
--- no service is found.
--- @usage
--- local service = docker_compose_get_service_at_cursor()
--- if service ~= "" then
---     print("Service at cursor: " .. service)
--- else
---     print("No service found at cursor.")
--- end
local function docker_compose_get_service_body_at_cursor()
    local service = ts.get_match_text_at_cursor(L.ts_compose_services_query,
        "yaml", "service-node", "service-node")
    return service
end

```

If you have the following docker compose file:

```yaml
services:
  backend:
    build:
      context: backend
      target: builder
    ...
  db:
    # We use a mariadb image which supports both amd64 & arm64 architecture
    image: mariadb:10-focal
    # If you really want to use MySQL, uncomment the following line
    #image: mysql:8
    ...
  proxy:
    build: proxy
    ...
```

Those functions will return:

| Function                                  | Result                         | Condition                                                          |
| ----------------------------------------- | ------------------------------ | ------------------------------------------------------------------ |
| docker_compose_get_services               | List: `backend`, `db`, `proxy` | Always                                                             |
| docker_compose_get_service_at_cursor      | Single: `backend`              | If your cursor is anywhere inside the 'backend' service definition |
| docker_compose_get_service_at_cursor      | Single: ``                     | If your cursor is anywhere outside a service definition            |
| docker_compose_get_service_body_at_cursor | Single: full service body      | If your cursor is anywhere inside the 'backend' service definition |

Hope this will help you with your Neovim skills to build productivity tools.
