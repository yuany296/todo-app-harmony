// PreferenceHelper.ets
import { TodoItem } from '../Types/ToDoItem';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'todo_prefs';
const KEY_PLAN_LIST = 'planList';

// 初始化Preferences实例
let pref: preferences.Preferences | null = null;

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
    return raw ? JSON.parse(raw as string) : null;
  } catch (err) {
    console.error('loadPlanList error:', err);
    return null;
  }
}