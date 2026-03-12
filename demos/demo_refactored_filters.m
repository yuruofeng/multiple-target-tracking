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

fprintf('\n演示完成！\n');
