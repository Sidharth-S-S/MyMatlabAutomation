%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Add Mux Wherever necessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SubSys = 'Highway_TCG/CRA_Extension_TCG/createObject9/'

% find the Bus Creator Handle where the connection to be done
block_ = find_system(SubSys,'LookUnderMasks','on','SearchDepth','1','BlockType','BusCreator');
handle_ = getSimulinkBlockHandle(block_);
BusCrHandle = get_param(handle_,'PortHandles');

%find the Bus Selector from which the connection should be done
block1_ = find_system(SubSys,'LookUnderMasks','on','SearchDepth','1','BlockType','BusSelector');
handle1_ = getSimulinkBlockHandle(block1_);
BusSelHandle = get_param(handle1_,'PortHandles');

for i = 1:3
    position = [420,   433+30*(i-1),   425,   457+30*(i-1)]
    %add the Mux
    if i == 1
        handle = add_block('simulink/Signal Routing/Mux',[SubSys,'mux0']);
    else
        handle = add_block('simulink/Signal Routing/Mux',[SubSys,'mux',num2str(i-1)]);
    end
    set_param(handle,'Inputs','1','Position',position)
    MuxPortHandle = get_param(handle,'PortHandles');
    
    delete_line(SubSys,BusSelHandle.Outport(i),BusCrHandle.Inport(end+i-3));
    %line from sel to mux i/p & mux o/p to bus creator
    h_  = add_line(SubSys,BusSelHandle.Outport(i),MuxPortHandle.Inport);
    h1_ = add_line(SubSys,MuxPortHandle.Outport,BusCrHandle.Inport(end+i-3));
    switch i
        case 1
            MuxOpName = 'curvature';
        case 2
            MuxOpName = 'speedLimit';
        case 3
            MuxOpName = 'distance';
    end
    set(MuxPortHandle.Outport, 'SignalNameFromLabel',MuxOpName)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Try to add annotation in the model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Add annotation in all the models coming in the VMC and Vehicle Path
open_system('vdp')
note = Simulink.Annotation('vdp/This is an annotation');
note.position = [10,50]

%To create an area, use the add_block function.

add_block('built-in/Area','vdp/This is an Area','Position',[120,100,230,200])

%get the details of the annotation
open_system('vdp')
annotations = find_system(gcs,'FindAll','on','Type','annotation')
get_param(annotations,'Name')

dirinfo = dir();
dirinfo(~[dirinfo.isdir]) = [];  %remove non-directories
path = uigetdir('/Users/user/')
files = dir(fullfile(path,'**','*.png'));

Path_ = pwd
VMCDir = [pwd,'\VMC']
VehDir = [pwd,'\Vehicle']
VMCdirinfo = dir(fullfile(VMCDir,'**','*.mdl'));
Vehdirinfo = dir(fullfile(VehDir,'**','*.mdl'));

%getting the annot from already loaded model
handle_   = find_system(gcs,'FindAll','on','Type','annotation');
annot_ = get_param(handle_(5),'Name');

for i = 1:length(VMCdirinfo)
    if strncmp(VMCdirinfo(i).name,'Controller_',11)
        continue
    else
        open_system(fullfile(VMCdirinfo(i).folder,VMCdirinfo(i).name))
        annot1 = 'Copyright:© 2020 Robert Bosch GmbH'
        annot2 = 'The reproduction, distribution and utilization of this file as well as the communication of its contents to others without express  authorization is prohibited'
        annot3 = 'Offenders will be held liable for the payment of damages. All rights reserved in the event of the grant of a patent, utility model or design.'
        
        note = Simulink.Annotation('untitled/This is an annotation');
        note.position = [10,50]
        
        close_system(fullfile(VMCdirinfo(i).folder,VMCdirinfo(i).name),1)
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Automatic Add the Bus Creators in the Location 120 times 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script to Add the Bus Creators for the Values
% distance has elements  1 to 120
% speedlimit & curvature as well 
% Automatically take these signals from the already present Bus Selector to the Bus Creator for the Values_0_   to values_1_  so on .. till values_119_
% Once these are created Add a Bus Selector and change the inputs to 120 for all the values and then automatically connect them together
SubSys = 'TCGDrive_Highway_TCG/FarRange_CRA/farRangeLimits' ;
%% find the Bus Selectors from Distance , Curvature , velocity
Selblock_ = find_system(SubSys,'LookUnderMasks','on','SearchDepth','1','BlockType','BusSelector');
Selhandle_ = getSimulinkBlockHandle(Selblock_);
BusSelHandle = get_param(Selhandle_,'PortHandles');

