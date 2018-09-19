#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=Curvature
#pragma IgorVersion = 6.00


//2017.10, Curvature V2.0 by Peng Zhang, based on Rev. Sci. Instrum. 82, 043712 (2011).

//Use curv_ini() to start the panel. Or choose "Curvature Panel" in "Macros" menu.
//If it is the first time to call this panel, it will ask you to input the data name.

//The data must be in the root folder. The output data are also in the root folder,
//with names dataname+"_CV",dataname+"_CH",dataname+"_C2D",dataname+"_DV",
//dataname+"_DH", and dataname+"_D2D".

//If you put the mouse cursor on the control elements of the panel for a while,
//you will see a help message for each element. 

//You can also call Curvature(mat,num,box,choice,factor) for EDC/MDC curvature or 
//Curvature2w(mat,num,box,num2,box2,choice,factor,weight2d) for 2D curvature in your program.

//Curvature(mat,num,box,choice,factor): 
//mat is the original data. 
//(num,box) specify the smooth times and box width for boxcar smoothing method. 
//choice = 1 for EDC curvature and EDC 2nd derivative, 
//choice = 2 for MDC curvature and MDC 2nd derivative. 
//factor specifies the arbitrary factor in curvature method.
//results will be in the current folder with names nameofwave(mat)+"_CV/CH/DV/DH"

//Curvature2w(mat,num,box,num2,box2,choice,factor,weight2d)
//mat is the original data. 
//(num,box) specify the smooth times and box width along EDC direction.
//(num2,box2) specify the smooth times and box width along MDC direction.
//choice = 3 for 2D curvature and 2D 2nd derivative, 
//choice = 4 for 2D 2nd derivative, 
//factor specifies the arbitrary factor in curvature method.
//weight2d specifies the weight of the MDC curvature/2nd derivative in the calculation.
//results will be in the current folder with names nameofwave(mat)+"_C2D/D2D"


//***********************************************************************************
//********************************Curvature panel************************************
//***********************************************************************************
Menu "Macros"
	"Curvature Panel",/Q, curv_ini()
end

Function curv_ini()
	If(wintype("curv_panel"))
		dowindow/f curv_panel
		abort
	endif

	DFREF dfr=GetCurvDFREF()
	SVAR T_curv_data_STR=dfr:T_curv_data_STR
	if(strLen(T_curv_data_STR)==0)	
		string wave_name_str
		prompt wave_name_str, "Enter the wave"
		doprompt "Curvature",wave_name_str
		if(V_flag)
			abort
		endif
		curv_load_data(wave_name_str)
	endif
	Curv_Panel()
end

Static Function/DF CreateCurvData()	// Called only from GetPackageDFREF
	// Create the package data folder
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:curv_data

	// Create a data folder reference variable
	DFREF dfr = root:Packages:curv_data

	variable/g dfr:T_EDCT=2
	variable/g dfr:T_EDCW=5
	variable/g dfr:T_EDCF=.1
	variable/g dfr:t_EDCFi=.01
	variable/g dfr:T_MDCT=2
	variable/g dfr:T_MDCW=5
	variable/g dfr:T_MDCF=.1
	variable/g dfr:t_MDCFi=.01
	variable/g dfr:T_twoDF=.01
	variable/g dfr:T_twoDFi=.001
	variable/g dfr:T_twoDW=1
	variable/g dfr:T_2dUPdate=0
	string/g dfr:T_curv_data_STR=""

	return dfr
End

Static Function/DF GetCurvDFREF()
	DFREF dfr = root:Packages:curv_data
	if (DataFolderRefStatus(dfr) != 1)	// Data folder does not exist?
		DFREF dfr = CreateCurvData()	// Create package data folder
	endif
	return dfr
End

