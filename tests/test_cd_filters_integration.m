function test_cd_filters_integration()
    % TEST_CD_FILTERS_INTEGRATION 测试连续-离散滤波器集成
    %
    % 功能:
    %   1. 创建连续-离散GM-PHD、GM-CPHD滤波器
    %   2. 创建连续-离散PMBM滤波器演示
    %   3. 验证滤波器功能正确性
    %   4. 计算性能指标
    %
    % 参考文献:
    %   A. F. Garcia-Fernandez, S. Maskell, "Continuous-discrete multiple target 
    %   filtering: PMBM, PHD and CPHD filter implementations," 
    %   IEEE Transactions on Signal Processing, vol. 68, pp. 1300-1314, 2020.
    %
    % 版本: 2.0 (重构版)
    % 日期: 2026-03-12
    
    fprintf('\n========================================\n');
    fprintf('连续-离散滤波器集成测试\n');
    fprintf('========================================\n\n');
    
    testResults = struct();
    
    try
        fprintf('--- 测试1: CD-GMPHD滤波器 ---\n');
        testResults.CDGMPHD = test_cd_gmphd();
        fprintf('CD-GMPHD测试通过\n\n');
    catch ME
        fprintf('CD-GMPHD测试失败: %s\n\n', ME.message);
        testResults.CDGMPHD = struct('passed', false, 'error', ME.message);
    end
    
    try
        fprintf('--- 测试2: CD-GMCPHD滤波器 ---\n');
        testResults.CDGMCPHD = test_cd_gmcphd();
        fprintf('CD-GMCPHD测试通过\n\n');
    catch ME
        fprintf('CD-GMCPHD测试失败: %s\n\n', ME.message);
        testResults.CDGMCPHD = struct('passed', false, 'error', ME.message);
    end
    
    try
        fprintf('--- 测试3: CD-PMBM滤波器 ---\n');
        testResults.CDPMBM = test_cd_pmbm();
        fprintf('CD-PMBM测试通过\n\n');
    catch ME
        fprintf('CD-PMBM测试失败: %s\n\n', ME.message);
        testResults.CDPMBM = struct('passed', false, 'error', ME.message);
    end
    
    try
        fprintf('--- 测试4: 滤波器工厂 ---\n');
        testResults.Factory = test_cd_filter_factory();
        fprintf('滤波器工厂测试通过\n\n');
    catch ME
        fprintf('滤波器工厂测试失败: %s\n\n', ME.message);
        testResults.Factory = struct('passed', false, 'error', ME.message);
    end
    
    try
        fprintf('--- 测试5: 轨迹误差计算 ---\n');
        testResults.TrajectoryError = test_trajectory_error_calculator();
        fprintf('轨迹误差计算测试通过\n\n');
    catch ME
        fprintf('轨迹误差计算测试失败: %s\n\n', ME.message);
        testResults.TrajectoryError = struct('passed', false, 'error', ME.message);
    end
    
    fprintf('========================================\n');
    fprintf('测试总结\n');
    fprintf('========================================\n');
    
    testNames = fieldnames(testResults);
    passCount = 0;
    totalCount = length(testNames);
    
    for i = 1:totalCount
        name = testNames{i};
        if isfield(testResults.(name), 'passed') && testResults.(name).passed
            fprintf('  [%s] %s: 通过\n', char(10004), name);
            passCount = passCount + 1;
        else
            fprintf('  [%s] %s: 失败\n', char(10006), name);
        end
    end
    
    fprintf('\n总计: %d/%d 测试通过\n', passCount, totalCount);
    fprintf('========================================\n');
end

function result = test_cd_gmphd()
    % TEST_CD_GMPHD 测试CD-GMPHD滤波器
    
    config = create_test_config();
    filter = cdfilters.CDGMPHD(config);
    
    filter = filter.initialize();
    
    result = struct('passed', true);
    
    if isempty(filter.GaussianComponents.weights)
        result.passed = false;
        result.error = '初始化失败: 高斯分量为空';
        return;
    end
    
    filter = filter.predict(1);
    
    if all(~filter.GaussianComponents.active)
        result.passed = false;
        result.error = '预测失败: 所有分量都非活跃';
        return;
    end
    
    measurements = create_test_measurements(2);
    filter = filter.update(measurements);
    
    estimates = filter.extractEstimates();
    result.numEstimates = length(estimates);
    result.filterActive = any(filter.GaussianComponents.active);
end

function result = test_cd_gmcphd()
    % TEST_CD_GMCPHD 测试CD-GMCPHD滤波器
    
    config = create_test_config();
    filter = cdfilters.CDGMCPHD(config);
    
    filter = filter.initialize();
    
    result = struct('passed', true);
    
    if isempty(filter.GaussianComponents.weights)
        result.passed = false;
        result.error = '初始化失败: 高斯分量为空';
        return;
    end
    
    filter = filter.predict(1);
    
    filter = filter.update(create_test_measurements(2));
    
    estimates = filter.extractEstimates();
    result.numEstimates = length(estimates);
    result.filterActive = any(filter.GaussianComponents.active);
