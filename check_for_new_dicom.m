function check_for_new_dicom(subject)

    fsl_path = '/usr/local/fsl/';
    setenv('FSLDIR',fsl_path);
    setenv('FSLOUTPUTTYPE','NIFTI_GZ');
    curpath = getenv('PATH');
    setenv('PATH',sprintf('%s:%s',fullfile(fsl_path,'bin'),curpath));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FILL IN SCANNER PATH HERE!!!!%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %scanner_path = '/Volumes/rtexport/RTexport_Current/20180928.819931_TOME_3040_398782.18.09.28_08_11_04_DST_1.3.12.2.1107.5.2.43.66044/'; % FILL IN SCANNER PATH HERE
    scanner_path = '/Users/iron/Documents/neurofeedback/fake_dicoms/20180928.819931_TOME_3040_398782.18.09.28_08_11_04_DST_1.3.12.2.1107.5.2.43.66044';
    
    
    
    trigger = input('Waiting for trigger...','s');
    
    global subjectPath
    
    if strcmp(trigger,'t')
        initial_dir = dir(scanner_path);
        
        i=0;
        while i<10000000
            i = i+1;
            new_dir = dir(scanner_path); % check files in scanner_path
            if length(new_dir) > length(initial_dir) % if there's a new file
        
                reg_dicom_name = initial_dir(end).name;
                reg_dicom_path = initial_dir(end).folder;
                break
            else
                pause(0.01);
            end
        end
    end
    
    % get AP or PA automatically from the name of the run
    ap_check = strfind(reg_dicom_name,'AP');
    if ap_check
        ap_or_pa = 'AP';
    else
        ap_or_pa = 'PA';
    end
    
    new_dicom_name = strcat(subjectPath,'/new',ap_or_pa);
    
    % convert the first DICOM to a NIFTI
    dicm2nii(fullfile(reg_dicom_path,reg_dicom_name),new_dicom_name);
    old_dicom_dir = dir(strcat(new_dicom_name,'/*.nii.gz'));
    old_dicom_name = old_dicom_dir.name;
    old_dicom_folder = old_dicom_dir.folder;
    copyfile(fullfile(old_dicom_folder,old_dicom_name),strcat(subjectPath,'/new',ap_or_pa,'.nii.gz'));
    % grab path to the bash script for registering to the new DICOM
    pathToRegistrationScript = fullfile(pwd,'register_EPI_to_EPI.sh');
    % run script name as: register_EPI_to_EPI.sh AP 3040
    cmdStr = [pathToRegistrationScript ' ' ap_or_pa ' ' subject];
    system(cmdStr);
        
        


    % load the v1 ROI
    v1Index = load_roi(ap_or_pa);
        
    
    
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
            [acqTime(iteration),v1Signal(iteration),dataTimepoint(iteration)] = plot_at_scanner(new_dicom_name,new_dicom_path,v1Index);

            % plot the time point
            plot(dataTimepoint(iteration),v1Signal(iteration),'r.','MarkerSize',20);
            hold on;


            toc % end timer

            iteration = iteration + 1;

        end


        pause(0.01);
    end
end
