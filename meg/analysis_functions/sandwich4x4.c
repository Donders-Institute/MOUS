#include <math.h>
#include <matrix.h>
#include <mex.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /*declare variables*/
  const mwSize *dims;
  mwSize  *dimsout;
  mwIndex indx;
  int i, numdims;
  int numelin;
  mxClassID classid;
  double *input1r, *input1i, *output1r, *output1i, *input2r, *input2i, *output2r, *output2i;
  double x11,x12,x13,x14,x21,x22,x23,x24,x31,x32,x33,x34,x41,x42,x43,x44;
  double y11,y12,y13,y14,y21,y22,y23,y24,y31,y32,y33,y34,y41,y42,y43,y44;
  double z11,z12,z13,z14,z21,z22,z23,z24,z31,z32,z33,z34,z41,z42,z43,z44;
  double x11i,x12i,x13i,x14i,x21i,x22i,x23i,x24i,x31i,x32i,x33i,x34i,x41i,x42i,x43i,x44i;
  double y11i,y12i,y13i,y14i,y21i,y22i,y23i,y24i,y31i,y32i,y33i,y34i,y41i,y42i,y43i,y44i;
  double z11i,z12i,z13i,z14i,z21i,z22i,z23i,z24i,z31i,z32i,z33i,z34i,z41i,z42i,z43i,z44i;
  
  /*figure out the classid*/
  classid = mxGetClassID(prhs[1]);
     
  /*check inputs*/
  if (nrhs>2)
    mexErrMsgTxt("Too many input arguments");
  
  /*associate inputs*/
  input1r = mxGetData(prhs[0]);
  input1i = mxGetImagData(prhs[0]);
  input2r = mxGetData(prhs[1]);
  input2i = mxGetImagData(prhs[1]);
  
  /*figure out dimension info and number of elements*/
  dims    = mxGetDimensions(prhs[0]);
  numdims = mxGetNumberOfDimensions(prhs[0]);
  numelin = mxGetNumberOfElements(prhs[0]);
  
  dimsout    = mxMalloc(numdims * sizeof(mwSize));
  for (i=0; i<numdims; i++)
  {
    dimsout[i] = dims[i];
  }
  
  /*associate output*/
  if (input1i == NULL && input2i == NULL)
  {
    plhs[0]  = mxCreateNumericArray(numdims, dimsout, classid, mxREAL);
    output1r = mxGetData(plhs[0]);
  }
  else
  {
    plhs[0]  = mxCreateNumericArray(numdims, dimsout, classid, mxCOMPLEX);
    output1r = mxGetData(plhs[0]);
    output1i = mxGetImagData(plhs[0]);
  }
  
  /* do the computation*/
  if (input1i == NULL && input2i == NULL)
  {  
    for (i=0; i<numelin/16; i++)
    {
      x11 = input1r[i*16   ];
      x21 = input1r[i*16+1 ];
      x31 = input1r[i*16+2 ];
      x41 = input1r[i*16+3 ];
      x12 = input1r[i*16+4 ];
      x22 = input1r[i*16+5 ];
      x32 = input1r[i*16+6 ];
      x42 = input1r[i*16+7 ];
      x13 = input1r[i*16+8 ];
      x23 = input1r[i*16+9 ];
      x33 = input1r[i*16+10];
      x43 = input1r[i*16+11];
      x14 = input1r[i*16+12];
      x24 = input1r[i*16+13];
      x34 = input1r[i*16+14];
      x44 = input1r[i*16+15];
      
      y11 = input2r[i*16   ];
      y21 = input2r[i*16+1 ];
      y31 = input2r[i*16+2 ];
      y41 = input2r[i*16+3 ];
      y12 = input2r[i*16+4 ];
      y22 = input2r[i*16+5 ];
      y32 = input2r[i*16+6 ];
      y42 = input2r[i*16+7 ];
      y13 = input2r[i*16+8 ];
      y23 = input2r[i*16+9 ];
      y33 = input2r[i*16+10];
      y43 = input2r[i*16+11];
      y14 = input2r[i*16+12];
      y24 = input2r[i*16+13];
      y34 = input2r[i*16+14];
      y44 = input2r[i*16+15];
      
      z11 = x11*y11+x12*y21+x13*y31+x14*y41;
      z21 = x21*y11+x22*y21+x23*y31+x24*y41;
      z31 = x31*y11+x32*y21+x33*y31+x34*y41;
      z41 = x41*y11+x42*y21+x43*y31+x44*y41;
      z12 = x11*y12+x12*y22+x13*y32+x14*y42;
      z22 = x21*y12+x22*y22+x23*y32+x24*y42;
      z32 = x31*y12+x32*y22+x33*y32+x34*y42;
      z42 = x41*y12+x42*y22+x43*y32+x44*y42;
      z13 = x11*y13+x12*y23+x13*y33+x14*y43;
      z23 = x21*y13+x22*y23+x23*y33+x24*y43;
      z33 = x31*y13+x32*y23+x33*y33+x34*y43;
      z43 = x41*y13+x42*y23+x43*y33+x44*y43;
      z14 = x11*y14+x12*y24+x13*y34+x14*y44;
      z24 = x21*y14+x22*y24+x23*y34+x24*y44;
      z34 = x31*y14+x32*y24+x33*y34+x34*y44;
      z44 = x41*y14+x42*y24+x43*y34+x44*y44;
      
      output1r[i*16   ] = z11*x11+z12*x12+z13*x13+z14*x14;
      output1r[i*16+1 ] = z21*x11+z22*x12+z23*x13+z24*x14;
      output1r[i*16+2 ] = z31*x11+z32*x12+z33*x13+z34*x14;
      output1r[i*16+3 ] = z41*x11+z42*x12+z43*x13+z44*x14;
      output1r[i*16+4 ] = z11*x21+z12*x22+z13*x23+z14*x24;
      output1r[i*16+5 ] = z21*x21+z22*x22+z23*x23+z24*x24;
      output1r[i*16+6 ] = z31*x21+z32*x22+z33*x23+z34*x24;
      output1r[i*16+7 ] = z41*x21+z42*x22+z43*x23+z44*x24;
      output1r[i*16+8 ] = z11*x31+z12*x32+z13*x33+z14*x34;
      output1r[i*16+9 ] = z21*x31+z22*x32+z23*x33+z24*x34;
      output1r[i*16+10] = z31*x31+z32*x32+z33*x33+z34*x34;
      output1r[i*16+11] = z41*x31+z42*x32+z43*x33+z44*x34;
      output1r[i*16+12] = z11*x41+z12*x42+z13*x43+z14*x44;
      output1r[i*16+13] = z21*x41+z22*x42+z23*x43+z24*x44;
      output1r[i*16+14] = z31*x41+z32*x42+z33*x43+z34*x44;
      output1r[i*16+15] = z41*x41+z42*x42+z43*x43+z44*x44;

    }
    return;
  }
  else if (input1i == NULL)
  {
    for (i=0; i<numelin/16; i++)
    {
      /*matrix 1*/
      x11 = input1r[i*16   ];
      x21 = input1r[i*16+1 ];
      x31 = input1r[i*16+2 ];
      x41 = input1r[i*16+3 ];
      x12 = input1r[i*16+4 ];
      x22 = input1r[i*16+5 ];
      x32 = input1r[i*16+6 ];
      x42 = input1r[i*16+7 ];
      x13 = input1r[i*16+8 ];
      x23 = input1r[i*16+9 ];
      x33 = input1r[i*16+10];
      x43 = input1r[i*16+11];
      x14 = input1r[i*16+12];
      x24 = input1r[i*16+13];
      x34 = input1r[i*16+14];
      x44 = input1r[i*16+15];
           
      /*matrix 2*/
      y11 = input2r[i*16   ];
      y21 = input2r[i*16+1 ];
      y31 = input2r[i*16+2 ];
      y41 = input2r[i*16+3 ];
      y12 = input2r[i*16+4 ];
      y22 = input2r[i*16+5 ];
      y32 = input2r[i*16+6 ];
      y42 = input2r[i*16+7 ];
      y13 = input2r[i*16+8 ];
      y23 = input2r[i*16+9 ];
      y33 = input2r[i*16+10];
      y43 = input2r[i*16+11];
      y14 = input2r[i*16+12];
      y24 = input2r[i*16+13];
      y34 = input2r[i*16+14];
      y44 = input2r[i*16+15];
      
      y11i = input2i[i*16   ];
      y21i = input2i[i*16+1 ];
      y31i = input2i[i*16+2 ];
      y41i = input2i[i*16+3 ];
      y12i = input2i[i*16+4 ];
      y22i = input2i[i*16+5 ];
      y32i = input2i[i*16+6 ];
      y42i = input2i[i*16+7 ];
      y13i = input2i[i*16+8 ];
      y23i = input2i[i*16+9 ];
      y33i = input2i[i*16+10];
      y43i = input2i[i*16+11];
      y14i = input2i[i*16+12];
      y24i = input2i[i*16+13];
      y34i = input2i[i*16+14];
      y44i = input2i[i*16+15];
      
      z11 = x11*y11+x12*y21+x13*y31+x14*y41;
      z21 = x21*y11+x22*y21+x23*y31+x24*y41;
      z31 = x31*y11+x32*y21+x33*y31+x34*y41;
      z41 = x41*y11+x42*y21+x43*y31+x44*y41;
      z12 = x11*y12+x12*y22+x13*y32+x14*y42;
      z22 = x21*y12+x22*y22+x23*y32+x24*y42;
      z32 = x31*y12+x32*y22+x33*y32+x34*y42;
      z42 = x41*y12+x42*y22+x43*y32+x44*y42;
      z13 = x11*y13+x12*y23+x13*y33+x14*y43;
      z23 = x21*y13+x22*y23+x23*y33+x24*y43;
      z33 = x31*y13+x32*y23+x33*y33+x34*y43;
      z43 = x41*y13+x42*y23+x43*y33+x44*y43;
      z14 = x11*y14+x12*y24+x13*y34+x14*y44;
      z24 = x21*y14+x22*y24+x23*y34+x24*y44;
      z34 = x31*y14+x32*y24+x33*y34+x34*y44;
      z44 = x41*y14+x42*y24+x43*y34+x44*y44;
     
      z11i = x11*y11i+x12*y21i+x13*y31i+x14*y41i;
      z21i = x21*y11i+x22*y21i+x23*y31i+x24*y41i;
      z31i = x31*y11i+x32*y21i+x33*y31i+x34*y41i;
      z41i = x41*y11i+x42*y21i+x43*y31i+x44*y41i;
      z12i = x11*y12i+x12*y22i+x13*y32i+x14*y42i;
      z22i = x21*y12i+x22*y22i+x23*y32i+x24*y42i;
      z32i = x31*y12i+x32*y22i+x33*y32i+x34*y42i;
      z42i = x41*y12i+x42*y22i+x43*y32i+x44*y42i;
      z13i = x11*y13i+x12*y23i+x13*y33i+x14*y43i;
      z23i = x21*y13i+x22*y23i+x23*y33i+x24*y43i;
      z33i = x31*y13i+x32*y23i+x33*y33i+x34*y43i;
      z43i = x41*y13i+x42*y23i+x43*y33i+x44*y43i;
      z14i = x11*y14i+x12*y24i+x13*y34i+x14*y44i;
      z24i = x21*y14i+x22*y24i+x23*y34i+x24*y44i;
      z34i = x31*y14i+x32*y24i+x33*y34i+x34*y44i;
      z44i = x41*y14i+x42*y24i+x43*y34i+x44*y44i;
      
      /*fill in the real part of the output matrix*/
      output1r[i*16   ] = z11*x11+z12*x12+z13*x13+z14*x14;
      output1r[i*16+1 ] = z21*x11+z22*x12+z23*x13+z24*x14;
      output1r[i*16+2 ] = z31*x11+z32*x12+z33*x13+z34*x14;
      output1r[i*16+3 ] = z41*x11+z42*x12+z43*x13+z44*x14;
      output1r[i*16+4 ] = z11*x21+z12*x22+z13*x23+z14*x24;
      output1r[i*16+5 ] = z21*x21+z22*x22+z23*x23+z24*x24;
      output1r[i*16+6 ] = z31*x21+z32*x22+z33*x23+z34*x24;
      output1r[i*16+7 ] = z41*x21+z42*x22+z43*x23+z44*x24;
      output1r[i*16+8 ] = z11*x31+z12*x32+z13*x33+z14*x34;
      output1r[i*16+9 ] = z21*x31+z22*x32+z23*x33+z24*x34;
      output1r[i*16+10] = z31*x31+z32*x32+z33*x33+z34*x34;
      output1r[i*16+11] = z41*x31+z42*x32+z43*x33+z44*x34;
      output1r[i*16+12] = z11*x41+z12*x42+z13*x43+z14*x44;
      output1r[i*16+13] = z21*x41+z22*x42+z23*x43+z24*x44;
      output1r[i*16+14] = z31*x41+z32*x42+z33*x43+z34*x44;
      output1r[i*16+15] = z41*x41+z42*x42+z43*x43+z44*x44;
      
      /*fill in the imaginary part of the output matrix*/
      output1i[i*16   ] = z11i*x11+z12i*x12+z13i*x13+z14i*x14;
      output1i[i*16+1 ] = z21i*x11+z22i*x12+z23i*x13+z24i*x14;
      output1i[i*16+2 ] = z31i*x11+z32i*x12+z33i*x13+z34i*x14;
      output1i[i*16+3 ] = z41i*x11+z42i*x12+z43i*x13+z44i*x14;
      output1i[i*16+4 ] = z11i*x21+z12i*x22+z13i*x23+z14i*x24;
      output1i[i*16+5 ] = z21i*x21+z22i*x22+z23i*x23+z24i*x24;
      output1i[i*16+6 ] = z31i*x21+z32i*x22+z33i*x23+z34i*x24;
      output1i[i*16+7 ] = z41i*x21+z42i*x22+z43i*x23+z44i*x24;
      output1i[i*16+8 ] = z11i*x31+z12i*x32+z13i*x33+z14i*x34;
      output1i[i*16+9 ] = z21i*x31+z22i*x32+z23i*x33+z24i*x34;
      output1i[i*16+10] = z31i*x31+z32i*x32+z33i*x33+z34i*x34;
      output1i[i*16+11] = z41i*x31+z42i*x32+z43i*x33+z44i*x34;
      output1i[i*16+12] = z11i*x41+z12i*x42+z13i*x43+z14i*x44;
      output1i[i*16+13] = z21i*x41+z22i*x42+z23i*x43+z24i*x44;
      output1i[i*16+14] = z31i*x41+z32i*x42+z33i*x43+z34i*x44;
      output1i[i*16+15] = z41i*x41+z42i*x42+z43i*x43+z44i*x44;
            
    }
    return;
  }
  else if (input2i == NULL)
  {
    for (i=0; i<numelin/16; i++)
    {
      /*matrix 1*/
      x11 = input1r[i*16   ];
      x21 = input1r[i*16+1 ];
      x31 = input1r[i*16+2 ];
      x41 = input1r[i*16+3 ];
      x12 = input1r[i*16+4 ];
      x22 = input1r[i*16+5 ];
      x32 = input1r[i*16+6 ];
      x42 = input1r[i*16+7 ];
      x13 = input1r[i*16+8 ];
      x23 = input1r[i*16+9 ];
      x33 = input1r[i*16+10];
      x43 = input1r[i*16+11];
      x14 = input1r[i*16+12];
      x24 = input1r[i*16+13];
      x34 = input1r[i*16+14];
      x44 = input1r[i*16+15];
      
      x11i = input1i[i*16   ];
      x21i = input1i[i*16+1 ];
      x31i = input1i[i*16+2 ];
      x41i = input1i[i*16+3 ];
      x12i = input1i[i*16+4 ];
      x22i = input1i[i*16+5 ];
      x32i = input1i[i*16+6 ];
      x42i = input1i[i*16+7 ];
      x13i = input1i[i*16+8 ];
      x23i = input1i[i*16+9 ];
      x33i = input1i[i*16+10];
      x43i = input1i[i*16+11];
      x14i = input1i[i*16+12];
      x24i = input1i[i*16+13];
      x34i = input1i[i*16+14];
      x44i = input1i[i*16+15];
      
      /*matrix 2*/  
      y11 = input2r[i*16   ];
      y21 = input2r[i*16+1 ];
      y31 = input2r[i*16+2 ];
      y41 = input2r[i*16+3 ];
      y12 = input2r[i*16+4 ];
      y22 = input2r[i*16+5 ];
      y32 = input2r[i*16+6 ];
      y42 = input2r[i*16+7 ];
      y13 = input2r[i*16+8 ];
      y23 = input2r[i*16+9 ];
      y33 = input2r[i*16+10];
      y43 = input2r[i*16+11];
      y14 = input2r[i*16+12];
      y24 = input2r[i*16+13];
      y34 = input2r[i*16+14];
      y44 = input2r[i*16+15];
      
      z11 = x11*y11+x12*y21+x13*y31+x14*y41;
      z21 = x21*y11+x22*y21+x23*y31+x24*y41;
      z31 = x31*y11+x32*y21+x33*y31+x34*y41;
      z41 = x41*y11+x42*y21+x43*y31+x44*y41;
      z12 = x11*y12+x12*y22+x13*y32+x14*y42;
      z22 = x21*y12+x22*y22+x23*y32+x24*y42;
      z32 = x31*y12+x32*y22+x33*y32+x34*y42;
      z42 = x41*y12+x42*y22+x43*y32+x44*y42;
      z13 = x11*y13+x12*y23+x13*y33+x14*y43;
      z23 = x21*y13+x22*y23+x23*y33+x24*y43;
      z33 = x31*y13+x32*y23+x33*y33+x34*y43;
      z43 = x41*y13+x42*y23+x43*y33+x44*y43;
      z14 = x11*y14+x12*y24+x13*y34+x14*y44;
      z24 = x21*y14+x22*y24+x23*y34+x24*y44;
      z34 = x31*y14+x32*y24+x33*y34+x34*y44;
      z44 = x41*y14+x42*y24+x43*y34+x44*y44;
     
      z11i = x11i*y11+x12i*y21+x13i*y31+x14i*y41;
      z21i = x21i*y11+x22i*y21+x23i*y31+x24i*y41;
      z31i = x31i*y11+x32i*y21+x33i*y31+x34i*y41;
      z41i = x41i*y11+x42i*y21+x43i*y31+x44i*y41;
      z12i = x11i*y12+x12i*y22+x13i*y32+x14i*y42;
      z22i = x21i*y12+x22i*y22+x23i*y32+x24i*y42;
      z32i = x31i*y12+x32i*y22+x33i*y32+x34i*y42;
      z42i = x41i*y12+x42i*y22+x43i*y32+x44i*y42;
      z13i = x11i*y13+x12i*y23+x13i*y33+x14i*y43;
      z23i = x21i*y13+x22i*y23+x23i*y33+x24i*y43;
      z33i = x31i*y13+x32i*y23+x33i*y33+x34i*y43;
      z43i = x41i*y13+x42i*y23+x43i*y33+x44i*y43;
      z14i = x11i*y14+x12i*y24+x13i*y34+x14i*y44;
      z24i = x21i*y14+x22i*y24+x23i*y34+x24i*y44;
      z34i = x31i*y14+x32i*y24+x33i*y34+x34i*y44;
      z44i = x41i*y14+x42i*y24+x43i*y34+x44i*y44;
      
      /*fill in the real part of the output matrix*/
      output1r[i*16   ] = z11*x11+z12*x12+z13*x13+z14*x14+z11i*x11i+z12i*x12i+z13i*x13i+z14i*x14i;
      output1r[i*16+1 ] = z21*x11+z22*x12+z23*x13+z24*x14+z21i*x11i+z22i*x12i+z23i*x13i+z24i*x14i;
      output1r[i*16+2 ] = z31*x11+z32*x12+z33*x13+z34*x14+z31i*x11i+z32i*x12i+z33i*x13i+z34i*x14i;
      output1r[i*16+3 ] = z41*x11+z42*x12+z43*x13+z44*x14+z41i*x11i+z42i*x12i+z43i*x13i+z44i*x14i;
      output1r[i*16+4 ] = z11*x21+z12*x22+z13*x23+z14*x24+z11i*x21i+z12i*x22i+z13i*x23i+z14i*x24i;
      output1r[i*16+5 ] = z21*x21+z22*x22+z23*x23+z24*x24+z21i*x21i+z22i*x22i+z23i*x23i+z24i*x24i;
      output1r[i*16+6 ] = z31*x21+z32*x22+z33*x23+z34*x24+z31i*x21i+z32i*x22i+z33i*x23i+z34i*x24i;
      output1r[i*16+7 ] = z41*x21+z42*x22+z43*x23+z44*x24+z41i*x21i+z42i*x22i+z43i*x23i+z44i*x24i;
      output1r[i*16+8 ] = z11*x31+z12*x32+z13*x33+z14*x34+z11i*x31i+z12i*x32i+z13i*x33i+z14i*x34i;
      output1r[i*16+9 ] = z21*x31+z22*x32+z23*x33+z24*x34+z21i*x31i+z22i*x32i+z23i*x33i+z24i*x34i;
      output1r[i*16+10] = z31*x31+z32*x32+z33*x33+z34*x34+z31i*x31i+z32i*x32i+z33i*x33i+z34i*x34i;
      output1r[i*16+11] = z41*x31+z42*x32+z43*x33+z44*x34+z41i*x31i+z42i*x32i+z43i*x33i+z44i*x34i;
      output1r[i*16+12] = z11*x41+z12*x42+z13*x43+z14*x44+z11i*x41i+z12i*x42i+z13i*x43i+z14i*x44i;
      output1r[i*16+13] = z21*x41+z22*x42+z23*x43+z24*x44+z21i*x41i+z22i*x42i+z23i*x43i+z24i*x44i;
      output1r[i*16+14] = z31*x41+z32*x42+z33*x43+z34*x44+z31i*x41i+z32i*x42i+z33i*x43i+z34i*x44i;
      output1r[i*16+15] = z41*x41+z42*x42+z43*x43+z44*x44+z41i*x41i+z42i*x42i+z43i*x43i+z44i*x44i;
      
      /*fill in the imaginary part of the output matrix*/
      output1i[i*16   ] = z11i*x11+z12i*x12+z13i*x13+z14i*x14-z11*x11i-z12*x12i-z13*x13i-z14*x14i;
      output1i[i*16+1 ] = z21i*x11+z22i*x12+z23i*x13+z24i*x14-z21*x11i-z22*x12i-z23*x13i-z24*x14i;
      output1i[i*16+2 ] = z31i*x11+z32i*x12+z33i*x13+z34i*x14-z31*x11i-z32*x12i-z33*x13i-z34*x14i;
      output1i[i*16+3 ] = z41i*x11+z42i*x12+z43i*x13+z44i*x14-z41*x11i-z42*x12i-z43*x13i-z44*x14i;
      output1i[i*16+4 ] = z11i*x21+z12i*x22+z13i*x23+z14i*x24-z11*x21i-z12*x22i-z13*x23i-z14*x24i;
      output1i[i*16+5 ] = z21i*x21+z22i*x22+z23i*x23+z24i*x24-z21*x21i-z22*x22i-z23*x23i-z24*x24i;
      output1i[i*16+6 ] = z31i*x21+z32i*x22+z33i*x23+z34i*x24-z31*x21i-z32*x22i-z33*x23i-z34*x24i;
      output1i[i*16+7 ] = z41i*x21+z42i*x22+z43i*x23+z44i*x24-z41*x21i-z42*x22i-z43*x23i-z44*x24i;
      output1i[i*16+8 ] = z11i*x31+z12i*x32+z13i*x33+z14i*x34-z11*x31i-z12*x32i-z13*x33i-z14*x34i;
      output1i[i*16+9 ] = z21i*x31+z22i*x32+z23i*x33+z24i*x34-z21*x31i-z22*x32i-z23*x33i-z24*x34i;
      output1i[i*16+10] = z31i*x31+z32i*x32+z33i*x33+z34i*x34-z31*x31i-z32*x32i-z33*x33i-z34*x34i;
      output1i[i*16+11] = z41i*x31+z42i*x32+z43i*x33+z44i*x34-z41*x31i-z42*x32i-z43*x33i-z44*x34i;
      output1i[i*16+12] = z11i*x41+z12i*x42+z13i*x43+z14i*x44-z11*x41i-z12*x42i-z13*x43i-z14*x44i;
      output1i[i*16+13] = z21i*x41+z22i*x42+z23i*x43+z24i*x44-z21*x41i-z22*x42i-z23*x43i-z24*x44i;
      output1i[i*16+14] = z31i*x41+z32i*x42+z33i*x43+z34i*x44-z31*x41i-z32*x42i-z33*x43i-z34*x44i;
      output1i[i*16+15] = z41i*x41+z42i*x42+z43i*x43+z44i*x44-z41*x41i-z42*x42i-z43*x43i-z44*x44i;
            
    }
    return;
  }
  else
  {
    for (i=0; i<numelin/16; i++)
    {
      /*matrix 1*/
      x11 = input1r[i*16   ];
      x21 = input1r[i*16+1 ];
      x31 = input1r[i*16+2 ];
      x41 = input1r[i*16+3 ];
      x12 = input1r[i*16+4 ];
      x22 = input1r[i*16+5 ];
      x32 = input1r[i*16+6 ];
      x42 = input1r[i*16+7 ];
      x13 = input1r[i*16+8 ];
      x23 = input1r[i*16+9 ];
      x33 = input1r[i*16+10];
      x43 = input1r[i*16+11];
      x14 = input1r[i*16+12];
      x24 = input1r[i*16+13];
      x34 = input1r[i*16+14];
      x44 = input1r[i*16+15];
      
      x11i = input1i[i*16   ];
      x21i = input1i[i*16+1 ];
      x31i = input1i[i*16+2 ];
      x41i = input1i[i*16+3 ];
      x12i = input1i[i*16+4 ];
      x22i = input1i[i*16+5 ];
      x32i = input1i[i*16+6 ];
      x42i = input1i[i*16+7 ];
      x13i = input1i[i*16+8 ];
      x23i = input1i[i*16+9 ];
      x33i = input1i[i*16+10];
      x43i = input1i[i*16+11];
      x14i = input1i[i*16+12];
      x24i = input1i[i*16+13];
      x34i = input1i[i*16+14];
      x44i = input1i[i*16+15];
      
      /*matrix 2*/
      y11i = input2i[i*16   ];
      y21i = input2i[i*16+1 ];
      y31i = input2i[i*16+2 ];
      y41i = input2i[i*16+3 ];
      y12i = input2i[i*16+4 ];
      y22i = input2i[i*16+5 ];
      y32i = input2i[i*16+6 ];
      y42i = input2i[i*16+7 ];
      y13i = input2i[i*16+8 ];
      y23i = input2i[i*16+9 ];
      y33i = input2i[i*16+10];
      y43i = input2i[i*16+11];
      y14i = input2i[i*16+12];
      y24i = input2i[i*16+13];
      y34i = input2i[i*16+14];
      y44i = input2i[i*16+15];
     
      y11 = input2r[i*16   ];
      y21 = input2r[i*16+1 ];
      y31 = input2r[i*16+2 ];
      y41 = input2r[i*16+3 ];
      y12 = input2r[i*16+4 ];
      y22 = input2r[i*16+5 ];
      y32 = input2r[i*16+6 ];
      y42 = input2r[i*16+7 ];
      y13 = input2r[i*16+8 ];
      y23 = input2r[i*16+9 ];
      y33 = input2r[i*16+10];
      y43 = input2r[i*16+11];
      y14 = input2r[i*16+12];
      y24 = input2r[i*16+13];
      y34 = input2r[i*16+14];
      y44 = input2r[i*16+15];
      
      z11 = (x11*y11+x12*y21+x13*y31+x14*y41)-(x11i*y11i+x12i*y21i+x13i*y31i+x14i*y41i);
      z21 = (x21*y11+x22*y21+x23*y31+x24*y41)-(x21i*y11i+x22i*y21i+x23i*y31i+x24i*y41i);
      z31 = (x31*y11+x32*y21+x33*y31+x34*y41)-(x31i*y11i+x32i*y21i+x33i*y31i+x34i*y41i);
      z41 = (x41*y11+x42*y21+x43*y31+x44*y41)-(x41i*y11i+x42i*y21i+x43i*y31i+x44i*y41i);
      z12 = (x11*y12+x12*y22+x13*y32+x14*y42)-(x11i*y12i+x12i*y22i+x13i*y32i+x14i*y42i);
      z22 = (x21*y12+x22*y22+x23*y32+x24*y42)-(x21i*y12i+x22i*y22i+x23i*y32i+x24i*y42i);
      z32 = (x31*y12+x32*y22+x33*y32+x34*y42)-(x31i*y12i+x32i*y22i+x33i*y32i+x34i*y42i);
      z42 = (x41*y12+x42*y22+x43*y32+x44*y42)-(x41i*y12i+x42i*y22i+x43i*y32i+x44i*y42i);
      z13 = (x11*y13+x12*y23+x13*y33+x14*y43)-(x11i*y13i+x12i*y23i+x13i*y33i+x14i*y43i);
      z23 = (x21*y13+x22*y23+x23*y33+x24*y43)-(x21i*y13i+x22i*y23i+x23i*y33i+x24i*y43i);
      z33 = (x31*y13+x32*y23+x33*y33+x34*y43)-(x31i*y13i+x32i*y23i+x33i*y33i+x34i*y43i);
      z43 = (x41*y13+x42*y23+x43*y33+x44*y43)-(x41i*y13i+x42i*y23i+x43i*y33i+x44i*y43i);
      z14 = (x11*y14+x12*y24+x13*y34+x14*y44)-(x11i*y14i+x12i*y24i+x13i*y34i+x14i*y44i);
      z24 = (x21*y14+x22*y24+x23*y34+x24*y44)-(x21i*y14i+x22i*y24i+x23i*y34i+x24i*y44i);
      z34 = (x31*y14+x32*y24+x33*y34+x34*y44)-(x31i*y14i+x32i*y24i+x33i*y34i+x34i*y44i);
      z44 = (x41*y14+x42*y24+x43*y34+x44*y44)-(x41i*y14i+x42i*y24i+x43i*y34i+x44i*y44i);
     
      z11i = x11i*y11+x12i*y21+x13i*y31+x14i*y41+x11*y11i+x12*y21i+x13*y31i+x14*y41i;
      z21i = x21i*y11+x22i*y21+x23i*y31+x24i*y41+x21*y11i+x22*y21i+x23*y31i+x24*y41i;
      z31i = x31i*y11+x32i*y21+x33i*y31+x34i*y41+x31*y11i+x32*y21i+x33*y31i+x34*y41i;
      z41i = x41i*y11+x42i*y21+x43i*y31+x44i*y41+x41*y11i+x42*y21i+x43*y31i+x44*y41i;
      z12i = x11i*y12+x12i*y22+x13i*y32+x14i*y42+x11*y12i+x12*y22i+x13*y32i+x14*y42i;
      z22i = x21i*y12+x22i*y22+x23i*y32+x24i*y42+x21*y12i+x22*y22i+x23*y32i+x24*y42i;
      z32i = x31i*y12+x32i*y22+x33i*y32+x34i*y42+x31*y12i+x32*y22i+x33*y32i+x34*y42i;
      z42i = x41i*y12+x42i*y22+x43i*y32+x44i*y42+x41*y12i+x42*y22i+x43*y32i+x44*y42i;
      z13i = x11i*y13+x12i*y23+x13i*y33+x14i*y43+x11*y13i+x12*y23i+x13*y33i+x14*y43i;
      z23i = x21i*y13+x22i*y23+x23i*y33+x24i*y43+x21*y13i+x22*y23i+x23*y33i+x24*y43i;
      z33i = x31i*y13+x32i*y23+x33i*y33+x34i*y43+x31*y13i+x32*y23i+x33*y33i+x34*y43i;
      z43i = x41i*y13+x42i*y23+x43i*y33+x44i*y43+x41*y13i+x42*y23i+x43*y33i+x44*y43i;
      z14i = x11i*y14+x12i*y24+x13i*y34+x14i*y44+x11*y14i+x12*y24i+x13*y34i+x14*y44i;
      z24i = x21i*y14+x22i*y24+x23i*y34+x24i*y44+x21*y14i+x22*y24i+x23*y34i+x24*y44i;
      z34i = x31i*y14+x32i*y24+x33i*y34+x34i*y44+x31*y14i+x32*y24i+x33*y34i+x34*y44i;
      z44i = x41i*y14+x42i*y24+x43i*y34+x44i*y44+x41*y14i+x42*y24i+x43*y34i+x44*y44i;
      
      /*fill in the real part of the output matrix*/
      output1r[i*16   ] = z11*x11+z12*x12+z13*x13+z14*x14+z11i*x11i+z12i*x12i+z13i*x13i+z14i*x14i;
      output1r[i*16+1 ] = z21*x11+z22*x12+z23*x13+z24*x14+z21i*x11i+z22i*x12i+z23i*x13i+z24i*x14i;
      output1r[i*16+2 ] = z31*x11+z32*x12+z33*x13+z34*x14+z31i*x11i+z32i*x12i+z33i*x13i+z34i*x14i;
      output1r[i*16+3 ] = z41*x11+z42*x12+z43*x13+z44*x14+z41i*x11i+z42i*x12i+z43i*x13i+z44i*x14i;
      output1r[i*16+4 ] = z11*x21+z12*x22+z13*x23+z14*x24+z11i*x21i+z12i*x22i+z13i*x23i+z14i*x24i;
      output1r[i*16+5 ] = z21*x21+z22*x22+z23*x23+z24*x24+z21i*x21i+z22i*x22i+z23i*x23i+z24i*x24i;
      output1r[i*16+6 ] = z31*x21+z32*x22+z33*x23+z34*x24+z31i*x21i+z32i*x22i+z33i*x23i+z34i*x24i;
      output1r[i*16+7 ] = z41*x21+z42*x22+z43*x23+z44*x24+z41i*x21i+z42i*x22i+z43i*x23i+z44i*x24i;
      output1r[i*16+8 ] = z11*x31+z12*x32+z13*x33+z14*x34+z11i*x31i+z12i*x32i+z13i*x33i+z14i*x34i;
      output1r[i*16+9 ] = z21*x31+z22*x32+z23*x33+z24*x34+z21i*x31i+z22i*x32i+z23i*x33i+z24i*x34i;
      output1r[i*16+10] = z31*x31+z32*x32+z33*x33+z34*x34+z31i*x31i+z32i*x32i+z33i*x33i+z34i*x34i;
      output1r[i*16+11] = z41*x31+z42*x32+z43*x33+z44*x34+z41i*x31i+z42i*x32i+z43i*x33i+z44i*x34i;
      output1r[i*16+12] = z11*x41+z12*x42+z13*x43+z14*x44+z11i*x41i+z12i*x42i+z13i*x43i+z14i*x44i;
      output1r[i*16+13] = z21*x41+z22*x42+z23*x43+z24*x44+z21i*x41i+z22i*x42i+z23i*x43i+z24i*x44i;
      output1r[i*16+14] = z31*x41+z32*x42+z33*x43+z34*x44+z31i*x41i+z32i*x42i+z33i*x43i+z34i*x44i;
      output1r[i*16+15] = z41*x41+z42*x42+z43*x43+z44*x44+z41i*x41i+z42i*x42i+z43i*x43i+z44i*x44i;
      
      /*fill in the imaginary part of the output matrix*/
      output1i[i*16   ] = z11i*x11+z12i*x12+z13i*x13+z14i*x14-z11*x11i-z12*x12i-z13*x13i-z14*x14i;
      output1i[i*16+1 ] = z21i*x11+z22i*x12+z23i*x13+z24i*x14-z21*x11i-z22*x12i-z23*x13i-z24*x14i;
      output1i[i*16+2 ] = z31i*x11+z32i*x12+z33i*x13+z34i*x14-z31*x11i-z32*x12i-z33*x13i-z34*x14i;
      output1i[i*16+3 ] = z41i*x11+z42i*x12+z43i*x13+z44i*x14-z41*x11i-z42*x12i-z43*x13i-z44*x14i;
      output1i[i*16+4 ] = z11i*x21+z12i*x22+z13i*x23+z14i*x24-z11*x21i-z12*x22i-z13*x23i-z14*x24i;
      output1i[i*16+5 ] = z21i*x21+z22i*x22+z23i*x23+z24i*x24-z21*x21i-z22*x22i-z23*x23i-z24*x24i;
      output1i[i*16+6 ] = z31i*x21+z32i*x22+z33i*x23+z34i*x24-z31*x21i-z32*x22i-z33*x23i-z34*x24i;
      output1i[i*16+7 ] = z41i*x21+z42i*x22+z43i*x23+z44i*x24-z41*x21i-z42*x22i-z43*x23i-z44*x24i;
      output1i[i*16+8 ] = z11i*x31+z12i*x32+z13i*x33+z14i*x34-z11*x31i-z12*x32i-z13*x33i-z14*x34i;
      output1i[i*16+9 ] = z21i*x31+z22i*x32+z23i*x33+z24i*x34-z21*x31i-z22*x32i-z23*x33i-z24*x34i;
      output1i[i*16+10] = z31i*x31+z32i*x32+z33i*x33+z34i*x34-z31*x31i-z32*x32i-z33*x33i-z34*x34i;
      output1i[i*16+11] = z41i*x31+z42i*x32+z43i*x33+z44i*x34-z41*x31i-z42*x32i-z43*x33i-z44*x34i;
      output1i[i*16+12] = z11i*x41+z12i*x42+z13i*x43+z14i*x44-z11*x41i-z12*x42i-z13*x43i-z14*x44i;
      output1i[i*16+13] = z21i*x41+z22i*x42+z23i*x43+z24i*x44-z21*x41i-z22*x42i-z23*x43i-z24*x44i;
      output1i[i*16+14] = z31i*x41+z32i*x42+z33i*x43+z34i*x44-z31*x41i-z32*x42i-z33*x43i-z34*x44i;
      output1i[i*16+15] = z41i*x41+z42i*x42+z43i*x43+z44i*x44-z41*x41i-z42*x42i-z43*x43i-z44*x44i;
            
    }
    return;
  }
}
