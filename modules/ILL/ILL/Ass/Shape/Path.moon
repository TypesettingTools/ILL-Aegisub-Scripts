CPP = require "clipper2.clipper2"

import Point from require "ILL.ILL.Ass.Shape.Point"
import Curve from require "ILL.ILL.Ass.Shape.Curve"
import Segment from require "ILL.ILL.Ass.Shape.Segment"
{:insert, :remove} = table

class Path

	-- Create a new Path object
	new: (path) =>
		if type(path) == "string"
			@import path
		elseif type(path) == "table"
			@path = {}
			if type(path[1]) == "number"
				@path[1] = {
					Point path[1], path[2]
					Point path[3], path[2]
					Point path[3], path[4]
					Point path[1], path[4]
				}
				return
			if rawget path, "path"
				path = path.path
			for contour in *path
				insert @path, {}
				for point in *contour
					insert @path[#@path], point\clone!
		else
			@path = {}

	-- Returns a copy of the path.
	clone: => Path @path

	-- Maps all points on the Path
	map: (fn) =>
		for contour in *@path
			for point in *contour
				px, py = fn point.x, point.y, point
				if px and py
					point.x, point.y = px, py
		return @

	-- Callback to access the Curves and Segments
	callBackPath: (fn) =>
		for contour in *@path
			j = 2
			while j <= #contour
				prev = contour[j-1]
				curr = contour[j]
				if curr.id == "b"
					if "break" == fn "b", Curve prev, curr, contour[j+1], contour[j+2]
						return
					j += 2
				else
					if "break" == fn "l", Segment prev, curr
						return
				j += 1
		return @

	-- Gets the bounding box and other information from the Path
	boundingBox: =>
		l, t, r, b = math.huge, math.huge, -math.huge, -math.huge
		@map (x, y) ->
			l = math.min l, x
			t = math.min t, y
			r = math.max r, x
			b = math.max b, y
		-- width, height, origin, ass shape
		width = r - l
		height = b - t
		origin = Point l, t
		center = Point l + width / 2, t + height / 2
		assDraw = ("m %s %s l %s %s %s %s %s %s")\format l, t, r, t, r, b, l, b
		return {:l, :t, :r, :b, :width, :height, :origin, :center, :assDraw}

	-- Flattens bezier segments and optionally flattens line segments of the @path
	flatten: (distance, flattenStraight, customLen) =>
		newPath = {}
		for contour in *@path
			j, newContour = 2, {}
			insert newContour, contour[1]\clone!
			while j <= #contour
				prev = contour[j-1]
				curr = contour[j]
				if curr.id == "b"
					points = Curve(prev, curr, contour[j+1], contour[j+2])\flatten customLen, distance
					for k = 2, #points
						insert newContour, points[k]
					j += 2
				else
					if flattenStraight
						points = Segment(prev, curr)\flatten customLen, distance
						for k = 2, #points
							insert newContour, points[k]
					else
						insert newContour, curr
				j += 1
			insert newPath, newContour
		@path = newPath
		return @

	-- Simplifies the number of path points
	simplify: (tolerance = 0.5, highestQuality = true, recreateBezier = true, angleThreshold = 170) =>
		@cleanContours!
		@path = Path.PathSimplifier(@path, tolerance, highestQuality, recreateBezier, angleThreshold)
		return @

	-- Move the @path by specified distance
	move: (px, py) =>
		@map (x, y, p) ->
			p\move px, py

	-- Rotates the @path by specified angle
	-- Note: the angle is based on the \frz tag
	rotate: (angle) =>
		@map (x, y, p) ->
			p\rotate angle

	-- Scales the @path by specified horizontal and vertical values
	-- Note: the values are defined on a scale of 100
	scale: (hor, ver) =>
		@map (x, y, p) ->
			p\scale hor, ver

	-- Moves the points to the origin of the plane
	toOrigin: =>
		{:origin} = @boundingBox!
		@move -origin.x, -origin.y

	-- Moves the points to the center of the plane
	toCenter: =>
		{:origin, :width, :height} = @boundingBox!
		@move -origin.x - width * 0.5, -origin.y - height * 0.5

	-- Reallocates the shape to align 7 or from align 7 to any other align
	reallocate: (an, box, rev, x = 0, y = 0) =>
		{:width, :height} = box and box or @boundingBox!
		-- offset to y-axis according to defined alignment
		tx = switch an
			when 1, 4, 7 then 0
			when 2, 5, 8 then 0.5
			when 3, 6, 9 then 1
		-- offset to x-axis according to defined alignment
		ty = switch an
			when 7, 8, 9 then 0
			when 4, 5, 6 then 0.5
			when 1, 2, 3 then 1
		-- moves the shape to a position relative to the alignment value 7
		unless rev
			@move x - width * tx, y - height * ty
		else
			-- does the reverse operation
			@move -x + width * tx, -y + height * ty

	-- Makes a distortion based on the control points given by a quadrilateral
	perspective: (mesh, real, mode) =>
		path = mode == "warping" and Path({mesh}) or @
		unless real
			{:l, :t, :r, :b} = path\boundingBox!
			real = {Point(l, t), Point(r, t), Point(r, b), Point(l, b)}
		@map (x, y, pt) ->
			uv = pt\quadPT2UV unpack real
			pt = uv\quadUV2PT unpack mesh
			return pt.x, pt.y

	-- Creates a grid for the distortion envelope
	envelopeGrid: (numRows, numCols, isBezier) =>
		{:assDraw, :l, :t, :width, :height} = @boundingBox!
		rowDistance = height / numRows
		colDistance = width / numCols
		rect = Path!
		rect.path[1] = {
			Point 0, 0
			Point colDistance, 0
			Point colDistance, rowDistance
			Point 0, rowDistance
		}
		rectsCol, rectsRow = Path!, Path!
		for col = 0, numCols - 1
			newRect = rect\clone!
			newRect\move col * colDistance, 0
			insert rectsCol.path, newRect.path[1]
		for row = 0, numRows - 1
			newRect = rectsCol\clone!
			newRect\move 0, row * rowDistance
			for i = 1, #newRect.path
				insert rectsRow.path, newRect.path[i]
		if isBezier
			rectsRow\closeContours!
			rectsRow\allCurve!
		return rectsRow\move(l, t), colDistance, rowDistance

	-- Makes a distortion based on the control points given by a mesh
	envelopeDistort: (gridMesh, gridReal, ep = 0.5) =>
		assert #gridMesh == #gridReal, "The control points must have the same quantity!"
		{:l, :t, :r, :b} = @boundingBox!
		distort = (mesh, real, pt) ->
			assert #real == #mesh, "The control points must have the same quantity!"
			for i = 1, #mesh
				with mesh[i]
					.x = .x == l and .x - ep or (.x == r and .x + ep or .x)
					.y = .y == t and .y - ep or (.y == b and .y + ep or .y)
				with real[i] 
					.x = .x == l and .x - ep or (.x == r and .x + ep or .x)
					.y = .y == t and .y - ep or (.y == b and .y + ep or .y)
			findAngles = (pt) ->
				A = {}
				for i = 1, #real
					vi, vj = real[i], real[i % #real + 1]
					r0i = pt\distance vi
					r0j = pt\distance vj
					rij = vi\distance vj
					r = (r0i ^ 2 + r0j ^ 2 - rij ^ 2) / (2 * r0i * r0j)
					A[i] = r != r and 0 or math.acos math.max -1, math.min r, 1
				return A
			findWeights = (pt) ->
				W = {}
				A = findAngles pt
				for i = 1, #real
					j = (i > 1 and i or #real + 1) - 1
					r = real[i]\distance pt
					W[i] = (math.tan(A[j] / 2) + math.tan(A[i] / 2)) / r
				return W
			normalizeWeights = (pt) ->
				Ws, W = 0, findWeights pt
				for i = 1, #W
					Ws += W[i]
				return Ws, W
			nx, ny, Ws, W = 0, 0, normalizeWeights pt
			for i = 1, #real
				L = W[i] / Ws
				with mesh[i]
					nx += L * .x
					ny += L * .y
			return nx, ny
		-- https://stackoverflow.com/a/28130452/15411556
		pointInsidePolygon = (points, p, ep = 2) ->
			n = #points
			j = n
			r = false
			for i = 1, n
				a = points[i]
				b = points[j]
				if math.abs(a.y - b.y) <= ep and math.abs(b.y - p.y) <= ep and (a.x >= p.x) != (b.x >= p.x)
					return true
				if (a.y > p.y) != (b.y > p.y)
					c = (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x
					if math.abs(p.x - c) <= ep
						return true
					if p.x < c
						r = not r
				j = i
			return r
		@map (x, y, pt) ->
			for i = 1, #gridMesh.path
				if pointInsidePolygon gridReal.path[i], pt
					return distort gridMesh.path[i], gridReal.path[i], pt

	-- Checks if all contours are open
	areContoursOpen: =>
		for contour in *@path
			firstPoint = contour[1]
			lastPoint = contour[#contour]
			if firstPoint\equals lastPoint
				return false
		return true

	-- Closes all contours that are open
	closeContours: =>
		for contour in *@path
			firstPoint = contour[1]
			lastPoint = contour[#contour]
			unless firstPoint\equals lastPoint
				newPoint = firstPoint\clone!
				newPoint.id = "l"
				insert contour, newPoint
		return @

	-- Opens all contours that are closed
	openContours: =>
		for contour in *@path
			firstPoint = contour[1]
			lastPoint = contour[#contour]
			if lastPoint.id == "l" and firstPoint\equals lastPoint
				remove contour, #contour
		return @

	-- Removes the duplicate points in sequence on the contours
	cleanContours: =>
		for contour in *@path
			j = 2
			while j <= #contour
				prev = contour[j-1]
				curr = contour[j]
				if curr.id == "b"
					if j > 2 and prev\equals curr
						j -= 1
						remove contour, j
					j += 2
				elseif prev\equals curr
					remove contour, j
					j -= 1
				j += 1
		return @

	-- Converts all line segments to bezier segments
	allCurve: =>
		newPath = {}
		for contour in *@path
			j, add = 2, {contour[1]\clone!}
			while j <= #contour
				prev = contour[j-1]
				curr = contour[j]
				if curr.id == "b"
					insert add, curr
					insert add, contour[j+1]
					insert add, contour[j+2]
					j += 2
				else
					unless prev\equals curr
						a, b, c, d = Segment(prev, curr)\lineToBezier!
						insert add, b
						insert add, c
						insert add, d
					else
						insert add, curr
				j += 1
			insert newPath, add
		@path = newPath
		return @

	-- Gets the total length of the Path
	getLength: =>
		length = 0
		@callBackPath (id, seg) ->
			length += seg\getLength!
		return length

	-- Gets the normalized tangent on the Path given a time
	getNormalized: (t = 0.5) =>
		sumLength, length, tan, p, u = 0, t * @getLength!, nil, nil, nil
		@callBackPath (id, seg) ->
			segmentLen = seg\getLength!
			if sumLength + segmentLen >= length
				u = (length - sumLength) / segmentLen
				tan, p, u = seg\getNormalized u
				return "break"
			sumLength += segmentLen
		return tan, p, u

	-- Distort the Path into another Path
	-- http://www.planetclegg.com/projects/WarpingTextToSplines.html
	inClip: (an = 7, clip, mode = "center", leng, offset = 0) =>
		{:origin, :width, :height} = @boundingBox!
		{x: ox, y: oy} = origin
		if type(clip) == "string"
			clip = Path(clip)\openContours!
		leng or= clip\getLength!
		size = leng - width
		@flatten nil, true
		sx = switch mode
			when 1, "left"   then -ox + offset
			when 2, "center" then -ox + offset + size * 0.5
			when 3, "right"  then -ox - offset + size
		sy = switch an
			when 7, 8, 9 then -oy - height
			when 4, 5, 6 then -oy - height * 0.5
			when 1, 2, 3 then -oy
		@map (x, y) ->
			tan, pnt = clip\getNormalized (sx + x) / leng, true
			px = pnt.x + (sy + y) * tan.x
			py = pnt.y + (sy + y) * tan.y
			return px, py

	-- Create the @path table for the given string
	import: (shape) =>
		@path = {}
		for strPath in shape\gmatch "m [^m]+"
			insert @path, {}
			i, path, currCmd = 2, @path[#@path], nil
			for cmd, x, y in strPath\gmatch "(%a?)%s+(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)"
				if cmd != ""
					-- checks if the shape has only m, l and b commands
					unless cmd\find "[mlb]"
						error "shape unknown", 2
					currCmd = cmd
				insert path, Point tonumber(x), tonumber(y), currCmd
			path[1].id = "l"
		return @

	-- Create a string for @path
	export: (decimal = 2) =>
		shape = {}
		for i = 1, #@path
			shape[i] = {}
			j, contour, cmd = 2, @path[i], nil
			while j <= #contour
				prev = contour[j-1]\round decimal
				curr = contour[j]\round decimal
				if curr.id == "b"
					c = contour[j+1]\round decimal
					d = contour[j+2]\round decimal
					if cmd == "b"
						insert shape[i], "#{curr.x} #{curr.y} #{c.x} #{c.y} #{d.x} #{d.y}"
					else
						cmd = "b"
						insert shape[i], "b #{curr.x} #{curr.y} #{c.x} #{c.y} #{d.x} #{d.y}"
					j += 2
				else
					if cmd == "l"
						insert shape[i], "#{curr.x} #{curr.y}"
					else
						cmd = "l"
						insert shape[i], "l #{curr.x} #{curr.y}"
				j += 1
			shape[i] = "m #{contour[1].x} #{contour[1].y} " .. table.concat shape[i], " "
		return table.concat shape, " "

	-- (Clipper function)
	-- Converts ILL Path to Clipper Paths
	convertToClipper: (reduce = 1, flattenStraight) =>
		cppPaths = CPP.paths.new!
		for contour in *@path
			j, cppPath = 2, CPP.path.new!
			cppPath\add "line", contour[1].x, contour[1].y
			while j <= #contour
				prev = contour[j-1]
				curr = contour[j]
				if curr.id == "b"
					c, d = contour[j+1], contour[j+2]
					cppPath\add "bezier", reduce, prev.x, prev.y, curr.x, curr.y, c.x, c.y, d.x, d.y
					j += 2
				else
					if flattenStraight
						cppPath\add "line", reduce, prev.x, prev.y, curr.x, curr.y
					else
						cppPath\add "line", curr.x, curr.y
				j += 1
			cppPaths\add cppPath
		return cppPaths

	-- (Clipper function)
	-- Converts Clipper Paths to ILL Path
	convertFromClipper: (cppPaths) ->
		path = Path!
		for i = 1, cppPaths\len!
			path.path[i] = {}
			cppPath = cppPaths\get i
			for j = 1, cppPath\len!
				{:x, :y} = cppPath\get j
				insert path.path[i], Point x, y
		return path

	-- (Clipper function)
	-- Join @path with another path object 
	unite: (clip) =>
		subj = @convertToClipper!
		clip = clip\convertToClipper!
		@path = Path.convertFromClipper(subj\union clip).path
		return @

	-- (Clipper function)
	-- Remove from @path another path object
	difference: (clip) =>
		subj = @convertToClipper!
		clip = clip\convertToClipper!
		@path = Path.convertFromClipper(subj\difference clip).path
		return @

	-- (Clipper function)
	-- Intersect @path with another path object
	intersect: (clip) =>
		subj = @convertToClipper!
		clip = clip\convertToClipper!
		@path = Path.convertFromClipper(subj\intersection clip).path
		return @

	-- (Clipper function)
	-- Join @path with another path object and remove the parts where those intersect
	exclude: (clip) =>
		subj = @convertToClipper!
		clip = clip\convertToClipper!
		@path = Path.convertFromClipper(subj\xor clip).path
		return @

	-- (Clipper function)
	-- Inflate/deflate @path by the specifies amount
	offset: (delta, join_type, end_type, miter_limit, arc_tolerance, preserve_collinear, reverse_solution) =>
		subj = @convertToClipper!
		subj = subj\inflate delta, join_type, end_type, miter_limit, arc_tolerance, preserve_collinear, reverse_solution
		@path = Path.convertFromClipper(subj).path
		return @

Path.PathSimplifier = (points, tolerance = 0.1, highestQuality, recreateBezier, angleThreshold) ->
	simplifyRadialDist = (points, sqTolerance) ->
		prevPoint = points[1]
		newPoints = {prevPoint}
		local point

		for i = 2, #points
			point = points[i]

			if point\sqDistance(prevPoint) > sqTolerance
				table.insert newPoints, point
				prevPoint = point

		if (prevPoint.x != point.x) and (prevPoint.y != point.y)
			table.insert newPoints, point

		return newPoints

	simplifyDPStep = (points, first, last, sqTolerance, simplified) ->
		maxSqDist, index = sqTolerance

		for i = first + 1, last
			sqDist = points[i]\sqSegDistance points[first], points[last]

			if (sqDist > maxSqDist)
				index = i
				maxSqDist = sqDist

		if (maxSqDist > sqTolerance)
			if (index - first > 1)
				simplifyDPStep(points, first, index, sqTolerance, simplified)
			table.insert simplified, points[index]

			if (last - index > 1)
				simplifyDPStep(points, index, last, sqTolerance, simplified)

	simplifyDouglasPeucker = (points, sqTolerance) ->
		last = #points
		simplified = {points[1]}

		simplifyDPStep(points, 1, last - 1, sqTolerance, simplified)
		table.insert simplified, points[last]

		return simplified

	-- bezier
	computeLeftTangent = (d, _end) ->
		tHat1 = d[_end + 1]\subtract(d[_end])
		return tHat1\vecNormalize!

	computeRightTangent = (d, _end) ->
		tHat2 = d[_end - 1]\subtract(d[_end])
		return tHat2\vecNormalize!

	computeCenterTangent = (d, center) ->
		V1 = d[center - 1]\subtract(d[center])
		V2 = d[center]\subtract(d[center + 1])
		tHatCenter = Point!
		tHatCenter.x = (V1.x + V2.x) / 2
		tHatCenter.y = (V1.y + V2.y) / 2
		return tHatCenter\vecNormalize!

	chordLengthParameterize = (d, first, last) ->
		u = {0}
		for i = first + 1, last
			u[i - first + 1] = u[i - first] + d[i]\distance d[i - 1]
		for i = first + 1, last
			u[i - first + 1] /= u[last - first + 1]
		return u

	bezierII = (degree, V, t) ->
		Vtemp = {}
		for i = 0, degree
			Vtemp[i] = Point V[i + 1].x, V[i + 1].y

		for i = 1, degree
			for j = 0, degree - i
				Vtemp[j].x = (1 - t) * Vtemp[j].x + t * Vtemp[j + 1].x
				Vtemp[j].y = (1 - t) * Vtemp[j].y + t * Vtemp[j + 1].y

		return Point Vtemp[0].x, Vtemp[0].y

	computeMaxError = (d, first, last, bezCurve, u, splitPoint) ->
		splitPoint = (last - first + 1) / 2

		maxError = 0
		for i = first + 1, last - 1
			P = bezierII(3, bezCurve, u[i - first + 1])
			v = P\subtract d[i]
			dist = v\vecLength!
			if dist >= maxError
				maxError = dist
				splitPoint = i

		return {:maxError, :splitPoint}

	newtonRaphsonRootFind = (_Q, _P, u) ->
		Q1, Q2 = {}, {}

		Q = {
			Point _Q[1].x, _Q[1].y
			Point _Q[2].x, _Q[2].y
			Point _Q[3].x, _Q[3].y
			Point _Q[4].x, _Q[4].y
		}
	
		P = Point _P.x, _P.y

		Q_u = bezierII(3, Q, u)
		for i = 1, 3
			Q1[i] = Point!
			Q1[i].x = (Q[i + 1].x - Q[i].x) * 3
			Q1[i].y = (Q[i + 1].y - Q[i].y) * 3

		for i = 1, 2
			Q2[i] = Point!
			Q2[i].x = (Q1[i + 1].x - Q1[i].x) * 2
			Q2[i].y = (Q1[i + 1].y - Q1[i].y) * 2
	
		Q1_u = bezierII(2, Q1, u)
		Q2_u = bezierII(1, Q2, u)

		numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y)
		denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) + (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y)

		if denominator == 0
			return u

		return u - (numerator / denominator)

	reparameterize = (d, first, last, u, bezCurve) ->
		_bezCurve = {
			Point bezCurve[1].x, bezCurve[1].y
			Point bezCurve[2].x, bezCurve[2].y
			Point bezCurve[3].x, bezCurve[3].y
			Point bezCurve[4].x, bezCurve[4].y
		}
		uPrime = {}
		for i = first, last
			uPrime[i - first + 1] = newtonRaphsonRootFind(_bezCurve, d[i], u[i - first + 1])
		return uPrime

	BM = (u, tp) ->
		switch tp
			when 1 then 3 * u * ((1 - u) ^ 2)
			when 2 then 3 * (u ^ 2) * (1 - u)
			when 3 then u ^ 3
			else        (1 - u) ^ 3

	generateBezier = (d, first, last, uPrime, tHat1, tHat2) ->
		C, A, bezCurve = {{0, 0}, {0, 0}, {0, 0}}, {}, {}
		nPts = last - first + 1

		for i = 1, nPts
			v1 = Point tHat1.x, tHat1.y
			v2 = Point tHat2.x, tHat2.y
			v1 = v1\vecScale BM(uPrime[i], 1)
			v2 = v2\vecScale BM(uPrime[i], 2)
			A[i] = {v1, v2}

		for i = 1, nPts
			C[1][1] += A[i][1]\dot A[i][1]
			C[1][2] += A[i][1]\dot A[i][2]

			C[2][1] = C[1][2]
			C[2][2] += A[i][2]\dot A[i][2]

			b0 = d[first]\multiply(BM(uPrime[i]), BM(uPrime[i]))
			b1 = d[first]\multiply(BM(uPrime[i], 1))
			b2 = d[last]\multiply(BM(uPrime[i], 2))
			b3 = d[last]\multiply(BM(uPrime[i], 3))

			tm0 = b2\add b3
			tm1 = b1\add tm0
			tm2 = b0\add tm1
			tmp = d[first + i - 1]\subtract tm2

			C[3][1] += A[i][1]\dot tmp
			C[3][2] += A[i][2]\dot tmp

		det_C0_C1 = C[1][1] * C[2][2] - C[2][1] * C[1][2]
		det_C0_X = C[1][1] * C[3][2] - C[2][1] * C[3][1]
		det_X_C1 = C[3][1] * C[2][2] - C[3][2] * C[1][2]

		alpha_l = det_C0_C1 == 0 and 0 or det_X_C1 / det_C0_C1
		alpha_r = det_C0_C1 == 0 and 0 or det_C0_X / det_C0_C1

		segLength = d[last]\distance d[first]
		epsilon = 1e-6 * segLength

		if alpha_l < epsilon or alpha_r < epsilon
			dist = segLength / 3
			bezCurve[1] = d[first]
			bezCurve[4] = d[last]
			bezCurve[2] = bezCurve[1]\add tHat1\vecScale dist
			bezCurve[3] = bezCurve[4]\add tHat2\vecScale dist
			bezCurve[1].id, bezCurve[2].id, bezCurve[3].id, bezCurve[4].id = "l", "b", "b", "b"
			return bezCurve

		bezCurve[1] = d[first]
		bezCurve[4] = d[last]
		bezCurve[2] = bezCurve[1]\add tHat1\vecScale alpha_l
		bezCurve[3] = bezCurve[4]\add tHat2\vecScale alpha_r
		bezCurve[1].id, bezCurve[2].id, bezCurve[3].id, bezCurve[4].id = "l", "b", "b", "b"
		return bezCurve
	
	addtoB = (b, bez) ->
		n = #b
		lastP = b[n]
		for i = 1, #bez
			if lastP.x == bez[i].x and lastP.y == bez[i].y
				continue
			table.insert(b, bez[i])
		
	fitCubic = (b, d, first, last, tHat1, tHat2, _error) ->
		u, uPrime, maxIterations, tHatCenter = {}, {}, 4, Point!
		iterationError = _error ^ 2
		nPts = last - first + 1
	
		if nPts == 2
			dist = d[last]\distance(d[first]) / 3

			bezCurve = {}
			bezCurve[1] = d[first]
			bezCurve[4] = d[last]
			tHat1 = tHat1\vecScale dist
			tHat2 = tHat2\vecScale dist
			bezCurve[2] = bezCurve[1]\add tHat1
			bezCurve[3] = bezCurve[4]\add tHat2
			bezCurve[1].id, bezCurve[2].id, bezCurve[3].id, bezCurve[4].id = "l", "b", "b", "b"
			addtoB(b, bezCurve)
			return

		u = chordLengthParameterize(d, first, last)
		bezCurve = generateBezier(d, first, last, u, tHat1, tHat2)

		resultMaxError = computeMaxError(d, first, last, bezCurve, u, nil)
		maxError = resultMaxError.maxError
		splitPoint = resultMaxError.splitPoint

		if maxError < _error
			addtoB(b, bezCurve)
			return

		if maxError < iterationError
			for i = 1, maxIterations
				uPrime = reparameterize(d, first, last, u, bezCurve)
				bezCurve = generateBezier(d, first, last, uPrime, tHat1, tHat2)
				resultMaxError = computeMaxError(d, first, last, bezCurve, uPrime, splitPoint)
				maxError = resultMaxError.maxError
				splitPoint = resultMaxError.splitPoint
				if maxError < _error
					addtoB(b, bezCurve)
					return
				u = uPrime

		tHatCenter = computeCenterTangent(d, splitPoint)
		fitCubic(b, d, first, splitPoint, tHat1, tHatCenter, _error)
		tHatCenter = tHatCenter\negate!
		fitCubic(b, d, splitPoint, last, tHatCenter, tHat2, _error)

	fitCurve = (b, d, nPts, _error = 1) ->
		tHat1 = computeLeftTangent(d, 1)
		tHat2 = computeRightTangent(d, nPts)
		fitCubic(b, d, 1, nPts, tHat1, tHat2, _error)
	
	getAngle = (p1, p2, p3) ->
		x1, y1 = p1.x, p1.y
		x2, y2 = p2.x, p2.y
		x3, y3 = p3.x, p3.y
		angle = math.atan2(y3 - y2, x3 - x2) - math.atan2(y1 - y2, x1 - x2)
		return math.deg(angle)

	elaborateSelected = (selected, final, tolerance) ->

		if #selected <= 4
			for i = 1, #selected
				table.insert final, selected[i]
			return
		
		b = {selected[1]}
			
		fitCurve(b, selected, #selected, tolerance)
		
		for i = 1, #b
			table.insert final, b[i]

	isInRange = (cs, ls) ->
		if not (cs > ls * 2) and not (cs < ls / 2)
			return true
		return false

	simplify = (points, tolerance, angleThreshold) ->
		at1, at2 = angleThreshold, 360 - angleThreshold
		final = {}

		-- first and last points are duplicated for checks but ignored
		table.insert points, 1, points[#points]
		table.insert points, points[2]

		lastSegmentLength = 0
		selected = {points[1]}
		-- the current work around to remove duplicated points
		-- close the contour by duplicating the first point
		-- in this foor loop is possible to change to #points - 2
		-- if you want to have an open contour
		for i = 2, #points - 1
			
			-- first point must not be a control point
			if i == 2
				lastSegmentLength = points[2]\distance(points[3])
				points[i].id = "l"
				table.insert final, points[i]
				selected = {points[i]}
				continue
			table.insert selected, points[i]
			
			currSegmentLength = points[i]\distance(points[i + 1])
			if not isInRange(currSegmentLength, lastSegmentLength)
				elaborateSelected(selected, final, tolerance)
				selected = {}
				lastSegmentLength = currSegmentLength
				continue
			
			ang = math.abs getAngle(points[i-1], points[i], points[i+1])
			if ang < at1 or ang > at2
				elaborateSelected(selected, final, tolerance)
				selected = {}
				lastSegmentLength = currSegmentLength
				continue
			
			lastSegmentLength = currSegmentLength

		elaborateSelected(selected, final, tolerance)
		return final

	for i = 1, #points
		if recreateBezier
			points[i] = simplifyRadialDist(points[i], 0.5) -- from 0.5 to 1
			points[i] = simplify(points[i], tolerance, angleThreshold)
		else
			sqTolerance = tolerance * tolerance
			if not highestQuality
				points[i] = simplifyRadialDist(points[i], sqTolerance)

			points[i] = simplifyDouglasPeucker(points[i], sqTolerance)

	return points

{:Path}