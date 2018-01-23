#Ifdef ARrtGlobals
#pragma rtGlobals=1        // Use modern global access method.
#else
#pragma rtGlobals=3        // Use strict wave reference mode
#endif 
#pragma ModuleName=MainPanel
Menu "Second Harmonic"
	"Measure Curves", SecondHarmonic_Initialize()
End

Function SecondHarmonic_Initialize()
	
	// Make data folder to hold variables
	if (datafolderexists("Root:Variables") == 0)
		NewDataFolder Root:Variables
	endif

	cd "Root:Variables"

	String/G foldername = "SecondHarm"
	String/G exptbasename = "Tune"
	Variable/G firstspot = 0
	Variable/G lastspot = 0
	Variable/G centerfreq_input = 300
	Variable/G centerfreqL_input = 800
	Variable/G FittWidth_input=100
	Variable/G Tunetime_input=3
	Variable/G driveamp_input = 1
	Variable/G centerfreq
	Variable/G centerfreqL
	Variable/G driveamp
	Variable/G currentspot
	Variable/G currentvolt
	Variable/G Vincr=0 
	Variable/G MHarm1=1 
	Variable/G MHarm2=2 
	Variable/G involsconvert = GV("AmpInvOLS") // units of nm/V

	String/G processfolder = "SecondHarm"
	String/G basename = "Tune"
	String/G typeharm
	Variable/G freqfitwidth = 90
	Variable/G firstpoint = 0
	Variable/G lastpoint = 0
	Variable/G plotpoint = 0
	Variable/G incrmvolt=.2
	Variable/G stopvolt=3
	Execute "SecondHarmonicPanel()"

End

Window SecondHarmonicPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(930,166,1314,547)
	ShowTools/A
	SetDrawLayer UserBack
	DrawLine 17,245,363,245
	SetVariable foldername_setvar,pos={8,34},size={194,16},bodyWidth=97,title="Name of data folder"
	SetVariable foldername_setvar,value= root:Variables:foldername
	SetVariable exptbasename_setvar,pos={228,35},size={151,16},bodyWidth=97,title="Basename"
	SetVariable exptbasename_setvar,value= root:Variables:exptbasename
	SetVariable firstspot_setvar,pos={15,69},size={160,16},title="First Spot"
	SetVariable firstspot_setvar,value= root:Variables:firstspot
	SetVariable lastspot_setvar,pos={209,68},size={138,16},title="Last Spot"
	SetVariable lastspot_setvar,value= root:Variables:lastspot
	SetVariable driveampinput_setvar,pos={0,101},size={142,16},bodyWidth=50,title="Drive Amp start (V)"
	SetVariable driveampinput_setvar,value= root:Variables:driveamp_input
	SetVariable incrmvolt_setvar,pos={149,101},size={106,16},bodyWidth=50,title="Increments"
	SetVariable incrmvolt_setvar,value= root:Variables:incrmvolt
	SetVariable stopvolt_setvar,pos={273,101},size={73,16},bodyWidth=50,title="End"
	SetVariable stopvolt_setvar,value= root:Variables:stopvolt
	SetVariable centerfreqinput_setvar,pos={0,130},size={217,16},bodyWidth=60,title="Center Frequency (kHz)  Vertical"
	SetVariable centerfreqinput_setvar,value= root:Variables:centerfreq_input
	SetVariable centerfreqinputl_setvar,pos={242,130},size={96,16},bodyWidth=60,title="Lateral"
	SetVariable centerfreqinputl_setvar,value= root:Variables:centerfreql_input
	SetVariable MHarm1_setvar,pos={42,180},size={175,16},bodyWidth=60,title="Measured Harmonic #1"
	SetVariable MHarm1_setvar,value= root:Variables:MHarm1
	SetVariable MHarm2_setvar,pos={261,180},size={77,16},bodyWidth=60,title="#2"
	SetVariable MHarm2_setvar,value= root:Variables:MHarm2
	Button SecondHarmonic_button,pos={162,202},size={110,40},proc=SecondHarmonic_button,title="Measure Curves"
	SetVariable processfolder_setvar,pos={20,267},size={253,16},bodyWidth=121,title="Data folder to process data"
	SetVariable processfolder_setvar,value= root:Variables:processfolder
	Button LoadSecondHarmonic_button,pos={289,263},size={63,23},proc=LoadSecondHarmonic_button,title="Load Data"
	SetVariable basename_setvar,pos={17,328},size={150,16},bodyWidth=96,title="Basename"
	SetVariable basename_setvar,value= root:Variables:basename
	SetVariable firstpoint_setvar,pos={187,312},size={88,16},bodyWidth=38,title="First Point"
	SetVariable firstpoint_setvar,value= root:Variables:firstpoint
	SetVariable lastpoint_setvar,pos={187,335},size={88,16},bodyWidth=37,title="Last Point"
	SetVariable lastpoint_setvar,value= root:Variables:lastpoint
	Button ProcessHarmonics_button,pos={291,320},size={81,29},proc=ProcessHarmonics_button,title="Process Data"
	SetVariable Fit_setvar1,pos={12,157},size={145,16},bodyWidth=60,title="Tune width (kHz)"
	SetVariable Fit_setvar1,value= root:Variables:FittWidth_input
	SetVariable tunetime_setvar2,pos={204,156},size={137,16},bodyWidth=60,title="Tune time (sec)"
	SetVariable tunetime_setvar2,value= root:Variables:Tunetime_input
	Button Stop_button1,pos={4,199},size={110,40},proc=Stop_button,title="STOP"
	Button Stop_button1,fColor=(39168,0,0)
