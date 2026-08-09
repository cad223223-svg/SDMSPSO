function plot_uav_results(inputDirectory,outputDirectory)
%PLOT_UAV_RESULTS Plot the best stored SDMSPSO path for each paper scenario.
cfg = paper_settings();
if nargin < 1 || isempty(inputDirectory), inputDirectory = fullfile(pwd,'results','uav'); end
if nargin < 2 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','figures'); end
if ~exist(outputDirectory,'dir'), mkdir(outputDirectory); end
figure('Color','w','Position',[100,100,1800,520]);
layout = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for scenario = cfg.uavScenarios
    files = dir(fullfile(inputDirectory,sprintf('scenario_%d',scenario),'run_*.mat'));
    if isempty(files), error('No result files found for scenario %d.',scenario); end
    best = inf; decision = [];
    for i = 1:numel(files)
        data = load(fullfile(files(i).folder,files(i).name),'output');
        if data.output.bestObjective < best
            best = data.output.bestObjective;
            decision = data.output.bestDecision;
        end
    end
    path = UAVPathPlanning3D.DecodeTrajectory(decision,cfg.uavStart,cfg.uavEnd,cfg.uavSamples);
    [xGrid,yGrid] = meshgrid(0:2:200,0:2:200);
    terrain = UAVPathPlanning3D.TerrainHeight(xGrid,yGrid,scenario);
    nexttile;
    surf(xGrid,yGrid,terrain,'LineStyle','none','FaceAlpha',0.82); hold on;
    plot3(path(:,1),path(:,2),path(:,3),'r-','LineWidth',2.5);
    scatter3(cfg.uavStart(1),cfg.uavStart(2),cfg.uavStart(3),80,'g','filled');
    scatter3(cfg.uavEnd(1),cfg.uavEnd(2),cfg.uavEnd(3),80,'m','filled');
    zones = UAVPathPlanning3D.RestrictedZones(scenario);
    [sx,sy,sz] = sphere(24); sz(sz<0) = 0;
    for z = 1:size(zones,1)
        surf(zones(z,1)+zones(z,4)*sx,zones(z,2)+zones(z,4)*sy, ...
            zones(z,3)+zones(z,4)*sz,'FaceColor',[1,0.2,0.2], ...
            'FaceAlpha',0.25,'LineStyle','none');
    end
    title(sprintf('Scenario %d, cost %.3e',scenario,best));
    xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
    view([-35,35]); grid on; axis tight;
end
title(layout,'SDMSPSO 500-D UAV trajectory planning');
exportgraphics(gcf,fullfile(outputDirectory,'uav_best_paths.png'),'Resolution',300);
end

