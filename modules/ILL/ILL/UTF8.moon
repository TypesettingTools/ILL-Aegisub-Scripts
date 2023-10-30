-- code taken from the Yutils lib
-- https://github.com/TypesettingTools/Yutils/blob/91a4ac771b08ecffdcc8c084592286961d99c5f2/src/Yutils.lua#L587

class UTF8

    new: (@s) =>

    charrange: (s, i) ->
        byte = s\byte i
        return not byte and 0 or byte < 192 and 1 or byte < 224 and 2 or byte < 240 and 3 or byte < 248 and 4 or byte < 252 and 5 or 6

    chars: =>
        {:s} = @
        charI, sPos, sLen = 0, 1, #s
        ->
            if sPos <= sLen
                currPos = sPos
                sPos += UTF8.charrange s, sPos
                if sPos - 1 <= sLen
                    charI += 1
                    return charI, s\sub currPos, sPos - 1

    len: (s) ->
        n = 0
        for ci in @chars!
            n += 1
        return n

{:UTF8}