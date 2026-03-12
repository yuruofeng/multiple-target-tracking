% tests/unit/TestFilterConfig.m
% TESTFILTERCONFIG FilterConfig单元测试

classdef TestFilterConfig < matlab.unittest.TestCase
    % TESTFILTERCONFIG FilterConfig类单元测试
    
    properties
        TestConfig
        DefaultTolerance = 1e-6
    end
    
    methods (TestMethodSetup)
        function setup(testCase)
            % 创建默认配置
            testCase.TestConfig = FilterConfig();
        end
    end
    
    methods (Test)
        function testDefaultValues(testCase)
            % 测试默认值
            
            config = testCase.TestConfig;
            
            % 验证默认值
            testCase.assertEqual(config.detectionProb, 0.9);
            testCase.assertEqual(config.survivalProb, 0.99);
            testCase.assertEqual(config.pruningThreshold, 1e-5);
            testCase.assertEqual(config.maxComponents, 100);
            
            % 验证运动模型
            testCase.assertNotEmpty(config.motionModel.F);
            testCase.assertNotEmpty(config.motionModel.Q);
            
            % 验证量测模型
            testCase.assertNotEmpty(config.measurementModel.H);
            testCase.assertNotEmpty(config.measurementModel.R);
        end
        
        function testCustomValues(testCase)
            % 测试自定义值
            
            config = FilterConfig(...
                'detectionProb', 0.95, ...
                'survivalProb', 0.98, ...
                'pruningThreshold', 1e-4, ...
                'maxComponents', 50 ...
            );
            
            % 验证自定义值
            testCase.assertEqual(config.detectionProb, 0.95);
            testCase.assertEqual(config.survivalProb, 0.98);
            testCase.assertEqual(config.pruningThreshold, 1e-4);
            testCase.assertEqual(config.maxComponents, 50);
        end
        
        function testValidation(testCase)
            % 测试验证功能
            
            config = testCase.TestConfig;
            
            % 有效配置应该通过
            testCase.assertTrue(config.isValid);
            
            % 无效配置
            invalidConfig = FilterConfig();
            invalidConfig.motionModel.F = [];
            
            try
                invalidConfig.validate();
                testCase.verifyFail('无效配置应该抛出异常');
            catch ME
                testCase.verifyEqual(ME.errorCode, utils.ErrorCode.INVALID_CONFIG);
            end
        end
        
        function testInvalidParameter(testCase)
            % 测试无效参数
            
            config = testCase.TestConfig;
            
            % 无效检测概率
            try
                config.detectionProb = 1.5;
                testCase.verifyFail('检测概率 > 1 应该抛出异常');
            catch
                testCase.assertTrue(true);
            end
            
            % 无效存活概率
            try
                config.survivalProb = -0.1;
                testCase.verifyFail('存活概率 < 0 应该抛出异常');
            catch
                testCase.assertTrue(true);
            end
        end
    end
end
