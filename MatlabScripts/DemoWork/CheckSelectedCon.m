function varargout = checkSelectedConfig(selectedConfig)
% checkSelectedConfig - check if the variable selectedConfig is valid
%
% Description:
%  This function checks if the passed variable "selectedConfig" is a valid
%  configuration. Three different checks are performed:
%   - are "VMC", "Vehicle" and "Body" available in selectedConfig?
%   - are the references structs with the fields 'variant' and 'infofile'?
%   - do the references of the infofiles of selectedConfig.{VMC/Vehicle}
%     match the references of the selectedConfig?
%  If these checks are passed, the functions returns true, otherwise false.
%
% Example:
%  [isValid, warnCell, validReferences] = checkSelectedConfig(selectedConfig)
%
% Inputs:
%  selectedConfig            Struct that is supposed to be a selectedConfig
%
% Mandatory Outputs:
%  isValid                   Bool telling if the passed struct is a valid
%                            configuration or not.
% Optional Outputs:
%  warnCell                  Cell containing the lines for a warning, error
%                            or uialert message. Needs reformation with
%                            sprintf('%s\n', warnCell{:})
%  validReferences           Cell array containg the valid components
%                            as well as 'VMC' and 'Vehicle'
%
% See also:
%  startSimulation, vmcsimgui_execution>loadConfig

isValid = true;
warntext_ = cell(0,1);
validReferences_ = {};

% Save field 'VMCSim' in extra variable and delete it from selectedConfig
% The second and fourth check has to be done without VMCSim as it is not
% part of the infofiles in the folder structure.
if isfield(selectedConfig, 'VMCSim')
    VMCSim_ = selectedConfig.VMCSim;
    selectedConfig = rmfield(selectedConfig, 'VMCSim');
end

refs_ = fieldnames(selectedConfig);

%First check: are "VMC", "Vehicle" and "Body" available in selectedConfig
if ~any(strcmp(refs_, 'VMC'))
    isValid = isValid && false;
    warntext_{end+1,1} = 'Invalid selectedConfig: No "VMC" origin and top level available.';
end

if ~any(strcmp(refs_, 'Vehicle'))
    isValid = isValid && false;
    warntext_{end+1,1} = 'Invalid selectedConfig: No "Vehicle" origin and top level available.';
end

if ~any(strcmp(refs_, 'Body'))
    isValid = isValid && false;
    warntext_{end+1,1} = 'Invalid selectedConfig: No "Body" component available inside the selected vehicle top level.';
end

% Second check: Are the references structs with the fields 'variant' and
% 'infofile'?
for i_=1:numel(refs_)
    if ~all(isfield(selectedConfig.(refs_{i_}), {'variant', 'infofile'}))
        isValid = isValid && false;
        warntext_{end+1,1} = sprintf('Invalid selectedConfig: Instance or instance information (infofile) for component "%s" is not available.', refs_{i_}); %#ok<*AGROW>
        continue;
    end
    infofile = selectedConfig.(refs_{i_}).infofile;
    variant = selectedConfig.(refs_{i_}).variant;
    if ((isempty(infofile) || isempty(variant)))
        isValid = isValid && false;
        warntext_{end+1,1} = sprintf('Invalid selectedConfig: Instance or instance information (infofile) for component "%s" is empty.', refs_{i_});
    end
end

% third check is only allowed when first and second are successful
if ~isValid
    if nargout==3
        varargout{1} = isValid;
        varargout{2} = warntext_;
        varargout{3} = validReferences_;
    elseif narargout==2
        varargout{1} = isValid;
        varargout{2} = warntext_;
    else
        varargout{1} = isValid;
        warning('%s\n', warntext_{:});
    end
    return;
end

% third check: do the references of the infofiles of
% selectedConfig.{VMC/Vehicle} match the references of the selectedConfig?
VMCrefs_ = selectedConfig.VMC.infofile.references;
Vehrefs_ = selectedConfig.Vehicle.infofile.references;
SCrefs_ = [{'VMC'; 'Vehicle'}; VMCrefs_; Vehrefs_];
isValid = isValid && isempty(setdiff(SCrefs_, refs_));

