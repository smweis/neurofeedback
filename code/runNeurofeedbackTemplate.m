


%% Either edit these variables here, or input them each time.
%subject = input('Subject number?','s');
%run = input('Which run?','s');
subject = 'TOME_3021_rtSim/rawDicomIncoming';
run = '1';



% set flags
showFig = false;
checkForTrigger = true;
registerToFirst = true;

% initialize figure
if showFig
    figure;
end

%% Get Relevant Paths

[subjectPath, scannerPath, codePath, scratchPath] = getPaths(subject);


%% Check for trigger

if checkForTrigger
    first_trigger_time = waitForTrigger;
end

%% Register to First DICOM

if registerToFirst
    [ap_or_pa,initialDirSize] = registerToFirstDicom(subject,subjectPath,run,scannerPath,codePath);
end

%% Load the ROI HERE!

roiName = ['ROI_to_new',ap_or_pa,'_bin.nii.gz'];
roiPath = fullfile(subjectPath,roiName);
roiIndex = loadRoi(roiPath);


%% Main Neurofeedback Loop

% Initialize the main data struct;
mainData = struct;
mainData.acqTime = {}; % time at which the DICOM hit the local computer
mainData.dataTimepoint = {}; % time at which the DICOM was processed
mainData.dicomName = {}; % name of the DICOM
mainData.roiSignal = {}; % whatever signal is the output (default is mean)


% This script will check for a new DICOM, then call scripts that will
% convert it to NIFTI, and do some processing on the NIFTI.
% (Extract ROI, compute mean signal of the ROI).

i = 0;
j = 1;
while i < 10000000000
    i = i + 1;

    [mainData(j).acqTime,mainData(j).dataTimepoint,mainData(j).roiSignal,...
     initialDirSize, mainData(j).dicomName] = ...
     checkForNewDicom(scannerPath,roiIndex,initialDirSize,scratchPath);
    
    % write out a file each time a new one comes in
    save(fullfile(scratchPath,'mainData'),'mainData');
 
 
    j = j + 1;

    pause(0.01);
end
