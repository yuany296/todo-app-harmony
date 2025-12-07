// TodoPage.ets
import { TodoItem } from '../Types/ToDoItem';
import { EditModal } from './EditModal';
import { AddTodoDialog } from './AddTodoDialog';

@Component
export struct TodoPage {
  @Link planList: TodoItem[];
  // 可选回调：优先调用父组件的修改回调以确保父状态驱动 UI
  onUpdate?: (updatedItem: TodoItem) => void;
  onDelete?: (id: number) => void;
  onToggle?: (id: number) => void;
  onListChange?: () => void;
  @State isEditModalShow: boolean = false;
  @State currentEditItem: TodoItem | null = null;
  @State refreshKey: number = 0; // 用于强制刷新列表
  editDialogController?: CustomDialogController;
  addDialogController?: CustomDialogController;
  // 父组件的添加回调
  onAddButtonClick?: () => void;

  aboutToAppear() {
    // 页面显示时初始化
    console.log('TodoPage aboutToAppear, planList length:', this.planList.length);
  }

  aboutToUpdate() {
    // 当planList更新时，确保UI刷新
    console.log('TodoPage aboutToUpdate, planList length:', this.planList.length);
  }

  // 🌟 新增：获取排序后的待办事项列表
  private getSortedTodos(): TodoItem[] {
    if (!this.planList || this.planList.length === 0) {
      return [];
    }

    // 创建数组副本进行排序
    const todos = [...this.planList];

    return todos.sort((a: TodoItem, b: TodoItem) => {
      // 1. 首先按完成状态排序：未完成的在前，已完成的在后
      if (a.isFinished && !b.isFinished) {
        return 1; // a已完成，b未完成，b应该在前
      }
      if (!a.isFinished && b.isFinished) {
        return -1; // a未完成，b已完成，a应该在前
      }

      // 2. 如果都是未完成，按截止日期排序：截止日期越早的越靠前
      if (!a.isFinished && !b.isFinished) {
        try {
          const dateA = new Date(a.deadline);
          const dateB = new Date(b.deadline);
          // 比较日期（只比较年月日，忽略时间）
          dateA.setHours(0, 0, 0, 0);
          dateB.setHours(0, 0, 0, 0);

          return dateA.getTime() - dateB.getTime(); // 升序排列
        } catch (e) {
          console.error('日期解析错误:', e);
          return 0;
        }
      }

      // 3. 如果都是已完成，按原来的顺序（或按完成时间排序）
      // 这里保持原来的顺序，或者你可以添加按完成时间排序的逻辑
      return 0;
    });
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('待办事项')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .padding({ top: 20, bottom: 20, left: 24 })
      .backgroundColor('#FFFFFF')

      // 🌟 修改：显示未完成和已完成的统计
      Row() {
        Text(`未完成: ${this.planList.filter(item => !item.isFinished).length}个`)
          .fontSize(14)
          .fontColor('#52C41A')
          .margin({ right: 20 })

        Text(`已完成: ${this.planList.filter(item => item.isFinished).length}个`)
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 列表
      Scroll() {
        List({ space: 12 }) {
          // 🌟 修改：使用排序后的列表
          ForEach(
            this.getSortedTodos(),
            (item: TodoItem, index: number) => {
              ListItem() {
                Row({ space: 16 }) {
                  // 左侧：完成状态图标（点击切换状态）
                  Image(this.getFinishIcon(item.isFinished))
                    .width(24)
                    .height(24)
                    .objectFit(ImageFit.Contain)
                    .onClick(() => {
                      console.log('点击切换状态:', item.id);
                      this.toggleFinishStatus(item.id);
                    })

                  // 中间：待办文本和截止时间（点击编辑）
                  Column({ space: 4 }) {
                    Text(item.name)
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.getTextColor(item))
                      .decoration({
                        type: item.isFinished ?
                          TextDecorationType.LineThrough :
                          TextDecorationType.None,
                        color: '#FF6B6B'
                      })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .onClick(() => {
                        this.editTodo(item.id);
                      })

                    // 截止时间
                    Text(this.formatDeadline(item.deadline))
                      .fontSize(12)
                      .fontColor('#999999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .onClick(() => {
                        this.editTodo(item.id);
                      })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  // 右侧：删除图标（点击删除）
                  Image($r('app.media.delete'))
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
            },
            // 🌟 修改：key 中包含排序相关的字段
            (item: TodoItem,
              index: number) => `${item.id}_${item.isFinished}_${item.deadline}_${item.name}_${this.refreshKey}`
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

      // 添加按钮
      Row() {
        Image($r('app.media.add'))
          .width(48)
          .height(48)
          .backgroundColor(Color.White)
          .borderRadius(28)
          .shadow({
            radius: 12,
            color: '#00000030',
            offsetX: 0,
            offsetY: 6
          })
          .onClick(() => {
            // 使用自己的弹窗控制器
            this.addDialogController = new CustomDialogController({
              builder: AddTodoDialog({
                onConfirm: (item: TodoItem) => {
                  this.addTodo(item);
                },
                onCancel: () => {
                }
              }),
              autoCancel: true,
              alignment: DialogAlignment.Center
            });

            this.addDialogController.open();
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
  }

  // --- 逻辑方法 ---
  // 编辑待办
  private editTodo(id: number): void {
    console.log('editTodo called for id:', id);
    const itemToEdit = this.planList.find(item => item.id === id);
    if (itemToEdit) {
      this.currentEditItem = {
        id: itemToEdit.id,
        name: itemToEdit.name,
        deadline: itemToEdit.deadline,
        total_time: itemToEdit.total_time,
        isFinished: itemToEdit.isFinished
      };
      this.showEditDialog();
    }
  }

  // 显示编辑弹窗
  private showEditDialog(): void {
    if (this.editDialogController) {
      this.editDialogController.close();
    }

    this.editDialogController = new CustomDialogController({
      builder: EditModal({
        todoItem: this.currentEditItem,
        onCancel: () => {
          this.closeEditModal();
        },
        onSave: (updatedItem: TodoItem) => {
          this.updateTodo(updatedItem);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });

    this.editDialogController.open();
  }

  // 关闭编辑弹窗
  private closeEditModal(): void {
    if (this.editDialogController) {
      this.editDialogController.close();
    }
    this.currentEditItem = null;
  }

  // 更新待办
  private updateTodo(updatedItem: TodoItem): void {
    console.log('updateTodo called for id:', updatedItem.id, 'name:', updatedItem.name);
    // 直接更新 @Link 绑定的数组
    const index = this.planList.findIndex(item => item.id === updatedItem.id);
    if (index >= 0) {
      const newList = this.planList.slice();
      newList[index] = updatedItem;
      this.planList = [...newList];

      // 🌟 关键修改点：强制刷新列表，更新 refreshKey
      this.refreshKey = Date.now();
    }

    // 如果有回调，通知父组件（保持兼容性）
    if (this.onUpdate) {
      this.onUpdate(updatedItem);
    }

    this.closeEditModal();
  }

  // 切换完成状态
  private toggleFinishStatus(id: number): void {
    console.log('切换状态，ID:', id, '当前列表:', this.planList);

    // 优先使用父组件的回调，让父组件统一管理状态
    if (this.onToggle) {
      this.onToggle(id);
      // 强制刷新列表
      this.refreshKey = Date.now();
    } else {
      // 如果没有回调，直接更新 @Link 绑定的数组
      const newList = this.planList.map((item: TodoItem): TodoItem => {
        if (item.id === id) {
          const updatedItem: TodoItem = {
            id: item.id,
            name: item.name,
            deadline: item.deadline,
            total_time: item.total_time,
            isFinished: !item.isFinished
          };
          console.log('更新项目:', updatedItem);
          return updatedItem;
        }
        return item;
      });

      // 必须创建新数组才能触发更新
      this.planList = [...newList];
      // 强制刷新列表
      this.refreshKey = Date.now();
    }

    console.log('状态切换完成');
  }

  // 删除
  private deleteTodo(id: number): void {
    console.log('deleteTodo called for id:', id);
    // 直接更新 @Link 绑定的数组
    const newList = this.planList.filter(item => item.id !== id);
    this.planList = [...newList];

    // 🌟 关键修改点：强制刷新列表，更新 refreshKey
    this.refreshKey = Date.now();

    // 如果有回调，通知父组件（保持兼容性）
    if (this.onDelete) {
      this.onDelete(id);
    }

    console.log('删除完成，剩余:', this.planList.length, '条');
  }

  // 完成图标
  private getFinishIcon(isFinished: boolean): Resource {
    return isFinished ?
      $r('app.media.finished') :
      $r('app.media.unfinish');
  }

  // 格式化截止时间显示
  private formatDeadline(deadline: string): string {
    if (!deadline) {
      return '';
    }
    try {
      const date = new Date(deadline);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');
      return `截止：${year}-${month}-${day}`;
    } catch (e) {
      return '';
    }
  }

  // 判断是否逾期
  private isOverdue(item: TodoItem): boolean {
    if (item.isFinished) {
      return false;
    }
    try {
      const deadline = new Date(item.deadline);
      const now = new Date();
      // 只比较日期，不考虑时间
      deadline.setHours(0, 0, 0, 0);
      now.setHours(0, 0, 0, 0);
      return deadline < now;
    } catch (e) {
      return false;
    }
  }

  // 获取文字颜色（逾期显示红色）
  private getTextColor(item: TodoItem): string {
    if (item.isFinished) {
      return '#999999';
    }
    if (this.isOverdue(item)) {
      return '#FF4757';
    } // 逾期显示红色
    return '#333333';
  }

  // 添加待办
  private addTodo(item: TodoItem): void {
    this.planList = this.planList.concat([item]);
    // 🌟 关键修改点：强制刷新列表，更新 refreshKey
    this.refreshKey = Date.now();
  }
}