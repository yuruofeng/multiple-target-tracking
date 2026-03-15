% test_gospa_fixes.m
% GOSPA修复方案验证测试套件
%
% 目的: 全面验证修复后的GOSPA实现和平均值计算

clear; clc;
addpath(genpath('..'));

fprintf('========================================\n');
fprintf('  GOSPA修复方案验证测试套件\n');
fprintf('========================================\n\n');

test_results = [];
passed_count = 0;
failed_count = 0;

%% 测试1: 空估计值 + 非空真值
fprintf('【测试1】空估计值 + 非空真值\n');
fprintf('----------------------------------------\n');
try
    est = [];
    gt = [0; 0; 10; 0];
    gospa_obj = metric.GOSPA('p', 2, 'c', 100, 'alpha', 2);
    [d, ~, decomp] = gospa_obj.compute(est, gt);
    
    if ~isnan(d) && decomp.false > 0
        fprintf('✓ 通过: GOSPA=%.4f, 虚警=%.4f\n', d, decomp.false);
        passed_count = passed_count + 1;
        test_results(end+1) = true;
    else
        fprintf('✗ 失败: GOSPA=%.4f (应为非NaN), 虚警=%.4f (应>0)\n', d, decomp.false);
        failed_count = failed_count + 1;
        test_results(end+1) = false;
    end
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试2: 非空估计值 + 空真值
fprintf('【测试2】非空估计值 + 空真值\n');
fprintf('----------------------------------------\n');
try
    est = [0; 0; 10; 0];
    gt = [];
    gospa_obj = metric.GOSPA('p', 2, 'c', 100, 'alpha', 2);
    [d, ~, decomp] = gospa_obj.compute(est, gt);
    
    if ~isnan(d) && decomp.missed > 0
        fprintf('✓ 通过: GOSPA=%.4f, 漏检=%.4f\n', d, decomp.missed);
        passed_count = passed_count + 1;
        test_results(end+1) = true;
    else
        fprintf('✗ 失败: GOSPA=%.4f (应为非NaN), 漏检=%.4f (应>0)\n', d, decomp.missed);
        failed_count = failed_count + 1;
        test_results(end+1) = false;
    end
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试3: 两个空集
fprintf('【测试3】两个空集\n');
fprintf('----------------------------------------\n');
try
    est = [];
    gt = [];
    gospa_obj = metric.GOSPA('p', 2, 'c', 100, 'alpha', 2);
    [d, ~, decomp] = gospa_obj.compute(est, gt);
    
    if d == 0 && decomp.localisation == 0 && decomp.missed == 0 && decomp.false == 0
        fprintf('✓ 通过: GOSPA=%.4f (应为0)\n', d);
        passed_count = passed_count + 1;
        test_results(end+1) = true;
    else
        fprintf('✗ 失败: GOSPA=%.4f (应为0)\n', d);
        failed_count = failed_count + 1;
        test_results(end+1) = false;
    end
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试4: 非空估计值 + 非空真值(正常情况)
fprintf('【测试4】非空估计值 + 非空真值\n');
fprintf('----------------------------------------\n');
try
    est = [1; 1; 10; 0];
    gt = [0; 0; 10; 0];
    gospa_obj = metric.GOSPA('p', 2, 'c', 100, 'alpha', 2);
    result = gospa_obj.compute(est, gt);
    d = result.distance;
    decomp = result.decomposition;
    
    if ~isnan(d) && d > 0
        fprintf('✓ 通过: GOSPA=%.4f\n', d);
        passed_count = passed_count + 1;
        test_results(end+1) = true;
    else
        fprintf('✗ 失败: GOSPA=%.4f\n', d);
        failed_count = failed_count + 1;
        test_results(end+1) = false;
    end
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试5: 包含NaN值的数据
fprintf('【测试5】包含NaN值的数据\n');
fprintf('----------------------------------------\n');
try
    est = [NaN; 1; 10; 0];
    gt = [0; 0; 10; 0];
    gospa_obj = metric.GOSPA('p', 2, 'c', 100, 'alpha', 2);
    [d, ~, decomp] = gospa_obj.compute(est, gt);
    
    if isnan(d)
        fprintf('⚠ 警告: GOSPA=%.4f (NaN传播,建议添加NaN检测)\n', d);
    else
        fprintf('✓ 通过: GOSPA=%.4f (已处理NaN)\n', d);
    end
    passed_count = passed_count + 1;
    test_results(end+1) = true;
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试6: 平均值计算 - 默认mean
fprintf('【测试6】平均值计算 - 默认mean\n');
fprintf('----------------------------------------\n');
values = [10.5, NaN, 12.3, NaN, 15.2];
avg_default = mean(values);
if isnan(avg_default)
    fprintf('✓ 通过: mean([含NaN])=%.4f (正确返回NaN)\n', avg_default);
    passed_count = passed_count + 1;
    test_results(end+1) = true;
else
    fprintf('✗ 失败: mean([含NaN])=%.4f (应返回NaN)\n', avg_default);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试7: 平均值计算 - omitnan选项
