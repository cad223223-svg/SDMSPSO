function run_benchmark_suite(outputDirectory,runs,dimensions)
%RUN_BENCHMARK_SUITE Reproduce the paper's SDMSPSO benchmark matrix.
cfg = paper_settings();
if nargin < 1 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','benchmarks'); end
if nargin < 2 || isempty(runs), runs = cfg.runs; end
if nargin < 3 || isempty(dimensions), dimensions = cfg.dimensions; end
for f = 1:numel(cfg.functions)
    for d = dimensions
        folder = fullfile(outputDirectory,cfg.functions{f},sprintf('D%d',d));
        if ~exist(folder,'dir'), mkdir(folder); end
        for r = 1:runs
            seed = cfg.seedBase + 100000*f + 100*d + r;
            output = run_single_experiment('SDMSPSO',cfg.functions{f},d, ...
                cfg.maxFE,cfg.population,seed,cfg.sdmsParameters,{});
            save(fullfile(folder,sprintf('run_%02d.mat',r)),'output');
            fprintf('%s D=%d run=%d/%d best=%.6e\n',cfg.functions{f},d,r,runs,output.bestObjective);
        end
    end
end
end

