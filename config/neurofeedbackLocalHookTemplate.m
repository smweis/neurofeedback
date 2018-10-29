function neurofeedbackLocalHook
%  neurofeedbackLocalHook
%
% Configure things for working on the  neurofeedback project.
%
% For use with the ToolboxTo
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localToolboxHooks/neurofeedbackLocalHook.m
%
% Each time you run tbUseProject('neurofeedback'), ToolboxToolbox will
% execute your local copy of this file to do setup.
%
% You should edit your local copy with values that are correct for your
% local machine, for example the output directory location.
%


%% Say hello.
fprintf('neurofeedback local hook.\n');
projectName = 'neurofeedback';

%% Delete any old prefs
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify base paths for materials and data
[~, userID] = system('whoami');
userID = strtrim(userID);
switch userID
    case {'iron'}
        currentSubjectBasePath = [filesep 'Users' filesep, userID filesep 'Documents' filesep 'rtQuest'];
    otherwise
        currentSubjectBasePath = [filesep 'Users' filesep, userID filesep 'Documents' filesep 'rtQuest'];
end

%% Specify where output goes

if ismac
    % Code to run on Mac plaform
    setpref(projectName,'analysisScratchDir',[filesep 'tmp' filesep 'neurofeedback']);
    setpref(projectName,'projectRootDir',[filesep 'Users' filesep ,userID, filesep 'Documents' filesep 'Matlab',projectName]);
    setpref(projectName,'currentSubjectBasePath', currentSubjectBasePath);
elseif isunix
    % Code to run on Linux plaform
    setpref(projectName,'analysisScratchDir',[filesep 'tmp' filesep 'neurofeedback']);
    setpref(projectName,'projectRootDir',[filesep 'Users' filesep ,userID, filesep 'Documents' filesep 'Matlab',projectName]);
    setpref(projectName,'currentSubjectBasePath', currentSubjectBasePath);
    
elseif ispc
    % Code to run on Windows platform
    warning('No supported for PC')
else
    disp('What are you using?')
end
