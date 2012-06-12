/*
 * Auxiliary routines, all taken from xyplot (translated from Fortran to C).
 */

#ifndef PLOTDEFS
#include "defs.h"
#endif

#include <strings.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>		// for exit()
#import <AppKit/AppKit.h>
//#include <appkit/Panel.h>	// for NSRunAlertPanel
//#include <bsd/sys/param.h>	// for definitions of MAX and MIN

/*
 * Count the number of labels on a given axis.
 */

void
count_labels(int *pn, double *pfirst, double min, double inc, double max)
{
	int   bottom, top, j;
	double range, absinc, tol, guess;
	
	if (inc != 0.0) {
		*pn  = 0;
		bottom = (int)(min/inc) - 1;
		top    = (int)(max/inc) + 1;
		range  = ABS(max - min);
		absinc = MIN(range, ABS(inc));
		tol    = absinc * (range + absinc) / 100.0;
		for (j=top; j>=bottom; j--) {
			guess = (double)j * inc;
			if ( (max-guess)*(guess-min) >= -tol) {
				*pn += 1;
				*pfirst = guess;
			}
		}
	}
	else {
		*pn     = 0;
		*pfirst = 0.0;
	}
	return;
}

/*
 * Write a float into a string and see how many characters are to the left
 * of the decimal point, how many total decimal characters there are, and
 * how many characters there are in the exponent (if exponential notation).
 */
void
numstring(double x, int *nl, int *nd, int *ne)
{
	char string[80];
	double  ax;
	int     i, nc, net;
	
	ax = ABS(x);
	i  = ax;
	if ((double)i==ax  &&  ax<99999.0) {
		sprintf(string, "%1d", (int)x);
	}
	else {
		if (ax>=1.e-4  && ax<1.e5) {
			if ( ((int)(x*10000.0) % 10000) == 0 )
				sprintf(string, "%-6.0f", x); /* left-justify  */
						else if ( ((int)(x*10000.0) % 1000) == 0 )
						sprintf(string, "%-7.1f", x);
						else if ( ((int)(x*10000.0) % 100) == 0 )
						sprintf(string, "%-8.2f", x);
						else if ( ((int)(x*10000.0) % 10) == 0 )
						sprintf(string, "%-9.3f", x);
						else
						/*	sprintf(string, "%-10.4f", x);  this can fail -- e.g., x=0.000718 */
						sprintf(string, "%10.6f", x); /* will this always work? */
		}
else {
			sprintf(string, "%-#11.2e", x);
}
	}
nc = strlen(string);
/* strip off blanks from the end of the string: */
while (string[nc-1] == ' ') {
    string[--nc] = '\0';
}
nc = strlen(string);

/* nl = no. of characters left of the decimal point (including sign) */
*nl = 0;
for (i=nc-1; i>=0; i--) {
    *nl += 1;
    if (string[i] == '.') *nl = 0;
}

/* nd = no. of decimal characters (including decimal point, omitting
* trailing zeros)
*/
*nd = 0;
for (i=nc-1; i>=*nl; i--) {
    *nd += 1;
    if (string[i] == 'e' || string[i] == 'E') *nd = 0;
    if (string[i] == '0' && *nd == 1) *nd = 0;
}

/* ne = no. of exponent characters (including the 'E' if any) */
*ne = 0;
for (i=*nl + *nd; i<nc; i++) {
    if (string[i] == 'e' || string[i] == 'E') *ne = nc - i;
}
net = 0;
for (i = nc-1; i >= nc - *ne + 2; i--) {
    if (string[i] != '0') net = 2 + nc - i;
}
*ne = net;

/* Some special cases where floating point numbers may be
* expressed as integers.
*/
if (*nd==1 && *ne==0) *nd = 1;
return;
}

/*
 * See what the formatting would be if we go from min to max in
 * steps of inc.
 */
void
autoformat(double min, double inc, double max, int *axformat)
{
	int     nlabels, i, nl, nd, ne;
	double  first, value;
	
	*axformat       = 0;
	*(axformat + 1) = 0;
	*(axformat + 2) = 0;
	count_labels(&nlabels, &first, min, inc, max);
	for (i=0; i<nlabels; i++) {
		/* Special test here for what should be exact 0 (but isn't sometimes
		* due to floating-point arithmetic.
		*/
		if (inc != 0.0  && fabs(first/inc + (double)i) < 1.0e-14) {	/* ugly */
			value = 0.0;
		}
		else {
			value = first + inc*(double)i;
		}
		numstring(value, &nl, &nd, &ne);
		if (*(axformat+2)==0 && ne!=0) {
			*axformat     = nl;
			*(axformat+1) = nd;
			*(axformat+2) = ne;
		}
		else {
			*axformat     = MAX(nl, *axformat);
			*(axformat+1) = MAX(nd, *(axformat+1));
			*(axformat+2) = MAX(ne, *(axformat+2));
		}
  }
return;
}

