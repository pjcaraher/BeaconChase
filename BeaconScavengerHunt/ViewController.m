//
//  ViewController.m
//  BeaconScavengerHunt
//
//  Created by Patrick Caraher on 12/18/14.
//  Copyright (c) 2014 Mustang Data Management. All rights reserved.
//

#import "ViewController.h"
#import "BSHConfigurationManager.h"
#import "BSHWebViewController.h"
#import "BSHSettingsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

#define kOpenWebURLSegue @"openWebUrlSegue"
#define kOpenSettingsSegue @"openSettingsSegue"

#define kButtonTitleScan @"PRESS TO SCAN"
#define kButtonTitleCancel @"CANCEL"

#define kArchiveFileName @"configuration.data"


@interface ViewController () <UITableViewDelegate,BSHBeaconActionDelegate,AVCaptureMetadataOutputObjectsDelegate,MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) IBOutlet BSHConfigurationManager *configurationManager;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIImageView *headerImageView;
@property (strong, nonatomic) IBOutlet UILabel *headerDescriptionLabel;
@property (weak, nonatomic) IBOutlet UITableView *beaconsTableView;
@property (strong, nonatomic) IBOutlet UIView *qrCodeView;
@property (strong, nonatomic) IBOutlet UIView *settingsView;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) IBOutlet UIView *viewPreview;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIButton *scanCancelButton;
@property (nonatomic, strong) MFMailComposeViewController *mailCVC;

@property BOOL completionMessageHasBeenShown;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.configurationManager.actionDelegate = self;
    self.completionMessageHasBeenShown = NO;
    [self initializeMailVC];
    
    // Check the archive.  If a configuration with Beacons exists, display it.
    [self readArchive];
    
    if (self.configurationManager.hasBeacons)
    {
        [self removeScanView];
        [self completeConfigurationUpdate];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.beaconsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkForCompletion];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)test_cancelQRScanClicked:(id)sender
{
    [self.configurationManager loadConfigurationAtURLString:@"http://Patricks-MacBook-Pro-4.local/BeaconScavengerHunt" completionHandler:^(BOOL success, NSError *error){
        NSLog(@"Returned success of [%@]", (success) ? @"YES" : @"NO");
        
        [self performSelectorOnMainThread:@selector(removeScanView) withObject:nil waitUntilDone:NO];
        
        if (success)
        {
            [self performSelectorOnMainThread:@selector(completeConfigurationUpdate) withObject:nil waitUntilDone:NO];
        }
    }];
}

- (IBAction)cancelQRScanClicked:(id)sender
{
    if ([self isScanning])
    {
        [self stopScan];
    }
    else
    {
        [self startScan];
    }
}

- (IBAction)settingsButtonClicked:(id)sender
{
    [self showSettings];
}

- (IBAction)cancelSettingsButtonClicked:(id)sender
{
    [self hideSettings];
}

- (IBAction)clearFoundBeacons:(id)sender
{
    [self.configurationManager markAllBeaconsAsUnseen];
    [self hideSettings];
    [self.beaconsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)clearScavengerHunt
{
    [self hideSettings];
    [self.configurationManager clear];
    self.headerDescriptionLabel.text = @"";
    self.headerImageView.image = nil;
    [self.beaconsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    [self showScanView];
}

- (void)hideSettings
{
//    self.settingsView.hidden = YES;
}

- (void)showSettings
{
//    self.settingsView.hidden = NO;
}

-(void)startScan
{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    [self updateScanButtonTitle:kButtonTitleCancel];
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
}

-(void)stopScan
{
    [self updateScanButtonTitle:kButtonTitleScan];
    
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
}

-(void)updateScanButtonTitle:(NSString *)title
{
    [self.scanCancelButton setTitle:title forState:UIControlStateNormal];
}

-(BOOL)isScanning
{
    return ([kButtonTitleCancel compare:self.scanCancelButton.titleLabel.text] == NSOrderedSame);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:kOpenWebURLSegue])
    {
        // Get reference to the destination view controller
        BSHWebViewController *vc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        [vc setUrlString:sender];
    }
    else if ([[segue identifier] isEqualToString:kOpenSettingsSegue])
    {
        BSHSettingsViewController *vc = [segue destinationViewController];
        
        [vc setConfigurationManager:self.configurationManager];
        [vc setHomeViewController:self];
    }
}

