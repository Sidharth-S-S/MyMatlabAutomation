function VariantCloseFcn(path_)
% VariantCloseFcn - CloseFcn of all VMC SIm Simulink models
%
% Syntax:
%  VariantCloseFcn('VMC/Platform/DASY/DASY_1903')
%
% Inputs:
%  path_             Relative path of the variant

% This are either specified in the VMC variant or not a bus
specialOnes_ = {'Inherit: auto', 'VMC2Vhcl', 'VMC', 'Vhcl2VMC', 'Vhcl'};

% Read infofiles
infofile_ = infofile_read(path_);

parentInfofile = infofile_read(infofile_.parent);

myModel_ = gcs;

% Gather all sub-models
subModels_ = strcat(infofile_.name, ...
    arrayfun(@(x) parentInfofile.mdl(x).suffix.name, ...
    1:numel(parentInfofile.mdl), 'UniformOutput', false));

% Find the current one
idx_            = strcmp(subModels_, myModel_);
otherModelsIdx_ = ~idx_;
everythingElseClosed_ = all(~bdIsLoaded(subModels_(otherModelsIdx_)));
% for i_=1:sum()

% Combine path
if everythingElseClosed_
    lastwarn_ = lastwarn('');
    warning('off','MATLAB:rmpath:DirNotFound');
    rmpath(infofile_.parent); rmpath(genpath([infofile_.parent, filesep 'Files']));
    rmpath(path_); rmpath(genpath([path_, filesep 'Files'])); lastwarn(lastwarn_);
    warning('on','MATLAB:rmpath:DirNotFound');
else
    return;
end

% Clear buses
if strcmp(parentInfofile.name, 'VMC')
    clearFun = @clearTopLevelOnly;
else
    clearFun = @clearBusRecursively;
end

for i_=1:numel(parentInfofile.mdl(idx_).inports)
    if all(~strcmp(parentInfofile.mdl(idx_).inports(i_).name, specialOnes_)) 
        clearFun(parentInfofile.mdl(idx_).inports(i_).name);
    end
end

for i_=1:numel(parentInfofile.mdl(idx_).outports)
    if all(~strcmp(parentInfofile.mdl(idx_).outports(i_).name, specialOnes_))
        clearFun(parentInfofile.mdl(idx_).outports(i_).name);
        if evalin('base', ['exist(''', parentInfofile.mdl(idx_).outports(i_).name, '_init'', ''var'')'])
            evalin('base', ['clear(''', parentInfofile.mdl(idx_).outports(i_).name, '_init'');']);
        end
    end
end

if isempty(get_param(Simulink.allBlockDiagrams(),'Name'))
    clearFun('VMC2Vhcl');
    clearFun('VMC');
    % Vhcl2VMC has to be removed recursively
    clearBusRecursively('Vhcl2VMC');
end

% clear user-defined parameters
userDefinedParameterFile = [path_, '/Files/.userAddedParameters.txt'];
if exist(userDefinedParameterFile, 'file')==2
    fid = fopen(userDefinedParameterFile, 'r');
    tline = fgetl(fid);
    numParams = sscanf(tline,'%d');
    userParams_ = cell(numParams, 1);
    for i_=1:numParams
        tline = fgetl(fid);
        userParams_{i_} = sscanf(tline,'%s');
        evalin('base', ['clear ', userParams_{i_}]);
    end
    fclose(fid);
end

% remove user-defined path
userDefinedPathFile = [path_, '/Files/.userAddedPath.txt'];
if exist(userDefinedPathFile, 'file')==2
    fid = fopen(userDefinedPathFile, 'r');
    tline = fgetl(fid);
    numParams = sscanf(tline,'%d');
    userPath_ = cell(numParams, 1);
    for i_=1:numParams
        tline = fgetl(fid);
        userPath_{i_} = sscanf(tline,'%s');
        evalin('base', ['rmpath ', userPath_{i_}]);
    end
    fclose(fid);
end

% Return to GUI - if the model was opened from there 
callingGUI = findall(groot, 'Type', 'figure', 'Tag', 'openSimulinkModel');

if ~isempty(callingGUI)
    callingGUI(1).Visible = 'on';
end

end % END of VariantCloseFcn

function clearTopLevelOnly(myBus)

evalin('base', ['clear ', myBus]);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function VariantInitFcn(path_)
% VariantInitFcn - InitFcn of all VMC SIM Simulink models
%
% Syntax:
%  VariantInitFcn('VMC/Platform/DASY/DASY_1903')
if evalin('base', 'exist(''selectedConfig'', ''var'')==1')
    selectedConfig = evalin('base', 'selectedConfig');
    pathParts_ = strsplit(path_, '/');
    if isfield(selectedConfig, pathParts_{end-1})
        infofile_ = selectedConfig.(pathParts_{end-1}).infofile;
    else
        % Read infofiles
        infofile_ = infofile_read(path_);
    end
