export script_name        = "Envelope Distort"
export script_description = "Allows you to warp and manipulate shapes within a customizable envelope"
export script_version     = "1.0.7"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.EnvelopeDistort"

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

makeMesh = (ass, button, elements) ->
	{:lineType, :rows, :cols, :tolerance, :perspective, :keepMesh} = elements
	isBezier = lineType == "Bezier"
	getMesh = (l) ->
		clips, colDistance, rowDistance = {}, nil, nil
		Line.callBackExpand ass, l, {rows, cols, isBezier}, (line) ->
			{:colDistance, :rowDistance} = line.grid
			table.insert clips, line.grid.path\export!
		return clips, colDistance, rowDistance
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		Line.extend ass, l, i
		if button == "Mesh"
			ass\removeLine l, s
			clips = getMesh l
			xr, yr = aegisub.video_size!
			screen = "m 0 0 l #{xr} 0 #{xr} #{yr} 0 #{yr} "
			l.tags\remove "clip", "iclip"
			if l.isShape
				clips = table.concat clips
				l.tags\insert {{"clip", screen .. clips}}
				ass\insertLine l, s
			else
				{:org} = l.data
				isMove = l.tags\existsTag "move"
				Line.callBack ass, l, (line, j) ->
					line.text\callBack (tags, text) ->
						line.tags\insert {{"clip", screen .. clips[j]}}
						if line.data.angle != 0 or line.tags\existsTagOr "frx", "fry", "frz"
							line.tags\insert {{"org", org}, true}
						return line.tags, text
					ass\insertLine line, s
		else
			ass\removeLine l, s
			{:clip, :pos} = l.data
			if clip
				mesh = Path clip
				table.remove mesh.path, 1
				if perspective and (isBezier or #mesh.path != 1)
					ass\error s, "Expected an quadrilateral"
				clips, colDistance, rowDistance = getMesh l
				local area
				if isBezier
					area = (colDistance * rowDistance) / 1000
					mesh\flatten 1, nil, area
				Line.callBackExpand ass, l, {rows, cols, isBezier}, (line, j) ->
					{x, y} = line.data.pos
					real = Path clips[j]
					if isBezier
						real = real\flatten 1, nil, area
					path = Path(line.shape)\move x, y
					if perspective
						path\perspective mesh.path[1], real.path[1]
					else
						path\allCurve!
						path\envelopeDistort mesh, real, tolerance
					unless maintainMesh
						line.tags\remove "clip", "iclip"
					line.shape = path\move(-x, -y)\export!
					ass\insertLine line, s
			else
				ass\error s, "The grid was not found"
	return ass\getNewSelection!

config = depctrl\getConfigHandler {
	lineType: "Straight"
	rows: 1
	cols: 1
	tolerance: 0
	perspective: false
	keepMesh: false
}

interface = ->
	{
		{class: "label", label: " - Mesh options -----", x: 0, y: 0}
		{class: "label", label: "Line type", x: 0, y: 1}
		{class: "dropdown", items: {"Straight", "Bezier"}, x: 1, y: 1, name: "lineType", value: config.c.lineType}
		{class: "label", label: "Rows", x: 0, y: 2}
		{class: "intedit", min: 1, x: 1, y: 2, name: "rows", value: config.c.rows}
		{class: "label", label: "Columns", x: 0, y: 3}
		{class: "intedit", min: 1, x: 1, y: 3, name: "cols", value: config.c.cols}
		{class: "label", label: "Tolerance", x: 0, y: 4}
		{class: "floatedit", min: 0, x: 1, y: 4, name: "tolerance", value: config.c.tolerance}
		{class: "checkbox", label: "Perspective", x: 0, y: 6, name: "perspective", value: config.c.perspective}
		{class: "checkbox", label: "Keep Mesh", x: 1, y: 6, name: "keepMesh", value: config.c.keepMesh}
	}

makeWithMesh = (sub, sel, activeLine) ->
	button, elements = aegisub.dialog.display interface!, {"Warp", "Mesh", "Cancel"}, {close: "Cancel"}
	if button != "Cancel"
		for key, value in pairs elements
			config.c[key] = value
		config\write!
		return makeMesh Ass(sub, sel, activeLine), button, config.c

if haveDepCtrl
	depctrl\registerMacros {
		{"Make with Mesh", script_name, makeWithMesh}
	}
else
	aegisub.register_macro "#{script_name} / Make with Mesh", script_description, makeWithMesh