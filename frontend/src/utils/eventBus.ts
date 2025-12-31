import { ref } from 'vue'

// 事件类型定义
export interface EventMap {
  'record:created': void
  'record:updated': void
  'record:deleted': void
  'file:uploaded': void
  'file:deleted': void
  'user:created': void
  'user:updated': void
  'user:deleted': void
  'dashboard:refresh': void
}

// 事件监听器类型
type EventListener<T = any> = (data?: T) => void

// 事件总线类
class EventBus {
  private listeners: Map<string, EventListener[]> = new Map()

  // 监听事件
  on<K extends keyof EventMap>(event: K, listener: EventListener<EventMap[K]>): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, [])
    }
    this.listeners.get(event)!.push(listener)
  }

  // 移除事件监听
  off<K extends keyof EventMap>(event: K, listener: EventListener<EventMap[K]>): void {
    const eventListeners = this.listeners.get(event)
    if (eventListeners) {
      const index = eventListeners.indexOf(listener)
      if (index > -1) {
        eventListeners.splice(index, 1)
      }
    }
  }

  // 触发事件
  emit<K extends keyof EventMap>(event: K, data?: EventMap[K]): void {
    const eventListeners = this.listeners.get(event)
    if (eventListeners) {
      eventListeners.forEach(listener => listener(data))
    }
  }

  // 移除所有监听器
  clear(): void {
    this.listeners.clear()
  }
}

// 创建全局事件总线实例
export const eventBus = new EventBus()

// 便捷的组合式函数
export function useEventBus() {
  return {
    on: eventBus.on.bind(eventBus),
    off: eventBus.off.bind(eventBus),
    emit: eventBus.emit.bind(eventBus)
  }
}