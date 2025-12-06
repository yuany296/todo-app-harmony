// AddTodo.ets (已修复)
import router from '@ohos.router';
import { TodoItem } from '../Types/ToDoItem'; // 假定 TodoItem 结构未变

@Entry
@Component
export struct AddTodoPage {
  @State todoText: string = '';

  // 🚨 移除接收 planList 的状态和逻辑，ID 应由 TodoPage 统一生成
  // @State receivedPlanList: TodoItem[] = [];

  aboutToAppear() {
    console.log('AddTodoPage页面显示');
    // 移除所有关于接收 planList 的逻辑
    console.log('AddTodoPage初始化完成');
  }

  build() {
    // ... UI 部分保持不变 ...
    Column({ space: 16 }) {
      // 顶部导航栏 (保持不变)
      Row({ space: 12 }) {
        Image($r('app.media.go_back'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('添加待办')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Blank()
      }
      .width('100%')
      .padding({
        top: 60,
        bottom: 20,
        left: 24,
        right: 24
      })
      .backgroundColor('#FFFFFF')

      // 主要内容 (保持不变)
      Scroll() {
        Column({ space: 24 }) {
          // 输入区域
          Column({ space: 8 }) {
            Text('待办内容')
              .fontSize(16)
              .fontColor('#666666')

            TextInput({ placeholder: '请输入待办事项...', text: this.todoText })
              .width('100%')
              .height(120)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#E8E8E8' })
              .borderRadius(12)
              .padding(16)
              .fontSize(16)
              .onChange((value: string) => {
                this.todoText = value;
              })
              .maxLength(100)
          }
          .width('100%')
        }
        .width('100%')
        .padding(24)
      }
      .layoutWeight(1)

      // 底部按钮 (保持不变)
      Row() {
        Button('保存')
          .width('90%')
          .height(48)
          .backgroundColor(this.todoText.trim() ? '#409EFF' : '#CCCCCC')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .enabled(!!this.todoText.trim())
          .onClick(() => {
            this.saveTodo();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  private saveTodo(): void {
    if (!this.todoText.trim()) {
      return;
    }

    console.log('准备返回待办事项内容:', this.todoText.trim());

    // 🚨 核心修复：返回目标改为 'pages/Index'
    // 🚨 核心修复：只传递文本内容 newTodoPlan
    router.back({
      url: 'pages/Index',
      params: {
        newTodoPlan: this.todoText.trim(),
        operation: 'add',
        timestamp: new Date().getTime()
      }
    });
  }
}