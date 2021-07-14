function CreateOEMexport(varargin)
% CreateOEMexport - Create OEM Export for VMCSim_JLR in the destination
% folder given as input .
%
%%%%%%%%%%%%%%%%%%%%%%%%%   Note   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The Released Instances to be shared with JLR should be updated in a file
% JLR_Used_Instance.json inside <Repository>/doc Folder.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Description:
%    This Function checks if Repository is clean to start the process.
%    It Copies the used BL of vmcsim.core to the src_cm4sl .It deletes the
%    unused instances from the Export. In Vehicle, for all the Top Level it
%    converts the ModelReferences to ProtectedModel and deletes the
%    ModelReferences. Delete the files from <vmcsim.core> & JLR Repository.
%    Deletes the Unused Library Components from Brake and Steering Lib.
%    It deletes Test Repositories added as Submodules except Simple_Tests
%    where it will checkout the OEM Testruns directly. It does Pcode of the
%    necessary mfiles with help text. Open_VMC_Sim_environment.bat is
%    updated for OEM. Zip the Files in the Selected Directory.
%
% Syntax:
%  CreateOEMexport('TestRepoCommitId' , TestRepoCommitId,...
%                   'OEMPath' ,  path_to_store,...
%                   'AutoRun' , 'True',...
%                   'ConfigFile' , 'path to config json file')
%
% Inputs:
%   TestCommitId :  Optional Input. If not given as input then default
%                    commit id 'b3f0506' will be used . << character >> .
%   path2store   :  Optional Input. If not passed as input then popup will
%                    will come to select the folder.
%   AutoRun      :  Optional Input . If Set as True, Once Successful Export
%                    is created then Tests to be executed in Headless mode.
%   ConfigFile   :  Optional Input. If not passed as input then MLA High
%                    will be considered as default Config for Execution.
%
% Example FunctionCall:
%      CreateOEMexport()
%      CreateOEMexport('TestRepoCommitId','b3f0506')
%      CreateOEMexport('OEMPath','D:\Refactor\RefactorOEM')
%      CreateOEMexport('TestRepoCommitId','b3f0506',...
%                       'OEMPath','D:\Refactor\RefactorOEM')
%      CreateOEMexport('TestRepoCommitId','3736996',...
%                       'OEMPath','D:\Refactor\RefactorOEM',...
%                       'AutoRun' , true , 'ConfigFile',...
%                   'TestConfig\D7u_MY23_L663\D7u_MY23_Release_Drive.json')
%
%   Copyright:
%    © 2021 Robert Bosch GmbH
%
%    The reproduction, distribution and utilization of this file as
%    well as the communication of its contents to others without express
%    authorization is prohibited. Offenders will be held liable for the
%    payment of damages. All rights reserved in the event of the grant
%    of a patent, utility model or design.

%% Progressbar Initialise
fig = uifigure;
d = uiprogressdlg(fig,'Title','Please Wait',...
    'Message','Opening the OEM Export Copy','Cancelable','on');

%% Set default variables & accept the inputs
Testcommit = '3736996' ;
AutoRun = 0 ; %Do Not Run the Tests Automatically
ConfigFile = 'TestConfig\MLA-High_L460\MLA-High_Release_Drive.json';
if nargin > 1
    for h_=2:2:numel(varargin)
        switch lower(varargin{h_-1})
            case 'testrepocommitid'
                if ischar(varargin{h_}) && (numel(varargin{h_})==7 || numel(varargin{h_})==40)
                    Testcommit = varargin{h_};
                else
                    error('The input argument given for TestRepoCommitId - %s has to be Character Array of either 7 or 40 characters! Aborting...' ,varargin{h_});
                end
            case 'oempath'
                if ischar(varargin{h_}) && exist( varargin{h_},'file')==7
                    path2store = varargin{h_};
                    path2store = strrep(path2store, '\\', filesep);
                    path2store = strrep(path2store, '/', filesep);
                    if endsWith(path2store, filesep)
                        path2store= path2store(1:end-1);
                    end
                    fprintf("The OEM Copy will be created in %s folder .\n",path2store)
                else
                    warning('The input for the Path given is not character array or does not exist! Please Select it Manually...');
                    path2store = uigetdir(pwd,'Select the directory to store OEM Export.');
                    fprintf("The OEM Copy will be created in %s folder .\n",path2store)
                end
            case 'autorun'
                if islogical(varargin{h_})
                    AutoRun = varargin{h_} ;
                else
                    warning('The input for AutoRun : %s is not logical.Setting AutoRun as False.', string(varargin{h_}));
                end
            case  'configfile'
                if ischar(varargin{h_})  && exist( varargin{h_},'file')==2 && endsWith(varargin{h_},'.json')
                    ConfigFile = varargin{h_};
                else
                    error('The input argument given for ConfigFile %s is not valid ...' ,varargin{h_});
                end
            otherwise
                warning('Unknown argument "%s" passed! Ignoring ...', varargin{h_-1});
        end
    end
end

if ~exist('path2store','var')
    path2store = uigetdir(pwd,'Select the directory to store OEM Export.');
    if path2store == 0
        % User clicked Cancel
        return;
    end
    fprintf("The OEM Copy will be created in %s folder .\n",path2store)
end

%Removing the Previous OEMexport if exists
if exist(fullfile(path2store,'JLR_VMCSim_Export.zip'),'file')==2
    delete(fullfile(path2store,'JLR_VMCSim_Export.zip'));
