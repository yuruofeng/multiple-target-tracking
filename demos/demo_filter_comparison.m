% demos/demo_filter_comparison.m
% 滤波器通用对比演示应用
% 支持多种滤波器的性能对比和可视化

%% 清理环境
clear; clc; close all;

%% 添加路径
addpath(genpath('..'));

%% 主函数
function main()
    % 显示欢迎信息
    display_welcome();
    
    % 初始化应用
    app = init_app();
    
    % 主循环
    while true
        % 显示主菜单
        choice = display_main_menu();
        
        switch choice
            case 1
                % 配置对比参数
                configure_comparison(app);
            case 2
                % 运行对比测试
                run_comparison(app);
            case 3
                % 可视化结果
                visualize_results(app);
            case 4
                % 导出结果
                export_results(app);
            case 5
                % 退出应用
                fprintf('感谢使用滤波器对比演示应用！\n');
                break;
            otherwise
                fprintf('无效选择，请重新输入。\n');
        end
    end
end

%% 显示欢迎信息
function display_welcome()
fprintf('=====================================\n');
fprintf('   滤波器通用对比演示应用\n');
fprintf('=====================================\n');
fprintf('本应用支持多种多目标跟踪滤波器的对比分析\n');
fprintf('可以测试不同滤波器的性能、资源占用等指标\n');
fprintf('并提供多样化的可视化结果展示\n');
fprintf('=====================================\n\n');
end

%% 初始化应用
function app = init_app()
    % 创建应用结构体
    app = struct();
    
    % 可用的滤波器类型
    app.available_filters = get_available_filters();
    
    % 默认对比参数
    app.params = struct();
    app.params.selected_filters = {};
    app.params.num_runs = 10; % 每个滤波器运行次数
    app.params.simulation_duration = 100; % 模拟时长
    app.params.num_targets = 5; % 目标数量
    app.params.clutter_rate = 10; % 杂波率
    app.params.detection_prob = 0.9; % 检测概率
    app.params.survival_prob = 0.99; % 存活概率
    
    % 性能结果
    app.results = struct();
    app.results.execution_times = {};
    app.results.memory_usage = {};
    app.results.tracking_accuracy = {};
    
    % 可视化选项
    app.visualization = struct();
    app.visualization.show_execution_time = true;
    app.visualization.show_memory_usage = true;
    app.visualization.show_tracking_accuracy = true;
    app.visualization.show_trajectories = true;
    
    fprintf('应用初始化完成！\n');
    fprintf('可用滤波器数量: %d\n\n', length(app.available_filters));
end

%% 获取可用的滤波器类型
function filters = get_available_filters()
    % 收集所有可用的滤波器类型
    filters = struct();
    
    % PHD滤波器
    filters.phd = struct();
    filters.phd.name = 'PHD滤波器';
    filters.phd.types = phd.PHDFactory.getAvailableTypes();
    filters.phd.factory = @phd.PHDFactory.createFilter;
    
    % PMBM滤波器
    filters.pmbm = struct();
    filters.pmbm.name = 'PMBM滤波器';
    filters.pmbm.types = pmbm.PMBMFactory.getAvailableTypes();
    filters.pmbm.factory = @pmbm.PMBMFactory.createFilter;
    
    % TPMBM滤波器
    filters.tpmbm = struct();
    filters.tpmbm.name = 'TPMBM滤波器';
    filters.tpmbm.types = tpmbm.TPMBMFactory.getAvailableTypes();
    filters.tpmbm.factory = @tpmbm.TPMBMFactory.createFilter;
    
    % 连续-离散滤波器
    filters.cd = struct();
    filters.cd.name = '连续-离散滤波器';
    filters.cd.types = cdfilters.CDFilterFactory.getAvailableTypes();
    filters.cd.factory = @cdfilters.CDFilterFactory.createFilter;
end

%% 显示主菜单
function choice = display_main_menu()
fprintf('\n主菜单:\n');
fprintf('1. 配置对比参数\n');
fprintf('2. 运行对比测试\n');
fprintf('3. 可视化结果\n');
fprintf('4. 导出结果\n');
fprintf('5. 退出应用\n');

choice = input('请输入选择 (1-5): ');
end