else
    % Read infofiles
    infofile_ = infofile_read(path_);
end

% Create AddressValues_sim.txt of the OMCL (if there is one)
if isfield(infofile_, 'runnable') && ...
        isfield(infofile_.runnable, 'modParams') && ...
        isfield(infofile_.runnable.modParams, 'internal') && ...
        isfield(infofile_.runnable, 'epk')

    % Create header
    header = createParamFileHeader(infofile_.runnable.epk);
    
    % Put together the path of the <*>_AddressValues_sim.txt
    component_ = reverse(strtok(reverse(infofile_.parent), '/'));
    addressValuesFile = [path_, '/Files/' component_, '_AddressValues_sim.txt'];

    % Update <*>_AddressValues_sim.txt
    if ~isstruct(infofile_.runnable.modParams.internal) && ...
            iscell(infofile_.runnable.modParams.internal)
        infofile_.runnable.modParams.internal = [infofile_.runnable.modParams.internal{:}];
    end
    modParams2File(infofile_.runnable.modParams.internal, header, ...
        addressValuesFile);
    
end

end % END of VariantInitFcn

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function VariantPostLoadFcn(path_)
% VariantPostLoadFcn - PostLoadFcn of all VMC SIM Simulink models
if evalin('base', 'exist(''selectedConfig'', ''var'')==1')
    selectedConfig = evalin('base', 'selectedConfig');
    pathParts_ = strsplit(path_, '/');
    if isfield(selectedConfig, pathParts_{end-1})
        infofile_ = selectedConfig.(pathParts_{end-1}).infofile;
    else
        % Read infofiles
        infofile_ = infofile_read(path_);
    end
else
    % Read infofiles
    infofile_ = infofile_read(path_);
end

myModel_ = gcs;