% third check is only allowed when first and second are successful
if ~isValid
    warntext_{end+1,1} = sprintf('Invalid selectedConfig: Selected components do not match the file structure!');
    if nargout==2
        varargout{1} = isValid;
        varargout{2} = warntext_;
    else
        varargout{1} = isValid;
        warning('%s\n', warntext_{:});
    end
    return;
end

validReferences_ = SCrefs_;

% fourth check: compare infofiles in selected with infofiles stored in
% folder structure
for i_=1:numel(refs_)
    infofile_SC = selectedConfig.(refs_{i_}).infofile;
    if exist([infofile_SC.parent '/' infofile_SC.name], 'file')==7
        infofile_FS = infofile_read([infofile_SC.parent '/' infofile_SC.name]);
    else
        warntext_{end+1,1} = sprintf('Invalid infofile: The chosen instance "%s" of component "%s"', infofile_SC.name, refs_{i_});
        warntext_{end+1,1} = 'does not have a counterpart in the file structure!';
        isValid = isValid && false; validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
        continue;
    end
    
    fields_SC = fieldnames(infofile_SC);
    fields_FS = fieldnames(infofile_FS);
    
    if ~isempty(setdiff(fields_SC, fields_FS))
        warntext_{end+1,1} = sprintf('Fields of the infofile of the selected Config do not correspond to the saved ones!');
        isValid = isValid && false; validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
        continue;
    end
    
    for j_=1:numel(fields_FS)
        myField = fields_FS{j_};
        switch myField
            case {'measurements', 'signalmanipulations'}
                % inputs
                if isfield(infofile_FS.(myField), 'inputs') ...
                        && ~isempty(infofile_FS.(myField).inputs)
                    inputs_FS = infofile_FS.(myField).inputs;
                    inputSignals_FS = {inputs_FS(:).name};
                    if isfield(infofile_SC, myField) && ...
                            isfield(infofile_SC.(myField), 'inputs') ...
                            && ~isempty(infofile_SC.(myField).inputs)
                        inputs_SC = infofile_SC.(myField).inputs;
                        inputSignals_SC = {inputs_SC(:).name};
                        Lia_input = ismember(inputSignals_FS, inputSignals_SC);
                        if sum(Lia_input)~=numel(inputSignals_SC)
                            % Invalid signals found!
                            isValid = isValid && false; validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                            warntext_{end+1,1} = sprintf('Invalid infofile: At least one entry in "%s".inputs',myField);
                            warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!' , refs_{i_});
                        end
                    end
                elseif isfield(infofile_SC, myField) && ...
                        isfield(infofile_SC.(myField), 'inputs') ...
                        && ~isempty(infofile_SC.(myField).inputs)
                    % Invalid signals found!
                    isValid = isValid && false; validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile: At least one entry in "%s".inputs', myField);
                    warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!', refs_{i_});
                else
                    clear Lia_input
                end
                
                % outputs
                if isfield(infofile_FS.(myField), 'outputs') ...
                        && ~isempty(infofile_FS.(myField).outputs)
                    outputs_FS = infofile_FS.(myField).outputs;
                    outputSignals_FS = {outputs_FS(:).name};
                    if isfield(infofile_SC, myField) && ...
                            isfield(infofile_SC.(myField), 'outputs') ...
                            && ~isempty(infofile_SC.(myField).outputs)
                        outputs_SC = infofile_SC.(myField).outputs;
                        outputSignals_SC = {outputs_SC(:).name};
                        Lia_output = ismember(outputSignals_FS, outputSignals_SC);
                        if sum(Lia_output)~=numel(outputSignals_SC)
                            % Invalid signals found!
                            isValid = isValid && false; validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                            warntext_{end+1,1} = sprintf('Invalid infofile: At least one entry in "%s".outputs', myField);
                            warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!', refs_{i_});
                        end
                    end
                elseif isfield(infofile_SC, myField) && ...
                        isfield(infofile_SC.(myField), 'outputs') ...
                        && ~isempty(infofile_SC.(myField).outputs)
                    % Invalid signals found!
                    isValid = isValid && false; validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile: At least one entry in "%s".outputs', myField);
                    warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!', refs_{i_});
                else
                    clear Lia_output
                end
                
                % Additional part for signal manipulations
                if strcmp(myField, 'signalmanipulations')
                    if exist('Lia_input', 'var')==1
                        idx_ = find(Lia_input);
                        if any(arrayfun(@(x) ~isempty(setdiff(inputs_SC(x).type, inputs_FS(idx_(x)).type)), 1:numel(idx_)))
                            isValid = isValid && false; validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                            warntext_{end+1,1} = sprintf('Invalid infofile: The type of at least one entry in "%s".inputs', myField);
                            warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!', refs_{i_});
                        end
                    end
                    if exist('Lia_output', 'var')==1
                        idx_ = find(Lia_output);
                        if any(arrayfun(@(x) ~isempty(setdiff(outputs_SC(x).type, outputs_FS(idx_(x)).type)), 1:numel(idx_)))
                            isValid = isValid && false;
                            warntext_{end+1,1} = sprintf('Invalid infofile: The type of at least one entry in "%s".outputs', myField);
                            warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!', refs_{i_});
                        end
                    end
                end
                
                % Clear temporary variables because this case can be
                % executed twice
                clear inputs_FS inputSignals_FS inputs_SC ...
                    inputSignals_SC Lia_input ...
                    outputs_FS outputSignals_FS outputs_SC ...
                    outputSignals_SC Lia_output
                
            case 'references'
                if ~isempty(setdiff(infofile_SC.(myField), infofile_FS.(myField)))
                    isValid = isValid && false; 
                    validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile: The entries of "%s"', myField);
                    warntext_{end+1,1} = sprintf('of the infofile of component "%s" are not compatible with the stored infofile!', refs_{i_});
                end
            case {'cm', 'extFileList'} % These are only struct/cell compares
                if ~isequaln(infofile_SC.(myField), infofile_FS.(myField))
                    isValid = isValid && false; 
                    validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile: The entries of "%s"', myField);
                    warntext_{end+1,1} = sprintf('of the infofile of component "%s" are not compatible with the stored infofile!', refs_{i_});
                end
            case 'runnable'
                if ~isfield(infofile_SC.(myField), 'blockName') || ...
                        ~isfield(infofile_FS.(myField), 'blockName') || ...
                        ~strcmp(infofile_SC.(myField).blockName, infofile_FS.(myField).blockName)
                    isValid = isValid && false; 
                    validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile: The entries of "%s"', myField);
                    warntext_{end+1,1} = sprintf('of the infofile of component "%s" are not compatible with the stored infofile!', refs_{i_});
                end
                if ~isfield(infofile_SC.(myField), 'epk')
                    isValid = isValid && false; 
                    validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile in selectedConfig: The sub-struct "%s" in "%s"', myField, refs_{i_});
                    warntext_{end+1,1} = sprintf('does not have an entry "epk"!');
                elseif ~isfield(infofile_FS.(myField), 'epk')
                    isValid = isValid && false; 
                    validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid stored infofile: The sub-struct "%s" in "%s"', myField, refs_{i_});
                    warntext_{end+1,1} = sprintf('does not have an entry "epk"!');
                elseif ~strcmp(infofile_SC.(myField).epk, infofile_FS.(myField).epk)
                    isValid = isValid && false; 
                    validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile: The epk versions in "%s"', myField);
                    warntext_{end+1,1} = sprintf('of the infofile of component "%s" are not compatible with the stored infofile!', refs_{i_});
                end
            case {'sampletime', 'solvertype'}
                if ~strcmp(refs_{i_}, {'VMC', 'Vehicle'})
                    if ~strcmp(infofile_SC.(myField), infofile_FS.(myField))
                        isValid = isValid && false; 
                        validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                        warntext_{end+1,1} = sprintf('Invalid infofile: The value of "%s"', myField);
                        warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!', refs_{i_});
                    end
                end
            case {'name', 'kind', 'parent', 'status'} % These are only string compares
                if ~strcmp(infofile_SC.(myField), infofile_FS.(myField))
                    isValid = isValid && false; 
                    validReferences_ = setdiff(validReferences_, refs_{i_}, 'stable');
                    warntext_{end+1,1} = sprintf('Invalid infofile: The value of "%s"', myField);
                    warntext_{end+1,1} = sprintf('of the infofile of component "%s" is not compatible with the stored infofile!', refs_{i_});
                end
        end
    end
