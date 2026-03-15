function test_integration()
% TEST_INTEGRATION 集成测试函数
%
% 测试所有重构后的模块是否正常工作

fprintf('\n===== 开始集成测试 =====\n\n');

% 1. 测试数据关联模块
fprintf('1. 测试数据关联模块...\n');
test_assignment();

% 2. 测试度量模块
fprintf('\n2. 测试度量模块...\n');
test_metric();

% 3. 测试TPHD滤波器
fprintf('\n3. 测试TPHD滤波器...\n');
test_tphd();

% 4. 测试TPMBM滤波器
fprintf('\n4. 测试TPMBM滤波器...\n');
test_tpmbm();

fprintf('\n===== 集成测试完成 =====\n\n');
end

function test_assignment()
% 测试数据关联模块

% 创建成本矩阵
costMatrix = [10 2 3;
              4 7 1;
              5 8 6];

% 测试Murty算法
fprintf('  - 测试Murty算法...');
try
    murty = assignment.Murty(3);
    [assignments, costs] = murty.solve(costMatrix);
    fprintf(' ✓\n');
    fprintf('    最佳分配: %s\n', mat2str(assignments(:,1)));
    fprintf('    最佳成本: %.2f\n', costs(1));
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end

% 测试Auction算法
fprintf('  - 测试Auction算法...');
try
    auction = assignment.Auction();
    [personToObj, objToPerson, cost] = auction.solve(costMatrix);
    fprintf(' ✓\n');
    fprintf('    分配结果: %s\n', mat2str(personToObj));
    fprintf('    总成本: %.2f\n', cost);
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end

% 测试Munkres算法
fprintf('  - 测试Munkres算法...');
try
    munkres = assignment.Munkres();
    [assignment, cost] = munkres.solve(costMatrix);
    fprintf(' ✓\n');
    fprintf('    分配结果: %s\n', mat2str(assignment));
    fprintf('    总成本: %.2f\n', cost);
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end

% 测试分配工厂
fprintf('  - 测试分配工厂...');
try
    factory = assignment.AssignmentFactory();
    algorithm = factory.createAlgorithm('Murty', 2);
    [assignments, costs] = algorithm.solve(costMatrix);
    fprintf(' ✓\n');
    fprintf('    工厂创建成功\n');
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end
end

function test_metric()
% 测试度量模块

% 创建测试数据
x = [1 2 3;
     4 5 6];
y = [1.1 2.2 3.3;
     4.4 5.5 6.6];

% 测试GOSPA度量
fprintf('  - 测试GOSPA度量...');
try
    gospa = metric.GOSPA('p', 2, 'c', 10, 'alpha', 2);
    [distance, assignment, decomposition] = gospa.compute(x, y);
    fprintf(' ✓\n');
    fprintf('    GOSPA距离: %.4f\n', distance);
    fprintf('    定位误差: %.4f\n', decomposition.localisation);
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end

% 测试度量工厂
fprintf('  - 测试度量工厂...');
try
    factory = metric.MetricFactory();
    gospa = factory.createMetric('GOSPA', 'p', 2, 'c', 10);
    [distance, ~, ~] = gospa.compute(x, y);
    fprintf(' ✓\n');
    fprintf('    工厂创建成功\n');
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end
end

function test_tphd()
% 测试TPHD滤波器

% 创建配置
F = [1 1 0 0;
     0 1 0 0;
     0 0 1 1;
     0 0 0 1];
Q = 0.1 * eye(4);
H = [1 0 0 0;
     0 0 1 0];
R = 0.1 * eye(2);

config = utils.FilterConfig('motionModel', struct('type', 'CV', 'F', F, 'Q', Q), ...
                           'measurementModel', struct('type', 'Linear', 'H', H, 'R', R), ...
                           'pruningThreshold', 1e-4, ...
                           'maxComponents', 30, ...
                           'Lscan', 5);

config.extraParams.Lscan = 5;
config.extraParams.maxComponents = 30;
config.extraParams.absorptionThreshold = 4;

% 测试TPHD滤波器
fprintf('  - 测试TPHD滤波器...');
try
    filter = tphd.GMTPHD(config);
    filter = filter.initialize();
    
    % 创建测试测量
    measurement = [1 2;
                   3 4];
    
    filter = filter.predict();
    filter = filter.update(measurement);
    estimate = filter.estimate();
    
    fprintf(' ✓\n');
    fprintf('    滤波器初始化成功\n');
    fprintf('    估计目标数: %d\n', estimate.cardinality);
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end

% 测试TPHD工厂
fprintf('  - 测试TPHD工厂...');
try
    factory = tphd.TPHDFactory();
    filter = factory.createFromPreset('standard', 'motionModel', struct('type', 'CV', 'F', F, 'Q', Q), ...
                                     'measurementModel', struct('type', 'Linear', 'H', H, 'R', R));
    fprintf(' ✓\n');
    fprintf('    工厂创建成功\n');
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end
end

function test_tpmbm()
% 测试TPMBM滤波器

% 创建配置
F = [1 1 0 0;
     0 1 0 0;
     0 0 1 1;
     0 0 0 1];
Q = 0.1 * eye(4);
H = [1 0 0 0;
     0 0 1 0];
R = 0.1 * eye(2);

config = utils.FilterConfig('motionModel', struct('type', 'CV', 'F', F, 'Q', Q), ...
                           'measurementModel', struct('type', 'Linear', 'H', H, 'R', R), ...
                           'pruningThreshold', 1e-4);

config.extraParams.gateSize = 9.210;
config.extraParams.maxGlobalHypotheses = 1000;
config.extraParams.minGlobalHypothesisWeight = 1e-4;
config.extraParams.numMinimumAssignment = 100;
config.extraParams.minEndTimeProbability = 1e-4;
config.extraParams.minBirthTimeProbability = 1e-1;
config.extraParams.minExistenceProbability = 1e-4;
config.extraParams.totalTimeSteps = 10;

% 测试TPMBM滤波器
fprintf('  - 测试TPMBM滤波器...');
try
    filter = tpmbm.TPMBM(config);
    filter = filter.initialize();
    
    % 创建测试测量
    measurement = [1 2;
                   3 4];
    
    filter = filter.predict();
    filter = filter.update(measurement);
    estimate = filter.estimate();
    
    fprintf(' ✓\n');
    fprintf('    滤波器初始化成功\n');
    fprintf('    估计目标数: %d\n', estimate.cardinality);
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end

% 测试TPMBM工厂
fprintf('  - 测试TPMBM工厂...');
try
    factory = tpmbm.TPMBMFactory();
    filter = factory.createFromPreset('standard', 'motionModel', struct('type', 'CV', 'F', F, 'Q', Q), ...
                                     'measurementModel', struct('type', 'Linear', 'H', H, 'R', R));
    fprintf(' ✓\n');
    fprintf('    工厂创建成功\n');
catch ME
    fprintf(' ✗\n');
    fprintf('    错误: %s\n', ME.message);
end
end
