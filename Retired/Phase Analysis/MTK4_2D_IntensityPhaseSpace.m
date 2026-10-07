%% Basic ideas for phase field of [MT] vs. [k4] 
% The idea of this analysis is to extract dynamic trends in kinesin-4
% samples by visualizing a phase field of intensity v. intensity. One will
% then be able to back out regions of interest corresponding to places in
% the field and hopefully say something about k4-MT dynamics over time

%% Data Info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 12, Exp 4';
MTChanName = 'Composite_z%0.3i_c001.tif';
K4ChanName = 'Composite_z%0.3i_c002.tif';
timeRange = 1:240;
mtBounds = [50 1500]; k4Bounds = [25 800];
numBins = 100;
windowSize = 10;

% Define histogram edges
mtEdges = mtBounds(1):diff(mtBounds)/numBins:mtBounds(2);
k4Edges = k4Bounds(1):diff(k4Bounds)/numBins:k4Bounds(2);
[mtMesh, k4Mesh] = meshgrid(mtEdges(2:end), k4Edges(2:end));

%% Iterate through time
%Define and load first image pair
currMTName1 = sprintf(MTChanName, timeRange(1));
currK4Name1 = sprintf(K4ChanName, timeRange(1));
currMT1 = double(tiffreadVolume(fullfile(dataDir, currMTName1)));
currK41 = double(tiffreadVolume(fullfile(dataDir, currK4Name1)));
%Instantiate storage matrices
gradMasterMatMT = zeros(numBins,numBins,numel(timeRange)-1);
gradMasterMatK4 = gradMasterMatMT;
gradMasterMatMTNorm = gradMasterMatMT;
gradMasterMatK4Norm = gradMasterMatMT;

for currT = 2:numel(timeRange)
    
    %Assign pixel values to intensity bins
    [N1, ~, ~, mtBin, k4Bin] = histcounts2(currMT1, currK41, mtEdges, k4Edges);
    
    %Define new file name and load
    currMTName2 = sprintf(MTChanName, timeRange(currT));
    currK4Name2 = sprintf(K4ChanName, timeRange(currT));
    %Load Data
    currMT2 = double(tiffreadVolume(fullfile(dataDir, currMTName2)));
    currK42 = double(tiffreadVolume(fullfile(dataDir, currK4Name2)));

    %Get difference in intensities
    mtDiff = currMT2 - currMT1;
    k4Diff = currK42 - currK41;

    %Instantiate phase/quiver matrices
    mtGrad = zeros(numBins,numBins);
    k4Grad = mtGrad;
tic
    %Loop through intensity bins of both channels
    uniMTVals = unique(mtBin(:)); uniK4Vals = unique(k4Bin(:));
    for currMTVal = find(uniMTVals~=0)'
        for currK4Val = find(uniK4Vals~=0)'
            %Find indices of pixels in current bin of specific mt and k4 intensities.
            validInds = (mtBin == currMTVal) & (k4Bin == currK4Val);
            %Define index of current bin
            currInd = sub2ind([numBins,numBins], currK4Val, currMTVal);
            %Store means in respective matrices
            mtGrad(currInd) = mean(mtDiff(validInds));
            k4Grad(currInd) = mean(k4Diff(validInds));
        end
    end
toc
    %Plot quiver
%     colorMat = [normFactor(:)/max(normFactor(:)) (1-normFactor(:)/max(normFactor(:))) zeros(numel(normFactor(:)),1)];
    normFactor = sqrt(mtGrad.^2 + k4Grad.^2);
    normMT = mtGrad./normFactor; normK4 = k4Grad./normFactor;
% %     quiver(mtMesh(:),k4Mesh(:),mtGrad(:),k4Grad(:),1)
%     quiver(mtMesh(:),k4Mesh(:),normMT(:),normK4(:),.5)
%     xlim(mtBounds); ylim(k4Bounds);
%     pause(.5)
% %     quiver(mtMesh(:),k4Mesh(:),normMT(:),normK4(:),1,'Color',colorMat)

gradMasterMatMTNorm(:,:,currT-1) = mtGrad;
gradMasterMatK4Norm(:,:,currT-1) = k4Grad;

gradMasterMatMT(:,:,currT-1) = normMT;
gradMasterMatK4(:,:,currT-1) = normK4;

    %Reassign image2 to image1
    currMT1 = currMT2; currK41 = currK42;

end

%% Look at all data averaged
meanMasterMT = mean(gradMasterMatMT,3);
meanMasterK4 = mean(gradMasterMatK4,3);
quiver(mtMesh(:), k4Mesh(:), meanMasterMT(:), meanMasterK4(:), .5)
xlim(mtBounds); ylim(k4Bounds);

%% Rolling average
rollingMeanMT = zeros(size(gradMasterMatMT,1),size(gradMasterMatMT,2),size(gradMasterMatMT,3)-windowSize);
rollingMeanK4 = rollingMeanMT;
for currIt = 1:windowSize

    rollingMeanMT = rollingMeanMT + gradMasterMatMT(:,:,currIt:end-windowSize+currIt-1);
    rollingMeanK4 = rollingMeanK4 + gradMasterMatK4(:,:,currIt:end-windowSize+currIt-1);

end
rollingMeanMT = rollingMeanMT/windowSize;
rollingMeanK4 = rollingMeanK4/windowSize;

%% Display
currIMG = zeros(size(currMT1,1),size(currMT1,2),3);
for index = 1:10:size(gradMasterMatMT,3)-windowSize
    subplot(1,2,1)
    quiver(mtMesh, k4Mesh, rollingMeanMT(:,:,index), rollingMeanK4(:,:,index),1.4,...
        'Color',[index/(size(gradMasterMatMT,3)-windowSize) 0 (1-index/(size(gradMasterMatMT,3)-windowSize))])
    xlim(mtBounds); ylim(k4Bounds);
%     hold on
    subplot(1,2,2)
%     quiver(tempa, tempb, rollingMeanMT(:,:,index), rollingMeanK4(:,:,index),.8,...
%         'Color',[index/(size(gradMasterMatMT,3)-windowSize) 0 (1-index/(size(gradMasterMatMT,3)-windowSize))])
    
    xlim([1 100]); ylim([1 100]);
    currMTName = sprintf(MTChanName, timeRange(index));
    currK4Name = sprintf(K4ChanName, timeRange(index));
    currIMG(:,:,1) = double(tiffreadVolume(fullfile(dataDir, currMTName)));
    currIMG(:,:,3) = double(tiffreadVolume(fullfile(dataDir, currK4Name)));
    imagesc( currIMG(:,:,1))
    pause(1)

end
