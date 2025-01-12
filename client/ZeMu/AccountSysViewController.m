//
//  AccountSysViewController.m
//  ZeMu
//
//  Created by User on 26.10.24.
//  Copyright (c) 2024 CydiaRU. All rights reserved.
//

#import "AccountSysViewController.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface AccountSysViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *loginTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *authButton;
@property (nonatomic, strong) UIButton *logoutButton;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) NSString *cachedImagePath;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIView *customDimmingView; // Изменено имя переменной

@end

@implementation AccountSysViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Создаем и добавляем индикатор загрузки
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.center = self.view.center;
    [self.view addSubview:self.activityIndicator];
    
    // Настраиваем интерфейс
    [self setupUI];
    
    // Создаем UINavigationBar черного цвета
    [self setupNavigationBar];
    
    // Проверяем, есть ли сохраненные данные
    NSString *savedLogin = [[NSUserDefaults standardUserDefaults] stringForKey:@"login"];
    NSString *savedPassword = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
    
    if (savedLogin && savedPassword) {
        // Если есть сохраненные данные, скрываем поля ввода и кнопку авторизации
        self.loginTextField.hidden = YES;
        self.passwordTextField.hidden = YES;
        self.authButton.hidden = YES;
        
        // Устанавливаем текст UILabel равным сохраненному логину
        self.resultLabel.text = savedLogin;
        
        // Отправляем запрос на сервер
        [self.activityIndicator startAnimating];
        [self fetchDataWithLogin:savedLogin password:savedPassword completion:^{
            [self.activityIndicator stopAnimating];
        }];
    }
}

- (void)setupUI {
    // Создаем текстовые поля
    self.loginTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 30)];
    self.loginTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.loginTextField.placeholder = @"Login";
    self.loginTextField.delegate = self;
    [self.view addSubview:self.loginTextField];
    
    self.passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 150, self.view.frame.size.width - 40, 30)];
    self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.placeholder = @"Password";
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.delegate = self;
    [self.view addSubview:self.passwordTextField];
    
    // Создаем кнопку
    self.authButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.authButton.frame = CGRectMake(20, 200, self.view.frame.size.width - 40, 40);
    [self.authButton setTitle:@"Authorize" forState:UIControlStateNormal];
    [self.authButton addTarget:self action:@selector(authorizeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.authButton];
    
    // Создаем метку для отображения результата
    self.resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 260, self.view.frame.size.width - 40, 30)];
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    self.resultLabel.text = @"Loading..."; // Устанавливаем начальный текст
    self.resultLabel.textColor = [UIColor whiteColor]; // Белый цвет текста
    self.resultLabel.font = [UIFont boldSystemFontOfSize:18];
    self.resultLabel.backgroundColor = [UIColor clearColor]; // Прозрачный фон
    [self.view addSubview:self.resultLabel];
    
    // Создаем кнопку обновления данных
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshButton.frame = CGRectMake(20, 300, self.view.frame.size.width - 40, 40);
    [self.refreshButton setTitle:@"Refresh Data" forState:UIControlStateNormal];
    [self.refreshButton addTarget:self action:@selector(refreshButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.refreshButton];
    
    // Создаем UIImageView для фона
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];
    
    // Создаем UIImageView для иконки
    self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = self.iconImageView;
    
    // Создаем затемняющий слой
    self.customDimmingView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.customDimmingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.customDimmingView.hidden = YES;
    [self.view addSubview:self.customDimmingView];
    
    // Создаем кнопку выхода
    self.logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.logoutButton.frame = CGRectMake(20, 350, self.view.frame.size.width - 40, 40);
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal]; // Черный цвет текста
    [self.logoutButton addTarget:self action:@selector(logoutButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutButton];
    self.logoutButton.hidden = YES;
    
    // Добавляем UILabel поверх всех элементов
    [self.view bringSubviewToFront:self.resultLabel];
}

- (void)setupNavigationBar {
    // Создаем UINavigationBar черного цвета
    UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    navigationBar.tintColor = [UIColor blackColor]; // Устанавливаем цвет UINavigationBar
    
    // Создаем UINavigationItem
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@"Аккаунт"]; // Устанавливаем текст на UINavigationBar
    navigationItem.titleView = self.iconImageView;
    
    // Добавляем UINavigationItem в UINavigationBar
    [navigationBar setItems:@[navigationItem]];
    
    // Добавляем UINavigationBar в view
    [self.view addSubview:navigationBar];
}