EndMacro

Function Stop_button(ctrlName) : ButtonControl //STOP

	String ctrlName // currently a string variable not used
	NVAR Vincr = root:Variables:Vincr
	NVAR DoNXTune =root:Packages:MFP3D:Tune:DoNXTune

	ARCheckFunc("DontChangeXPTCheck",0)//  unlock cross point
	ARCheckFunc("ARUserCallbackMasterCheck_1",0) // Turn off callbacks on tune
	ARExecuteControl("StopScan_0", "MasterPanel", 0, "") // Withdraw	
	DoNXTune = 0	// turn on harmonic measurmennts // 1 to turn on  N X tuning, 0 for off
	Vincr=0
	beep
	print "STOPED"

END
// This is the first function that will be run when the "measure curves" button is pressed
Function SecondHarmonic_button(ctrlName) : ButtonControl

	String ctrlName // currently a string variable not used
	// Declare all global variables used in this function
	SVAR foldername = root:Variables:foldername
	NVAR Vincr = root:Variables:Vincr
	NVAR firstspot = root:Variables:firstspot
	NVAR lastspot = root:Variables:lastspot
	NVAR centerfreq_input = root:Variables:centerfreq_input
	NVAR centerfreql_input = root:Variables:centerfreql_input
	NVAR driveamp_input = root:Variables:driveamp_input
	NVAR centerfreq = root:Variables:centerfreq
	NVAR centerfreqL = root:Variables:centerfreqL
	NVAR driveamp = root:Variables:driveamp
	NVAR currentspot = root:Variables:currentspot
	NVAR currentvolt = root:Variables:currentvolt
	NVAR DoNXTune =root:Packages:MFP3D:Tune:DoNXTune
	NVAR centerfreq = root:Variables:centerfreq
	NVAR currentvolt = root:Variables:currentvolt
	NVAR stopvolt = root:Variables:stopvolt
	NVAR incrmvolt = root:Variables:incrmvolt
	NVAR FittWidth_input = root:Variables:FittWidth_input
	NVAR Tunetime_input = root:Variables:Tunetime_input
	SVAR exptbasename = root:variables:exptbasename
	String/G exptbasenameFreq=exptbasename+"Freq"
	String/G exptbasenameAmp=exptbasename+"Amp"
	String/G exptbasenamePhase=exptbasename+"Phase"
	
	Variable Tunetime,stepsV, numpAmp
	
	Variable/G widthfreq
	//NVAR driveamp = root:Variables:driveamp
	// Convert input frequency and drive amps into frequency in kHz, and amplitude before going through high voltage amplifier
	centerfreq = centerfreq_input*1000
	centerfreql = centerfreql_input*1000
	widthfreq=FittWidth_input*1000
	currentvolt = driveamp_input //for high voltage unit, devide by 22
	currentspot = firstspot
	
	Tunetime=Tunetime_input
	ARCheckFunc("DualACModeBox_3",1) // tunr dual AC on	
	
	
	ARExecuteControl("DualACModeBox_3", "MasterPanel",1,"") // turn dual AC on
	sleep/s 2
	
	ARExecuteControl("DoTuneOnce_3", "MasterPanel", 0, "")  // run one tune
	sleep/s 2
	
	numpAmp=numpnts(root:packages:MFP3D:Tune:Amp) //this is the number of data points in one tune!
	print "numpAmp" ,numpAmp

	// for this to work, you should have the modified version of thermal.ipf file in place  (ehsan's modification)
	 
	DoNXTune = 1	// turn on harmonic measurmennts // 1 to turn on  N X tuning, 0 for off
	Vincr=0	// this is the increment counter for drive amplitude.let's start with zero, fresh and easy!
	// Make new folder from the name selected and place in root
	String folder_path = "root:" + foldername
	if (datafolderexists(folder_path) == 0)
		NewDataFolder/O $folder_path
	endif

	cd folder_path
	
	stepsV=round((stopvolt- driveamp_input)/incrmvolt)+2
	Make/O/N=(lastspot+1,stepsV, 14) $exptbasename=NaN
	// i=vector data of tuning, j=step in voltage, k=location, l=[V1,V2,L1,L2]
	Make/O/N=(numpAmp,stepsV,lastspot+1, 4) $exptbasenameAmp=NaN
	Make/O/N=(numpAmp,stepsV,lastspot+1, 4) $exptbasenameFreq=NaN
	Make/O/N=(numpAmp,stepsV,lastspot+1, 4) $exptbasenamePhase=NaN

	
	// Turn on callbacks
	ARCheckFunc("ARUserCallbackMasterCheck_1", 1) //Master callback on
	ARCheckFunc("ARUserCallbackStopCheck_1", 1)  // withdraw callback
	ARCheckFunc("ARUserCallbackGoToSpotCheck_1", 1) // go to spot
	
	ARCheckFunc("ARUserCallbackTuneCheck_1",1)// tune call back

	ARExecuteControl("TuneTimeSetVar_3", "MasterPanel",Tunetime, "S") // tune time is deifned 	
	ARExecuteControl("SweepWidthSetVar_3", "MasterPanel", widthfreq, "Hz") // sweep width widthfreq Hz	
	// filter frequency to 500Hz
	//PV("Lockin.0.Filter.Freq",500)		
	//PV("Lockin.1.Filter.Freq",500)
	//ARCheckFunc("ForceFilterBox",1)//  lock filter
	// Make sure probe is withdrawn before attempting to move spots
	PV("ForcespotNumber", firstspot)
	PDS("ARUserCallbackStop", "GotoPoint()")   // "ARUserCallbackStop" is the call back for "Withdraw". We associate "GotoPoint()" with withdraw, after each withdraw, gotopoint() will be perfromed.
	ARExecuteControl("StopScan_0", "MasterPanel", 0, "") // Withdraw
	//in the above code we turned on 2 callbacks (withdraw, go to spot), we associate withdraw with GoToPoint(), and then we withdraw. After the withdraw is completed, GotoPoint() will be run.
