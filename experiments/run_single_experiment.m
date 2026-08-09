function output = run_single_experiment(algorithmName,problemName,D,maxFE,N,seed,algorithmParameters,problemParameters)
%RUN_SINGLE_EXPERIMENT Execute one deterministic PlatEMO run and summarize it.
if nargin < 7 || isempty(algorithmParameters), algorithmParameters = {}; end
if nargin < 8 || isempty(problemParameters), problemParameters = {}; end
rng(seed,'twister');
problemArgs = {'D',D,'N',N,'maxFE',maxFE};
if ~isempty(problemParameters)
    problemArgs = [problemArgs,{'parameter',problemParameters}];
end
problem = feval(problemName,problemArgs{:});
algorithm = feval(algorithmName,'parameter',algorithmParameters,'save',0);
timer = tic;
algorithm.Solve(problem);
elapsed = toc(timer);
finalPopulation = algorithm.result{end,2};
objectives = finalPopulation.objs;
[bestObjective,index] = min(objectives(:,1));
output.algorithm = algorithmName;
output.problem = problemName;
output.dimension = D;
output.maxFE = maxFE;
output.population = N;
output.seed = seed;
output.algorithmParameters = algorithmParameters;
output.problemParameters = problemParameters;
output.bestObjective = bestObjective;
bestSolution = finalPopulation(index);
output.bestDecision = bestSolution.dec;
output.runtimeSeconds = elapsed;
end
