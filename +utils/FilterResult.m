classdef FilterResult
    % FILTERRESULT 滤波器统一结果类
    %
    % 所有滤波器的输出结果统一在此类中定义
    %
    % 使用示例:
    %   result = FilterResult();
    %   result.estimates.states = estimatedStates;
    %   result.metrics.GOSPA.total = gospaError;
    %   result.save('results.mat');
    %
    % 版本: 1.0
    % 日期: 2026-03-12
    
    properties
        % 核心结果
        estimates struct = struct(...
            'states', [], ...
            'weights', [], ...
            'cardinality', [], ...
            'trajectories', {} ...
        )
        
        % 性能指标
        metrics struct = struct(...
            'GOSPA', struct(...
                'total', [], ...
                'localization', [], ...
                'missed', [], ...
                'false', [] ...
            ), ...
            'trajectory', struct(...
                'total', [], ...
                'localization', [], ...
                'missed', [], ...
                'false', [], ...
                'switch', [] ...
            ), ...
            'cardinalityError', [], ...
            'computationalTime', [] ...
        )
        
        % 滤波器状态
        filterState struct = struct()
        
        % 元信息
        executionTime (1,1) double = 0
        timeStamp (1,1) datetime = datetime('now')
        algorithmVersion (1,:) char = '1.0'
        algorithmName (1,:) char = ''
        
        % 状态标识
        status (1,:) char = 'pending'
        message (1,:) char = ''
        errorCode (1,1) double = utils.ErrorCode.SUCCESS
        
        % 诊断信息
        diagnostics struct = struct(...
            'numComponents', [], ...
            'numPredictions', [], ...
            'numUpdates', [], ...
            'numPrunes', [] ...
        )
    end
    
    methods
        function obj = FilterResult()
            % FILTERRESULT 构造函数
            
            obj.timeStamp = datetime('now');
        end
        
        function display(obj)
            % DISPLAY 显示结果摘要
            
            fprintf('\n===== 滤波结果 =====\n');
            fprintf('算法: %s v%s\n', obj.algorithmName, obj.algorithmVersion);
            fprintf('状态: %s\n', obj.status);
            
            if ~strcmp(obj.status, 'success')
                fprintf('执行时间: %.3f 秒\n', obj.executionTime);
                
                if ~isempty(obj.estimates.cardinality)
                    fprintf('平均估计目标数: %.1f\n', mean(obj.estimates.cardinality));
                end
                
                if isfield(obj.metrics, 'GOSPA') && ~isempty(obj.metrics.GOSPA.total)
                    fprintf('平均GOSPA误差: %.2f\n', mean(obj.metrics.GOSPA.total));
                end
            else
                fprintf('错误码: %d\n', obj.errorCode);
                fprintf('错误消息: %s\n', obj.message);
            end
            
            fprintf('==================\n\n');
        end
        
        function save(obj, filename)
            % SAVE 保存结果到文件
            
            resultStruct = obj.toStruct();
            save(filename, '-struct', 'resultStruct');
        end
        
        function s = toStruct(obj)
            % TOSTRUCT 转换为结构体
            
            props = properties(obj);
            s = struct();
            for i = 1:length(props)
                if ~isprop(obj, props{i}, 'Dependent')
                    s.(props{i}) = obj.(props{i});
                end
            end
        end
        
        function obj = fromStruct(obj, s)
            % FROMSTRUCT 从结构体创建结果
            
            fieldNames = fieldnames(s);
            for i = 1:length(fieldNames)
                if isprop(obj, fieldNames{i})
                    obj.(fieldNames{i}) = s.(fieldNames{i});
                end
            end
        end
        
        function success = isSuccess(obj)
            % ISSUCCESS 检查是否成功
            
            success = strcmp(obj.status, 'success') == 0;
        end
        
        function obj = setError(obj, errorCode, message)
            % SETERROR 设置错误信息
            
            obj.status = 'error';
            obj.errorCode = errorCode;
            obj.message = message;
        end
        
        function obj = setWarning(obj, message)
            % SETWARNING 设置警告信息
            
            obj.status = 'warning';
            obj.message = message;
        end
        
        function summary = getSummary(obj)
            % GETSUMMARY 获取结果摘要
            
            summary = struct();
            summary.algorithmName = obj.algorithmName;
            summary.status = obj.status;
            summary.executionTime = obj.executionTime;
            
            if ~isempty(obj.estimates.cardinality)
                summary.avgCardinality = mean(obj.estimates.cardinality);
            end
            
            if isfield(obj.metrics, 'GOSPA') && ~isempty(obj.metrics.GOSPA.total)
                summary.avgGOSPA = mean(obj.metrics.GOSPA.total);
            end
        end
    end
    
    methods (Static)
        function obj = load(filename)
            % LOAD 从文件加载结果
            
            data = load(filename);
            obj = FilterResult();
            obj = obj.fromStruct(data);
        end
    end
end