End

Function GotoPoint()
	NVAR firstspot = root:Variables:firstspot
	NVAR lastspot = root:Variables:lastspot
	NVAR currentspot = root:Variables:currentspot
	NVAR MHarm1 = root:Variables:MHarm1
	NVAR currentvolt = root:Variables:currentvolt
	NVAR centerfreq = root:Variables:centerfreq
	NVAR DoNXTune =root:Packages:MFP3D:Tune:DoNXTune
	NVAR centerfreqL = root:Variables:centerfreqL	
	SVAR exptbasename = root:variables:exptbasename	
	NVAR Vincr = root:Variables:Vincr
	Wave savewave = $exptbasename	// First time running		
	SVAR exptbasenameAmp = root:variables:exptbasenameAmp
	SVAR exptbasenamePhase = root:variables:exptbasenamePhase
	SVAR exptbasenameFreq = root:variables:exptbasenameFreq

	if (currentspot == firstspot)
		ARExecuteControl("DriveAmplitudeSetVar_3", "MasterPanel",0,"V") // set drive amplitude1
		ARExecuteControl("DriveAmplitude1SetVar_3", "MasterPanel",currentvolt,"V") // set drive amplitude2
		ARExecuteControl("DriveFrequencySetVar_3", "MasterPanel",centerfreq,"Hz") // set center freq 1		
		ARExecuteControl("FrequencyRatioSetVar_3", "MasterPanel",1/MHarm1,"")  // measuring "MHarm1" harmonic of Deflection signa	
		PV("ForcespotNumber", currentspot)
		// cross point setting
ARExecuteControl("InFastPopup", "crosspointpanel",0,"ACdefl")//put InFast on ACDefl 
		ARCheckFunc("DontChangeXPTCheck",1)//  lock cross point
		ARExecuteControl("WriteXPT", "crosspointpanel",0,"Write Crosspoint")//write corsspoint
		ARExecuteControl("FrequencyRatioSetVar_3", "MasterPanel",1/MHarm1,"")  // measuring "MHarm1" harmonic of Deflection signa
		if (vincr==0)
				PDS("ARUserCallbackGoToSpot", " tunev1()")	//associates tuneARv() with "go to point". //vertical tune
				ARExecuteControl("GoForce_2", "MasterPanel", 0, "")  // run go there and after that run tuneAR()
		else
			PDS("ARUserCallbackTune", " tuneARv()")	//associates tuneARv() with "tune". //vertical tune
			ARExecuteControl("DoTuneOnce_3", "MasterPanel", 0, "")  // run one tune and after that run tuneAR()		
		endif 		
	endif
	
	if (currentspot > firstspot && currentspot <= lastspot)
				ARExecuteControl("DriveAmplitudeSetVar_3", "MasterPanel",0,"V") // set drive amplitude1
				ARExecuteControl("DriveAmplitude1SetVar_3", "MasterPanel",currentvolt,"V") // set drive amplitude2
				ARExecuteControl("DriveFrequencySetVar_3", "MasterPanel",centerfreq,"Hz") // set center freq 1		
				ARExecuteControl("FrequencyRatioSetVar_3", "MasterPanel",1/MHarm1,"")  // measuring "MHarm1" harmonic of Deflection signa	
				PV("ForcespotNumber", currentspot)
				PDS("ARUserCallbackGoToSpot", " tunev1()")	//associates tunev1() with "go to point". //vertical tune
				ARExecuteControl("GoForce_2", "MasterPanel", 0, "")  // run go there and after that run tuneAR()
	endif
	
	if (currentspot > lastspot)
		ARExecuteControl("DriveFrequencySetVar_3", "MasterPanel",centerfreqL,"Hz") // set center freq 1		
		ARCheckFunc("DontChangeXPTCheck",0)//  unlock cross point
		ARCheckFunc("ARUserCallbackMasterCheck_1",0) // Turn off callbacks on tune
		ARExecuteControl("StopScan_0", "MasterPanel", 0, "") // Withdraw	
		//DoNXTune = 0	// turn off harmonic measurmennts // 1 to turn on  N X tuning, 0 for off
		Save/O/C/P=SaveImage $exptbasename			
		Save/O/C/P=SaveImage $exptbasenameAmp			
		Save/O/C/P=SaveImage $exptbasenameFreq			
		Save/O/C/P=SaveImage $exptbasenamePhase			
			
		beep
		print "done"
	endif
End


function tunev1() //run the tune V 1
	PDS("ARUserCallbackTune", " tuneARv()")	//associates tuneARv2() with "tune". //vertical  tune #2harm
	ARExecuteControl("DoTuneOnce_3", "MasterPanel", 0, "")  // run one tune and after that run tuneAR()
End



