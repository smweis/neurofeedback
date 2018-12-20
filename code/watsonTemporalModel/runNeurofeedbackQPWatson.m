


%% Either edit these variables here, or input them each time.
%subject = input('Subject number?','s');
%run = input('Which run?','s');
subject = 'TOME_3040_TEST';
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

%% Initialize Quest and TFE

initializeQuestAndTFE;


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

% We could initialize this with the number of TRs, if known in advance. 
roiSignal = [];

i = 0;
j = 1;
while i < 10000000000
    i = i + 1;
    
    % Check for a new DICOM. This will run until there is a new one. 
    [mainData(j).acqTime,mainData(j).dataTimepoint,mainData(j).roiSignal,...
     initialDirSize, mainData(j).dicomName] = ...
     checkForNewDicom(scannerPath,roiIndex,initialDirSize,scratchPath);
 
    % turn latest acquired dicoms back into a vector. 
    for k = 1:length(mainData(j).roiSignal)
        roiSignal(end+1) = mainData(j).roiSignal(k);
    end
 
    % Mean center roiSignal and take out linear trends
    roiSignal = detrend(roiSignal);
    roiSignal = detrend(roiSignal,'constant');
 
    
    % update thePacket for TFE
    thePacket.response.values(1:length(roiSignal)) = roiSignal;
    
    % run TFE
    params = temporalFit.fitResponse(thePacket,...
        'defaultParamsInfo', defaultParamsInfo, ...
        'searchMethod','linearRegression');
    
    
    % get the latest list of actual Stimuli that have been run
    actualStims = readActualStimuli(fullfile(subjectPath,'actualStimuli.txt'));
    
    
    % re-start the questData structure from when it was initialized;
    questData = questDataCopy;
    
    
    %% Turn this into a function. 
    
    % adjust pctBOLDbins if necessary creating 20 bins, evenly spaced, 
    % between the observed min and max
    if min(params.paramMainMatrix) < min(pctBOLDbins)
        pctBOLDbinsMin = min(params.paramMainMatrix) - .01;
    end
    
    if max(params.paramMainMatrix) > max(pctBOLDbins)
        pctBOLDbinsMax = max(params.paramMainMatrix) + .01;
    end
    pctBOLDbins = pctBOLDbinsMin:(pctBOLDbinsMax-pctBOLDbinsMin)/20:pctBOLDbinsMax;
    
    %% Run Q+ update with every stim so far and every outcome as given by TFE
    for k = 1:length(actualStims)
        outcome = discretize(params.paramMainMatrix(k),pctBOLDbins);
        questData = qpUpdate(questData,actualStims(k),outcome);
    end
    
    % get the next suggested stim from Q+
    stim = qpQuery(questData);
    
    
    %% Turn this into a function. 
    % write the suggeste stim to a new text file
    nextStimNum = length(dir(fullfile(subjectPath,'stimLog'))) + 1;
    nextStimFileName = horzcat('nextStimuli',num2str(nextStimNum),'.txt');
    nextStimFullPath = fullfile(subjectPath,'stimLog',nextStimFileName);
    fidw = fopen(nextStimFullPath,'w');
    fprintf(fidw,'%d',stim);
    fclose(fidw);

    %% Next iteration
    j = j + 1;

    pause(0.01);
end
