//
//  FiveViewController.m
//  LGBluetooth
//
//  Created by mac on 16/6/2.
//  Copyright © 2016年 ZnLG. All rights reserved.
//

#import "FiveViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE" //服务的UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC" //特征的UUID

@interface FiveViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (strong,nonatomic) CBCentralManager *centralManager;//中心设备管理器
@property (strong,nonatomic) NSMutableArray *peripherals;//连接的外围设备
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong,nonatomic) CBPeripheral *currentPeripheral;

@end

@implementation FiveViewController

#pragma mark - 控制器视图事件
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"中心服务器";
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.centralManager cancelPeripheralConnection:self.currentPeripheral];
    self.centralManager.delegate = nil;
    self.currentPeripheral.delegate = nil;
}

#pragma mark - UI事件
- (IBAction)start:(id)sender {
    //创建中心设备管理器并设置当前控制器视图为代理
    _centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
}

#pragma mark - CBCentralManager代理方法
//中心服务器状态更新后
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"BLE已打开.");
            [self writeToLog:@"BLE已打开."];
            //扫描外围设备
            //            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            [central scanForPeripheralsWithServices:nil options:nil];
            break;
            
        default:
            NSLog(@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备.");
            [self writeToLog:@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备."];
            break;
    }
}
/**
 *  发现外围设备
 *
 *  @param central           中心设备
 *  @param peripheral        外围设备
 *  @param advertisementData 特征数据
 *  @param RSSI              信号质量（信号强度）
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"发现外围设备...");
    [self writeToLog:@"发现外围设备..."];
    //连接外围设备
    if (peripheral) {
        //添加保存外围设备，注意如果这里不保存外围设备（或者说peripheral没有一个强引用，无法到达连接成功（或失败）的代理方法，因为在此方法调用完就会被销毁
        if(![self.peripherals containsObject:peripheral]){
            [self.peripherals addObject:peripheral];
        }
        NSLog(@"开始连接外围设备...%@",peripheral.name );
        [self writeToLog:@"开始连接外围设备..."];
        if ([peripheral.name hasPrefix:@"LD Smart 03EI"]) {

            [self.centralManager connectPeripheral:peripheral options:nil];
            return;
        }
    }
}

//连接到外围设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"连接外围设备成功!");
    [self writeToLog:@"连接外围设备成功!"];
    [self.centralManager stopScan];
    self.currentPeripheral = peripheral;
    //设置外围设备的代理为当前视图控制器
    peripheral.delegate=self;
    //外围设备开始寻找服务
    [peripheral discoverServices:nil];

}
//连接外围设备失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接外围设备失败!");
    [self writeToLog:@"连接外围设备失败!"];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
    //自动重连
//    [self.centralManager connectPeripheral:self.currentPeripheral options:nil];
}
#pragma mark - CBPeripheral 代理方法
//外围设备寻找到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"已发现可用服务...");
    [self writeToLog:@"已发现可用服务..."];
    if(error){
        NSLog(@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription]];
    }
    //遍历查找到的服务
    for (CBService *service in peripheral.services) {
        if([service.UUID.UUIDString isEqual:@"180D"]){

            //外围设备查找指定服务中的特征
            [peripheral discoverCharacteristics:nil forService:service];

        }
    }
}

//外围设备寻找到特征后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"已发现可用特征...");
    [self writeToLog:@"已发现可用特征..."];
    if (error) {
        NSLog(@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription]];
    }
    //遍历服务中的特征
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
//    if ([service.UUID isEqual:serviceUUID]) {
    if([service.UUID.UUIDString isEqual:@"180D"]){

        for (CBCharacteristic *characteristic in service.characteristics) {
//            if ([characteristic.UUID isEqual:characteristicUUID]) {
                //情景一：通知
                /*找到特征后设置外围设备为已通知状态（订阅特征）：
                 *1.调用此方法会触发代理方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                 *2.调用此方法会触发外围设备的订阅代理方法
                 */
                //情景二：读取
            if (characteristic.properties ==CBCharacteristicPropertyRead) {
                [peripheral readValueForCharacteristic:characteristic];
            }else if(characteristic.properties == CBCharacteristicPropertyNotify){
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }

        }
    }
}

//特征值被更新后
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"收到特征更新通知...");
    [self writeToLog:@"收到特征更新通知..."];
    if (error) {
        NSLog(@"更新通知状态时发生错误，错误信息：%@",error.localizedDescription);
    }
    //给特征值设置新的值
    if (characteristic.isNotifying) {
        if (characteristic.properties==CBCharacteristicPropertyNotify) {
            NSLog(@"已订阅特征通知.");
            [self writeToLog:@"已订阅特征通知."];
            return;
        }else if (characteristic.properties ==CBCharacteristicPropertyRead) {
            //从外围设备读取新值,调用此方法会触发代理方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
            [peripheral readValueForCharacteristic:characteristic];
        }
        
    }else{
        NSLog(@"停止已停止.");
        [self writeToLog:@"停止已停止."];
        //取消连接
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

//更新特征值后（调用readValueForCharacteristic:方法或者外围设备在订阅后更新特征值都会调用此代理方法）
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"更新特征值时发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"更新特征值时发生错误，错误信息：%@",error.localizedDescription]];
        return;
    }
    if (characteristic.value) {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A37"]]) {
            
            //***********方法可用
            //        Byte *databyte = (Byte *)[characteristic.value bytes];
            //        for (int i = 0; i<[characteristic.value length]; i++) {
            //            NSLog(@"收到3蓝牙发来的数据  %d",databyte[i]);//心率带的心率值（经过10进制转换）
            //        }
            //**********************
            
            //        NSString * string = [NSString hexadecimalString:characteristic.value];
//            NSLog(@"打印出(心率带)心率值（十六进制）:%@",characteristic.value);//心率带的心率值（没有经过10进制转换）
            
            //**************将心率带的16进制转换成10进制
            NSRange range = {3,2};
            NSString *subString = [[NSString stringWithFormat:@"%@",characteristic.value] substringWithRange:range];
            int xintiao = (int)strtoul([subString UTF8String],0,16);
//            NSLog(@"打印出(心率带)心率值（十进制）:%ld",(long)xintiao);//打印出心率值(经过10进制转换)
            [self writeToLog:[NSString stringWithFormat:@"读取到心跳值：%ld",(long)xintiao]];
        }
    }else{
        NSLog(@"未发现特征值.");
        [self writeToLog:@"未发现特征值."];
    }
}

#pragma mark - 属性
-(NSMutableArray *)peripherals{
    if(!_peripherals){
        _peripherals=[NSMutableArray array];
    }
    return _peripherals;
}

#pragma mark - 私有方法
/**
 *  记录日志
 *
 *  @param info 日志信息
 */
-(void)writeToLog:(NSString *)info{
    self.textView.text=[NSString stringWithFormat:@"%@\r\n%@",self.textView.text,info];
}

@end