Function tuneARv() //vertical  tune #1 harm

	NVAR MHarm2 = root:Variables:MHarm2	
	NVAR Vincr = root:Variables:Vincr
	NVAR currentspot = root:Variables:currentspot
	NVAR involsconvert = root:Variables:involsconvert
	SVAR exptbasename = root:variables:exptbasename
	SVAR typeharm = root:variables:typeharm
		Wave savewave = $exptbasename	// First time running			savewave[currentspot][Vincr][0] = GV("TuneQResult")
	SVAR exptbasenameAmp = root:variables:exptbasenameAmp
	SVAR exptbasenamePhase = root:variables:exptbasenamePhase
	SVAR exptbasenameFreq = root:variables:exptbasenameFreq
	Wave savewaveAmp = $exptbasenameAmp	// First time running			
	Wave savewaveFreq= $exptbasenameFreq	// First time running			
	Wave savewavePhase = $exptbasenamePhase	// First time running			
	Wave dumAmp=root:packages:MFP3D:Tune:Amp
	Wave dumPhase=root:packages:MFP3D:Tune:Phase
	Wave dumFreq=root:packages:MFP3D:Tune:frequency

	 typeharm="ARV"

	savewaveAmp[][Vincr][currentspot][0]=dumAmp[p]
	savewaveFreq[][Vincr][currentspot][0] =dumFreq[p]
	savewavePhase[][Vincr][currentspot][0] =dumPhase[p]
	
//	if ( isnan(GV("TuneQResult"))==1||GV("TuneQResult")<20)// if the AR Q=NaN then use NaN for all, if not use my code to fit 
//		savewave[currentspot][Vincr][0]=nan
//		savewave[currentspot][Vincr][1]=nan
//		savewave[currentspot][Vincr][2] =nan
//				print "ARV failed"
//		//print  "Q<20 or Q=NaN"
//		
//	else
//		TuneFit_General("root:packages:mfp3d:tune:amp", "root:packages:MFP3D:Tune:frequency") 
//		wave coeffs
//		savewave[currentspot][Vincr][0] =coeffs[2]
//		savewave[currentspot][Vincr][1] =coeffs[0]
//		savewave[currentspot][Vincr][2] =coeffs[1]*involsconvert //convert the amplitude [voltage] to amplitude [meter]		
//		removefromgraph fit_amp 
//	endif 
	
	
	//saving the real tune data

	
	//savewave[currentspot][Vincr][0] = GV("TuneQResult")
	//savewave[currentspot][Vincr][1] = GV("TuneFreqResult")
	//savewave[currentspot][Vincr][2] = GV("TunePeakResult")*involsconvert
	// getting prepared for tuneARv2()
	
	ARExecuteControl("FrequencyRatioSetVar_3", "MasterPanel",1/MHarm2,"")  // measuring "MHarm2" harmonic of Deflection signa	
	PDS("ARUserCallbackTune", " tuneARv2()")	//associates tuneARv2() with "tune". //vertical  tune #2harm
	ARExecuteControl("DoTuneOnce_3", "MasterPanel", 0, "")  // run one tune and after that run tuneAR()
END

Function tuneARv2() //Vertical  tune  #2harm
	SVAR typeharm = root:variables:typeharm
	SVAR state=root:packages:mfp3d:xpt:state
	NVAR MHarm1 = root:Variables:MHarm1
	NVAR centerfreqL = root:Variables:centerfreqL	
	NVAR Vincr = root:Variables:Vincr
	NVAR currentspot = root:Variables:currentspot
	NVAR involsconvert = root:Variables:involsconvert
	SVAR exptbasename = root:variables:exptbasename	
	Wave savewave = $exptbasename	// First time running			savewave[currentspot][Vincr][3] = GV("TuneQResult")
	SVAR exptbasenameAmp = root:variables:exptbasenameAmp
	SVAR exptbasenamePhase = root:variables:exptbasenamePhase
	SVAR exptbasenameFreq = root:variables:exptbasenameFreq
	Wave savewaveAmp = $exptbasenameAmp	// First time running			
	Wave savewaveFreq= $exptbasenameFreq	// First time running			
	Wave savewavePhase = $exptbasenamePhase	// First time running			
	Wave dumAmp=root:packages:MFP3D:Tune:Amp
	Wave dumPhase=root:packages:MFP3D:Tune:Phase
	Wave dumFreq=root:packages:MFP3D:Tune:frequency
	
	 typeharm="ARV2"

		//saving the real tune data
	savewaveAmp[][Vincr][currentspot][1]=dumAmp[p]
	savewaveFreq[][Vincr][currentspot][1] =dumFreq[p]
	savewavePhase[][Vincr][currentspot][1]=dumPhase[p]

//	if ( isnan(GV("TuneQResult"))==1||GV("TuneQResult")<20) // if the AR Q=NaN then use NaN for all, if not use my code to fit 
//		savewave[currentspot][Vincr][3]=nan
//		savewave[currentspot][Vincr][4]=nan
//		savewave[currentspot][Vincr][5] =nan
//		print "ARV2 failed"
//
//	else
//		TuneFit_General("root:packages:mfp3d:tune:amp", "root:packages:mfp3d:tune:frequency") 
//		wave coeffs
//		savewave[currentspot][Vincr][3] =coeffs[2]
//		savewave[currentspot][Vincr][4] =coeffs[0]
//		savewave[currentspot][Vincr][5] =coeffs[1]*involsconvert
//			removefromgraph fit_amp 
//	endif
	//savewave[currentspot][Vincr][3] = GV("TuneQResult")
	//savewave[currentspot][Vincr][4] = GV("TuneFreqResult")
	//savewave[currentspot][Vincr][5] = GV("TunePeakResult")*involsconvert
	// getting prepared for tunearl()
	

	
	
	ARExecuteControl("DriveFrequencySetVar_3", "MasterPanel",centerfreqL,"Hz") // set center freq for lateral 1st harm		
	ARExecuteControl("InFastPopup", "crosspointpanel",0,"Lateral")  //put InFast on Lateral
	ARExecuteControl("WriteXPT", "crosspointpanel",0,"Write Crosspoint") //write corsspoint
	ARExecuteControl("FrequencyRatioSetVar_3", "MasterPanel",1/MHarm1,"")  // measuring "MHarm1" harmonic of Deflection signa	
	PDS("ARUserCallbackTune", " tuneARl()")	//associates tuneARv2() with "tune". //vertical  tune #1harm
	ARExecuteControl("DoTuneOnce_3", "MasterPanel", 0, "")  // run one tune and after that run tuneAR()
	
	

	
	
