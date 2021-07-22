function plot_results_LMCAxReqSrvAvl(test,failureMsg)

%% Get the data to Plot
%addpath(genpath(fullfile(test, 'TestResults')))
%OMCLResults = d97tomat(fullfile('ModelData','OML.d97'),'DSM_MDM_Plots.PLT',0.001);
OMCLResults = d97tomat('OML.d97','DSM_MDM_Plots.PLT',0.001);

%% Define signals for plotting
l_DrvLgtCmft12Avl						  	= OMCLResults.l_DrvLgtCmft12Avl;
VMC_LMCAxReqSrvAvl_RangeCheck             	= OMCLResults.VMC_LMCAxReqSrvAvl_RangeCheck;
VMC_LMCAxReqSrvAvl_StatusCheck            	= OMCLResults.VMC_LMCAxReqSrvAvl_StatusCheck;
isL12DrivingLongitudinalComfortRequested  	= OMCLResults.isL12DrivingLongitudinalComfortRequested;
isL12DrivingLongitudinalEmergencyRequested 	= OMCLResults.isL12DrivingLongitudinalEmergencyRequested;
isL12DrivingLateralComfortRequested 		= OMCLResults.isL12DrivingLateralComfortRequested;
isL12DrivingLateralEmergencyRequested 		= OMCLResults.isL12DrivingLateralEmergencyRequested;
isL012DrivingSpeedLimiterRequested 			= OMCLResults.isL012DrivingSpeedLimiterRequested;
longitudinal_L12_Comfort_ActivationRequest 	= OMCLResults.longitudinal_L12_Comfort_ActivationRequest;
Time 										= OMCLResults.q_T0;
res1 										= load('testCase_01.mat') ;

%%Plot Function
set(0, 'DefaultTextInterpreter', 'none')
set(0, 'DefaultLegendInterpreter', 'none')

figure('name', 'Req_330:LongComfort\_Availability')

Ax1 = subplot(7,2,[1,2]) ; 
plot(Time,OMCLResults.LMCAxReqSrvAvl,"Color",'k','Linewidth',2) ;
hold on
grid on;
%Add the title
title('LMCAxReqSrvAvl')
Legend_details{1} = 'Modify LMC From 2 -> 0 at t = 10.0 second';

Ax2 = subplot(7,2,[3,4]) ; 
plot(Time,l_DrvLgtCmft12Avl,"Color",'k','Linewidth',2) ;
hold on
grid on;
%Add the title
title('l_DrvLgtCmft12Avl')
Legend_details{2} = 'Modify LMC From 2 -> 0 at t = 14.0 second';

Ax3 = subplot(7,2,[5,6]) ; 
plot(Time,VMC_LMCAxReqSrvAvl_StatusCheck,"Color",'k','Linewidth',2) ;
hold on
grid on;
%Add the title
title('VMC_LMCAxReqSrvAvl_StatusCheck')
Legend_details{3} = 'Modify LMC From 2 -> 0 at t = 24.0 second';

Ax4 = subplot(7,2,[7,8]) ; 
plot(Time,VMC_LMCAxReqSrvAvl_RangeCheck,"Color",'k','Linewidth',2) ;
hold on
grid on;
%Add the title
title('VMC_LMCAxReqSrvAvl_RangeCheck')
Legend_details{4} = 'Modify LMC From 2 -> 0 at t = 30.0 second';

Ax5 = subplot(7,2,[9,10]) ; 
plot(Time,longitudinal_L12_Comfort_ActivationRequest,"Color",'k','Linewidth',2) ;
hold on
grid on;
%Add the title
title('longitudinal_L12_Comfort_ActivationRequest')
Legend_details{5} = 'Modify LMC From 2 -> 0 at t = 34.0 second';

Ax6 = subplot(7,2,[11,12]) ; 
plot(Time,isL12DrivingLongitudinalComfortRequested,"Color",'k','Linewidth',2) ;
hold on
grid on;
%Add the title
title('isL12DrivingLongitudinalComfortRequested')
Legend_details{6} = 'Modify LMC From 2 -> 0 at t = 40.0 second';
xlabel('Time [s]')

linkaxes([Ax1,Ax2,Ax3,Ax4,Ax5,Ax6],'x');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %display the messages%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
message = subplot(7,2,13);
leg = text(0,0,Legend_details);
set(leg,'Interpreter', 'none');
set (message, 'visible', 'off')

message = subplot(7,2,14);
if ~isempty(strfind(FailureMsg{1},'Passed'))
    text(0,0,FailureMsg,'color','[0, 1, 0]','FontSize', 12,'FontWeight','bold');
else
    text(0,0,FailureMsg,'color','[1, 0, 0]','FontSize', 12,'FontWeight','bold');
end
set (message, 'visible', 'off')

%Saving Figure
set(gcf, 'Position', get(0, 'Screensize'));
nameOfFigure = get(gcf,'name');
FigName = strrep([test,nameOfFigure,'.png'],'\','_');
FigName = strrep(FigName,'/','_');
saveas(gcf,FigName)
end
