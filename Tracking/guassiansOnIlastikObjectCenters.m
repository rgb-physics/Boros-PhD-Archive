%%This script takes in a directory of tifs and h5 files and returns a set
%%of .ply files containing the contours of gaussians with sigmas defined by
%%the radii of each object centered at each object center, where object
%%info is stored in the .h5 files (output of object classification in
%%Ilastik)

%% data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 24, Exp 1';
saveDir = dataDir;
dataName = 'Time%0.6i.tif';
saveNameFormat = 'Frame 2 2D Background avg Channel %i.tif';

%Output from object classification
h5ObjInfo = 'Time%0.6i.h5';
chanNum = 1;
timeRange = 45;

%Define pixel size
pixelSize = 11*2/60;

%% Load data
firstObjName = sprintf(h5ObjInfo,timeRange(1));
firstTiffName = sprintf(dataName,timeRange(1));
objData = h5read(fullfile(dataDir,firstObjName),'/table');
firstTiff = tiffreadVolume(fullfile(dataDir, firstTiffName));

%% Iterate through all time points and define gaussian matrix masks

for currTime = 1:numel(timeRange)
    %Instantiate new mask
    maskMat = zeros(size(firstTiff));
    imgDims = size(firstTiff);           %In [rows, cols, depth]
    maskSize = [imgDims(2:-1:1), imgDims(3)];    %For meshgrid
    %Load current obj info
    currObjName = sprintf(h5ObjInfo,timeRange(1));
    currObjs = h5read(fullfile(dataDir,firstObjName),'/table');
    %Extract data
    objCenters = [objData.CenterOfTheObject_1,objData.CenterOfTheObject_0,objData.CenterOfTheObject_2];
    objRadii = [objData.RadiiOfTheObject_1, objData.RadiiOfTheObject_0, objData.RadiiOfTheObject_2];
    
    %Iterate through each point and generate matrix
    for currObj = 1:size(objCenters,1)

        maskMat = maskMat + generate3DGaussian(maskSize, objCenters(currObj,:), objRadii(currObj,:),1);

    end

end

%% Binarize as first guess
firstPass = imbinarize(maskMat);

%% Active contours
test = activecontour(tiffData, firstPass,200,'edge');