// src/main/ets/pages/FocusTimerPage.ets
import { TimerItem } from '../Types/TimerItem';
import { TodoItem } from '../Types/ToDoItem';
import promptAction from '@ohos.promptAction';

interface TimePickerResult {
  hour: number;
  minute: number;
}

interface PromptResult {
  index: number;
  message?: string;
}

@Component
export struct FocusTimerPage {
  @Link planList: TodoItem[]; // 接收待办事项列表
  @State currentTask: TodoItem | null = null; // 当前选中的待办事项
  @State timeLeft: number = 1500; // 当前剩余时间（秒）
  @State isRunning: boolean = false;
  @State isPaused: boolean = false;
  @State timerProgress: number = 0; // 进度百分比
  @State showTaskPicker: boolean = false;
  @State showAddTodoDialog: boolean = false; // 添加待办弹窗

  // 计时器ID
  private timerId: number = 0;

  // 计时历史记录
  @State timerHistory: TimerItem[] = [];

  aboutToAppear() {
    // 页面显示时，如果有未完成的待办，默认选中第一个
    if (this.planList && this.planList.length > 0) {
      const unfinishedTodo = this.planList.find(item => !item.isFinished);
      if (unfinishedTodo) {
        this.currentTask = unfinishedTodo;
      } else {
        this.currentTask = this.planList[0]; // 如果没有未完成的，选中第一个
      }
      this.timeLeft = 1500; // 默认25分钟
    }
  }

  // 格式化时间显示
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // 计算进度百分比
  private calculateProgress(): number {
    const total = 1500; // 默认25分钟
    const remaining = this.timeLeft;
    return ((total - remaining) / total) * 100;
  }

  // 开始计时器
  private startTimer(): void {
    if (this.isRunning || !this.currentTask) return;

    this.isRunning = true;
    this.isPaused = false;

    this.timerId = setInterval(() => {
      if (this.timeLeft > 0) {
        this.timeLeft -= 1;
        this.timerProgress = this.calculateProgress();
      } else {
        this.handleTimerFinish();
      }
    }, 1000);
  }

  // 暂停计时器
  private pauseTimer(): void {
    if (this.isRunning && !this.isPaused) {
      clearInterval(this.timerId);
      this.isPaused = true;
    }
  }

  // 继续计时器
  private resumeTimer(): void {
    if (this.isRunning && this.isPaused) {
      this.startTimer();
    }
  }

  // 停止计时器
  private stopTimer(): void {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
    this.isRunning = false;
    this.isPaused = false;
    this.timeLeft = 1500; // 重置为默认25分钟
    this.timerProgress = 0;
  }

  // 选择待办事项作为任务
  private selectTodoAsTask(todo: TodoItem): void {
    this.currentTask = todo;
    this.stopTimer(); // 切换任务时重置计时器
    this.timeLeft = 1500; // 重置为默认25分钟
    this.showTaskPicker = false;
  }
  // 自定义时间
  private showTimePicker(): void {
    // 简化处理：直接设置固定时间
    // 在实际应用中，这里应该使用系统的时间选择器API
    const hours = 0;
    const minutes = 25;
    const totalSeconds = (hours * 3600) + (minutes * 60);

    if (totalSeconds > 0) {
      this.timeLeft = totalSeconds;
      this.stopTimer();
    }
  }

  // 计时结束处理
  private handleTimerFinish(): void {
    this.stopTimer();

    // 记录完成历史
    if (this.currentTask) {
      const finishedTimer: TimerItem = {
        id: Date.now(),
        taskName: this.currentTask.plan,
        duration: 1500, // 默认25分钟
        endTime: new Date().toISOString(),
        completed: true
      };

      this.timerHistory = [finishedTimer, ...this.timerHistory];

      // 显示完成提示
      promptAction.showToast({
        message: `任务 "${this.currentTask.plan}" 已完成！`,
        duration: 3000
      });

      // 标记待办为已完成（可选功能）
      // this.markTodoAsFinished(this.currentTask.id);
    }
  }

