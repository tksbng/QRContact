//
//  ViewController.m
//  QRContact
//
//  Created by Takeshi Bingo on 2013/08/03.
//  Copyright (c) 2013年 Takeshi Bingo. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (strong,nonatomic)AVCaptureSession *session;

@end

@implementation ViewController{
    //読み取った画像を表示するImage View
    IBOutlet UIImageView *barcodeImageView;
    //バーコードの解析結果を表示するText View
    IBOutlet UITextView *barcodeResults;
    //バーコードの生データを格納
    NSString *barcodeString;
    //読み取った連絡先のインスタンス
    Contact *contactInfo;
    //ZBarのインスタンス
    //ZBarReaderViewController *reader;
}
//スキャンボタンが押されたときのメソッド
-(IBAction)scan:(id)sender {
/*
    //ZBarのインスタンスを生成
    reader = [ZBarReaderViewController new];
    //ZBarに関する各種設定
    reader.readerDelegate = (id)self; reader.readerView.zoom = 1.0;
    //バーコードリーダ画面起動
    [self presentViewController: reader animated: YES completion:nil];
*/
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = nil;
    AVCaptureDevicePosition camera = AVCaptureDevicePositionBack; // Back or Front
    for (AVCaptureDevice *d in devices) {
        device = d;
        if (d.position == camera) {
            break;
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    [self.session addInput:input];
    
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:output];
    
    // QR コードのみ
    //output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    // 全部認識させたい場合
    // (
    // face,
    // "org.gs1.UPC-E",
    // "org.iso.Code39",
    // "org.iso.Code39Mod43",
    // "org.gs1.EAN-13",
    // "org.gs1.EAN-8",
    // "com.intermec.Code93",
    // "org.iso.Code128",
    // "org.iso.PDF417",
    // "org.iso.QRCode",
    // "org.iso.Aztec"
    // )
    output.metadataObjectTypes = output.availableMetadataObjectTypes;
    
    NSLog(@"%@", output.availableMetadataObjectTypes);
    NSLog(@"%@", output.metadataObjectTypes);
    
    [self.session startRunning];
    
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    preview.frame = self.view.bounds;
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:preview];

}
//バーコードが読み取られた時のメソッド
- (void)imagePickerController: (UIImagePickerController*) picker didFinishPickingMediaWithInfo: (NSDictionary*) info {
    //読み取ったバーコード画像を画面上に表示
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    barcodeImageView.image = image;
    //読み取り結果を取得
/*
    id <NSFastEnumeration> syms = [info objectForKey: ZBarReaderControllerResults];
    for(ZBarSymbol *sym in syms) {
        barcodeString = sym.data;
        break;
    }
 */
    
    
    
    
    //リーダを閉じる
//    [reader dismissViewControllerAnimated: YES completion:nil];
    
    //バーコードのタイプを判定
 //   [self determineType];
 //   [self.session stopRunning];

}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"----");
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            // 複数の QR があっても1度で読み取れている
            NSString *qrcode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            NSLog(@"%@", qrcode);
        }
        else if ([metadata.type isEqualToString:AVMetadataObjectTypeEAN13Code]) {
            NSString *ean13 = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            NSLog(@"%@", ean13);
        }
    }
    [self.session stopRunning];
    [self determineType];
    //読み取ったバーコード画像を画面上に表示
    //UIImage *image =
   // barcodeImageView.image = image;
}
//バーコードのタイプを判定
- (void)determineType {
    
    //Docomoの場合の正規表現
    NSString *patternDocomo = @"^(MECARD:N:)";
    
    NSRegularExpression *regexpDocomo = [NSRegularExpression regularExpressionWithPattern:patternDocomo options:0 error:nil];
    
    NSTextCheckingResult *matchDocomo = [regexpDocomo firstMatchInString:barcodeString options:0 range:NSMakeRange(0, barcodeString.length)];
    
    //AU/Softbankの場合の正規表現
    NSString *patternAUSB = @"^(MEMORY:)";
    
    NSRegularExpression *regexpAUSB = [NSRegularExpression regularExpressionWithPattern:patternAUSB options:0 error:nil];
    
    NSTextCheckingResult *matchAUSB = [regexpAUSB firstMatchInString:barcodeString options:0 range:NSMakeRange(0, barcodeString.length)];
    
    
    //双方一致しない場合
    if (matchDocomo.numberOfRanges == 0 && matchAUSB.numberOfRanges == 0) {
        barcodeResults.text = @"連絡先では無いバーコードが読み込まれました。";
        
        //Docomoに一致する場合
    } else if (matchDocomo.numberOfRanges > 0 && matchAUSB.numberOfRanges == 0) {
        //Docomoのフォーマットに従って解析
        contactInfo = [self parseDocomo];
        
        //AU/Softbankに一致する場合
    } else if (matchDocomo.numberOfRanges == 0 && matchAUSB.numberOfRanges > 0) {
        //AU/Softbankのフォーマットに従って解析
        contactInfo = [self parseAUSB];
    }
    
    //結果を表示するTextViewを更新
    [self updateText];
}
//Docomoの連絡先コードの解析
- (Contact *)parseDocomo {
    //Contactのインスタンス生成・初期化
    Contact *c = [[Contact alloc] init];
    c.email = [[NSMutableArray alloc] init];
    c.phone = [[NSMutableArray alloc] init];
    //「;」で項目ごとに分割
    NSArray* codeElement = [barcodeString componentsSeparatedByString:@";"];
    
    //それぞれの項目を示す正規表現
    NSString *patternName = @"MECARD:N:(.*?)$";
    NSString *patternYomi = @"SOUND:(.*?)$";
    NSString *patternEmail = @"EMAIL:(.*?)$";
    NSString *patternPhone = @"TEL:(.*?)$";
    
    //NSRegularExpressionクラスのインスタンスを生成
    NSRegularExpression *regexpName = [NSRegularExpression regularExpressionWithPattern:patternName options:0 error:nil];
    NSRegularExpression *regexpYomi = [NSRegularExpression regularExpressionWithPattern:patternYomi options:0 error:nil];
    NSRegularExpression *regexpEmail = [NSRegularExpression regularExpressionWithPattern:patternEmail options:0 error:nil];
    NSRegularExpression *regexpPhone = [NSRegularExpression regularExpressionWithPattern:patternPhone options:0 error:nil];
    
    //項目の個数分繰り返し
    for (int i = 0; i < [codeElement count]; i++) {
        //現在の項目を文字列に
        NSString *element = [codeElement objectAtIndex:i];
        NSTextCheckingResult *match;
        //名前を抽出
        match = [regexpName firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        if (match.numberOfRanges > 0) {
            NSString *name = [element substringWithRange:[match rangeAtIndex:1]];
            NSArray *names = [name componentsSeparatedByString:@","];
            c.lastname = [names objectAtIndex:0];
            c.firstname = [names objectAtIndex:1];
        }
        //よみがなを抽出
        match = [regexpYomi firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        if (match.numberOfRanges > 0) {
            NSString *yomi = [element substringWithRange:[match rangeAtIndex:1]];
            NSArray *yomis = [yomi componentsSeparatedByString:@","];
            c.lastyomi = [yomis objectAtIndex:0];
            c.firstyomi = [yomis objectAtIndex:1];
        }
        //メールアドレスを抽出
        match = [regexpEmail firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        
        if (match.numberOfRanges > 0) {
            NSString *email = [element substringWithRange:[match rangeAtIndex:1]];
            [c.email addObject:email];
        }
        
        //電話番号を抽出
        match = [regexpPhone firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        
        if (match.numberOfRanges > 0) {
            NSString *phone = [element substringWithRange:[match rangeAtIndex:1]];
            [c.phone addObject:phone];
        }
    }
    return c;
}
//AU/Softbankの連絡先コードの解析
- (Contact *) parseAUSB {
    //Contactのインスタンス生成・初期化
    Contact *c = [[Contact alloc] init];
    c.email = [[NSMutableArray alloc] init];
    c.phone = [[NSMutableArray alloc] init];
    
    //改行文字「\r\n」で項目ごとに分割
    NSArray* codeElement = [barcodeString componentsSeparatedByString:@"\n"];
    
    //それぞれの項目を示す正規表現
    NSString *patternName = @"NAME1:(.*?)$";
    NSString *patternYomi = @"NAME2:(.*?)$";
    NSString *patternEmail = @"MAIL[0-9]:(.*?)$";
    NSString *patternPhone = @"TEL[0-9]:(.*?)$";
    //NSRegularExpressionクラスのインスタンスを生成
    NSRegularExpression *regexpName = [NSRegularExpression regularExpressionWithPattern:patternName options:0 error:nil];
    NSRegularExpression *regexpYomi = [NSRegularExpression regularExpressionWithPattern:patternYomi options:0 error:nil];
    NSRegularExpression *regexpEmail = [NSRegularExpression regularExpressionWithPattern:patternEmail options:0 error:nil];
    NSRegularExpression *regexpPhone = [NSRegularExpression regularExpressionWithPattern:patternPhone options:0 error:nil];
    //項目の個数分繰り返し
    for (int i = 0; i < [codeElement count]; i++) {
        //現在の項目を文字列に
        NSString *element = [codeElement objectAtIndex:i];
        NSTextCheckingResult *match;
        //名前を抽出
        match = [regexpName firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        if (match.numberOfRanges > 0) {
            NSString *name = [element substringWithRange:[match rangeAtIndex:1]];
            c.lastname = name;
        }
        //よみがなを抽出
        match = [regexpYomi firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        
        if (match.numberOfRanges > 0) {
            NSString *yomi = [element substringWithRange:[match rangeAtIndex:1]];
            c.lastyomi = yomi;
        }
        //メールアドレスを抽出
        match = [regexpEmail firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        
        if (match.numberOfRanges > 0) {
            NSString *email = [element substringWithRange:[match rangeAtIndex:1]];
            [c.email addObject:email];
        }
        //電話番号を抽出
        match = [regexpPhone firstMatchInString:element options:0 range:NSMakeRange(0, element.length)];
        
        if (match.numberOfRanges > 0) {
            NSString *phone = [element substringWithRange:[match rangeAtIndex:1]];
            [c.phone addObject:phone];
        }
    }
    return c;
}
//読取り結果を表示するText Viewを更新
-(void)updateText {
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    //名前を参照
    if (contactInfo.firstname != nil) {
        [result appendFormat:@"名前: %@ %@\n", contactInfo.lastname, contactInfo.firstname];
    } else {
        [result appendFormat:@"名前: %@\n", contactInfo.lastname];
    }
    //ふりがなを参照
    if (contactInfo.firstname != nil) {
        [result appendFormat:@"ふりがな: %@ %@\n", contactInfo.lastyomi, contactInfo.firstyomi];
    } else {
        [result appendFormat:@"ふりがな: %@\n", contactInfo.lastyomi];
    }
    
    //電話番号を参照
    for (int i = 0; i < [contactInfo.phone count]; i++) {
        [result appendFormat:@"電話番号 %d: %@\n", i+1, [contactInfo.phone objectAtIndex:i]];
    }
    //メールアドレスを参照
    for (int i = 0; i < [contactInfo.email count]; i++) {
        [result appendFormat:@"メールアドレス %d: %@\n", i+1, [contactInfo.email objectAtIndex:i]];
    }
    
    //結果をText Viewに反映
    barcodeResults.text = result;
}
//電話帳に登録
-(IBAction)addContact:(id)sender {
    
    //contactInfoが空の場合は中断
    if (contactInfo == nil) {
        //メッセージを表示
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.title = @"エラー";
        alert.message = @"バーコードを読み込んでください。";
        [alert addButtonWithTitle:@"OK"];
        [alert show];
        
        return;
    }
    //電話帳を開く
    NSLog(@"%@", [self description]);
    ABAddressBookRef iPhoneAddressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(iPhoneAddressBook, ^(bool granted, CFErrorRef error) {
            [self registContact:iPhoneAddressBook];
        });
    }else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self registContact:iPhoneAddressBook];
    }
}
-(void)registContact:(ABAddressBookRef)iPhoneAddressBook{
    CFErrorRef error = NULL;
    ABRecordRef newBook = ABPersonCreate();
    //姓を指定
    ABRecordSetValue(newBook, kABPersonLastNameProperty,
                     (__bridge CFStringRef)contactInfo.lastname, &error);
    ABRecordSetValue(newBook, kABPersonLastNamePhoneticProperty ,
                     (__bridge CFStringRef)contactInfo.lastyomi, &error);
    
    
    //名の指定
    ABRecordSetValue(newBook, kABPersonFirstNameProperty,
                     (__bridge CFStringRef)contactInfo.firstname, &error);
    ABRecordSetValue(newBook, kABPersonFirstNamePhoneticProperty,
                     (__bridge CFStringRef)contactInfo.firstyomi, &error);
    
    //電話番号の指定
    ABMutableMultiValueRef multiPhone =
    ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (int i = 0; i < [contactInfo.phone count]; i++) {
        NSString *phone = [contactInfo.phone objectAtIndex:i];
        ABMultiValueAddValueAndLabel(multiPhone,
                                     (__bridge CFStringRef)phone, NULL, NULL);
    }
    ABRecordSetValue(newBook, kABPersonPhoneProperty,
                     multiPhone, &error);
    CFRelease(multiPhone);
    
    //メールアドレスの指定
    ABMutableMultiValueRef multiEmail =
    ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (int i = 0; i < [contactInfo.email count]; i++) {
        NSString *email = [contactInfo.email objectAtIndex:i];
        ABMultiValueAddValueAndLabel(multiEmail,
                                     (__bridge CFStringRef)email, NULL, NULL);
    }
    ABRecordSetValue(newBook, kABPersonEmailProperty ,
                     multiEmail, &error);
    CFRelease(multiEmail);
    //電話帳にレコードを追加・保存
    ABAddressBookAddRecord(iPhoneAddressBook, newBook, &error);
    ABAddressBookSave(iPhoneAddressBook, &error);
    CFRelease(newBook);
    CFRelease(iPhoneAddressBook);
    dispatch_async(dispatch_get_main_queue(), ^{
        //保存が正常に完了した場合・失敗した場合のメッセージを表示
        UIAlertView *alert = [[UIAlertView alloc] init];
        
        if (error != NULL) {
            CFStringRef errorDesc = CFErrorCopyDescription(error);
            alert.title = @"アドレス帳保存エラー";
            alert.message = [NSString
                             stringWithFormat:@"エラー: %@", errorDesc];
            CFRelease(errorDesc);
        } else {
            //メッセージを表示
            alert.title = @"登録完了";
            alert.message = @"連絡先に追加されました。";
        }
        
        [alert addButtonWithTitle:@"OK"];
        [alert show];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
