%% Takes in binarized blobs and intensity data from 2 channels
% Returns intensities sampled in blob locations; rescale if desired
% 2025-06-17 - Rémi Boros

% blobDir = '<redacted original absolute path>';
blobDir = 'Session 81, Exp 3';
blobName = 'carved_t%03i_illBleachCorr16bit_560.tif';
% int1Dir = '<redacted original absolute path>';
int1Dir = 'Session 81, Exp 3';
% int2Dir ='<redacted original absolute path>';
int2Dir ='Session 81, Exp 3';
int1Name = 't%03i_illBleachCorr16bit_560.tif';
int2Name = 't%03i_illBleachCorr16bit_488.tif';

blobThresh = 7000;
gKern = 5;

selTimes = 240;
renormMax = 65535;
voxSize = [.3667 .3667 1.5];
rsSize = [1 1 4.1];
% Use LOG to identify motor-rich core
logRSScale = voxSize/voxSize(3)*2;
logKern = 3;
logThresh = 70;

%% load, thresh, rescale, save

for tInd = 1:numel(selTimes)
    
    currT = selTimes(tInd);
       % Load data
    currBlobs = double(tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT))));
    currInts1 = double(tiffreadVolume(fullfile(int1Dir,sprintf(int1Name,currT))));
    currInts2 = double(tiffreadVolume(fullfile(int2Dir,sprintf(int2Name,currT))));

    % get motor core
    downInts2 = imresize3(currInts2,size(currInts2).*logRSScale);
    logInts2 = -LOG(downInts2,logKern);
    motorLogic = imbinarize(logInts2,logThresh);

    % threshold blobs for microtubules
    bwMask = imbinarize(currBlobs,blobThresh);
    mtLogic = imresize3(bwMask,size(currInts2),'nearest');

    % Remove motor logic from mt logic
    

    % subsample intensities
    matSamp1 = consMatLnB(currInts1,mtLogic);
    matSamp2 = consMatLnB(currInts2,mtLogic);

    % Resize to desired
    matSamp1RS = imresize3(matSamp1,size(matSamp1).*rsSize);
    matSamp2RS = imresize3(matSamp2,size(matSamp2).*rsSize);

    % Rescale voxels
    test1 = consMatLnB(matSamp1RS,matSamp1RS>matSamp2RS);
    test2 = consMatLnB(matSamp2RS,matSamp2RS>=matSamp1RS);
    outMat1 = test1/2;
    outMat2 = test2/2 + renormMax/2;
    fullChan = zeros([size(outMat2) 3]);
    fullChan(:,:,:,1) = test1;
    
    fullChan(:,:,:,2) = test2;
    
    % outMat1 = matSamp1RS/2;
    % outMat2 = matSamp2RS/2 + renormMax/2;

    % Save
    % save3DTiff(uint16(outMat1 + outMat2))

end


