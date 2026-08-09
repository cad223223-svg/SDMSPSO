function run_uav_suite(outputDirectory,runs)
%RUN_UAV_SUITE Reproduce the 500-D, three-scenario UAV experiment for SDMSPSO.
cfg = paper_settings();
if nargin < 1 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','uav'); end
if nargin < 2 || isempty(runs), runs = cfg.runs; end
for scenario = cfg.uavScenarios
    folder = fullfile(outputDirectory,sprintf('scenario_%d',scenario));
    if ~exist(folder,'dir'), mkdir(folder); end
    for r = 1:runs
        seed = cfg.seedBase+1000*scenario+r;
        output = run_single_experiment('SDMSPSO','UAVPathPlanning3D', ...
            cfg.uavDimension,cfg.maxFE,cfg.population,seed,cfg.sdmsParameters, ...
            {scenario,cfg.uavStart,cfg.uavEnd});
        save(fullfile(folder,sprintf('run_%02d.mat',r)),'output');
        fprintf('UAV scenario=%d run=%d/%d best=%.6e\n',scenario,r,runs,output.bestObjective);
    end
end
end