  // 标记待办为已完成（可选）
  private markTodoAsFinished(id: number): void {
    const newList = this.planList.map((item: TodoItem): TodoItem => {
      if (item.id === id) {
        return {
          id: item.id,
          plan: item.plan,
          isFinished: true,
          createTime: item.createTime
        };
      }
      return item;
    });

    this.planList = [...newList];
  }

  // 打开添加待办弹窗
  private openAddTodoDialog(): void {
    this.showAddTodoDialog = true;
    this.showTaskPicker = false;
  }

  // 添加待办事项
  private addTodoToList(planText: string): void {
    if (!planText.trim()) {
      return;
    }

    let maxId = 0;
    if (this.planList && this.planList.length > 0) {
      maxId = this.planList.reduce((max, item) => item.id > max ? item.id : max, 0);
    }

    const newTodo: TodoItem = {
      id: maxId + 1,
      plan: planText,
      isFinished: false
    };

    // 更新待办列表
    this.planList = [...this.planList, newTodo];

    // 自动选中新添加的待办
    this.currentTask = newTodo;
    this.showAddTodoDialog = false;

    promptAction.showToast({
      message: '待办已添加并选中',
      duration: 2000
    });
  }

  // 获取未完成的待办事项
  private getUnfinishedTodos(): TodoItem[] {
    return this.planList ? this.planList.filter(item => !item.isFinished) : [];
  }

  // 获取已完成或所有待办（如果没有未完成的）
  private getTodosForPicker(): TodoItem[] {
    const unfinished = this.getUnfinishedTodos();
    if (unfinished.length > 0) {
      return unfinished;
    }
    return this.planList || []; // 返回所有待办
  }

