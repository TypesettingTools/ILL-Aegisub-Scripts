import Point from require "ILL.ILL.Ass.Shape.Point"
import Aegi from require "ILL.ILL.Aegi"

{:bor} = require "bit"
{:insert} = table

class Curve

	-- Create a new Curve object
	new: (@a = Point!, @b = Point!, @c = Point!, @d = Point!) =>

	-- Get the X position of a point running through the bezier for the given time.
	getXatTime: (t) => (1 - t) ^ 3 * @a.x + 3 * t * (1 - t) ^ 2 * @b.x + 3 * t ^ 2 * (1 - t) * @c.x + t ^ 3 * @d.x

	-- Get the Y position of a point running through the bezier for the given time.
	getYatTime: (t) => (1 - t) ^ 3 * @a.y + 3 * t * (1 - t) ^ 2 * @b.y + 3 * t ^ 2 * (1 - t) * @c.y + t ^ 3 * @d.y

	-- Get the X and Y position of a point running through the bezier for the given time.
	getPTatTime: (t) =>
		x = @getXatTime t
		y = @getYatTime t
		return Point x, y

	-- flattens the bezier segment
	flatten: (len = @getLength!, reduce = 1) =>
		len = math.floor len / reduce + 0.5
		lengths = @getArcLenghts len
		points = {Point @a.x, @a.y}
		for i = 1, len - 1
			insert points, @getPTatTime Curve.uniformTime lengths, len, i / len
		insert points, Point @d.x, @d.y
		return points

	-- checks if the point is on the bezier segment
	-- if yes returns the time(t)
	-- if not returns false
	pointIsInCurve: (p, tolerance = 2, precision = 100) =>
		{:a, :d} = @
		return 0 if a.x == p.x and a.y == p.y
		return 1 if d.x == p.x and d.y == p.y
		length = @getLength!
		lengths = @getArcLenghts precision
		for t = 0, 1, 1 / precision
			u = Curve.uniformTime lengths, length, t
			if @getPTatTime(u)\distance(p) <= tolerance
				return t
		return false

	-- splits the bezier segment in two
	split: (t) =>
		{:a, :b, :c, :d} = @
		v1 = a\lerp b, t
		v2 = b\lerp c, t
		v3 = c\lerp d, t
		v4 = v1\lerp v2, t
		v5 = v2\lerp v3, t
		v6 = v4\lerp v5, t
		return {
			Curve a, v1, v4, v6
			Curve v6, v5, v3, d
		}

	-- gets the cubic coefficient of the bezier segment
	getCoefficient: =>
		{:a, :b, :c, :d} = @
		return {
			Point d.x - a.x + 3 * (b.x - c.x), d.y - a.y + 3 * (b.y - c.y)
			Point 3 * a.x - 6 * b.x + 3 * c.x, 3 * a.y - 6 * b.y + 3 * c.y
			Point 3 * (b.x - a.x), 3 * (b.y - a.y)
			Point a.x, a.y
		}

	-- gets the cubic derivative of the bezier segment
	getDerivative: (t, cf) =>
		{a, b, c} = cf
		x = c.x + t * (2 * b.x + 3 * a.x * t)
		y = c.y + t * (2 * b.y + 3 * a.y * t)
		return Point x, y

	-- gets the real length of the segment through time
	getLength: (t = 1) =>

		abscissas = {
			-0.0640568928626056299791002857091370970011, 0.0640568928626056299791002857091370970011
			-0.1911188674736163106704367464772076345980, 0.1911188674736163106704367464772076345980
			-0.3150426796961633968408023065421730279922, 0.3150426796961633968408023065421730279922
			-0.4337935076260451272567308933503227308393, 0.4337935076260451272567308933503227308393
			-0.5454214713888395626995020393223967403173, 0.5454214713888395626995020393223967403173
			-0.6480936519369755455244330732966773211956, 0.6480936519369755455244330732966773211956
			-0.7401241915785543579175964623573236167431, 0.7401241915785543579175964623573236167431
			-0.8200019859739029470802051946520805358887, 0.8200019859739029470802051946520805358887
			-0.8864155270044010714869386902137193828821, 0.8864155270044010714869386902137193828821
			-0.9382745520027327978951348086411599069834, 0.9382745520027327978951348086411599069834
			-0.9747285559713094738043537290650419890881, 0.9747285559713094738043537290650419890881
			-0.9951872199970213106468008845695294439793, 0.9951872199970213106468008845695294439793
		}

		weights = {
			0.1279381953467521593204025975865079089999, 0.1279381953467521593204025975865079089999
			0.1258374563468283025002847352880053222179, 0.1258374563468283025002847352880053222179
			0.1216704729278033914052770114722079597414, 0.1216704729278033914052770114722079597414
			0.1155056680537255991980671865348995197564, 0.1155056680537255991980671865348995197564
			0.1074442701159656343712356374453520402312, 0.1074442701159656343712356374453520402312
			0.0976186521041138843823858906034729443491, 0.0976186521041138843823858906034729443491
			0.0861901615319532743431096832864568568766, 0.0861901615319532743431096832864568568766
			0.0733464814110802998392557583429152145982, 0.0733464814110802998392557583429152145982
			0.0592985849154367833380163688161701429635, 0.0592985849154367833380163688161701429635
			0.0442774388174198077483545432642131345347, 0.0442774388174198077483545432642131345347
			0.0285313886289336633705904233693217975087, 0.0285313886289336633705904233693217975087
			0.0123412297999872001830201639904771582223, 0.0123412297999872001830201639904771582223
		}

		len, cf, z = 0, @getCoefficient!, t / 2
		for i = 1, #abscissas
			drv = @getDerivative z * abscissas[i] + z, cf
			len += weights[i] * drv\hypot!

		return len * z

	-- Return a table containing the lenght of all the arc
	-- The "precision" variable can be considered the distance of the points from each other in pixel 
	getArcLenghts: (precision = 100) =>
		z = 1 / precision
		lengths, clen = {0}, 0

		cx, cy = @getXatTime(0), @getYatTime(0)
		for i = 1, precision
			px, py = @getXatTime(i * z), @getYatTime(i * z)
			dx, dy = cx - px, cy - py
			cx, cy = px, py
			clen += math.sqrt dx * dx + dy * dy
			insert lengths, clen

		return lengths

	uniformTime: (lengths, len, u) ->
		targetLength = u * lengths[#lengths]
		low, high, index = 0, len, 0

		while low < high
			index = low + bor (high - low) / 2, 0
			if lengths[index + 1] < targetLength
				low = index + 1
			else
				high = index

		if lengths[index + 1] > targetLength
			index -= 1

		lengthBefore = lengths[index + 1]
		if lengthBefore == targetLength
			return index / len

		return (index + (targetLength - lengthBefore) / (lengths[index + 2] - lengthBefore)) / len

{:Curve}