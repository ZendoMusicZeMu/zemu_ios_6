#import "AllmusicViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface AllmusicViewController () <UIWebViewDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UISlider *timeSlider;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *rewindButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *playbackTimer;
@property (nonatomic, strong) UILabel *songNameLabel;
@property (nonatomic, strong) UILabel *artistNameLabel;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) NSString *nextSongID; // ID следующей песни

@end

@implementation AllmusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Настраиваем AVAudioSession для фонового воспроизведения
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    if (sessionError) {
        NSLog(@"Ошибка настройки AVAudioSession: %@", sessionError);
    }
    
    // Создаем и настраиваем UIWebView
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    // Создаем URL
    NSURL *url = [NSURL URLWithString:@"https://zendomusic.ru/app-version/music/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Загружаем URL в webView
    [self.webView loadRequest:request];
    
    // Создаем UIImageView для фона
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];
    
    // Создаем overlayView для затемнения иконки песни
    self.overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.overlayView.hidden = YES;
    [self.view addSubview:self.overlayView];
    
    // Создаем UISlider для управления временем воспроизведения
    self.timeSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 40, self.view.bounds.size.width - 40, 20)];
    [self.timeSlider addTarget:self action:@selector(timeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.timeSlider];
    
    // Создаем кнопку управления
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.playPauseButton addTarget:self action:@selector(playPauseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.playPauseButton.frame = CGRectMake(self.view.bounds.size.width / 2 - 30, self.view.bounds.size.height - 100, 60, 35);
    self.playPauseButton.layer.cornerRadius = 30;
    self.playPauseButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [self.view addSubview:self.playPauseButton];
    
    // Создаем кнопку для перемотки на начало песни
    self.rewindButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.rewindButton setTitle:@"<<" forState:UIControlStateNormal];
    [self.rewindButton addTarget:self action:@selector(rewindButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.rewindButton.frame = CGRectMake(self.view.bounds.size.width / 2 - 120, self.view.bounds.size.height - 100, 60, 35);
    self.rewindButton.layer.cornerRadius = 30;
    self.rewindButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [self.view addSubview:self.rewindButton];
    
    // Создаем кнопку для перемотки в конец песни
    self.forwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.forwardButton setTitle:@">>" forState:UIControlStateNormal];
    [self.forwardButton addTarget:self action:@selector(forwardButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.forwardButton.frame = CGRectMake(self.view.bounds.size.width / 2 + 60, self.view.bounds.size.height - 100, 60, 35);
    self.forwardButton.layer.cornerRadius = 30;
    self.forwardButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [self.view addSubview:self.forwardButton];
    
    // Создаем кнопку "назад"
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setTitle:@"Назад" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.backButton.frame = CGRectMake(0, 0, 60, 30);
    self.backButton.hidden = YES;
    [self.view addSubview:self.backButton];
    
    // Создаем UILabel для имени песни
    self.songNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 60, self.view.bounds.size.width, 30)];
    self.songNameLabel.textColor = [UIColor whiteColor];
    self.songNameLabel.textAlignment = NSTextAlignmentCenter;
    self.songNameLabel.backgroundColor = [UIColor clearColor];
    self.songNameLabel.font = [UIFont boldSystemFontOfSize:18];
    self.songNameLabel.hidden = YES;
    [self.view addSubview:self.songNameLabel];
    
    // Создаем UILabel для имени автора
    self.artistNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 30, self.view.bounds.size.width, 30)];
    self.artistNameLabel.textColor = [UIColor whiteColor];
    self.artistNameLabel.textAlignment = NSTextAlignmentCenter;
    self.artistNameLabel.backgroundColor = [UIColor clearColor];
    self.artistNameLabel.font = [UIFont boldSystemFontOfSize:18];
    self.artistNameLabel.hidden = YES;
    [self.view addSubview:self.artistNameLabel];
    
    // Скрываем элементы управления, если ничего не введено
    [self hideControls];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    
    // Проверяем, соответствует ли URL протоколу zemu://
    if ([[url scheme] isEqualToString:@"zemu"] && [[url host] isEqualToString:@"music"]) {
        // Извлекаем параметры из URL
        NSString *query = [url query];
        NSDictionary *params = [self parseQueryString:query];
        
        // Извлекаем id песни
        NSString *songID = params[@"id"];
        
        // Если id песни получен, делаем запрос к API
        if (songID) {
            [self fetchDataFromServerWithID:songID];
        }
        
        // Предотвращаем загрузку URL в webView
        return NO;
    }
    
    // Разрешаем загрузку других URL
    return YES;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)elements[0], CFSTR(""), kCFStringEncodingUTF8);
        NSString *val = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)elements[1], CFSTR(""), kCFStringEncodingUTF8);
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (void)fetchDataFromServerWithID:(NSString *)songID {
    // Останавливаем текущую музыку, если она играет
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    
    // URL вашего PHP-скрипта
    NSString *urlString = [NSString stringWithFormat:@"https://zendomusic.ru/API/test1.php?id=%@", songID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Создаем NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Выполняем асинхронный запрос
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if (connectionError) {
                                   NSLog(@"Ошибка подключения: %@", connectionError);
                               } else {
                                   // Преобразуем полученные данные в строку
                                   NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   NSLog(@"Ответ сервера: %@", responseString);
                                   
                                   // Разделяем строку на массив по запятой
                                   NSArray *components = [responseString componentsSeparatedByString:@","];
                                   
                                   if (components.count == 5) {
                                       // Получаем значения переменных url, icon, songName, artistName и ID следующей песни
                                       NSString *audioURLString = components[0];
                                       NSString *iconURLString = components[1];
                                       NSString *songName = components[2];
                                       NSString *artistName = components[3];
                                       NSString *nextSongIDComponent = components[4]; // ID следующей песни
                                       
                                       // Извлекаем ID следующей песни
                                       NSArray *idComponents = [nextSongIDComponent componentsSeparatedByString:@":"];
                                       if (idComponents.count == 2) {
                                           self.nextSongID = [idComponents[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                           NSLog(@"ID следующей песни: %@", self.nextSongID);
                                       }
                                       
                                       // Создаем NSURL для аудио и иконки
                                       NSURL *audioURL = [NSURL URLWithString:audioURLString];
                                       NSURL *iconURL = [NSURL URLWithString:iconURLString];
                                       
                                       if (!audioURL || !iconURL) {
                                           NSLog(@"Неверный формат URL");
                                           return;
                                       }
                                       
                                       NSLog(@"Audio URL: %@", audioURL);
                                       NSLog(@"Icon URL: %@", iconURL);
                                       NSLog(@"Song Name: %@", songName);
                                       NSLog(@"Artist Name: %@", artistName);
                                       
                                       // Загружаем иконку
                                       [self loadIconFromURL:iconURL];
                                       
                                       // Создаем проигрыватель
                                       [self createAudioPlayerWithURL:audioURL];
                                       
                                       // Показываем элементы управления
                                       [self showControls];
                                       
                                       // Устанавливаем текст для лейблов
                                       self.songNameLabel.text = songName;
                                       self.artistNameLabel.text = artistName;
                                   } else {
                                       NSLog(@"Неверный формат данных");
                                   }
                               }
                           }];
}

- (void)loadIconFromURL:(NSURL *)iconURL {
    // Создаем NSURLRequest для иконки
    NSURLRequest *iconRequest = [NSURLRequest requestWithURL:iconURL];
    
    // Выполняем асинхронный запрос для загрузки иконки
    [NSURLConnection sendAsynchronousRequest:iconRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if (connectionError) {
                                   NSLog(@"Ошибка загрузки иконки: %@", connectionError);
                               } else {
                                   // Преобразуем данные в UIImage
                                   UIImage *iconImage = [UIImage imageWithData:data];
                                   
                                   // Отображаем иконку в UIImageView
                                   self.backgroundImageView.image = iconImage;
                               }
                           }];
}

