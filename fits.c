/*
 *  fits.c
 *  Messier
 *
 *  Created by abraham on Sun Dec 16 2001.
 *  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
 *
 */


#include <string.h>
#include <stdlib.h>

#include "fitsio.h"


int checkForSimpleSpectrum(char *filename)
{
    fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
    long naxes[2];
    int nfound, status;
    char filestring[FLEN_FILENAME];
    strncpy(filestring,filename,FLEN_FILENAME);

    status = 0;
    naxes[0] = 0;
    naxes[1] = 0;
    
    if(fits_open_file(&fptr, filestring, READONLY, &status)){
        fits_close_file(fptr, &status);
        return(1);
    }
    if(fits_read_keys_lng(fptr, "NAXIS", 1, 2, naxes, &nfound, &status)){
        fits_close_file(fptr, &status);
        return(1);
    }
    if(fits_close_file(fptr, &status)){
        return(1);
    }

    if (naxes[0] <= 0 || naxes[1] != 0){
        return(1); 
    }

    return(0);

};



float *readfloat(char *filename, int *nx, int *ny, int *error_status)

{
  float *arr;
  fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
  long naxes[2], npixels, firstelem;
  int nfound, anynull, status;
  double nullval;
  char filestring[FLEN_FILENAME];
  strncpy(filestring,filename,FLEN_FILENAME);

  status = 0;
  *nx = 0;
  *ny = 0;

  if(fits_open_file(&fptr, filestring, READONLY, &status)){
    fits_close_file(fptr, &status);
    *error_status = status;		
    return (arr);
  }
  if(fits_read_keys_lng(fptr, "NAXIS", 1, 2, naxes, &nfound, &status)){
    fits_close_file(fptr, &status);
    *error_status = status;
    return(arr);
  }

  firstelem = 1;
  npixels  = naxes[0] * naxes[1];     /* number of pixels in the image */
  nullval  = 0;         /* don't check for null values in the image */
  arr = (float *) malloc(sizeof(float)*npixels);
  if(fits_read_img(fptr,TFLOAT,firstelem,npixels,&nullval,arr,&anynull,&status)){
    fits_close_file(fptr, &status);
    *error_status = status;
    return(arr);
  }

  if(fits_close_file(fptr, &status)){
    *error_status = status;
    return(arr);
  }

  *nx = naxes[0];
  *ny = naxes[1];
  *error_status = status;

  return(arr);
};



char *readheader(char *filename, int *error_status)
{
  fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
  int status;
  int nkey,nblank;
  char filestring[FLEN_FILENAME];
  char *header;
  char card[80];
  int i,j;
  int index;
	
  strncpy(filestring,filename,FLEN_FILENAME);
  status = 0;
	
  if(fits_open_file(&fptr, filestring, READONLY, &status)){
    fits_close_file(fptr, &status);
    *error_status = status;		
    return (header);
  }
	
  if(fits_get_hdrspace(fptr, &nkey, &nblank, &status)){
    fits_close_file(fptr, &status);
    *error_status = status;
    return(header);
  }
	
  header = malloc(nkey*81+1);   /* A FITS line is 80 characters by definition. Add 1 for newlines 
				   and the final '\0' on the last line. */
  index = 0;
  for(i=0;i<nkey;i++){
    if(fits_read_record(fptr, i+1, card, &status)){
      fits_close_file(fptr, &status);
      *error_status = status;		
      return (header);
    }
		
    for(j=0;j<80;j++){
      if (card[j]!='\0'){
	header[index++] = card[j];
      }
      else{
	header[index++] = ' ';
      }
    }
    header[index++] = '\n';
  }
  header[81*nkey-1] = '\0';
	
  if(fits_close_file(fptr, &status)){
    *error_status = status;
    return(header);
  }
	
  *error_status = status;
	
  return(header);
};


void writefloat(char *filename, float *arr, long nx, long ny, int *error_status)

