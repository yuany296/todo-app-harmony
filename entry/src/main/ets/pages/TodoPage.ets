// TodoPage.ets
import router from '@ohos.router';
import { TodoItem } from '../Types/ToDoItem';

@Component
export struct TodoPage {
  @Link planList: TodoItem[];
  @State selectedId: number | null = null;
  // 可选：接收父组件的回调函数
  private onListChange?: () => void;

  build() {
    Column() {
      // 标题区域
      Row() {
        Text('待办事项')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .padding({ top: 60, bottom: 20, left: 24 })
      .backgroundColor('#FFFFFF')

      // 待办事项列表
      Scroll() {
        List({ space: 12 }) {
          ForEach(
            this.planList,
            (item: TodoItem) => {
              ListItem() {
                Row({ space: 16 }) {
                  // 完成状态图标
                  Image(this.getFinishIcon(item.isFinished))
                    .width(24)
                    .height(24)
                    .objectFit(ImageFit.Contain)

                  // 待办文本
                  Text(item.plan)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(item.isFinished ? '#999999' : '#333333')
                    .decoration({
                      type: item.isFinished ?
                        TextDecorationType.LineThrough :
                        TextDecorationType.None,
                      color: '#FF6B6B'
                    })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  // 删除按钮（可选）
                  Image($r('app.media.foreground'))
                    .width(20)
                    .height(20)
                    .opacity(0.6)
                    .onClick(() => {
                      this.deleteTodo(item.id);
                    })
                }
                .width('100%')
                .padding({
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: 16
                })
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .shadow({
                  radius: 8,
                  color: '#00000010',
                  offsetX: 0,
                  offsetY: 2
                })
              }
              .onClick(() => {
                console.log('点击切换状态:', item.id);
                this.toggleFinishStatus(item.id);
              })
            },
            (item: TodoItem) => item.id.toString()
          )
        }
        .width('100%')
        .height('100%')
        .margin({ top: 8, left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .width('100%')
      .layoutWeight(1)

      // 底部添加按钮
      Row() {
        Image($r('app.media.add'))
          .width(48)
          .height(48)
          .backgroundColor(Color.White)
          .borderRadius(24)
          .shadow({
            radius: 12,
            color: '#00000020',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => {
            console.log('点击添加按钮');
            this.addNewTodo();
          })
      }
      .width('100%')
      .padding({ bottom: 40, top: 20 })
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F8F8F8')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
    .onAppear(() => {
      console.log('TodoPage显示，当前列表:', this.planList);
    })
  }

  // 获取对应状态的图标
  private getFinishIcon(isFinished: boolean): Resource {
    return isFinished ?
      $r('app.media.finished') :
      $r('app.media.unfinish');
  }

  // 切换待办状态
  private toggleFinishStatus(id: number): void {
    console.log('切换状态，ID:', id, '当前列表:', this.planList);

    const newList = this.planList.map((item: TodoItem): TodoItem => {
      if (item.id === id) {
        const updatedItem: TodoItem = {
          id: item.id,
          plan: item.plan,
          isFinished: !item.isFinished,
          createTime: item.createTime
        };
        console.log('更新项目:', updatedItem);
        return updatedItem;
      }
      return item;
    });

    // 必须创建新数组才能触发更新
    this.planList = [...newList];

    // 如果有回调，通知父组件
    if (this.onListChange) {
      this.onListChange();
    }

    console.log('状态切换完成，新列表:', this.planList);
  }

  // 删除待办事项
  private deleteTodo(id: number): void {
    console.log('删除待办，ID:', id);

    // 过滤掉要删除的项目
    const newList = this.planList.filter(item => item.id !== id);
    this.planList = [...newList];

    // 如果有回调，通知父组件
    if (this.onListChange) {
      this.onListChange();
    }

    console.log('删除完成，剩余:', this.planList.length, '条');
  }

  private addNewTodo(): void {
    console.log('跳转到添加页面');
    router.pushUrl({
      url: 'pages/AddTodo'
    }).then(() => {
      console.log('跳转成功');
    }).catch((err: Error) => {
      console.error('跳转失败:', err);
    });
  }
}