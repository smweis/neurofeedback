function [acqTime,dataTimepoint,v1Signal,initialDirSize] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize)    
%% Main Neurofeedback Loop

acqTime = datetime;

%initialize to # of files in scanner_path


newDir = dir(scannerPath); % check files in scanner_path

% if no new files, call the function again
if length(newDir) == initialDirSize
    pause(0.01);
    [acqTime,dataTimepoint,v1Signal,initialDirSize] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize);

% else if there are new files
elseif length(newDir) > initialDirSize
    missedDicomNumber = length(newDir) - initialDirSize; % how many DICOMS were missed?
    initialDirSize = length(newDir); % reset # of files
    newDicoms = newDir(end + 1 - missedDicomNumber:end); % get the last # of missed dicoms
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    
    %tic
    parfor j = 1:length(newDicoms)
        thisDicomName = newDicoms(j).name;
        thisDicomPath = newDir(j).folder; % get path to file

        targetIm = extract_signal(thisDicomName,thisDicomPath,subjectPath);
        
        
        %this is where the QUESTPLUS function should go!

        
        [v1Signal(j),dataTimepoint(j)] = scanner_function(targetIm,roiIndex);

        %plot(dataTimepoint(iteration),v1Signal(iteration),'r.','MarkerSize',20);
        %hold on;
        
    end
    %toc
    
end

end