%% Add the Final Bus Creator
FinalBusCreatorh_ = add_block('simulink/Signal Routing/Bus Creator',[SubSys,'/farRangeLimit'])
set_param(FinalBusCreatorh_,'Inputs','120','Position',[2500,-320,2510,2070]);
FinalBusCrPortH = get_param(FinalBusCreatorh_,'PortHandles');
set(FinalBusCrPortH.Outport,'SignalNameFromLabel','farRangeLimit');

%% From the OutPut of these Bus Handles are in order Distance , Curvature , Velocity  so use them accordingly
posleft   = 1500;
posright  = 1505;
posTop    = -904;
posBottom = -876;
Span = 30;

for i = 1:120
    % Add the Bus Creator Block & set the input number to 3 & Change the
    % Position of the block to be changed by Code
    handle = add_block('simulink/Signal Routing/Bus Creator',[SubSys,'/Creator',num2str(i-1)]);
    set_param(handle,'Inputs','3','Position',[posleft,posTop+Span*(i-1),posright,posBottom+Span*(i-1)]);
    %get the port handle of the New Bus Creator so that input can be added
    BusCrHandle = get_param(handle,'PortHandles');
    for j = 1:3
        InputPort = BusCrHandle.Inport(j);
        OutPort = BusSelHandle{j, 1}.Outport(i);
        
        %As the name of the Bus selector are values so add a mux to rename
        switch j
            case 1
                SelectorOPName = 'distance';
                Muxhandle = add_block('simulink/Signal Routing/Mux',[SubSys,'/distancemux',num2str(i-1),'_',num2str(j-1)]);
                position = [895,-907+10*(i-1),900,-893+10*(i-1)];
            case 2
                SelectorOPName = 'curvature';
                Muxhandle = add_block('simulink/Signal Routing/Mux',[SubSys,'/curvaturemux',num2str(i-1),'_',num2str(j-1)]);
                position = [895,293+10*(i-1),900,307+10*(i-1)];
            case 3
                SelectorOPName = 'speedLimit';
                Muxhandle = add_block('simulink/Signal Routing/Mux',[SubSys,'/speedLimitmux',num2str(i-1),'_',num2str(j-1)]); 
                position = [895,1493+10*(i-1),900,1507+10*(i-1)];
        end
        %Mux is added and From the Output Port Name is given & Line is
        %drawn to the Input of the Bus Selector 
        set_param(Muxhandle,'Inputs','1','Position',position);
        MuxPortHandle = get_param(Muxhandle,'PortHandles');
        set(MuxPortHandle.Outport,'SignalNameFromLabel',SelectorOPName);
        
        %Connect the input of the Bus Selector to Mux
        add_line(SubSys,OutPort,MuxPortHandle.Inport);
        %From the BusSelHandles Connect the Signals to Values_0_ Bus Creator
        add_line(SubSys,MuxPortHandle.Outport,InputPort);
    end
    set(BusCrHandle.Outport,'SignalNameFromLabel',['values_',num2str(i-1),'_']);
    add_line(SubSys,BusCrHandle.Outport,FinalBusCrPortH.Inport(i));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Automatic Read DD Block Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

model_ = 'Highway_TCG/TCGDrive_CMDicts'
ReadDicts = find_system(model_,'LookUnderMasks','on','FollowLinks', 'on',...
    'SearchDepth',1,'BlockType','S-Function','MaskType','Read CarMaker Dictionary Variable(s)') ;
model_1 = [model_,'/ReadDicts'];
position = [-20   185   350   205];
Positiongap = 40;


if ~isempty(ReadDicts)
    %Input Ports Assign in BusCreator
    bus_in_gather = add_block('simulink/Signal Routing/Bus Creator',[model_1 ,'/', 'gather_ReadDicts']);
    BusPos = position + [720 , -30 ,355, (numel(ReadDicts)*40 - 10 )];
    set_param(bus_in_gather,'Inputs', num2str(numel(ReadDicts)),'position',BusPos);
    InPort = get_param(bus_in_gather,'PortHandles');
    %ReadDicts Create Properly
    for i_ = 1:1:numel(ReadDicts)
        tempName                = get_param(ReadDicts(i_),'xname');
        %tempMask                = get_param(ReadDicts(i_),'MaskValueString');
        CM_Dicts(i_).xname      = tempName{1};
        %Names Containing Multiple , are truncated
        if contains(tempName{1},',')
            idx = strfind(tempName,',');
            FirstName = tempName{1}(1:idx{1,1}(1)-1);
            idx = strfind(FirstName,'.');
            BlockName = [FirstName(1:idx(end)-1),'.Array'];
        else
            BlockName = tempName{1};
        end
        %CM_Dicts(i_).mask       = tempMask{1};
        handle_ = add_block('CarMaker4SL/Read CM Dict',[model_1,'/',BlockName]);
        newPos = position + [0 40*(i_-1) 0 40*(i_-1)]
        set_param(handle_,'xname',tempName{1},'position',newPos);
        
        %connect the line and set the name
        out_port = get_param(handle_, 'PortHandles');
        h = add_line(model_1,out_port.Outport, InPort.Inport(i_));
        set_param(h, 'SignalNameFromLabel', BlockName);
        
    end
    
