function run_ocd_grid_sensitivity(outputDirectory,runs)
%RUN_OCD_GRID_SENSITIVITY OCD grid study on F1, F5, F11 at D=200.
cfg = paper_settings();
if nargin < 1 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','ocd_grid'); end
if nargin < 2 || isempty(runs), runs = cfg.runs; end
for f = 1:numel(cfg.ocdGridFunctions)
    problem = cfg.ocdGridFunctions{f};
    for gridSize = cfg.ocdGridSizes
        folder = fullfile(outputDirectory,problem,sprintf('D%d',cfg.sensitivityDimension),sprintf('grid_%d',gridSize));
        if ~exist(folder,'dir'), mkdir(folder); end
        for r = 1:runs
            filename = fullfile(folder,sprintf('run_%02d.mat',r));
            if exist(filename,'file'), continue; end
            parameters = cfg.sdmsParameters;
            parameters{8} = gridSize;
            seed = cfg.seedBase+100000*f+1000*gridSize+r;
            output = run_single_experiment('SDMSPSO',problem,cfg.sensitivityDimension, ...
                cfg.maxFE,cfg.population,seed,parameters,{});
            output.ocdGridSize = gridSize;
            save(filename,'output');
        end
    end
end
end

