classdef FilterConfig
    % FILTERCONFIG 滤波器统一配置类
    %
    % 所有滤波器的配置参数统一在此类中定义
    %
    % 使用示例:
    %   config = FilterConfig();
    %   config.detectionProb = 0.9;
    %   config.motionModel.F = kron(eye(2), [1 T; 0 1]);
    %   result = phd.GMPHD_filter(config, measurements);
    %
    % 版本: 1.0
    % 日期: 2026-03-12
    
    properties
        % 运动模型
        motionModel struct = struct(...
            'type', 'CV', ...
            'F', [], ...
            'Q', [] ...
        )
        
        % 量测模型
        measurementModel struct = struct(...
            'type', 'Linear', ...
            'H', [], ...
            'R', [] ...
        )
        
        % 滤波器参数
        pruningThreshold (1,1) double = 1e-5
        mergingThreshold (1,1) double = 0.1
        maxComponents (1,1) double = 100
        gatingThreshold (1,1) double = 20
        
        % 目标参数
        detectionProb (1,1) double = 0.9
        survivalProb (1,1) double = 0.99
        
        % 杂波模型
        clutterRate (1,1) double = 10
        surveillanceArea (1,2) double = [300, 300]
        
        % 新生模型
        birthModel struct = struct(...
            'type', 'Poisson', ...
            'intensity', 0.005, ...
            'means', [], ...
            'covs', [], ...
            'weights', [] ...
        )
        
        % 估计参数
        estimationMethod (1,:) char = 'weighted_mean'
        existenceThreshold (1,1) double = 0.5
        
        % 性能选项
        enableParallel (1,1) logical = false
        verbose (1,1) logical = false
        plotResults (1,1) logical = false
    end
    
    properties (Dependent)
        isValid
    end
    
    methods
        function obj = FilterConfig(varargin)
            % FILTERCONFIG 构造函数
            %
            % 支持键值对初始化
            % 示例:
            %   config = FilterConfig('detectionProb', 0.9, 'survivalProb', 0.99);
            
            % 解析键值对参数
            if mod(nargin, 2) ~= 0
                error('MTT:InvalidInput', '参数必须为键值对');
            end
            
            % 应用用户提供的参数
            for i = 1:2:nargin
                key = varargin{i};
                value = varargin{i+1};
                
                if isprop(obj, key)
                    obj.(key) = value;
                else
                    warning('MTT:UnknownProperty', ...
                        '未知属性: %s，将被忽略', key);
                end
            end
        end
        
        function validate(obj)
            % VALIDATE 验证配置的有效性
            
            % 验证滤波器参数
            if obj.maxComponents <= 0
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    'maxComponents必须为正数');
                throw(ME);
            end
            
            if obj.gatingThreshold <= 0
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    'gatingThreshold必须为正数');
                throw(ME);
            end
            
            % 验证目标参数
            if obj.detectionProb < 0 || obj.detectionProb > 1
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    'detectionProb必须在0到1之间');
                throw(ME);
            end
            
            if obj.survivalProb < 0 || obj.survivalProb > 1
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    'survivalProb必须在0到1之间');
                throw(ME);
            end
            
            % 验证杂波模型
            if obj.clutterRate < 0
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    'clutterRate必须为非负数');
                throw(ME);
            end
            
            % 验证运动模型
            if isempty(obj.motionModel.F) || isempty(obj.motionModel.Q)
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    '运动模型矩阵F和Q不能为空');
                throw(ME);
            end
            
            % 验证量测模型
            if isempty(obj.measurementModel.H) || isempty(obj.measurementModel.R)
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    '量测模型矩阵H和R不能为空');
                throw(ME);
            end
            
            % 验证新生模型
            if isempty(obj.birthModel.means) || isempty(obj.birthModel.covs)
                ME = utils.MTTException(utils.ErrorCode.INVALID_CONFIG, ...
                    '新生模型参数不能为空');
                throw(ME);
            end
            
            % 验证维度一致性
            stateDim = size(obj.motionModel.F, 1);
            measDim = size(obj.measurementModel.H, 1);
            
            if size(obj.measurementModel.H, 2) ~= stateDim
                ME = utils.MTTException(utils.ErrorCode.DIMENSION_MISMATCH, ...
                    '量测矩阵H的列数(%d)与状态维数(%d)不匹配', ...
                    size(obj.measurementModel.H, 2), stateDim);
                throw(ME);
            end
            
            if ~isempty(obj.birthModel.means)
                if size(obj.birthModel.means, 1) ~= stateDim
                    ME = utils.MTTException(utils.ErrorCode.DIMENSION_MISMATCH, ...
                        '新生均值维度(%d)与状态维数(%d)不匹配', ...
                        size(obj.birthModel.means, 1), stateDim);
                    throw(ME);
                end
            end
        end
        
        function tf = get.isValid(obj)
            % GET.ISVALID 检查配置是否有效
            
            try
                obj.validate();
                tf = true;
            catch
                tf = false;
            end
        end
        
        function display(obj)
            % DISPLAY 显示配置摘要
            
            fprintf('\n===== 滤波器配置 =====\n');
            fprintf('运动模型: %s (状态维数: %d)\n', ...
                obj.motionModel.type, size(obj.motionModel.F, 1));
            fprintf('量测模型: %s (量测维数: %d)\n', ...
                obj.measurementModel.type, size(obj.measurementModel.H, 1));
            fprintf('检测概率: %.2f\n', obj.detectionProb);
            fprintf('存活概率: %.2f\n', obj.survivalProb);
            fprintf('杂波率: %.2f\n', obj.clutterRate);
            fprintf('剪枝阈值: %.2e\n', obj.pruningThreshold);
            fprintf('最大分量数: %d\n', obj.maxComponents);
            fprintf('====================\n\n');
        end
        
        function save(obj, filename)
            % SAVE 保存配置到文件
            
            configStruct = obj.toStruct();
            save(filename, '-struct', 'configStruct');
        end
        
        function s = toStruct(obj)
            % TOSTRUCT 转换为结构体
            
            props = properties(obj);
            s = struct();
            for i = 1:length(props)
                s.(props{i}) = obj.(props{i});
            end
        end
    end
end
