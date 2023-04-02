export script_name        = "Shapery"
export script_description = "Does several types of shape manipulations from the simplest to the most complex"
export script_version     = "2.2.0"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.Shapery"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, ConfigHandler, Clipper, ILL, Aegi, Ass, Line, Curve, Path, Point, Util, Math, Table, Util
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/klsruan/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"a-mo.ConfigHandler"
				version: "1.1.4"
				url: "https://github.com/TypesettingTools/Aegisub-Motion"
				feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"
			}
			{
				"clipper2.clipper2"
				version: "1.3.0"
				url: "https://github.com/klsruan/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/klsruan/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
			{
				"ILL.ILL"
				version: "1.3.0"
				url: "https://github.com/klsruan/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/klsruan/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	ConfigHandler, Clipper, ILL = depctrl\requireModules!
	{:Aegi, :Ass, :Line, :Curve, :Path, :Point, :Util, :Math, :Table, :Util} = ILL
else
	ConfigHandler = require "a-mo.ConfigHandler"
	Clipper = require "clipper2.clipper2"
	ILL = require "ILL.ILL"
	{:Aegi, :Ass, :Line, :Curve, :Path, :Point, :Util, :Math, :Table, :Util} = ILL

{:insert} = table

global = {}

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
		insert curves, approxUnitArc ang1, ang2
		ang1 += ang2

	result = {}
	for i = 1, #curves
		curve = curves[i]
		{x: x1, y: y1} = mapToEllipse curve[1], rx, ry, cosphi, sinphi, centerx, centery
		{x: x2, y: y2} = mapToEllipse curve[2], rx, ry, cosphi, sinphi, centerx, centery
		{:x, :y} = mapToEllipse curve[3], rx, ry, cosphi, sinphi, centerx, centery
		insert result, {x1, y1, x2, y2, x, y}

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
	insert path, p1
	insert path, p2
	insert path, p3

modeChamfer = (radius, a, b, c, path) ->
	{:line1, :line2} = modeRoundingAbsolute radius, a, b, c
	p1 = line1[2]
	p3 = line2[2]
	insert path, p1
	insert path, p3

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
	insert path, Point line1[2].x, line1[2].y
	for curve in *curves
		insert path, Point curve[1], curve[2], "b"
		insert path, Point curve[3], curve[4], "b"
		insert path, Point curve[5], curve[6], "b"

makeRoundingRelative = (r, inverted, a, b, c, path) ->
	p1, c1, c2, p4 = modeRoundingRelative r, inverted, a, b, c
	insert path, Point p1.x, p1.y
	insert path, Point c1.x, c1.y, "b"
	insert path, Point c2.x, c2.y, "b"
	insert path, Point p4.x, p4.y, "b"

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

Pathfinder = (ass, res) ->
	{:multiline, :operation} = res
	info = {shapes: {}}
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		ass\removeLine l, s
		Line.extend ass, l, i
		if multiline
			if n == 1
				Aegi.progressCancel "You must select 2 lines or more."
			clip = {}
			Line.callBackExpand ass, l, nil, (line, j) ->
				{x, y} = line.data.pos
				if i == 1 and j == 1
					info.pos = {x, y}
					info.line = Table.copy line
				insert clip, Path(line.shape)\move(x - info.pos[1], y - info.pos[2])\export!
			insert info.shapes, Path table.concat clip
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
			clip = l.data.clip
			Line.callBackExpand ass, l, nil, (line) ->
				{px, py} = line.data.pos
				shape = Path line.shape
				if clip
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

Offsetting = (ass, res) ->
	{:strokeWeight, :strokeAlign, :cornerStyle, :miterLimit, :arcPrecision, :cut} = res
	if strokeWeight < 0
		strokeAlign = "Inside"
	cornerStyle = cornerStyle\lower!
	cutsOutside = cut and strokeAlign == "Outside"
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		ass\removeLine l, s
		Line.extend ass, l, i
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

Manipulate = (ass, res, button) ->
	{:enableClip, :recreateBezier, :distance, :angleThreshold} = res
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		Line.extend ass, l, i
		if enableClip
			{:clip, :isIclip} = l.data
			if clip
				if type(clip) != "table"
					clip = Path(clip)\flatten(1)\simplify(tolerance, false, recreateBezier, angleThreshold)\export!
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

Transform = (ass, res) ->
	{:horizontalScale, :verticalScale, :angle, :xAxis, :yAxis} = res
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		Line.extend ass, l, i
		if l.isShape
			ass\removeLine l, s
			path = Path l.shape
			if horizontalScale != 0 or verticalScale != 0
				path\scale horizontalScale, verticalScale
			if angle != 0
				path\rotate angle
			if xAxis != 0 or yAxis != 0
				path\move xAxis, yAxis
			l.shape = path\export!
			ass\insertLine l, s
		else
			ass\warning s, "Expected a shape"
	return ass\getNewSelection!

ShadowEffect = (ass, res) ->
	{:shadow} = res
	local xshad, yshad
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		ass\removeLine l, s
		Line.extend ass, l, i
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
	return ass\getNewSelection!

CornerEffect = (ass, res) ->
	{:cornerStyle, :rounding, :radius} = res
	inverted = cornerStyle == "Inverted Round"
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		ass\removeLine l, s
		Line.extend ass, l, i
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
						insert newContour, 1, a
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
							insert newContour, a
						insert newContour, b
				insert newPath.path, newContour
			line.shape = newPath\export!
			ass\insertLine line, s
	return ass\getNewSelection!

ShaperyMacros = (ass, macro) ->
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		Line.extend ass, l, i
		switch macro
			when "Shape expand"
				ass\removeLine l, s
				Line.callBackExpand ass, l, nil, (line) ->
					copy = Table.copy line
					if global.expandBordShadow
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
										pathShadow\difference cutShadow\offset -global.cutBordShadow, "miter"
								else
									pathShadow\difference path
								line.shape = pathShadow\export!
								line.tags\insert {{"c", color4}}
								ass\insertLine line, s
							-- solves outline
							if passOutline and not (passShadows and color3 == color4)
								path\offset -global.cutBordShadow, "miter"
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
					insert clip, Path(line.shape)\move(px, py)\export!
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
					if type(clip) == "table"
						{cl, ct, cr, cb} = clip
						clip = "m #{cl} #{ct} l #{cr} #{ct} #{cr} #{cb} #{cl} #{cb}"
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
			when "Shape to origin", "Shape to center"
				if l.isShape
					torigin = macro == "Shape to origin"
					newPath = Path l.shape
					{l: pl, t: pt, :width, :height} = newPath\boundingBox!
					x = torigin and -pl or -pl - width / 2
					y = torigin and -pt or -pt - height / 2
					newPath\move x, y
					l.shape = newPath\export!
					with l.data
						if l.tags\existsTag "move"
							.move[1] -= x
							.move[2] -= y
							.move[3] -= x
							.move[4] -= y
							l.tags\insert {{"move", .move}, true}
						else
							.pos[1] -= x
							.pos[2] -= y
							l.tags\insert {{"pos", .pos}, true}
					ass\setLine l, s
				else
					ass\warning s, "Expected a shape"
	return ass\getNewSelection!

guis = {
	pathfinder: {
		operationLabel: {
			class: "label", label: "Operation:",
			x: 0, y: 0
		},
		operation: {
			class: "dropdown",
			value: "Unite", config: true, items: {"Unite", "Intersect", "Difference", "Exclude"},
			x: 1, y: 0,
			hint: ""
		},
		multiline: {
			class: "checkbox", label: "Multiline",
			value: false,
			x: 0, y: 2,
			hint: ""
		},
	},
	offsetting: {
		strokeWeightLabel: {
			class: "label", label: "Stroke weight",
			x: 0, y: 0
		},
		strokeWeight: {
			class: "floatedit",
			value: 0, config: true,
			x: 1, y: 0, width: 1, height: 1
		},
		cut: {
			class: "checkbox", label: "Cut",
			value: false, config: true,
			x: 1, y: 1, width: 1, height: 1
			hint: ""
		},
		cornerStyleLabel: {
			class: "label", label: "Corner style",
			x: 0, y: 2
		},
		cornerStyle: {
			class: "dropdown",
			value: "Miter", config: true, items: {"Miter", "Round", "Square"},
			x: 1, y: 2
			hint: ""
		},
		strokeAlignLabel: {
			class: "label", label: "Align stroke",
			x: 0, y: 3
		},
		strokeAlign: {
			class: "dropdown",
			value: "Outside", config: true, items: {"Outside", "Center", "Inside"},
			x: 1, y: 3
		},
		miterLimitLabel: {
			class: "label", label: "Miter limit",
			x: 0, y: 5
		},
		arcPrecisionLabel: {
			class: "label", label: "Arc precision",
			x: 1, y: 5
		},
		miterLimit: {
			class: "floatedit",
			value: 2, config: true
			x: 0, y: 6, width: 1, height: 1,
			hint: "miterLimit"
		},
		arcPrecision: {
			class: "floatedit",
			value: 0.25, config: true,
			x: 1, y: 6, width: 1, height: 1,
			hint: "arcTolerance"
		},
	},
	manipulate: {
		fitCurvesLabel: {
			class: "label",
			label: "Fit Curves",
			x: 0, y: 0
		},
		recreateBezier: {
			class: "checkbox",
			label: "#{(" ")\rep 28}"
			value: true, config: true,
			x: 3, y: 0
		},
		enableClipLabel: {
			class: "label",
			label: "Execute On \\clip",
			x: 0, y: 1
		},
		enableClip: {
			class: "checkbox",
			value: false, config: true,
			x: 3, y: 1
		},
		simplifyLabel: {
			class: "label",
			label: "- Simplify -----",
			x: 0, y: 3
		},
		toleranceLabel: {
			class: "label",
			label: "Tolerance",
			x: 0, y: 4
		},
		tolerance: {
			class: "floatedit",
			value: 0.5, config: true, min: 0.1, max: 10, step: 0.01
			x: 3, y: 4
		},
		angleThresholdLabel: {
			class: "label",
			label: "Angle Threshold",
			x: 0, y: 5
		},
		angleThreshold: {
			class: "floatedit",
			value: 170, config: true, min: 0, max: 180, step: 0.1
			x: 3, y: 5
		},
		flattenLabel: {
			class: "label",
			label: "- Flatten -----",
			x: 0, y: 7
		},
		distanceLabel: {
			class: "label",
			label: "Distance",
			x: 0, y: 8
		},
		distance: {
			class: "floatedit",
			value: 1, config: true, min: 0.1, max: 100, step: 0.1
			x: 3, y: 8
		},
	},
	transform: {
		moveLabel: {
			class: "label", label: "Move",
			x: 0, y: 0
		},
		xAxisLabel: {
			class: "label", label: "X axis",
			x: 0, y: 1
		},
		xAxis: {
			class: "floatedit",
			value: 0,
			x: 1, y: 1, width: 1, height: 1
		},
		yAxisLabel: {
			class: "label", label: "Y axis",
			x: 0, y: 2
		},
		yAxis: {
			class: "floatedit",
			value: 0,
			x: 1, y: 2, width: 1, height: 1
		},
		rotationLabel: {
			class: "label", label: "Rotate",
			x: 4, y: 0
		},
		angleLabel: {
			class: "label", label: "Angle",
			x: 4, y: 1
		},
		angle: {
			class: "floatedit",
			value: 0,
			x: 4, y: 2, width: 1, height: 1
		},
		scaleLabel: {
			class: "label", label: "Scale",
			x: 8, y: 0
		},
		horizontalLabel: {
			class: "label", label: "Hor. %",
			x: 8, y: 1
		},
		verticalLabel: {
			class: "label", label: "Ver. %",
			x: 8, y: 2
		},
		horizontalScale: {
			class: "floatedit",
			value: 100, min: 1, max: 500, step: 0.1
			x: 9, y: 1, width: 1, height: 1
		},
		verticalScale: {
			class: "floatedit",
			value: 100, min: 1, max: 500, step: 0.1,
			x: 9, y: 2, width: 1, height: 1,
		},
	},
	utilities: {
		shadowLabel: {
			class: "label", label: "Shadow Effect",
			x: 0, y: 0
		},
		shadow: {
			class: "dropdown",
			value: "Inner shadow", config: true,
			items: {"Inner shadow", "3D from shadow", "3D from shape"},
			x: 0, y: 1
		},
		cornerLabel: {
			class: "label", label: "Corner",
			x: 4, y: 0
		},
		cornerStyle: {
			class: "dropdown",
			value: "Rounded", config: true, items: {"Rounded", "Inverted Round", "Chamfer", "Spike"},
			x: 5, y: 0
		},
		radiusLabel: {
			class: "label", label: "Radius",
			x: 4, y: 1
		},
		radius: {
			class: "floatedit",
			value: 0, config: true, min: 0, max: 1e5, step: 0.1,
			x: 5, y: 1
		},
		roundingLabel: {
			class: "label", label: "Rounding",
			x: 4, y: 2
		},
		rounding: {
			class: "dropdown",
			value: "Absolute", config: true, items: {"Absolute", "Relative"},
			x: 5, y: 2
		}
	},
	config: {
		expandTagLabel: {
			class: "label", label: "Expand",
			x: 0, y: 0
		},
		cutBordShadow: {
			class: "floatedit",
			value: 1, config: true, min: 0.1, max: 2, step: 0.1,
			hint: "Cutting gap size"
			x: 0, y: 1
		},
		expandBordShadow: {
			class: "checkbox", label: "Cut",
			value: false, config: true,
			hint: "Cuts the outline, shadow and fill"
			x: 0, y: 2,
		},
		bordBehaviourLabel: {
			class: "label", label: "Renderer #{(" ")\rep 14}",
			x: 0, y: 5
		},
		bordBehaviour: {
			class: "dropdown",
			value: "libass", config: true, items: {"libass", "VSFilter"},
			x: 5, y: 5
		},
		saveLines: {
			class: "checkbox", label: "Save lines",
			value: false, config: true,
			hint: "Saves the selected lines, the saved lines will be commented out"
			x: 5, y: 0
		},
	}
}

LoadGlobalOptions = ->
	-- there is for sure a better way to load "global" options
	-- but i don't know it
	global = ConfigHandler guis, depctrl.configFile, false, script_version, depctrl.configDir
	global\read!
	global\updateInterface "config"
	global = {
		expandBordShadow: guis.config.expandBordShadow.value
		cutBordShadow: guis.config.cutBordShadow.value
		bordBehaviour: guis.config.bordBehaviour.value
		saveLines: guis.config.saveLines.value
	}

LoadConfig = (interface) ->
	LoadGlobalOptions!
	config = ConfigHandler guis, depctrl.configFile, false, script_version, depctrl.configDir
	config\read!
	config\updateInterface interface
	return config

SaveConfig = (config, values, interface) ->
	config\updateConfiguration values, interface
	config\write!

ConfigDialog = (sub, sel, activeLine) ->
	config = LoadConfig "config"
	run, res = aegisub.dialog.display guis.config, {"Save", "Reset", "Cancel"}, {close: "Cancel"}
	if run == "Save"
		SaveConfig config, res, "config"
		LoadGlobalOptions!
	elseif run == "Reset"
		config = ConfigHandler guis, depctrl.configFile, false, script_version, depctrl.configDir
		config\write!

PathfinderDialog = (sub, sel, activeLine) ->
	config = LoadConfig "pathfinder"
	run, res = aegisub.dialog.display guis.pathfinder, {"Ok", "Cancel"}, {close: "Cancel"}
	if run == "Ok"
		SaveConfig config, res, "pathfinder"
		return Pathfinder Ass(sub, sel, activeLine, not global.saveLines), res

OffsettingDialog = (sub, sel, activeLine) ->
	config = LoadConfig "offsetting"
	run, res = aegisub.dialog.display guis.offsetting, {"Ok", "Cancel"}, {close: "Cancel"}
	if run == "Ok"
		SaveConfig config, res, "offsetting"
		return Offsetting Ass(sub, sel, activeLine, not global.saveLines), res

ManipulateDialog = (sub, sel, activeLine) ->
	config = LoadConfig "manipulate"
	run, res = aegisub.dialog.display guis.manipulate, {"Simplify", "Flatten", "Cancel"}, {close: "Cancel"}
	if run != "Cancel"
		SaveConfig config, res, "manipulate"
		return Manipulate Ass(sub, sel, activeLine, not global.saveLines), res, run

TransformDialog = (sub, sel, activeLine) ->
	config = LoadConfig "transform"
	run, res = aegisub.dialog.display guis.transform, {"Ok", "Cancel"}, {close: "Cancel"}
	if run == "Ok"
		SaveConfig config, res, "transform"
		return Transform Ass(sub, sel, activeLine, not global.saveLines), res

UtilitiesDialog = (sub, sel, activeLine) ->
	config = LoadConfig "utilities"
	run, res = aegisub.dialog.display guis.utilities, {"Shadow", "Corners", "Cancel"}, {close: "Cancel"}
	if run != "Cancel"
		SaveConfig config, res, "utilities"
		ass = Ass sub, sel, activeLine, not global.saveLines
		switch run
			when "Shadow"  then ShadowEffect ass, res
			when "Corners" then CornerEffect ass, res
		return ass\getNewSelection!

ShaperyMacrosDialog = (macro) ->
	(sub, sel, activeLine) ->
		LoadGlobalOptions!
		return ShaperyMacros Ass(sub, sel, activeLine, not global.saveLines), macro

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
		{"Shape to origin",    "", ShaperyMacrosDialog "Shape to origin"}
		{"Shape to center",    "", ShaperyMacrosDialog "Shape to center"}
		{"Shape bounding box", "", ShaperyMacrosDialog "Shape bounding box"}
	}, ": Shapery macros :"
else
	aegisub.register_macro "#{script_name} / Pathfinder", "", PathfinderDialog
	aegisub.register_macro "#{script_name} / Offsetting", "", OffsettingDialog
	aegisub.register_macro "#{script_name} / Manipulate", "", ManipulateDialog
	aegisub.register_macro "#{script_name} / Transform",  "", TransformDialog
	aegisub.register_macro "#{script_name} / Utilities",  "", UtilitiesDialog
	aegisub.register_macro "#{script_name} / Config",     "", ConfigDialog

	aegisub.register_macro ": Shapery macros : / Shape expand",       "", ShaperyMacrosDialog "Shape expand"
	aegisub.register_macro ": Shapery macros : / Shape clipper",      "", ShaperyMacrosDialog "Shape clipper"
	aegisub.register_macro ": Shapery macros : / Clip to shape",      "", ShaperyMacrosDialog "Clip to shape"
	aegisub.register_macro ": Shapery macros : / Shape to clip",      "", ShaperyMacrosDialog "Shape to clip"
	aegisub.register_macro ": Shapery macros : / Shape to origin",    "", ShaperyMacrosDialog "Shape to origin"
	aegisub.register_macro ": Shapery macros : / Shape to center",    "", ShaperyMacrosDialog "Shape to center"
	aegisub.register_macro ": Shapery macros : / Shape bounding box", "", ShaperyMacrosDialog "Shape bounding box"