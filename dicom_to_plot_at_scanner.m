% This is the folder at the scanner that we can see dicoms in.
sourcePath = 'F:\dicom_source';

% This is the folder on Geoff's computer we want to save the dicom.
dicomPath = 'E:\neurofeedback_test\data\testdata\dicom_target\';
%cd(dicomPath);

niftiPath = 'E:\neurofeedback_test\data\testdata\niftis\';


% This is where you will load the Nifti file that is V1_TO_new[PA,AP].nii
% roiPath = PATH_TO_NIFTI
% roiNifti = load_untouch_nii(roiPath);
% v1Index = roiNifti.img;
% v1Index = logical(v1Index);



v1Index = zeros(96,96,80);
v1Index(45:55,45:55,45:55) = 1;
v1Index = logical(v1Index);




%this is wrapped in a for loop, closing....how?

% Option 1 is to plot an animated line:
% h = animatedline;

% Option 2 is to plot dots with datetimes:
figure;

testLength = 9;

v1Signal = zeros(1,testLength);
dataTimepoint = repmat(datetime,1,testLength);

acquisitionTimepoint = repmat(datetime,1,testLength);

for i = 1:testLength
    
    tic %start timer from here
    acquisitionTimepoint(i) = datetime; %save timepoint
    
    
    % Step 1. Copy DICOM from scanner computer to local computer. (Maybe not
    % necessary if we can just read directly)?
    
    sourceFileName = strcat('001_000004_00000',num2str(i),'.dcm');
    targetFileName = strcat('dicom',num2str(i),'.dcm');
    sourceFile = fullfile(sourcePath,sourceFileName);
    targetDicom = fullfile(dicomPath,targetFileName);
    copyfile(sourceFile,targetDicom);

    
    % Step 2. Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
    dicm2nii(targetDicom,niftiPath,0);
    targetNifti = load_untouch_nii(fullfile(niftiPath,'BOLD_RUN1.nii'));
    targetIm = targetNifti.img;

    
    % Step 3. Compute mean from v1 ROI, then plot it against a timestamp
    v1Signal(i) = mean(targetIm(v1Index));
    dataTimepoint(i) = datetime;
    
    % Option 1
    %addpoints(h,i,v1Signal(i))
    %drawnow

    
    % Option 2
    plot(dataTimepoint(i),v1Signal(i),'r.','MarkerSize',20);
    hold on;

    toc % end timer
    
end
