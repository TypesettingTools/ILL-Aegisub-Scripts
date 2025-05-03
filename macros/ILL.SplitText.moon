export script_name        = "ILL - Split Text"
export script_description = "Splits the text in several ways"
export script_version     = "2.0.0"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.SplitText"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, ILL, Ass, Line
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"ILL.ILL"
				version: "1.6.1"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	ILL = depctrl\requireModules!
else
	ILL = require "ILL.ILL"

{:Ass, :Line} = ILL

main = (mode) ->
    (sub, sel, activeLine) ->
        ass = Ass sub, sel, activeLine
        for l, s, i, n in ass\iterSel!
            ass\progressLine s, i, n
            ass\removeLine l, s
            Line.extend ass, l
            unless l.isShape
                for line in *(mode == "chars" and Line.chars(ass, l, true) or Line.words(ass, l, true))
                    fr = line.data.angle != 0
                    if fr or line.text\existsTagOr "frx", "fry", "frz"
                        line.tags\insert {{"org", line.data.org}, true}
                    line.tags\insert {{"pos", Line.reallocate l, line}, true}
                    line.text\modifyBlock line.tags
                    ass\insertLine line, s
            else
                ass\warning s, "Only divite text not shapes"
        return ass\getNewSelection!

if haveDepCtrl
    depctrl\registerMacros {
        {"By Chars", "", main "chars"}
        {"By Words", "", main "words"}
    }
else
    aegisub.register_macro "#{script_name}/By Chars", "", main "chars"
    aegisub.register_macro "#{script_name}/By Words", "", main "words"