  // 任务选择弹窗
  @Builder
  private TaskPickerDialog() {
    Column() {
      // 半透明背景（点击关闭）
      Column() {
        Blank()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .opacity(0.3)
      .onClick(() => {
        this.showTaskPicker = false;
      })

      // 弹窗内容
      Column() {
        // 弹窗头部
        Row() {
          Text('选择待办事项')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')

          Blank()

          Image($r('app.media.false'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.showTaskPicker = false;
            })
        }
        .width('100%')
        .padding({ top: 24, left: 24, right: 24 })

        // 待办事项列表
        if (this.getTodosForPicker().length > 0) {
          Scroll() {
            Column({ space: 12 }) {
              ForEach(this.getTodosForPicker(), (todo: TodoItem) => {
                Row({ space: 16 }) {
                  // 完成状态图标
                  Image(todo.isFinished ?
                    $r('app.media.finished') :
                    $r('app.media.unfinish'))
                    .width(24)
                    .height(24)
                    .objectFit(ImageFit.Contain)

                  Column() {
                    Text(todo.plan)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(todo.isFinished ? '#999999' : '#333333')
                      .decoration({
                        type: todo.isFinished ?
                          TextDecorationType.LineThrough :
                          TextDecorationType.None,
                        color: '#FF6B6B'
                      })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (todo.isFinished) {
                      Text('已完成')
                        .fontSize(12)
                        .fontColor('#999999')
                        .margin({ top: 2 })
                    }
                  }
                  .layoutWeight(1)

                  // 选中标记
                  if (this.currentTask?.id === todo.id) {
                    Image($r('app.media.finished'))
                      .width(20)
                      .height(20)
                      .objectFit(ImageFit.Contain)
                  }
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 12, bottom: 12 })
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .onClick(() => {
                  if (!todo.isFinished) {
                    this.selectTodoAsTask(todo);
                  }
                })
                .opacity(todo.isFinished ? 0.6 : 1)
              })
            }
            .padding({ left: 24, right: 24 })
          }
          .width('100%')
          .height(300)
          .margin({ top: 20 })
        } else {
          // 没有待办事项时的提示
          Column() {
            Image($r('app.media.add'))
              .width(60)
              .height(60)
              .margin({ bottom: 20 })
              .opacity(0.5)

            Text('暂无待办事项')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ bottom: 8 })

            Text('点击下方按钮创建第一个待办')
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        // 按钮区域
        Column({ space: 12 }) {
          // 添加待办按钮
          Button('新建待办', { type: ButtonType.Normal })
            .width('80%')
            .height(40)
            .backgroundColor('#409EFF')
            .fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => {
              this.openAddTodoDialog();
            })

          // 自定义时间按钮（独立于待办）
          Button('自定义时间任务', { type: ButtonType.Normal })
            .width('80%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .fontColor('#666666')
            .onClick(() => {
              this.showTaskPicker = false;
              this.currentTask = null; // 设置为非待办任务
              this.showTimePicker();
            })

          // 关闭按钮
          Button('关闭', { type: ButtonType.Normal })
            .width('80%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .fontColor('#666666')
            .margin({ top: 10, bottom: 24 })
            .onClick(() => {
              this.showTaskPicker = false;
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('80%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({
        radius: 24,
        color: '#00000040',
        offsetX: 0,
        offsetY: 8
      })
      .position({ x: '10%', y: '10%' })
    }
  }

  // 添加待办弹窗（复用你的AddTodoDialog）
  @Builder
  private AddTodoDialog() {
    Stack() {
      // 半透明背景
      Column() {
        Blank()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .opacity(0.3)
      .onClick(() => {
        this.showAddTodoDialog = false;
      })

      // 弹窗内容
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
              this.showAddTodoDialog = false;
            })
        }
        .width('100%')
        .padding({ top: 24, left: 24, right: 24 })

        // 输入区域
        Column({ space: 8 }) {
          Text('待办内容')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .textAlign(TextAlign.Start)

          TextInput({ placeholder: '请输入待办事项...', text: '' })
            .width('100%')
            .height(100)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E8E8E8' })
            .borderRadius(8)
            .padding(12)
            .fontSize(16)
            .onChange((value: string) => {
              // 这里需要创建一个临时状态来存储输入值
              // 为了简化，我们在确认按钮中直接弹出系统对话来获取输入
            })
            .maxLength(100)
            .id('todoInput')
        }
        .width('100%')
        .padding({ top: 24, left: 24, right: 24 })

        // 按钮区域
        Row({ space: 12 }) {
          // 取消按钮
          Button('取消', { type: ButtonType.Normal })
            .width('40%')
            .height(40)
            .backgroundColor('#FFFFFF')
            .fontColor('#666666')
            .border({ width: 1, color: '#E8E8E8' })
            .borderRadius(20)
            .onClick(() => {
              this.showAddTodoDialog = false;
            })

          // 确认按钮
          Button('确认', { type: ButtonType.Normal })
            .width('40%')
            .height(40)
            .backgroundColor('#409EFF')
            .fontColor('#FFFFFF')
            .borderRadius(20)
            .onClick(() => {
              // 由于 ArkTS 的 UI 文本输入获取在此处较复杂，保留使用系统 prompt 的方式
              promptAction.showDialog({
                title: '输入待办内容',
                message: '请输入待办事项：',
                buttons: [
                  {
                    text: '取消',
                    color: '#666666'
                  },
                  {
                    text: '确认',
                    color: '#409EFF'
                  }
                ]
              }).then((result: PromptResult) => {
                if (result.index === 1) {
                  const planText = result.message?.trim() || '';
                  if (planText) {
                    this.addTodoToList(planText);
                  }
                }
                this.showAddTodoDialog = false;
              });
            })
        }
        .width('100%')
        .padding({ top: 32, bottom: 24 })
        .justifyContent(FlexAlign.Center)
      }
      .width('80%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({
        radius: 24,
        color: '#00000040',
        offsetX: 0,
        offsetY: 8
      })
      .position({ x: '10%', y: '30%' })
    }
  }

