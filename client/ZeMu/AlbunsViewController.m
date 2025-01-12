#import "AlbunsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AlbunsViewController () <UIWebViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UISlider *timeSlider;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *rewindButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) UILabel *songNameLabel;
@property (nonatomic, strong) UILabel *artistNameLabel;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) NSString *nextSongID;
@property (nonatomic, strong) NSString *currentSongID;
@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UINavigationItem *webViewNavigationItem;
@property (nonatomic, strong) UINavigationBar *playerNavigationBar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIView *loadingOverlay;
@property (nonatomic, strong) NSMutableArray *webViewStack;
@property (nonatomic, strong) NSTimer *titleCheckTimer;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, assign) BOOL isInitialPage;
@property (nonatomic, strong) NSURL *initialURL;
@property (nonatomic, assign) BOOL radioMode; // Флаг для режима радио
@property (nonatomic, assign) BOOL radioModeButton; // Флаг для отображения кнопки "Радио"
@property (nonatomic, assign) BOOL infoProgrammButton; // Флаг для отображения кнопки "Информация о программе"

@end

@implementation AlbunsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Изначально режим радио выключен
    self.radioMode = NO;
    
    // Устанавливаем значения для отображения кнопок
    self.radioModeButton = NO; // Кнопка "Радио" будет отображаться
    self.infoProgrammButton = NO; // Кнопка "Информация о программе" будет отображаться
    
    // Настраиваем AVAudioSession для фонового воспроизведения
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    if (sessionError) {
        NSLog(@"Ошибка настройки AVAudioSession: %@", sessionError);
    }
    
    // Создаем и настраиваем UIWebView
    CGFloat webViewTopMargin = 44; // Отступ сверху для UINavigationBar
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, webViewTopMargin, self.view.bounds.size.width, self.view.bounds.size.height - webViewTopMargin)];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    // Получаем версию приложения из Info.plist
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    // Создаем URL с параметром version
    NSString *urlString = [NSString stringWithFormat:@"https://zendomusic.ru/ios6/music/albums/?version=%@", appVersion];
    self.initialURL = [NSURL URLWithString:urlString];
    
    // Создаем NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:self.initialURL];
    
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
    self.timeSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - 100, self.view.bounds.size.width - 40, 20)];
    [self.timeSlider addTarget:self action:@selector(timeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.timeSlider.hidden = YES;
    [self.view addSubview:self.timeSlider];
    
    // Создаем кнопку управления с изображением "Play"
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playPauseButton setImage:[UIImage imageNamed:@"AudioPlayer_Play.png"] forState:UIControlStateNormal];
    [self.playPauseButton addTarget:self action:@selector(playPauseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat playPauseButtonSize = 25;
    CGFloat buttonYPosition = self.view.bounds.size.height - 150;
    self.playPauseButton.frame = CGRectMake(self.view.bounds.size.width / 2 - playPauseButtonSize / 2, buttonYPosition, playPauseButtonSize, playPauseButtonSize);
    self.playPauseButton.backgroundColor = [UIColor clearColor];
    self.playPauseButton.layer.cornerRadius = 0;
    self.playPauseButton.hidden = YES;
    [self.view addSubview:self.playPauseButton];
    
    // Создаем кнопку для перемотки на начало песни
    self.rewindButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rewindButton setImage:[UIImage imageNamed:@"AudioPlayer_PreviousSong.png"] forState:UIControlStateNormal];
    [self.rewindButton addTarget:self action:@selector(rewindButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat rewindButtonSize = 25;
    self.rewindButton.frame = CGRectMake(self.view.bounds.size.width / 2 - 120, buttonYPosition, rewindButtonSize, rewindButtonSize); // Сдвигаем влево
    self.rewindButton.backgroundColor = [UIColor clearColor];
    self.rewindButton.layer.cornerRadius = 0;
    self.rewindButton.hidden = YES;
    [self.view addSubview:self.rewindButton];
    
    // Создаем кнопку для перемотки в конец песни
    self.forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.forwardButton setImage:[UIImage imageNamed:@"AudioPlayer_NextSong.png"] forState:UIControlStateNormal];
    [self.forwardButton addTarget:self action:@selector(forwardButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat forwardButtonSize = 25;
    self.forwardButton.frame = CGRectMake(self.view.bounds.size.width / 2 + 95, buttonYPosition, forwardButtonSize, forwardButtonSize); // Сдвигаем вправо
    self.forwardButton.backgroundColor = [UIColor clearColor];
    self.forwardButton.layer.cornerRadius = 0;
    self.forwardButton.hidden = YES;
    [self.view addSubview:self.forwardButton];
    
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
    
    // Создаем UINavigationBar для webView
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    self.navigationBar.tintColor = [UIColor blackColor];
    [self.view addSubview:self.navigationBar];
    
    // Создаем UINavigationItem для webView
    self.webViewNavigationItem = [[UINavigationItem alloc] initWithTitle:@""];
    [self.navigationBar setItems:@[self.webViewNavigationItem]];
    
    // Создаем UINavigationBar для плеера
    self.playerNavigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    self.playerNavigationBar.tintColor = [UIColor blackColor];
    self.playerNavigationBar.hidden = YES;
    [self.view addSubview:self.playerNavigationBar];
    
    // Устанавливаем флаг для отслеживания изначальной страницы
    self.isInitialPage = YES;
    
    // Создаем UIActivityIndicatorView
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.view.center;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
    
    // Создаем overlay для затемнения webView
    self.loadingOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    self.loadingOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.loadingOverlay.hidden = YES;
    [self.view addSubview:self.loadingOverlay];
    
    // Создаем стек для webView
    self.webViewStack = [NSMutableArray array];
    [self.webViewStack addObject:self.webView];
    
    // Запускаем таймер для проверки заголовка страницы
    self.titleCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkPageTitle) userInfo:nil repeats:YES];
    
    // Создаем представление для плеера
    [self createPlayerView];
}

- (void)createPlayerView {
    self.playerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.playerView.backgroundColor = [UIColor clearColor];
    self.playerView.hidden = YES;
    [self.view addSubview:self.playerView];
    
    // Добавляем элементы плеера в playerView
    [self.playerView addSubview:self.backgroundImageView];
    [self.playerView addSubview:self.overlayView];
    [self.playerView addSubview:self.timeSlider];
    [self.playerView addSubview:self.playPauseButton];
    [self.playerView addSubview:self.rewindButton];
    [self.playerView addSubview:self.forwardButton];
    [self.playerView addSubview:self.songNameLabel];
    [self.playerView addSubview:self.artistNameLabel];
    [self.playerView addSubview:self.playerNavigationBar];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    
    // Проверяем, соответствует ли URL протоколу zemu://alert
    if ([[url scheme] isEqualToString:@"zemu"] && [[url host] isEqualToString:@"alert"]) {
        // Извлекаем параметры из URL
        NSString *query = [url query];
        NSDictionary *params = [self parseQueryString:query];
        
        // Извлекаем значения параметров name и text
        NSString *name = params[@"name"];
        NSString *text = params[@"text"];
        
        // Отображаем UIAlertView с извлеченными параметрами
        if (name && text) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:name
                                                            message:text
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        // Предотвращаем загрузку URL в webView
        return NO;
    }
    
    // Проверяем, соответствует ли URL протоколу zemu://music
    if ([[url scheme] isEqualToString:@"zemu"] && [[url host] isEqualToString:@"music"]) {
        // Извлекаем параметры из URL
        NSString *query = [url query];
        NSDictionary *params = [self parseQueryString:query];
        
        // Извлекаем id песни
        NSString *songID = params[@"id"];
        
        // Если id песни получен, делаем запрос к API
        if (songID) {
            [self fetchDataFromServerWithID:songID isRadioMode:NO]; // Стандартный режим (не радио)
        }
        
        // Предотвращаем загрузку URL в webView
        return NO;
    }
    
    // Разрешаем загрузку других URL
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    // Проверяем, является ли текущий URL изначальным
    if ([webView.request.URL isEqual:self.initialURL]) {
        self.isInitialPage = YES;
    } else {
        self.isInitialPage = NO;
    }
    
    // Показываем overlay для затемнения webView
    self.loadingOverlay.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Обновляем заголовок UINavigationBar
    NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.webViewNavigationItem.title = pageTitle;
    
    // Скрываем overlay для затемнения webView
    self.loadingOverlay.hidden = YES;
    [self.activityIndicator stopAnimating];
    
    // Проверяем заголовок страницы
    [self checkPageTitle];
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

- (void)fetchDataFromServerWithID:(NSString *)songID isRadioMode:(BOOL)isRadioMode {
    // Сохраняем ID текущей песни
    self.currentSongID = songID;
    
    // Показываем индикатор загрузки
    [self.activityIndicator startAnimating];
    
    // Останавливаем текущую музыку, если она играет
    if (self.player) {
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.player = nil;
    }
    
    // Выбираем ссылку в зависимости от режима
    NSString *urlString;
    if (isRadioMode) {
        urlString = @"https://zendomusic.ru/ios6/API/get-info-random-songs.php";
    } else {
        urlString = [NSString stringWithFormat:@"https://zendomusic.ru/ios6/API/get-info-songs.php?id=%@", songID];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Создаем NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Выполняем асинхронный запрос
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if (connectionError) {
                                   NSLog(@"Ошибка подключения: %@", connectionError);
                                   [self showAlertWithTitle:@"Ошибка" message:@"Не удалось подключиться к серверу."];
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
                                           [self showAlertWithTitle:@"Ошибка" message:@"Неверный формат данных"];
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
                                       
                                       // Создаем и показываем UINavigationBar для плеера
                                       [self createAndShowPlayerNavigationBarWithTitle:songName];
                                   } else {
                                       // Если формат данных неверный, показываем алерт
                                       NSLog(@"Неверный формат данных");
                                       [self showAlertWithTitle:@"Ошибка" message:@"Неверный формат данных"];
                                   }
                                   
                                   // Останавливаем индикатор загрузки
                                   [self.activityIndicator stopAnimating];
                               }
                           }];
}

- (void)loadIconFromURL:(NSURL *)iconURL {
    // Показываем индикатор загрузки
    [self.activityIndicator startAnimating];
    
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
                                   
                                   // Останавливаем индикатор загрузки
                                   [self.activityIndicator stopAnimating];
                               }
                           }];
}