End

Function tuneARl() //lateral  tune #1 harm
	SVAR typeharm = root:variables:typeharm
	NVAR MHarm2 = root:Variables:MHarm2
	NVAR Vincr = root:Variables:Vincr
	NVAR currentspot = root:Variables:currentspot
	NVAR involsconvert = root:Variables:involsconvert
	SVAR exptbasename = root:variables:exptbasename	
	Wave savewave = $exptbasename	// First time running			savewave[currentspot][Vincr][6] = GV("TuneQResult")
	SVAR exptbasenameAmp = root:variables:exptbasenameAmp
	SVAR exptbasenamePhase = root:variables:exptbasenamePhase
	SVAR exptbasenameFreq = root:variables:exptbasenameFreq
	Wave savewaveAmp = $exptbasenameAmp	// First time running			
	Wave savewaveFreq= $exptbasenameFreq	// First time running			
	Wave savewavePhase = $exptbasenamePhase	// First time running			
	Wave dumAmp=root:packages:MFP3D:Tune:Amp
	Wave dumPhase=root:packages:MFP3D:Tune:Phase
	Wave dumFreq=root:packages:MFP3D:Tune:frequency
	 typeharm="ARL"
	 
	 		//saving the real tune data
	savewaveAmp[][Vincr][currentspot][2] =dumAmp[p]
	savewaveFreq[][Vincr][currentspot][2] =dumFreq[p]
	savewavePhase[][Vincr][currentspot][2] =dumPhase[p]
	 
//	if ( isnan(GV("TuneQResult"))==1||GV("TuneQResult")<20) // if the AR Q=NaN then use NaN for all, if not use my code to fit 
//		savewave[currentspot][Vincr][6]=nan
//		savewave[currentspot][Vincr][7]=nan
//		savewave[currentspot][Vincr][8] =nan
//		print "ARL failed"
//	else
//		TuneFit_General("root:packages:mfp3d:tune:amp", "root:packages:mfp3d:tune:frequency") 
//		wave coeffs
//		savewave[currentspot][Vincr][6] =coeffs[2]
//		savewave[currentspot][Vincr][7] =coeffs[0]
//		savewave[currentspot][Vincr][8] =coeffs[1]*involsconvert
//				removefromgraph fit_amp 
//	endif 
	

	//savewave[currentspot][Vincr][6] = GV("TuneQResult")
	//savewave[currentspot][Vincr][7] = GV("TuneFreqResult")
	//savewave[currentspot][Vincr][8] = GV("TunePeakResult")*involsconvert		
	// getting prepared for tunearl2()
	ARExecuteControl("FrequencyRatioSetVar_3", "MasterPanel",1/MHarm2,"")  // measuring "MHarm2" harmonic of Deflection signa	
	PDS("ARUserCallbackTune", " tuneARl2()")	//associates tuneARv2() with "tune". //vertical  tune #2harm
	ARExecuteControl("DoTuneOnce_3", "MasterPanel", 0, "")  // run one tune and after that run tuneAR()
	
End
	
Function tuneARl2() //lateral  tune #2 harm
	SVAR typeharm = root:variables:typeharm
	NVAR Vincr = root:Variables:Vincr
	NVAR currentvolt = root:Variables:currentvolt
	NVAR stopvolt = root:Variables:stopvolt
	NVAR incrmvolt = root:Variables:incrmvolt
	NVAR driveamp_input = root:Variables:driveamp_input
	NVAR currentspot = root:Variables:currentspot
	NVAR MHarm1 = root:Variables:MHarm1
	NVAR centerfreq = root:Variables:centerfreq	
	NVAR Vincr = root:Variables:Vincr
	NVAR currentspot = root:Variables:currentspot
	NVAR involsconvert = root:Variables:involsconvert
	SVAR exptbasename = root:variables:exptbasename	
	Wave savewave = $exptbasename	// First time running			savewave[currentspot][Vincr][9] = GV("TuneQResult")
	SVAR exptbasenameAmp = root:variables:exptbasenameAmp
	SVAR exptbasenamePhase = root:variables:exptbasenamePhase
	SVAR exptbasenameFreq = root:variables:exptbasenameFreq
	Wave savewaveAmp = $exptbasenameAmp	// First time running			
	Wave savewaveFreq= $exptbasenameFreq	// First time running			
	Wave savewavePhase = $exptbasenamePhase	// First time running			
	Wave dumAmp=root:packages:MFP3D:Tune:Amp
	Wave dumPhase=root:packages:MFP3D:Tune:Phase
	Wave dumFreq=root:packages:MFP3D:Tune:frequency
	 typeharm="ARL2"
	 
	 		//saving the real tune data
	savewaveAmp[][Vincr][currentspot][3] =dumAmp[p]
	savewaveFreq[][Vincr][currentspot][3]=dumFreq[p]
	savewavePhase[][Vincr][currentspot][3] =dumPhase[p]
