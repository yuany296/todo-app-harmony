// src/main/ets/pages/FocusTimerPage.ets
import { TimerItem } from '../Types/TimerItem';
import { TodoItem } from '../Types/ToDoItem';
import { AddTodoDialog } from './AddTodoDialog';
import promptAction from '@ohos.promptAction';
import { deviceInfo } from '@kit.BasicServicesKit';

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
  @State initialTime: number = 1500; // 初始时间（秒）
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
    // 如果定时器还在运行，说明是从其他页面返回，需要清理
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
      this.isRunning = false;
      this.isPaused = false;
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
    if (this.isRunning || !this.currentTask) {
      return;
    }

    // 确保清理之前的定时器
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }

    this.isRunning = true;
    this.isPaused = false;
    // 记录初始时间
    this.initialTime = this.timeLeft;

    const timerIdRef = setInterval(() => {
      // 检查是否还在运行状态，防止状态不一致
      if (!this.isRunning) {
        clearInterval(timerIdRef);
        this.timerId = 0;
        return;
      }

      if (this.timeLeft > 0) {
        this.timeLeft -= 1;
        this.timerProgress = this.calculateProgress();
      } else {
        // 时间到了，立即清理定时器并处理完成
        clearInterval(timerIdRef);
        this.timerId = 0;
        // 先设置状态，防止定时器继续运行
        this.isRunning = false;
        this.isPaused = false;
        this.handleTimerFinish();
      }
    }, 1000);
    this.timerId = timerIdRef;
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
      // 确保清理之前的定时器
      if (this.timerId) {
        clearInterval(this.timerId);
        this.timerId = 0;
      }

      this.isPaused = false;
      // 重新启动定时器
      const timerIdRef = setInterval(() => {
        // 检查是否还在运行状态，防止状态不一致
        if (!this.isRunning) {
          clearInterval(timerIdRef);
          this.timerId = 0;
          return;
        }

        if (this.timeLeft > 0) {
          this.timeLeft -= 1;
          this.timerProgress = this.calculateProgress();
        } else {
          // 时间到了，立即清理定时器并处理完成
          clearInterval(timerIdRef);
          this.timerId = 0;
          // 先设置状态，防止定时器继续运行
          this.isRunning = false;
          this.isPaused = false;
          this.handleTimerFinish();
        }
      }, 1000);
      this.timerId = timerIdRef;
    }
  }

  // 停止计时器
  private stopTimer(saveTime: boolean = true): void {
    // 如果正在运行且需要保存时间，记录已用时间
    if (saveTime && this.isRunning && this.currentTask) {
      const elapsedTime = this.initialTime - this.timeLeft;
      if (elapsedTime > 0) {
        // 更新待办的total_time
        const taskId = this.currentTask.id;
        const newList = this.planList.map((item: TodoItem): TodoItem => {
          if (item.id === taskId) {
            return {
              id: item.id,
              name: item.name,
              deadline: item.deadline,
              total_time: item.total_time + elapsedTime,
              isFinished: item.isFinished
            };
          }
          return item;
        });
        this.planList = [...newList];
      }
    }

    // 清理定时器
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
    // 切换任务时，先保存当前任务的计时时间
    if (this.currentTask && this.isRunning) {
      this.stopTimer(true); // 保存时间
    } else {
      this.stopTimer(false); // 不保存时间，只是重置
    }
    this.currentTask = todo;
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
      // 设置新时间前，先保存当前计时时间
      if (this.isRunning && this.currentTask) {
        this.stopTimer(true); // 保存时间
      } else {
        this.stopTimer(false); // 不保存，只是重置
      }
      this.timeLeft = totalSeconds;
    }
  }

  // 计时结束处理
  private handleTimerFinish(): void {
    // 确保定时器已完全停止（在定时器回调中已经清理，这里再次确认）
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }

    // 确保状态已停止（在定时器回调中已经设置，这里再次确认）
    this.isRunning = false;
    this.isPaused = false;

    // 计算已用时间（此时timeLeft应该是0或接近0）
    const elapsedTime = this.initialTime;

    // 重置时间（必须在清理定时器后设置）
    this.timeLeft = 1500; // 重置为默认25分钟
    this.timerProgress = 0;

    // 记录完成历史
    if (this.currentTask) {
      const finishedTimer: TimerItem = {
        id: Date.now(),
        taskName: this.currentTask.name,
        duration: elapsedTime,
        endTime: new Date().toISOString(),
        completed: true
      };

      this.timerHistory = [finishedTimer, ...this.timerHistory];

      // 更新待办的total_time
      const taskId = this.currentTask.id;
      const newList = this.planList.map((item: TodoItem): TodoItem => {
        if (item.id === taskId) {
          return {
            id: item.id,
            name: item.name,
            deadline: item.deadline,
            total_time: item.total_time + elapsedTime,
            isFinished: item.isFinished
          };
        }
        return item;
      });
      this.planList = [...newList];

      // 显示完成提示
      promptAction.showToast({
        message: `任务 "${this.currentTask.name}" 已完成！`,
        duration: 3000
      });
    }
  }

  // 标记待办为已完成（可选）
  private markTodoAsFinished(id: number): void {
    const newList = this.planList.map((item: TodoItem): TodoItem => {
      if (item.id === id) {
        return {
          id: item.id,
          name: item.name,
          deadline: item.deadline,
          total_time: item.total_time,
          isFinished: true
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
  private addTodoToList(item: TodoItem): void {
    // 更新待办列表
    this.planList = [...this.planList, item];

    // 自动选中新添加的待办
    this.currentTask = item;
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
                    Text(todo.name)
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
                .padding({
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 12
                })
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

              Text(this.currentTask.name)
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
        .padding({
          left: 24,
          right: 24,
          top: 12,
          bottom: 12
        })
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

          // 时间设置提示（用 Button 替代 Text 以确保可点击性）
          Button('点击设置自定义时间', { type: ButtonType.Normal })
            .fontSize(14)
            .fontColor('#1890FF')
            .backgroundColor(Color.Transparent)
            .margin({ bottom: 40 })
            .onClick(() => {
              console.log('showTimePicker invoked from UI');
              this.showTimePicker();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // 底部：控制按钮区域
        Column() {
          // 状态提示（放在按钮上方）
          if (this.isRunning) {
            Text(this.isPaused ? '已暂停' : '专注中...')
              .fontSize(14)
              .fontColor(this.isPaused ? '#FA8C16' : '#52C41A')
              .margin({ bottom: 20 })
          }

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
      .padding({ bottom: 50 })

      // 弹窗层（条件渲染，仍属于 Stack 的子节点 —— 因此 build() 只有一个根）
      if (this.showTaskPicker) {
        this.TaskPickerDialog()
      }

      if (this.showAddTodoDialog) {
        AddTodoDialog({
          onConfirm: (item: TodoItem) => {
            this.addTodoToList(item);
          },
          onCancel: () => {
            this.showAddTodoDialog = false;
          }
        })
      }
    }
  }

  aboutToDisappear() {
    // 页面消失时清理定时器
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
    // 重置状态
    this.isRunning = false;
    this.isPaused = false;
  }

  aboutToUpdate() {
    // 当状态更新时，确保定时器状态正确
    // 如果isRunning为false但定时器还在运行，清理它
    if (!this.isRunning && this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
  }
}
