function test_performance()
% TEST_PERFORMANCE 性能测试函数
%
% 测试各算法的性能

fprintf('\n===== 开始性能测试 =====\n\n');

% 1. 测试数据关联算法性能
fprintf('1. 测试数据关联算法性能...\n');
test_assignment_performance();

% 2. 测试度量算法性能
fprintf('\n2. 测试度量算法性能...\n');
test_metric_performance();

% 3. 测试滤波器性能
fprintf('\n3. 测试滤波器性能...\n');
test_filter_performance();

fprintf('\n===== 性能测试完成 =====\n\n');
end

function test_assignment_performance()
% 测试数据关联算法性能

% 测试不同规模的成本矩阵
matrixSizes = [10, 20, 50, 100];

for i = 1:length(matrixSizes)
    n = matrixSizes(i);
    fprintf('  - 测试 %dx%d 成本矩阵...\n', n, n);
    
    % 创建随机成本矩阵
    costMatrix = rand(n, n);
    
    % 测试Murty算法
    fprintf('    Murty算法: ');
    tic;
    try
        murty = assignment.Murty(5);
        [~, ~] = murty.solve(costMatrix);
        t = toc;
        fprintf('%.4f 秒\n', t);
    catch ME
        fprintf('错误: %s\n', ME.message);
    end
    
    % 测试Auction算法
    fprintf('    Auction算法: ');
    tic;
    try
        auction = assignment.Auction();
        [~, ~, ~] = auction.solve(costMatrix);
        t = toc;
        fprintf('%.4f 秒\n', t);
    catch ME
        fprintf('错误: %s\n', ME.message);
    end
    
    % 测试Munkres算法
    fprintf('    Munkres算法: ');
    tic;
    try
        munkres = assignment.Munkres();
        [~, ~] = munkres.solve(costMatrix);
        t = toc;
        fprintf('%.4f 秒\n', t);
    catch ME
        fprintf('错误: %s\n', ME.message);
    end
end
end

function test_metric_performance()
% 测试度量算法性能

% 测试不同规模的目标集合
targetCounts = [10, 50, 100, 200];

for i = 1:length(targetCounts)
    n = targetCounts(i);
    fprintf('  - 测试 %d 个目标...\n', n);
    
    % 创建随机目标集合
    x = rand(2, n);
    y = x + 0.01 * randn(2, n);
    
    % 测试GOSPA度量
    fprintf('    GOSPA度量: ');
    tic;
    try
        gospa = metric.GOSPA('p', 2, 'c', 10, 'alpha', 2);
        [~, ~, ~] = gospa.compute(x, y);
        t = toc;
        fprintf('%.4f 秒\n', t);
    catch ME
        fprintf('错误: %s\n', ME.message);
    end
end
end

function test_filter_performance()
% 测试滤波器性能

% 创建配置
F = [1 1 0 0;
     0 1 0 0;
     0 0 1 1;
     0 0 0 1];
Q = 0.1 * eye(4);
H = [1 0 0 0;
     0 0 1 0];
R = 0.1 * eye(2);

% 测试TPHD滤波器
fprintf('  - 测试TPHD滤波器...\n');
config = utils.FilterConfig('motionModel', struct('type', 'CV', 'F', F, 'Q', Q), ...
                           'measurementModel', struct('type', 'Linear', 'H', H, 'R', R), ...
                           'pruningThreshold', 1e-4);

config.extraParams.Lscan = 5;
config.extraParams.maxComponents = 30;
config.extraParams.absorptionThreshold = 4;

fprintf('    初始化: ');
tic;
try
    filter = tphd.GMTPHD(config);
    filter = filter.initialize();
    t = toc;
    fprintf('%.4f 秒\n', t);
    
    % 测试预测和更新
    fprintf('    预测和更新: ');
    tic;
    for i = 1:10
        measurement = rand(2, 5);
        filter = filter.predict();
        filter = filter.update(measurement);
        estimate = filter.estimate();
    end
    t = toc;
    fprintf('%.4f 秒 (10次迭代)\n', t);
catch ME
    fprintf('错误: %s\n', ME.message);
end

% 测试TPMBM滤波器
fprintf('  - 测试TPMBM滤波器...\n');
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

fprintf('    初始化: ');
tic;
try
    filter = tpmbm.TPMBM(config);
    filter = filter.initialize();
    t = toc;
    fprintf('%.4f 秒\n', t);
    
    % 测试预测和更新
    fprintf('    预测和更新: ');
    tic;
    for i = 1:5
        measurement = rand(2, 3);
        filter = filter.predict();
        filter = filter.update(measurement);
        estimate = filter.estimate();
    end
    t = toc;
    fprintf('%.4f 秒 (5次迭代)\n', t);
catch ME
    fprintf('错误: %s\n', ME.message);
end
end
