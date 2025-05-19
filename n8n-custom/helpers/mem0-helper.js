/**
 * Хелпер для работы с Mem0 в n8n
 * Упрощает взаимодействие с Mem0 API из узла Code
 */

const axios = require('axios');

class Mem0Helper {
  /**
   * Создает экземпляр хелпера для работы с Mem0
   * @param {Object} config - Конфигурация подключения
   * @param {string} config.url - URL Mem0 API (по умолчанию http://mem0:3000)
   * @param {string} config.apiKey - API ключ для Mem0
   */
  constructor(config = {}) {
    this.baseUrl = config.url || 'http://mem0:3000';
    this.apiKey = config.apiKey;
    
    if (!this.apiKey) {
      throw new Error('API ключ для Mem0 не указан');
    }
    
    this.axiosInstance = axios.create({
      baseURL: this.baseUrl,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      }
    });
  }

  /**
   * Создание нового воспоминания
   * @param {Object} memory - Данные воспоминания
   * @param {string} memory.user_id - ID пользователя
   * @param {string} memory.content - Содержимое воспоминания
   * @param {string} memory.type - Тип воспоминания
   * @param {string} memory.session_id - ID сессии (опционально)
   * @param {Object} memory.metadata - Метаданные (опционально)
   * @returns {Promise<Object>} - Созданное воспоминание
   */
  async createMemory(memory) {
    try {
      const response = await this.axiosInstance.post('/api/memories', memory);
      return response.data;
    } catch (error) {
      console.error('Error creating memory in Mem0:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Поиск релевантных воспоминаний
   * @param {Object} searchParams - Параметры поиска
   * @param {string} searchParams.user_id - ID пользователя
   * @param {string} searchParams.query - Поисковый запрос
   * @param {number} searchParams.relevance_threshold - Порог релевантности (0-1)
   * @param {number} searchParams.limit - Максимальное количество результатов
   * @param {Array<string>} searchParams.types - Типы воспоминаний для поиска
   * @returns {Promise<Array>} - Найденные воспоминания
   */
  async searchMemories(searchParams) {
    try {
      const response = await this.axiosInstance.post('/api/memories/search', searchParams);
      return response.data;
    } catch (error) {
      console.error('Error searching memories in Mem0:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Получение воспоминания по ID
   * @param {string} memoryId - ID воспоминания
   * @returns {Promise<Object>} - Воспоминание
   */
  async getMemory(memoryId) {
    try {
      const response = await this.axiosInstance.get(`/api/memories/${memoryId}`);
      return response.data;
    } catch (error) {
      console.error('Error getting memory from Mem0:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Обновление воспоминания
   * @param {string} memoryId - ID воспоминания
   * @param {Object} updateData - Данные для обновления
   * @returns {Promise<Object>} - Обновленное воспоминание
   */
  async updateMemory(memoryId, updateData) {
    try {
      const response = await this.axiosInstance.patch(`/api/memories/${memoryId}`, updateData);
      return response.data;
    } catch (error) {
      console.error('Error updating memory in Mem0:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Удаление воспоминания
   * @param {string} memoryId - ID воспоминания
   * @returns {Promise<Object>} - Результат операции
   */
  async deleteMemory(memoryId) {
    try {
      const response = await this.axiosInstance.delete(`/api/memories/${memoryId}`);
      return response.data;
    } catch (error) {
      console.error('Error deleting memory from Mem0:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Получение списка воспоминаний пользователя
   * @param {string} userId - ID пользователя
   * @param {Object} options - Опции запроса
   * @param {number} options.limit - Максимальное количество результатов
   * @param {number} options.offset - Смещение для пагинации
   * @returns {Promise<Array>} - Список воспоминаний
   */
  async listMemories(userId, options = {}) {
    try {
      const params = {
        user_id: userId,
        limit: options.limit || 10,
        offset: options.offset || 0
      };
      
      const response = await this.axiosInstance.get('/api/memories', { params });
      return response.data;
    } catch (error) {
      console.error('Error listing memories from Mem0:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Формирование системного промпта с контекстом из воспоминаний
   * @param {string} userId - ID пользователя
   * @param {string} basePrompt - Базовый системный промпт
   * @param {string} query - Текущий запрос пользователя
   * @param {Object} options - Опции
   * @returns {Promise<string>} - Системный промпт с контекстом
   */
  async generateContextPrompt(userId, basePrompt, query, options = {}) {
    try {
      // Поиск релевантных воспоминаний
      const memories = await this.searchMemories({
        user_id: userId,
        query: query,
        relevance_threshold: options.relevanceThreshold || 0.7,
        limit: options.limit || 5,
        types: options.types || ['preference', 'fact', 'interaction']
      });
      
      // Если воспоминаний нет, возвращаем базовый промпт
      if (!memories || memories.length === 0) {
        return basePrompt;
      }
      
      // Формирование контекста из воспоминаний
      const context = memories.map(memory => {
        return `- ${memory.content} (тип: ${memory.type}, релевантность: ${memory.relevance.toFixed(2)})`;
      }).join('\n');
      
      // Формирование итогового промпта
      return `${basePrompt}\n\nКонтекст из воспоминаний пользователя:\n${context}`;
    } catch (error) {
      console.error('Error generating context prompt:', error);
      // В случае ошибки возвращаем базовый промпт
      return basePrompt;
    }
  }
}

module.exports = Mem0Helper;
