%% This script plots data calculated in blobVolFractFromh5.m
%2023/10/26

%% Data dir
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 84';
saveDirs = {''};
saveNames = {'VolumeFracs_Kif4a.mat'};
deltaT = 30;

%% Load and concatenate data sets from 2chan (PASS ONE)
allVols2 = []; allTimes2 = [];
for index = 1:numel(saveDirs)
    load(fullfile(baseDir,saveDirs{index},saveNames{index}));
    allVols2 = [allVols2 allVols];
    allTimes2 = [allTimes2 timeRange];
end
scaledTimes = allTimes2*deltaT;
timeRange = scaledTimes;

%% Scatter the two
figure
hold on
scatter(scaledTimes,allVols2/totalPix,'filled');
scatter(scaledTimes,(1-allVols2/totalPix),'filled');
plot([12 12]*30,[0 1],'b')
ylim([0 1]);
legend('Blob Volume', 'Background Volume')
xlabel('Time (frame)')
ylabel('Normalized volume Fraction')
title('Normalized Volume Fraction in Two Regions Over Time')
set(gca,'FontSize',15);

%% Plot intensity in regions, density, and volumes
% index = 1;
% load(fullfile(baseDir,saveDirs{index},saveNames{index}));
figure
hold on
scatter(timeRange,allInts(1,:)./totalInts,30,'filled','MarkerFaceColor',[20 120 240]/255)
% scatter(timeRange,allInts(2,:)./sum(allInts,1),'filled')
% scatter(timeRange,allInts(3,:)./sum(allInts,1),'filled')
% scatter(timeRange,sum(allInts,1),'filled')
% legend('Intensity On Smectics', 'Intensity Outside Smectic', 'Intensity Within Smectic')
xlabel('Time (minutes)')
ylabel('Normalized Intensity Fraction')
% title('Normalized Intensity Fraction in Three Regions Over Time')
set(gca,'FontSize',15);
box on

%% 
figure
hold on
scatter(timeRange,allVols(1,:)./totalPix,'filled','MarkerFaceColor',[70 70 80]/255)
% scatter(timeRange,allVols(1,:)./totalPix,'filled','MarkerFaceColor',[20 120 240]/255)
% scatter(timeRange,allVols(2,:)./totalPix,'filled','r')
% scatter(timeRange,allVols(3,:)./totalPix,'filled','o')
% scatter(timeRange,sum(allInts,1),'filled')
% legend('Volume On Smectics', 'Volume Outside Smectic', 'Volume Within Smectic')
xlabel('Time (minutes)')
ylabel('Normalized Volume Fraction')
% title('Normalized Volume Fraction in Three Regions Over Time')
set(gca,'FontSize',15);
box on

%% Load and concatenate data sets from 3chan (PASS TWO)
allVols3 = []; allTimes3 = [];  totVols3 = []; allInts3 = []; totInts3 = [];
for index = 1:numel(saveDirs)
    load(fullfile(baseDir,saveDirs{index},saveNames{index}));
    allVols3 = [allVols3 allVols];
    allInts3 = [allInts3 allInts];
    % totInts3 = [totInts3 totalInts];
    allTimes3 = [allTimes3 timeRange];
    totVols3 = [totVols3 repmat(totalPix,[1 numel(timeRange)])];
end


%% Scatter the three
figure
hold on
scatter(allTimes3*deltaT,allInts3(1,:)./totInts3,'filled')
scatter(allTimes3*deltaT,allInts3(2,:)./totInts3,'filled')
scatter(allTimes3*deltaT,allInts3(3,:)./totInts3,'filled')
% scatter(allTimes3*deltaT,1-allInts3(1,:)./totInts3,'filled')
plot([21 21]*deltaT,[0 1],'b')
plot([49 49]*deltaT,[0 1],'b')
legend('Intensity on smectic', 'Intensity outside smectic', 'Intensity inside smectic')
% legend('Blob Volume', 'Background Volume','Volume On Smectics', 'Volume Outside Smectic', 'Volume Within Smectic')
xlabel('Time (minutes)')
ylabel('Normalized Intensity Fraction')
title('Normalized Intensity Fraction in Two Regions Over Time')
set(gca,'FontSize',15);
ylim([0 1])

%% Scatter the three
figure
hold on
scatter(allTimes3*deltaT,allVols3(1,:)./totVols3,'filled')
scatter(allTimes3*deltaT,(allVols3(2,:)+allVols3(3,:))./totVols3,'filled')
% scatter(allTimes3*deltaT,allVols3(2,:)./totVols3,'filled')
% scatter(allTimes3*deltaT,allVols3(3,:)./totVols3,'filled')
% scatter(allTimes3*deltaT,1-allVols3(1,:)./totVols3,'filled')
% plot([21 21]*deltaT,[0 1],'b')
% plot([49 49]*deltaT,[0 1],'b')
legend('Background volume', 'Total blob volume')
% legend('Volume on smectic', 'Volume outside smectic', 'Volume inside smectic')
xlabel('Time (seconds)')
ylabel('Normalized Volume Fraction')
title('Normalized Volume Fraction in Two Regions Over Time')
set(gca,'FontSize',20);
ylim([0 1])
box on

