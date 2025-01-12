#import "AccountViewController.h"

@interface AccountViewController () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation AccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Задаем отступы сверху и снизу
    CGFloat topMargin = 175.0; // Отступ сверху
    CGFloat textViewHeight = 50.0; // Высота UITextView
    
    // Рассчитываем размеры UITextView
    CGRect textViewFrame = CGRectMake(0, topMargin, self.view.bounds.size.width, textViewHeight);
    
    // Создаем UITextView и добавляем его на view
    self.textView = [[UITextView alloc] initWithFrame:textViewFrame];
    self.textView.textAlignment = NSTextAlignmentCenter;
    self.textView.editable = NO; // Делаем его нередактируемым
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.textView];
    
    // Загружаем текст с веб-сайта
    NSURL *url = [NSURL URLWithString:@"https://zendomusic.ru/ios6/API/developers.php"];
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