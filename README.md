# 🎯 多目标跟踪 (Multiple Target Tracking) 项目

## 📋 项目概述

这是一个多目标跟踪（MTT）算法的实现库，包含多种先进的多目标跟踪算法，支持不同场景下的目标跟踪任务。

## 🚀 支持的算法

### 基础滤波器

- **PHD (Probability Hypothesis Density)** 📊: 概率假设密度滤波器
  - GMPHD (Gaussian Mixture PHD) 🔄
  - GMCPHD (Gaussian Mixture Cardinalized PHD) 📈

### 轨迹滤波器

- **TPHD (Trajectory PHD)** 🛤️: 轨迹PHD滤波器
  - GMTPHD (Gaussian Mixture Trajectory PHD) 📍

### PMBM系列

- **PMB (Poisson Multi-Bernoulli)** 🎲: 泊松多伯努利滤波器
- **TPMB (Trajectory Poisson Multi-Bernoulli)** 🛣️: 轨迹泊松多伯努利滤波器
- **PMBM (Poisson Multi-Bernoulli Mixture)** 🧩: 泊松多伯努利混合滤波器
- **TPMBM (Trajectory Poisson Multi-Bernoulli Mixture)** 📏: 轨迹泊松多伯努利混合滤波器
- **TMBM (Trajectory Multi-Bernoulli Mixture)** 📎: 轨迹多伯努利混合滤波器

### 连续-离散滤波器

- **CDGMPHD (Continuous-Discrete Gaussian Mixture PHD)** ⏱️: 连续-离散高斯混合PHD滤波器
- **CDGMCPHD (Continuous-Discrete Gaussian Mixture Cardinalized PHD)** ⚡: 连续-离散高斯混合CPHD滤波器
- **CDPMBM (Continuous-Discrete Poisson Multi-Bernoulli Mixture)** 🔄⏱️: 连续-离散泊松多伯努利混合滤波器

## 📁 项目结构

```
multiple-target-tracking/
├── +assignment/          # 🔗 数据关联算法
├── +cdfilters/           # ⏱️ 连续-离散滤波器
├── +metric/              # 📏 性能评估度量
├── +phd/                 # 📊 PHD滤波器
├── +pmbm/                # 🎲 PMB和PMBM滤波器
├── +tmbm/                # 📎 TMBM滤波器
├── +tphd/                # 🛤️ TPHD滤波器
├── +tpmb/                # 🛣️ TPMB滤波器
├── +tpmbm/               # 📏 TPMBM滤波器
├── +utils/               # 🛠️ 工具类
├── +viz/                 # 📈 可视化工具
├── demos/                # 🎮 演示脚本
├── docs/                 # 📚 文档
├── tests/                # 🧪 测试文件
```

## 💻 安装和使用

### 环境要求

- MATLAB R2018a或更高版本

### 安装步骤

1. 克隆或下载项目到本地
2. 在MATLAB中添加项目根目录到搜索路径

### 基本使用

```matlab
% 创建滤波器配置
config = utils.FilterConfig();
config.detectionProb = 0.9;
config.survivalProb = 0.99;
config.clutterRate = 1e-4;
config.surveillanceArea = [1000, 1000];
config.pruningThreshold = 1e-5;
config.maxComponents = 100;
config.existenceThreshold = 1e-5;

% 配置运动模型
config.motionModel.F = eye(4);
config.motionModel.Q = eye(4) * 0.1;

% 配置测量模型
config.measurementModel.H = [1 0 0 0; 0 1 0 0];
config.measurementModel.R = eye(2) * 1;

% 配置新生模型
config.birthModel.means = zeros(4, 1);
config.birthModel.covs = eye(4);
config.birthModel.weights = 1;
config.birthModel.intensity = 0.005;

% 创建滤波器实例
filter = pmbm.PMB(config);
filter = filter.initialize();

% 处理测量数据
z = [10 20; 30 40];  % 示例测量数据
filter = filter.predict();
filter = filter.update(z);

% 获取估计结果
estimates = filter.estimate();
```

## 🧪 测试

项目包含多个测试文件，用于验证算法的正确性：

- `tests/test_integration.m` 📋: 集成测试
- `tests/test_new_algorithms.m` 🆕: 新算法测试
- `tests/test_cd_filters_integration.m` ⏱️: 连续-离散滤波器测试
- `tests/test_performance.m` ⚡: 性能测试
- `tests/unit/` 🧬: 单元测试

运行测试：

```matlab
% 运行所有测试
run('tests/test_integration.m');

% 运行新算法测试
run('tests/test_new_algorithms.m');
```

## 🎮 演示脚本

项目包含多个演示脚本，用于展示算法的使用方法：

- `demos/demo_refactored_filters.m` 🎯: 重构后的滤波器演示
- `demos/demo_filter_comparison.m` 📊: 滤波器通用对比演示应用

运行演示：

```matlab
% 运行重构后的滤波器演示
run('demos/demo_refactored_filters.m');

% 运行滤波器通用对比演示应用
run('demos/demo_filter_comparison.m');
```

### 滤波器通用对比演示应用

**功能特点**：
- 📊 **多滤波器对比**：支持选择多种滤波器进行性能对比
- ⚡ **性能测试**：测量执行时间、内存使用和跟踪精度
- 📈 **可视化展示**：提供性能对比图表和轨迹对比视图
- 💾 **结果导出**：支持CSV和MAT格式的结果导出
- 🔄 **批处理模式**：支持非交互式运行，便于自动化测试

**使用方法**：
1. 运行演示应用
2. 在主菜单中选择操作：
   - 1: 配置对比参数
   - 2: 运行对比测试
   - 3: 可视化结果
   - 4: 导出结果
   - 5: 退出应用

**批处理模式**：
```matlab
% 在MATLAB命令窗口中运行批处理模式
setenv('MATLAB_BATCH', '1');
run('demos/demo_filter_comparison.m');
```

**结果文件**：
- 批处理模式下会生成 `filter_comparison_results.csv` 文件，包含性能对比数据

## 📏 性能评估

项目提供了多种性能评估工具：

- **GOSPA (Generalized Optimal Subpattern Assignment)** 📊: 广义最优子模式分配度量
- **TrajectoryErrorCalculator** 📏: 轨迹级别的误差计算
- **TrajectoryMetric** 🎯: 轨迹度量

## 📈 可视化

项目包含轨迹可视化工具：

- **TrajectoryVisualizer** 🎨: 绘制真值轨迹和估计轨迹，显示测量数据，绘制误差历史

## 🔗 依赖关系

- **+assignment.*** 🔗: 数据关联算法
- **+metric.*** 📏: 性能评估度量
- **+utils.*** 🛠️: 工具类和配置

---

**项目版本**: 1.0
**最后更新**: 2026-03-12