function AutoIntegration(varargin)
%AutoIntegration : Try to integrate the VMC Instance Automatically
%   Given any artefacts already available as a zip file in a Local system
%   Or given any commit id already available to be integrated along with
%   the Path to the Repo in a Json File.
%
% Syntax :    Two Type of Function Call Possible.
% 1 :   jsonfile : Mandatory Input as a Json File containing Information of
%                  Integration Type, New Name, OMCL Path, Commit Id.
%       Check    : IntegrationDetailsDADC.json/IntegrationDetailsLMC.json
%
% 2.    type        : Mandatory I/P. Can be 'DADC' / 'LMC'
%       newname     : Mandatory I/P. NewName for OMCL starts with
%                     'DADC'/'LMC'
%       pathtozip   : Mandatory I/P. Path of the local .zip File.
%
% %%%%%%%%%%%%%%%%     %IMPORTANT NOTE For LMC:%     %%%%%%%%%%%%%%%%%%%%
%       '.sim' File should be in the same path as OMCL.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Example FunctionCall from MATLAB:
%       1.   AutoIntegration('jsonfile','IntegrationDetailsDADC.json')
%        - - - - - - - - - -   OR   - - - - - - - - - -  -
%       2.   AutoIntegration('type','DADC',...
%               'newname','DADC_2009_5_RC21_09_V2',...
%               'pathtozip','D:\DA_VMC_CoreRepo\vmc_simulink_aos\Deliverables\Sim_Work.zip')
%       3.   AutoIntegration('type','LMC',...
%               'newname','LMC_CSW8_localdev_Part2_10',...
%               'pathtozip','D:\Artifacts_For_Integration\LMC OMCL\MLA_High_CSW8\Sim_Work_Sfun4VMCOnlySimMain.zip')
%
% Alternate FunctionCall (much like command prompt)
%     AutoIntegration('type dadc newname DADC_2009_5_RC21_09_V ...
%     pathtozip D:\DA_VMC_CoreRepo\vmc_simulink_aos\Deliverables\Sim_Work.zip')
%
% Copyright:
%      © 2021 Robert Bosch GmbH
%  
%      The reproduction, distribution and utilization of this file as
%      well as the communication of its contents to others without express
%      authorization is prohibited. Offenders will be held liable for the
%      payment of damages. All rights reserved in the event of the grant
%      of a patent, utility model or design.
% See also: CreateOEMexport

%% Check if the VMCSim BL is in Path
try
    CoreDir = getCoreDir;     %#ok<NASGU>
catch
    addpathVMCSim;
end

% Parse the Arguments to accomodate call from CMD or MATLAB
if nargin == 1
    varargin_ = strsplit(varargin{1}, ',');
elseif nargin > 1
    varargin_ = varargin;
else
    varargin_ = [];
end

%% Set default variables & accept the inputs 
evalin('base','clear all');
VMCIntegration = '';

for h_=2:2:numel(varargin_)
    switch lower(varargin_{h_-1})
        case 'type'
            if ischar(varargin_{h_}) && ismember(lower(varargin_{h_}),{'lmc','dadc'})
                VMCIntegration = varargin_{h_};
            else
                error('The input argument given for vmc_integration : %s has to be Character Array with either DADC or LMC! Aborting...' ,varargin_{h_});
            end
        case 'newname'
            if ischar(varargin_{h_}) && startsWith(lower(varargin_{h_}),{'lmc','dadc'}) && numel(varargin_{h_})<30
                Instance_NewName = varargin_{h_};
            else
                error('The input argument given for instance_newname : %s has to be Character Array starting with DADC or LMC & Character length should not exceed 29! Aborting...' ,varargin_{h_});
            end
        case 'pathtozip'
            if ischar(varargin_{h_}) && exist( varargin_{h_},'file')==2 && endsWith(lower(varargin_{h_}),'.zip')
                OMCL_Path = varargin_{h_};
                OMCL_Path = strrep(OMCL_Path, '\\', filesep);
                OMCL_Path = strrep(OMCL_Path, '/', filesep);
            else
                error('The input argument given for omcl_path : %s has to be Character Array Or does not exist Or is not a zip file! Aborting...' ,varargin_{h_});
            end
        case  'jsonfile'
            if ischar(varargin_{h_})  && exist( varargin_{h_},'file')==2 && endsWith(lower(varargin_{h_}),'.json')
                IntegrationFname = varargin_{h_};
            else
                error('The input argument given for ConfigFile %s is not valid ...' ,varargin_{h_});
            end
        otherwise
            warning('Unknown argument "%s" passed! Ignoring ...', varargin_{h_-1});
    end
end


if exist('IntegrationFname','var')
	[VMCIntegration,Instance_NewName,OMCL_Path] = get_IntegrationDetails(IntegrationFname);
end
try    
    if ~exist('VMCIntegration','var') && ~exist('Instance_NewName','var') && ~exist('OMCL_Path','var')
        error('Atlease 3 inputs OMCL_Path,VMCIntegration,Instance_NewName are necessary to proceed.')
    end
    
    %% Process the inputs
    switch lower(VMCIntegration)
        case 'dadc'
            VMCPath = 'VMC\DADC_LMC\DADC';
            simfile_flag = false;
        case 'lmc'
            VMCPath = 'VMC\DADC_LMC\LMC';
            simfile_flag = true;
            simfilePath = fileparts(OMCL_Path);
            simfilePath = dir(fullfile(simfilePath,'**\*.sim'));
            if numel(simfilePath)==1
                simfile = fullfile(simfilePath.folder,simfilePath.name);
            else
                error('No SIM File found for the current Software in %s!Aborting ...',fileparts(OMCL_Path))
            end
    end
    
    if exist(fullfile(VMCPath,Instance_NewName),'file')== 7
        files = dir(fullfile(VMCPath,Instance_NewName));
        if any(ismember({files.name},'infofile.json'))
            error('The Instance %s already exists & Integrated into VMCSIM.',fullfile(VMCPath,Instance_NewName))
        else
            warning('The Folder %s already exists but not Integrated into VMCSIM.Deleting the folder...',...
                fullfile(VMCPath,Instance_NewName))
            rmdir(fullfile(VMCPath,Instance_NewName),"s");
        end
    end
    
    %% Clone the Latest Instance of the Steering Controller
    RequiredInfoFile = infofile_read(VMCPath);
    Last_Instance = RequiredInfoFile.variants{end};
    Last_InstancePath = fullfile(VMCPath,Last_Instance);
    cloneInstance('srcFolder',Last_InstancePath, ...
        'Parent', VMCPath, 'Name', Instance_NewName)
    
    %% Modify the OMCL with the Artefacts to be integrated
    modifyVMCInstance('Path', fullfile(VMCPath,Instance_NewName),...
        'Data', OMCL_Path,...
        'Overwrite', 'none')
    
    %% get details of different interfaces else issue the error with the difflist.
    VersionInfo = infofile_read(fullfile(VMCPath,Instance_NewName));
    SigList = {VersionInfo.mapping.pre.usedSignal};
    NeededSig = {VersionInfo.mapping.pre.neededSignal};
    if any(contains(SigList,'__I_AM_A_PLACEHOLDER_'))
        UnmappedSig = NeededSig(contains(SigList,'__I_AM_A_PLACEHOLDER_'));
        disp('The Unmapped/New Signals are: ')
        disp(UnmappedSig')
        removeInstance('path',fullfile(VMCPath,Instance_NewName))
        error('The Current Version to be integrated: %s has unmapped/new interfaces.Please Contact SIM TEAM. Aborting...',Instance_NewName)
    end
    basicCheck()
    
    %% Integrated the SIM File into the LMC
    if simfile_flag
        copyfile(simfile,fullfile(VMCPath,Instance_NewName,'Files','Master.sim'))
        load_system(fullfile(VMCPath,Instance_NewName,[Instance_NewName,'.mdl']))
        myBlock = find_system([bdroot,'/Runnable'],'LookUnderMasks','on','FollowLinks', 'off','BlockType','SubSystem','Mask','on');
        myHandle_ =getSimulinkBlockHandle(myBlock);
        % Set parameters
        mask_object = get_param(myHandle_, 'MaskObject');
        mask_object.Parameters(14).Value = 'on';
        mask_object.Parameters(15).Value = fullfile(VMCPath,Instance_NewName,'Files','Master.sim');
        close_system(fullfile(VMCPath,Instance_NewName,[Instance_NewName,'.mdl']),1);
        bdclose all
    end
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp(['Integrated ',num2str(Instance_NewName),' as New VMC Instance in Path ',fullfile(pwd,VMCPath)])
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    
    %% Additional Operations
    vmcsimgui_decision
catch ME
    %Call the gui to show the newly integrated instance
    vmcsimgui_mainIntegration
    rethrow(ME);
end
end

function [VMCIntegration,Instance_NewName,OMCL_Path] = get_IntegrationDetails(IntegrationFname)
% Json File would be the input for this function and it would consider the
% parameters to read throgh and extract necessary information .
Contents = readJson(IntegrationFname) ;

if ischar(Contents.Component) && ismember(lower(Contents.Component),{'lmc','dadc'})
    VMCIntegration = Contents.Component;
else
    error('The input argument given for Component : %s has to be Character Array with either DADC or LMC! Aborting...' ,Contents.Component);
end

if ischar(Contents.NewName) && startsWith(lower(Contents.NewName),{'lmc','dadc'}) && numel(Contents.NewName)<30
    Instance_NewName = Contents.NewName;
else
    error('The input argument given for NewName : %s has to be Character Array starting with DADC or LMC & Character length should not exceed 29! Aborting...' ,Contents.NewName);
end

if ischar(Contents.OMCL_Delivery_Path) && exist(Contents.OMCL_Delivery_Path,'file')==2 && endsWith(lower(Contents.OMCL_Delivery_Path),'.zip')
    OMCL_Path = Contents.OMCL_Delivery_Path;
    OMCL_Path = strrep(OMCL_Path, '\\', filesep);
    OMCL_Path = strrep(OMCL_Path, '/', filesep);
else
    error('The input argument given for omcl_path : %s has to be Character Array Or does not exist Or is not a zip file! Aborting...' ,Contents.OMCL_Delivery_Path);
end

if ischar(Contents.CommitId) && (numel(Contents.CommitId)==7 || numel(Contents.CommitId)==40)
    Integration_CommitId = Contents.CommitId;
else
    error('The input argument given for Integration_CommitId : %s has to be Character Array with 7 or 40 characters! Aborting...' ,Contents.CommitId);
end

switch lower(VMCIntegration)
    case 'dadc'
        IntegrationRepo = [extractBefore(OMCL_Path,'vmc_simulink_aos'),'vmc_simulink_aos'];
    case 'lmc'
        IntegrationRepo = [extractBefore(OMCL_Path,'lmc_integration'),'lmc_integration'];
end

CurrDir = pwd ;
cd(IntegrationRepo)
[~,commitId] = system('git rev-parse HEAD');
if ~strcmp(strtrim(commitId),Integration_CommitId)
    system('git checkout .'); %discarding any changed files from the path
    system('git fetch --all');
    system(['git checkout ',Integration_CommitId]);
end
cd(CurrDir)
end