Static Function Curv_Panel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /N=curv_panel /K=1 /W=(240,478,771,630)
	ModifyPanel cbRGB=(32768,40777,65535)
	SetDrawLayer UserBack
	DrawRect 128,43,436,141
	DrawText 147,85,"EDC"
	DrawText 147,110,"MDC"
	DrawText 187,61,"St. Times"
	DrawText 264,60,"St. Width"
	DrawText 345,60,"Factor"
	DrawText 147,133,"2D"
	Button button_EDCDisp,pos={441.00,68.00},size={30.00,22.00},proc=Curvature#buttonProc_dispCurv,title="CV"
	Button button_EDCDisp,help={"Display EDC curvature."}
	Button button_MDCDisp,pos={441.00,93.00},size={30.00,22.00},proc=Curvature#buttonProc_dispCurv,title="CH"
	Button button_MDCDisp,help={"Display MDC curvature."}
	Button button_2DDisp,pos={441.00,118.00},size={33.00,22.00},proc=Curvature#buttonProc_dispCurv,title="C2D"
	Button button_2DDisp,help={"Display 2D curvature."}
	Button button_EDCDisp1,pos={481.00,68.00},size={30.00,22.00},proc=Curvature#buttonProc_dispCurv,title="DV"
	Button button_EDCDisp1,help={"Display EDC 2nd derivative."}
	Button button_MDCDisp1,pos={481.00,93.00},size={30.00,22.00},proc=Curvature#buttonProc_dispCurv,title="DH"
	Button button_MDCDisp1,help={"Display MDC 2nd derivative."}
	Button button_2DDisp1,pos={481.00,118.00},size={33.00,22.00},proc=Curvature#buttonProc_dispCurv,title="D2D"
	Button button_2DDisp1,help={"Display 2D 2nd derivative."}
	Button button_EDCDisp2,pos={441.00,41.00},size={66.00,22.00},proc=Curvature#buttonProc_dispCurv,title="Disp"
	Button button_EDCDisp2,help={"Display the raw data."}
	SetVariable setvar_EDCT,pos={195.00,70.00},size={50.00,14.00},proc=Curvature#setvarEDC,title=" "
	SetVariable setvar_EDCT help={"How many times to smooth for EDC. It will change CV, DV, C2D, and D2D. Be careful of smooth, it may change peak position. It is recommended to use as small as possible smooth factors."}
	SetVariable setvar_EDCT,limits={1,inf,1},value= root:Packages:curv_data:T_edct
	SetVariable setvar_EDCW,pos={270.00,70.00},size={50.00,14.00},proc=Curvature#setvarEDC,title=" "
	SetVariable setvar_EDCW,help={"Box width for smooth to EDC. It will change CV, DV, C2D, and D2D. . Be careful of smooth, it may change peak position. It is recommended to use as small as possible smooth factors."}
	SetVariable setvar_EDCW,limits={1,inf,2},value= root:Packages:curv_data:T_edcW
	SetVariable setvar_EDCF,pos={345.00,70.00},size={80.00,14.00},proc=Curvature#setvarEDCF,title=" "
	SetVariable setvar_EDCF,help={"Abitrary factor for EDC curvature. It will change CV."}
	SetVariable setvar_EDCF,limits={0,inf,0.01},value= root:Packages:curv_data:T_EDCF
	SetVariable setvar_MDCT,pos={195.00,95.00},size={50.00,14.00},proc=Curvature#setvarMDC,title=" "
	SetVariable setvar_MDCT,help={"How many times to smooth for MDC. It will change CH, DH, C2D, and D2D. . Be careful of smooth, it may change peak position. It is recommended to use as small as possible smooth factors."}
	SetVariable setvar_MDCT,limits={1,inf,1},value= root:Packages:curv_data:T_MdcT
	SetVariable setvar_MDCW,pos={270.00,95.00},size={50.00,14.00},proc=Curvature#setvarMDC,title=" "
	SetVariable setvar_MDCW,help={"Box width for smooth to MDC. It will change CH, DH, C2D, and D2D. . Be careful of smooth, it may change peak position. It is recommended to use as small as possible smooth factors."}
	SetVariable setvar_MDCW,limits={1,inf,2},value= root:Packages:curv_data:T_MdcW
	SetVariable setvar_MDCF,pos={345.00,95.00},size={80.00,14.00},proc=Curvature#setvarmDCF,title=" "
	SetVariable setvar_MDCF,help={"Abitrary factor for MDC curvature. It will change CH."}
	SetVariable setvar_MDCF,limits={0,inf,0.01},value= root:Packages:curv_data:T_MDCF
	SetVariable setvar_TwoDF,pos={343.00,118.00},size={80.00,14.00},proc=Curvature#setvartwoDF,title=" "
	SetVariable setvar_TwoDF,help={"Abitrary factor for 2D curvature. It will change C2D."}
	SetVariable setvar_TwoDF,limits={0,inf,1e-06},value= root:Packages:curv_data:T_twoDF
	CheckBox check_2d,pos={22.00,124.00},size={87.00,16.00},title="Auto 2D Update"
	CheckBox check_2d,help={"Auto update 2D cuvature and 2nd derivative or not."}
	CheckBox check_2d,variable= root:Packages:curv_data:T_2DUpdate
	Button button_2dCurv,pos={28.00,88.00},size={72.00,25.00},proc=Curvature#buttonProc_2dCurv,title="Update 2D"
	Button button_2dCurv,help={"When the \"Auto 2D Update\" is off, the 2D curvature and 2nd derivative will not update automatically. You need this button to manually update them."}
	Button button_data,pos={27.00,47.00},size={75.00,30.00},proc=Curvature#buttonProc_curv_data,title="DATA"
	Button button_data,help={"Use this button to input/change the data."}
	SetVariable setvar_twoDW,pos={196.00,118.00},size={125.00,14.00},proc=Curvature#setvartwodW,title=" MDC Weight"
	SetVariable setvar_twoDW help={"MDC/EDC weight for energy-momentum plot. It will change C2D and D2D. If x and y axis are the same physical quantity (such as Fermi surface plot), leave weight to 1."}
	SetVariable setvar_twoDW,value= root:Packages:curv_data:T_twodW
	SetVariable setvar_EDCT1,pos={51.00,11.00},size={143.00,18.00},proc=Curvature#setvar_curv_data,title=" Data: "
	SetVariable setvar_EDCT1,help={"The current data name. You can also change this to switch to another data, like the DATA button. Data must be in root folder."}
	SetVariable setvar_EDCT1,fSize=12
	SetVariable setvar_EDCT1,limits={1,inf,1},value= root:Packages:curv_data:T_curv_data_STR
	SetVariable setvar_config,pos={255.00,12.00},size={118.00,16.00},title="Config: "
	SetVariable setvar_config,help={"Sometimes you may need to save the parameters. This input is the name of the set of the parameters."}
	SetVariable setvar_config,fSize=10,limits={1,inf,1},value= _STR:"config0"
	Button button_EDCDisp3,pos={380.00,10.00},size={32.00,20.00},proc=Curvature#ButtonProc_curv_save,title="Save"
	Button button_EDCDisp3,help={"This button saves the current parameters with the config name."}
	Button button_EDCDisp3,fSize=10
	PopupMenu popup0,pos={425.00,11.00},size={69.00,23.00},proc=Curvature#Popup_curv_Load
	PopupMenu popup0,help={"By choosing one item, the set of the parameters with that name will be restored. _none_ does nothing."}
	PopupMenu popup0,mode=1,value= #"curvature#curv_get_list()"
