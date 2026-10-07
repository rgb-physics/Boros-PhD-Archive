%% Directories
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 32, Exp 2';
indDirs = dir(baseDir);
tifName = 'Time%06i_raw.tif';

timeRange = 1:5:120;

%%
bleachRates = zeros(numel(indDirs)-2, numel(timeRange));

%% x ranges

for index = 3:(numel(indDirs))

    currDir = fullfile(baseDir,indDirs(index).name);
    fprintf('Working on data set %i...\n', index - 2)
    bleachRates(index,:) = getTotIntOver3DTiffs(currDir, tifName, timeRange);
    
    
end

%% separating manually as wanted
set1 = [9 7 8 10 11];
set2 = [9 4 6 12 14];
set3 = [9 3 5 13 15];

figure
hold on
for index = 1:numel(set1)

    plot(timeRange, bleachRates(set1(index),:)','Color',[index/numel(set1) 0 (1 - index/numel(set1))],'LineWidth',5);

end
xlabel('Time (frame)')
ylabel('Total Ill.')
title('Along X')
set(gca,'FontSize',15)
legend('(50 50)','(200 50)','(350 50)','(500 50)','(650 50)')

figure
hold on
for index = 1:numel(set2)

    plot(timeRange,bleachRates(set2(index),:)','Color',[index/numel(set2) 0 (1 - index/numel(set2))],'LineWidth',5);

end
xlabel('Time (frame)')
ylabel('Total Ill.')
title('Along Y')
set(gca,'FontSize',15)
legend('(50 50)','(50 200)','(50 350)','(50 500)','(50 650)')

figure
hold on
for index = 1:numel(set3)

    plot(timeRange, bleachRates(set3(index),:)','Color',[index/numel(set3) 0 (1 - index/numel(set3))],'LineWidth',5);

end
xlabel('Time (frame)')
ylabel('Total Ill.')
title('Along Diagonal')
set(gca,'FontSize',15)
legend('(50 50)','(200 200)','(350 350)','(500 500)','(650 650)')