//	 
//	if ( isnan(GV("TuneQResult"))==1||GV("TuneQResult")<20) // if the AR Q=NaN then use NaN for all, if not use my code to fit 
//		savewave[currentspot][Vincr][9]=nan
//		savewave[currentspot][Vincr][10]=nan
//		savewave[currentspot][Vincr][11] =nan
//		print "ARL2 failed"
//	else
//		TuneFit_General("root:packages:mfp3d:tune:amp", "root:packages:mfp3d:tune:frequency") 
//		wave coeffs
//		savewave[currentspot][Vincr][9] =coeffs[2]
//		savewave[currentspot][Vincr][10] =coeffs[0]
//		savewave[currentspot][Vincr][11] =coeffs[1]*involsconvert
//		removefromgraph fit_amp 
//	endif 	
	

	
	//savewave[currentspot][Vincr][9] = GV("TuneQResult")
	//savewave[currentspot][Vincr][10] = GV("TuneFreqResult")
	//savewave[currentspot][Vincr][11] = GV("TunePeakResult")*involsconvert					// getting prepared for tuneARv()
	ARExecuteControl("DriveAmplitudeSetVar_3", "MasterPanel",0,"V") // set drive amplitude1
	ARExecuteControl("DriveAmplitude1SetVar_3", "MasterPanel",currentvolt,"V") // set drive amplitude2		
	ARExecuteControl("InFastPopup", "crosspointpanel",0,"ACdefl")//put InFast on ACDefl	
	ARExecuteControl("WriteXPT", "crosspointpanel",0,"Write Crosspoint") //write corsspoint
	ARExecuteControl("DriveFrequencySetVar_3", "MasterPanel",centerfreq,"Hz") // set center freq 1		
	ARExecuteControl("FrequencyRatioSetVar_3", "MasterPanel",1/MHarm1,"")  // measuring "MHarm1" harmonic of Deflection signa
	PDS("ARUserCallbackTune", " tuneARv()")	//associates tuneARv2() with "tune". //vertical  tune #2harm
	Print "Drive Amp=",currentvolt,"V -- Increment",Vincr, "  -- Current spot=",currentspot
	savewave[currentspot][Vincr][12] = currentvolt
	
	if ((currentvolt+incrmvolt)<= stopvolt)				
		Vincr+=1
		currentvolt += incrmvolt
		ARExecuteControl("DriveAmplitudeSetVar_3", "MasterPanel",0,"V") // set drive amplitude1
		ARExecuteControl("DriveAmplitude1SetVar_3", "MasterPanel",currentvolt,"V") // set drive amplitude2		
		ARExecuteControl("DoTuneOnce_3", "MasterPanel", 0, "")
	else
		NVAR involsconvert = root:Variables:involsconvert
		Vincr=0
		currentvolt=driveamp_input
		currentspot += 1
		ARExecuteControl("StopScan_0", "MasterPanel", 0, "") // Withdrawing calls up the function "GoToPoint()"		
	endif

End


Function gotopointok()

//currentspot


End

/// ----------------------- Data Processing Portion --------------------------------------

Function LoadSecondHarmonic_button(ctrlName): ButtonControl 
	String ctrlName
	SVAR processfolder = root:variables:processfolder
	
	// Make data folder to hold loaded data
	String processfolderpath = "Root:" + processfolder
	if (datafolderexists(processfolderpath) == 0)
		NewDataFolder $processfolderpath
	endif
	cd processfolderpath

	Variable refNum
	String message = "Select one or more files"

	String fileFilters = "All Files:.*;"
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	//Contains the names of all of the files loaded, one file per line
	String outputPaths = S_fileName
	
	If (strlen(outputPaths) == 0)
		Print "Cancelled"
	Else
		//---------------------- Start loading files --------------------------------------------------------
	
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		String path, filename, dataname
		Variable index, num_filename
	
		For(index=0; index<numFilesSelected; index+=1)
			// path selects a single file, including the entire path
			path = StringFromList(index, outputPaths, "\r")
			// Number of items separated by :
			num_filename = ItemsInList(path, ":") - 1
			filename = StringFromList(0, (StringFromList(num_filename, path, ":")), ".")

			LoadWave/Q/M/D/A=$filename path
	
		Endfor
	Endif

End

