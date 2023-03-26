import Table from require "ILL.ILL.Table"
import Util  from require "ILL.ILL.Util"
import Aegi  from require "ILL.ILL.Aegi"
import Text  from require "ILL.ILL.Ass.Text.Text"

hasInspector, Inspector = pcall require, "SubInspector.Inspector"

class Ass

	set: (@sub, @sel, @activeLine, @remLine = true) =>
		-- sets the selection information
		@i, @fi, @newSelection = 0, 0, {}
		for l, i in @iterSub false
			if l.class == "dialogue"
				-- number of the first line of the dialog
				@fi = i
				break
		-- gets meta and styles values
		@collectHead!

	get: (index) => index and @[index] or @

	new: (...) => @set ...

	-- iterates over all the lines of the ass file
	iterSub: (copy = true) =>
		i = 0
		n = #@sub
		->
			i += 1
			if i <= n
				l = @sub[i + @i]
				if copy
					if l.class == "dialogue"
						line = Table.deepcopy l
						line.isShape = Util.isShape line.text
						line.text = Text line.text, line.isShape
					return l, line, i, n
				return l, i, n

	-- iterates over all the selected lines of the ass file
	iterSel: (copy = true) =>
		i = 0
		n = #@sel
		->
			i += 1
			if i <= n
				s = @sel[i]
				l = @sub[s + @i]
				if copy
					line = Table.deepcopy l
					line.isShape = Util.isShape line.text
					line.text = Text line.text, line.isShape
					return l, line, s, i, n
				return l, s, i, n

	-- gets the meta and styles values from the ass file
	collectHead: =>
		@meta, @styles = {res_x: 0, res_y: 0, video_x_correct_factor: 1}, {}
		for l in @iterSub false
			if aegisub.progress.is_cancelled!
				error "User cancelled", 2

			if l.class == "style"
				@styles[l.name] = l
			elseif l.class == "info"
				@meta[l.key\lower!] = l.value
			else
				break

		-- gets the bounding box of the selected lines
		if jit.os != "Windows"
			@collectBounds!

		-- check if there are any styles present in the ass file
		if Table.isEmpty @styles
			error "ERROR: No styles were found in the file, bug?!", 2

		-- fix resolution data
		@meta.res_x, @meta.res_y = @sub.script_resolution!

		video_x, video_y = aegisub.video_size!
		if video_y
			@meta.video_x_correct_factor = (video_y / video_x) / (@meta.res_y / @meta.res_x)

		Aegi.debug 4, "ILL: Video X correction factor = %f\n\n", @meta.video_x_correct_factor
		return @

	-- gets the bounding box of all selected lines
	collectBounds: (si_exhaustive = false) =>
		if hasInspector
			lines, @bounds = {}, {}
			for l, lcopy, s, i in @iterSel!
				lines[i] = {}
				newLine = Table.copy lcopy
				newLine.text\callBack (tags, text) ->
					tags\remove "clip", "iclip", "outline", "shadow", "perspective"
					tags\insert "\\fscx100\\fscy100\\frz0\\bord0\\shad0"
					return tags, text
				newLine.text = newLine.text\__tostring!
				newLine.raw = newLine.raw\gsub "^(.-: .-,.-,.-,.-,.-,.-,.-,.-,.-,)(.*)$", "%1#{newLine.text}"
				newLine.si_exhaustive = si_exhaustive
				lines[i][1] = newLine
			insp, msg = Inspector @sub
			assert insp, "SubInspector Error: #{msg}"
			for i = 1, #lines
				bounds, times = insp\getBounds lines[i]
				assert bounds != nil, "SubInspector Error: #{times}"
				l, t, r, b = nil, nil, 0, 0
				for j = 1, #times
					if bound = bounds[j]
						l = math.min bound.x, l or bound.x
						t = math.min bound.y, t or bound.y
						r = math.max bound.x + bound.w, r
						b = math.max bound.y + bound.h, b
				@bounds[i] = {:l, :t, :r, :b}
			return @
		else
			error "ERROR: Install SubInspector", 2

	-- gets the real number of the current line
	lineNumber: (s) => s - @fi + 1

	-- sets the value of the line in the dialog
	setLine: (l, s, first, buildTextInstance) =>
		-- makes updating the text more dynamic
		Ass.setText l, first, buildTextInstance
		-- sets the value of the line
		@sub[s + @i] = l

	-- inserts a line in dialogs
	insertLine: (l, s, first, buildTextInstance) =>
		i = s + @i + 1
		-- makes updating the text more dynamic
		Ass.setText l, first, buildTextInstance
		-- adds a dialogue line in subtitle
		@sub.insert i, l
		-- inserts the index of this new line in the selected lines box
		table.insert @newSelection, i
		@i += 1
		@activeLine += 1

	-- removes a line in dialogs
	removeLine: (l, s) =>
		i = s + @i
		l.comment = true
		@sub[i] = l
		l.comment = false
		if @remLine
			@sub.delete i
			@i -= 1
			@activeLine -= 1

	-- gets the index values of the lines that were added
	getNewSelection: =>
		if #@newSelection > 0
			return @newSelection, @activeLine

	-- the subtitle that will appear on the progress screen
	progressLine: (s, i, n) =>
		Aegi.progressSet i, n
		Aegi.progressTask "Processing Line: #{@lineNumber s} - #{i} / #{n}"
		Aegi.progressCancelled!

	-- sets an error on the line
	error: (s, msg = "not specified") =>
		Aegi.debug 0, "———— [Error] ➔ Line #{@lineNumber s}\n"
		Aegi.debug 0, "—— [Cause] ➔ " .. msg .. "\n\n"
		Aegi.progressCancel!

	-- sets a warning on the line
	warning: (s, msg = "not specified") =>
		Aegi.debug 2, "———— [Warning] ➔ Line #{@lineNumber s} skipped\n"
		Aegi.debug 2, "—— [Cause] ➔ " .. msg .. "\n\n"

	-- sets the final value of the text
	setText: (l, first, buildTextInstance) ->
		if first and l.tags
			l.tags\clear l.styleref
			l.text.tagsBlocks[1] = l.tags\__tostring!
			l.text = l.text\__tostring!
		elseif buildTextInstance
			l.text = l.text\__tostring!
		else
			if l.tags
				l.tags\clear l.styleref
				l.text = l.tags\__tostring!
				l.text = l.text\gsub "{%s*}", ""
			else
				l.text = l.text\match("%b{}") or ""
			l.text ..= l.isShape and l.shape or l.text_stripped

{:Ass}