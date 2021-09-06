:: Integrate_SIM_Instance
:: 
:: Inputs (given pairwise):
::    -t, --type 		'dadc' or 'lmc'
::    -n, --newname     New Name of the Instance to be Integrated.
::    -p, --pathtozip   Path to the local SimWork.zip File to be integrated.
::                      ---OR---                                                
::    -j, --jsonfile    Json File containing Information of Integration Repo, Commit Id, New Name,  Type. Refer to Example File src_cm4sl/IntegrationDetailsDADC.json
::
:: Examplary function call:
::  Integrate_SIM_Instance -t dadc -n DADC_2009_5_RC21_09_V2 -p D:\DA_VMC_CoreRepo\vmc_simulink_aos\Deliverables\Sim_Work.zip
::  Integrate_SIM_Instance -j D:\customer_project\vmcsim.jlr\src_cm4sl\IntegrationDetailsDADC.json
::  Integrate_SIM_Instance -t lmc -n LMC_CSW8_localdev_Part2_10 -p "D:\Artifacts_For_Integration\LMC OMCL\MLA_High_CSW8\Sim_Work_Sfun4VMCOnlySimMain.zip"
::

@ ECHO off

setlocal enableDelayedExpansion

SET curDir=%~dp0

SET input_args=%*

IF [%1]==[/?] GOTO :Help
IF [%1]==[/help] GOTO :Help
IF [%1]==[-h] GOTO :Help
IF [%1]==[--help] GOTO :Help

:: Default values
SET type_=dadc
SET newname_=DADC_Dummy

:moreOptionsOrFlags

SET  curArg=%1

SET  curArg1stChar=!curArg:~0,1!

IF [!curArg1stChar!] == [-] (
	
	IF /i [!curArg!] == [--type]  (

        IF NOT [%2] == [] (
            SET type_=%~2
            SHIFT & SHIFT
	    ) ELSE (
            ECHO No value specified for !curArg!
            EXIT /b
	    )

	) ELSE IF /i [!curArg!] == [-t]  (

        IF NOT [%2] == [] (
            SET type_=%~2
            SHIFT & SHIFT
	    ) ELSE (
            ECHO No value specified for !curArg!
            EXIT /b
	    )

    ) ELSE IF /i [!curArg!] == [--newname] (

	    IF NOT [%2] == [] (
		    SET newname_=%~2
			SHIFT & SHIFT
        ) ELSE (
            ECHO No value specified for !curArg!
            EXIT /b
	    )

	) ELSE IF /i [!curArg!] == [-n] (

	    IF NOT [%2] == [] (
		    SET newname_=%~2
			SHIFT & SHIFT
        ) ELSE (
            ECHO No value specified for !curArg!
            EXIT /b
	    )

    ) ELSE IF /i [!curArg!] == [--pathtozip] (

        IF NOT [%2] == [] (
            SET pathtozip_=%~2
            SHIFT & SHIFT
        ) ELSE (
			ECHO No value specified for !curArg!
            EXIT /b
        )
	) ELSE IF /i [!curArg!] == [-p] (

        IF NOT [%2] == [] (
            SET pathtozip_=%~2
            SHIFT & SHIFT
        ) ELSE (
			ECHO No value specified for !curArg!
            EXIT /b
        )

    ) ELSE IF /i [!curArg!] == [--jsonfile] (

        IF NOT [%2] == [] (
            SET jsonfile_=%~2
            SHIFT & SHIFT
        ) ELSE (
			ECHO No value specified for !curArg!
            EXIT /b
        )
	
	) ELSE IF /i [!curArg!] == [-j] (

        IF NOT [%2] == [] (
            SET jsonfile_=%~2
            SHIFT & SHIFT
        ) ELSE (
			ECHO No value specified for !curArg!
            EXIT /b
        )

    ) ELSE (

        ECHO Unexpected option or flag !curArg!
        EXIT /b

    )
	
	GOTO moreOptionsOrFlags
	
)

