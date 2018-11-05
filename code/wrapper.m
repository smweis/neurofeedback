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
iteration = 1;
acqTime = repmat(datetime,10000,1);
dataTimepoint = repmat(datetime,10000,1);
v1Signal = repmat(10000,1);

    
i = 0;
while i < 10000000000
    i = i + 1;
    [acqTime(iteration),dataTimepoint(iteration),v1Signal(iteration),initialDirSize] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize);
    iteration = iteration + 1;
    pause(0.01);
end








