export script_name        = "Shapery"
export script_description = "Does several types of shape manipulations from the simplest to the most complex"
export script_version     = "2.4.0"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.Shapery"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, Clipper, ILL, Aegi, Ass, Config, Line, Curve, Path, Point, Util, Math, Table, Util
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"clipper2.clipper2"
				version: "1.3.2"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
			{
				"ILL.ILL"
				version: "1.3.6"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	Clipper, ILL = depctrl\requireModules!
	{:Aegi, :Ass, :Config, :Line, :Curve, :Path, :Point, :Util, :Math, :Table, :Util} = ILL
else
	Clipper = require "clipper2.clipper2"
	ILL = require "ILL.ILL"
	{:Aegi, :Ass, :Config, :Line, :Curve, :Path, :Point, :Util, :Math, :Table, :Util} = ILL

-- https://github.com/colinmeinke/svg-arc-to-cubic-bezier
arc2CubicBezier = (info) ->
	TAU = math.pi * 2

	mapToEllipse = (p, rx, ry, cosphi, sinphi, centerx, centery) ->
		p.x *= rx
		p.y *= ry
		xp = cosphi * p.x - sinphi * p.y
		yp = sinphi * p.x + cosphi * p.y
		return Point xp + centerx, yp + centery

	approxUnitArc = (ang1, ang2) ->
		-- If 90 degree circular arc, use a constant
		-- as derived from http://spencermortensen.com/articles/bezier-circle
		a = ang2 == 1.5707963267948966 and 0.551915024494 or (ang2 == -1.5707963267948966 and -0.551915024494 or 4 / 3 * math.tan(ang2 / 4))

		x1 = math.cos ang1
		y1 = math.sin ang1
		x2 = math.cos ang1 + ang2
		y2 = math.sin ang1 + ang2

		return {
			Point x1 - y1 * a, y1 + x1 * a
			Point x2 + y2 * a, y2 - x2 * a
			Point x2, y2
		}

	vectorAngle = (ux, uy, vx, vy) ->
		sign = (ux * vy - uy * vx < 0) and -1 or 1
		dot = ux * vx + uy * vy
		if dot > 1
			dot = 1
		if dot < -1
			dot = -1
		return sign * math.acos dot

	getArcCenter = (px, py, cx, cy, rx, ry, largeArcFlag, sweepFlag, sinphi, cosphi, pxp, pyp) ->
		rxsq = rx ^ 2
		rysq = ry ^ 2
		pxpsq = pxp ^ 2
		pypsq = pyp ^ 2

		radicant = rxsq * rysq - rxsq * pypsq - rysq * pxpsq
		if radicant < 0
			radicant = 0

		radicant = radicant / (rxsq * pypsq + rysq * pxpsq)
		radicant = math.sqrt(radicant) * (largeArcFlag == sweepFlag and -1 or 1)

		centerxp = radicant * rx / ry * pyp
		centeryp = radicant * -ry / rx * pxp

		centerx = cosphi * centerxp - sinphi * centeryp + (px + cx) / 2
		centery = sinphi * centerxp + cosphi * centeryp + (py + cy) / 2

		vx1 = (pxp - centerxp) / rx
		vy1 = (pyp - centeryp) / ry
		vx2 = (-pxp - centerxp) / rx
		vy2 = (-pyp - centeryp) / ry

		ang1 = vectorAngle 1, 0, vx1, vy1
		ang2 = vectorAngle vx1, vy1, vx2, vy2

		if sweepFlag == 0 and ang2 > 0
			ang2 -= TAU

		if sweepFlag == 1 and ang2 < 0
			ang2 += TAU

		return {centerx, centery, ang1, ang2}

	{:px, :py, :cx, :cy, :rx, :ry, :xAxisRotation, :largeArcFlag, :sweepFlag} = info
	xAxisRotation or= 0
	largeArcFlag or= 0
	sweepFlag or= 0

	if rx == 0 or ry == 0
		return {}

	sinphi = math.sin xAxisRotation * TAU / 360
	cosphi = math.cos xAxisRotation * TAU / 360

	pxp = cosphi * (px - cx) / 2 + sinphi * (py - cy) / 2
	pyp = -sinphi * (px - cx) / 2 + cosphi * (py - cy) / 2

	if pxp == 0 and pyp == 0
		return {}

	rx = math.abs rx
	ry = math.abs ry

	lambda = (pxp ^ 2) / (rx ^ 2) + (pyp ^ 2) / (ry ^ 2)
	if lambda > 1
		rx *= math.sqrt lambda
		ry *= math.sqrt lambda

	{centerx, centery, ang1, ang2} = getArcCenter px, py, cx, cy, rx, ry, largeArcFlag, sweepFlag, sinphi, cosphi, pxp, pyp

	ratio = math.abs(ang2) / (TAU / 4)
	if math.abs(1 - ratio) < 1e-7
		ratio = 1

	segments = math.max math.ceil(ratio), 1

	ang2 /= segments

	curves = {}
	for i = 1, segments
		table.insert curves, approxUnitArc ang1, ang2
		ang1 += ang2

	result = {}
	for i = 1, #curves
		curve = curves[i]
		{x: x1, y: y1} = mapToEllipse curve[1], rx, ry, cosphi, sinphi, centerx, centery
		{x: x2, y: y2} = mapToEllipse curve[2], rx, ry, cosphi, sinphi, centerx, centery
		{:x, :y} = mapToEllipse curve[3], rx, ry, cosphi, sinphi, centerx, centery
		table.insert result, {x1, y1, x2, y2, x, y}

	return result

sweepAngularPoint = (a, b, c) ->
	center = a\lerp c, 0.5

	cos_pi = math.cos math.pi
	sin_pi = math.sin math.pi

	p = Point!
	p.x = cos_pi * (b.x - center.x) - sin_pi * (b.y - center.y) + center.x
	p.y = sin_pi * (b.x - center.x) + cos_pi * (b.y - center.y) + center.y
	return p

-- https://stackoverflow.com/a/40444735
getSweepFlag = (S, V, E) ->
	getAngle = (a, b, c) ->
		angle_1 = math.atan2 a.y - b.y, a.x - b.x
		angle_2 = math.atan2 c.y - b.y, c.x - b.x
		angle_3 = angle_2 - angle_1
		return (angle_3 + 3 * math.pi) % (2 * math.pi) - math.pi
	return getAngle(E, S, V) > 0 and 0 or 1

-- https://stackoverflow.com/a/24780108
getProportionPoint = (point, segment, length, d) ->
	factor = segment / length
	return Point point.x - d.x * factor, point.y - d.y * factor

modeRoundingAbsolute = (radius, p1, angularPoint, p2) ->
	-- Vector 1
	v1 = Point angularPoint.x - p1.x, angularPoint.y - p1.y

	-- Vector 2
	v2 = Point angularPoint.x - p2.x, angularPoint.y - p2.y

	-- Angle between vector 1 and vector 2
	angle = math.atan2(v1.y, v1.x) - math.atan2(v2.y, v2.x)

	-- The length of segment between angular point and the
	-- points of intersection with the circle of a given radius
	abs_tan = math.abs math.tan angle / 2
	segment = radius / abs_tan

	-- Check the segment
	length1 = v1\vecMagnitude!
	length2 = v2\vecMagnitude!

	length = math.min(length1, length2) / 2
	if segment > length
		segment = length
		radius = length * abs_tan

	-- Points of intersection are calculated by the proportion between 
	-- the coordinates of the vector, length of vector and the length of the segment.
	p1Cross = getProportionPoint angularPoint, segment, length1, v1
	p2Cross = getProportionPoint angularPoint, segment, length2, v2

	-- Calculation of the coordinates of the circle 
	-- center by the addition of angular vectors.
	c = Point!
	c.x = angularPoint.x * 2 - p1Cross.x - p2Cross.x
	c.y = angularPoint.y * 2 - p1Cross.y - p2Cross.y

	L = c\vecMagnitude!
	d = Point(segment, radius)\vecMagnitude!

	circlePoint = getProportionPoint angularPoint, d, L, c

	-- StartAngle and EndAngle of arc
	startAngle = math.atan2 p1Cross.y - circlePoint.y, p1Cross.x - circlePoint.x
	endAngle = math.atan2 p2Cross.y - circlePoint.y, p2Cross.x - circlePoint.x

	-- Sweep angle
	sweepAngle = endAngle - startAngle

	-- Some additional checks
	if sweepAngle < 0
		startAngle = endAngle
		sweepAngle = -sweepAngle

	if sweepAngle > math.pi
		sweepAngle = -(2 * math.pi - sweepAngle)

	degreeFactor = 180 / math.pi
	sweepFlag = getSweepFlag p1Cross, angularPoint, p2Cross

	return {
		line1: {p1, p1Cross}
		line2: {p2, p2Cross}
		arc: {
			:sweepFlag
			rx: radius
			ry: radius
			start_angle: startAngle * degreeFactor
			end_angle: sweepAngle * degreeFactor
		}
	}

modeRoundingRelative = (radius, inverted, a, b, c) ->
	{:line1, :line2} = modeRoundingAbsolute radius, a, b, c
	p1 = line1[2]
	p2 = b\clone!
	p3 = line2[2]
	if inverted
		p2 = sweepAngularPoint p1, p2, p3
	c1 = p1\lerp p2, 0.5
	c2 = p2\lerp p3, 0.5
	return p1, c1, c2, p3

modeSpike = (radius, a, b, c, path) ->
	{:line1, :line2} = modeRoundingAbsolute radius, a, b, c
	p1 = line1[2]
	p3 = line2[2]
	p2 = sweepAngularPoint p1, b, p3
	table.insert path, p1
	table.insert path, p2
	table.insert path, p3

modeChamfer = (radius, a, b, c, path) ->
	{:line1, :line2} = modeRoundingAbsolute radius, a, b, c
	p1 = line1[2]
	p3 = line2[2]
	table.insert path, p1
	table.insert path, p3

makeRoundingAbsolute = (r, inverted, a, b, c, path) ->
	{:line1, :line2, :arc} = modeRoundingAbsolute r, a, b, c
	curves = arc2CubicBezier {
		px: line1[2].x
		py: line1[2].y
		cx: line2[2].x
		cy: line2[2].y
		rx: arc.rx
		ry: arc.ry
		sweepFlag: inverted and 1 - arc.sweepFlag or arc.sweepFlag
	}
	table.insert path, Point line1[2].x, line1[2].y
	for curve in *curves
		table.insert path, Point curve[1], curve[2], "b"
		table.insert path, Point curve[3], curve[4], "b"
		table.insert path, Point curve[5], curve[6], "b"

makeRoundingRelative = (r, inverted, a, b, c, path) ->
	p1, c1, c2, p4 = modeRoundingRelative r, inverted, a, b, c
	table.insert path, Point p1.x, p1.y
	table.insert path, Point c1.x, c1.y, "b"
	table.insert path, Point c2.x, c2.y, "b"
	table.insert path, Point p4.x, p4.y, "b"

shadow3D = (shape, xshad, yshad) ->
	-- sorts the points to clockwise
	toClockWise = (points) ->
		cx, cy, n = 0, 0, #points
		for {:x, :y} in *points
			cx += x
			cy += y
		cx /= n
		cy /= n
		table.sort points, (a, b) ->
			a1 = (math.deg(math.atan2(a.x - cx, a.y - cy)) + 360) % 360
			a2 = (math.deg(math.atan2(b.x - cx, b.y - cy)) + 360) % 360
			return a1 < a2
		return unpack points
	pathA = Path shape
	pathA\closeContours!
	pathA\flatten!
	pathB = pathA\clone!
	pathB\move xshad, yshad
	pathsClipperA = pathA\convertToClipper!
	newPathsClipper = Clipper.paths.new!
	for i = 1, #pathA.path
		pa = pathA.path[i]
		pb = pathB.path[i]
		for j = 1, #pa - 1
			newPathClipper = Clipper.path.new!
			newPathClipper\push toClockWise {pa[j], pa[j + 1], pb[j + 1], pb[j]}
			newPathsClipper\add newPathClipper
	return Path.convertFromClipper(pathsClipperA\union newPathsClipper)\export!

shadowInner = (shape, xshad, yshad) ->
	pathA = Path shape
	pathB = pathA\clone!
	pathB\move xshad, yshad
	pathA\difference pathB
	return pathA\export!

interfaces = {
	config: -> {
		{class: "label", label: "Expand", x: 0, y: 0}
		{class: "floatedit", x: 0, y: 1, name: "cutBordShadow", min: 0.1, max: 2, step: 0.1, value: 1}
		{class: "checkbox", label: "Cut", x: 0, y: 2, name: "expandBordShadow", value: false}
		{class: "label", label: "Reset Macro", x: 0, y: 5}
		{class: "dropdown", items: {"All", "Config", "Pathfinder", "Offsetting", "Manipulate", "Transform", "Utilities"}, x: 5, y: 5, name: "reset", value: "All"}
		{class: "checkbox", label: "Save lines", x: 5, y: 0, name: "saveLines", value: false}
	}
	pathfinder: -> {
		{class: "label", label: "Operation:", x: 0, y: 0}
		{class: "dropdown", items: {"Unite", "Intersect", "Difference", "Exclude"}, x: 1, y: 0, name: "operation", value: "Unite"}
		{class: "checkbox", label: "Multiline", x: 0, y: 2, name: "multiline", value: false}
	}
	offsetting: -> {
		{class: "label", label: "Stroke Weight", x: 0, y: 0}
		{class: "floatedit", x: 1, y: 0, name: "strokeWeight", value: 0}
		{class: "checkbox", x: 1, y: 1, name: "cut", value: false}
		{class: "label", label: "Corner Style", x: 0, y: 2}
		{class: "dropdown", items: {"Miter", "Round", "Square"}, x: 1, y: 2, name: "cornerStyle", value: "Round"}
		{class: "label", label: "Align Stroke", x: 0, y: 3}
		{class: "dropdown", items: {"Outside", "Center", "Inside"}, x: 1, y: 3, name: "strokeAlign", value: "Outside"}
		{class: "label", label: "Miter Limit", x: 0, y: 5}
		{class: "floatedit", x: 0, y: 6, name: "miterLimit", value: 2}
		{class: "label", label: "Arc Precision", x: 1, y: 5}
		{class: "floatedit", x: 1, y: 6, name: "arcPrecision", value: 0.25}
	}
	manipulate: -> {
		{class: "label", label: "Fit Curves", x: 0, y: 0}
		{class: "checkbox", x: 3, y: 0, name: "recreateBezier", value: true}
		{class: "label", label: "Execute On \\clip", x: 0, y: 1}
		{class: "checkbox", x: 3, y: 1, name: "enableClip", value: false}
		{class: "label", label: "- Simplify -----", x: 0, y: 3}
		{class: "label", label: "Tolerance", x: 0, y: 4}
		{class: "floatedit", x: 3, y: 4, name: "tolerance", min: 0.1, max: 10, step: 0.01, value: 0.5}
		{class: "label", label: "Angle Threshold", x: 0, y: 5}
		{class: "floatedit", x: 3, y: 5, name: "angleThreshold", min: 0, max: 180, step: 0.1, value: 170}
		{class: "label", label: "- Flatten -----", x: 0, y: 7}
		{class: "label", label: "Distance", x: 0, y: 8}
		{class: "floatedit", x: 3, y: 8, name: "distance", min: 0.1, max: 100, step: 0.1, value: 1}
	}
	transform: -> {
		{class: "label", label: "- Move -----", x: 0, y: 0}
		{class: "label", label: "X axis", x: 0, y: 1}
		{class: "floatedit", x: 1, y: 1, name: "xAxis", value: 0}
		{class: "label", label: "Y axis", x: 0, y: 2}
		{class: "floatedit", x: 1, y: 2, name: "yAxis", value: 0}
		{class: "label", label: "- Rotate -----", x: 4, y: 0}
		{class: "label", label: "Angle", x: 4, y: 1}
		{class: "floatedit", x: 4, y: 2, name: "angle", value: 0}
		{class: "label", label: "- Scale -----", x: 8, y: 0}
		{class: "label", label: "Hor. %", x: 8, y: 1}
		{class: "floatedit", x: 9, y: 1, name: "horizontalScale", min: 1, max: 500, step: 0.1, value: 100}
		{class: "label", label: "Ver. %", x: 8, y: 2}
		{class: "floatedit", x: 9, y: 2, name: "verticalScale", min: 1, max: 500, step: 0.1, value: 100}
		{class: "label", label: "- Filter -----", x: 0, y: 3}
		{class: "textbox", x: 0, y: 4, width: 10, height: 8, name: "filter", value: ""}
	}
	utilities: -> {
		{class: "label", label: "Shadow Effect", x: 0, y: 0}
		{class: "dropdown", items: {"Inner shadow", "3D from shadow", "3D from shape"}, x: 0, y: 1, name: "shadow", value: "Inner shadow"}
		{class: "label", label: "Corner", x: 4, y: 0}
		{class: "dropdown", items: {"Rounded", "Inverted Round", "Chamfer", "Spike"}, x: 5, y: 0, name: "cornerStyle", value: "Rounded"}
		{class: "label", label: "Radius", x: 4, y: 1}
		{class: "floatedit", x: 5, y: 1, name: "radius", min: 0, max: 1e5, step: 0.1, value: 0}
		{class: "label", label: "Rounding", x: 4, y: 2}
		{class: "dropdown", items: {"Absolute", "Relative"}, x: 5, y: 2, name: "rounding", value: "Absolute"}
	}
}

resetInterface = (name) ->
	if name != "All"
		cfg = Config interfaces[name\lower!]!
		cfg\setJsonPath script_namespace .. name
		cfg\reset!
	else
		interface = interfaces.config!
		for n in *interface[5].items
			if n != "All"
				resetInterface n

getConfigElements = ->
	cfg = Config interfaces.config!
	cfg\setJsonPath script_namespace .. "Config"
	return Config.getElements cfg\getInterface!

PathfinderDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.pathfinder!, {"Ok", "Cancel"}, {close: "Cancel"}, "Pathfinder"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		info = {shapes: {}}
		{:multiline, :operation} = elements
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			ass\removeLine l, s
			Line.extend ass, l
			if multiline
				if n == 1
					Aegi.progressCancel "You must select 2 lines or more."
				clip = {}
				Line.callBackExpand ass, l, nil, (line, j) ->
					{x, y} = line.data.pos
					if i == 1 and j == 1
						info.pos = {x, y}
						info.line = Table.copy line
					table.insert clip, Path(line.shape)\move(x - info.pos[1], y - info.pos[2])\export!
				table.insert info.shapes, Path table.concat clip
				if i == n
					{:line, :shapes} = info
					shape = shapes[1]
					for j = 2, #shapes
						cut = shapes[j]
						switch operation
							when "Unite"      then shape\unite      cut
							when "Intersect"  then shape\intersect  cut
							when "Difference" then shape\difference cut
							when "Exclude"    then shape\exclude    cut
					line.shape = shape\export!
					if line.shape != ""
						ass\insertLine line, s
			else
				if clip = l.data.clip
					Line.callBackExpand ass, l, nil, (line) ->
						{px, py} = line.data.pos
						shape = Path line.shape
						cut = Path(clip)\move -px, -py
						switch operation
							when "Unite"      then shape\unite      cut
							when "Intersect"  then shape\intersect  cut
							when "Difference" then shape\difference cut
							when "Exclude"    then shape\exclude    cut
						line.shape = shape\export!
						if line.shape != ""
							line.tags\remove "clip", "iclip"
							ass\insertLine line, s
				else
					ass\error s, "Expected \\clip or \\iclip tag"
		return ass\getNewSelection!

OffsettingDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.offsetting!, {"Ok", "Cancel"}, {close: "Cancel"}, "Offsetting"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:strokeWeight, :strokeAlign, :cornerStyle, :miterLimit, :arcPrecision, :cut} = elements
		if strokeWeight < 0
			strokeAlign = "Inside"
		cornerStyle = cornerStyle\lower!
		cutsOutside = cut and strokeAlign == "Outside"
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			ass\removeLine l, s
			Line.extend ass, l
			Line.callBackExpand ass, l, nil, (line) ->
				path, clip = Path line.shape
				if cutsOutside
					clip = path\clone!
				switch strokeAlign
					when "Outside" then path\offset strokeWeight, cornerStyle, "polygon", miterLimit, arcPrecision
					when "Center"  then path\offset strokeWeight, cornerStyle, "joined", miterLimit, arcPrecision
					when "Inside"  then path\offset -math.abs(strokeWeight), cornerStyle, "polygon", miterLimit, arcPrecision
				if cutsOutside
					path\difference clip
				line.shape = path\export!
				ass\insertLine line, s
		return ass\getNewSelection!

ManipulateDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.manipulate!, {"Simplify", "Flatten", "Cancel"}, {close: "Cancel"}, "Manipulate"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:enableClip, :recreateBezier, :distance, :angleThreshold} = elements
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l
			if enableClip
				{:clip, :isIclip} = l.data
				if clip
					if type(clip) != "table"
						clip = Path(clip)\flatten(distance)\simplify(tolerance, false, recreateBezier, angleThreshold)\export!
						if isIclip
							l.tags\insert {{"iclip", clip}}
						else
							l.tags\insert {{"clip", clip}}
						unless l.isShape
							l.text\modifyBlock l.tags
						ass\setLine l, s
				else
					ass\warning s, "Expected \\clip or \\iclip tag"
			else
				if l.isShape
					ass\removeLine l, s
					path = Path l.shape
					if button == "Flatten"
						path\flatten distance
					elseif button == "Simplify"
						path\flatten(distance)\simplify tolerance, false, recreateBezier, angleThreshold
					l.shape = path\export!
					ass\insertLine l, s
				else
					ass\warning s, "Expected a shape"
		return ass\getNewSelection!

TransformDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.transform!, {"Ok", "Cancel"}, {close: "Cancel"}, "Transform"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:horizontalScale, :verticalScale, :angle, :xAxis, :yAxis, :filter} = elements
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l
			if l.isShape
				ass\removeLine l, s
				path = Path l.shape
				if horizontalScale != 0 or verticalScale != 0
					path\scale horizontalScale, verticalScale
				if angle != 0
					path\rotate angle
				if xAxis != 0 or yAxis != 0
					path\move xAxis, yAxis
				if filter != ""
					box = path\boundingBox!
					raw = [[
						local ILL = require "ILL.ILL"
						local s, i, n = %d, %d, %d
						return function(x, y)
							left, top, right, bottom = %s, %s, %s, %s
							width, height = right - left, bottom - top
							%s
							return x, y
						end
					]]
					path\map loadstring(raw\format(s, i, n, box.l, box.t, box.r, box.b, filter))!
				l.shape = path\export!
				ass\insertLine l, s
			else
				ass\warning s, "Expected a shape"
		return ass\getNewSelection!

UtilitiesDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.utilities!, {"Shadow", "Corners", "Cancel"}, {close: "Cancel"}, "Utilities"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:shadow, :cornerStyle, :rounding, :radius} = elements
		switch button
			when "Shadow"
				local xshad, yshad
				for l, s, i, n in ass\iterSel!
					ass\progressLine s, i, n
					ass\removeLine l, s
					Line.extend ass, l
					Line.callBackExpand ass, l, nil, (line) ->
						{:data} = line
						switch shadow
							when "3D from shadow", "Inner shadow"
								xshad, yshad = Line.solveShadow line
								if shadow == "3D from shadow"
									line.shape = shadow3D line.shape, xshad, yshad
								else
									-- adds the current line, removing unnecessary tags
									line.tags\remove "shadow", "4c"
									line.tags\insert "\\shad0"
									ass\insertLine line, s
									-- adds the shadow color to the first color and sets
									-- the new value for the shape
									line.tags\insert {{"c", data.color4}}
									line.shape = shadowInner line.shape, xshad, yshad
							when "3D from shape"
								if n < 2 or n > 2
									Aegi.progressCancel "You must select 2 lines."
								if i == 1
									{xshad, yshad} = data.pos
									return
								else
									line.shape = shadow3D line.shape, xshad - data.pos[1], yshad - data.pos[2]
						line.tags\remove "shad", "xshad", "yshad", "4c"
						line.tags\insert "\\shad0"
						ass\insertLine line, s
			when "Corners"
				inverted = cornerStyle == "Inverted Round"
				for l, s, i, n in ass\iterSel!
					ass\progressLine s, i, n
					ass\removeLine l, s
					Line.extend ass, l
					Line.callBackExpand ass, l, nil, (line) ->
						path = Path line.shape
						path\openContours!
						newPath = Path!
						for contour in *path.path
							newContour, len = {}, #contour
							for i = 1, len
								j = i % len + 1
								k = (i + 1) % len + 1
								-- points that form a possible corner
								a = contour[i]
								b = contour[j]
								c = contour[k]
								-- checks if the start point is equal to the end point of the last segment, if it is a bezier segment
								-- for example, this happens for the letter S with the Arial font
								if i == len and a.id == "b" and b.id == "l" and a\equals b
									table.insert newContour, 1, a
								-- if the id value of point b(angle point) is "l", this means it is a corner
								elseif b.id == "l" and c.id == "l"
									if cornerStyle == "Rounded" or inverted
										if rounding == "Absolute"
											makeRoundingAbsolute radius, inverted, a, b, c, newContour
										elseif rounding == "Relative"
											makeRoundingRelative radius, inverted, a, b, c, newContour
									elseif cornerStyle == "Spike"
										modeSpike radius, a, b, c, newContour
									elseif cornerStyle == "Chamfer"
										modeChamfer radius, a, b, c, newContour
								-- this is not a corner, add the angle point and continue
								else
									if i == 1 and not b.id == "l"
										table.insert newContour, a
									table.insert newContour, b
							table.insert newPath.path, newContour
						line.shape = newPath\export!
						ass\insertLine line, s
		return ass\getNewSelection!

ConfigDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.config!, {"Ok", "Reset", "Cancel"}, {close: "Cancel"}, "Config"
	if button == "Reset"
		resetInterface elements.reset
		switch elements.reset
			when "Config"     then ConfigDialog sub, sel, activeLine
			when "Pathfinder" then PathfinderDialog sub, sel, activeLine
			when "Offsetting" then OffsettingDialog sub, sel, activeLine
			when "Manipulate" then ManipulateDialog sub, sel, activeLine
			when "Transform"  then TransformDialog sub, sel, activeLine
			when "Utilities"  then UtilitiesDialog sub, sel, activeLine

ShaperyMacrosDialog = (macro) ->
	(sub, sel, activeLine) ->
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		mergeShapesObj = {}
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l
			switch macro
				when "Shape expand"
					ass\removeLine l, s
					Line.callBackExpand ass, l, nil, (line) ->
						copy = Table.copy line
						if cfg.expandBordShadow
							xshad, yshad = Line.solveShadow line
							line.tags\remove "outline", "shadow", "3c", "4c"
							copy.tags\remove "outline", "shadow", "3c", "4c"
							line.tags\insert "\\shad0\\bord0"
							copy.tags\insert "\\shad0\\bord0"
							-- gets the required values
							{:outline, :color1, :color3, :color4} = line.data
							-- conditions to check if it needs to expand ouline, shadow or both
							passOutline = outline > 0
							passShadows = xshad != 0 or yshad != 0
							if passOutline or passShadows
								path, pathOutline, pathShadow, cutShadow = Path line.shape
								-- solves outline
								if passOutline
									pathOutline = path\clone!
									pathOutline\offset outline, "round"
									if passShadows
										cutShadow = pathOutline\clone!
								-- solves shadow
								if passShadows
									pathShadow = (pathOutline and pathOutline or path)\clone!
									pathShadow\move xshad, yshad
									if passOutline
										if color3 == color4
											pathShadow\unite pathOutline
											pathShadow\difference path
										else
											pathShadow\difference cutShadow\offset -cfg.cutBordShadow, "miter"
									else
										pathShadow\difference path
									line.shape = pathShadow\export!
									line.tags\insert {{"c", color4}}
									ass\insertLine line, s
								-- solves outline
								if passOutline and not (passShadows and color3 == color4)
									path\offset -cfg.cutBordShadow, "miter"
									pathOutline\difference path
									-- adds outline
									line.shape = pathOutline\export!
									line.tags\insert {{"c", color3}}
									ass\insertLine line, s
						ass\insertLine copy, s
				when "Shape clipper"
					{:clip, :isIclip} = l.data
					if clip
						ass\removeLine l, s
						Line.callBackExpand ass, l, nil, (line) ->
							shape = Path line.shape
							{px, py} = line.data.pos
							cut = Path(clip)\move -px, -py
							if isIclip
								shape\difference cut
							else
								shape\intersect cut
							line.shape = shape\export!
							if line.shape != ""
								line.tags\remove "clip", "iclip"
								ass\insertLine line, s
					else
						ass\warning s, "Expected \\clip or \\iclip tag"
				when "Shape to clip"
					clip = {}
					Line.callBackExpand ass, l, nil, (line) ->
						{px, py} = line.data.pos
						table.insert clip, Path(line.shape)\move(px, py)\export!
					clip = table.concat clip, " "
					if l.data.isIclip
						l.tags\insert {{"iclip", clip}}
					else
						l.tags\insert {{"clip", clip}}
					unless l.isShape
						l.text\modifyBlock l.tags
					ass\setLine l, s
				when "Clip to shape"
					{:an, :pos, :clip} = l.data
					if clip
						{px, py} = pos
						l.shape = Path(clip)\reallocate(an, nil, true, px, py)\export!
						l.tags\remove "perspective", "clip", "iclip"
						unless l.isShape
							l.isShape = true
							l.tags\remove "font"
							l.tags\insert {{"pos", pos}, true}, {{"an", an}, true}, "\\fscx100\\fscy100\\frz0\\p1"
						ass\setLine l, s
					else
						ass\warning s, "Expected \\clip or \\iclip tag"
				when "Shape bounding box"
					if l.isShape
						l.shape = Path(l.shape)\boundingBox!["assDraw"]
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
				when "Shape merge"
					if l.isShape
						{:color1, :color3, :color4, :alpha, :alpha1, :alpha2, :alpha3, :alpha4} = l.data
						code = (alpha .. color1 .. alpha1 .. color3 .. alpha3 .. color4 .. alpha4)\gsub "[&hH]*", ""
						Aegi.log code
						if n < 2
							ass\error s, "Expected one or more selected lines"
						if info = mergeShapesObj[code]
							clip = {}
							Line.callBackExpand ass, l, nil, (line, j) ->
								{x, y} = line.data.pos
								table.insert clip, Path(line.shape)\move(x - info.pos[1], y - info.pos[2])\export!
							info.shape ..= " " .. table.concat clip, " "
							if i == n
								mergeShapesArray = {}
								for k, v in pairs mergeShapesObj
									table.insert mergeShapesArray, v
								table.sort mergeShapesArray, (a, b) -> a.i < b.i
								if #mergeShapesArray > 0
									ass\deleteLines l, sel
									for k = 1, #mergeShapesArray
										{:line, :shape} = mergeShapesArray[k]
										line.shape = shape
										ass\insertLine line, s
						else
							clip, lcopy = {}, nil
							Line.callBackExpand ass, l, nil, (line, j) ->
								if j == 1
									lcopy = Table.copy line
								table.insert clip, Path(line.shape)\export!
							mergeShapesObj[code] = {:i, pos: l.data.pos, line: lcopy, shape: table.concat clip}
					else
						ass\warning s, "Expected a shape"
				when "Shape to 0,0"
					if l.isShape
						{x, y} = l.data.pos
						newPath = Path l.shape
						newPath\move x, y
						l.tags\remove "move"
						l.tags\insert {{"pos", {0, 0}}, true}
						l.shape = newPath\export!
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
				when "Shape to origin", "Shape to center"
					if l.isShape
						too = macro == "Shape to origin"
						newPath = Path l.shape
						{l: x, t: y, :width, :height} = newPath\boundingBox!
						if too
							newPath\toOrigin!
						else
							x += width / 2
							y += height / 2
							newPath\toCenter!
						l.shape = newPath\export!
						with l.data
							if l.tags\existsTag "move"
								.move[1] += x
								.move[2] += y
								.move[3] += x
								.move[4] += y
								l.tags\insert {{"move", .move}, true}
							else
								.pos[1] += x
								.pos[2] += y
								l.tags\insert {{"pos", .pos}, true}
						unless too
							Line.changeAlign l, 7
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
		return ass\getNewSelection!