:: Identify Matlab R2019b directory
SET "matlab_default_dir_1=%ProgramFiles%\MATLAB\R2019b\bin\"
SET "matlab_default_dir_2=C:\MATLAB\R2019b_x64\bin\"

IF EXIST "%matlab_default_dir_1%" (

	SET matlab_dir=%matlab_default_dir_1%
	
) ELSE IF EXIST "%matlab_default_dir_2%" (

	SET matlab_dir=%matlab_default_dir_2%
	
) ELSE (

	GOTO Failure
	
)

:: Verify the Input Arguments before opening MATLAB
IF "%pathtozip_%"=="" (

    IF "%jsonfile_%"=="" (

        ECHO Zip File Path is not provided as input. Jsonfile is also not provided as input.
        GOTO ParamFailure
    
    ) ELSE IF NOT EXIST "%jsonfile_%" (

        ECHO Json File Path does not exist.
        GOTO ParamFailure
    
    ) ELSE (

        ECHO Starting Matlab to integrate the jsonfile contents in "%jsonfile_%"
        "%matlab_dir%matlab.exe" -sd src_cm4sl -r "addpathVMCSim; AutoIntegration('jsonfile,!jsonfile_!');"

    )
	
) ELSE IF NOT EXIST "%pathtozip_%" (

    ECHO Zip File Path does not exist.
	GOTO ParamFailure
	
) ELSE IF EXIST "%pathtozip_%" (

	ECHO Starting Matlab to integrate the Zip File Contents in "%pathtozip_%"
    "%matlab_dir%matlab.exe" -sd src_cm4sl -r "addpathVMCSim; AutoIntegration('type,!type_!,newname,!newname_!,pathtozip,!pathtozip_!');"

)ELSE (
	
	ECHO Unknown Parameters !pathtozip_!! Aborting...
	GOTO end
	
)

EXIT /b

:Failure
PAUSE>NUL | SET /p ="Cannot find a valid Matlab version. Aborting ..."
GOTO end

:ParamFailure
PAUSE>NUL | SET /p ="Input Parameters are either blank or does not exist.Refer to help by either -h or --help as Arguments. Aborting ..."
GOTO end

:Help
ECHO.
ECHO.
ECHO Integrate_SIM_Instance
ECHO.
ECHO Inputs (given pairwise):
ECHO    -t, --type       'dadc' or 'lmc'
ECHO    -n, --newname     New Name of the Instance to be Integrated.
ECHO    -p, --pathtozip   Path to the local SimWork.zip File to be integrated.
ECHO                      ---OR---                                                
ECHO    -j, --jsonfile    Json File containing Information of Integration Repo, Commit Id, New Name,  Type. Refer to Example File src_cm4sl/IntegrationDetailsDADC.json
ECHO.
ECHO Examplary function call:
ECHO    Integrate_SIM_Instance -t dadc -n DADC_2009_5_RC21_09_V2 -p D:\DA_VMC_CoreRepo\vmc_simulink_aos\Deliverables\Sim_Work.zip
ECHO    Integrate_SIM_Instance -j D:\customer_project\vmcsim.jlr\src_cm4sl\IntegrationDetailsDADC.json
ECHO    Integrate_SIM_Instance -t lmc -n LMC_CSW8_localdev_Part2_10 -p "D:\Artifacts_For_Integration\LMC OMCL\MLA_High_CSW8\Sim_Work_Sfun4VMCOnlySimMain.zip"
ECHO.
ECHO Copyright:
ECHO 2021 Robert Bosch GmbH
ECHO.
ECHO  The reproduction, distribution and utilization of this file as
ECHO  well as the communication of its contents to others without express
ECHO  authorization is prohibited. Offenders will be held liable for the
ECHO  payment of damages. All rights reserved in the event of the grant
ECHO  of a patent, utility model or design.
ECHO.

:end
EXIT /b
