% demos/demo_filter_comparison.m
% 滤波器通用对比演示应用
% 支持多种滤波器的性能对比和可视化

%% 清理环境
clear; clc; close all;

%% 添加路径
addpath(genpath('..'));

%% 主函数
function main()
    display_welcome();
    app = init_app();
    
    while true
        choice = display_main_menu();
        
        switch choice
            case 1
                configure_comparison(app);
            case 2
                run_comparison(app);
            case 3
                visualize_results(app);
            case 4
                export_results(app);
            case 5
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
    app = struct();
    app.available_filters = get_available_filters();
    
    app.params = struct();
    app.params.selected_filters = {};
    app.params.num_runs = 10;
    app.params.simulation_duration = 100;
    app.params.num_targets = 5;
    app.params.clutter_rate = 10;
    app.params.detection_prob = 0.9;
    app.params.survival_prob = 0.99;
    
    app.results = struct();
    app.results.execution_times = {};
    app.results.memory_usage = {};
    app.results.tracking_accuracy = {};
    
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
    filters = struct();
    
    try
        filters.phd = struct();
        filters.phd.name = 'PHD滤波器';
        filters.phd.types = phd.PHDFactory.getAvailableTypes();
        filters.phd.factory = @phd.PHDFactory.createFilter;
    catch
        fprintf('警告: PHD滤波器工厂不可用\n');
    end
    
    try
        filters.pmbm = struct();
        filters.pmbm.name = 'PMBM滤波器';
        filters.pmbm.types = pmbm.PMBMFactory.getAvailableTypes();
        filters.pmbm.factory = @pmbm.PMBMFactory.createFilter;
    catch
        fprintf('警告: PMBM滤波器工厂不可用\n');
    end
    
    try
        filters.tpmbm = struct();
        filters.tpmbm.name = 'TPMBM滤波器';
        filters.tpmbm.types = tpmbm.TPMBMFactory.getAvailableTypes();
        filters.tpmbm.factory = @tpmbm.TPMBMFactory.createFilter;
    catch
        fprintf('警告: TPMBM滤波器工厂不可用\n');
    end
    
    try
        filters.cd = struct();
        filters.cd.name = '连续-离散滤波器';
        filters.cd.types = cdfilters.CDFilterFactory.getAvailableTypes();
        filters.cd.factory = @cdfilters.CDFilterFactory.createFilter;
    catch
        fprintf('警告: 连续-离散滤波器工厂不可用\n');
    end
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

fprintf('\n可用滤波器类型:\n');
filter_idx = 1;
filter_options = {};

filter_names = fieldnames(app.available_filters);
for k = 1:length(filter_names)
    filter_group_name = filter_names{k};
    filter_group = app.available_filters.(filter_group_name);
    fprintf('\n%s:\n', filter_group.name);
    for i = 1:length(filter_group.types)
        fprintf('%d. %s\n', filter_idx, filter_group.types{i});
        filter_options{filter_idx} = struct('group', filter_group_name, 'type', filter_group.types{i});
        filter_idx = filter_idx + 1;
    end
end

fprintf('\n请输入要对比的滤波器编号（多个编号用空格分隔）: ');
selected_indices = input('');

app.params.selected_filters = {};
for i = 1:length(selected_indices)
    idx = selected_indices(i);
    if idx >= 1 && idx <= length(filter_options)
        app.params.selected_filters{end+1} = filter_options{idx};
    end
end

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

app.results.execution_times = {};
app.results.memory_usage = {};
app.results.tracking_accuracy = {};

