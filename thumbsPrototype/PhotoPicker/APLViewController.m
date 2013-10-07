/*
     File: APLViewController.m
 Abstract: Main view controller for the application.
  Version: 2.0
 
*/

#import "APLViewController.h"
#import "KTOneFingerRotationGestureRecognizer.h"

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * 180 / M_PI)

@interface APLViewController ()

// thumb management stuff
@property (nonatomic, assign) CGFloat currentAngle;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, assign) CGFloat stopAngle;
@property (nonatomic, assign) CGFloat resetAngle;
@property int thumbCount;
@property int direction;

// camera management stuff
@property (nonatomic, weak) IBOutlet UIButton *updThumb;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolBar;

@property (nonatomic) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *takePictureButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *startStopButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *delayedPhotoButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic, weak) NSTimer *cameraTimer;
@property (nonatomic) NSMutableArray *capturedImages;

@end



@implementation APLViewController

- (IBAction)thumbTouchUpInside:(id)sender {
     [self resetKnob:[self updThumb]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.capturedImages = [[NSMutableArray alloc] init];

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        // There is not a camera on this device, so don't show the camera button.
        NSMutableArray *toolbarItems = [self.toolBar.items mutableCopy];
        [toolbarItems removeObjectAtIndex:2];
        [self.toolBar setItems:toolbarItems animated:NO];
    }
    
    [self performSelector:@selector(switchToCamera) withObject:nil afterDelay:0.1];
    
    NSLog(@"viewDidLoad.");
}

- (void) initThumbKnob {
    // big thumb
    KTOneFingerRotationGestureRecognizer *spinThumb = [[KTOneFingerRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotated:)];
    [[self updThumb] addGestureRecognizer:spinThumb];
    [[self updThumb] setUserInteractionEnabled:YES];
    
    // Allow rotation between the start and stop angles.
    [self setStartAngle:-95.0];
    [self setStopAngle:95.0];
    [self setResetAngle:0.0];
    [self setThumbCount:0];
    [self setDirection:0];
    [self resetKnob:[self updThumb]];
    NSLog(@"initThumbKnob");
}


- (void)rotated:(KTOneFingerRotationGestureRecognizer *)recognizer
{
    CGFloat degrees = radiansToDegrees([recognizer rotation]);
    CGFloat currentAngle = [self currentAngle] + degrees;
    CGFloat relativeAngle = fmodf(currentAngle, 360.0);  // Converts to angle between 0 and 360 degrees.
    
    BOOL shouldRotate = NO;
    if ([self startAngle] <= [self stopAngle]) {
        shouldRotate = (relativeAngle >= [self startAngle] && relativeAngle <= [self stopAngle]);
    } else if ([self startAngle] > [self stopAngle]) {
        shouldRotate = (relativeAngle >= [self startAngle] || relativeAngle <= [self stopAngle]);
    }
    
    if (shouldRotate) {
        [self setCurrentAngle:currentAngle];
        [self reactToThumbTwist:currentAngle ofKnob:[self updThumb]];
        UIView *view = [recognizer view];
        [view setTransform:CGAffineTransformRotate([view transform], [recognizer rotation])];
    }
    NSLog(@"rotated, currentAngle %f; relativeAngle %f",currentAngle,relativeAngle);
}

- (void)reactToThumbTwist:(CGFloat)twistLevel ofKnob:(UIView *)knob
{
    if ((twistLevel>87) && ([self direction]<1)){
        [self setDirection:1];
        [self setThumbCount:[self thumbCount]+1];
        [self.imagePickerController takePicture];
        [self resetKnob:knob];
    } else if ((twistLevel<-87) && ([self direction]>-1)){
        [self setDirection:-1];
        [self setThumbCount:[self thumbCount]-1];
        [self.imagePickerController takePicture];
        [self resetKnob:knob];
    };
    if ((twistLevel>87 && [self direction]>0) || (twistLevel<87 && [self direction]<0))
        [self setDirection:0];
    NSLog(@"react to thumb twist");
}


- (void)resetKnob:(UIView *)knob
{
    CGFloat startAngleInRadians = degreesToRadians([self resetAngle]);
    [knob setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.20 animations:^{
        [knob setTransform:CGAffineTransformMakeRotation(startAngleInRadians)];
    } completion:^(BOOL finished) {
        [knob setUserInteractionEnabled:YES];
        [self setCurrentAngle:[self resetAngle]];
    }];
    NSLog(@"resetKnob");
}
- (void) switchToCamera{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)showImagePickerForCamera:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
    NSLog(@"showImagePickerForCamera");
}

- (IBAction)showImagePickerForPhotoPicker:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    NSLog(@"showImagePickerForPhotoPicker");
}


- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if (self.imageView.isAnimating)
    {
        [self.imageView stopAnimating];
    }

    if (self.capturedImages.count > 0)
    {
        [self.capturedImages removeAllObjects];
    }

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        /*
         The user wants to use the camera interface. Set up our custom overlay view for the camera.
         */
        imagePickerController.showsCameraControls = NO;
        CGAffineTransform tmp = imagePickerController.cameraViewTransform;
        CGFloat tx = 0.0;
        CGFloat ty = 50.0;
        imagePickerController.cameraViewTransform = CGAffineTransformTranslate(tmp, tx, ty);
        //imagePickerController.cameraOverlayView.transform = CGAffineTransformMakeTranslation(tx, ty);

        /*
         Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
         */
        [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
        self.overlayView.frame = imagePickerController.cameraOverlayView.frame;
        imagePickerController.cameraOverlayView = self.overlayView;
        self.overlayView = nil;
        [self initThumbKnob];
    }

    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
    NSLog(@"end showImagePickerForSourceType");
}

#pragma mark - Thumb actions
- (IBAction)clickThumb:(id)sender{
    [self.imagePickerController takePicture];
     NSLog(@"clickThumb");
}

#pragma mark - Toolbar actions
- (IBAction)done:(id)sender
{
    // Dismiss the camera.
    if ([self.cameraTimer isValid])
    {
        [self.cameraTimer invalidate];
    }
    [self finishAndUpdate];
     NSLog(@"done");
}


- (IBAction)takePhoto:(id)sender
{
    [self.imagePickerController takePicture];
     NSLog(@"takePhoto");
}


- (IBAction)delayedTakePhoto:(id)sender
{
    // These controls can't be used until the photo has been taken
    self.doneButton.enabled = NO;
    self.takePictureButton.enabled = NO;
    self.delayedPhotoButton.enabled = NO;
    self.startStopButton.enabled = NO;

    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    NSTimer *cameraTimer = [[NSTimer alloc] initWithFireDate:fireDate interval:1.0 target:self selector:@selector(timedPhotoFire:) userInfo:nil repeats:NO];

    [[NSRunLoop mainRunLoop] addTimer:cameraTimer forMode:NSDefaultRunLoopMode];
    self.cameraTimer = cameraTimer;
}


- (IBAction)startTakingPicturesAtIntervals:(id)sender
{
    /*
     Start the timer to take a photo every 1.5 seconds.
     
     CAUTION: for the purpose of this sample, we will continue to take pictures indefinitely.
     Be aware we will run out of memory quickly.  You must decide the proper threshold number of photos allowed to take from the camera.
     One solution to avoid memory constraints is to save each taken photo to disk rather than keeping all of them in memory.
     In low memory situations sometimes our "didReceiveMemoryWarning" method will be called in which case we can recover some memory and keep the app running.
     */
    self.startStopButton.title = NSLocalizedString(@"Stop", @"Title for overlay view controller start/stop button");
    [self.startStopButton setAction:@selector(stopTakingPicturesAtIntervals:)];

    self.doneButton.enabled = NO;
    self.delayedPhotoButton.enabled = NO;
    self.takePictureButton.enabled = NO;

    self.cameraTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(timedPhotoFire:) userInfo:nil repeats:YES];
    [self.cameraTimer fire]; // Start taking pictures right away.
}


- (IBAction)stopTakingPicturesAtIntervals:(id)sender
{
    // Stop and reset the timer.
    [self.cameraTimer invalidate];
    self.cameraTimer = nil;

    [self finishAndUpdate];
}


- (void)finishAndUpdate
{
    [self dismissViewControllerAnimated:YES completion:NULL];

    if ([self.capturedImages count] > 0)
    {
        if ([self.capturedImages count] == 1)
        {
            // Camera took a single picture.
            [self.imageView setImage:[self.capturedImages objectAtIndex:0]];
        }
        else
        {
            // Camera took multiple pictures; use the list of images for animation.
            self.imageView.animationImages = self.capturedImages;
            self.imageView.animationDuration = 5.0;    // Show each captured photo for 5 seconds.
            self.imageView.animationRepeatCount = 0;   // Animate forever (show all photos).
            [self.imageView startAnimating];
        }
        
        // To be ready to start again, clear the captured images array.
        [self.capturedImages removeAllObjects];
    }

    self.imagePickerController = nil;
     NSLog(@"finishAndUpdate");
}


#pragma mark - Timer

// Called by the timer to take a picture.
- (void)timedPhotoFire:(NSTimer *)timer
{
    [self.imagePickerController takePicture];
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];

    [self.capturedImages addObject:image];
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    if ([self.cameraTimer isValid])
    {
        return;
    }

    [self finishAndUpdate];
     NSLog(@"imagePickerController didFinishPickingMediaWithInfo");
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
     NSLog(@"imagePickerControllerDidCancel");
}
@end