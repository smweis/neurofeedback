function [acqTime,dataTimepoint,roiSignal,initialDirSize,dicomNames] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize, scratchPath)    
%% Check for DICOMs

% Save a time stamp
acqTime = datetime;

% check files in scanner_path
newDir = dir(scannerPath); 

% If no new files, call the function again
if length(newDir) == initialDirSize
    pause(0.01);
    [acqTime,dataTimepoint,roiSignal,initialDirSize,dicomNames] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize, scratchPath);

    
% If there are new files
elseif length(newDir) > initialDirSize
    missedDicomNumber = length(newDir) - initialDirSize; % how many DICOMS were missed?
    initialDirSize = length(newDir); % reset # of files
    newDicoms = newDir(end + 1 - missedDicomNumber:end); % get the last # of missed dicoms
    

    
    %% Process the DICOMs into NIFTIs in a parallel computing loop
    %tic
    parfor j = 1:length(newDicoms)
        thisDicomName = newDicoms(j).name;
        thisDicomPath = newDir(j).folder; % get path to file
        
        
        targetIm = extract_signal(thisDicomName,thisDicomPath,scratchPath);
        
     
        [roiSignal(j),dataTimepoint(j)] = scanner_function(targetIm,roiIndex);
        dicomNames{j} = thisDicomName;
    end
    %toc
    
end

end

