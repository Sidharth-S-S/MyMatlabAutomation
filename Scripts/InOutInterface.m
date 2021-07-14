OMCLName = find_system(bdroot, 'BlockType', 'SubSystem');

handles = find_system(OMCLName, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'Inport');
SW_Input_Signal_Names = get_param(handles, 'Name');
OMCL_Input_Signal_Names = makeSignalsPretty(SW_Input_Signal_Names);


handles = find_system(OMCLName, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'Outport');
SW_Output_Signal_Names = get_param(handles, 'Name');
OMCL_Output_Signal_Names = makeSignalsPretty(SW_Output_Signal_Names);

xlsxname = 'Input_Output_OMCL.xlsx';
SignalTable_input = table(SW_Input_Signal_Names, OMCL_Input_Signal_Names);
SignalTable_output = table(SW_Output_Signal_Names, OMCL_Output_Signal_Names);

writetable(SignalTable_input,  xlsxname, 'Sheet', 'InputSignals', 'Range','A1');
writetable(SignalTable_output, xlsxname, 'Sheet', 'OutputSignals', 'Range','A1');
writetable(cell2table(OMCL_Input_Signal_Names,'VariableNames',{'OMCL_Inputs'}), xlsxname, 'Sheet', 'OMCLSignals', 'Range','A1');
writetable(cell2table(OMCL_Output_Signal_Names,'VariableNames',{'OMCL_Outputs'}), xlsxname, 'Sheet', 'OMCLSignals', 'Range','B1');

%%
function pretty_signals = makeSignalsPretty(ugly_signals)

pretty_signals = strrep(ugly_signals,'[-]','');
pretty_signals = strrep(pretty_signals,'m_','');
pretty_signals = strrep(pretty_signals,'.data.','.');
pretty_signals = strrep(pretty_signals,'.memory.','.');
pretty_signals = strrep(pretty_signals,'.value_','');
pretty_signals = strcat(pretty_signals, '?');
pretty_signals = strrep(pretty_signals,'.value?','?');
pretty_signals = strrep(pretty_signals,'?','');

end
