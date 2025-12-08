// PreferenceHelper.ets
import { TodoItem } from '../Types/ToDoItem';
import { TimerItem } from '../Types/TimerItem';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'todo_prefs';
const KEY_PLAN_LIST = 'planList';
const KEY_TIMER_HISTORY = 'timerHistory';

// 初始化Preferences实例
let pref: preferences.Preferences | null = null;

// 订阅者，当 timerHistory 变化时会被通知
let timerHistorySubscribers: Array<() => void> = [];

export function subscribeTimerHistory(cb: () => void): () => void {
  timerHistorySubscribers.push(cb);
  return () => {
    timerHistorySubscribers = timerHistorySubscribers.filter(f => f !== cb);
  };
}
async function initPreferences(): Promise<void> {
  if (!pref) {
    pref = await preferences.getPreferences(getContext(), PREF_NAME);
  }
}

export async function savePlanList(planList: TodoItem[]): Promise<void> {
  try {
    await initPreferences();
    await pref!.put(KEY_PLAN_LIST, JSON.stringify(planList || []));
    await pref!.flush();
    console.info('Preferences: saved planList');
  } catch (err) {
    console.error('savePlanList error:', err);
  }
}

export async function loadPlanList(): Promise<TodoItem[] | null> {
  try {
    await initPreferences();
    const raw = await pref!.get(KEY_PLAN_LIST, '');
    return raw ? JSON.parse(raw as string) as TodoItem[] : null;
  } catch (err) {
    console.error('loadPlanList error:', err);
    return null;
  }
}

// ----- Timer history persistence -----
export async function saveTimerHistory(history: TimerItem[]): Promise<void> {
  try {
    await initPreferences();
    await pref!.put(KEY_TIMER_HISTORY, JSON.stringify(history || []));
    await pref!.flush();
    console.info('Preferences: saved timerHistory');
      // 通知订阅者
      try {
        timerHistorySubscribers.forEach(cb => {
          try { cb(); } catch (e) { console.error('timerHistory subscriber error:', e); }
        });
      } catch (err) {
        console.error('notify timerHistory subscribers error:', err);
      }
  } catch (err) {
    console.error('saveTimerHistory error:', err);
  }
}

export async function loadTimerHistory(): Promise<TimerItem[]> {
  try {
    await initPreferences();
    const raw = await pref!.get(KEY_TIMER_HISTORY, '');
    if (!raw) {
      return [];
    }
    const parsed = JSON.parse(raw as string) as Array<Record<string, string | number | boolean>>;
    // 映射并强制类型，以避免 any/unknown
    const history: TimerItem[] = parsed.map(obj => {
      const id = typeof obj['id'] === 'number' ? obj['id'] as number : Number(obj['id']);
      const taskName = obj['taskName'] ? String(obj['taskName']) : '';
      const duration = typeof obj['duration'] === 'number' ? obj['duration'] as number : Number(obj['duration']);
      const endTime = obj['endTime'] ? String(obj['endTime']) : '';
      const completed = !!obj['completed'];
      return {
        id,
        taskName,
        duration,
        endTime,
        completed
      } as TimerItem;
    });
    return history;
  } catch (err) {
    console.error('loadTimerHistory error:', err);
    return [];
  }
}

export async function addTimerItem(item: TimerItem): Promise<void> {
  try {
    const history = await loadTimerHistory();
    history.push(item);
    // 可选：限制历史长度
    const MAX_HISTORY = 1000;
    if (history.length > MAX_HISTORY) {
      history.splice(0, history.length - MAX_HISTORY);
    }
    await saveTimerHistory(history);
  } catch (err) {
    console.error('addTimerItem error:', err);
  }
}

export async function clearTimerHistory(): Promise<void> {
  try {
    await saveTimerHistory([]);
  } catch (err) {
    console.error('clearTimerHistory error:', err);
  }
}

export interface TaskStat {
  count: number;
  totalTime: number;
}

export interface TimerStats {
  total: number;
  completed: number;
  totalTime: number;
  completionRate: number; // 0..1
  taskStats: Record<string, TaskStat>;
}

export async function getTimerStats(): Promise<TimerStats> {
  try {
    const history = await loadTimerHistory();
    const total = history.length;
    const completed = history.filter(item => item.completed).length;
    const totalTime = history.reduce((sum, item) => sum + (item.duration || 0), 0);
    const taskStats: Record<string, TaskStat> = {};
    for (const it of history) {
      const name = it.taskName || '未命名任务';
      if (!taskStats[name]) {
        taskStats[name] = { count: 0, totalTime: 0 };
      }
      taskStats[name].count += 1;
      taskStats[name].totalTime += it.duration || 0;
    }
    const completionRate = total === 0 ? 0 : completed / total;
    return {
      total,
      completed,
      totalTime,
      completionRate,
      taskStats
    } as TimerStats;
  } catch (err) {
    console.error('getTimerStats error:', err);
    return {
      total: 0,
      completed: 0,
      totalTime: 0,
      completionRate: 0,
      taskStats: {}
    } as TimerStats;
  }
}