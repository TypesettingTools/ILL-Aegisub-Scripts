import Tag  from require "ILL.ILL.Ass.Text.Tag"
import Util from require "ILL.ILL.Util"

class Tags

	-- sets the tag value
	set: (@tags) =>
		-- corrects the positioning of the transformation tags,
		-- some of them may be internally grouped,
		-- which would be functional, but not ideal
		-- to manipulate
		move = (val) ->
			new = ""
			val = val\match "%((.+)%)"
			while val
				tag = val\gsub "\\t%b()", ""
				val = val\match "\\t%((.+)%)"
				new ..= "\\t(#{tag})"
			return new
		-- fix "\\t(\\t(\\t()))" --> "\\t()\\t()\\t()"
		@tags = @tags\gsub "\\t%b()", (t) -> move t
		-- fix "\\1c&H000000&" --> "\\c&H000000&"
		@tags = @tags\gsub "\\1c%s*(&?[Hh]%x+&?)", "\\c%1"
		-- fix "\\fr360" --> "\\frz360"
		@tags = @tags\gsub "\\fr%s*(%-?%d[%.%d]*[eE%-%+%d]*)", "\\frz%1"

	get: => @tags

	new: (tags) => @set tags

	-- removes the keys that close the tags
	open: =>
		{:tags} = @
		if c = tags\match "%{(.-)%}"
			@tags = c
		return @

	-- inserts the keys that close the tags
	close: =>
		{:tags} = @
		unless tags\match "%b{}"
			@tags = "{" .. tags .. "}"
		return @

	-- hides or unhides the tag \t of the tags
	animated: (cmd = "hide") =>
		if cmd == "hide"
			@tags = @tags\gsub "\\t%b()", (t) -> t\gsub "\\", "\\@"
		else
			@tags = @tags\gsub "\\@", "\\"

	-- removes one or more tags simultaneously
	remove: (...) =>
		remove = (argument) ->
			if type(argument) == "table" and #argument > 0 and #argument <= 3
				{name, replace, n} = argument
				@tags = @tags\gsub Tag.getPattern(name), replace or "", n
			elseif type(argument) == "string"
				switch argument
					when "all"
						for tag in pairs ASS_TAGS
							@remove tag
					when "font"
						@remove "fn", "fs", "fsp", "b", "i", "u", "s", "fscx", "fscy"
					when "perspective"
						@remove "fax", "fay", "frx", "fry", "frz", "fscx", "fscy", "org"
					when "colors"
						@remove "c", "2c", "3c", "4c"
					when "shadow"
						@remove "xshad", "yshad", "shad"
					when "outline"
						@remove "xbord", "ybord", "bord"
					else
						@tags = @tags\gsub Tag.getPattern(argument), ""
			else
				error "invalid argument type", 2
		-- removes all arguments into tags
		for argument in *{...}
			remove argument
		return @

	-- inserts one or more tags simultaneously
	insert: (...) =>
		@open!
		insert = (argument) ->
			if type(argument) == "table" and #argument > 0 and #argument <= 2
				{tag, invert} = argument
				if type(tag) == "table"
					{name, value} = tag
					tag = Tag\setValue(name, value)\__tostring!
					-- if tag already exists replace it
					if @existsTag name
						@remove {name, tag, 1}
					else
						insert {tag, invert}
				else
					@tags = invert and tag .. @tags or @tags .. tag
			elseif type(argument) == "string"
				@tags ..= argument
			else
				error "invalid argument type", 2
		-- inserts all arguments into tags
		for argument in *{...}
			insert argument
		@close!
		return @

	-- gets the value of a given tag within the tag layer
	getTag: (name, subTags = @tags) =>
		notIsAnimated = name != "t"
		if notIsAnimated
			@animated "hide"
		a = Tag.getPattern name
		b = Tag.getPattern name, true
		if value = @tags\match a
			res = Tag value, name, value\match(b), subTags\find value, 1, true
			if notIsAnimated
				@animated "unhide"
			return res
		if notIsAnimated
			@animated "unhide"

	-- separates all tags and gets all possible information about them
	split: =>
		split, copy = {}, Tags @tags
		-- does split processing on all the tags
		process = (name) ->
			if tag = copy\getTag name, @tags
				table.insert split, tag
				copy\remove {name, "", 1}
		-- does processing on all tags
		for k, v in pairs ASS_TAGS
			while copy\existsTag k
				process k
		-- fixes the position of the array to the original tag position
		table.sort split, (a, b) -> a.i < b.i
		-- removes all tags that have been reset by the \r tag
		for i = 1, #split
			if split[i].name == "r"
				for j = 1, i - 1
					table.remove split, 1
				break
		-- gets the reconstructed version of the tags
		split.__tostring = ->
			return table.concat [s\__tostring! for s in *split]
		return split

	-- clean up the tags
	clean: =>
		split = @split!
		@tags = split.__tostring!
		@close!
		return @

	-- checks if the tag exists in the tags
	existsTag: (name) =>
		if name != "t"
			@animated "hide"
			if @tags\match Tag.getPattern name
				@animated "unhide"
				return true
			@animated "unhide"
			return false
		else
			if @tags\match Tag.getPattern "t"
				return true
			return false

	-- checks if the tag exists in the tags
	-- if any all tags exists returns true
	existsTagAnd: (...) =>
		for name in *{...}
			unless @existsTag name
				return false
		return true

	-- checks if the tag exists in the tags
	-- if any of the tags exists returns true
	existsTagOr: (...) =>
		for name in *{...}
			if @existsTag name
				return true
		return false

	__tostring: => @tags\gsub("{%s*}", "")\gsub "\\t%(([%.%d]*)%,?([%.%d]*)%,?([%.%d]*)%,?%)", ""

{:Tags}