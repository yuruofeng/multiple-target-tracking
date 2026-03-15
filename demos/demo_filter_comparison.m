% demos/demo_filter_comparison.m
% 一键式多目标跟踪滤波器性能对比基准
%
% 描述:
%   本脚本旨在提供一个标准化的测试平台，用于对比多种多目标跟踪滤波器的性能。
%   所有滤波器在统一的仿真场景下运行，以确保对比的公平性。
%
% 支持的滤波器类型:
%   PMBM家族: PMBM, PMB
%   TPMBM家族: TPMBM, TPMB
%   PHD家族: GMPHD, GMCPHD
%   TPHD家族: GMTPHD
%   CDFilter家族: CDPMBM, CDGMPHD, CDGMCPHD
%
% 功能:
%   1. 固定随机种子，保证结果的可复现性。
%   2. 在统一的仿真参数（如目标模型、杂波率、检测概率）下生成测试数据。
%   3. 通过激活选项选择要对比的滤波器。
%   4. 计算并记录每种算法的运行时间、GOSPA 误差和势估计误差。
%   5. 使用 metric.GOSPA 计算 GOSPA 指标。
%   6. 生成可视化图表。
%   7. 将所有量化性能指标输出为 MATLAB 表格。
%
% 前提条件:
%   - MATLAB R2020a 或更高版本。
%   - 相关的滤波器和工具函数已添加到 MATLAB 路径中。
%
%---

%% 清理与环境设置
clear; clc; close all;

% 添加必要的工具包路径
addpath(genpath('..'));

% 定义一个可重跑的接口
if ~exist('rerun_simulation', 'var')
    rerun_simulation = @() demo_filter_comparison;
end


%% --- 滤波器激活选项 ---
% 设置为true以启用对应滤波器的测试

% PMBM家族
enable.PMBM = true;
enable.PMB = true;

% TPMBM家族
enable.TPMBM = true;
enable.TPMB = true;

% PHD家族
enable.GMPHD = true;
enable.GMCPHD = true;

% TPHD家族 (轨迹PHD)
enable.GMTPHD = true;

% 连续-离散滤波器家族
enable.CDPMBM = false;      % 需要连续-离散模型配置
enable.CDGMPHD = false;     % 需要连续-离散模型配置
enable.CDGMCPHD = false;    % 需要连续-离散模型配置


%% --- 仿真核心参数 ---
% 使用固定的随机种子以保证结果的可复现性
rng(2024);

% 仿真总时长 (时间步)
simulation_duration = 100;

% 滤波器配置列表 (根据激活选项动态构建)
filter_configs = build_filter_configs(enable);

% 初始化结果存储结构
num_filters = length(filter_configs);
results = cell(num_filters, 1);
filter_names = cell(num_filters, 1);


%% --- 生成仿真数据 ---
fprintf('正在生成仿真数据...\n');

% 统一的仿真参数
sim_params = struct();
sim_params.simulation_duration = simulation_duration;
sim_params.num_targets = 5;
sim_params.clutter_rate = 15;
sim_params.detection_prob = 0.95;
sim_params.survival_prob = 0.99;
sim_params.surveillance_area = [-1000, 1000; -1000, 1000];

% 运动和测量模型
motion_model = struct('F', [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1], 'Q', eye(4) * 0.5);
measurement_model = struct('H', [1 0 0 0; 0 1 0 0], 'R', eye(2) * 5);

% 生成测试数据
[measurements, ground_truth] = generate_test_data(sim_params, motion_model, measurement_model);

fprintf('仿真数据生成完毕。\n\n');


%% --- 运行滤波器对比测试 ---
fprintf('开始运行滤波器对比测试...\n');

