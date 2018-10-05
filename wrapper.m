% Change path to where NIFTIs will be stored on Macbook
global niftiPath



niftiPath = '/Users/iron/Documents/neurofeedback/TOME_3040/niftis';
% initialize some global variables
global iteration
iteration = 1;

global acqTime
global v1Signal
global dataTimepoint

acqTime = repmat(datetime,10000,1);
dataTimepoint = repmat(datetime,10000,1);
v1Signal = repmat(10000,1);

% load the v1 ROI (which has already been processed in fsl)
load_roi

% initialize figure
figure;


% run the main script
check_for_new_dicom
