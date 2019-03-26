subjectPath = '/Users/nfuser/Documents/rtQuest/TOME_3040_TEST';
for i = 1:23
    stims = [2,4,8,16,32,64];
    nextStim = stims(randi(6));
    fid = fopen(fullfile(subjectPath,'actualStimuli.txt'),'a+');
    fprintf(fid,'%d\n',nextStim);
    fclose(fid);
    pause(12);
end