- (void)authorizeButtonTapped {
    NSString *login = self.loginTextField.text;
    NSString *password = self.passwordTextField.text;
    
    if (login.length > 0 && password.length > 0) {
        // Сохраняем данные
        [[NSUserDefaults standardUserDefaults] setObject:login forKey:@"login"];
        [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Скрываем клавиатуру и текстовые поля
        [self.loginTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        self.loginTextField.hidden = YES;
        self.passwordTextField.hidden = YES;
        self.authButton.hidden = YES;
        
        // Устанавливаем текст UILabel равным сохраненному логину
        self.resultLabel.text = login;
        
        // Отправляем запрос на сервер
        [self.activityIndicator startAnimating];
        [self fetchDataWithLogin:login password:password completion:^{
            [self.activityIndicator stopAnimating];
        }];
    } else {
        self.resultLabel.text = @"Please enter login and password";
    }
}

- (void)fetchDataWithLogin:(NSString *)login password:(NSString *)password completion:(void (^)(void))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://zendomusic.ru/ios6/API/account.php?login=%@&password=%@", login, password];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data) {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSArray *components = [responseString componentsSeparatedByString:@","];
            if (components.count > 0) {
                // Выводим все секции в консоль
                for (int i = 0; i < components.count; i++) {
                    NSLog(@"Section %d: %@", i + 1, components[i]);
                }
                
                // Сохраняем данные в NSUserDefaults
                [[NSUserDefaults standardUserDefaults] setObject:components forKey:@"userData"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // Загружаем фоновую картинку
                NSURL *imageURL = [NSURL URLWithString:components[1]];
                [self loadBackgroundImageFromURL:imageURL];
                
                // Загружаем иконку пользователя
                NSURL *iconURL = [NSURL URLWithString:components[2]];
                [self loadIconImageFromURL:iconURL];
                
                // Показываем кнопку "Выйти"
                self.logoutButton.hidden = NO;
                self.refreshButton.hidden = NO;
                
                // Показываем затемняющий слой
                self.customDimmingView.hidden = NO;
                
                // Устанавливаем текст на UINavigationBar
                UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 30)];
                titleLabel.textAlignment = NSTextAlignmentCenter;
                titleLabel.text = login; // Устанавливаем текст на UINavigationBar равным сохраненному login
                titleLabel.textColor = [UIColor blackColor];
                titleLabel.font = [UIFont boldSystemFontOfSize:18];
                self.navigationItem.titleView = titleLabel;
            } else {
                // Обновляем UILabel в главном потоке
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.resultLabel.text = @"No data received";
                });
            }
        } else {
            // Обновляем UILabel в главном потоке
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resultLabel.text = @"Error fetching data";
            });
        }
        
        if (completion) {
            completion();
        }
    }];
}

- (void)logoutButtonTapped {
    // Удаляем сохраненные данные
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"login"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Удаляем кэшированное изображение
    if (self.cachedImagePath) {
        [[NSFileManager defaultManager] removeItemAtPath:self.cachedImagePath error:nil];
    }
    
    // Возвращаем интерфейс к исходному состоянию
    self.loginTextField.hidden = NO;
    self.passwordTextField.hidden = NO;
    self.authButton.hidden = NO;
    self.logoutButton.hidden = YES;
    self.refreshButton.hidden = YES;
    self.resultLabel.hidden = NO;
    self.resultLabel.text = @"";
    self.backgroundImageView.image = nil;
    self.view.backgroundColor = [UIColor whiteColor]; // Возвращаем белый фон
    self.iconImageView.image = nil; // Очищаем иконку
    self.customDimmingView.hidden = YES; // Скрываем затемняющий слой
    self.navigationItem.titleView = nil; // Очищаем текст на UINavigationBar
}

- (void)refreshButtonTapped {
    // Перезагружаем ViewController с обновленными данными
    [self viewDidLoad];
}

- (void)loadBackgroundImageFromURL:(NSURL *)imageURL {
    // Проверяем, есть ли уже загруженное изображение
    NSString *cachedImageName = [imageURL.absoluteString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    self.cachedImagePath = [cacheDirectory stringByAppendingPathComponent:cachedImageName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachedImagePath]) {
        // Если изображение уже есть в кэше, загружаем его
        UIImage *cachedImage = [UIImage imageWithContentsOfFile:self.cachedImagePath];
        self.backgroundImageView.image = cachedImage;
    } else {
        // Иначе загружаем изображение с сервера
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageURL];
        [NSURLConnection sendAsynchronousRequest:imageRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                UIImage *backgroundImage = [UIImage imageWithData:data];
                self.backgroundImageView.image = backgroundImage;
                
                // Сохраняем изображение в кэш
                [data writeToFile:self.cachedImagePath atomically:YES];
            } else {
                NSLog(@"Error loading background image: %@", connectionError);
            }
        }];
    }
}

- (void)loadIconImageFromURL:(NSURL *)iconURL {
    NSURLRequest *iconRequest = [NSURLRequest requestWithURL:iconURL];
    [NSURLConnection sendAsynchronousRequest:iconRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data) {
            UIImage *iconImage = [UIImage imageWithData:data];
            self.iconImageView.image = iconImage;
        } else {
            NSLog(@"Error loading icon image: %@", connectionError);
        }
    }];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // Пропускаем символ #
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end