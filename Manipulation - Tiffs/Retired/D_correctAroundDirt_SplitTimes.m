%% This script takes in an h5 file (2D) that has been used to detect dirt (output of object + pixel class)
% and uses the positions of detected dirt to interpolate data in place of
% the dirt

% FilePath = '<redacted original absolute path>';
FilePath = 'Session 25, Exp 5';
% DirtPath = '<redacted original absolute path>';
DirtPath = 'Session 25, Exp 5';
% SaveDir = '<redacted original absolute path>';
SaveDir = 'Session 25, Exp 5';

FileNameFormat = 'Time%06i_intCorrected.tif'; %The file name format
DirtName = 'Dirt Detection_Object Predictions.h5';
SaveNameFormat = 'Time%0.6i_NoDirt.tif';
fileRange = 1:120;
objChanNum = 1;
channelNum = 2; cutoffVal = .7;
xSpace = 1; ySpace = 1; zSpace = 1;

%% Save ply objects of generated isosurfaces
mkdir(SaveDir);
DirtData = squeeze(h5read(fullfile(DirtPath,DirtName),'/exported_data'))';
DirtData(DirtData~=objChanNum) = 0;
[xDirt, yDirt] = find(DirtData == objChanNum);
[xData, yData] = find(DirtData == 0);
% DirtData3D = extend2DTiffAlongZ(DirtData, 148, fullfile(DirtPath, "Trained Dirt Detection Stack.tif"));
% 
% DirtInds = find(DirtData3D == objChanNum);
% DataInds = find(DirtData3D == 0);

%% Load data and interpolate
%Iterate through time points
tic
for currTime = 1:numel(fileRange)
    %Load current time points
    currTiff = tiffreadVolume(fullfile(FilePath, sprintf(FileNameFormat, fileRange(currTime))));
    %Iterate through each 

%     [xData, yData, zData] = ind2sub(size(currTiff), DataInds);
%     [xDirt, yDirt, zDirt] = ind2sub(size(currTiff), DirtInds);
%     currData = double(currTiff(DataInds));
%     interpObj = scatteredInterpolant(xData, yData, zData, currData);
%     currTiff(currDirtInds) = interpObj(xDirt, yDirt, zDirt);
    
    for currZ = 1:size(currTiff,3)
        currDataInds = sub2ind(size(currTiff), xData, yData, currZ*ones(numel(xData),1));
        currDirtInds = sub2ind(size(currTiff), xDirt, yDirt, currZ*ones(numel(xDirt),1));
        currData = double(currTiff(currDataInds));
        interpObj = scatteredInterpolant(xData(:), yData(:), currData(:));
        currTiff(currDirtInds) = interpObj(xDirt, yDirt);
    end

    %Save tiff
    savePath = fullfile(SaveDir, sprintf(SaveNameFormat, currTime));
    save3DTiff(uint8(currTiff), savePath);

end
toc

