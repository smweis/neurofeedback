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
        projectBasePath = [filesep 'Users' filesep userID filesep 'Documents' filesep 'MATLAB' filesep 'projects' filesep projectName];
    otherwise
        currentSubjectBasePath = [filesep 'Users' filesep, userID filesep 'Documents' filesep 'rtQuest'];
        projectBasePath = [filesep 'Users' filesep userID filesep 'Documents' filesep 'MATLAB' filesep 'projects' filesep projectName];

end

addpath(genpath(projectBasePath));

%% Generate a parallel pool of workers, based on the number of logical cores on your system
% To find out how many you have look at logical cores: 
% feature('numCores'); 

parpool(8);

%% Try to log into the scanner computer at SC3T

username = 'mars2';
password = 'PASSword$$$$1111';
serverIP = '10.140.146.254';

command = ['mount_smbfs //' username ':' password '@' serverIP filesep 'mnt' filesep 'rtexport'];

status = system(command);
if status == 0
    fprintf('success');
    scannerBasePath = [filesep 'Volumes' filesep 'rtexport' filesep 'RTexport_Current' filesep];
  
else
    warning('No server access.');
    scannerBasePath = [projectBasePath filesep 'test_data' filesep 'fake_dicoms' filesep 'copy_into' filesep];
end


%% Specify where output goes

if ismac
    % Code to run on Mac plaform
    setpref(projectName,'analysisScratchDir',[filesep 'tmp' filesep 'neurofeedback']);
    setpref(projectName,'projectRootDir',projectBasePath);
    setpref(projectName,'currentSubjectBasePath', currentSubjectBasePath);
    setpref(projectName,'scannerBasePath',scannerBasePath);
    
    % SET FSL Directory
    fsl_path = [filesep 'usr' filesep 'local' filesep 'fsl' filesep];
    setenv('FSLDIR',fsl_path);
    setenv('FSLOUTPUTTYPE','NIFTI_GZ');
    curpath = getenv('PATH');
    setenv('PATH',sprintf('%s:%s',fullfile(fsl_path,'bin'),curpath));

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