%% 配置对比参数
function configure_comparison(app)
fprintf('\n=== 配置对比参数 ===\n');

% 选择滤波器
fprintf('\n可用滤波器类型:\n');
filter_idx = 1;
filter_options = {};

for filter_group_name = fieldnames(app.available_filters)'
    filter_group = app.available_filters.(filter_group_name{1});
    fprintf('\n%s:\n', filter_group.name);
    for i = 1:length(filter_group.types)
        fprintf('%d. %s\n', filter_idx, filter_group.types{i});
        filter_options{filter_idx} = struct('group', filter_group_name{1}, 'type', filter_group.types{i});
        filter_idx = filter_idx + 1;
    end
end

% 让用户选择滤波器
fprintf('\n请输入要对比的滤波器编号（多个编号用空格分隔）: ');
selected_indices = input('');

app.params.selected_filters = {};
for i = 1:length(selected_indices)
    idx = selected_indices(i);
    if idx >= 1 && idx <= length(filter_options)
        app.params.selected_filters{end+1} = filter_options{idx};
    end
end

% 配置模拟参数
fprintf('\n配置模拟参数:\n');
app.params.num_runs = input('每个滤波器运行次数: ', 's');
app.params.num_runs = str2double(app.params.num_runs);
if isnan(app.params.num_runs) || app.params.num_runs < 1
    app.params.num_runs = 10;
end

app.params.simulation_duration = input('模拟时长: ', 's');
app.params.simulation_duration = str2double(app.params.simulation_duration);
if isnan(app.params.simulation_duration) || app.params.simulation_duration < 1
    app.params.simulation_duration = 100;
end

app.params.num_targets = input('目标数量: ', 's');
app.params.num_targets = str2double(app.params.num_targets);
if isnan(app.params.num_targets) || app.params.num_targets < 1
    app.params.num_targets = 5;
end

app.params.clutter_rate = input('杂波率: ', 's');
app.params.clutter_rate = str2double(app.params.clutter_rate);
if isnan(app.params.clutter_rate) || app.params.clutter_rate < 0
    app.params.clutter_rate = 10;
end

app.params.detection_prob = input('检测概率: ', 's');
app.params.detection_prob = str2double(app.params.detection_prob);
if isnan(app.params.detection_prob) || app.params.detection_prob < 0 || app.params.detection_prob > 1
    app.params.detection_prob = 0.9;
end

app.params.survival_prob = input('存活概率: ', 's');
app.params.survival_prob = str2double(app.params.survival_prob);
if isnan(app.params.survival_prob) || app.params.survival_prob < 0 || app.params.survival_prob > 1
    app.params.survival_prob = 0.99;
end

% 配置可视化选项
fprintf('\n配置可视化选项:\n');
app.visualization.show_execution_time = input('显示执行时间对比 (1=是, 0=否): ');
app.visualization.show_memory_usage = input('显示内存使用对比 (1=是, 0=否): ');
app.visualization.show_tracking_accuracy = input('显示跟踪精度对比 (1=是, 0=否): ');
app.visualization.show_trajectories = input('显示轨迹对比 (1=是, 0=否): ');

fprintf('\n配置完成！\n');
end

%% 运行对比测试
function run_comparison(app)
if isempty(app.params.selected_filters)
    fprintf('请先选择要对比的滤波器！\n');
    return;
end

fprintf('\n=== 运行对比测试 ===\n');

% 重置结果
app.results.execution_times = {};
app.results.memory_usage = {};
app.results.tracking_accuracy = {};

