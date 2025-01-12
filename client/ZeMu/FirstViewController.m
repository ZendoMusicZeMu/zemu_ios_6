#import "FirstViewController.h"

@interface FirstViewController () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Задаем размеры UITextView
    CGFloat topMargin = 50.0; // Отступ сверху
    CGRect textViewFrame = CGRectMake(0, topMargin, self.view.bounds.size.width, self.view.bounds.size.height - topMargin);
    
    // Создаем UITextView и добавляем его на view
    self.textView = [[UITextView alloc] initWithFrame:textViewFrame];
    self.textView.textAlignment = NSTextAlignmentCenter;
    self.textView.editable = NO; // Делаем его нередактируемым
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.textView];
    
    // Загружаем текст с веб-сайта
    NSURL *url = [NSURL URLWithString:@"https://zendomusic.ru/API/lastnews.php"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *text = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    if (text) {
        self.textView.text = text;
    } else {
        self.textView.text = @"Failed to decode data.";
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.textView.text = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
}

@end