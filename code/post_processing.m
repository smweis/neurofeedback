

dicomVecs = zeros(length(dicomAcqTime),6);
dataVecs = zeros(length(dicomAcqTime),6);
formatIn = 'HHMMSS.FFF';

for i = 1:length(dicomAcqTime)
    dicomVecs(i,:) = datevec(dicomAcqTime(i),formatIn);
    dataVecs(i,:) = datevec(dataTimepoint(i));
end

zeroedDicomAcqTime = zeros(length(dicomAcqTime),1);
zeroedDataTime = zeros(length(dicomAcqTime),1);

for i = 1:length(dicomAcqTime)
    zeroedDicomAcqTime(i) = etime(dicomVecs(i,:), dicomVecs(1,:));
    zeroedDataTime(i) = etime(dataVecs(i,:), dataVecs(1,:));
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