% 为每个选中的滤波器运行测试
for i = 1:length(app.params.selected_filters)
    filter_info = app.params.selected_filters{i};
    filter_group = app.available_filters.(filter_info.group);
    filter_type = filter_info.type;
    
    fprintf('\n测试 %s - %s\n', filter_group.name, filter_type);
    
    % 初始化结果数组
    exec_times = zeros(1, app.params.num_runs);
    memory_usages = zeros(1, app.params.num_runs);
    accuracies = zeros(1, app.params.num_runs);
    
    % 运行多次测试
    for run = 1:app.params.num_runs
        fprintf('  运行 %d/%d...', run, app.params.num_runs);
        
        % 创建配置
        config = create_filter_config(app.params);
        
        % 创建滤波器
        try
            filter = filter_group.factory(filter_type, config);
        catch ME
            fprintf('  错误: %s\n', ME.message);
            continue;
        end
        
        % 生成测试数据
        [measurements, ground_truth] = generate_test_data(app.params);
        
        % 测量执行时间
        start_time = tic;
        
        % 测量内存使用
        memory_before = memory;
        
        % 运行滤波器
        result = filter.run(measurements, ground_truth);
        
        % 计算执行时间
        exec_times(run) = toc(start_time);
        
        % 计算内存使用
        memory_after = memory;
        memory_usages(run) = memory_after.MemUsedMATLAB - memory_before.MemUsedMATLAB;
        
        % 计算跟踪精度
        accuracies(run) = calculate_tracking_accuracy(result, ground_truth);
        
        fprintf('  完成\n');
    end
    
    % 存储结果
    app.results.execution_times{i} = struct('filter', [filter_group.name, ' - ', filter_type], 'times', exec_times);
    app.results.memory_usage{i} = struct('filter', [filter_group.name, ' - ', filter_type], 'usage', memory_usages);
    app.results.tracking_accuracy{i} = struct('filter', [filter_group.name, ' - ', filter_type], 'accuracy', accuracies);
end

fprintf('\n对比测试完成！\n');
end

%% 创建滤波器配置
function config = create_filter_config(params)
config = utils.FilterConfig();

% 基本参数
config.detectionProb = params.detection_prob;
config.survivalProb = params.survival_prob;
config.clutterRate = params.clutter_rate;
config.surveillanceArea = [1000, 1000];
config.pruningThreshold = 1e-5;
config.maxComponents = 100;
config.existenceThreshold = 1e-5;

% 运动模型 (CV模型)
config.motionModel.F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
config.motionModel.Q = eye(4) * 0.1;

% 测量模型
config.measurementModel.H = [1 0 0 0; 0 1 0 0];
config.measurementModel.R = eye(2) * 1;

% 新生模型
config.birthModel.means = zeros(4, 1);
config.birthModel.covs = eye(4);
config.birthModel.weights = 1;
config.birthModel.intensity = 0.005;
end

%% 生成测试数据
function [measurements, ground_truth] = generate_test_data(params)
% 生成目标轨迹
num_targets = params.num_targets;
duration = params.simulation_duration;

% 初始化目标状态
target_states = cell(duration, 1);
target_births = cell(duration, 1);
target_deaths = cell(duration, 1);

% 生成目标轨迹
for t = 1:duration
    % 初始化当前时刻的目标状态
    target_states{t} = [];
    target_births{t} = [];
    target_deaths{t} = [];
    
    % 处理目标出生
    if t == 1 || (t > 1 && rand() < 0.1) % 10%的概率有新目标出生
        num_new_targets = randi(2); % 最多2个新目标
        for i = 1:num_new_targets
            if length(target_states{t}) < num_targets
                % 随机初始位置
                x0 = rand() * 800 + 100;
                y0 = rand() * 800 + 100;
                vx0 = (rand() - 0.5) * 10;
                vy0 = (rand() - 0.5) * 10;
                
                new_state = [x0; y0; vx0; vy0];
                target_states{t} = [target_states{t}, new_state];
                target_births{t} = [target_births{t}, length(target_states{t})];
            end
        end
    else
        % 复制上一时刻的目标状态
        if t > 1
            target_states{t} = target_states{t-1};
        end
    end
    
    % 处理目标运动
    if ~isempty(target_states{t})
        F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
        Q = eye(4) * 0.1;
        
        for i = 1:size(target_states{t}, 2)
            % 状态转移
            target_states{t}(:, i) = F * target_states{t}(:, i) + mvnrnd(zeros(4, 1), Q)';
            
            % 处理目标死亡
            if rand() > params.survival_prob
                target_deaths{t} = [target_deaths{t}, i];
            end
        end
        
        % 移除死亡的目标
        if ~isempty(target_deaths{t})
            target_states{t}(:, target_deaths{t}) = [];
        end
    end
end

