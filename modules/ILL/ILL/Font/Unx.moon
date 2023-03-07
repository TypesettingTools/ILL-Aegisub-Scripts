ffi = require "ffi"

-- Extension must be appended because of dot already in filename
has_pangocairo, pangocairo = pcall ffi.load, "pangocairo-1.0.so"
import C, cdef, gc, new from ffi

-- Set C definitions for pangocairo
cdef [[
	typedef enum{
		CAIRO_FORMAT_INVALID   = -1,
		CAIRO_FORMAT_ARGB32    = 0,
		CAIRO_FORMAT_RGB24     = 1,
		CAIRO_FORMAT_A8        = 2,
		CAIRO_FORMAT_A1        = 3,
		CAIRO_FORMAT_RGB16_565 = 4,
		CAIRO_FORMAT_RGB30     = 5
	}cairo_format_t;
	typedef void cairo_surface_t;
	typedef void cairo_t;
	typedef void PangoLayout;
	typedef void* gpointer;
	static const int PANGO_SCALE = 1024;
	typedef void PangoFontDescription;
	typedef enum{
		PANGO_WEIGHT_THIN	= 100,
		PANGO_WEIGHT_ULTRALIGHT = 200,
		PANGO_WEIGHT_LIGHT = 300,
		PANGO_WEIGHT_NORMAL = 400,
		PANGO_WEIGHT_MEDIUM = 500,
		PANGO_WEIGHT_SEMIBOLD = 600,
		PANGO_WEIGHT_BOLD = 700,
		PANGO_WEIGHT_ULTRABOLD = 800,
		PANGO_WEIGHT_HEAVY = 900,
		PANGO_WEIGHT_ULTRAHEAVY = 1000
	}PangoWeight;
	typedef enum{
		PANGO_STYLE_NORMAL,
		PANGO_STYLE_OBLIQUE,
		PANGO_STYLE_ITALIC
	}PangoStyle;
	typedef void PangoAttrList;
	typedef void PangoAttribute;
	typedef enum{
		PANGO_UNDERLINE_NONE,
		PANGO_UNDERLINE_SINGLE,
		PANGO_UNDERLINE_DOUBLE,
		PANGO_UNDERLINE_LOW,
		PANGO_UNDERLINE_ERROR
	}PangoUnderline;
	typedef int gint;
	typedef gint gboolean;
	typedef void PangoContext;
	typedef unsigned int guint;
	typedef struct{
		guint ref_count;
		int ascent;
		int descent;
		int approximate_char_width;
		int approximate_digit_width;
		int underline_position;
		int underline_thickness;
		int strikethrough_position;
		int strikethrough_thickness;
	}PangoFontMetrics;
	typedef void PangoLanguage;
	typedef struct{
		int x;
		int y;
		int width;
		int height;
	}PangoRectangle;
	typedef enum{
		CAIRO_STATUS_SUCCESS = 0
	}cairo_status_t;
	typedef enum{
		CAIRO_PATH_MOVE_TO,
		CAIRO_PATH_LINE_TO,
		CAIRO_PATH_CURVE_TO,
		CAIRO_PATH_CLOSE_PATH
	}cairo_path_data_type_t;
	typedef union{
		struct{
			cairo_path_data_type_t type;
			int length;
		}header;
		struct{
			double x, y;
		}point;
	}cairo_path_data_t;
	typedef struct{
		cairo_status_t status;
		cairo_path_data_t* data;
		int num_data;
	}cairo_path_t;
	cairo_surface_t* cairo_image_surface_create(cairo_format_t, int, int);
	void cairo_surface_destroy(cairo_surface_t*);
	cairo_t* cairo_create(cairo_surface_t*);
	void cairo_destroy(cairo_t*);
	PangoLayout* pango_cairo_create_layout(cairo_t*);
	void g_object_unref(gpointer);
	PangoFontDescription* pango_font_description_new(void);
	void pango_font_description_free(PangoFontDescription*);
	void pango_font_description_set_family(PangoFontDescription*, const char*);
	void pango_font_description_set_weight(PangoFontDescription*, PangoWeight);
	void pango_font_description_set_style(PangoFontDescription*, PangoStyle);
	void pango_font_description_set_absolute_size(PangoFontDescription*, double);
	void pango_layout_set_font_description(PangoLayout*, PangoFontDescription*);
	PangoAttrList* pango_attr_list_new(void);
	void pango_attr_list_unref(PangoAttrList*);
	void pango_attr_list_insert(PangoAttrList*, PangoAttribute*);
	PangoAttribute* pango_attr_underline_new(PangoUnderline);
	PangoAttribute* pango_attr_strikethrough_new(gboolean);
	PangoAttribute* pango_attr_letter_spacing_new(int);
	void pango_layout_set_attributes(PangoLayout*, PangoAttrList*);
	PangoContext* pango_layout_get_context(PangoLayout*);
	const PangoFontDescription* pango_layout_get_font_description(PangoLayout*);
	PangoFontMetrics* pango_context_get_metrics(PangoContext*, const PangoFontDescription*, PangoLanguage*);
	void pango_font_metrics_unref(PangoFontMetrics*);
	int pango_font_metrics_get_ascent(PangoFontMetrics*);
	int pango_font_metrics_get_descent(PangoFontMetrics*);
	int pango_layout_get_spacing(PangoLayout*);
	void pango_layout_set_text(PangoLayout*, const char*, int);
	void pango_layout_get_pixel_extents(PangoLayout*, PangoRectangle*, PangoRectangle*);
	void cairo_save(cairo_t*);
	void cairo_restore(cairo_t*);
	void cairo_scale(cairo_t*, double, double);
	void pango_cairo_layout_path(cairo_t*, PangoLayout*);
	void cairo_new_path(cairo_t*);
	cairo_path_t* cairo_copy_path(cairo_t*);
	void cairo_path_destroy(cairo_path_t*);
]]

