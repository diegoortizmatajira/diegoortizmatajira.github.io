return {
	default = {
		-- file and directory options
		dir_path = "assets", ---@type string | fun(): string
		extension = "jpg", ---@type string | fun(): string
		file_name = "%Y-%m-%d-%H-%M-%S", ---@type string | fun(): string
		use_absolute_path = false, ---@type boolean | fun(): boolean
		relative_to_current_file = true, ---@type boolean | fun(): boolean
	},
}
