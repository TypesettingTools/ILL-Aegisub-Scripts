export script_name        = "ILL - Change Alignment"
export script_description = "Changes the alignment of a text or shape without changing its original position"
export script_version     = "1.0.0"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.ChangeAlign"

depctrl = require("l0.DependencyControl") {
	{
		{"ILL.Main"}
	}
}

{:Ass, :Line, :Path} = depctrl\requireModules!

interface = ->
	{
		{class: "label", label: "New alignment:#{(" ")\rep 22}", x: 0, y: 0}
		{class: "dropdown", name: "an", items: [tostring(i) for i = 1, 9], x: 0, y: 1, value: "7"}
	}

main = (sub, sel, activeLine) ->
	button, elements = aegisub.dialog.display interface!, {"Ok", "Cancel"}, {close: "Cancel"}
	if button == "Ok"
		nan = tonumber elements.an
		ass = Ass sub, sel, activeLine
		for l, line, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, line
			local width, height
			if line.isShape
				{:width, :height} = Path(line.shape)\boundingBox!
			Line.changeAlign line, nan, width, height
			ass\setLine line, s, true

depctrl\registerMacro main