end

function result = test_cd_pmbm()
    % TEST_CD_PMBM 测试CD-PMBM滤波器
    
    config = create_test_config();
    filter = cdfilters.CDPMBM(config);
    
    filter = filter.initialize();
    
    result = struct('passed', true);
    
    filter = filter.predict(1);
    
    filter = filter.update(create_test_measurements(2));
    
    estimates = filter.extractEstimates();
    result.numEstimates = length(estimates);
end

function result = test_cd_filter_factory()
    % TEST_CD_FILTER_FACTORY 测试滤波器工厂
    
    result = struct('passed', true);
    
    types = cdfilters.CDFilterFactory.getAvailableTypes();
    
    if isempty(types)
        result.passed = false;
        result.error = '工厂返回空类型列表';
        return;
    end
    
    result.availableTypes = types;
    
    for i = 1:length(types)
        filterType = types{i};
        try
            config = create_test_config();
            filter = cdfilters.CDFilterFactory.create(filterType, config);
            info = cdfilters.CDFilterFactory.getTypeInfo(filterType);
            result.(['info_' filterType]) = info;
        catch ME
            result.passed = false;
            result.(['error_' filterType]) = ME.message;
        end
    end
end

function result = test_trajectory_error_calculator()
    % TEST_TRAJECTORY_ERROR_CALCULATOR 测试轨迹误差计算器
    
    result = struct('passed', true);
    
    calc = metric.TrajectoryErrorCalculator('c', 10, 'p', 2, 'Nx', 4);
    
    k_end = 10;
    numTargets = 2;
    Nx = 4;
    
    X_truth = zeros(Nx * numTargets, k_end);
    for t = 1:numTargets
        for k = 1:k_end
            X_truth((t-1)*Nx + 1, k) = t * 100 + k * 10;
            X_truth((t-1)*Nx + 2, k) = 10;
            X_truth((t-1)*Nx + 3, k) = t * 100;
            X_truth((t-1)*Nx + 4, k) = 0;
        end
    end
    
    t_birth = [1, 1];
    t_death = [k_end + 1, k_end + 1];
    
    X_estimate = cell(1, 2);
    for t = 1:2
        X_estimate{t} = zeros(Nx * k_end, 1);
        for k = 1:k_end
            X_estimate{t}((k-1)*Nx + 1) = t * 100 + k * 10 + randn() * 0.1;
            X_estimate{t}((k-1)*Nx + 2) = 10;
            X_estimate{t}((k-1)*Nx + 3) = t * 100;
            X_estimate{t}((k-1)*Nx + 4) = 0;
        end
    end
    
    t_b_estimate = [1, 1];
    length_estimate = [k_end, k_end];
    
    try
        [squaredGOSPA, loc, mis, fal] = calc.computeGOSPAErrorTrajectory(...
            X_estimate, t_b_estimate, length_estimate, ...
            X_truth, t_birth, t_death, k_end);
        
        result.squaredGOSPA = squaredGOSPA;
        result.localisation = loc;
        result.missed = mis;
        result.false = fal;
        
        if squaredGOSPA < 0
            result.passed = false;
            result.error = 'GOSPA值不能为负';
        end
    catch ME
        result.passed = false;
        result.error = ME.message;
    end
end

function config = create_test_config()
    % CREATE_TEST_CONFIG 创建测试配置
    
    config = utils.FilterConfig();
    
    config.detectionProb = 0.9;
    config.survivalProb = 0.99;
    config.clutterIntensity = 1e-4;
    config.maxComponents = 30;
    config.pruningThreshold = 1e-5;
    config.mergingThreshold = 0.1;
    
    motionModel = struct();
    motionModel.F = [1, 1, 0, 0; 0, 1, 0, 0; 0, 0, 1, 1; 0, 0, 0, 1];
    motionModel.Q = diag([1, 0.1, 1, 0.1]);
    config.motionModel = motionModel;
    
    measurementModel = struct();
    measurementModel.H = [1, 0, 0, 0; 0, 0, 1, 0];
    measurementModel.R = eye(2) * 5;
    config.measurementModel = measurementModel;
    
    birthModel = struct();
    birthModel.intensity = 0.1;
    birthModel.means = [250, 0, 250, 0]';
    birthModel.covs = diag([100, 25, 100, 25]);
    birthModel.weights = 1;
    config.birthModel = birthModel;
end

function measurements = create_test_measurements(numMeasurements)
    % CREATE_TEST_MEASUREMENTS 创建测试测量数据
    
    if nargin < 1
        numMeasurements = 2;
    end
    
    measurements = 200 + 50 * randn(2, numMeasurements);
end