-(void)updateTopImageUrl:(NSString *)topImageUrl
{
    if (topImageUrl)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            NSURL *imageURL = [NSURL URLWithString:topImageUrl];
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            
            //This is your completion handler
            dispatch_sync(dispatch_get_main_queue(), ^{
                //If self.image is atomic (not declared with nonatomic)
                // you could have set it directly above
                UIImage *image = [UIImage imageWithData:imageData];
                
                //This needs to be set here now that the image is downloaded
                // and you are back on the main thread
                self.headerImageView.image = image;
                
                [self.beaconsTableView reloadData];
            });
        });
    }
}

-(void)writeArchive
{
    [NSKeyedArchiver archiveRootObject:self.configurationManager toFile:[self archiveFilePath]];
}

- (void)readArchive
{
    BSHConfigurationManager *_archivedManager = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
    
    if (_archivedManager)
    {
        self.configurationManager = _archivedManager;
        self.configurationManager.actionDelegate = self;
        self.beaconsTableView.dataSource = self.configurationManager;
    }
}

- (NSString *)archiveFilePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:kArchiveFileName];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.configurationManager invokeActionForIndexPath:indexPath];
}

#pragma mark BSHBeaconActionDelegate

-(void)openUrlString:(NSString *)urlString
{
    [self performSegueWithIdentifier: @"openWebUrlSegue" sender: urlString];
}

-(void)displayMessage:(NSString *)message
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                delegate:nil
                                       cancelButtonTitle:nil
                                       otherButtonTitles:@"OK", nil];
    
    [av show];
}

-(void)sendEmailMessage:(NSString *)message withSubject:(NSString *)subject to:(NSString *)toAddress
{
    NSArray *toRecipents = [NSArray arrayWithObject:toAddress];
    
    [self.mailCVC setSubject:subject];
    [self.mailCVC setMessageBody:message isHTML:NO];
    [self.mailCVC setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:self.mailCVC animated:YES completion:NULL];
}

-(void)newBeaconHasBeenSeen
{
    [self.beaconsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

-(void)checkForCompletion
{
    if (!self.completionMessageHasBeenShown)
    {
        if ([self.configurationManager allBeaconsAreSeen])
        {
            self.completionMessageHasBeenShown = YES;
            [self.configurationManager invokeCompletionAction];
        }
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            [self performSelectorOnMainThread:@selector(removeScanView) withObject:nil waitUntilDone:NO];
            
            [self.configurationManager loadConfigurationAtURLString:[metadataObj stringValue] completionHandler:^(BOOL success, NSError *error){
                NSLog(@"Returned success of [%@]", (success) ? @"YES" : @"NO");
                
                if (success)
                {
                    [self performSelectorOnMainThread:@selector(completeConfigurationUpdate) withObject:nil waitUntilDone:NO];
                }
            }];
        }
    }
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    [self initializeMailVC];
}

-(void)removeScanView
{
    [self stopScan];
    self.qrCodeView.hidden = YES;
    self.activityIndicator.hidden = NO;
}

-(void)showScanView
{
    self.qrCodeView.hidden = NO;
    self.activityIndicator.hidden = YES;
}

// Perform on the Main Thread
-(void)completeConfigurationUpdate
{
    [self.configurationManager updateUUID:self.configurationManager.uuidString];
    self.headerDescriptionLabel.text = self.configurationManager.descriptionString;
    [self updateTopImageUrl:self.configurationManager.topImageUrlString];
    [self.beaconsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    self.activityIndicator.hidden = YES;
    self.completionMessageHasBeenShown = NO;
}

-(void)initializeMailVC
{
    self.mailCVC = [[MFMailComposeViewController alloc] init];
    self.mailCVC.mailComposeDelegate = self;
}

@end
