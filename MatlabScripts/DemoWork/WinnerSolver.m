function selectedConfigOut = updateWinnerSolverAndSampleTime(selectedConfigIn)
% updateWinnerSolverAndSampleTime - This function determines the winner
% solvertype and sampletime of the TopLevels and the generic.mdl 
% and adds it to the selectedConfig.
%
% Syntax:
%  [winnerSolver, winnerSampleTime] = getWinnerSolverAndSamplerTime('VMC', selectedConfig_)
%
% Inputs:
%  selectedConfigIn     selectedConfig with selected components which are the
%                       base for sampletime and solvertype determination
%
% Outputs:
%  selectedConfigOut    selectedConfig with determined winner solver and
%                       sampletime

% Add winnersettings for VMC
selectedConfigIn = determineWinner('VMC', selectedConfigIn);

% Add winnersettings for Vehicle
selectedConfigIn = determineWinner('Vehicle', selectedConfigIn);

% Add winnersettings for VMCSim
if ~isfield(selectedConfigIn, 'VMCSim')
    selectedConfigIn.VMCSim.infofile.references = {'VMC', 'Vehicle'};
end
selectedConfigIn = determineWinner('VMCSim', selectedConfigIn);

% Write resulting selectedConfig to return value
selectedConfigOut = selectedConfigIn;

end % END of updateWinnerSolverAndSampleTime

function selectedConfigOut = determineWinner(name_, selectedConfigIn)

% Allowed solvers (has to be in the correct order!)
sortedSolvers  = {'FixedStepDiscrete'; 'ode1'; 'ode2'};

% Get solvers and sampletimes
refs_        = selectedConfigIn.(name_).infofile.references;
if ~isempty(refs_)
    solvers_     = cellfun(@(x) selectedConfigIn.(x).infofile.solvertype, ...
        refs_, 'UniformOutput', false);
    sampleTimes_ = cellfun(@(x) selectedConfigIn.(x).infofile.sampletime, ...
        refs_, 'UniformOutput', false);
else
    solvers_     = {'FixedStepDiscrete'};
    sampleTimes_ = {'0.02'};
end

% Find out who's the winner
winnerSolver     = sortedSolvers{max(cellfun(@(x) find(strcmp(sortedSolvers, x)), solvers_))};
winnerSampleTime = num2str(min(str2double(sampleTimes_(:))));

% Write result to selectedConfig
selectedConfigIn.(name_).infofile.solvertype = winnerSolver;
selectedConfigIn.(name_).infofile.sampletime = winnerSampleTime;
selectedConfigOut = selectedConfigIn;

end % END of determineWinner