import Math from require "ILL.ILL.Math"
import Init from require "ILL.ILL.Font.Init"

class PangoCairo extends Init

	LIBASS_FONTHACK: true

	init: =>
		-- Check whether or not the pangocairo library was loaded
		unless has_pangocairo
			error "pangocairo library couldn't be loaded", 2

		-- Create surface, context & layout
		surface = pangocairo.cairo_image_surface_create C.CAIRO_FORMAT_A8, 1, 1
		@context = pangocairo.cairo_create surface

		local layout
		layout = gc pangocairo.pango_cairo_create_layout(@context), ->
			pangocairo.g_object_unref layout
			pangocairo.cairo_destroy @context
			pangocairo.cairo_surface_destroy surface
			return

		-- Set font to layout
		font_desc = gc pangocairo.pango_font_description_new!, pangocairo.pango_font_description_free
		pangocairo.pango_font_description_set_family font_desc, @family
		pangocairo.pango_font_description_set_weight font_desc, @bold and C.PANGO_WEIGHT_BOLD or C.PANGO_WEIGHT_NORMAL
		pangocairo.pango_font_description_set_style font_desc, @italic and C.PANGO_STYLE_ITALIC or C.PANGO_STYLE_NORMAL
		pangocairo.pango_font_description_set_absolute_size font_desc, @size * C.PANGO_SCALE * FONT_UPSCALE
		pangocairo.pango_layout_set_font_description layout, font_desc

		attr = gc pangocairo.pango_attr_list_new!, pangocairo.pango_attr_list_unref
		pangocairo.pango_attr_list_insert attr, pangocairo.pango_attr_underline_new @underline and C.PANGO_UNDERLINE_SINGLE or C.PANGO_UNDERLINE_NONE
		pangocairo.pango_attr_list_insert attr, pangocairo.pango_attr_strikethrough_new @strikeout
		pangocairo.pango_attr_list_insert attr, pangocairo.pango_attr_letter_spacing_new @hspace * C.PANGO_SCALE * FONT_UPSCALE
		pangocairo.pango_layout_set_attributes layout, attr

		-- Scale factor for resulting font data
		if PangoCairo.LIBASS_FONTHACK 
			metrics = gc pangocairo.pango_context_get_metrics(pangocairo.pango_layout_get_context(layout), pangocairo.pango_layout_get_font_description(layout), nil), pangocairo.pango_font_metrics_unref
			@fonthack_scale = @size / ((pangocairo.pango_font_metrics_get_ascent(metrics) + pangocairo.pango_font_metrics_get_descent(metrics)) / C.PANGO_SCALE * FONT_DOWNSCALE)
		else
			@fonthack_scale = 1

		@layout = layout
		@offset_x = @xscale * @fonthack_scale
		@offset_y = @yscale * @fonthack_scale

	-- Get font metrics
	getMetrics: =>
		metrics = gc pangocairo.pango_context_get_metrics(pangocairo.pango_layout_get_context(@layout), pangocairo.pango_layout_get_font_description(@layout), nil), pangocairo.pango_font_metrics_unref
		ascent = pangocairo.pango_font_metrics_get_ascent(metrics) / C.PANGO_SCALE * FONT_DOWNSCALE
		descent = pangocairo.pango_font_metrics_get_descent(metrics) / C.PANGO_SCALE * FONT_DOWNSCALE
		{
			height: (ascent + descent) * @offset_y
			ascent: ascent * @offset_y
			descent: descent * @offset_y
			internal_leading: 0
			external_leading: pangocairo.pango_layout_get_spacing(@layout) / C.PANGO_SCALE * FONT_DOWNSCALE * @offset_y
		}

	-- Get text extents
	getTextExtents: (text) =>
		-- Set text to layout
		pangocairo.pango_layout_set_text @layout, text, -1
		-- Get text extents with this font
		rect = new "PangoRectangle[1]"
		pangocairo.pango_layout_get_pixel_extents @layout, nil, rect
		{:width, :height} = rect[0]
		{
			width: width * FONT_DOWNSCALE * @offset_x
			height: height * FONT_DOWNSCALE * @offset_y
		}

	-- Converts text to ASS shape
	getTextToShape: (text, precision = 3) =>
		-- Initialize shape as table
		shape, insert, round = {}, table.insert, Math.round

		-- Set text path to layout
		pangocairo.cairo_save @context
		pangocairo.cairo_scale @context, FONT_DOWNSCALE * @offset_x, FONT_DOWNSCALE * @offset_y
		pangocairo.pango_layout_set_text @layout, text, -1
		pangocairo.pango_cairo_layout_path @context, @layout
		pangocairo.cairo_restore @context

		-- Convert path to shape
		path = gc(pangocairo.cairo_copy_path(@context), pangocairo.cairo_path_destroy)[0]
		if path.status == C.CAIRO_STATUS_SUCCESS
			i, curr_type, last_type = 0
			while i < path.num_data
				curr_type = path.data[i].header.type
				switch curr_type
					when C.CAIRO_PATH_MOVE_TO
						if curr_type != last_type
							insert shape, "m"
						{:x, :y} = path.data[i + 1].point
						insert shape, round x, precision
						insert shape, round y, precision
					when C.CAIRO_PATH_LINE_TO
						if curr_type != last_type
							insert shape, "l"
						{:x, :y} = path.data[i + 1].point
						insert shape, round x, precision
						insert shape, round y, precision
					when C.CAIRO_PATH_CURVE_TO
						if curr_type != last_type
							insert shape, "b"
						{:x, :y} = path.data[i + 1].point
						insert shape, round x, precision
						insert shape, round y, precision
						{:x, :y} = path.data[i + 2].point
						insert shape, round x, precision
						insert shape, round y, precision
						{:x, :y} = path.data[i + 3].point
						insert shape, round x, precision
						insert shape, round y, precision
				last_type = curr_type
				i += path.data[i].header.length
		pangocairo.cairo_new_path @context
		return table.concat shape, " "

{:PangoCairo}