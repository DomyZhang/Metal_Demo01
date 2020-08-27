//
//  MyMetalRender.m
//  Metal_Demo01
//
//  Created by Domy on 2020/8/27.
//  Copyright © 2020 Domy. All rights reserved.
//

#import "MyMetalRender.h"
#import "MyVertex.h"

// 定义颜色结构体
typedef struct {
    float red, green, blue, alpha;
} Color;

@implementation MyMetalRender
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    
    // 渲染管道有 顶点着色器和片元着色器 它们存储在 .metal shader 文件中
    id<MTLRenderPipelineState> _pipelineState;
    
    // 当前视图大小,这样我们可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
}

- (id)initWithMTKView:(MTKView *)mtkView {
    
    if (self = [super init]) {
        
        // 1.获取 GPU 设备
        _device = mtkView.device;
        
        // 2.在项目中加载所有的(.metal)着色器文件
        // 从bundle中获取.metal文件
        id<MTLLibrary> defaultLib = [_device newDefaultLibrary];
        // 顶点/片元函数
        id<MTLFunction> vertexFunc = [defaultLib newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunc = [defaultLib newFunctionWithName:@"fragmentShader"];
        
        // 3.配置用于创建管道状态的管道
        MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDescriptor.label = @"Simple Pipeline";
        // 可编程顶点/片元函数, 用于处理渲染过程中的各个顶点
        pipelineDescriptor.vertexFunction = vertexFunc;
        pipelineDescriptor.fragmentFunction = fragmentFunc;
        // 一组存储颜色数据的组件
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        // 4.同步创建并返回 渲染管线状态对象
        NSError *error = NULL;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        // 判断是否返回了管线状态对象
        if (!_pipelineState) {
            // 如果没有正确设置管道描述符，则管道状态创建可能失败
            NSLog(@"Failed to created pipeline state, error %@", error);
            return nil;
        }
        
        // 创建命令队列
        _commandQueue = [_device newCommandQueue];
        
    }
    
//    if (self = [super init]) {
//        _device = mtkView.device;
//        // 所有应用程序需要与GPU交互的第一个对象是一个对象。MTLCommandQueue.
//        // 你使用MTLCommandQueue 去创建对象,并且加入MTLCommandBuffer 对象中.确保它们能够按照正确顺序发送到GPU.对于每一帧,一个新的MTLCommandBuffer 对象创建并且填满了由GPU执行的命令.
//        _commandQueue = [_device newCommandQueue];
//    }
    return self;
}

//// 设置颜色
//- (Color)configColor {
//
//    // 1. 增加颜色/减小颜色的 标记
//    static BOOL       growing = YES;
//    // 2.颜色通道值(0~3)
//    static NSUInteger primaryChannel = 0;
//    // 3.颜色通道数组 colorChannels(颜色值) --> 初始值：红色 透明度1
//    static float      colorChannels[] = {1.0, 0.0, 0.0, 1.0};
//    // 4.颜色调整步长 -- 每次变化
//    const float DynamicColorRate = 0.015;
//
//    // 5.判断
//    if(growing) {
//        // 动态信道索引 (1,2,3,0)通道间切换
//        NSUInteger dynamicChannelIndex = (primaryChannel+1)%3;
//
//        // 修改对应通道的颜色值 调整0.015
//        colorChannels[dynamicChannelIndex] += DynamicColorRate;
//
//        // 当颜色通道对应的颜色值 = 1.0
//        if(colorChannels[dynamicChannelIndex] >= 1.0) {
//            // 设置为NO
//            growing = NO;
//
//            // 将颜色通道修改为动态颜色通道
//            primaryChannel = dynamicChannelIndex;
//        }
//    }
//    else {
//        // 获取动态颜色通道
//        NSUInteger dynamicChannelIndex = (primaryChannel+2)%3;
//
//        // 将当前颜色的值 减去0.015
//        colorChannels[dynamicChannelIndex] -= DynamicColorRate;
//
//        // 当颜色值小于等于0.0
//        if(colorChannels[dynamicChannelIndex] <= 0.0) {
//            // 又调整为颜色增加
//            growing = YES;
//        }
//    }
//
//    // 创建颜色
//    Color color;
//    // 修改颜色的RGBA的值
//    color.red   = colorChannels[0];
//    color.green = colorChannels[1];
//    color.blue  = colorChannels[2];
//    color.alpha = colorChannels[3];
//
//    // 返回颜色
//    return color;
//}

#pragma mark - MTKView delegate -
// 每当视图渲染时 调用
- (void)drawInMTKView:(nonnull MTKView *)view {
    
    // 1. 顶点/颜色 数据
    static const MyVertex triangleVertices[] =
    {
        // 顶点 xyzw,                 颜色值RGBA
        { {  0.5, -0.25, 0.0, 1.0 }, { 1, 0, 0, 1 } },
        { { -0.5, -0.25, 0.0, 1.0 }, { 0, 1, 0, 1 } },
        { { -0.0f, 0.25, 0.0, 1.0 }, { 0, 0, 1, 1 } },
    };
    // 2.为当前渲染的每个渲染 传递 创建 一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandBuffer";
    
    // 3.MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor) {
        // 4.创建 渲染命令编码
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        // 5.设置 可绘制区域 Viewport
        /*
        typedef struct {
            double originX, originY, width, height, znear, zfar;
        } MTLViewport;
         */
        // 视口指定 Metal 渲染内容的 drawable 区域。 视口是具有x和y偏移，宽度和高度以及近和远平面的 3D 区域
        // 为管道分配自定义视口,需要通过调用 setViewport：方法将 MTLViewport 结构 编码为渲染命令编码器。 如果未指定视口，Metal会设置一个默认视口，其大小与用于创建渲染命令编码器的 drawable 相同。
        MTLViewport viewport = {
            0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0
        };
        [renderEncoder setViewport:viewport];
//        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        
        // 6.设置当前渲染管道状态对象
        [renderEncoder setRenderPipelineState:_pipelineState];

        // 7.数据传递给着色函数 -- 从应用程序(OC 代码)中发送数据给 Metal 顶点着色器 函数
        // 顶点 + 颜色
        //   1) 指向要传递给着色器的内存的指针
        //   2) 我们想要传递的数据的内存大小
        //   3)一个整数索引，它对应于我们的“vertexShader”函数中的缓冲区属性限定符的索引。
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:MyVertexInputIndexVertices];

        // viewPortSize 数据
        //  1) 发送到顶点着色函数中,视图大小
        //  2) 视图大小内存空间大小
        //  3) 对应的索引
        [renderEncoder setVertexBytes:triangleVertices length:sizeof(_viewportSize) atIndex:MyVertexInputIndexViewportSize];
        
        
        // 8.画出 三角形的 3 个顶点
        // @method drawPrimitives:vertexStart:vertexCount:
        // @brief 在不使用索引列表的情况下,绘制图元
        // @param 绘制图形组装的基元类型
        // @param 从哪个位置数据开始绘制,一般为0
        // @param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        
        // 9.编码完成 - 表示该编码器生成的命令都已完成,并且从 MTLCommandBuffer 中分离
        [renderEncoder endEncoding];
        
        // 10.一旦框架缓冲区完成，使用当前可绘制的进度表
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    // 11. 最后,完成渲染并将命令缓冲区推送到 GPU
    [commandBuffer commit];
    
///    绘制背景色
//    // 拿到颜色
//    Color color = [self configColor];
//
//    // 1. 设置颜色 --> 类似OpenGL ES 的 clearColor
//    view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha);
//    // 2. Create a new command buffer for each render pass to the current drawable
//    // 使用MTLCommandQueue 创建对象并且加入到MTCommandBuffer对象中去.
//    // 为当前渲染的每个渲染传递创建一个新的命令缓冲区
//    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
//    commandBuffer.label = @"MyCommandBuffer";
//
//    // 3.从视图中,获得 渲染描述符
//    MTLRenderPassDescriptor *renderDescriptor = view.currentRenderPassDescriptor;
//    if (renderDescriptor) {
//
//        // 4.通过渲染描述符 renderPassDescriptor  创建 MTLRenderCommandEncoder 对象
//        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderDescriptor];
//        renderEncoder.label = @"MyRenderEncoder";
//
//        // 5.我们可以使用 MTLRenderCommandEncoder 来绘制对象,此 demo 仅仅创建编码器就可以了,我们并没有让 Metal 去执行我们绘制的东西,这个时候表示我们的任务已经完成.
//        // 即: 可结束 MTLRenderCommandEncoder 工作
//        [renderEncoder endEncoding];
//
//        /*
//         当编码器结束之后,命令缓存区就会接受到 2 个命令.
//         1) present
//         2) commit
//         因为 GPU 是不会直接绘制到屏幕上,因此若不给出指令，则不会有任何内容渲染到屏幕上.
//        */
//        // 6.添加最后一个命令 来显示清楚的可绘制的屏幕
//        [commandBuffer presentDrawable:view.currentDrawable];
//
//    }
//    // 7. 完成渲染并将命令缓冲区提交给 GPU
//    [commandBuffer commit];
}

// 当 MTKView 视图发生大小改变时调用
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
    // 保存可绘制的大小，绘制时，将会把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

@end
