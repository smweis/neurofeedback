%% Either edit these variables here, or input them each time.
%subject = input('Subject number?','s');
%run = input('Which run?','s');
subject = 'TOME_3040_TEST';
run = '1';



% set flags
showFig = false;

% initialize figure
if showFig
    figure;
end

%% Get Relevant Paths
[subjectPath, scannerPath, codePath] = getPaths(subject);


%% Check for trigger
first_trigger_time = wait_for_trigger;


%% Register to First DICOM

[ap_or_pa,initialDirSize] = register_to_first_dicom(subject,subjectPath,run,scannerPath,codePath);


%% Load the ROI HERE! 
roiName = ['ROI_to_new',ap_or_pa,'_bin.nii.gz'];
roiPath = fullfile(subjectPath,roiName);
roiIndex = load_roi(roiPath);


%% Main Neurofeedback Loop

mainData = struct;

mainData.acqTime = {};
mainData.dataTimepoint = {};
% figure how to save v1 signal in a way that allows you to do calculations
% on it. 
mainData.v1Signal = {};



% need to figure out how to do stuff outside this while loop? 
% maybe can do things inside it still. Not sure
i = 0;
while i < 10000000000
    i = i + 1;
    [newAcqTimes,newDataTimepoints,newV1Signals,initialDirSize] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize);
    mainData.acqTime = [mainData.acqTime newAcqTimes];
    mainData.dataTimepoint = [mainData.dataTimepoint newDataTimepoints];
    mainData.v1Signal = [mainData.v1Signal; newV1Signals];
    pause(0.01);
end








