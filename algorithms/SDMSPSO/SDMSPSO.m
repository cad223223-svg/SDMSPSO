classdef SDMSPSO < ALGORITHM
% <single> <real> <expensive>
% Synergistic dual-scale multi-surrogate particle swarm optimization.
%
% Parameters:
%   TR_init         initial normalized trust-region radius (default 0.4)
%   K_loc_max       maximum local archive size (default 150)
%   useMacroQuad    enable macro separable-quadratic candidates (default 1)
%   useLRSS         enable all local LRSS candidates (default 1)
%   useAdaptiveTR   enable trust-region adaptation (default 1)
%   useLocalQuad    enable the local quadratic candidate (default 1)
%   useOCD          enable the OCD candidate (default 1)
%   ocdGridSize     number of OCD grid points (default 21)

    methods
        function main(Algorithm,Problem)
            [TR_init,K_loc_max,useMacroQuad,useLRSS,useAdaptiveTR, ...
                useLocalQuad,useOCD,ocdGridSize] = ...
                Algorithm.ParameterSet(0.4,150,1,1,1,1,1,21);

            D = Problem.D;
            lower = Problem.lower;
            upper = Problem.upper;
            scale = upper - lower;
            if Problem.maxFE < 31
                error('SDMSPSO:BudgetTooSmall','SDMSPSO requires maxFE >= 31.');
            end
            if any(scale <= 0)
                error('SDMSPSO:InvalidBounds','Every decision variable must have a nonzero range.');
            end
            if ocdGridSize < 3 || mod(ocdGridSize,2) ~= 1
                error('SDMSPSO:OCDGridSize','ocdGridSize must be an odd integer >= 3.');
            end

            initN = 100;
            if D >= 100
                initN = 150;
            end
            initN = min(initN,Problem.maxFE-30);
            initialDecs = lower + scale.*lhsdesign(initN,D);
            archive = Problem.Evaluation(initialDecs);
            archiveX = archive.decs;
            archiveF = archive.objs;
            archiveF = archiveF(:,1);
            bestValue = min(archiveF);

            tr = TR_init;
            stall = 0;
            while Algorithm.NotTerminated(archive)
                Xn = (archiveX-lower)./scale;
                [~,order] = sort(archiveF);
                incumbent = Xn(order(1),:);
                topCount = min(10,size(Xn,1));
                topStd = std(Xn(order(1:topCount),:),0,1) + 1e-12;

                candidates = zeros(0,D);
                if logical(useMacroQuad)
                    [aGlobal,bGlobal] = fitSeparableQuadratic(Xn,archiveF,D);
                    zQuad = solveBoxQuadratic(aGlobal,bGlobal,incumbent,0,1);
                    zProbe = min(1,max(0,zQuad + 0.5*randn(1,D).*topStd));
                    candidates = [candidates;zQuad;zProbe]; %#ok<AGROW>
                end

                eliteCount = max(3,floor(0.3*size(Xn,1)));
                weights = log(eliteCount+1)-log((1:eliteCount)');
                weights = weights/sum(weights);
                zEda = sum(weights.*Xn(order(1:eliteCount),:),1);
                poolEnd = min(10,numel(order));
                r2 = order(randi([2,poolEnd]));
                r3 = order(randi([2,poolEnd]));
                zDe = min(1,max(0,incumbent+0.6*(Xn(r2,:)-Xn(r3,:))));
                candidates = [candidates;zEda;zDe]; %#ok<AGROW>

                if logical(useLRSS)
                    localCount = min(size(Xn,1),round(K_loc_max));
                    localX = Xn(order(1:localCount),:);
                    localF = archiveF(order(1:localCount));
                    S = (localX-incumbent)/tr;

                    if logical(useLocalQuad)
                        [aLocal,bLocal] = fitSeparableQuadratic(S,localF,D);
                        sQuad = solveBoxQuadratic(aLocal,bLocal,zeros(1,D),-1,1);
                        zLocalQuad = min(1,max(0,incumbent+tr*sQuad+1e-8*randn(1,D)));
                        candidates = [candidates;zLocalQuad]; %#ok<AGROW>
                    end

                    fMin = min(localF);
                    fRange = max(localF)-fMin;
                    if fRange < 1e-10
                        fRange = 1;
                    end
                    localFn = (localF-fMin)/fRange;
                    [~,~,V] = svd(S,'econ');
                    subDim = min([D,20,localCount-1]);
                    basis = V(:,1:subDim);
                    projected = S*basis;
                    [wSvd,cSvd,sigmaSvd] = trainRbf(projected,localFn,2.0);
                    zSub = optimizeRbfPso(projected,wSvd,cSvd,sigmaSvd,subDim);
                    zSvd = min(1,max(0,incumbent+tr*(basis*zSub')'));

                    candidates = [candidates;zSvd]; %#ok<AGROW>
                    if logical(useOCD)
                        ocdCount = min(D,20);
                        ocdDims = randperm(D,ocdCount);
                        ocdTrain = S(:,ocdDims);
                        [wOcd,cOcd,sigmaOcd] = trainRbf(ocdTrain,localFn,1.0);
                        zOcd = incumbent;
                        gridNorm = linspace(-1,1,ocdGridSize)';
                        for j = 1:ocdCount
                            test = zeros(ocdGridSize,ocdCount);
                            test(:,j) = gridNorm;
                            prediction = predictRbf(test,ocdTrain,wOcd,cOcd,sigmaOcd);
                            [~,idx] = min(prediction);
                            zOcd(ocdDims(j)) = incumbent(ocdDims(j))+tr*gridNorm(idx);
                        end
                        zOcd = min(1,max(0,zOcd));
                        candidates = [candidates;zOcd]; %#ok<AGROW>
                    end
                end

                candidates = removeDuplicates(candidates,Xn,1e-11);
                if isempty(candidates) || stall > 4
                    candidates = min(1,max(0,incumbent+randn(1,D).*topStd));
                end

                remaining = Problem.maxFE-numel(archive);
                count = min(size(candidates,1),remaining);
                if count <= 0
                    break;
                end
                newX = lower+candidates(1:count,:).*scale;
                newSolutions = Problem.Evaluation(newX);
                newF = newSolutions.objs;
                newF = newF(:,1);
                archive = [archive,newSolutions]; %#ok<AGROW>
                archiveX = [archiveX;newX]; %#ok<AGROW>
                archiveF = [archiveF;newF]; %#ok<AGROW>

                improved = min(newF) < bestValue-1e-12;
                if improved
                    bestValue = min(newF);
                    stall = 0;
                    if logical(useAdaptiveTR)
                        tr = min(0.4,1.25*tr);
                    end
                else
                    stall = stall+1;
                    if logical(useAdaptiveTR)
                        tr = max(1e-6,0.75*tr);
                        if stall > 5
                            tr = max(tr,0.01);
                        end
                    end
                end
            end
        end
    end
end

function [a,b] = fitSeparableQuadratic(X,F,trueDimension)
    [n,d] = size(X);
    normalizedF = (F-mean(F))/(std(F)+1e-12);
    design = [X.^2,X,ones(n,1)];
    p = 2*d+1;
    if trueDimension < 100
        lambda = 1e-6;
    else
        lambda = max(1e-5,1e-4*sum(design(:).^2)/n);
    end
    if n < p
        alpha = (design*design'+lambda*eye(n))\normalizedF;
        beta = design'*alpha;
    else
        beta = (design'*design+lambda*eye(p))\(design'*normalizedF);
    end
    a = beta(1:d)';
    b = beta(d+1:2*d)';
end

function x = solveBoxQuadratic(a,b,anchor,lower,upper)
    x = anchor;
    convex = a > 1e-8;
    x(convex) = -b(convex)./(2*a(convex));
    nonconvex = ~convex;
    if lower < 0
        x(nonconvex) = sign(-b(nonconvex));
    end
    x = min(upper,max(lower,x));
end

function [weights,bias,sigma2] = trainRbf(X,F,smoothing)
    n = size(X,1);
    squaredNorm = sum(X.^2,2);
    distances = max(squaredNorm+squaredNorm'-2*(X*X'),0);
    sortedDistances = sort(distances(:));
    idx = max(1,floor(0.2*numel(sortedDistances)));
    sigma2 = sortedDistances(idx)*smoothing;
    if sigma2 < 1e-5
        sigma2 = 1;
    end
    kernel = exp(-distances/(2*sigma2));
    system = [kernel,ones(n,1);ones(1,n),0]+1e-5*eye(n+1);
    parameters = system\[F;0];
    weights = parameters(1:n);
    bias = parameters(n+1);
end

function values = predictRbf(Xnew,Xtrain,weights,bias,sigma2)
    newNorm = sum(Xnew.^2,2);
    trainNorm = sum(Xtrain.^2,2)';
    distances = max(newNorm+trainNorm-2*(Xnew*Xtrain'),0);
    values = exp(-distances/(2*sigma2))*weights+bias;
end

function best = optimizeRbfPso(Xtrain,weights,bias,sigma2,d)
    particleCount = 50;
    generations = 30;
    position = randn(particleCount,d);
    velocity = zeros(particleCount,d);
    personalBest = position;
    personalValue = predictRbf(position,Xtrain,weights,bias,sigma2);
    [globalValue,idx] = min(personalValue);
    best = personalBest(idx,:);
    for generation = 1:generations %#ok<NASGU>
        velocity = 0.5*velocity + 1.5*rand(particleCount,d).*(personalBest-position) ...
            + 1.5*rand(particleCount,d).*(best-position);
        position = min(3,max(-3,position+velocity));
        value = predictRbf(position,Xtrain,weights,bias,sigma2);
        improved = value < personalValue;
        personalBest(improved,:) = position(improved,:);
        personalValue(improved) = value(improved);
        [candidateValue,idx] = min(personalValue);
        if candidateValue < globalValue
            globalValue = candidateValue;
            best = personalBest(idx,:);
        end
    end
end

function uniqueCandidates = removeDuplicates(candidates,archive,tolerance)
    uniqueCandidates = zeros(0,size(candidates,2));
    reference = archive;
    for i = 1:size(candidates,1)
        distance = sqrt(sum((reference-candidates(i,:)).^2,2));
        if isempty(distance) || min(distance) > tolerance
            uniqueCandidates = [uniqueCandidates;candidates(i,:)]; %#ok<AGROW>
            reference = [reference;candidates(i,:)]; %#ok<AGROW>
        end
    end
end

