%% Either edit these variables here, or input them each time.
%subject = input('Subject number?','s');
%run = input('Which run?','s');
subject = 'TOME_3040_TEST';
run = '1';



% initialize some global variables


% initialize figure
figure;

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
[acqTime,dataTimepoint,v1Signal,dicomAcqTime] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize);









