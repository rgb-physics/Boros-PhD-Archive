%%

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataName = 't%03i_illCorr8bit.tif';
selTimes = 20:200;
stepZ = 0.75;

%%

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));

    if tInd == 1
        
        meanInts = zeros(numel(selTimes),size(currTif,3));

    end
    meanInts(tInd,:) = mean(mean(currTif,1),2);

end

%% 
subTs = 1:6:60;
zRange = 10:175;
shftVal = 10;
% Define boundaries for recolor
colorTimeBnds = (min(subTs)-1):(max(subTs) + 2);    
% colorTimeBnds = 1:4:24;    
colorStr = 'BuPu3';
colorOffSet = 7;

% Prepare colormap 
colorLen = max(colorTimeBnds) - min(colorTimeBnds) + 1;
colorTimeBnds = fliplr(colorTimeBnds);  
% Reset color vector, if wanted
timeColorArray = othercolor(colorStr,colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);
figure
for tInd = 1:numel(subTs)

    currT = subTs(tInd);
    % hold on
    scatter(meanInts(currT,zRange)'+shftVal*(tInd-1),zRange*stepZ,32,'filled','MarkerFaceColor',timeColorArray(currT,:));
    hold on
    plot(meanInts(currT,zRange)'+shftVal*(tInd-1),zRange*stepZ,'black')
    % plot(meanInts(currT,zRange)'+shftVal*(tInd-1),zRange,'Color',timeColorArray(currT,:),'LineWidth',2)
    % hold on
    % plot(zRange,meanInts(currT,zRange)'+shftVal*(tInd-1),'black')
    % hold on
    % scatter(zRange,meanInts(currT,zRange)'+shftVal*(tInd-1),16,'filled','MarkerFaceColor',timeColorArray(currT,:));

    % plot(1:size(currTif,3),meanInts(tInd,:)./meanInts(1,:),'black')
    % hold on
    % scatter(1:size(currTif,3),meanInts(tInd,:)./meanInts(1,:),16,'filled','MarkerFaceColor',timeColorArray(currT,:));

end

box on





