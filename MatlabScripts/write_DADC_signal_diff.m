function write_DADC_signal_diff(path_old,path_new)
%% This function gives the diff between New and Old DADC OMCL Input Signals and Write them to the Excel
path1 = fullfile(pwd,'VMC','JLR',path_old,[path_old,'.mdl']);
path2 = fullfile(pwd,'VMC','JLR',path_new,[path_new,'.mdl']);

load_system(path1);
DADC_inport_names= find_system([path_old,'/Sfun_subsystem/ESP Controller Interface'],'SearchDepth',1,'LookUnderMasks','All','BlockType','Inport');
portNames_in_path1 = cellstr(get_param(DADC_inport_names, 'Name'));
portNames_in_path1 = removeUnits(portNames_in_path1);
portNames_in_path1 = makeSignalsPretty(portNames_in_path1);
DADC_outport_names= find_system([path_old,'/Sfun_subsystem/ESP Controller Interface'],'SearchDepth',1,'LookUnderMasks','All','BlockType','Outport');
portNames_out_path1 = cellstr(get_param(DADC_outport_names, 'Name'));
portNames_out_path1 = removeUnits(portNames_out_path1);
portNames_out_path1 = makeSignalsPretty(portNames_out_path1);
close_system(path1);

load_system(path2);
DADC_inport_names= find_system([path_new,'/Sfun_subsystem/ESP Controller Interface'],'SearchDepth',1,'LookUnderMasks','All','BlockType','Inport');
portNames_in_path2 = cellstr(get_param(DADC_inport_names, 'Name'));
portNames_in_path2 = removeUnits(portNames_in_path2);
portNames_in_path2 = makeSignalsPretty(portNames_in_path2);
DADC_outport_names= find_system([path_new,'/Sfun_subsystem/ESP Controller Interface'],'SearchDepth',1,'LookUnderMasks','All','BlockType','Outport');
portNames_out_path2 = cellstr(get_param(DADC_outport_names, 'Name'));
portNames_out_path2 = removeUnits(portNames_out_path2);
portNames_out_path2 = makeSignalsPretty(portNames_out_path2);
close_system(path2);

path2_wrt_path1_in = setdiff(portNames_in_path2,portNames_in_path1);
path1_wrt_path2_in = setdiff(portNames_in_path1,portNames_in_path2);
path2_wrt_path1_out = setdiff(portNames_out_path2,portNames_out_path1);
path1_wrt_path2_out = setdiff(portNames_out_path1,portNames_out_path2);

%Recheck to make sure that the file is closed before rewriting the data
if exist(fullfile(cd,'SignalDifference.xlsx'),'file')== 2
    disp('SignalDifference.xlsx is still existing & deleting the same.')
    try
        delete(which('SignalDifference.xlsx'));
    catch ME
        disp('Cant delete the Excel Sheet')
        rethrow (ME.message)
    end
end
%write the data to excel sheet
if ~isempty(path2_wrt_path1_in); xlswrite('SignalDifference.xlsx',path2_wrt_path1_in,'New_Vs_Old_Input');end
if ~isempty(path1_wrt_path2_in); xlswrite('SignalDifference.xlsx',path1_wrt_path2_in,'Old_Vs_New_Input');end
if ~isempty(path2_wrt_path1_out); xlswrite('SignalDifference.xlsx',path2_wrt_path1_out,'New_Vs_Old_Output');end
if ~isempty(path1_wrt_path2_out); xlswrite('SignalDifference.xlsx',path1_wrt_path2_out,'Old_Vs_New_Output');end

disp('Completed list comparision between old and new and written to SignalDifference.xlsx');
end

function pretty_signals = makeSignalsPretty(ugly_signals)

pretty_signals = strrep(ugly_signals,'m_','');
pretty_signals = strrep(pretty_signals,'.data.','.');
pretty_signals = strrep(pretty_signals,'.memory.','.');
pretty_signals = strrep(pretty_signals,'.value_','');
pretty_signals = strcat(pretty_signals, '?');
pretty_signals = strrep(pretty_signals,'.value?','?');
pretty_signals = strrep(pretty_signals,'?','');

end

function cellArray_ = removeUnits(cellArray_)
% removeUnits - Remove units from signal names
%
% Syntax:
%  cellArray_ = removeUnits(cellArray_)
%
% Inputs:
%  cellArray_       Cell array containing the signal names with Units
%
% Outputs:
%  cellArray_       Cell Array with signals without Units in their names

for k_=1:numel(cellArray_)
    openingBracket_ = strfind(cellArray_{k_}, '[');
    while ~isempty(openingBracket_)
        closingBracket_ = strfind(cellArray_{k_}, ']');
        if isnan(str2double(cellArray_{k_}(openingBracket_(1)+1:closingBracket_(1)-1)))
            cellArray_{k_} = cellArray_{k_}([1:openingBracket_(1)-1 closingBracket_(1)+1:numel(cellArray_{k_})]);
            openingBracket_ = strfind(cellArray_{k_}, '[');
        else
            cellArray_{k_}(openingBracket_(1)) = '_';
            cellArray_{k_}(closingBracket_(1)) = '_';
            openingBracket_ = strfind(cellArray_{k_}, '[');
            continue;
        end
    end
    
end
end
