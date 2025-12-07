// Component/EditModal.ets
import { TodoItem } from '../Types/ToDoItem';

// 步骤 1: 添加 DatePickerResult 接口定义
interface DatePickerResult {
  year?: number;
  month?: number;
  day?: number;
}

@CustomDialog
export struct EditModal {
  private controller: CustomDialogController;
  @State todoItem: TodoItem | null = null;
  @State todoName: string = '';
  @State deadline: string = '';
  @State selectedDate: Date = new Date();
  // 步骤 2: 删除 @State showDatePicker: boolean = false;
  onCancel: () => void = () => {
  };
  onSave: (updatedItem: TodoItem) => void = () => {
  };

  constructor(controller: CustomDialogController, params: {
    todoItem: TodoItem | null,
    onCancel: () => void,
    onSave: (updatedItem: TodoItem) => void
  }) {
    super();
    this.controller = controller;
    this.todoItem = params.todoItem;
    this.onCancel = params.onCancel;
    this.onSave = params.onSave;
    console.log('EditModal constructor, todoItem id:', this.todoItem ? this.todoItem.id : 'null');
  }

  aboutToAppear() {
    if (this.todoItem) {
      this.todoName = this.todoItem.name;
      this.deadline = this.todoItem.deadline;
      this.selectedDate = new Date(this.todoItem.deadline);
      console.log('EditModal aboutToAppear, todoName set to:', this.todoName);
    }
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
          Text('修改待办')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')

          Blank()

          Image($r('app.media.false'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.controller?.close();
              this.onCancel();
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
            // 步骤 3: 修改 onClick 为调用 DatePickerDialog
            .onClick(() => {
              DatePickerDialog.show({
                start: new Date(), // 从今天开始
                end: new Date('2100-12-31'),
                selected: this.selectedDate,
                onAccept: (value: DatePickerResult) => {
                  if (value.year === undefined || value.month === undefined || value.day === undefined) {
                    return;
                  }
                  // month - 1: DatePickerResult.month 是 1-12，Date 构造函数中的 month 是 0-11
                  const selected = new Date(value.year, value.month - 1, value.day);
                  this.selectedDate = selected;
                  this.deadline = this.formatDate(selected);
                },
                onCancel: () => {
                  console.log('用户取消了日期选择');
                }
              });
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
              this.onCancel();
            })

          // 确认按钮
          Button('保存', { type: ButtonType.Normal })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(this.todoName.trim() && this.deadline ? '#1A73E8' : '#CCCCCC')
            .fontColor('#FFFFFF')
            .borderRadius(20)
            .enabled(!!this.todoName.trim() && !!this.deadline)
            .onClick(() => {
              if (this.onSave && this.todoItem && this.todoName.trim() && this.deadline) {
                const updatedItem: TodoItem = {
                  id: this.todoItem.id,
                  name: this.todoName.trim(),
                  deadline: this.deadline,
                  total_time: this.todoItem.total_time,
                  isFinished: this.todoItem.isFinished
                };
                this.onSave(updatedItem);
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

      // 步骤 4: 删除自定义日期选择器 UI 逻辑
      // if (this.showDatePicker) { ... } 块已删除

    }
  }
}