  build() {
    // 统一使用一个根节点 Stack，将主界面和弹窗按层放置
    Stack() {
      // 主界面
      Column() {
        // 顶部：任务选择区域
        Column() {
          Text('当前任务')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 8 })

          if (this.currentTask) {
            // 显示选中的待办事项
            Row() {
              Image(this.currentTask.isFinished ?
                $r('app.media.finished') :
                $r('app.media.unfinish'))
                .width(20)
                .height(20)
                .margin({ right: 12 })

              Text(this.currentTask.plan)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentTask.isFinished ? '#999999' : '#1A1A1A')
                .decoration({
                  type: this.currentTask.isFinished ?
                    TextDecorationType.LineThrough :
                    TextDecorationType.None,
                  color: '#FF6B6B'
                })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Image($r('app.media.ic_dropdown'))
                .width(16)
                .height(16)
                .margin({ left: 8 })
            }
            .onClick(() => {
              this.showTaskPicker = true;
            })
          } else {
            // 没有选择任务时
            Row() {
              Text('请选择待办事项')
                .fontSize(18)
                .fontColor('#999999')

              Image($r('app.media.ic_dropdown'))
                .width(16)
                .height(16)
                .margin({ left: 8 })
            }
            .onClick(() => {
              this.showTaskPicker = true;
            })
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .shadow({
          radius: 8,
          color: '#00000010',
          offsetX: 0,
          offsetY: 2
        })
        .margin({ top: 60, bottom: 40 })
        .alignItems(HorizontalAlign.Center)

        // 中间：计时器显示区域
        Column() {
          // 圆形进度条
          Stack() {
            // 背景圆环
            Circle({ width: 280, height: 280 })
              .fill(Color.Transparent)
              .stroke('#E8E8E8')
              .strokeWidth(8)

            // 进度圆环
            Circle({ width: 280, height: 280 })
              .fill(Color.Transparent)
              .stroke('#409EFF')
              .strokeWidth(8)
              .strokeDashArray([this.timerProgress * 8.8, 880])
              .strokeDashOffset(220)

            // 时间显示
            Column() {
              Text(this.formatTime(this.timeLeft))
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.timeLeft < 60 ? '#FF4757' : '#333333')

              Text('剩余时间')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
          }
          .margin({ bottom: 40 })

          // 时间设置提示
          Text('点击设置自定义时间')
            .fontSize(14)
            .fontColor('#1890FF')
            .margin({ bottom: 40 })
            .onClick(() => {
              this.showTimePicker();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // 底部：控制按钮区域
        Column() {
          if (!this.isRunning) {
            // 开始按钮
            Button('开始专注', { type: ButtonType.Capsule })
              .width(200)
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.currentTask ? '#409EFF' : '#CCCCCC')
              .enabled(!!this.currentTask && !this.currentTask.isFinished)
              .onClick(() => {
                this.startTimer();
              })
          } else {
            Row({ space: 20 }) {
              // 暂停/继续按钮
              Button(this.isPaused ? '继续' : '暂停', { type: ButtonType.Capsule })
                .width(140)
                .height(48)
                .fontSize(16)
                .backgroundColor(this.isPaused ? '#52C41A' : '#FA8C16')
                .onClick(() => {
                  if (this.isPaused) {
                    this.resumeTimer();
                  } else {
                    this.pauseTimer();
                  }
                })

              // 结束按钮
              Button('结束', { type: ButtonType.Capsule })
                .width(140)
                .height(48)
                .fontSize(16)
                .backgroundColor('#F5222D')
                .onClick(() => {
                  this.stopTimer();
                })
            }
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 40 })

        // 状态提示
        if (this.isRunning) {
          Text(this.isPaused ? '已暂停' : '专注中...')
            .fontSize(14)
            .fontColor(this.isPaused ? '#FA8C16' : '#52C41A')
            .margin({ top: 20 })
        }

        // 完成次数统计
        if (this.timerHistory.length > 0) {
          Column() {
            Divider()
              .color('#E8E8E8')
              .strokeWidth(1)
              .margin({ top: 40, bottom: 20 })

            Row() {
              Text('今日已完成')
                .fontSize(14)
                .fontColor('#666666')

              Blank()

              Text(`${this.timerHistory.length} 次`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#409EFF')
            }
            .width('100%')
            .padding({ left: 24, right: 24 })
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      // 弹窗层（条件渲染，仍属于 Stack 的子节点 —— 因此 build() 只有一个根）
      if (this.showTaskPicker) {
        this.TaskPickerDialog()
      }

      if (this.showAddTodoDialog) {
        this.AddTodoDialog()
      }
    }
  }

  aboutToDisappear() {
    // 页面消失时清理定时器
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
  }
}