End

//***********************************************************************************
static function curv_load_data(wave_name_str)
	String wave_name_str
	
	DFREF dfr=GetCurvDFREF()
	SVAR T_curv_data_STR=dfr:T_curv_data_STR

	if(waveExists($("root:"+wave_name_str))==0)
		abort "Wave does not exist in the root folder!"
	endif
	
	String old_data_name_str=T_curv_data_STR
	T_curv_data_STR=wave_name_str

	String olddx=old_data_name_str+"dx"
	String olddy=old_data_name_str+"dy"
	String olddx2=old_data_name_str+"dx2"
	String olddy2=old_data_name_str+"dy2"
	String olddydx=old_data_name_str+"dydx"

	String dv=wave_name_str+"_DV"
	String dh=wave_name_str+"_DH"
	String d2d=wave_name_str+"_D2D"
	String cv=wave_name_str+"_CV"
	String ch=wave_name_str+"_CH"
	String c2d=wave_name_str+"_C2D"
	String dx=wave_name_str+"dx"
	String dy=wave_name_str+"dy"
	String dx2=wave_name_str+"dx2"
	String dy2=wave_name_str+"dy2"
	String dydx=wave_name_str+"dydx"

	String savedDataFolder = GetDataFolder(1)
	SetDataFolder root:
	
	KillWaves/Z $olddx
	KillWaves/Z $olddy
	KillWaves/Z $olddx2
	KillWaves/Z $olddy2
	KillWaves/Z $olddydx
	Duplicate/o $wave_name_str $dv
	Duplicate/o $wave_name_str $dh
	Duplicate/o $wave_name_str $d2d
	Duplicate/o $wave_name_str $cv
	Duplicate/o $wave_name_str $ch
	Duplicate/o $wave_name_str $c2d
	Duplicate/o $wave_name_str $dx
	Duplicate/o $wave_name_str $dy
	Duplicate/o $wave_name_str $dx2
	Duplicate/o $wave_name_str $dy2
	Duplicate/o $wave_name_str $dydx
	SetDataFolder savedDataFolder

	EDCCurv()
	MDCcurv()
	twoDcurv()
