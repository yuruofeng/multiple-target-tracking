classdef Murty < handle
    % MURTY Murty算法实现
    %
    % 实现Murty算法，用于获取K个最佳分配
    %
    % 参考文献:
    %   K. G. Murty, "An algorithm for ranking all the assignments in order of increasing cost", 
    %   Operations Research, vol. 16, no. 3, pp. 682–687, 1968.
    %
    % 使用示例:
    %   murty = assignment.Murty(3);
    %   [assignments, costs] = murty.solve(costMatrix);
    %
    % 版本: 2.0 (重构版)
    % 日期: 2026-03-12
    
    properties
        NumBest      (1,1) double = 1  % 要查找的k个最佳分配
        Assignments   (:,:) double = []  % k-best分配
        Costs       (:,1) double = []  % 每个分配的成本
        History     struct = struct()  % 算法历史
    end
    
    methods
        function obj = Murty(kBest)
            % MURTY 构造函数
            %
            % 输入:
            %   kBest - 要查找的最佳分配数量
            
            if nargin > 0
                obj.NumBest = kBest;
            end
        end
        
        function [assignments, costs] = solve(obj, costMatrix)
            % SOLVE 求解K最佳分配
            %
            % 输入:
            %   costMatrix - 成本矩阵
            %
            % 输出:
            %   assignments - K最佳分配
            %   costs - 每个分配的成本
            
            % 验证输入
            if ~ismatrix(costMatrix) || size(costMatrix, 1) ~= size(costMatrix, 2)
                ME = utils.MTTException(utils.ErrorCode.INVALID_INPUT, ...
                    '成本矩阵必须是方阵');
                throw(ME);
            end
            
            n = size(costMatrix, 1);
            
            % 初始化优先队列
            priorityQueue = java.util.PriorityQueue();
            
            % 计算初始最优分配
            [initialAssignment, initialCost] = assignment.Munkres.run(costMatrix);
            
            % 创建初始节点
            node = struct();
            node.cost = initialCost;
            node.assignment = initialAssignment;
            node.rowExcluded = [];
            node.colExcluded = [];
            node.level = 0;
            
            % 将初始节点加入优先队列
            priorityQueue.offer(node);
            
            % 存储结果
            assignments = zeros(obj.NumBest, n);
            costs = zeros(obj.NumBest, 1);
            
            count = 0;
            while count < obj.NumBest && ~priorityQueue.isEmpty()
                % 取出成本最小的节点
                currentNode = priorityQueue.poll();
                
                % 保存结果
                count = count + 1;
                assignments(count, :) = currentNode.assignment;
                costs(count) = currentNode.cost;
                
                % 生成子问题
                if currentNode.level < n-1
                    for i = currentNode.level + 1:n
                        % 生成子问题：排除当前分配
                        newRowExcluded = [currentNode.rowExcluded, i];
                        newColExcluded = [currentNode.colExcluded, currentNode.assignment(i)];
                        
                        % 构建子成本矩阵
                        subCostMatrix = costMatrix;
                        subCostMatrix(newRowExcluded, :) = Inf;
                        subCostMatrix(:, newColExcluded) = Inf;
                        
                        % 求解子问题
                        try
                            [subAssignment, subCost] = assignment.Munkres.run(subCostMatrix);
                            
                            % 创建子节点
                            childNode = struct();
                            childNode.cost = subCost;
                            childNode.assignment = subAssignment;
                            childNode.rowExcluded = newRowExcluded;
                            childNode.colExcluded = newColExcluded;
                            childNode.level = i;
                            
                            % 将子节点加入优先队列
                            priorityQueue.offer(childNode);
                        catch ME
                            % 子问题无解，跳过
                            continue;
                        end
                    end
                end
            end
            
            % 保存结果到对象属性
            obj.Assignments = assignments(1:count, :);
            obj.Costs = costs(1:count);
            
            % 保存历史
            obj.History = struct('numBest', obj.NumBest, 'totalFound', count, 'assignments', obj.Assignments, 'costs', obj.Costs);
        end
        
        function displayResults(obj)
            % DISPLAYRESULTS 显示结果
            
            if isempty(obj.Assignments)
                fprintf('没有结果可显示\n');
                return;
            end
            
            fprintf('\n===== Murty算法结果 =====\n');
            fprintf('请求的最佳分配数: %d\n', obj.NumBest);
            fprintf('找到的分配数: %d\n', size(obj.Assignments, 1));
            
            for i = 1:size(obj.Assignments, 1)
                fprintf('\n第 %d 最佳分配:\n', i);
                fprintf('分配: ');
                fprintf('%d ', obj.Assignments(i, :));
                fprintf('\n成本: %.4f\n', obj.Costs(i));
            end
            fprintf('====================\n\n');
        end
    end
    
    methods (Static)
        function [assignments, costs] = run(costMatrix, kBest)
            % RUN 静态方法 - 求解K最佳分配
            %
            % 输入:
            %   costMatrix - 成本矩阵
            %   kBest - 要查找的最佳分配数量
            %
            % 输出:
            %   assignments - K最佳分配
            %   costs - 每个分配的成本
            
            murty = assignment.Murty(kBest);
            [assignments, costs] = murty.solve(costMatrix);
        end
    end
end
