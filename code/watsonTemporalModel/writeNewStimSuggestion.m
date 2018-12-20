function writeNewStimSuggestion(newStimSuggestion,pathToNewStimTextFiles)
% Writes a newStimSuggestion (an integer) to a text file, (name of which is 
% specified in pathToNewStimTextFile. 

if ~isnumeric(newStimSuggestion)
    error('newStimSuggestion is an unsupported type');
end


nextStimNum = length(dir(pathToNewStimTextFiles));
nextStimFileName = horzcat('nextStimuli',num2str(nextStimNum),'.txt');
nextStimFullPath = fullfile(pathToNewStimTextFiles,nextStimFileName);
fid = fopen(nextStimFullPath,'w');
fprintf(fid,'%d',newStimSuggestion);
fclose(fid);

end