for i = 1:num_filters
    config = filter_configs{i};
    filter_names{i} = config.name;
    
    fprintf('--- 正在测试: %s ---\n', config.name);
    
    % 创建滤波器配置参数
    filter_config = utils.FilterConfig();
    filter_config.detectionProb = sim_params.detection_prob;
    filter_config.survivalProb = sim_params.survival_prob;
    filter_config.clutterRate = sim_params.clutter_rate;
    filter_config.surveillanceArea = sim_params.surveillance_area(1,:);
    filter_config.motionModel = motion_model;
    filter_config.measurementModel = measurement_model;

    % 添加必需的birth模型（已优化参数）
    % 注意：不同滤波器对birthModel的字段名有不同要求
    % PMBM/TPMBM使用PoissonComponent，需要means/covs/weights (复数)
    % PMB/TPMB直接访问，需要mean/cov/existProb (单数)
    %
    % 参数优化说明：
    % - intensity: 0.005 → 0.05 (提高10倍，增加新生目标检测能力)
    % - existProb: 0.01 → 0.1 (提高10倍，增加初始航迹置信度)
    % - cov: 使用更大的初始不确定性，允许目标在更大范围内出现
    filter_config.birthModel = struct(...
        'type', 'Poisson', ...
        'intensity', 0.05, ...         % 优化：提高birth强度，更容易初始化航迹
        'means', [0; 0; 0; 0], ...     % PMBM/TPMBM用
        'covs', eye(4) * 200, ...      % 优化：增大初始协方差，覆盖更大区域
        'weights', 1, ...              % PMBM/TPMBM用
        'mean', [0; 0; 0; 0], ...      % PMB/TPMB用
        'cov', eye(4) * 200, ...       % 优化：增大初始协方差
        'existProb', 0.1 ...           % 优化：提高初始存在概率，避免过早剪枝
    );

    % 设置更宽松的滤波器参数，避免过早剪枝航迹
    filter_config.pruningThreshold = 1e-6;      % 优化：降低剪枝阈值，保留弱航迹
    filter_config.existenceThreshold = 1e-5;    % 优化：降低存在阈值
    filter_config.maxComponents = 200;          % 优化：增加最大分量数
    filter_config.gatingThreshold = 30;         % 优化：增大门控阈值，接受更多量测
    filter_config.verbose = false;              % 关闭详细输出

    % 为TPMBM滤波器添加特定的参数
    if strcmp(config.type, 'TPMBM')
        filter_config.extraParams.gateSize = 9.210;
        filter_config.extraParams.maxGlobalHypotheses = 1000;
        filter_config.extraParams.minGlobalHypothesisWeight = 1e-4;
        filter_config.extraParams.numMinimumAssignment = 100;
        filter_config.extraParams.minEndTimeProbability = 1e-4;
        filter_config.extraParams.minBirthTimeProbability = 1e-1;
        filter_config.extraParams.minExistenceProbability = 1e-4;
        filter_config.extraParams.totalTimeSteps = simulation_duration;
    end

    % 为GMTPHD滤波器添加特定的参数
    if strcmp(config.type, 'GMTPHD')
        filter_config.extraParams.Lscan = 5;
        filter_config.extraParams.maxComponents = 30;
        filter_config.extraParams.absorptionThreshold = 4;
    end

    % 创建滤波器
    try
        % 根据配置中指定的工厂创建滤波器
        switch config.factory
            case 'pmbm.PMBMFactory'
                filter = pmbm.PMBMFactory.createFilter(config.type, filter_config);
            case 'tpmbm.TPMBMFactory'
                filter = tpmbm.TPMBMFactory.createFilter(config.type, filter_config);
            case 'tpmbm.TPMBFactory'
                filter = tpmbm.TPMBFactory.createFilter(config.type, filter_config);
            case 'phd.PHDFactory'
                filter = phd.PHDFactory.createFilter(config.type, filter_config);
            case 'tphd.TPHDFactory'
                filter = tphd.TPHDFactory.createFilter(config.type, filter_config);
            case 'cdfilters.CDFilterFactory'
                filter = cdfilters.CDFilterFactory.create(config.type, filter_config);
            otherwise
                error('未知的工厂: %s', config.factory);
        end

    catch ME
        fprintf('错误: 无法创建滤波器 "%s"。\n', config.name);
        fprintf('错误信息: %s\n', ME.message);
        fprintf('错误标识符: %s\n', ME.identifier);
        if isa(ME, 'utils.MTTException')
            fprintf('错误码: %d\n', ME.ErrorCode);
        end
        fprintf('工厂: %s, 类型: %s\n', config.factory, config.type);
        results{i} = create_empty_result(config.name, simulation_duration);
        continue;
    end

    % 运行滤波器
    start_time = tic;
    try
        result = filter.run(measurements);
        run_time = toc(start_time);
    catch ME
        fprintf('错误: 滤波器 "%s" 运行时发生错误。\n', config.name);
        fprintf('错误信息: %s\n', ME.message);
        fprintf('错误标识符: %s\n', ME.identifier);
        fprintf('错误堆栈:\n');
        for stack_i = 1:length(ME.stack)
            fprintf('  [%d] %s (文件: %s, 行: %d)\n', ...
                stack_i, ME.stack(stack_i).name, ME.stack(stack_i).file, ME.stack(stack_i).line);
        end
        results{i} = create_empty_result(config.name, simulation_duration);
        continue;
    end
    
    % --- 性能评估 ---
    fprintf('正在评估性能...\n');
    
    gospa_metrics = zeros(simulation_duration, 4);
    cardinality_error = zeros(simulation_duration, 1);
    estimated_cardinality = zeros(simulation_duration, 1);
    
    % 检查result对象结构
    if ~isa(result, 'utils.FilterResult')
        fprintf('错误: 滤波器返回的不是FilterResult对象\n');
        results{i} = create_empty_result(config.name, simulation_duration);
        continue;
    end

    % 检查滤波器是否执行成功
    if strcmp(result.status, 'error')
        fprintf('错误: 滤波器 "%s" 执行失败。\n', config.name);
        fprintf('错误码: %d\n', result.errorCode);
        fprintf('错误消息: %s\n', result.message);
        if isfield(result, 'diagnostics') && isfield(result.diagnostics, 'errorStack')
            fprintf('错误堆栈:\n');
            for stack_i = 1:length(result.diagnostics.errorStack)
                fprintf('  [%d] %s (文件: %s, 行: %d)\n', ...
                    stack_i, result.diagnostics.errorStack(stack_i).name, ...
                    result.diagnostics.errorStack(stack_i).file, ...
                    result.diagnostics.errorStack(stack_i).line);
            end
        end
        results{i} = create_empty_result(config.name, simulation_duration);
        continue;
    end
    
    for t = 1:simulation_duration
        gt_states = ground_truth.states{t};
        
        est_states = [];
        try
            estimates_data = result.estimates;
            
            if isfield(estimates_data, 'estimatesList')
                estimates_list = estimates_data.estimatesList;
                
                if iscell(estimates_list) && t <= numel(estimates_list) && ~isempty(estimates_list{t})
                    est_item = estimates_list{t};
                    
                    if isstruct(est_item) && isfield(est_item, 'states')
                        extracted_states = est_item.states;
                        
                        if isnumeric(extracted_states) && size(extracted_states, 2) > 0
                            est_states = extracted_states;
                        end
                    end
                end
            end
        catch ME
            est_states = [];
        end
        
        try
            [gospa_metrics(t,1), ~, gospa_decomposed] = metric.GOSPA.run(est_states, gt_states, 'p', 2, 'c', 100, 'alpha', 2);
            gospa_metrics(t,2) = gospa_decomposed.localisation;
            gospa_metrics(t,3) = gospa_decomposed.missed;
            gospa_metrics(t,4) = gospa_decomposed.false;
        catch ME
            gospa_metrics(t,:) = NaN;
        end
        
        true_card = size(gt_states, 2);
        est_card = size(est_states, 2);
        estimated_cardinality(t) = est_card;
        cardinality_error(t) = abs(true_card - est_card);
    end
    
    % 存储结果
    results{i} = struct( ...
        'name', config.name, ...
        'run_time', run_time, ...
        'gospa_metrics', gospa_metrics, ...
        'cardinality_error', cardinality_error, ...
        'estimated_cardinality', estimated_cardinality ...
    );
    
    fprintf('测试完成 (总耗时: %.2f 秒)。\n\n', run_time);