%% Scatter the three
totInts3 = sum(allInts3,1);
figure
hold on
scatter(allTimes3*deltaT,(allInts3(1,:)./totInts3)./(allVols3(1,:)./totVols3),'filled')
% scatter(allTimes3*deltaT,(allInts3(2,:)./totInts3)./(allVols3(2,:)./totVols3),'filled')
% scatter(allTimes3*deltaT,(allInts3(3,:)./totInts3)./(allVols3(3,:)./totVols3),'filled')
scatter(allTimes3*deltaT,((allInts3(3,:)+allInts3(2,:))./totInts3)./((allVols3(3,:)+allVols3(2,:))./totVols3),'filled')
% scatter(allTimes3*deltaT,(1-allInts3(1,:)./totInts3)./(1-allVols3(1,:)./totVols3),'filled')
% plot([21 21]*deltaT,[0.8 1.4],'b')
% plot([49 49]*deltaT,[0.8 1.4],'b')
% legend('Density on smectic', 'Density outside smectic', 'Density inside smectic')
legend('Background Density','Mean Blob Density')
xlabel('Time (seconds)')
ylabel('Normalized Density Fraction')
title('Normalized Density Over Time')
set(gca,'FontSize',20);
% ylim([0.8 1.4])
xlim([0 3500])
plot([0 3500],[1 1],'--')


%% Plot intensity in regions, density, and volumes
index = 1;
load(fullfile(baseDir,saveDirs{index},saveNames{index}));
timeRange = timeRange*deltaT;
figure
hold on
scatter(timeRange,allInts(1,:)./sum(allInts,1),'filled')
scatter(timeRange,allInts(2,:)./sum(allInts,1),'filled')
scatter(timeRange,allInts(3,:)./sum(allInts,1),'filled')
% scatter(timeRange,sum(allInts,1),'filled')
legend('Intensity On Smectics', 'Intensity Outside Smectic', 'Intensity Within Smectic')
xlabel('Time (minutes)')
ylabel('Normalized Intensity Fraction')
title('Normalized Intensity Fraction in Three Regions Over Time')
set(gca,'FontSize',15);

figure
hold on
scatter(timeRange,allVols(1,:)./totalPix,'filled','b')
scatter(timeRange,allVols(2,:)./totalPix,'filled','r')
scatter(timeRange,allVols(3,:)./totalPix,'filled','o')
% scatter(timeRange,sum(allInts,1),'filled')
legend('Volume On Smectics', 'Volume Outside Smectic', 'Volume Within Smectic')
xlabel('Time (minutes)')
ylabel('Normalized Volume Fraction')
title('Normalized Volume Fraction in Three Regions Over Time')
set(gca,'FontSize',15);

%% Same plot: ints and volumes
figure
hold on
scatter(timeRange,allInts(1,:)./sum(allInts,1),'filled','MarkerFaceColor',[194, 25, 10]/255,'MarkerEdgeColor','none')
scatter(timeRange,allInts(2,:)./sum(allInts,1),'filled','MarkerFaceColor',[232, 51, 35]/255,'MarkerEdgeColor','none')
scatter(timeRange,allInts(3,:)./sum(allInts,1),'filled','MarkerFaceColor',[250, 89, 75]/255,'MarkerEdgeColor','none')
scatter(timeRange,allVols(1,:)./totalPix,'filled','MarkerFaceColor',[7, 20, 168]/255,'MarkerEdgeColor','none')
scatter(timeRange,allVols(2,:)./totalPix,'filled','MarkerFaceColor',[24, 42, 242]/255,'MarkerEdgeColor','none')
scatter(timeRange,allVols(3,:)./totalPix,'filled','MarkerFaceColor',[125, 135, 245]/255,'MarkerEdgeColor','none')
legend('Int On Smectic', 'Int Out Smectic', 'Int In Smectic', 'Vol On Smectic', 'Vol Out Smectic', 'Vol In Smectic')
xlabel('Time (minutes)')
ylabel('Normalized Fractions')
title('Normalized Vol/Int Fractions in Three Regions Over Time')
set(gca,'FontSize',15);

%% Densities over time
figure
hold on
scatter(timeRange,allInts(1,:)./allVols(1,:)*totalPix./sum(allInts,1),'filled')
scatter(timeRange,allInts(2,:)./allVols(2,:)*totalPix./sum(allInts,1),'filled')
scatter(timeRange,allInts(3,:)./allVols(3,:)*totalPix./sum(allInts,1),'filled')
legend('Density On Smectics', 'Density Outside Smectic', 'Density Within Smectic')
xlabel('Time (minutes)')
ylabel('Normalized Density')
title('Normalized Density Fractions in Three Regions Over Time')
set(gca,'FontSize',15);

%% Total intensity over time
index = 1;
load(fullfile(baseDir,saveDirs{index},saveNames{index}));
figure
hold on
scatter(timeRange,sum(allInts,1),'filled');
xlabel('Time (frame)')
ylabel('Total intensity')
title('Total intensity over time')
set(gca,'FontSize',15);