end
//***********************************************************************************
static function EDCcurv()
	DFREF dfr=GetCurvDFREF()
	NVAR T_EDCT=dfr:T_EDCT
	NVAR T_EDCW=dfr:T_EDCW
	NVAR T_EDCF=dfr:T_EDCF
	SVAR T_curv_data_STR=dfr:T_curv_data_STR
	
	String savedDataFolder = GetDataFolder(1)
	SetDataFolder root:
	curvature($T_curv_data_STR,T_edct,T_edcw,1,T_edcf)
	SetDataFolder savedDataFolder
	
end

//*************
static function MDCcurv()
	DFREF dfr=GetCurvDFREF()
	NVAR T_EDCT=dfr:T_EDCT
	NVAR T_EDCW=dfr:T_EDCW
	NVAR T_EDCF=dfr:T_EDCF
	NVAR T_MDCT=dfr:T_MDCT
	NVAR T_MDCW=dfr:T_MDCW
	NVAR T_MDCF=dfr:T_MDCF
	SVAR T_curv_data_STR=dfr:T_curv_data_STR

	String savedDataFolder = GetDataFolder(1)
	SetDataFolder root:
	curvature($t_curv_data_str,T_mdct,T_mdcw,2,T_mdcf)	
	SetDataFolder savedDataFolder
	
end

//*************
static function twoDcurv()
	DFREF dfr=GetCurvDFREF()
	NVAR T_EDCT=dfr:T_EDCT
	NVAR T_EDCW=dfr:T_EDCW
	NVAR T_EDCF=dfr:T_EDCF
	NVAR T_MDCT=dfr:T_MDCT
	NVAR T_MDCW=dfr:T_MDCW
	NVAR T_MDCF=dfr:T_MDCF
	NVAR T_TwoDF=dfr:T_TwoDF
	NVAR T_TwoDW=dfr:T_TwoDW
	SVAR T_curv_data_STR=dfr:T_curv_data_STR

	String savedDataFolder = GetDataFolder(1)
	SetDataFolder root:
	curvature2w($t_curv_data_str,T_edct,T_edcw,T_mdct,T_mdcw,3,T_twoDf,T_TwoDW)	
	SetDataFolder savedDataFolder
	
end

//***********************************************************************************
static Function setvarEDC(ctrlName,varNum,varStr,varName): SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	edccurv()
	
	DFREF dfr=GetCurvDFREF()
	NVAR t_2dupdate=dfr:t_2dupdate
	if(t_2dupdate==1)
		twoDcurv()
	endif
End

//**********************
Static Function setvarEDCF(ctrlName,varNum,varStr,varName): SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	DFREF dfr=GetCurvDFREF()
	NVAR T_EDCFI=dfr:T_EDCFI
	NVAR T_EDCF=dfr:T_EDCF

	t_edcf=ceil(t_EDCF/10^(floor(log(t_EDCF)))-1e-9)*10^(floor(log(t_EDCF)))
	t_edcfi=10^(floor(log(t_EDCF)))
	if(log(t_EDCF)==round(log(t_edcf)))
		t_EDCFI/=10
	endif
	SetVariable setvar_EDCF,limits={0,inf,t_edcfi },value= T_edcF
	
	edccurv()
