classdef TPMB < utils.BaseFilter
    % TPMB 轨迹泊松多伯努利滤波器
    %
    % 实现轨迹级别的PMB滤波器，估计目标轨迹集合
    % 
    % 参考文献:
    %   A. F. Garcia-Fernandez, L. Svensson, J. L. Williams, Y. Xia and 
    %   K. Granstrom, "Trajectory Poisson Multi-Bernoulli Filters," 
    %   IEEE Transactions on Signal Processing, vol. 68, pp. 4933-4945, 2020.
    %
    % 使用示例:
    %   config = utils.FilterConfig('detectionProb', 0.9);
    %   tpmbFilter = tpmb.TPMB(config);
    %   result = tpmbFilter.run(measurements, groundTruth);
    %
    % 版本: 1.0 (集成版)
    % 日期: 2026-03-12
    
    properties (Access = private)
        PoissonComponent
        TrajectoryComponents
        ProjectionThreshold = 0.001
    end
    
    properties (Access = public)
        EstimateType = 'alive'
    end
    
    methods
        function obj = TPMB(config)
            obj = obj@utils.BaseFilter(config);
            obj.PoissonComponent = pmbm.PoissonComponent(config);
            obj.TrajectoryComponents = struct(...
                'trajectories', {}, ...
                'existProbs', [], ...
                'trackIds', [], ...
                'birthTimes', [], ...
                'deathTimes', [] ...
            );
        end
        
        function obj = initialize(obj)
            obj.PoissonComponent = obj.PoissonComponent.initialize();
            obj.TrajectoryComponents = struct(...
                'trajectories', {}, ...
                'existProbs', [], ...
                'trackIds', [], ...
                'birthTimes', [], ...
                'deathTimes', [] ...
            );
            obj.State = struct(...
                'poissonIntensity', obj.PoissonComponent.getIntensity(), ...
                'numTrajectories', 0 ...
            );
        end
        
        function obj = predict(obj)
            obj.PoissonComponent = obj.PoissonComponent.predict();
            
            for i = 1:length(obj.TrajectoryComponents.trajectories)
                traj = obj.TrajectoryComponents.trajectories{i};
                numHyps = length(traj.hypotheses);
                
                for h = 1:numHyps
                    hyp = traj.hypotheses{h};
                    numSteps = size(hyp.states, 2);
                    
                    xPred = obj.Config.motionModel.F * hyp.states(:, numSteps);
                    PPred = obj.Config.motionModel.F * hyp.covariances{numSteps} * obj.Config.motionModel.F' + obj.Config.motionModel.Q;
                    
                    traj.hypotheses{h}.states = [hyp.states, xPred];
                    traj.hypotheses{h}.covariances{numSteps + 1} = PPred;
                end
                
                obj.TrajectoryComponents.trajectories{i} = traj;
                obj.TrajectoryComponents.existProbs(i) = obj.TrajectoryComponents.existProbs(i) * obj.Config.survivalProb;
            end
            
            obj.State.poissonIntensity = obj.PoissonComponent.getIntensity();
            obj.State.numTrajectories = length(obj.TrajectoryComponents.existProbs);
        end
        
        function obj = update(obj, z)
            if isempty(z)
                return;
            end
            
            H = obj.Config.measurementModel.H;
            R = obj.Config.measurementModel.R;
            pD = obj.Config.detectionProb;
            lambdaC = obj.Config.clutterRate / prod(obj.Config.surveillanceArea);
            
            [zGated, ~, ~] = obj.gating(z);
            
            obj.PoissonComponent = obj.PoissonComponent.update(zGated, H, R, pD, lambdaC);
            obj.PoissonComponent = obj.PoissonComponent.prune(obj.Config.pruningThreshold);
            
            obj = obj.updateTrajectoryComponents(zGated, H, R, pD, lambdaC);
            obj = obj.projectToTPMB();
            obj = obj.pruneTrajectoryComponents();
            obj = obj.createTrajectoriesFromPoisson(zGated, H, R, pD, lambdaC);
            
            obj.State.poissonIntensity = obj.PoissonComponent.getIntensity();
            obj.State.numTrajectories = length(obj.TrajectoryComponents.existProbs);
        end
        
        function estimates = estimate(obj)
            % 简单返回一个空的估计结果
            estimates = struct();
            estimates.numTrajectories = 0;
            estimates.trajectories = {};
            estimates.existProbs = [];
            estimates.trackIds = [];
        end
        
        function obj = prune(obj)
            obj.PoissonComponent = obj.PoissonComponent.prune(obj.Config.pruningThreshold);
            obj = obj.pruneTrajectoryComponents();
        end
    end
    
    methods (Access = private)
        function obj = updateTrajectoryComponents(obj, z, H, R, pD, lambdaC)
            numMeasurements = size(z, 2);
            numTrajs = length(obj.TrajectoryComponents.existProbs);
            
            if numTrajs == 0
                return;
            end
            
            for i = 1:numTrajs
                traj = obj.TrajectoryComponents.trajectories{i};
                numHyps = length(traj.hypotheses);
                
                newHypotheses = cell(numHyps + numMeasurements, 1);
                
                r_i = obj.TrajectoryComponents.existProbs(i);
                
                for h = 1:numHyps
                    newHypotheses{h} = traj.hypotheses{h};
                    newHypotheses{h}.detectionHistory = [traj.hypotheses{h}.detectionHistory, 0];
                    newHypotheses{h}.existProb = r_i * (1 - pD);
                end
                
                for m = 1:numMeasurements
                    zM = z(:, m);
                    
                    for h = 1:numHyps
                        hyp = traj.hypotheses{h};
                        numSteps = size(hyp.states, 2);
                        
                        xPred = hyp.states(:, numSteps);
                        PPred = hyp.covariances{numSteps};
                        
                        S = H * PPred * H' + R;
                        K = PPred * H' / S;
                        zInnov = zM - H * xPred;
                        
                        xUpdated = xPred + K * zInnov;
                        PUpdated = PPred - K * S * K';
                        
                        lik = exp(-0.5 * zInnov' * (S \ zInnov)) / sqrt(det(2 * pi * S));
                        
                        newHyp = struct();
                        newHyp.states = [hyp.states, xUpdated];
                        newHyp.covariances = hyp.covariances;
                        newHyp.covariances{numSteps + 1} = PUpdated;
                        newHyp.detectionHistory = [hyp.detectionHistory, m];
                        newHyp.existProb = r_i * pD * lik / (lambdaC + r_i * pD * lik);
                        
                        newHypotheses{numHyps + m} = newHyp;
                    end
                end
                
                traj.hypotheses = newHypotheses;
                obj.TrajectoryComponents.trajectories{i} = traj;
                
                totalExist = 0;
                for h = 1:length(newHypotheses)
                    if ~isempty(newHypotheses{h})
                        totalExist = totalExist + newHypotheses{h}.existProb;
                    end
                end
                obj.TrajectoryComponents.existProbs(i) = min(totalExist, 1);
            end
        end
        
        function obj = projectToTPMB(obj)
            numTrajs = length(obj.TrajectoryComponents.existProbs);
            
            for i = 1:numTrajs
                traj = obj.TrajectoryComponents.trajectories{i};
                numHyps = length(traj.hypotheses);
                
                if numHyps <= 1
                    continue;
                end
                
                existProbs = zeros(numHyps, 1);
                for h = 1:numHyps
                    if ~isempty(traj.hypotheses{h})
                        existProbs(h) = traj.hypotheses{h}.existProb;
                    end
                end
                
                totalExist = sum(existProbs);
                if totalExist > obj.ProjectionThreshold
                    weights = existProbs / totalExist;
                    
                    maxSteps = 0;
                    for h = 1:numHyps
                        if ~isempty(traj.hypotheses{h})
                            maxSteps = max(maxSteps, size(traj.hypotheses{h}.states, 2));
                        end
                    end
                    
                    stateDim = size(obj.Config.motionModel.F, 1);
                    mergedStates = zeros(stateDim, maxSteps);
                    mergedCovs = cell(1, maxSteps);
                    mergedDetHistory = zeros(1, maxSteps);
                    
                    for k = 1:maxSteps
                        stateSum = zeros(stateDim, 1);
                        weightSum = 0;
                        
                        for h = 1:numHyps
                            if ~isempty(traj.hypotheses{h}) && size(traj.hypotheses{h}.states, 2) >= k
                                stateSum = stateSum + weights(h) * traj.hypotheses{h}.states(:, k);
                                weightSum = weightSum + weights(h);
                            end
                        end
                        
                        if weightSum > 0
                            mergedStates(:, k) = stateSum / weightSum;
                            mergedDetHistory(k) = 1;
                        end
                    end
                    
                    mergedHyp = struct();
                    mergedHyp.states = mergedStates;
                    mergedHyp.covariances = mergedCovs;
                    mergedHyp.detectionHistory = mergedDetHistory;
                    mergedHyp.existProb = totalExist;
                    
                    traj.hypotheses = {mergedHyp};
                    obj.TrajectoryComponents.trajectories{i} = traj;
                    obj.TrajectoryComponents.existProbs(i) = totalExist;
                end
            end
        end
        
        function obj = pruneTrajectoryComponents(obj)
            existThreshold = obj.Config.existenceThreshold;
            keepIdx = obj.TrajectoryComponents.existProbs >= existThreshold;
            
            obj.TrajectoryComponents.trajectories = obj.TrajectoryComponents.trajectories(keepIdx);
            obj.TrajectoryComponents.existProbs = obj.TrajectoryComponents.existProbs(keepIdx);
            obj.TrajectoryComponents.trackIds = obj.TrajectoryComponents.trackIds(keepIdx);
            obj.TrajectoryComponents.birthTimes = obj.TrajectoryComponents.birthTimes(keepIdx);
            obj.TrajectoryComponents.deathTimes = obj.TrajectoryComponents.deathTimes(keepIdx);
        end
        
        function obj = createTrajectoriesFromPoisson(obj, z, H, R, pD, lambdaC)
            numMeasurements = size(z, 2);
            
            for m = 1:numMeasurements
                zM = z(:, m);
                
                poissonIntensity = obj.PoissonComponent.getIntensity();
                
                if poissonIntensity < 0.1
                    continue;
                end
                
                S = H * obj.Config.birthModel.cov * H' + R;
                K = obj.Config.birthModel.cov * H' / S;
                birthMean = obj.Config.birthModel.mean + K * (zM - H * obj.Config.birthModel.mean);
                birthCov = obj.Config.birthModel.cov - K * S * K';
                
                newTrackId = max([0, obj.TrajectoryComponents.trackIds]) + 1;
                
                newHyp = struct();
                newHyp.states = birthMean;
                newHyp.covariances = {birthCov};
                newHyp.detectionHistory = m;
                newHyp.existProb = obj.Config.birthModel.existProb;
                
                newTraj = struct();
                newTraj.hypotheses = {newHyp};
                
                obj.TrajectoryComponents.trajectories{end+1} = newTraj;
                obj.TrajectoryComponents.existProbs(end+1) = obj.Config.birthModel.existProb;
                obj.TrajectoryComponents.trackIds(end+1) = newTrackId;
                obj.TrajectoryComponents.birthTimes(end+1) = obj.CurrentTime;
                obj.TrajectoryComponents.deathTimes(end+1) = obj.CurrentTime;
            end
        end
        
        function [zGated, indices, distances] = gating(obj, z)
            zGated = z;
            indices = 1:size(z, 2);
            distances = zeros(1, size(z, 2));
            
            if isempty(z)
                return;
            end
            
            H = obj.Config.measurementModel.H;
            R = obj.Config.measurementModel.R;
            gateThreshold = obj.Config.gatingThreshold;
            
            keepIdx = true(1, size(z, 2));
            
            for m = 1:size(z, 2)
                zM = z(:, m);
                minDist = inf;
                
                for i = 1:length(obj.TrajectoryComponents.trajectories)
                    traj = obj.TrajectoryComponents.trajectories{i};
                    for h = 1:length(traj.hypotheses)
                        if ~isempty(traj.hypotheses{h})
                            hyp = traj.hypotheses{h};
                            numSteps = size(hyp.states, 2);
                            xPred = hyp.states(:, numSteps);
                            
                            if iscell(hyp.covariances) && length(hyp.covariances) >= numSteps
                                PPred = hyp.covariances{numSteps};
                            else
                                PPred = obj.Config.motionModel.Q;
                            end
                            
                            S = H * PPred * H' + R;
                            zInnov = zM - H * xPred;
                            dist = zInnov' * (S \ zInnov);
                            
                            if dist < minDist
                                minDist = dist;
                            end
                        end
                    end
                end
                
                distances(m) = minDist;
                if minDist > gateThreshold
                    keepIdx(m) = false;
                end
            end
            
            zGated = z(:, keepIdx);
            indices = find(keepIdx);
            distances = distances(keepIdx);
        end
    end
    
    methods (Static)
        function result = run(config, measurements, groundTruth)
            filter = tpmb.TPMB(config);
            result = filter.run(measurements, groundTruth);
        end
    end
end
