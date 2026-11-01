function cfg = paper_settings()
%PAPER_SETTINGS Settings reported in the associated SDMSPSO manuscript.
cfg.platform = 'PlatEMO v4.15';
cfg.matlab = 'MATLAB R2024b';
cfg.functions = {'SOP_F1','SOP_F5','SOP_F8','SOP_F9','SOP_F10','SOP_F11','SOP_F12','SOP_F13'};
cfg.dimensions = [30,50,100,200,500,1000];
cfg.maxFE = 1000;
cfg.population = 50;
cfg.runs = 20;
cfg.seedBase = 20260809;
cfg.sdmsParameters = {0.4,150,1,1,1,1,1,21};
cfg.sensitivityFunctions = {'SOP_F1','SOP_F5','SOP_F11'};
cfg.sensitivityDimension = 200;
cfg.trValues = [0.2,0.4,0.8];
cfg.kLocValues = [50,100,150,200];
cfg.ablationDimensions = [30,200,500];
cfg.ocdGridSizes = [9,13,21,31,41];
cfg.ocdGridFunctions = {'SOP_F1','SOP_F5','SOP_F11'};
cfg.uavScenarios = 1:3;
cfg.uavDimension = 500;
cfg.uavStart = [0,0,50];
cfg.uavEnd = [200,200,100];
cfg.uavSamples = 300;
end