End

//**********************
Static Function setvarMDC(ctrlName,varNum,varStr,varName): SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	mdccurv()
	
	DFREF dfr=GetCurvDFREF()
	NVAR t_2dupdate=dfr:t_2dupdate
	if(t_2dupdate==1)
		twoDcurv()
	endif
	
End

//**********************
Static Function setvarMDCF(ctrlName,varNum,varStr,varName): SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	DFREF dfr=GetCurvDFREF()
	NVAR T_MDCFI=dfr:T_MDCFI
	NVAR T_MDCF=dfr:T_MDCF
	
	t_mdcf=ceil(t_mDCF/10^(floor(log(t_mDCF)))-1e-9)*10^(floor(log(t_mDCF)))
	t_mdcfi=10^(floor(log(t_mDCF)))
	if(log(t_mDCF)==round(log(t_mdcf)))
		t_mDCFI/=10
	endif	
	SetVariable setvar_MDCF,limits={0,inf,t_mdcfi },value= T_MdcF
	
	mdccurv()
End

//**********************
Static Function setvartwoDF(ctrlName,varNum,varStr,varName): SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	DFREF dfr=GetCurvDFREF()
	NVAR T_TwoDFI=dfr:T_TwoDFI
	NVAR T_TwoDF=dfr:T_TwoDF
	
	t_twodf=ceil(t_twodF/10^(floor(log(t_twodF)))-1e-10)*10^(floor(log(t_twodF)))
	t_twodfi=10^(floor(log(t_twodF)))
	if(log(t_twodF)==round(log(t_twodf)))
		t_twodFI/=10
	endif
	SetVariable setvar_TwoDF,limits={0,inf,t_twoDFi },value= T_twoDF
	
	twodcurv()
End

//**********************
Static Function setvartwoDW(ctrlName,varNum,varStr,varName): SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	twoDcurv()
End

//***********************************************************************************
Static Function ButtonProc_2dCurv(ctrlName) : ButtonControl
	string ctrlName
	twoDcurv()
end

//***********************************************************************************

Static Function CheckProc_2dupdate(ctrlName) : CheckBoxControl //problem!!
	string ctrlName
	
	DFREF dfr=GetCurvDFREF()
	NVAR t_2dupdate=dfr:t_2dupdate
	if(t_2dupdate==1)
		twoDcurv()
	endif
End

//***********************************************************************************
Static Function ButtonProc_curv_data(ctrlName) : ButtonControl
	string ctrlName

	string wave_name_str
	prompt wave_name_str, "Enter the wave"
	doprompt "Curvature",wave_name_str
	if(V_flag)
		abort
	endif
	curv_load_data(wave_name_str)
end

Static Function setvar_curv_data(ctrlName,varNum,varStr,varName): SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	DFREF dfr=GetCurvDFREF()
	SVAR T_curv_data_STR=dfr:T_curv_data_STR
	curv_load_data(varStr)
End

Static Function ButtonProc_dispData(ctrlName) : ButtonControl
	string ctrlName

	DFREF dfr=GetCurvDFREF()
	SVAR T_curv_data_STR=dfr:T_curv_data_STR
	string data=t_curv_data_str
	disp($data)
end 

Static Function ButtonProc_dispCurv(ctrlName) : ButtonControl
	string ctrlName
	
	ControlInfo $ctrlName
	String button_title=StringFromList(1,s_recreation,"\"")
	
	DFREF dfr=GetCurvDFREF()
	SVAR T_curv_data_STR=dfr:T_curv_data_STR
	if(cmpStr(Button_title,"Disp")==0)	
		disp($("root:"+T_curv_data_STR))
	else
		string data="root:"+t_curv_data_str+"_"+button_title
		idisp($data)
	endif
end