/*
 * Put a float into a string with a specified format.
 */
void
handformat(float number, char *string, int *axformat)
{
	int  nl, nd, ne;
	
	nl = *(axformat+0);
	nd = *(axformat+1);
	ne = *(axformat+2);
	
	// if all axformat[i] are 0, return just a blank:
	if (ne==0 && nd==0 && nl==0) {
		sprintf(string, " ");
		return;
	}
	
	// special case 0:
	if (number == 0.0) {
		sprintf(string, "%1d", 0);
		return;
	}
	if (ne==0) {
		if (nd==0) {
			sprintf(string, "%*d", nl, (int)rint((double)number));
		}
		else
			sprintf(string, "%*.*f", nl, nd-1, number);
	}
	else {
		if (nd==0)
			sprintf(string, "%*.*e", nl, nd, number);
		else
			sprintf(string, "%*.*e", ne+1, nd-1, number);
	}
	return;
}

/*
 * Compute nice increment for linear plotting, given min and max.
 */
void
computeNiceLinInc(float *pmin, float *pmax, float *pinc)
{
	float fmin = *pmin, fmax = *pmax, finc = (fmax - fmin)/5.0, x;
	int n;
	
	if (finc <= 0.0) {
		fmin = (fmin>0.0? 0.9*fmin : 1.1*fmin);
		fmax = (fmax>0.0? 1.1*fmax : 0.9*fmax);
		NSLog(@"---------> fmin: %f fmax: %f",fmin,fmax);
		finc = (fmax - fmin)/5.0;
		// for safety:
		
		if (finc < 0.0) {
			n = NSRunAlertPanel(@"computeNiceLinInc",
								@"Impossible increment = %g.\n"
								@"I'm very confused "
								@"(Perhaps all data is being ignored -- no lines, no symbols)",
								@"Quit", @"Continue", NULL, finc);
			if (n==NSAlertDefaultReturn)
				exit(0);
			else if (n==NSAlertAlternateReturn) {
				*pmin = 0.0;
				*pmax = 1.0;
				*pinc = 0.2;
				return;
			}
			
		}
	}
	n = ( log10((double)finc) >= 0.0 ? (int)floor(log10((double)finc)) :
		  (int)ceil(log10((double)finc)) );
	if (finc > 1.0) n++;
	x = finc * (float)pow((double)10.0, (double)(-n));
	finc = 0.1;
	if (x > 0.1)  finc = 0.2;
	if (x > 0.2)  finc = 0.25;
	if (x > 0.25) finc = 0.5;
	if (x > 0.5)  finc = 1.0;
	finc = finc * (float)pow((double)10.0, (double)n);
	
	if (fmin < ((int)(fmin/finc))*finc) fmin = ((int)(fmin/finc - 1))*finc;
	else                                fmin = ((int)(fmin/finc))*finc;
	
	if (fmax > ((int)(fmax/finc))*finc) fmax = ((int)(fmax/finc + 1))*finc;
	else                                fmax = ((int)(fmax/finc))*finc;
	
	*pmin = fmin;
	*pmax = fmax;
	*pinc = finc;
	return;
}


/*
 * Compute a nice min and max for logarithmic plotting (we take increment=1).
 */
void
computeNiceLogInc(float *pmin, float *pmax, float *pinc)
{
	float fmin, fmax, finc;
	int n;
	
	// for safety:
	if (*pmin <= 0.0 || *pmax <= 0.0) {
		n = NSRunAlertPanel(@"computeNiceLogInc",
							@"Impossible min/max = %g, %g.\n"
							@"I'm very confused "
							@"(Perhaps all data is being ignored -- no lines, no symbols)",
							@"Quit", @"Continue", NULL, *pmin, *pmax);
		if (n==NSAlertDefaultReturn)
			exit(0);
		else if (n==NSAlertAlternateReturn) {
			*pmin = 1.0;
			*pmax = 10.0;
			*pinc = 1.0;
			return;
		}
    }
	
	fmin = (float)log10(*pmin);
	fmax = (float)log10(*pmax);
	finc = 1.0;
	
	fmin = (float) floor((double)fmin);
	fmax = (float) ceil((double)fmax);
	
	if (fmin == fmax) {
		fmin = fmin - 1.0;
		fmax = fmax + 1.0;
	}
	*pmin = (float)pow((double)10.0, (double)fmin);
	*pmax = (float)pow((double)10.0, (double)fmax);
	*pinc = (float)pow((double)10.0, (double)finc);
	return;
}
