function run_smoke_test()
%RUN_SMOKE_TEST Fast integration checks; not a paper experiment.
cfg = paper_settings();
out = run_single_experiment('SDMSPSO','SOP_F1',30,160,20,1,{0.4,50,1,1,1},{});
assert(isfinite(out.bestObjective));
problem = UAVPathPlanning3D('D',500,'N',2,'maxFE',2,'parameter',{1,cfg.uavStart,cfg.uavEnd});
decisions = [problem.lower;problem.upper];
values = problem.CalObj(decisions);
assert(all(isfinite(values)) && numel(values)==2);
fprintf('Smoke test passed. SOP_F1 best = %.6e\n',out.bestObjective);
end