else
    CM_Dicts = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change the Bus Creator Name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subsys_ = 'Highway_TCG/CRA_Extension_TCG/farRangeLimits';
blocks = find_system(subsys_,'SearchDepth',1,'BlockType','BusCreator');
handle_ = get_param(blocks,'handle')
for i =1:length(handle_)
    param_ = get_param(handle_{i},'OutputSignalNames');
    if strncmp(param_,'value',5)
        oldname = param_{1};
        newname = [oldname(1:5),'s',oldname(6:end)]
        portHandle = get_param(handle_{i},'PortHandles');
        set(portHandle.Outport, 'SignalNameFromLabel',newname);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Try to Find the Contents in a Nested Bus Creator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

model_ = 'Highway_TCG/TCI_Drive_NewStructure'
%bdIsLoaded(model_) %bdIsLibrary
%RefModelhandle = find_mdlrefs()
BusCreator_ = find_system(model_,'FindAll', 'on','SearchDepth',1,'BlockType','BusCreator');
TL1 = get_param(BusCreator_,"InputSignalNames") %find the top level Bus Names
BusCreator_ = find_system(model_,'FindAll', 'on','SearchDepth',1,'BlockType','BusCreator');


getfullname(Simulink.findBlocks(model_))
line = find_system(gcs, 'SearchDepth', 1, 'FindAll', 'on', ...
      'Type', 'line', 'Selected', 'on');
path = getfullname(line);


%Find the Bus Creator Elements
BusCreator_ = find_system(model_,'FindAll', 'on','BlockType','BusCreator')
getfullname(BusCreator_)
Signals_ = get_param(BusCreator_,"InputSignalNames")

for i = 1:numel(BusCreator_)
    CreateBusElem(Signals_(i),)
end


%Bus Element
signal = get_param(gcbh,'OutputSignalNames')';

signal_new = signal;

% signal_new = {'<PtMTar>'
% '<PtMLim>'
% '<RBVMI_PowertrainFxTargetEnable>'
% '<RBVMI_PowertrainLimitFxEnable>'};
signal_new=strrep(signal_new(:),'<','');
signal_new=strrep(signal_new(:),'>','');

clear Data;Data=struct();
for i = 1 : numel(signal_new)
Data(i).Name = signal_new(i);
end
clear elems
for i = 1: numel(Data)
    elems(i) = Simulink.BusElement;
    elems(i).Name = char(Data(i).Name);
    elems(i).Dimensions = 1;
    elems(i).DimensionsMode = 'Fixed';
    elems(i).DataType = 'double';
    elems(i).SampleTime = -1;
    elems(i).Complexity = 'real';
end

PT_Fb = Simulink.Bus;
PT_Fb.Elements = elems;
automate the name of the signal
line = find_system(gcs, 'SearchDepth', 1, 'FindAll', 'on','Type','line')
path = getfullname(line)

for i = 1:numel(line)
    SrcBlockHandle = get_param(line(i),'SrcBlockHandle')
    if ~strcmp(get_param(SrcBlockHandle,'BlockType'),'Inport')
        name_ = get_param(SrcBlockHandle,'xname')
        name_ = replace(name_,'.','_');
        set_param(line(i),'Name',name_)
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Function for P Code the Files with help text
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CustompCode(File2pCode)
    help_txt = help(fullfile(pwd,File2pCode));
    help_txt_parts = strsplit(help_txt, newline);
    pcode(File2pCode,'-inplace');
    fid = fopen(File2pCode, 'w');
    assert(fid>0, ...
        sprintf('Could not open "%s" with write permissions! Aborting ...',File2pCode))
    for i_=1:numel(help_txt_parts)
        fprintf(fid, '%% %s\n', help_txt_parts{i_});
    end
    fclose(fid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Subsys2ModelReference(CurrSystem)
%UNTITLED Summary of this function goes here
%  Detailed explanation goes here
disp(['The current system selected is ',CurrSystem,'Model Reference Code to be followed']);

%% Covert the Subsystem to a Model Reference by Script
open_system('sldemo_mdlref_conversion');
Simulink.SubSystem.convertToModelReference(...
   'sldemo_mdlref_conversion/Bus Counter', ...
   'bus_counter_ref_model', ...
   'AutoFix',true,...
   'ReplaceSubsystem',true,...
   'CheckSimulationResults',true);
end