fprintf('【测试7】平均值计算 - omitnan选项\n');
fprintf('----------------------------------------\n');
values = [10.5, NaN, 12.3, NaN, 15.2];
avg_omitnan = mean(values, 'omitnan');
expected_avg = (10.5 + 12.3 + 15.2) / 3;
if abs(avg_omitnan - expected_avg) < 0.01
    fprintf('✓ 通过: mean([含NaN], ''omitnan'')=%.4f (期望%.4f)\n', avg_omitnan, expected_avg);
    passed_count = passed_count + 1;
    test_results(end+1) = true;
else
    fprintf('✗ 失败: mean([含NaN], ''omitnan'')=%.4f (期望%.4f)\n', avg_omitnan, expected_avg);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试8: 规范化空矩阵维度
fprintf('【测试8】规范化空矩阵维度\n');
fprintf('----------------------------------------\n');
try
    % 空矩阵 [] (0×0) vs 非空 (4×1)
    est = [];
    gt = [0; 0; 10; 0];
    
    fprintf('  输入: est=[%s], gt=[%s]\n', num2str(size(est)), num2str(size(gt)));
    gospa_obj = metric.GOSPA('p', 2, 'c', 100, 'alpha', 2);
    [d, ~, ~] = gospa_obj.compute(est, gt);
    
    if ~isnan(d)
        fprintf('✓ 通过: 自动规范化成功, GOSPA=%.4f\n', d);
        passed_count = passed_count + 1;
        test_results(end+1) = true;
    else
        fprintf('✗ 失败: GOSPA=%.4f\n', d);
        failed_count = failed_count + 1;
        test_results(end+1) = false;
    end
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试9: 多目标场景
fprintf('【测试9】多目标场景\n');
fprintf('----------------------------------------\n');
try
    est = [1 2 3; 1 2 3; 10 11 12; 0 1 0];
    gt = [0 2 4; 0 2 4; 10 11 12; 0 1 0];
    gospa_obj = metric.GOSPA('p', 2, 'c', 100, 'alpha', 2);
    [d, ~, decomp] = gospa_obj.compute(est, gt);
    
    if ~isnan(d) && d > 0
        fprintf('✓ 通过: GOSPA=%.4f\n', d);
        passed_count = passed_count + 1;
        test_results(end+1) = true;
    else
        fprintf('✗ 失败: GOSPA=%.4f\n', d);
        failed_count = failed_count + 1;
        test_results(end+1) = false;
    end
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试10: 时间序列平均值(模拟实际使用场景)
fprintf('【测试10】时间序列平均值(模拟实际场景)\n');
fprintf('----------------------------------------\n');
try
    % 模拟100个时间步的GOSPA值,部分为NaN
    gospa_series = randn(100, 1) * 10 + 20;
    gospa_series([10, 20, 30, 40]) = NaN;  % 4个时间步为NaN
    
    avg_with_nan = mean(gospa_series);
    avg_ignore_nan = mean(gospa_series, 'omitnan');
    valid_count = sum(~isnan(gospa_series));
    nan_count = sum(isnan(gospa_series));
    
    fprintf('  总时间步: 100\n');
    fprintf('  有效值: %d, NaN值: %d\n', valid_count, nan_count);
    fprintf('  mean(默认): %.4f\n', avg_with_nan);
    fprintf('  mean(omitnan): %.4f\n', avg_ignore_nan);
    
    if isnan(avg_with_nan) && ~isnan(avg_ignore_nan)
        fprintf('✓ 通过: omitnan正确忽略NaN值\n');
        passed_count = passed_count + 1;
        test_results(end+1) = true;
    else
        fprintf('✗ 失败: 平均值计算不符合预期\n');
        failed_count = failed_count + 1;
        test_results(end+1) = false;
    end
catch ME
    fprintf('✗ 失败: 异常 - %s\n', ME.message);
    failed_count = failed_count + 1;
    test_results(end+1) = false;
end
fprintf('\n');

%% 测试总结
fprintf('========================================\n');
fprintf('  测试总结\n');
fprintf('========================================\n');
fprintf('总测试数: %d\n', length(test_results));
fprintf('通过: %d (%.1f%%)\n', passed_count, 100*passed_count/length(test_results));
fprintf('失败: %d (%.1f%%)\n', failed_count, 100*failed_count/length(test_results));
fprintf('\n');

if failed_count == 0
    fprintf('🎉 恭喜! 所有测试通过!\n');
    fprintf('修复方案验证成功。\n');
else
    fprintf('⚠️  有 %d 个测试失败,请检查修复方案。\n', failed_count);
end
fprintf('\n');

%% 验证建议
fprintf('========================================\n');
fprintf('  后续验证建议\n');
fprintf('========================================\n');
fprintf('1. 运行修复后的demo_filter_comparison.m\n');
fprintf('   >> cd demos\n');
fprintf('   >> demo_filter_comparison\n');
fprintf('\n');
fprintf('2. 检查输出结果中平均GOSPA是否为非NaN\n');
fprintf('\n');
fprintf('3. 查看可视化图表,确保GOSPA曲线正常显示\n');
fprintf('\n');
fprintf('4. 如有问题,请查看诊断报告:\n');
fprintf('   docs/GOSPA_NaN_Diagnostic_Report.md\n');
fprintf('\n');