//***********************************************************************************
Static Function ButtonProc_curv_save(ctrlName) : ButtonControl
	String ctrlName
	
	controlInfo setvar_config
	String panel_name="curv_panel"
	String srcFolderStr="root:packages:curv_data"
	String config_name=s_value
	
	String this_config_folder="root:packages:config_save:"+panel_name+":"+config_name
	if(DataFolderExists(this_config_folder)==1 && cmpstr(config_name,"last")!=0)
		doalert 1, "Config exists. Do you want to overwrite?"
		if (v_flag!=1)
			abort
		endif
		KillDataFolder $this_config_folder
		DuplicateDataFolder $srcFolderStr $this_config_folder
	else
		NewDataFolder/o root:packages
		NewDataFolder/o root:packages:config_save
		NewDataFolder/o root:packages:config_save:$panel_name
		if(DataFolderExists(this_config_folder)==1)
			killDataFolder $this_config_folder
		endif
		DuplicateDataFolder $srcFolderStr $this_config_folder
	endif
End

Static Function Popup_curv_Load(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr	

	String panel_name="curv_panel"
	String panel_data_folder="root:packages:curv_data:"
	String config_name=popstr
	
	if (cmpStr(config_name,"_none_")==0)
		abort
	endif
	string config_folder="root:packages:config_save:"+panel_name+":"+config_name+":"
	//update strings
	String StringsInFolder=StringByKey("Strings",DataFolderDir(8,$config_folder))
	Variable amount=ItemsInList(StringsInFolder,",")
	Variable i
	String str_name
	String str_name0
	For(i=0;i<amount;i+=1)
		str_name=config_folder+StringFromList(i,StringsInFolder,",")
		str_name0=panel_data_folder+StringFromList(i,StringsInFolder,",")
		SVAR str_config=$str_name
		SVAR str_origin=$str_name0
		str_origin=str_config
	endfor
	//update variables
	String VariablesInFolder=StringByKey("Variables",DataFolderDir(4,$config_folder))
	amount=ItemsInList(VariablesInFolder,",")
	String var_name
	String var_name0
	For(i=0;i<amount;i+=1)
		var_name=config_folder+StringFromList(i,VariablesInFolder,",")
		var_name0=panel_data_folder+StringFromList(i,VariablesInFolder,",")
		NVAR var_config=$var_name
		NVAR var_origin=$var_name0
		var_origin=var_config
	endfor
	//update waves
	String WavesInFolder=StringByKey("Waves",DataFolderDir(2,$config_folder))
	amount=ItemsInList(WavesInFolder,",")
	String wave_name
	String wave_name0
	For(i=0;i<amount;i+=1)
		wave_name=config_folder+StringFromList(i,wavesInFolder,",")
		wave_name0=panel_data_folder+StringFromList(i,wavesInFolder,",")
		duplicate/o $wave_name $wave_name0
	endfor

	DFREF dfr=GetCurvDFREF()
	SVAR T_curv_data_STR=dfr:T_curv_data_STR
	curv_load_data(T_curv_data_STR)
end

Static Function/S curv_get_list()
	String panel_name="curv_panel"
	String panel_folder="root:packages:config_save:"+panel_name
	if(DataFolderExists(panel_folder)==0)
		return "_none_"
	endif
	String DataFolderList=StringByKey("Folders",DataFolderDir(1,$panel_folder))
	String config_List=ReplaceString(",",DataFolderList,";")
	return Config_List+";_none_"

End

//***********************************************************************************
function disp(mat) //disp a matrix
	wave mat
	string graphname,wavenam
	wavenam=nameofwave(mat)
	graphname=nameofwave(mat)+"_plot"
	
	if(wintype(graphname)==1)
		dowindow/f $graphname
	else
		display/n=$graphname; appendimage mat
		Showinfo	
		ModifyImage $wavenam,ctab= {*,*,Terrain,1}
	endif
end

function idisp(mat)
	wave mat
	string graphname,wavenam
	wavenam=nameofwave(mat)
	graphname=nameofwave(mat)+"_plot"
	
	if(wintype(graphname)==1)
		dowindow/f $graphname
	else
		display/n=$graphname; appendimage mat
		Showinfo	
		ModifyImage $wavenam,ctab= {*,0,Terrain,1}
	endif
end

//***********************************************************************************
Function DM1(oldM,newM,num,box,choice)
	wave oldM,newM
	variable num,box,choice
	newM=oldM
	
	if(choice==1)			//energy direction, col---df/dE
		Smooth/DIM=1/E=3/B=(num) box,newM
		Differentiate/DIM=1 newM			
				
	elseif(choice==2)		//k direction, row --- df/dk
		Smooth/DIM=0/E=3/B=(num) box,newM
		Differentiate/DIM=0 newM		
			
	endif
End

Function DM2(oldM,newM,num,box,choice)
	wave oldM,newM
	variable num,box,choice
	newM=oldM
	
	if(choice==1)			//energy direction, col---d2f/dE2
		Smooth/DIM=1/E=3/B=(num) box,newM
		Differentiate/DIM=1 newM			
		Differentiate/DIM=1 newM	
				
	elseif(choice==2)		//k direction, row --- d2f/dk2
		Smooth/DIM=0/E=3/B=(num) box,newM
		Differentiate/DIM=0 newM			
		Differentiate/DIM=0 newM
		
	elseif(choice==4)		//energy + k, ---- d2f/dkdE
		Smooth/DIM=1/E=3/B=(num) box,newM
		Differentiate/DIM=1 newM		
		Smooth/DIM=0/E=3/B=(num) box,newM
		Differentiate/DIM=0 newM	
	
	elseif(choice==5)		//k + energy, ---- d2f/dEdk
		Smooth/DIM=0/E=3/B=(num) box,newM
		Differentiate/DIM=0 newM		
		Smooth/DIM=1/E=3/B=(num) box,newM
		Differentiate/DIM=1 newM	
	
	endif
End

function Curvature(mat,num,box,choice,factor) //curvature. choice = 1 for EDC, 2 for MDC
	wave mat
	variable num,box,choice,factor
	string diff1mat,diff2mat,matcurv,matderiv
	variable avg,avgv,avgh
	if(choice==1)
		matcurv=nameofwave(mat)+"_CV"
		diff1mat=nameofwave(mat)+"dy"; diff2mat=nameofwave(mat)+"dy2"
		matderiv=nameofwave(mat)+"_DV"
		if(waveExists($matcurv)==0)
			duplicate/o mat $matcurv
		endif
		if(waveExists($diff1mat)==0)
			duplicate/o mat $diff1mat,$diff2mat
		endif
		if(waveExists($matderiv)==0)
			duplicate/o mat $matderiv
		endif
			
		DM1(mat,$diff1mat,num,box,1)
		DM1($diff1mat,$diff2mat,1,1,1)
		//DM2(mat,$diff2mat,num,box,1)

		wave T_diff1mat=$diff1mat
		wave T_diff2mat=$diff2mat
		wave curvatureV = $matcurv
		avg=abs(wavemin($diff1mat))
		curvatureV=T_diff2mat/(avg*avg*factor+T_diff1mat*T_diff1mat)^1.5
		
		wave derivV=$matderiv
		derivV=T_diff2mat
	endif
	
	if(choice==2)
		matcurv=nameofwave(mat)+"_CH"
		diff1mat=nameofwave(mat)+"dx"; diff2mat=nameofwave(mat)+"dx2"
		matderiv=nameofwave(mat)+"_DH"
		if(waveExists($matcurv)==0)
			duplicate/o mat $matcurv
		endif
		if(waveExists($diff1mat)==0)
			duplicate/o mat $diff1mat,$diff2mat
		endif
		if(waveExists($matderiv)==0)
			duplicate/o mat $matderiv
		endif

		DM1(mat,$diff1mat,num,box,2)
		DM1($diff1mat,$diff2mat,1,1,2)

		wave T_diff1mat=$diff1mat
		wave T_diff2mat=$diff2mat
		wave curvatureH = $matcurv
		avg=abs(wavemin($diff1mat))
		curvatureH=T_diff2mat/(avg*avg*factor+T_diff1mat*T_diff1mat)^1.5

		wave derivH=$matderiv
		derivH=T_diff2mat
	endif
end

function curvature2w(mat,num,box,num2,box2,choice,factor,weight2d) // choice are 3 and 4. 3 for curvature 2D and 2nd derive 2D, 4 for 2nd deriv 2D only.
	wave mat
	variable num,box,num2,box2,choice,factor,weight2d
	string diff1maty,diff2maty,diff1matx,diff2matx,diff2matyx
	String matcurv,graphcurv,matderiv
	variable avg,avgv,avgh
	variable dx,dy,weight
	dx=dimdelta(mat,0)
	dy=dimdelta(mat,1)
	weight=(dx/dy)*(dx/dy)

	if(choice==3)
		matcurv=nameofwave(mat)+"_C2D"
		diff1maty=nameofwave(mat)+"dy"; diff2maty=nameofwave(mat)+"dy2"
		diff1matx=nameofwave(mat)+"dx"; diff2matx=nameofwave(mat)+"dx2"
		diff2matyx=nameofwave(mat)+"dy"+"dx"
		matderiv=nameofwave(mat)+"_D2D"
		if(waveExists($diff1maty)==0)
			duplicate/o mat $diff1maty,$diff2maty
		endif
		if(waveExists($diff1matx)==0)
			duplicate/o mat $diff1matx,$diff2matx
		endif
		if(waveExists($diff2matyx)==0)
			duplicate/o mat $diff2matyx
		endif
		if(waveExists($matcurv)==0)
			duplicate/o mat $matcurv
		endif
		if(waveExists($matderiv)==0)
			duplicate/o mat $matderiv
		endif
		
		DM1(mat,$diff1maty,num,box,1)
		DM1($diff1maty,$diff2maty,1,1,1)
		avgv=abs(wavemin($diff1maty))
		
		DM1(mat,$diff1matx,num2,box2,2)
		DM1($diff1matx,$diff2matx,1,1,2)
		avgh=abs(wavemin($diff1matx))

		DM1($diff1maty,$diff2matyx,num2,box2,2)

		wave T_diff1matV=$diff1maty
		wave T_diff2matV=$diff2maty
		wave T_diff1matH=$diff1matx
		wave T_diff2matH=$diff2matx
		wave T_diff2matVH=$diff2matyx
		wave curvature2D=$matcurv
		if(weight2d>0)
			weight*=weight2d
		endif
		if(weight2d<0)
			weight/=abs(weight2d)
		endif
		avg=max(avgv*avgv,weight*avgh*avgh)
		curvature2D=((factor*avg+weight*t_diff1math*t_diff1math)*t_diff2matv-2*weight*t_diff1math*t_diff1matv*t_diff2matvh+weight*(factor*avg+t_diff1matv*t_diff1matv)*t_diff2math)/(factor*avg+weight*t_diff1math*t_diff1math+t_diff1matv*t_diff1matv)^1.5
		
		wave Deriv2D=$matderiv
		Deriv2D=t_diff2matV+t_diff2matH*weight
	endif
	
	if(choice==4)
		matderiv=nameofwave(mat)+"_D2D"
		diff2maty=nameofwave(mat)+"dy2"
		diff2matx=nameofwave(mat)+"dx2"
		if(waveExists($diff2maty)==0)
			duplicate/o mat $diff2maty
		endif
		if(waveExists($diff2matx)==0)
			duplicate/o mat $diff2matx		
		endif
		if(waveExists($matderiv)==0)
			duplicate/o mat $matderiv
		endif
		
		DM2(mat,$diff2maty,num,box,1)
		DM2(mat,$diff2matx,num,box,2)

		wave T_diff2matV=$diff2maty
		wave T_diff2matH=$diff2matx
		wave Deriv2D=$matderiv
		if(weight2d>0)
			weight*=weight2d
		endif
		if(weight2d<0)
			weight/=abs(weight2d)
		endif
		Deriv2D=t_diff2matV+t_diff2matH*weight
		
	endif
end
//***********************************************************************************
//***********************************************************************************

