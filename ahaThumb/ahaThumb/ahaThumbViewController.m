//
//  ahaThumbViewController.m
//  ahaThumb
//
//  Created by Vikash Mishra on 10/1/13.
//  Copyright (c) 2013 Vikash Mishra. All rights reserved.
//

#import "ahaThumbViewController.h"

@interface ahaThumbViewController ()

@property (nonatomic, weak) IBOutlet UIButton *thumbTakePictureButton;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) NSMutableArray *capturedImages;
@property (weak, nonatomic) IBOutlet UIButton *clickMeButton;
@property BOOL activatedCamera;
@property (nonatomic, weak) IBOutlet UIToolbar *overlayView;

@end

@implementation ahaThumbViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.capturedImages = [[NSMutableArray alloc] init];
    self.activatedCamera = FALSE;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)clickMeOnUp:(id)sender {
    [self showImagePicker];
}


- (void)showImagePicker{
    
    if ([self activatedCamera]) {
        return;
    }
    [self setActivatedCamera:TRUE];
    if (self.imageView.isAnimating){
        [self.imageView stopAnimating];
    }
    
    if (self.capturedImages.count > 0)
    {
        [self.capturedImages removeAllObjects];
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    //imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    
    //  By default, the user will want to use the camera interface but not the controls.

    imagePickerController.showsCameraControls = NO;
    //self.overlayView.frame = imagePickerController.cameraOverlayView.frame;
    imagePickerController.cameraOverlayView = self.overlayView;
    //self.overlayView = nil;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - control and response

- (IBAction)takePhoto:(id)sender
{
    [self.imagePickerController takePicture];
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
        
        // To be ready to start again, clear the captured images array.
        [self.capturedImages removeAllObjects];
    }
    
    self.imagePickerController = nil;
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    [self.capturedImages addObject:image];
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    [self finishAndUpdate];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
