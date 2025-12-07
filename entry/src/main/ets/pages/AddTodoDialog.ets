// Component/AddTodoDialog.ets
import { TodoItem } from '../Types/ToDoItem';

@CustomDialog
export struct AddTodoDialog {
  private controller?: CustomDialogController;
  @State todoName: string = '';
  @State deadline: string = '';
  @State selectedDate: Date = new Date();
  @State showDatePicker: boolean = false;
  private onConfirm?: (item: TodoItem) => void;
  private onCancel?: () => void;

  constructor(controller: CustomDialogController, params: {
    onConfirm?: (item: TodoItem) => void,
    onCancel?: () => void
  }) {
    super();
    this.controller = controller;
    this.onConfirm = params.onConfirm;
    this.onCancel = params.onCancel;
    // 默认截止时间为明天
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    this.selectedDate = tomorrow;
    this.deadline = this.formatDate(tomorrow);
  }

  // 格式化日期为ISO字符串
  private formatDate(date: Date): string {
    return date.toISOString();
  }

  // 格式化日期显示
  private formatDateDisplay(dateStr: string): string {
    if (!dateStr) {
      return '请选择截止时间';
    }
    const date = new Date(dateStr);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  build() {
    Stack() {
      Column() {
        // 弹窗头部
        Row() {
          Text('添加待办')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')

          Blank()

          Image($r('app.media.false'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.controller?.close();
              if (this.onCancel) {
                this.onCancel();
              }
            })
        }
        .width('100%')
        .padding({ top: 24, left: 24, right: 24 })

        // 输入区域
        Column({ space: 16 }) {
          // 待办名称
          Column({ space: 8 }) {
            Text('待办名称')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .textAlign(TextAlign.Start)

            TextInput({ placeholder: '请输入待办名称...', text: this.todoName })
              .width('100%')
              .height(48)
              .backgroundColor('#F7F7F7')
              .border({ width: 1, color: '#E8E8E8' })
              .borderRadius(8)
              .padding(12)
              .fontSize(16)
              .onChange((value: string) => {
                this.todoName = value;
              })
              .maxLength(100)
          }

          // 截止时间
          Column({ space: 8 }) {
            Text('截止时间')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .textAlign(TextAlign.Start)

            Row() {
              Text(this.formatDateDisplay(this.deadline))
                .fontSize(16)
                .fontColor(this.deadline ? '#333333' : '#999999')
                .layoutWeight(1)

              Image($r('app.media.ic_dropdown'))
                .width(20)
                .height(20)
            }
            .width('100%')
            .height(48)
            .backgroundColor('#F7F7F7')
            .border({ width: 1, color: '#E8E8E8' })
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.showDatePicker = true;
            })
          }
        }
        .width('100%')
        .padding({ top: 24, left: 24, right: 24 })

        // 按钮区域
        Row({ space: 12 }) {
          // 取消按钮
          Button('取消', { type: ButtonType.Normal })
            .layoutWeight(1)
            .height(40)
            .backgroundColor('#F0F0F0')
            .fontColor('#666666')
            .borderRadius(20)
            .onClick(() => {
              this.controller?.close();
              if (this.onCancel) {
                this.onCancel();
              }
            })

          // 确认按钮
          Button('确认', { type: ButtonType.Normal })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(this.todoName.trim() && this.deadline ? '#1A73E8' : '#CCCCCC')
            .fontColor('#FFFFFF')
            .borderRadius(20)
            .enabled(!!this.todoName.trim() && !!this.deadline)
            .onClick(() => {
              if (this.onConfirm && this.todoName.trim() && this.deadline) {
                const newItem: TodoItem = {
                  id: Date.now(),
                  name: this.todoName.trim(),
                  deadline: this.deadline,
                  total_time: 0,
                  isFinished: false
                };
                this.onConfirm(newItem);
                this.controller?.close();
              }
            })
        }
        .width('100%')
        .padding({
          top: 32,
          bottom: 24,
          left: 24,
          right: 24
        })
        .justifyContent(FlexAlign.Center)
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

      // 日期选择器弹窗
      if (this.showDatePicker) {
        Column() {
          // 半透明背景
          Column() {
            Blank()
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .opacity(0.3)
          .onClick(() => {
            this.showDatePicker = false;
          })

          // 日期选择器内容
          Column() {
            // 标题栏
            Row() {
              Text('选择截止日期')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .layoutWeight(1)

              Button('取消')
                .fontSize(16)
                .fontColor('#666666')
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.showDatePicker = false;
                })

              Blank()
                .width(8)

              Button('确定')
                .fontSize(16)
                .fontColor('#1A73E8')
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.showDatePicker = false;
                })
            }
            .width('100%')
            .padding({ top: 16, bottom: 16, left: 20, right: 20 })

            DatePicker({
              start: new Date(), // 从今天开始
              end: new Date('2100-12-31'),
              selected: this.selectedDate
            })
              .onChange((value: DatePickerResult) => {
                if (value.year === undefined || value.month === undefined || value.day === undefined) {
                  return;
                }
                const selected = new Date(value.year, value.month - 1, value.day);
                this.selectedDate = selected;
                this.deadline = this.formatDate(selected);
              })
          }
          .width('90%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 24,
            color: '#00000040',
            offsetX: 0,
            offsetY: 8
          })
          .position({ x: '5%', y: '20%' })
        }
        .width('100%')
        .height('100%')
      }
    }
  }
}