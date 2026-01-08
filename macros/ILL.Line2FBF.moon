export script_name        = "Line To FBF"
export script_description = "It calculates line transformations frame by frame or given a step frame."
export script_version     = "1.1.0"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.Line2FBF"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, ILL
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"ILL.ILL"
				version: "1.7.7"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	ILL = depctrl\requireModules!
else
	ILL = require "ILL.ILL"

{:Aegi, :Ass, :Line} = ILL

interface = ->
    {
        {class: "label", label: "Frame Step:", x: 0, y: 0}
        {class: "intedit", name: "step", min: 1, x: 0, y: 1, value: 1}  
    }

main = (sub, sel, activeLine) ->
	button, elements = Aegi.display interface!, {"Ok", "Cancel"}, {close: "Cancel"}
	if button == "Ok"
		ass = Ass sub, sel, activeLine
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
            ass\removeLine l, s
			Line.process ass, l
            Line.callBackFBFWithStep ass, l, elements.step, (line, i, end_frame, j, n) ->
                ass\insertLine line, s

if haveDepCtrl
	depctrl\registerMacro main
else
	aegisub.register_macro script_name, script_description, main