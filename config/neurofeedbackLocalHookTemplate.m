function neurofeedbackLocalHook
%  neurofeedbackLocalHook
%
% Configure things for working on the neurofeedback project.
%
% For use with the toolboxToolbox.
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localHookFolder/neurofeedbackLocalHook.m
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


%% Generate a parallel pool of workers, based on the number of logical cores on your system
% To find out how many you have look at logical cores: 
% feature('numCores'); 


%% Automatically sort out paths
% These prefs are used by the real-time fMRI pipeline and are all on the
% local machine. 

[~, userID] = system('whoami');
userID = strtrim(userID);

if IsWindows
    userID = strsplit(userID,'\');
    userID = userID{2};
    baseDir = strcat('C:/Users/',userID,'/Documents/');
else
    baseDir = strcat('/blue/stevenweisberg/');
    % Load packages for data analysis on Hipergator. 
    system('ml mricrogl');
    system('ml fsl');
end

paths = struct;

% scannerBasePath is the main directory where the scanner will drop files.
paths.scannerBase = fullfile(baseDir,'blue',...,
    'share','rtfmri_incoming');

% projectBasePath is where the Matlab directories are.
paths.projectBase = fullfile(baseDir,'MATLAB','projects',projectName);

% currentSubjectBasePath will load in the new currentSubjectData
paths.currentSubjectBase = fullfile(baseDir,'blue','rtQuest');

% scratch is just for temporary storage.
paths.scratch = fullfile(paths.scannerBase,'scratch');

% Add all path names to the path
pathNames = fieldNames(paths);
for i = 1:length(pathNames)
    path = paths.(pathNames{i});
    if ~isfolder(path)
        mkdir(path);    
    end
    addpath(path);
end

cd(paths.scannerBase);

setpref(projectName,'analysisScratchDir',paths.scratch);
setpref(projectName,'projectRootDir',paths.projectBase);
setpref(projectName,'currentSubjectBasePath',paths.currentSubjectBase);
setpref(projectName,'scannerBasePath',paths.scannerBase);

end
