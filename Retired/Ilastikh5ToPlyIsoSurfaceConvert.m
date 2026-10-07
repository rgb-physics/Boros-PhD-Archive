%% This script takes in individual meshes saved in probability .h5 files
% and generates .ply files based on a given cutoff value

% currDir = pwd;
% FilePath = '<redacted original absolute path>';
FilePath = 'Session 25, Exp 5';
SaveDir = fullfile(FilePath, 'Ply Files');
% cd(FilePath);
pause (.1)
FileNameFormat = 'bin2xy_t32_8bit_Probabilities.h5'; %The file name format
SaveNameFormat = 'bin2xy_t32_8bit_Probabilities.ply';
fileRange = 1;
channelNum = 2; cutoffVal = .7;
xSpace = 1; ySpace = 1; zSpace = 2;

%% Load first data point and instantiate x,y,z meshgrids
Data = h5read(fullfile(FilePath,sprintf(FileNameFormat,fileRange(1))),'/exported_data');
cData = squeeze(Data(channelNum,:,:,:));
[xSize,ySize,zSize] = size(cData);
% x = 1/xSpace:(1/xSpace):xSize; y = 1/ySpace:(1/ySpace):ySize; z = 1/zSpace:(1/zSpace):zSize;
x = 1:xSpace*xSize; y = 1:ySpace*ySize; z = 1:zSpace*zSize;
% x = 1:xSize; y = 1:ySize; z = 1:zSize;
[rowMat, colMat, depthMat] = meshgrid(y,x,z);

%% Save ply objects of generated isosurfaces
mkdir(SaveDir);
for index = fileRange
   
    %Load data
    fprintf('Current object... %i\n',index)
    Data = h5read(fullfile(FilePath,sprintf(FileNameFormat,index)),'/exported_data');
    cData = squeeze(Data(channelNum,:,:,:));
    cData = imresize3(cData, [xSpace*xSize, ySpace*ySize, zSpace*zSize]);
    s = isosurface(rowMat,colMat,depthMat,cData,cutoffVal);
    faces = s.faces; vertices = s.vertices;
    plywrite(fullfile(SaveDir,sprintf(SaveNameFormat,index)),faces,vertices)    
    
end

%% Make morphological kernel
[xx,yy,zz] = ndgrid(-5:5);
nhood = sqrt(xx.^2 + yy.^2 + zz.^2) <= 5.0;