Function ProcessHarmonics_button(ctrlName): ButtonControl 

	String ctrlName 

	SVAR basename = root:variables:basename
	NVAR firstpoint = root:variables:firstpoint
	NVAR lastpoint = root:variables:lastpoint
	SVAR processfolder = root:variables:processfolder
	
	// Move to folder that contains data
 
	wave tuneP=$basename
	Variable numpoints
	numpoints = lastpoint - firstpoint + 1
	duplicate/O/R=[firstpoint,lastpoint][][] tuneP tunePM
	
	make/o/n=(dimsize(tunePM,1))  LinQV_ave=nan,  QuadQV_ave=nan,  LinQL_ave=nan,  QuadQL_ave=nan
	make/o/n=(dimsize(tunePM,1))  LinQV_std=nan,  QuadQV_std=nan,  LinQL_std=nan,  QuadQL_std=nan
	make/o/n=(dimsize(tunePM,1))  LinFreqV_ave=nan,  QuadFreqV_ave=nan,  LinFreqL_ave=nan,  QuadFreqL_ave=nan
	make/o/n=(dimsize(tunePM,1))  LinFreqV_std=nan,  QuadFreqV_std=nan,  LinFreqL_std=nan,  QuadFreqL_std=nan
	make/o/n=(dimsize(tunePM,1))  LinAmpV_ave=nan,  QuadAmpV_ave=nan,  LinAmpL_ave=nan,  QuadAmpL_ave=nan
	make/o/n=(dimsize(tunePM,1))  LinAmpV_std=nan,  QuadAmpV_std=nan,  LinAmpL_std=nan,  QuadAmpL_std=nan
	make/o/n=(dimsize(tunePM,1))  DriveVol=tuneP[firstpoint][p][12]/sqrt(2) // convert it RMS
	SetScale d 0,0,"V", DriveVol
	SetScale d 0,0,"m",   LinAmpV_ave,  QuadAmpV_ave,  LinAmpL_ave,  QuadAmpL_ave,LinAmpV_std,  QuadAmpV_std,  LinAmpL_std,  QuadAmpL_std
	SetScale d 0,0,"Hz",   LinFreqV_ave,  QuadFreqV_ave,  LinFreqL_ave,  QuadFreqL_ave,LinFreqV_std,  QuadFreqV_std,  LinFreqL_std,  QuadFreqL_std

	variable ic
	for (ic=0;ic<dimsize(tunePM,1);ic+=1)
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][0] // linear Q vertical
		WaveStats/Q ww
		LinQV_ave[ic] = v_avg
		LinQV_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][3] //Quad Q Vertical
		WaveStats/Q ww
		QuadQV_ave[ic] = v_avg
		QuadQV_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][6] // Linear Q Lateral
		WaveStats/Q ww
		LinQL_ave[ic] = v_avg
		LinQL_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][9] //Quad Q Lateral
		WaveStats/Q ww
		QuadQL_ave[ic] = v_avg
		QuadQL_std[ic] = v_sdev
		
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][1] // Linear Freq Vertical //the last part convert the freq to NaN in case Q=NaN
		WaveStats/Q ww
		LinFreqV_ave[ic] = v_avg
		LinFreqV_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][4] //Quad Freq Vertical
		WaveStats/Q ww
		QuadFreqV_ave[ic] = v_avg
		QuadFreqV_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][7] //Linear Freq Lateral
		WaveStats/Q ww
		LinFreqL_ave[ic] = v_avg
		LinFreqL_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][10] //Quad Freq Lateral
		WaveStats/Q ww
		QuadFreqL_ave[ic] = v_avg
		QuadFreqL_std[ic] = v_sdev
				
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][2]/tunePM[p][ic][0] //Linear Corrected Amp Vertical
		WaveStats/Q ww
		LinAmpV_ave[ic] = v_avg
		LinAmpV_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][5]/tunePM[p][ic][3] //Quad Corrected Amp Vertical
		WaveStats/Q ww
		QuadAmpV_ave[ic] = v_avg
		QuadAmpV_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][8]/tunePM[p][ic][6] //Linear Corrected Amp Lateral
		WaveStats/Q ww
		LinAmpL_ave[ic] = v_avg
		LinAmpL_std[ic] = v_sdev
		make/O/N=(numpoints) /FREE ww=nan
		ww = tunePM[p][ic][11]/tunePM[p][ic][9] //Quad. Corrected Amp Lateral
		WaveStats/Q ww
		QuadAmpL_ave[ic] = v_avg
		QuadAmpL_std[ic] = v_sdev		
	endfor

	Edit  LinQV_ave,  QuadQV_ave,  LinQL_ave,  QuadQL_ave
	Edit LinAmpV_ave,  QuadAmpV_ave,  LinAmpL_ave,  QuadAmpL_ave


	Display LinAmpV_ave vs DriveVol
	ErrorBars LinAmpV_ave Y,wave=(LinAmpV_std,LinAmpV_std)
	Appendtograph QuadAmpV_ave vs DriveVol
	ErrorBars QuadAmpV_ave Y,wave=(QuadAmpV_std,QuadAmpV_std)
	Legend/C/N=text0/J/F=0/A=MC "\\s(LinAmpV_ave) Linear\r\\s(QuadAmpV_ave) Quad."
	ModifyGraph mode=3,mrkThick=1,marker(LinAmpV_ave)=8,marker(QuadAmpV_ave)=6;DelayUpdate
	ModifyGraph rgb(QuadAmpV_ave)=(0,0,65280)
	Label left "Vertical Defl.  Amp. [\\U]"
	Label bottom "Drive Amp. [\\U]"

	Display LinAmpL_ave vs DriveVol
	ErrorBars LinAmpL_ave Y,wave=(LinAmpL_std,LinAmpL_std)
	Appendtograph QuadAmpL_ave vs DriveVol
	ErrorBars QuadAmpL_ave Y,wave=(QuadAmpL_std,QuadAmpL_std)
	Legend/C/N=text0/J/F=0/A=MC "\\s(LinAmpL_ave) Linear\r\\s(QuadAmpL_ave) Quad."
	ModifyGraph mode=3,mrkThick=1,marker(LinAmpL_ave)=8,marker(QuadAmpL_ave)=6;DelayUpdate
	ModifyGraph rgb(QuadAmpL_ave)=(0,0,65280)
	Label left "Lateral Defl.  Amp. [\\U]"
	Label bottom "Drive Freq. [\\U]"
	
	
	
	Display LinFreqV_ave vs DriveVol
	ErrorBars LinFreqV_ave Y,wave=(LinFreqV_std,LinFreqV_std)
	Appendtograph QuadFreqV_ave vs DriveVol
	ErrorBars QuadFreqV_ave Y,wave=(QuadFreqV_std,QuadFreqV_std)
	Legend/C/N=text0/J/F=0/A=MC "\\s(LinFreqV_ave) Linear\r\\s(QuadFreqV_ave) Quad."
	ModifyGraph mode=3,mrkThick=1,marker(LinFreqV_ave)=8,marker(QuadFreqV_ave)=6;DelayUpdate
	ModifyGraph rgb(QuadFreqV_ave)=(0,0,65280)
	Label left "Vertical Resonance Freq. [\\U]"
	Label bottom "Drive Freq. [\\U]"

	Display LinFreqL_ave vs DriveVol
	ErrorBars LinFreqL_ave Y,wave=(LinFreqL_std,LinFreqL_std)
	Appendtograph QuadFreqL_ave vs DriveVol
	ErrorBars QuadFreqL_ave Y,wave=(QuadFreqL_std,QuadFreqL_std)
	Legend/C/N=text0/J/F=0/A=MC "\\s(LinFreqL_ave) Linear\r\\s(QuadFreqL_ave) Quad."
	ModifyGraph mode=3,mrkThick=1,marker(LinFreqL_ave)=8,marker(QuadFreqL_ave)=6;DelayUpdate
	ModifyGraph rgb(QuadFreqL_ave)=(0,0,65280)
	Label left "Lateral Resonance Freq.[\\U]"
	Label bottom "Drive Amp. [\\U]"
	
	
	Display LinQV_ave vs DriveVol
	ErrorBars LinQV_ave Y,wave=(LinQV_std,LinQV_std)
	Appendtograph QuadQV_ave vs DriveVol
	ErrorBars QuadQV_ave Y,wave=(QuadQV_std,QuadQV_std)
	Legend/C/N=text0/J/F=0/A=MC "\\s(LinQV_ave) Linear\r\\s(QuadQV_ave) Quad."
	ModifyGraph mode=3,mrkThick=1,marker(LinQV_ave)=8,marker(QuadQV_ave)=6;DelayUpdate
	ModifyGraph rgb(QuadQV_ave)=(0,0,65280)
	Label left "Vertical Quality Factor "
	Label bottom "Drive Amp. [\\U]"

	Display LinQL_ave vs DriveVol
	ErrorBars LinQL_ave Y,wave=(LinQL_std,LinQL_std)
	Appendtograph QuadQL_ave vs DriveVol
	ErrorBars QuadQL_ave Y,wave=(QuadQL_std,QuadQL_std)
	Legend/C/N=text0/J/F=0/A=MC "\\s(LinQL_ave) Linear\r\\s(QuadQL_ave) Quad."
	ModifyGraph mode=3,mrkThick=1,marker(LinQL_ave)=8,marker(QuadQL_ave)=6;DelayUpdate
	ModifyGraph rgb(QuadQL_ave)=(0,0,65280)
	Label left "Lateral Quality Factor "
	Label bottom "Drive Amp. [\\U]"
	
