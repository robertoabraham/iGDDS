/* collecting all the defines in one place */

#define PLOTDEFS

#define ALLOCSIZE 2048		/* used in readData */

#define N_LINE_STYLES 6		/* number of line styles (including none) */
#define N_SYMBOL_STYLES 8	/* number of symbol styles (including none) */

/*
#ifndef MIN
#define MIN(x,y) ((x)<(y)? (x) : (y))
#endif
*/

/*
#ifndef MAX
#define MAX(x,y) ((x)>(y)? (x) : (y))
#endif
*/

#ifndef ABS
#define ABS(x) ( (x)<0? (-(x)) : (x) )
#endif

#ifndef SGN
#define SGN(x) ( (x)<0? -1.0 : 1.0 )
#endif

#define XOFFSET  40.0		/* offsets (in pixels) of axis origin from */
#define YOFFSET  25.0		/* lower left hand corner of window        */

#define SQRT3  1.73205081

enum movetypes {NOZOOM = 0, ZOOM = 1, MOVELEGEND = 2, MOVEXTITLE = 3,
		 MOVEYTITLE = 4, MOVEMAINTITLE = 5};

enum symboltypes {NOSYMBOL = 0, CIRCLE = 1, XMARK = 2, UPTRIANGLE = 3,
		    DOWNTRIANGLE = 4, DIAMOND = 5, SQUARE = 6, PLUS = 7};

enum linetypes {SOLID = 0, DASH = 1, DOT = 2, CHAINDASH = 3,
		  CHAINDOT = 4, NOLINE = 5};

#define DEFAULTFONTSIZE 12.0

#define DEFAULTAXISTITLEWIDTH 31.332
/* The width of the default xtitle and ytitle in the default font
 * (returned by [axisTitleFont getWidthOf:xtitle], e.g.)
 */

#define DEFAULTMAINTITLEWIDTH 60.676
/* 60.676 is the width of the default main title in the default font */

#define LINE_WIDTH_IF_PRINTING_BW 0.4
#define LINE_WIDTH_IF_PRINTING_COLOR 1.0
