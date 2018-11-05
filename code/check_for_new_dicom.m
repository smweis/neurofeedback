function [acqTime,dataTimepoint,v1Signal,dicomAcqTime,initialDirSize] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize)    
%% Main Neurofeedback Loop

acqTime = datetime;

%initialize to # of files in scanner_path


newDir = dir(scannerPath); % check files in scanner_path

if length(newDir) > initialDirSize % if there's a new file
    missedDicomNumber = length(newDir) - initialDirSize; % how many DICOMS were missed?
    initialDirSize = newDir; % reset # of files
    newDicoms = newDir(end + 1 - missedDicomNumber:end); % get the last # of missed dicoms
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % consider PARALLEL COMPUTING HERE.
    % this is where the QUESTPLUS function should go!
    for j = 1:length(newDicoms)
        thisDicomName = newDicoms(j).name;
        thisDicomPath = newDir(j).folder; % get path to file
        
        targetIm = extract_signal(thisDicomName,thisDicomPath,subjectPath);
        
        
        % run plot
        
        [v1Signal,dataTimepoint] = scanner_function(targetIm,roiIndex);
        
        %plot(dataTimepoint(iteration),v1Signal(iteration),'r.','MarkerSize',20);
        %hold on;
        
    end
    
    
end

end

