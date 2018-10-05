function check_for_new_dicom()


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FILL IN SCANNER PATH HERE!!!!%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    scanner_path = '/Volumes/rtexport/RTexport_Current/20180928.819931_TOME_3040_398782.18.09.28_08_11_04_DST_1.3.12.2.1107.5.2.43.66044/'; % FILL IN SCANNER PATH HERE
    
    
    
    global iteration
    global acqTime
    global v1Signal
    global dataTimepoint


    
    %initialize to # of files in scanner_path
    initial_dir = dir(scanner_path);

    i=0;
    while i<10000000
        i = i+1;
        new_dir = dir(scanner_path); % check files in scanner_path
        if length(new_dir) > length(initial_dir) % if there's a new file
            tic % start timer

            initial_dir = new_dir; % reset # of files


            new_dicom_name = new_dir(end).name; % get new name of file
            new_dicom_path = new_dir.folder; % get path to file
            
            % run plot
            [acqTime(iteration),v1Signal(iteration),dataTimepoint(iteration)] = plot_at_scanner(new_dicom_name,new_dicom_path);

            % plot the time point
            plot(dataTimepoint(iteration),v1Signal(iteration),'r.','MarkerSize',20);
            hold on;


            toc % end timer

            iteration = iteration + 1;

        end


        pause(0.01);
    end
end