for i = 1:length(app.params.selected_filters)
    filter_info = app.params.selected_filters{i};
    filter_group = app.available_filters.(filter_info.group);
    filter_type = filter_info.type;
    
    fprintf('\n测试 %s - %s\n', filter_group.name, filter_type);
    
    exec_times = zeros(1, app.params.num_runs);
    memory_usages = zeros(1, app.params.num_runs);
    accuracies = zeros(1, app.params.num_runs);
    
    for run = 1:app.params.num_runs
        fprintf('  运行 %d/%d...', run, app.params.num_runs);
        
        config = create_filter_config(app.params);
        
        try
            filter = filter_group.factory(filter_type, config);
        catch ME
            fprintf('  错误: %s\n', ME.message);
            exec_times(run) = NaN;
            memory_usages(run) = NaN;
            accuracies(run) = NaN;
            continue;
        end
        
        [measurements, ground_truth] = generate_test_data(app.params);
        
        start_time = tic;
        
        try
            result = filter.run(measurements, ground_truth);
            exec_times(run) = toc(start_time);
        catch ME
            fprintf('  运行错误: %s\n', ME.message);
            exec_times(run) = NaN;
            accuracies(run) = NaN;
            memory_usages(run) = 0;
            continue;
        end
        
        try
            memInfo = memory;
            memory_usages(run) = memInfo.MemUsedMATLAB / 1024 / 1024;
        catch
            memory_usages(run) = 0;
        end
        
        try
            accuracies(run) = calculate_tracking_accuracy(result, ground_truth);
        catch
            accuracies(run) = 0;
        end
        
        fprintf('  完成 (%.3f秒)\n', exec_times(run));
    end
    
    app.results.execution_times{i} = struct('filter', [filter_group.name, ' - ', filter_type], 'times', exec_times);
    app.results.memory_usage{i} = struct('filter', [filter_group.name, ' - ', filter_type], 'usage', memory_usages);
    app.results.tracking_accuracy{i} = struct('filter', [filter_group.name, ' - ', filter_type], 'accuracy', accuracies);
end

fprintf('\n对比测试完成！\n');
end

%% 创建滤波器配置
function config = create_filter_config(params)
config = utils.FilterConfig();

config.detectionProb = params.detection_prob;
config.survivalProb = params.survival_prob;
config.clutterRate = params.clutter_rate;
config.surveillanceArea = [1000, 1000];
config.pruningThreshold = 1e-5;
config.maxComponents = 100;
config.existenceThreshold = 1e-5;

config.motionModel.F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
config.motionModel.Q = eye(4) * 0.1;

config.measurementModel.H = [1 0 0 0; 0 1 0 0];
config.measurementModel.R = eye(2) * 1;

config.birthModel.means = zeros(4, 1);
config.birthModel.covs = eye(4);
config.birthModel.weights = 1;
config.birthModel.intensity = 0.005;
end

%% 生成测试数据
function [measurements, ground_truth] = generate_test_data(params)
num_targets = params.num_targets;
duration = params.simulation_duration;

target_states = cell(duration, 1);
target_births = cell(duration, 1);
target_deaths = cell(duration, 1);

for t = 1:duration
    target_states{t} = [];
    target_births{t} = [];
    target_deaths{t} = [];
    
    if t == 1 || (t > 1 && rand() < 0.1)
        num_new_targets = randi(2);
        for i = 1:num_new_targets
            if size(target_states{t}, 2) < num_targets
                x0 = rand() * 800 + 100;
                y0 = rand() * 800 + 100;
                vx0 = (rand() - 0.5) * 10;
                vy0 = (rand() - 0.5) * 10;
                
                new_state = [x0; y0; vx0; vy0];
                target_states{t} = [target_states{t}, new_state];
                target_births{t} = [target_births{t}, size(target_states{t}, 2)];
            end
        end
    else
        if t > 1
            target_states{t} = target_states{t-1};
        end
    end
    
    if ~isempty(target_states{t})
        F = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1];
        Q = eye(4) * 0.1;
        
        for i = 1:size(target_states{t}, 2)
            target_states{t}(:, i) = F * target_states{t}(:, i) + mvnrnd(zeros(4, 1), Q)';
            
            if rand() > params.survival_prob
                target_deaths{t} = [target_deaths{t}, i];
            end
        end
        
        if ~isempty(target_deaths{t})
            target_states{t}(:, target_deaths{t}) = [];
        end
    end
end

measurements = struct();
measurements.timeStamps = 1:duration;
measurements.measurements = cell(1, duration);

for t = 1:duration
    z = [];
    
    if ~isempty(target_states{t})
        H = [1 0 0 0; 0 1 0 0];
        R = eye(2) * 1;
        
        for i = 1:size(target_states{t}, 2)
            if rand() < params.detection_prob
                measurement = H * target_states{t}(:, i) + mvnrnd(zeros(2, 1), R)';
                z = [z, measurement];
            end
        end
    end
    
    num_clutter = poissrnd(params.clutter_rate);
    for i = 1:num_clutter
        clutter = [rand() * 1000; rand() * 1000];
        z = [z, clutter];
    end
    
    measurements.measurements{t} = z;
end

