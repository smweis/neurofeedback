function [subjectPath, scannerPath, codePath, scratchPath] = getPaths(subject)
%Get all relevant paths for experiment

scannerPath = getpref('neurofeedback','scannerBasePath');


subjectPath = getpref('neurofeedback', 'currentSubjectBasePath');
subjectPath = [subjectPath filesep subject];

scratchPath = getpref('neurofeedback', 'analysisScratchDir');

codePath = getpref('neurofeedback','projectRootDir');
codePath = [codePath filesep 'code'];

end

