



%% Enter in some initial values

% Set FSL directory
setenv('FSLDIR','/usr/local/fsl');

% Enter subject ID here
subjectID = 'TOME_3021';

% Enter run name and numbers here
runNums = [1];
runName = 'tfMRI_CheckFlash_PA_run';

% Download all relevant data from Flywheel and place in subject directory.
subjectDir = fullfile('/Users/nfuser/Documents/rtQuest',subjectID);
addpath(subjectDir);


%% Create retinotopy-based V1 mask
% Retintopy data, downloaded from Flywheel from a previous study. 
areasPath = fullfile(subjectDir,horzcat(subjectID,'_native.template_areas.nii.gz'));
eccenPath = fullfile(subjectDir,horzcat(subjectID,'_native.template_eccen.nii.gz'));
anglesPath = fullfile(subjectDir,horzcat(subjectID,'_native.template_angle.nii.gz'));

% Read in retinotopic maps with MRIread
areasMap = MRIread(areasPath);
eccenMap = MRIread(eccenPath);
anglesMap = MRIread(anglesPath);

% Relevant retinotopic values. 
areas = 1; % V1
eccentricities = [0 12];
angles = [0 360];

% Create retinotopic mask (in T1w space)
[maskFullFile,saveName] = makeMaskFromRetino(eccenMap,areasMap,anglesMap,areas,eccentricities,angles,subjectDir);

%% Register functional data to anatomical data. 
% Where is anatomical and functional data (NOTE, FUNC DATA ARE IN STANDARD SPACE):
T1Path = fullfile(subjectDir,horzcat(subjectID,'_T1.nii.gz'));

funcName = [runName num2str(runNums)];
funcDataPath = fullfile(subjectDir,subjectID,'MNINonLinear','Results',funcName,[funcName '.nii.gz']);


% Extract brain from T1 
fprintf('BET\n');
cmd = horzcat('/usr/local/fsl/bin/bet ',T1Path,' ',subjectDir,'/betT1.nii.gz');
system(cmd);

% Get scout EPI image.
fprintf('Create scout EPI image\n');
cmd = horzcat('/usr/local/fsl/bin/fslroi ',funcDataPath,' ',subjectDir,'/scoutEPI.nii.gz 0 91 0 109 0 91 0 1');
system(cmd);

% Calculate registration matrix
fprintf('Calculate registration matrix\n');
cmd = horzcat('/usr/local/fsl/bin/flirt -ref /usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz -in ',subjectDir,'/betT1.nii.gz -out ',subjectDir,'/T12standard -omat ',subjectDir,'/T12standard.mat ');
system(cmd);

% Apply registration to mask
fprintf('Apply registration matrix to mask\n');
cmd = horzcat('/usr/local/fsl/bin/flirt -ref /usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz -in ',maskFullFile,' -applyxfm -init ',subjectDir,'/T12standard.mat -out ',subjectDir,'/retinoMask2standard');
system(cmd);

% Binarize mask, thresholded at .2 to get rid of some noise
fprintf('Threshold and binarize mask\n');
cmd = horzcat('/usr/local/fsl/bin/fslmaths ',subjectDir,'/retinoMask2standard -thr .4 -bin ',subjectDir,'/retinoMask2standardBin');
system(cmd);



%% Spot check

% Everything (retino data, functional data) should be in MNI space. Spot
% check that with fsleyes 

cmd = horzcat('/usr/local/fsl/bin/fsleyes ', subjectDir,'/scoutEPI.nii.gz ',subjectDir,'/retinoMask2standardBin.nii.gz');
system(cmd);

%% Extract V1 timeseries

funcData = MRIread(funcDataPath);
funcData = funcData.vol;

retinoMask = MRIread(horzcat(subjectDir,'/retinoMask2standardBin.nii.gz'));
ROIindex = logical(retinoMask.vol);

v1Timeseries = zeros(1,size(funcData,4));

for i = 1:size(funcData,4)
    tempVol = funcData(:,:,:,i);
    tempVolMasked = tempVol(ROIindex);
    v1Timeseries(i) = mean(tempVolMasked,'all');
end


v1Detrend = detrend(v1Timeseries);

detrendTimeseries = detrendTimeseries/(max(detrendTimeseries)-min(detrendTimeseries));

