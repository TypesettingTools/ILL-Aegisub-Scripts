ffi = require "ffi"
import C, cdef, gc, new from ffi

cdef [[
	enum{CP_UTF8 = 65001};
	enum{MM_TEXT = 1};
	enum{TRANSPARENT = 1};
	enum{
		FW_NORMAL = 400,
		FW_BOLD = 700
	};
	enum{DEFAULT_CHARSET = 1};
	enum{OUT_TT_PRECIS = 4};
	enum{CLIP_DEFAULT_PRECIS = 0};
	enum{ANTIALIASED_QUALITY = 4};
	enum{DEFAULT_PITCH = 0x0};
	enum{FF_DONTCARE = 0x0};
	enum{
		PT_MOVETO = 0x6,
		PT_LINETO = 0x2,
		PT_BEZIERTO = 0x4,
		PT_CLOSEFIGURE = 0x1
	};
	typedef unsigned int UINT;
	typedef unsigned long DWORD;
	typedef DWORD* LPDWORD;
	typedef const char* LPCSTR;
	typedef const wchar_t* LPCWSTR;
	typedef wchar_t* LPWSTR;
	typedef char* LPSTR;
	typedef void* HANDLE;
	typedef HANDLE HDC;
	typedef int BOOL;
	typedef BOOL* LPBOOL;
	typedef unsigned int size_t;
	typedef HANDLE HFONT;
	typedef HANDLE HGDIOBJ;
	typedef long LONG;
	typedef wchar_t WCHAR;
	typedef unsigned char BYTE;
	typedef BYTE* LPBYTE;
	typedef int INT;
	typedef long LPARAM;
	static const int LF_FACESIZE = 32;
	static const int LF_FULLFACESIZE = 64;
	typedef struct{
		LONG tmHeight;
		LONG tmAscent;
		LONG tmDescent;
		LONG tmInternalLeading;
		LONG tmExternalLeading;
		LONG tmAveCharWidth;
		LONG tmMaxCharWidth;
		LONG tmWeight;
		LONG tmOverhang;
		LONG tmDigitizedAspectX;
		LONG tmDigitizedAspectY;
		WCHAR tmFirstChar;
		WCHAR tmLastChar;
		WCHAR tmDefaultChar;
		WCHAR tmBreakChar;
		BYTE tmItalic;
		BYTE tmUnderlined;
		BYTE tmStruckOut;
		BYTE tmPitchAndFamily;
		BYTE tmCharSet;
	}TEXTMETRICW, *LPTEXTMETRICW;
	typedef struct{
		LONG cx;
		LONG cy;
	}SIZE, *LPSIZE;
	typedef struct{
		LONG left;
		LONG top;
		LONG right;
		LONG bottom;
	}RECT;
	typedef const RECT* LPCRECT;
	typedef struct{
		LONG x;
		LONG y;
	}POINT, *LPPOINT;
	typedef struct{
	LONG  lfHeight;
	LONG  lfWidth;
	LONG  lfEscapement;
	LONG  lfOrientation;
	LONG  lfWeight;
	BYTE  lfItalic;
	BYTE  lfUnderline;
	BYTE  lfStrikeOut;
	BYTE  lfCharSet;
	BYTE  lfOutPrecision;
	BYTE  lfClipPrecision;
	BYTE  lfQuality;
	BYTE  lfPitchAndFamily;
	WCHAR lfFaceName[LF_FACESIZE];
	}LOGFONTW, *LPLOGFONTW;
	typedef struct{
	LOGFONTW elfLogFont;
	WCHAR   elfFullName[LF_FULLFACESIZE];
	WCHAR   elfStyle[LF_FACESIZE];
	WCHAR   elfScript[LF_FACESIZE];
	}ENUMLOGFONTEXW, *LPENUMLOGFONTEXW;
	enum{
		FONTTYPE_RASTER = 1,
		FONTTYPE_DEVICE = 2,
		FONTTYPE_TRUETYPE = 4
	};
	typedef int (__stdcall *FONTENUMPROC)(const ENUMLOGFONTEXW*, const void*, DWORD, LPARAM);
	enum{ERROR_SUCCESS = 0};
	typedef HANDLE HKEY;
	typedef HKEY* PHKEY;
	enum{HKEY_LOCAL_MACHINE = 0x80000002};
	typedef enum{KEY_READ = 0x20019}REGSAM;

	int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
	int WideCharToMultiByte(UINT, DWORD, LPCWSTR, int, LPSTR, int, LPCSTR, LPBOOL);
	HDC CreateCompatibleDC(HDC);
	BOOL DeleteDC(HDC);
	int SetMapMode(HDC, int);
	int SetBkMode(HDC, int);
	size_t wcslen(const wchar_t*);
	HFONT CreateFontW(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
	HGDIOBJ SelectObject(HDC, HGDIOBJ);
	BOOL DeleteObject(HGDIOBJ);
	BOOL GetTextMetricsW(HDC, LPTEXTMETRICW);
	BOOL GetTextExtentPoint32W(HDC, LPCWSTR, int, LPSIZE);
	BOOL BeginPath(HDC);
	BOOL ExtTextOutW(HDC, int, int, UINT, LPCRECT, LPCWSTR, UINT, const INT*);
	BOOL EndPath(HDC);
	int GetPath(HDC, LPPOINT, LPBYTE, int);
	BOOL AbortPath(HDC);
	int EnumFontFamiliesExW(HDC, LPLOGFONTW, FONTENUMPROC, LPARAM, DWORD);
	LONG RegOpenKeyExA(HKEY, LPCSTR, DWORD, REGSAM, PHKEY);
	LONG RegCloseKey(HKEY);
	LONG RegEnumValueW(HKEY, DWORD, LPWSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD);
]]

import Init from require "ILL.ILL.Font.Init"
import Math from require "ILL.ILL.Math"

utf8_to_utf16 = (s) ->
	-- Get resulting utf16 characters number (+ null-termination)
	wlen = C.MultiByteToWideChar C.CP_UTF8, 0x0, s, -1, nil, 0
	-- Allocate array for utf16 characters storage
	ws = new "wchar_t[?]", wlen
	-- Convert utf8 string to utf16 characters
	C.MultiByteToWideChar C.CP_UTF8, 0x0, s, -1, ws, wlen
	-- Return utf16 C string
	return ws

class WindowsGDI extends Init

	init: =>
		-- Create device context and set light resources deleter
		local resources_deleter
		@dc = gc C.CreateCompatibleDC(nil), ->
			resources_deleter!
			return

		-- Set context coordinates mapping mode
		C.SetMapMode @dc, C.MM_TEXT

		-- Set context backgrounds to transparent
		C.SetBkMode @dc, C.TRANSPARENT

		-- Convert family from utf8 to utf16
		family = utf8_to_utf16 @family
		if tonumber(C.wcslen family) > 31
			error "family name to long", 2

		-- Create font handle
		font = C.CreateFontW @size * FONT_UPSCALE, 0, 0, 0, @bold and C.FW_BOLD or C.FW_NORMAL, @italic and 1 or 0, @underline and 1 or 0, @strikeout and 1 or 0, C.DEFAULT_CHARSET, C.OUT_TT_PRECIS, C.CLIP_DEFAULT_PRECIS, C.ANTIALIASED_QUALITY, C.DEFAULT_PITCH + C.FF_DONTCARE, family

		-- Set new font to device context
		old_font = C.SelectObject @dc, font

		-- Define light resources deleter
		resources_deleter = ->
			C.SelectObject @dc, old_font
			C.DeleteObject font
			C.DeleteDC @dc
			return

		@dx = FONT_DOWNSCALE * @xscale
		@dy = FONT_DOWNSCALE * @yscale

	-- Get font metrics
	getMetrics: =>
		-- Get font metrics from device context
		metrics = new "TEXTMETRICW[1]"
		C.GetTextMetricsW @dc, metrics
		{:tmHeight, :tmAscent, :tmDescent, :tmInternalLeading, :tmExternalLeading} = metrics[0]
		{:dy} = @
		return {
			height: tmHeight * dy
			ascent: tmAscent * dy
			descent: tmDescent * dy
			internal_leading: tmInternalLeading * dy
			external_leading: tmExternalLeading * dy
		}

	-- Get text extents
	getTextExtents: (text) =>
		-- Get utf16 text
		tx = utf8_to_utf16 text
		text_len = tonumber C.wcslen tx

		-- Get text extents with this font
		sz = new "SIZE[1]"
		C.GetTextExtentPoint32W @dc, tx, text_len, sz
		{:cx, :cy} = sz[0]
		{
			width: (cx * FONT_DOWNSCALE + @hspace * text_len) * @xscale
			height: cy * @dy
		}

	-- Converts text to ASS shape
	getTextToShape: (text, precision = 3) =>
		-- Initialize shape as table
		shape, insert, round = {}, table.insert, Math.round

		-- Get utf16 text
		tx = utf8_to_utf16 text
		text_len = tonumber C.wcslen tx

		-- Add path to device context
		if text_len > 8192
			error "text too long", 2

		local char_widths
		if @hspace != 0
			char_widths = new "INT[?]", text_len
			size = new "SIZE[1]"
			space = @hspace * FONT_UPSCALE
			for i = 0, text_len - 1
				C.GetTextExtentPoint32W @dc, tx + i, 1, size
				char_widths[i] = size[0].cx + space

		-- Inits path
		C.BeginPath @dc
		C.ExtTextOutW @dc, 0, 0, 0x0, nil, tx, text_len, char_widths
		C.EndPath @dc

		-- Get path data
		points_n = C.GetPath @dc, nil, nil, 0

		if points_n > 0
			{:dx, :dy} = @
			points = new "POINT[?]", points_n
			types = new "BYTE[?]", points_n
			C.GetPath @dc, points, types, points_n
			-- Convert points to shape
			i, last_type, curr_type, curr_point = 0, nil, nil, nil
			while i < points_n
				curr_type, curr_point = types[i], points[i]
				if curr_type == C.PT_MOVETO
					if last_type != C.PT_MOVETO
						insert shape, "m"
						last_type = curr_type
					{:x, :y} = curr_point
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					i += 1
				elseif curr_type == C.PT_LINETO or curr_type == C.PT_LINETO + C.PT_CLOSEFIGURE
					if last_type != C.PT_LINETO
						insert shape, "l"
						last_type = curr_type
					{:x, :y} = curr_point
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					i += 1
				elseif curr_type == C.PT_BEZIERTO or curr_type == C.PT_BEZIERTO + C.PT_CLOSEFIGURE
					if last_type != C.PT_BEZIERTO
						insert shape, "b"
						last_type = curr_type
					{:x, :y} = curr_point
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					{:x, :y} = points[i + 1]
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					{:x, :y} = points[i + 2]
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					i += 3
				else -- invalid type (should never happen, but let us be safe)
					i += 1
			-- Clear device context path
			C.AbortPath @dc
		-- Return shape as string
		return table.concat shape, " "

{:WindowsGDI}