end

% ProgressBar Update
d.Message = [d.Message '...done!', newline, 'ExportPath ',path2store,newline,'OEM Test Commit Id:',Testcommit];
if d.CancelRequested
    return;
end

try
    CurrWorkDir = pwd ;
    %% Get the User Details
    ExecutedBy = getenv('username');
    [~,userName]  = system('git config --get user.name');
    d.Message = [d.Message,newline,'The OEM Export is performed by :',ExecutedBy];
    %Updating the Msg Contents to be written to Log File
    Msg{1} = "'************************        OEM EXPORT Log File        ************************'";
    Msg{end+1} = [newline,newline,'PreCheck Before Export Preparation : '];
    Msg{end+1} = [newline,newline,'The OEM Export is performed by - < ',ExecutedBy,' > - ',strtrim(userName)];
    Msg{end+1} = [newline,'OEM Export started at : ',datestr(now, 'dd/mm/yy - HH:MM:SS'),' .'];
    %% Git Related Precheck
    [~,branchName] = system('git branch --show-current');
    [~,commitId] = system('git rev-parse HEAD');
    branchName = strtrim(branchName);
    commitId = strtrim(commitId);
    d.Message = [d.Message,newline,'Branch :',branchName,newline,' Commit_id :',commitId];
    d.Message = [d.Message,newline,'Verifying Git Status'];
    Msg{end+1} = [newline,'The OEM Export is performed on ',newline,'Branch : ',branchName,newline,'Commit_id : ',commitId];
    %% Git Status Check for Clean Repository
    [~,status]    = system('git status');
    %check if the repo is clean or not , if not then give error message
    assert(~any(contains(split(status,newline),'Changes not staged for commit:')),'The Working Copy is not clean.Aborting...!!!');
    assert(~any(contains(split(status,newline),'Untracked files:')),'The Working Copy has Untracked Files.Aborting...!!!');
    d.Message = [d.Message '...done !', newline,'Checking Current Directory & vmcsim.core '];
    Msg{end+1} = [newline,'Git status is verified. There is no Modified Files & Untracked files.',newline,'Git status is - ',newline,status];
    %% Checking the directory is src_cm4sl or not & vmcsimcore exists or not
    %Abort if the current directory is not src_cm4sl
    assert(strcmp(reverse(strtok(reverse(pwd),filesep)),'src_cm4sl'),'The Current Directory is %s.It should be at src_cm4sl.Aborting...!!!',pwd)
    %Abort if the vmcsimcore doesnot exist in path.
    assert(exist([getCoreDir(), 'vmcsim.core'],'dir')==7,'The following directory %s does not exist.Please Check the Configuration.Aborting...!!!',getCoreDir())
    Msg{end+1} = [newline,'The Current working Directory is ',pwd,newline,'The vmcsimcore is checked out from ',getCoreDir(),'vmcsim.core .'];
    %% Check the Released Instance data file exists or not
    assert(exist('../doc/JLR_Used_Instance.json','file')==2,'Released Instance Information File : ../doc/JLR_Used_Instance.json does not exist.Aborting...!!!')
    %% Check if MingW64 installed for protected model creation
    assert(exist('C:\TCC\Tools\mingw64','file')==7,'Mingw64 Installation does not exist.Aborting...!!! ');
    d.Message = [d.Message '...done !', newline,'Fetching all the SubModules '];
    d.Value   = 0.025;
    %% Gather the Inforamtion of all the Submodules added and Checkout OEM Tests from simple_tests directly
    [~,submoduleStatus] = system('git submodule foreach "git status"');
    submoduleStatus = split(submoduleStatus,newline);
    submoduleStatus = submoduleStatus(contains(submoduleStatus,'Entering ''../'));
    
    for i = 1:numel(submoduleStatus)
        submodule = strrep(reverse(strtok(reverse(submoduleStatus{i}),' ')),"'","")   ; %remove the  ' '  from the git status message
        TestRepo(i).path = submodule; %#ok<AGROW>
        if ~contains(submodule,"vmc_sim_simple_tests")
            TestRepo(i).ToDelete = 1; %#ok<AGROW>
        elseif contains(submodule,"vmc_sim_simple_tests")
            currDir = pwd;
            cd (fullfile(pwd,submodule))
            Msg{end+1} = [newline,'In Submodule : ',submodule,' to checkout the OEM TestRuns directly.'] ; %#ok<AGROW>
            [~,SimpleTestCId] = system('git rev-parse HEAD');
            SimpleTest.Path = pwd;
            SimpleTest.CommitId =strtrim(SimpleTestCId);
            system('git checkout .'); %clearing files from the path
            system('git fetch --all');
            %checkout the commit id for the oem copy
            Msg{end+1} = [newline,"Checking out the OEM Commit Id: ",Testcommit];%#ok<AGROW>
            system(['git checkout ',Testcommit]);
            TestRepo(i).ToDelete = 0; %#ok<AGROW>
            cd (currDir);
        else
            warning ([newline,'While trying to remove the submodule',submodule,'Facing Issue .']);
        end
    end
    
    %% Directory to Copy the data
    tempDir = getenv('temp');
    RepoName = reverse(strtok(reverse(fileparts(pwd)),filesep));
    tempDir = fullfile(tempDir,RepoName);
    
    if ~(exist(tempDir,'file')==7)
        mkdir(tempDir)
    else
        rmdir(tempDir,"s")
        mkdir(tempDir)
    end
    Msg{end+1} = [newline,newline,'Copying Contents to : ',tempDir];
    % ProgressBar Update
    d.Message = ['PreRequisites are verified for Export.',newline,'Copying all data to ',tempDir];
    d.Title = 'Copy Contents for Export' ;
    d.Value   = 0.10;
    if d.CancelRequested
        return;
    end
    %% Copy the Contents to Temp Folder without .git Files
    RepoContents = dir(fullfile(pwd,'..\'));
    %Remove the .git not to be copied
    RepoContents = RepoContents(~ismember({RepoContents.name}, {'.', '..','.git'}));
    
    for idx = 1:length(RepoContents)
        FName = fullfile(RepoContents(idx).folder,RepoContents(idx).name) ;
        FileSeg = split(FName,[RepoName,filesep]) ;
        if ~(exist(fullfile(tempDir,FileSeg{2}),"file")>0)
            copyfile(FName,fullfile(tempDir,FileSeg{2})) ;
        end
    end
    d.Message = [d.Message '...done !', newline,'Taking SimpleTest to Original Commit Id. '];
    %% Changing the Simple Test Commit Id to Previus after Copy
    cd (SimpleTest.Path)
    system(['git checkout ',SimpleTest.CommitId]);
    
    %Changing the directory for all subtasks
    cd (fullfile(tempDir,'src_cm4sl'))
    
    d.Message = [d.Message '...done !', newline,'Deleting .git related Files '];
    %% Delete all the .git related Files still there
    GitFiles = dir(fullfile(pwd,'..\','**\*.git*'));
    GitfileList = fullfile({GitFiles.folder}, {GitFiles.name});
    if ~isempty(GitfileList)
        Msg{end+1} = [newline,'Deleting all the .git related files .'];
        delete(GitfileList{:});
    end
    
    % ProgressBar Update
    d.Message = [d.Message '...done!',newline,'Reading JLR_Used_Instance.json.'];
    d.Title = 'Making Contents Ready for Export !' ;
    d.Value = 0.125;
    if d.CancelRequested
        return;
    end
    
    %% Getting the Released Information from the json file
    ReleasedInstances = readJson(fullfile(pwd,'../doc/JLR_Used_Instance.json'));
    Origin = fieldnames(ReleasedInstances) ;
    
    %% Copy SimCore to src_cm4sl
    copyfile([getCoreDir(), 'vmcsim.core'],fullfile(pwd, 'vmcsim.core'));
    Msg{end+1} = [newline,'VMCSimCore is copied to ',fullfile(pwd, 'vmcsim.core'),' .'];
    d.Value = 0.15 ;
    %% Delete the Submodules & Clean TestRun Folder
    d.Message = [d.Message '...done',newline,'Removing all the Testrun submodules'];
    
    for i = 1:length(TestRepo)
        if TestRepo(i).ToDelete && (exist(fullfile(pwd,TestRepo(i).path),'file')==7)
            rmdir(fullfile(pwd,TestRepo(i).path),"s")
            Msg{end+1} = [newline,"Removing the Folder - ",TestRepo(i).path];%#ok<AGROW>
        end
    end
    
    TestRunFolder = dir(fullfile(pwd,fileparts(TestRepo(~[TestRepo.ToDelete]).path))) ;
    TestRunFolder = TestRunFolder(~ismember({TestRunFolder.name},{'.','..','vmc_sim_simple_tests',...
        'F3_3041_0001_DriverInteraction_Accelerating_AboveActLong'}));
    TestRunFolder = fullfile({TestRunFolder.folder},{TestRunFolder.name});
    for i = 1 : numel(TestRunFolder)
        switch exist(TestRunFolder{i},'file')
            case 2
                delete(TestRunFolder{i});
            case 7
                rmdir(TestRunFolder{i},"s");
        end
    end
    
    %% Unused Instance Removal and Convert to Protected Model Operation
    d.Message = 'Protected Model Creation and Instance Removal will start.';
    d.Cancelable = 'off';
    
    for i_ = 1:numel(Origin)
        switch Origin{i_}
            case 'VMC' %analyze the top level VMC & get the list of Component and Instances
                for j_ =1:numel(ReleasedInstances.VMC)
                    VMC_TL = ReleasedInstances.VMC{j_};
                    TL_Name = fieldnames(VMC_TL) ;
                    for k_ = 1:numel(VMC_TL.(TL_Name{1}).Component)
                        ComponentJson = fullfile('VMC',TL_Name{1},(VMC_TL.(TL_Name{1}).Component{k_}),'infofile.json');
                        [Msg,d] = cleanComponent(ComponentJson,VMC_TL.(TL_Name{1}).ReleasedInstances,Msg,d) ; %Remove the Unused Instances
                        CleanComponentFolder(fileparts(ComponentJson),VMC_TL.(TL_Name{1}).ReleasedInstances)
                    end
                end
            case 'Vehicle'
                for j_ =1:numel(ReleasedInstances.Vehicle)
                    Veh_TL = ReleasedInstances.Vehicle{j_};
                    TL_Name = fieldnames(Veh_TL) ;
                    for k_ = 1:numel(Veh_TL.(TL_Name{1}).Component)
                        ComponentJson = fullfile('Vehicle',TL_Name{1},(Veh_TL.(TL_Name{1}).Component{k_}),'infofile.json');
                        % Clean the Instances of the Vehicle which are not used
                        [Msg,d] = cleanComponent(ComponentJson,Veh_TL.(TL_Name{1}).ReleasedInstances,Msg,d); %Remove the Unused Instances
                        CleanComponentFolder(fileparts(ComponentJson),Veh_TL.(TL_Name{1}).ReleasedInstances)
                        % Convert the Model Reference to Protected Model
                        % excpet Body Component as it does not have any model
                        if ~contains((Veh_TL.(TL_Name{1}).Component{k_}),'Body')
                            [Msg,d] = Convert2Protected(Veh_TL.(TL_Name{1}).Component{k_},ComponentJson,Msg,d); %Convert to protected Model
                        end
                    end
                end
        end
    end
    d.Value   = 0.75;
    d.Message = 'Unused Instances Removed & Protected Models Created.';
    
    % vmcsim.core is removed from path to avoid shadowing error for library
    % to be deleted below.
    lastwarning = lastwarn('');
    warning('off','MATLAB:rmpath:DirNotFound');
    rmpath(genpath(fullfile(getCoreDir(),'vmcsim.core')));
    lastwarn(lastwarning);
    warning('on','MATLAB:rmpath:DirNotFound');
    
    d.Message = [d.Message '...done',newline,'Removing Unused Library.'];
    %% library to be opened and to be deleted from vmcsimcore & Steering.
    BrakeLib = fullfile(pwd,'vmcsim.core\ModelLibrary\Brake\SimpleBrake\Model\Files\simplebrake_plantmodel_lib.slx');
    SteeringLib = dir(fullfile(pwd,'Vehicle','**\Paket_BoschCC','**\EPS_JLR_D7u2_Lib*.mdl')) ;
    SteeringLib = fullfile({SteeringLib.folder},{SteeringLib.name}) ;
    Lib = [BrakeLib,SteeringLib];
    
    for i =  1:numel(Lib)
        load_system(Lib{i})
        libname =  bdroot ;
        set_param(libname,'Lock','off')
        if startsWith(libname,'EPS_')
            SubSysAll = find_system(libname,'LookUnderMasks', 'all','BlockType','SubSystem');
            SubSys_2Del = {'Example Model','Example Model For Fixed Step Solvers',...
                'Components/Simple Rack','Components/Utilities/BUS','Components/Utilities/STW'};
            Blocks2Del = SubSysAll(endsWith(SubSysAll,SubSys_2Del));
            delete_block(Blocks2Del);
            Msg{end+1} = [newline,'Deleted Unused Library blocks from ',Lib{i}];%#ok<AGROW>
        elseif startsWith(libname,'simplebrake')
            TopLevel1 = find_system(libname,'LookUnderMasks', 'all','SearchDepth', 1,'BlockType','SubSystem');
            TopLevel21 = find_system(libname,'LookUnderMasks', 'all','SearchDepth', 2,'BlockType','SubSystem');
            TopLevel22 = find_system(libname,'LookUnderMasks', 'all','SearchDepth', 2,'BlockType','S-Function');
            TopLevel2 = [TopLevel21;TopLevel22];
            SubSys = setxor(TopLevel1,TopLevel2);
            Exclude_SubSys_FromDel = {'SimpleTCS';...
                'brakePedal2pMC'};
            Blocks2Del = SubSys(~contains(SubSys,Exclude_SubSys_FromDel));
            delete_block(Blocks2Del);
            Msg{end+1} = [newline,'Deleted Unused Library blocks from ',Lib{i}];%#ok<AGROW>
        end
        set_param(libname,'Lock','on')
        close_system(libname,1)
    end
    Msg{end+1} = [newline,newline,'Deleting Below Contents:'];
    d.Message = [d.Message '...done',newline,'Removing Vehicle Related Files.'];
    %% Vehicle Files to be removed
    VehicleContents2Remove = {'Example_TCGPark_Standard.mdl';...
        'EPB_controller.slxp';...
        'Example_TCGPark_Standard_CarMaker_rtw';...
        'Vehicle\**\slprj';...
        'Example_TCGDrive_Highway.mdl';...
        'Example_TCGDrive_Highway_CarMaker_rtw';...
        'Paket_BoschCC\doc';...
        '*.mdl.r20*'};
    VMCContents2Remove = {'LOG_*.txt'};
    Contents2Remove = [VehicleContents2Remove;VMCContents2Remove];
    for i_ = 1:numel(Contents2Remove)
        ContentsFiles = dir(fullfile(pwd,'**\',Contents2Remove{i_}));
        if any([ContentsFiles.isdir])
            FolderName = intersect({ContentsFiles.folder},{ContentsFiles.folder});
            for j_ = 1:numel(FolderName)
                if contains(FolderName,'Paket_BoschCC\doc')
                    Exceptions = {'Main.html','.','..'};
                    docfiles = dir(FolderName{j_});
                    docfiles = docfiles(~ismember({docfiles.name},Exceptions));
                    docfiles = fullfile({docfiles.folder},{docfiles.name});
                    for k_ = 1:numel(docfiles)
                        switch exist(docfiles{k_},'file')
                            case 7
                                rmdir(docfiles{k_},"s")
                            case 2
                                delete(docfiles{k_})
                            otherwise
                                warning('File %s does not exist.',docfiles{k_})
                        end
                    end
                else
                    rmdir(FolderName{j_},"s")
                end
            end
        else
            Files = fullfile({ContentsFiles.folder},{ContentsFiles.name}) ;
            if ~isempty(Files)
                delete(Files{:});
            end
        end
    end
    d.Message = [d.Message '...done',newline,'Removing the Not Required Files.'];
    d.Value   = 0.80;
    %% Create a common Structure to remove all the above files retaining the Folder Structure
    % List down the files for Removal from the OEM Copy
    ContentsToRemove = GetAllFilestoDelete();
    
    for k_ = 1:numel(ContentsToRemove)
        switch exist(fullfile(pwd,ContentsToRemove{k_}),'file')
            case 7
                which_dir = fullfile(pwd,ContentsToRemove{k_});
                Msg{end+1} = [newline,'Trying to remove the folder Contents from ',which_dir,' .'];%#ok<AGROW>
                dirInfo = dir(fullfile(which_dir,'**\*'));
                dirInfo([dirInfo.isdir]) = [];   %skip directories
                fileList = fullfile({dirInfo.folder}, {dirInfo.name});
                % For the Road Folder we can not delete all the files for the oem copy so need to call another function
                if contains(which_dir,'Data\Road')
                    Msg = CleanRoadFolder(fileList,Msg);
                    %Update the Files which needs to be completely removed
                    %instead of nested folder structure
                elseif contains(which_dir,{'src_cm4sl\Results\Build','src_cm4sl\Results\headless',...
                        'src_cm4sl\SimulinkCache\slprj','src_cm4sl\..\SimOutput','src_cm4sl\src',...
                        'src_cm4sl\Results\Measurements','src_cm4sl\Vil','Movie\.road_cache'})
                    rmdir(which_dir,"s")
                elseif ~isempty(fileList)
                    delete(fileList{:})
                else
                    disp(['Can not Delete ',which_dir, 'as it may be Empty. \n']);
                end
            case {2,3}
                Msg{end+1} = [newline,'Trying to remove the file ',ContentsToRemove{k_}];%#ok<AGROW>
                delete(fullfile(pwd,ContentsToRemove{k_}));
            otherwise
                Msg{end+1} = [newline,'The file ',ContentsToRemove{k_},' does not exist in Path .'];%#ok<AGROW>
                disp(['Cannot Delete ',ContentsToRemove{k_},' as it does not exist.']);
        end
    end
    d.Message = [d.Message '...done',newline,'Removing all the .json Files & .mdl Files from vmcsim.core',...
        newline,'Removing Saf,PRT,SimConfig,Log,PDB Files'];
    %% list down all the .json files &  .mdl files from the vmcsimcore/ModelLibrary & delete them from Export
    rootdir = fullfile(pwd,'vmcsim.core','ModelLibrary') ;
    
    Jsonfilelist  = dir(fullfile(rootdir,'**\*.json'));
    JsonFile = fullfile({Jsonfilelist.folder},{Jsonfilelist.name}) ;
    
    % list mdl files
    Mdlfilelist  = dir(fullfile(rootdir,'**\*.mdl'));
    MdlFile = fullfile({Mdlfilelist.folder},{Mdlfilelist.name}) ;
    
    %List down .saf Files if any in the directory
    SafFileList = dir(fullfile(pwd,'..\**\*.saf'));
    PRTfiles    = dir(fullfile(pwd,'Log_Exe_*.prt')) ;
    SimConfig   = dir(fullfile(pwd,'Sim_ExeConfig*.txt')) ;
    PDBFiles    = dir(fullfile(pwd,'PDB_*.txt'));
    UserTxtFiles= dir(fullfile(pwd,'..\**\.user*.txt')) ;
    DummyFiles = [SafFileList;PRTfiles;SimConfig;PDBFiles;UserTxtFiles];
    DummyFiles = fullfile({DummyFiles.folder},{DummyFiles.name}) ;
    
    %delete the files
    if ~isempty(JsonFile)
        Msg{end+1} = [newline,'Deleting all the .json related files from Model Library .'];
        delete(JsonFile{:});
    end
    if ~isempty(MdlFile)
        Msg{end+1} = [newline,'Deleting all the .mdl related files from Model Library.'];
        delete(MdlFile{:});
    end
    if ~isempty(DummyFiles)
        Msg{end+1} = [newline,'Deleting all the .saf related files .'];
        delete(DummyFiles{:});
    end
    
    d.Message = [d.Message '...done',newline,'Converting Files to pCode'];
    Msg{end+1} = [newline,newline,'Creating Final Export : '];
    %% Pcode Necessary Files
    pCodeFiles = {'vmcsim.core\ModelLibrary\TCGDrive\Highway\Files\TCG_checkIfLaneDrivable.m';...
        'vmcsim.core\ModelLibrary\TCGDrive\Highway\Files\TCG_checkIfLaneFree.m';...
        'vmcsim.core\ModelLibrary\TCGDrive\Highway\Files\TCG_getLineY.m';...
        'Close.m';...
        'CreateOEMexport.m'};
    
    for i = 1:numel(pCodeFiles)
        Msg{end+1} = [newline,'Pcoding the File - ',pCodeFiles{i}];%#ok<AGROW>
        CustompCode(fullfile(pwd,pCodeFiles{i}))
    end
    d.Message = [d.Message '...done',newline,'Changing the batch file & retaining the batfile.'];
    
    %% Make gui argument as %execution’ in the file Open_VMC_Sim_environment.bat
    BatFile = '..\Open_VMC_Sim_environment.bat' ;
    BatContent = fileread(fullfile(pwd,BatFile)) ;
    BatContent = split(BatContent,newline);
    fid = fopen(fullfile(pwd,BatFile), 'w');
    assert(fid>0,sprintf('Could not open "%s" with write permissions! Aborting ...',BatFile))
    PatternCheck = {'SET test_=';...
        'SET gui_='};
    for i_=1:numel(BatContent)
        if ~contains(BatContent{i_},PatternCheck)
            fprintf(fid, '%s\n',BatContent{i_});
        else
            String = lower(strtrim(BatContent{i_}));
            switch [strtok(String,'='),'=']
                case lower(PatternCheck{1})
                    ChangedText = strrep(BatContent(i_),...
                        reverse(strtok(reverse(strtrim(BatContent{i_})),'=')),...
                        'vmc_sim_simple_tests/VMC_Delivery_JLR.ts');
                case lower(PatternCheck{2})
                    ChangedText = strrep(BatContent(i_),'decision','execution');
            end
            fprintf(fid, '%s\n', ChangedText{1});
        end
    end
    Msg{end+1} = [newline,'Modified Open_VMC_Sim_environment.bat file '];
    fclose(fid);
    %% Keep the Original par File Copy of Steering and UserAdded Param
    ParFilePath =  dir(fullfile(pwd,'Vehicle','**\Paket_BoschCC','**\ParMech*.par'));
    UserParPath = dir(fullfile(pwd,'Vehicle','**\.userAddedParameters.txt'));
    ParFile = [ParFilePath;UserParPath];
    ParFile = fullfile({ParFile.folder},{ParFile.name}) ;
    
    for i = 1 : numel(ParFile)
        RelativeParPath = split(ParFile{i},'src_cm4sl\');
        delete(ParFile{i});
        copyfile(fullfile(CurrWorkDir,RelativeParPath{2}),fullfile(pwd,RelativeParPath{2}))
    end
    %% Zip the Files in the Selected Directory
    d.Message = [d.Message '...done',newline,'Creating the Export in ',fullfile(path2store,'JLR_VMCSim_Export.zip')];
    d.Value   = 0.825;
    
    % Wrap folder in zip container
    zip(fullfile(path2store,'JLR_VMCSim_Export.zip'),fullfile(pwd,'..\*'));
    
    cd (CurrWorkDir)
    % Open folder
    winopen(path2store);
    
    %Try to Remove the directory
    try
        rmdir(tempDir,"s")
    catch
        evalin('base','clear all')
        evalin('base','bdclose all')
        rmdir(tempDir,"s")
    end
    
    Msg{end+1} = [newline,newline,'OEMCopy Successfully created at ',fullfile(path2store,'JLR_VMCSim_Export.zip')];
    Msg{end+1} = [newline,'OEM Export completed at : ',datestr(now, 'dd/mm/yy - HH:MM:SS'),' .'];
    d.Message = [d.Message '...done',newline,'Creating the log File',fullfile(path2store,'OEMExport_Info.txt')];
    d.Value   = 0.95;
    %% Write the messages to OEMExport_Info.txt file.
    writecell(Msg,fullfile(pwd,'OEMExport_Info.txt'))
    if (exist(fullfile(path2store,'OEMExport_Info.txt'),'file')==2)
        delete(fullfile(path2store,'OEMExport_Info.txt'));
    end
    movefile(fullfile(pwd,'OEMExport_Info.txt'),fullfile(path2store,'OEMExport_Info.txt'))
    d.Message = 'OEMExport Creation Successful';
    addpathVMCSim;
    d.Value   = 1;
    close(d)
    close(fig)
    % Create message in command window
    disp([newline,newline,' '])
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('% OEMCopy Creation Successful %')
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp([newline,'NOTES:',newline,'OEM Copy is Created in: ',fullfile(path2store,'JLR_VMCSim_Export.zip')])
    disp('Please add the VMCSim_Release_Sheet for OEM in ..\doc Folder.');
    disp('Please add VMCSim_core_Release.zip for OEM in ..\doc Folder.');
    %% Run the tests Automatically by unzipping the Export.
    if AutoRun && (exist(fullfile(path2store,'JLR_VMCSim_Export.zip'),'file')==2)
        fig = uifigure;
        d = uiprogressdlg(fig,'Title','Please Wait',...
            'Message','Unzipping the Files from the Zip Created');
        d.Value = 0.33;
        if exist(fullfile(path2store,['JLR_VMCSim_Export','AutoRun']),'file')==7
            rmdir(fullfile(path2store,['JLR_VMCSim_Export','AutoRun']),'s');
            if status
                mkdir(fullfile(path2store,['JLR_VMCSim_Export','AutoRun']));
            end
        end
        unzip(fullfile(path2store,'JLR_VMCSim_Export.zip'),...
            fullfile(path2store,['JLR_VMCSim_Export','AutoRun']));
        d.Message = ['Unzipping Successful.',newline,'OEM Export is available in : ',fullfile(path2store,'JLR_VMCSim_Export.zip'),...
            newline,'Configuring the Headless Execution & Running Tests.'];
        d.Value   = 0.66;
        cd (fullfile(path2store,['JLR_VMCSim_Export','AutoRun']))
        system(['Open_VMC_Sim_environment -m headless -c ',ConfigFile,' -f execution -t vmc_sim_simple_tests/VMC_Delivery_JLR.ts'])
        close(d)
        close(fig)
        cd (CurrWorkDir)
    end
catch ME
    close(d)
    close(fig)
    cd (CurrWorkDir)
    addpathVMCSim
    Msg{end+1} = [newline,newline,ME.message];
    %Write the messages to OEMExport_Info.txt file.
    if contains(ME.message,{'The Working Copy has Untracked Files','The Working Copy is not clean'})
        Msg{end+1} = [newline,'The git Status during Exception is : ',newline,status];
    end
    writecell(Msg,fullfile(path2store,'OEMExport_Info.txt'))
    winopen(fullfile(path2store,'OEMExport_Info.txt'));
    rethrow(ME);
end
end

%% Remove the Instances from the Component
function [Msg,d] = cleanComponent(ComponentInfoFile,RlsdInstance,Msg,d)

if exist(ComponentInfoFile, 'file')==2
    Component = readJson(ComponentInfoFile);
else
    error('The File "%s" does not exist. Aborting...',ComponentInfoFile)
end

if numel(Component.variants) > 1
    VariantToDelete = Component.variants(~ismember(Component.variants,RlsdInstance)) ;
    for ii = 1:numel(VariantToDelete)
        path_    = fullfile( Component.parent , Component.name , VariantToDelete{ii} );
        %calling the simcore utility to delete the instance
        Msg{end+1} = [newline,'Removing the Unused Instance  - ',path_]; %#ok<AGROW>
        d.Message = [d.Message ,newline,'Removing: ',path_];
        removeInstance('Path',path_)
    end
end
end

%% Protected Model Creation
%Find the Model Reference & Replace with Protected Model for the Vehicle Top Level
function [Msg,d] = Convert2Protected(VehComponent,ComponentInfoFile,Msg,d)
bdclose('all')
if exist(ComponentInfoFile, 'file')==2
    Component = readJson(ComponentInfoFile);
else
    error('The File "%s" does not exist. Aborting...',ComponentInfoFile)
end
d.Message = [d.Message ,newline,'Protected Model Creation starting in ',VehComponent];
% for each of the existing variant which are used convert to protected model
for variant = 1:numel(Component.variants)
    InstanceFolder = fullfile(Component.parent,VehComponent,Component.variants{variant});
    MdlNames = dir(fullfile(InstanceFolder,[Component.variants{variant},'*']));
    InstanceFolder = [InstanceFolder,filesep,'Files']; %#ok<AGROW>
    
    for i_ = 1:numel(MdlNames)
        CurrentMdl = [MdlNames(i_).folder, filesep ,MdlNames(i_).name];
        load_system(CurrentMdl)
        blocks = find_system(bdroot,'LookUnderMasks','on','FollowLinks','on','BlockType','ModelReference');
        
        for j_ = 1:numel(blocks)
            model = blocks{j_} ;
            Msg{end+1} = [newline,'The Protected Model Creation will start for - ',MdlNames(i_).name,filesep,model]; %#ok<AGROW>
            
            %exclude the protected model by JLR in Powertrain
            if contains(model,'LMC2PTProtectedModel')
                continue
            end
            
            %get the handle name of the block
            handle_ = getSimulinkBlockHandle(model);
            
            %find the name of the referenced model
            OldRefName = get_param(handle_,'ModelName');
            
            %conver the block to protected model
            currdir = pwd ;
            cd (InstanceFolder);
            Simulink.ModelReference.protect(model,'Report',true);
            cd (currdir);
            
            %Replace it with the newly added protected model
            set_param(handle_,'ModelFile',[OldRefName,'.slxp']);
            
            %delete the old .mdl file after conversion to protected model
            delete(fullfile(InstanceFolder,[OldRefName,'.mdl']))
        end
        
        %save and close the system model
        close_system(CurrentMdl,1)
    end
    
    if ~isempty(dir(fullfile(InstanceFolder,'*.slxp')))
        if (exist('C:\TCC\Tools\mingw64\6.3.0_WIN64\MinGW-w64_License_Copyright_Attributions.pdf','file')==2)
            copyfile('C:\TCC\Tools\mingw64\6.3.0_WIN64\MinGW-w64_License_Copyright_Attributions.pdf',...
                fullfile(InstanceFolder,'MinGW-w64_License_Copyright_Attributions.pdf'));
        else
            Msg{end+1} = [newline,'Mingw License File not found in path.Kindly Install TCC - Mingw 6.3.0 version to proceed.Aborting...']; %#ok<NASGU,AGROW>
            error('Mingw License File not found in path.Kindly Install TCC - Mingw 6.3.0 version to proceed. Aborting...');
        end
    end
end
end

%% Function for P Code the Files with help text
function CustompCode(File2pCode)
help_txt = help(File2pCode);
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

%% Clear Road Files
function Msg = CleanRoadFolder(fileList,Msg)

Exceptions = {'Road\JLR\LeftTurn.rd5';...
    'Road\VMC_RBT\RBT_basic_straight_3lane_highway.rd5';...
    'Road\StraightRoad.rd5';...
    'Road\CRA_trial.rd5'};

fileList = fileList(~contains(fileList,Exceptions));
Msg{end+1} = [newline,'From Road Folder Deleting All Files Except ',Exceptions{:}];
delete(fileList{:})
RoadFolders = dir(fullfile(pwd,'..\Data\Road')) ;
RoadFolders = RoadFolders([RoadFolders.isdir]);
RoadFolders = RoadFolders(~ismember({RoadFolders.name},{'.','..'}));
RoadFolders = fullfile({RoadFolders.folder},{RoadFolders.name});
for i = 1 : numel(RoadFolders)
    FolderContents = dir(RoadFolders{i});
    if (length(FolderContents)==2)
        rmdir(RoadFolders{i},"s")
    end
end
end

%% Function to clear unintended Folders kept
function CleanComponentFolder(Folder2Check,RlsdInstance)
Contents = dir(Folder2Check);
Contents = Contents([Contents.isdir]);
Contents = Contents(~ismember({Contents.name},{'.','..','Files'}));
%Removing MeasureAll_lean.cfx from OEM Release Version not to expose the
%available OMCL Signals to OEM
LeanCfxFile = fullfile({Contents.folder},{Contents.name},'Files\MeasureAll_lean.cfx');
for i = 1 : length(LeanCfxFile)
    if exist(LeanCfxFile{i},'file')==2
        delete(LeanCfxFile{i})
    end
end
%Checking if there are some other folders except the Released
Contents2Del = Contents(~ismember({Contents.name},RlsdInstance));
if ~isempty(Contents2Del)
    for i = 1:numel(Contents2Del)
        Folder2Del = fullfile(Contents2Del(i).folder,Contents2Del(i).name);%fullfile({Contents.folder},{Contents.name}) could have been used
        rmdir(Folder2Del,"s")
    end
end
%Removing the Enums Folder from LMC Folder if exists
if strcmp(reverse(strtok(reverse(Folder2Check),filesep)),'LMC')
    EnumFolders = fullfile({Contents.folder},{Contents.name},'Files','Enums');
    for i = 1:numel(EnumFolders)
        if exist(EnumFolders{i},'dir')==7
            rmdir(EnumFolders{i},"s")
        end
    end
end
end

%% List All the Files to be deleted
function ToRemove = GetAllFilestoDelete()
ToRemove = {
    'vmcsim.core\InternalToolbox\trainingmaterial';...
    'vmcsim.core\ModelLibrary\TCGPark\Standard\ShortInstruction.txt';...
    'vmcsim.core\ModelLibrary\TCGDrive\Highway\ShortInstruction.txt';...
    'vmcsim.core\ModelLibrary\TCGDrive\Highway\Files\liblinedetection.a';...
    'vmcsim.core\ModelLibrary\TCGDrive\Highway\Files\LineDetection.h';...
    'vmcsim.core\ModelLibrary\TCGDrive\CRA_extension\ShortInstruction.txt';...
    'vmcsim.core\ModelLibrary\TCGDrive\CRA_extension\Files\FarRangeInfo.h';...
    'vmcsim.core\ModelLibrary\TCGDrive\CRA_extension\Files\libfarrangeinfo.a';...
    'vmcsim.core\ModelLibrary\TCGDrive\Highway\Files\TCGDrive_Highway_lib.slx';...
    'vmcsim.core\ModelLibrary\Misc\BrakeSystemSensors\Model\Files\brakesystemsensors_plantmodel_lib.slx';...
    'vmcsim.core\ModelLibrary\Misc\InertialSensors\Model\Files\InertialSensors_lib.slx';...
    'vmcsim.core\ModelLibrary\Misc\InertialSensors\ReadMe.txt';...
    'vmcsim.core\ModelLibrary\TCGDrive\AES_ESS\ShortInstruction.txt';...
    'vmcsim.core\ModelLibrary\TCGDrive\AES_ESS\Files\TCGDrive_AES_ESS_lib.slx';...
    'vmcsim.core\ModelLibrary\TCGDrive\AES_ESS\Files\libgci.a';...
    'vmcsim.core\ModelLibrary\TCGDrive\AES_ESS\Files\gci.h';...
    'vmcsim.core\VmcSim.Core_Release_Sheet.html';...
    'vmcsim.core\VMC_Sim_Docu_ViL.html';...
    'vmcsim.core\VMC_Sim_Docu_OL.html';...
    '..\doc\JLR_Used_Instance.json';...
    '..\doc\VMCSim_Release_Sheet.html';...
    '..\doc\VMCSim_core_Release.zip';...
    '..\Data\TestRun\vmc_sim_simple_tests\README.md';...
    '..\SimOutput';...
    '..\Open_VMC_Sim_ViL_environment.bat';...
    '..\README.md';...
    '..\Movie\Camera.cfg';...
    '..\Movie\.road_cache';...
    '..\Data\Road';...
    '..\Data\Config\SingleLane.jpg';...
    '..\Data\Config\SingleLane.lcfg';...
    '..\Data\Config\SingleLane_WideBorders.jpg';...
    '..\Data\Config\SingleLane_WideBorders.lcfg';...
    '..\Data\Config\ThreeLanes.jpg';...
    '..\Data\Config\ThreeLanes.lcfg';...
    '..\Data\Vehicle\selectedVehicle';...
    'SimulinkCache\slprj';...
    'SimulinkCache';...
    'Results\Measurements';...
    'Parameters.c';...
    'gmon.out';...
    'src';...
    'Vil';...
    'Results\headless';...
    'Results\Build'};
end