end

% Check solvertype and sampletime for the toplevels and generic.mdl
if exist('VMCSim_', 'var')
    tempSelectedConfig = updateWinnerSolverAndSampleTime(selectedConfig);
    
    if ~strcmp(tempSelectedConfig.VMC.infofile.solvertype, selectedConfig.VMC.infofile.solvertype)
        isValid = isValid && false;
        warntext_{end+1,1} = 'Invalid selectedConfig: The value of solvertype';
        warntext_{end+1,1} = 'of the original selectedConfig of VMC is not compatible with the value of the expected solvertype!';
    end
    if ~strcmp(tempSelectedConfig.VMC.infofile.sampletime, selectedConfig.VMC.infofile.sampletime)
        isValid = isValid && false;
        warntext_{end+1,1} = 'Invalid selectedConfig: The value of sampletime';
        warntext_{end+1,1} = 'of the original selectedConfig of VMC is not compatible with the value of the expected sampletime!';
    end
    if ~strcmp(tempSelectedConfig.Vehicle.infofile.solvertype, selectedConfig.Vehicle.infofile.solvertype)
        isValid = isValid && false;
        warntext_{end+1,1} = 'Invalid selectedConfig: The value of solvertype';
        warntext_{end+1,1} = 'of the original selectedConfig of Vehicle is not compatible with the value of the expected solvertype!';
    end
    if ~strcmp(tempSelectedConfig.Vehicle.infofile.sampletime, selectedConfig.Vehicle.infofile.sampletime)
        isValid = isValid && false;
        warntext_{end+1,1} = 'Invalid selectedConfig: The value of sampletime';
        warntext_{end+1,1} = 'of the original selectedConfig of Vehicle is not compatible with the value of the expected sampletime!';
    end
    
    if ~strcmp(tempSelectedConfig.VMCSim.infofile.solvertype, VMCSim_.infofile.solvertype)
        isValid = isValid && false;
        warntext_{end+1,1} = 'Invalid selectedConfig: The value of solvertype';
        warntext_{end+1,1} = 'of the original selectedConfig of VMCSim is not compatible with the value of the expected solvertype!';
    end
    if ~strcmp(tempSelectedConfig.VMCSim.infofile.sampletime, VMCSim_.infofile.sampletime)
        isValid = isValid && false;
        warntext_{end+1,1} = 'Invalid selectedConfig: The value of sampletime';
        warntext_{end+1,1} = 'of the original selectedConfig of VMCSim is not compatible with the value of the expected sampletime!';
    end
    if isValid
        selectedConfig.VMCSim = VMCSim_;
    end
else
    isValid = isValid && false;
    warntext_{end+1,1} = sprintf('Invalid selectedConfig: VMCSim entry is missing!');
end

if nargout==3
    varargout{1} = isValid;
    varargout{2} = warntext_;
    varargout{3} = validReferences_;
elseif nargout==2
    varargout{1} = isValid;
    varargout{2} = warntext_;
else
    varargout{1} = isValid;
    warning('%s\n', warntext_{:});
end
