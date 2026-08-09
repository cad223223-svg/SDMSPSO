function run_ablation_suite(outputDirectory,runs)
%RUN_ABLATION_SUITE Disable one component at a time using one codebase.
cfg = paper_settings();
if nargin < 1 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','ablation'); end
if nargin < 2 || isempty(runs), runs = cfg.runs; end
variants = {
    'SDMSPSO',        {0.4,150,1,1,1};
    'wo-Quad',        {0.4,150,0,1,1};
    'wo-LRSS',        {0.4,150,1,0,1};
    'wo-ATR',         {0.4,150,1,1,0}};
for f = 1:numel(cfg.functions)
    for d = cfg.ablationDimensions
        for v = 1:size(variants,1)
            folder = fullfile(outputDirectory,cfg.functions{f},sprintf('D%d',d),variants{v,1});
            if ~exist(folder,'dir'), mkdir(folder); end
            for r = 1:runs
                seed = cfg.seedBase+100000*f+1000*d+100*v+r;
                output = run_single_experiment('SDMSPSO',cfg.functions{f},d, ...
                    cfg.maxFE,cfg.population,seed,variants{v,2},{});
                output.variant = variants{v,1};
                save(fullfile(folder,sprintf('run_%02d.mat',r)),'output');
            end
        end
    end
end
end