% 生成测量数据
measurements = cell(duration, 1);
for t = 1:duration
    % 初始化测量
    z = [];
    
    % 生成目标测量
    if ~isempty(target_states{t})
        H = [1 0 0 0; 0 1 0 0];
        R = eye(2) * 1;
        
        for i = 1:size(target_states{t}, 2)
            if rand() < params.detection_prob
                % 生成测量
                measurement = H * target_states{t}(:, i) + mvnrnd(zeros(2, 1), R)';
                z = [z, measurement];
            end
        end
    end
    
    % 生成杂波
    num_clutter = poissrnd(params.clutter_rate);
    for i = 1:num_clutter
        clutter = [rand() * 1000; rand() * 1000];
        z = [z, clutter];
    end
    
    measurements{t} = z;
end

% 构建地面真值
ground_truth = struct();
ground_truth.states = target_states;
ground_truth.births = target_births;
ground_truth.deaths = target_deaths;
end

%% 计算跟踪精度
function accuracy = calculate_tracking_accuracy(result, ground_truth)
% 使用GOSPA度量计算跟踪精度
if ~isfield(result, 'estimates') || isempty(result.estimates)
    accuracy = 0;
    return;
end

% 简单计算 - 实际应用中应使用完整的GOSPA计算
num_estimates = length(result.estimates);
num_ground_truth = 0;
for t = 1:length(ground_truth.states)
    num_ground_truth = num_ground_truth + size(ground_truth.states{t}, 2);
end

% 计算准确率
if num_ground_truth > 0
    accuracy = 1 - abs(num_estimates - num_ground_truth) / num_ground_truth;
else
    accuracy = 0;
end
end

%% 可视化结果
function visualize_results(app)
if isempty(app.results.execution_times)
    fprintf('请先运行对比测试！\n');
    return;
end

fprintf('\n=== 可视化结果 ===\n');

% 创建图形窗口
figure('Name', '滤波器对比结果', 'Position', [100, 100, 1200, 800]);

% 子图计数
subplot_idx = 1;
num_subplots = 0;

% 计算需要的子图数量
if app.visualization.show_execution_time
    num_subplots = num_subplots + 1;
end
if app.visualization.show_memory_usage
    num_subplots = num_subplots + 1;
end
if app.visualization.show_tracking_accuracy
    num_subplots = num_subplots + 1;
end
if app.visualization.show_trajectories
    num_subplots = num_subplots + 1;
end

% 确定子图布局
if num_subplots <= 2
    [rows, cols] = deal(1, num_subplots);
elseif num_subplots <= 4
    [rows, cols] = deal(2, 2);
else
    [rows, cols] = deal(3, ceil(num_subplots/3));
end

% 执行时间对比
if app.visualization.show_execution_time && ~isempty(app.results.execution_times)
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    filter_names = {};
    avg_times = [];
    std_times = [];
    
    for i = 1:length(app.results.execution_times)
        result = app.results.execution_times{i};
        filter_names{end+1} = result.filter;
        avg_times(end+1) = mean(result.times);
        std_times(end+1) = std(result.times);
    end
    
    bar(avg_times);
    errorbar(avg_times, std_times, '.');
    set(gca, 'XTickLabel', filter_names, 'XTick', 1:length(filter_names));
    xtickangle(45);
    title('执行时间对比 (秒)');
    xlabel('滤波器');
    ylabel('平均执行时间');
    grid on;
end

% 内存使用对比
if app.visualization.show_memory_usage && ~isempty(app.results.memory_usage)
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    filter_names = {};
    avg_memory = [];
    std_memory = [];
    
    for i = 1:length(app.results.memory_usage)
        result = app.results.memory_usage{i};
        filter_names{end+1} = result.filter;
        avg_memory(end+1) = mean(result.usage);
        std_memory(end+1) = std(result.usage);
    end
    
    bar(avg_memory);
    errorbar(avg_memory, std_memory, '.');
    set(gca, 'XTickLabel', filter_names, 'XTick', 1:length(filter_names));
    xtickangle(45);
    title('内存使用对比 (MB)');
    xlabel('滤波器');
    ylabel('平均内存使用');
    grid on;
end

