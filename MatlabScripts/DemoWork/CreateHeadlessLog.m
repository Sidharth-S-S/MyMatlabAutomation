function createLogFile(varargin)
% createLogFile - This function logs the errors and warnings which were
% encountered during the headless execution.
%
% Description:
%  This function will be called in the startRemoteSession whenever an error
%  or warning is required to be logged. The log file has to be deleted in
% Possible inputs:
%  testSeries       Name/Path of the TestSeries.
%  testRun          Name/Path of the TestRun.
%  Variation        Name of the Variation.
%  Err_Msg          Error Message if provided from the another scripts.
%  Warn_Msg         Warning Message if provided from the another scripts.
%  job              Current job under execution.
%  Exception_       Matlab Exception which has all info  for error logging.
% Default values
job_ = [];
testRun_ = [];
testSeries_ = [];
variation_ = [];
Err_Msg_ = [];
Warn_Msg_ = [];
MException_ = [];

for h_=2:2:nargin
    switch lower(varargin{h_-1})
        case 'job'
            if ~isempty(varargin{h_})
                job_ = varargin{h_};
            else
                error('No input argument given for "job" ! Aborting ...');
            end
            
        case {'testseries'}
            if ~isempty(varargin{h_}) && ischar(varargin{h_})
                testSeries_ = varargin{h_};
            else
                error('The input argument given for "testSeries" has to be a a string! Aborting ...');
            end
            
        case {'testrun'}
            if ~isempty(varargin{h_}) && ischar(varargin{h_})
                testRun_ = varargin{h_};
            else
                error('The input argument given for "testRun" has to be a a string! Aborting ...');
            end
            
        case {'variation'}
            if ~isempty(varargin{h_}) && ischar(varargin{h_})
                variation_ = varargin{h_};
            else
                error('The input argument given for "Variation" has to be a a string! Aborting ...');
            end
            
        case {'warn_msg'}
            if ~isempty(varargin{h_}) && ischar(varargin{h_})
                Warn_Msg_ = varargin{h_};
            else
                error('No input argument given for "Warn_Msg" ! Aborting ...');
            end
            
        case {'err_msg'}
            if ~isempty(varargin{h_}) && ischar(varargin{h_})
                Err_Msg_ = varargin{h_};
            else
                error('No input argument given for "Err_Msg" ! Aborting ...');
            end
        case {'exception_'}
            if ~isempty(varargin{h_})
                classinfo = metaclass(varargin{h_});
                if strcmp(classinfo.Name,'MException')
                    MException_ = varargin{h_};
                else
                    error('The input argument "Exception_" should be of the class MException.  Aborting ...');
                end
            else
                error('No input argument given for "Err_Msg" ! Aborting ...');
            end
            
        otherwise
            warning('Unknown input argument "%s" given. Ignoring ...', varargin{h_-1});
    end
end

% Open the log file and write down the information passed to this function
fid = fopen('Results\headless\Headless_Execution.txt','a');
if fid ~= -1
    % Add for job data
    if exist('job_','var') && ~isempty(job_)
        fprintf(fid, '\nJob Start DataTime %s:', job_.StartDateTime);
        fprintf(fid,'\n');
        if ~isempty(job_.Tasks.Error)
            fprintf(fid,'Job Error Message %s:',job_.Tasks.Error.message);
            fprintf(fid,'\n');
            fprintf(fid,'Job Error Identifier %s:',job_.Tasks.Error.identifier);
            fprintf('\n');
            for jj = 1:length(job_.Tasks.Error.stack)
                fprintf(fid,'Error File name %s: ',job_.Tasks.Error.stack(jj).filename);
                fprintf(fid,'Job Error Line number %s:',job_.Tasks.Error.stack(jj).linenum);
            end
        end
    end
    
    % Add test series name
    if exist('testSeries_','var') && ~isempty(testSeries_)
        fprintf(fid, 'Name of the Test Series: %s', testSeries_);
        fprintf(fid,'\n');
    end
    % Add test run name
    if exist('testRun_','var')&& ~isempty(testRun_)
        fprintf(fid, 'Name of the Testrun: %s', testRun_);
        fprintf(fid,'\n');
    end
    % Add variation name
    if exist('variation_','var') && ~isempty(variation_)
        fprintf(fid, 'Variation: %s', variation_);
        fprintf(fid,'\n');
    end
    % Add error message
    if exist('Err_Msg_','var') && ~isempty(Err_Msg_)
        fprintf(fid, 'Error Message:\n%s', Err_Msg_);
        fprintf(fid,'\n');
    end
    % Add warning message
    if exist('Warn_Msg_','var') && ~isempty(Warn_Msg_)
        fprintf(fid, 'Warning Message:\n%s', Warn_Msg_);
        fprintf(fid,'\n');
    end
    
    %     Add MException details.
    if exist('MException_','var') && ~isempty(MException_)
        fprintf(fid,'\nError Message: %s', MException_.message);
        fprintf(fid,'\nError Identifier: %s', MException_.identifier);
        for ii = 1:length(MException_.stack)
            fprintf(fid,'\nError File name: %s\n', MException_.stack(ii).file);
            fprintf(fid,'\nError Line number: %s\n', num2str(MException_.stack(ii).line));
        end
    end
    fprintf(fid,'#####################################################################');
    fprintf(fid,'\n');
    % Close the log file again
    fclose(fid);
