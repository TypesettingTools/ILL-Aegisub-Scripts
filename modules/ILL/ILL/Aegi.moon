import Table from require "ILL.ILL.Table"

-- https://aegisub.org/docs/latest/automation/lua/progress_reporting/
class Aegi

	-- use loaded frame rate data to convert an absolute time given in milliseconds into a frame number
	ffm: (ms) -> aegisub.frame_from_ms ms

	-- use loaded frame rate data to convert a frame number of the video into an absolute time in milliseconds
	mff: (frame) -> aegisub.ms_from_frame frame

	-- the title that will appear on the progress screen
	progressTitle: (title) ->
		aegisub.progress.title title
		return

	-- the subtitle that will appear on the progress screen
	progressTask: (task = "") ->
		aegisub.progress.task task
		return

	-- the processing bar that ranges from 0 to 100
	progressSet: (i, n) ->
		aegisub.progress.set 100 * i / n
		return

	-- resets all progress
	progressReset: ->
		aegisub.progress.set 0
		aegisub.progress.task ""
		return

	-- checks if processing has been canceled and cancels
	progressCancelled: ->
		if aegisub.progress.is_cancelled!
			aegisub.cancel!
		return

	-- cancels current processing
	progressCancel: (msg) ->
		if msg
			aegisub.log msg
		aegisub.cancel!
		return

	-- debugging support
	debug: (lvl = 0, msg) ->
		aegisub.debug.out lvl, msg
		return

	-- prints any value in the Aegisub log
	log: (value) ->
		if type(value) == "string" or type(value) == "number"
			aegisub.log tostring(value) .. "\n"
		else
			aegisub.log Table.view value
		return

{:Aegi}