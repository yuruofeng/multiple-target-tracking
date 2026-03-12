classdef MBMComponent
    % MBMCOMPONENT 多伯努利混合分量
    %
    % 实现PMBM滤波器中的多伯努利混合分量
    %
    % 使用示例:
    %   mbm = pmbm.MBMComponent(config);
    %   mbm = mbm.predict();
    %   mbm = mbm.update(z, H, R);
    %
    % 版本: 1.0
    % 日期: 2026-03-12
    
    properties
        Tracks         cell   = {}  % 伯努利分量列表
        GlobalHyp      double = []  % 全局假设矩阵
        GlobalHypWeight double = []  % 全局假设权重
    end
    
    properties (Access = private)
        Config
        NextTrackId = 1  % 下一个航迹ID
    end
    
    methods
        function obj = MBMComponent(config)
            % MBMCOMPONENT 构造函数
            
            if nargin < 1
                error('MTT:MissingParameter', '必须提供config参数');
            end
            
            obj.Config = config;
        end
        
        function obj = initialize(obj)
            % INITIALIZE 初始化MBM分量
            
            obj.Tracks = {};
            obj.GlobalHyp = [];
            obj.GlobalHypWeight = [];
        end
        
        function obj = predict(obj)
            % PREDICT 预测MBM分量
            
            pS = obj.Config.survivalProb;
            F = obj.Config.motionModel.F;
            Q = obj.Config.motionModel.Q;
            
            % 预测每个航迹
            for i = 1:length(obj.Tracks)
                track = obj.Tracks{i};
                
                % 预测状态
                track.state = F * track.state;
                track.covariance = F * track.covariance * F' + Q;
                track.covariance = (track.covariance + track.covariance') / 2;
                
                % 预测存在概率
                track.existenceProb = pS * track.existenceProb;
                
                obj.Tracks{i} = track;
            end
        end
        
        function obj = update(obj, z, H, R, pD, lambdaC, existenceThreshold)
            % UPDATE 更新MBM分量
            
            if isempty(z)
                return;
            end
            
            numMeas = size(z, 2);
            
            % 对每个量测创建新的潜在航迹
            for j = 1:numMeas
                z_j = z(:, j);
                
                % 创建新的伯努利分量
                newTrack = obj.createTrackFromMeasurement(z_j, H, R, pD, lambdaC);
                
                if newTrack.existenceProb > existenceThreshold
                    obj.Tracks{end+1} = newTrack;
                    
                    % 创建新的全局假设
                    obj = obj.addGlobalHypothesis(length(obj.Tracks));
                end
            end
            
            % 更新现有航迹
            for i = 1:length(obj.Tracks)
                track = obj.Tracks{i};
                
                % 漏检更新
                track.existenceProb = (1 - pD) * track.existenceProb;
                
                obj.Tracks{i} = track;
            end
        end
        
        function obj = prune(obj, weightThreshold, maxHypotheses)
            % PRUNE 剪枝MBM分量
            
            % 1. 移除权重小的全局假设
            if ~isempty(obj.GlobalHypWeight)
                keepIdx = obj.GlobalHypWeight >= weightThreshold;
                obj.GlobalHyp = obj.GlobalHyp(:, keepIdx);
                obj.GlobalHypWeight = obj.GlobalHypWeight(keepIdx);
                
                % 限制最大假设数
                if length(obj.GlobalHypWeight) > maxHypotheses
                    [~, sortedIdx] = sort(obj.GlobalHypWeight, 'descend');
                    keepIdx = sortedIdx(1:maxHypotheses);
                    
                    obj.GlobalHyp = obj.GlobalHyp(:, keepIdx);
                    obj.GlobalHypWeight = obj.GlobalHypWeight(keepIdx);
                end
                
                % 归一化权重
                obj.GlobalHypWeight = obj.GlobalHypWeight / sum(obj.GlobalHypWeight);
            end
            
            % 2. 移除未使用的航迹
            usedTracks = unique(obj.GlobalHyp(:));
            if ~isempty(usedTracks)
                obj.Tracks = obj.Tracks(usedTracks);
                
                % 更新全局假设索引
                [~, ~, newIndices] = unique(obj.GlobalHyp(:));
                obj.GlobalHyp = reshape(newIndices, size(obj.GlobalHyp));
            else
                obj.Tracks = {};
                obj.GlobalHyp = [];
                obj.GlobalHypWeight = [];
            end
        end
        
        function estimate = estimate(obj, method)
            % ESTIMATE 估计目标状态
            
            if nargin < 2
                method = 1;  % 默认使用方法1
            end
            
            estimate = struct('states', [], 'existenceProbs', []);
            
            if isempty(obj.GlobalHypWeight)
                return;
            end
            
            % 选择权重最大的全局假设
            [~, maxIdx] = max(obj.GlobalHypWeight);
            selectedHyp = obj.GlobalHyp(:, maxIdx);
            
            % 提取该假设中的航迹
            trackIndices = unique(selectedHyp(selectedHyp > 0));
            
            states = [];
            existenceProbs = [];
            
            for i = 1:length(trackIndices)
                trackIdx = trackIndices(i);
                if trackIdx <= length(obj.Tracks)
                    track = obj.Tracks{trackIdx};
                    states = [states, track.state];
                    existenceProbs = [existenceProbs, track.existenceProb];
                end
            end
            
            estimate.states = states;
            estimate.existenceProbs = existenceProbs;
        end
    end
    
    methods (Access = protected)
        function track = createTrackFromMeasurement(obj, z, H, R, pD, lambdaC)
            % CREATETRACKFROMMEASUREMENT 从量测创建新航迹
            
            track = struct();
            
            % 使用量测初始化状态
            stateDim = size(H, 2);
            measDim = size(H, 1);
            
            % 简单初始化：假设前measDim维是位置
            track.state = zeros(stateDim, 1);
            track.state(1:measDim) = z;
            
            % 初始协方差
            track.covariance = eye(stateDim) * 100;
            track.covariance(1:measDim, 1:measDim) = R;
            
            % 存在概率
            track.existenceProb = pD * lambdaC;
            
            % 航迹ID和初始时间
            track.id = obj.NextTrackId;
            obj.NextTrackId = obj.NextTrackId + 1;
            track.birthTime = obj.Config.CurrentTime;
        end
        
        function obj = addGlobalHypothesis(obj, trackIdx)
            % ADDGLOBALHYPOTHESIS 添加新的全局假设
            
            if isempty(obj.GlobalHyp)
                obj.GlobalHyp = trackIdx;
                obj.GlobalHypWeight = 1;
            else
                % 添加新假设
                numExistingHyp = size(obj.GlobalHyp, 2);
                newHyp = zeros(length(obj.Tracks), 1);
                newHyp(trackIdx) = 1;
                
                obj.GlobalHyp = [obj.GlobalHyp, newHyp];
                obj.GlobalHypWeight = [obj.GlobalHypWeight, 1];
                
                % 归一化
                obj.GlobalHypWeight = obj.GlobalHypWeight / sum(obj.GlobalHypWeight);
            end
        end
    end
end