if haveDepCtrl
	depctrl\registerMacros {
		{"Pathfinder", "", PathfinderDialog}
		{"Offsetting", "", OffsettingDialog}
		{"Manipulate", "", ManipulateDialog}
		{"Transform",  "", TransformDialog}
		{"Utilities",  "", UtilitiesDialog}
		{"Config",     "", ConfigDialog}
	}

	depctrl\registerMacros {
		{"Shape expand",       "", ShaperyMacrosDialog "Shape expand"}
		{"Shape clipper",      "", ShaperyMacrosDialog "Shape clipper"}
		{"Clip to shape",      "", ShaperyMacrosDialog "Clip to shape"}
		{"Shape to clip",      "", ShaperyMacrosDialog "Shape to clip"}
		{"Shape merge",        "", ShaperyMacrosDialog "Shape merge"}
		{"Shape to 0,0",       "", ShaperyMacrosDialog "Shape to 0,0"}
		{"Shape to origin",    "", ShaperyMacrosDialog "Shape to origin"}
		{"Shape to center",    "", ShaperyMacrosDialog "Shape to center"}
		{"Shape bounding box", "", ShaperyMacrosDialog "Shape bounding box"}
	}, ": Shapery macros :"
else
	aegisub.register_macro "#{script_name}/Pathfinder", "", PathfinderDialog
	aegisub.register_macro "#{script_name}/Offsetting", "", OffsettingDialog
	aegisub.register_macro "#{script_name}/Manipulate", "", ManipulateDialog
	aegisub.register_macro "#{script_name}/Transform",  "", TransformDialog
	aegisub.register_macro "#{script_name}/Utilities",  "", UtilitiesDialog
	aegisub.register_macro "#{script_name}/Config",     "", ConfigDialog

	aegisub.register_macro ": Shapery macros :/Shape expand",       "", ShaperyMacrosDialog "Shape expand"
	aegisub.register_macro ": Shapery macros :/Shape clipper",      "", ShaperyMacrosDialog "Shape clipper"
	aegisub.register_macro ": Shapery macros :/Clip to shape",      "", ShaperyMacrosDialog "Clip to shape"
	aegisub.register_macro ": Shapery macros :/Shape to clip",      "", ShaperyMacrosDialog "Shape to clip"
	aegisub.register_macro ": Shapery macros :/Shape merge",        "", ShaperyMacrosDialog "Shape merge"
	aegisub.register_macro ": Shapery macros :/Shape to 0,0",       "", ShaperyMacrosDialog "Shape to 0,0"
	aegisub.register_macro ": Shapery macros :/Shape to origin",    "", ShaperyMacrosDialog "Shape to origin"
	aegisub.register_macro ": Shapery macros :/Shape to center",    "", ShaperyMacrosDialog "Shape to center"
	aegisub.register_macro ": Shapery macros :/Shape bounding box", "", ShaperyMacrosDialog "Shape bounding box"