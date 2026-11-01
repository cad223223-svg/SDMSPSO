function records = audit_uav_geometry(outputDirectory)
%AUDIT_UAV_GEOMETRY Check saved SDMSPSO paths at 300 and 3000 samples.
cfg = paper_settings();
if nargin < 1 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','uav'); end
records = table();
for scenario = cfg.uavScenarios
    files = dir(fullfile(outputDirectory,sprintf('scenario_%d',scenario),'run_*.mat'));
    for i = 1:numel(files)
        loaded = load(fullfile(files(i).folder,files(i).name),'output');
        decision = loaded.output.bestDecision;
        path300 = UAVPathPlanning3D.DecodeTrajectory(decision,cfg.uavStart,cfg.uavEnd,300);
        path3000 = UAVPathPlanning3D.DecodeTrajectory(decision,cfg.uavStart,cfg.uavEnd,3000);
        [feasible300,~,~] = assess(path300,scenario,cfg);
        [feasible3000,terrainViolation,zoneEntry,minimumClearance] = assess(path3000,scenario,cfg);
        row = table(scenario,string(files(i).name),feasible300,feasible3000, ...
            terrainViolation,zoneEntry,minimumClearance, ...
            'VariableNames',{'Scenario','RunFile','F300','F3000','T3000','Z3000','MinimumClearance'});
        records = [records;row]; %#ok<AGROW>
    end
end
if isempty(records)
    error('audit_uav_geometry:NoRuns','No saved UAV runs found in %s.',outputDirectory);
end
writetable(records,fullfile(outputDirectory,'uav_geometry_audit.csv'));
end

function [feasible,terrainViolation,zoneEntry,minimumClearance] = assess(path,scenario,cfg)
terrain = UAVPathPlanning3D.TerrainHeight(path(:,1),path(:,2),scenario);
minimumClearance = min(path(:,3)-terrain);
terrainViolation = minimumClearance < 15;
zones = UAVPathPlanning3D.RestrictedZones(scenario);
zoneEntry = false;
for j = 1:size(zones,1)
    margin = sqrt(sum((path-zones(j,1:3)).^2,2))-zones(j,4);
    zoneEntry = zoneEntry || any(margin < 0);
end
endpointsMatch = all(abs(path(1,:)-cfg.uavStart) < 1e-9) && ...
    all(abs(path(end,:)-cfg.uavEnd) < 1e-9);
feasible = ~terrainViolation && ~zoneEntry && endpointsMatch;
end