- (void)createAudioPlayerWithURL:(NSURL *)audioURL {
    // Создаем AVPlayerItem
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:audioURL];
    
    // Проверяем, что AVPlayerItem создан успешно
    if (!playerItem) {
        NSLog(@"Ошибка создания AVPlayerItem");
        [self showAlertWithTitle:@"Ошибка" message:@"Не удалось загрузить трек."];
        return;
    }
    
    // Добавляем наблюдателя за ошибками
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemFailedToPlay:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:playerItem];
    
    // Создаем AVPlayer
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
    // Проверяем, что AVPlayer создан успешно
    if (!self.player) {
        NSLog(@"Ошибка создания AVPlayer");
        [self showAlertWithTitle:@"Ошибка" message:@"Не удалось создать плеер."];
        return;
    }
    
    // Запускаем воспроизведение
    [self.player play];
    
    // Настраиваем UISlider
    self.timeSlider.minimumValue = 0.0;
    self.timeSlider.maximumValue = CMTimeGetSeconds(playerItem.asset.duration);
    
    // Добавляем наблюдателя для обновления UISlider
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
                                                                 [weakSelf updateTimeSlider];
                                                             }];
    
    // Добавляем наблюдателя за завершением воспроизведения
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    // Меняем изображение кнопки на "Pause"
    [self.playPauseButton setImage:[UIImage imageNamed:@"AudioPlayer_Pause.png"] forState:UIControlStateNormal];
    
    // Показываем лейблы
    self.songNameLabel.hidden = NO;
    self.artistNameLabel.hidden = NO;
    
    // Показываем overlayView
    self.overlayView.hidden = NO;
    
    // Показываем playerView
    self.playerView.hidden = NO;
    
    // Обновляем информацию в MPNowPlayingInfoCenter
    [self updateNowPlayingInfo];
}

