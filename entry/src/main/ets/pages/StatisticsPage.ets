import { TodoItem } from '../Types/ToDoItem';

interface StatisticsData {
  total: number;
  finished: number;
  unfinished: number;
  totalTime: number;
  overdue: number;
}

@Component
export struct StatisticsPage {
  @Link planList: TodoItem[];

  // 计算统计数据
  private getStatistics(): StatisticsData {
    const total = this.planList.length;
    const finished = this.planList.filter(item => item.isFinished).length;
    const unfinished = total - finished;
    const totalTime = this.planList.reduce((sum, item) => sum + item.total_time, 0);
    const overdue = this.planList.filter(item => {
      if (item.isFinished) {
        return false;
      }
      const deadline = new Date(item.deadline);
      return deadline < new Date();
    }).length;

    return {
      total,
      finished,
      unfinished,
      totalTime,
      overdue
    };
  }

  // 格式化时间显示
  private formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) {
      return `${hours}小时${minutes}分钟`;
    }
    return `${minutes}分钟`;
  }

  // 格式化截止时间显示
  private formatDeadline(deadline: string): string {
    if (!deadline) return '';
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

  // 获取排序后的任务列表（按计时时间降序，有计时时间的排在前面）
  private getSortedTasks(): TodoItem[] {
    const sorted = [...this.planList].sort((a, b) => {
      // 先按计时时间降序
      if (b.total_time !== a.total_time) {
        return b.total_time - a.total_time;
      }
      // 如果计时时间相同，按名称排序
      return a.name.localeCompare(b.name);
    });
    return sorted;
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('统计信息')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .padding({ top: 20, bottom: 20, left: 24 })
      .backgroundColor('#FFFFFF')

      // 统计卡片
      Scroll() {
        Column({ space: 16 }) {
          // 总体统计卡片
          Column() {
            Text('总体统计')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 16 })

            Row({ space: 20 }) {
              // 总待办
              Column() {
                Text(this.getStatistics().total.toString())
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#409EFF')
                Text('总待办')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .padding(16)
              .backgroundColor('#F0F7FF')
              .borderRadius(12)

              // 已完成
              Column() {
                Text(this.getStatistics().finished.toString())
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#52C41A')
                Text('已完成')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .padding(16)
              .backgroundColor('#F6FFED')
              .borderRadius(12)
            }
            .width('100%')
            .margin({ bottom: 12 })

            Row({ space: 20 }) {
              // 未完成
              Column() {
                Text(this.getStatistics().unfinished.toString())
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FA8C16')
                Text('未完成')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .padding(16)
              .backgroundColor('#FFF7E6')
              .borderRadius(12)

              // 已逾期
              Column() {
                Text(this.getStatistics().overdue.toString())
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#F5222D')
                Text('已逾期')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .padding(16)
              .backgroundColor('#FFF1F0')
              .borderRadius(12)
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#00000010',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ top: 16, left: 16, right: 16 })

          // 时间统计卡片
          Column() {
            Text('时间统计')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 16 })

            Row() {
              Text('总计时长')
                .fontSize(16)
                .fontColor('#666666')
                .layoutWeight(1)

              Text(this.formatTime(this.getStatistics().totalTime))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#409EFF')
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#00000010',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ left: 16, right: 16 })

          // 完成率
          Column() {
            Text('完成率')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 16 })

            Row() {
              Text(`${this.getStatistics().total > 0 ?
                Math.round((this.getStatistics().finished / this.getStatistics().total) * 100) : 0}%`)
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor('#52C41A')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 20, bottom: 20 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#00000010',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ left: 16, right: 16 })

          // 任务计时列表
          Column() {
            Text('任务计时')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 16 })

            if (this.planList.length > 0) {
              Column({ space: 12 }) {
                ForEach(
                  this.getSortedTasks(),
                  (item: TodoItem, index: number) => {
                    Row({ space: 12 }) {
                      // 任务名称
                      Column({ space: 4 }) {
                        Text(item.name)
                          .fontSize(16)
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

                        // 截止时间
                        Text(this.formatDeadline(item.deadline))
                          .fontSize(12)
                          .fontColor('#999999')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      // 计时时间
                      Column({ space: 4 }) {
                        Text(this.formatTime(item.total_time))
                          .fontSize(16)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#409EFF')
                          .textAlign(TextAlign.End)

                        Text('计时')
                          .fontSize(12)
                          .fontColor('#999999')
                          .textAlign(TextAlign.End)
                      }
                      .alignItems(HorizontalAlign.End)
                    }
                    .width('100%')
                    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
                    .backgroundColor('#F8F9FA')
                    .borderRadius(8)
                  },
                  (item: TodoItem, index: number) => `${item.id}_${item.isFinished}_${item.total_time}`
                )
              }
            } else {
              Column() {
                Text('暂无任务')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ top: 20, bottom: 20 })
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#00000010',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ left: 16, right: 16, bottom: 16 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}