%% Display code from analysis
% Display data calculated from Q-tensor alignment:
% C_fil2ObjAlignmentQTensor.m
% Option to bin along contours of distance transform OR 3chan seg
% 2025-02-16 - Rémi Boros

% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 83';
filDataName = 'Concatenated_2D_Info.mat';
alignDataName = 'FilamentAlignment_AngleDataREDO.mat';
% seg3ChanDir = '<redacted original absolute path>';
seg3ChanDir = 'Session 83';
seg3Name = 'Time%06i_Probabilities_smoothbin.tif';

timeRange = 1:50;
timeSpace = 30/60;
binMode = 1;            % 0 means segmentation, 1 means binned dist contour

rBin = [-Inf 100 220 Inf];
% rBin = [-Inf -10 10 Inf];

colorMat = min(1,[[100,0,100];  [230, 30, 165];  [0 180 100] ]/255); % watermelon
% colorMat = [[100,0,100]; [150, 0, 150]; [230, 30, 165]; [1,210,105]; [0 180 100] ;[0 150 100]]/255; % watermelon

%% Load
load(fullfile(filDataDir,alignDataName))
load(fullfile(filDataDir,filDataName));
generalFilt = filterStruct.filter;

%% Plot order parameter over time for different delta r bins
timeVec = timeRange*timeSpace;
meanMat = zeros(numel(rBin)-1,numel(timeVec));
numMat = meanMat;       stdMat = meanMat;
maskLogic = maskedFils == 0;
legLabels = {'Interior','','Surface','','Bulk'};


for tInd = 1:numel(timeRange)
        
    currT = timeRange(tInd);
    tLogic = objInds == currT;

    for rInd = 1:(numel(rBin) - 1)
        if binMode == 1
            rEdge1 = rBin(rInd);    rEdge2 = rBin(rInd+1);
            rLogic = (filDeltaRs >= rEdge1) & (filDeltaRs < rEdge2);
        elseif binMode == 0 
            currSeg = tiffreadVolume(fullfile(seg3ChanDir,sprintf(seg3Name,currT)));
            rescaleSeg = imresize3(currSeg,ogImgSize);
            
        end
        
        currLogic = generalFilt & tLogic & rLogic & maskLogic;
        % currAligns = allAligns(currLogic);
        currAligns = tensorAligns(currLogic);
        meanMat(rInd,tInd) = mean(currAligns);
        stdMat(rInd,tInd) = std(currAligns);
        numMat(rInd,tInd) = sum(currLogic);
    end
end

figure
filtMatLogic = numMat > 100;
filtMat = meanMat; filtMat(~filtMatLogic) = NaN;
% plot(timeVec,filtMat','LineWidth',2)
for index = 1:size(meanMat,1)
    currColor = colorMat(index,:);
    plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./sqrt(numMat(index,:)),timeVec,currColor,0.4,'black');
    % plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./numMat(index,:),timeVec,currColor,0.4,'black');
end
xlabel('Time (min)')
ylabel('Average Alignment')
legend(legLabels)
set(gca,'FontSize',15)
box on
% ylim([0 1])
xlim([0 20])
% colororder(colorMat)

figure
plot(timeVec,numMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
legend(legLabels{1:2:6})
set(gca,'FontSize',15)
colororder(colorMat)

% %% Plot distribution of alignments over time
% subTimes = 1:5:50;
% for rInd = 1:(numel(rBin) - 1)
% 
%     rEdge1 = rBin(rInd);    rEdge2 = rBin(rInd+1);
%     rLogic = (filDeltaRs >= rEdge1) & (filDeltaRs < rEdge2);
% figure
%     for tInd = 1:numel(subTimes)
%         currT = subTimes(tInd);
%         tLogic = objInds == currT;
% 
%         currLogic = generalFilt & tLogic & rLogic & maskLogic;
%         % currAligns = allAligns(currLogic);
%         currAligns = tensorAligns(currLogic);
% % histogram(currAligns)
%     end
% end