% 跟踪精度对比
if app.visualization.show_tracking_accuracy && ~isempty(app.results.tracking_accuracy)
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    filter_names = {};
    avg_accuracy = [];
    std_accuracy = [];
    
    for i = 1:length(app.results.tracking_accuracy)
        result = app.results.tracking_accuracy{i};
        filter_names{end+1} = result.filter;
        avg_accuracy(end+1) = mean(result.accuracy);
        std_accuracy(end+1) = std(result.accuracy);
    end
    
    bar(avg_accuracy);
    errorbar(avg_accuracy, std_accuracy, '.');
    set(gca, 'XTickLabel', filter_names, 'XTick', 1:length(filter_names));
    xtickangle(45);
    title('跟踪精度对比');
    xlabel('滤波器');
    ylabel('平均精度');
    ylim([0, 1]);
    grid on;
end

% 轨迹对比
if app.visualization.show_trajectories
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    % 这里应该显示轨迹对比
    % 由于需要实际的轨迹数据，这里仅作占位
    plot(0, 0);
    title('轨迹对比');
    xlabel('X');
    ylabel('Y');
    grid on;
    legend('真值轨迹', '估计轨迹');
end

% 调整布局
tightlayout;

fprintf('可视化完成！\n');
end

%% 导出结果
function export_results(app)
if isempty(app.results.execution_times)
    fprintf('请先运行对比测试！\n');
    return;
end

fprintf('\n=== 导出结果 ===\n');

% 选择导出格式
fprintf('导出格式:\n');
fprintf('1. CSV文件\n');
fprintf('2. MAT文件\n');
format_choice = input('请选择导出格式 (1-2): ');

% 生成文件名
filename = sprintf('filter_comparison_%s', datestr(now, 'yyyyMMdd_HHmmss'));

switch format_choice
    case 1
        % 导出为CSV文件
        csv_filename = [filename, '.csv'];
        export_to_csv(app, csv_filename);
    case 2
        % 导出为MAT文件
        mat_filename = [filename, '.mat'];
        export_to_mat(app, mat_filename);
    otherwise
        fprintf('无效选择！\n');
        return;
end

fprintf('结果已导出到 %s\n', filename);
end

%% 导出到CSV文件
function export_to_csv(app, filename)
fid = fopen(filename, 'w');

% 写入执行时间
fprintf(fid, '=== 执行时间 (秒) ===\n');
fprintf(fid, '滤波器,平均值,标准差\n');
for i = 1:length(app.results.execution_times)
    result = app.results.execution_times{i};
    fprintf(fid, '%s,%.4f,%.4f\n', result.filter, mean(result.times), std(result.times));
end

% 写入内存使用
fprintf(fid, '\n=== 内存使用 (MB) ===\n');
fprintf(fid, '滤波器,平均值,标准差\n');
for i = 1:length(app.results.memory_usage)
    result = app.results.memory_usage{i};
    fprintf(fid, '%s,%.4f,%.4f\n', result.filter, mean(result.usage), std(result.usage));
end

% 写入跟踪精度
fprintf(fid, '\n=== 跟踪精度 ===\n');
fprintf(fid, '滤波器,平均值,标准差\n');
for i = 1:length(app.results.tracking_accuracy)
    result = app.results.tracking_accuracy{i};
    fprintf(fid, '%s,%.4f,%.4f\n', result.filter, mean(result.accuracy), std(result.accuracy));
end

fclose(fid);
end

%% 导出到MAT文件
function export_to_mat(app, filename)
save(filename, 'app');
end

%% 运行应用
% 检查是否在批处理模式下运行
if isempty(getenv('MATLAB_BATCH'))
    % 交互式模式
    main();
else
    % 批处理模式 - 运行默认对比测试
    fprintf('在批处理模式下运行默认对比测试...\n');
    
    % 初始化应用
    app = init_app();
    
    % 设置默认选中的滤波器
    app.params.selected_filters = {
        struct('group', 'phd', 'type', 'GM-PHD'),
        struct('group', 'pmbm', 'type', 'PMBM')
    };
    
    % 运行对比测试
    run_comparison(app);
    
    % 导出结果
    export_to_csv(app, 'filter_comparison_results.csv');
    
    fprintf('对比测试完成，结果已导出到 filter_comparison_results.csv\n');
end