ground_truth = struct();
ground_truth.states = target_states;
ground_truth.births = target_births;
ground_truth.deaths = target_deaths;
end

%% 计算跟踪精度
function accuracy = calculate_tracking_accuracy(result, ground_truth)
if ~isfield(result, 'estimates') || isempty(result.estimates)
    accuracy = 0;
    return;
end

if ~isfield(result.estimates, 'states') || isempty(result.estimates.states)
    accuracy = 0;
    return;
end

num_estimates = 0;
for t = 1:length(result.estimates.states)
    if iscell(result.estimates.states)
        if ~isempty(result.estimates.states{t})
            num_estimates = num_estimates + size(result.estimates.states{t}, 2);
        end
    else
        num_estimates = num_estimates + size(result.estimates.states, 2);
    end
end

num_ground_truth = 0;
for t = 1:length(ground_truth.states)
    num_ground_truth = num_ground_truth + size(ground_truth.states{t}, 2);
end

if num_ground_truth > 0
    accuracy = max(0, 1 - abs(num_estimates - num_ground_truth) / num_ground_truth);
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

figure('Name', '滤波器对比结果', 'Position', [100, 100, 1200, 800]);

subplot_idx = 1;
num_subplots = 0;

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

if num_subplots <= 2
    [rows, cols] = deal(1, num_subplots);
elseif num_subplots <= 4
    [rows, cols] = deal(2, 2);
else
    [rows, cols] = deal(3, ceil(num_subplots/3));
end

if app.visualization.show_execution_time && ~isempty(app.results.execution_times)
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    filter_names = {};
    avg_times = [];
    std_times = [];
    
    for i = 1:length(app.results.execution_times)
        result = app.results.execution_times{i};
        filter_names{end+1} = result.filter;
        valid_times = result.times(~isnan(result.times));
        if ~isempty(valid_times)
            avg_times(end+1) = mean(valid_times);
            std_times(end+1) = std(valid_times);
        else
            avg_times(end+1) = 0;
            std_times(end+1) = 0;
        end
    end
    
    bar(avg_times);
    hold on;
    errorbar(1:length(avg_times), avg_times, std_times, '.');
    set(gca, 'XTickLabel', filter_names, 'XTick', 1:length(filter_names));
    xtickangle(45);
    title('执行时间对比 (秒)');
    xlabel('滤波器');
    ylabel('平均执行时间');
    grid on;
end

if app.visualization.show_memory_usage && ~isempty(app.results.memory_usage)
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    filter_names = {};
    avg_memory = [];
    std_memory = [];
    
    for i = 1:length(app.results.memory_usage)
        result = app.results.memory_usage{i};
        filter_names{end+1} = result.filter;
        valid_memory = result.usage(~isnan(result.usage));
        if ~isempty(valid_memory)
            avg_memory(end+1) = mean(valid_memory);
            std_memory(end+1) = std(valid_memory);
        else
            avg_memory(end+1) = 0;
            std_memory(end+1) = 0;
        end
    end
    
    bar(avg_memory);
    hold on;
    errorbar(1:length(avg_memory), avg_memory, std_memory, '.');
    set(gca, 'XTickLabel', filter_names, 'XTick', 1:length(filter_names));
    xtickangle(45);
    title('内存使用对比 (MB)');
    xlabel('滤波器');
    ylabel('平均内存使用');
    grid on;
end

if app.visualization.show_tracking_accuracy && ~isempty(app.results.tracking_accuracy)
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    filter_names = {};
    avg_accuracy = [];
    std_accuracy = [];
    
    for i = 1:length(app.results.tracking_accuracy)
        result = app.results.tracking_accuracy{i};
        filter_names{end+1} = result.filter;
        valid_accuracy = result.accuracy(~isnan(result.accuracy));
        if ~isempty(valid_accuracy)
            avg_accuracy(end+1) = mean(valid_accuracy);
            std_accuracy(end+1) = std(valid_accuracy);
        else
            avg_accuracy(end+1) = 0;
            std_accuracy(end+1) = 0;
        end
    end
    
    bar(avg_accuracy);
    hold on;
    errorbar(1:length(avg_accuracy), avg_accuracy, std_accuracy, '.');
    set(gca, 'XTickLabel', filter_names, 'XTick', 1:length(filter_names));
    xtickangle(45);
    title('跟踪精度对比');
    xlabel('滤波器');
    ylabel('平均精度');
    ylim([0, 1]);
    grid on;
