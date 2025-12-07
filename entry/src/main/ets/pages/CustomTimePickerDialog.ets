// src/main/ets/pages/CustomTimePickerDialog.ets

import promptAction from '@ohos.promptAction';

@CustomDialog
export struct CountdownPickerDialog {
  private controller?: CustomDialogController;
  // 创建范围数组
  @State hoursRange: string[] = [];
  @State minutesRange: string[] = [];
  @State secondsRange: string[] = [];
  @State selectedHours: number = 0;
  @State selectedMinutes: number = 0;
  @State selectedSeconds: number = 0;
  private onConfirm?: (h: number, m: number, s: number) => void;
  private onCancel?: () => void;

  constructor(controller: CustomDialogController, params: {
    initialHour: number,
    initialMinute: number,
    initialSecond: number,
    onConfirm?: (h: number, m: number, s: number) => void,
    onCancel?: () => void
  }) {
    super();
    this.controller = controller;
    this.selectedHours = params.initialHour;
    this.selectedMinutes = params.initialMinute;
    this.selectedSeconds = params.initialSecond;
    this.onConfirm = params.onConfirm;
    this.onCancel = params.onCancel;
  }

  aboutToAppear() {
    // 生成小时范围 (0-23)
    for (let i = 0; i <= 23; i++) {
      this.hoursRange.push(i.toString().padStart(2, '0'));
    }

    // 生成分钟范围 (0-59)
    for (let i = 0; i <= 59; i++) {
      this.minutesRange.push(i.toString().padStart(2, '0'));
    }

    // 生成秒范围 (0-59)
    for (let i = 0; i <= 59; i++) {
      this.secondsRange.push(i.toString().padStart(2, '0'));
    }
  }

  build() {
    Stack() {
      Column() {
        Text('设置专注时长')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({ top: 24, bottom: 20 })

        // 显示当前选择的时间
        Text(`${this.hoursRange[this.selectedHours]}:${this.minutesRange[this.selectedMinutes]}:${this.secondsRange[this.selectedSeconds]}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#409EFF')
          .margin({ bottom: 20 })

        Row({ space: 20 }) {
          // 小时选择器
          Column({ space: 5 }) {
            TextPicker({ range: this.hoursRange, selected: this.selectedHours })
              .width(80)
              .height(150)
              .onChange((value: string | string[], index: number | number[]) => {
                if (typeof index === 'number') {
                  this.selectedHours = index;
                }
              })
            Text('小时')
              .fontSize(14)
              .fontColor('#666666')
          }

          // 分钟选择器
          Column({ space: 5 }) {
            TextPicker({ range: this.minutesRange, selected: this.selectedMinutes })
              .width(80)
              .height(150)
              .onChange((value: string | string[], index: number | number[]) => {
                if (typeof index === 'number') {
                  this.selectedMinutes = index;
                }
              })
            Text('分钟')
              .fontSize(14)
              .fontColor('#666666')
          }

          // 秒选择器
          Column({ space: 5 }) {
            TextPicker({ range: this.secondsRange, selected: this.selectedSeconds })
              .width(80)
              .height(150)
              .onChange((value: string | string[], index: number | number[]) => {
                if (typeof index === 'number') {
                  this.selectedSeconds = index;
                }
              })
            Text('秒')
              .fontSize(14)
              .fontColor('#666666')
          }
        }
        .justifyContent(FlexAlign.Center)

        Row({ space: 10 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#EFEFEF')
            .fontColor('#666666')
            .onClick(() => {
              this.controller?.close();
              if (this.onCancel) {
                this.onCancel();
              }
            })

          Button('确定')
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#409EFF')
            .fontColor('#FFFFFF')
            .onClick(() => {
              if (this.validateInput()) {
                if (this.onConfirm) {
                  this.onConfirm(this.selectedHours, this.selectedMinutes, this.selectedSeconds);
                }
                this.controller?.close();
              } else {
                promptAction.showToast({ message: '专注时间至少为 1 秒' });
              }
            })
        }
        .width('100%')
        .padding({
          top: 24,
          bottom: 16,
          left: 24,
          right: 24
        })
      }
      .width('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({
        radius: 12,
        color: '#00000040',
        offsetX: 0,
        offsetY: 6
      })
    }
  }

  private validateInput(): boolean {
    return this.selectedHours > 0 || this.selectedMinutes > 0 || this.selectedSeconds > 0;
  }
}