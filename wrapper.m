% Change path to where NIFTIs will be stored on Macbook
global subjectPath

subject = input('Subject number?','s');
run = input('Which run?','s');

subjectPath = strcat('/Users/iron/Documents/neurofeedback/Current_Subject/',subject);



% initialize some global variables
global iteration
iteration = 1;

global acqTime
global v1Signal
global dataTimepoint
global dicomAcqTime
global first_trigger_time

acqTime = repmat(datetime,10000,1);
dataTimepoint = repmat(datetime,10000,1);
v1Signal = repmat(10000,1);
dicomAcqTime = repmat(10000,1);


% initialize figure
figure;


% run the main script
check_for_new_dicom(subject,run)
