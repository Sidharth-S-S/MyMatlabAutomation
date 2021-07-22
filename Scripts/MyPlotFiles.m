function MyPlotFiles(Data,FailureMsg,plotData,TestRunName,variation)
  
%% Logic

set(0, 'DefaultTextInterpreter', 'none')
set(0, 'DefaultLegendInterpreter', 'none')

figure('name', 'Gen_SysRS_VMC_4355')

Ax1=subplot(4,1,1)
%rectangle('Position',[time(Blue_border_Index),-5.25,Crossing_Duration,10.5],'FaceColor',[0 1 1]);
ay= [-5.5:5.5]
ax1=zeros(size(ay));
ax2=ax1;
ax1(1:end) = time(Blueborderoutside_index);
ax2(1:end) = time(Blueborderinside_index);
X = [ax1,ax2]
Y = [ay, fliplr(ay)];
a = fill(X,Y,'k','FaceColor',[0.9 0.9 0.9]);
hold on
h1=plot(time,LaneOffset,'LineWidth',1.25,'color','k');
hold on
h2=plot(time,Left_Blue_Border,'LineWidth',1.25,'color','b');
h3=plot(time,Right_Blue_Border,'LineWidth',1.25,'color','r');
ylim([-5.5 5.5]);
xlim([time(1) time(end)]);
set(gca,'Ytick',[-5.25 -3.5 -1.75 0 1.75 3.5 5.25]);
set(gca,'Ycolor','b');
grid on
ylabel('Distance[m]','color','b');
title('Lane Offset and Static Blue Borders')  
legend([h1 h2 h3 a],'LaneOffset','BlueBorderLeft','BlueBorderRight','Crossing_Duration');
xlabel('Time [s]');

Ax2 = subplot(4,1,2)
[hAx,hLine1,hLine2] = plotyy(time,SvcActivation,time,LatBhvModID);
hold on
grid on
xlabel('Time [s]');
set(hAx(1),'XLim',[time(1) time(end)]);
set(hAx(2),'XLim',[time(1) time(end)]);
set(hAx(1),'Box','off');
set(hAx(2),'Box','off');
hAx(2).XRuler.Visible = 'on';
set(hAx(2), 'XTickLabel','','XAxisLocation','Top');
set(hAx(1),'YLim',[-0.5 3.5]);
set(hAx(1),'Ytick',[0 1 2 3]);
set(hAx(2),'YLim',[1.5 3.5]);
set(hAx(2),'Ytick',[2 3]);
set(hAx(1),'yticklabel',{'Inactive = 0','FadeIn = 1','ComfActive = 2','FadeOut = 3'});
set(hAx(2),'yticklabel',{'2= Default','3 = LaneChange'});
hAx(1).YGrid='on';
hAx(2).YGrid='on';
ylabel(hAx(1),'LatServiceActivation'); % left y-axis
ylabel(hAx(2),'LateralBehaviorModifierId'); % right y-axis
hAx(1).XColor = 'k' ;
hAx(1).YColor = 'b' ;
hAx(2).YColor = 'r' ;
hLine1.Color = 'b';
hLine2.Color = 'r';
hLine2.LineWidth = 1.5;
hLine1.LineWidth = 1.25 ;
hLine2.LineStyle = '-' ;
title('LateralBehaviorModifierId and LatServiceActivation');

linkaxes([Ax1,Ax2],'x');

Legend_details{1} = 'Legend details:';
Legend_details{2} = 'Lane Offset -> Data.LaneOffset';
Legend_details{3} = 'Left_Blue_Border -> Data.c0_Left_Blue';
Legend_details{4} = 'Right_Blue_Border -> Data.c0_Right_Blue';
Legend_details{5} = 'LateralBehaviorModifierId -> data.Lat_BehaviorModifierID';
Legend_details{6} = 'LatServiceActivation -> Data.Lat_Comf_service_Status';

%Variant Details
variant_info{1} = 'Variation:';
variant_info{2} = variantName;

%display the message
message = subplot(4,1,3);
leg = text(0,0,Legend_details);
text(0.5,0,variant_info);
set(leg,'Interpreter', 'none');
set (message, 'visible', 'off')

message = subplot(4,1,4);
if ~isempty(strfind(FailureMsg{1},'Passed'))
    text(0,0,FailureMsg,'color','[0, 0.5, 0]','FontSize', 12,'FontWeight','bold');
else
    text(0,0,FailureMsg,'color','r','FontSize', 12,'FontWeight','bold');
end
set (message, 'visible', 'off')

%Saving Figure
set(gcf, 'Position', get(0, 'Screensize'));
nameOfFigure = get(gcf,'name');
SavePlotImage_as_fig(TestRunName, variantName, nameOfFigure);
end
