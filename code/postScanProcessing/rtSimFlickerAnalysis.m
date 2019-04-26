
 



subjectIDStem = 'TOME_3021';
subjectID = 'TOME_3021_rtSim';

% Enter run name and numbers here
subjectDirStem = '/Users/nfuser/Documents/rtQuest';

TR = 800;
ntrials = 30;
trialLength = 12000;

   

% Wrapper for all runs
for i = 1:5
    % Change the acquisition direction name depending on even or odd
    if mod(i,2) == 1
        runName = 'tfMRI_CheckFlash_PA_run';
    else
        runName = 'tfMRI_CheckFlash_AP_run';
    end

    load(fullfile(subjectDirStem,subjectID,'processed',strcat('run',num2str(i)),strcat('mainDatarun',num2str(i))));

    v1Timeseries = [mainData.roiSignal];
    v1Detrend = detrend(v1Timeseries);

    detrendTimeseries(i,:) = v1Detrend/(max(v1Detrend)-min(v1Detrend));
    
    stimParams(i) = load(fullfile(subjectDirStem,subjectIDStem,horzcat(subjectIDStem,'_run',num2str(i)),horzcat('stimDataRun',num2str(i),'.mat')));
    
    [tfeParams(i,:),scaledBOLDresponse(i,:),watsonParams(i,:)] = flickerAnalysisTFE(detrendTimeseries(i,:),stimParams(i),TR,ntrials,trialLength);
    
end

save(fullfile(subjectDirStem,subjectID,'processed','rtSimResults.mat'));