{
  fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
  long naxes[2], firstelem, npixels;
  int status;
  char filestring[FLEN_FILENAME];
  strncpy(filestring,filename,FLEN_FILENAME);

  status = 0;

  if(fits_create_file(&fptr, filestring, &status)){
    fits_close_file(fptr, &status);
    *error_status = status;		
  }

  naxes[0] = nx;
  naxes[1] = ny;
  if(fits_create_img(fptr, -32, 2, naxes, &status)){
    fits_close_file(fptr, &status);
    *error_status = status;
  }

  firstelem = 1;
  npixels = nx*ny;
  if(fits_write_img(fptr,TFLOAT,firstelem,npixels,arr,&status)){
    fits_close_file(fptr, &status);
    *error_status = status;
  }

  
  if(fits_close_file(fptr, &status)){
    *error_status = status;
  }

  *error_status = status;

  return;
};


void savespectrum2(char *filename, float *lambda, float *arr, float *optarr,
                 float *skyarr, float *electrons, long nx, int *error_status)
{
    fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
    long naxes[2], firstelem, npixels;
    int status;
    char tempstring[FLEN_FILENAME];
    char filestring[FLEN_FILENAME] = "!";
    int itemp;
    float ftemp;
    char *cchunk;
    char *clines;
    char keyword[10];
    int count;
    int i;
    
    //Create an enormous line with the wavelength calibration information
    cchunk = malloc(1000);
    clines = malloc(1000000);
    sprintf(clines,"wtype=multispec spec1 = \"1 1 2 1. %10.2f %d 0. INDEF INDEF 1. 0. 5 %d",(lambda[nx-1]-lambda[0])/count,(int)nx,(int)nx+1);

    //Write data to a file
    for(i=0;i<nx;i++){
        sprintf(cchunk," %10.2f",*(lambda+i));
        strcat(clines,cchunk);
    }
    strcat(clines,"\"");
    printf("clines is %d characters long\n",strlen(clines));

    //Create the FITS file, over-writing an existing one of the same name if it exists
    strncpy(tempstring,filename,FLEN_FILENAME);
    strncat(filestring,tempstring,FLEN_FILENAME);
    status = 0;
    if(fits_create_file(&fptr, filestring, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Write an empty PHU with information common to all the other headers
    naxes[0] = 0;
    if(fits_create_img(fptr, -32, 0, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

        
    // LINEAR OBJECT SPECTRUM
    naxes[0] = nx;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LINEAR","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    itemp = 2;
    if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE2","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CDELT2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAXMAP01","1 0 0 0 ","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT0_001","system=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Now write the incredibly long WAT2 keyword
    count = 1;
    for(i=0;i<strlen(clines);i+=68){
        if(count>=0 && count<10)
            sprintf(keyword,"WAT2_00%d",count);
        if(count>=10 && count<100)
            sprintf(keyword,"WAT2_0%d",count);
        if(count>=100 && count<1000)
            sprintf(keyword,"WAT2_%d",count);
        fits_write_key(fptr,TSTRING,keyword,clines+i,"",&status);
        count++;
    }

    //Now write the data
    firstelem = 1;
    npixels = nx;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,arr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }


    // ELECTRONS SPECTRUM
    naxes[0] = nx;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","ELECTRON","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    itemp = 2;
    if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE2","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CDELT2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAXMAP01","1 0 0 0 ","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT0_001","system=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Now write the incredibly long WAT2 keyword
    count = 1;
    for(i=0;i<strlen(clines);i+=68){
        if(count>=0 && count<10)
            sprintf(keyword,"WAT2_00%d",count);
        if(count>=10 && count<100)
            sprintf(keyword,"WAT2_0%d",count);
        if(count>=100 && count<1000)
            sprintf(keyword,"WAT2_%d",count);
        fits_write_key(fptr,TSTRING,keyword,clines+i,"",&status);
        count++;
    }

    //Now write the data
    firstelem = 1;
    npixels = nx;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,electrons,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    


    // SKY SPECTRUM
    naxes[0] = nx;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","SKY","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    itemp = 2;
    if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE2","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CDELT2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAXMAP01","1 0 0 0 ","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT0_001","system=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Now write the incredibly long WAT2 keyword
    count = 1;
    for(i=0;i<strlen(clines);i+=68){
        if(count>=0 && count<10)
            sprintf(keyword,"WAT2_00%d",count);
        if(count>=10 && count<100)
            sprintf(keyword,"WAT2_0%d",count);
        if(count>=100 && count<1000)
            sprintf(keyword,"WAT2_%d",count);
        fits_write_key(fptr,TSTRING,keyword,clines+i,"",&status);
        count++;
    }

    //Now write the data
    firstelem = 1;
    npixels = nx;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,skyarr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    

    
    //THAT'S ALL, FOLKS
    if(fits_close_file(fptr, &status)){
        *error_status = status;
    }

    *error_status = status;

    free(cchunk);
    free(clines);
    
    return;
};



void writefloatspec0(char *filename, float *x, float *arr, float *optarr,
                    float *skyarr, float *lambda, float *fits, float *segWithMasks, float *weights,
                    long npts, long nx, long ny, float crval, float crpix, float cdelt, int *error_status)
{
    fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
    long naxes[2], firstelem, npixels;
    int status;
    char tempstring[FLEN_FILENAME];
    char filestring[FLEN_FILENAME] = "!";
    int itemp;
    float ftemp;
    strncpy(tempstring,filename,FLEN_FILENAME);
    strncat(filestring,tempstring,FLEN_FILENAME);
    printf("Writing FITS file: %s \n",filestring);
    
    status = 0;

    if(fits_create_file(&fptr, filestring, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    /* Write an empty PHU */
    naxes[0] = 0;
    if(fits_create_img(fptr, -32, 0, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    
    /* Write the 1D galaxy spectrum to the file as an extension*/
    //LINSPEC1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,arr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LINSPEC1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(crpix > 0.1){
        if(fits_write_key(fptr,TSTRING,"APNUM1","1 1     ","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 1;
        if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"CTYPE1","LINEAR","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRVAL1",&crval,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRPIX1",&crpix,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CD1_1",&cdelt,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT0_001","system=equispec","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=linear label=Wavelength units=angstroms","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = -1.0 * *x;
        if(fits_write_key(fptr,TFLOAT,"LTV1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = 1.0;
        if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 0;
        if(fits_write_key(fptr,TLONG,"DC-FLAG",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
    }
    
    

    //1D sky spectrum
    //LINSKY1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,skyarr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LINSKY1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(crpix > 0.1){
        if(fits_write_key(fptr,TSTRING,"APNUM1","1 1     ","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 1;
        if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"CTYPE1","LINEAR","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRVAL1",&crval,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRPIX1",&crpix,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CD1_1",&cdelt,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT0_001","system=equispec","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=linear label=Wavelength units=angstroms","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = -1.0 * *x;
        if(fits_write_key(fptr,TFLOAT,"LTV1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = 1.0;
        if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 0;
        if(fits_write_key(fptr,TLONG,"DC-FLAG",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
    }
    
  

    /* Write the optimally extracted galaxy spectrum to the file as an extension */
    //OPTSPEC1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,optarr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","OPTSPEC1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(crpix > 0.1){
        if(fits_write_key(fptr,TSTRING,"APNUM1","1 1     ","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 1;
        if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"CTYPE1","LINEAR","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRVAL1",&crval,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRPIX1",&crpix,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CD1_1",&cdelt,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT0_001","system=equispec","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=linear label=Wavelength units=angstroms","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = -1.0 * *x;
        if(fits_write_key(fptr,TFLOAT,"LTV1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = 1.0;
        if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 0;
        if(fits_write_key(fptr,TLONG,"DC-FLAG",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
    }
        

    /* Write the flipped CCD position as an extension */
    //CCDXPOS1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,x,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","CCDXPOS1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }


    /* Write the wavelengths (if known) to the file as an extension. */
    //LAMBDA1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,lambda,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LAMBDA1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }


    /* Write the 2D FITS image to the file as an extension. */
    naxes[0] = nx;
    naxes[1] = ny;
    if(fits_create_img(fptr, -32, 2, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = nx*ny;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,fits,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","SPEC2D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    

    /* Write the 2D Segmentation image to the file as an extension. */
    naxes[0] = nx;
    naxes[1] = ny;
    if(fits_create_img(fptr, -32, 2, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = nx*ny;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,segWithMasks,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","SEG2D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    

    /* Write the 2D optimal extraction weights image to the file as an extension. */
    naxes[0] = nx;
    naxes[1] = ny;
    if(fits_create_img(fptr, -32, 2, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = nx*ny;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,weights,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","WEIGHTS2D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    
    

    if(fits_close_file(fptr, &status)){
        *error_status = status;
    }

    *error_status = status;

    return;
};




void writeFITS1D(char *filename, float *lambda, float *arr, float *optarr,
                 float *skyarr, float *electrons, long nx, int *error_status)
{
    fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
    long naxes[2], firstelem, npixels;
    int status;
    char tempstring[FLEN_FILENAME];
    char filestring[FLEN_FILENAME] = "!";
    int itemp;
    float ftemp;
    char *cchunk;
    char *clines;
    char keyword[10];
    int count;
    int i;
    
    //Create an enormous line with the wavelength calibration information
    cchunk = malloc(1000);
    clines = malloc(1000000);
    sprintf(clines,"wtype=multispec spec1 = \"1 1 2 1. %10.2f %d 0. INDEF INDEF 1. 0. 5 %d",(lambda[nx-1]-lambda[0])/count,(int)nx,(int)nx+1);

    //Write data to a file
    for(i=0;i<nx;i++){
        sprintf(cchunk," %10.2f",*(lambda+i));
        strcat(clines,cchunk);
    }
    strcat(clines,"\"");
    printf("clines is %d characters long\n",strlen(clines));

    //Create the FITS file, over-writing an existing one of the same name if it exists
    strncpy(tempstring,filename,FLEN_FILENAME);
    strncat(filestring,tempstring,FLEN_FILENAME);
    status = 0;
    if(fits_create_file(&fptr, filestring, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Write an empty PHU with information common to all the other headers
    naxes[0] = 0;
    if(fits_create_img(fptr, -32, 0, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

        
    // LINEAR OBJECT SPECTRUM
    naxes[0] = nx;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LINEAR","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    itemp = 2;
    if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE2","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CDELT2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAXMAP01","1 0 0 0 ","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT0_001","system=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Now write the incredibly long WAT2 keyword
    count = 1;
    for(i=0;i<strlen(clines);i+=68){
        if(count>=0 && count<10)
            sprintf(keyword,"WAT2_00%d",count);
        if(count>=10 && count<100)
            sprintf(keyword,"WAT2_0%d",count);
        if(count>=100 && count<1000)
            sprintf(keyword,"WAT2_%d",count);
        fits_write_key(fptr,TSTRING,keyword,clines+i,"",&status);
        count++;
    }

    //Now write the data
    firstelem = 1;
    npixels = nx;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,arr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }


    // ELECTRONS SPECTRUM
    naxes[0] = nx;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","ELECTRON","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    itemp = 2;
    if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE2","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CDELT2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAXMAP01","1 0 0 0 ","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT0_001","system=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Now write the incredibly long WAT2 keyword
    count = 1;
    for(i=0;i<strlen(clines);i+=68){
        if(count>=0 && count<10)
            sprintf(keyword,"WAT2_00%d",count);
        if(count>=10 && count<100)
            sprintf(keyword,"WAT2_0%d",count);
        if(count>=100 && count<1000)
            sprintf(keyword,"WAT2_%d",count);
        fits_write_key(fptr,TSTRING,keyword,clines+i,"",&status);
        count++;
    }

    //Now write the data
    firstelem = 1;
    npixels = nx;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,electrons,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    


    // SKY SPECTRUM
    naxes[0] = nx;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","SKY","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    itemp = 2;
    if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE2","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CDELT2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAXMAP01","1 0 0 0 ","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT0_001","system=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Now write the incredibly long WAT2 keyword
    count = 1;
    for(i=0;i<strlen(clines);i+=68){
        if(count>=0 && count<10)
            sprintf(keyword,"WAT2_00%d",count);
        if(count>=10 && count<100)
            sprintf(keyword,"WAT2_0%d",count);
        if(count>=100 && count<1000)
            sprintf(keyword,"WAT2_%d",count);
        fits_write_key(fptr,TSTRING,keyword,clines+i,"",&status);
        count++;
    }

    //Now write the data
    firstelem = 1;
    npixels = nx;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,skyarr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    

    
    //THAT'S ALL, FOLKS
    if(fits_close_file(fptr, &status)){
        *error_status = status;
    }

    *error_status = status;

    free(cchunk);
    free(clines);
    
    return;
};



void writefloatspec(char *filename, float *x, float *arr, float *optarr,
                    float *skyarr, float *lambda, float *fits, float *segWithMasks, float *weights,
                    long npts, long nx, long ny, float crval, float crpix, float cdelt, int *error_status)
{
    fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
    long naxes[2], firstelem, npixels;
    int status;
    char tempstring[FLEN_FILENAME];
    char filestring[FLEN_FILENAME] = "!";
    int itemp;
    float ftemp;
    strncpy(tempstring,filename,FLEN_FILENAME);
    strncat(filestring,tempstring,FLEN_FILENAME);
    printf("Writing FITS file: %s \n",filestring);
    
    status = 0;

    if(fits_create_file(&fptr, filestring, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    /* Write an empty PHU */
    naxes[0] = 0;
    if(fits_create_img(fptr, -32, 0, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    
    /* Write the 1D galaxy spectrum to the file as an extension*/
    //LINSPEC1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,arr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LINSPEC1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(crpix > 0.1){
        if(fits_write_key(fptr,TSTRING,"APNUM1","1 1     ","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 1;
        if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"CTYPE1","LINEAR","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRVAL1",&crval,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRPIX1",&crpix,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CD1_1",&cdelt,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT0_001","system=equispec","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=linear label=Wavelength units=angstroms","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = -1.0 * *x;
        if(fits_write_key(fptr,TFLOAT,"LTV1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = 1.0;
        if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 0;
        if(fits_write_key(fptr,TLONG,"DC-FLAG",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
    }
    
    

    //1D sky spectrum
    //LINSKY1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,skyarr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LINSKY1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(crpix > 0.1){
        if(fits_write_key(fptr,TSTRING,"APNUM1","1 1     ","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 1;
        if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"CTYPE1","LINEAR","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRVAL1",&crval,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRPIX1",&crpix,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CD1_1",&cdelt,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT0_001","system=equispec","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=linear label=Wavelength units=angstroms","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = -1.0 * *x;
        if(fits_write_key(fptr,TFLOAT,"LTV1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = 1.0;
        if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 0;
        if(fits_write_key(fptr,TLONG,"DC-FLAG",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
    }
    
  

    /* Write the optimally extracted galaxy spectrum to the file as an extension */
    //OPTSPEC1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,optarr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","OPTSPEC1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(crpix > 0.1){
        if(fits_write_key(fptr,TSTRING,"APNUM1","1 1     ","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 1;
        if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"CTYPE1","LINEAR","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRVAL1",&crval,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CRPIX1",&crpix,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TFLOAT,"CD1_1",&cdelt,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT0_001","system=equispec","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        if(fits_write_key(fptr,TSTRING,"WAT1_001","wtype=linear label=Wavelength units=angstroms","",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = -1.0 * *x;
        if(fits_write_key(fptr,TFLOAT,"LTV1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        ftemp = 1.0;
        if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
        itemp = 0;
        if(fits_write_key(fptr,TLONG,"DC-FLAG",&itemp,"",&status)){
            fits_close_file(fptr, &status);
            *error_status = status;
        }
    }
        

    /* Write the flipped CCD position as an extension */
    //CCDXPOS1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,x,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","CCDXPOS1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }


    /* Write the wavelengths (if known) to the file as an extension. */
    //LAMBDA1D
    naxes[0] = npts;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = npts;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,lambda,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","LAMBDA1D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }


    /* Write the 2D FITS image to the file as an extension. */
    naxes[0] = nx;
    naxes[1] = ny;
    if(fits_create_img(fptr, -32, 2, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = nx*ny;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,fits,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","SPEC2D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    

    /* Write the 2D Segmentation image to the file as an extension. */
    naxes[0] = nx;
    naxes[1] = ny;
    if(fits_create_img(fptr, -32, 2, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = nx*ny;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,segWithMasks,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","SEG2D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    

    /* Write the 2D optimal extraction weights image to the file as an extension. */
    naxes[0] = nx;
    naxes[1] = ny;
    if(fits_create_img(fptr, -32, 2, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    firstelem = 1;
    npixels = nx*ny;
    if(fits_write_img(fptr,TFLOAT,firstelem,npixels,weights,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"EXTNAME","WEIGHTS2D","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    
    

    if(fits_close_file(fptr, &status)){
        *error_status = status;
    }

    *error_status = status;

    return;
};





int savespectrum(char *filename, int nx, void *arr, int datatype, int p0, double pMin, double pMax,
                double *coeffs, int ncoeff)
{
    fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
    long naxes[2], firstelem, npixels;
    int status;
    char tempstring[FLEN_FILENAME];
    char filestring[FLEN_FILENAME] = "!";
    int itemp;
    float ftemp;
    char keyword[10];
    int count;
    int i;
    char *cchunk;
    char *clines;
    int *error_status;
    
    //Create the FITS file, over-writing an existing one of the same name if it exists
    strncpy(tempstring,filename,FLEN_FILENAME);
    strncat(filestring,tempstring,FLEN_FILENAME);
    status = 0;
    if(fits_create_file(&fptr, filestring, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Write the linear object spectrum
    naxes[0] = nx;
    if(fits_create_img(fptr, -32, 1, naxes, &status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    itemp = -p0;
    if(fits_write_key(fptr,TLONG,"LTV1",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    itemp = 2;
    if(fits_write_key(fptr,TLONG,"WCSDIM",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE1","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    itemp = -p0;
    if(fits_write_key(fptr,TLONG,"CRPIX1",&itemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM1_1",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT0_001","system=multispec","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAT1_001",
                      "wtype=multispec label=Wavelength unit=angstroms","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"CTYPE2","MULTISPE","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    ftemp = 1.0;
    if(fits_write_key(fptr,TFLOAT,"CDELT2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"CD2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TFLOAT,"LTM2_2",&ftemp,"",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
    if(fits_write_key(fptr,TSTRING,"WAXMAP01","1 0 0 0 ","",&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }

    //Create an enormous line with the wavelength calibration information
    cchunk = malloc(1000);
    clines = malloc(1000000);
    sprintf(clines,"wtype=multispec spec1 = \"1 1 2 1. %10.2f %d 0. INDEF INDEF 1. 0. 2 %d %f %f",
            5.0, (int)nx, ncoeff, (float)pMin, (float)pMax);
    //Write data to a file
    for(i=0;i<ncoeff;i++){
        sprintf(cchunk," %18.12f",*(coeffs+i));
        strcat(clines,cchunk);
    }
    strcat(clines,"\"");
    //printf("clines is %d characters long\n",strlen(clines));
    
    
    //Now write the incredibly long WAT2 keyword
    count = 1;
    for(i=0;i<strlen(clines);i+=68){
        if(count>=0 && count<10)
            sprintf(keyword,"WAT2_00%d",count);
        if(count>=10 && count<100)
            sprintf(keyword,"WAT2_0%d",count);
        if(count>=100 && count<1000)
            sprintf(keyword,"WAT2_%d",count);
        fits_write_key(fptr,TSTRING,keyword,clines+i,"",&status);
        count++;
    }

    //Now write the data
    firstelem = 1;
    npixels = nx;
    if(fits_write_img(fptr,datatype,firstelem,npixels,arr,&status)){
        fits_close_file(fptr, &status);
        *error_status = status;
    }
        
    //Close up shop
    if(fits_close_file(fptr, &status)){
        *error_status = status;
    }

    free(cchunk);
    free(clines);
    
    return(status);
};




char *errormessage(int status)
{
  char *message;
  message=malloc(FLEN_ERRMSG);
  fits_get_errstatus(status,message);
  return(message);
}

