% demos/demo_refactored_filters.m
% 演示重构后的滤波器使用方法

%% 清理环境
clear; clc; close all;

%% 添加路径
addpath(genpath('..'));

%% 1. 创建配置
fprintf('=== 创建滤波器配置 ===\n');
config = utils.FilterConfig(...
    'detectionProb', 0.9, ...
    'survivalProb', 0.99, ...
    'pruningThreshold', 1e-5, ...
    'mergingThreshold', 0.1, ...
    'maxComponents', 100, ...
    'verbose', true);

% 添加必要的运动模型和测量模型参数
config.motionModel.F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
config.motionModel.Q = eye(4) * 0.1;
config.measurementModel.H = [1 0 0 0; 0 1 0 0];
config.measurementModel.R = eye(2) * 1;

% 添加新生模型参数
config.birthModel.means = zeros(4, 1);
config.birthModel.covs = eye(4);
config.birthModel.weights = 1;
config.birthModel.intensity = 0.005;

% 显示配置
config.display();

%% 2. 使用PHD工厂创建GM-PHD滤波器
fprintf('\n=== 使用PHD工厂创建滤波器 ===\n');

% 显示可用的滤波器类型
phd.PHDFactory.displayAvailableTypes();

% 创建GM-PHD滤波器
phdFilter = phd.PHDFactory.createFilter('GM-PHD', config);

%% 3. 使用预设配置创建滤波器
fprintf('\n=== 使用预设配置创建滤波器 ===\n');

% 创建高精度配置的滤波器
phdFilterHP = phd.PHDFactory.createFromPreset('high_precision');

%% 4. 创建GM-CPHD滤波器
fprintf('\n=== 创建GM-CPHD滤波器 ===\n');
cphdFilter = phd.PHDFactory.createFilter('GM-CPHD', config);

%% 5. 创建PMBM滤波器
fprintf('\n=== 创建PMBM滤波器 ===\n');

% 显示可用的PMBM滤波器类型
pmbm.PMBMFactory.displayAvailableTypes();

% 创建PMBM滤波器
pmbmFilter = pmbm.PMBMFactory.createFilter('PMBM', config);

%% 6. 演示统一接口
fprintf('\n=== 演示统一接口 ===\n');

% 所有滤波器都使用相同的接口
filters = {phdFilter, cphdFilter, pmbmFilter};
filterNames = {'GM-PHD', 'GM-CPHD', 'PMBM'};

fprintf('创建了 %d 个滤波器，它们都使用统一的接口\n', length(filters));
for i = 1:length(filters)
    fprintf('  - %s: %s\n', filterNames{i}, class(filters{i}));
end

%% 7. 演示错误处理
fprintf('\n=== 演示错误处理 ===\n');

try
    % 尝试创建不支持的滤波器类型
    invalidFilter = phd.PHDFactory.createFilter('INVALID', config);
catch ME
    fprintf('捕获到预期的异常:\n');
    if isa(ME, 'utils.MTTException')
        fprintf('  错误码: %d\n', ME.ErrorCode);
    end
    fprintf('  错误消息: %s\n', ME.message);
end

%% 8. 演示配置验证
fprintf('\n=== 演示配置验证 ===\n');

% 创建一个无效配置
invalidConfig = utils.FilterConfig();
invalidConfig.motionModel.F = [];  % 无效的运动模型

if ~invalidConfig.isValid
    fprintf('成功检测到无效配置\n');
end

%% 9. 总结
fprintf('\n=== 重构总结 ===\n');
fprintf('✓ M0: 项目包结构创建完成\n');
fprintf('✓ M1: 核心基础类实现完成\n');
fprintf('  - FilterConfig: 统一配置类\n');
fprintf('  - FilterResult: 统一结果类\n');
fprintf('  - MTTException: 统一异常处理\n');
fprintf('  - ErrorCode: 统一错误码\n');
fprintf('  - BaseFilter: 滤波器抽象基类\n');
fprintf('✓ M2: PHD滤波器重构完成\n');
fprintf('  - GMPHD: GM-PHD滤波器\n');
fprintf('  - GMCPHD: GM-CPHD滤波器\n');
fprintf('  - PHDFactory: PHD滤波器工厂\n');
fprintf('✓ M3: PMBM滤波器重构完成\n');
fprintf('  - PoissonComponent: 泊松分量\n');
fprintf('  - MBMComponent: 多伯努利混合分量\n');
fprintf('  - PMBM: PMBM滤波器\n');
fprintf('  - PMBMFactory: PMBM滤波器工厂\n');

fprintf('\n所有滤波器现在都使用统一的接口:\n');
fprintf('  1. 使用 FilterConfig 创建配置\n');
fprintf('  2. 使用工厂类创建滤波器\n');
fprintf('  3. 调用 run() 方法执行滤波\n');
fprintf('  4. 获取 FilterResult 结果对象\n');

%% 10. 性能指标计算与可视化
fprintf('\n=== 性能指标计算与可视化 ===\n');

