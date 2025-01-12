//
//  SearchViewController.m
//  ZeMu
//
//  Created by User on 13.09.24.
//  Copyright (c) 2024 CydiaRU. All rights reserved.
//

#import "SearchViewController.h"

@interface SearchViewController ()

@property (strong, nonatomic) UIWebView *webView;

@end

@implementation SearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Создаем и настраиваем UIWebView
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; // Автоматическая подстройка под размер контейнера
    [self.view addSubview:self.webView];
    
    // Создаем URL
    NSURL *url = [NSURL URLWithString:@"https://zendomusic.ru/app-version/search"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Загружаем URL в webView
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
