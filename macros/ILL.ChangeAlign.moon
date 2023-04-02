export script_name        = "Change Alignment"
export script_description = "Changes the alignment of a text or shape without changing its original position"
export script_version     = "1.0.5"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.ChangeAlign"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, Ass, Line, Path
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"ILL.ILL"
				version: "1.3.0"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	{:Ass, :Line, :Path} = depctrl\requireModules!
else
	{:Ass, :Line, :Path} = require "ILL.ILL"

interface = ->
	{
		{class: "label", label: "New alignment:#{(" ")\rep 22}", x: 0, y: 0}
		{class: "dropdown", name: "an", items: [tostring(i) for i = 1, 9], x: 0, y: 1, value: "7"}
	}

main = (sub, sel, activeLine) ->
	button, elements = aegisub.dialog.display interface!, {"Ok", "Cancel"}, {close: "Cancel"}
	if button == "Ok"
		aln = tonumber elements.an
		ass = Ass sub, sel, activeLine
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l, i
			local width, height
			if l.isShape
				{:width, :height} = Path(l.shape)\boundingBox!
			Line.changeAlign l, aln, width, height
			ass\setLine l, s

if haveDepCtrl
	depctrl\registerMacros {
		{script_name, script_description, main}
	}, ": ILL macros :"
else
	aegisub.register_macro ": ILL macros : / #{script_name}", script_description, main