

dicomVecs = zeros(length(dicomAcqTime),6);
dataVecs = zeros(length(dicomAcqTime),6);
formatIn = 'HHMMSS.FFF';

for i = 1:length(dicomAcqTime)
    dicomVecs(i,:) = datevec(num2str(dicomAcqTime(i)),formatIn);
    dataVecs(i,:) = datevec(dataTimepoint(i));
end

zeroedDicomAcqTime = zeros(length(dicomAcqTime),1);
zeroedDataTime = zeros(length(dicomAcqTime),1);

for i = 1:length(dicomAcqTime)
    zeroedDicomAcqTime(i) = etime(dicomVecs(i,:), dicomVecs(1,:));
    zeroedDataTime(i) = etime(dataVecs(i,:), dataVecs(1,:));
end

fixedDicomVecs = dicomVecs;

for i = 1:length(dicomVecs)
    fixedDicomVecs(i,5) = fixedDicomVecs(i,5) + 4;
    fixedDicomVecs(i,2) = fixedDicomVecs(i,2) + 9;
    fixedDicomVecs(i,3) = fixedDicomVecs(i,3) + 19;
    fixedDicomVecs(i,6) = fixedDicomVecs(i,6) + 56;
    if fixedDicomVecs(i,6) > 60
        fixedDicomVecs(i,6) = fixedDicomVecs(i,6) - 60;
        fixedDicomVecs(i,5) = fixedDicomVecs(i,5) + 1;
    end
end

dataDicomTime = zeros(length(dicomAcqTime),1);

for i = 1:length(dicomAcqTime)
    dataDicomTime(i) = etime(dataVecs(i,:), fixedDicomVecs(1,:));
end

for i = 1:length(dataVecs)
    a(i) = etime(dataVecs(i,:),fixedDicomVecs(i,:));
end


TOMEdir = dir('/Users/iron/Documents/neurofeedback/Old_Subjects/TOME_3040/niftis/*.dcm');
TOMEdicomAcqTime = {};
for i = 1:length(TOMEdir)
    cd(TOMEdir(i).name);
    load('dcmHeaders.mat');
    fields = fieldnames(h);
    TOMEdicomAcqTime{i} = h.(fields{1}).AcquisitionTime;
    cd ..
end


TOMEdicomVecs = zeros(length(TOMEdicomAcqTime),6);
TOMEdataVecs = zeros(length(TOMEdicomAcqTime),6);
formatIn = 'HHMMSS.FFF';

for i = 1:length(TOMEdicomAcqTime)
    TOMEdicomVecs(i,:) = datevec(TOMEdicomAcqTime(i),formatIn);
    TOMEdataVecs(i,:) = datevec(dataTimepoint(i));
end

TOMEzeroedDicomAcqTime = zeros(length(TOMEdicomAcqTime),1);
TOMEzeroedDataTime = zeros(length(TOMEdicomAcqTime),1);

for i = 1:length(TOMEdicomAcqTime)
    TOMEzeroedDicomAcqTime(i) = etime(TOMEdicomVecs(i,:), TOMEdicomVecs(1,:));
    TOMEzeroedDataTime(i) = etime(TOMEdataVecs(i,:), TOMEdataVecs(1,:));
end