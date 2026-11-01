function run_ocd_ablation_suite(outputDirectory,runs)
%RUN_OCD_ABLATION_SUITE Paired-seed OCD ablation at D=30, 200, and 500.
cfg = paper_settings();
if nargin < 1 || isempty(outputDirectory), outputDirectory = fullfile(pwd,'results','ocd_ablation'); end
if nargin < 2 || isempty(runs), runs = cfg.runs; end
for f = 1:numel(cfg.functions)
    for d = cfg.ablationDimensions
        for r = 1:runs
            seed = cfg.seedBase+100000*f+1000*d+r;
            for useOCD = [1,0]
                parameters = cfg.sdmsParameters;
                parameters{7} = useOCD;
                if useOCD, variant = 'SDMSPSO'; else, variant = 'wo-OCD'; end
                folder = fullfile(outputDirectory,cfg.functions{f},sprintf('D%d',d),variant);
                if ~exist(folder,'dir'), mkdir(folder); end
                filename = fullfile(folder,sprintf('run_%02d.mat',r));
                if exist(filename,'file'), continue; end
                output = run_single_experiment('SDMSPSO',cfg.functions{f},d, ...
                    cfg.maxFE,cfg.population,seed,parameters,{});
                output.variant = variant;
                save(filename,'output');
            end
        end
    end
end
end