end

if app.visualization.show_trajectories
    subplot(rows, cols, subplot_idx);
    subplot_idx = subplot_idx + 1;
    
    plot(0, 0);
    title('轨迹对比');
    xlabel('X');
    ylabel('Y');
    grid on;
    legend('真值轨迹', '估计轨迹');
end

fprintf('可视化完成！\n');
end

%% 导出结果
function export_results(app)
if isempty(app.results.execution_times)
    fprintf('请先运行对比测试！\n');
    return;
end

fprintf('\n=== 导出结果 ===\n');

fprintf('导出格式:\n');
fprintf('1. CSV文件\n');
fprintf('2. MAT文件\n');
format_choice = input('请选择导出格式 (1-2): ');

filename = sprintf('filter_comparison_%s', datestr(now, 'yyyyMMdd_HHmmss'));

switch format_choice
    case 1
        csv_filename = [filename, '.csv'];
        export_to_csv(app, csv_filename);
    case 2
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

if fid == -1
    fprintf('错误: 无法创建文件 %s\n', filename);
    return;
end

fprintf(fid, '=== 执行时间 (秒) ===\n');
fprintf(fid, '滤波器,平均值,标准差\n');
for i = 1:length(app.results.execution_times)
    result = app.results.execution_times{i};
    if ~isfield(result, 'times') && ~isempty(result.times)
        fprintf(fid, '%s,%.4f,%.4f\n', result.filter, mean(result.times), std(result.times));
    else
        fprintf(fid, '%s,N/A,N/A\n', result.filter);
    end
end

fprintf(fid, '\n=== 内存使用 (MB) ===\n');
fprintf(fid, '滤波器,平均值,标准差\n');
for i = 1:length(app.results.memory_usage)
    result = app.results.memory_usage{i};
    valid_memory = result.usage(~isnan(result.usage));
    if ~isempty(valid_memory)
        fprintf(fid, '%s,%.4f,%.4f\n', result.filter, mean(valid_memory), std(valid_memory));
    else
        fprintf(fid, '%s,N/A,N/A\n', result.filter);
    end
end

fprintf(fid, '\n=== 跟踪精度 ===\n');
fprintf(fid, '滤波器,平均值,标准差\n');
for i = 1:length(app.results.tracking_accuracy)
    result = app.results.tracking_accuracy{i};
    valid_accuracy = result.accuracy(~isnan(result.accuracy));
    if ~isempty(valid_accuracy)
        fprintf(fid, '%s,%.4f,%.4f\n', result.filter, mean(valid_accuracy), std(valid_accuracy));
    else
        fprintf(fid, '%s,N/A,N/A\n', result.filter);
    end
end

fclose(fid);
fprintf('CSV文件已成功导出到: %s\n', filename);
end

%% 导出到MAT文件
function export_to_mat(app, filename)
save(filename, 'app');
fprintf('MAT文件已成功导出到: %s\n', filename);
end

%% 运行应用
is_batch_mode = false;
try
    if ~isempty(getenv('MATLAB_BATCH')) || ~isempty(getenv('SLURM_JOB_ID')) || ~isempty(getenv('PBS_JOBID'))
        is_batch_mode = true;
    end
    test_input = input('', 's');
catch
    is_batch_mode = true;
end

if ~is_batch_mode
    main();
else
    fprintf('在批处理模式下运行默认对比测试...\n');
    
    app = init_app();
    
    filter_names = fieldnames(app.available_filters);
    if ~isempty(filter_names)
        first_filter = filter_names{1};
        if isfield(app.available_filters.(first_filter), 'types') && ~isempty(app.available_filters.(first_filter).types)
            app.params.selected_filters = {struct('group', first_filter, 'type', app.available_filters.(first_filter).types{1})};
            
            if length(filter_names) > 1
                second_filter = filter_names{2};
                if isfield(app.available_filters.(second_filter), 'types') && ~isempty(app.available_filters.(second_filter).types)
                    app.params.selected_filters{end+1} = struct('group', second_filter, 'type', app.available_filters.(second_filter).types{1});
                end
            end
        end
    end
    
    run_comparison(app);
    
    csv_filename = fullfile(pwd, 'filter_comparison_results.csv');
    export_to_csv(app, csv_filename);
    
    fprintf('\n对比测试完成！\n');
end