end

fprintf('所有滤波器测试完毕。\n');


%% --- 结果可视化 ---
fprintf('正在生成可视化图表...\n');

% 图一：GOSPA 曲线对比
figure('Name', 'GOSPA 误差对比', 'NumberTitle', 'off', 'Position', [100, 600, 800, 400]);
hold on;
colors = lines(num_filters);
for i = 1:num_filters
    if ~isempty(results{i})
        plot(1:simulation_duration, results{i}.gospa_metrics(:,1), 'LineWidth', 1.5, 'Color', colors(i,:), 'DisplayName', results{i}.name);
    end
end
hold off;
title('GOSPA 误差随时间变化曲线');
xlabel('时间步');
ylabel('GOSPA 误差');
legend('show', 'Location', 'northwest');
grid on;
set(gca, 'FontSize', 12);

% 图二：多维度性能对比
figure('Name', '多维度性能对比', 'NumberTitle', 'off', 'Position', [950, 200, 600, 800]);

% 子图 1: 势估计对比
subplot(3, 1, 1);
hold on;
true_cardinality = zeros(simulation_duration, 1);
for t = 1:simulation_duration
    true_cardinality(t) = size(ground_truth.states{t}, 2);
end
plot(1:simulation_duration, true_cardinality, 'k--', 'LineWidth', 2, 'DisplayName', '真实目标数');
for i = 1:num_filters
    if ~isempty(results{i})
        plot(1:simulation_duration, results{i}.estimated_cardinality, 'LineWidth', 1.5, 'Color', colors(i,:), 'DisplayName', results{i}.name);
    end
