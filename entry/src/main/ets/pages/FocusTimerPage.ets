// src/main/ets/pages/FocusTimerPage.ets
import { TimerItem } from '../Types/TimerItem';
import { TodoItem } from '../Types/ToDoItem';
import { AddTodoDialog } from './AddTodoDialog';
import { CountdownPickerDialog } from './CustomTimePickerDialog';
import promptAction from '@ohos.promptAction';

@Component
export struct FocusTimerPage {
  @Link planList: TodoItem[];
  @State currentTask: TodoItem | null = null;
  @State timeLeft: number = 1500;
  @State initialTime: number = 1500;
  @State isRunning: boolean = false;
  @State isPaused: boolean = false;
  @State timerProgress: number = 0;
  @State showTaskPicker: boolean = false;
  @State showAddTodoDialog: boolean = false;
  @State selectedHour: number = 0;
  @State selectedMinute: number = 25;
  @State selectedSecond: number = 0;
  private timerId: number = 0;
  @State timerHistory: TimerItem[] = [];
  // 添加 CustomDialogController
  private countdownDialogController?: CustomDialogController;
  private addTodoDialogController?: CustomDialogController;

  aboutToAppear() {
    if (this.planList && this.planList.length > 0) {
      const unfinishedTodo = this.planList.find(item => !item.isFinished);
      if (unfinishedTodo) {
        this.currentTask = unfinishedTodo;
      } else {
        this.currentTask = this.planList[0];
      }
    }

    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
      this.isRunning = false;
      this.isPaused = false;
    }