% 生成测试数据
fprintf('生成测试数据...\n');
numTimeSteps = 50;
numTargets = 5;
measurements = struct();
measurements.timeStamps = 1:numTimeSteps;
measurements.measurements = cell(1, numTimeSteps);
groundTruth = struct();
groundTruth.states = cell(1, numTimeSteps);
groundTruth.births = cell(1, numTimeSteps);
groundTruth.deaths = cell(1, numTimeSteps);

% 生成目标轨迹和测量数据
for t = 1:numTimeSteps
    % 生成真实目标状态
    if t == 1
        % 初始化目标状态
        groundTruth.states{t} = zeros(4, numTargets);
        for i = 1:numTargets
            groundTruth.states{t}(:, i) = [rand()*1000; rand()*1000; (rand()-0.5)*10; (rand()-0.5)*10];
        end
    else
        % 状态转移
        F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
        Q = eye(4) * 0.1;
        groundTruth.states{t} = F * groundTruth.states{t-1} + mvnrnd(zeros(4, 1), Q, numTargets)';
    end
    
    % 生成测量数据
    z = [];
    H = [1 0 0 0; 0 1 0 0];
    R = eye(2) * 1;
    
    % 目标测量
    for i = 1:numTargets
        if rand() < config.detectionProb
            measurement = H * groundTruth.states{t}(:, i) + mvnrnd(zeros(2, 1), R)';
            z = [z, measurement];
        end
    end
    
    % 杂波
    numClutter = poissrnd(config.clutterRate);
    for i = 1:numClutter
        clutter = [rand()*1000; rand()*1000];
        z = [z, clutter];
    end
    
    measurements.measurements{t} = z;
end

% 运行所有滤波器
fprintf('运行滤波器...\n');
results = cell(1, length(filters));
for i = 1:length(filters)
    fprintf('  运行 %s 滤波器...\n', filterNames{i});
    results{i} = filters{i}.run(measurements, groundTruth);
end

% 计算性能指标
fprintf('计算性能指标...\n');
metrics = cell(1, length(filters));
gospa = metric.GOSPA('p', 2, 'c', 10, 'alpha', 2);

for i = 1:length(filters)
    metrics{i} = struct();
    metrics{i}.filterName = filterNames{i};
    metrics{i}.distance = zeros(1, numTimeSteps);
    metrics{i}.localisation = zeros(1, numTimeSteps);
    metrics{i}.missed = zeros(1, numTimeSteps);
    metrics{i}.false = zeros(1, numTimeSteps);
    
    % 检查滤波器是否执行成功
    if strcmp(results{i}.status, 'success')
        for t = 1:numTimeSteps
            % 获取估计结果
            estStates = zeros(4, 0);
            try
                if isfield(results{i}.estimates, 'states') && iscell(results{i}.estimates.states) && length(results{i}.estimates.states) >= t
                    estStates = results{i}.estimates.states{t};
                end
            catch
                % 发生错误时使用空状态
                estStates = zeros(4, 0);
            end
            
            % 获取真实值
            trueStates = groundTruth.states{t};
            
            % 只使用位置信息
            if size(estStates, 2) > 0
                estPos = estStates([1, 2], :);
            else
                estPos = zeros(2, 0);
            end
            
            if size(trueStates, 2) > 0
                truePos = trueStates([1, 2], :);
            else
                truePos = zeros(2, 0);
            end
            
            % 计算GOSPA
            [distance, ~, decomposition] = gospa.compute(truePos, estPos);
            metrics{i}.distance(t) = distance;
            metrics{i}.localisation(t) = decomposition.localisation;
            metrics{i}.missed(t) = decomposition.missed;
            metrics{i}.false(t) = decomposition.false;
        end
    else
        % 滤波器执行失败，使用默认值
        metrics{i}.distance = ones(1, numTimeSteps) * NaN;
        metrics{i}.localisation = ones(1, numTimeSteps) * NaN;
        metrics{i}.missed = ones(1, numTimeSteps) * NaN;
        metrics{i}.false = ones(1, numTimeSteps) * NaN;
        fprintf('  %s 滤波器执行失败，跳过性能指标计算\n', filterNames{i});
    end
end

% 可视化结果
fprintf('可视化结果...\n');
viz.TrackingVisualizer.visualizePerformance(metrics, groundTruth, results, 1:numTimeSteps);

% 显示性能指标
fprintf('\n性能指标汇总:\n');
for i = 1:length(metrics)
    fprintf('\n%s 滤波器:\n', metrics{i}.filterName);
    fprintf('  平均GOSPA距离: %.4f\n', mean(metrics{i}.distance));
    fprintf('  平均定位误差: %.4f\n', mean(metrics{i}.localisation));
    fprintf('  平均漏检误差: %.4f\n', mean(metrics{i}.missed));
    fprintf('  平均虚警误差: %.4f\n', mean(metrics{i}.false));
end

fprintf('\n演示完成！\n');
fprintf('\n性能指标可视化结果已生成，请查看生成的图形窗口。\n');