- (void)playerItemFailedToPlay:(NSNotification *)notification {
    // Получаем ошибку из уведомления
    NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    NSLog(@"Ошибка воспроизведения: %@", error.localizedDescription);
    
    // Показываем сообщение об ошибке
    [self showAlertWithTitle:@"Ошибка" message:@"Не удалось воспроизвести трек. Проверьте подключение к интернету или попробуйте другой трек."];
    
    // Сбрасываем плеер
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    
    // Скрываем элементы управления
    [self hideControls];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if (self.radioMode) {
        // В режиме радио загружаем случайную песню
        [self fetchDataFromServerWithID:nil isRadioMode:YES];
    } else if (self.nextSongID) {
        // Если не в режиме радио и есть nextSongID, загружаем следующую песню
        [self fetchDataFromServerWithID:self.nextSongID isRadioMode:NO];
    }
}

#pragma mark - Управление плеером

- (void)playPauseButtonTapped:(UIButton *)sender {
    if (self.player.rate == 0) {
        // Если песня не играет, начинаем воспроизведение
        [self.player play];
        [self.playPauseButton setImage:[UIImage imageNamed:@"AudioPlayer_Pause.png"] forState:UIControlStateNormal];
    } else {
        // Если песня играет, ставим на паузу
        [self.player pause];
        [self.playPauseButton setImage:[UIImage imageNamed:@"AudioPlayer_Play.png"] forState:UIControlStateNormal];
    }
    
    // Обновляем информацию в MPNowPlayingInfoCenter
    [self updateNowPlayingInfo];
}