end
hold off;
title('目标数估计对比');
xlabel('时间步');
ylabel('目标数');
legend('show', 'Location', 'best');
grid on;

% 子图 2: GOSPA分量对比
subplot(3, 1, 2);
avg_loc = zeros(num_filters, 1);
avg_missed = zeros(num_filters, 1);
avg_false = zeros(num_filters, 1);
for i = 1:num_filters
    if ~isempty(results{i})
        avg_loc(i) = mean(results{i}.gospa_metrics(:,2), 'omitnan');
        avg_missed(i) = mean(results{i}.gospa_metrics(:,3), 'omitnan');
        avg_false(i) = mean(results{i}.gospa_metrics(:,4), 'omitnan');
    end
end
bar_data = [avg_loc, avg_missed, avg_false];
b = bar(bar_data);
title('平均 GOSPA 分量对比');
xlabel('滤波器');
ylabel('误差');
set(gca, 'XTickLabel', filter_names);
legend({'定位误差', '漏检误差', '误报误差'}, 'Location', 'best');
grid on;

% 子图 3: 运行时间对比
subplot(3, 1, 3);
run_times = zeros(num_filters, 1);
for i = 1:num_filters
    if ~isempty(results{i})
        run_times(i) = results{i}.run_time;
    end
end
b = bar(run_times);
title('总运行时间对比');
xlabel('滤波器');
ylabel('时间 (秒)');
set(gca, 'XTickLabel', filter_names);
grid on;

fprintf('可视化图表生成完毕。\n\n');

% --- 性能指标量化总结 ---
fprintf('--- 性能指标量化总结 ---\n');

% 使用omitnan避免NaN传播
avg_gospa = cellfun(@(r) mean(r.gospa_metrics(:,1), 'omitnan'), results);
avg_card_error = cellfun(@(r) mean(r.cardinality_error), results);
total_run_time = cellfun(@(r) r.run_time, results);

% 创建表格
summary_table = table(filter_names, total_run_time, avg_gospa, avg_card_error, ...
    'VariableNames', {'滤波器', '总运行时间_秒', '平均GOSPA', '平均势误差'});

% 显示表格
disp(summary_table);


%% --- 辅助函数 ---

function [measurements, ground_truth] = generate_test_data(params, motion_model, measurement_model)
    % 从参数结构体中提取参数
    duration = params.simulation_duration;
    surveillance_area = params.surveillance_area;
    
    % 初始化状态和量测容器
    target_states = cell(duration, 1);
    measurements.timeStamps = 1:duration;
    measurements.measurements = cell(1, duration);

    % 初始目标状态
    initial_states = [
        0, 0, 10, 0;
        400, -300, -5, 8;
        -500, 500, 6, -6;
        -200, 600, -8, -4;
        700, -100, -10, 5
    ]';
    
    birth_times = [1, 10, 20, 30, 40];
    death_times = [80, 70, 90, 85, 95];

    % 仿真循环
    for t = 1:duration
        % --- 目标状态演化 ---
        live_targets = [];
        if t > 1
            prev_states = target_states{t-1};
            for i = 1:size(prev_states, 2)
                % 目标存活
                if rand() < params.survival_prob
                    % 运动传播
                    new_state = motion_model.F * prev_states(:, i) + sqrtm(motion_model.Q) * randn(4, 1);
                    live_targets = [live_targets, new_state];
                end
            end
        end
        
        % --- 目标新生 ---
        for i = 1:length(birth_times)
            if t == birth_times(i)
                live_targets = [live_targets, initial_states(:,i)];
            end
        end
        
        % --- 目标死亡 (通过时间控制) ---
        current_targets = [];
        for i = 1:size(live_targets, 2)
            is_dead = false;
            for j = 1:length(birth_times)
                if all(live_targets(:,i) == initial_states(:,j)) && t >= death_times(j)
                    is_dead = true;
                    break;
                end
            end
            if ~is_dead
                current_targets = [current_targets, live_targets(:,i)];
            end
        end
        
        target_states{t} = current_targets;

        % --- 生成量测 ---
        z = [];
        if ~isempty(target_states{t})
            for i = 1:size(target_states{t}, 2)
                if rand() < params.detection_prob
                    % 生成目标量测
                    measurement = measurement_model.H * target_states{t}(:, i) + sqrtm(measurement_model.R) * randn(2, 1);
                    z = [z, measurement];
                end
            end
        end
        
        % --- 生成杂波 ---
        num_clutter = poissrnd(params.clutter_rate);
        clutter = [
            rand(1, num_clutter) * (surveillance_area(1,2) - surveillance_area(1,1)) + surveillance_area(1,1);
            rand(1, num_clutter) * (surveillance_area(2,2) - surveillance_area(2,1)) + surveillance_area(2,1)
        ];
        z = [z, clutter];
        
        measurements.measurements{t} = z;
    end
    
    ground_truth.states = target_states;
