export interface TimerItem {
  id: number;
  taskName: string;
  duration: number; // 总时长（秒）
  endTime: string; // 完成时间
  completed: boolean;
}