    this.initialTime = this.selectedHour * 3600 + this.selectedMinute * 60 + this.selectedSecond;
    this.timeLeft = this.initialTime;
  }

  private handleTimeUpdate(h: number, m: number, s: number): void {
    const newTimeInSeconds = h * 3600 + m * 60 + s;

    if (newTimeInSeconds < 1) {
      promptAction.showToast({ message: '专注时间至少为 1 秒' });
      return;
    }

    this.selectedHour = h;
    this.selectedMinute = m;
    this.selectedSecond = s;

    if (this.isRunning || this.isPaused) {
      this.stopTimer(false);
    }

    this.initialTime = newTimeInSeconds;
    this.timeLeft = newTimeInSeconds;
    this.timerProgress = 0;
  }

  private formatTime(seconds: number): string {
    const absSeconds = Math.abs(seconds);
    const hour = Math.floor(absSeconds / 3600);
    const minute = Math.floor((absSeconds % 3600) / 60);
    const second = Math.floor(absSeconds % 60);

    const hourStr = hour.toString().padStart(2, '0');
    const minuteStr = minute.toString().padStart(2, '0');
    const secondStr = second.toString().padStart(2, '0');

    if (hour > 0) {
      return `${hourStr}:${minuteStr}:${secondStr}`;
    }
    return `${minuteStr}:${secondStr}`;
  }

  private startTimer(): void {
    if (this.initialTime <= 0) {
      promptAction.showToast({ message: '请先设置专注时间' });
      return;
    }

    if (this.currentTask === null && this.initialTime === 0) {
      promptAction.showToast({ message: '请先选择任务或设置专注时间' });
      return;
    }

    if (this.isRunning) {
      return;
    }

    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }

    this.isRunning = true;
    this.isPaused = false;
    this.initialTime = this.timeLeft;

    const timerIdRef = setInterval(() => {
      if (!this.isRunning) {
        clearInterval(timerIdRef);
        this.timerId = 0;
        return;
      }

      if (this.timeLeft > 0) {
        this.timeLeft -= 1;
        this.timerProgress = 100 - (this.timeLeft / this.initialTime) * 100;
      } else {
        clearInterval(timerIdRef);
        this.timerId = 0;
        this.isRunning = false;
        this.isPaused = false;
        this.handleTimerFinish();
      }
    }, 1000);
    this.timerId = timerIdRef;
  }

  private pauseTimer(): void {
    if (this.isRunning && !this.isPaused) {
      clearInterval(this.timerId);
      this.isPaused = true;
    }
  }

  private resumeTimer(): void {
    if (this.isRunning && this.isPaused) {
      if (this.timerId) {
        clearInterval(this.timerId);
        this.timerId = 0;
      }

      this.isPaused = false;
      const timerIdRef = setInterval(() => {
        if (!this.isRunning) {
          clearInterval(timerIdRef);
          this.timerId = 0;
          return;
        }

        if (this.timeLeft > 0) {
          this.timeLeft -= 1;
          this.timerProgress = 100 - (this.timeLeft / this.initialTime) * 100;
        } else {
          clearInterval(timerIdRef);
          this.timerId = 0;
          this.isRunning = false;
          this.isPaused = false;
          this.handleTimerFinish();
        }
      }, 1000);
      this.timerId = timerIdRef;
    }
  }

  private stopTimer(saveTime: boolean = true): void {
    if (saveTime && this.isRunning && this.currentTask) {
      const elapsedTime = this.initialTime - this.timeLeft;
      if (elapsedTime > 0) {
        const taskId = this.currentTask.id;
        const newList = this.planList.map((item: TodoItem): TodoItem => {
          if (item.id === taskId) {
            return {
              id: item.id,
              name: item.name,
              deadline: item.deadline,
              total_time: item.total_time + elapsedTime,
              isFinished: item.isFinished,
            };
          }
          return item;
        });
        this.planList = newList.slice();

        this.timerHistory = [{
          id: Date.now(),
          taskName: this.currentTask.name,
          duration: elapsedTime,
          endTime: new Date().toISOString(),
          completed: false
        }, ...this.timerHistory];
      }
    }

    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
    this.isRunning = false;
    this.isPaused = false;
    this.initialTime = this.selectedHour * 3600 + this.selectedMinute * 60 + this.selectedSecond;
    this.timeLeft = this.initialTime;
    this.timerProgress = 0;
  }

  private selectTodoAsTask(todo: TodoItem): void {
    if (this.isRunning || this.isPaused) {
      this.stopTimer(true);
    }
    this.currentTask = todo;
    this.showTaskPicker = false;
  }

  private handleTimerFinish(): void {
    const elapsedTime = this.initialTime;

    this.initialTime = this.selectedHour * 3600 + this.selectedMinute * 60 + this.selectedSecond;
    this.timeLeft = this.initialTime;
    this.timerProgress = 0;

    if (this.currentTask) {
      const finishedTimer: TimerItem = {
        id: Date.now(),
        taskName: this.currentTask.name,
        duration: elapsedTime,
        endTime: new Date().toISOString(),
        completed: true
      };

      this.timerHistory = [finishedTimer, ...this.timerHistory];
      const taskId = this.currentTask.id;
      const newList = this.planList.map((item: TodoItem): TodoItem => {
        if (item.id === taskId) {
          return {
            id: item.id,
            name: item.name,
            deadline: item.deadline,
            total_time: item.total_time + elapsedTime,
            isFinished: item.isFinished,
          };
        }
        return item;
      });
      this.planList = newList.slice();

      promptAction.showToast({
        message: `任务 "${this.currentTask.name}" 已完成！`,
        duration: 3000
      });
    } else {
      promptAction.showToast({
        message: `专注计时完成！`,
        duration: 3000
      });
      this.timerHistory = [{
        id: Date.now(),
        taskName: '自定义专注',
        duration: elapsedTime,
        endTime: new Date().toISOString(),
        completed: true
      }, ...this.timerHistory];
    }
  }

  // 打开时间选择器弹窗
  private openCountdownDialog(): void {
    if (this.countdownDialogController) {
      this.countdownDialogController.close();
    }
    this.countdownDialogController = new CustomDialogController({
      builder: CountdownPickerDialog({
        selectedHours: this.selectedHour,
        selectedMinutes: this.selectedMinute,
        selectedSeconds: this.selectedSecond,
        onConfirm: (h: number, m: number, s: number) => {
          this.handleTimeUpdate(h, m, s);
        },
        onCancel: () => {
          // 取消操作，不执行任何操作
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });

    this.countdownDialogController.open();
  }

  // 打开添加待办弹窗
  private openAddTodoDialog(): void {
    if (this.addTodoDialogController) {
      this.addTodoDialogController.close();
    }

    this.addTodoDialogController = new CustomDialogController({
      builder: AddTodoDialog({
        onConfirm: (item: TodoItem) => {
          this.addTodoToList(item);
        },
        onCancel: () => {
          // 取消操作，不执行任何操作
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });

    this.addTodoDialogController.open();
  }

  private addTodoToList(item: TodoItem): void {
    this.planList = [...this.planList, item];
    this.currentTask = item;

    promptAction.showToast({
      message: '待办已添加并选中',
      duration: 2000
    });
  }

  private getUnfinishedTodos(): TodoItem[] {
    return this.planList ? this.planList.filter(item => !item.isFinished) : [];
  }

  @Builder
  private TaskPickerDialog() {
    Column() {
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

      Column() {
        Row() {
          Text('选择专注事项')
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

        if (this.getUnfinishedTodos().length > 0) {
          Scroll() {
            Column({ space: 12 }) {
              Row({ space: 16 }) {
                Text('无任务（自定义时间）')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentTask === null ? '#409EFF' : '#333333')
                  .layoutWeight(1)

                if (this.currentTask === null) {
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
                if (this.isRunning || this.isPaused) {
                  this.stopTimer(true);
                }
                this.currentTask = null;
                this.showTaskPicker = false;
              })

              ForEach(this.getUnfinishedTodos(), (todo: TodoItem) => {
                Row({ space: 16 }) {
                  Text(todo.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.currentTask?.id === todo.id ? '#409EFF' : '#333333')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)

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
                  this.selectTodoAsTask(todo);
                })
              })
            }
            .padding({ left: 24, right: 24 })
          }
          .width('100%')
          .height(300)
          .margin({ top: 20 })
        } else {
          Column() {
            Image($r('app.media.add'))
              .width(60)
              .height(60)
              .margin({ bottom: 20 })
              .opacity(0.5)

            Text('暂无未完成待办事项')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ bottom: 8 })
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        Column({ space: 12 }) {
          Button('新建待办', { type: ButtonType.Normal })
            .width('80%')
            .height(40)
            .backgroundColor('#409EFF')
            .fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => {
              this.openAddTodoDialog();
            })

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
    Stack() {
      Column() {
        Column() {
          Text('当前专注目标')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 8 })

          Row() {
            Image(this.currentTask?.isFinished ? $r('app.media.finished') : $r('app.media.unfinish'))
              .width(20)
              .height(20)
              .margin({ right: 12 })
              .visibility(this.currentTask ? Visibility.Visible : Visibility.Hidden)

            Text(this.currentTask ? this.currentTask.name : '无任务')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentTask?.isFinished ? '#999999' : '#1A1A1A')
              .decoration({
                type: this.currentTask?.isFinished ? TextDecorationType.LineThrough : TextDecorationType.None,
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
        }
        .width('90%')
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

        Column() {
          Stack() {
            Circle({ width: 280, height: 280 })
              .fill(Color.Transparent)
              .stroke('#E8E8E8')
              .strokeWidth(8)

            Progress({ value: this.timerProgress, total: 100, type: ProgressType.Ring })
              .color('#409EFF')
              .style({ strokeWidth: 8 })
              .size({ width: 280, height: 280 })

            Column() {
              Text(this.formatTime(this.timeLeft))
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.timeLeft < 60 && this.isRunning ? '#FF4757' : '#333333')

              Text('剩余时间')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
          }
          .margin({ bottom: 40 })
          .onClick(() => {
            if (this.isRunning) {
              promptAction.showToast({ message: '请先停止计时器再修改时间' });
              return;
            }
            this.openCountdownDialog();
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Column() {
          if (this.isRunning) {
            Text(this.isPaused ? '已暂停' : '专注中...')
              .fontSize(14)
              .fontColor(this.isPaused ? '#FA8C16' : '#52C41A')
              .margin({ bottom: 20 })
          }

          if (!this.isRunning) {
            Button('开始专注', { type: ButtonType.Capsule })
              .width(200)
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.initialTime > 0 ? '#409EFF' : '#CCCCCC')
              .enabled(this.initialTime > 0)
              .onClick(() => {
                this.startTimer();
              })
          } else {
            Row({ space: 20 }) {
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

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')
      .padding({ bottom: 50 })

      if (this.showTaskPicker) {
        this.TaskPickerDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  aboutToDisappear() {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
    this.isRunning = false;
    this.isPaused = false;
  }

  aboutToUpdate() {
    if (!this.isRunning && this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
  }
}