end

function empty_result = create_empty_result(name, duration)
    % 创建一个空的结构体，用于在滤波器运行失败时填充
    empty_result = struct( ...
        'name', name, ...
        'run_time', NaN, ...
        'gospa_metrics', NaN(duration, 4), ...
        'cardinality_error', NaN(duration, 1), ...
        'estimated_cardinality', NaN(duration, 1) ...
    );
end

function configs = build_filter_configs(enable)
    % BUILD_FILTER_CONFIGS 根据激活选项构建滤波器配置列表
    %
    % 输入:
    %   enable - 包含各滤波器激活状态的结构体
    %
    % 输出:
    %   configs - 滤波器配置元胞数组

    configs = {};

    % PMBM家族
    if isfield(enable, 'PMBM') && enable.PMBM
        configs{end+1} = struct('name', 'PMBM', 'factory', 'pmbm.PMBMFactory', 'type', 'PMBM');
    end
    if isfield(enable, 'PMB') && enable.PMB
        configs{end+1} = struct('name', 'PMB', 'factory', 'pmbm.PMBMFactory', 'type', 'PMB');
    end

    % TPMBM家族
    if isfield(enable, 'TPMBM') && enable.TPMBM
        configs{end+1} = struct('name', 'TPMBM', 'factory', 'tpmbm.TPMBMFactory', 'type', 'TPMBM');
    end
    if isfield(enable, 'TPMB') && enable.TPMB
        configs{end+1} = struct('name', 'TPMB', 'factory', 'tpmbm.TPMBFactory', 'type', 'TPMB');
    end

    % PHD家族
    if isfield(enable, 'GMPHD') && enable.GMPHD
        configs{end+1} = struct('name', 'GMPHD', 'factory', 'phd.PHDFactory', 'type', 'GMPHD');
    end
    if isfield(enable, 'GMCPHD') && enable.GMCPHD
        configs{end+1} = struct('name', 'GMCPHD', 'factory', 'phd.PHDFactory', 'type', 'GMCPHD');
    end

    % TPHD家族 (轨迹PHD)
    if isfield(enable, 'GMTPHD') && enable.GMTPHD
        configs{end+1} = struct('name', 'GMTPHD', 'factory', 'tphd.TPHDFactory', 'type', 'GMTPHD');
    end

    % 连续-离散滤波器家族
    if isfield(enable, 'CDPMBM') && enable.CDPMBM
        configs{end+1} = struct('name', 'CDPMBM', 'factory', 'cdfilters.CDFilterFactory', 'type', 'cd_pmbm');
    end
    if isfield(enable, 'CDGMPHD') && enable.CDGMPHD
        configs{end+1} = struct('name', 'CDGMPHD', 'factory', 'cdfilters.CDFilterFactory', 'type', 'cd_gmphd');
    end
    if isfield(enable, 'CDGMCPHD') && enable.CDGMCPHD
        configs{end+1} = struct('name', 'CDGMCPHD', 'factory', 'cdfilters.CDFilterFactory', 'type', 'cd_gmcphd');
    end
end

% --- 脚本末尾 ---
fprintf('\n仿真与分析全部完成。\n');
fprintf('您可以调用 rerun_simulation() 函数以相同的参数重新运行此脚本。\n');