- (void)createAudioPlayerWithURL:(NSURL *)audioURL {
    // Останавливаем предыдущий аудиоплеер
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    
    // Создаем AVAudioPlayer
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
    
    if (error) {
        NSLog(@"Ошибка создания AVAudioPlayer: %@", error);
        return;
    }
    
    // Настраиваем плеер
    self.audioPlayer.delegate = self; // Устанавливаем делегат для обработки завершения воспроизведения
    
    // Запускаем воспроизведение
    [self.audioPlayer play];
    
    // Настраиваем UISlider
    self.timeSlider.minimumValue = 0.0;
    self.timeSlider.maximumValue = self.audioPlayer.duration;
    
    // Запускаем таймер для обновления слайдера
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                          target:self
                                                        selector:@selector(updateTimeSlider)
                                                        userInfo:nil
                                                         repeats:YES];
    
    // Меняем текст кнопки на "Pause"
    [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    
    // Показываем кнопку "назад"
    self.backButton.hidden = NO;
    
    // Показываем лейблы
    self.songNameLabel.hidden = NO;
    self.artistNameLabel.hidden = NO;
    
    // Показываем overlayView
    self.overlayView.hidden = NO;
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        // Если песня успешно завершилась, загружаем следующую песню
        if (self.nextSongID) {
            [self fetchDataFromServerWithID:self.nextSongID];
        }
    }
}

#pragma mark - Управление плеером

- (void)playPauseButtonTapped:(UIButton *)sender {
    if (self.audioPlayer.isPlaying) {
        // Если песня играет, ставим на паузу
        [self.audioPlayer pause];
        [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        // Если песня на паузе, продолжаем воспроизведение
        [self.audioPlayer play];
        [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

- (void)rewindButtonTapped:(UIButton *)sender {
    // Перематываем на начало песни
    self.audioPlayer.currentTime = 0;
}

- (void)forwardButtonTapped:(UIButton *)sender {
    // Перематываем в конец песни
    self.audioPlayer.currentTime = self.audioPlayer.duration;
}

- (void)timeSliderValueChanged:(UISlider *)sender {
    // Устанавливаем текущее время воспроизведения
    self.audioPlayer.currentTime = sender.value;
}

- (void)updateTimeSlider {
    // Обновляем значение слайдера
    self.timeSlider.value = self.audioPlayer.currentTime;
}

- (void)hideControls {
    self.timeSlider.hidden = YES;
    self.playPauseButton.hidden = YES;
    self.rewindButton.hidden = YES;
    self.forwardButton.hidden = YES;
    self.backButton.hidden = YES;
    self.songNameLabel.hidden = YES;
    self.artistNameLabel.hidden = YES;
    self.overlayView.hidden = YES;
}

- (void)showControls {
    self.timeSlider.hidden = NO;
    self.playPauseButton.hidden = NO;
    self.rewindButton.hidden = NO;
    self.forwardButton.hidden = NO;
    self.backButton.hidden = NO;
    self.songNameLabel.hidden = NO;
    self.artistNameLabel.hidden = NO;
    self.overlayView.hidden = NO;
}

- (void)backButtonTapped:(UIButton *)sender {
    // Останавливаем воспроизведение
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    
    // Скрываем элементы управления
    [self hideControls];
    
    // Удаляем иконку песни
    self.backgroundImageView.image = nil;
}

- (void)dealloc {
    [self.playbackTimer invalidate]; // Останавливаем таймер
    self.playbackTimer = nil;
}

@end