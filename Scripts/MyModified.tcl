proc EvalProc {key name args} {
    switch $key {
	
        TestSeries {
		
		set jenkins_user dummy1
		set usr_name [exec whoami]
		set usr_name [string range $usr_name [expr {[string first \\ $usr_name]+1}] [string length $usr_name]]
		
		if { $usr_name == $jenkins_user } {
		
			set MyDate [clock format [clock seconds] -format {%Y_%m_%d-%H-%M-%S}] 
			set i0 [expr {[string last / $name]+1}] 
			set i1 [expr {[string last . $name]-1}] 
			set name [string range $name $i0 $i1] 		
			MatlabEval -timeout 300000 "Quit_Environment"			
			}
		PopupCtrl timeout 0
		MatlabEval {[~,commitVMCSim] = system('git rev-parse HEAD');}
		MatlabEval {[~,branchNameVMCSim] = system('git rev-parse --abbrev-ref HEAD');}
		MatlabEval {[~, commitTestRepo] = system('git rev-parse @:../Data/TestRun/vmc_sim_simple_tests');}
		set commitVmcSim [MatlabEval {commitVMCSim}]
		set VMCSimBranchName [MatlabEval {branchNameVMCSim}]
		set commitTestCatalogue [MatlabEval {commitTestRepo}]
		set creationDate [clock format [clock seconds] -format {%Y_%m_%d-%H-%M-%S}]
		Report configure -notes "---Test Executed By:---\n $usr_name \n-----VMC Sim Repository:-----\nBranchName: $VMCSimBranchName Commit Id: $commitVmcSim\n\n-----Testing repository:-----\nCommit Id: $commitTestCatalogue"
		set i0 [expr {[string last / $name]+1}] 
		set i1 [expr {[string last . $name]-1}] 
		set name [string range $name $i0 $i1] 
		Report create "Data/TestRun/vmc_sim_simple_tests/Reports/Platform_Test_Report_$creationDate-$name.pdf"
		}
        Group {}
						
        TestRunGroup {}
		
        TestRun { 
			Log "EndProc: ${TS::MatlabFunction}"
			Update_RoadAnimation_End
			if {[TestMgr::GetResult] != "err"} {
				set TS::Res [MatlabEval -timeout 300000 "try; ${TS::MatlabFunction}('$name','$args'); catch ME; rethrow(ME); end"]
				if {$TS::Res==0} {
					::TestMgr::SetResult good
				} elseif {$TS::Res==2} {
					::TestMgr::SetResult warn
				} elseif {$TS::Res==3} {
					::TestMgr::SetResult err
				} else {
					::TestMgr::SetResult bad
				}
				set plotName [MatlabEval -timeout 300000 "try; SaveFigAsMontage('$name','$args'); catch ME; rethrow(ME); end"]
				if {$plotName != ""} {
					set imageFolder "src_cm4sl/"
					append imageFolder $plotName
					append imageFolder ".png"
					TestMgr assocfile Image $imageFolder
				} else {
					Log " No plot Name to be Associated with Test Manager."
				}
				### move sim measurement artifacts ###
				MatlabEval -timeout 300000 "try; zipTestResults('$name','$args'); catch ME; rethrow(ME); end"
			}
			restoreOriginalRoadParams
		}
		
        default         {}
		
    }
}