- (void)rewindButtonTapped:(UIButton *)sender {
    // Перематываем на начало песни
    [self.player seekToTime:kCMTimeZero];
    
    // Обновляем информацию в MPNowPlayingInfoCenter
    [self updateNowPlayingInfo];
}

- (void)forwardButtonTapped:(UIButton *)sender {
    if (self.radioMode) {
        // В режиме радио загружаем случайную песню
        [self fetchDataFromServerWithID:nil isRadioMode:YES];
    } else if (self.nextSongID) {
        // В режиме не радио используем заранее сохраненный nextSongID
        [self fetchDataFromServerWithID:self.nextSongID isRadioMode:NO];
    } else {
        // Если nextSongID отсутствует, загружаем случайную песню
        [self fetchDataFromServerWithID:nil isRadioMode:NO];
    }
}

- (void)timeSliderValueChanged:(UISlider *)sender {
    CMTime time = CMTimeMakeWithSeconds(sender.value, 1);
    [self.player seekToTime:time];
    
    // Обновляем информацию в MPNowPlayingInfoCenter
    [self updateNowPlayingInfo];
}

- (void)updateTimeSlider {
    self.timeSlider.value = CMTimeGetSeconds(self.player.currentTime);
    
    // Обновляем информацию в MPNowPlayingInfoCenter
    [self updateNowPlayingInfo];
}

- (void)hideControls {
    self.timeSlider.hidden = YES;
    self.playPauseButton.hidden = YES;
    self.rewindButton.hidden = YES;
    self.forwardButton.hidden = YES;
    self.songNameLabel.hidden = YES;
    self.artistNameLabel.hidden = YES;
    self.overlayView.hidden = YES;
    self.playerView.hidden = YES;
}

- (void)showControls {
    self.timeSlider.hidden = NO;
    self.playPauseButton.hidden = NO;
    self.rewindButton.hidden = NO;
    self.forwardButton.hidden = NO;
    self.songNameLabel.hidden = NO;
    self.artistNameLabel.hidden = NO;
    self.overlayView.hidden = NO;
    self.playerView.hidden = NO;
}

- (void)backButtonTapped:(UIButton *)sender {
    // Сбрасываем режим радио
    self.radioMode = NO;
    
    // Удаляем элементы плеера
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    
    // Скрываем элементы управления
    [self hideControls];
    
    // Удаляем иконку песни
    self.backgroundImageView.image = nil;
    
    // Возвращаемся на изначальную страницу
    [self.webView goBack];
    
    // Обновляем информацию в MPNowPlayingInfoCenter
    [self updateNowPlayingInfo];
}

- (void)playerBackButtonTapped:(UIButton *)sender {
    // Сбрасываем режим радио
    self.radioMode = NO;
    
    // Удаляем элементы плеера
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    
    // Скрываем элементы управления
    [self hideControls];
    
    // Удаляем иконку песни
    self.backgroundImageView.image = nil;
    
    // Скрываем UINavigationBar для плеера
    self.playerNavigationBar.hidden = YES;
    
    // Обновляем информацию в MPNowPlayingInfoCenter
    [self updateNowPlayingInfo];
}

- (void)createAndShowPlayerNavigationBarWithTitle:(NSString *)title {
    // Устанавливаем заголовок UINavigationBar для плеера
    UINavigationItem *playerNavigationItem = [[UINavigationItem alloc] initWithTitle:title];
    
    // Добавляем кнопку "Назад" в UINavigationBar для плеера
    UIBarButtonItem *playerBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Назад" style:UIBarButtonItemStylePlain target:self action:@selector(playerBackButtonTapped:)];
    playerNavigationItem.leftBarButtonItem = playerBackButton;
    
    // Добавляем кнопку "Инфо" в правую часть UINavigationBar
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithTitle:@"Инфо" style:UIBarButtonItemStylePlain target:self action:@selector(playerInfoButtonTapped:)];
    playerNavigationItem.rightBarButtonItem = infoButton;
    
    [self.playerNavigationBar setItems:@[playerNavigationItem]];
    
    // Показываем UINavigationBar для плеера
    self.playerNavigationBar.hidden = NO;
}

