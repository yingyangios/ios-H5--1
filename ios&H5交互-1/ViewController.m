//
//  ViewController.m
//  ios&H5交互-1
//
//  Created by zhaoyan on 4/27/16.
//  Copyright © 2016 ZY. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIWebViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) UIWebView *webView;

@property (strong, nonatomic) NSString *callback;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"H5&iOS";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSURL *fileURL = [NSURL fileURLWithPath:htmlPath];
    NSURLRequest *loadRequest = [NSURLRequest requestWithURL:fileURL];
    
    UIWebView *webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    webView.scalesPageToFit = YES;
    webView.dataDetectorTypes = UIDataDetectorTypePhoneNumber;
    webView.delegate = self;
    [webView loadRequest:loadRequest];
    self.webView = webView;
    
    [self.view addSubview:self.webView];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(_webView.loading)
    {
        [_webView stopLoading];
    }
    
    NSLog(@"master");
    
//    _webView.delegate = nil;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSString *errorHTML = [NSString stringWithFormat:@"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",error.localizedDescription];
    [_webView loadHTMLString:errorHTML baseURL:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *scheme = [request.URL scheme];
    if([@"js-call" isEqualToString:scheme])
    {
        UIImagePickerControllerSourceType sourceType;
        NSString *resourceSpecifier = [request.URL resourceSpecifier];
        if([@"//camera" isEqualToString:resourceSpecifier])
        {
            sourceType = UIImagePickerControllerSourceTypeCamera;
            _callback = @"getImageFromCamera";
        }
        else if([@"//photoLibrary" isEqualToString:resourceSpecifier])
        {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            _callback = @"getImageFromPhotoLibrary";
        }
        
        if([UIImagePickerController isSourceTypeAvailable:sourceType])
        {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
            imagePicker.sourceType = sourceType;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = YES;
            
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
        else
        {
            if(sourceType == UIImagePickerControllerSourceTypeCamera)
            {
                [_webView stringByEvaluatingJavaScriptFromString:@"alert('设备中摄像头')"];
            }
            else
            {
                [_webView stringByEvaluatingJavaScriptFromString:@"alert('设备中无图片')"];
            }
        }
        
        return NO;
    }
    
    return YES;
}

#pragma mark - UIImagePickerViewControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *editImage = info[UIImagePickerControllerEditedImage];
    NSString *imageData = [UIImagePNGRepresentation(editImage) base64Encoding];

    [picker dismissViewControllerAnimated:YES completion:^{
        
        /**
          You must perform the method on MainThread!
         */
        [_webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:[NSString stringWithFormat:@"%@(\"%@\")",_callback,imageData] waitUntilDone:NO];
        
    }];
}


@end
