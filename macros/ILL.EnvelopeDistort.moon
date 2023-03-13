export script_name        = "Envelope Distort"
export script_description = "Allows you to warp and manipulate shapes within a customizable envelope"
export script_version     = "1.0.3"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.EnvelopeDistort"

depctrl = require("l0.DependencyControl") {
	{
		{"ILL.Main"}
	}
}

{:Ass, :Line, :Path} = depctrl\requireModules!

config = depctrl\getConfigHandler {
	lineType: "Straight"
	rows: 1
	cols: 1
	perspective: false
	keepMesh: false
}

makeMesh = (ass, button, elements) ->
	{:lineType, :rows, :cols, :perspective, :keepMesh} = elements
	isBezier = lineType == "Bezier"
	getMesh = (l) ->
		clips, colDistance, rowDistance = {}, nil, nil
		Line.callBackExpand ass, l, {rows, cols, isBezier}, (line) ->
			{:colDistance, :rowDistance} = line.grid
			table.insert clips, line.grid.path\export!
		return clips, colDistance, rowDistance
	for l, lcopy, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		Line.extend ass, lcopy, i
		if button == "Mesh"
			ass\removeLine l, s
			clips = getMesh lcopy
			xr, yr = aegisub.video_size!
			screen = "m 0 0 l #{xr} 0 #{xr} #{yr} 0 #{yr} "
			lcopy.tags\remove "clip", "iclip"
			if lcopy.isShape
				clips = table.concat clips
				lcopy.tags\insert {{"clip", screen .. clips}}
				ass\insertLine lcopy, s
			else
				isMove = lcopy.tags\existsTag "move"
				Line.callBack ass, lcopy, (line, j) ->
					line.tags\insert {{"clip", screen .. clips[j]}}
					ass\insertLine line, s
		else
			ass\removeLine l, s
			{:clip, :pos} = lcopy.data
			if clip
				mesh = Path clip
				table.remove mesh.path, 1
				if perspective and (isBezier or #mesh.path != 1)
					ass\error s, "Expected an quadrilateral"
				clips, colDistance, rowDistance = getMesh lcopy
				local area
				if isBezier
					area = (colDistance * rowDistance) / 1000
					mesh\flatten 1, nil, area
				Line.callBackExpand ass, lcopy, {rows, cols, isBezier}, (line, j) ->
					{x, y} = line.data.pos
					real = Path clips[j]
					if isBezier
						real = real\flatten 1, nil, area
					path = Path(line.shape)\move x, y
					if perspective
						path\perspective mesh.path[1], real.path[1]
					else
						path\allCurve!
						path\envelopeDistort mesh, real
					unless maintainMesh
						line.tags\remove "clip", "iclip"
					line.shape = path\move(-x, -y)\export!
					ass\insertLine line, s
			else
				ass\error s, "The grid was not found"
	return ass\getNewSelection!

main = (sub, sel, activeLine) ->
	gui = {
		{class: "label", label: " - Mesh options ----", x: 0, y: 0}
		{class: "label", label: "Line type", x: 0, y: 1}
		{class: "dropdown", items: {"Straight", "Bezier"}, x: 3, y: 1, name: "lineType", value: config.c.lineType}
		{class: "label", label: "Rows", x: 0, y: 2}
		{class: "intedit", min: 1, step: 1, x: 3, y: 2, width: 1, height: 1, name: "rows", value: config.c.rows}
		{class: "label", label: "Columns", x: 0, y: 3}
		{class: "intedit", min: 1, step: 1, x: 3, y: 3, width: 1, height: 1, name: "cols", value: config.c.cols}
		{class: "checkbox", label: "Perspective", x: 0, y: 5, name: "perspective", value: config.c.perspective}
		{class: "checkbox", label: "Keep Mesh", x: 3, y: 5, width: 1, height: 1, name: "keepMesh", value: config.c.keepMesh}
	}
	button, elements = aegisub.dialog.display gui, {"Warp", "Mesh", "Cancel"}, {close: "Cancel"}
	if button != "Cancel"
		for key, value in pairs elements
			config.c[key] = value
		config\write!
		return makeMesh Ass(sub, sel, activeLine), button, config.c

depctrl\registerMacros {
	{"Make with Mesh", "", main}
}