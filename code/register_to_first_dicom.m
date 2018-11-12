function [ap_or_pa,dir_length_after_registration] = register_to_first_dicom(subject,subjectPath,which_run,scannerPath,codePath)
%register_to_first_dicom, return whether this scan is AP or PA direction
%based on whether PA or AP is present in the NIFTI file name. 

    initial_dir = dir([scannerPath filesep '*00001.dcm']); % count all the FIRST DICOMS in the directory
    

    fprintf('Waiting for first DICOM...\n');
    while(1)
        
        new_dir = dir([scannerPath filesep '*00001.dcm']); % check files in scanner_path
        if length(new_dir) > length(initial_dir) % if there's a new FIRST DICOM
            reg_dicom_name = new_dir(end).name;
            reg_dicom_path = new_dir(end).folder;
            dir_length_after_registration = length(dir(scannerPath)); % Save this to initialize the check_for_new_dicoms function
            break
        else
            pause(0.01);
        end
    end
    
    fprintf('Performing registration on first DICOM\n');
    
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

    
    copyfile(fullfile(old_dicom_folder,old_dicom_name),strcat(subjectPath,'/new',ap_or_pa,'.nii.gz'));
    
    % grab path to the bash script for registering to the new DICOM
    pathToRegistrationScript = fullfile(codePath,'register_EPI_to_EPI.sh');
    
    % run registration script name as: register_EPI_to_EPI.sh AP TOME_3040
    cmdStr = [pathToRegistrationScript ' ' ap_or_pa ' ' subject];
    system(cmdStr);

    fprintf('Registration Complete. \n');

end