End

	

Function TuneFit_General(amp_name, freq_name)
	
	String amp_name, freq_name
	Wave amp_handle = $amp_name
	Wave freq_handle = $freq_name
	
	// -------- Calculate guess values for SHO fit
	Wavestats/Q amp_handle
	Variable ampguess = V_max
	Variable guesslocation = V_maxloc
	Variable freqguess = freq_handle(V_maxloc)
	SVAR typeharm = root:variables:typeharm

	// -------- Calculate boundary values for SHO fit
	Variable amplow, amphigh, freqlow, freqhigh
	amplow = ampguess*0.5
	amphigh = ampguess*2
	freqlow = freqguess*0.5
	freqhigh = freqguess*2
	
	Make/D/N=3/O coeffs
	coeffs = {freqguess, ampguess,100}
	Make/O/T/N=6 T_Constraints
	String Constraint1, Constraint2, Constraint3, Constraint4
	Constraint1 = "K0 > " + num2str(freqlow)
	Constraint2 = "K0 < " + num2str(freqhigh)
	Constraint3 = "K1 > " + num2str(amplow)
	Constraint4 = "K1 < " + num2str(amphigh)
	T_Constraints = {Constraint1, Constraint2, Constraint3, Constraint4,"K2 > 20","K2 < 500"}
	
	try
		FuncFit/Q/NTHR=0 SHOfit_amp coeffs amp_handle /X=freq_handle /D /C=T_Constraints ; AbortOnRTE
	catch
		if (V_AbortCode == -4)
			Print "Error during curve fit:"
			Variable CFerror = GetRTError(1)	// 1 to clear the error
			Print GetErrMessage(CFerror)
				coeffs[0] = nan
				coeffs[1] = nan
				coeffs[2] = nan;

		endif
	endtry
print typeharm,coeffs

end

Function SHOfit_amp(w,freq) : FitFunc
	Wave w
	Variable freq

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(freq) = (Amax*omega0^2/Q)/sqrt((omega0^2-freq^2)^2 + (omega0*freq/Q)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ freq
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = omega0
	//CurveFitDialog/ w[1] = Amax
	//CurveFitDialog/ w[2] = Q

	return (w[1]*w[0]^2/w[2])/sqrt((w[0]^2-freq^2)^2 + (w[0]*freq/w[2])^2)
End
