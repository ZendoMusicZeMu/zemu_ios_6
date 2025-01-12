#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AllmusicViewController : UIViewController

@property (nonatomic, strong) UITextField *idTextField;
@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic, assign) BOOL isPlayerVisible;

- (void)fetchDataFromServerWithID:(NSString *)songID;
- (void)loadIconFromURL:(NSURL *)iconURL;
- (void)createAudioPlayerWithURL:(NSURL *)audioURL;
- (void)playPauseButtonTapped:(UIButton *)sender;
- (void)timeSliderValueChanged:(UISlider *)sender;
- (void)updateTimeSlider;
- (void)backButtonTapped:(UIButton *)sender;
- (void)hideControls;
- (void)showControls;

@end