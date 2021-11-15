function returnCode = startHeadlessIntegration(config_,component_,instanceName_,artefact_)
% startHeadlessIntegration - Start the integration in the headless mode.
%
% Description:
%  This function is called during the headless integration. It clones the
%  instance and a new instance is created.
%
% Syntax:
%  startHeadlessIntegration(config_, component_, instanceName_, artefact_)
%
% Example:
%  startHeadlessIntegration('Configs/VMC_at_ADAS.json',...
%                           'Dasy', 'NewInstance',...
%                           '<Bitbucket Link or file path of OMCL>');
%
% Mandatory inputs:
%  component_             Name of the component
%  instanceName_          Name of the new instance
%  artefact_              String defining the link to the SW (OMCL commit
%                         or network drive)
%  config_                Cell array that consists of multiple
%                         configuration json files or a string defining one
%                         configuration json file.
% Output:
%  returnCode             0 = integration completed successfully
%                        Warnings:
%                         1 = some of the provided configs have been ignored
%                         2 = smoke test failed or could not be executed
%                         3 = smoke test failed & some of the provided configs have been ignored
%                         4 = some of the integrations have been skipped
%                         5 = automatic adaptions in OMCL mask
%                         6 = multiple warnings
%                        Errors:
%                         -1 = unable to access logfile
%                         -2 = contradicting selected configs
%                         -3 = no valid selected config
%                         -4 = creation of a new instance failed
returnCode = 0;

if ischar(config_)
    config_ = {config_};
end

% Reset files for logging
if ~isfolder('Results/headless')
    mkdir('Results/headless');
end
fid = fopen('Results/headless/Headless_Integration.txt','w');
if fid==-1
    returnCode = -1;
    return;
end
fid1 = fopen('Results/headless/PR_Description.txt', 'w');
if fid1==-1
    returnCode = -1;
    return;
else
    fclose(fid1);
end
fid1 = fopen('Results\headless\Headless_Execution.txt', 'w');
if fid1==-1
    returnCode = -1;
    return;
else
    fclose(fid1);
end

% Sort provided selected configs
cfgnames_ = {};
cfgnamesSameTL_ = {};
cfgnamesIgnored_ = {};
parentSameTL_ = {};
parent_ = {};
srcInstance_ = {};
for ii = 1:length(config_)
    selectedConfig_ = readJson(config_{ii});

    %... ignore invalid configs
    if ~isfield(selectedConfig_, component_)
        cfgnamesIgnored_{end+1} = config_{ii}; %#ok<AGROW>
        returnCode = 1;
        fprintf(fid, '\nWARNING: %s has no component %s! Update of this configuration skipped.', ...
            config_{ii}, component_);
        continue;
    end
    if exist(selectedConfig_.(component_).variant, 'dir') ~=7
        cfgnamesIgnored_{end+1} = config_{ii}; %#ok<AGROW>
        returnCode = 1;
        fprintf(fid, '\nWARNING: %s is outdated! The instance to be cloned (%s) does not exist. Update of this configuration skipped.', ...
            config_{ii}, selectedConfig_.(component_).variant);
        continue;
    end
    if exist([selectedConfig_.(component_).infofile.parent '/' instanceName_], 'file')==7
        cfgnamesIgnored_{end+1} = config_{ii}; %#ok<AGROW>
        returnCode = 1;
        fprintf(fid, '\nWARNING: %s already has an instance called %s! Update of this configuration skipped.', ...
            selectedConfig_.(component_).infofile.parent, instanceName_);
        continue;
    end

    duplicated_ = ismember(parent_, selectedConfig_.(component_).infofile.parent);
    if ~any(duplicated_)
        %... top level not yet considered
        %-> new instance & update of the selected config & smoke test
        cfgnames_{end+1} = config_{ii}; %#ok<AGROW>
        parent_{end+1} = selectedConfig_.(component_).infofile.parent; %#ok<AGROW>
        srcInstance_{end+1} = selectedConfig_.(component_).variant; %#ok<AGROW>
    elseif srcInstance_{duplicated_} ~= selectedConfig_.(component_).variant
        % ... contradicting configs -> error
        returnCode = -2;
        fprintf(fid, '\nERROR: Contradicting selected Configs provided! %s and %s mention different instances to be cloned for the same top level. Aborting ...', ...
            cfgnames_{duplicated_}, config_{ii});
        fclose(fid);
        return;
    else
        %... top level already considered
        %-> update the selected config only (no new instance, no smoke
        %test)
        cfgnamesSameTL_{end+1} = config_{ii}; %#ok<AGROW>
        parentSameTL_{end+1} = selectedConfig_.(component_).infofile.parent;  %#ok<AGROW>
    end