- (void)playerInfoButtonTapped:(UIButton *)sender {
    // Создаем UIAlertView с информацией о текущей песне
    NSString *songName = self.songNameLabel.text ?: @"Неизвестно";
    NSString *artistName = self.artistNameLabel.text ?: @"Неизвестно";
    
    // Формируем ссылку с ID текущей песни
    NSString *songURL = [NSString stringWithFormat:@"https://zendomusic.ru/music/play?id=%@", self.currentSongID];
    
    // Формируем сообщение
    NSString *message = [NSString stringWithFormat:@"Название: %@\nАвтор: %@\nСсылка: %@", songName, artistName, songURL];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Информация о песне"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"ОК"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)checkPageTitle {
    // Получаем заголовок страницы
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    // Проверяем, равен ли заголовок стандартному значению (например, "ZeMu")
    if ([pageTitle isEqualToString:@"Альбомы"]) {
        // Если заголовок стандартный, показываем кнопку "Инфо" слева и "Радио" справа
        UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithTitle:@"Инфо" style:UIBarButtonItemStylePlain target:self action:@selector(showAppInfo)];
        UIBarButtonItem *radioButton = [[UIBarButtonItem alloc] initWithTitle:@"Радио" style:UIBarButtonItemStylePlain target:self action:@selector(radioButtonTapped:)];
        
        // Устанавливаем кнопки
        if (self.infoProgrammButton) {
            self.webViewNavigationItem.leftBarButtonItem = infoButton; // "Инфо" слева
        } else {
            self.webViewNavigationItem.leftBarButtonItem = nil; // Скрываем кнопку "Инфо"
        }
        
        if (self.radioModeButton) {
            self.webViewNavigationItem.rightBarButtonItem = radioButton; // "Радио" справа
        } else {
            self.webViewNavigationItem.rightBarButtonItem = nil; // Скрываем кнопку "Радио"
        }
    } else {
        // Если заголовок нестандартный, показываем кнопку "Назад" слева
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Назад" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTapped:)];
        self.webViewNavigationItem.leftBarButtonItem = backButton;
        self.webViewNavigationItem.rightBarButtonItem = nil; // Убираем кнопку "Радио"
    }
}

- (void)showAppInfo {
    // Получаем версию приложения из Info.plist
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    // Формируем сообщение
    NSString *message = [NSString stringWithFormat:@"ZeMu версия %@\nСайт: https://zendomusic.ru", appVersion];
    
    // Создаем и показываем UIAlertView
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Информация о приложении"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"ОК"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)radioButtonTapped:(UIButton *)sender {
    // Запускаем радио
    [self startRadio];
}

- (void)startRadio {
    // Устанавливаем флаг режима радио
    self.radioMode = YES;
    
    // Загружаем случайную песню
    [self fetchDataFromServerWithID:nil isRadioMode:YES];
}

- (void)settingsButtonTapped:(UIButton *)sender {
    // Обработка нажатия на кнопку настроек
    NSLog(@"Настройки нажата");
}

#pragma mark - MPNowPlayingInfoCenter

- (void)updateNowPlayingInfo {
    if (self.player) {
        NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
        
        // Устанавливаем название песни
        if (self.songNameLabel.text) {
            [nowPlayingInfo setObject:self.songNameLabel.text forKey:MPMediaItemPropertyTitle];
        }
        
        // Устанавливаем название исполнителя
        if (self.artistNameLabel.text) {
            [nowPlayingInfo setObject:self.artistNameLabel.text forKey:MPMediaItemPropertyArtist];
        }
        
        // Устанавливаем обложку
        if (self.backgroundImageView.image) {
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.backgroundImageView.image];
            [nowPlayingInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
        }
        
        // Устанавливаем продолжительность трека
        [nowPlayingInfo setObject:@(CMTimeGetSeconds(self.player.currentItem.asset.duration)) forKey:MPMediaItemPropertyPlaybackDuration];
        
        // Устанавливаем текущее время воспроизведения
        [nowPlayingInfo setObject:@(CMTimeGetSeconds(self.player.currentTime)) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        
        // Устанавливаем скорость воспроизведения
        [nowPlayingInfo setObject:@(self.player.rate) forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        // Обновляем информацию в MPNowPlayingInfoCenter
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
    } else {
        // Очищаем информацию в MPNowPlayingInfoCenter, если плеер не активен
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"ОК"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

@end