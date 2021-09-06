function plotFName = SaveFigAsMontage(TestRunName, variantName)

% get variation number value from Car Maker test manager
SavePlotPath = [pwd,filesep,'..',filesep,'Data',filesep,'TestRun',filesep,'rbt_bp_tests',filesep,'Plots'];

%find all the opened Figures
FigList = findobj(allchild(0), 'flat', 'Type', 'figure', 'Units', 'Pixels');

%save all the opened pictures
for i = 1 : size(FigList,1)
    FigHandle = FigList(i,1);
    GetName   = get(FigList(i,1), 'Name');
    iFigstr   = num2str(variantName);
    NewName   = strcat(GetName,'_Var_',num2str(i));
    [~,name,~] = fileparts(NewName);
    FigFile(i).Name = fullfile(SavePlotPath, [name, '.tif']);
    savefig(FigHandle, fullfile(SavePlotPath, [name, '.fig']));
    saveas(FigHandle, fullfile(SavePlotPath, [name, '.tif']));
end

close all
%Create a Montage out of the saved .tif files

fileNames = {FigFile.Name};
TC_Name = strsplit(TestRunName,'/');
Fname = strcat(TC_Name{end},'_Var_',iFigstr);
figure('Name',strcat(Fname,'_montage'))
numOfFigs = size(FigList,1);
montage(fileNames, 'Size', [numOfFigs 1]);

% Save results graph to png file
set(gcf, 'Position', get(0, 'Screensize')); 
saveas(gcf, fullfile(SavePlotPath, [Fname, '.png']))
disp(['Plot image saved to: ' fullfile(SavePlotPath, [Fname, '.png'])]);
plotFName = Fname;
clc;
end
