function [subjectPath, scannerPath, codePath] = getPaths(subject)
%Get all relevant paths for experiment

scannerPath = getpref('neurofeedback','scannerBasePath');


subjectPath = getpref('neurofeedback', 'currentSubjectBasePath');
subjectPath = [subjectPath filesep subject];


codePath = getpref('neurofeedback','projectRootDir');
codePath = [codePath filesep 'code'];

end

