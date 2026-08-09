function run_sensitivity_suite(outputDirectory,runs)
%RUN_SENSITIVITY_SUITE Paper sensitivity study: F1, F5, F11 at D=200.
cfg = paper_settings();
if nargin < 1 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','sensitivity'); end
if nargin < 2 || isempty(runs), runs = cfg.runs; end
if ~exist(outputDirectory,'dir'), mkdir(outputDirectory); end
records = struct([]);
k = 0;
for f = 1:numel(cfg.sensitivityFunctions)
    problem = cfg.sensitivityFunctions{f};
    for value = cfg.trValues
        for r = 1:runs
            k = k+1;
            seed = cfg.seedBase+10000*f+1000*find(cfg.trValues==value,1)+r;
            out = run_single_experiment('SDMSPSO',problem,cfg.sensitivityDimension, ...
                cfg.maxFE,cfg.population,seed,{value,150,1,1,1},{});
            records(k) = pack(out,'TR_init',value);
        end
    end
    for value = cfg.kLocValues
        for r = 1:runs
            k = k+1;
            seed = cfg.seedBase+20000*f+1000*find(cfg.kLocValues==value,1)+r;
            out = run_single_experiment('SDMSPSO',problem,cfg.sensitivityDimension, ...
                cfg.maxFE,cfg.population,seed,{0.4,value,1,1,1},{});
            records(k) = pack(out,'K_loc_max',value);
        end
    end
end
save(fullfile(outputDirectory,'sensitivity_results.mat'),'records','cfg');
end

function record = pack(out,parameter,value)
record.problem = out.problem;
record.dimension = out.dimension;
record.parameter = parameter;
record.value = value;
record.seed = out.seed;
record.bestObjective = out.bestObjective;
record.runtimeSeconds = out.runtimeSeconds;
end
