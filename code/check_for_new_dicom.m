function check_for_new_dicom(subject,which_run)

    fsl_path = '/usr/local/fsl/';
    setenv('FSLDIR',fsl_path);
    setenv('FSLOUTPUTTYPE','NIFTI_GZ');
    curpath = getenv('PATH');
    setenv('PATH',sprintf('%s:%s',fullfile(fsl_path,'bin'),curpath));

    %% Fill in Scanner Path

    %scanner_path = '/Volumes/rtexport/RTexport_Current/20181020.817774_KAS25_300034.18.10.20_13_29_14_DST_1.3.12.2.1107.5.2.43.66044/'; % FILL IN SCANNER PATH HERE
    
    scanner_path = '/Users/iron/Documents/neurofeedback/fake_dicoms/copy_into/';

    global subjectPath
    global first_trigger_time
    
    %% Check for trigger
    first_trigger_time = wait_for_trigger;
    
    %% Check for first DICOM Loop

    initial_dir = dir([scanner_path '*00001.dcm']); % count all the FIRST DICOMS in the directory
        
    i=0;
    while i<10000000000
        i = i+1;
        new_dir = dir([scanner_path '*00001.dcm']); % check files in scanner_path
        if length(new_dir) > length(initial_dir) % if there's a new FIRST DICOM
            
            reg_dicom_name = new_dir(end).name;
            reg_dicom_path = new_dir(end).folder;
            break
        else
            pause(0.01);
        end
    end

    %% Complete Registration to First DICOM

    reg_image_dir = strcat(subjectPath,'/run', which_run);

    % convert the first DICOM to a NIFTI
    dicm2nii(fullfile(reg_dicom_path,reg_dicom_name),reg_image_dir);
    old_dicom_dir = dir(strcat(reg_image_dir,'/*.nii.gz'));
    old_dicom_name = old_dicom_dir.name;
    old_dicom_folder = old_dicom_dir.folder;
    
        
    ap_check = strfind(old_dicom_name,'AP');
    if ap_check
        ap_or_pa = 'AP';
    else
        ap_or_pa = 'PA';
    end

    
    copyfile(fullfile(old_dicom_folder,old_dicom_name),strcat(reg_image_dir,'/new',ap_or_pa,'.nii.gz'));
    
    % grab path to the bash script for registering to the new DICOM
    pathToRegistrationScript = fullfile(pwd,'register_EPI_to_EPI.sh');
    
    % run registration script name as: register_EPI_to_EPI.sh AP TOME_3040
    cmdStr = [pathToRegistrationScript ' ' ap_or_pa ' ' subject];
    system(cmdStr);


    load(fullfile(reg_image_dir,'dcmHeaders.mat'),'h');
    subHName = fieldnames(h);
    
    global initialDicomAcqTime
    
    initialDicomAcqTime = str2double(h.(subHName{1}).AcquisitionTime);

    %% Main Neurofeedback Loop
    
    %%% Load the ROI HERE! 
    v1Index = load_roi(ap_or_pa);
    %%% Load the ROI ABOVE!
    
    

    global iteration
    global acqTime
    global v1Signal
    global dataTimepoint
    global dicomAcqTime


    %initialize to # of files in scanner_path
    initial_dir = dir(scanner_path);


    
    
    % Should build in TWO settings. One setting should allow you to get the
    % latest DICOM. The other setting should collect all DICOMs and process
    % them as fast as you can. 
    
    


    i=0;
    while i<10000000000
        i = i+1;
        new_dir = dir(scanner_path); % check files in scanner_path
        if length(new_dir) > length(initial_dir) % if there's a new file
            tic % start timer

            initial_dir = new_dir; % reset # of files


            reg_image_dir = new_dir(end).name; % get new name of file
            new_dicom_path = new_dir.folder; % get path to file


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % this is where the QUESTPLUS function should go!

            % run plot
            [acqTime(iteration),dicomAcqTime(iteration),v1Signal(iteration),dataTimepoint(iteration)] = plot_at_scanner(reg_image_dir,new_dicom_path,v1Index);

            plot(dataTimepoint(iteration),v1Signal(iteration),'r.','MarkerSize',20);
            hold on;

            % WE CAN CALCULATE LAG HERE! 
            %str2double(datestr(dataTimepoint(iteration),'HHMMSS.FFF')) - dicomAcqTime(iteration)

            toc % end timer

            iteration = iteration + 1;

        end


        pause(0.01);
    end
end