% Configure internal measurement of the OMCL (if there is one)
if isfield(infofile_, 'measurements') && ...
        isfield(infofile_.measurements, 'internal')
    
    omcl_handle = getSimulinkBlockHandle([myModel_ '/Runnable/ESP Controller Interface']);
    
    if omcl_handle>0
        mask_ = get_param(omcl_handle, 'MaskObject');
        mask_.Parameters(7).Value = strrep(infofile_.measurements.internal.cfxfile, '/', '\');
        if infofile_.measurements.internal.active
            mask_.Parameters(1).Value = 'on';
        else
            mask_.Parameters(1).Value = 'off';
        end
    end
elseif isfield(infofile_, 'references') && strcmp(infofile_.parent, 'Vehicle')
    if evalin('base', 'exist(''selectedConfig'', ''var'')==1')
        selectedConfig = evalin('base', 'selectedConfig');
    else
        return;
    end
    
    refType = readJson(selectedConfig.Vehicle.infofile.reftype);
    potentialRefs_ = setdiff(fieldnames(refType.References), 'Body');
    
    availRefs_ = intersect(potentialRefs_, fieldnames(selectedConfig), 'stable');
    
    for i_=1:numel(availRefs_)
        parent_ = [selectedConfig.(availRefs_{i_}).infofile.parent];
        name_   = [selectedConfig.(availRefs_{i_}).infofile.name];
        loadVariant('Path', [parent_, '/', name_]);
    end
end

end % END of VariantPostLoadFcn

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function VariantPreLoadFcn(path_)
% VariantPreLoadFcn - PreLoadFcn of all VMC SIM Simulink models
%
% Syntax:
%  VariantPreLoadFcn('VMC/Platform/DASY/DASY_1903')
% This are either specified in the VMC variant or not a bus
specialOnes_ = {'Inherit: auto', 'VMC2Vhcl', 'VMC', 'Vhcl2VMC', 'Vhcl'};

% Read infofiles
infofile_ = infofile_read(path_);
parentInfofile = infofile_read(infofile_.parent);

% cleanup remains from previous simulations
ToBeRemoved = { ...
    'Log_Exe_*.prt' ...
    'Sim_ExeConfig_*.txt' ...
    'LOG_ConvertMesDataToD97Format_*.txt' ...
    'LOG_CreateMeasurementDataDesc_*.txt' ...
    'PDB_MEAS_DESC_Bin_*.txt' ...
    'APL_Asap_*_a2l.saf'};
for ii=1:numel(ToBeRemoved)
    f = dir(fullfile(path_, 'Files', ToBeRemoved{ii}));
    if ~isempty(f)
        for jj=1:length(f)
            delete(fullfile(path_, 'Files', f(jj).name));
        end
    end
end

% Combine path
addpath(infofile_.parent); addpath(genpath([infofile_.parent, filesep 'Files']));
addpath(path_); addpath(genpath([path_, filesep 'Files']));

myModel_ = gcs;

% Gather all sub-models
subModels_ = strcat(infofile_.name, ...
    arrayfun(@(x) parentInfofile.mdl(x).suffix.name, ...
    1:numel(parentInfofile.mdl), 'UniformOutput', false));

% Find the current one
idx_ = strcmp(subModels_, myModel_);
otherSubmodelsIdx_= ~idx_;

% Load inport buses
for i_=1:numel(parentInfofile.mdl(idx_).inports)
    if all(~strcmp(parentInfofile.mdl(idx_).inports(i_).name, specialOnes_))
        if evalin('base', ['exist(''', parentInfofile.mdl(idx_).inports(i_).name, '.mat'', ''file'')==2'])
            evalin('base', ['load(''', [parentInfofile.mdl(idx_).inports(i_).name],''');']);
        end
    end
end

% Load outport buses
for i_=1:numel(parentInfofile.mdl(idx_).outports)
    if all(~strcmp(parentInfofile.mdl(idx_).outports(i_).name, specialOnes_))
        if evalin('base', ['exist(''', parentInfofile.mdl(idx_).outports(i_).name, '.mat'', ''file'')==2']) && ...
                evalin('base', ['exist(''', parentInfofile.mdl(idx_).outports(i_).name, ''', ''var'')~=1'])
            evalin('base', ['load(''', [parentInfofile.mdl(idx_).outports(i_).name],''');']);
        end
        if endsWith(parentInfofile.mdl(idx_).outports(i_).name, '_extended')
            if evalin('base', ['exist(''', strrep(parentInfofile.mdl(idx_).outports(i_).name, '_extended', ''), '_init.mat'', ''file'')==2']) && ...
                    evalin('base', ['exist(''', strrep(parentInfofile.mdl(idx_).outports(i_).name, '_extended', ''), '_init'', ''var'')~=1'])
                evalin('base', ['load(''', strrep(parentInfofile.mdl(idx_).outports(i_).name, '_extended', ''),'_init'');']);
            end
        elseif endsWith(parentInfofile.mdl(idx_).outports(i_).name, '_brief')
            if evalin('base', ['exist(''', strrep(parentInfofile.mdl(idx_).outports(i_).name, '_brief', ''), '_init.mat'', ''file'')==2']) && ...
                    evalin('base', ['exist(''', strrep(parentInfofile.mdl(idx_).outports(i_).name, '_brief', ''), '_init'', ''var'')~=1'])
                evalin('base', ['load(''', strrep(parentInfofile.mdl(idx_).outports(i_).name, '_brief', ''),'_init'');']);
            end
        else
            if evalin('base', ['exist(''', parentInfofile.mdl(idx_).outports(i_).name, '_init.mat'', ''file'')==2']) && ...
                    evalin('base', ['exist(''', parentInfofile.mdl(idx_).outports(i_).name, '_init'', ''var'')~=1'])
                evalin('base', ['load(''', parentInfofile.mdl(idx_).outports(i_).name,'_init'');']);
            end
        end
    end
end

% Check and call user-defined PreLoadFcn
if ~any(bdIsLoaded(subModels_(otherSubmodelsIdx_)))
    userPreloadFile = [infofile_.name '_PreLoadFcn'];
    if exist(userPreloadFile, 'file')==2 || ...
            exist(userPreloadFile, 'file')==6
        errMsg_ = checkcode(userPreloadFile, '-m2'); % the undocumented option '-m2' only checks for errors 
        if isempty(errMsg_)
            isscript = false;
            try
                [~] = nargin(userPreloadFile);
            catch ME
                if strcmp(ME.identifier, 'MATLAB:nargin:isScript')
                    isscript = true;
                end
            end
            if isscript
                % Get previously available workspace and path
                prevVars_ = evalin('base', 'who();');
                prevPath_ = strsplit(path(), ';');
                % Call script
                evalin('base', [userPreloadFile ';']);
                % Get workspace and path after calling script
                updatedVars_ = evalin('base', 'who();');
                updatedPath_ = strsplit(path(), ';');
                
                % handle parameters
                userParams_ = setdiff(updatedVars_, prevVars_);
                if numel(userParams_)>0
                    fid = fopen([path_ '/Files/.userAddedParameters.txt'], 'w');
                    fprintf(fid, '%d\n', numel(userParams_));
                    fprintf(fid, '%s\n', userParams_{:});
                    fclose(fid);
                end
                
                % handle paths
                userPath_ = setdiff(updatedPath_, prevPath_);
                remPath_  = setdiff(prevPath_, updatedPath_);
                if numel(userPath_)>0
                    fid = fopen([path_ '/Files/.userAddedPath.txt'], 'w');
                    fprintf(fid, '%d\n', numel(userPath_));
                    fprintf(fid, '%s\n', userPath_{:});
                    fclose(fid);
                end
                if numel(remPath_)>0
                    warning('User-defined PreLoadFcn tried to remove folders from path. Path is restored.')
                    for i_=1:numel(remPath_)
                        addpath(remPath_{i_});
                    end
                end
            else
                warning('The user-defined PreLoadFcn is not a script, therefore it is ignored.');
            end
        else
            warning('The user-defined PreLoadFcn is corrupt, therefore it is ignored.');
        end
    end
end

% Since the VMC is the master, it loads the parts
if strcmp(parentInfofile.name, 'VMC')
    if evalin('base', 'exist(''Vhcl.mat'', ''file'')==2') && ...
            evalin('base', 'exist(''Vhcl'', ''var'')~=1')
        evalin('base', 'load(''Vhcl.mat'');');
    end
    if evalin('base', 'exist(''VMC2Vhcl.mat'', ''file'')==2') && ...
            evalin('base', 'exist(''VMC2Vhcl'', ''var'')~=1')
        evalin('base', 'load(''VMC2Vhcl.mat'');');
    end
    if evalin('base', 'exist(''VMC.mat'', ''file'')==2') && ...
            evalin('base', 'exist(''VMC'', ''var'')~=1')
        evalin('base', 'load(''VMC.mat'');');
    end
    if evalin('base', 'exist(''Vhcl2VMC.mat'', ''file'')==2') && ...
            evalin('base', 'exist(''Vhcl2VMC'', ''var'')~=1')
        evalin('base', 'load(''Vhcl2VMC.mat'');');
    end
    if evalin('base', 'exist(''Vhcl2VMC_init.mat'', ''file'')==2') && ...
            evalin('base', 'exist(''Vhcl2VMC_init'', ''var'')~=1')
        evalin('base', 'load(''Vhcl2VMC_init.mat'');');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function VMCSimCloseFcn()
% VMCSimCloseFcn - Close function of the Simulink model generic.mdl
% 
% Description:
%  Function is used for resetting solver settings as well as sample time 
%  settings in rate transitions     
CleanupCMproject;

if evalin('base', 'exist(''selectedConfig'', ''var'')')
    % Define default settings
    myModel_           = 'generic';
    defaultSolverName_ = 'FixedStepDiscrete';
    defaultSampleTime_ = '0.001';
    
    % Reset solver settings of generic.mdl
    set_param(myModel_,'SolverType', 'Fixed-step');
    set_param(myModel_,'SolverName', defaultSolverName_);
    set_param(myModel_,'FixedStep',  defaultSampleTime_);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function VMCSimPostLoadFcn()
% VMCSimPostLoadFcn - PostLoad function of the Simulink model generic.mdl
% 
% Description:
%  Function is used to load the toplevel models and for setting solver
%  settings as well as sample time settings in rate transitions
% cleanup remains from previous simulations
clear mex %#ok<CLMEX>

ToBeRemoved = { ...
    'Log_Exe_*.prt' ...
    'Sim_ExeConfig_*.txt' ...
    'LOG_ConvertMesDataToD97Format_*.txt' ...
    'LOG_CreateMeasurementDataDesc_*.txt' ...
    'PDB_MEAS_DESC_Bin_*.txt' ...
    'APL_Asap_*_a2l.saf'};

for ii=1:numel(ToBeRemoved)
    f = dir(ToBeRemoved{ii});
    if ~isempty(f)
        for jj=1:length(f)
            delete(which(f(jj).name));
        end
    end
end

myModel_ = gcs;
myRefs_ = {[myModel_, '/CarMaker/VehicleControl/VMC'], [myModel_, '/CarMaker/Vehicle/Vehicle']};

for j_=1:numel(myRefs_)
    load_system(get_param(myRefs_(j_), 'ModelFile'));
end

% Modify solver settings if necessary
if evalin('base', 'exist(''selectedConfig'', ''var'')')
    
    selectedConfig = evalin('base', 'selectedConfig');
    
    % Write settings to generic.mdl
    set_param(myModel_,'SolverType', 'Fixed-step');
    set_param(myModel_,'SolverName', selectedConfig.VMCSim.infofile.solvertype);
    set_param(myModel_,'FixedStep',  selectedConfig.VMCSim.infofile.sampletime);

end

end % END of initializeVMCSim