end

% ... any selected config left?
if isempty(parent_)
    returnCode = -3;
    fprintf(fid, '\nERROR: No valid selected configuration provided! Aborting ...');
    fclose(fid);
    return;
end

% Start creation of PR description
fid1 = fopen('Results/headless/PR_Description.txt', 'a');
if fid1==-1
    returnCode = -1;
    fprintf(fid, '\nERROR: Unable to open Results/headless/PR_Description.txt for writing!');
    fclose(fid);
    return;
end


% Add new instances
for ii = 1:length(parent_)
    fprintf(fid, '\n\n### Adding a new instance to %s ###################', ...
        parent_{ii});
    fprintf(fid1, "______________________________________________________________________\\n");
    % Clone the instance
    fprintf(fid, '\nCloning Artefact from %s ... ' , srcInstance_{ii});
    try
        lastwarn('', '');
        cloneInstance('srcFolder', srcInstance_{ii}, ...
            'Parent', parent_{ii}, 'Name', instanceName_);
    catch ME
        returnCode = 4;
        fprintf(fid, 'failed!\n');
        fprintf(fid, '\nERROR: Cloning of %s as %s failed!\n', ...
            [parent_{ii} '/' srcInstance_{ii}], [parent_{ii} '/' instanceName_]);
        removeInstance('parent', parent_{ii}, 'name', instanceName_);
        fprintf(fid, ['\t' ME.message newline]);
        fprintf(fid1, '!!! The integration of the new OMCL into %s was not successfull !!!\\n', ...
            [parent_{ii} '/' instanceName_]);
         fprintf(fid1, "----------------------------------------------------------------------------\\n");
        continue;
    end
    [warnMsg, ~] = lastwarn();
    if ~isempty(warnMsg)
        returnCode = 4;
        fprintf(fid, 'failed!\n');
        fprintf(fid, '\nWARNING: Cloning of %s as %s not possible!\n', ...
            [parent_{ii} '/' srcInstance_{ii}], [parent_{ii} '/' instanceName_]);
        fprintf(fid, ['\t' warnMsg newline]);
        fprintf(fid1, '!!! The integration of the new OMCL into %s was not successfull !!!\\n', ...
            [parent_{ii} '/' instanceName_]);
         fprintf(fid1, "----------------------------------------------------------------------------\\n");
        continue;
    end
    fprintf(fid, 'done!\n');
    rehash;

    % Integrating new artefact
    fprintf(fid, 'Integrating artefact new to the instance %s ... ', ...
        [parent_{ii} '/' instanceName_]);
    try
        lastwarn('', '');
        [isValid_, reason_] = modifyVMCInstance( ...
            'Path', [parent_{ii} '/' instanceName_], ...
            'Data', artefact_);
    catch ME
        returnCode = 4;
        fprintf(fid, 'failed!\n');
        fprintf(fid, '\nERROR: Integration of %s as %s failed!\n', ...
            artefact_, [parent_{ii} '/' instanceName_]);
        removeInstance('parent', parent_{ii}, 'name', instanceName_);
        fprintf(fid, ['\t' ME.message '\n']);
        fprintf(fid1, '!!! The integration of the new OMCL into %s was not successfull !!!\\n', ...
            [parent_{ii} '/' instanceName_]);
         fprintf(fid1, "----------------------------------------------------------------------------\\n");
        continue;
    end
    [warnMsg, warnID] = lastwarn();
    if ~isempty(warnMsg) 
        if strcmp(warnID, 'SfunAutoConnect:FixOmclMask')
            returnCode = 5;
            fprintf(fid, 'done!\n');
            fprintf(fid, '\tWARNING: Integration of the OMCL as %s only possible with automatic adaptions of the OMCL parameters!\n', ...
                [parent_{ii} '/' instanceName_]);
            fprintf(fid1, '\\nWARNING: Integration of the OMCL as %s only possible with automatic adaptions of the OMCL parameters!\\n', ...
                [parent_{ii} '/' instanceName_]);
        else
            returnCode = 4;
            fprintf(fid, 'failed!\n');
            fprintf(fid, '\nWARNING: Integration of the OMCL as %s failed!\n', ...
                [parent_{ii} '/' instanceName_]);
            fprintf(fid, ['\t' warnMsg '\n']);
            fprintf(fid1, '!!! The integration of the new OMCL into %s was not successfull !!!\\n', ...
                [parent_{ii} '/' instanceName_]);
             fprintf(fid1, "----------------------------------------------------------------------------\\n");
            continue;
        end
    else
        fprintf(fid, 'done!\n');
    end   
    rehash;

    interfaces = compareOMCLInterfaces(srcInstance_{ii},[parent_{ii} '/' instanceName_], fid, true);
    interfaceChanged = (~isempty(interfaces.inputs.new) || ~isempty(interfaces.inputs.removed) || ...
        ~isempty(interfaces.outputs.new)  || ~isempty(interfaces.outputs.removed));

    if ~isValid_ || interfaceChanged
        fprintf(fid, '\n*****************************************************************\n');
        fprintf(fid, 'The artefact is integrated into the instance %s, but needs revision!\n', ...
            [parent_{ii} '/' instanceName_]);
        fprintf(fid, '*****************************************************************\n');

        fprintf(fid1, '!!! The integration of the new OMCL into %s needs revision !!!\\n', ...
            [parent_{ii} '/' instanceName_]);
         fprintf(fid1, "----------------------------------------------------------------------------\\n");
    else
        fprintf(fid, '\n**********************************************************\n');
        fprintf(fid, 'The artefact is successfully integrated into the instance %s!\n', ...
            [parent_{ii} '/' instanceName_]);
        fprintf(fid, '**********************************************************\n');

        fprintf(fid1, 'The integration of the new OMCL into %s was successful!\\n', ...
            [parent_{ii} '/' instanceName_]);
         fprintf(fid1, "----------------------------------------------------------------------------\\n");
    end

    fprintf(fid1, '\\n');
    fprintf(fid1, 'Name of the new Instance: %s\\n',[parent_{ii} '/' instanceName_]);
    fprintf(fid1, 'Source of integrated artefact: %s\\n', strrep(artefact_, '\', '/'));
    fprintf(fid1, '\\n');

    % Log the interface differences into a text file PR_Description.
    if ~isValid_
        fprintf(fid1, 'Please check the log files for more details!\\n');
        fprintf(fid, 'The following reason was returned by checkInstance:\\n');
        fprintf(fid, '\t%s\\n', reason_.message);
    end
    if (~isempty(interfaces.inputs.new) || ~isempty(interfaces.inputs.removed) || ...
            ~isempty(interfaces.outputs.new)  || ~isempty(interfaces.outputs.removed))
        fprintf(fid1, '\\nThere are interface changes! Please check Headless_Integration.txt for further details.\\n');
        fprintf(fid1, '\\n');
    else
        fprintf(fid1, '\\nThere are no interface changes!\\n');
        fprintf(fid1, '\\n');
    end

    % Update selectedConfig
    fprintf(fid, '\nUpdate %s ...', cfgnames_{ii});
    UpdateSelectedConfig(cfgnames_{ii}, parent_{ii}, component_, instanceName_);
    rehash;
    fprintf(fid, 'done!\n');
    
     if isValid_
         % Run smoke test
         % Execute the default TestRun using headless mode of execution.
         % Official mode is set to false as the repo will not be clean due to
         % the addition of new instance.
         ret = startRemoteSession(cfgnames_{ii}, 'Headless_template', false, 'NoNewLogfile');
         if ret
             % Arbitrate warnings
             switch returnCode
                 case 0
                     returnCode = 2;
                 case {1, 3}
                     returnCode = 3;
                 case {4, 5, 6}
                     returnCode = 6;
             end
         end
         rehash;
     end

end

% Update selectedConfigs of an already updated top level
if ~isempty(cfgnamesSameTL_)
    fprintf(fid, '\n### Updating additional selectedConfigs ###################');
    fprintf(fid1, "______________________________________________________________________\\n");
    fprintf(fid1, "The following selectedConfigs have been updated:\\n");
    fprintf(fid1, "----------------------------------------------------------------------------\\n");
end
for ii=1:length(cfgnamesSameTL_)
    fprintf(fid, '\nUpdate %s ...', cfgnamesSameTL_{ii});
    try
        UpdateSelectedConfig(cfgnamesSameTL_{ii}, parentSameTL_{ii}, component_, instanceName_);
        fprintf(fid1, '- %s \\n', cfgnamesSameTL_{ii});
    catch
        fprintf(fid1, '- %s: Update failed!\\n', cfgnamesSameTL_{ii});
    end
end

% List ignored configs in PR
if ~isempty(cfgnamesIgnored_)
    fprintf(fid1, "______________________________________________________________________\\n");
    fprintf(fid1, "The following selectedConfigs have been ignored:\\n");
    fprintf(fid1, "----------------------------------------------------------------------------\\n");
    fprintf(fid1, "Please refer to Headless_Integration.txt for more details.\\n");
    for ii=1:length(cfgnamesIgnored_)
        fprintf(fid1, '- %s \\n', cfgnamesIgnored_{ii});
    end
end

% Close integer file identifier
fclose(fid);
fclose(fid1);

end

function LogInterfacesDifferences(interfaces, fid)
% LogInterfacesDifferences - Function to log the interface differences
%
% Inputs:
%  interfaces       Struct containing the list of common, new and removed
%                   interfaces
%  fid              file identifier
%
% Examplary function call:
%  LogInterfacesDifferences(interfaces,fid)

if ~isempty(interfaces.inputs.new)
    fprintf(fid, 'New input interfaces:\\n');
    fprintf(fid, '\\t- %s\\n', interfaces.inputs.new{:});
end

if ~isempty(interfaces.inputs.removed)
    fprintf(fid, 'Removed input interfaces:\\n');
    fprintf(fid, '\\t- %s\\n', interfaces.inputs.removed{:});
end

if ~isempty(interfaces.outputs.new)
    fprintf(fid, 'New output interfaces:\\n');
    fprintf(fid, '\\t- %s\\n', interfaces.outputs.new{:});
end

if ~isempty(interfaces.outputs.removed)
    fprintf(fid, 'Removed output interfaces:\\n');
    fprintf(fid, '\\t- %s\\n', interfaces.outputs.removed{:});
end

end

function UpdateSelectedConfig(config, parent, component, instance)
% UpdateSelectedConfig - Update a selected Config json file by replacing
% the selected instance of a VMC component by another instance
%
% Inputs:
%  config       original selected config json-file
%  parent       path of the parent to be modified
%  component    name of the component for which a new instance shall be
%               selected
%  instance     new instance to be selected
%
% Examplary function call:
%  UpdateSelectedConfig(cfgnames_{ii}, parent_{ii}, component_, instanceName_)

    selectedConfig_ = readJson(config);
    infofile_ = infofile_read([parent '/' instance]);
    selectedConfig_.(component).infofile = infofile_;
    selectedConfig_.(component).variant = [parent '/' instance];
    writeJson(selectedConfig_, '', config);
end