end



function Pids_ = getPid(appString)
  % getPid - Get Process ids from program name
%
% Inputs:
%  appString             Name of the program in task manager (e.g.
%                        MATLAB.exe or HIL.exe)
%
% Outputs:
%  Pids_                 Array of PIDs corresponding to the provided
%                        application name (appString)
  % Get PID STring from task manager
[~, PidString] = system(['tasklist | "C:\\Program Files\\Git\\usr\\bin\\grep.exe" "', appString, '"']);

% Extract PIDs as numbers
m_string = strsplit(PidString, '\n');
Pids_ = [];
n = 1;
for i = 1:length(m_string)
    if ~isempty(m_string{i})
        Pids_(1,n) = sscanf(m_string{i}, '%*s %d %*s %*d %*f %*s'); %#ok<AGROW>
        n=n+1;
    end
end


function readDiagnosticLog()
% readDiagnosticLog - This function is used to read Diagnostcs.txt and add
% it to the Headless_Execution.txt.
%
% Description:
%  This function reads the Diagnostic.txt and add the content to the 
%  Headless_Execution.txt. This function will be called inside the
%  startRemoteSession file.
%  This function gets the details of warning and error messages during the
%  headless execution.
  % open the diagnistics file
fid = fopen('SimulinkCache\Diagnostics.txt');
if fid~=-1
    text = fscanf(fid,'%c');
    fclose(fid);
else
    text = 'Unable to access the Diagnostics.txt file.';
end

fid1 = fopen('Results\headless\Headless_Execution.txt','a');
% Write the whole content of the file into the Headless_Execution.txt
if fid1~=-1
    fprintf(fid1,'\n Details of Model update are as below \n');
    fprintf(fid1, '%s',text);
    fprintf(fid1,'\n');
    fprintf(fid1,'#######################################################################');
    fclose(fid1);
end


function readSessionLog()
% readSessionLog - This function is used to read the session log details
% from CarMaker.
%
% Description:
%  This function is used to read the session log file which will be present
%  at the below location [<vmc sim environment>\SimOutput\Host Name\Log].
%  These errors and warnings will be further logged.
  
  % Find the newest session log file
files = dir(['..\SimOutput\'  getenv('COMPUTERNAME') '\Log\*.log']);
if ~isempty(files)
    [~,idx] = max([files.datenum]);
    filename = [files(idx).folder filesep files(idx).name];
    % Open session log
    fid = fopen(filename);
    % Go through the file and find all relevant data to be logged in headless
    % execution log
    if fid ~=-1
        text = fscanf(fid,'%c');
        fclose(fid);
    else
        text = 'Unable to access the Session log file.';
    end
    fid1 = fopen('Results\headless\Headless_Execution.txt','a');
    % Write the whole content of the file into the Headless_Execution.txt
    if fid1~=-1
        fprintf(fid1,'#######################################################################');
        fprintf(fid1,'\n Details of Session Log are as below\n');
        fprintf(fid1,'%s',text);
        fprintf(fid1,'\n');
        fprintf(fid1,'#######################################################################');
        fclose(fid1);
    else
        error('Unable to read the file Headless_Execution.txt');
    end
end

function licNo = waitForCMLic(jenkinsUser)
% waitForCMLic - Wait for free CM license and return license number
%
% Description:
%  This function checks if a free license for CM is availabele. If this is
%  not the case, it tries for 60 seconds or 24 hours, dependent whether a
%  local execution or an execution on jenkins is performed, to get a
%  license. If it succeeds in this time frame, the used license will be
%  returned, outerwise an error is thrown.
success = false;
licNo = 'License Error: user limit reached';

% Get CM directory
CM_path = which('CM_Simulink');
endOfPath = strfind(CM_path, 'CM4SL');
CM_path = CM_path(1:endOfPath-1);
CM_path = strrep(CM_path, '/', '\');

if strcmpi(getenv('USERNAME'), jenkinsUser)
    waitTime = 30;
    timeOut = 86400;
else
    waitTime = 1;
    timeOut = 60;
end

t=0;

while t<timeOut
    [~, Licenses] = system([CM_path, 'GUI\HIL.exe -licinfo']);
    if contains(Licenses, 'License Error:')
        fprintf(1, 'No CM License available! Waiting for another %d seconds before retrying to get CM License!\n', waitTime);
        pause(waitTime);
        t=t+waitTime;
    elseif contains(Licenses, 'Error:')
        warning('Connection to CarMaker license server is not possible. Please try again later.');
        break
    else
        success = true;
        break;
    end
end

if ~success
    licNo = '';
    warning('CarMaker License is not available. Please try again later.');
else
    strParts = strsplit(Licenses, '\n');
    if any(startsWith(strParts, 'License: '))
        lic = strParts{cellfun(@(x) any(startsWith(x, 'License: ')), strParts)};
        licParts = strsplit(lic, ' ');
        licNo = licParts{2};
    end
end


