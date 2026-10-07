%% Takes in object struct, returns vols/radii and number over time
% ccDir = 'Session 87, Exp 5';
% ccDir = '<redacted original absolute path>';
ccDir = 'Session 84';
structName = 'storageStruct.mat';

selectTimes = 1:120;
segMatSize = [284 284 99];
ogImgSize = [775 775 141];
pixSize = [2*11/60 2*11/60 0.7];
pixSize = ogImgSize./segMatSize.*pixSize;
timeStep = 30;
binnedVols = 0:60:2000;

% Color map info
timeColorVec = [1 0.5 0.5; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
timeColorStamps = [1 8 24 70 100 270];
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

%% Load storage structure
load(fullfile(ccDir,structName));

%% Over time - all vols
figure
avgVols = zeros(numel(selectTimes),1);
medianVols = avgVols;
volFracSeg = avgVols;
stdVols = avgVols;
avgRadii = avgVols;
stdRadii = avgVols;
numObjs = structFieldSizes(storeStruct,'Volume');
numObjs = numObjs(selectTimes);
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currVols = (storeStruct(currT).Volume)*prod(pixSize);
    % currAxes = storeStruct(currT).PrincipalAxisLength.*pixSize;
    avgVols(tInd) = mean(currVols);
    medianVols(tInd) = median(currVols);
    stdVols(tInd) = std(currVols);
    volFracSeg(tInd) = sum(currVols,'all')/prod(segMatSize);
    avgRadii(tInd) = mean( (currVols).^(1/3) );
    stdRadii(tInd) = std((currVols*prod(pixSize)).^(1/3));
    [a,b,c] = histcounts(currVols,binnedVols);
    % loglog(b(1:end-1),a/numObjs(tInd));
    plot(b(1:end-1),a+tInd*200,'LineWidth',2);
    % histogram(currVols,binnedVols);
    hold on
end
volErrs = stdVols./sqrt(numObjs');
radErrs = stdRadii./sqrt(numObjs');
colororder(timeColorArray(selectTimes,:))
cbh = colorbar;
colormap(timeColorArray(selectTimes,:));
cbh.Ticks = (selectTimes - selectTimes(1))/(selectTimes(end)- selectTimes(1)) ; %Create 8 ticks from zero to 1
tickLabelCell = cell(numel(selectTimes),1);
tickLabelCell{1} = selectTimes(1)*timeStep;    
tickLabelCell{end} = selectTimes(end)*timeStep; 
cbh.TickLabels = tickLabelCell;
xlabel('Volume (um^3)')
ylabel('Count')

%% Over time - filtered vols
avgVolsF = avgVols;
stdVolsF = avgVols;
volFracSegF = avgVols;
avgRadiiF = avgVols;
stdRadiiF = avgVols;
numObjsF = avgVols;
meanLensF = avgVols;    stdLensF = avgVols;
meanSphF = avgVols;     stdSphF = avgVolsF;
% Removed objects
avgVolsR = avgVols;
stdVolsR = avgVols;
volFracSegR = avgVols;
avgRadiiR = avgVols;
stdRadiiR = avgVols;
numObjsR = avgVols;

for tInd = 1:numel(selectTimes)

    currVols = (storeStruct(tInd).Volume)*prod(pixSize);
    % currAxes = storeStruct(tInd).PrincipalAxisLength;
    % currLens = sqrt(sum((currAxes/2).^2,2)).*sqrt(sum(pixSize.^2))/2;
    % currSpherocity = sqrt( diff(currAxes(:,1:2)').^2 + diff(currAxes(:,2:3)').^2)'./currAxes(:,2);

    filtVolsLogic = currVols > volErrs(tInd)/exp(4);
    filtVols = currVols(filtVolsLogic);
    % filtAxes = currAxes(filtVolsLogic,:);
    % filtLens = currLens(filtVolsLogic);
    % filtSpherocity = currSpherocity(filtVolsLogic);

    numObjsF(tInd) = sum(filtVolsLogic);
    avgVolsF(tInd) = mean(filtVols);
    stdVolsF(tInd) = std(filtVols);
    avgRadiiF(tInd) = mean(filtVols.^(1/3));
    stdRadiiF(tInd) = std(filtVols.^(1/3));
    % meanLensF(tInd) = mean(filtLens);   stdLensF(tInd) = std(filtLens);
    % meanSphF(tInd) = mean(filtSpherocity);   stdSphF(tInd) = std(filtSpherocity);

    numObjsR(tInd) = sum(~filtVolsLogic);
    avgVolsR(tInd) = mean(currVols(~filtVolsLogic));
    stdVolsR(tInd) = std(currVols(~filtVolsLogic));
    avgRadiiR(tInd) = mean(currVols(~filtVolsLogic).^(1/3));
    stdRadiiR(tInd) = std(currVols(~filtVolsLogic).^(1/3));

end

volErrsF = stdVolsF./sqrt(numObjsF');
radErrsF = stdRadiiF./sqrt(numObjsF');
lensErrsF = meanLensF./sqrt(numObjsF');
sphErrsF = meanSphF./sqrt(numObjsF');
volErrsR = stdVolsR./sqrt(numObjsR');
radErrsR = stdRadiiR./sqrt(numObjsR');

%% Plot a field
% selField = avgRadiiF;    selErr = radErrsF;
% selField = meanLensF;    selErr = lensErrsF;
selField = avgVolsF;    selErr = volErrsF;
% selField = meanSphF;    selErr = sphErrsF;
earlyTimes = 1:12;
laterTimes = 12:max(selectTimes);
figure
timeVec = selectTimes*timeStep;
errorbar(timeVec(earlyTimes),selField(earlyTimes), selErr(earlyTimes), ...
    'MarkerSize', 10,'Marker','pentagram','MarkerEdgeColor','Black')
hold on
errorbar(timeVec(laterTimes),selField(laterTimes), selErr(laterTimes), ...
    'MarkerSize', 10,'Marker','pentagram','MarkerFaceColor','Black')
% loglog((timeVec(earlyTimes)),(avgVolsF(earlyTimes)),'pentagram')
% hold on
% loglog((timeVec(laterTimes)),(avgVolsF(laterTimes)),'pentagram')
% scatter(log(timeVec(earlyTimes)),log(avgVolsF(earlyTimes)),75,'pentagram','MarkerEdgeColor','Black')
% hold on
% scatter(log(timeVec(laterTimes)),log(avgVolsF(laterTimes)),75,'filled','pentagram','MarkerFaceColor','Black')
xlabel('Time (sec)')
set(gca,'FontSize',15)
ylabel('Object Volumes')
box on



%% Plot num objs
earlyTimes = 1:12;
laterTimes = 12:max(selectTimes);
% figure
timeVec = selectTimes*timeStep;
% scatter(timeVec(earlyTimes),numObjs(earlyTimes),75,'diamond','MarkerEdgeColor','Blue')
% hold on
% scatter(timeVec(laterTimes),numObjs(laterTimes),75,'filled','diamond','MarkerFaceColor','Blue')
% scatter(timeVec(earlyTimes),numObjsF(earlyTimes),75,'diamond','MarkerEdgeColor','Red')
% scatter(timeVec(laterTimes),numObjsF(laterTimes),75,'filled','diamond','MarkerFaceColor','Red')
scatter(timeVec(earlyTimes),numObjs(earlyTimes),40,'square','MarkerEdgeColor','black')
hold on
scatter(timeVec(laterTimes),numObjs(laterTimes),40,'filled','square','MarkerFaceColor','black')
xlabel('Time (sec)')
set(gca,'FontSize',15)
ylabel('Number of Objects')
box on

%% Plot vols
earlyTimes = 1:12;
laterTimes = 12:max(selectTimes);
figure
timeVec = selectTimes*timeStep;
errorbar(timeVec(earlyTimes),avgVolsF(earlyTimes), volErrsF(earlyTimes), ...
    'MarkerSize', 10,'Marker','pentagram','MarkerEdgeColor','Black')
hold on
errorbar(timeVec(laterTimes),avgVolsF(laterTimes), volErrsF(laterTimes), ...
    'MarkerSize', 10,'Marker','pentagram','MarkerFaceColor','Black')
% scatter(log(timeVec(earlyTimes)),log(avgVolsF(earlyTimes)),75,'pentagram','MarkerEdgeColor','Black')
% hold on
% scatter(log(timeVec(laterTimes)),log(avgVolsF(laterTimes)),75,'filled','pentagram','MarkerFaceColor','Black')
xlabel('Time (sec)')
set(gca,'FontSize',15)
ylabel('Object Volumes')
box on

%% Plot radii
earlyTimes = 1:12;
laterTimes = 13:max(selectTimes);
figure
timeVec = selectTimes*timeStep;
errorbar(timeVec(earlyTimes),avgRadiiF(earlyTimes), radErrs(earlyTimes), ...
    'MarkerSize', 10,'Marker','pentagram','MarkerEdgeColor','Black')
hold on
errorbar(timeVec(laterTimes),avgRadiiF(laterTimes), radErrs(laterTimes), ...
    'MarkerSize', 10,'Marker','pentagram','MarkerFaceColor','Black')
% scatter(timeVec(earlyTimes),movmean(avgVols(earlyTimes),rollAvgWin),75,'pentagram','MarkerEdgeColor','Black')
% hold on
% scatter(timeVec(laterTimes),movmean(avgVols(laterTimes),rollAvgWin),75,'filled','pentagram','MarkerFaceColor','Black')
xlabel('Time (sec)')
set(gca,'FontSize',15)
ylabel('Object Radii')
box on

%% Plot special
timeColorVec = [1 0.5 0.5; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
timeColorStamps = [1 19 25 39 110 270];
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

rollAvgWin = 5;
firstPart = 1:2:25;
secondPart = 26:2:125;


figure
hold on
timeVec = selectTimes*timeStep;

yyaxis left
plot(timeVec,movmean(numObjs,rollAvgWin),'k')
yyaxis right
plot(timeVec,avgVols.^(1/3),'k')

for tInd = firstPart
    yyaxis left
    scatter(timeVec(tInd),numObjs(tInd),30,'o','MarkerFaceColor',timeColorArray(tInd,:),'MarkerEdgeColor','none')
    ylabel('Number of Segmented Objects')
    
    yyaxis right
    scatter(timeVec(tInd),avgVols(tInd).^(1/3),50,'d','MarkerFaceColor',timeColorArray(tInd,:),'MarkerEdgeColor','none','MarkerFaceAlpha',.5)
    % scatter(timeVec(firstPart),avgVols(firstPart).^(1/3),10,'d')
    hold on
    % plot(timeVec,medianVols.^(1/3))
    ylabel('Object Radii (um)')
    xlabel('Time (sec)')
    set(gca,'FontSize',15)
end

for tInd = secondPart
    yyaxis left
    scatter(timeVec(tInd),numObjs(tInd),30,'o','MarkerFaceColor',timeColorArray(tInd,:),'MarkerEdgeColor','none')
    ylabel('Number of Segmented Objects')
    
    yyaxis right
    scatter(timeVec(tInd),avgVols(tInd).^(1/3),50,'d','MarkerFaceColor',timeColorArray(tInd,:),'MarkerEdgeColor','none','MarkerFaceAlpha',.5)
    % scatter(timeVec(firstPart),avgVols(firstPart).^(1/3),10,'d')
    hold on
    % plot(timeVec,medianVols.^(1/3))
    ylabel('Object Radii (um)')
    xlabel('Time (sec)')
    set(gca,'FontSize',15)
end

%% Plot total segmented volume fraction over time
figure
plot(timeVec,volFracSeg);
ylabel('Volume Fraction Segmented Objects')
xlabel('Time (s)')
set(gca,'FontSize',15)

%% Plot
rollAvgWin = 1;
figure
timeVec = selectTimes*timeStep;
yyaxis left
plot(timeVec,movmean(numObjs,rollAvgWin))
ylabel('Number of Segmented Objects')

yyaxis right
% plot(timeVec,avgVols.^(1/3))
% hold on
% plot(timeVec,medianVols.^(1/3))
% plot(timeVec,volErrs.^(1))
loglog(timeVec,avgVols.^(1))
hold on
loglog(timeVec,medianVols.^(1))
ylabel('Object Radii (um)')
xlabel('Time (sec)')
set(gca,'FontSize',15)