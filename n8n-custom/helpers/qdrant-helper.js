/**
 * Хелпер для работы с Qdrant в n8n
 * Упрощает взаимодействие с Qdrant API из узла Code
 */

const { QdrantClient } = require('@qdrant/js-client-rest');

class QdrantHelper {
  /**
   * Создает экземпляр хелпера для работы с Qdrant
   * @param {Object} config - Конфигурация подключения
   * @param {string} config.url - URL Qdrant API (по умолчанию http://qdrant:6333)
   * @param {string} config.apiKey - API ключ для Qdrant (опционально)
   */
  constructor(config = {}) {
    this.client = new QdrantClient({
      url: config.url || 'http://qdrant:6333',
      apiKey: config.apiKey
    });
  }

  /**
   * Поиск по векторам в коллекции
   * @param {string} collectionName - Имя коллекции
   * @param {Array<number>} vector - Вектор для поиска
   * @param {number} limit - Максимальное количество результатов
   * @param {Object} filter - Фильтр для поиска (опционально)
   * @returns {Promise<Array>} - Результаты поиска
   */
  async search(collectionName, vector, limit = 5, filter = null) {
    try {
      const searchParams = {
        vector: vector,
        limit: limit,
        with_payload: true,
        with_vectors: false
      };
      
      if (filter) {
        searchParams.filter = filter;
      }
      
      return await this.client.search(collectionName, searchParams);
    } catch (error) {
      console.error('Error searching in Qdrant:', error);
      throw error;
    }
  }

  /**
   * Добавление точки в коллекцию
   * @param {string} collectionName - Имя коллекции
   * @param {string|number} id - ID точки
   * @param {Array<number>} vector - Вектор точки
   * @param {Object} payload - Полезная нагрузка (метаданные)
   * @returns {Promise<Object>} - Результат операции
   */
  async upsertPoint(collectionName, id, vector, payload) {
    try {
      return await this.client.upsert(collectionName, {
        points: [
          {
            id: id,
            vector: vector,
            payload: payload
          }
        ]
      });
    } catch (error) {
      console.error('Error upserting point to Qdrant:', error);
      throw error;
    }
  }

  /**
   * Удаление точки из коллекции
   * @param {string} collectionName - Имя коллекции
   * @param {string|number} id - ID точки
   * @returns {Promise<Object>} - Результат операции
   */
  async deletePoint(collectionName, id) {
    try {
      return await this.client.delete(collectionName, {
        points: [id]
      });
    } catch (error) {
      console.error('Error deleting point from Qdrant:', error);
      throw error;
    }
  }

  /**
   * Создание новой коллекции
   * @param {string} collectionName - Имя коллекции
   * @param {number} vectorSize - Размер вектора
   * @returns {Promise<Object>} - Результат операции
   */
  async createCollection(collectionName, vectorSize) {
    try {
      return await this.client.createCollection(collectionName, {
        vectors: {
          size: vectorSize,
          distance: 'Cosine'
        }
      });
    } catch (error) {
      console.error('Error creating collection in Qdrant:', error);
      throw error;
    }
  }

  /**
   * Получение информации о коллекции
   * @param {string} collectionName - Имя коллекции
   * @returns {Promise<Object>} - Информация о коллекции
   */
  async getCollection(collectionName) {
    try {
      return await this.client.getCollection(collectionName);
    } catch (error) {
      console.error('Error getting collection info from Qdrant:', error);
      throw error;
    }
  }

  /**
   * Получение списка всех коллекций
   * @returns {Promise<Array>} - Список коллекций
   */
  async listCollections() {
    try {
      return await this.client.listCollections();
    } catch (error) {
      console.error('Error listing collections from Qdrant:', error);
      throw error;
    }
  }
}

module.exports = QdrantHelper;
