//
//  MyCameraViewController.m
//  MyCamera
//
//  Created by 珍玮 on 16/6/20.
//  Copyright © 2016年 ZhenWei. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height


#import "MyCameraViewController.h"
#import <AVFoundation/AVFoundation.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface MyCameraViewController ()<UIAlertViewDelegate,UIGestureRecognizerDelegate>{
    BOOL isUsingFrontFacingCamera;//判断是前置摄像头还是后置摄像头
}

@property (nonatomic, strong) AVCaptureDevice *device;//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic,strong)AVCaptureSession *session;//输出和输入设备之间的传递数据，控制输入和输出设备之间的数据传递
@property(nonatomic,strong)AVCaptureDeviceInput *videoInput;//输入设备，调用所有的输入硬件。例如摄像头和麦克风
@property(nonatomic,strong)AVCaptureStillImageOutput *stillImageOutput;//照片输出流，用于输出图像
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;//预览图层，镜头捕捉到得预览图层

@property(nonatomic,strong)UIImage *image;

@property(nonatomic,assign)CGFloat beginGestureScale;//记录开始的缩放比例

@property(nonatomic,assign)CGFloat effectiveScale;//最后的缩放比例
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;//闪光灯切换按钮
@property (weak, nonatomic) IBOutlet UIButton *swichBtn;//前后摄像头切换按钮
@property (weak, nonatomic) IBOutlet UIImageView *focusView;


@end

@implementation MyCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initAVCaptureSession];
    
    [self addPinchGesture];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //开启session
    if (self.session) {
        [self.session startRunning];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    //关闭session
    if (self.session) {
        [self.session stopRunning];
    }
}


-(void)initAVCaptureSession{
    
    isUsingFrontFacingCamera = NO;
    self.beginGestureScale = 1.0;
    self.effectiveScale = 1.0;
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.device = device;
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [self.flashBtn setTitle:@"闪光灯自动" forState:0];
    
    if ([device position] == AVCaptureDevicePositionBack){
        [self.swichBtn setTitle:@"后置摄像头" forState:0];
    }else{
        [self.swichBtn setTitle:@"前置摄像头" forState:0];
    }

    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置，输出为JPEG格式图片
    NSDictionary *outSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecKey,AVVideoCodecJPEG, nil];
    self.stillImageOutput.outputSettings = outSettings;
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    self.previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    self.view.layer.masksToBounds = YES;
    
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
}

//给视图添加缩放手势
-(void)addPinchGesture{
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
}
//缩放手势相应事件
-(void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSInteger numTouches = [pinchGesture numberOfTouches],i;
    
    for (i = 0; i < numTouches; ++i) {
        CGPoint location = [pinchGesture locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location toLayer:self.previewLayer];
        
        if (![self.previewLayer containsPoint:convertedLocation]) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
        
    }
    
    if (allTouchesAreOnThePreviewLayer) {
        self.effectiveScale = self.beginGestureScale * pinchGesture.scale;
        if (self.effectiveScale < 1.0) {
            self.effectiveScale = 1.0;
        }
    }
    
    NSLog(@"%f-----%f-------pinchGesture.scale%f",self.effectiveScale,self.beginGestureScale,pinchGesture.scale);
    
    CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoScaleAndCropFactor];
    
    NSLog(@"------%f",maxScaleAndCropFactor);
    
    if (self.effectiveScale > maxScaleAndCropFactor) {
        self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        
    }
    
}

//在缩放手势开始的时候进行设置起始缩放值
-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}


//进行判断设备左右
-(AVCaptureVideoOrientation)avOritentationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        result = AVCaptureVideoOrientationLandscapeRight;
    }else if(deviceOrientation == UIDeviceOrientationLandscapeLeft){
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    return result;
}


//取消返回按钮事件
- (IBAction)backBtnAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
//切换前置摄像头和后置摄像头
- (IBAction)switchCameraSegmentedControlClick:(id)sender {
//    NSLog(@"%ld",(long)sender.selectedSegmentIndex);
    
    //给摄像头的切换添加翻转动画
    CATransition *animation = [CATransition animation];
    animation.duration = .5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = @"oglFlip";
    
    
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera){
        desiredPosition = AVCaptureDevicePositionBack;
        animation.subtype = kCATransitionFromLeft;//动画翻转方向
    }else{
        desiredPosition = AVCaptureDevicePositionFront;
        animation.subtype = kCATransitionFromRight;//动画翻转方向
    }
    //添加翻转动画
    [self.previewLayer addAnimation:animation forKey:nil];
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            
            if ([d position] == AVCaptureDevicePositionBack){
                [self.swichBtn setTitle:@"后置摄像头" forState:0];
            }else{
                [self.swichBtn setTitle:@"前置摄像头" forState:0];
            }
            
            break;
        }
    }
    
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

//闪光灯设置
- (IBAction)flashButtonClick:(UIButton *)sender {
    NSLog(@"flashButtonClick");
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //修改前必须先锁定
    [device lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
        
        NSLog(@"设备===%ld",device.flashMode);
        
        if (device.flashMode == AVCaptureFlashModeAuto) {
            
            device.flashMode = AVCaptureFlashModeOn;
            [sender setTitle:@"打开闪光" forState:0];
        }else if (device.flashMode == AVCaptureFlashModeOn) {
            
            device.flashMode = AVCaptureFlashModeOff;
            [sender setTitle:@"关闭闪光" forState:0];
        }else if (device.flashMode == AVCaptureFlashModeOff) {
            
            device.flashMode = AVCaptureFlashModeAuto;
            [sender setTitle:@"自动闪光" forState:0];
        }
        
    } else {
        
        NSLog(@"设备不支持闪光灯");
    }
    [device unlockForConfiguration];
}


//拍照按钮事件
- (IBAction)takePhotoAvtion:(id)sender {
    
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!stillImageConnection) {
        NSLog(@"拍照失败！");
        return;
    }
    
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOritentationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
//    [stillImageConnection setVideoScaleAndCropFactor:1];
    //设置相机焦距为结束后的缩放值
    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
    //拍照
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        //判断有没有拿到图片数据
        if (imageDataSampleBuffer == nil) {
            NSLog(@"没有拍到照片");
            return ;
        }
        
        NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        self.image = [UIImage imageWithData:data];
        
        [self.session stopRunning];
        
        //判断有没有访问相册的权限
        PHAuthorizationStatus authors = [PHPhotoLibrary authorizationStatus];
        if(authors == PHAuthorizationStatusRestricted || authors == PHAuthorizationStatusDenied){
            NSLog(@"没有访问相册的权限");
            return ;//无权限
        }
        
        //将图片保存到相册
        UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
    }];
    
}

//保存结果的回调
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存图片失败!" ;
    }else{
        msg = @"保存图片成功!" ;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存图片结果提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}


//AVCaptureFlashMode  闪光灯
//AVCaptureFocusMode  对焦
//AVCaptureExposureMode  曝光
//AVCaptureWhiteBalanceMode  白平衡
//闪光灯和白平衡可以在生成相机时候设置
//曝光要根据对焦点的光线状况而决定,所以和对焦一块写
//point为点击的位置
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    [self focusAtPoint:point];
    
}

//设置对焦点
- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        //对焦模式和对焦点
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        //曝光模式和曝光点
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        //设置对焦动画
        _focusView.center = point;
        _focusView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            _focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                _focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                _focusView.hidden = YES;
            }];
        }];
    }
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
