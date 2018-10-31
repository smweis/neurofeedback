function [acqTime,dataTimepoint,v1Signal,dicomAcqTime] = check_for_new_dicom(subjectPath,scannerPath,roiIndex,initialDirSize)    
    %% Main Neurofeedback Loop

    iteration = 1;
    acqTime = repmat(datetime,10000,1);
    dataTimepoint = repmat(datetime,10000,1);
    v1Signal = repmat(10000,1);
    dicomAcqTime = repmat(10000,1);

    
    %initialize to # of files in scanner_path
    initialDir = dir(scannerPath);

    i=0;
    while i<10000000000
        i = i+1;
        newDir = dir(scannerPath); % check files in scanner_path
             
        if length(newDir) > length(initialDir) % if there's a new file
            missedDicomNumber = length(newDir) - length(initialDir); % how many DICOMS were missed?
            initialDir = newDir; % reset # of files
            newDicoms = newDir(end-missedDicomNumber:end); % get the last # of missed dicoms
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % consider PARALLEL COMPUTING HERE. ALSO, NEED TO FIX
            % PLOT_FOR_SCANNER TO JUST BE A GENERIC FUNCTION 
            % this is where the QUESTPLUS function should go!
            for j = 1:length(newDicoms)
                thisDicomName = newDicoms(j).name;
                thisDicomPath = newDir(j).folder; % get path to file


                % run plot
                
                [acqTime(iteration),dicomAcqTime(iteration),v1Signal(iteration),dataTimepoint(iteration)] = plot_at_scanner(thisDicomName,thisDicomPath,roiIndex,subjectPath);

                plot(dataTimepoint(iteration),v1Signal(iteration),'r.','MarkerSize',20);
                hold on;

            end
            
            iteration = iteration + 1;

        end


        pause(0.01);
    end
end
