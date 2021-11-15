function [ok, Msg] = checkForCMReferences(test)
% checkForCMReferences - Check if a CM Testseries only contains existing
% TestRuns and if these TestRuns use the selectedVehicle
%
% Description:
%  This function checks if the provided "test" uses the selectedVehicle.
%  Test can be either a TestRun or a Testseries. In case of a TestSeries,
%  all of its TestRuns are checked for existance and if they use 
%  selectedVehicle. If these checks are passed, the function returns ok = 
%  true, otherwise a list of "invalidTests" that don't use selectedVehicle 
%  is returned. "Msg" contains the corresponding error/warning message.
%  Recommended to be used after checkForCMTest.
%
% Example:
%  checkForCMReferences('D:/git_Repos/vmcsim.platform/Data/TestRun/platform_example_tests/TestSeries/Development.ts')
%
% Inputs:
%  test             CarMaker TestRun or Testseries to be checked
%                   (use return of checkForCMTest)
%
% Outputs:
%  ok               Boolean telling if the test uses selectedVehicle
%  Msg              Error message explaining the reason(s) why ok=0
%
ok = true;
TR_invalid = {};
Vhcl_invalid = {};

% Path to Data/TestRun
tmp = pwd;
tmp = fullfile(tmp(1:end-10), 'Data/TestRun');
TR_folder = replace(tmp, '\', '/');

% Get TestRuns to be checked
TR = {};
if endsWith(test, '.ts')  
    % Inside a Testseries
    
    prefix ={};
    fileID = fopen(test,'r');
    
    if fileID<0
        ok = false;
        TR_invalid{end+1,1} = test; %#ok<*AGROW>
    else
        
        while ~feof(fileID)
            tline = fgetl(fileID);
            % Identify which "Step" in the Testseries corresponds to a TestRun
            % example syntax: Step.1.0.4.2 = TestRun
            if ~strcmp(tline(1),'#') && endsWith(tline, ' = TestRun')
                tmp = strsplit(tline, ' =');
                prefix = tmp{1};       
            elseif ~isempty(prefix) && startsWith(tline, strcat(prefix, '.Name'))
                % Get TestRun name (only works if Testseries is sorted)
                % example syntax: Step.1.0.4.2.Name = platform_example_tests/TestRuns/Long/1111_0402_ACC_WSOP_with_PP0
                tmp = strsplit(tline, ' = ');
                TR{end+1,1} = strcat('/',tmp{end});  
            end
        end
        fclose(fileID);
    end
    
else
    % test is a single TestRun
    tmp = strsplit(test, TR_folder);
    tmp = replace(tmp, '\', '/');
    TR{end+1,1} = tmp{end};
end

% Check TestRun's vehicle selection
for ii=1:numel(TR)
    
    handle = ifile_new;
    if ifile_read(handle, strcat(TR_folder, TR{ii}))
        % file not readable
        ok = false;
        TR_invalid{end+1,1} = TR{ii}(2:end);  %#ok<*AGROW>
        continue;
    end
    
    if ~strcmp(ifile_getstr(handle, 'Vehicle'), 'selectedVehicle')
        ok = false;
        Vhcl_invalid{end+1,1} = TR{ii}(2:end);  %#ok<*AGROW>
    end
    ifile_delete(handle);
end

% Consolidate error messages
Msg = {};
if isempty(TR)
    Msg{end+1,1} = 'The selected TestSeries does not include any TestRun.';
end

if ~isempty(TR_invalid)
    tmp = 'The selected TestSeries contains references to invalid TestRuns: ';
    for ii=1:numel(TR_invalid)
        tmp = [tmp TR_invalid{ii} ', '];
    end
    Msg{end+1,1} = tmp(1:end-2);
end

if ~isempty(Vhcl_invalid)
    tmp = 'The following selected TestRuns do not use "selectedVehicle": ';
    for ii=1:numel(Vhcl_invalid)
        tmp = [tmp Vhcl_invalid{ii} ', '];
    end
    Msg{end+1,1} = tmp(1:end-2);
end
 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [flag_, errorMsg, file_out] = checkForCMTest(file_)
% checkForCMInfoFile - Check if file contains a valid CM TestSeries/TestRun
%
% Description:
%  This function checks via "ifile_getstr" if the passed file is a valid
%  CM 8 Testrun or TestSeries
%
% Example:
%  checkForCMTest('D:/git_Repos/vmcsim.platform/Data/TestRun/platform_example_tests/TestSeries/Development.ts')
%  checkForCMTest('platform_example_tests/TestSeries/Development.ts')
%
% Inputs:
%  file_             File that is supposed to be a CM TestSeries or TestRun
%                    This can be an abolute path or a path relative to
%                    Data/TestRun
%
% Outputs:
%  flag_             Flag telling if the file_ is a valid
%                    TestSeries/TestRun
%                    0: neither a TestRun nor a Testseries
%                    1: is a vaild TestRun
%                    2: is a valid Testseries
%  errorMsg          Error message in case flag_=0
%  file_out          Absolute path to TestRun/TestSeries in a format that
%                    CM can load
flag_    = 0;
errorMsg = '';
file_out = '';
pwd_ = pwd;

% Use \ in path in order to simplify the usage of "startsWith" in
% combination with "fullfile"
file_ = replace(file_, '/', '\');

if isfile(file_)
    % absolute path provided
    if ~startsWith(file_, fullfile(pwd_(1:end-10), 'Data\TestRun')) && ~startsWith(file_, fullfile(pwd_, '..\Data\TestRun'))
        errorMsg = ['Invalid TestRun/Testseries file location. The chosen file does not reside in ' pwd_(1:end-10) '\Data\TestRun.'];
        return;
    end
   
elseif isfile(fullfile(pwd_(1:end-10), 'Data\TestRun', file_))
    % relative path provided
    file_ = fullfile(pwd_(1:end-10), 'Data\TestRun', file_);
else
    % file does not exist
    errorMsg = ['The chosen TestRun/Testseries (' file_, ') does not exist.'];
    return;
end

handle_ = ifile_new;
% Check file format
if ifile_read(handle_, file_)
    errorMsg = ['The chosen file (' file_, ') is not a valid CarMaker TestRun or Testseries.'];
    return;
else
    FileIdent_ = ifile_getstr(handle_, 'FileIdent');
    % Check file version
    if strcmp(FileIdent_, 'CarMaker-TestRun 8') 
        flag_ = 1;
    elseif strcmp(FileIdent_, 'CarMaker-TestSeries 2')
        flag_ = 2;
    else
        errorMsg = ['The chosen file (' file_, ') is not a valid CarMaker 8 TestRun or Testseries.'];
        return;
    end
end
ifile_delete(handle_);

% CM GUI requires / instead of \
file_out = replace(file_, '\', '/');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function createLog(varargin)
% createLog - Create the log file during Simulation.
%
% Description:
%  This function can be used to generate log automatically during the
%  simulation. The log file contains the details like Commit IDs , modified
%  and untracked files of Simulation Environment , Test Repos and BaseLine
%  of the vmcsim.core.
%
% Syntax:
%  createLog();
%
% Mandatory inputs:
%  SelectedConfig        Struct containing the chosen configuration.
%  Test                  Relative path to a CM test run or test series.
% Default values
testRun_ = '';
SelectedConfig = '';

for h_=2:2:nargin
    switch lower(varargin{h_-1})
        case 'selectedconfig'
            if isstruct(varargin{h_})
                SelectedConfig = varargin{h_};
            else
                error('The input argument given for "SelectedConfig" has to be a struct! Aborting ...');
            end
        case 'test'
            if ~isempty(varargin{h_})
                if ischar(varargin{h_})
                    [ok, Msg, testRun_] = checkForCMTest(varargin{h_});
                    if ~ok
                        error([Msg 'Aborting ...']);
                    end
                else
                    error('The input argument given for "Test" has to be a string! Aborting ...');
                end
            end
    end
end

[~, projDir_] = strtok(reverse(strrep(pwd, '\', '/')), '/');
projDir_ = reverse(projDir_);
curDir = pwd;

try
    data = struct('selectedConfig', SelectedConfig, ...
        'test', testRun_, ...
        'simEnv', [], ...
        'testRepos', getPrototype, ...
        'core', []);
    
    % Get the Sim Environment git status
    [~ , data.simEnv] = gitStatus(projDir_, '', projDir_, 'Simulation Environment');
    
    % Get the Test Repos git status.
    [err, submodulepath]  = system('git submodule foreach --recursive');
    if err
        temp = '';
    else
        temp = strrep(submodulepath,'Entering ''../','');
    end
    if ~isempty(temp)
        submodules = strsplit(strtrim(temp),'\n');
    
        for ii = 1:length(submodules)
            curr_submodule = submodules{ii};
            curr_submodule(end) = '';
            [~, data.testRepos(ii)] = gitStatus(projDir_, curr_submodule, curDir, 'TestRepo');
        end
    end
    
    % Get the vmcsim.core git status.
    [err, data.core] = gitStatus(getCoreDir(), '' , curDir, 'vmcsim.core');
    
    if err
        if exist([getCoreDir() 'vmcsim.core' filesep 'BL_Info.txt'], 'file')~=0
            content = fileread([getCoreDir() 'vmcsim.core' filesep 'BL_Info.txt']);
            content = strsplit(strtrim(content), newline);
            if strcmp(content{1},'This is not an official Baseline!')
                data.core.name = content{3};
            elseif strcmp(content{1},'Baseline number:')
                data.core.name = content{2};
            end
        end
    end
    
    cd(curDir);
    
    filename = ['LogFile_' datestr(now,'yyyy_mm_dd-HH_MM_SS') '.json'];
    % First check for SimulinkCache folder and create it. mkdir for folder
    % Logfiles will only work if the folder above already exists.
    if exist('SimulinkCache','dir')~=7
        mkdir('SimulinkCache');
    end
    if exist('SimulinkCache\Logfiles','dir')~=7
        mkdir('SimulinkCache\Logfiles');
    end
    
    % Export json
    writeJson(data, [curDir '\SimulinkCache\Logfiles\'], filename, 1);
    
catch ME
    cd(curDir);
    warning('Error during Log File creation!');
end

end

function [err, simEnv] = gitStatus(projDir_, curr_submodule, curDir, RepoType)
% gitStatus - Get the git status of the repo and its submodules.
%
% Mandatory inputs:
%   projDir_              Start Directory of the sim environment.
%   curr_submodule        Name of the submodule.
%   curDir                Current Directory.
%   RepoType              Type of the repo - Sim , Test or vmcsim.core
%
% Outputs
%  err                    Error flag during git status
%  simEnv                 Struct containing name, commitID, changedFiles
%                         and untrackedFiles
%

simEnv = struct('name', '', ...
    'commitID', '', ...
    'changedFiles', '', ...
    'untrackedFiles', '');

if strcmp(RepoType,'TestRepo')
    cd([projDir_ curr_submodule]);
elseif strcmp(RepoType,'vmcsim.core')
    cd([projDir_ 'vmcsim.core']);
else
    % Do nothing
    % This is for the repo type sim-environment.
end

[err, ~] = system('git status');

if ~err
    % Get git status
    [~, commitID]   = system('git rev-parse HEAD');
    commitID = strsplit(strtrim(commitID), '\n');
    simEnv.commitID = commitID{end};
    
    [~, changedFiles]   = system('git diff --name-only --ignore-submodules');
    if ~isempty(changedFiles)
        simEnv.changedFiles = strrep(strsplit(strtrim(changedFiles), newline), '\', '/');
    end
    
    [~, untrackedFiles] = system('git ls-files --others --exclude-standard');
    if ~isempty(untrackedFiles)
        simEnv.untrackedFiles = strrep(strsplit(strtrim(untrackedFiles), newline), '\', '/');
    end
    
    if ~isempty(curr_submodule)
        simEnv.name = strrep(curr_submodule, '\', '/');
        cd(curDir);
    else
        simEnv.name = strrep(projDir_, '\', '/');
    end
else
    cd(curDir);
end

end

function simEnv = getPrototype()

simEnv = struct('name', {}, ...
    'commitID', {}, ...
    'changedFiles', {}, ...
    'untrackedFiles', {});

end
