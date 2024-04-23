-- code taken from the Yutils lib
-- https://github.com/TypesettingTools/Yutils/blob/91a4ac771b08ecffdcc8c084592286961d99c5f2/src/Yutils.lua#L587

class UTF8

    new: (@s) =>

    charrange: (c, i) ->
        byte = c\byte i
        return not byte and 0 or byte < 192 and 1 or byte < 224 and 2 or byte < 240 and 3 or byte < 248 and 4 or byte < 252 and 5 or 6

    charcodepoint: (c) ->
        byte1, byte2, byte3, byte4 = c\byte 1, -1
        if not byte1
            return nil
        elseif byte1 < 128
            return byte1
        elseif byte1 < 224 and byte2
            return (byte1 - 192) * 64 + (byte2 - 128)
        elseif byte1 < 240 and byte2 and byte3
            return (byte1 - 224) * 4096 + (byte2 - 128) * 64 + (byte3 - 128)
        elseif byte1 < 248 and byte2 and byte3 and byte4
            return (byte1 - 240) * 262144 + (byte2 - 128) * 4096 + (byte3 - 128) * 64 + (byte4 - 128)
        else
            return nil

    chars: =>
        {:s} = @
        ci, sp, len = 0, 1, #s
        ->
            if sp <= len
                cp = sp
                sp += UTF8.charrange s, sp
                if sp - 1 <= len
                    ci += 1
                    return ci, s\sub cp, sp - 1

    len: =>
        n = 0
        for ci in @chars!
            n += 1
        return n

{:UTF8}