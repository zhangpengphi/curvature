# Usage of the panel
Open the Curvature.ipf file in Igor pro, and compile. Use curv_ini() to start the panel. Or choose "Curvature Panel" in "Macros" menu. If it is the first time to call this panel, it will ask you to input the data name.

The data must be in the root folder. The output data are also in the root folder,
with names dataname + "_CV", dataname + "_CH", dataname + "_C2D", dataname + "_DV", dataname + "_DH", and dataname + "_D2D".

If you put the mouse cursor on the control elements of the panel for a while,
you will see a help message for each element. 


You can also call Curvature(mat,num,box,choice,factor) for EDC/MDC curvature or Curvature2w(mat,num,box,num2,box2,choice,factor,weight2d) for 2D curvature in your program.

## Curvature(mat,num,box,choice,factor): 
mat is the original data,   
(num,box) specify the smooth times and box width for boxcar smoothing method,   
choice = 1 for EDC curvature and EDC 2nd derivative,   
choice = 2 for MDC curvature and MDC 2nd derivative,   
factor specifies the arbitrary factor in curvature method.  
   
Results will be in the current folder with names nameofwave(mat) + "_CV/CH/DV/DH".  

## Curvature2w(mat,num,box,num2,box2,choice,factor,weight2d)
mat is the original data,   
(num,box) specify the smooth times and box width along EDC direction,   
(num2,box2) specify the smooth times and box width along MDC direction,   
choice = 3 for 2D curvature and 2D 2nd derivative,   
choice = 4 for 2D 2nd derivative,   
factor specifies the arbitrary factor in curvature method,   
weight2d specifies the weight of the MDC curvature/2nd derivative in the calculation.   
   
Results will be in the current folder with names nameofwave(mat) + "_C2D/D2D".
   
   
This macro is written by Peng Zhang, based on [Rev. Sci. Instrum. 82, 043712 (2011)](https://doi.org/10.1063/1.3585113), *"A precise method for visualizing dispersive features in image plots"*.