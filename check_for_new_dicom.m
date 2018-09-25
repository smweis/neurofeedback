function check_for_new_dicom()

    path_to_watch = 'E:\neurofeedback_test\data\testdata\dicom_source'; % FILL IN SCANNER PATH HERE
    fileObj = System.IO.FileSystemWatcher(path_to_watch);
    fileObj.Filter = '*.dcm';
    fileObj.EnableRaisingEvents = true;
    addlistener(fileObj,'Created', @eventhandlerChanged);
    i=0;
    while i<10000000
        i = i+1;
        pause(0.01);
    end
end



function eventhandlerChanged(~,file)
tic % start timer

global iteration

iteration = iteration + 1;

nameStr = char(file.Name);
pathStr = char(file.FullPath);
[acqTime(iteration),v1Signal(iteration),dataTimepoint(iteration)] = plot_at_scanner(nameStr,pathStr);


plot(dataTimepoint,v1Signal,'r.','MarkerSize',20);
hold on;


toc % end timer


end