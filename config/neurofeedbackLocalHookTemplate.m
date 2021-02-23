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
    fprintf('No FSL available on Windows.');
    userID = strsplit(userID,'\');
    userID = userID{2};
    baseDir = '\\exasmb.rc.ufl.edu';
else
    baseDir = '';
    
    % Load packages for data analysis on Hipergator. 
    system('module load mricrogl');
    system('module load fsl');

end

try
    % scannerBasePath is the main directory where the scanner will drop files.
    scannerBasePath = fullfile(baseDir,'blue',...,
        'stevenweisberg','share','rtfmri_incoming');
    cd(scannerBasePath);
    addpath(scannerBasePath);
    fprintf('Success, server mounted at: %s',scannerBasePath);
    
catch
    fprintf('No server found at: %s',scannerBasePath);
    fprintf('Try mounting the Hipergator and trying again.');
end

% projectBasePath is where the Matlab directories are.
projectBasePath = fullfile(baseDir,'blue',...,
        'stevenweisberg',userID,'MATLAB','projects',projectName);
addpath('projectBasePath');    

% currentSubjectBasePath will load in the new currentSubjectData
currentSubjectBasePath = fullfile(baseDir,'blue','stevenweisberg','rtQuest','rtQuest');
addpath(currentSubjectBasePath);

analysisScratchDir = fullfile(scannerBasePath,'scratch');
mkdir(analysisScratchDir);
addpath(analysisScratchDir);

setpref(projectName,'analysisScratchDir',analysisScratchDir);
setpref(projectName,'projectRootDir',projectBasePath);
setpref(projectName,'currentSubjectBasePath', currentSubjectBasePath);
setpref(projectName,'scannerBasePath',scannerBasePath);

end
