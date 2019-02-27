
% Set FSL directory
setenv('FSLDIR','/usr/local/fsl');


% Enter subject ID here
subjectID = 'TOME_3021';

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
% Where is anatomical and functional data:
T1Path = fullfile(subjectDir,horzcat(subjectID,'_T1.nii.gz'));
funcDataPath = fullfile(subjectDir,'TOME_3021','MNINonLinear','Results','tfMRI_CheckFlash_PA_run1','tfMRI_CheckFlash_PA_run1.nii.gz');


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
cmd = horzcat('/usr/local/fsl/bin/flirt -ref ',subjectDir,'/betT1.nii.gz -in ',subjectDir,'/scoutEPI.nii.gz -out ',subjectDir,'/scout2T1 -omat ',subjectDir,'/scout2T1.mat');
system(cmd);

cmd = horzcat('/usr/local/fsl/bin/convert_xfm -omat ',subjectDir,'/T12scouti.mat -inverse ',subjectDir,'/scout2T1.mat');
system(cmd);

% Apply registration to mask
fprintf('Apply registration matrix to mask\n');
cmd = horzcat('/usr/local/fsl/bin/flirt -ref ',subjectDir,'/scoutEPI.nii.gz -in ',maskFullFile,' -applyxfm -init ',subjectDir,'/T12scouti.mat -out ',subjectDir,'/retinoMask2func');
system(cmd);

% Binarize mask, thresholded at .2 to get rid of some noise
fprintf('Threshold and binarize mask\n');
cmd = horzcat('/usr/local/fsl/bin/fslmaths ',subjectDir,'/retinoMask2func -thr .2 -bin ',subjectDir,'/retinoMask2funcBin');
system(cmd);


%% Extract V1 timeseries

funcData = MRIread(funcDataPath);
funcData = funcData.vol;

retinoMask = MRIread(horzcat(subjectDir,'/retinoMask2funcBin.nii.gz'));
ROIindex = logical(retinoMask.vol);

v1Timeseries = zeros(1,size(funcData,4));

for i = 1:size(funcData,4)
    tempVol = funcData(:,:,:,i);
    tempVolMasked = tempVol(ROIindex);
    v1Timeseries(i) = mean(tempVolMasked,'all');
end

    



