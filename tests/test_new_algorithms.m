function test_new_algorithms()
    % TEST_NEW_ALGORITHMS 测试新集成的算法
    %
    % 测试PMB、TPMB、TMBM滤波器的基本功能
    %
    % 版本: 1.0
    % 日期: 2026-03-12
    
    % 添加项目根目录到搜索路径
    projectRoot = fullfile(pwd, '..');
    addpath(projectRoot);
    
    fprintf('\n========================================\n');
    fprintf('新算法集成测试\n');
    fprintf('========================================\n\n');
    
    testResults = struct();
    
    try
        fprintf('--- 测试1: PMB滤波器 ---\n');
        testResults.PMB = test_pmb();
        fprintf('PMB测试通过\n\n');
    catch ME
        fprintf('PMB测试失败: %s\n', ME.message);
        testResults.PMB = struct('passed', false, 'error', ME.message);
    end
    
    try
        fprintf('--- 测试2: TPMB滤波器 ---\n');
        testResults.TPMB = test_tpmb();
        fprintf('TPMB测试通过\n\n');
    catch ME
        fprintf('TPMB测试失败: %s\n', ME.message);
        testResults.TPMB = struct('passed', false, 'error', ME.message);
    end
    
    try
        fprintf('--- 测试3: TMBM滤波器 ---\n');
        testResults.TMBM = test_tmbm();
        fprintf('TMBM测试通过\n\n');
    catch ME
        fprintf('TMBM测试失败: %s\n', ME.message);
        testResults.TMBM = struct('passed', false, 'error', ME.message);
    end
    
    try
        fprintf('--- 测试4: TPMBM工厂 ---\n');
        testResults.TPMBMFactory = test_tpmbm_factory();
        fprintf('TPMBM工厂测试通过\n\n');
    catch ME
        fprintf('TPMBM工厂测试失败: %s\n', ME.message);
        testResults.TPMBMFactory = struct('passed', false, 'error', ME.message);
    end
    
    fprintf('\n========================================\n');
    fprintf('测试总结\n');
    fprintf('========================================\n');
    
    testNames = fieldnames(testResults);
    passCount = 0;
    totalCount = length(testNames);
    
    for i = 1:totalCount
        name = testNames{i};
        if isfield(testResults.(name), 'passed') && testResults.(name).passed
            fprintf('  [PASS] %s: 通过\n', name);
            passCount = passCount + 1;
        else
            fprintf('  [FAIL] %s: 失败\n', name);
        end
    end
    
    fprintf('\n总计: %d/%d 测试通过\n', passCount, totalCount);
    fprintf('========================================\n');
end

function result = test_pmb()
    result = struct('passed', true);
    
    config = utils.FilterConfig();
    config.detectionProb = 0.9;
    config.survivalProb = 0.99;
    config.clutterRate = 1e-4;
    config.surveillanceArea = [1000, 100];
    config.pruningThreshold = 1e-5;
    config.maxComponents = 100;
    config.existenceThreshold = 1e-5;
    
    config.motionModel.F = eye(4);
    config.motionModel.Q = eye(4) * eye(4);
    
    config.measurementModel.H = [1 0 0 0; 0 1 0 0];
    config.measurementModel.R = eye(2);
    
    config.birthModel.means = zeros(4, 1);
    config.birthModel.covs = eye(4);
    config.birthModel.weights = 1;
    config.birthModel.intensity = 0.005;
    
    try
        filter = pmbm.PMB(config);
        fprintf('PMB滤波器创建成功\n');
        
        filter = filter.initialize();
        fprintf('PMB滤波器初始化成功\n');
        
        z = zeros(2, 0);
        estimates = filter.estimate();
        fprintf('PMB滤波器估计成功\n');
    catch ME
        fprintf('PMB测试详细错误: %s\n', ME.message);
        fprintf('错误堆栈: %s\n', ME.stack);
        rethrow(ME);
    end
    
    result.passed = true;
    result.estimates = estimates;
end

function result = test_tpmb()
    result = struct('passed', true);
    
    config = utils.FilterConfig();
    config.detectionProb = 0.9;
    config.survivalProb = 0.99;
    config.clutterRate = 1e-4;
    config.surveillanceArea = [1000, 100];
    config.pruningThreshold = 1e-5;
    config.maxComponents = 100;
    config.existenceThreshold = 1e-5;
    
    config.motionModel.F = eye(4);
    config.motionModel.Q = eye(4) * eye(4);
    
    config.measurementModel.H = [1 0 0 0; 0 1 0 0];
    config.measurementModel.R = eye(2);
    
    config.birthModel.means = zeros(4, 1);
    config.birthModel.covs = eye(4);
    config.birthModel.weights = 1;
    config.birthModel.intensity = 0.005;
    
    filter = tpmb.TPMB(config);
    filter = filter.initialize();
    
    z = zeros(2, 0);
    estimates = filter.estimate();
    
    result.passed = true;
    result.estimates = estimates;
end

function result = test_tmbm()
    result = struct('passed', true);
    
    config = utils.FilterConfig();
    config.detectionProb = 0.9;
    config.survivalProb = 0.99;
    config.clutterRate = 1e-4;
    config.surveillanceArea = [1000, 100];
    config.pruningThreshold = 1e-5;
    config.maxComponents = 100;
    config.existenceThreshold = 1e-5;
    config.gatingThreshold = 20;
    
    config.motionModel.F = eye(4);
    config.motionModel.Q = eye(4) * eye(4);
    
    config.measurementModel.H = [1 0 0 0; 0 1 0 0];
    config.measurementModel.R = eye(2);
    
    config.birthModel.means = zeros(4, 1);
    config.birthModel.covs = eye(4);
    config.birthModel.weights = 1;
    config.birthModel.intensity = 0.005;
    
    filter = tmbm.TMBM(config);
    filter = filter.initialize();
    
    z = zeros(2, 0);
    estimates = filter.estimate();
    
    result.passed = true;
    result.estimates = estimates;
end

function result = test_tpmbm_factory()
    result = struct('passed', true);
    
    types = tpmbm.TPMBFactory.getAvailableTypes();
    
    if isempty(types)
        result.passed = false;
        result.error = 'Unable获取可用类型';
        return;
    end
    
    for i = 1:length(types)
        config = utils.FilterConfig();
        filter = tpmbm.TPMBFactory.createFilter(types{i}, config);
        if isempty(filter)
            result.passed = false;
            result.error = sprintf('无法创建 %s 滤波器', types{i});
        end
    end
    
    result.types = types;
end
