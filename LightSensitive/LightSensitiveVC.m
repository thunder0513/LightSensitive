//
//  LightSensitiveVC.m
//  LightSensitive
//
//  Created by Thunder on 2017/10/11.
//  Copyright © 2017年 Thunder. All rights reserved.
//

#import "LightSensitiveVC.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>

@interface LightSensitiveVC () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;

@property (weak, nonatomic) IBOutlet UIButton *torchSwitchBtn;

@end

@implementation LightSensitiveVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"光感";
    // 设置光感
    [self lightSensitiveSetting];
}

#pragma mark - 设置光感
- (void)lightSensitiveSetting
{
    // 获取硬件设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 创建输入流
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc]initWithDevice:device error:nil];
    // 创建设备输出流
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // AVCaptureSession属性
    self.session = [[AVCaptureSession alloc]init];
    // 设置为高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    // 添加会话输入和输出
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
    // 启动会话
    [self.session startRunning];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // 获取环境光感参数
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    // 根据brightnessValue的值来现实隐藏闪光灯开关按钮
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL result = [device hasTorch];// 判断设备是否有闪光灯
    if (result && device.torchMode == AVCaptureTorchModeOff) {
        if (brightnessValue < 0 && _torchSwitchBtn.hidden == YES) {
            [UIView animateWithDuration:0.4 animations:^{
                _torchSwitchBtn.hidden = NO;
            }];
        } else if(brightnessValue > 0 && _torchSwitchBtn.hidden == NO) {
            [UIView animateWithDuration:0.4 animations:^{
                _torchSwitchBtn.hidden = YES;
            }];
        }
    }
}

- (IBAction)torchSwitchAction:(UIButton *)sender
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL result = [device hasTorch];
    if (result) {
        if (sender.selected == NO) {
            // 打开闪光灯
            [device lockForConfiguration:nil];
            [device setTorchMode: AVCaptureTorchModeOn];
            [device unlockForConfiguration];
            [sender setTitle:@"关闭照明" forState:UIControlStateNormal];
            sender.selected = YES;
        } else if(sender.selected == YES) {
            // 关闭闪光灯
            [device lockForConfiguration:nil];
            [device setTorchMode: AVCaptureTorchModeOff];
            [device unlockForConfiguration];
            [sender setTitle:@"环境较暗 开启照明" forState:UIControlStateNormal];
            sender.selected = NO;
        }
    }
}

@end
